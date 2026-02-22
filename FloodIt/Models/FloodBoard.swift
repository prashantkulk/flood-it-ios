import Foundation

/// The game board model: a grid of colored cells with flood region tracking.
struct FloodBoard {
    let gridSize: Int
    private(set) var cells: [[GameColor]]

    /// Initialize a board with a given size and pre-filled color grid.
    init(gridSize: Int, cells: [[GameColor]]) {
        precondition(gridSize > 0, "Grid size must be positive")
        precondition(cells.count == gridSize, "Cell rows must match grid size")
        precondition(cells.allSatisfy({ $0.count == gridSize }), "Cell columns must match grid size")
        self.gridSize = gridSize
        self.cells = cells
    }

    /// Initialize a board with a given size, filled with a default color.
    init(gridSize: Int) {
        self.gridSize = gridSize
        self.cells = Array(repeating: Array(repeating: GameColor.coral, count: gridSize), count: gridSize)
    }

    /// Returns the color at the given position.
    func color(atRow row: Int, col: Int) -> GameColor {
        return cells[row][col]
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
                if !visited.contains(neighbor) && cells[neighbor.row][neighbor.col] == targetColor {
                    visited.insert(neighbor)
                    queue.append(neighbor)
                }
            }
        }

        return visited
    }

    /// Performs a flood fill with the given color.
    /// Changes the entire flood region to the new color, then absorbs all adjacent cells matching it.
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
                if !absorbed.contains(neighbor) && cells[neighbor.row][neighbor.col] == newColor {
                    absorbed.insert(neighbor)
                    queue.append(neighbor)
                }
            }
        }
        // Mark all absorbed cells with the new color (they already match, but ensures consistency)
        for pos in absorbed {
            cells[pos.row][pos.col] = newColor
        }
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
        return FloodBoard(gridSize: size, cells: cells)
    }

    /// Returns the 4-directional neighbors of a cell position within bounds.
    private func neighbors(of position: CellPosition) -> [CellPosition] {
        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        return directions.compactMap { dr, dc in
            let r = position.row + dr
            let c = position.col + dc
            guard r >= 0, r < gridSize, c >= 0, c < gridSize else { return nil }
            return CellPosition(row: r, col: c)
        }
    }
}

/// A hashable position on the grid.
struct CellPosition: Hashable {
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
