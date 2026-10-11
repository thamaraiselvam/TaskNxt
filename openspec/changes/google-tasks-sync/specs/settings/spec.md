## ADDED Requirements

### Requirement: Google Tasks settings section
The settings view SHALL include a Google Tasks section showing connection state, a connect/disconnect control, and, when connected, the account email and a toggle per Google task list (see `google-tasks-sync`).

#### Scenario: Not connected
- **WHEN** the user opens the Google Tasks section without a connected account
- **THEN** a "Connect Google Tasks" button is shown and no lists are shown

#### Scenario: Connected with several lists
- **WHEN** the account has multiple task lists
- **THEN** each is shown with its own enable/disable toggle
