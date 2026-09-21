import Testing
import Foundation
@testable import TaskNxtCore

struct LocalStoreTests {
    private func tempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("store.json")
    }

    @Test func firstLaunchCreatesDefaultWorkTab() async throws {
        let store = LocalStore(fileURL: tempFileURL())
        let loaded = await store.load()

        #expect(loaded.tabs.count == 1)
        #expect(loaded.tabs.first?.name == "Work")
        #expect(loaded.settings.retentionDays == 2)
        #expect(loaded.settings.lastActiveTabID == loaded.tabs.first?.id)
        for lane in Lane.allCases {
            #expect(loaded.tabs.first?.tasks[lane]?.count == 0)
        }
    }

    @Test func saveThenLoadRoundTripsData() async throws {
        let url = tempFileURL()
        let store = LocalStore(fileURL: url)

        var initial = await store.load()
        var task = TaskItem(text: "Ship landing page", order: 0)
        initial.tabs[0].tasks[.now] = [task]
        try await store.save(initial)

        let reloaded = await store.load()
        #expect(reloaded.tabs[0].tasks[.now]?.first?.text == "Ship landing page")

        task.completedAt = Date()
        initial.tabs[0].tasks[.now] = [task]
        try await store.save(initial)

        let reloaded2 = await store.load()
        #expect(reloaded2.tabs[0].tasks[.now]?.first?.isDone ?? false)
    }

    @Test func corruptedFileFallsBackToDefaultsWithoutCrashing() async throws {
        let url = tempFileURL()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try Data("not valid json".utf8).write(to: url)

        let store = LocalStore(fileURL: url)
        let loaded = await store.load()

        #expect(loaded.tabs.count == 1)
        #expect(loaded.tabs.first?.name == "Work")
    }

    /// A `TaskItem` persisted before `dueDate` existed has no `dueDate` key
    /// in its JSON at all -- confirms decoding such older data still
    /// succeeds and defaults the new field to `nil` (spec:
    /// task-management, "Optional task deadline"; proposal.md's additive/
    /// backward-compatible schema note).
    @Test func decodingPreDueDateTaskDefaultsToNilDueDate() async throws {
        let url = tempFileURL()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        let taskID = UUID()
        let tabID = UUID()
        let json = """
        {
          "schemaVersion": 1,
          "tabs": [
            {
              "id": "\\(tabID.uuidString)",
              "name": "Work",
              "order": 0,
              "tasks": {
                "now": [
                  { "id": "\\(taskID.uuidString)", "text": "Legacy task", "order": 0 }
                ],
                "nxt": [],
                "ltr": []
              }
            }
          ],
          "settings": {
            "hotKey": { "keyCode": 12, "modifierFlags": 4096 },
            "launchAtLogin": false,
            "retentionDays": 2,
            "lastActiveTabID": "\\(tabID.uuidString)"
          }
        }
        """
        try Data(json.utf8).write(to: url)

        let store = LocalStore(fileURL: url)
        let loaded = await store.load()

        let task = try #require(loaded.tabs.first?.tasks[.now]?.first)
        #expect(task.text == "Legacy task")
        #expect(task.dueDate == nil)
    }
}
