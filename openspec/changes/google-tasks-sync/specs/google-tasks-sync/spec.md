## Purpose

Connects a user's Google account so their Google Tasks lists can be chosen and synced into TaskNxt tabs, with newly imported tasks landing in the Inbox lane for triage.

## ADDED Requirements

### Requirement: Connect Google account
Settings SHALL provide a "Connect Google Tasks" action that signs the user in via Google's OAuth consent in the system browser/web session and requests only Google Tasks access plus the account email (for display). Credentials SHALL be stored in the macOS Keychain, never in `store.json`. The user SHALL be able to disconnect at any time.

#### Scenario: Successful connection
- **WHEN** the user activates "Connect Google Tasks" and approves access
- **THEN** Settings shows the connected account email and the list of Google task lists

#### Scenario: Consent cancelled or failed
- **WHEN** the user cancels or sign-in fails
- **THEN** the app remains disconnected and shows a brief error; no local data changes

#### Scenario: Disconnect
- **WHEN** the user disconnects
- **THEN** stored credentials are removed and syncing stops
- **AND** previously synced tabs and tasks remain as local data, no longer linked to Google

### Requirement: One tab per Google task list
When a Google list is first discovered (on connect or later), the system SHALL automatically create a tab named after the list and import its open tasks into that tab's Inbox lane. Settings SHALL list every Google task list with an enable/disable toggle, on by default for newly discovered lists. Disabling SHALL stop syncing that list and keep its tab as local data; the system SHALL NOT recreate a tab for a list the user has disabled or whose tab the user deleted. Google tabs SHALL NOT count toward the tab limit.

#### Scenario: Connect creates tabs
- **WHEN** the user connects an account with lists "Groceries" and "Work"
- **THEN** tabs "Groceries" and "Work" appear, each with that list's open tasks in its Inbox lane

#### Scenario: Disable a list
- **WHEN** the user disables "Groceries"
- **THEN** no further changes are exchanged with Google for that list
- **AND** the tab and its tasks remain locally and are not recreated on later syncs

#### Scenario: Re-enable a list
- **WHEN** the user enables a previously disabled list
- **THEN** a tab for it is created and its open tasks are imported into Inbox

#### Scenario: List added or removed in Google
- **WHEN** a sync finds a new Google list
- **THEN** a tab is created for it automatically
- **WHEN** a sync finds an enabled list was deleted in Google
- **THEN** its tab is kept as local data and unlinked

### Requirement: Two-way task sync
For enabled lists the app SHALL sync automatically on connect, on launch, when the popover opens, on demand via a "Sync Now" action, and automatically at a user-chosen interval while running. The interval options SHALL be every minute, 5 minutes, 15 minutes, hour, and day (default). Creating, renaming, completing/uncompleting, deleting, and changing the due date of a task on either side SHALL be reflected on the other. If both sides changed the same task, the most recent edit SHALL win. Lane and order are local-only and SHALL NOT be sent to Google.

#### Scenario: Remote task appears
- **WHEN** a task is added to an enabled list in Google Tasks
- **THEN** after the next sync it appears in that tab's Inbox lane

#### Scenario: Local completion pushed
- **WHEN** the user marks a synced task done in TaskNxt
- **THEN** the task is marked completed in Google Tasks

#### Scenario: Completion reaches Google promptly
- **WHEN** the user completes a synced task
- **THEN** the completion is sent to Google within a few seconds, regardless of the chosen sync interval
- **AND** auto-purge SHALL NOT remove the task until Google has received the completion

#### Scenario: Local task created in synced tab
- **WHEN** the user adds a task to any lane of a synced tab
- **THEN** it is created in the corresponding Google list and keeps its local lane

#### Scenario: Offline
- **WHEN** the network is unavailable
- **THEN** local edits still work and are pushed on the next successful sync; the app never loses a local edit

#### Scenario: Revoked access
- **WHEN** Google rejects the stored credentials
- **THEN** the app shows "Reconnect Google Tasks" in Settings and keeps all local data

### Requirement: Configurable sync interval
Settings SHALL let the user choose how often automatic sync runs (every minute, 5 minutes, 15 minutes, hour, or day). A change SHALL take effect immediately and persist across launches.

#### Scenario: Default interval
- **WHEN** a user connects for the first time
- **THEN** automatic sync runs once a day

#### Scenario: Change interval to daily
- **WHEN** the user selects "Every day"
- **THEN** automatic sync runs once per day from then on
- **AND** syncing on launch, popover open, and "Sync Now" still work
