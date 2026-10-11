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
    @FocusState private var isNameFocused: Bool

    var body: some View {
        HStack {
            if isEditing {
                TextField("Name", text: $name, onCommit: commitRename)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFocused)
                    .onExitCommand { isEditing = false }
                    // Focus is dropped if requested in the same update that
                    // inserts the field (same fix as TaskRowView).
                    .onAppear { DispatchQueue.main.async { isNameFocused = true } }
                    // Clicking elsewhere commits, like pressing Enter.
                    .onChange(of: isNameFocused) { focused in
                        if !focused && isEditing { commitRename() }
                    }
            } else {
                Text(tab.name)
                Spacer()
                Button {
                    name = tab.name
                    isEditing = true
                } label: {
                    Text("Rename")
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
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
