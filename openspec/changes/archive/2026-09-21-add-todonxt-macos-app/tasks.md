## 1. Project Setup

- [x] 1.1 Create new Xcode project: macOS App target, SwiftUI lifecycle, deployment target macOS 13.0, `LSUIElement = true` in Info.plist (no Dock icon)
- [x] 1.2 Set up folder structure: `Sources/App`, `Sources/Models`, `Sources/Persistence`, `Sources/Features/{MenuBar,Tasks,Tabs,Settings}`, `Sources/Support`
- [x] 1.3 Add app icon asset catalog placeholder (final custom icon designed separately)
- [x] 1.4 Configure app name/bundle identifier distinct from original TodoNxt

## 2. Data Model & Persistence (local-persistence, task-management, tab-management foundations)

- [x] 2.1 Define `Codable` models: `Store` (schemaVersion, tabs, settings), `Tab` (id, name, order, lanes), `Lane` enum (now/nxt/ltr), `Task` (id, text, isDone, completedAt, order)
- [x] 2.2 Define `Settings` model: hotkey binding, launchAtLogin, retentionDays (default 2), lastActiveTabID
- [x] 2.3 Implement `LocalStore` actor: load/save JSON at `~/Library/Application Support/<AppName>/store.json`, atomic write (temp file + rename)
- [x] 2.4 Implement first-launch default-data creation: single "Work" tab, empty lanes
- [x] 2.5 Implement schemaVersion field and a no-op v1 migration path for future-proofing
- [x] 2.6 Unit tests: load/save round-trip, first-launch defaults, corrupted-file fallback behavior

## 3. Menu Bar Shell (menu-bar-shell)

- [x] 3.1 Implement menu bar shell hosting the root popover view (AppKit `NSStatusItem`+`NSPopover` per design.md Decision 1, not `MenuBarExtra` — needed for hotkey-driven external toggle)
- [x] 3.2 `LSUIElement`+`.accessory` activation policy set; click-to-open/close wired in `AppDelegate` (code-complete; not runtime-verified in this sandbox — see note below)
- [x] 3.3 Implement click-outside-to-dismiss behavior (`NSPopover.behavior = .transient`)
- [x] 3.4 Implement `GlobalHotKey` wrapper around Carbon `RegisterEventHotKey`/`InstallEventHandler` to toggle popover visibility
- [x] 3.5 Wire default hotkey binding and load/apply user-configured binding from `Settings`
- [x] 3.6 Popover uses standard SwiftUI/AppKit system appearance (no custom color scheme override), so it follows system light/dark mode live by default
- [ ] 3.7 Manual test: toggle popover via icon click and via global hotkey from another focused app — **blocked in this sandbox** (see limitations note; requires a running app on a licensed Xcode/normal Mac)

## 4. Task Management (task-management)

- [x] 4.1 Build `LaneView`: header (label, count), task rows, inline "+ add to <lane>..." control
- [x] 4.2 Implement inline task creation (text field commit on Enter, ignore empty input)
- [x] 4.3 Implement task row: checkbox toggle, strikethrough done style, manual delete action
- [x] 4.4 Implement completion timestamp set/clear on toggle
- [x] 4.5 Implement countdown badge computation (pure function of completedAt, retentionDays, now)
- [x] 4.6 Implement periodic sweep (on launch + every 60s) to purge expired completed tasks via `AppState`/`LocalStore`
- [x] 4.7 Implement drag-and-drop reordering within a lane (`DraggedTask` Transferable + `.draggable`/`.dropDestination`)
- [x] 4.8 Implement drag-and-drop moving tasks between lanes (same tab) preserving completion state
- [x] 4.9 Implement drag-and-drop moving tasks across tabs
- [x] 4.10 Compute and display per-lane and per-tab incomplete task counts
- [x] 4.11 Unit tests: countdown/purge pure functions, move-preserves-completion-state (`RetentionPolicyTests`, `AppStateTabTests` — 14/14 passing)

## 5. Tab Management (tab-management)

- [x] 5.1 Build tab selector UI showing all tabs with incomplete counts, active-tab highlighting (`TabBarView`)
- [x] 5.2 Implement add-tab flow with name input, enforce 4-tab maximum with user-facing message when blocked
- [x] 5.3 Implement rename-tab flow, preserving tasks
- [x] 5.4 Implement delete-tab flow, enforce minimum-of-1 with user-facing message when blocked, confirm destructive action
- [x] 5.5 Implement tab reordering (drag or up/down controls) with persisted order
- [x] 5.6 Implement switch-active-tab behavior, persist `lastActiveTabID`
- [x] 5.7 Unit tests: 4-tab max enforcement, 1-tab min enforcement, rename preserves tasks, delete removes tasks (`AppStateTabTests` — passing)

## 6. Settings (settings)

- [x] 6.1 Build settings view reachable via gear icon in popover (`SettingsView`)
- [x] 6.2 Implement hotkey recorder control; on change, re-register `GlobalHotKey`, reject conflicts with reserved system shortcuts
- [x] 6.3 Implement "Launch at Login" toggle using `SMAppService.mainApp`
- [x] 6.4 Implement retention-period (days) configuration control, applied to future purges only
- [x] 6.5 Embed tab management controls (add/rename/reorder/delete) within settings (`TabManagementView`)
- [x] 6.6 Unit tests: hotkey conflict rejection keeps previous binding (`GlobalHotKeyTests`); retention change doesn't resurrect already-purged tasks (`RetentionPolicyTests`) — passing

## 7. Local-Only Guarantees (local-persistence)

- [x] 7.1 Audited: no `URLSession`/network client code, no analytics SDKs, no CloudKit entitlements anywhere in the project
- [x] 7.2 Confirmed: no account/sign-in UI or auth-related code exists anywhere in the app
- [x] 7.3 App Sandbox entitlements limited to `app-sandbox` + `files.user-selected.read-write`; no network entitlement present
- [ ] 7.4 Manual test: full offline functional pass with network access disabled — **blocked in this sandbox**, requires a running built app

## 8. Polish & Validation

- [ ] 8.1 Verify light/dark mode visuals match original TodoNxt's color scheme — **blocked in this sandbox** (no running app); colors were coded to match the reference palette but not visually verified
- [ ] 8.2 Verify app footer/version display and remaining chrome matches the reference design — **blocked in this sandbox**
- [ ] 8.3 Full manual regression pass against all spec scenarios — **blocked in this sandbox**; all scenarios implemented and code-reviewed against specs, but require a running app to execute
- [x] 8.4 Replace placeholder icon with final custom app icon asset (custom-generated 10-size `.appiconset` + `Contents.json`)
- [x] 8.5 Run `openspec validate --change add-todonxt-macos-app --strict` and fix any reported issues — validated clean
