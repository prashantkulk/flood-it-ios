import XCTest
@testable import FloodIt

final class LevelGeneratorTests: XCTestCase {

    // MARK: - P2-T7: LevelGenerator

    func testLevelGeneratorProducesSolvableLevel() {
        let level = LevelGenerator.generateLevel(seed: 42, difficulty: .medium)
        // The solver should be able to solve within the move budget
        let solverMoves = FloodSolver.solveMoveCount(board: level.board)
        XCTAssertLessThanOrEqual(solverMoves, level.moveBudget)
        // Budget should be optimal + 4 for medium
        XCTAssertEqual(level.moveBudget, level.optimalMoves + 4)
    }

    func testLevelGeneratorDifficultyBudgets() {
        let seed: UInt64 = 100
        let easy = LevelGenerator.generateLevel(seed: seed, difficulty: .easy)
        let medium = LevelGenerator.generateLevel(seed: seed, difficulty: .medium)
        let hard = LevelGenerator.generateLevel(seed: seed, difficulty: .hard)
        let expert = LevelGenerator.generateLevel(seed: seed, difficulty: .expert)

        // All should have the same board (same seed)
        XCTAssertEqual(easy.board.cells, medium.board.cells)
        XCTAssertEqual(medium.board.cells, hard.board.cells)
        XCTAssertEqual(hard.board.cells, expert.board.cells)

        // Budget should decrease with difficulty
        XCTAssertGreaterThan(easy.moveBudget, medium.moveBudget)
        XCTAssertGreaterThan(medium.moveBudget, hard.moveBudget)
        XCTAssertGreaterThan(hard.moveBudget, expert.moveBudget)

        // Expert budget = optimal moves
        XCTAssertEqual(expert.moveBudget, expert.optimalMoves)
    }

    func testLevelGeneratorSameSeedSameLevel() {
        let level1 = LevelGenerator.generateLevel(seed: 77, difficulty: .hard)
        let level2 = LevelGenerator.generateLevel(seed: 77, difficulty: .hard)
        XCTAssertEqual(level1.board.cells, level2.board.cells)
        XCTAssertEqual(level1.moveBudget, level2.moveBudget)
        XCTAssertEqual(level1.optimalMoves, level2.optimalMoves)
    }

    func testLevelGeneratorMultipleSeedsAllSolvable() {
        for seed: UInt64 in 1...5 {
            let level = LevelGenerator.generateLevel(seed: seed, difficulty: .expert)
            var board = level.board
            let moves = FloodSolver.solve(board: board)
            for color in moves {
                board.flood(color: color)
            }
            XCTAssertTrue(board.isComplete, "Level with seed \(seed) is not solvable")
            XCTAssertLessThanOrEqual(moves.count, level.moveBudget,
                "Level with seed \(seed) requires more moves than budget")
        }
    }
}
