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

    public init(id: UUID = UUID(), text: String, completedAt: Date? = nil, order: Int, dueDate: Date? = nil) {
        self.id = id
        self.text = text
        self.completedAt = completedAt
        self.order = order
        self.dueDate = dueDate
    }

    public var isDone: Bool { completedAt != nil }
}
