import Foundation

/// Tracks the current state of a game: board, moves, and win/lose status.
class GameState: ObservableObject {
    @Published var board: FloodBoard
    @Published private(set) var movesRemaining: Int
    @Published private(set) var movesMade: Int
    @Published private(set) var gameStatus: GameStatus
    @Published private(set) var comboCount: Int = 0
    let scoreState = ScoreState()

    private(set) var totalMoves: Int
    private(set) var optimalMoves: Int = 0
    private(set) var maxCombo: Int = 0
    /// History of colors chosen (for share card).
    private(set) var colorHistory: [GameColor] = []
    /// RNG for countdown scramble determinism.
    private var countdownRng = SeededRandomNumberGenerator(seed: 42)

    enum GameStatus {
        case playing
        case won
        case lost
    }

    init(board: FloodBoard, totalMoves: Int) {
        self.board = board
        self.totalMoves = totalMoves
        self.movesRemaining = totalMoves
        self.movesMade = 0
        self.gameStatus = .playing
        self.optimalMoves = FloodSolver.solveMoveCount(board: board)
    }

    /// Resets the game with a new board and move budget.
    func reset(board: FloodBoard, totalMoves: Int) {
        self.board = board
        self.totalMoves = totalMoves
        self.movesRemaining = totalMoves
        self.movesMade = 0
        self.gameStatus = .playing
        self.optimalMoves = FloodSolver.solveMoveCount(board: board)
        self.comboCount = 0
        self.maxCombo = 0
        self.colorHistory = []
        self.countdownRng = SeededRandomNumberGenerator(seed: 42)
        self.scoreState.reset()
    }

    /// Result of performing a flood move, containing data for animation and scoring.
    struct FloodResult {
        let waves: [[CellPosition]]
        let cascadeWaves: [[CellPosition]]
        let previousColors: [CellPosition: GameColor]
        let cascadeCount: Int
    }

    /// Computes the wave data for animation BEFORE mutating the board, then performs the flood.
    /// Returns the waves of absorbed cells (empty if move is invalid), cascade waves, and previous colors.
    @discardableResult
    func performFlood(color: GameColor) -> FloodResult {
        guard gameStatus == .playing else { return FloodResult(waves: [], cascadeWaves: [], previousColors: [:], cascadeCount: 0) }

        // Don't waste a move if tapping the same color as current flood region
        let currentColor = board.cells[0][0]
        guard color != currentColor else { return FloodResult(waves: [], cascadeWaves: [], previousColors: [:], cascadeCount: 0) }

        // Capture wave data and cascade waves BEFORE mutating
        let allWaves = board.cellsAbsorbedBy(color: color)
        let initialWaves: [[CellPosition]] = allWaves.isEmpty ? [] : [allWaves[0]]
        let cascadeWaves: [[CellPosition]] = allWaves.count > 1 ? Array(allWaves.dropFirst()) : []

        var previousColors = [CellPosition: GameColor]()
        for wave in allWaves {
            for pos in wave {
                previousColors[pos] = board.cells[pos.row][pos.col]
            }
        }
        // Also capture the existing flood region cells that change color
        let floodRegion = board.floodRegion
        for pos in floodRegion {
            previousColors[pos] = board.cells[pos.row][pos.col]
        }

        // Count absorbed cells for combo tracking (initial + cascade)
        let absorbedCount = allWaves.flatMap { $0 }.count

        board.flood(color: color)
        board.tickCountdowns(using: &countdownRng)
        movesMade += 1
        movesRemaining -= 1
        colorHistory.append(color)

        // Update combo: >=4 cells absorbed increments, <4 resets
        if absorbedCount >= 4 {
            comboCount += 1
            if comboCount > maxCombo {
                maxCombo = comboCount
            }
        } else {
            comboCount = 0
        }

        // Record move score with cascade multiplier: 1.5^cascadeCount
        let comboMultiplier = comboCount >= 2 ? Double(comboCount) : 1.0
        let cascadeCount = cascadeWaves.count
        let cascadeMultiplier = cascadeCount > 0 ? pow(1.5, Double(cascadeCount)) : 1.0
        scoreState.recordMove(cellsAbsorbed: absorbedCount, comboMultiplier: comboMultiplier, cascadeMultiplier: cascadeMultiplier)

        if board.isComplete {
            gameStatus = .won
            let isOptimalPlusOne = movesMade <= optimalMoves + 1
            scoreState.recordEndBonus(movesRemaining: movesRemaining, isOptimalPlusOne: isOptimalPlusOne)
        } else if movesRemaining <= 0 {
            gameStatus = .lost
        }

        return FloodResult(waves: initialWaves, cascadeWaves: cascadeWaves, previousColors: previousColors, cascadeCount: cascadeCount)
    }

    /// Returns the number of cells not in the flood region.
    var unfloodedCellCount: Int {
        let total = board.gridSize * board.gridSize
        return total - board.floodRegion.count
    }

    /// Flood completion percentage (0.0 - 1.0).
    var floodCompletionPercentage: Double {
        let total = Double(board.gridSize * board.gridSize)
        return Double(board.floodRegion.count) / total
    }

    /// Grants extra moves, returning the game to playing state.
    func grantExtraMoves(_ count: Int) {
        movesRemaining += count
        totalMoves += count
        gameStatus = .playing
    }
}
