import Foundation

/// A minimal reimplementation of SwiftUI's `RangeReplaceableCollection.move(fromOffsets:toOffset:)`
/// so `TaskNxtCore` (which intentionally has no SwiftUI dependency) can
/// share the exact same reordering semantics used by the UI's
/// `.onMove`/drag handlers.
extension RangeReplaceableCollection where Self: MutableCollection, Index == Int {
    mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        let elementsToMove = source.map { self[$0] }
        var remaining = self.enumerated().filter { !source.contains($0.offset) }.map { $0.element }
        let adjustedDestination = destination - source.filter { $0 < destination }.count
        let insertAt = Swift.min(Swift.max(adjustedDestination, 0), remaining.count)
        remaining.insert(contentsOf: elementsToMove, at: insertAt)
        self = Self(remaining)
    }
}
