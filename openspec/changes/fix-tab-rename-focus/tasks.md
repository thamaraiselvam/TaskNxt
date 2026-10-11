## 1. Fix TabRow rename

- [x] 1.1 Add `@FocusState` to `TabRow` and focus the field in `.onAppear` via `DispatchQueue.main.async`
- [x] 1.2 Commit on focus loss (`.onChange` of focus, only while `isEditing`)
- [x] 1.3 Cancel on Escape (`.onExitCommand`) without committing the draft
- [x] 1.4 Give the Rename button a full-area hit target (`.contentShape` + padding)

## 2. Verification

- [x] 2.1 Build the `TaskNxt` target — builds cleanly with full Xcode (`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build`)
- [x] 2.2 Manually verify in Settings → Tabs: focus on Rename, Enter commits, click-away commits, Escape cancels, empty name keeps old name
