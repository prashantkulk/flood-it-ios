import Foundation

/// Calculates star rating based on moves used vs optimal solution.
struct StarRating {
    /// Calculate stars earned for a completed game.
    /// - Parameters:
    ///   - movesUsed: Number of moves the player used
    ///   - optimalMoves: Number of moves the greedy solver uses
    /// - Returns: 1, 2, or 3 stars
    static func calculate(movesUsed: Int, optimalMoves: Int) -> Int {
        if movesUsed <= optimalMoves + 1 {
            return 3
        } else if movesUsed <= optimalMoves + 3 {
            return 2
        } else {
            return 1
        }
    }
}
