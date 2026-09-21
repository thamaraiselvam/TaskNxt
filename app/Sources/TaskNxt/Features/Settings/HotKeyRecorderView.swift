import AppKit
import TaskNxtCore
import Carbon.HIToolbox
import SwiftUI

/// A small custom NSView, styled to look like a single button, that
/// captures the next key-down event as a candidate global shortcut once
/// clicked -- no separate "click here" hint control needed. Needed
/// because SwiftUI on macOS 13 has no built-in "record a keyboard
/// shortcut" control.
private final class KeyCaptureView: NSView {
    var onCapture: ((HotKeyBinding) -> Void)?
    var displayText: String = "" {
        didSet { needsDisplay = true }
    }
    private(set) var isRecording = false {
        didSet { needsDisplay = true }
    }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        isRecording = true
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        isRecording = false

        var carbonModifiers: UInt32 = 0
        if event.modifierFlags.contains(.command) { carbonModifiers |= HotKeyModifier.command }
        if event.modifierFlags.contains(.option) { carbonModifiers |= HotKeyModifier.option }
        if event.modifierFlags.contains(.control) { carbonModifiers |= HotKeyModifier.control }
        if event.modifierFlags.contains(.shift) { carbonModifiers |= HotKeyModifier.shift }

        let binding = HotKeyBinding(keyCode: UInt32(event.keyCode), modifierFlags: carbonModifiers)
        onCapture?(binding)
    }

    // Pressing Escape while recording cancels back to the previous
    // shortcut instead of registering Escape itself as the new one --
    // matches the standard macOS "record shortcut" affordance behavior.
    override func cancelOperation(_ sender: Any?) {
        guard isRecording else { return }
        isRecording = false
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }

    override func draw(_ dirtyRect: NSRect) {
        let cornerRadius: CGFloat = 6
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: cornerRadius, yRadius: cornerRadius)

        let fill: NSColor = isRecording ? .controlAccentColor.withAlphaComponent(0.18) : .controlColor
        fill.setFill()
        path.fill()

        let stroke: NSColor = isRecording ? .controlAccentColor : .separatorColor
        stroke.setStroke()
        path.lineWidth = 1
        path.stroke()

        let text = isRecording ? "Press shortcut…" : displayText
        let textColor: NSColor = isRecording ? .controlAccentColor : .labelColor
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: textColor
        ]
        let size = text.size(withAttributes: attributes)
        let origin = NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2)
        text.draw(at: origin, withAttributes: attributes)
    }
}

private struct KeyCaptureRepresentable: NSViewRepresentable {
    let displayText: String
    let onCapture: (HotKeyBinding) -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.displayText = displayText
        view.onCapture = onCapture
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.displayText = displayText
        nsView.onCapture = onCapture
    }
}

/// Displays the current global shortcut as a single click-to-record
/// button: clicking it immediately arms key capture (label changes to
/// "Press shortcut…") and the very next key combination pressed becomes
/// the new shortcut -- no separate confirm/Enter step needed (spec:
/// settings, "Configurable global hotkey").
struct HotKeyRecorderView: View {
    @EnvironmentObject private var appState: AppState
    @State private var conflictMessage: String?

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            KeyCaptureRepresentable(displayText: describe(appState.store.settings.hotKey)) { binding in
                if !appState.updateHotKey(binding) {
                    conflictMessage = "That shortcut is already in use. Keeping the previous one."
                } else {
                    conflictMessage = nil
                }
            }
            .frame(width: 160, height: 26)

            if let conflictMessage {
                Text(conflictMessage).font(.caption2).foregroundStyle(.red)
            }
        }
    }

    private func describe(_ binding: HotKeyBinding) -> String {
        var parts: [String] = []
        if binding.modifierFlags & HotKeyModifier.control != 0 { parts.append("⌃") }
        if binding.modifierFlags & HotKeyModifier.option != 0 { parts.append("⌥") }
        if binding.modifierFlags & HotKeyModifier.shift != 0 { parts.append("⇧") }
        if binding.modifierFlags & HotKeyModifier.command != 0 { parts.append("⌘") }
        parts.append(KeyCodeNames.name(for: binding.keyCode))
        return parts.joined()
    }
}

/// Virtual-key-code -> display-name lookup covering the standard US ANSI
/// keyboard layout (letters, digits, punctuation, function keys, arrows, and
/// common editing keys), matching macOS's `kVK_ANSI_*` / `kVK_*` constants
/// from Carbon.HIToolbox. Falls back to a numeric placeholder only for
/// truly exotic/unassigned codes.
enum KeyCodeNames {
    private static let names: [UInt32: String] = [
        // Letters
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
        38: "J", 40: "K", 45: "N", 46: "M",
        // Digits (top row)
        18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 25: "9",
        26: "7", 28: "8", 29: "0",
        // Punctuation
        24: "=", 27: "-", 30: "]", 33: "[", 39: "'", 41: ";", 42: "\\",
        43: ",", 44: "/", 47: ".", 50: "`",
        // Editing / whitespace / control keys
        36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 53: "Escape",
        71: "Clear", 76: "Enter", 117: "Forward Delete", 115: "Home",
        119: "End", 116: "Page Up", 121: "Page Down",
        // Arrows
        123: "Left", 124: "Right", 125: "Down", 126: "Up",
        // Function keys
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
        105: "F13", 107: "F14", 113: "F15", 106: "F16", 64: "F17",
        79: "F18", 80: "F19", 90: "F20",
        // Keypad
        82: "Keypad 0", 83: "Keypad 1", 84: "Keypad 2", 85: "Keypad 3",
        86: "Keypad 4", 87: "Keypad 5", 88: "Keypad 6", 89: "Keypad 7",
        91: "Keypad 8", 92: "Keypad 9", 65: "Keypad .", 67: "Keypad *",
        69: "Keypad +", 75: "Keypad /", 78: "Keypad -", 81: "Keypad =",
        114: "Help", 63: "Fn"
    ]

    static func name(for code: UInt32) -> String {
        names[code] ?? "Key \(code)"
    }
}
