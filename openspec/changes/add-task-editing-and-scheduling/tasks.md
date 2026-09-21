## 1. Data model

- [x] 1.1 Add `dueDate: Date?` to `TaskItem` with a default of `nil` in the memberwise initializer
- [x] 1.2 Add a decode-compatibility test/fixture confirming pre-existing persisted tasks (without the new key) load with `dueDate == nil` — added `decodingPreDueDateTaskDefaultsToNilDueDate` to `LocalStoreTests.swift`; verified by compiling+linking a standalone harness directly against the real `TaskNxtCore.o` build product (the `@Test`-based suite itself can't run in this sandbox's CommandLineTools-only toolchain — see fix-hotkey-display-and-row-hover notes). This also surfaced that `[Lane: [TaskItem]]` actually persists as a flat array of alternating key/value pairs, not a keyed JSON object as an existing code comment claims — a pre-existing, out-of-scope documentation inaccuracy (encode/decode are internally consistent, so it isn't a functional bug); the fixture was written to match the real on-disk format

## 2. Inline text editing

- [x] 2.1 Add edit-mode state to `TaskRowView` (e.g. `@State private var isEditing`, `@State private var draftText`)
- [x] 2.2 Add a double-click gesture on the task text that enters edit mode and seeds `draftText` with the current text
- [x] 2.3 Swap the static `Text` for a `TextField` while editing; wire Enter to commit and Escape to cancel — commit via `.onSubmit`, cancel via `.onExitCommand` (macOS Escape-key hook)
- [x] 2.4 Reject empty commits (revert to previous text) per spec scenario — enforced in `AppState.updateTaskText`
- [x] 2.5 Add `appState.updateTaskText(...)` (or equivalent) plumbing from row → `AppState` → `Store`

## 3. Deadline

- [x] 3.1 Add a calendar-badge affordance to `TaskRowView`, shown when `dueDate != nil` or on hover (to set one)
- [x] 3.2 Build a small date-picker popover (anchored to the badge) to set/clear the due date
- [x] 3.3 Style the badge distinctly when `dueDate < now` and the task is incomplete (overdue)
- [x] 3.4 Confirm setting/clearing a due date never mutates `order` (add a regression test if `AppState`/`Store` has task-order tests) — added `settingDueDatePreservesTaskOrder` and `updateTaskTextRejectsEmptyCommit` to `AppStateTests.swift`; functionally verified both (order preserved, due date set/cleared, empty commit rejected, non-empty commit applied) via a standalone harness compiled+linked against the real `TaskNxtCore.o` build product, since the `@Test` suite itself can't run in this sandbox (toolchain limitation noted throughout)

## 4. Verification

- [ ] 4.1 Manually verify edit/cancel/commit flows and overdue styling in both light and dark appearance — **requires running the app on-device**; this sandbox can't build the SwiftUI (`TaskNxt`) target (see fix-hotkey-display-and-row-hover notes). Logic-level behavior (commit/cancel/reject-empty/order-preservation) is verified per tasks above; only visual rendering in both appearances needs a real session
