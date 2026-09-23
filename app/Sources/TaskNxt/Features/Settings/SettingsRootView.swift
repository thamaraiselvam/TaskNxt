import SwiftUI
import TaskNxtCore

/// Top icon-tab-bar navigated root of the settings window: General,
/// Shortcuts, Tabs, and About sections (spec: settings, "Settings entry
/// point"). Mirrors the common macOS preferences-window convention of a
/// row of icon+label tabs across the top, rather than a sidebar list.
struct SettingsRootView: View {
    enum Section: String, CaseIterable, Identifiable {
        case general = "General"
        case shortcuts = "Shortcuts"
        case tabs = "Tabs"
        case about = "About"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .general: "gearshape"
            case .shortcuts: "command"
            case .tabs: "square.on.square"
            case .about: "info.circle"
            }
        }
    }

    @State private var selection: Section = .general

    var body: some View {
        VStack(spacing: 0) {
            settingsTabBar
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()

            Group {
                switch selection {
                case .general: GeneralSettingsView()
                case .shortcuts: ShortcutsSettingsView()
                case .tabs: TabManagementView()
                case .about: AboutView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 640, height: 520)
        .background(.background)
    }

    private var settingsTabBar: some View {
        HStack(spacing: 8) {
            ForEach(Section.allCases) { section in
                SettingsTabButton(
                    section: section,
                    isSelected: selection == section,
                    action: { selection = section }
                )
                .frame(maxWidth: .infinity)
            }
        }
        // Matches the `.padding(24)` each section body uses below, so the
        // tab row's leading/trailing edges line up with the content's
        // margins instead of floating as a much-narrower centered cluster
        // with mismatched, much wider side gaps (the "alignment is not
        // good" look).
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
    }
}

private struct SettingsTabButton: View {
    let section: SettingsRootView.Section
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 18))
                Text(section.rawValue)
                    .font(.caption)
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.4) : .clear, lineWidth: 1)
            )
            // A `.plain` button only hit-tests its drawn pixels, and the
            // unselected background is clear -- so only the icon/label
            // glyphs were clickable. Make the whole box the hit area.
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
