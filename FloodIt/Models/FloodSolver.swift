import Foundation

/// Greedy solver that plays the game by always picking the color that absorbs the most cells.
/// Handles all obstacle types: stones, voids, ice, countdowns, portals, walls, and bonus tiles.
struct FloodSolver {

    /// Solves the board greedily, returning the sequence of colors chosen.
    static func solve(board: FloodBoard) -> [GameColor] {
        var currentBoard = board
        var moves = [GameColor]()
        var rng = SeededRandomNumberGenerator(seed: 0)

        // Higher safety limit to account for ice layers and countdown scrambles
        let maxMoves = board.gridSize * board.gridSize * 3

        while !currentBoard.isComplete {
            let currentColor = currentBoard.cells[0][0]
            var bestColor: GameColor = GameColor.allCases.first(where: { $0 != currentColor }) ?? .coral
            var bestScore = -1

            for color in GameColor.allCases {
                if color == currentColor { continue }
                let absorbed = currentBoard.cellsAbsorbedBy(color: color)
                let count = absorbed.flatMap { $0 }.count

                // Also consider ice cracking: simulate the flood to count ice cracks
                var simBoard = currentBoard
                simBoard.flood(color: color)
                let iceCracks = countIceCracks(original: currentBoard, after: simBoard)

                let score = count * 10 + iceCracks
                if score > bestScore {
                    bestScore = score
                    bestColor = color
                }
            }

            currentBoard.flood(color: bestColor)
            currentBoard.tickCountdowns(using: &rng)
            moves.append(bestColor)

            if moves.count > maxMoves {
                break
            }
        }

        return moves
    }

    /// Counts how many ice cells had their layers decremented between original and modified board.
    private static func countIceCracks(original: FloodBoard, after modified: FloodBoard) -> Int {
        var cracks = 0
        for row in 0..<original.gridSize {
            for col in 0..<original.gridSize {
                if case .ice(let before) = original.cellTypes[row][col] {
                    let afterType = modified.cellTypes[row][col]
                    switch afterType {
                    case .ice(let after) where after < before:
                        cracks += 1
                    case .normal:
                        cracks += 1
                    default:
                        break
                    }
                }
            }
        }
        return cracks
    }

    /// Returns the number of moves the greedy solver needs to complete the board.
    static func solveMoveCount(board: FloodBoard) -> Int {
        return solve(board: board).count
    }
}
