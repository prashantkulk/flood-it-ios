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
}
