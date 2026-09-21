import SwiftUI
import TaskNxtCore

/// "Shortcuts" settings section: the global hotkey recorder, presented in
/// the shared card/row style (spec: settings, "Configurable global
/// hotkey").
struct ShortcutsSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsPageHeader(title: "Shortcuts", subtitle: "Hotkey options")

            SettingsCard {
                SettingsRow(
                    "Show / Hide TaskNxt",
                    description: "Click the box, then press a new key combination."
                ) {
                    HotKeyRecorderView()
                }
            }

            Spacer()
        }
        .padding(24)
    }
}
