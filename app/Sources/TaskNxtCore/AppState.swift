import Foundation
import Combine

/// Errors surfaced to the UI for user-facing validation messages (spec:
/// tab-management, "Blocked from adding a 5th tab" / "Blocked from
/// deleting the last tab").
public enum TabActionError: LocalizedError {
    case maximumTabsReached
    case cannotDeleteLastTab

    public var errorDescription: String? {
        switch self {
        case .maximumTabsReached:
            return "You can have up to 4 tabs. Delete one before adding another."
        case .cannotDeleteLastTab:
            return "You need at least 1 tab. Add another before deleting this one."
        }
    }
}

/// Central, observable, single source of truth for the running app: the
/// in-memory mirror of `Store`, plus every mutation the UI can perform.
/// All mutations funnel through here so the local file is always kept in
/// sync and the periodic auto-purge sweep can't race a user edit
/// (design.md, Risk 3).
@MainActor
public final class AppState: ObservableObject {
    public static let maxTabs = 4
    public static let minTabs = 1

    @Published public private(set) var store: Store
    @Published public var activeTabID: UUID?

    private let localStore: LocalStore
    private var sweepTimer: Timer?
    public let globalHotKey: GlobalHotKey
    private var togglePopover: (() -> Void)?
    private var openSettings: (() -> Void)?

    public init(localStore: LocalStore = LocalStore()) {
        self.localStore = localStore
        let initial = Store.firstLaunchDefault()
        self.store = initial
        self.activeTabID = initial.settings.lastActiveTabID
        self.globalHotKey = GlobalHotKey(onPress: {})
        globalHotKey.onPress = { [weak self] in
            // Carbon's hot key callback isn't statically known to run on
            // the main actor, so hop explicitly before touching any
            // @MainActor-isolated state (mirrors the fix needed for
            // AppDelegate's synchronous init call).
            Task { @MainActor in self?.togglePopover?() }
        }
        Task { await loadFromDisk() }
    }

    /// Lets the menu bar shell hand this state a way to toggle the popover
    /// so the global hotkey (owned here) can drive it.
    public func bindPopoverToggle(_ action: @escaping () -> Void) {
        togglePopover = action
    }

    /// Lets the menu bar shell hand this state a way to open the
    /// standalone settings window, so SwiftUI views (which have no direct
    /// AppKit window access) can trigger it via `appState` (spec:
    /// settings, "Settings entry point").
    public func bindOpenSettings(_ action: @escaping () -> Void) {
        openSettings = action
    }

    public func requestOpenSettings() {
        openSettings?()
    }

    private func loadFromDisk() async {
        let loaded = await localStore.load()
        store = loaded
        activeTabID = loaded.settings.lastActiveTabID ?? loaded.tabs.first?.id
        globalHotKey.register(loaded.settings.hotKey)
        startSweepTimer()
        sweepExpiredTasks()
    }

    private func persist() {
        let snapshot = store
        Task { try? await localStore.save(snapshot) }
    }

    // MARK: - Tabs

    public func addTab(named name: String) throws {
        guard store.tabs.count < Self.maxTabs else { throw TabActionError.maximumTabsReached }
        let tab = AppTab(name: name, order: store.tabs.count)
        store.tabs.append(tab)
        activeTabID = tab.id
        store.settings.lastActiveTabID = tab.id
        persist()
    }

    public func renameTab(_ id: UUID, to name: String) {
        guard let idx = store.tabs.firstIndex(where: { $0.id == id }) else { return }
        store.tabs[idx].name = name
        persist()
    }

    public func deleteTab(_ id: UUID) throws {
        guard store.tabs.count > Self.minTabs else { throw TabActionError.cannotDeleteLastTab }
        store.tabs.removeAll { $0.id == id }
        reindexTabOrders()
        if activeTabID == id {
            activeTabID = store.tabs.first?.id
            store.settings.lastActiveTabID = activeTabID
        }
        persist()
    }

    public func moveTab(fromOffsets source: IndexSet, toOffset destination: Int) {
        store.tabs.move(fromOffsets: source, toOffset: destination)
        reindexTabOrders()
        persist()
    }

    public func setActiveTab(_ id: UUID) {
        activeTabID = id
        store.settings.lastActiveTabID = id
        persist()
    }

    private func reindexTabOrders() {
        for i in store.tabs.indices {
            store.tabs[i].order = i
        }
    }

    private func tabIndex(_ id: UUID) -> Int? {
        store.tabs.firstIndex { $0.id == id }
    }

    // MARK: - Tasks

    public func addTask(text: String, lane: Lane, tabID: UUID) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = tabIndex(tabID) else { return }
        let order = store.tabs[idx].tasks[lane]?.count ?? 0
        let task = TaskItem(text: trimmed, order: order)
        store.tabs[idx].tasks[lane, default: []].append(task)
        persist()
    }

    public func toggleTask(_ taskID: UUID, lane: Lane, tabID: UUID) {
        guard let tabIdx = tabIndex(tabID),
              var tasks = store.tabs[tabIdx].tasks[lane],
              let taskIdx = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        if tasks[taskIdx].isDone {
            tasks[taskIdx].completedAt = nil
        } else {
            tasks[taskIdx].completedAt = Date()
        }
        store.tabs[tabIdx].tasks[lane] = tasks
        persist()
    }

    public func deleteTask(_ taskID: UUID, lane: Lane, tabID: UUID) {
        guard let tabIdx = tabIndex(tabID) else { return }
        store.tabs[tabIdx].tasks[lane]?.removeAll { $0.id == taskID }
        persist()
    }

    /// Updates a task's text in place (spec: task-management, "Inline task
    /// text editing"). An empty/whitespace-only value is rejected and the
    /// task's existing text is left unchanged.
    public func updateTaskText(_ taskID: UUID, lane: Lane, tabID: UUID, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let tabIdx = tabIndex(tabID),
              let taskIdx = store.tabs[tabIdx].tasks[lane]?.firstIndex(where: { $0.id == taskID })
        else { return }
        store.tabs[tabIdx].tasks[lane]![taskIdx].text = trimmed
        persist()
    }

    /// Sets or clears a task's due date. Never touches `order` (spec:
    /// task-management, "Due date does not affect ordering").
    public func setTaskDueDate(_ taskID: UUID, lane: Lane, tabID: UUID, dueDate: Date?) {
        guard let tabIdx = tabIndex(tabID),
              let taskIdx = store.tabs[tabIdx].tasks[lane]?.firstIndex(where: { $0.id == taskID })
        else { return }
        store.tabs[tabIdx].tasks[lane]![taskIdx].dueDate = dueDate
        persist()
    }

    /// Moves a task to a (possibly different) lane and/or tab, preserving
    /// its completion state, and inserts it at `index` in the destination
    /// (spec: task-management, "Move task between lanes" / "across tabs").
    public func moveTask(
        _ taskID: UUID,
        fromLane: Lane, fromTabID: UUID,
        toLane: Lane, toTabID: UUID,
        toIndex index: Int?
    ) {
        guard let fromTabIdx = tabIndex(fromTabID),
              let taskIdx = store.tabs[fromTabIdx].tasks[fromLane]?.firstIndex(where: { $0.id == taskID })
        else { return }

        var task = store.tabs[fromTabIdx].tasks[fromLane]![taskIdx]
        store.tabs[fromTabIdx].tasks[fromLane]!.remove(at: taskIdx)

        guard let toTabIdx = tabIndex(toTabID) else { return }
        var destination = store.tabs[toTabIdx].tasks[toLane] ?? []
        let insertAt = min(max(index ?? destination.count, 0), destination.count)
        task.order = insertAt
        destination.insert(task, at: insertAt)
        for i in destination.indices { destination[i].order = i }
        store.tabs[toTabIdx].tasks[toLane] = destination

        persist()
    }

    public func reorderTasks(in lane: Lane, tabID: UUID, fromOffsets source: IndexSet, toOffset destination: Int) {
        guard let tabIdx = tabIndex(tabID), var tasks = store.tabs[tabIdx].tasks[lane] else { return }
        tasks.move(fromOffsets: source, toOffset: destination)
        for i in tasks.indices { tasks[i].order = i }
        store.tabs[tabIdx].tasks[lane] = tasks
        persist()
    }

    // MARK: - Settings

    @discardableResult
    public func updateHotKey(_ binding: HotKeyBinding) -> Bool {
        guard globalHotKey.register(binding) else { return false }
        store.settings.hotKey = binding
        persist()
        return true
    }

    public func setRetentionDays(_ days: Int) {
        store.settings.retentionDays = max(0, days)
        persist()
    }

    public func setLaunchAtLogin(_ enabled: Bool) {
        store.settings.launchAtLogin = enabled
        LaunchAtLogin.setEnabled(enabled)
        persist()
    }

    public func setArchiveCompletedTasks(_ enabled: Bool) {
        store.settings.archiveCompletedTasks = enabled
        persist()
    }

    // MARK: - Menu bar badge

    /// Incomplete-task count for the currently active tab, used to badge
    /// the menu bar icon (spec: menu-bar-shell, "Pending-count badge on
    /// menu bar icon"). Computed from the existing `@Published` `store`/
    /// `activeTabID`, so `objectWillChange` already fires whenever either
    /// changes -- no separate publishing plumbing needed.
    public var activeTabIncompleteCount: Int {
        guard let activeTabID else { return 0 }
        return store.tabs.first(where: { $0.id == activeTabID })?.incompleteCount ?? 0
    }

    // MARK: - Auto-purge sweep

    private func startSweepTimer() {
        sweepTimer?.invalidate()
        sweepTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            // `Timer`'s fire closure is `@Sendable`, so capturing the
            // `weak self` var directly inside the nested `Task` would
            // reference a mutable variable from concurrently-executing
            // code. Binding it to a local `let` first captures a fixed,
            // safe-to-send reference instead.
            guard let self else { return }
            Task { @MainActor in self.sweepExpiredTasks() }
        }
    }

    /// Removes any completed task whose retention period has fully
    /// elapsed -- moving it to the archive first if
    /// `settings.archiveCompletedTasks` is enabled, otherwise deleting it
    /// outright as before (spec: task-management, "Task purged after
    /// retention period (archiving disabled)" / "Task archived after
    /// retention period (archiving enabled)"). Runs on launch and on a
    /// 60s timer while the popover is open (design.md, Decision 4).
    public func sweepExpiredTasks() {
        let retentionDays = store.settings.retentionDays
        let shouldArchive = store.settings.archiveCompletedTasks
        var changed = false
        for tabIdx in store.tabs.indices {
            let tabID = store.tabs[tabIdx].id
            for lane in Lane.allCases {
                guard var tasks = store.tabs[tabIdx].tasks[lane] else { continue }
                let before = tasks.count
                let expiring = tasks.filter { task in
                    guard let completedAt = task.completedAt else { return false }
                    return RetentionPolicy.isExpired(completedAt: completedAt, retentionDays: retentionDays)
                }
                if !expiring.isEmpty {
                    if shouldArchive {
                        for task in expiring {
                            store.archivedTasks.append(
                                ArchivedTask(from: task, tabID: tabID, lane: lane, completedAt: task.completedAt!)
                            )
                        }
                    }
                    tasks.removeAll { task in expiring.contains { $0.id == task.id } }
                }
                if tasks.count != before {
                    store.tabs[tabIdx].tasks[lane] = tasks
                    changed = true
                }
            }
        }
        if changed { persist() }
    }

    // MARK: - Task archive

    /// Restores an archived task back to its original tab/lane as
    /// incomplete, or to the current active tab's matching lane if the
    /// original tab was since deleted (spec: task-archive, "Restore an
    /// archived task").
    public func restoreArchivedTask(_ archivedID: UUID) {
        guard let idx = store.archivedTasks.firstIndex(where: { $0.id == archivedID }) else { return }
        let archived = store.archivedTasks[idx]
        let destinationTabID = tabIndex(archived.originalTabID) != nil ? archived.originalTabID : activeTabID
        guard let destinationTabID, let tabIdx = tabIndex(destinationTabID) else { return }

        let order = store.tabs[tabIdx].tasks[archived.originalLane]?.count ?? 0
        let restored = TaskItem(
            id: archived.id, text: archived.text, completedAt: nil, order: order, dueDate: archived.dueDate
        )
        store.tabs[tabIdx].tasks[archived.originalLane, default: []].append(restored)
        store.archivedTasks.remove(at: idx)
        persist()
    }

    /// Permanently deletes an archived task (spec: task-archive,
    /// "Permanently delete an archived task").
    public func deleteArchivedTask(_ archivedID: UUID) {
        store.archivedTasks.removeAll { $0.id == archivedID }
        persist()
    }

    /// Immediately archives a single completed task on demand, rather
    /// than waiting for the retention countdown to expire (spec:
    /// task-archive, "Archive a completed task on demand"). No-op for
    /// tasks that aren't yet marked done, since only completed tasks have
    /// a `completedAt` to record on the resulting `ArchivedTask`.
    public func archiveTask(_ taskID: UUID, lane: Lane, tabID: UUID) {
        guard let tabIdx = tabIndex(tabID),
              var tasks = store.tabs[tabIdx].tasks[lane],
              let taskIdx = tasks.firstIndex(where: { $0.id == taskID }),
              let completedAt = tasks[taskIdx].completedAt
        else { return }

        let task = tasks[taskIdx]
        store.archivedTasks.append(ArchivedTask(from: task, tabID: tabID, lane: lane, completedAt: completedAt))
        tasks.remove(at: taskIdx)
        store.tabs[tabIdx].tasks[lane] = tasks
        persist()
    }
}
