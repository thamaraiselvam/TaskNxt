## Context

TaskNxt is a sandboxed SwiftUI/AppKit menu-bar app; state lives in `AppState` (TaskNxtCore, no SwiftUI) persisted to `store.json` via `LocalStore`. It currently makes no network calls. Tasks have `order`, `completedAt`, `dueDate`; `Lane` is a fixed 3-case enum. Task drag-and-drop exists only in spec; only tab reordering uses `.onMove`.

## Goals / Non-Goals

**Goals:** one-click Google connect; per-list enable; two-way sync of core fields; Inbox lane; task drag-and-drop.

**Non-Goals:** subtasks, Google task notes/links, multiple Google accounts, push/webhook sync (polling only), syncing lane/order to Google, Google Calendar.

## Decisions

- **OAuth: installed-app flow with PKCE via `ASWebAuthenticationSession`**, scope `tasks`. No client secret needed for the iOS/desktop client type; the client ID is a build-time constant. Alternative: loopback HTTP server (more code, port handling). Tokens (refresh token) in Keychain; access token in memory.
- **Raw REST via `URLSession`** (`tasklists`, `tasks` with `updatedMin`, `showCompleted`, `showDeleted`). Avoids a Google SDK dependency. Needs `com.apple.security.network.client` entitlement.
- **Each enabled list = one tab.** Reuses existing tab UI and avoids inventing a list-to-lane mapping. `AppTab` gains optional `googleListID`; `Settings` gains `googleAccountEmail` and enabled list IDs (derivable from tabs with `googleListID`, so only the email is stored).
- **Inbox lane = new `Lane.inbox` case, first in `allCases`.** Remote-imported tasks go to Inbox; locally created tasks go to the lane they were added in. Since lane has no Google counterpart, existing remote tasks keep their local lane after first import.
- **TaskItem gains `googleID: String?` and `updatedAt: Date`.** Sync matches by `googleID`; conflicts resolved last-write-wins on `updatedAt` vs Google `updated`. Local deletions of linked tasks are recorded as tombstones (`pendingDeletes` per tab) until pushed. All new fields decode with defaults so old `store.json` still loads (same approach as `Settings.archiveCompletedTasks`).
- **Sync trigger:** on connect, launch, popover open, and a 5-minute timer; a single in-flight sync guarded by an actor. Local edits mark the tab dirty and push on the next sync.
- **Drag-and-drop:** SwiftUI `.draggable(task.id)` / `.dropDestination` on rows and on lane containers, calling one `AppState.moveTask(id:to:before:)` that reuses `CollectionMove`. Native `List.onMove` does not cross lanes, so it is not used.
- **Lane enum change:** unknown-case-safe decoding is unnecessary (new case only added), and the Inbox is hidden when empty, so non-synced users see no change.

## Risks / Trade-offs

- [Google Cloud OAuth client must be created and verified for production use of the `tasks` scope] → ship with a client ID constant, document setup in README; unverified apps are limited to 100 test users.
- [Last-write-wins can overwrite a concurrent edit] → acceptable for single-user to-dos; only title/done/due are affected.
- [Clock skew between device and Google] → compare against Google's `updated` only when the remote changed since last sync (`updatedMin`), otherwise local wins.
- [Deleted-remote vs edited-local conflict] → local edit wins and the task is re-created.
- [Refresh token revoked] → surface "Reconnect", never wipe local data.
- [Polling uses API quota] → one list call plus one `tasks` call per enabled list per 5 minutes is far below quota.
