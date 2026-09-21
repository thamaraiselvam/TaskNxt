import SwiftUI
import TaskNxtCore

/// Horizontal tab selector shown at the top of the popover: one entry per
/// tab with an active/inactive icon indicator, name, and incomplete-task
/// count, plus a control to add a new tab (spec: tab-management, "Switch
/// between tabs" / "Add a tab").
struct TabBarView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isAddingTab = false
    @State private var newTabName = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(appState.store.tabs.sorted(by: { $0.order < $1.order })) { tab in
                    tabButton(for: tab)
                }

                Button {
                    isAddingTab = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(appState.store.tabs.count >= AppState.maxTabs)
                .help(
                    appState.store.tabs.count >= AppState.maxTabs
                        ? "Maximum of 4 tabs reached"
                        : "Add a tab"
                )
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .popover(isPresented: $isAddingTab) {
            VStack(spacing: 8) {
                Text("New Tab").font(.headline)
                TextField("Tab name", text: $newTabName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                Button("Add") {
                    do {
                        try appState.addTab(named: newTabName.isEmpty ? "New Tab" : newTabName)
                        newTabName = ""
                        isAddingTab = false
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func tabButton(for tab: AppTab) -> some View {
        let isActive = appState.activeTabID == tab.id
        Button {
            appState.setActiveTab(tab.id)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.caption2)
                Text(tab.name)
                Text("\(tab.incompleteCount)")
                    .font(.caption2)
                    .opacity(0.6)
            }
            .font(.callout)
            .fontWeight(isActive ? .semibold : .regular)
            .foregroundStyle(isActive ? Color.accentColor : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                isActive
                    ? Color.secondary.opacity(0.15)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
    }
}
