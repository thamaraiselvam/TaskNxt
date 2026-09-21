import Foundation
import TaskNxtCore
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    /// Custom type identifying a dragged task payload for in-app
    /// drag-and-drop only (spec: task-management, "Drag-and-drop
    /// reordering").
    static let taskNxtTask = UTType(exportedAs: "com.tasknxt.task")
}

/// The payload carried while a task row is being dragged: enough to find
/// and remove it from its origin, regardless of which lane/tab it's
/// dropped into.
struct DraggedTask: Codable, Transferable {
    var taskID: UUID
    var fromLane: Lane
    var fromTabID: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .taskNxtTask)
    }
}
