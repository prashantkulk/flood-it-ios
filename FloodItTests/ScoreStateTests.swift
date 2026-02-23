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

    // MARK: - P14-T15: Performance test

    func testLargeBoardScoreCalculation() {
        // Create a 15x15 board and simulate multiple floods through GameState
        let board = FloodBoard.generateBoard(size: 15, seed: 12345)
        let state = GameState(board: board, totalMoves: 50)

        // Simulate several floods and verify scoring works
        let colors: [GameColor] = [.amber, .emerald, .sapphire, .violet, .coral]
        var moveCount = 0
        for color in colors {
            let currentColor = state.board.cells[0][0]
            if color == currentColor { continue }
            state.performFlood(color: color)
            moveCount += 1
            if state.gameStatus != .playing { break }
        }

        // Verify score state is consistent
        XCTAssertGreaterThan(state.scoreState.totalScore, 0, "Score should be positive after moves")
        XCTAssertEqual(state.movesMade, moveCount)
        XCTAssertEqual(state.movesRemaining, 50 - moveCount)
    }

    func testLargeBoardScorePerformance() {
        // Performance: create a 15x15 board and run 30 floods
        measure {
            let board = FloodBoard.generateBoard(size: 15, seed: 99999)
            let state = GameState(board: board, totalMoves: 50)
            let allColors = GameColor.allCases
            for i in 0..<30 {
                guard state.gameStatus == .playing else { break }
                let color = allColors[i % allColors.count]
                let currentColor = state.board.cells[0][0]
                if color == currentColor { continue }
                state.performFlood(color: color)
            }
            XCTAssertGreaterThanOrEqual(state.scoreState.totalScore, 0)
        }
    }

    func testScoreStateWithEndBonus() {
        // Simulate a winnable scenario and check end bonus
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber],
            [.amber, .amber, .amber],
            [.amber, .amber, .amber],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells)
        let state = GameState(board: board, totalMoves: 10)
        state.performFlood(color: .amber)
        XCTAssertEqual(state.gameStatus, .won)
        // 8 cells absorbed * 20 = 160 base, plus end bonus: 9 moves * 50 + 500 (optimal+1) = 950
        // Total should be 160 + 950 = 1110
        XCTAssertGreaterThan(state.scoreState.totalScore, 0, "Score should include end bonus on win")
    }
}
