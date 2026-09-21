## Why

The menu bar icon currently gives no at-a-glance signal of pending work -- users must open the popover to see counts. Since tabs already track incomplete-task counts, surfacing the active tab's count directly on the menu bar icon (as macOS status-item text) closes that gap cheaply.

## What Changes

- The menu bar status item displays the currently-active tab's incomplete-task count as a small numeric badge/title next to (or on) the icon.
- The badge updates live when: a task is added/completed/deleted in the active tab, or the user switches to a different tab (badge reflects the newly active tab's count, not a global total).
- If the count is 0, the badge is hidden (icon-only), matching common menu-bar conventions for unread/pending counts.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `menu-bar-shell`: add a "Pending-count badge on menu bar icon" requirement describing the above scenarios (updates on task changes, updates on active-tab switch, hidden at zero).

## Impact

- `app/Sources/TaskNxt/App/AppDelegate.swift` (status item title/attributed title updates)
- `app/Sources/TaskNxtCore/AppState.swift` (expose active tab's incomplete count as an observable the status item can bind to)
