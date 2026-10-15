import XCTest
@testable import IM02Core

final class GameSessionTests: XCTestCase {
    func testControlledElapsedTimeAndInput() {
        var session = GameSession(seed: 9, rules: .test)
        session.start(.gameB, bestScore: 37)
        XCTAssertEqual(session.state.bestScore, 37)
        session.advance(elapsed: 0.5)
        XCTAssertTrue(session.state.eggs.isEmpty)
        session.advance(elapsed: 0.5)
        XCTAssertEqual(session.state.eggs.count, 1)
        let lane = session.state.eggs[0].lane
        session.press(lane)
        XCTAssertEqual(session.state.wolf, lane)
        session.advance(elapsed: 5)
        XCTAssertEqual(session.state.score, 1)
        session.reset()
        XCTAssertEqual(session.state.phase, .clock)
        XCTAssertEqual(session.state.bestScore, 37)
        session.start(.gameA, bestScore: 5)
        XCTAssertEqual(session.state.bestScore, 5)
    }
}
