import SwiftUI
import TaskNxtCore

/// A single task row: completion checkbox, text (strikethrough when done,
/// double-click to edit in place), an archive affordance for completed
/// tasks, and a delete affordance (spec: task-management, "Task
/// completion toggle" / "Inline task text editing" / "Manual task
/// deletion").
struct TaskRowView: View {
    @EnvironmentObject private var appState: AppState
    let task: TaskItem
    let lane: Lane
    let tabID: UUID

    @State private var isHovering = false
    @State private var isEditing = false
    @State private var draftText = ""
    @FocusState private var isEditFieldFocused: Bool

    var body: some View {
        rowContent
            .padding(.vertical, 3)
            // Without an explicit `.frame(maxWidth: .infinity)` + full-row
            // `.contentShape(Rectangle())`, the row only sized itself (and
            // thus only became hoverable/tappable) around its
            // non-transparent content -- e.g. the task text -- leaving the
            // `Spacer()` gap and right-hand badge area dead to hover, which
            // is why the delete (x) button only appeared while hovering
            // directly over the text instead of anywhere on the row.
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
            .contextMenu {
                // Only completed tasks have a `completedAt`, which
                // `archiveTask` needs to record on the archived copy --
                // offering this for an incomplete task would silently
                // no-op, so it's hidden until the task is done.
                if task.isDone {
                    Button {
                        appState.archiveTask(task.id, lane: lane, tabID: tabID)
                    } label: {
                        Label("Archive Now", systemImage: "archivebox")
                    }
                }
                Button("Delete", role: .destructive) {
                    appState.deleteTask(task.id, lane: lane, tabID: tabID)
                }
            }
    }

    private var rowContent: some View {
        HStack(spacing: 8) {
            Button {
                appState.toggleTask(task.id, lane: lane, tabID: tabID)
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("", text: $draftText)
                    .textFieldStyle(.plain)
                    .focused($isEditFieldFocused)
                    .onSubmit { commitEdit() }
                    .onExitCommand { cancelEdit() }
            } else {
                Text(task.text)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? .secondary : .primary)
                    .lineLimit(2)
                    .onTapGesture(count: 2) { beginEdit() }
            }

            Spacer(minLength: 4)

            // Archive affordance: only meaningful once a task is done
            // (archiving needs `completedAt`), so it's hidden entirely for
            // still-open tasks rather than shown disabled. Fixed-width
            // slot + opacity/hit-testing toggle (not conditional view
            // insertion) for the same anti-flicker/anti-reflow reason as
            // the delete button below.
            if task.isDone {
                Button {
                    appState.archiveTask(task.id, lane: lane, tabID: tabID)
                } label: {
                    Image(systemName: "archivebox")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0)
                .allowsHitTesting(isHovering)
            }

            // Always present (fixed-width slot) so toggling its visibility
            // never reflows the row and re-triggers `.onHover` below --
            // only its opacity/hit-testing change with hover state.
            Button {
                appState.deleteTask(task.id, lane: lane, tabID: tabID)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
            .allowsHitTesting(isHovering)
        }
    }

    private func beginEdit() {
        draftText = task.text
        isEditing = true
        isEditFieldFocused = true
    }

    private func commitEdit() {
        // `updateTaskText` itself rejects empty/whitespace-only text and
        // leaves the task unchanged, satisfying the "empty edit is
        // rejected" spec scenario; re-showing `Text(task.text)` below
        // naturally reflects whichever value won.
        appState.updateTaskText(task.id, lane: lane, tabID: tabID, text: draftText)
        isEditing = false
    }

    private func cancelEdit() {
        draftText = task.text
        isEditing = false
    }
}
