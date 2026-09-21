import SwiftUI
import TaskNxtCore

/// Browsable list of archived (completed-and-expired) tasks, grouped by
/// the date each was completed, with restore/delete actions (spec:
/// task-archive, "Archive view of completed tasks").
struct ArchiveView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var groups: [(date: Date, tasks: [ArchivedTask])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: appState.store.archivedTasks) { task in
            calendar.startOfDay(for: task.completedAt)
        }
        return grouped
            .map { (date: $0.key, tasks: $0.value.sorted { $0.completedAt > $1.completedAt }) }
            .sorted { $0.date > $1.date }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Archived Tasks").font(.title3.bold())
                Spacer()
                Button("Done") { dismiss() }
            }

            if appState.store.archivedTasks.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(groups, id: \.date) { group in
                        Section(Self.dateFormatter.string(from: group.date)) {
                            ForEach(group.tasks) { task in
                                ArchivedTaskRow(
                                    task: task,
                                    onRestore: { appState.restoreArchivedTask(task.id) },
                                    onDelete: { appState.deleteArchivedTask(task.id) }
                                )
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding()
        .frame(width: 380, height: 420)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "archivebox")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No archived tasks yet")
                .foregroundStyle(.secondary)
            Text("Completed tasks appear here once their retention period elapses, if archiving is enabled in Settings.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ArchivedTaskRow: View {
    let task: ArchivedTask
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text(task.text)
            Spacer()
            Button("Restore", action: onRestore)
                .buttonStyle(.borderless)
            Button("Delete", role: .destructive, action: onDelete)
                .buttonStyle(.borderless)
        }
    }
}
