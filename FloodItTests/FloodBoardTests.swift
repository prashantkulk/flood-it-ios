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

    // MARK: - P2-T2: flood(color:)

    func testFloodChangesRegionColor() {
        // Top-left is coral, adjacent (0,1) is amber, (1,0) is emerald
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald],
            [.emerald, .amber, .emerald],
            [.emerald, .emerald, .emerald],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells)
        board.flood(color: .amber)
        // Top-left should now be amber
        XCTAssertEqual(board.color(atRow: 0, col: 0), .amber)
        // (0,1) was amber and adjacent — should be absorbed into flood region
        XCTAssertEqual(board.color(atRow: 0, col: 1), .amber)
        // (1,1) was also amber and adjacent to (0,1) — should be absorbed too
        XCTAssertEqual(board.color(atRow: 1, col: 1), .amber)
    }

    func testFloodAbsorbsAdjacentCells() {
        let cells: [[GameColor]] = [
            [.coral, .emerald, .emerald],
            [.emerald, .emerald, .sapphire],
            [.sapphire, .sapphire, .sapphire],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells)
        // Flood with emerald — should absorb all connected emerald cells
        board.flood(color: .emerald)
        let region = board.floodRegion()
        // Should have absorbed (0,0), (0,1), (0,2), (1,0), (1,1) — all emerald connected
        XCTAssertEqual(region.count, 5)
    }

    func testFloodDoesNotAbsorbDisconnected() {
        let cells: [[GameColor]] = [
            [.coral, .amber, .sapphire],
            [.amber, .amber, .sapphire],
            [.sapphire, .sapphire, .coral],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells)
        // Flood with sapphire — only (0,0) changes; (2,2) is coral but not connected
        board.flood(color: .sapphire)
        // Check that disconnected coral at (2,2) is still coral... wait, we flooded sapphire
        // Let me think: top-left was coral. We flood sapphire. Region is just (0,0).
        // (0,0) becomes sapphire. Then absorb adjacent sapphire: (0,2) is sapphire but not adjacent to (0,0).
        // Actually (0,1) is amber, (1,0) is amber. No adjacent sapphire. Region stays 1.
        XCTAssertEqual(board.color(atRow: 0, col: 0), .sapphire)
        let region = board.floodRegion()
        XCTAssertEqual(region.count, 1)
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
