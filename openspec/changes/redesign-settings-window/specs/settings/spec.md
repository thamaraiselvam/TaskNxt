## MODIFIED Requirements

### Requirement: Settings entry point
The popover SHALL display a settings (gear) affordance that opens the settings window.

#### Scenario: Open settings
- **WHEN** the user activates the gear icon in the popover
- **THEN** the settings window is displayed, organized into General, Tabs, and About sections

#### Scenario: Settings window persists independently of the popover
- **WHEN** the settings window is open
- **AND** the popover closes (e.g. the user clicks outside it)
- **THEN** the settings window remains open

## ADDED Requirements

### Requirement: Quit application
The settings window SHALL provide an action to quit the application.

#### Scenario: Quit from settings
- **WHEN** the user activates "Quit" in the General section of settings
- **THEN** the application quits, removing its menu bar icon, per the `menu-bar-shell` capability
