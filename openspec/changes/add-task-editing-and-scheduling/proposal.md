## Why

Two gaps limit the task model's usefulness: (1) once created, a task's text can never be corrected or refined -- there is no edit path at all, only delete-and-recreate; (2) tasks have no notion of time (deadline/due date), so users can't see what's approaching or overdue. Both are natural extensions of the existing `task-management` capability.

## What Changes

- **Inline editing**: double-click a task's text to enter an inline edit mode (text becomes an editable field in place); Enter commits, Escape cancels, clicking away commits. Single click/tap is left alone (reserved for the existing checkbox/drag behaviors) so this doesn't conflict with drag-and-drop reordering.
- **Deadline field**: add an optional due date (date, optionally with time) to each task. Tasks with a due date show a small calendar-style badge; a due date in the past renders in a warning color (overdue). Manual drag-and-drop order is NOT changed by due dates -- this is a visual/informational addition only, not an auto-sort, to preserve the existing "Drag-and-drop reordering" requirement's guarantees.
- Due date is set/cleared via a small popover/date-picker reachable from the task row (e.g. clicking the calendar badge, or a control that appears alongside the delete "x" on hover).
- **BREAKING**: `TaskItem`'s persisted schema gains a new optional field; existing stored tasks without it must decode with a nil default (additive, non-breaking for storage, but called out since it touches `local-persistence`).

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `task-management`: add "Inline task text editing" requirement (double-click to edit, commit/cancel semantics) and "Optional task deadline" requirement (set/clear a due date, overdue visual indicator, no effect on manual ordering).
- `local-persistence`: note the additive schema change (new optional field, backward-compatible decode) if that capability's spec enumerates the persisted shape.

## Impact

- `app/Sources/TaskNxtCore/Models/TaskItem.swift` (new optional `dueDate: Date?`)
- `app/Sources/TaskNxt/Features/Tasks/TaskRowView.swift` (inline edit mode, due-date badge/picker)
- `app/Sources/TaskNxtCore/Persistence/LocalStore.swift` (decode compatibility for existing saved data)
