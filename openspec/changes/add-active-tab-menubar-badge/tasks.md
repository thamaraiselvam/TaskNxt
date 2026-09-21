## 1. Expose active-tab count

- [x] 1.1 Add/confirm an observable property on `AppState` for the active tab's incomplete-task count — added `activeTabIncompleteCount`; verified it compiles via `swift build --target TaskNxtCore`
- [x] 1.2 Ensure it updates whenever tasks change or the active tab switches — it's computed directly from the existing `@Published var store` / `@Published var activeTabID`, both of which already fire `objectWillChange` on every mutation path (`addTask`, `toggleTask`, `deleteTask`, `moveTask`, `setActiveTab`, etc.), so no extra publishing plumbing was needed

## 2. Status item badge

- [x] 2.1 Bind `NSStatusItem.button`'s title/attributed title to the active-tab count from `AppDelegate` — subscribed to `appState.objectWillChange` in `applicationDidFinishLaunching`, updating the button title on each change
- [x] 2.2 Hide the badge (icon-only) when the count is 0 — `updateBadge()` sets an empty title and `.imageOnly` position when count is 0
- [ ] 2.3 Manually verify the badge updates live: adding/completing/deleting tasks, and switching tabs, all while the popover is open and closed — **requires running the app on-device**; this sandbox can't build the SwiftUI/AppKit (`TaskNxt`) target (see fix-hotkey-display-and-row-hover notes for the toolchain limitation)
