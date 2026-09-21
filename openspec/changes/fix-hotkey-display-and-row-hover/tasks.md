## 1. Hotkey display fix

- [x] 1.1 Replace `KeyCodeNames.names` with a complete macOS virtual-keycode table (letters, digits, punctuation, function keys, arrows, common editing keys)
- [x] 1.2 Verify `describe(_:)` / `hotKeyHint` render correctly for a sample of previously-broken codes (e.g. keyCode 17 = "T") — verified via standalone script mirroring the lookup logic; keyCode 17 -> "T", full arrow/function-key/keypad ranges resolve, fallback still works for genuinely unmapped codes
- [ ] 1.3 Manually re-record a shortcut (e.g. Cmd+Shift+T) via `HotKeyRecorderView` and confirm the label shown matches the physical keys pressed — **requires running the app on-device** (same toolchain limitation as 2.3); code-level verification (task 1.2) confirms the underlying lookup is correct

## 2. Task row hover fix

- [x] 2.1 Reserve a fixed-width slot for the delete ("x") control in `TaskRowView`'s layout at all times
- [x] 2.2 Toggle only the delete control's opacity/hit-testing (not its presence in the view tree) based on `isHovering`
- [ ] 2.3 Manually verify hovering anywhere on the row keeps the "x" visible and clickable without flicker, including near the row's edges — **requires running the app on-device**; this sandbox can't build the SwiftUI (`TaskNxt`) target (`SwiftUIMacros`/`TestingMacros` plugins unavailable in the CommandLineTools-only toolchain here), so this needs manual verification in Xcode
- [x] 2.4 Confirm existing drag-and-drop and context-menu delete behavior on the row are unaffected — verified via code review: `.draggable`, `.dropDestination`, and `.contextMenu` modifiers were not touched; only the trailing delete button's visibility mechanism changed (opacity/hit-testing instead of conditional insertion)
