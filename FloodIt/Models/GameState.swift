import Foundation

/// Tracks the current state of a game: board, moves, and win/lose status.
class GameState: ObservableObject {
    @Published var board: FloodBoard
    @Published private(set) var movesRemaining: Int
    @Published private(set) var movesMade: Int
    @Published private(set) var gameStatus: GameStatus

    let totalMoves: Int

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
    }

    /// Performs a flood with the given color, decrements moves, and checks win/lose.
    func performFlood(color: GameColor) {
        guard gameStatus == .playing else { return }

        // Don't waste a move if tapping the same color as current flood region
        let currentColor = board.cells[0][0]
        guard color != currentColor else { return }

        board.flood(color: color)
        movesMade += 1
        movesRemaining -= 1

        if board.isComplete {
            gameStatus = .won
        } else if movesRemaining <= 0 {
            gameStatus = .lost
        }
    }
}
