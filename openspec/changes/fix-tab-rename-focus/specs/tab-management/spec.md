## MODIFIED Requirements

### Requirement: Rename a tab
The user SHALL be able to rename any existing tab. Renaming SHALL NOT affect the tab's tasks. When the user starts a rename, the name field SHALL be immediately focused and ready for typing. The rename SHALL be committed when the user presses Enter or moves focus away from the field, and SHALL be cancelled, leaving the name unchanged, when the user presses Escape. An empty name SHALL NOT replace the existing name. The entire Rename control SHALL be clickable, not only its label text.

#### Scenario: Rename preserves tasks
- **WHEN** a tab named "Work" contains tasks
- **AND** the user renames it to "Projects"
- **THEN** the tab is now labeled "Projects" and all of its tasks remain unchanged

#### Scenario: Field is focused on rename
- **WHEN** the user activates Rename on a tab
- **THEN** the name field appears with keyboard focus and typing edits the name without any extra click

#### Scenario: Focus loss commits
- **WHEN** the user edits the name and clicks elsewhere
- **THEN** the new name is saved and the row leaves edit mode

#### Scenario: Escape cancels
- **WHEN** the user edits the name and presses Escape
- **THEN** the tab keeps its previous name and the row leaves edit mode

#### Scenario: Empty name rejected
- **WHEN** the user clears the name and commits
- **THEN** the tab keeps its previous name

#### Scenario: Whole Rename control is clickable
- **WHEN** the user clicks the padding around the Rename label
- **THEN** rename starts
