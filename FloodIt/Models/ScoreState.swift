import Foundation

/// Tracks scoring for a game session: per-move scores and end-of-game bonuses.
class ScoreState: ObservableObject {
    @Published private(set) var totalScore: Int = 0
    @Published private(set) var lastMoveScore: Int = 0
    @Published private(set) var lastCellsAbsorbed: Int = 0

    /// End-of-round bonus breakdown (for win card display).
    @Published private(set) var speedBonus: Int = 0
    @Published private(set) var comboBonus: Int = 0

    /// Pending tally ticks (one per remaining move, 50 pts each). Set by recordEndBonus, consumed by applyTallyTick.
    private(set) var pendingTallyTicks: Int = 0
    /// Whether the perfect bonus (+500) is pending.
    private(set) var hasPerfectBonus: Bool = false

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

    /// Prepare end-of-game bonus for tally animation. Also calculates speed and combo bonuses.
    func recordEndBonus(movesRemaining: Int, isOptimalPlusOne: Bool, maxCombo: Int = 0, timeTaken: TimeInterval = 0, totalMoves: Int = 0) {
        pendingTallyTicks = movesRemaining
        hasPerfectBonus = isOptimalPlusOne

        // Speed bonus: up to 500 pts, scaled by move budget
        if totalMoves > 0 {
            let baseTime = Double(max(15, totalMoves * 3))
            let maxTime = Double(max(60, totalMoves * 8))
            let seconds = max(0, timeTaken)
            if seconds < baseTime {
                speedBonus = 500
            } else if seconds < maxTime {
                speedBonus = Int(500.0 * (1.0 - (seconds - baseTime) / (maxTime - baseTime)))
            } else {
                speedBonus = 0
            }
        }

        // Combo bonus: 75 per max combo level
        comboBonus = maxCombo * 75

        // Add speed and combo bonuses to total immediately
        totalScore += speedBonus + comboBonus
    }

    /// Apply one tally tick (+50 points). Returns true if more ticks remain.
    @discardableResult
    func applyTallyTick() -> Bool {
        guard pendingTallyTicks > 0 else { return false }
        totalScore += 50
        pendingTallyTicks -= 1
        return pendingTallyTicks > 0
    }

    /// Apply the perfect clear bonus (+500 points).
    func applyPerfectBonus() {
        guard hasPerfectBonus else { return }
        totalScore += 500
        hasPerfectBonus = false
    }

    /// Reset all scoring state for a new game.
    func reset() {
        totalScore = 0
        lastMoveScore = 0
        lastCellsAbsorbed = 0
        pendingTallyTicks = 0
        hasPerfectBonus = false
        speedBonus = 0
        comboBonus = 0
    }
}
