## Why

In Settings → Tabs, clicking **Rename** swaps the label for a text field that never receives keyboard focus, so it looks like plain text and swallows typing. Renaming a tab is effectively broken. Task rows had the same bug, fixed in `31b0bc3`; the tab row was missed.

## What Changes

- Focus the rename field as soon as it appears.
- Commit the rename when the field loses focus (like Enter); Escape cancels and keeps the old name.
- Make the whole **Rename** button hit-testable, not just its text glyphs.

## Capabilities

### New Capabilities

### Modified Capabilities
- `tab-management`: "Rename a tab" gains requirements on how the inline rename interaction behaves (focus, commit, cancel).

## Impact

- `app/Sources/TaskNxt/Features/Tabs/TabManagementView.swift` (`TabRow`) only. No model, persistence, or `AppState` changes.
