## Purpose

Defines multi-tab support: users organize tasks into up to four independent named tabs (e.g. Work, Personal), each owning its own set of lanes, with management operations to add, rename, reorder, and delete tabs.

## Requirements

### Requirement: Default tabs on first launch
On first launch (no existing local data), the system SHALL create a default set of tabs so the app is immediately usable. The default SHALL be a single tab named "Work".

#### Scenario: Fresh install shows default tab
- **WHEN** the app is launched for the first time with no prior local data
- **THEN** exactly one tab named "Work" exists and is selected, with all three lanes empty

### Requirement: Tab limit of four
The system SHALL allow a minimum of 1 and a maximum of 4 tabs at any time.

#### Scenario: Blocked from adding a 5th tab
- **WHEN** 4 tabs already exist
- **AND** the user attempts to add another tab
- **THEN** the system prevents creation and communicates that the 4-tab limit has been reached

#### Scenario: Blocked from deleting the last tab
- **WHEN** only 1 tab exists
- **AND** the user attempts to delete it
- **THEN** the system prevents deletion of the last remaining tab

### Requirement: Add a tab
The user SHALL be able to create a new tab with a user-supplied name, up to the 4-tab limit. A new tab starts with all three lanes empty.

#### Scenario: Add a second tab
- **WHEN** 1 tab exists
- **AND** the user creates a new tab named "Personal"
- **THEN** 2 tabs exist, with "Personal" having empty Now/Nxt/Ltr lanes

### Requirement: Rename a tab
The user SHALL be able to rename any existing tab. Renaming SHALL NOT affect the tab's tasks.

#### Scenario: Rename preserves tasks
- **WHEN** a tab named "Work" contains tasks
- **AND** the user renames it to "Projects"
- **THEN** the tab is now labeled "Projects" and all of its tasks remain unchanged

### Requirement: Delete a tab
The user SHALL be able to delete an existing tab (subject to the minimum-of-1 rule), permanently removing that tab and all of its tasks.

#### Scenario: Delete a tab removes its tasks
- **WHEN** the user deletes a tab that has 3 tasks across its lanes
- **THEN** the tab and all 3 tasks are permanently removed
- **AND** the remaining tabs are unaffected

### Requirement: Switch between tabs
The system SHALL display one tab's content at a time, with a tab selector showing all tabs and each tab's incomplete task count. Selecting a tab SHALL switch the visible lanes to that tab's tasks.

#### Scenario: Switch active tab
- **WHEN** "Work" tab is active and the user selects the "Personal" tab
- **THEN** the popover now shows Personal's Now/Nxt/Ltr lanes instead of Work's

### Requirement: Reorder tabs
The user SHALL be able to reorder tabs, and the tab order SHALL persist across app restarts.

#### Scenario: Reordered tabs persist
- **WHEN** the user reorders tabs so "Personal" appears before "Work"
- **AND** the app is restarted
- **THEN** "Personal" still appears before "Work" in the tab list
