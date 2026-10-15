import Foundation
import Combine

@MainActor final class GameViewModel: ObservableObject {
    @Published private(set) var state: GameState
    @Published private(set) var clock = Date()
    @Published private(set) var bestPreview: Int?
    @Published private(set) var alarmEnabled = false
    private enum TimeSetting { case none, clock, alarm }
    private var timeSetting: TimeSetting = .none
    private var clockOffset = 0.0
    private var alarmHour = 12
    private var alarmMinute = 0
    private var alarmUntil: Date?
    private var lastAlarmKey = ""
    private var lastAlarmBeepSecond = -1
    private var session = GameSession(seed: UInt64.random(in: 1...UInt64.max))
    private let audio = BeepAudio()
    private var loop: Task<Void, Never>?
    private var previewTask: Task<Void, Never>?
    private let storage = UserDefaults.standard

    init() {
        state = session.state
        audio.enabled = storage.object(forKey: "soundEnabled") as? Bool ?? true
        alarmEnabled = storage.bool(forKey: "alarmEnabled")
        clockOffset = storage.double(forKey: "clockOffset")
        alarmHour = storage.object(forKey: "alarmHour") as? Int ?? 12
        alarmMinute = storage.object(forKey: "alarmMinute") as? Int ?? 0
        refreshClock()
        startLoop()
    }

    func start(_ mode: GameMode) {
        bestPreview = nil
        timeSetting = .none
        session.start(mode, bestScore: storage.integer(forKey: "best_\(mode.rawValue)"))
        publish()
    }
    func showBest(_ mode: GameMode) {
        guard state.phase != .playing else { return }
        bestPreview = storage.integer(forKey: "best_\(mode.rawValue)")
        previewTask?.cancel()
        previewTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled { self?.bestPreview = nil }
        }
    }
    func select(_ lane: EggLane) {
        if timeSetting != .none {
            switch lane {
            case .upperLeft: setPM(false)
            case .lowerLeft: setPM(true)
            case .upperRight: adjustTime(hours: 1)
            case .lowerRight: adjustTime(minutes: 1)
            }
        } else { session.press(lane) }
        publish()
    }
    func showClock() {
        if alarmUntil != nil { alarmUntil = nil; alarmEnabled = false; storage.set(false, forKey: "alarmEnabled") }
        bestPreview = nil
        timeSetting = .none
        session.reset()
        refreshClock()
        publish()
    }
    func toggleSound() {
        audio.enabled.toggle()
        storage.set(audio.enabled, forKey: "soundEnabled")
    }
    func setAlarmTime() {
        guard state.phase != .playing else { return }
        session.reset()
        timeSetting = .alarm
        alarmEnabled = true
        storage.set(true, forKey: "alarmEnabled")
        refreshClock(); publish()
    }
    func setCurrentTime() {
        guard state.phase != .playing else { return }
        session.reset()
        timeSetting = .clock
        refreshClock(); publish()
    }
    private func setPM(_ pm: Bool) {
        let calendar = Calendar.current
        let currentHour = timeSetting == .alarm ? alarmHour : calendar.component(.hour, from: Date().addingTimeInterval(clockOffset))
        let updated = currentHour % 12 + (pm ? 12 : 0)
        if timeSetting == .alarm { alarmHour = updated; storage.set(updated, forKey: "alarmHour") }
        else { clockOffset += Double((updated-currentHour)*3600); storage.set(clockOffset, forKey: "clockOffset") }
        refreshClock()
    }
    private func adjustTime(hours: Int = 0, minutes: Int = 0) {
        if timeSetting == .alarm {
            alarmHour = (alarmHour + hours) % 24
            alarmMinute = (alarmMinute + minutes) % 60
            storage.set(alarmHour, forKey: "alarmHour")
            storage.set(alarmMinute, forKey: "alarmMinute")
        } else {
            clockOffset += Double(hours*3600 + minutes*60)
            storage.set(clockOffset, forKey: "clockOffset")
        }
        refreshClock()
    }
    private func refreshClock() {
        if timeSetting == .alarm {
            clock = Calendar.current.date(bySettingHour: alarmHour, minute: alarmMinute,
                                          second: 0, of: Date()) ?? Date()
        } else { clock = Date().addingTimeInterval(clockOffset) }
    }
    private func checkAlarm() {
        guard alarmEnabled, timeSetting == .none else { return }
        let now = Date().addingTimeInterval(clockOffset)
        let components = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: now)
        let key = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)-\(components.hour ?? 0)-\(components.minute ?? 0)"
        if components.hour == alarmHour && components.minute == alarmMinute && key != lastAlarmKey {
            lastAlarmKey = key
            alarmUntil = Date().addingTimeInterval(60)
        }
        if let until = alarmUntil, Date() < until {
            let second = Int(Date().timeIntervalSince1970)
            if second != lastAlarmBeepSecond { lastAlarmBeepSecond = second; audio.playAlarm() }
        }
        else { alarmUntil = nil }
    }
    func setActive(_ active: Bool) {
        if active { startLoop() } else { loop?.cancel(); loop = nil }
    }

    private func startLoop() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            guard let self else { return }
            var last = ProcessInfo.processInfo.systemUptime
            while !Task.isCancelled {
                let delay = self.state.phase == .playing ? min(self.session.nextTickDelay, 0.25) : 1
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { break }
                let now = ProcessInfo.processInfo.systemUptime
                self.session.advance(elapsed: now-last)
                last = now
                self.refreshClock()
                self.checkAlarm()
                self.publish()
            }
        }
    }
    private func publish() {
        let new = session.state
        if new != state {
            if new.bestScore > state.bestScore, let mode = new.mode {
                storage.set(new.bestScore, forKey: "best_\(mode.rawValue)")
            }
            audio.play(new.lastEvents)
            state = new
        }
    }
}
