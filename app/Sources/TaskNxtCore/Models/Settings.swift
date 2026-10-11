import Foundation

/// User-configurable preferences (spec: settings). Stored alongside tabs in
/// the same local JSON document — one file, one source of truth.
public struct Settings: Codable, Equatable {
    public var hotKey: HotKeyBinding
    public var launchAtLogin: Bool
    /// Days a completed task is retained before automatic purge (spec:
    /// task-management, "Completed task retention countdown"). Default 2.
    public var retentionDays: Int
    /// Restores the previously active tab across relaunches.
    public var lastActiveTabID: UUID?
    /// When true, tasks purged after their retention period elapses are
    /// moved to the archive instead of being permanently deleted (spec:
    /// settings, "Archive-completed-tasks toggle"). Default false so
    /// existing purge-and-forget behavior is unchanged unless opted in.
    public var archiveCompletedTasks: Bool
    /// Connected Google account's email, for display only (spec:
    /// google-tasks-sync). Credentials live in the Keychain, never here.
    public var googleAccountEmail: String?
    /// Google list ids already offered a tab, so a list the user disabled
    /// or whose tab they deleted is not auto-recreated.
    public var googleKnownListIDs: [String]
    /// Seconds between automatic Google syncs (spec: google-tasks-sync).
    public var googleSyncInterval: Int

    public init(
        hotKey: HotKeyBinding,
        launchAtLogin: Bool,
        retentionDays: Int,
        lastActiveTabID: UUID?,
        archiveCompletedTasks: Bool = false,
        googleAccountEmail: String? = nil,
        googleKnownListIDs: [String] = [],
        googleSyncInterval: Int = 86400
    ) {
        self.googleSyncInterval = googleSyncInterval
        self.googleAccountEmail = googleAccountEmail
        self.googleKnownListIDs = googleKnownListIDs
        self.hotKey = hotKey
        self.launchAtLogin = launchAtLogin
        self.retentionDays = retentionDays
        self.lastActiveTabID = lastActiveTabID
        self.archiveCompletedTasks = archiveCompletedTasks
    }

    public static let `default` = Settings(
        hotKey: .default,
        launchAtLogin: false,
        retentionDays: 2,
        lastActiveTabID: nil,
        archiveCompletedTasks: false
    )

    // Custom Codable so decoding a pre-existing `store.json` (written
    // before `archiveCompletedTasks` existed, so missing that key
    // entirely) defaults it to `false` instead of throwing -- a
    // non-Optional property with a synthesized Decodable would otherwise
    // fail the whole `Settings` decode, which cascades to `LocalStore`
    // discarding the user's tabs/tasks too (it falls back to first-launch
    // defaults on any decode error), not just resetting this one setting.
    private enum CodingKeys: String, CodingKey {
        case hotKey, launchAtLogin, retentionDays, lastActiveTabID, archiveCompletedTasks, googleAccountEmail, googleKnownListIDs, googleSyncInterval
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hotKey = try container.decode(HotKeyBinding.self, forKey: .hotKey)
        launchAtLogin = try container.decode(Bool.self, forKey: .launchAtLogin)
        retentionDays = try container.decode(Int.self, forKey: .retentionDays)
        lastActiveTabID = try container.decodeIfPresent(UUID.self, forKey: .lastActiveTabID)
        archiveCompletedTasks = try container.decodeIfPresent(Bool.self, forKey: .archiveCompletedTasks) ?? false
        googleAccountEmail = try container.decodeIfPresent(String.self, forKey: .googleAccountEmail)
        googleKnownListIDs = try container.decodeIfPresent([String].self, forKey: .googleKnownListIDs) ?? []
        googleSyncInterval = try container.decodeIfPresent(Int.self, forKey: .googleSyncInterval) ?? 86400
    }
}
