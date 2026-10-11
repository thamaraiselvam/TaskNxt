import Foundation

/// Pure remote-into-local merge (spec: google-tasks-sync, "Two-way task
/// sync"). Last-write-wins on `updatedAt` vs Google's `updated`.
enum GoogleSyncMerge {
    static func apply(_ remote: [GoogleTask], to tab: inout AppTab) {
        for r in remote {
            let loc = locate(r.id, in: tab)
            if r.deleted {
                tab.pendingDeletes.removeAll { $0 == r.id }
                guard let (lane, i) = loc else { continue }
                let local = tab.tasks[lane]![i]
                if local.updatedAt > (local.syncedAt ?? .distantPast) {
                    tab.tasks[lane]![i].googleID = nil  // edited locally: keep it, re-create remotely
                } else {
                    tab.tasks[lane]!.remove(at: i)
                }
            } else if let (lane, i) = loc {
                guard r.updated > tab.tasks[lane]![i].updatedAt else { continue }
                tab.tasks[lane]![i].text = r.title
                tab.tasks[lane]![i].completedAt = r.isCompleted ? (tab.tasks[lane]![i].completedAt ?? r.completedAt ?? r.updated) : nil
                // Keep the local time-of-day when the day is unchanged.
                if let due = r.due, let cur = tab.tasks[lane]![i].dueDate, Calendar.current.isDate(due, inSameDayAs: cur) {} else {
                    tab.tasks[lane]![i].dueDate = r.due
                }
                tab.tasks[lane]![i].updatedAt = r.updated
                tab.tasks[lane]![i].syncedAt = r.updated
            } else if !r.isCompleted, !tab.pendingDeletes.contains(r.id) {
                // Unknown, still-open remote task: new for us -> Inbox.
                let order = tab.tasks[.inbox]?.count ?? 0
                tab.tasks[.inbox, default: []].append(TaskItem(
                    text: r.title, order: order, dueDate: r.due, googleID: r.id, updatedAt: r.updated, syncedAt: r.updated
                ))
            }
        }
    }

    private static func locate(_ googleID: String, in tab: AppTab) -> (Lane, Int)? {
        for lane in Lane.allCases {
            if let i = tab.tasks[lane]?.firstIndex(where: { $0.googleID == googleID }) { return (lane, i) }
        }
        return nil
    }
}

/// Owns the Google connection state, list selection, and the sync loop.
@MainActor
public final class GoogleTasksSync: ObservableObject {
    public enum Status: Equatable { case disconnected, connected, reconnectRequired }

    @Published public private(set) var status: Status = .disconnected
    @Published public private(set) var lists: [GoogleTaskList] = []
    @Published public private(set) var isSyncing = false
    @Published public private(set) var lastError: String?

    private let appState: AppState
    private let auth: GoogleAuth
    private let api: GoogleTasksAPI
    private var timer: Timer?
    private var pendingResync = false
    private var debounce: Task<Void, Never>?

    public init(appState: AppState, auth: GoogleAuth, api: GoogleTasksAPI) {
        self.appState = appState
        self.auth = auth
        self.api = api
        // Push local edits (e.g. completing a task) within seconds instead of waiting for the interval.
        appState.onTaskEdited = { [weak self] in self?.scheduleSoon() }
    }

    private func scheduleSoon() {
        guard status == .connected else { return }
        debounce?.cancel()
        debounce = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.syncNow()
        }
    }

    /// Convenience wiring for the real app.
    public convenience init(appState: AppState, clientID: String?) {
        let auth = GoogleAuth(clientID: clientID)
        self.init(appState: appState, auth: auth, api: GoogleTasksClient(token: { try await auth.validAccessToken() }))
    }

    /// Call once at launch: restores connection state, syncs, and starts the 5-minute timer.
    public func start() {
        Task {
            await appState.waitUntilLoaded()
            if await auth.hasCredentials {
                status = .connected
                await syncNow()
            }
        }
        scheduleTimer()
    }

    /// Choices offered in Settings (seconds).
    public static let intervalOptions: [(label: String, seconds: Int)] = [
        ("Every minute", 60), ("Every 5 minutes", 300), ("Every 15 minutes", 900),
        ("Every hour", 3600), ("Every day", 86400),
    ]

    public func setSyncInterval(_ seconds: Int) {
        appState.setGoogleSyncInterval(seconds)
        scheduleTimer()
    }

    private func scheduleTimer() {
        timer?.invalidate()
        let interval = TimeInterval(max(60, appState.store.settings.googleSyncInterval))
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in await self.syncNow() }
        }
    }

    /// Test hook: behave as connected and run a sync.
    func connectForTesting() async {
        status = .connected
        await syncNow()
    }

    public func isEnabled(_ list: GoogleTaskList) -> Bool {
        appState.store.tabs.contains { $0.googleListID == list.id }
    }

    // MARK: - Connection

    public func connect(_ web: @escaping GoogleAuth.WebSession) async {
        lastError = nil
        do {
            let email = try await auth.signIn(web)
            appState.setGoogleAccountEmail(email)
            status = .connected
            await syncNow()
        } catch GoogleAuthError.cancelled {
            // Not an error worth showing.
        } catch {
            lastError = error.localizedDescription
        }
    }

    public func disconnect() async {
        await auth.disconnect()
        for tab in appState.store.tabs where tab.googleListID != nil { unlink(tab.id) }
        appState.setGoogleAccountEmail(nil)
        appState.clearGoogleKnownLists()
        lists = []
        status = .disconnected
        lastError = nil
    }

    // MARK: - List selection

    public func setList(_ list: GoogleTaskList, enabled: Bool) async {
        lastError = nil
        if enabled {
            guard !isEnabled(list) else { return }
            appState.addGoogleTab(named: list.title, listID: list.id)
            await syncNow()
        } else if let tab = appState.store.tabs.first(where: { $0.googleListID == list.id }) {
            unlink(tab.id)
        }
    }

    private func unlink(_ tabID: UUID) {
        appState.updateTab(tabID) { tab in
            tab.googleListID = nil
            tab.googleLastSync = nil
            tab.pendingDeletes = []
            for lane in Lane.allCases {
                for i in tab.tasks[lane]?.indices ?? 0..<0 {
                    tab.tasks[lane]![i].googleID = nil
                    tab.tasks[lane]![i].syncedAt = nil
                }
            }
        }
    }

    // MARK: - Sync

    public func syncNow() async {
        guard status != .disconnected else { return }
        await appState.waitUntilLoaded()
        guard !isSyncing else { pendingResync = true; return }  // edit landed mid-sync: run again after
        isSyncing = true
        await runSync()
        isSyncing = false
        if pendingResync {
            pendingResync = false
            await syncNow()
        }
    }

    private func runSync() async {
        do {
            let remoteLists = try await api.lists()
            lists = remoteLists
            // New lists get a tab automatically, once; user choices stick afterwards.
            let known = Set(appState.store.settings.googleKnownListIDs)
            for list in remoteLists where !known.contains(list.id) && !isEnabled(list) {
                appState.addGoogleTab(named: list.title, listID: list.id)
            }
            appState.markGoogleListsKnown(remoteLists.map(\.id))
            for tab in appState.store.tabs {
                guard let listID = tab.googleListID else { continue }
                if remoteLists.contains(where: { $0.id == listID }) {
                    try await sync(tabID: tab.id)
                } else {
                    unlink(tab.id)  // list deleted in Google: keep tab as local data
                }
            }
            lastError = nil
        } catch GoogleAPIError.unauthorized {
            status = .reconnectRequired
        } catch GoogleAuthError.reconnectRequired {
            status = .reconnectRequired
        } catch {
            // Offline/transient: local edits stay dirty and go out next time.
            lastError = error.localizedDescription
        }
    }

    func sync(tabID: UUID) async throws {
        guard let tab = appState.store.tabs.first(where: { $0.id == tabID }), let listID = tab.googleListID else { return }
        let started = Date()

        // Pull
        let remote = try await api.tasks(listID: listID, updatedMin: tab.googleLastSync)
        appState.updateTab(tabID) { GoogleSyncMerge.apply(remote, to: &$0) }

        // Push deletions
        for gid in appState.store.tabs.first(where: { $0.id == tabID })?.pendingDeletes ?? [] {
            do { try await api.delete(listID: listID, taskID: gid) } catch GoogleAPIError.notFound {}
            appState.updateTab(tabID) { $0.pendingDeletes.removeAll { $0 == gid } }
        }

        // Push new and changed tasks
        let current = appState.store.tabs.first(where: { $0.id == tabID })!
        for lane in Lane.allCases {
            for task in current.tasks[lane] ?? [] {
                let result: GoogleTask
                if let gid = task.googleID {
                    guard task.updatedAt > (task.syncedAt ?? .distantPast) else { continue }
                    result = try await api.patch(listID: listID, taskID: gid, title: task.text, isCompleted: task.isDone, due: task.dueDate)
                } else {
                    result = try await api.insert(listID: listID, title: task.text, isCompleted: task.isDone, due: task.dueDate)
                }
                appState.updateTab(tabID) { tab in
                    guard let i = tab.tasks[lane]?.firstIndex(where: { $0.id == task.id }) else { return }
                    tab.tasks[lane]![i].googleID = result.id
                    // Keep a newer local edit made while the request was in flight dirty.
                    if tab.tasks[lane]![i].updatedAt == task.updatedAt {
                        tab.tasks[lane]![i].updatedAt = result.updated
                        tab.tasks[lane]![i].syncedAt = result.updated
                    }
                }
            }
        }
        appState.updateTab(tabID) { $0.googleLastSync = started.addingTimeInterval(-1) }
    }
}
