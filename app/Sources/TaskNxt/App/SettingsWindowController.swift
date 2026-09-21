import AppKit
import SwiftUI
import TaskNxtCore

/// Owns a single standalone settings `NSWindow`, independent of the
/// popover's lifecycle (spec: settings, "Settings entry point"; design.md
/// Decision "Dedicated NSWindow ... Singleton window"). Activating the
/// gear icon while the window is already open brings it to front rather
/// than creating a second instance.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    func show(appState: AppState) {
        if let window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(rootView: SettingsRootView().environmentObject(appState))
        // `NSHostingController`'s default `sizingOptions` lets it
        // auto-resize its window to match the SwiftUI content's intrinsic
        // size on every layout pass. With that enabled *and* us also
        // setting an explicit content size below, the two could fight
        // (e.g. after switching settings tabs to a section with different
        // natural content height/width), which is what caused the window
        // to render at an unexpected size/position ("alignment broken").
        // Disabling it makes our explicit `setContentSize` below the one
        // and only source of truth for this window's size.
        hosting.sizingOptions = []
        let window = NSWindow(contentViewController: hosting)
        window.title = "TaskNxt"
        window.styleMask = [.titled, .closable, .miniaturizable]
        // Closing this window must never quit the app -- TaskNxt is a
        // menu-bar-only (LSUIElement) app with no Dock icon and no other
        // windows, so the default "close last window terminates app"
        // behavior would be surprising here (design.md Risk).
        window.isReleasedWhenClosed = false
        window.delegate = self

        // `SettingsRootView` fixes its own size via `.frame(width:height:)`,
        // but at construction time the hosting controller hasn't laid out
        // its SwiftUI content yet, so the window's frame is still an
        // arbitrary default. Calling `center()` before that layout pass
        // centers a wrongly-sized (near-zero) rect, which is why the
        // window used to appear anchored near the status item instead of
        // screen-centered until manually moved. Setting the real content
        // size explicitly first makes `center()` operate on the window's
        // actual final size. This must exactly match `SettingsRootView`'s
        // own `.frame(width:height:)` so the two never disagree.
        window.setContentSize(NSSize(width: 640, height: 520))
        window.center()

        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
