## ADDED Requirements

### Requirement: Pending-count badge on menu bar icon
The menu bar status item SHALL display the active tab's incomplete-task count as a badge/title alongside its icon.

#### Scenario: Badge shows active tab's count
- **WHEN** the active tab has 1 or more incomplete tasks
- **THEN** the menu bar icon displays that count

#### Scenario: Badge updates on task changes
- **WHEN** a task in the active tab is added, completed, un-completed, or deleted
- **THEN** the menu bar badge updates to reflect the active tab's new incomplete-task count without requiring the popover to reopen

#### Scenario: Badge updates on tab switch
- **WHEN** the user switches the active tab
- **THEN** the menu bar badge updates to show the newly active tab's incomplete-task count, not the previous tab's

#### Scenario: Badge hidden at zero
- **WHEN** the active tab has 0 incomplete tasks
- **THEN** the menu bar icon shows no badge/count (icon only)
