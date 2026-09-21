import Foundation

/// A single global keyboard shortcut binding: a virtual key code plus
/// modifier flags, in a form independent of any particular hotkey API
/// (Carbon's `RegisterEventHotKey` takes exactly this shape).
public struct HotKeyBinding: Codable, Equatable {
    /// macOS virtual key code (e.g. `12` for the "Q" key).
    public var keyCode: UInt32
    /// Raw Carbon modifier mask (cmdKey | controlKey | optionKey | shiftKey bits).
    public var modifierFlags: UInt32

    public init(keyCode: UInt32, modifierFlags: UInt32) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
    }

    /// Default shortcut: Control + Q — matches the reference design's
    /// documented example shortcut.
    public static let `default` = HotKeyBinding(keyCode: 12, modifierFlags: HotKeyModifier.control)
}

/// Carbon modifier bit values, kept here (rather than importing Carbon into
/// the model layer) so the model stays a plain, testable value type.
public enum HotKeyModifier {
    public static let command: UInt32 = 0x0100
    public static let shift: UInt32 = 0x0200
    public static let option: UInt32 = 0x0800
    public static let control: UInt32 = 0x1000
}
