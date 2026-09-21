## Purpose

Defines the user-facing settings surface: global hotkey configuration, launch-at-login, completed-task retention period, and access to tab management, reached via a gear icon in the popover.

## Requirements

### Requirement: Settings entry point
The popover SHALL display a settings (gear) affordance that opens a settings view.

#### Scenario: Open settings
- **WHEN** the user activates the gear icon in the popover
- **THEN** a settings view is displayed

### Requirement: Configurable global hotkey
The settings view SHALL allow the user to view and change the global keyboard shortcut used to summon the popover (see `menu-bar-shell` capability). Changes SHALL take effect immediately.

#### Scenario: Change the global hotkey
- **WHEN** the user records a new key combination in the hotkey settings field
- **THEN** the previous shortcut is deactivated and the new shortcut immediately opens/closes the popover from any app

#### Scenario: Conflicting shortcut rejected
- **WHEN** the user attempts to set a hotkey combination already reserved by the system
- **THEN** the system rejects the change and keeps the previous shortcut active

### Requirement: Launch at login toggle
The settings view SHALL provide a toggle to enable or disable automatically launching the app at user login.

#### Scenario: Enable launch at login
- **WHEN** the user enables "Launch at Login"
- **AND** the user logs out and back in (or restarts)
- **THEN** the app is running and its menu bar icon is present without manual relaunch

#### Scenario: Disable launch at login
- **WHEN** the user disables "Launch at Login"
- **THEN** the app SHALL NOT automatically launch on the next login

### Requirement: Configurable completed-task retention period
The settings view SHALL allow the user to configure the retention period (in days) before completed tasks are automatically purged, as described in `task-management`. The default SHALL be 2 days.

#### Scenario: Change retention period
- **WHEN** the user sets the retention period to 5 days
- **THEN** subsequently completed tasks are purged 5 days after completion instead of 2

#### Scenario: Retention change does not affect already-elapsed tasks
- **WHEN** a completed task's original countdown has already fully elapsed
- **THEN** changing the retention period SHALL NOT restore it (it remains purged)

### Requirement: Tab management access
The settings view SHALL provide access to add, rename, reorder, and delete tabs, per the `tab-management` capability.

#### Scenario: Manage tabs from settings
- **WHEN** the user opens settings
- **THEN** the user can add, rename, reorder, or delete tabs from within the settings view
