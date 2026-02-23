import Foundation

/// Tracks scoring for a game session: per-move scores and end-of-game bonuses.
class ScoreState: ObservableObject {
    @Published private(set) var totalScore: Int = 0
    @Published private(set) var lastMoveScore: Int = 0
    @Published private(set) var lastCellsAbsorbed: Int = 0

    /// Calculate score for a single move.
    /// Formula: base = cellsAbsorbed * 20, then * comboMultiplier * cascadeMultiplier.
    func calculateMoveScore(cellsAbsorbed: Int, comboMultiplier: Double = 1.0, cascadeMultiplier: Double = 1.0) -> Int {
        let base = cellsAbsorbed * 20
        return Int(Double(base) * comboMultiplier * cascadeMultiplier)
    }

    /// Calculate end-of-game bonus.
    /// 50 per remaining move, +500 if optimal+1 or better.
    func calculateEndBonus(movesRemaining: Int, isOptimalPlusOne: Bool) -> Int {
        var bonus = movesRemaining * 50
        if isOptimalPlusOne {
            bonus += 500
        }
        return bonus
    }

    /// Record a move score, updating totals and last-move state.
    func recordMove(cellsAbsorbed: Int, comboMultiplier: Double = 1.0, cascadeMultiplier: Double = 1.0) {
        let score = calculateMoveScore(cellsAbsorbed: cellsAbsorbed, comboMultiplier: comboMultiplier, cascadeMultiplier: cascadeMultiplier)
        lastMoveScore = score
        lastCellsAbsorbed = cellsAbsorbed
        totalScore += score
    }

    /// Record end-of-game bonus.
    func recordEndBonus(movesRemaining: Int, isOptimalPlusOne: Bool) {
        let bonus = calculateEndBonus(movesRemaining: movesRemaining, isOptimalPlusOne: isOptimalPlusOne)
        totalScore += bonus
    }

    /// Reset all scoring state for a new game.
    func reset() {
        totalScore = 0
        lastMoveScore = 0
        lastCellsAbsorbed = 0
    }
}
