import SwiftUI
import TaskNxtCore

private extension Lane {
    /// Accent color matching the reference design's palette for each lane.
    var accentColor: Color {
        switch self {
        case .now: return Color(red: 0.91, green: 0.64, blue: 0.29)  // amber
        case .nxt: return Color(red: 0.36, green: 0.55, blue: 0.94)  // blue
        case .ltr: return Color(red: 0.61, green: 0.48, blue: 0.86)  // purple
        }
    }
}

/// One priority lane (Now, Nxt, or Ltr): header with count, its tasks, and
/// the inline "+ add to <lane>..." affordance (spec: task-management).
struct LaneView: View {
    @EnvironmentObject private var appState: AppState
    let lane: Lane
    let tabID: UUID

    @State private var newTaskText = ""
    @FocusState private var isAddFieldFocused: Bool

    private var tasks: [TaskItem] {
        appState.store.tabs.first(where: { $0.id == tabID })?.tasks[lane] ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(lane.displayName.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(lane.accentColor)
                Text("\(tasks.filter { !$0.isDone }.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Rectangle()
                    .fill(.secondary.opacity(0.15))
                    .frame(height: 1)
            }
            .padding(.top, 8)

            ForEach(tasks.sorted(by: { $0.order < $1.order })) { task in
                TaskRowView(task: task, lane: lane, tabID: tabID)
            }

            HStack(spacing: 6) {
                Text("+").foregroundStyle(lane.accentColor)
                TextField("add to \(lane.rawValue)...", text: $newTaskText)
                    .textFieldStyle(.plain)
                    .focused($isAddFieldFocused)
                    .onSubmit {
                        appState.addTask(text: newTaskText, lane: lane, tabID: tabID)
                        newTaskText = ""
                    }
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .onTapGesture {
                // `contentShape` alone only expands the *hit-testable* area
                // for gestures/drop targets attached here -- it does not
                // forward clicks to the child `TextField` for focus. Without
                // this, only clicks landing exactly on the TextField's own
                // (sometimes narrow) rendered bounds would focus it, which
                // is why clicking the "+" label or surrounding padding
                // appeared to do nothing.
                isAddFieldFocused = true
            }
        }
    }
}
