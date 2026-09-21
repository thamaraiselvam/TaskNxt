## Context

Settings is currently `SettingsView`, presented via `.sheet(isPresented:)` from `PopoverRootView`, which is itself hosted inside an `NSPopover`. A sheet is scoped to its presenting view's lifecycle -- it cannot outlive the popover, and macOS sheets are modal-in-context (attached to their parent), not freestanding windows. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- Settings survives independently of the popover's open/closed state.
- A navigable structure (General / Tabs / About) that scales as more settings are added, instead of one flat `VStack`.
- Consolidate version/about/bug-report content in one discoverable place instead of scattering it across the popover footer.

**Non-Goals:**
- Redesigning the popover's own task-list UI (out of scope; only the gear icon's destination changes).
- Multi-window settings (e.g. detachable panes per section) -- one window with sidebar/segmented navigation is sufficient at this scale.
- Localization/accessibility audit of the new window (should follow existing app conventions, not introduce new ones).

## Decisions

- **Dedicated `NSWindow` (via `NSWindowController` or SwiftUI `Settings` scene / an `NSHostingController`-backed window), not `.sheet`**: matches standard macOS menu-bar-app convention (e.g. how most `NSStatusItem`-only apps present preferences), and is the only way to get a window that outlives the popover's `NSPopover` lifecycle.
- **Sidebar-style navigation** (`NavigationSplitView` with a small sidebar list, or a `TabView`/segmented control if the window is too narrow for a sidebar to look right) for General / Tabs / About: keeps each section focused and gives room to grow without one section crowding another.
- **Singleton window**: activating the gear icon while the settings window is already open brings it to front rather than opening a second instance -- avoids duplicate-window confusion.
- **About as its own capability (`settings-about`) rather than folded into `settings`**: it's read-only informational content (version, author, links), not user-configurable state, so it has a different "shape" of requirement (display + external links vs. toggles/steppers) worth tracking separately.
- **Quit lives in General, not a separate menu bar right-click item**: this app has no Dock icon and no menu bar left-click menu (the icon opens the popover) -- Settings is the only always-reachable surface for administrative actions, so Quit belongs there per the `menu-bar-shell` spec's existing "quit via Settings" scenario wording.

## Risks / Trade-offs

- [Risk] A second, independent window adds app lifecycle complexity (e.g. does closing it quit the app? No -- this is a menu-bar-only app with no Dock icon, so the standard "close last window quits app" behavior must be explicitly disabled for this window) → Mitigation: configure the settings window's behavior so closing it only hides/closes that window, never terminates the app; only the explicit Quit action or Cmd+Q does that.
- [Risk] Moving version/bug-report out of the popover footer could reduce their visibility for users who never open Settings → Mitigation: acceptable trade-off per the request; the gear icon remains a one-click path to About.
- [Risk] Existing `TabManagementView` assumes it's embedded in a sheet-sized `SettingsView`; moving it into a sidebar section may require it to adapt to a different available width/height → Mitigation: verify/adjust its layout constraints when relocating it into the Tabs section.
