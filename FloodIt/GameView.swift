import SwiftUI
import SpriteKit
import UIKit

struct GameView: View {
    @StateObject private var gameState: GameState
    private let scene: GameScene
    private let seed: UInt64
    @State private var moveCounterScale: CGFloat = 1.0
    @State private var moveCounterFlash: Bool = false
    @State private var moveCounterPulse: Bool = false
    @State private var isWinningMove: Bool = false

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

            // Subtle border frame around the board area (no fill, just a thin luminous border)
            GeometryReader { geo in
                let boardSize = geo.size.width - 12
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
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
                        .foregroundColor(moveCounterColor)
                        .opacity(gameState.movesRemaining <= 2 ? (moveCounterPulse ? 0.7 : 1.0) : 1.0)
                        .scaleEffect(moveCounterScale)
                        .overlay(
                            Color.white
                                .opacity(moveCounterFlash ? 0.6 : 0)
                                .blendMode(.sourceAtop)
                                .allowsHitTesting(false)
                        )
                        .accessibilityIdentifier("moveCounter")
                        .onChange(of: gameState.movesRemaining) { newValue in
                            moveCounterFlash = true
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                                moveCounterScale = 1.2
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                    moveCounterScale = 1.0
                                }
                                withAnimation(.easeOut(duration: 0.15)) {
                                    moveCounterFlash = false
                                }
                            }
                            // Start/stop pulse for critical moves
                            if newValue <= 2 {
                                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                    moveCounterPulse = true
                                }
                            } else {
                                moveCounterPulse = false
                            }
                        }

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
                            tapColorButton(color)
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
                        .buttonStyle(OrbPressStyle())
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

    private var moveCounterColor: Color {
        if gameState.movesRemaining <= 2 { return .red }
        if gameState.movesRemaining <= 5 { return .orange }
        return .white
    }

    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let warningHaptic = UINotificationFeedbackGenerator()

    private func tapColorButton(_ color: GameColor) {
        let currentColor = gameState.board.cells[0][0]
        if color == currentColor {
            warningHaptic.notificationOccurred(.warning)
            return
        }
        lightHaptic.impactOccurred()

        // Detect if this move will complete the board
        let willComplete = gameState.board.wouldComplete(color: color)
        if willComplete {
            isWinningMove = true
        }

        let result = gameState.performFlood(color: color)
        if result.waves.isEmpty {
            scene.updateColors(from: gameState.board)
        } else {
            scene.animateFlood(
                board: gameState.board,
                waves: result.waves,
                newColor: color,
                previousColors: result.previousColors,
                isWinningMove: willComplete
            )
        }
    }

    private func resetGame() {
        let board = FloodBoard.generateBoard(size: 9, colors: GameColor.allCases, seed: seed)
        gameState.reset(board: board, totalMoves: 30)
        scene.configure(with: board)
    }
}

/// Button style that scales down on press (0.88x) and bounces back on release (1.05x → 1.0x).
struct OrbPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(
                configuration.isPressed
                    ? .easeIn(duration: 0.08)
                    : .spring(response: 0.25, dampingFraction: 0.5),
                value: configuration.isPressed
            )
    }
}

#Preview {
    GameView()
}
