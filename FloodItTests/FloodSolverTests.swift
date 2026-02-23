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

    // MARK: - P16-T9: Solver with obstacles

    func testSolverSolvesBoardWithStones() {
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 4), count: 4)
        types[1][1] = .stone
        types[2][2] = .stone
        let board = FloodBoard.generateBoard(size: 4, seed: 42)
        var boardWithStones = FloodBoard(gridSize: 4, cells: board.cells, cellTypes: types)
        let moves = FloodSolver.solve(board: boardWithStones)
        var testBoard = boardWithStones
        for color in moves {
            testBoard.flood(color: color)
        }
        XCTAssertTrue(testBoard.isComplete, "Solver should handle stones")
    }

    func testSolverSolvesBoardWithIce() {
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[0][1] = .ice(layers: 2)
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber],
            [.amber, .emerald, .sapphire],
            [.emerald, .sapphire, .violet],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)
        let moves = FloodSolver.solve(board: board)
        var testBoard = board
        var rng = SeededRandomNumberGenerator(seed: 0)
        for color in moves {
            testBoard.flood(color: color)
            testBoard.tickCountdowns(using: &rng)
        }
        XCTAssertTrue(testBoard.isComplete, "Solver should handle ice layers")
    }

    func testSolverSolvesBoardWithPortals() {
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[0][0] = .portal(pairId: 1)
        types[2][2] = .portal(pairId: 1)
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald],
            [.amber, .emerald, .sapphire],
            [.emerald, .sapphire, .coral],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)
        let moves = FloodSolver.solve(board: board)
        var testBoard = board
        for color in moves {
            testBoard.flood(color: color)
        }
        XCTAssertTrue(testBoard.isComplete, "Solver should handle portals")
    }
}
