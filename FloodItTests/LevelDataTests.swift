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
            let board = FloodBoard.generateBoard(from: level)
            let solverMoves = FloodSolver.solveMoveCount(board: board)
            XCTAssertLessThanOrEqual(solverMoves, level.moveBudget,
                "Level \(level.id) not solvable: solver needs \(solverMoves) moves, budget is \(level.moveBudget)")
        }
    }

    func testMoveBudgetExceedsOptimal() {
        for level in LevelStore.levels {
            XCTAssertGreaterThanOrEqual(level.moveBudget, level.optimalMoves,
                "Level \(level.id) budget (\(level.moveBudget)) should be >= optimal (\(level.optimalMoves))")
        }
    }

    func testLevelLookup() {
        XCTAssertNotNil(LevelStore.level(1))
        XCTAssertNotNil(LevelStore.level(100))
        XCTAssertNil(LevelStore.level(0))
        XCTAssertNil(LevelStore.level(101))
    }

    func testStandardLevelsHaveGridSize9() {
        for level in LevelStore.levels.dropFirst(5) {
            XCTAssertEqual(level.gridSize, 9, "Level \(level.id) should have grid size 9")
        }
    }

    // MARK: - P10-T6: Onboarding levels

    func testOnboardingLevelsProgressiveSize() {
        let expectedSizes = [3, 4, 5, 7, 9]
        for (i, size) in expectedSizes.enumerated() {
            let level = LevelStore.level(i + 1)!
            XCTAssertEqual(level.gridSize, size, "Onboarding level \(i + 1) should have grid size \(size)")
        }
    }

    func testOnboardingLevelsProgressiveColors() {
        let expectedColors = [3, 3, 4, 4, 5]
        for (i, count) in expectedColors.enumerated() {
            let level = LevelStore.level(i + 1)!
            XCTAssertEqual(level.colorCount, count, "Onboarding level \(i + 1) should have \(count) colors")
        }
    }

    func testOnboardingLevelsAreSolvable() {
        for i in 1...5 {
            let level = LevelStore.level(i)!
            let board = FloodBoard.generateBoard(from: level)
            let solverMoves = FloodSolver.solveMoveCount(board: board)
            XCTAssertLessThanOrEqual(solverMoves, level.moveBudget,
                "Onboarding level \(i) not solvable within budget")
        }
    }

    // MARK: - P18-T1: Obstacle config

    func testObstacleConfigDefaultsToNil() {
        // Existing levels without obstacles should have nil config
        let level = LevelStore.level(1)!
        XCTAssertNil(level.obstacleConfig)
    }

    func testObstacleConfigIsEmpty() {
        let config = ObstacleConfig()
        XCTAssertTrue(config.isEmpty)
    }

    func testObstacleConfigWithStones() {
        var config = ObstacleConfig()
        config.stonePositions = [CellPosition(row: 2, col: 3)]
        XCTAssertFalse(config.isEmpty)
    }

    func testGenerateBoardFromLevelDataWithObstacles() {
        let config = ObstacleConfig(
            stonePositions: [CellPosition(row: 4, col: 4)],
            icePositions: [ObstacleConfig.IcePlacement(position: CellPosition(row: 3, col: 3), layers: 2)],
            countdownPositions: [ObstacleConfig.CountdownPlacement(position: CellPosition(row: 5, col: 5), movesLeft: 3)],
            wallEdges: [ObstacleConfig.WallEdgePlacement(position: CellPosition(row: 2, col: 2), direction: .east)],
            portalPairs: [ObstacleConfig.PortalPairPlacement(position1: CellPosition(row: 1, col: 1), position2: CellPosition(row: 7, col: 7), pairId: 0)],
            bonusPositions: [ObstacleConfig.BonusPlacement(position: CellPosition(row: 6, col: 6), multiplier: 2)],
            voidPositions: [CellPosition(row: 8, col: 8)]
        )
        let levelData = LevelData(id: 999, seed: 42, gridSize: 9, colorCount: 5, optimalMoves: 10, moveBudget: 15, tier: .splash, obstacleConfig: config)
        let board = FloodBoard.generateBoard(from: levelData)

        XCTAssertEqual(board.cellType(atRow: 4, col: 4), .stone)
        XCTAssertEqual(board.cellType(atRow: 3, col: 3), .ice(layers: 2))
        XCTAssertEqual(board.cellType(atRow: 5, col: 5), .countdown(movesLeft: 3))
        XCTAssertEqual(board.cellType(atRow: 1, col: 1), .portal(pairId: 0))
        XCTAssertEqual(board.cellType(atRow: 7, col: 7), .portal(pairId: 0))
        XCTAssertEqual(board.cellType(atRow: 6, col: 6), .bonus(multiplier: 2))
        XCTAssertEqual(board.cellType(atRow: 8, col: 8), .void)
        XCTAssertTrue(board.hasWall(at: CellPosition(row: 2, col: 2), direction: .east))
    }

    func testGenerateBoardFromLevelDataWithoutObstacles() {
        let levelData = LevelData(id: 1, seed: 38, gridSize: 9, colorCount: 5, optimalMoves: 10, moveBudget: 15, tier: .splash)
        let board = FloodBoard.generateBoard(from: levelData)
        // All cells should be normal
        for row in 0..<9 {
            for col in 0..<9 {
                XCTAssertEqual(board.cellType(atRow: row, col: col), .normal)
            }
        }
    }
}
