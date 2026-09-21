import ServiceManagement

/// Thin wrapper around `SMAppService` (macOS 13+) for the "Launch at
/// Login" setting toggle (design.md, Decision 6 — replaces the deprecated
/// `SMLoginItemSetEnabled` and needs no separate helper-app target).
public enum LaunchAtLogin {
    public static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            // Non-fatal: leave the setting as the user requested in
            // preferences even if the OS registration call failed; the
            // toggle can be retried from Settings.
        }
    }

    public static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
