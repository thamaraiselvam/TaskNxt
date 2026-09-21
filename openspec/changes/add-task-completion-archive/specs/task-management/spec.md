## MODIFIED Requirements

### Requirement: Completed task retention countdown
A completed task SHALL display a countdown indicator showing the time remaining before it is automatically removed from its lane. The retention period SHALL default to 2 days and SHALL be configurable (see `settings` capability).

#### Scenario: Countdown badge shown on completion
- **WHEN** a task is marked done
- **THEN** the task row shows a countdown badge reflecting time remaining until auto-removal (e.g. "2d")

#### Scenario: Task purged after retention period (archiving disabled)
- **WHEN** a completed task's retention period has fully elapsed
- **AND** archiving is disabled in settings
- **THEN** the task is automatically and permanently removed from its lane without user action

#### Scenario: Task archived after retention period (archiving enabled)
- **WHEN** a completed task's retention period has fully elapsed
- **AND** archiving is enabled in settings
- **THEN** the task is moved out of its lane into the archive (see `task-archive`) instead of being permanently deleted
