import Foundation

public struct GoogleTaskList: Equatable, Identifiable {
    public let id: String
    public let title: String
    public init(id: String, title: String) { self.id = id; self.title = title }
}

public struct GoogleTask: Equatable {
    public var id: String
    public var title: String
    public var isCompleted: Bool
    public var completedAt: Date?
    /// Google stores a date only; the time component is meaningless.
    public var due: Date?
    public var updated: Date
    public var deleted: Bool

    public init(
        id: String, title: String, isCompleted: Bool = false, completedAt: Date? = nil,
        due: Date? = nil, updated: Date = Date(), deleted: Bool = false
    ) {
        self.id = id; self.title = title; self.isCompleted = isCompleted; self.completedAt = completedAt
        self.due = due; self.updated = updated; self.deleted = deleted
    }
}

public enum GoogleAPIError: LocalizedError, Equatable {
    case unauthorized
    case notFound
    case http(Int)
    case badResponse

    public var errorDescription: String? {
        switch self {
        case .unauthorized: return "Google rejected the sign-in. Reconnect Google Tasks."
        case .notFound: return "Not found on Google Tasks."
        case .http(let code): return "Google Tasks returned an error (\(code))."
        case .badResponse: return "Unexpected response from Google Tasks."
        }
    }
}

public protocol GoogleTasksAPI {
    func lists() async throws -> [GoogleTaskList]
    /// All tasks in the list (incl. completed/deleted) changed since `updatedMin`.
    func tasks(listID: String, updatedMin: Date?) async throws -> [GoogleTask]
    func insert(listID: String, title: String, isCompleted: Bool, due: Date?) async throws -> GoogleTask
    func patch(listID: String, taskID: String, title: String, isCompleted: Bool, due: Date?) async throws -> GoogleTask
    func delete(listID: String, taskID: String) async throws
}

/// Plain REST client for the Google Tasks API (no SDK dependency).
public struct GoogleTasksClient: GoogleTasksAPI {
    private let token: () async throws -> String
    private let session: URLSession
    private static let base = "https://tasks.googleapis.com/tasks/v1"

    public init(session: URLSession = .shared, token: @escaping () async throws -> String) {
        self.session = session
        self.token = token
    }

    public func lists() async throws -> [GoogleTaskList] {
        try await pages("/users/@me/lists", query: []).compactMap { item in
            guard let id = item["id"] as? String else { return nil }
            return GoogleTaskList(id: id, title: item["title"] as? String ?? "Untitled")
        }
    }

    public func tasks(listID: String, updatedMin: Date?) async throws -> [GoogleTask] {
        var query = [
            URLQueryItem(name: "showCompleted", value: "true"),
            URLQueryItem(name: "showHidden", value: "true"),
            URLQueryItem(name: "showDeleted", value: "true"),
        ]
        if let updatedMin { query.append(URLQueryItem(name: "updatedMin", value: Self.format(updatedMin))) }
        return try await pages("/lists/\(Self.seg(listID))/tasks", query: query).compactMap(Self.parse)
    }

    public func insert(listID: String, title: String, isCompleted: Bool, due: Date?) async throws -> GoogleTask {
        let body = Self.body(title: title, isCompleted: isCompleted, due: due)
        return try parseOne(try await send("POST", "/lists/\(Self.seg(listID))/tasks", body: body))
    }

    public func patch(listID: String, taskID: String, title: String, isCompleted: Bool, due: Date?) async throws -> GoogleTask {
        let body = Self.body(title: title, isCompleted: isCompleted, due: due)
        return try parseOne(try await send("PATCH", "/lists/\(Self.seg(listID))/tasks/\(Self.seg(taskID))", body: body))
    }

    public func delete(listID: String, taskID: String) async throws {
        _ = try await send("DELETE", "/lists/\(Self.seg(listID))/tasks/\(Self.seg(taskID))", body: nil)
    }

    // MARK: - Plumbing

    /// Ids go into URL paths; encode so a odd id can't alter the request path.
    static func seg(_ id: String) -> String {
        id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))) ?? ""
    }

    private func parseOne(_ data: Data) throws -> GoogleTask {
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any], let t = Self.parse(obj)
        else { throw GoogleAPIError.badResponse }
        return t
    }

    private func pages(_ path: String, query: [URLQueryItem]) async throws -> [[String: Any]] {
        var items: [[String: Any]] = []
        var pageToken: String?
        repeat {
            var q = query + [URLQueryItem(name: "maxResults", value: "100")]
            if let pageToken { q.append(URLQueryItem(name: "pageToken", value: pageToken)) }
            let data = try await send("GET", path, query: q, body: nil)
            guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { throw GoogleAPIError.badResponse }
            items += obj["items"] as? [[String: Any]] ?? []
            pageToken = obj["nextPageToken"] as? String
        } while pageToken != nil
        return items
    }

    private func send(_ method: String, _ path: String, query: [URLQueryItem] = [], body: [String: Any]?) async throws -> Data {
        var comps = URLComponents(string: Self.base + path)!
        if !query.isEmpty { comps.queryItems = query }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = method
        req.setValue("Bearer \(try await token())", forHTTPHeaderField: "Authorization")
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw GoogleAPIError.badResponse }
        switch http.statusCode {
        case 200..<300: return data
        case 401: throw GoogleAPIError.unauthorized
        case 404, 410: throw GoogleAPIError.notFound
        default: throw GoogleAPIError.http(http.statusCode)
        }
    }

    // MARK: - Encoding

    private static func body(title: String, isCompleted: Bool, due: Date?) -> [String: Any] {
        var body: [String: Any] = [
            "title": title,
            "status": isCompleted ? "completed" : "needsAction",
            "due": due.map(dueString) ?? NSNull(),
        ]
        // Google only clears the completion time on un-complete if told to.
        if !isCompleted { body["completed"] = NSNull() }
        return body
    }

    /// Google treats `due` as a calendar date; send the user's local day as UTC midnight.
    static func dueString(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02dT00:00:00.000Z", c.year!, c.month!, c.day!)
    }

    /// Inverse of `dueString`: the day at 23:59 local, so it isn't overdue until the day ends.
    static func dueDate(_ string: String) -> Date? {
        guard string.count >= 10 else { return nil }
        let p = string.prefix(10).split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: p[0], month: p[1], day: p[2], hour: 23, minute: 59))
    }

    static func format(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: date)
    }

    static func parseDate(_ string: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: string) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: string)
    }

    static func parse(_ o: [String: Any]) -> GoogleTask? {
        guard let id = o["id"] as? String else { return nil }
        return GoogleTask(
            id: id,
            title: o["title"] as? String ?? "",
            isCompleted: o["status"] as? String == "completed",
            completedAt: (o["completed"] as? String).flatMap(parseDate),
            due: (o["due"] as? String).flatMap(dueDate),
            updated: (o["updated"] as? String).flatMap(parseDate) ?? Date(),
            deleted: o["deleted"] as? Bool ?? false
        )
    }
}
