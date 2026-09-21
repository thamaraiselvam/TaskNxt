## Why

Settings currently opens as a `.sheet` modal anchored to the popover -- it disappears the moment the popover closes, can't be worked in alongside the task list, and has no room to grow. Several requested additions (author/about info, version + bug-report links, a quit action) don't fit naturally into a cramped sheet, and the current flat list of controls (hotkey, toggle, stepper, tab management) has no organizing structure. This bundles those requests into one settings-architecture change, since they all depend on the same underlying surface.

## What Changes

- Replace the settings `.sheet` with a standalone `NSWindow`-backed settings window (macOS convention, like System Settings/most menu-bar utilities), opened from the gear icon. It has its own lifecycle: closing the popover does not close it, and it can be reopened without reopening the popover.
- Organize it with a sidebar (or segmented control, given the small size) with sections:
  - **General**: global hotkey, launch at login, completed-task retention, quit-the-app action.
  - **Tabs**: existing tab add/rename/reorder/delete (moved from the flat list into its own section).
  - **About**: app icon, version number, author/contact info, and links (report a bug, view source/changelog) -- consolidating the version label and bug-report affordance that would otherwise clutter the popover's footer.
- Popover footer stays minimal (task counts / hotkey hint); version + bug-report access moves entirely into About, keeping the popover focused on tasks.
- Add a "Quit TaskNxt" action in General settings (standard macOS placement for menu-bar-only apps per `menu-bar-shell`'s "Quitting the app removes the menu bar icon" scenario, which currently has no UI trigger).

## Capabilities

### New Capabilities
- `settings-about`: the About section's content (version display, author/contact info, bug-report/changelog links) -- kept distinct from `settings` since it's read-only informational content, not configuration.

### Modified Capabilities
- `settings`: "Settings entry point" requirement changes from "opens a settings view" (sheet) to "opens the settings window"; add a "Quit application" requirement; reorganize existing requirements to reference the General/Tabs sections.
- `menu-bar-shell`: the "Quitting the app" scenario gains a concrete trigger (the new Quit action in settings).

## Impact

- `app/Sources/TaskNxt/Features/Settings/SettingsView.swift` (becomes windowed, sectioned)
- `app/Sources/TaskNxt/Features/MenuBar/PopoverRootView.swift` (gear opens window instead of `.sheet`; footer simplified)
- `app/Sources/TaskNxt/App/AppDelegate.swift` (new settings-window controller/lifecycle, quit wiring)
- New "About" content/view
