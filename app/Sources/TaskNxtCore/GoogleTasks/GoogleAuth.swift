import CryptoKit
import Foundation
import Security

public enum GoogleAuthError: LocalizedError, Equatable {
    case notConfigured
    case cancelled
    case failed(String)
    case reconnectRequired

    public var errorDescription: String? {
        switch self {
        case .notConfigured: return "Google sign-in isn't configured in this build (missing GoogleClientID)."
        case .cancelled: return "Sign-in was cancelled."
        case .failed(let why): return "Google sign-in failed: \(why)"
        case .reconnectRequired: return "Google access expired. Reconnect Google Tasks."
        }
    }
}

/// Refresh token in the macOS Keychain (spec: google-tasks-sync, "Connect
/// Google account" -- never in store.json).
public struct KeychainTokenStore {
    private let service = "com.tasknxt.google"
    private let account = "refresh-token"
    public init() {}

    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    public func get() -> String? {
        var q = query
        q[kSecReturnData as String] = true
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func set(_ token: String) throws {
        SecItemDelete(query as CFDictionary)
        var q = query
        q[kSecValueData as String] = Data(token.utf8)
        let status = SecItemAdd(q as CFDictionary, nil)
        guard status == errSecSuccess else { throw GoogleAuthError.failed("Keychain error \(status)") }
    }

    public func delete() { SecItemDelete(query as CFDictionary) }
}

/// OAuth for an installed app (PKCE, no client secret). The browser step is
/// injected so this stays free of AppKit/AuthenticationServices.
public actor GoogleAuth {
    /// Opens `url` for the user and returns the redirect URL (callback scheme given).
    public typealias WebSession = @Sendable (_ url: URL, _ callbackScheme: String) async throws -> URL

    private let clientID: String?
    private let tokens: KeychainTokenStore
    private let session: URLSession
    private var accessToken: (value: String, expires: Date)?

    /// `clientID` is an OAuth client of type "iOS" (custom-scheme redirect, no secret).
    public init(clientID: String?, tokens: KeychainTokenStore = KeychainTokenStore(), session: URLSession = .shared) {
        self.clientID = (clientID?.isEmpty ?? true) ? nil : clientID
        self.tokens = tokens
        self.session = session
    }

    public var hasCredentials: Bool { tokens.get() != nil }

    /// Returns the account email.
    public func signIn(_ web: WebSession) async throws -> String? {
        guard let clientID else { throw GoogleAuthError.notConfigured }
        let scheme = "com.googleusercontent.apps." + clientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
        let redirect = "\(scheme):/oauth2redirect"
        let verifier = Self.randomURLSafe(32)
        let state = Self.randomURLSafe(16)

        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        comps.queryItems = [
            .init(name: "client_id", value: clientID), .init(name: "redirect_uri", value: redirect),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: "https://www.googleapis.com/auth/tasks openid email"),
            .init(name: "code_challenge", value: Self.b64url(Data(SHA256.hash(data: Data(verifier.utf8))))),
            .init(name: "code_challenge_method", value: "S256"), .init(name: "state", value: state),
            .init(name: "access_type", value: "offline"), .init(name: "prompt", value: "consent"),
        ]
        let callback = try await web(comps.url!, scheme)
        let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
        if items.first(where: { $0.name == "error" })?.value == "access_denied" { throw GoogleAuthError.cancelled }
        guard items.first(where: { $0.name == "state" })?.value == state,
              let code = items.first(where: { $0.name == "code" })?.value
        else { throw GoogleAuthError.failed("Invalid response") }

        let json = try await tokenRequest([
            "client_id": clientID, "code": code, "code_verifier": verifier,
            "redirect_uri": redirect, "grant_type": "authorization_code",
        ])
        guard let refresh = json["refresh_token"] as? String else { throw GoogleAuthError.failed("No refresh token") }
        try tokens.set(refresh)
        remember(json)
        return (json["id_token"] as? String).flatMap(Self.email(fromIDToken:))
    }

    public func validAccessToken() async throws -> String {
        if let t = accessToken, t.expires > Date().addingTimeInterval(60) { return t.value }
        guard let clientID else { throw GoogleAuthError.notConfigured }
        guard let refresh = tokens.get() else { throw GoogleAuthError.reconnectRequired }
        let json = try await tokenRequest([
            "client_id": clientID, "refresh_token": refresh, "grant_type": "refresh_token",
        ])
        guard let value = json["access_token"] as? String else { throw GoogleAuthError.failed("No access token") }
        remember(json)
        return value
    }

    public func signOut() {
        tokens.delete()
        accessToken = nil
    }

    /// Revokes the grant at Google (best effort, so the token is useless even
    /// if a copy leaked), then forgets it locally.
    public func disconnect() async {
        if let refresh = tokens.get() {
            var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/revoke")!)
            req.httpMethod = "POST"
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = Data("token=\(Self.formEncode(refresh))".utf8)
            _ = try? await session.data(for: req)
        }
        signOut()
    }

    private static func formEncode(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    }

    // MARK: - Helpers

    private func remember(_ json: [String: Any]) {
        guard let value = json["access_token"] as? String else { return }
        accessToken = (value, Date().addingTimeInterval((json["expires_in"] as? Double) ?? 3600))
    }

    private func tokenRequest(_ form: [String: String]) async throws -> [String: Any] {
        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = form.map { "\($0.key)=\(Self.formEncode($0.value))" }
            .joined(separator: "&").data(using: .utf8)
        let (data, resp) = try await session.data(for: req)
        let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        guard let status = (resp as? HTTPURLResponse)?.statusCode, status < 300 else {
            if json["error"] as? String == "invalid_grant" {
                signOut()
                throw GoogleAuthError.reconnectRequired
            }
            throw GoogleAuthError.failed(json["error_description"] as? String ?? "token request failed")
        }
        return json
    }

    private static func randomURLSafe(_ bytes: Int) -> String {
        b64url(Data((0..<bytes).map { _ in UInt8.random(in: .min ... .max) }))
    }

    private static func b64url(_ data: Data) -> String {
        data.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }

    /// Email claim from the id_token we just received over TLS from Google (not verified further; display only).
    static func email(fromIDToken jwt: String) -> String? {
        let parts = jwt.split(separator: ".")
        guard parts.count > 1 else { return nil }
        var b64 = parts[1].replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while b64.count % 4 != 0 { b64 += "=" }
        guard let data = Data(base64Encoded: b64),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return obj["email"] as? String
    }
}
