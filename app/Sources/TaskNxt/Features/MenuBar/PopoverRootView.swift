import SwiftUI
import TaskNxtCore

/// The root content shown inside the popover: title + total count + gear,
/// the tab bar, the active tab's three lanes, and a minimal footer
/// (spec: menu-bar-shell, task-management, tab-management).
struct PopoverRootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isShowingArchive = false

    private var activeTab: AppTab? {
        appState.store.tabs.first(where: { $0.id == appState.activeTabID })
            ?? appState.store.tabs.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("TaskNxt").font(.headline)
                if let count = activeTab?.incompleteCount {
                    Text("\(count)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.secondary.opacity(0.12), in: Capsule())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    isShowingArchive = true
                } label: {
                    Image(systemName: "archivebox")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("View archived tasks")
                .popover(isPresented: $isShowingArchive) {
                    ArchiveView().environmentObject(appState)
                }

                Button {
                    appState.requestOpenSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            TabBarView()
                .padding(.horizontal, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if let tab = activeTab {
                        ForEach(Lane.allCases) { lane in
                            LaneView(lane: lane, tabID: tab.id)
                        }
                    } else {
                        Text("No tabs yet").foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
            }

            HStack {
                Spacer()
                Text(hotKeyHint).font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .frame(width: 340, height: 480)
        .onAppear { appState.sweepExpiredTasks() }
    }

    private var hotKeyHint: String {
        let m = appState.store.settings.hotKey.modifierFlags
        var s = ""
        if m & HotKeyModifier.control != 0 { s += "⌃" }
        if m & HotKeyModifier.option != 0 { s += "⌥" }
        if m & HotKeyModifier.shift != 0 { s += "⇧" }
        if m & HotKeyModifier.command != 0 { s += "⌘" }
        s += KeyCodeNames.name(for: appState.store.settings.hotKey.keyCode)
        return s
    }
}
