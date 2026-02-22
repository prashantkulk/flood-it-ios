import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject private var gameState: GameState

    private let scene: GameScene
    private let seed: UInt64

    init(seed: UInt64 = 42) {
        self.seed = seed
        let board = FloodBoard.generateBoard(size: 9, colors: GameColor.allCases, seed: seed)
        let totalMoves = 30
        _gameState = StateObject(wrappedValue: GameState(board: board, totalMoves: totalMoves))

        let gameScene = GameScene(size: UIScreen.main.bounds.size)
        gameScene.scaleMode = .resizeFill
        gameScene.configure(with: board)
        self.scene = gameScene
    }

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
}

#Preview {
    GameView()
}
