import SwiftUI
import SpriteKit
import UIKit

struct GameView: View {
    @StateObject private var gameState: GameState
    private let scene: GameScene
    @State private var currentLevelNumber: Int
    @State private var currentLevelData: LevelData
    @State private var moveCounterScale: CGFloat = 1.0
    @State private var moveCounterFlash: Bool = false
    @State private var moveCounterPulse: Bool = false
    @State private var scoreCounterScale: CGFloat = 1.0
    @State private var scoreCounterFlash: Bool = false
    @State private var moveCounterGoldFlash: Bool = false
    @State private var isWinningMove: Bool = false
    @State private var showWinCard: Bool = false
    @State private var winCardOffset: CGFloat = 600
    @State private var starScales: [CGFloat] = [0, 0, 0]
    @State private var showLoseCard: Bool = false
    @State private var loseCardOffset: CGFloat = 600
    @State private var showSettings: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var hintColor: GameColor? = nil
    /// Whether this is a daily challenge game.
    let isDailyChallenge: Bool
    /// The daily challenge date string (shown on screen).
    let dailyChallengeDate: String?
    @Environment(\.dismiss) private var dismiss

    init(levelNumber: Int = 1) {
        _currentLevelNumber = State(initialValue: levelNumber)
        let data = LevelStore.level(levelNumber) ?? LevelStore.levels[0]
        _currentLevelData = State(initialValue: data)
        let colors = Array(GameColor.allCases.prefix(data.colorCount))
        let board = FloodBoard.generateBoard(size: data.gridSize, colors: colors, seed: data.seed)
        _gameState = StateObject(wrappedValue: GameState(board: board, totalMoves: data.moveBudget))

        let gameScene = GameScene(size: UIScreen.main.bounds.size)
        gameScene.scaleMode = .resizeFill
        gameScene.configure(with: board)
        self.scene = gameScene
        self.isDailyChallenge = false
        self.dailyChallengeDate = nil
    }

    init(dailyChallengeDate date: Date) {
        let board = DailyChallenge.generateBoard(for: date)
        let budget = DailyChallenge.moveBudget(for: date)
        _currentLevelNumber = State(initialValue: -1) // sentinel for daily
        let data = LevelData(id: -1, seed: DailyChallenge.seed(for: date), gridSize: 9, colorCount: 5, optimalMoves: FloodSolver.solveMoveCount(board: board), moveBudget: budget, tier: .splash)
        _currentLevelData = State(initialValue: data)
        _gameState = StateObject(wrappedValue: GameState(board: board, totalMoves: budget))

        let gameScene = GameScene(size: UIScreen.main.bounds.size)
        gameScene.scaleMode = .resizeFill
        gameScene.configure(with: board)
        self.scene = gameScene
        self.isDailyChallenge = true

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        self.dailyChallengeDate = formatter.string(from: date)
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
                            let stars = StarRating.calculate(movesUsed: gameState.movesMade, optimalMoves: gameState.optimalMoves, maxCombo: gameState.maxCombo)
                            if isDailyChallenge {
                                let dateStr = DailyChallenge.dateString(for: Date())
                                let result = DailyResult(
                                    dateString: dateStr,
                                    movesUsed: gameState.movesMade,
                                    moveBudget: gameState.totalMoves,
                                    starsEarned: stars,
                                    colorsUsed: gameState.colorHistory.prefix(5).map { $0.rawValue }
                                )
                                ProgressStore.shared.saveDailyResult(result)
                            } else {
                                ProgressStore.shared.updateStars(for: currentLevelNumber, stars: stars)
                            }
                            ProgressStore.shared.recordPlay()
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
                if isDailyChallenge, let dateStr = dailyChallengeDate {
                    Text(dateStr)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 44)
                }

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
                        .overlay(
                            Color(red: 1.0, green: 0.84, blue: 0.0)
                                .opacity(moveCounterGoldFlash ? 0.7 : 0)
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

                    // MARK: P14-T3 Score counter
                    Text("\(gameState.scoreState.totalScore)")
                        .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        .scaleEffect(scoreCounterScale)
                        .overlay(
                            Color(red: 1.0, green: 0.84, blue: 0.0)
                                .opacity(scoreCounterFlash ? 0.6 : 0)
                                .blendMode(.sourceAtop)
                                .allowsHitTesting(false)
                        )
                        .accessibilityIdentifier("scoreCounter")
                        .onChange(of: gameState.scoreState.totalScore) { _ in
                            scoreCounterFlash = true
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                                scoreCounterScale = 1.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    scoreCounterScale = 1.0
                                }
                                withAnimation(.easeOut(duration: 0.2)) {
                                    scoreCounterFlash = false
                                }
                            }
                        }

                    Spacer()

                    // MARK: P12-T3 Hint button
                    Button(action: {
                        watchAdForHint()
                    }) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(hintColor != nil ? hintColor!.lightColor : .white.opacity(0.7))
                    }
                    .accessibilityIdentifier("hintButton")
                    .disabled(gameState.gameStatus != .playing)

                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .accessibilityIdentifier("settingsButton")

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
                    ForEach(Array(GameColor.allCases.prefix(currentLevelData.colorCount)), id: \.self) { color in
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
                                watchAdForExtraMoves()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.rectangle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Extra Moves (+3)")
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                }
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
                        let stars = StarRating.calculate(movesUsed: gameState.movesMade, optimalMoves: gameState.optimalMoves, maxCombo: gameState.maxCombo)
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
                        if isDailyChallenge {
                            Button(action: {
                                showShareSheet = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Share")
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(Color(red: 0.06, green: 0.06, blue: 0.12))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.white)
                                .clipShape(Capsule())
                            }
                            .accessibilityIdentifier("shareButton")

                            Button(action: {
                                dismiss()
                            }) {
                                Text("Done")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .accessibilityIdentifier("doneButton")
                        } else {
                            Button(action: {
                                advanceToNextLevel()
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
                .sheet(isPresented: $showShareSheet) {
                    if isDailyChallenge {
                        let challengeNum = DailyChallenge.challengeNumber(for: Date())
                        let stars = StarRating.calculate(movesUsed: gameState.movesMade, optimalMoves: gameState.optimalMoves, maxCombo: gameState.maxCombo)
                        let starStr = String(repeating: "\u{2605}", count: stars) + String(repeating: "\u{2606}", count: 3 - stars)
                        let shareText = "Flood It Daily #\(challengeNum) \(starStr) \(gameState.movesMade)/\(gameState.totalMoves) moves"
                        let result = DailyResult(
                            dateString: DailyChallenge.dateString(for: Date()),
                            movesUsed: gameState.movesMade,
                            moveBudget: gameState.totalMoves,
                            starsEarned: stars,
                            colorsUsed: gameState.colorHistory.prefix(5).map { $0.rawValue }
                        )
                        let image = ShareCardRenderer.render(result: result, challengeNumber: challengeNum)
                        ShareSheet(items: [image, shareText])
                    }
                }
            }

            // Settings overlay
            if showSettings {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showSettings = false }
                    .transition(.opacity)

                SettingsView()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSettings)
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
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidHaptic = UIImpactFeedbackGenerator(style: .rigid)
    private let warningHaptic = UINotificationFeedbackGenerator()

    private func tapColorButton(_ color: GameColor) {
        let currentColor = gameState.board.cells[0][0]
        if color == currentColor {
            warningHaptic.notificationOccurred(.warning)
            return
        }
        SoundManager.shared.playButtonClick(centerFrequency: color.clickFrequency)

        // Detect if this move will complete the board
        let willComplete = gameState.board.wouldComplete(color: color)
        if willComplete {
            isWinningMove = true
        }

        let prevCombo = gameState.comboCount
        let result = gameState.performFlood(color: color)

        // MARK: P14-T7 Tiered haptics based on cells absorbed
        let cellsAbsorbed = result.waves.flatMap { $0 }.count
        if cellsAbsorbed >= 15 {
            heavyHaptic.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
                rigidHaptic.impactOccurred()
            }
        } else if cellsAbsorbed >= 5 {
            mediumHaptic.impactOccurred()
        } else {
            lightHaptic.impactOccurred()
        }
        if cellsAbsorbed >= 10 {
            moveCounterGoldFlash = true
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                moveCounterScale = 1.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    moveCounterScale = 1.0
                }
                withAnimation(.easeOut(duration: 0.2)) {
                    moveCounterGoldFlash = false
                }
            }
        }

        // Combo audio
        if gameState.comboCount >= 3 {
            // x2+ reverb plip
            SoundManager.shared.playComboPlip(frequency: 440 + Double(gameState.comboCount) * 30)
            // x3+ bass throb
            if gameState.comboCount >= 4 {
                SoundManager.shared.playBassThob()
            }
        }
        // Combo break: tink + fade out visuals
        let comboJustBroke = gameState.comboCount == 0 && prevCombo >= 3
        if comboJustBroke {
            SoundManager.shared.playComboBreakTink()
        }

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
            // MARK: P14-T5/T6 Floating text
            if cellsAbsorbed > 0 {
                scene.spawnFloatingCellsText(waves: result.waves, cellsAbsorbed: cellsAbsorbed)
                let comboMult = gameState.comboCount >= 2 ? Double(gameState.comboCount) : 1.0
                scene.spawnFloatingPointsText(waves: result.waves, points: gameState.scoreState.lastMoveScore, multiplier: comboMult)
            }
        }

        // Update combo visuals
        if gameState.comboCount >= 3 {
            let intensity = gameState.comboCount >= 4 ? 2 : 1
            scene.showComboGlow(board: gameState.board, intensity: intensity)
            // x3+ sparks
            if gameState.comboCount >= 4 {
                scene.spawnComboSparks(board: gameState.board)
            }
            // x4+ saturation + screen shake
            if gameState.comboCount >= 5 {
                scene.applyComboSaturation()
                scene.comboScreenShake()
            }
        } else if comboJustBroke {
            // Animate combo visuals fading out
            scene.fadeOutComboGlow(duration: 0.3)
            scene.removeComboSaturation()
        } else {
            scene.removeComboGlow()
            scene.removeComboSaturation()
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

    // MARK: - P12-T3 Rewarded video for extra moves and hints

    private func watchAdForExtraMoves() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            useExtraMoves()
            return
        }
        adManager.showRewardedVideo(from: rootVC) { [self] rewarded in
            if rewarded {
                useExtraMoves()
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

    private func watchAdForHint() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            showHint()
            return
        }
        adManager.showRewardedVideo(from: rootVC) { [self] rewarded in
            if rewarded {
                showHint()
            }
        }
    }

    private func showHint() {
        // Use greedy solver to find best next color
        let currentColor = gameState.board.cells[0][0]
        let colors = Array(GameColor.allCases.prefix(currentLevelData.colorCount))
        var bestColor = colors.first(where: { $0 != currentColor }) ?? .coral
        var bestCount = 0
        for color in colors {
            if color == currentColor { continue }
            let absorbed = gameState.board.cellsAbsorbedBy(color: color)
            let count = absorbed.flatMap { $0 }.count
            if count > bestCount {
                bestCount = count
                bestColor = color
            }
        }
        // Highlight the hint color briefly
        hintColor = bestColor
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            hintColor = nil
        }
    }

    // MARK: - P12-T2 Pack boundary interstitial

    /// Pack boundaries where an interstitial ad should show (e.g., level 50 → 51).
    private static let packBoundaries: Set<Int> = [50]

    private func advanceToNextLevel() {
        let nextNumber = currentLevelNumber + 1
        guard let nextData = LevelStore.level(nextNumber) else {
            // No more levels, just dismiss
            dismiss()
            return
        }

        // Check if crossing a pack boundary — show interstitial if not ad-free
        if Self.packBoundaries.contains(currentLevelNumber) && !adManager.isAdFree {
            showInterstitialThenAdvance(to: nextNumber, data: nextData)
        } else {
            performLevelTransition(to: nextNumber, data: nextData)
        }
    }

    private func showInterstitialThenAdvance(to nextNumber: Int, data: LevelData) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            performLevelTransition(to: nextNumber, data: data)
            return
        }
        adManager.showInterstitial(from: rootVC) { [self] _ in
            performLevelTransition(to: nextNumber, data: data)
        }
    }

    private func performLevelTransition(to nextNumber: Int, data: LevelData) {
        // Dismiss win card
        showWinCard = false
        winCardOffset = 600
        isWinningMove = false
        starScales = [0, 0, 0]

        // Update level tracking
        currentLevelNumber = nextNumber
        currentLevelData = data

        // Build new board
        let colors = Array(GameColor.allCases.prefix(data.colorCount))
        let newBoard = FloodBoard.generateBoard(size: data.gridSize, colors: colors, seed: data.seed)

        // Transition animation: scatter out old cells, then scale in new ones
        scene.transitionToNewBoard(newBoard) {
            gameState.reset(board: newBoard, totalMoves: data.moveBudget)
        }
    }

    private func resetGame() {
        showWinCard = false
        winCardOffset = 600
        showLoseCard = false
        loseCardOffset = 600
        isWinningMove = false
        starScales = [0, 0, 0]
        let colors = Array(GameColor.allCases.prefix(currentLevelData.colorCount))
        let board = FloodBoard.generateBoard(size: currentLevelData.gridSize, colors: colors, seed: currentLevelData.seed)
        gameState.reset(board: board, totalMoves: currentLevelData.moveBudget)
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
    GameView(levelNumber: 1)
}
