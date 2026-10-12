import Foundation

/// Positions use a screen-width fraction. Extra cards extend the scrollable string.
enum RopePlacement {
    static let margin: CGFloat = 100
    static let gap: CGFloat = 190
    static func positions(ids: [UUID], saved: [String: Double], width: CGFloat) -> [UUID: CGFloat] {
        let width = max(200, width)
        let first = max(margin, (width - CGFloat(ids.count) * gap - 58) / 2 + 82)
        var result: [UUID: CGFloat] = [:]
        var previous = margin - gap
        for (i, id) in ids.enumerated() {
            let raw = saved[id.uuidString]
            let desired = raw.flatMap { $0.isFinite ? CGFloat(max(0, min(100, $0))) * width : nil } ?? (first + CGFloat(i) * gap)
            let x = max(previous + gap, desired)
            result[id] = x; previous = x
        }
        return result
    }
    static func inserting(_ id: UUID, at x: CGFloat, into positions: [UUID: CGFloat]) -> (order: [UUID], positions: [UUID: CGFloat]) {
        var result = positions; result.removeValue(forKey: id)
        var order = result.keys.sorted { result[$0]! < result[$1]! }
        let desired = max(margin, x)
        let proposed = order.firstIndex { result[$0]! > desired } ?? order.count
        let index = min(proposed, Int((desired - margin) / gap))
        order.insert(id, at: index)
        // Leave room on the left, moving only neighbours that would overlap.
        result[id] = desired
        if index > 0 {
            for i in stride(from: index - 1, through: 0, by: -1) {
                result[order[i]] = min(result[order[i]]!, result[order[i + 1]]! - gap)
            }
        }
        for i in (index + 1)..<order.count {
            result[order[i]] = max(result[order[i]]!, result[order[i - 1]]! + gap)
        }
        return (order, result)
    }
    static func maxScroll(_ positions: [UUID: CGFloat], width: CGFloat) -> CGFloat {
        max(0, (positions.values.max() ?? 100) + 170 - width)
    }
}
