import SwiftUI
import AppKit

/// Read-only informational content: app icon/version card, then a
/// details card with author/link, description, and a bug-report action
/// (spec: settings-about). Consolidates version/bug-report affordances
/// previously scattered in the popover footer.
struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsPageHeader(title: "About", subtitle: "Version, credits, and links")

            SettingsCard {
                HStack(spacing: 14) {
                    appIcon
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("TaskNxt").font(.title3.bold())
                        Text("Version \(AppInfo.version) (\(AppInfo.build))")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            }

            SettingsCard {
                HStack {
                    Text("Made by \(AppInfo.author)").font(.body.weight(.semibold))
                    Spacer()
                    Link(AppInfo.websiteDisplayName, destination: AppInfo.websiteURL)
                }
                .padding(.vertical, 14)

                SettingsRowDivider()

                Text(AppInfo.aboutDescription)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)

                SettingsRowDivider()

                SettingsRow("Report an Issue", description: "Found a bug? Let us know.") {
                    Link("Report a Bug", destination: AppInfo.bugReportURL)
                        .buttonStyle(.bordered)
                }
            }

            Spacer()
        }
        .padding(24)
    }

    private var appIcon: some View {
        Image(nsImage: AppInfo.icon).resizable()
    }
}
