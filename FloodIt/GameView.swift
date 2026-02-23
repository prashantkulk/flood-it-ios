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
    @State private var showWinCard: Bool = false
    @State private var winCardOffset: CGFloat = 600
    @State private var starScales: [CGFloat] = [0, 0, 0]
    @State private var showLoseCard: Bool = false
    @State private var loseCardOffset: CGFloat = 600
    @Environment(\.dismiss) private var dismiss

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
                .onAppear {
                    SoundManager.shared.startAmbient()
                    scene.onWinAnimationComplete = {
                        DispatchQueue.main.async {
                            showWinCard = true
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                winCardOffset = 0
                            }
                            // Stagger star reveals after card slides in
                            let stars = StarRating.calculate(movesUsed: gameState.movesMade, optimalMoves: gameState.optimalMoves)
                            for i in 0..<stars {
                                let delay = 0.5 + Double(i) * 0.3
                                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                        starScales[i] = 1.0
                                    }
                                    SoundManager.shared.playStarChime(noteIndex: i)
                                }
                            }
                        }
                    }
                    scene.onLoseAnimationComplete = {
                        DispatchQueue.main.async {
                            showLoseCard = true
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                loseCardOffset = 0
                            }
                        }
                    }
                }

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
            if showLoseCard {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 20) {
                    if almostCellCount > 0 {
                        // "Almost!" variant for ≤2 remaining cells
                        Text("SO CLOSE!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Just \(almostCellCount) cell\(almostCellCount == 1 ? "" : "s") left!")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))

                        VStack(spacing: 12) {
                            Button(action: {
                                useExtraMoves()
                            }) {
                                Text("Extra Moves (+3)")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(red: 0.06, green: 0.06, blue: 0.12))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.white)
                                    .clipShape(Capsule())
                            }
                            .accessibilityIdentifier("extraMovesButton")

                            Button(action: {
                                resetGame()
                            }) {
                                Text("Try Again")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .accessibilityIdentifier("tryAgainButton")

                            Button(action: {
                                dismiss()
                            }) {
                                Text("Quit")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .accessibilityIdentifier("quitButton")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    } else {
                        // Standard lose overlay
                        Text("Out of Moves")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        VStack(spacing: 12) {
                            Button(action: {
                                resetGame()
                            }) {
                                Text("Try Again")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(red: 0.06, green: 0.06, blue: 0.12))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.white)
                                    .clipShape(Capsule())
                            }
                            .accessibilityIdentifier("tryAgainButton")

                            Button(action: {
                                dismiss()
                            }) {
                                Text("Quit")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .accessibilityIdentifier("quitButton")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 24)
                .frame(maxWidth: 300)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .offset(y: loseCardOffset)
            }

            // Win score card overlay
            if showWinCard {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 20) {
                    Text("Solved!")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    // Moves info
                    HStack(spacing: 4) {
                        Text("\(gameState.movesMade)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("/ \(gameState.totalMoves)")
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .offset(y: 8)
                    }

                    Text("moves")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .offset(y: -10)

                    // Star rating with staggered animation
                    HStack(spacing: 8) {
                        let stars = StarRating.calculate(movesUsed: gameState.movesMade, optimalMoves: gameState.optimalMoves)
                        ForEach(0..<3, id: \.self) { index in
                            Image(systemName: index < stars ? "star.fill" : "star")
                                .font(.system(size: 28))
                                .foregroundColor(index < stars ? .yellow : .white.opacity(0.3))
                                .scaleEffect(index < stars ? starScales[index] : 1.0)
                        }
                    }
                    .padding(.vertical, 4)

                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            resetGame()
                        }) {
                            Text("Next")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.06, green: 0.06, blue: 0.12))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.white)
                                .clipShape(Capsule())
                        }
                        .accessibilityIdentifier("nextButton")

                        Button(action: {
                            resetGame()
                        }) {
                            Text("Replay")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .accessibilityIdentifier("replayButton")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 24)
                .frame(maxWidth: 300)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .offset(y: winCardOffset)
            }
        }
    }

    /// Number of unflooded cells if ≤2 (for "Almost!" mechanic), 0 otherwise.
    private var almostCellCount: Int {
        let count = gameState.unfloodedCellCount
        return count <= 2 ? count : 0
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
        SoundManager.shared.playButtonClick(centerFrequency: color.clickFrequency)

        // Detect if this move will complete the board
        let willComplete = gameState.board.wouldComplete(color: color)
        if willComplete {
            isWinningMove = true
        }

        let result = gameState.performFlood(color: color)

        // Update ambient volume based on flood progress
        let totalCells = Double(gameState.board.gridSize * gameState.board.gridSize)
        let floodedCells = Double(gameState.board.floodRegion.count)
        SoundManager.shared.updateAmbientVolume(floodPercentage: floodedCells / totalCells)

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

        // Trigger lose animation if game just ended
        if gameState.gameStatus == .lost {
            SoundManager.shared.playLoseTone()
            scene.animateLose()
            // Pulse remaining cells if "almost" (≤2 unflooded)
            if gameState.unfloodedCellCount <= 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    scene.pulseUnfloodedCells()
                }
            }
        }
    }

    private func useExtraMoves() {
        showLoseCard = false
        loseCardOffset = 600
        gameState.grantExtraMoves(3)
        // Restore cell alpha and stop pulsing
        scene.stopPulseUnfloodedCells()
        scene.updateColors(from: gameState.board)
    }

    private func resetGame() {
        showWinCard = false
        winCardOffset = 600
        showLoseCard = false
        loseCardOffset = 600
        isWinningMove = false
        starScales = [0, 0, 0]
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
