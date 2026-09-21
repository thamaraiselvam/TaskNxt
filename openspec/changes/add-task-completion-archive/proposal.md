## Why

Completed tasks currently only exist briefly as a countdown badge before being permanently purged (per `task-management`'s retention policy) -- there is no way to look back at what was finished. Users want an optional archive view of completed tasks, each labeled with its completion date, without changing the existing auto-purge default behavior.

## What Changes

- Add a settings toggle, "Keep an archive of completed tasks" (default off, to preserve current lightweight behavior). When enabled, tasks are moved to a persistent archive (grouped/labeled by completion date) instead of being hard-deleted when their retention countdown elapses.
- Add an "Archived" view (reachable from the popover, e.g. a small clock/archive icon near the tab bar or from Settings) listing archived tasks grouped by day, read-only except for permanent delete and "restore to lane."
- When the archive toggle is off, behavior is unchanged from today: tasks are permanently purged after the retention period.

## Capabilities

### New Capabilities
- `task-archive`: viewing, grouping-by-completion-date, restoring, and permanently deleting archived tasks; the settings toggle that gates whether purge-eligible tasks are archived vs. hard-deleted.

### Modified Capabilities
- `task-management`: "Task auto-purged after retention period" scenario gains a branch -- when archiving is enabled, the task is moved to the archive instead of deleted.
- `settings`: add the archive-enable toggle as a new settings requirement.

## Impact

- `app/Sources/TaskNxtCore/Support/RetentionPolicy.swift` (branch: archive vs. delete on expiry)
- `app/Sources/TaskNxtCore/Models/Store.swift` / `LocalStore.swift` (new persisted archive collection)
- New view for the archive list (Features/Tasks or a new Features/Archive)
- `SettingsView.swift` (new toggle)
