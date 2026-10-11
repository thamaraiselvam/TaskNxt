import Testing
import Foundation
@testable import TaskNxtCore

final class FakeGoogleAPI: GoogleTasksAPI, @unchecked Sendable {
    var remote: [String: GoogleTask] = [:]
    var failing = false
    var calls: [String] = []
    private var counter = 0

    func lists() async throws -> [GoogleTaskList] { [GoogleTaskList(id: "L1", title: "Groceries")] }

    func tasks(listID: String, updatedMin: Date?) async throws -> [GoogleTask] {
        if failing { throw URLError(.notConnectedToInternet) }
        return Array(remote.values)
    }

    func insert(listID: String, title: String, isCompleted: Bool, due: Date?) async throws -> GoogleTask {
        if failing { throw URLError(.notConnectedToInternet) }
        counter += 1
        let t = GoogleTask(id: "new\(counter)", title: title, isCompleted: isCompleted, updated: Date())
        remote[t.id] = t
        calls.append("insert")
        return t
    }

    func patch(listID: String, taskID: String, title: String, isCompleted: Bool, due: Date?) async throws -> GoogleTask {
        calls.append("patch")
        var t = remote[taskID]!
        t.title = title; t.isCompleted = isCompleted; t.updated = Date()
        remote[taskID] = t
        return t
    }

    func delete(listID: String, taskID: String) async throws {
        calls.append("delete")
        remote[taskID] = nil
    }
}

@MainActor
struct GoogleSyncTests {
    private func make() async -> (AppState, GoogleTasksSync, FakeGoogleAPI, UUID) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathComponent("store.json")
        let state = AppState(localStore: LocalStore(fileURL: url))
        await state.waitUntilLoaded()
        let api = FakeGoogleAPI()
        let sync = GoogleTasksSync(appState: state, auth: GoogleAuth(clientID: nil), api: api)
        state.addGoogleTab(named: "Groceries", listID: "L1")
        return (state, sync, api, state.store.tabs[1].id)
    }

    private func tab(_ s: AppState, _ id: UUID) -> AppTab { s.store.tabs.first { $0.id == id }! }

    @Test func remoteTaskLandsInInbox() async throws {
        let (s, sync, api, id) = await make()
        api.remote["a"] = GoogleTask(id: "a", title: "Milk")
        try await sync.sync(tabID: id)
        #expect(tab(s, id).tasks[.inbox]?.map(\.text) == ["Milk"])
    }

    @Test func completedUnknownRemoteTaskIsNotImported() async throws {
        let (s, sync, api, id) = await make()
        api.remote["a"] = GoogleTask(id: "a", title: "Old", isCompleted: true)
        try await sync.sync(tabID: id)
        #expect(tab(s, id).tasks[.inbox]?.isEmpty == true)
    }

    @Test func localCompletionAndCreateArePushedOnceThenStable() async throws {
        let (s, sync, api, id) = await make()
        api.remote["a"] = GoogleTask(id: "a", title: "Milk", updated: Date(timeIntervalSinceNow: -100))
        try await sync.sync(tabID: id)
        let local = tab(s, id).tasks[.inbox]![0]
        s.toggleTask(local.id, lane: .inbox, tabID: id)
        s.addTask(text: "Eggs", lane: .now, tabID: id)
        try await sync.sync(tabID: id)
        #expect(api.remote["a"]?.isCompleted == true)
        #expect(api.remote.values.contains { $0.title == "Eggs" })
        api.calls = []
        try await sync.sync(tabID: id)
        #expect(api.calls.isEmpty)  // nothing dirty -> no ping-pong
    }

    @Test func remoteEditWinsWhenNewer() async throws {
        let (s, sync, api, id) = await make()
        api.remote["a"] = GoogleTask(id: "a", title: "Milk", updated: Date(timeIntervalSinceNow: -100))
        try await sync.sync(tabID: id)
        api.remote["a"] = GoogleTask(id: "a", title: "Oat milk", updated: Date(timeIntervalSinceNow: 10))
        try await sync.sync(tabID: id)
        #expect(tab(s, id).tasks[.inbox]?.map(\.text) == ["Oat milk"])
    }

    @Test func remoteDeleteRemovesCleanLocalTask() async throws {
        let (s, sync, api, id) = await make()
        api.remote["a"] = GoogleTask(id: "a", title: "Milk", updated: Date(timeIntervalSinceNow: -100))
        try await sync.sync(tabID: id)
        api.remote["a"] = GoogleTask(id: "a", title: "Milk", updated: Date(), deleted: true)
        try await sync.sync(tabID: id)
        #expect(tab(s, id).tasks[.inbox]?.isEmpty == true)
    }

    @Test func localDeletePushedAsRemoteDelete() async throws {
        let (s, sync, api, id) = await make()
        api.remote["a"] = GoogleTask(id: "a", title: "Milk", updated: Date(timeIntervalSinceNow: -100))
        try await sync.sync(tabID: id)
        s.deleteTask(tab(s, id).tasks[.inbox]![0].id, lane: .inbox, tabID: id)
        try await sync.sync(tabID: id)
        #expect(api.remote["a"] == nil)
        #expect(tab(s, id).pendingDeletes.isEmpty)
    }

    @Test func offlineKeepsLocalEditsForNextSync() async throws {
        let (s, sync, api, id) = await make()
        s.addTask(text: "Eggs", lane: .now, tabID: id)
        api.failing = true
        await #expect(throws: URLError.self) { try await sync.sync(tabID: id) }
        #expect(tab(s, id).tasks[.now]?.count == 1)
        api.failing = false
        try await sync.sync(tabID: id)
        #expect(api.remote.values.contains { $0.title == "Eggs" })
    }

    @Test func disablingListKeepsTabAndUnlinks() async {
        let (s, sync, _, id) = await make()
        s.addTask(text: "Eggs", lane: .now, tabID: id)
        await sync.setList(GoogleTaskList(id: "L1", title: "Groceries"), enabled: false)
        #expect(tab(s, id).googleListID == nil)
        #expect(tab(s, id).tasks[.now]?.count == 1)
    }

    @Test func googleTabsDoNotCountTowardTabCap() async throws {
        let (s, _, _, _) = await make()
        for i in 0..<5 { s.addGoogleTab(named: "G\(i)", listID: "X\(i)") }
        try s.addTab(named: "B"); try s.addTab(named: "C"); try s.addTab(named: "D")  // Work + 3 = 4 local
        #expect(s.localTabCount == 4)
        #expect(throws: TabActionError.maximumTabsReached) { try s.addTab(named: "E") }
    }

    @Test func listsAutoCreateOnceAndDisabledStaysGone() async {
        let (s, _, api, _) = await make()
        let sync = GoogleTasksSync(appState: s, auth: GoogleAuth(clientID: nil), api: api)
        await sync.connectForTesting()
        #expect(s.store.tabs.filter { $0.googleListID == "L1" }.count == 1)  // existing tab reused
        await sync.setList(GoogleTaskList(id: "L1", title: "Groceries"), enabled: false)
        await sync.connectForTesting()
        #expect(s.store.tabs.filter { $0.googleListID == "L1" }.isEmpty)  // not recreated
    }

    @Test func syncIntervalDefaultsToDayAndPersistsChange() async {
        let (s, sync, _, _) = await make()
        #expect(s.store.settings.googleSyncInterval == 86400)
        sync.setSyncInterval(300)
        #expect(s.store.settings.googleSyncInterval == 300)
        s.setGoogleSyncInterval(5)
        #expect(s.store.settings.googleSyncInterval == 60)  // floored
    }

    @Test func completionNotYetSyncedSurvivesPurgeAndReachesGoogle() async throws {
        let (s, sync, api, id) = await make()
        api.remote["a"] = GoogleTask(id: "a", title: "Milk", updated: Date(timeIntervalSinceNow: -100))
        try await sync.sync(tabID: id)
        s.setRetentionDays(0)  // purge completed tasks immediately
        s.toggleTask(tab(s, id).tasks[.inbox]![0].id, lane: .inbox, tabID: id)
        s.sweepExpiredTasks()
        #expect(tab(s, id).tasks[.inbox]?.count == 1)  // not purged: Google hasn't heard yet
        try await sync.sync(tabID: id)
        #expect(api.remote["a"]?.isCompleted == true)
        s.sweepExpiredTasks()
        #expect(tab(s, id).tasks[.inbox]?.isEmpty == true)  // purged after it synced
    }
}

struct GoogleSecurityTests {
    @Test func idsCannotEscapeTheirPathSegment() {
        #expect(GoogleTasksClient.seg("a/../b?x=1") == "a%2F..%2Fb%3Fx=1")
    }

    @Test func idTokenEmailParses() {
        let payload = Data(#"{"email":"me@example.com"}"#.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
        #expect(GoogleAuth.email(fromIDToken: "h.\(payload).s") == "me@example.com")
    }
}
