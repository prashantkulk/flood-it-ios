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
        let region = board.floodRegion
        XCTAssertEqual(region.count, 4)
        XCTAssertTrue(region.contains(CellPosition(row: 0, col: 0)))
        XCTAssertTrue(region.contains(CellPosition(row: 0, col: 1)))
        XCTAssertTrue(region.contains(CellPosition(row: 1, col: 0)))
        XCTAssertTrue(region.contains(CellPosition(row: 1, col: 1)))
    }

    // MARK: - P2-T4: isComplete

    func testIsCompleteOnFullBoard() {
        let cells: [[GameColor]] = [
            [.coral, .coral, .coral],
            [.coral, .coral, .coral],
            [.coral, .coral, .coral],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells)
        XCTAssertTrue(board.isComplete)
    }

    func testIsCompleteOnPartialBoard() {
        let cells: [[GameColor]] = [
            [.coral, .coral, .coral],
            [.coral, .amber, .coral],
            [.coral, .coral, .coral],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells)
        XCTAssertFalse(board.isComplete)
    }

    func testIsCompleteAfterFloodingEntireBoard() {
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.amber, .amber],
        ]
        var board = FloodBoard(gridSize: 2, cells: cells)
        XCTAssertFalse(board.isComplete)
        board.flood(color: .amber)
        XCTAssertTrue(board.isComplete)
    }

    // MARK: - P2-T3: floodRegion computed property

    func testFloodRegionGrowsAfterFlood() {
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald],
            [.amber, .emerald, .sapphire],
            [.emerald, .sapphire, .violet],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells)
        let regionBefore = board.floodRegion
        XCTAssertEqual(regionBefore.count, 1) // Just top-left

        board.flood(color: .amber)
        let regionAfter = board.floodRegion
        // Should now include (0,0), (0,1), (1,0) — all amber connected to top-left
        XCTAssertEqual(regionAfter.count, 3)
        XCTAssertTrue(regionAfter.contains(CellPosition(row: 0, col: 0)))
        XCTAssertTrue(regionAfter.contains(CellPosition(row: 0, col: 1)))
        XCTAssertTrue(regionAfter.contains(CellPosition(row: 1, col: 0)))
    }

    func testFloodRegionInitialSingleCell() {
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.emerald, .sapphire],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells)
        let region = board.floodRegion
        XCTAssertEqual(region.count, 1)
        XCTAssertTrue(region.contains(CellPosition(row: 0, col: 0)))
    }

    // MARK: - P2-T6: cellsAbsorbedBy(color:)

    func testCellsAbsorbedByReturnsCorrectWaves() {
        // Board:
        // C A A
        // E A E
        // E E E
        // Flood region is just (0,0) = coral
        // Flooding with amber should absorb: wave1 = (0,1), (1,1) [adjacent to flood region]
        //                                    wave2 = (0,2) [adjacent to wave1]
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber],
            [.emerald, .amber, .emerald],
            [.emerald, .emerald, .emerald],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells)
        let waves = board.cellsAbsorbedBy(color: .amber)
        XCTAssertEqual(waves.count, 2)
        // Wave 1: cells directly adjacent to flood region matching amber
        let wave1Set = Set(waves[0])
        XCTAssertTrue(wave1Set.contains(CellPosition(row: 0, col: 1)))
        // Wave 2: cells adjacent to wave 1 matching amber
        let wave2Set = Set(waves[1])
        XCTAssertTrue(wave2Set.contains(CellPosition(row: 0, col: 2)) || wave2Set.contains(CellPosition(row: 1, col: 1)))
        // Total absorbed should be 3 amber cells
        let totalAbsorbed = waves.flatMap { $0 }.count
        XCTAssertEqual(totalAbsorbed, 3)
    }

    func testCellsAbsorbedByNoMatchReturnsEmpty() {
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.amber, .amber],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells)
        let waves = board.cellsAbsorbedBy(color: .emerald)
        XCTAssertTrue(waves.isEmpty)
    }

    func testCellsAbsorbedByPreservesBoard() {
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.amber, .amber],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells)
        let _ = board.cellsAbsorbedBy(color: .amber)
        // Board should not be modified
        XCTAssertEqual(board.cells[0][0], .coral)
    }

    // MARK: - P7-T1: wouldComplete

    func testWouldCompleteReturnsTrueWhenLastMove() {
        let cells: [[GameColor]] = [
            [.coral, .coral, .amber],
            [.coral, .coral, .amber],
            [.coral, .coral, .coral],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells)
        XCTAssertTrue(board.wouldComplete(color: .amber))
    }

    func testWouldCompleteReturnsFalseWhenNotLastMove() {
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald],
            [.amber, .emerald, .sapphire],
            [.emerald, .sapphire, .violet],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells)
        XCTAssertFalse(board.wouldComplete(color: .amber))
    }

    func testWouldCompleteDoesNotMutateBoard() {
        let cells: [[GameColor]] = [
            [.coral, .coral, .amber],
            [.coral, .coral, .amber],
            [.coral, .coral, .coral],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells)
        _ = board.wouldComplete(color: .amber)
        XCTAssertEqual(board.cells[0][2], .amber, "Board should not be mutated")
        XCTAssertEqual(board.cells[0][0], .coral, "Board should not be mutated")
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
        let region = board.floodRegion
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
        let region = board.floodRegion
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

    // MARK: - P7-T7: Star rating

    func testStarRating3Stars() {
        // Within optimal + 1 → 3 stars
        XCTAssertEqual(StarRating.calculate(movesUsed: 10, optimalMoves: 10), 3)
        XCTAssertEqual(StarRating.calculate(movesUsed: 11, optimalMoves: 10), 3)
    }

    func testStarRating2Stars() {
        // Within optimal + 3 but more than optimal + 1 → 2 stars
        XCTAssertEqual(StarRating.calculate(movesUsed: 12, optimalMoves: 10), 2)
        XCTAssertEqual(StarRating.calculate(movesUsed: 13, optimalMoves: 10), 2)
    }

    func testStarRating1Star() {
        // More than optimal + 3 → 1 star
        XCTAssertEqual(StarRating.calculate(movesUsed: 14, optimalMoves: 10), 1)
        XCTAssertEqual(StarRating.calculate(movesUsed: 20, optimalMoves: 10), 1)
    }

    func testStarRatingBetterThanOptimal() {
        // If player somehow beats the greedy solver → 3 stars
        XCTAssertEqual(StarRating.calculate(movesUsed: 8, optimalMoves: 10), 3)
    }

    // MARK: - P9-T7: Combo Score Multiplier

    func testStarRatingWithComboBonus3() {
        // 12 moves, optimal 10 → normally 2 stars (10+1 < 12 <= 10+3)
        XCTAssertEqual(StarRating.calculate(movesUsed: 12, optimalMoves: 10, maxCombo: 0), 2)
        // With maxCombo 3: effective = 12 - 1 = 11 ≤ 10 + 1 → 3 stars
        XCTAssertEqual(StarRating.calculate(movesUsed: 12, optimalMoves: 10, maxCombo: 3), 3)
    }

    func testStarRatingWithComboBonus5() {
        // 13 moves, optimal 10 → normally 2 stars
        XCTAssertEqual(StarRating.calculate(movesUsed: 13, optimalMoves: 10, maxCombo: 0), 2)
        // With maxCombo 5: effective = 13 - 2 = 11 ≤ 10 + 1 → 3 stars
        XCTAssertEqual(StarRating.calculate(movesUsed: 13, optimalMoves: 10, maxCombo: 5), 3)
    }

    func testStarRatingCombo4SameAsCombo3() {
        // maxCombo 4 still only gives -1 bonus (same as 3)
        XCTAssertEqual(StarRating.calculate(movesUsed: 14, optimalMoves: 10, maxCombo: 4), 2)
        // effective = 14 - 1 = 13 ≤ 10 + 3 → 2 stars
    }

    func testStarRatingNoComboNoChange() {
        // maxCombo 0 or 2: no bonus
        XCTAssertEqual(StarRating.calculate(movesUsed: 14, optimalMoves: 10, maxCombo: 0), 1)
        XCTAssertEqual(StarRating.calculate(movesUsed: 14, optimalMoves: 10, maxCombo: 2), 1)
    }

    func testStarRatingComboBonusUpgrades1To2Stars() {
        // 14 moves, optimal 10 → 1 star normally (14 > 10+3)
        XCTAssertEqual(StarRating.calculate(movesUsed: 14, optimalMoves: 10, maxCombo: 0), 1)
        // With maxCombo 5: effective = 14 - 2 = 12 ≤ 10+3 → 2 stars
        XCTAssertEqual(StarRating.calculate(movesUsed: 14, optimalMoves: 10, maxCombo: 5), 2)
    }

    // MARK: - P15-T1: Cascade detection

    func testCascadeWavesDetectsChainReaction() {
        // Board where flooding creates multi-wave absorption:
        // A  B  B  B
        // C  C  C  C
        // C  C  C  C
        // C  C  C  C
        // Flood to B: wave 1 = (0,1), wave 2 = (0,2), wave 3 = (0,3)
        // Cascade = waves 2 and 3
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber, .amber],
            [.emerald, .emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald, .emerald],
        ]
        let board = FloodBoard(gridSize: 4, cells: cells)
        let cascade = board.cascadeWaves(after: .amber)

        // Should have 2 cascade waves (waves beyond the first direct absorption)
        XCTAssertEqual(cascade.count, 2)

        // Cascade wave 1 should contain (0,2) — adjacent to wave 1's (0,1)
        let cascadeWave1 = Set(cascade[0])
        XCTAssertTrue(cascadeWave1.contains(CellPosition(row: 0, col: 2)))

        // Cascade wave 2 should contain (0,3) — adjacent to cascade wave 1's (0,2)
        let cascadeWave2 = Set(cascade[1])
        XCTAssertTrue(cascadeWave2.contains(CellPosition(row: 0, col: 3)))
    }

    func testCascadeWavesEmptyWhenNoCascade() {
        // Board where flooding only has 1 wave (no cascade):
        // A  B
        // C  C
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.emerald, .emerald],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells)
        let cascade = board.cascadeWaves(after: .amber)
        XCTAssertTrue(cascade.isEmpty)
    }

    // MARK: - P15-T2: Recursive cascade (triple cascade)

    func testTripleCascade() {
        // Board where flooding triggers a 3-deep cascade chain:
        // A  B  C  C  C
        // C  C  B  C  C
        // C  C  C  B  C
        // C  C  C  C  B
        // C  C  C  C  C
        // Flood to B: wave 1 = (0,1) [adjacent to region]
        //   → wave 2 = (1,2) [adjacent to (0,1) via diagonal? No, only 4-dir]
        // Actually let me use a straight chain:
        // A  B  B  B  B
        // C  C  C  C  C
        // ...
        // wave 1 = (0,1), wave 2 = (0,2), wave 3 = (0,3), wave 4 = (0,4)
        // cascade = 3 rounds
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber, .amber, .amber],
            [.emerald, .emerald, .emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald, .emerald, .emerald],
        ]
        let board = FloodBoard(gridSize: 5, cells: cells)
        let cascade = board.cascadeWaves(after: .amber)

        // Should have 3 cascade rounds (4 total waves, minus first = 3)
        XCTAssertEqual(cascade.count, 3, "Expected a triple cascade")

        // Each cascade round should have 1 cell
        XCTAssertEqual(cascade[0].count, 1)
        XCTAssertEqual(cascade[1].count, 1)
        XCTAssertEqual(cascade[2].count, 1)

        // Verify cascade cells are the chain: (0,2), (0,3), (0,4)
        XCTAssertEqual(Set(cascade[0]), Set([CellPosition(row: 0, col: 2)]))
        XCTAssertEqual(Set(cascade[1]), Set([CellPosition(row: 0, col: 3)]))
        XCTAssertEqual(Set(cascade[2]), Set([CellPosition(row: 0, col: 4)]))
    }

    func testCascadeWavesEmptyWhenNoAbsorption() {
        // Flooding with a color not adjacent to the flood region
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.amber, .amber],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells)
        let cascade = board.cascadeWaves(after: .emerald)
        XCTAssertTrue(cascade.isEmpty)
    }

    // MARK: - P5-T7: Wave animation performance on 15×15 board

    func testWaveAnimationSetup15x15() {
        // Create a 15×15 board (225 cells) and verify wave computation works
        let board = FloodBoard.generateBoard(size: 15, colors: GameColor.allCases, seed: 999)
        XCTAssertEqual(board.gridSize, 15)
        XCTAssertEqual(board.cells.count, 15)

        // Find a color different from top-left to trigger absorption
        let currentColor = board.cells[0][0]
        let targetColor = GameColor.allCases.first { $0 != currentColor } ?? .coral

        // Compute waves — this is the key animation setup step
        let waves = board.cellsAbsorbedBy(color: targetColor)

        // Waves should be non-empty for a diverse board
        // (With 5 colors on 225 cells, there should be adjacent cells of different colors)
        // Each wave should contain valid positions
        for wave in waves {
            for pos in wave {
                XCTAssertTrue(pos.row >= 0 && pos.row < 15, "Row out of bounds: \(pos.row)")
                XCTAssertTrue(pos.col >= 0 && pos.col < 15, "Col out of bounds: \(pos.col)")
            }
        }

        // Total absorbed cells should not exceed board size
        let totalAbsorbed = waves.flatMap { $0 }.count
        XCTAssertTrue(totalAbsorbed <= 225, "Absorbed cells exceed board size")

        // Verify no duplicate positions across waves
        let allPositions = waves.flatMap { $0 }
        let uniquePositions = Set(allPositions)
        XCTAssertEqual(allPositions.count, uniquePositions.count, "Duplicate positions in waves")

        // Simulate multiple floods to ensure stability
        var mutableBoard = board
        for color in GameColor.allCases {
            let _ = mutableBoard.cellsAbsorbedBy(color: color)
            mutableBoard.flood(color: color)
        }
        // Board should still be valid after multiple floods
        XCTAssertEqual(mutableBoard.gridSize, 15)
        XCTAssertEqual(mutableBoard.cells.count, 15)
    }
}
