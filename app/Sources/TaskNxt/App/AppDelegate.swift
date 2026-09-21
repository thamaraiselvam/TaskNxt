import AppKit
import TaskNxtCore
import SwiftUI
import Combine

/// Owns the menu bar icon, its popover, and the global hotkey wiring.
///
/// We use classic AppKit `NSStatusItem` + `NSPopover` here rather than
/// SwiftUI's `MenuBarExtra` because the global hotkey (spec: menu-bar-shell,
/// "Global keyboard shortcut") must be able to open *and* close the popover
/// from outside any SwiftUI view hierarchy, and `MenuBarExtra` does not
/// expose a reliable external toggle for its presented state on macOS 13
/// (design.md, Decision 1's noted AppKit fallback).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()
    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // belt-and-suspenders with LSUIElement: no Dock icon

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureStatusItem(item)
        statusItem = item

        let popover = NSPopover()
        popover.behavior = .transient // closes automatically on outside click
        popover.contentSize = NSSize(width: 340, height: 480)
        popover.contentViewController = NSHostingController(
            rootView: PopoverRootView().environmentObject(appState)
        )
        self.popover = popover

        appState.bindPopoverToggle { [weak self] in self?.togglePopover() }
        appState.bindOpenSettings { [weak self] in self?.openSettingsWindow() }

        // Keep the menu bar badge in sync with the active tab's pending
        // count (spec: menu-bar-shell, "Pending-count badge on menu bar
        // icon"). `objectWillChange` fires on any relevant `store`/
        // `activeTabID` mutation, so re-reading the computed count here is
        // sufficient -- no separate diffing needed.
        appState.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Published values haven't updated yet on `objectWillChange`
                // (it fires *before* the change); defer to the next runloop
                // turn so `appState.activeTabIncompleteCount` reflects the
                // new state.
                DispatchQueue.main.async { self?.updateBadge() }
            }
            .store(in: &cancellables)
        updateBadge()
    }

    private func updateBadge() {
        guard let button = statusItem?.button else { return }
        let count = appState.activeTabIncompleteCount
        button.title = count > 0 ? " \(count)" : ""
        // Keep `imagePosition` fixed at `.imageLeading` at all times (rather
        // than switching to `.imageOnly` when the count is 0) so the icon's
        // own position never shifts as the badge text appears/disappears --
        // only the title text next to it changes. Combined with the
        // `.variableLength` status item (which can actually grow to fit
        // the title -- `.squareLength` clipped it to a fixed square and is
        // why the badge number never rendered), this keeps the icon
        // visually anchored while the count updates.
        button.imagePosition = .imageLeading
    }

    private func configureStatusItem(_ item: NSStatusItem) {
        guard let button = item.button else { return }
        // Plain `NSImage(systemSymbolName:)` renders quite small/thin in
        // the menu bar by default; a larger point size + medium weight
        // (and the filled symbol variant) reads much more clearly at menu
        // bar scale, matching how most third-party status items look.
        let configuration = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "TaskNxt")?
            .withSymbolConfiguration(configuration)
        image?.isTemplate = true
        button.image = image
        button.action = #selector(togglePopoverFromClick)
        button.target = self
    }

    @objc private func togglePopoverFromClick() {
        togglePopover()
    }

    private func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func openSettingsWindow() {
        SettingsWindowController.shared.show(appState: appState)
    }

    // The settings window is the app's only real `NSWindow`; closing it
    // must not terminate this menu-bar-only (LSUIElement) app (design.md
    // Risk: "does closing it quit the app? No").
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
