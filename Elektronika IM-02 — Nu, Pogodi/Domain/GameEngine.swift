import Foundation

enum EggLane: Int, CaseIterable, Hashable, Codable {
    case upperLeft, lowerLeft, upperRight, lowerRight
}

enum GameMode: String, Codable { case gameA, gameB }
enum GamePhase: Equatable { case clock, playing, gameOver }
enum GameEvent: Equatable { case catchEgg, miss, gameOver, milestone }

struct Egg: Equatable, Identifiable {
    let id: Int
    let lane: EggLane
    var step: Int
}

struct GameState: Equatable {
    var phase: GamePhase = .clock
    var mode: GameMode? = nil
    var wolf: EggLane = .lowerLeft
    var eggs: [Egg] = []
    var score = 0
    var bestScore = 0
    var missHalfUnits = 0
    var hareVisible = false
    var tickCount = 0
    var lastEvents: [GameEvent] = []
}

struct GameRules {
    let initialTickSeconds: Double
    let minimumTickSeconds: Double
    let spawnEveryTicks: Int
    let maxConcurrentEggs: Int
    let hareCycleTicks: Int
    let hareVisibleTicks: Int
    let missLimitHalfUnits: Int

    static let originalApproximation = GameRules(initialTickSeconds: 0.68, minimumTickSeconds: 0.22,
        spawnEveryTicks: 4, maxConcurrentEggs: 4, hareCycleTicks: 19,
        hareVisibleTicks: 5, missLimitHalfUnits: 6)
    static let test = GameRules(initialTickSeconds: 1, minimumTickSeconds: 1,
        spawnEveryTicks: 99, maxConcurrentEggs: 1, hareCycleTicks: 1000,
        hareVisibleTicks: 0, missLimitHalfUnits: 6)
}

struct GameEngine {
    private(set) var state = GameState()
    let rules: GameRules
    private var randomState: UInt64
    private var nextEggID = 0
    private var elapsedRemainder = 0.0
    private var totalCatches = 0

    init(seed: UInt64, rules: GameRules = .originalApproximation) {
        self.randomState = seed == 0 ? 1 : seed
        self.rules = rules
    }

    var tickDuration: Double {
        // Exact oscillator timings are undocumented; this curve is isolated for calibration.
        let progress = Double(totalCatches % 100)
        let century = Double(totalCatches / 100)
        return max(rules.minimumTickSeconds,
                   rules.initialTickSeconds - progress * 0.0028 - century * 0.025)
    }

    mutating func start(_ mode: GameMode) {
        state = GameState(phase: .playing, mode: mode)
        elapsedRemainder = 0
        totalCatches = 0
        nextEggID = 0
    }

    mutating func restoreBestScore(_ score: Int) {
        state.bestScore = max(state.bestScore, max(0, min(score, 999)))
    }

    mutating func reset() {
        let best = state.bestScore
        state = GameState(bestScore: best)
        elapsedRemainder = 0
    }

    mutating func select(_ lane: EggLane) {
        guard state.phase == .playing else { return }
        state.lastEvents = []
        state.wolf = lane
    }

    mutating func advance(seconds: Double) {
        guard state.phase == .playing, seconds > 0, seconds.isFinite else { return }
        elapsedRemainder += seconds
        while elapsedRemainder >= tickDuration && state.phase == .playing {
            elapsedRemainder -= tickDuration
            tick()
        }
    }

    mutating func advance(ticks: Int) {
        guard ticks > 0 else { return }
        for _ in 0..<ticks where state.phase == .playing { tick() }
    }

    private mutating func tick() {
        state.lastEvents = []
        state.tickCount += 1
        state.hareVisible = rules.hareVisibleTicks > 0 &&
            state.tickCount % rules.hareCycleTicks < rules.hareVisibleTicks

        var survivors: [Egg] = []
        for var egg in state.eggs {
            if egg.step == 4 {
                if egg.lane == state.wolf { registerCatch() }
                else { registerMiss() }
            } else {
                egg.step += 1
                survivors.append(egg)
            }
        }
        state.eggs = survivors
        guard state.phase == .playing else { return }
        let spawnPeriod = max(2, rules.spawnEveryTicks - totalCatches / 150)
        if state.tickCount == 1 || state.tickCount % spawnPeriod == 1 { spawn() }
    }

    private mutating func spawn() {
        guard state.eggs.count < rules.maxConcurrentEggs else { return }
        let options = EggLane.allCases.filter { lane in
            !state.eggs.contains(where: { $0.lane == lane }) &&
            (state.mode == .gameB || lane != excludedLane)
        }
        guard !options.isEmpty else { return }
        let index = Int(nextRandom() % UInt64(options.count))
        state.eggs.append(Egg(id: nextEggID, lane: options[index], step: 0))
        nextEggID += 1
    }

    private var excludedLane: EggLane {
        switch state.missHalfUnits {
        case 0: return .lowerLeft
        case 1...2: return .lowerRight
        case 3...4: return .upperLeft
        default: return .upperRight
        }
    }

    private mutating func nextRandom() -> UInt64 {
        randomState = randomState &* 6364136223846793005 &+ 1442695040888963407
        return randomState >> 32
    }

    private mutating func registerCatch() {
        totalCatches += 1
        state.score = (state.score + 1) % 1000
        state.bestScore = max(state.bestScore, state.score)
        state.lastEvents.append(.catchEgg)
        if state.score == 200 || state.score == 500 {
            state.missHalfUnits = 0
            state.lastEvents.append(.milestone)
        }
    }

    private mutating func registerMiss() {
        state.missHalfUnits += state.hareVisible ? 1 : 2
        state.lastEvents.append(.miss)
        if state.missHalfUnits >= rules.missLimitHalfUnits {
            state.phase = .gameOver
            state.lastEvents.append(.gameOver)
        }
    }

    #if DEBUG
    mutating func setProgressForTesting(score: Int, missHalfUnits: Int) {
        state.score = score
        state.missHalfUnits = missHalfUnits
        totalCatches = score
    }
    mutating func registerCatchForTesting() { registerCatch() }
    #endif
}
