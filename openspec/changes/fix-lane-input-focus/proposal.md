## Why

Users report that clicking directly on the "+ add to nxt..." / "+ add to ltr..." inline text field sometimes fails to focus it (no cursor, no typing), while pressing Tab to reach the same field works. This is intermittent and lane-dependent, which points at a hit-testing or focus-arbitration gap rather than a logic bug -- worth root-causing before prescribing a fix.

## What Changes

- Reproduce reliably: capture whether failure correlates with (a) lane position (Nxt/Ltr vs Now), (b) popover just having opened vs. steady-state, (c) presence of existing tasks in the lane changing the field's on-screen position/frame.
- Root-cause candidates to evaluate: the "+" `Text` and `TextField` are separate views in an `HStack` without a shared `contentShape`, so the field's actual clickable frame may be narrower than its visible row; SwiftUI popover focus can also be stolen by a preceding view's first-responder claim on the frame right after open.
- Once root-caused, apply the minimal fix -- most likely making the entire "+ add to <lane>..." row one tappable hit target (`contentShape(Rectangle())` + explicit `isAddFieldFocused = true` on tap) so focus doesn't depend on hitting the native text-field glyph bounds exactly.
- No change to the add-task behavior itself (spec: `task-management`, "Inline task creation" already covers the intended UX).

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
(none -- bug fix only; behavior is already specified in `task-management`)

## Impact

- `app/Sources/TaskNxt/Features/Tasks/LaneView.swift` (add-task row hit-testing/focus)
- Needs manual repro/verification on-device since the trigger is intermittent; not easily unit-testable.
