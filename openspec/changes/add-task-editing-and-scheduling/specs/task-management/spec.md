## ADDED Requirements

### Requirement: Inline task text editing
Each task's text SHALL be editable in place after creation, without deleting and recreating the task.

#### Scenario: Enter edit mode
- **WHEN** the user double-clicks a task's text
- **THEN** the text becomes an editable field pre-filled with the current text

#### Scenario: Commit an edit
- **WHEN** the user is editing a task's text
- **AND** presses Enter, or clicks outside the field
- **THEN** the task's text is updated to the new value and edit mode ends

#### Scenario: Cancel an edit
- **WHEN** the user is editing a task's text
- **AND** presses Escape
- **THEN** the task's text reverts to its previous value and edit mode ends

#### Scenario: Empty edit is rejected
- **WHEN** the user clears all text while editing
- **AND** commits the edit
- **THEN** the task's text is unchanged (reverts to previous value) rather than becoming empty

### Requirement: Optional task deadline
Each task MAY have an optional due date (date, optionally with time). Setting or clearing it SHALL NOT alter the task's manual drag-and-drop order.

#### Scenario: Set a due date
- **WHEN** the user sets a due date on a task
- **THEN** the task row displays a due-date badge showing that date

#### Scenario: Overdue task is visually flagged
- **WHEN** a task's due date is in the past
- **AND** the task is still incomplete
- **THEN** the due-date badge renders in a distinct warning style (e.g. red)

#### Scenario: Clear a due date
- **WHEN** the user clears a task's due date
- **THEN** the due-date badge no longer appears on that task

#### Scenario: Due date does not affect ordering
- **WHEN** a task is given or has its due date changed
- **THEN** the task's position within its lane (set by manual drag-and-drop) SHALL NOT change as a result
