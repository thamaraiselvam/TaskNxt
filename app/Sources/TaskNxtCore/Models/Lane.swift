import Foundation

/// The four fixed lanes every tab has. Order is fixed and meaningful:
/// Inbox (unclassified, e.g. freshly synced from Google Tasks), then Now,
/// Nxt, Ltr — lanes cannot be added, removed, or reordered (spec:
/// task-management, "Three fixed lanes per tab").
public enum Lane: String, Codable, CaseIterable, Identifiable {
    case inbox
    case now
    case nxt
    case ltr

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .inbox: return "Inbox"
        case .now: return "Now"
        case .nxt: return "Nxt"
        case .ltr: return "Ltr"
        }
    }
}
