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
}
