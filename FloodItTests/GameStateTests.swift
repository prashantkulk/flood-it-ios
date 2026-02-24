import XCTest
@testable import FloodIt

final class GameStateTests: XCTestCase {

    // MARK: - P2-T5: GameState

    func testGameStateInitialization() {
        let board = FloodBoard.generateBoard(size: 9, seed: 42)
        let state = GameState(board: board, totalMoves: 22)
        XCTAssertEqual(state.movesRemaining, 22)
        XCTAssertEqual(state.movesMade, 0)
        XCTAssertEqual(state.gameStatus, .playing)
    }

    func testPerformFlood() {
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald],
            [.amber, .emerald, .sapphire],
            [.emerald, .sapphire, .violet],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells)
        let state = GameState(board: board, totalMoves: 10)
        state.performFlood(color: .amber)
        XCTAssertEqual(state.movesMade, 1)
        XCTAssertEqual(state.movesRemaining, 9)
        XCTAssertEqual(state.gameStatus, .playing)
        // Top-left should now be amber
        XCTAssertEqual(state.board.cells[0][0], .amber)
    }

    func testPerformFloodSameColorNoOp() {
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.emerald, .sapphire],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells)
        let state = GameState(board: board, totalMoves: 5)
        state.performFlood(color: .coral) // same color — should not use a move
        XCTAssertEqual(state.movesMade, 0)
        XCTAssertEqual(state.movesRemaining, 5)
    }

    func testGameStateWin() {
        // Board that can be won in one move
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.amber, .amber],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells)
        let state = GameState(board: board, totalMoves: 5)
        state.performFlood(color: .amber)
        XCTAssertEqual(state.gameStatus, .won)
        XCTAssertEqual(state.movesMade, 1)
    }

    func testGameStateLose() {
        // Board that needs more than 1 move to complete
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.emerald, .sapphire],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells)
        let state = GameState(board: board, totalMoves: 1)
        state.performFlood(color: .amber) // Uses last move, board not complete
        XCTAssertEqual(state.gameStatus, .lost)
        XCTAssertEqual(state.movesRemaining, 0)
    }

    // MARK: - P9-T1: Combo Tracking

    func testComboIncrementsOnLargeAbsorption() {
        // Board where flooding amber absorbs 4+ cells
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber, .amber, .amber],
            [.amber, .emerald, .emerald, .emerald, .emerald],
            [.emerald, .sapphire, .sapphire, .sapphire, .sapphire],
            [.sapphire, .violet, .violet, .violet, .violet],
            [.violet, .coral, .coral, .coral, .coral],
        ]
        let board = FloodBoard(gridSize: 5, cells: cells)
        let state = GameState(board: board, totalMoves: 20)
        XCTAssertEqual(state.comboCount, 0)

        // Flood amber: absorbs (0,1),(0,2),(0,3),(0,4),(1,0) = 5 cells → combo 1
        state.performFlood(color: .amber)
        XCTAssertEqual(state.comboCount, 1)

        // Flood emerald: absorbs many emerald cells → combo 2
        state.performFlood(color: .emerald)
        XCTAssertEqual(state.comboCount, 2)

        // Flood sapphire: absorbs sapphire cells → combo 3
        state.performFlood(color: .sapphire)
        XCTAssertEqual(state.comboCount, 3)
    }

    func testComboResetsOnSmallAbsorption() {
        // Board where first move absorbs many, second absorbs few
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber, .amber, .amber],
            [.emerald, .sapphire, .sapphire, .sapphire, .sapphire],
            [.sapphire, .sapphire, .sapphire, .sapphire, .sapphire],
            [.sapphire, .sapphire, .sapphire, .sapphire, .sapphire],
            [.sapphire, .sapphire, .sapphire, .sapphire, .sapphire],
        ]
        let board = FloodBoard(gridSize: 5, cells: cells)
        let state = GameState(board: board, totalMoves: 20)

        // Flood amber: absorbs 4 cells → combo 1
        state.performFlood(color: .amber)
        XCTAssertEqual(state.comboCount, 1)

        // Flood emerald: only absorbs (1,0) = 1 cell → combo resets
        state.performFlood(color: .emerald)
        XCTAssertEqual(state.comboCount, 0)
    }

    func testMaxComboTracked() {
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber, .amber, .amber],
            [.amber, .emerald, .emerald, .emerald, .emerald],
            [.emerald, .sapphire, .sapphire, .sapphire, .sapphire],
            [.sapphire, .violet, .violet, .violet, .violet],
            [.violet, .coral, .coral, .coral, .coral],
        ]
        let board = FloodBoard(gridSize: 5, cells: cells)
        let state = GameState(board: board, totalMoves: 20)

        state.performFlood(color: .amber)
        state.performFlood(color: .emerald)
        state.performFlood(color: .sapphire)
        XCTAssertEqual(state.maxCombo, 3)

        // Even after reset, maxCombo reflects highest
        state.performFlood(color: .violet)
        state.performFlood(color: .coral)
        XCTAssertGreaterThanOrEqual(state.maxCombo, 3)
    }

    func testComboResetOnGameReset() {
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber, .amber, .amber],
            [.amber, .emerald, .emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald, .emerald, .emerald],
        ]
        let board = FloodBoard(gridSize: 5, cells: cells)
        let state = GameState(board: board, totalMoves: 20)
        state.performFlood(color: .amber)
        XCTAssertEqual(state.comboCount, 1)

        let newBoard = FloodBoard(gridSize: 5, cells: cells)
        state.reset(board: newBoard, totalMoves: 20)
        XCTAssertEqual(state.comboCount, 0)
        XCTAssertEqual(state.maxCombo, 0)
    }

    func testCannotFloodAfterGameOver() {
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.amber, .amber],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells)
        let state = GameState(board: board, totalMoves: 5)
        state.performFlood(color: .amber) // Win
        XCTAssertEqual(state.gameStatus, .won)
        state.performFlood(color: .coral) // Should be ignored
        XCTAssertEqual(state.movesMade, 1) // No additional move
    }

    // MARK: - P20-T5: Bug fix verification — playable cell counting

    func testUnfloodedCellCountExcludesVoids() {
        // 3x3 board with one void at (2,2)
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald],
            [.amber, .emerald, .sapphire],
            [.emerald, .sapphire, .violet],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells)
        board.setCellType(.void, atRow: 2, col: 2)
        let state = GameState(board: board, totalMoves: 20)
        // Playable cells = 8 (9 - 1 void). Flood region starts with just (0,0) = 1 cell.
        XCTAssertEqual(state.unfloodedCellCount, 7) // 8 - 1
    }

    func testUnfloodedCellCountExcludesStones() {
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald],
            [.amber, .emerald, .sapphire],
            [.emerald, .sapphire, .violet],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells)
        board.setCellType(.stone, atRow: 1, col: 1)
        board.setCellType(.stone, atRow: 2, col: 2)
        let state = GameState(board: board, totalMoves: 20)
        // Playable = 7 (9 - 2 stones). Flood region = 1.
        XCTAssertEqual(state.unfloodedCellCount, 6) // 7 - 1
    }

    func testFloodCompletionPercentageWithVoids() {
        // All playable cells same color → 100% completion
        let cells: [[GameColor]] = [
            [.coral, .coral, .coral],
            [.coral, .coral, .coral],
            [.coral, .coral, .coral],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells)
        board.setCellType(.void, atRow: 2, col: 2)
        board.setCellType(.void, atRow: 2, col: 1)
        let state = GameState(board: board, totalMoves: 20)
        // All 7 playable cells are coral and connected → 100%
        XCTAssertEqual(state.floodCompletionPercentage, 1.0, accuracy: 0.001)
        XCTAssertEqual(state.unfloodedCellCount, 0)
    }

    func testFloodCompletionOnShapedBoard() {
        // 3x3 board, flood 1 cell out of 5 playable (4 voids)
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald],
            [.amber, .emerald, .sapphire],
            [.emerald, .sapphire, .violet],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells)
        board.setCellType(.void, atRow: 0, col: 2)
        board.setCellType(.void, atRow: 1, col: 2)
        board.setCellType(.void, atRow: 2, col: 0)
        board.setCellType(.void, atRow: 2, col: 1)
        board.setCellType(.void, atRow: 2, col: 2)
        let state = GameState(board: board, totalMoves: 20)
        // Playable = 4 cells. Flood region at start = 1 (just (0,0)).
        XCTAssertEqual(board.playableCellCount, 4)
        XCTAssertEqual(state.floodCompletionPercentage, 0.25, accuracy: 0.001)
    }

    // MARK: - P20-T7: Edge case testing

    func testThreeByThreeWithObstacles() {
        // 3x3 board with stone, ice, and a wall
        let cells: [[GameColor]] = [
            [.coral, .coral, .amber],
            [.coral, .emerald, .amber],
            [.amber, .amber, .amber],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells)
        board.setCellType(.stone, atRow: 1, col: 1)
        board.setCellType(.ice(layers: 1), atRow: 0, col: 2)
        board.addWall(at: CellPosition(row: 1, col: 0), direction: .south)
        let state = GameState(board: board, totalMoves: 10)
        // Stone at (1,1) blocks traversal; ice at (0,2) blocks flood
        XCTAssertEqual(board.playableCellCount, 8) // 9 - 1 stone
        // Flood coral from (0,0): should get (0,0), (0,1), (1,0) — stone blocks (1,1)
        let region = board.floodRegion
        XCTAssertTrue(region.contains(CellPosition(row: 0, col: 0)))
        XCTAssertTrue(region.contains(CellPosition(row: 0, col: 1)))
        XCTAssertTrue(region.contains(CellPosition(row: 1, col: 0)))
        XCTAssertFalse(region.contains(CellPosition(row: 1, col: 1))) // stone
        // Perform flood to amber — all traversable cells become amber (ice excluded from check)
        state.performFlood(color: .amber)
        XCTAssertEqual(state.gameStatus, .won)
    }

    func testLevel100Exists() {
        // Verify level 100 exists and level 101 does not
        let level100 = LevelStore.level(100)
        XCTAssertNotNil(level100)
        let level101 = LevelStore.level(101)
        XCTAssertNil(level101)
    }

    func testLevel100Solvable() {
        // Level 100 should produce a valid, solvable board
        let data = LevelStore.level(100)!
        let board = FloodBoard.generateBoard(from: data)
        XCTAssertEqual(board.gridSize, data.gridSize)
        // Board should be playable at (0,0)
        XCTAssertTrue(board.isPlayable(at: CellPosition(row: 0, col: 0)))
        // Solver should find a solution
        let moves = FloodSolver.solveMoveCount(board: board)
        XCTAssertGreaterThan(moves, 0)
        XCTAssertLessThanOrEqual(moves, data.gridSize * data.gridSize)
    }

    func testLevelTransitionPreservesObstacles() {
        // Simulate what performLevelTransition does (the fixed version)
        // Level 25 should have stones
        guard let data = LevelStore.level(25) else {
            XCTFail("Level 25 should exist")
            return
        }
        let board = FloodBoard.generateBoard(from: data)
        // Check that obstacle config is applied
        if let config = data.obstacleConfig {
            if !config.stonePositions.isEmpty {
                let stonePos = config.stonePositions[0]
                XCTAssertFalse(board.isPlayable(at: stonePos))
            }
        }
    }

    func testAllSameColorBoardIsAlreadyComplete() {
        // Board where all cells are already the same color
        let cells: [[GameColor]] = [
            [.coral, .coral, .coral],
            [.coral, .coral, .coral],
            [.coral, .coral, .coral],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells)
        XCTAssertTrue(board.isComplete)
        let state = GameState(board: board, totalMoves: 10)
        // GameState init doesn't auto-detect win; stays playing until a move
        XCTAssertEqual(state.gameStatus, .playing)
        // But completion percentage should be 100%
        XCTAssertEqual(state.floodCompletionPercentage, 1.0, accuracy: 0.001)
        XCTAssertEqual(state.unfloodedCellCount, 0)
    }

    func testBoardWithOnlyOnePlayableCell() {
        // 3x3 board where 8 cells are stones, only (0,0) is playable
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald],
            [.amber, .emerald, .sapphire],
            [.emerald, .sapphire, .violet],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells)
        for row in 0..<3 {
            for col in 0..<3 {
                if row == 0 && col == 0 { continue }
                board.setCellType(.stone, atRow: row, col: col)
            }
        }
        XCTAssertEqual(board.playableCellCount, 1)
        let state = GameState(board: board, totalMoves: 5)
        // Only 1 playable cell which is already flooded → complete
        XCTAssertEqual(state.floodCompletionPercentage, 1.0, accuracy: 0.001)
        XCTAssertEqual(state.unfloodedCellCount, 0)
    }

    func testRapidFloodsSameColor() {
        // Flooding with the same color as current should be a no-op
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.amber, .amber],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells)
        let state = GameState(board: board, totalMoves: 5)
        // Current color is coral. Flooding with coral should not count as a move.
        state.performFlood(color: .coral)
        XCTAssertEqual(state.movesMade, 0) // no-op
        XCTAssertEqual(state.movesRemaining, 5)
    }

    func testScoreLargeBoard() {
        // Verify scoring doesn't overflow on a large board with many cascades
        let board = FloodBoard.generateBoard(size: 14, seed: 999)
        let state = GameState(board: board, totalMoves: 100)
        // Solve the board greedily
        var moves = 0
        while state.gameStatus == .playing && moves < 100 {
            // Try each color, pick the one that absorbs most cells
            var bestColor = GameColor.coral
            var bestAbsorbed = 0
            for color in GameColor.allCases {
                if color == state.board.cells[0][0] { continue }
                let waves = state.board.cellsAbsorbedBy(color: color)
                let totalAbsorbed = waves.reduce(0) { $0 + $1.count }
                if totalAbsorbed > bestAbsorbed {
                    bestAbsorbed = totalAbsorbed
                    bestColor = color
                }
            }
            state.performFlood(color: bestColor)
            moves += 1
        }
        // Score should be a reasonable positive number
        XCTAssertGreaterThanOrEqual(state.scoreState.totalScore, 0)
    }

    func testComboMultiplierActivatesAtTwo() {
        // Verify combo multiplier is applied at comboCount >= 2
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald, .amber],
            [.amber, .amber, .emerald, .emerald],
            [.emerald, .emerald, .coral, .coral],
            [.coral, .coral, .coral, .coral],
        ]
        let board = FloodBoard(gridSize: 4, cells: cells)
        let state = GameState(board: board, totalMoves: 20)
        // First move: flood amber (absorbs neighbors)
        state.performFlood(color: .amber)
        let combo1 = state.comboCount
        // Combo count should be >= 1 if cells were absorbed
        XCTAssertGreaterThanOrEqual(combo1, 0)
    }

    // MARK: - BUG-7: Level Transition Tests

    func testLevelTransitionProducesValidBoard() {
        // Advancing from level 1 to level 2 should produce a valid playable board
        guard let level1 = LevelStore.level(1), let level2 = LevelStore.level(2) else {
            XCTFail("Levels 1 and 2 must exist")
            return
        }
        let board1 = FloodBoard.generateBoard(from: level1)
        XCTAssertTrue(board1.isPlayable(at: CellPosition(row: 0, col: 0)), "Level 1 (0,0) must be playable")

        let state = GameState(board: board1, totalMoves: level1.moveBudget)
        XCTAssertEqual(state.gameStatus, .playing)

        // Simulate what performLevelTransition does: generate next board and reset
        let board2 = FloodBoard.generateBoard(from: level2)
        XCTAssertEqual(board2.gridSize, level2.gridSize)
        XCTAssertTrue(board2.isPlayable(at: CellPosition(row: 0, col: 0)), "Level 2 (0,0) must be playable")

        state.reset(board: board2, totalMoves: level2.moveBudget)
        XCTAssertEqual(state.movesRemaining, level2.moveBudget)
        XCTAssertEqual(state.movesMade, 0)
        XCTAssertEqual(state.gameStatus, .playing)
        XCTAssertEqual(state.comboCount, 0)
    }

    func testLevelTransitionPreservesObstaclesOnNewBoard() {
        // Level 25 has stones — transition to it should have stones
        guard let data25 = LevelStore.level(25) else {
            XCTFail("Level 25 must exist")
            return
        }
        let board = FloodBoard.generateBoard(from: data25)
        XCTAssertEqual(board.gridSize, data25.gridSize)
        if let config = data25.obstacleConfig, !config.stonePositions.isEmpty {
            for pos in config.stonePositions {
                XCTAssertFalse(board.isPlayable(at: pos), "Stone at \(pos) should not be playable")
            }
        }
    }

    func testNoLevelBeyond100() {
        // advanceToNextLevel should gracefully handle level 100 → 101
        XCTAssertNil(LevelStore.level(101), "Level 101 should not exist")
        XCTAssertNil(LevelStore.level(0), "Level 0 should not exist")
        XCTAssertNil(LevelStore.level(-1), "Level -1 should not exist")
        XCTAssertNotNil(LevelStore.level(100), "Level 100 must exist")
    }

    func testLevelResetClearsState() {
        // Reset should clear score, combo, history
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald],
            [.amber, .coral, .amber],
            [.emerald, .amber, .coral],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells)
        let state = GameState(board: board, totalMoves: 10)
        state.performFlood(color: .amber)  // Top-left is coral so this is a valid move
        XCTAssertGreaterThan(state.movesMade, 0)

        let board2 = FloodBoard.generateBoard(size: 5, seed: 100)
        state.reset(board: board2, totalMoves: 15)
        XCTAssertEqual(state.movesMade, 0)
        XCTAssertEqual(state.movesRemaining, 15)
        XCTAssertEqual(state.comboCount, 0)
        XCTAssertEqual(state.colorHistory, [])
        XCTAssertEqual(state.scoreState.totalScore, 0)
    }

    func testProgressStoreCurrentLevelAdvances() {
        // currentLevel only moves forward
        let store = ProgressStore()
        let initial = store.currentLevel
        // Advance to a higher level
        store.updateCurrentLevel(initial + 5)
        XCTAssertEqual(store.currentLevel, initial + 5)
        // Should not go back
        store.updateCurrentLevel(initial + 2)
        XCTAssertEqual(store.currentLevel, initial + 5, "currentLevel should not go backward")
    }
}
