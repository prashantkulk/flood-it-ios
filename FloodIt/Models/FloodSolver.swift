import Foundation

/// Greedy solver that plays the game by always picking the color that absorbs the most cells.
/// Not optimal, but good enough to set move budgets.
struct FloodSolver {

    /// Solves the board greedily, returning the sequence of colors chosen.
    static func solve(board: FloodBoard) -> [GameColor] {
        var currentBoard = board
        var moves = [GameColor]()

        while !currentBoard.isComplete {
            let currentColor = currentBoard.cells[0][0]
            var bestColor: GameColor = GameColor.allCases.first(where: { $0 != currentColor }) ?? .coral
            var bestCount = 0

            for color in GameColor.allCases {
                if color == currentColor { continue }
                let absorbed = currentBoard.cellsAbsorbedBy(color: color)
                let count = absorbed.flatMap { $0 }.count
                if count > bestCount {
                    bestCount = count
                    bestColor = color
                }
            }

            currentBoard.flood(color: bestColor)
            moves.append(bestColor)

            // Safety: prevent infinite loops on degenerate boards
            if moves.count > board.gridSize * board.gridSize {
                break
            }
        }

        return moves
    }

    /// Returns the number of moves the greedy solver needs to complete the board.
    static func solveMoveCount(board: FloodBoard) -> Int {
        return solve(board: board).count
    }
}
