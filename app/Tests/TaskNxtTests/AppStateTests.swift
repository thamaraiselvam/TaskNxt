import Testing
import Foundation
@testable import TaskNxtCore

@MainActor
struct AppStateTabTests {
    private func makeState() -> AppState {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("store.json")
        return AppState(localStore: LocalStore(fileURL: url))
    }

    @Test func addTabEnforcesFourTabMaximum() throws {
        let state = makeState()
        // One "Work" tab already exists from first-launch defaults.
        try state.addTab(named: "Personal")
        try state.addTab(named: "Errands")
        try state.addTab(named: "Ideas")
        #expect(state.store.tabs.count == 4)

        #expect(throws: TabActionError.maximumTabsReached) {
            try state.addTab(named: "One Too Many")
        }
        #expect(state.store.tabs.count == 4)
    }

    @Test func deleteTabEnforcesOneTabMinimum() throws {
        let state = makeState()
        let onlyTabID = state.store.tabs[0].id

        #expect(throws: TabActionError.cannotDeleteLastTab) {
            try state.deleteTab(onlyTabID)
        }
        #expect(state.store.tabs.count == 1)
    }

    @Test func renameTabPreservesTasks() {
        let state = makeState()
        let tabID = state.store.tabs[0].id
        state.addTask(text: "Write report", lane: .now, tabID: tabID)

        state.renameTab(tabID, to: "Renamed Tab")

        #expect(state.store.tabs[0].name == "Renamed Tab")
        #expect(state.store.tabs[0].tasks[.now]?.count == 1)
        #expect(state.store.tabs[0].tasks[.now]?.first?.text == "Write report")
    }

    @Test func deleteTabRemovesItsTasks() throws {
        let state = makeState()
        try state.addTab(named: "Temp")
        let tempTabID = state.store.tabs[1].id
        state.addTask(text: "Throwaway task", lane: .nxt, tabID: tempTabID)

        try state.deleteTab(tempTabID)

        #expect(state.store.tabs.count == 1)
        #expect(!state.store.tabs.contains { $0.id == tempTabID })
    }

    /// Regression coverage for spec: task-management, "Optional task
    /// deadline" -- setting/clearing a due date must never alter a task's
    /// `order` (drag-and-drop position), and `updateTaskText` must reject
    /// empty commits per "Inline task text editing".
    @Test func settingDueDatePreservesTaskOrder() {
        let state = makeState()
        let tabID = state.store.tabs[0].id
        state.addTask(text: "First", lane: .now, tabID: tabID)
        state.addTask(text: "Second", lane: .now, tabID: tabID)
        let firstID = state.store.tabs[0].tasks[.now]![0].id
        let secondID = state.store.tabs[0].tasks[.now]![1].id
        let firstOrderBefore = state.store.tabs[0].tasks[.now]![0].order
        let secondOrderBefore = state.store.tabs[0].tasks[.now]![1].order

        state.setTaskDueDate(secondID, lane: .now, tabID: tabID, dueDate: Date())

        let tasksAfter = state.store.tabs[0].tasks[.now]!
        #expect(tasksAfter.first { $0.id == firstID }?.order == firstOrderBefore)
        #expect(tasksAfter.first { $0.id == secondID }?.order == secondOrderBefore)
        #expect(tasksAfter.first { $0.id == secondID }?.dueDate != nil)

        state.setTaskDueDate(secondID, lane: .now, tabID: tabID, dueDate: nil)
        #expect(state.store.tabs[0].tasks[.now]!.first { $0.id == secondID }?.dueDate == nil)
    }

    @Test func updateTaskTextRejectsEmptyCommit() {
        let state = makeState()
        let tabID = state.store.tabs[0].id
        state.addTask(text: "Original text", lane: .now, tabID: tabID)
        let taskID = state.store.tabs[0].tasks[.now]![0].id

        state.updateTaskText(taskID, lane: .now, tabID: tabID, text: "   ")
        #expect(state.store.tabs[0].tasks[.now]![0].text == "Original text")

        state.updateTaskText(taskID, lane: .now, tabID: tabID, text: "Updated text")
        #expect(state.store.tabs[0].tasks[.now]![0].text == "Updated text")
    }

    @Test func sweepHardDeletesWhenArchivingDisabled() {
        let state = makeState()
        let tabID = state.store.tabs[0].id
        state.setRetentionDays(0)
        state.addTask(text: "Expiring task", lane: .now, tabID: tabID)
        let taskID = state.store.tabs[0].tasks[.now]![0].id
        state.toggleTask(taskID, lane: .now, tabID: tabID)

        state.sweepExpiredTasks()

        #expect(state.store.tabs[0].tasks[.now]?.isEmpty ?? true)
        #expect(state.store.archivedTasks.isEmpty)
    }

    @Test func sweepArchivesWhenArchivingEnabled() {
        let state = makeState()
        let tabID = state.store.tabs[0].id
        state.setRetentionDays(0)
        state.setArchiveCompletedTasks(true)
        state.addTask(text: "Archivable task", lane: .nxt, tabID: tabID)
        let taskID = state.store.tabs[0].tasks[.nxt]![0].id
        state.toggleTask(taskID, lane: .nxt, tabID: tabID)

        state.sweepExpiredTasks()

        #expect(state.store.tabs[0].tasks[.nxt]?.isEmpty ?? true)
        #expect(state.store.archivedTasks.count == 1)
        #expect(state.store.archivedTasks[0].text == "Archivable task")
        #expect(state.store.archivedTasks[0].originalLane == .nxt)
    }

    @Test func restoreArchivedTaskReturnsItIncompleteToOriginalLane() {
        let state = makeState()
        let tabID = state.store.tabs[0].id
        state.setRetentionDays(0)
        state.setArchiveCompletedTasks(true)
        state.addTask(text: "Archivable task", lane: .ltr, tabID: tabID)
        let taskID = state.store.tabs[0].tasks[.ltr]![0].id
        state.toggleTask(taskID, lane: .ltr, tabID: tabID)
        state.sweepExpiredTasks()
        let archivedID = state.store.archivedTasks[0].id

        state.restoreArchivedTask(archivedID)

        #expect(state.store.archivedTasks.isEmpty)
        let restored = state.store.tabs[0].tasks[.ltr]?.first { $0.text == "Archivable task" }
        #expect(restored != nil)
        #expect(restored?.isDone == false)
    }

    @Test func deleteArchivedTaskRemovesItPermanently() {
        let state = makeState()
        let tabID = state.store.tabs[0].id
        state.setRetentionDays(0)
        state.setArchiveCompletedTasks(true)
        state.addTask(text: "Archivable task", lane: .now, tabID: tabID)
        let taskID = state.store.tabs[0].tasks[.now]![0].id
        state.toggleTask(taskID, lane: .now, tabID: tabID)
        state.sweepExpiredTasks()
        let archivedID = state.store.archivedTasks[0].id

        state.deleteArchivedTask(archivedID)

        #expect(state.store.archivedTasks.isEmpty)
    }
}

struct GlobalHotKeyTests {
    @Test @MainActor func conflictingRegistrationKeepsPreviousBinding() {
        let hotKey = GlobalHotKey(onPress: {})
        defer { hotKey.unregister() }

        let first = HotKeyBinding(keyCode: 12, modifierFlags: HotKeyModifier.control) // Q
        #expect(hotKey.register(first))

        // Registering the exact same combination again from a second
        // manager simulates "already claimed" and must fail without
        // disturbing the first registration (spec: settings, "Conflicting
        // shortcut rejected").
        let other = GlobalHotKey(onPress: {})
        defer { other.unregister() }
        let claimed = other.register(first)

        // On this OS/hardware pair, Carbon hot key registration is
        // typically exclusive per (keyCode, modifiers) pair system-wide.
        #expect(!claimed)
    }
}

@MainActor
struct AppStateMoveTaskTests {
    private func makeState() async -> (AppState, UUID) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("store.json")
        let state = AppState(localStore: LocalStore(fileURL: url))
        await state.waitUntilLoaded()
        return (state, state.store.tabs[0].id)
    }

    private func texts(_ s: AppState, _ lane: Lane) -> [String] {
        (s.store.tabs[0].tasks[lane] ?? []).sorted { $0.order < $1.order }.map(\.text)
    }

    @Test func reorderWithinLane() async {
        let (s, tab) = await makeState()
        ["A", "B", "C"].forEach { s.addTask(text: $0, lane: .now, tabID: tab) }
        let c = s.store.tabs[0].tasks[.now]![2].id
        let a = s.store.tabs[0].tasks[.now]![0].id
        s.moveTask(c, tabID: tab, to: .now, before: a)
        #expect(texts(s, .now) == ["C", "A", "B"])
    }

    @Test func moveAcrossLanesKeepsCompletionAndReindexes() async {
        let (s, tab) = await makeState()
        s.addTask(text: "X", lane: .inbox, tabID: tab)
        s.addTask(text: "Y", lane: .inbox, tabID: tab)
        let x = s.store.tabs[0].tasks[.inbox]![0].id
        s.toggleTask(x, lane: .inbox, tabID: tab)
        s.moveTask(x, tabID: tab, to: .ltr)  // empty lane
        #expect(texts(s, .ltr) == ["X"])
        #expect(texts(s, .inbox) == ["Y"])
        #expect(s.store.tabs[0].tasks[.inbox]![0].order == 0)
        #expect(s.store.tabs[0].tasks[.ltr]![0].isDone)
    }

    @Test func movingDoesNotMarkTaskForSync() async {
        let (s, tab) = await makeState()
        s.addTask(text: "X", lane: .now, tabID: tab)
        let before = s.store.tabs[0].tasks[.now]![0].updatedAt
        s.moveTask(s.store.tabs[0].tasks[.now]![0].id, tabID: tab, to: .nxt)
        #expect(s.store.tabs[0].tasks[.nxt]![0].updatedAt == before)
    }

    @Test func deletingLinkedTaskRecordsTombstone() async {
        let (s, tab) = await makeState()
        s.addTask(text: "X", lane: .now, tabID: tab)
        s.updateTab(tab) { $0.tasks[.now]![0].googleID = "g1" }
        s.deleteTask(s.store.tabs[0].tasks[.now]![0].id, lane: .now, tabID: tab)
        #expect(s.store.tabs[0].pendingDeletes == ["g1"])
    }

    @Test func legacyStoreJSONStillDecodes() throws {
        let json = """
        {"schemaVersion":1,"settings":{"hotKey":{"keyCode":49,"modifierFlags":256},"launchAtLogin":false,"retentionDays":2},
         "tabs":[{"id":"\(UUID())","name":"Work","order":0,
           "tasks":{"now":[{"id":"\(UUID())","text":"Old","order":0}],"nxt":[],"ltr":[]}}]}
        """
        let store = try JSONDecoder().decode(Store.self, from: Data(json.utf8))
        #expect(store.tabs[0].tasks[.now]?.first?.text == "Old")
        #expect(store.tabs[0].tasks[.inbox]?.isEmpty == true)
        #expect(store.tabs[0].googleListID == nil)
    }
}
