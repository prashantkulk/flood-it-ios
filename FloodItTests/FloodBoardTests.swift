import XCTest
@testable import FloodIt

final class FloodBoardTests: XCTestCase {

    // MARK: - testBoardInitialization

    func testBoardInitialization() {
        let board = FloodBoard(gridSize: 9)
        XCTAssertEqual(board.gridSize, 9)
        // Default board should have 9 rows of 9 columns
        XCTAssertEqual(board.cells.count, 9)
        for row in board.cells {
            XCTAssertEqual(row.count, 9)
        }
    }

    // MARK: - testFloodCellProperties

    func testFloodCellProperties() {
        let cell = FloodCell(row: 3, col: 5, color: .sapphire)
        XCTAssertEqual(cell.row, 3)
        XCTAssertEqual(cell.col, 5)
        XCTAssertEqual(cell.color, .sapphire)
    }

    // MARK: - testGameColorCount

    func testGameColorCount() {
        XCTAssertEqual(GameColor.allCases.count, 5)
        let expected: [GameColor] = [.coral, .amber, .emerald, .sapphire, .violet]
        XCTAssertEqual(GameColor.allCases, expected)
    }

    // MARK: - testFloodRegion

    func testFloodRegionSingleColor() {
        // Board where top-left 2x2 is coral, rest is emerald
        let cells: [[GameColor]] = [
            [.coral, .coral, .emerald],
            [.coral, .coral, .emerald],
            [.emerald, .emerald, .emerald],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells)
        let region = board.floodRegion()
        XCTAssertEqual(region.count, 4)
        XCTAssertTrue(region.contains(CellPosition(row: 0, col: 0)))
        XCTAssertTrue(region.contains(CellPosition(row: 0, col: 1)))
        XCTAssertTrue(region.contains(CellPosition(row: 1, col: 0)))
        XCTAssertTrue(region.contains(CellPosition(row: 1, col: 1)))
    }

    // MARK: - P2-T1: generateBoard

    func testSameSeedSameBoard() {
        let board1 = FloodBoard.generateBoard(size: 9, seed: 42)
        let board2 = FloodBoard.generateBoard(size: 9, seed: 42)
        XCTAssertEqual(board1.cells, board2.cells)
    }

    func testDifferentSeedDifferentBoard() {
        let board1 = FloodBoard.generateBoard(size: 9, seed: 42)
        let board2 = FloodBoard.generateBoard(size: 9, seed: 99)
        XCTAssertNotEqual(board1.cells, board2.cells)
    }

    func testGenerateBoardUsesAllColors() {
        let board = FloodBoard.generateBoard(size: 9, seed: 12345)
        let allColors = Set(board.cells.flatMap { $0 })
        // With 81 cells and 5 colors, extremely likely all colors appear
        XCTAssertEqual(allColors.count, 5)
    }

    func testGenerateBoardCorrectSize() {
        let board = FloodBoard.generateBoard(size: 5, seed: 1)
        XCTAssertEqual(board.gridSize, 5)
        XCTAssertEqual(board.cells.count, 5)
        for row in board.cells {
            XCTAssertEqual(row.count, 5)
        }
    }
}
