## Purpose

Defines how the app presents itself as a menu-bar-only utility: its icon, the popover window it shows, how users open/close it, and the global keyboard shortcut that summons it from anywhere.

## ADDED Requirements

### Requirement: Menu bar only presence
The system SHALL run as a menu bar utility with no Dock icon and no traditional application window. The only persistent UI element SHALL be an icon in the macOS menu bar.

#### Scenario: App launches without a Dock icon
- **WHEN** the app is launched
- **THEN** no icon appears in the Dock
- **AND** an icon appears in the system menu bar

#### Scenario: Quitting the app removes the menu bar icon
- **WHEN** the user quits the app (via Settings or a quit shortcut)
- **THEN** the menu bar icon is removed and no process UI remains visible

### Requirement: Popover open and close via menu bar icon
Clicking the menu bar icon SHALL toggle a popover window showing the app's task content. Clicking outside the popover SHALL close it.

#### Scenario: Click to open
- **WHEN** the user clicks the menu bar icon while the popover is closed
- **THEN** the popover opens showing the last-active tab's tasks

#### Scenario: Click to close
- **WHEN** the user clicks the menu bar icon while the popover is open
- **THEN** the popover closes

#### Scenario: Click outside closes popover
- **WHEN** the popover is open and the user clicks anywhere outside it
- **THEN** the popover closes

### Requirement: Global keyboard shortcut
The system SHALL support a user-configurable global keyboard shortcut (default: a chord not already reserved by macOS) that toggles the popover open/closed regardless of which application currently has focus.

#### Scenario: Shortcut opens popover from another app
- **WHEN** the user is focused in a different application
- **AND** the user presses the configured global shortcut
- **THEN** the TodoNxt-clone popover opens and gains focus

#### Scenario: Shortcut toggles closed
- **WHEN** the popover is currently open
- **AND** the user presses the configured global shortcut
- **THEN** the popover closes

### Requirement: Appearance follows system
The popover UI SHALL render in light or dark appearance matching the current macOS system appearance setting, and SHALL update live if the system appearance changes while the popover is open.

#### Scenario: System in dark mode
- **WHEN** macOS is set to Dark appearance
- **THEN** the popover renders using dark-mode colors

#### Scenario: Live appearance change
- **WHEN** the popover is open
- **AND** the user changes the system appearance in System Settings
- **THEN** the popover's appearance updates without requiring a reopen
