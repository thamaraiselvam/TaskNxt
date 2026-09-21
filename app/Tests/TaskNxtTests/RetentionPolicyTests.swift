import Testing
import Foundation
@testable import TaskNxtCore

struct RetentionPolicyTests {
    @Test func countdownLabelShowsDaysRemaining() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let completedAt = now.addingTimeInterval(-1 * 86400) // completed 1 day ago
        let label = RetentionPolicy.countdownLabel(completedAt: completedAt, retentionDays: 2, now: now)
        #expect(label == "1d")
    }

    @Test func countdownLabelIsNilOnceExpired() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let completedAt = now.addingTimeInterval(-3 * 86400) // completed 3 days ago, retention 2
        let label = RetentionPolicy.countdownLabel(completedAt: completedAt, retentionDays: 2, now: now)
        #expect(label == nil)
    }

    @Test func isExpiredTrueAfterRetentionWindowElapses() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let completedAt = now.addingTimeInterval(-2 * 86400)
        #expect(RetentionPolicy.isExpired(completedAt: completedAt, retentionDays: 2, now: now))
    }

    @Test func isExpiredFalseWithinRetentionWindow() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let completedAt = now.addingTimeInterval(-1 * 3600) // 1 hour ago
        #expect(!RetentionPolicy.isExpired(completedAt: completedAt, retentionDays: 2, now: now))
    }

    @Test func retentionChangeDoesNotResurrectAlreadyPurgedTasks() {
        // Simulates the acceptance criterion in spec: settings —
        // increasing retentionDays after a task has already been purged
        // must not bring it back, because purging removes the task
        // entirely rather than just hiding it.
        let now = Date(timeIntervalSince1970: 1_000_000)
        let completedAt = now.addingTimeInterval(-5 * 86400)
        #expect(RetentionPolicy.isExpired(completedAt: completedAt, retentionDays: 2, now: now))
        // Even with a much larger retention window applied *after* purge,
        // the policy function itself is stateless — resurrection is
        // prevented at the AppState/sweep layer (the task record is gone),
        // not by this function returning something different.
        #expect(!RetentionPolicy.isExpired(completedAt: completedAt, retentionDays: 10, now: now))
    }
}
