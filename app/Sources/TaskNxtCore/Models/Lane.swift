import Foundation

/// The three fixed priority lanes every tab has. Order is fixed and
/// meaningful: Now, then Nxt, then Ltr — lanes cannot be added, removed,
/// or reordered (spec: task-management, "Three fixed lanes per tab").
public enum Lane: String, Codable, CaseIterable, Identifiable {
    case now
    case nxt
    case ltr

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .now: return "Now"
        case .nxt: return "Nxt"
        case .ltr: return "Ltr"
        }
    }
}
