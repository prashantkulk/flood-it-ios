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
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()

            VStack {
                Spacer()

                // Color buttons
                HStack(spacing: 16) {
                    ForEach(GameColor.allCases, id: \.self) { color in
                        Button(action: {
                            // Wiring in T3
                        }) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [color.lightColor, color.darkColor],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 52, height: 52)
                                .shadow(color: color.shadowColor, radius: 4, x: 0, y: 2)
                        }
                        .accessibilityIdentifier("colorButton_\(color.rawValue)")
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    GameView()
}
