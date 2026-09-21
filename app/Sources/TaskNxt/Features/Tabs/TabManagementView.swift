import SwiftUI
import TaskNxtCore

/// Full tab management surface embedded in Settings: rename, reorder, and
/// delete tabs (spec: tab-management, spec: settings "Tab management
/// access").
struct TabManagementView: View {
    @EnvironmentObject private var appState: AppState
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsPageHeader(title: "Tabs", subtitle: "Add, rename, reorder, and delete your tabs")

            List {
                ForEach(appState.store.tabs.sorted(by: { $0.order < $1.order })) { tab in
                    TabRow(tab: tab, errorMessage: $errorMessage)
                }
                .onMove { source, destination in
                    appState.moveTab(fromOffsets: source, toOffset: destination)
                }
            }
            .frame(minHeight: 200)

            if let errorMessage {
                Text(errorMessage).font(.caption2).foregroundStyle(.red)
            }
        }
        .padding(24)
    }
}

private struct TabRow: View {
    @EnvironmentObject private var appState: AppState
    let tab: AppTab
    @Binding var errorMessage: String?
    @State private var name: String = ""
    @State private var isEditing = false

    var body: some View {
        HStack {
            if isEditing {
                TextField("Name", text: $name, onCommit: commitRename)
                    .textFieldStyle(.roundedBorder)
            } else {
                Text(tab.name)
                Spacer()
                Button("Rename") {
                    name = tab.name
                    isEditing = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                do {
                    try appState.deleteTab(tab.id)
                    errorMessage = nil
                } catch {
                    errorMessage = error.localizedDescription
                }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
    }

    private func commitRename() {
        appState.renameTab(tab.id, to: name.isEmpty ? tab.name : name)
        isEditing = false
    }
}
