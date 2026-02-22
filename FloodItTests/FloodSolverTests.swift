import XCTest
@testable import FloodIt

final class FloodSolverTests: XCTestCase {

    // MARK: - P2-T8: FloodSolver

    func testSolverSolvesBoard() {
        let board = FloodBoard.generateBoard(size: 9, seed: 42)
        let moves = FloodSolver.solve(board: board)
        // Apply all moves and verify the board is complete
        var testBoard = board
        for color in moves {
            testBoard.flood(color: color)
        }
        XCTAssertTrue(testBoard.isComplete)
    }

    func testSolverSolvesSmallBoard() {
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.emerald, .sapphire],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells)
        let moves = FloodSolver.solve(board: board)
        var testBoard = board
        for color in moves {
            testBoard.flood(color: color)
        }
        XCTAssertTrue(testBoard.isComplete)
        XCTAssertLessThanOrEqual(moves.count, 4) // 4 colors max for 2x2
    }

    func testSolverSolvesUniformBoard() {
        let cells: [[GameColor]] = [
            [.coral, .coral],
            [.coral, .coral],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells)
        let moves = FloodSolver.solve(board: board)
        XCTAssertEqual(moves.count, 0) // Already complete
    }

    func testSolverSolvesMultipleSeeds() {
        for seed: UInt64 in 1...10 {
            let board = FloodBoard.generateBoard(size: 9, seed: seed)
            let moves = FloodSolver.solve(board: board)
            var testBoard = board
            for color in moves {
                testBoard.flood(color: color)
            }
            XCTAssertTrue(testBoard.isComplete, "Solver failed for seed \(seed)")
        }
    }
}
