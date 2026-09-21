## Purpose

Provides read-only informational content about the app itself -- version, author/contact information, and links to report issues or view changes -- separate from the configurable settings in the `settings` capability.

## ADDED Requirements

### Requirement: About section
The settings window SHALL include an "About" section showing the app's icon, current version number, and author/contact information.

#### Scenario: View app info
- **WHEN** the user navigates to the About section of settings
- **THEN** the app icon, version number, and author/contact information are displayed

### Requirement: Bug report and changelog links
The About section SHALL provide a way to report a bug and a way to view the changelog or source.

#### Scenario: Report a bug
- **WHEN** the user activates the "Report a Bug" affordance in About
- **THEN** the system opens the configured bug-reporting destination (e.g. an issue tracker URL or a pre-filled email) in the user's default browser/mail client

#### Scenario: View changelog or source
- **WHEN** the user activates the changelog/source link in About
- **THEN** the system opens that destination in the user's default browser
