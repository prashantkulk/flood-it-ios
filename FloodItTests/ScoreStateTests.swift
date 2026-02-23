import XCTest
@testable import FloodIt

final class ScoreStateTests: XCTestCase {

    // MARK: - P14-T1: ScoreState

    func testCalculateMoveScore() {
        let score = ScoreState()
        // 12 cells at combo x3 = 12 * 20 * 3 = 720
        let result = score.calculateMoveScore(cellsAbsorbed: 12, comboMultiplier: 3.0)
        XCTAssertEqual(result, 720)
    }

    func testCalculateMoveScoreBase() {
        let score = ScoreState()
        // 5 cells, no multiplier = 5 * 20 = 100
        let result = score.calculateMoveScore(cellsAbsorbed: 5)
        XCTAssertEqual(result, 100)
    }

    func testCalculateMoveScoreWithCascade() {
        let score = ScoreState()
        // 10 cells, combo x2, cascade x1.5 = 10 * 20 * 2 * 1.5 = 600
        let result = score.calculateMoveScore(cellsAbsorbed: 10, comboMultiplier: 2.0, cascadeMultiplier: 1.5)
        XCTAssertEqual(result, 600)
    }

    func testCalculateEndBonus() {
        let score = ScoreState()
        // 3 remaining moves, optimal+1 = 3*50 + 500 = 650
        let result = score.calculateEndBonus(movesRemaining: 3, isOptimalPlusOne: true)
        XCTAssertEqual(result, 650)
    }

    func testCalculateEndBonusNotOptimal() {
        let score = ScoreState()
        // 5 remaining moves, not optimal = 5*50 = 250
        let result = score.calculateEndBonus(movesRemaining: 5, isOptimalPlusOne: false)
        XCTAssertEqual(result, 250)
    }

    func testRecordMoveUpdatesTotal() {
        let score = ScoreState()
        score.recordMove(cellsAbsorbed: 12, comboMultiplier: 3.0)
        XCTAssertEqual(score.totalScore, 720)
        XCTAssertEqual(score.lastMoveScore, 720)
        XCTAssertEqual(score.lastCellsAbsorbed, 12)
    }

    func testMultipleMovesAccumulate() {
        let score = ScoreState()
        score.recordMove(cellsAbsorbed: 5) // 100
        score.recordMove(cellsAbsorbed: 10, comboMultiplier: 2.0) // 400
        XCTAssertEqual(score.totalScore, 500)
        XCTAssertEqual(score.lastMoveScore, 400)
    }

    func testResetClearsState() {
        let score = ScoreState()
        score.recordMove(cellsAbsorbed: 12, comboMultiplier: 3.0)
        score.reset()
        XCTAssertEqual(score.totalScore, 0)
        XCTAssertEqual(score.lastMoveScore, 0)
        XCTAssertEqual(score.lastCellsAbsorbed, 0)
    }
}
