## MODIFIED Requirements

### Requirement: Menu bar only presence
The system SHALL run as a menu bar utility with no Dock icon and no traditional application window (the settings window is an intentional exception, opened only on user request via the gear icon). The only persistent, always-visible UI element SHALL be an icon in the macOS menu bar.

#### Scenario: App launches without a Dock icon
- **WHEN** the app is launched
- **THEN** no icon appears in the Dock
- **AND** an icon appears in the system menu bar

#### Scenario: Quitting the app removes the menu bar icon
- **WHEN** the user quits the app (via the Quit action in settings, or a quit shortcut)
- **THEN** the menu bar icon is removed, any open settings window is closed, and no process UI remains visible
