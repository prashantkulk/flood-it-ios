import Foundation

/// Tracks the current state of a game: board, moves, and win/lose status.
class GameState: ObservableObject {
    @Published var board: FloodBoard
    @Published private(set) var movesRemaining: Int
    @Published private(set) var movesMade: Int
    @Published private(set) var gameStatus: GameStatus
    @Published private(set) var comboCount: Int = 0

    private(set) var totalMoves: Int
    private(set) var optimalMoves: Int = 0
    private(set) var maxCombo: Int = 0

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
    }

    /// Computes the wave data for animation BEFORE mutating the board, then performs the flood.
    /// Returns the waves of absorbed cells (empty if move is invalid), plus the previous colors for crossfade.
    @discardableResult
    func performFlood(color: GameColor) -> (waves: [[CellPosition]], previousColors: [CellPosition: GameColor]) {
        guard gameStatus == .playing else { return ([], [:]) }

        // Don't waste a move if tapping the same color as current flood region
        let currentColor = board.cells[0][0]
        guard color != currentColor else { return ([], [:]) }

        // Capture wave data and previous colors BEFORE mutating
        let waves = board.cellsAbsorbedBy(color: color)
        var previousColors = [CellPosition: GameColor]()
        for wave in waves {
            for pos in wave {
                previousColors[pos] = board.cells[pos.row][pos.col]
            }
        }
        // Also capture the existing flood region cells that change color
        let floodRegion = board.floodRegion
        for pos in floodRegion {
            previousColors[pos] = board.cells[pos.row][pos.col]
        }

        // Count absorbed cells for combo tracking
        let absorbedCount = waves.flatMap { $0 }.count

        board.flood(color: color)
        movesMade += 1
        movesRemaining -= 1

        // Update combo: >=4 cells absorbed increments, <4 resets
        if absorbedCount >= 4 {
            comboCount += 1
            if comboCount > maxCombo {
                maxCombo = comboCount
            }
        } else {
            comboCount = 0
        }

        if board.isComplete {
            gameStatus = .won
        } else if movesRemaining <= 0 {
            gameStatus = .lost
        }

        return (waves, previousColors)
    }

    /// Returns the number of cells not in the flood region.
    var unfloodedCellCount: Int {
        let total = board.gridSize * board.gridSize
        return total - board.floodRegion.count
    }

    /// Grants extra moves, returning the game to playing state.
    func grantExtraMoves(_ count: Int) {
        movesRemaining += count
        totalMoves += count
        gameStatus = .playing
    }
}
