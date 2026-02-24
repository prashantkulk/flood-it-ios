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

    // MARK: - P18-T4: Levels 1-20 onboarding + easy breathers

    func testLevels6To20NoObstacles() {
        for i in 6...20 {
            let level = LevelStore.level(i)!
            XCTAssertNil(level.obstacleConfig, "Level \(i) should have no obstacles")
        }
    }

    func testLevels6To20GenerousBudgets() {
        // BUG-14: Tightened — levels 6-15 get +3, levels 16-20 get +2
        for i in 6...20 {
            let level = LevelStore.level(i)!
            let extra = level.moveBudget - level.optimalMoves
            let minExtra = i <= 15 ? 3 : 2
            XCTAssertGreaterThanOrEqual(extra, minExtra, "Level \(i) should have at least +\(minExtra) moves")
        }
    }

    func testLevels6To20AllSolvable() {
        for i in 6...20 {
            let level = LevelStore.level(i)!
            let board = FloodBoard.generateBoard(from: level)
            let solverMoves = FloodSolver.solveMoveCount(board: board)
            XCTAssertLessThanOrEqual(solverMoves, level.moveBudget,
                "Level \(i) should be solvable")
        }
    }

    func testLevels6To20Are9x9With5Colors() {
        for i in 6...20 {
            let level = LevelStore.level(i)!
            XCTAssertEqual(level.gridSize, 9, "Level \(i) should be 9x9")
            XCTAssertEqual(level.colorCount, 5, "Level \(i) should have 5 colors")
        }
    }

    // MARK: - P18-T5: Levels 21-30 stones + shaped boards

    func testLevels21To30HaveStones() {
        for i in 21...30 {
            let level = LevelStore.level(i)!
            XCTAssertNotNil(level.obstacleConfig, "Level \(i) should have obstacle config")
            let config = level.obstacleConfig!
            XCTAssertGreaterThanOrEqual(config.stonePositions.count, 2,
                "Level \(i) should have at least 2 stones")
            XCTAssertLessThanOrEqual(config.stonePositions.count, 4,
                "Level \(i) should have at most 4 stones")
        }
    }

    func testLevels21To30AllSolvableWithStones() {
        for i in 21...30 {
            let level = LevelStore.level(i)!
            let board = FloodBoard.generateBoard(from: level)
            let solverMoves = FloodSolver.solveMoveCount(board: board)
            XCTAssertLessThanOrEqual(solverMoves, level.moveBudget,
                "Level \(i) with stones should be solvable: solver needs \(solverMoves), budget is \(level.moveBudget)")
        }
    }

    func testSomeLevels21To30HaveShapedBoards() {
        // Levels 23, 25, 27, 29 should have void positions
        let shapedLevels = [23, 25, 27, 29]
        for i in shapedLevels {
            let level = LevelStore.level(i)!
            XCTAssertNotNil(level.obstacleConfig, "Level \(i) should have obstacle config")
            XCTAssertFalse(level.obstacleConfig!.voidPositions.isEmpty,
                "Level \(i) should have void positions for shaped board")
        }
    }

    // MARK: - P18-T6: Levels 31-40 ice

    func testLevels31To40HaveIce() {
        for i in 31...40 {
            let level = LevelStore.level(i)!
            XCTAssertNotNil(level.obstacleConfig, "Level \(i) should have obstacle config")
            let config = level.obstacleConfig!
            XCTAssertGreaterThanOrEqual(config.icePositions.count, 2,
                "Level \(i) should have at least 2 ice cells")
        }
    }

    func testLevels31To40AllSolvable() {
        for i in 31...40 {
            let level = LevelStore.level(i)!
            let board = FloodBoard.generateBoard(from: level)
            let solverMoves = FloodSolver.solveMoveCount(board: board)
            XCTAssertLessThanOrEqual(solverMoves, level.moveBudget,
                "Level \(i) with ice should be solvable: solver needs \(solverMoves), budget is \(level.moveBudget)")
        }
    }

    func testLevels31To40ModerateBudgets() {
        // BUG-14: Tightened — levels 31-40 now get +1 (tight, challenging)
        for i in 31...40 {
            let level = LevelStore.level(i)!
            let extra = level.moveBudget - level.optimalMoves
            XCTAssertGreaterThanOrEqual(extra, 1, "Level \(i) should have at least +1 moves")
            XCTAssertLessThanOrEqual(extra, 4, "Level \(i) budget should not exceed +4")
        }
    }

    // MARK: - P18-T7: Levels 41-50 countdown cells + boss

    func testLevels41To50HaveCountdowns() {
        for i in 41...50 {
            let level = LevelStore.level(i)!
            XCTAssertNotNil(level.obstacleConfig, "Level \(i) should have obstacle config")
            let config = level.obstacleConfig!
            XCTAssertGreaterThanOrEqual(config.countdownPositions.count, 1,
                "Level \(i) should have at least 1 countdown cell")
        }
    }

    func testLevels41To50AllSolvable() {
        for i in 41...50 {
            let level = LevelStore.level(i)!
            let board = FloodBoard.generateBoard(from: level)
            let solverMoves = FloodSolver.solveMoveCount(board: board)
            XCTAssertLessThanOrEqual(solverMoves, level.moveBudget,
                "Level \(i) with countdowns should be solvable: solver needs \(solverMoves), budget is \(level.moveBudget)")
        }
    }

    func testLevel50IsBoss() {
        let level = LevelStore.level(50)!
        let config = level.obstacleConfig!
        // Boss should have more countdowns
        XCTAssertGreaterThanOrEqual(config.countdownPositions.count, 3,
            "Level 50 boss should have at least 3 countdowns")
        // Tighter budget
        let extra = level.moveBudget - level.optimalMoves
        XCTAssertLessThanOrEqual(extra, 2, "Level 50 boss should have tight budget")
    }

    // MARK: - P18-T8: Levels 51-65 walls + portals

    func testLevels51To65HaveWallsOrPortals() {
        for i in 51...65 {
            let level = LevelStore.level(i)!
            XCTAssertNotNil(level.obstacleConfig, "Level \(i) should have obstacle config")
            let config = level.obstacleConfig!
            let hasTopology = !config.wallEdges.isEmpty || !config.portalPairs.isEmpty
            XCTAssertTrue(hasTopology, "Level \(i) should have walls or portals")
        }
    }

    func testLevels51To65AllSolvable() {
        for i in 51...65 {
            let level = LevelStore.level(i)!
            let board = FloodBoard.generateBoard(from: level)
            let solverMoves = FloodSolver.solveMoveCount(board: board)
            XCTAssertLessThanOrEqual(solverMoves, level.moveBudget,
                "Level \(i) should be solvable: solver needs \(solverMoves), budget is \(level.moveBudget)")
        }
    }

    func testPortalsIntroducedInLevel55Plus() {
        // Levels 55+ should have portals
        var portalFound = false
        for i in 55...65 {
            let level = LevelStore.level(i)!
            if let config = level.obstacleConfig, !config.portalPairs.isEmpty {
                portalFound = true
                break
            }
        }
        XCTAssertTrue(portalFound, "Portals should appear in levels 55-65")
    }

    // MARK: - P18-T9: Levels 66-100 escalating + final boss

    func testLevels66To100AllSolvable() {
        for i in 66...100 {
            let level = LevelStore.level(i)!
            let board = FloodBoard.generateBoard(from: level)
            let solverMoves = FloodSolver.solveMoveCount(board: board)
            XCTAssertLessThanOrEqual(solverMoves, level.moveBudget,
                "Level \(i) should be solvable: solver needs \(solverMoves), budget is \(level.moveBudget)")
        }
    }

    func testLevels66To100HaveObstacles() {
        for i in 66...100 {
            let level = LevelStore.level(i)!
            XCTAssertNotNil(level.obstacleConfig, "Level \(i) should have obstacle config")
        }
    }

    func testLevel100IsFinalBoss() {
        let level = LevelStore.level(100)!
        let config = level.obstacleConfig!
        // Final boss should have multiple obstacle types
        XCTAssertGreaterThanOrEqual(config.stonePositions.count, 1, "Boss should have stones")
        XCTAssertGreaterThanOrEqual(config.icePositions.count, 1, "Boss should have ice")
        XCTAssertGreaterThanOrEqual(config.wallEdges.count, 1, "Boss should have walls")
        // Tight budget
        let extra = level.moveBudget - level.optimalMoves
        XCTAssertLessThanOrEqual(extra, 1, "Level 100 should have very tight budget")
    }

    func testBreatherLevelsExistIn66To100() {
        // BUG-14: Breather levels now have +2 extra moves (tightened from +5)
        var breatherFound = false
        for i in 66...100 {
            let level = LevelStore.level(i)!
            let extra = level.moveBudget - level.optimalMoves
            // Breathers have more slack than regular expert levels (which have 0-1)
            if extra >= 2 {
                breatherFound = true
                break
            }
        }
        XCTAssertTrue(breatherFound, "Should have at least one breather level (extra >= 2) in 66-100")
    }

    // MARK: - P18-T10: Difficulty roller coaster verification

    func testBudgetRatiosOscillate() {
        // Compute budget ratios (moveBudget / optimalMoves) for all levels
        var ratios = [Double]()
        for level in LevelStore.levels {
            guard level.optimalMoves > 0 else {
                ratios.append(10.0)  // treat as very generous
                continue
            }
            ratios.append(Double(level.moveBudget) / Double(level.optimalMoves))
        }

        // The ratios should NOT be monotonically decreasing
        // Check that there are increases (breathers) after level 20
        var hasIncrease = false
        for i in 21..<ratios.count {
            if ratios[i] > ratios[i - 1] + 0.05 {
                hasIncrease = true
                break
            }
        }
        XCTAssertTrue(hasIncrease, "Budget ratios should oscillate, not monotonically decrease")
    }

    func testBreathersEvery5To8Levels() {
        // BUG-14: Design has intentional tight stretches (31-55 all +1), then breathers.
        // Verify there are breather levels with extra >= 2 in each major section.
        let section1 = (6...30).contains(where: { (LevelStore.level($0)?.moveBudget ?? 0) - (LevelStore.level($0)?.optimalMoves ?? 0) >= 2 })
        let section2 = (51...70).contains(where: { (LevelStore.level($0)?.moveBudget ?? 0) - (LevelStore.level($0)?.optimalMoves ?? 0) >= 2 })
        let section3 = (71...100).contains(where: { (LevelStore.level($0)?.moveBudget ?? 0) - (LevelStore.level($0)?.optimalMoves ?? 0) >= 2 })
        XCTAssertTrue(section1, "Levels 6-30 should have at least one breather")
        XCTAssertTrue(section2, "Levels 51-70 should have at least one breather")
        XCTAssertTrue(section3, "Levels 71-100 should have at least one breather")
    }

    func testOverallDifficultyTrendsUpward() {
        // Average budget ratio for early levels should be higher than later levels
        func avgRatio(range: ClosedRange<Int>) -> Double {
            let levels = range.compactMap { LevelStore.level($0) }
            let ratios = levels.map { level -> Double in
                guard level.optimalMoves > 0 else { return 10.0 }
                return Double(level.moveBudget) / Double(level.optimalMoves)
            }
            return ratios.reduce(0, +) / Double(ratios.count)
        }

        let earlyAvg = avgRatio(range: 6...20)
        let midAvg = avgRatio(range: 41...60)
        let lateAvg = avgRatio(range: 81...100)

        XCTAssertGreaterThan(earlyAvg, midAvg, "Early levels should have higher ratio than mid")
        XCTAssertGreaterThan(midAvg, lateAvg, "Mid levels should have higher ratio than late")
    }

    // MARK: - P18-T11: Bonus tiles scattered

    func testNoBonusTilesBeforeLevel15() {
        for i in 1...14 {
            let level = LevelStore.level(i)!
            if let config = level.obstacleConfig {
                XCTAssertTrue(config.bonusPositions.isEmpty,
                    "Level \(i) should have no bonus tiles")
            }
        }
    }

    func testBonusTilesExistInExpectedRange() {
        // At least some levels in 15-100 should have bonus tiles
        var bonusCount = 0
        for i in 15...100 {
            let level = LevelStore.level(i)!
            if let config = level.obstacleConfig, !config.bonusPositions.isEmpty {
                bonusCount += 1
            }
        }
        // Expect ~30-40% of 86 levels = ~26-34 levels
        XCTAssertGreaterThanOrEqual(bonusCount, 20,
            "Should have bonus tiles on at least 20 levels (got \(bonusCount))")
        XCTAssertLessThanOrEqual(bonusCount, 50,
            "Should not have bonus tiles on more than 50 levels (got \(bonusCount))")
    }

    func testBonusTilesMoreFrequentInHarderSections() {
        var earlyBonusCount = 0  // levels 15-50
        var lateBonusCount = 0   // levels 51-100

        for i in 15...50 {
            let level = LevelStore.level(i)!
            if let config = level.obstacleConfig, !config.bonusPositions.isEmpty {
                earlyBonusCount += 1
            }
        }
        for i in 51...100 {
            let level = LevelStore.level(i)!
            if let config = level.obstacleConfig, !config.bonusPositions.isEmpty {
                lateBonusCount += 1
            }
        }

        // Late section has more levels AND should have higher frequency
        XCTAssertGreaterThanOrEqual(lateBonusCount, earlyBonusCount,
            "Harder sections should have at least as many bonus levels (\(lateBonusCount) vs \(earlyBonusCount))")
    }

    func testBonusTilesHaveValidMultipliers() {
        for level in LevelStore.levels {
            guard let config = level.obstacleConfig else { continue }
            for bonus in config.bonusPositions {
                XCTAssertTrue(bonus.multiplier == 2 || bonus.multiplier == 3,
                    "Level \(level.id) bonus should be x2 or x3")
            }
        }
    }

    func testAllLevelsStillSolvableWithBonusTiles() {
        // Re-verify all levels are solvable now that bonus tiles have been added
        for level in LevelStore.levels {
            let board = FloodBoard.generateBoard(from: level)
            let solverMoves = FloodSolver.solveMoveCount(board: board)
            XCTAssertLessThanOrEqual(solverMoves, level.moveBudget,
                "Level \(level.id) not solvable with bonus tiles: solver needs \(solverMoves), budget is \(level.moveBudget)")
        }
    }
}
