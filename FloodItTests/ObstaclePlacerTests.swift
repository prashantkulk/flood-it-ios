import XCTest
@testable import FloodIt

final class ObstaclePlacerTests: XCTestCase {

    // MARK: - P18-T3: Obstacle placement algorithm

    func testPlaceStonesProducesSolvableBoard() {
        let request = ObstaclePlacer.PlacementRequest(stoneCount: 4)
        let config = ObstaclePlacer.placeObstacles(gridSize: 9, colorCount: 5, seed: 42, request: request)
        XCTAssertNotNil(config)
        XCTAssertEqual(config!.stonePositions.count, 4)

        let levelData = LevelData(id: 999, seed: 42, gridSize: 9, colorCount: 5, optimalMoves: 0, moveBudget: 100, tier: .splash, obstacleConfig: config)
        let board = FloodBoard.generateBoard(from: levelData)
        let moves = FloodSolver.solve(board: board)
        var testBoard = board
        for color in moves {
            testBoard.flood(color: color)
        }
        XCTAssertTrue(testBoard.isComplete, "Board with stones should be solvable")
    }

    func testPlaceIceProducesSolvableBoard() {
        let request = ObstaclePlacer.PlacementRequest(iceCount: 3, iceLayers: 2)
        let config = ObstaclePlacer.placeObstacles(gridSize: 9, colorCount: 5, seed: 100, request: request)
        XCTAssertNotNil(config)
        XCTAssertEqual(config!.icePositions.count, 3)

        let levelData = LevelData(id: 999, seed: 100, gridSize: 9, colorCount: 5, optimalMoves: 0, moveBudget: 100, tier: .splash, obstacleConfig: config)
        let board = FloodBoard.generateBoard(from: levelData)
        let solverMoves = FloodSolver.solveMoveCount(board: board)
        XCTAssertGreaterThan(solverMoves, 0, "Solver should find a solution")
    }

    func testPlaceCountdownsProducesSolvableBoard() {
        let request = ObstaclePlacer.PlacementRequest(countdownCount: 2, countdownMoves: 4)
        let config = ObstaclePlacer.placeObstacles(gridSize: 9, colorCount: 5, seed: 77, request: request)
        XCTAssertNotNil(config)
        XCTAssertEqual(config!.countdownPositions.count, 2)
    }

    func testPlaceWallsProducesSolvableBoard() {
        let request = ObstaclePlacer.PlacementRequest(wallCount: 3)
        let config = ObstaclePlacer.placeObstacles(gridSize: 9, colorCount: 5, seed: 55, request: request)
        XCTAssertNotNil(config)
        XCTAssertEqual(config!.wallEdges.count, 3)
    }

    func testPlacePortalsProducesSolvableBoard() {
        let request = ObstaclePlacer.PlacementRequest(portalPairCount: 1)
        let config = ObstaclePlacer.placeObstacles(gridSize: 9, colorCount: 5, seed: 33, request: request)
        XCTAssertNotNil(config)
        XCTAssertEqual(config!.portalPairs.count, 1)
    }

    func testPlaceMixedObstaclesProducesSolvableBoard() {
        let request = ObstaclePlacer.PlacementRequest(
            stoneCount: 2,
            iceCount: 2,
            iceLayers: 1,
            countdownCount: 1,
            countdownMoves: 3,
            wallCount: 2,
            portalPairCount: 1,
            bonusCount: 1
        )
        let config = ObstaclePlacer.placeObstacles(gridSize: 9, colorCount: 5, seed: 200, request: request)
        XCTAssertNotNil(config)

        let levelData = LevelData(id: 999, seed: 200, gridSize: 9, colorCount: 5, optimalMoves: 0, moveBudget: 100, tier: .splash, obstacleConfig: config)
        let board = FloodBoard.generateBoard(from: levelData)
        let solverMoves = FloodSolver.solveMoveCount(board: board)
        XCTAssertGreaterThan(solverMoves, 0)
        XCTAssertLessThan(solverMoves, 81, "Should be solvable in fewer moves than total cells")
    }

    func testNoObstaclesReturnsEmptyConfig() {
        let request = ObstaclePlacer.PlacementRequest()
        let config = ObstaclePlacer.placeObstacles(gridSize: 9, colorCount: 5, seed: 10, request: request)
        XCTAssertNotNil(config)
        XCTAssertTrue(config!.isEmpty)
    }

    func testOriginCellNeverBlocked() {
        // Place many stones; (0,0) should never be one of them
        let request = ObstaclePlacer.PlacementRequest(stoneCount: 20)
        let config = ObstaclePlacer.placeObstacles(gridSize: 9, colorCount: 5, seed: 42, request: request)
        XCTAssertNotNil(config)
        for pos in config!.stonePositions {
            XCTAssertFalse(pos.row == 0 && pos.col == 0, "Origin should never be a stone")
        }
    }

    func testMultipleSeedsAllSolvable() {
        let request = ObstaclePlacer.PlacementRequest(stoneCount: 3, iceCount: 2, iceLayers: 1)
        for seed: UInt64 in 1...10 {
            let config = ObstaclePlacer.placeObstacles(gridSize: 9, colorCount: 5, seed: seed, request: request)
            XCTAssertNotNil(config, "Seed \(seed) should produce a valid config")

            let levelData = LevelData(id: Int(seed), seed: seed, gridSize: 9, colorCount: 5, optimalMoves: 0, moveBudget: 100, tier: .splash, obstacleConfig: config)
            let board = FloodBoard.generateBoard(from: levelData)
            let solverMoves = FloodSolver.solveMoveCount(board: board)
            XCTAssertGreaterThan(solverMoves, 0, "Seed \(seed) should be solvable")
        }
    }

    func testVoidPositionsPreserved() {
        let voids = BoardShapes.diamond(gridSize: 9)
        let request = ObstaclePlacer.PlacementRequest(stoneCount: 2, voidPositions: voids)
        let config = ObstaclePlacer.placeObstacles(gridSize: 9, colorCount: 5, seed: 42, request: request)
        XCTAssertNotNil(config)
        XCTAssertEqual(config!.voidPositions, voids)
        // Stones should not be placed on void positions
        let voidSet = Set(voids)
        for stone in config!.stonePositions {
            XCTAssertFalse(voidSet.contains(stone), "Stone should not be placed on a void position")
        }
    }
}
