## 1. Settings toggle

- [x] 1.1 Add `archiveCompletedTasks: Bool` (default `false`) to the `Settings` model
- [x] 1.2 Add the "Keep an archive of completed tasks" toggle to the settings UI

## 2. Archive storage

- [x] 2.1 Add an `ArchivedTask` model (task snapshot + original tab/lane reference + `completedAt`)
- [x] 2.2 Add a persisted archive collection to `Store` / `LocalStore`
- [x] 2.3 Extend `RetentionPolicy`/`AppState.sweepExpiredTasks()` to branch: archive-and-remove-from-lane vs. hard-delete, based on the new setting

## 3. Archive view

- [x] 3.1 Add an entry point to the archive view (icon near tab bar, or a settings link) — implemented as a "View Archived Tasks…" link/sheet from the Settings view
- [x] 3.2 Build the list view grouped by completion date (most recent group first)
- [x] 3.3 Add empty-state messaging
- [x] 3.4 Wire "Restore" (back to original tab/lane, or active tab as fallback if original tab was deleted) and "Delete" (permanent removal) actions

## 4. Verification

- [x] 4.1 Manually verify: toggle off leaves current purge-and-forget behavior unchanged — verified via standalone harness against real `TaskNxtCore.o` (archiving disabled: task hard-deleted, archive stays empty) and added `sweepHardDeletesWhenArchivingDisabled` to `AppStateTests.swift`
- [x] 4.2 Manually verify: toggle on, let a task's retention elapse, confirm it appears in the archive grouped under the correct date — verified via harness (`sweepArchivesWhenArchivingEnabled`); grouping-by-date logic in `ArchiveView` is straightforward `Dictionary(grouping:)` over `completedAt`, exercised by construction (SwiftUI rendering itself needs on-device/Xcode confirmation since this sandbox's toolchain can't build the `TaskNxt` executable target)
- [ ] 4.3 Manually verify restore and permanent-delete paths from the archive — restore/delete logic itself is verified via harness and `AppStateTests.swift` (`restoreArchivedTaskReturnsItIncompleteToOriginalLane`, `deleteArchivedTaskRemovesItPermanently`); the on-screen button interactions in `ArchiveView` still need a real run in Xcode, which this sandbox cannot do
