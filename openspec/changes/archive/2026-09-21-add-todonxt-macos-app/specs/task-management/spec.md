## Purpose

Defines the core task model: three fixed priority lanes (Now, Nxt, Ltr) within a tab, task creation/completion/deletion, drag-and-drop reordering, and automatic cleanup of completed tasks.

## ADDED Requirements

### Requirement: Three fixed lanes per tab
Each tab SHALL contain exactly three lanes, in this fixed order: **Now**, **Nxt**, **Ltr**. Lanes SHALL NOT be renamed, reordered, added, or removed.

#### Scenario: Tab always shows three lanes
- **WHEN** a tab is displayed
- **THEN** the Now, Nxt, and Ltr lanes are shown in that order, each with its own task count

### Requirement: Inline task creation
Each lane SHALL provide an inline "+ add to <lane>..." affordance. Activating it SHALL allow the user to type task text and commit it (e.g. via Enter) as a new incomplete task at the end of that lane.

#### Scenario: Add a task to a lane
- **WHEN** the user activates "+ add to now..." in the Now lane
- **AND** types "Ship landing page" and presses Enter
- **THEN** a new incomplete task "Ship landing page" appears at the end of the Now lane
- **AND** the Now lane's task count increments by 1

#### Scenario: Empty input is not added
- **WHEN** the user activates the add-task affordance
- **AND** commits without entering any text
- **THEN** no task is created

### Requirement: Task completion toggle
Each task SHALL display a toggle control. Toggling it SHALL mark the task as done (showing a strikethrough/visual done state) or incomplete.

#### Scenario: Mark task done
- **WHEN** the user toggles an incomplete task's checkbox
- **THEN** the task is shown with a done visual style (e.g. strikethrough)
- **AND** the task records a completion timestamp

#### Scenario: Un-mark a done task
- **WHEN** the user toggles a done task's checkbox
- **THEN** the task returns to the incomplete visual state
- **AND** the task's completion timestamp is cleared
- **AND** any pending auto-purge for that task is cancelled

### Requirement: Completed task retention countdown
A completed task SHALL display a countdown indicator showing the time remaining before it is automatically removed. The retention period SHALL default to 2 days and SHALL be configurable (see `settings` capability).

#### Scenario: Countdown badge shown on completion
- **WHEN** a task is marked done
- **THEN** the task row shows a countdown badge reflecting time remaining until auto-purge (e.g. "2d")

#### Scenario: Task auto-purged after retention period
- **WHEN** a completed task's retention period has fully elapsed
- **THEN** the task is automatically and permanently removed from its lane without user action

### Requirement: Manual task deletion
The user SHALL be able to manually delete any task (complete or incomplete) at any time, independent of the auto-purge countdown.

#### Scenario: Manual delete of incomplete task
- **WHEN** the user invokes delete on an incomplete task
- **THEN** the task is immediately and permanently removed

### Requirement: Drag-and-drop reordering
Tasks SHALL be reorderable within a lane via drag-and-drop, and movable between lanes (Now/Nxt/Ltr) within the same tab via drag-and-drop. Moving a task to a different lane SHALL NOT alter its completion state.

#### Scenario: Reorder within a lane
- **WHEN** the user drags a task to a new position within the same lane
- **THEN** the task list order updates to reflect the new position

#### Scenario: Move task between lanes
- **WHEN** the user drags an incomplete task from the Nxt lane to the Now lane
- **THEN** the task appears in the Now lane and no longer appears in the Nxt lane
- **AND** the task remains incomplete

### Requirement: Task and lane counts
Each tab header SHALL display the total incomplete task count across its lanes, and each lane header SHALL display its own incomplete task count.

#### Scenario: Counts update on task creation
- **WHEN** a new task is added to a lane
- **THEN** both that lane's count and the owning tab's total count increment by 1

#### Scenario: Counts update on completion
- **WHEN** a task is marked done
- **THEN** the lane and tab counts reflect only incomplete tasks (the completed task no longer counts toward the total)
