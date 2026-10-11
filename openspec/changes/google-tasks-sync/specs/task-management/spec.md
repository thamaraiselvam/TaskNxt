## MODIFIED Requirements

### Requirement: Three fixed lanes per tab
Each tab SHALL contain exactly four lanes, in this fixed order: **Inbox**, **Now**, **Nxt**, **Ltr**. Inbox holds unclassified tasks (e.g. newly synced from Google Tasks). Lanes SHALL NOT be renamed, reordered, added, or removed. The Inbox lane MAY be hidden while it is empty.

#### Scenario: Tab shows its lanes
- **WHEN** a tab with tasks in Inbox is displayed
- **THEN** the Inbox, Now, Nxt, and Ltr lanes are shown in that order, each with its own task count

#### Scenario: Empty Inbox hidden
- **WHEN** a tab's Inbox lane has no tasks
- **THEN** the Now, Nxt, and Ltr lanes are shown and Inbox is not

### Requirement: Drag-and-drop reordering
Tasks SHALL be reorderable within a lane via drag-and-drop, and movable between any lanes (Inbox/Now/Nxt/Ltr) within the same tab via drag-and-drop. Dropping on an empty lane or its header SHALL place the task in that lane. Moving a task SHALL NOT alter its completion state.

#### Scenario: Reorder within a lane
- **WHEN** the user drags a task to a new position within the same lane
- **THEN** the task list order updates to reflect the new position

#### Scenario: Move task between lanes
- **WHEN** the user drags an incomplete task from the Nxt lane to the Now lane
- **THEN** the task appears in the Now lane and no longer appears in the Nxt lane
- **AND** the task remains incomplete

#### Scenario: Triage from Inbox
- **WHEN** the user drags a task from Inbox onto an empty Ltr lane
- **THEN** the task is in Ltr and Inbox no longer shows it
