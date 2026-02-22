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
                // Move counter
                Text("Moves: \(gameState.movesRemaining)")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 60)
                    .accessibilityIdentifier("moveCounter")

                Spacer()

                // Color buttons
                HStack(spacing: 16) {
                    ForEach(GameColor.allCases, id: \.self) { color in
                        Button(action: {
                            gameState.performFlood(color: color)
                            scene.updateColors(from: gameState.board)
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

            // Lose overlay
            if gameState.gameStatus == .lost {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Out of Moves")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Button(action: {
                        resetGame()
                    }) {
                        Text("Try Again")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.06, green: 0.06, blue: 0.12))
                            .padding(.horizontal, 48)
                            .padding(.vertical, 14)
                            .background(.white)
                            .clipShape(Capsule())
                    }
                    .accessibilityIdentifier("tryAgainButton")
                }
            }

            // Win overlay
            if gameState.gameStatus == .won {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("You Won!")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Moves used: \(gameState.movesMade)")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))

                    Button(action: {
                        // Next level — for now just restart
                        resetGame()
                    }) {
                        Text("Next")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.06, green: 0.06, blue: 0.12))
                            .padding(.horizontal, 48)
                            .padding(.vertical, 14)
                            .background(.white)
                            .clipShape(Capsule())
                    }
                    .accessibilityIdentifier("nextButton")
                }
            }
        }
    }

    private func resetGame() {
        let board = FloodBoard.generateBoard(size: 9, colors: GameColor.allCases, seed: seed)
        gameState.reset(board: board, totalMoves: 30)
        scene.configure(with: board)
    }
}

#Preview {
    GameView()
}
