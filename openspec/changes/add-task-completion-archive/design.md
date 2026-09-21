## Context

Today, `RetentionPolicy` (see proposal.md) computes a countdown from `TaskItem.completedAt` and, once elapsed, `AppState.sweepExpiredTasks()` (called on popover appear) permanently removes the task from its lane's array in `Store`. There is no persisted concept of "removed but kept" data.

## Goals / Non-Goals

**Goals:**
- Add an opt-in archive that captures a task at the moment it would otherwise be purged, grouped by completion date.
- Preserve today's default behavior (hard delete) unchanged when the new toggle is off.

**Non-Goals:**
- Search/filter within the archive, or archive size limits/pagination.
- Archiving manually-deleted tasks (manual delete stays a hard delete, unchanged from `task-management`'s "Manual task deletion" requirement).

## Decisions

- **Archive is a separate persisted collection, not a flag on `TaskItem`**: keeps `Store`'s active-lane arrays (used for counts, drag-and-drop, sweep) free of archived entries, avoiding filtering logic sprinkled through every existing task query.
- **Branch point is `sweepExpiredTasks()`**: rather than adding a new sweep path, the existing purge sweep is extended to either delete or append-to-archive based on `settings.archiveCompletedTasks`, keeping one code path for "what happens when retention elapses."
- **Grouping by completion date is a presentation concern**: the archive stores each entry with its original `completedAt`; the view groups/sorts by that timestamp rather than storing pre-grouped data.
- **Manual delete from the archive is a hard delete** (no "archive of an archive"), consistent with `task-management`'s existing manual-delete semantics.

## Risks / Trade-offs

- [Risk] Turning archiving on/off doesn't retroactively affect tasks already mid-countdown → Mitigation: match the existing precedent in `settings`' "Retention change does not affect already-elapsed tasks" scenario — document that the toggle only affects tasks purged *after* the change, no silent reclassification.
- [Risk] Unbounded archive growth over long-term use → Mitigation: out of scope for this change; note as a follow-up if it becomes a real problem (e.g. an archive retention cap), not solved here.
- [Risk] Restoring a task whose original tab/lane no longer exists (tab deleted) → Mitigation: restore into the current active tab's matching lane as a fallback, since lanes are fixed per tab but tabs are deletable.
