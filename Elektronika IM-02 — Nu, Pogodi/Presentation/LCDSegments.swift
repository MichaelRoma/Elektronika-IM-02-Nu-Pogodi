import CoreGraphics

// All coordinates refer to the 837×462 LCD glass image, never the screen size.
enum LCDSegmentID: Hashable {
    case egg(EggLane, Int)
    case wolf(EggLane)
    case digit(Int, Int)
    case miss(Int)
    case hare
}

struct LCDSegmentDefinition {
    let id: LCDSegmentID
    let frame: CGRect
}

enum LCDSegments {
    static let digitPatterns: [Int: Set<Int>] = [
        0: [0,1,2,3,4,5], 1: [1,2], 2: [0,1,6,4,3], 3: [0,1,6,2,3],
        4: [5,6,1,2], 5: [0,5,6,2,3], 6: [0,5,6,2,3,4],
        7: [0,1,2], 8: [0,1,2,3,4,5,6], 9: [0,1,2,3,5,6]
    ]
    static func digitRect(_ segment: Int, x: CGFloat, width: CGFloat) -> CGRect {
        let t: CGFloat = 7
        switch segment {
        case 0: return CGRect(x: x + t, y: 0, width: width - 2*t, height: t)
        case 1: return CGRect(x: x + width - t, y: t, width: t, height: 24)
        case 2: return CGRect(x: x + width - t, y: 38, width: t, height: 24)
        case 3: return CGRect(x: x + t, y: 62, width: width - 2*t, height: t)
        case 4: return CGRect(x: x, y: 38, width: t, height: 24)
        case 5: return CGRect(x: x, y: t, width: t, height: 24)
        default: return CGRect(x: x + t, y: 31, width: width - 2*t, height: t)
        }
    }
    static let eggs: [LCDSegmentDefinition] = EggLane.allCases.flatMap { lane in
        (0...4).map { step in
            let left = lane == .upperLeft || lane == .lowerLeft
            let upper = lane == .upperLeft || lane == .upperRight
            let x = CGFloat(left ? 130 + step * 29 : 668 - step * 29)
            let y = CGFloat((upper ? 145 : 245) + step * 18)
            return LCDSegmentDefinition(id: .egg(lane, step), frame: CGRect(x: x, y: y, width: 39, height: 63))
        }
    }
    static let wolves: [LCDSegmentDefinition] = EggLane.allCases.map { lane in
        let left = lane == .upperLeft || lane == .lowerLeft
        let upper = lane == .upperLeft || lane == .upperRight
        return LCDSegmentDefinition(id: .wolf(lane), frame: CGRect(x: left ? 287 : 309,
            y: upper ? 174 : 207, width: 240, height: 250))
    }
    static let misses: [LCDSegmentDefinition] = (0..<3).map { index in
        LCDSegmentDefinition(id: .miss(index), frame: CGRect(x: 565 + index * 36, y: 105, width: 28, height: 31))
    }
    static let hare = LCDSegmentDefinition(id: .hare, frame: CGRect(x: 28, y: 105, width: 66, height: 72))
}
