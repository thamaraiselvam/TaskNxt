import Foundation

/// A single named list (e.g. "Work", "Personal"), owning its own
/// independent Now/Nxt/Ltr lanes (spec: tab-management).
public struct AppTab: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    /// Position among sibling tabs; lower sorts first.
    public var order: Int
    public var tasks: [Lane: [TaskItem]]

    public init(id: UUID = UUID(), name: String, order: Int, tasks: [Lane: [TaskItem]]? = nil) {
        self.id = id
        self.name = name
        self.order = order
        self.tasks = tasks ?? Lane.allCases.reduce(into: [:]) { $0[$1] = [] }
    }

    /// Total incomplete tasks across all lanes (spec: task-management,
    /// "Task and lane counts").
    public var incompleteCount: Int {
        Lane.allCases.reduce(0) { total, lane in
            total + (tasks[lane]?.filter { !$0.isDone }.count ?? 0)
        }
    }

    public func incompleteCount(for lane: Lane) -> Int {
        tasks[lane]?.filter { !$0.isDone }.count ?? 0
    }
}

// `[Lane: [TaskItem]]` is `Codable` for free since `Lane` is `Codable` and
// `Hashable`. Note that Foundation's `JSONEncoder`/`JSONDecoder` only use a
// keyed *object* representation for `Dictionary` when the key type is
// exactly `String` or `Int`; a custom `RawRepresentable`-by-`String` enum
// key like `Lane` still round-trips correctly, but on disk it serializes
// as a flat array of alternating key/value elements (e.g.
// `["now", [...], "nxt", [...], "ltr", [...]]`), not `{"now": [...], ...}`.
// This only matters for anything reading/writing the JSON by hand (e.g.
// hand-authored test fixtures); encode/decode via `Store`'s own
// `Codable` conformance stay internally consistent.
