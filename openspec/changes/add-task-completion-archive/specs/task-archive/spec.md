## Purpose

Lets users optionally retain a browsable history of completed tasks, grouped by completion date, instead of having them permanently purged when their retention countdown elapses.

## ADDED Requirements

### Requirement: Archive view of completed tasks
When archiving is enabled (see `settings`), the system SHALL provide a view listing archived tasks grouped by completion date.

#### Scenario: Open the archive view
- **WHEN** the user opens the archive view
- **THEN** previously archived tasks are shown, grouped under headings for the date each was completed

#### Scenario: Empty archive
- **WHEN** the user opens the archive view and no tasks have been archived yet
- **THEN** an empty-state message is shown instead of an empty list

### Requirement: Restore an archived task
The user SHALL be able to restore an archived task back to its original lane as an incomplete task.

#### Scenario: Restore from archive
- **WHEN** the user chooses "Restore" on an archived task
- **THEN** the task reappears, incomplete, in its original tab and lane
- **AND** it is removed from the archive

### Requirement: Permanently delete an archived task
The user SHALL be able to permanently delete an archived task at any time.

#### Scenario: Delete from archive
- **WHEN** the user chooses "Delete" on an archived task
- **THEN** the task is immediately and permanently removed from the archive
