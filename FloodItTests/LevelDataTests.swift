import XCTest
@testable import FloodIt

final class LevelDataTests: XCTestCase {

    // MARK: - P10-T1: Level Data

    func testAllLevelsExist() {
        XCTAssertEqual(LevelStore.levels.count, 100)
    }

    func testLevelNumbering() {
        for (index, level) in LevelStore.levels.enumerated() {
            XCTAssertEqual(level.id, index + 1)
        }
    }

    func testSplashTierLevels() {
        for i in 1...50 {
            let level = LevelStore.level(i)!
            XCTAssertEqual(level.tier, .splash, "Level \(i) should be splash tier")
        }
    }

    func testCurrentTierLevels() {
        for i in 51...100 {
            let level = LevelStore.level(i)!
            XCTAssertEqual(level.tier, .current, "Level \(i) should be current tier")
        }
    }

    func testAllLevelsAreSolvable() {
        for level in LevelStore.levels {
            let colors = Array(GameColor.allCases.prefix(level.colorCount))
            let board = FloodBoard.generateBoard(size: level.gridSize, colors: colors, seed: level.seed)
            let solverMoves = FloodSolver.solveMoveCount(board: board)
            XCTAssertLessThanOrEqual(solverMoves, level.moveBudget,
                "Level \(level.id) not solvable: solver needs \(solverMoves) moves, budget is \(level.moveBudget)")
        }
    }

    func testMoveBudgetIncludesExtraMoves() {
        for level in LevelStore.levels {
            XCTAssertGreaterThan(level.moveBudget, level.optimalMoves,
                "Level \(level.id) budget (\(level.moveBudget)) should exceed optimal (\(level.optimalMoves))")
        }
    }

    func testLevelLookup() {
        XCTAssertNotNil(LevelStore.level(1))
        XCTAssertNotNil(LevelStore.level(100))
        XCTAssertNil(LevelStore.level(0))
        XCTAssertNil(LevelStore.level(101))
    }

    func testAllLevelsHaveValidGridSize() {
        for level in LevelStore.levels {
            XCTAssertEqual(level.gridSize, 9, "Level \(level.id) should have grid size 9")
        }
    }
}
