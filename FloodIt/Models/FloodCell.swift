import Foundation

/// Represents a single cell on the flood board.
struct FloodCell {
    let row: Int
    let col: Int
    var color: GameColor
}

/// The type of a cell on the board, determining its behavior during flood fill.
enum CellType: Equatable {
    case normal
    case stone
    case void
    case portal(pairId: Int)
    case countdown(movesLeft: Int)
    case ice(layers: Int)
    case bonus(multiplier: Int)
}

/// Cardinal directions for wall edges between cells.
enum Direction: Hashable, CaseIterable, Codable {
    case north, south, east, west

    /// The opposite direction.
    var opposite: Direction {
        switch self {
        case .north: return .south
        case .south: return .north
        case .east: return .west
        case .west: return .east
        }
    }

    /// Row/col delta for this direction.
    var delta: (dr: Int, dc: Int) {
        switch self {
        case .north: return (-1, 0)
        case .south: return (1, 0)
        case .east:  return (0, 1)
        case .west:  return (0, -1)
        }
    }
}

/// Represents a wall between two adjacent cells.
struct Wall: Hashable {
    let position: CellPosition
    let direction: Direction
}
