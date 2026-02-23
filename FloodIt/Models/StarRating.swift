import Foundation

/// Calculates star rating based on moves used vs optimal solution.
struct StarRating {
    /// Calculate stars earned for a completed game.
    /// - Parameters:
    ///   - movesUsed: Number of moves the player used
    ///   - optimalMoves: Number of moves the greedy solver uses
    ///   - maxCombo: Highest combo achieved during the level (default 0)
    /// - Returns: 1, 2, or 3 stars
    static func calculate(movesUsed: Int, optimalMoves: Int, maxCombo: Int = 0) -> Int {
        // Combo bonus: subtract from effective moves used
        var comboBonus = 0
        if maxCombo >= 5 {
            comboBonus = 2
        } else if maxCombo >= 3 {
            comboBonus = 1
        }
        let effectiveMoves = movesUsed - comboBonus

        if effectiveMoves <= optimalMoves + 1 {
            return 3
        } else if effectiveMoves <= optimalMoves + 3 {
            return 2
        } else {
            return 1
        }
    }
}
