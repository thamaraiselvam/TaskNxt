## Why

Users already keep to-dos in Google Tasks. TaskNxt is local-only, so they must retype everything. Connecting Google Tasks lets those items appear in TaskNxt and be triaged into Now/Nxt/Ltr. Task drag-and-drop is specced in `task-management` but not implemented, and triage needs it.

## What Changes

- Add a "Connect Google Tasks" flow (OAuth, one click, no manual token handling) in Settings.
- After connecting, every Google task list automatically becomes a tab, and Settings lists them with an enable/disable toggle (like choosing which calendars to show in Google Calendar).
- Google tabs do not count toward the 4-tab limit.
- Each enabled list's tab is named after the list; its tasks sync two ways (create, edit title, complete, delete, due date).
- Add a fourth lane, **Inbox**, for unclassified tasks. Newly synced Google tasks land in Inbox; the user moves them to Now/Nxt/Ltr.
- Implement drag-and-drop of tasks: reorder within a lane and move between lanes (incl. Inbox).
- **BREAKING**: "exactly three lanes" requirement becomes four lanes (Inbox + Now/Nxt/Ltr).
- The app now makes network calls: add the network-client sandbox entitlement.

## Capabilities

### New Capabilities
- `google-tasks-sync`: Google account connection, task-list selection, and two-way sync of tasks into tabs.

### Modified Capabilities
- `task-management`: add the Inbox lane (replaces "three fixed lanes"); tasks gain an optional remote link; drag-and-drop requirement extended to Inbox.
- `local-persistence`: "local-only", "no sign-in" and "no cloud sync" gain an explicit exception for the optional, user-initiated Google Tasks connection.
- `tab-management`: the 4-tab limit applies to local tabs only.
- `settings`: add a Google Tasks section (connect/disconnect, per-list toggles).

## Impact

- Code: `Lane`, `TaskItem`, `AppTab`, `Settings`, `AppState`, `LaneView`, `TaskRowView`, `SettingsRootView`; new `GoogleTasks` client/auth/sync files; `TaskNxt.entitlements`, `Info.plist` (URL scheme if needed).
- Dependencies: none added (URLSession, AuthenticationServices, Keychain).
- External: Google Tasks API, a Google Cloud OAuth client ID.
- Data: `store.json` gains optional fields; old files must still decode.
