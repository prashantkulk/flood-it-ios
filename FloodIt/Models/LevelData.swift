import Foundation

/// Configuration for obstacles placed on a level board.
struct ObstacleConfig: Codable, Equatable {
    var stonePositions: [CellPosition] = []
    var icePositions: [IcePlacement] = []
    var countdownPositions: [CountdownPlacement] = []
    var wallEdges: [WallEdgePlacement] = []
    var portalPairs: [PortalPairPlacement] = []
    var bonusPositions: [BonusPlacement] = []
    var voidPositions: [CellPosition] = []

    var isEmpty: Bool {
        stonePositions.isEmpty && icePositions.isEmpty && countdownPositions.isEmpty
            && wallEdges.isEmpty && portalPairs.isEmpty && bonusPositions.isEmpty
            && voidPositions.isEmpty
    }

    struct IcePlacement: Codable, Equatable {
        let position: CellPosition
        let layers: Int
    }

    struct CountdownPlacement: Codable, Equatable {
        let position: CellPosition
        let movesLeft: Int
    }

    struct WallEdgePlacement: Codable, Equatable {
        let position: CellPosition
        let direction: Direction
    }

    struct PortalPairPlacement: Codable, Equatable {
        let position1: CellPosition
        let position2: CellPosition
        let pairId: Int
    }

    struct BonusPlacement: Codable, Equatable {
        let position: CellPosition
        let multiplier: Int
    }
}

/// Metadata for a single level in the game.
struct LevelData: Codable, Identifiable {
    let id: Int          // 1-based level number
    let seed: UInt64
    let gridSize: Int
    let colorCount: Int  // number of colors to use
    let optimalMoves: Int
    let moveBudget: Int
    let tier: Tier
    let obstacleConfig: ObstacleConfig?

    init(id: Int, seed: UInt64, gridSize: Int, colorCount: Int, optimalMoves: Int, moveBudget: Int, tier: Tier, obstacleConfig: ObstacleConfig? = nil) {
        self.id = id
        self.seed = seed
        self.gridSize = gridSize
        self.colorCount = colorCount
        self.optimalMoves = optimalMoves
        self.moveBudget = moveBudget
        self.tier = tier
        self.obstacleConfig = obstacleConfig
    }

    enum Tier: String, Codable {
        case splash   // Levels 1-50
        case current  // Levels 51-100
    }
}

/// Static store of all 100 pre-generated levels.
struct LevelStore {
    static let levels: [LevelData] = generateAllLevels()

    static func level(_ number: Int) -> LevelData? {
        guard number >= 1, number <= levels.count else { return nil }
        return levels[number - 1]
    }

    /// Onboarding configs for levels 1-5: (gridSize, colorCount, moveBudget)
    private static let onboardingConfigs: [(gridSize: Int, colorCount: Int, moveBudget: Int)] = [
        (3, 3, 10),   // Level 1: trivial
        (4, 3, 12),   // Level 2
        (5, 4, 15),   // Level 3
        (7, 4, 20),   // Level 4
        (9, 5, 25),   // Level 5
    ]

    /// Deterministic seed for a given level number.
    static func seed(for levelNumber: Int) -> UInt64 {
        UInt64(levelNumber * 31 + 7)
    }

    private static func generateAllLevels() -> [LevelData] {
        var result = [LevelData]()

        for i in 1...100 {
            let seed = Self.seed(for: i)
            let tier: LevelData.Tier = i <= 50 ? .splash : .current

            let levelData: LevelData
            switch i {
            case 1...5:
                levelData = generateOnboardingLevel(id: i, seed: seed, tier: tier)
            case 6...20:
                levelData = generateEasyLevel(id: i, seed: seed, tier: tier)
            case 21...30:
                levelData = generateStoneLevels(id: i, seed: seed, tier: tier)
            case 31...40:
                levelData = generateIceLevels(id: i, seed: seed, tier: tier)
            case 41...50:
                levelData = generateCountdownLevels(id: i, seed: seed, tier: tier)
            case 51...65:
                levelData = generateWallPortalLevels(id: i, seed: seed, tier: tier)
            default:
                levelData = generateStandardLevel(id: i, seed: seed, tier: tier, extraMoves: extraMovesForLevel(i))
            }

            result.append(levelData)
        }

        return result
    }

    private static func generateOnboardingLevel(id: Int, seed: UInt64, tier: LevelData.Tier) -> LevelData {
        let config = onboardingConfigs[id - 1]
        let colors = Array(GameColor.allCases.prefix(config.colorCount))
        let board = FloodBoard.generateBoard(size: config.gridSize, colors: colors, seed: seed)
        let optimalMoves = FloodSolver.solveMoveCount(board: board)
        return LevelData(
            id: id, seed: seed, gridSize: config.gridSize, colorCount: config.colorCount,
            optimalMoves: optimalMoves, moveBudget: config.moveBudget, tier: tier
        )
    }

    private static func generateEasyLevel(id: Int, seed: UInt64, tier: LevelData.Tier) -> LevelData {
        // Levels 6-20: standard 9x9, 5 colors, no obstacles, generous budget
        let gridSize = 9
        let colorCount = 5
        let colors = Array(GameColor.allCases.prefix(colorCount))
        let board = FloodBoard.generateBoard(size: gridSize, colors: colors, seed: seed)
        let optimalMoves = FloodSolver.solveMoveCount(board: board)
        let extraMoves = id <= 10 ? 8 : 6  // very generous
        return LevelData(
            id: id, seed: seed, gridSize: gridSize, colorCount: colorCount,
            optimalMoves: optimalMoves, moveBudget: optimalMoves + extraMoves, tier: tier
        )
    }

    private static func generateStandardLevel(id: Int, seed: UInt64, tier: LevelData.Tier, extraMoves: Int, obstacleConfig: ObstacleConfig? = nil) -> LevelData {
        let gridSize = 9
        let colorCount = 5
        let levelData = LevelData(
            id: id, seed: seed, gridSize: gridSize, colorCount: colorCount,
            optimalMoves: 0, moveBudget: 0, tier: tier, obstacleConfig: obstacleConfig
        )
        let board = FloodBoard.generateBoard(from: levelData)
        let optimalMoves = FloodSolver.solveMoveCount(board: board)
        return LevelData(
            id: id, seed: seed, gridSize: gridSize, colorCount: colorCount,
            optimalMoves: optimalMoves, moveBudget: optimalMoves + extraMoves, tier: tier,
            obstacleConfig: obstacleConfig
        )
    }

    private static func generateStoneLevels(id: Int, seed: UInt64, tier: LevelData.Tier) -> LevelData {
        let gridSize = 9
        let colorCount = 5
        let extraMoves = 6  // still generous

        // Some levels use shaped boards (L-shape or diamond)
        var voids: [CellPosition] = []
        switch id {
        case 23, 27: voids = BoardShapes.lShape(gridSize: gridSize)
        case 25, 29: voids = BoardShapes.diamond(gridSize: gridSize)
        default: break
        }

        // 2-4 stones, increasing as we progress
        let stoneCount = id <= 24 ? 2 : (id <= 27 ? 3 : 4)

        let request = ObstaclePlacer.PlacementRequest(
            stoneCount: stoneCount,
            voidPositions: voids
        )
        let config = ObstaclePlacer.placeObstacles(gridSize: gridSize, colorCount: colorCount, seed: seed, request: request)
        return generateStandardLevel(id: id, seed: seed, tier: tier, extraMoves: extraMoves, obstacleConfig: config)
    }

    private static func generateIceLevels(id: Int, seed: UInt64, tier: LevelData.Tier) -> LevelData {
        let gridSize = 9
        let colorCount = 5
        let extraMoves = 4  // moderate budget

        // Ice layers: 1 for early, 2 for later levels
        let iceLayers = id <= 35 ? 1 : 2
        let iceCount = id <= 34 ? 2 : 3
        // Keep some stones too
        let stoneCount = id <= 36 ? 1 : 2

        let request = ObstaclePlacer.PlacementRequest(
            stoneCount: stoneCount,
            iceCount: iceCount,
            iceLayers: iceLayers
        )
        let config = ObstaclePlacer.placeObstacles(gridSize: gridSize, colorCount: colorCount, seed: seed, request: request)
        return generateStandardLevel(id: id, seed: seed, tier: tier, extraMoves: extraMoves, obstacleConfig: config)
    }

    private static func generateCountdownLevels(id: Int, seed: UInt64, tier: LevelData.Tier) -> LevelData {
        let gridSize = 9
        let colorCount = 5

        // Level 50 is a boss level — tighter budget, more countdowns
        let isBoss = id == 50
        let extraMoves = isBoss ? 2 : 4
        let countdownCount = isBoss ? 3 : (id <= 44 ? 1 : 2)
        let countdownMoves = isBoss ? 3 : (id <= 44 ? 5 : 4)
        // Some stones and ice carry over
        let stoneCount = id >= 45 ? 2 : 1
        let iceCount = id >= 47 ? 1 : 0

        let request = ObstaclePlacer.PlacementRequest(
            stoneCount: stoneCount,
            iceCount: iceCount,
            iceLayers: 1,
            countdownCount: countdownCount,
            countdownMoves: countdownMoves
        )
        let config = ObstaclePlacer.placeObstacles(gridSize: gridSize, colorCount: colorCount, seed: seed, request: request)
        return generateStandardLevel(id: id, seed: seed, tier: tier, extraMoves: extraMoves, obstacleConfig: config)
    }

    private static func generateWallPortalLevels(id: Int, seed: UInt64, tier: LevelData.Tier) -> LevelData {
        let gridSize = 9
        let colorCount = 5
        let extraMoves = 3  // strategic thinking needed

        // Walls increase, portals introduced mid-range
        let wallCount: Int
        let portalPairCount: Int
        let stoneCount: Int

        switch id {
        case 51...54:  // walls only
            wallCount = id - 49  // 2-5 walls
            portalPairCount = 0
            stoneCount = 1
        case 55...58:  // portals introduced
            wallCount = 2
            portalPairCount = 1
            stoneCount = 1
        case 59...62:  // walls + portals combined
            wallCount = 3
            portalPairCount = 1
            stoneCount = 2
        default:       // 63-65: heavier combinations
            wallCount = 4
            portalPairCount = 2
            stoneCount = 2
        }

        let request = ObstaclePlacer.PlacementRequest(
            stoneCount: stoneCount,
            wallCount: wallCount,
            portalPairCount: portalPairCount
        )
        let config = ObstaclePlacer.placeObstacles(gridSize: gridSize, colorCount: colorCount, seed: seed, request: request)
        return generateStandardLevel(id: id, seed: seed, tier: tier, extraMoves: extraMoves, obstacleConfig: config)
    }

    private static func extraMovesForLevel(_ i: Int) -> Int {
        switch i {
        case 21...30: return 6
        case 31...50: return 4
        case 51...70: return 3
        case 71...90: return 2
        default:      return 1
        }
    }
}
