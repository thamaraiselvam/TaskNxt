import SwiftUI

/// App entry point. There is no visible `Window`/`WindowGroup` scene by
/// design — this is a menu-bar-only app (spec: menu-bar-shell). The
/// `Settings` scene here is never shown to the user in a menu-bar-only
/// (LSUIElement) app; it merely satisfies `App`'s requirement of at least
/// one `Scene`, while `AppDelegate` owns the real UI (status item +
/// popover).
@main
struct TaskNxtApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
