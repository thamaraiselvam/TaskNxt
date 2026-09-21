import Carbon.HIToolbox
import Foundation

/// Registers a single system-wide keyboard shortcut using the Carbon Event
/// Manager (`RegisterEventHotKey`). This is deliberately not
/// `NSEvent.addGlobalMonitorForEvents`, which requires the user to grant
/// Accessibility permission — a heavier, more suspicious ask for an app
/// that markets itself as 100% private (design.md, Decision 2).
public final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: OSType(bitPattern: 0x544E_5854), id: 1) // 'TNXT'
    public var onPress: () -> Void

    public init(onPress: @escaping () -> Void) {
        self.onPress = onPress
    }

    deinit {
        unregister()
    }

    /// Registers `binding` as the active global shortcut, replacing any
    /// previously registered one. Returns `false` if registration failed
    /// (e.g. the combination is already claimed by the system or another
    /// app), in which case the previous binding remains active
    /// (spec: settings, "Conflicting shortcut rejected").
    @discardableResult
    public func register(_ binding: HotKeyBinding) -> Bool {
        var newRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            binding.keyCode,
            binding.modifierFlags,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &newRef
        )
        guard status == noErr, let newRef else {
            return false
        }

        // Only tear down the old registration after the new one succeeds,
        // so a failed re-registration leaves the previous shortcut intact.
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = newRef

        if eventHandler == nil {
            installHandlerIfNeeded()
        }
        return true
    }

    public func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = nil
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
        eventHandler = nil
    }

    private func installHandlerIfNeeded() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, userData -> OSStatus in
                guard let userData else { return noErr }
                let target = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                target.onPress()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
    }
}
