import Foundation

/// Generates levels with a seed and sets move budget based on difficulty.
struct LevelGenerator {

    enum Difficulty {
        case easy      // optimal + 8
        case medium    // optimal + 4
        case hard      // optimal + 2
        case expert    // optimal + 0
    }

    /// A generated level with board and move budget.
    struct Level {
        let board: FloodBoard
        let moveBudget: Int
        let optimalMoves: Int
        let seed: UInt64
        let difficulty: Difficulty
    }

    /// Generates a level with the given parameters.
    /// Uses FloodSolver to determine optimal move count, then sets budget based on difficulty.
    static func generateLevel(
        size: Int = 9,
        colors: [GameColor] = GameColor.allCases,
        seed: UInt64,
        difficulty: Difficulty = .medium
    ) -> Level {
        let board = FloodBoard.generateBoard(size: size, colors: colors, seed: seed)
        let optimalMoves = FloodSolver.solveMoveCount(board: board)
        let budget = optimalMoves + extraMoves(for: difficulty)

        return Level(
            board: board,
            moveBudget: budget,
            optimalMoves: optimalMoves,
            seed: seed,
            difficulty: difficulty
        )
    }

    private static func extraMoves(for difficulty: Difficulty) -> Int {
        switch difficulty {
        case .easy:   return 8
        case .medium: return 4
        case .hard:   return 2
        case .expert: return 0
        }
    }
}
