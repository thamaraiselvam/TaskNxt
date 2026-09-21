import Foundation

/// A completed task moved out of its lane after its retention countdown
/// elapsed, kept for browsing/restoring instead of being permanently
/// deleted (spec: task-archive, "Archive view of completed tasks"). Only
/// created when `settings.archiveCompletedTasks` is enabled.
public struct ArchivedTask: Codable, Identifiable, Equatable {
    public let id: UUID
    public var text: String
    /// When the task was originally completed -- the archive is grouped
    /// by this date (spec: task-archive).
    public var completedAt: Date
    public var dueDate: Date?
    /// The tab/lane the task lived in before being archived, used to
    /// restore it to the same place. The tab may since have been deleted;
    /// callers fall back to the current active tab in that case (spec:
    /// task-archive, "Restore an archived task").
    public var originalTabID: UUID
    public var originalLane: Lane

    public init(
        id: UUID = UUID(),
        text: String,
        completedAt: Date,
        dueDate: Date? = nil,
        originalTabID: UUID,
        originalLane: Lane
    ) {
        self.id = id
        self.text = text
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.originalTabID = originalTabID
        self.originalLane = originalLane
    }

    public init(from task: TaskItem, tabID: UUID, lane: Lane, completedAt: Date) {
        self.init(
            id: task.id,
            text: task.text,
            completedAt: completedAt,
            dueDate: task.dueDate,
            originalTabID: tabID,
            originalLane: lane
        )
    }
}
