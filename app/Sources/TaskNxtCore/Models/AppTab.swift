import Foundation

/// A single named list (e.g. "Work", "Personal"), owning its own
/// independent Now/Nxt/Ltr lanes (spec: tab-management).
public struct AppTab: Identifiable, Equatable {
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

// Custom `Codable` so the on-disk shape of `tasks` is a fixed, explicit
// `{"now": [...], "nxt": [...], "ltr": [...]}` JSON object, independent of
// however a given Foundation version happens to serialize
// `Dictionary<Lane, [TaskItem]>` internally. Relying on the synthesized
// conformance is fragile across toolchains: older Foundation only used a
// keyed object representation for `Dictionary` when the key type was
// exactly `String`/`Int` (any other `Codable`/`Hashable` key, including a
// `String`-backed `RawRepresentable` enum like `Lane`, serialized as a
// flat array of alternating key/value elements instead), while newer
// Foundation (Xcode 16+) recognizes `Lane`'s implicit
// `CodingKeyRepresentable` conformance and always uses the object form —
// so a store.json (or hand-authored test fixture) written under one
// toolchain fails to decode under the other. Encoding/decoding through an
// explicit `[String: [TaskItem]]` keyed by `Lane.rawValue` sidesteps that
// entirely.
extension AppTab: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, name, order, tasks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        order = try container.decode(Int.self, forKey: .order)
        let byRawValue = try container.decode([String: [TaskItem]].self, forKey: .tasks)
        tasks = Lane.allCases.reduce(into: [:]) { result, lane in
            result[lane] = byRawValue[lane.rawValue] ?? []
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(order, forKey: .order)
        let byRawValue = Dictionary(uniqueKeysWithValues: tasks.map { ($0.key.rawValue, $0.value) })
        try container.encode(byRawValue, forKey: .tasks)
    }
}
