import AppKit

/// Bundle metadata surfaced in the About settings section (spec:
/// settings-about). Centralized here so the version string has a single
/// source of truth instead of being hand-typed in multiple views.
enum AppInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// The app icon. `NSApplication.applicationIconImage` only knows about
    /// it inside a real .app bundle (Contents/Resources/AppIcon.icns); when
    /// run unbundled from Xcode or `swift build` it falls back to a generic
    /// folder-like icon, so look for the icon PNG ourselves first.
    static var icon: NSImage {
        if let bundled = Bundle.main.image(forResource: "AppIcon") {
            return bundled
        }
        let iconPath = "Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"
        let candidates = [
            // SwiftPM resource bundle, next to the executable or in Resources.
            Bundle.main.resourceURL?.appendingPathComponent("TaskNxt_TaskNxt.bundle/\(iconPath)"),
            Bundle.main.bundleURL.appendingPathComponent("TaskNxt_TaskNxt.bundle/\(iconPath)"),
            // Development fallback: the source tree this binary was built from.
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()  // App
                .deletingLastPathComponent()  // TaskNxt
                .deletingLastPathComponent()  // Sources
                .deletingLastPathComponent()  // app
                .appendingPathComponent("Resources/\(iconPath)")
        ]
        for case let url? in candidates {
            if let image = NSImage(contentsOf: url) { return image }
        }
        return NSApplication.shared.applicationIconImage
    }

    static let author = "Thamaraiselvam"
    static let websiteDisplayName = "github.com/thamaraiselvam/tasknxt"
    static let websiteURL = URL(string: "https://github.com/thamaraiselvam/tasknxt")!
    static let bugReportURL = URL(string: "https://github.com/thamaraiselvam/tasknxt/issues/new")!
    static let aboutDescription =
        "TaskNxt is a free, local-only menu bar to-do app. Organize tasks into Now, " +
        "Nxt, and Ltr lanes across multiple tabs, right from your menu bar."
}
