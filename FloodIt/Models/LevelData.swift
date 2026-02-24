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
            case 66...100:
                levelData = generateExpertLevels(id: i, seed: seed, tier: tier)
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
        let extraMoves = id <= 10 ? 8 : 6  // very generous

        let bonus = bonusForLevel(id)
        if bonus.count > 0 {
            let request = ObstaclePlacer.PlacementRequest(bonusCount: bonus.count, bonusMultiplier: bonus.multiplier)
            let config = ObstaclePlacer.placeObstacles(gridSize: gridSize, colorCount: colorCount, seed: seed, request: request)
            return generateStandardLevel(id: id, seed: seed, tier: tier, extraMoves: extraMoves, obstacleConfig: config)
        }

        let colors = Array(GameColor.allCases.prefix(colorCount))
        let board = FloodBoard.generateBoard(size: gridSize, colors: colors, seed: seed)
        let optimalMoves = FloodSolver.solveMoveCount(board: board)
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
        let bonus = bonusForLevel(id)

        let request = ObstaclePlacer.PlacementRequest(
            stoneCount: stoneCount,
            bonusCount: bonus.count,
            bonusMultiplier: bonus.multiplier,
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

        let bonus = bonusForLevel(id)
        let request = ObstaclePlacer.PlacementRequest(
            stoneCount: stoneCount,
            iceCount: iceCount,
            iceLayers: iceLayers,
            bonusCount: bonus.count,
            bonusMultiplier: bonus.multiplier
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

        let bonus = bonusForLevel(id)
        let request = ObstaclePlacer.PlacementRequest(
            stoneCount: stoneCount,
            iceCount: iceCount,
            iceLayers: 1,
            countdownCount: countdownCount,
            countdownMoves: countdownMoves,
            bonusCount: bonus.count,
            bonusMultiplier: bonus.multiplier
        )
        let config = ObstaclePlacer.placeObstacles(gridSize: gridSize, colorCount: colorCount, seed: seed, request: request)
        return generateStandardLevel(id: id, seed: seed, tier: tier, extraMoves: extraMoves, obstacleConfig: config)
    }

    private static func generateWallPortalLevels(id: Int, seed: UInt64, tier: LevelData.Tier) -> LevelData {
        let gridSize = 9
        let colorCount = 5

        // Breather at level 56 and 62
        let isBreather = id == 56 || id == 62

        let extraMoves: Int
        let wallCount: Int
        let portalPairCount: Int
        let stoneCount: Int

        if isBreather {
            extraMoves = 5
            wallCount = 1
            portalPairCount = 0
            stoneCount = 0
        } else {
            extraMoves = 3
            switch id {
            case 51...54:  // walls only
                wallCount = id - 49  // 2-5 walls
                portalPairCount = 0
                stoneCount = 1
            case 55, 57, 58:  // portals introduced
                wallCount = 2
                portalPairCount = 1
                stoneCount = 1
            case 59...61:  // walls + portals combined
                wallCount = 3
                portalPairCount = 1
                stoneCount = 2
            default:       // 63-65: heavier combinations
                wallCount = 4
                portalPairCount = 2
                stoneCount = 2
            }
        }

        let bonus = bonusForLevel(id)
        let request = ObstaclePlacer.PlacementRequest(
            stoneCount: stoneCount,
            wallCount: wallCount,
            portalPairCount: portalPairCount,
            bonusCount: bonus.count,
            bonusMultiplier: bonus.multiplier
        )
        let config = ObstaclePlacer.placeObstacles(gridSize: gridSize, colorCount: colorCount, seed: seed, request: request)
        return generateStandardLevel(id: id, seed: seed, tier: tier, extraMoves: extraMoves, obstacleConfig: config)
    }

    private static func generateExpertLevels(id: Int, seed: UInt64, tier: LevelData.Tier) -> LevelData {
        let gridSize = 9
        let colorCount = 5

        // Sawtooth difficulty: every 5-7 levels has a breather
        let isBreather = (id % 7 == 0) || id == 70 || id == 80 || id == 90
        let isFinalBoss = id == 100

        let extraMoves: Int
        let stoneCount: Int
        let iceCount: Int
        let iceLayers: Int
        let countdownCount: Int
        let countdownMoves: Int
        let wallCount: Int
        let portalPairCount: Int
        var voids: [CellPosition] = []

        if isFinalBoss {
            // Level 100: ultimate boss — all obstacle types, tight budget
            extraMoves = 1
            stoneCount = 3
            iceCount = 3
            iceLayers = 2
            countdownCount = 2
            countdownMoves = 3
            wallCount = 4
            portalPairCount = 2
            voids = BoardShapes.donut(gridSize: gridSize)
        } else if isBreather {
            // Breather levels — fewer obstacles, generous budget
            extraMoves = 5
            stoneCount = 1
            iceCount = 0
            iceLayers = 1
            countdownCount = 0
            countdownMoves = 5
            wallCount = 1
            portalPairCount = 0
        } else {
            // Progressive difficulty with sawtooth
            let difficulty = (id - 66) / 5  // 0-6 difficulty bands
            let withinBand = (id - 66) % 5  // position within band

            // Budget oscillates: tighter for mid-band, relaxes slightly at band edges
            let baseBudget = max(1, 3 - difficulty / 2)
            extraMoves = withinBand == 0 ? baseBudget + 1 : baseBudget

            // Obstacle counts ramp up across bands
            stoneCount = min(4, 1 + difficulty / 2)
            iceCount = min(3, difficulty / 2)
            iceLayers = difficulty >= 4 ? 2 : 1
            countdownCount = difficulty >= 2 ? min(2, difficulty / 3 + 1) : 0
            countdownMoves = difficulty >= 4 ? 3 : 4
            wallCount = min(4, 1 + difficulty / 2)
            portalPairCount = difficulty >= 3 ? 1 : 0

            // Some expert levels use shaped boards
            switch id {
            case 72: voids = BoardShapes.diamond(gridSize: gridSize)
            case 78: voids = BoardShapes.cross(gridSize: gridSize)
            case 85: voids = BoardShapes.lShape(gridSize: gridSize)
            case 92: voids = BoardShapes.heart(gridSize: gridSize)
            case 97: voids = BoardShapes.donut(gridSize: gridSize)
            default: break
            }
        }

        let bonus = bonusForLevel(id)
        let request = ObstaclePlacer.PlacementRequest(
            stoneCount: stoneCount,
            iceCount: iceCount,
            iceLayers: iceLayers,
            countdownCount: countdownCount,
            countdownMoves: countdownMoves,
            wallCount: wallCount,
            portalPairCount: portalPairCount,
            bonusCount: bonus.count,
            bonusMultiplier: bonus.multiplier,
            voidPositions: voids
        )
        let config = ObstaclePlacer.placeObstacles(gridSize: gridSize, colorCount: colorCount, seed: seed, request: request)
        return generateStandardLevel(id: id, seed: seed, tier: tier, extraMoves: extraMoves, obstacleConfig: config)
    }

    /// Determines bonus tile placement for a level. Returns (count, multiplier).
    /// ~30-40% of levels 15+ get bonus tiles, more frequent in harder sections.
    private static func bonusForLevel(_ id: Int) -> (count: Int, multiplier: Int) {
        guard id >= 15 else { return (0, 2) }
        // Use seed-based determinism for which levels get bonuses
        var rng = SeededRandomNumberGenerator(seed: UInt64(id * 17 + 3))
        let roll = rng.next() % 100

        // Harder sections get more frequent bonuses
        let threshold: UInt64
        switch id {
        case 15...30: threshold = 30   // ~30%
        case 31...50: threshold = 35
        case 51...70: threshold = 40
        default:      threshold = 45   // ~45% for expert levels
        }

        guard roll < threshold else { return (0, 2) }

        let multiplier = id >= 70 ? 3 : 2
        let count = id >= 80 ? 2 : 1
        return (count, multiplier)
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
