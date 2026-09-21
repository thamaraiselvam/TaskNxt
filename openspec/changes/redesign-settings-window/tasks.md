## 1. Settings window shell

- [x] 1.1 Create a settings window controller (singleton, brings existing window to front if already open) hosting a SwiftUI root view
- [x] 1.2 Configure the window so closing it does not terminate the app (menu-bar-only app has no Dock icon / no other windows)
- [x] 1.3 Wire the popover's gear icon to open/activate this window instead of presenting `.sheet`
- [x] 1.4 Remove the now-unused `.sheet(isPresented:)` wiring from `PopoverRootView`

## 2. Navigation structure

- [x] 2.1 Build a sidebar/segmented navigation with General, Tabs, About sections
- [x] 2.2 Move existing hotkey recorder, launch-at-login toggle, and retention stepper into General
- [x] 2.3 Move `TabManagementView` into the Tabs section, adjusting layout for the new window sizing

## 3. Quit action

- [x] 3.1 Add a "Quit TaskNxt" button/action in General
- [x] 3.2 Wire it to `NSApplication.shared.terminate(_:)` (or equivalent), confirming the menu bar icon is removed on quit

## 4. About section

- [x] 4.1 Build the About view: app icon, version number (reuse existing version string source), author/contact info
- [x] 4.2 Add "Report a Bug" link (opens configured issue-tracker/mail destination)
- [x] 4.3 Add changelog/source link
- [x] 4.4 Remove the version label from the popover footer now that it lives in About

## 5. Verification

- [ ] 5.1 Manually verify: opening settings, closing the popover, confirming settings window stays open — code is structured so the settings `NSWindow` is fully independent of the `NSPopover` (separate `NSWindowController` singleton, own lifecycle, `applicationShouldTerminateAfterLastWindowClosed` returns `false`); an actual on-device run in Xcode is needed since this sandbox's toolchain can't launch the app (SwiftUI macro plugins unavailable)
- [ ] 5.2 Manually verify: clicking the gear icon again while settings is open brings the existing window forward (no duplicate windows) — `SettingsWindowController.show(appState:)` checks for an existing `window` and calls `makeKeyAndOrderFront` instead of creating a new one; needs on-device confirmation
- [ ] 5.3 Manually verify: Quit removes the menu bar icon and ends the process — wired to `NSApplication.shared.terminate(nil)`; needs on-device confirmation
- [ ] 5.4 Manually verify all three sections render correctly at the window's default size — `NavigationSplitView` sidebar + `Form`/`.formStyle(.grouped)` layouts used; whole `TaskNxt` target typechecks cleanly (`swiftc -typecheck` across all files shows zero non-macro-plugin errors), but actual rendering needs Xcode/on-device since this sandbox cannot build/run the SwiftUI executable target
