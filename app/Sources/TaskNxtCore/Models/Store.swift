import Foundation

/// The root document persisted to `store.json`. `schemaVersion` exists from
/// day one so a future format change has a clean migration seam (design.md,
/// Decision 3 & Risk: "no built-in migration framework").
public struct Store: Codable, Equatable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var tabs: [AppTab]
    public var settings: Settings
    /// Completed tasks archived instead of hard-deleted, when
    /// `settings.archiveCompletedTasks` is enabled (spec: task-archive).
    public var archivedTasks: [ArchivedTask]

    public init(
        schemaVersion: Int = Store.currentSchemaVersion,
        tabs: [AppTab],
        settings: Settings,
        archivedTasks: [ArchivedTask] = []
    ) {
        self.schemaVersion = schemaVersion
        self.tabs = tabs
        self.settings = settings
        self.archivedTasks = archivedTasks
    }

    /// First-launch default data: a single "Work" tab with empty lanes
    /// (spec: tab-management, "Default tabs on first launch").
    public static func firstLaunchDefault() -> Store {
        let work = AppTab(name: "Work", order: 0)
        var settings = Settings.default
        settings.lastActiveTabID = work.id
        return Store(tabs: [work], settings: settings)
    }

    // Custom Codable for the same reason as `Settings`: a store.json
    // written before `archivedTasks` existed has no such key at all, and a
    // non-Optional `[ArchivedTask]` with synthesized Decodable would throw
    // on that missing key -- defaulting to `[]` here keeps old data
    // loading exactly as before.
    private enum CodingKeys: String, CodingKey {
        case schemaVersion, tabs, settings, archivedTasks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        tabs = try container.decode([AppTab].self, forKey: .tabs)
        settings = try container.decode(Settings.self, forKey: .settings)
        archivedTasks = try container.decodeIfPresent([ArchivedTask].self, forKey: .archivedTasks) ?? []
    }
}
