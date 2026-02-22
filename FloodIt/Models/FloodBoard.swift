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

    /// Computes the current flood region — all cells connected to top-left sharing its color.
    func floodRegion() -> Set<CellPosition> {
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
