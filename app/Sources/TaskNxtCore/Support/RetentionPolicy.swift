import Foundation

/// Pure functions governing the completed-task countdown badge and
/// auto-purge behavior (spec: task-management, "Completed task retention
/// countdown"). Kept as free functions of `(completedAt, retentionDays,
/// now)` per design.md Decision 4, so they're trivially unit-testable and
/// need no timers of their own.
public enum RetentionPolicy {
    /// The moment a completed task becomes eligible for automatic removal.
    public static func purgeDate(completedAt: Date, retentionDays: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: retentionDays, to: completedAt)
            ?? completedAt.addingTimeInterval(TimeInterval(retentionDays) * 86400)
    }

    /// Whether a task completed at `completedAt` should have already been
    /// purged as of `now`, given `retentionDays`.
    public static func isExpired(completedAt: Date, retentionDays: Int, now: Date = Date()) -> Bool {
        now >= purgeDate(completedAt: completedAt, retentionDays: retentionDays)
    }

    /// A short human-readable countdown label (e.g. "2d", "1d", "<1d") for
    /// display on a completed task's row. Returns `nil` once the task is
    /// already expired (it should be purged rather than shown).
    public static func countdownLabel(completedAt: Date, retentionDays: Int, now: Date = Date()) -> String? {
        let purge = purgeDate(completedAt: completedAt, retentionDays: retentionDays)
        let remaining = purge.timeIntervalSince(now)
        guard remaining > 0 else { return nil }

        let days = Int(ceil(remaining / 86400))
        return days >= 1 ? "\(days)d" : "<1d"
    }
}
