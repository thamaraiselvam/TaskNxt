## Context

`TaskItem` (see proposal.md) is currently a flat, append-only struct: `text` is set once at creation and never mutated, and there is no time-based field at all. `TaskRowView` renders text as a static `Text`; `LaneView` owns the only editable `TextField` (the add-task input). See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- Let a task's text be corrected in place.
- Let a task carry an optional due date that is purely informational (badge + overdue styling), never affecting sort order.

**Non-Goals:**
- Recurring tasks, reminders/notifications, or calendar integration.
- Auto-sorting or auto-promoting tasks by due date (explicitly excluded to preserve the existing manual drag-and-drop ordering guarantee).
- Editing a task's lane or completion state from the edit field (unchanged, handled by existing checkbox/drag affordances).

## Decisions

- **Double-click to edit, not single-click**: a single click is already free real estate reserved for potential future selection semantics, and using double-click avoids any ambiguity with the drag gesture (`draggable(...)`) already attached to the row, which begins on a single click-and-hold.
- **`dueDate: Date?` on `TaskItem`**: mirrors the existing `completedAt: Date?` optional-as-flag pattern already used in the model, keeping the type additive and `Codable`-compatible (decodes to `nil` for existing persisted tasks missing the key).
- **Due-date editor as a popover anchored to a small calendar badge**, consistent with the existing lightweight popover pattern used for "add tab" in `TabBarView`, rather than introducing a new modal/sheet.
- **No reordering on due-date change**: due dates are rendered as an informational badge only; `order` is untouched by any due-date mutation, preserving the `task-management` "Drag-and-drop reordering" requirement's guarantees unmodified.

## Risks / Trade-offs

- [Risk] Double-click may be undiscoverable (no visible affordance hints at edit) → Mitigation: show a pencil/edit cursor on hover over the text, matching the existing hover-reveals-delete-control pattern already in the row.
- [Risk] Adding a field to `TaskItem` requires confirming `LocalStore`'s decode path tolerates a missing key from older persisted data → Mitigation: `dueDate` is declared as `Date?` with no explicit `CodingKeys` requirement, which `Codable` synthesizes as optional-safe by default; add a decode test with a fixture missing the field.
