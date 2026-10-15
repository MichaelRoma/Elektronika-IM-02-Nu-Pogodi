import SwiftUI

struct ConsoleView: View {
    @StateObject private var model = GameViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 1774, geometry.size.height / 887)
            let size = CGSize(width: 1774 * scale, height: 887 * scale)
            ZStack {
                Color(red: 0.085, green: 0.075, blue: 0.07).ignoresSafeArea()
                ZStack(alignment: .topLeading) {
                    Image("console").resizable().interpolation(.high)
                        .frame(width: 1774, height: 887)
                    LCDView(state: model.state, clock: model.clock, alarmEnabled: model.alarmEnabled, bestPreview: model.bestPreview)
                        .frame(width: 837, height: 462)
                        .position(x: 470 + 837/2, y: 205 + 462/2)
                    consoleButton(x: 190, y: 523, width: 116, height: 130, label: "Верх слева") { model.select(.upperLeft) }
                    consoleButton(x: 190, y: 700, width: 116, height: 130, label: "Низ слева") { model.select(.lowerLeft) }
                    consoleButton(x: 1588, y: 523, width: 116, height: 130, label: "Верх справа") { model.select(.upperRight) }
                    consoleButton(x: 1588, y: 700, width: 116, height: 130, label: "Низ справа") { model.select(.lowerRight) }
                    consoleButton(x: 1538, y: 104, width: 90, height: 72, label: "Игра А", longAction: { model.showBest(.gameA) }) { model.start(.gameA) }
                    consoleButton(x: 1538, y: 219, width: 90, height: 72, label: "Игра Б", longAction: { model.showBest(.gameB) }) { model.start(.gameB) }
                    consoleButton(x: 1538, y: 336, width: 90, height: 72, label: "Время") { model.showClock() }
                    consoleButton(x: 1653, y: 160, width: 50, height: 50, label: "Будильник") { model.setAlarmTime() }
                    consoleButton(x: 1653, y: 295, width: 50, height: 50, label: "Установка времени", longAction: { model.toggleSound() }) { model.setCurrentTime() }
                }
                .frame(width: 1774, height: 887, alignment: .topLeading)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: size.width, height: size.height, alignment: .topLeading)
                .accessibilityElement(children: .contain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: scenePhase) { _, phase in model.setActive(phase == .active) }
    }

    private func consoleButton(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat,
                               label: String, longAction: (() -> Void)? = nil,
                               action: @escaping () -> Void) -> some View {
        ConsoleTouchButton(label: label, longAction: longAction, action: action)
            .frame(width: width, height: height)
            .position(x: x, y: y)
    }
}

private struct ConsoleTouchButton: View {
    let label: String
    let longAction: (() -> Void)?
    let action: () -> Void
    @State private var held = false
    var body: some View {
        Button {
            if held { held = false } else { action() }
        } label: { Color.clear.contentShape(Rectangle()) }
        .buttonStyle(.plain)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.65).onEnded { _ in
            if let longAction { held = true; longAction() }
        })
        .accessibilityLabel(label)
    }
}
