import Foundation

struct GameSession {
    private(set) var engine: GameEngine
    init(seed: UInt64, rules: GameRules = .originalApproximation) {
        engine = GameEngine(seed: seed, rules: rules)
    }
    var state: GameState { engine.state }
    mutating func start(_ mode: GameMode, bestScore: Int = 0) {
        engine.start(mode)
        engine.restoreBestScore(bestScore)
    }
    mutating func reset() { engine.reset() }
    mutating func press(_ position: EggLane) { engine.select(position) }
    mutating func advance(elapsed: Double) { engine.advance(seconds: elapsed) }
    var nextTickDelay: Double { engine.tickDuration }
}
