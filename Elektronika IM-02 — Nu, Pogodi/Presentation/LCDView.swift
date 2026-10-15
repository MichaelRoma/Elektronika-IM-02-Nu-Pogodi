import SwiftUI

struct LCDView: View {
    let state: GameState
    let clock: Date
    let alarmEnabled: Bool
    let bestPreview: Int?
    private let ink = Color(red: 0.09, green: 0.11, blue: 0.09)

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 837
            ZStack(alignment: .topLeading) {
                Image("lcd_background").resizable().interpolation(.high)
                    .frame(width: 837, height: 462)
                RailOverlay().stroke(ink, style: StrokeStyle(lineWidth: 5, lineCap: .square, lineJoin: .miter))
                    .frame(width: 837, height: 462)
                if state.phase == .clock {
                    let seconds = Calendar.current.component(.second, from: clock)
                    let lane = EggLane.allCases[(seconds / 5) % 4]
                    let wolf = LCDSegments.wolves[lane.rawValue]
                    let egg = LCDSegments.eggs.first { $0.id == .egg(lane, seconds % 5) }!
                    Image("wolf_right").resizable().interpolation(.high)
                        .frame(width: wolf.frame.width, height: wolf.frame.height)
                        .scaleEffect(x: lane == .upperLeft || lane == .lowerLeft ? -1 : 1)
                        .position(x: wolf.frame.midX, y: wolf.frame.midY)
                    Image("egg").resizable().interpolation(.high)
                        .frame(width: egg.frame.width, height: egg.frame.height)
                        .position(x: egg.frame.midX, y: egg.frame.midY)
                }
                if state.phase == .playing || state.phase == .gameOver {
                    let wolf = LCDSegments.wolves[state.wolf.rawValue]
                    Image("wolf_right").resizable().interpolation(.high)
                        .frame(width: wolf.frame.width, height: wolf.frame.height)
                        .scaleEffect(x: state.wolf == .upperLeft || state.wolf == .lowerLeft ? -1 : 1)
                        .position(x: wolf.frame.midX, y: wolf.frame.midY)
                    ForEach(state.eggs) { egg in
                        let segment = LCDSegments.eggs.first { $0.id == .egg(egg.lane, egg.step) }!
                        Image("egg").resizable().interpolation(.high)
                            .frame(width: segment.frame.width, height: segment.frame.height)
                            .position(x: segment.frame.midX, y: segment.frame.midY)
                    }
                    ForEach(0..<3, id: \.self) { index in
                        if state.missHalfUnits > index * 2 {
                            ChickSegment().fill(ink)
                                .frame(width: 28, height: 31)
                                .position(x: LCDSegments.misses[index].frame.midX,
                                          y: LCDSegments.misses[index].frame.midY)
                                .opacity(state.missHalfUnits == index * 2 + 1 ? 0.55 : 1)
                        }
                    }
                    if state.hareVisible {
                        HareSegment().fill(ink).frame(width: 66, height: 72)
                            .position(x: LCDSegments.hare.frame.midX, y: LCDSegments.hare.frame.midY)
                    }
                }
                SevenSegmentDisplay(value: displayValue, showColon: state.phase == .clock)
                    .frame(width: 270, height: 69)
                    .position(x: 532, y: 65)
                if state.phase == .clock && bestPreview == nil {
                    Text(Calendar.current.component(.hour, from: clock) < 12 ? "ДП" : "ПП")
                        .font(.system(size: 30, weight: .heavy, design: .monospaced))
                        .foregroundStyle(ink).position(x: 366, y: 56)
                    if alarmEnabled {
                        Image(systemName: "bell.fill").font(.system(size: 31)).foregroundStyle(ink)
                            .position(x: 723, y: 57)
                    }
                }
            }
            .frame(width: 837, height: 462, alignment: .topLeading)
            .scaleEffect(scale, anchor: .topLeading)
        }
    }

    private var displayValue: String {
        if let bestPreview { return String(format: "%03d", bestPreview) }
        if state.phase == .clock {
            let c = Calendar.current
            let hour = c.component(.hour, from: clock) % 12
            return String(format: "%02d%02d", hour == 0 ? 12 : hour, c.component(.minute, from: clock))
        }
        return String(format: "%03d", state.score)
    }
}

private struct SevenSegmentDisplay: View {
    let value: String
    let showColon: Bool
    var body: some View {
        Canvas { context, _ in
            let chars = value.compactMap { $0.wholeNumberValue }
            let width: CGFloat = showColon ? 45 : 57
            let origin: CGFloat = showColon ? 16 : 35
            for (index, digit) in chars.enumerated() {
                let col = showColon && index >= 2 ? Double(index) + 0.55 : Double(index)
                let x = origin + CGFloat(col) * (width + 7)
                for segment in LCDSegments.digitPatterns[digit] ?? [] {
                    let box = LCDSegments.digitRect(segment, x: x, width: width)
                    let path = Path(roundedRect: box, cornerRadius: 2)
                    context.fill(path, with: .color(Color(red: 0.08, green: 0.10, blue: 0.08)))
                }
            }
            if showColon {
                for y in [23.0, 45.0] {
                    context.fill(Path(ellipseIn: CGRect(x: 131, y: y, width: 7, height: 7)),
                                 with: .color(Color(red: 0.08, green: 0.10, blue: 0.08)))
                }
            }
        }
    }

}

private struct ChickSegment: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: r.width*0.22, y: r.height*0.32, width: r.width*0.58, height: r.height*0.45))
        p.addEllipse(in: CGRect(x: r.width*0.12, y: r.height*0.13, width: r.width*0.35, height: r.height*0.32))
        p.move(to: CGPoint(x: r.width*0.14, y: r.height*0.35))
        p.addLine(to: CGPoint(x: 0, y: r.height*0.39))
        p.addLine(to: CGPoint(x: r.width*0.16, y: r.height*0.45))
        p.move(to: CGPoint(x: r.width*0.4, y: r.height*0.7))
        p.addLine(to: CGPoint(x: r.width*0.34, y: r.height))
        p.move(to: CGPoint(x: r.width*0.65, y: r.height*0.7))
        p.addLine(to: CGPoint(x: r.width*0.68, y: r.height))
        return p
    }
}

private struct HareSegment: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: 17, y: 28, width: 33, height: 30))
        p.addEllipse(in: CGRect(x: 21, y: 2, width: 9, height: 35))
        p.addEllipse(in: CGRect(x: 36, y: 0, width: 9, height: 35))
        p.addEllipse(in: CGRect(x: 10, y: 52, width: 48, height: 16))
        return p
    }
}

private struct RailOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let paths: [[CGPoint]] = [
            [CGPoint(x:15,y:145),CGPoint(x:174,y:217)],
            [CGPoint(x:15,y:250),CGPoint(x:73,y:250),CGPoint(x:204,y:338)],
            [CGPoint(x:15,y:260),CGPoint(x:72,y:260),CGPoint(x:196,y:346)],
            [CGPoint(x:822,y:145),CGPoint(x:663,y:217)],
            [CGPoint(x:822,y:250),CGPoint(x:764,y:250),CGPoint(x:633,y:338)],
            [CGPoint(x:822,y:260),CGPoint(x:765,y:260),CGPoint(x:641,y:346)]
        ]
        for points in paths {
            p.move(to: points[0]); for point in points.dropFirst() { p.addLine(to: point) }
        }
        return p
    }
}
