## Why

We want a native macOS menu bar to-do app that is a functional clone of TodoNxt (todonxt.com): a minimalist, always-available task manager living in the menu bar with a Now/Nxt/Ltr priority model, multiple tabs, and 100% local storage. Unlike the original, this app will be free with no monetization, and will use its own icon/branding while keeping the same UI/UX design.

## What Changes

- New native SwiftUI macOS app (menu bar extra, no dock icon, no main window)
- Task organization into 3 fixed lanes per tab: **Now**, **Nxt**, **Ltr**
- Up to 4 user-defined tabs (lists), each with its own independent set of lanes
- Inline task creation ("+ add to now/nxt/ltr...") with click-to-type affordance
- Drag-and-drop reordering of tasks within a lane and between lanes (also across tabs)
- Task completion toggle; completed tasks show a countdown badge and are automatically purged after a configurable delay (default 2 days)
- Global keyboard shortcut to summon/dismiss the app popover from anywhere
- Light/Dark mode following system appearance
- Settings screen: hotkey configuration, launch-at-login toggle, tab management (add/rename/reorder/delete), completed-task retention period
- Fully local persistence — no accounts, no network calls, no analytics, no sync
- No purchase flow, no license gating, no auto-update mechanism (free, no monetization, no update server)
- Custom app icon distinct from the original TodoNxt icon; all other visual design (colors, layout, typography) mirrors the original

## Capabilities

### New Capabilities
- `menu-bar-shell`: The app's presence as a menu-bar-only process — icon, popover window, open/close behavior, global hotkey, no dock icon.
- `task-management`: Core task CRUD, lanes (Now/Nxt/Ltr), completion, auto-purge of completed tasks, drag-and-drop reordering.
- `tab-management`: Multiple named tabs (up to 4), each owning its own set of lanes; add/rename/reorder/delete tabs.
- `settings`: User-configurable preferences — global hotkey, launch-at-login, tab management surface, completed-task retention period, appearance.
- `local-persistence`: Local-only storage of all app data (tabs, tasks, settings) with no network/cloud dependency.

### Modified Capabilities
(none — greenfield project)

## Impact

- New Xcode project: SwiftUI macOS app target (macOS 13 Ventura+ deployment target), using `MenuBarExtra`.
- New local data store (JSON file or SwiftData, no CloudKit entitlement).
- New custom app icon asset (to be designed separately from the original TodoNxt icon).
- No backend, no third-party services, no payment integration.
