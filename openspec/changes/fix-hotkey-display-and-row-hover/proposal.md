## Why

Two visible bugs undermine trust in core surfaces: (1) the hotkey recorder shows raw numeric fallbacks like "Key 17" for any key outside a ~9-entry lookup table (e.g. Cmd+Shift+T), and (2) the per-task delete ("x") affordance appears/disappears erratically on hover because its presence changes the row's layout, which in turn changes whether the cursor is still "hovering" -- a self-referential flicker loop. Both are pure bug fixes with no new behavior.

## What Changes

- Replace the ~9-key `KeyCodeNames` lookup with a complete macOS virtual-keycode -> display-name table covering all standard alphanumeric, punctuation, and function keys, so any recordable shortcut renders its real symbol/letter instead of "Key N".
- Reserve a fixed-width slot for the row's delete control at all times (present but invisible/non-interactive when not hovering) instead of conditionally inserting it into the layout, so showing/hiding it never shifts row content or re-triggers the hover boundary.
- Keep existing `.onHover` semantics (hover row -> show delete control) and existing keyboard-shortcut-conflict rejection behavior unchanged.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
(none -- both are implementation-level bug fixes; the `settings` spec's "Configurable global hotkey" and `task-management`'s "Manual task deletion" scenarios already describe the intended user-visible behavior, which this change makes actually work as specified)

## Impact

- `app/Sources/TaskNxt/Features/Settings/HotKeyRecorderView.swift` (`KeyCodeNames`)
- `app/Sources/TaskNxt/Features/Tasks/TaskRowView.swift` (hover/delete-button layout)
- No data model or persistence changes.
