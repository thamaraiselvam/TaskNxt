import SwiftUI

/// Shared presentational building blocks for the settings window's
/// sections, giving General/Shortcuts/Tabs a consistent "big title +
/// subtitle + card of divided rows" layout (matches the reference design
/// requested for the settings redesign).
struct SettingsPageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.largeTitle.bold())
            Text(subtitle).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A rounded card grouping one or more `SettingsRow`s with hairline
/// dividers between them, mirroring the reference design's card style.
struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary.opacity(0.25))
            )
    }
}

/// One labeled settings row: bold title + secondary description on the
/// left, an arbitrary control on the right, matching the reference
/// design's row layout.
struct SettingsRow<Control: View>: View {
    let title: String
    let description: String?
    @ViewBuilder let control: Control

    init(_ title: String, description: String? = nil, @ViewBuilder control: () -> Control) {
        self.title = title
        self.description = description
        self.control = control()
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                if let description {
                    Text(description)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 12)
            control
        }
        .padding(.vertical, 14)
    }
}

/// Thin divider between rows inside a `SettingsCard`, indented to align
/// with row text rather than spanning the card's full padding.
struct SettingsRowDivider: View {
    var body: some View {
        Divider()
    }
}
