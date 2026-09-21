import SwiftUI
import AppKit
import TaskNxtCore

/// General settings: launch at login, completed-task retention/archiving,
/// and the Quit action (spec: settings; design.md "Quit lives in
/// General"). The global hotkey lives in its own "Shortcuts" section.
struct GeneralSettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsPageHeader(title: "General", subtitle: "Startup and completed-task behavior")

            SettingsCard {
                SettingsRow("Launch at Login", description: "Start TaskNxt automatically when you sign in.") {
                    Toggle("", isOn: Binding(
                        get: { appState.store.settings.launchAtLogin },
                        set: { appState.setLaunchAtLogin($0) }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                }

                SettingsRowDivider()

                SettingsRow("Keep Completed Tasks", description: "How long finished tasks stay before they're purged.") {
                    Stepper(
                        "\(appState.store.settings.retentionDays) day\(appState.store.settings.retentionDays == 1 ? "" : "s")",
                        value: Binding(
                            get: { appState.store.settings.retentionDays },
                            set: { appState.setRetentionDays($0) }
                        ),
                        in: 0...30
                    )
                }

                SettingsRowDivider()

                SettingsRow("Archive Completed Tasks", description: "Keep a browsable history instead of deleting them.") {
                    Toggle("", isOn: Binding(
                        get: { appState.store.settings.archiveCompletedTasks },
                        set: { appState.setArchiveCompletedTasks($0) }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                }
            }

            SettingsCard {
                SettingsRow("Quit TaskNxt", description: "Removes the menu bar icon and ends the app.") {
                    Button("Quit", role: .destructive) {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }

            Spacer()
        }
        .padding(24)
    }
}
