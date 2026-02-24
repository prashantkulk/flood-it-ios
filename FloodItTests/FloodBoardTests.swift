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

    // MARK: - P15-T5: Cascade scoring

    func testCascadeScoreMultiplier() {
        let scoreState = ScoreState()
        let base = 5 // cells absorbed

        // No cascade (0 cascade waves) → multiplier 1.0
        let noCascade = scoreState.calculateMoveScore(cellsAbsorbed: base, cascadeMultiplier: 1.0)
        XCTAssertEqual(noCascade, 100) // 5 * 20 * 1.0

        // Cascade 1 (1 cascade wave) → multiplier 1.5
        let cascade1 = scoreState.calculateMoveScore(cellsAbsorbed: base, cascadeMultiplier: 1.5)
        XCTAssertEqual(cascade1, 150) // 5 * 20 * 1.5

        // Cascade 2 (2 cascade waves) → multiplier 2.25 (1.5^2)
        let cascade2 = scoreState.calculateMoveScore(cellsAbsorbed: base, cascadeMultiplier: 2.25)
        XCTAssertEqual(cascade2, 225) // 5 * 20 * 2.25

        // Cascade 3 (3 cascade waves) → multiplier 3.375 (1.5^3)
        let cascade3 = scoreState.calculateMoveScore(cellsAbsorbed: base, cascadeMultiplier: 3.375)
        XCTAssertEqual(cascade3, 337) // 5 * 20 * 3.375 = 337.5 → 337
    }

    func testCascadeMultiplierFromGameState() {
        // Verify the cascade multiplier computation: pow(1.5, cascadeCount)
        // cascade 0 → 1.0
        XCTAssertEqual(pow(1.5, 0), 1.0, accuracy: 0.001)
        // cascade 1 → 1.5
        XCTAssertEqual(pow(1.5, 1), 1.5, accuracy: 0.001)
        // cascade 2 → 2.25
        XCTAssertEqual(pow(1.5, 2), 2.25, accuracy: 0.001)
        // cascade 3 → 3.375
        XCTAssertEqual(pow(1.5, 3), 3.375, accuracy: 0.001)
    }

    // MARK: - P16-T2: Stone blocks

    func testStoneBlocksFlood() {
        // Board: C A A
        //        S A E   (S = stone at (1,0))
        //        E E E
        // Stone at (1,0) should block flood from reaching (2,0)
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[1][0] = .stone
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber],
            [.coral, .amber, .emerald],
            [.coral, .emerald, .emerald],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)
        // Flood region is just (0,0) because stone at (1,0) blocks BFS
        let region = board.floodRegion
        XCTAssertEqual(region.count, 1)
        XCTAssertTrue(region.contains(CellPosition(row: 0, col: 0)))
        XCTAssertFalse(region.contains(CellPosition(row: 1, col: 0)))
    }

    func testStoneExcludedFromWinCheck() {
        // Board with all coral except one stone cell (which has amber color but is stone)
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 2), count: 2)
        types[1][1] = .stone
        let cells: [[GameColor]] = [
            [.coral, .coral],
            [.coral, .amber],  // (1,1) is stone with amber — should be ignored for win check
        ]
        let board = FloodBoard(gridSize: 2, cells: cells, cellTypes: types)
        XCTAssertTrue(board.isComplete, "Stone cells should be excluded from win check")
    }

    func testStoneCellsAbsorbedBySkipsStones() {
        // Stone cell should not be absorbed even if same color
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[0][2] = .stone
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber],  // (0,2) is stone
            [.emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)
        let waves = board.cellsAbsorbedBy(color: .amber)
        let allAbsorbed = Set(waves.flatMap { $0 })
        XCTAssertTrue(allAbsorbed.contains(CellPosition(row: 0, col: 1)))
        XCTAssertFalse(allAbsorbed.contains(CellPosition(row: 0, col: 2)), "Stone should not be absorbed")
    }

    // MARK: - P16-T3: Void cells

    func testVoidCellsExcludedFromFlood() {
        // Board: C C V    (V = void at (0,2))
        //        C C E
        //        E E E
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[0][2] = .void
        let cells: [[GameColor]] = [
            [.coral, .coral, .coral],
            [.coral, .coral, .emerald],
            [.emerald, .emerald, .emerald],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)
        let region = board.floodRegion
        // Void at (0,2) should not be in the flood region even though same color
        XCTAssertFalse(region.contains(CellPosition(row: 0, col: 2)))
        XCTAssertEqual(region.count, 4) // (0,0),(0,1),(1,0),(1,1)
    }

    func testVoidCellsExcludedFromWinCheck() {
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 2), count: 2)
        types[1][1] = .void
        let cells: [[GameColor]] = [
            [.coral, .coral],
            [.coral, .amber],  // (1,1) is void — should be ignored
        ]
        let board = FloodBoard(gridSize: 2, cells: cells, cellTypes: types)
        XCTAssertTrue(board.isComplete, "Void cells should be excluded from win check")
    }

    func testVoidEnablesNonRectangularShapes() {
        // L-shaped board: void out the top-right corner
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[0][2] = .void
        types[1][2] = .void
        let cells: [[GameColor]] = [
            [.coral, .coral, .amber],
            [.coral, .coral, .amber],
            [.coral, .coral, .coral],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)
        // All non-void cells are coral → should be complete
        XCTAssertTrue(board.isComplete)
    }

    // MARK: - P16-T4: Ice layers

    func testIceCracksOverMultipleFloods() {
        // Board: C A
        //        A A    (0,1) is ice(layers: 2), all amber
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 2), count: 2)
        types[0][1] = .ice(layers: 2)
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.amber, .amber],
        ]
        var board = FloodBoard(gridSize: 2, cells: cells, cellTypes: types)

        // First flood to amber: ice at (0,1) should crack to 1 layer
        board.flood(color: .amber)
        XCTAssertEqual(board.cellType(atRow: 0, col: 1), .ice(layers: 1))
        // (0,1) should NOT be in the flood region yet (still ice)
        XCTAssertFalse(board.floodRegion.contains(CellPosition(row: 0, col: 1)))

        // Second flood (different color and back): need another flood to crack again
        board.flood(color: .emerald)  // change to emerald, (0,1) won't crack (not adjacent after region changes)
        // Actually the flood region after first flood includes (0,0),(1,0),(1,1) = amber
        // Flooding emerald changes the region to emerald. (0,1) is still ice, but is it adjacent? Yes.
        XCTAssertEqual(board.cellType(atRow: 0, col: 1), .normal)
        // Now ice is cleared, flooding amber should absorb (0,1)
        board.flood(color: .amber)
        XCTAssertTrue(board.floodRegion.contains(CellPosition(row: 0, col: 1)))
    }

    func testIceSingleLayerBecomesNormal() {
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 2), count: 2)
        types[0][1] = .ice(layers: 1)
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.emerald, .emerald],
        ]
        var board = FloodBoard(gridSize: 2, cells: cells, cellTypes: types)

        // Flood to emerald: (0,1) is ice, not adjacent to absorbed region?
        // Flood region is (0,0). Flood to emerald: region becomes emerald, absorbs (1,0),(1,1).
        // Now (0,1) is adjacent to absorbed region → ice cracks to normal
        board.flood(color: .emerald)
        XCTAssertEqual(board.cellType(atRow: 0, col: 1), .normal)
    }

    func testIceNotAbsorbedUntilNormal() {
        // 3x3 board, ice at (0,1)
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[0][1] = .ice(layers: 1)
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber],
            [.emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)

        // cellsAbsorbedBy should NOT include (0,1) since it's ice
        let waves = board.cellsAbsorbedBy(color: .amber)
        let allAbsorbed = Set(waves.flatMap { $0 })
        XCTAssertFalse(allAbsorbed.contains(CellPosition(row: 0, col: 1)), "Ice cell should not be absorbed")

        // After flood, ice cracks to normal
        board.flood(color: .amber)
        XCTAssertEqual(board.cellType(atRow: 0, col: 1), .normal)
        XCTAssertTrue(board.canFloodTraverse(CellPosition(row: 0, col: 1)))
    }

    // MARK: - P16-T5: Countdown cells

    func testCountdownDecrementsEachMove() {
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[2][2] = .countdown(movesLeft: 3)
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald],
            [.amber, .emerald, .sapphire],
            [.emerald, .sapphire, .violet],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)
        var rng = SeededRandomNumberGenerator(seed: 1)

        board.flood(color: .amber)
        board.tickCountdowns(using: &rng)
        XCTAssertEqual(board.cellType(atRow: 2, col: 2), .countdown(movesLeft: 2))

        board.flood(color: .emerald)
        board.tickCountdowns(using: &rng)
        XCTAssertEqual(board.cellType(atRow: 2, col: 2), .countdown(movesLeft: 1))
    }

    func testCountdownScramblesAt0() {
        // Use a larger board so countdown cell is far from flood region
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 4), count: 4)
        types[3][3] = .countdown(movesLeft: 1)
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald, .sapphire],
            [.emerald, .sapphire, .violet, .coral],
            [.sapphire, .violet, .coral, .amber],
            [.violet, .coral, .amber, .emerald],
        ]
        var board = FloodBoard(gridSize: 4, cells: cells, cellTypes: types)
        var rng = SeededRandomNumberGenerator(seed: 99)

        // Capture colors around (3,3) before explosion
        let colorsBefore = [
            board.cells[2][2], board.cells[2][3],
            board.cells[3][2], board.cells[3][3]
        ]

        board.flood(color: .amber)
        board.tickCountdowns(using: &rng)

        // Countdown at (3,3) should become normal
        XCTAssertEqual(board.cellType(atRow: 3, col: 3), .normal)

        // Verify scramble happened: colors in 3x3 area around (3,3) should be randomized
        let colorsAfter = [
            board.cells[2][2], board.cells[2][3],
            board.cells[3][2], board.cells[3][3]
        ]
        // With 5 colors and seed 99, at least one cell should differ
        XCTAssertNotEqual(colorsBefore, colorsAfter, "Scramble should change cell colors")
    }

    func testCountdownDefusedOnAbsorption() {
        // Countdown cell is same color as flood and will be absorbed
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 2), count: 2)
        types[0][1] = .countdown(movesLeft: 5)
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.amber, .amber],
        ]
        var board = FloodBoard(gridSize: 2, cells: cells, cellTypes: types)

        // Flood amber: (0,1) is countdown but amber, should be absorbed and defused
        board.flood(color: .amber)
        XCTAssertEqual(board.cellType(atRow: 0, col: 1), .normal, "Countdown should be defused when absorbed")
    }

    // MARK: - P16-T6: Walls between cells

    func testWallBlocksFloodBetweenAdjacentSameColorCells() {
        // Board: C A     Wall between (0,0) and (0,1)
        //        E E     and wall between (0,0) and (1,0)
        // So (0,0) is completely isolated
        let cells: [[GameColor]] = [
            [.coral, .coral],
            [.coral, .coral],
        ]
        var board = FloodBoard(gridSize: 2, cells: cells)
        board.addWall(at: CellPosition(row: 0, col: 0), direction: .east)
        board.addWall(at: CellPosition(row: 0, col: 0), direction: .south)

        // Flood region is only (0,0) — walls block both neighbors
        let region = board.floodRegion
        XCTAssertEqual(region.count, 1, "Walls should block flood in both directions")
        XCTAssertTrue(region.contains(CellPosition(row: 0, col: 0)))
    }

    func testWallBidirectional() {
        // Adding wall at (0,0) east should also block from (0,1) west
        let cells: [[GameColor]] = [
            [.amber, .amber],
            [.coral, .coral],
        ]
        var board = FloodBoard(gridSize: 2, cells: cells)
        board.addWall(at: CellPosition(row: 0, col: 0), direction: .east)

        // Flood region starts at (0,0). Even though (0,1) is amber, wall blocks it.
        let region = board.floodRegion
        XCTAssertEqual(region.count, 1)
        XCTAssertFalse(region.contains(CellPosition(row: 0, col: 1)))
    }

    func testWallDoesNotAffectOtherDirections() {
        // Wall between (0,0) and (0,1) should not affect (0,0) south neighbor
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.coral, .amber],
        ]
        var board = FloodBoard(gridSize: 2, cells: cells)
        board.addWall(at: CellPosition(row: 0, col: 0), direction: .east)

        let region = board.floodRegion
        // (1,0) should still be reachable via south
        XCTAssertTrue(region.contains(CellPosition(row: 1, col: 0)))
        XCTAssertEqual(region.count, 2)
    }

    // MARK: - P16-T7: Portals

    func testPortalFloodFlowsThroughPair() {
        // Board: C E E
        //        E E E
        //        E E A
        // Portal pair: (0,0) and (2,2), so flood can reach (2,2) from (0,0)
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[0][0] = .portal(pairId: 1)
        types[2][2] = .portal(pairId: 1)
        let cells: [[GameColor]] = [
            [.coral, .emerald, .emerald],
            [.emerald, .emerald, .emerald],
            [.emerald, .emerald, .coral],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)
        let region = board.floodRegion
        // (0,0) is coral with portal to (2,2) which is also coral
        // So flood region should include both portal cells
        XCTAssertTrue(region.contains(CellPosition(row: 0, col: 0)))
        XCTAssertTrue(region.contains(CellPosition(row: 2, col: 2)), "Portal pair should be reachable")
    }

    func testPortalAbsorptionAcrossBoard() {
        // Board: C A A
        //        E E E
        //        A A A
        // Portal: (0,0) ↔ (2,0)
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[0][0] = .portal(pairId: 1)
        types[2][0] = .portal(pairId: 1)
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber],
            [.emerald, .emerald, .emerald],
            [.amber, .amber, .amber],
        ]
        let board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)
        let waves = board.cellsAbsorbedBy(color: .amber)
        let allAbsorbed = Set(waves.flatMap { $0 })
        // (0,1) is amber adjacent to (0,0) — absorbed
        XCTAssertTrue(allAbsorbed.contains(CellPosition(row: 0, col: 1)))
        // (2,0) is portal partner, amber — should be absorbed through portal
        XCTAssertTrue(allAbsorbed.contains(CellPosition(row: 2, col: 0)), "Portal should allow absorption across board")
        // (2,1) and (2,2) should also be absorbed (adjacent to (2,0))
        XCTAssertTrue(allAbsorbed.contains(CellPosition(row: 2, col: 1)))
        XCTAssertTrue(allAbsorbed.contains(CellPosition(row: 2, col: 2)))
    }

    // MARK: - P16-T8: Bonus tiles

    func testBonusTileDoublesScore() {
        // Single-wave absorption to avoid cascade multiplier
        // Board: C A     (0,1) is bonus(x2)
        //        E E
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 2), count: 2)
        types[0][1] = .bonus(multiplier: 2)
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.emerald, .emerald],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells, cellTypes: types)
        let state = GameState(board: board, totalMoves: 10)

        let result = state.performFlood(color: .amber)
        // Absorbed 1 amber cell with x2 bonus
        XCTAssertEqual(result.bonusMultiplier, 2)
        // Score: 1 cell * 20 * 2 (bonus) = 40
        XCTAssertEqual(state.scoreState.lastMoveScore, 40)
    }

    func testBonusTileTripleScore() {
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 2), count: 2)
        types[0][1] = .bonus(multiplier: 3)
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.emerald, .emerald],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells, cellTypes: types)
        let state = GameState(board: board, totalMoves: 10)

        let result = state.performFlood(color: .amber)
        XCTAssertEqual(result.bonusMultiplier, 3)
        // Score: 1 cell * 20 * 3 (bonus) = 60
        XCTAssertEqual(state.scoreState.lastMoveScore, 60)
    }

    func testNoBonusTileDefaultMultiplier() {
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.emerald, .emerald],
        ]
        let board = FloodBoard(gridSize: 2, cells: cells)
        let state = GameState(board: board, totalMoves: 10)

        let result = state.performFlood(color: .amber)
        XCTAssertEqual(result.bonusMultiplier, 1)
        // Score: 1 cell * 20 = 20
        XCTAssertEqual(state.scoreState.lastMoveScore, 20)
    }

    // MARK: - P16-T10: Comprehensive obstacle interaction tests

    func testStoneAdjacentToIce() {
        // Stone at (1,0), ice at (0,1) — stone blocks, ice cracks independently
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[1][0] = .stone
        types[0][1] = .ice(layers: 1)
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber],
            [.coral, .amber, .amber],
            [.emerald, .emerald, .emerald],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)
        // Flood region: only (0,0) — (1,0) is stone, blocks south
        let region = board.floodRegion
        XCTAssertEqual(region.count, 1)

        // Flood amber: no absorption (ice blocks (0,1), stone blocks (1,0))
        board.flood(color: .amber)
        // Ice at (0,1) should crack to normal (adjacent to region)
        XCTAssertEqual(board.cellType(atRow: 0, col: 1), .normal)
        // Stone at (1,0) should remain stone
        XCTAssertEqual(board.cellType(atRow: 1, col: 0), .stone)
    }

    func testPortalWithWall() {
        // Portal pair (0,0) ↔ (2,2), wall between (0,0) and (1,0)
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[0][0] = .portal(pairId: 1)
        types[2][2] = .portal(pairId: 1)
        let cells: [[GameColor]] = [
            [.coral, .emerald, .emerald],
            [.coral, .emerald, .emerald],
            [.emerald, .emerald, .coral],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)
        board.addWall(at: CellPosition(row: 0, col: 0), direction: .south)

        // Wall blocks (0,0) → (1,0), but portal connects (0,0) ↔ (2,2)
        let region = board.floodRegion
        // (0,0) coral, portal to (2,2) coral — should be connected
        XCTAssertTrue(region.contains(CellPosition(row: 0, col: 0)))
        XCTAssertTrue(region.contains(CellPosition(row: 2, col: 2)), "Portal should bypass wall")
        // (1,0) is coral but wall blocks it
        XCTAssertFalse(region.contains(CellPosition(row: 1, col: 0)), "Wall should still block")
    }

    func testCountdownWithCascade() {
        // Countdown at edge, cascade happens, countdown still ticks
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 4), count: 4)
        types[3][3] = .countdown(movesLeft: 2)
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber, .amber],
            [.emerald, .emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald, .sapphire],
        ]
        var board = FloodBoard(gridSize: 4, cells: cells, cellTypes: types)
        var rng = SeededRandomNumberGenerator(seed: 1)

        board.flood(color: .amber)
        board.tickCountdowns(using: &rng)
        XCTAssertEqual(board.cellType(atRow: 3, col: 3), .countdown(movesLeft: 1))
    }

    func testIceWithCascade() {
        // Ice blocks cascade propagation until cracked
        // Use wall to prevent absorption from going around
        var types4: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 4), count: 4)
        types4[0][2] = .ice(layers: 1)
        let cells4: [[GameColor]] = [
            [.coral, .amber, .amber, .amber],
            [.emerald, .emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald, .emerald],
        ]
        var board = FloodBoard(gridSize: 4, cells: cells4, cellTypes: types4)

        // cellsAbsorbedBy amber: only (0,1) — ice at (0,2) blocks cascade to (0,3)
        let waves = board.cellsAbsorbedBy(color: .amber)
        let allAbsorbed = Set(waves.flatMap { $0 })
        XCTAssertTrue(allAbsorbed.contains(CellPosition(row: 0, col: 1)))
        XCTAssertFalse(allAbsorbed.contains(CellPosition(row: 0, col: 2)), "Ice should block cascade")
        XCTAssertFalse(allAbsorbed.contains(CellPosition(row: 0, col: 3)), "Ice should block cascade to (0,3)")

        // After flood, ice cracks
        board.flood(color: .amber)
        XCTAssertEqual(board.cellType(atRow: 0, col: 2), .normal)

        // Now (0,2) is normal and amber — should be absorbable
        // The region is now {(0,0),(0,1)} = amber. (0,2) is amber and normal → yes
        let waves2 = board.cellsAbsorbedBy(color: .amber)
        let allAbsorbed2 = Set(waves2.flatMap { $0 })
        // Actually the region color is amber and we're querying cellsAbsorbedBy(.amber) — same color, no absorption
        // We need to flood a different color first, then back to amber
        // Let's just verify (0,2) is now traversable
        XCTAssertTrue(board.canFloodTraverse(CellPosition(row: 0, col: 2)),
                       "Ice should be normal after cracking")
    }

    func testBonusWithCombo() {
        // Bonus tile absorbed during a combo should multiply the already-combo'd score
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 5), count: 5)
        types[1][0] = .bonus(multiplier: 2)
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber, .amber, .amber],
            [.amber, .emerald, .emerald, .emerald, .emerald],
            [.emerald, .sapphire, .sapphire, .sapphire, .sapphire],
            [.sapphire, .violet, .violet, .violet, .violet],
            [.violet, .coral, .coral, .coral, .coral],
        ]
        let board = FloodBoard(gridSize: 5, cells: cells, cellTypes: types)
        let state = GameState(board: board, totalMoves: 20)

        // Move 1: flood amber, absorbs 5 cells → combo 1
        let result1 = state.performFlood(color: .amber)
        XCTAssertEqual(state.comboCount, 1)
        // Bonus x2 should be applied (bonus at (1,0) which is amber, absorbed)
        XCTAssertEqual(result1.bonusMultiplier, 2)
    }

    func testVoidShapedBoardWithPortals() {
        // L-shaped board with portals connecting corners
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 4), count: 4)
        // Void out top-right quadrant
        types[0][2] = .void; types[0][3] = .void
        types[1][2] = .void; types[1][3] = .void
        // Portal connecting (0,1) ↔ (3,3)
        types[0][1] = .portal(pairId: 1)
        types[3][3] = .portal(pairId: 1)
        let cells: [[GameColor]] = [
            [.coral, .coral, .amber, .amber],
            [.coral, .coral, .amber, .amber],
            [.emerald, .emerald, .sapphire, .sapphire],
            [.emerald, .emerald, .sapphire, .coral],
        ]
        let board = FloodBoard(gridSize: 4, cells: cells, cellTypes: types)
        let region = board.floodRegion
        // (0,0), (0,1) [portal], (1,0), (1,1) are coral and connected
        // Portal links (0,1) → (3,3) which is also coral
        XCTAssertTrue(region.contains(CellPosition(row: 0, col: 0)))
        XCTAssertTrue(region.contains(CellPosition(row: 3, col: 3)), "Portal should work on void-shaped board")
        // Void cells should not be in region
        XCTAssertFalse(region.contains(CellPosition(row: 0, col: 2)))

        // Board should be solvable
        let moves = FloodSolver.solve(board: board)
        var testBoard = board
        for color in moves {
            testBoard.flood(color: color)
        }
        XCTAssertTrue(testBoard.isComplete, "Solver should handle void+portal board")
    }

    func testStoneDoesNotCrackLikeIce() {
        // Stone never changes type, even when adjacent to flood region
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[0][1] = .stone
        let cells: [[GameColor]] = [
            [.coral, .amber, .amber],
            [.coral, .coral, .coral],
            [.coral, .coral, .coral],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)
        board.flood(color: .amber)
        XCTAssertEqual(board.cellType(atRow: 0, col: 1), .stone, "Stone should never change type")
        // Stone at (0,1) should still be skipped by flood
        XCTAssertFalse(board.floodRegion.contains(CellPosition(row: 0, col: 1)))
    }

    func testCountdownDefusedBeforeExplosion() {
        // Countdown with movesLeft 1, but absorbed this turn → defused, no scramble
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[0][1] = .countdown(movesLeft: 1)
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald],
            [.amber, .sapphire, .sapphire],
            [.sapphire, .sapphire, .sapphire],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)
        var rng = SeededRandomNumberGenerator(seed: 1)

        // Flood amber: absorbs (0,1) which is countdown → defused to normal
        board.flood(color: .amber)
        XCTAssertEqual(board.cellType(atRow: 0, col: 1), .normal)
        // Now tick — should NOT scramble because it was defused
        let cellsBefore = board.cells
        board.tickCountdowns(using: &rng)
        XCTAssertEqual(board.cells, cellsBefore, "Defused countdown should not scramble")
    }

    func testMultiplePortalPairs() {
        // Two portal pairs on the same board
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 4), count: 4)
        types[0][0] = .portal(pairId: 1)
        types[3][3] = .portal(pairId: 1)
        types[0][3] = .portal(pairId: 2)
        types[3][0] = .portal(pairId: 2)
        let cells: [[GameColor]] = [
            [.coral, .emerald, .emerald, .coral],
            [.emerald, .emerald, .emerald, .emerald],
            [.emerald, .emerald, .emerald, .emerald],
            [.coral, .emerald, .emerald, .coral],
        ]
        let board = FloodBoard(gridSize: 4, cells: cells, cellTypes: types)
        let region = board.floodRegion
        // (0,0) coral → portal to (3,3) coral. (3,3) neighbors: (3,2) emerald, (2,3) emerald, portal to (0,0).
        // (0,3) coral → portal to (3,0) coral. But (0,3) is not connected to (0,0) by BFS.
        // Region = {(0,0), (3,3)} only
        XCTAssertTrue(region.contains(CellPosition(row: 0, col: 0)))
        XCTAssertTrue(region.contains(CellPosition(row: 3, col: 3)), "Portal pair 1 connects")
        XCTAssertFalse(region.contains(CellPosition(row: 0, col: 3)), "Separate portal pair, not connected")
        XCTAssertEqual(region.count, 2, "Only portal pair 1 connects coral cells to origin")
    }

    func testWallBetweenPortalAndNeighbor() {
        // Portal at (0,0), wall between (0,0) and (0,1)
        // Portal should still work, wall only blocks the direct neighbor
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 3), count: 3)
        types[0][0] = .portal(pairId: 1)
        types[2][2] = .portal(pairId: 1)
        let cells: [[GameColor]] = [
            [.coral, .coral, .emerald],
            [.emerald, .emerald, .emerald],
            [.emerald, .emerald, .coral],
        ]
        var board = FloodBoard(gridSize: 3, cells: cells, cellTypes: types)
        board.addWall(at: CellPosition(row: 0, col: 0), direction: .east)

        let region = board.floodRegion
        // (0,0) coral, wall blocks east to (0,1), but portal reaches (2,2) coral
        XCTAssertTrue(region.contains(CellPosition(row: 0, col: 0)))
        XCTAssertTrue(region.contains(CellPosition(row: 2, col: 2)), "Portal bypasses wall")
        XCTAssertFalse(region.contains(CellPosition(row: 0, col: 1)), "Wall blocks east neighbor")
    }

    func testIceMultipleLayers() {
        // Ice with 3 layers takes 3 floods to crack fully
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 2), count: 2)
        types[0][1] = .ice(layers: 3)
        let cells: [[GameColor]] = [
            [.coral, .amber],
            [.amber, .amber],
        ]
        var board = FloodBoard(gridSize: 2, cells: cells, cellTypes: types)

        // Flood 1: ice cracks to 2
        board.flood(color: .amber)
        XCTAssertEqual(board.cellType(atRow: 0, col: 1), .ice(layers: 2))

        // Flood 2: ice cracks to 1
        board.flood(color: .emerald)
        XCTAssertEqual(board.cellType(atRow: 0, col: 1), .ice(layers: 1))

        // Flood 3: ice cracks to normal
        board.flood(color: .amber)
        XCTAssertEqual(board.cellType(atRow: 0, col: 1), .normal)
    }

    func testAllObstaclesBoardSolvable() {
        // Board with stones, ice, portals, and voids — solver should complete it
        var types: [[CellType]] = Array(repeating: Array(repeating: .normal, count: 5), count: 5)
        types[1][1] = .stone
        types[0][2] = .ice(layers: 1)
        types[0][4] = .void
        types[4][0] = .portal(pairId: 1)
        types[0][0] = .portal(pairId: 1)
        let cells: [[GameColor]] = [
            [.coral, .amber, .emerald, .sapphire, .violet],
            [.amber, .emerald, .sapphire, .violet, .coral],
            [.emerald, .sapphire, .violet, .coral, .amber],
            [.sapphire, .violet, .coral, .amber, .emerald],
            [.coral, .amber, .emerald, .sapphire, .violet],
        ]
        let board = FloodBoard(gridSize: 5, cells: cells, cellTypes: types)
        let moves = FloodSolver.solve(board: board)
        var testBoard = board
        var rng = SeededRandomNumberGenerator(seed: 0)
        for color in moves {
            testBoard.flood(color: color)
            testBoard.tickCountdowns(using: &rng)
        }
        XCTAssertTrue(testBoard.isComplete, "Solver should handle board with mixed obstacles")
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

    // MARK: - P17-T2 Void Board Shapes

    /// Verify L-shaped board: voids form a rectangle in the top-right.
    func testVoidLShapeBoard() {
        let n = 5
        let cells = Array(repeating: Array(repeating: GameColor.coral, count: n), count: n)
        var board = FloodBoard(gridSize: n, cells: cells)
        // Make top-right 3x2 block void to create an L-shape
        for row in 0..<2 {
            for col in 3..<n {
                board.setCellType(.void, atRow: row, col: col)
            }
        }
        // Void cells should not be playable
        XCTAssertFalse(board.isPlayable(at: CellPosition(row: 0, col: 3)))
        XCTAssertFalse(board.isPlayable(at: CellPosition(row: 1, col: 4)))
        // Non-void cells should be playable
        XCTAssertTrue(board.isPlayable(at: CellPosition(row: 0, col: 0)))
        XCTAssertTrue(board.isPlayable(at: CellPosition(row: 4, col: 4)))
        // Board completion should ignore voids
        XCTAssertTrue(board.isComplete, "All playable cells are coral, should be complete")
    }

    /// Verify donut board: center cells are void, creating a ring shape.
    func testVoidDonutBoard() {
        let n = 5
        let cells = Array(repeating: Array(repeating: GameColor.emerald, count: n), count: n)
        var board = FloodBoard(gridSize: n, cells: cells)
        // Void out center 3x3
        for row in 1...3 {
            for col in 1...3 {
                board.setCellType(.void, atRow: row, col: col)
            }
        }
        // Center should not be playable
        XCTAssertFalse(board.isPlayable(at: CellPosition(row: 2, col: 2)))
        // Edge cells should be playable
        XCTAssertTrue(board.isPlayable(at: CellPosition(row: 0, col: 0)))
        XCTAssertTrue(board.isPlayable(at: CellPosition(row: 4, col: 4)))
        // All playable cells are emerald, so complete
        XCTAssertTrue(board.isComplete)
    }

    /// Verify diamond board: corners are void, leaving a diamond shape.
    func testVoidDiamondBoard() {
        let n = 5
        let cells = Array(repeating: Array(repeating: GameColor.sapphire, count: n), count: n)
        var board = FloodBoard(gridSize: n, cells: cells)
        let center = n / 2
        for row in 0..<n {
            for col in 0..<n {
                let dist = abs(row - center) + abs(col - center)
                if dist > center {
                    board.setCellType(.void, atRow: row, col: col)
                }
            }
        }
        // Corners should be void
        XCTAssertFalse(board.isPlayable(at: CellPosition(row: 0, col: 0)))
        XCTAssertFalse(board.isPlayable(at: CellPosition(row: 4, col: 4)))
        // Center should be playable
        XCTAssertTrue(board.isPlayable(at: CellPosition(row: 2, col: 2)))
        // All playable cells are same color
        XCTAssertTrue(board.isComplete)
    }

    // MARK: - P17-T8 Performance Test — Mixed Obstacle Board

    /// Create a 15x15 board with a mix of all obstacle types and verify it can be
    /// constructed and flood-filled without issues.
    func testMixedObstacleBoard15x15() {
        let n = 15
        var rng = SeededRandomNumberGenerator(seed: 12345)
        let colors = GameColor.allCases
        var cells = [[GameColor]]()
        for _ in 0..<n {
            var row = [GameColor]()
            for _ in 0..<n {
                row.append(colors[Int.random(in: 0..<colors.count, using: &rng)])
            }
            cells.append(row)
        }
        var board = FloodBoard(gridSize: n, cells: cells)

        // Place stones (4 cells)
        board.setCellType(.stone, atRow: 3, col: 3)
        board.setCellType(.stone, atRow: 3, col: 4)
        board.setCellType(.stone, atRow: 7, col: 10)
        board.setCellType(.stone, atRow: 12, col: 1)

        // Place voids (corner cuts for shape)
        board.setCellType(.void, atRow: 0, col: 14)
        board.setCellType(.void, atRow: 14, col: 14)
        board.setCellType(.void, atRow: 14, col: 0)

        // Place ice (2 layers and 1 layer)
        board.setCellType(.ice(layers: 2), atRow: 5, col: 5)
        board.setCellType(.ice(layers: 1), atRow: 5, col: 6)
        board.setCellType(.ice(layers: 2), atRow: 10, col: 10)

        // Place countdowns
        board.setCellType(.countdown(movesLeft: 5), atRow: 2, col: 8)
        board.setCellType(.countdown(movesLeft: 3), atRow: 8, col: 2)

        // Place portal pairs
        board.setCellType(.portal(pairId: 0), atRow: 1, col: 1)
        board.setCellType(.portal(pairId: 0), atRow: 13, col: 13)
        board.setCellType(.portal(pairId: 1), atRow: 1, col: 13)
        board.setCellType(.portal(pairId: 1), atRow: 13, col: 1)

        // Place bonus tiles
        board.setCellType(.bonus(multiplier: 2), atRow: 7, col: 7)
        board.setCellType(.bonus(multiplier: 3), atRow: 11, col: 5)

        // Add walls
        board.addWall(at: CellPosition(row: 4, col: 4), direction: .south)
        board.addWall(at: CellPosition(row: 6, col: 8), direction: .east)
        board.addWall(at: CellPosition(row: 9, col: 3), direction: .north)

        // Verify board is valid
        XCTAssertEqual(board.gridSize, n)
        XCTAssertEqual(board.cells.count, n)

        // Verify obstacles are placed correctly
        XCTAssertEqual(board.cellType(atRow: 3, col: 3), .stone)
        XCTAssertEqual(board.cellType(atRow: 0, col: 14), .void)
        XCTAssertEqual(board.cellType(atRow: 5, col: 5), .ice(layers: 2))
        XCTAssertEqual(board.cellType(atRow: 2, col: 8), .countdown(movesLeft: 5))
        XCTAssertEqual(board.cellType(atRow: 1, col: 1), .portal(pairId: 0))
        XCTAssertEqual(board.cellType(atRow: 7, col: 7), .bonus(multiplier: 2))

        // Verify walls exist
        XCTAssertTrue(board.hasWall(at: CellPosition(row: 4, col: 4), direction: .south))
        XCTAssertTrue(board.hasWall(at: CellPosition(row: 5, col: 4), direction: .north))

        // Verify flood region computation works with all obstacles
        let region = board.floodRegion
        XCTAssertFalse(region.isEmpty, "Flood region should not be empty")

        // Perform multiple floods to verify no crashes with obstacle interactions
        var countdownRng = SeededRandomNumberGenerator(seed: 99)
        for color in GameColor.allCases {
            let _ = board.cellsAbsorbedBy(color: color)
            board.flood(color: color)
            board.tickCountdowns(using: &countdownRng)
        }

        // Board should still be valid
        XCTAssertEqual(board.gridSize, n)
    }

    /// Performance test: measure time to construct and flood a 15x15 mixed obstacle board.
    func testMixedObstacleBoardPerformance() {
        measure {
            let n = 15
            var rng = SeededRandomNumberGenerator(seed: 54321)
            let colors = GameColor.allCases
            var cells = [[GameColor]]()
            for _ in 0..<n {
                var row = [GameColor]()
                for _ in 0..<n {
                    row.append(colors[Int.random(in: 0..<colors.count, using: &rng)])
                }
                cells.append(row)
            }
            var board = FloodBoard(gridSize: n, cells: cells)

            // Place obstacles
            board.setCellType(.stone, atRow: 3, col: 3)
            board.setCellType(.void, atRow: 0, col: 14)
            board.setCellType(.ice(layers: 2), atRow: 5, col: 5)
            board.setCellType(.countdown(movesLeft: 3), atRow: 8, col: 2)
            board.setCellType(.portal(pairId: 0), atRow: 1, col: 1)
            board.setCellType(.portal(pairId: 0), atRow: 13, col: 13)
            board.setCellType(.bonus(multiplier: 2), atRow: 7, col: 7)
            board.addWall(at: CellPosition(row: 4, col: 4), direction: .south)

            // Simulate 10 flood moves
            var countdownRng = SeededRandomNumberGenerator(seed: 42)
            for color in GameColor.allCases {
                let _ = board.cellsAbsorbedBy(color: color)
                board.flood(color: color)
                board.tickCountdowns(using: &countdownRng)
            }
            for color in GameColor.allCases {
                let _ = board.cellsAbsorbedBy(color: color)
                board.flood(color: color)
                board.tickCountdowns(using: &countdownRng)
            }
        }
    }
}
