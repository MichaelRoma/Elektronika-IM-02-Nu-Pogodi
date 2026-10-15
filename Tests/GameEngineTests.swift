import XCTest
@testable import IM02Core

final class GameEngineTests: XCTestCase {
    func testStartAndReset() {
        var engine = GameEngine(seed: 7)
        XCTAssertEqual(engine.state.phase, .clock)
        engine.start(.gameA)
        XCTAssertEqual(engine.state.phase, .playing)
        XCTAssertEqual(engine.state.score, 0)
        XCTAssertEqual(engine.state.mode, .gameA)
        engine.reset()
        XCTAssertEqual(engine.state.phase, .clock)
        XCTAssertTrue(engine.state.eggs.isEmpty)
    }

    func testSpawnMoveCatchAndScore() {
        var engine = GameEngine(seed: 3, rules: .test)
        engine.start(.gameB)
        engine.advance(ticks: 1)
        XCTAssertEqual(engine.state.eggs.count, 1)
        let lane = try! XCTUnwrap(engine.state.eggs.first?.lane)
        XCTAssertEqual(engine.state.eggs.first?.step, 0)
        engine.advance(ticks: 4)
        XCTAssertEqual(engine.state.eggs.first?.step, 4)
        engine.select(lane)
        engine.advance(ticks: 1)
        XCTAssertTrue(engine.state.eggs.isEmpty)
        XCTAssertEqual(engine.state.score, 1)
        XCTAssertEqual(engine.state.missHalfUnits, 0)
    }

    func testWrongPositionMissesAndGameOver() {
        var engine = GameEngine(seed: 3, rules: .test)
        engine.start(.gameB)
        for _ in 0..<6 {
            while engine.state.eggs.isEmpty && engine.state.phase == .playing { engine.advance(ticks: 1) }
            let lane = try! XCTUnwrap(engine.state.eggs.first?.lane)
            engine.select(EggLane.allCases.first { $0 != lane }!)
            engine.advance(ticks: 5)
            if engine.state.phase == .gameOver { break }
        }
        XCTAssertEqual(engine.state.score, 0)
        XCTAssertEqual(engine.state.phase, .gameOver)
        XCTAssertGreaterThanOrEqual(engine.state.missHalfUnits, 6)
    }

    func testModeAExcludesOneLaneAndModeBAllowsFour() {
        let modeRules = GameRules(initialTickSeconds: 1, minimumTickSeconds: 1, spawnEveryTicks: 2, maxConcurrentEggs: 1, hareCycleTicks: 1000, hareVisibleTicks: 0, missLimitHalfUnits: 1000)
        var a = GameEngine(seed: 1, rules: modeRules)
        a.start(.gameA)
        for _ in 0..<40 {
            a.advance(ticks: 1)
            let misses = a.state.missHalfUnits
            let excluded: EggLane = misses == 0 ? .lowerLeft : (misses <= 2 ? .lowerRight : (misses <= 4 ? .upperLeft : .upperRight))
            XCTAssertFalse(a.state.eggs.contains { $0.lane == excluded })
        }
        var b = GameEngine(seed: 1, rules: modeRules)
        b.start(.gameB)
        var seen = Set<EggLane>()
        for _ in 0..<100 { b.advance(ticks: 1); seen.formUnion(b.state.eggs.map(\.lane)) }
        XCTAssertEqual(seen.count, 4)
    }

    func testMilestonesAndSpeed() {
        var engine = GameEngine(seed: 2)
        engine.start(.gameA)
        let initial = engine.tickDuration
        XCTAssertEqual(initial, 0.68, accuracy: 0.0001)
        engine.setProgressForTesting(score: 199, missHalfUnits: 4)
        engine.registerCatchForTesting()
        XCTAssertEqual(engine.state.score, 200)
        XCTAssertEqual(engine.state.missHalfUnits, 0)
        XCTAssertLessThan(engine.tickDuration, initial)
        engine.setProgressForTesting(score: 499, missHalfUnits: 2)
        engine.registerCatchForTesting()
        XCTAssertEqual(engine.state.missHalfUnits, 0)
        engine.setProgressForTesting(score: 999, missHalfUnits: 2)
        engine.registerCatchForTesting()
        XCTAssertEqual(engine.state.score, 0)
        XCTAssertEqual(engine.state.missHalfUnits, 2)
    }

    func testHareMakesHalfMiss() {
        let rules = GameRules(initialTickSeconds: 1, minimumTickSeconds: 1, spawnEveryTicks: 99, maxConcurrentEggs: 1, hareCycleTicks: 1, hareVisibleTicks: 1, missLimitHalfUnits: 6)
        var engine = GameEngine(seed: 1, rules: rules)
        engine.start(.gameA)
        engine.advance(ticks: 1)
        let lane = engine.state.eggs[0].lane
        engine.select(EggLane.allCases.first { $0 != lane }!)
        engine.advance(ticks: 5)
        XCTAssertEqual(engine.state.missHalfUnits, 1)
    }

    func testDeterminism() {
        var a = GameEngine(seed: 42)
        var b = GameEngine(seed: 42)
        a.start(.gameB); b.start(.gameB)
        for i in 0..<70 {
            if i % 3 == 0 { a.select(.upperRight); b.select(.upperRight) }
            a.advance(seconds: 0.43); b.advance(seconds: 0.43)
        }
        XCTAssertEqual(a.state, b.state)
    }
}
