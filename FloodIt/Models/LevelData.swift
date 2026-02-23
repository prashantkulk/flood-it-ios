import Foundation

/// Metadata for a single level in the game.
struct LevelData: Codable, Identifiable {
    let id: Int          // 1-based level number
    let seed: UInt64
    let gridSize: Int
    let colorCount: Int  // number of colors to use
    let optimalMoves: Int
    let moveBudget: Int
    let tier: Tier

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

    private static func generateAllLevels() -> [LevelData] {
        var result = [LevelData]()

        for i in 1...100 {
            let seed = UInt64(i * 31 + 7)  // deterministic seed per level
            let tier: LevelData.Tier = i <= 50 ? .splash : .current
            let gridSize = 9
            let colorCount = 5
            let colors = Array(GameColor.allCases.prefix(colorCount))

            let board = FloodBoard.generateBoard(size: gridSize, colors: colors, seed: seed)
            let optimalMoves = FloodSolver.solveMoveCount(board: board)

            // Difficulty scaling: easier levels get more extra moves
            let extraMoves: Int
            switch i {
            case 1...10:  extraMoves = 8   // easy
            case 11...30: extraMoves = 6
            case 31...50: extraMoves = 4   // medium
            case 51...70: extraMoves = 3
            case 71...90: extraMoves = 2   // hard
            default:      extraMoves = 1   // expert-ish
            }

            let moveBudget = optimalMoves + extraMoves

            result.append(LevelData(
                id: i,
                seed: seed,
                gridSize: gridSize,
                colorCount: colorCount,
                optimalMoves: optimalMoves,
                moveBudget: moveBudget,
                tier: tier
            ))
        }

        return result
    }
}
