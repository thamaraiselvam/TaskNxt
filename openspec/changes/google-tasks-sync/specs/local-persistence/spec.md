## MODIFIED Requirements

### Requirement: Local-only data storage
All application data (tabs, lanes, tasks, settings) SHALL be persisted to local on-device storage and the app SHALL be fully usable offline. The system SHALL NOT transmit this data to any network endpoint, with one exception: after the user explicitly connects Google Tasks, the tasks of the lists the user has enabled MAY be exchanged directly with Google (see `google-tasks-sync`).

#### Scenario: No network calls for data operations
- **WHEN** the user has not connected Google Tasks
- **AND** creates, edits, completes, or deletes a task, tab, or setting
- **THEN** no network request is made as part of persisting that change

#### Scenario: Only enabled Google lists are exchanged
- **WHEN** the user has connected Google Tasks and enabled some lists
- **THEN** only those lists' tasks are sent to or received from Google, and nothing is sent to any other endpoint

### Requirement: No account or sign-in required
The system SHALL NOT require account creation, sign-in, or any authentication to use any feature, except that connecting Google Tasks (an optional feature) requires signing in to Google.

#### Scenario: Full functionality without sign-in
- **WHEN** the app is launched for the first time
- **THEN** the user can create tabs and tasks and use all features other than Google Tasks sync without being prompted to sign in or create an account

### Requirement: No cloud sync
The system SHALL NOT operate or depend on any developer-run cloud service, and SHALL NOT sync data across devices by default. The only sync is the optional Google Tasks connection the user initiates; lane and order are never sent to Google.

#### Scenario: No sync by default
- **WHEN** the same user runs the app on a second Mac without connecting Google Tasks
- **THEN** tasks created on the first Mac do not appear on the second Mac

#### Scenario: Optional sync through the user's Google account
- **WHEN** the user connects the same Google account on a second Mac and enables a list
- **THEN** that list's tasks appear in the Inbox lane there, with lanes and order not carried over
