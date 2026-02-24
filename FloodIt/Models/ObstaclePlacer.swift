import Foundation

/// Places obstacles randomly on a board and verifies solvability.
struct ObstaclePlacer {

    struct PlacementRequest {
        var stoneCount: Int = 0
        var iceCount: Int = 0
        var iceLayers: Int = 1
        var countdownCount: Int = 0
        var countdownMoves: Int = 3
        var wallCount: Int = 0
        var portalPairCount: Int = 0
        var bonusCount: Int = 0
        var bonusMultiplier: Int = 2
        var voidPositions: [CellPosition] = []
    }

    /// Places obstacles on the board based on the request, verifying solvability.
    /// Returns an ObstacleConfig if successful, nil if unable to produce a solvable board after retries.
    static func placeObstacles(
        gridSize: Int,
        colorCount: Int,
        seed: UInt64,
        request: PlacementRequest
    ) -> ObstacleConfig? {
        var rng = SeededRandomNumberGenerator(seed: seed &+ 0xDEAD)
        var currentRequest = request
        let maxRetries = 10

        for attempt in 0..<maxRetries {
            if let config = tryPlacement(gridSize: gridSize, colorCount: colorCount, seed: seed, request: currentRequest, rng: &rng) {
                return config
            }
            // Reduce obstacle count on each retry
            if attempt >= maxRetries / 2 {
                currentRequest.stoneCount = max(0, currentRequest.stoneCount - 1)
                currentRequest.iceCount = max(0, currentRequest.iceCount - 1)
                currentRequest.countdownCount = max(0, currentRequest.countdownCount - 1)
                currentRequest.wallCount = max(0, currentRequest.wallCount - 1)
            }
        }

        // Last resort: no obstacles
        return ObstacleConfig(voidPositions: request.voidPositions)
    }

    private static func tryPlacement(
        gridSize: Int,
        colorCount: Int,
        seed: UInt64,
        request: PlacementRequest,
        rng: inout SeededRandomNumberGenerator
    ) -> ObstacleConfig? {
        let voidSet = Set(request.voidPositions)

        // Build list of available positions (not void, not (0,0), not adjacent to (0,0))
        var available = [CellPosition]()
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let pos = CellPosition(row: row, col: col)
                if voidSet.contains(pos) { continue }
                // Keep (0,0) clear for flood start
                if row == 0 && col == 0 { continue }
                available.append(pos)
            }
        }

        // Shuffle available positions
        for i in stride(from: available.count - 1, through: 1, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            available.swapAt(i, j)
        }

        var config = ObstacleConfig(voidPositions: request.voidPositions)
        var usedPositions = Set<CellPosition>()
        var idx = 0

        func nextPos() -> CellPosition? {
            while idx < available.count {
                let pos = available[idx]
                idx += 1
                if !usedPositions.contains(pos) {
                    usedPositions.insert(pos)
                    return pos
                }
            }
            return nil
        }

        // Place stones
        for _ in 0..<request.stoneCount {
            guard let pos = nextPos() else { break }
            config.stonePositions.append(pos)
        }

        // Place ice
        for _ in 0..<request.iceCount {
            guard let pos = nextPos() else { break }
            config.icePositions.append(ObstacleConfig.IcePlacement(position: pos, layers: request.iceLayers))
        }

        // Place countdowns
        for _ in 0..<request.countdownCount {
            guard let pos = nextPos() else { break }
            config.countdownPositions.append(ObstacleConfig.CountdownPlacement(position: pos, movesLeft: request.countdownMoves))
        }

        // Place portal pairs (need two positions each)
        for pairId in 0..<request.portalPairCount {
            guard let pos1 = nextPos(), let pos2 = nextPos() else { break }
            config.portalPairs.append(ObstacleConfig.PortalPairPlacement(position1: pos1, position2: pos2, pairId: pairId))
        }

        // Place bonus tiles
        for _ in 0..<request.bonusCount {
            guard let pos = nextPos() else { break }
            config.bonusPositions.append(ObstacleConfig.BonusPlacement(position: pos, multiplier: request.bonusMultiplier))
        }

        // Place walls between random adjacent pairs
        var wallCandidates = [(CellPosition, Direction)]()
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let pos = CellPosition(row: row, col: col)
                if voidSet.contains(pos) { continue }
                if row == 0 && col == 0 { continue }
                if row < gridSize - 1 {
                    let neighbor = CellPosition(row: row + 1, col: col)
                    if !voidSet.contains(neighbor) {
                        wallCandidates.append((pos, .south))
                    }
                }
                if col < gridSize - 1 {
                    let neighbor = CellPosition(row: row, col: col + 1)
                    if !voidSet.contains(neighbor) {
                        wallCandidates.append((pos, .east))
                    }
                }
            }
        }
        // Shuffle wall candidates
        for i in stride(from: wallCandidates.count - 1, through: 1, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            wallCandidates.swapAt(i, j)
        }
        for i in 0..<min(request.wallCount, wallCandidates.count) {
            let (pos, dir) = wallCandidates[i]
            config.wallEdges.append(ObstacleConfig.WallEdgePlacement(position: pos, direction: dir))
        }

        // Build board and verify solvability
        let colors = Array(GameColor.allCases.prefix(colorCount))
        var board = FloodBoard.generateBoard(size: gridSize, colors: colors, seed: seed)
        applyConfig(config, to: &board)

        let solverMoves = FloodSolver.solveMoveCount(board: board)
        let maxBudget = gridSize * gridSize  // reasonable upper bound
        guard solverMoves < maxBudget, board.isPlayable(at: CellPosition(row: 0, col: 0)) else {
            return nil
        }

        return config
    }

    /// Applies an ObstacleConfig to an existing board (used for verification).
    private static func applyConfig(_ config: ObstacleConfig, to board: inout FloodBoard) {
        for pos in config.voidPositions {
            board.setCellType(.void, atRow: pos.row, col: pos.col)
        }
        for pos in config.stonePositions {
            board.setCellType(.stone, atRow: pos.row, col: pos.col)
        }
        for ice in config.icePositions {
            board.setCellType(.ice(layers: ice.layers), atRow: ice.position.row, col: ice.position.col)
        }
        for cd in config.countdownPositions {
            board.setCellType(.countdown(movesLeft: cd.movesLeft), atRow: cd.position.row, col: cd.position.col)
        }
        for portal in config.portalPairs {
            board.setCellType(.portal(pairId: portal.pairId), atRow: portal.position1.row, col: portal.position1.col)
            board.setCellType(.portal(pairId: portal.pairId), atRow: portal.position2.row, col: portal.position2.col)
        }
        for bonus in config.bonusPositions {
            board.setCellType(.bonus(multiplier: bonus.multiplier), atRow: bonus.position.row, col: bonus.position.col)
        }
        for wall in config.wallEdges {
            board.addWall(at: wall.position, direction: wall.direction)
        }
    }
}
