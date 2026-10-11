import AuthenticationServices
import SwiftUI
import TaskNxtCore

/// Google Tasks section: connect/disconnect and a toggle per task list
/// (spec: settings, "Google Tasks settings section").
struct GoogleTasksSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var sync: GoogleTasksSync

    var body: some View {
        // Scrolls so many lists never overflow the fixed-size window.
        ScrollView {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsPageHeader(title: "Google Tasks", subtitle: "Sync Google task lists into tabs")

            SettingsCard {
                switch sync.status {
                case .disconnected:
                    SettingsRow("Connect Google Tasks", description: "Sign in to choose which task lists to sync.") {
                        Button("Connect") { Task { await sync.connect { url, scheme in try await WebAuth.run(url: url, scheme: scheme) } } }
                    }
                case .reconnectRequired:
                    SettingsRow("Reconnect Google Tasks", description: "Google access expired. Your local tasks are untouched.") {
                        Button("Reconnect") { Task { await sync.connect { url, scheme in try await WebAuth.run(url: url, scheme: scheme) } } }
                    }
                    SettingsRowDivider()
                    disconnectRow
                case .connected:
                    disconnectRow
                }
            }

            if let error = sync.lastError {
                Text(error).font(.callout).foregroundStyle(.red)
            }

            if sync.status == .connected {
                SettingsCard {
                    SettingsRow("Sync", description: sync.isSyncing ? "Syncing…" : "How often to check Google for changes.") {
                        HStack {
                            Picker("", selection: Binding(
                                get: { appState.store.settings.googleSyncInterval },
                                set: { sync.setSyncInterval($0) }
                            )) {
                                ForEach(GoogleTasksSync.intervalOptions, id: \.seconds) { Text($0.label).tag($0.seconds) }
                            }
                            .labelsHidden()
                            .fixedSize()
                            Button("Sync Now") { Task { await sync.syncNow() } }
                                .disabled(sync.isSyncing)
                        }
                    }
                }

                SettingsCard {
                    if sync.lists.isEmpty {
                        SettingsRow(sync.isSyncing ? "Loading lists…" : "No task lists found") {}
                    }
                    ForEach(Array(sync.lists.enumerated()), id: \.element.id) { index, list in
                        if index > 0 { SettingsRowDivider() }
                        SettingsRow(list.title, description: "Appears as its own tab; new tasks arrive in Inbox.") {
                            Toggle("", isOn: Binding(
                                get: { sync.isEnabled(list) },
                                set: { on in Task { await sync.setList(list, enabled: on) } }
                            ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                        }
                    }
                }
            }
        }
        .padding(24)
    }

    private var disconnectRow: some View {
        SettingsRow(
            "Connected",
            description: appState.store.settings.googleAccountEmail ?? "Google account"
        ) {
            Button("Disconnect", role: .destructive) { Task { await sync.disconnect() } }
        }
    }
}

/// Runs Google's consent page in the system web session.
private enum WebAuth {
    @MainActor
    static func run(url: URL, scheme: String) async throws -> URL {
        let presenter = PresentationContext()
        return try await withCheckedThrowingContinuation { cont in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { callback, error in
                if let callback {
                    cont.resume(returning: callback)
                } else if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                    cont.resume(throwing: GoogleAuthError.cancelled)
                } else {
                    cont.resume(throwing: GoogleAuthError.failed(error?.localizedDescription ?? "unknown"))
                }
            }
            session.presentationContextProvider = presenter
            // `presenter` must outlive the session; the session retains it weakly.
            objc_setAssociatedObject(session, "presenter", presenter, .OBJC_ASSOCIATION_RETAIN)
            session.start()
        }
    }

    private final class PresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            NSApp.keyWindow ?? NSApp.windows.first ?? ASPresentationAnchor()
        }
    }
}
