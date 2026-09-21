import Foundation

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

    static let author = "Thamaraiselvam"
    static let websiteDisplayName = "github.com/thamaraiselvam/tasknxt"
    static let websiteURL = URL(string: "https://github.com/thamaraiselvam/tasknxt")!
    static let bugReportURL = URL(string: "https://github.com/thamaraiselvam/tasknxt/issues/new")!
    static let aboutDescription =
        "TaskNxt is a free, local-only menu bar to-do app. Organize tasks into Now, " +
        "Nxt, and Ltr lanes across multiple tabs, right from your menu bar."
}
