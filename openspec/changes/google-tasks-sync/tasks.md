## 1. Inbox lane and drag-and-drop

- [x] 1.1 Add `Lane.inbox` (first, display name "Inbox") and update lane switch sites
- [x] 1.2 Hide the Inbox lane in `LaneView`/tab view while empty
- [x] 1.3 Add `AppState.moveTask(id:to:before:)` using `CollectionMove`, with unit tests (reorder, cross-lane, empty lane, completion untouched)
- [x] 1.4 Add `.draggable`/`.dropDestination` to `TaskRowView` and lane containers (incl. empty lane and header)
- [x] 1.5 Verify old `store.json` still loads

## 2. Data model

- [x] 2.1 Add `TaskItem.googleID`, `TaskItem.updatedAt`; `AppTab.googleListID` and pending-delete tombstones; `Settings.googleAccountEmail`, all with decode defaults
- [x] 2.2 Update `updatedAt` on every local task edit in `AppState`
- [x] 2.3 Tests: decoding legacy store, round-trip new fields

## 3. Google auth

- [x] 3.1 Add `com.apple.security.network.client` to `TaskNxt.entitlements`
- [x] 3.2 Implement PKCE sign-in with `ASWebAuthenticationSession` (scope `tasks`), client ID constant
- [x] 3.3 Keychain store for refresh token; access-token refresh; disconnect clears Keychain
- [x] 3.4 Handle cancel, failure, and revoked credentials (reconnect state)

## 4. Google Tasks client and sync

- [x] 4.1 REST client: list task lists, list/insert/patch/delete tasks (`URLSession`, injectable for tests)
- [x] 4.2 Sync engine (actor): pull with `updatedMin`, push local changes and tombstones, last-write-wins, import new remote tasks into Inbox
- [x] 4.3 Enable list creates a tab; disable/delete-in-Google unlinks and keeps the tab
- [x] 4.4 Triggers: connect, launch, popover open, 5-minute timer; offline retries without losing edits
- [x] 4.5 Unit tests for sync merge with a fake client (remote add, local complete, conflict, remote delete, offline)

## 5. Settings UI

- [x] 5.1 Add Google Tasks section to `SettingsRootView`: connect/disconnect, account email, error/reconnect state
- [x] 5.2 Per-list enable/disable toggles, default off, refreshed after sync

## 6. Auto-created Google tabs

- [x] 6.1 Limit the 4-tab cap to local tabs (core + tab bar "+" state); let Google tabs bypass it
- [x] 6.2 Remember discovered list ids; auto-create tabs for new lists on sync, never for disabled/deleted ones
- [x] 6.3 Tab bar scrolls horizontally when many tabs exist
- [x] 6.4 Tests: cap counts local only; auto-create once; disabled list not recreated

## 7. Sync interval

- [x] 7.1 Add `Settings.googleSyncInterval` (default 1 day, decode default) and reschedule the timer on change
- [x] 7.2 Picker (1 min, 5 min, 15 min, 1 hour, 1 day; default 1 day) and "Sync Now" in the Google settings section
- [x] 7.3 Test: interval persists and legacy settings default to 1 day

## 8. Branding and docs

- [x] 8.1 Reword "zero accounts / 100% local / no network" copy (landing page, README, About text, CONTRIBUTING, SECURITY) to "local-first, optional Google Tasks"
- [x] 8.2 Add privacy policy and terms pages under `docs/`

## 9. Finish

- [x] 9.1 Update README with Google Cloud OAuth client setup
- [ ] 9.2 Manually verify connect, enable list, triage by drag, complete round-trip
