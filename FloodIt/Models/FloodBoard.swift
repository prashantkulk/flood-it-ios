import Foundation

/// The game board model: a grid of colored cells with flood region tracking.
struct FloodBoard {
    let gridSize: Int
    private(set) var cells: [[GameColor]]
    private(set) var cellTypes: [[CellType]]
    private(set) var walls: Set<Wall>

    /// Initialize a board with a given size and pre-filled color grid.
    init(gridSize: Int, cells: [[GameColor]], cellTypes: [[CellType]]? = nil, walls: Set<Wall> = []) {
        precondition(gridSize > 0, "Grid size must be positive")
        precondition(cells.count == gridSize, "Cell rows must match grid size")
        precondition(cells.allSatisfy({ $0.count == gridSize }), "Cell columns must match grid size")
        self.gridSize = gridSize
        self.cells = cells
        self.cellTypes = cellTypes ?? Array(repeating: Array(repeating: CellType.normal, count: gridSize), count: gridSize)
        self.walls = walls
    }

    /// Initialize a board with a given size, filled with a default color.
    init(gridSize: Int) {
        self.gridSize = gridSize
        self.cells = Array(repeating: Array(repeating: GameColor.coral, count: gridSize), count: gridSize)
        self.cellTypes = Array(repeating: Array(repeating: CellType.normal, count: gridSize), count: gridSize)
        self.walls = []
    }

    /// Returns the color at the given position.
    func color(atRow row: Int, col: Int) -> GameColor {
        return cells[row][col]
    }

    /// Returns the cell type at the given position.
    func cellType(atRow row: Int, col: Int) -> CellType {
        return cellTypes[row][col]
    }

    /// Sets the cell type at the given position.
    mutating func setCellType(_ type: CellType, atRow row: Int, col: Int) {
        cellTypes[row][col] = type
    }

    /// Adds a wall between two adjacent cells (adds both directions).
    mutating func addWall(at position: CellPosition, direction: Direction) {
        walls.insert(Wall(position: position, direction: direction))
        let (dr, dc) = direction.delta
        let neighborPos = CellPosition(row: position.row + dr, col: position.col + dc)
        if neighborPos.row >= 0 && neighborPos.row < gridSize && neighborPos.col >= 0 && neighborPos.col < gridSize {
            walls.insert(Wall(position: neighborPos, direction: direction.opposite))
        }
    }

    /// Returns true if there is a wall between a cell and the given direction.
    func hasWall(at position: CellPosition, direction: Direction) -> Bool {
        return walls.contains(Wall(position: position, direction: direction))
    }

    /// Returns true if the cell is playable (not void, not stone for flood purposes).
    func isPlayable(at position: CellPosition) -> Bool {
        let type = cellTypes[position.row][position.col]
        switch type {
        case .void, .stone:
            return false
        default:
            return true
        }
    }

    /// Returns true if a cell can participate in flood BFS (not stone, void, or ice).
    func canFloodTraverse(_ pos: CellPosition) -> Bool {
        switch cellTypes[pos.row][pos.col] {
        case .stone, .void, .ice:
            return false
        default:
            return true
        }
    }

    /// Computed property: all cells connected to top-left sharing its color (BFS).
    var floodRegion: Set<CellPosition> {
        let targetColor = cells[0][0]
        var visited = Set<CellPosition>()
        var queue = [CellPosition(row: 0, col: 0)]
        visited.insert(CellPosition(row: 0, col: 0))

        while !queue.isEmpty {
            let current = queue.removeFirst()
            for neighbor in neighbors(of: current) {
                if !visited.contains(neighbor) && canFloodTraverse(neighbor) && cells[neighbor.row][neighbor.col] == targetColor {
                    visited.insert(neighbor)
                    queue.append(neighbor)
                }
            }
        }

        return visited
    }

    /// Returns the highest bonus multiplier among the given positions.
    /// If no bonus tiles are present, returns 1.
    func bonusMultiplier(for positions: [CellPosition]) -> Int {
        var maxBonus = 1
        for pos in positions {
            if case .bonus(let mult) = cellTypes[pos.row][pos.col] {
                maxBonus = max(maxBonus, mult)
            }
        }
        return maxBonus
    }

    /// Returns true when all playable cells on the board are the same color.
    /// Stones and voids are excluded from the win check.
    var isComplete: Bool {
        let firstColor = cells[0][0]
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let pos = CellPosition(row: row, col: col)
                if canFloodTraverse(pos) && cells[row][col] != firstColor {
                    return false
                }
            }
        }
        return true
    }

    /// Performs a flood fill with the given color.
    /// Changes the entire flood region to the new color, then absorbs all adjacent cells matching it.
    /// Ice cells at the boundary get their layers decremented instead of being absorbed.
    mutating func flood(color newColor: GameColor) {
        let currentRegion = floodRegion
        // Change all cells in the current flood region to the new color
        for pos in currentRegion {
            cells[pos.row][pos.col] = newColor
        }
        // BFS to absorb adjacent cells that match the new color
        var queue = Array(currentRegion)
        var absorbed = currentRegion
        while !queue.isEmpty {
            let current = queue.removeFirst()
            for neighbor in neighbors(of: current) {
                if !absorbed.contains(neighbor) && canFloodTraverse(neighbor) && cells[neighbor.row][neighbor.col] == newColor {
                    absorbed.insert(neighbor)
                    queue.append(neighbor)
                }
            }
        }
        // Mark all absorbed cells with the new color (they already match, but ensures consistency)
        // Defuse countdown cells that were absorbed into the region
        for pos in absorbed {
            cells[pos.row][pos.col] = newColor
            if case .countdown = cellTypes[pos.row][pos.col] {
                cellTypes[pos.row][pos.col] = .normal
            }
        }
        // Process ice cells adjacent to the final absorbed region
        var crackedIce = Set<CellPosition>()
        for pos in absorbed {
            for neighbor in neighbors(of: pos) {
                if !absorbed.contains(neighbor) && !crackedIce.contains(neighbor) {
                    if case .ice(let layers) = cellTypes[neighbor.row][neighbor.col] {
                        crackedIce.insert(neighbor)
                        if layers <= 1 {
                            cellTypes[neighbor.row][neighbor.col] = .normal
                        } else {
                            cellTypes[neighbor.row][neighbor.col] = .ice(layers: layers - 1)
                        }
                    }
                }
            }
        }
    }

    /// Decrements all countdown cells by 1. At 0, scrambles the 3x3 area around it.
    /// Uses the provided RNG for deterministic scrambling.
    mutating func tickCountdowns(using rng: inout SeededRandomNumberGenerator) {
        var exploded = [CellPosition]()
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if case .countdown(let movesLeft) = cellTypes[row][col] {
                    if movesLeft <= 1 {
                        // Explode: mark for scramble
                        exploded.append(CellPosition(row: row, col: col))
                        cellTypes[row][col] = .normal
                    } else {
                        cellTypes[row][col] = .countdown(movesLeft: movesLeft - 1)
                    }
                }
            }
        }
        // Scramble 3x3 area around each exploded countdown
        let colors = GameColor.allCases
        for pos in exploded {
            for dr in -1...1 {
                for dc in -1...1 {
                    let r = pos.row + dr
                    let c = pos.col + dc
                    guard r >= 0, r < gridSize, c >= 0, c < gridSize else { continue }
                    let cellPos = CellPosition(row: r, col: c)
                    // Only scramble playable, non-stone, non-void cells
                    switch cellTypes[r][c] {
                    case .stone, .void:
                        continue
                    default:
                        cells[r][c] = colors[Int.random(in: 0..<colors.count, using: &rng)]
                    }
                }
            }
        }
    }

    /// Returns cells that would be absorbed by flooding with the given color,
    /// grouped by BFS distance from the flood boundary.
    /// Each inner array is a "wave" of cells at the same distance.
    /// Only returns newly absorbed cells (not the existing flood region).
    func cellsAbsorbedBy(color newColor: GameColor) -> [[CellPosition]] {
        let currentRegion = floodRegion
        // Find boundary cells of the current region (cells adjacent to non-region cells)
        var boundary = [CellPosition]()
        for pos in currentRegion {
            for neighbor in neighbors(of: pos) {
                if !currentRegion.contains(neighbor) && canFloodTraverse(neighbor) && cells[neighbor.row][neighbor.col] == newColor {
                    boundary.append(neighbor)
                }
            }
        }

        if boundary.isEmpty { return [] }

        // BFS from boundary cells outward, collecting waves by distance
        var visited = currentRegion
        var currentWave = Set<CellPosition>()
        for pos in boundary {
            if !visited.contains(pos) {
                visited.insert(pos)
                currentWave.insert(pos)
            }
        }

        var waves = [[CellPosition]]()
        while !currentWave.isEmpty {
            waves.append(Array(currentWave))
            var nextWave = Set<CellPosition>()
            for pos in currentWave {
                for neighbor in neighbors(of: pos) {
                    if !visited.contains(neighbor) && canFloodTraverse(neighbor) && cells[neighbor.row][neighbor.col] == newColor {
                        visited.insert(neighbor)
                        nextWave.insert(neighbor)
                    }
                }
            }
            currentWave = nextWave
        }

        return waves
    }

    /// Generates a board from LevelData, applying obstacle config if present.
    static func generateBoard(from levelData: LevelData) -> FloodBoard {
        let colors = Array(GameColor.allCases.prefix(levelData.colorCount))
        var board = generateBoard(size: levelData.gridSize, colors: colors, seed: levelData.seed)

        guard let config = levelData.obstacleConfig, !config.isEmpty else {
            return board
        }

        // Apply void mask
        for pos in config.voidPositions {
            guard pos.row >= 0, pos.row < board.gridSize, pos.col >= 0, pos.col < board.gridSize else { continue }
            board.setCellType(.void, atRow: pos.row, col: pos.col)
        }

        // Apply stones
        for pos in config.stonePositions {
            guard pos.row >= 0, pos.row < board.gridSize, pos.col >= 0, pos.col < board.gridSize else { continue }
            board.setCellType(.stone, atRow: pos.row, col: pos.col)
        }

        // Apply ice
        for ice in config.icePositions {
            let pos = ice.position
            guard pos.row >= 0, pos.row < board.gridSize, pos.col >= 0, pos.col < board.gridSize else { continue }
            board.setCellType(.ice(layers: ice.layers), atRow: pos.row, col: pos.col)
        }

        // Apply countdowns
        for cd in config.countdownPositions {
            let pos = cd.position
            guard pos.row >= 0, pos.row < board.gridSize, pos.col >= 0, pos.col < board.gridSize else { continue }
            board.setCellType(.countdown(movesLeft: cd.movesLeft), atRow: pos.row, col: pos.col)
        }

        // Apply portals
        for portal in config.portalPairs {
            let p1 = portal.position1
            let p2 = portal.position2
            guard p1.row >= 0, p1.row < board.gridSize, p1.col >= 0, p1.col < board.gridSize,
                  p2.row >= 0, p2.row < board.gridSize, p2.col >= 0, p2.col < board.gridSize else { continue }
            board.setCellType(.portal(pairId: portal.pairId), atRow: p1.row, col: p1.col)
            board.setCellType(.portal(pairId: portal.pairId), atRow: p2.row, col: p2.col)
        }

        // Apply bonus tiles
        for bonus in config.bonusPositions {
            let pos = bonus.position
            guard pos.row >= 0, pos.row < board.gridSize, pos.col >= 0, pos.col < board.gridSize else { continue }
            board.setCellType(.bonus(multiplier: bonus.multiplier), atRow: pos.row, col: pos.col)
        }

        // Apply walls
        for wall in config.wallEdges {
            board.addWall(at: wall.position, direction: wall.direction)
        }

        return board
    }

    /// Generates a board with random colors using a seeded random number generator.
    /// Same seed always produces the same board.
    static func generateBoard(size: Int, colors: [GameColor] = GameColor.allCases, seed: UInt64) -> FloodBoard {
        precondition(size > 0, "Board size must be positive")
        precondition(!colors.isEmpty, "Must have at least one color")
        var rng = SeededRandomNumberGenerator(seed: seed)
        var cells = [[GameColor]]()
        for _ in 0..<size {
            var row = [GameColor]()
            for _ in 0..<size {
                row.append(colors[Int.random(in: 0..<colors.count, using: &rng)])
            }
            cells.append(row)
        }
        return FloodBoard(gridSize: size, cells: cells, cellTypes: nil, walls: [])
    }

    /// Returns all non-flood-region cells grouped in BFS waves from the flood region boundary.
    /// Used for the dam-break winning animation.
    func allRemainingCellsInBFSOrder() -> [[CellPosition]] {
        let region = floodRegion
        var visited = region
        // Mark voids and stones as already visited so they're excluded
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let pos = CellPosition(row: row, col: col)
                if !canFloodTraverse(pos) {
                    visited.insert(pos)
                }
            }
        }
        // Start from boundary of flood region
        var currentWave = Set<CellPosition>()
        for pos in region {
            for neighbor in neighbors(of: pos) {
                if !visited.contains(neighbor) {
                    visited.insert(neighbor)
                    currentWave.insert(neighbor)
                }
            }
        }
        var waves = [[CellPosition]]()
        while !currentWave.isEmpty {
            waves.append(Array(currentWave))
            var nextWave = Set<CellPosition>()
            for pos in currentWave {
                for neighbor in neighbors(of: pos) {
                    if !visited.contains(neighbor) {
                        visited.insert(neighbor)
                        nextWave.insert(neighbor)
                    }
                }
            }
            currentWave = nextWave
        }
        return waves
    }

    /// Returns cascade waves after the initial flood absorption.
    /// The initial flood absorbs cells directly adjacent to the flood region boundary (wave 1).
    /// Cascade waves are the subsequent BFS waves — cells reachable only through the initially
    /// absorbed cells, representing chain reactions rippling through connected same-color pockets.
    /// Returns an empty array if no cascade occurs (absorption is only 1 wave deep).
    func cascadeWaves(after color: GameColor) -> [[CellPosition]] {
        let allWaves = cellsAbsorbedBy(color: color)
        guard allWaves.count > 1 else { return [] }
        return Array(allWaves.dropFirst())
    }

    /// Returns true if flooding with the given color would complete the board (all cells same color).
    func wouldComplete(color newColor: GameColor) -> Bool {
        var simulated = self
        simulated.flood(color: newColor)
        return simulated.isComplete
    }

    /// Returns the 4-directional neighbors of a cell position within bounds,
    /// respecting walls and including portal connections.
    private func neighbors(of position: CellPosition) -> [CellPosition] {
        var result = Direction.allCases.compactMap { dir -> CellPosition? in
            guard !hasWall(at: position, direction: dir) else { return nil }
            let (dr, dc) = dir.delta
            let r = position.row + dr
            let c = position.col + dc
            guard r >= 0, r < gridSize, c >= 0, c < gridSize else { return nil }
            return CellPosition(row: r, col: c)
        }
        // Add portal pair as neighbor if this cell is a portal
        if case .portal(let pairId) = cellTypes[position.row][position.col] {
            if let partner = portalPartner(for: position, pairId: pairId) {
                result.append(partner)
            }
        }
        return result
    }

    /// Finds the portal partner for a given portal cell.
    private func portalPartner(for position: CellPosition, pairId: Int) -> CellPosition? {
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if row == position.row && col == position.col { continue }
                if case .portal(let otherId) = cellTypes[row][col], otherId == pairId {
                    return CellPosition(row: row, col: col)
                }
            }
        }
        return nil
    }
}

/// A hashable position on the grid.
struct CellPosition: Hashable, Codable {
    let row: Int
    let col: Int
}

/// A deterministic random number generator seeded with a UInt64.
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // SplitMix64 algorithm
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
