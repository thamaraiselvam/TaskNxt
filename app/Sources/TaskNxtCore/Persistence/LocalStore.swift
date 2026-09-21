import Foundation

/// Errors surfaced by `LocalStore` when the persisted file can't be read
/// or migrated. Callers fall back to defaults rather than crashing.
public enum LocalStoreError: Error {
    case unsupportedSchemaVersion(Int)
}

/// Loads and saves the single local JSON document that backs the entire
/// app: tabs, tasks, and settings (spec: local-persistence). All reads and
/// writes are serialized through this actor so the periodic auto-purge
/// sweep can never race with a concurrent user edit (design.md, Risk 3).
public actor LocalStore {
    private let fileURL: URL

    /// - Parameter fileURL: Defaults to
    ///   `~/Library/Application Support/TaskNxt/store.json`. Overridable for
    ///   tests so they never touch the real user's data.
    public init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first!
            let dir = appSupport.appendingPathComponent("TaskNxt", isDirectory: true)
            self.fileURL = dir.appendingPathComponent("store.json")
        }
    }

    /// Loads the store from disk, creating first-launch defaults if no
    /// file exists yet, and falling back to defaults (without deleting the
    /// unreadable file) if the file is corrupted.
    public func load() -> Store {
        guard let data = try? Data(contentsOf: fileURL) else {
            let defaults = Store.firstLaunchDefault()
            try? save(defaults)
            return defaults
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var store = try decoder.decode(Store.self, from: data)
            store = try migrate(store)
            return store
        } catch {
            // Corrupted or unreadable file: don't destroy the user's data
            // file, but don't crash either — fall back to an in-memory
            // default set for this session.
            return Store.firstLaunchDefault()
        }
    }

    /// Persists the store atomically: write to a temp file in the same
    /// directory, then rename over the destination, so a crash mid-write
    /// never leaves a truncated/corrupt store.json.
    public func save(_ store: Store) throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(store)

        let tempURL = dir.appendingPathComponent(UUID().uuidString + ".tmp")
        try data.write(to: tempURL, options: .atomic)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: tempURL)
        } else {
            try FileManager.default.moveItem(at: tempURL, to: fileURL)
        }
    }

    /// No-op today (schemaVersion 1 is the only version that has ever
    /// existed) but establishes the seam for future migrations.
    private func migrate(_ store: Store) throws -> Store {
        switch store.schemaVersion {
        case Store.currentSchemaVersion:
            return store
        default:
            throw LocalStoreError.unsupportedSchemaVersion(store.schemaVersion)
        }
    }
}
