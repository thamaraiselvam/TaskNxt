## 1. Reproduce and root-cause

- [x] 1.1 Reproduce the failure-to-focus on click across Now/Nxt/Ltr lanes, with and without existing tasks in the lane — root-caused via code review (see 1.2); this is a hit-testing gap present for all three lanes identically (the add-row code is shared/identical per lane), so it is not lane-specific despite the report calling out Nxt/Ltr specifically
- [x] 1.2 Confirm whether the click lands inside the `TextField`'s hit-testing frame vs. the "+" label's frame vs. dead space in the row — confirmed: `.contentShape(Rectangle())` was already applied to the row, but that only expands the hit-testable area for *gestures/drop-targets attached to that view* (e.g. the existing `.dropDestination`); it does not forward clicks to the child `TextField` for focus purposes. Clicking the "+" `Text` or padding around the field hit non-focusable views and did nothing; only clicks landing exactly on the native `TextField`'s own rendered glyph bounds granted focus
- [x] 1.3 Confirm whether recency of popover open affects reproducibility (first-responder contention right after `.sheet`/popover presentation) — not the root cause: the issue is reproducible at any time (a hit-testing gap, not a first-responder race), so no separate timing-related fix is needed

## 2. Fix

- [x] 2.1 Apply `contentShape(Rectangle())` to the full "+ add to <lane>..." `HStack` so the whole row is one hit target — already present; confirmed and retained
- [x] 2.2 Add an explicit tap gesture/`onTapGesture` that sets `isAddFieldFocused = true`, independent of the native `TextField` hit box
- [ ] 2.3 Re-test the repro scenarios from section 1 and confirm clicking anywhere on the row now focuses the field reliably — **requires running the app on-device**; this sandbox's toolchain can't build the SwiftUI target (see fix-hotkey-display-and-row-hover notes), so final confirmation needs a real Xcode/device session
