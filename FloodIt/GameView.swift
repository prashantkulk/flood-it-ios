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

            // Glassmorphism container behind the board
            GeometryReader { geo in
                let boardSize = geo.size.width - 16
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .frame(width: boardSize, height: boardSize)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2 + 20)
                    .allowsHitTesting(false)
            }

            VStack {
                // Top bar: move counter + restart
                HStack {
                    Text("Moves: \(gameState.movesRemaining)")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .accessibilityIdentifier("moveCounter")

                    Spacer()

                    Button(action: {
                        resetGame()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .accessibilityIdentifier("restartButton")
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                // Color buttons — glowing orbs
                HStack(spacing: 16) {
                    ForEach(GameColor.allCases, id: \.self) { color in
                        Button(action: {
                            gameState.performFlood(color: color)
                            scene.updateColors(from: gameState.board)
                        }) {
                            ZStack {
                                // Outer glow halo
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [color.lightColor.opacity(0.4), color.lightColor.opacity(0)],
                                            center: .center,
                                            startRadius: 10,
                                            endRadius: 36
                                        )
                                    )
                                    .frame(width: 64, height: 64)

                                // Orb body — radial gradient (lighter center, darker edge)
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [color.lightColor, color.darkColor],
                                            center: .init(x: 0.4, y: 0.35),
                                            startRadius: 2,
                                            endRadius: 28
                                        )
                                    )
                                    .frame(width: 48, height: 48)

                                // Gloss highlight
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [.white.opacity(0.45), .white.opacity(0)],
                                            center: .init(x: 0.35, y: 0.3),
                                            startRadius: 0,
                                            endRadius: 14
                                        )
                                    )
                                    .frame(width: 48, height: 48)
                            }
                            .shadow(color: color.shadowColor, radius: 8, x: 0, y: 4)
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
