## Context

`TabRow` in `TabManagementView.swift` toggles between `Text` + Rename button and a `TextField` using `isEditing`. `TaskRowView` solved the identical problem in `31b0bc3`: focus requested in the same update that inserts the field is dropped, so focus must be set after the field appears. See proposal.md.

## Goals / Non-Goals

**Goals:** make rename work reliably using the pattern already in `TaskRowView`.

**Non-Goals:** rename from the popover tab bar; a shared inline-edit component; changes to `AppState.renameTab`.

## Decisions

- **Mirror `TaskRowView`**: `@FocusState`, `.onAppear { DispatchQueue.main.async { focused = true } }`, `.onChange(of: focused)` to commit on blur, `.onExitCommand` to cancel. Consistent with existing code and proven for the same bug. Alternative: extract a shared view — rejected as more code for two call sites.
- **Keep empty-name handling** in `commitRename` (falls back to current name); `renameTab` unchanged.
- **Guard against double commit**: Enter sets `isEditing = false` before the blur `onChange` fires, and the blur handler only commits while `isEditing` is true. Escape also clears `isEditing` first, so the resulting blur does not commit the draft.
- **Hit area**: `.contentShape(Rectangle())` plus small padding on the Rename button label, as done in `ef50c31`.

## Risks / Trade-offs

- Focus timing is only verifiable in the running app → manual check task. The SwiftUI target can't be built in some sandboxes; verify with a real build.
