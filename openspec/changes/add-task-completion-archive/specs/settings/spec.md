## ADDED Requirements

### Requirement: Archive-completed-tasks toggle
The settings view SHALL provide a toggle to enable or disable archiving of completed tasks in place of permanent deletion, defaulting to disabled.

#### Scenario: Enable archiving
- **WHEN** the user enables "Keep an archive of completed tasks"
- **THEN** tasks whose retention period subsequently elapses are archived instead of permanently deleted

#### Scenario: Disable archiving
- **WHEN** the user disables "Keep an archive of completed tasks"
- **THEN** tasks whose retention period subsequently elapses are permanently deleted as before, and the archive view is no longer reachable
