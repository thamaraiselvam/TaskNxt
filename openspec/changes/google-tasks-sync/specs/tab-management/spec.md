## MODIFIED Requirements

### Requirement: Tab limit of four
The system SHALL allow a minimum of 1 tab in total, and a maximum of 4 local tabs. Tabs linked to a Google task list (see `google-tasks-sync`) SHALL NOT count toward the 4-tab maximum.

#### Scenario: Blocked from adding a 5th local tab
- **WHEN** 4 local tabs already exist (regardless of how many Google tabs exist)
- **AND** the user attempts to add another tab
- **THEN** the system prevents creation and communicates that the 4-tab limit has been reached

#### Scenario: Google tabs do not use up local slots
- **WHEN** 2 local tabs and 6 Google-linked tabs exist
- **AND** the user adds a local tab
- **THEN** the tab is created

#### Scenario: Blocked from deleting the last tab
- **WHEN** only 1 tab exists
- **AND** the user attempts to delete it
- **THEN** the system prevents deletion of the last remaining tab
