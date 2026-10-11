import Foundation

/// A single to-do item within a lane.
///
/// `completedAt` doubles as both the "is this done" flag (nil == incomplete)
/// and the anchor for the countdown/auto-purge computation in
/// `RetentionPolicy` (spec: task-management, "Completed task retention countdown").
public struct TaskItem: Codable, Identifiable, Equatable {
    public let id: UUID
    public var text: String
    public var completedAt: Date?
    /// Position within its lane; lower sorts first.
    public var order: Int
    /// Optional due date/time. Purely informational (badge + overdue
    /// styling) -- setting or clearing it never affects `order` (spec:
    /// task-management, "Optional task deadline").
    public var dueDate: Date?

    /// Google Tasks id once linked (spec: google-tasks-sync); nil for purely local tasks.
    public var googleID: String?
    /// Last local or remote edit; drives last-write-wins sync.
    public var updatedAt: Date
    /// `updatedAt` as of the last time this task matched Google; a linked
    /// task is dirty (needs pushing) when `updatedAt` is newer.
    public var syncedAt: Date?

    public init(
        id: UUID = UUID(), text: String, completedAt: Date? = nil, order: Int, dueDate: Date? = nil,
        googleID: String? = nil, updatedAt: Date = Date(), syncedAt: Date? = nil
    ) {
        self.syncedAt = syncedAt
        self.id = id
        self.text = text
        self.completedAt = completedAt
        self.order = order
        self.dueDate = dueDate
        self.googleID = googleID
        self.updatedAt = updatedAt
    }

    // Custom decoding so a store.json written before sync existed (no
    // `googleID`/`updatedAt`) still loads instead of resetting all data.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        order = try c.decode(Int.self, forKey: .order)
        dueDate = try c.decodeIfPresent(Date.self, forKey: .dueDate)
        googleID = try c.decodeIfPresent(String.self, forKey: .googleID)
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .distantPast
        syncedAt = try c.decodeIfPresent(Date.self, forKey: .syncedAt)
    }

    public var isDone: Bool { completedAt != nil }
}
