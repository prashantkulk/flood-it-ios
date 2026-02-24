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
    @State private var tallyMovesDisplay: Int? = nil
    @State private var isNewBest: Bool = false
    @State private var showSettings: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var hintColor: GameColor? = nil
    // BUG-11: Hint system — 3 per level, question mark icon, gold pulse
    @State private var hintsRemaining: Int = 3
    @State private var hintPulsing: Bool = false
    // BUG-12: Level intro splash
    @State private var showLevelIntro: Bool = true
    @State private var levelIntroOpacity: Double = 0
    // BUG-15: Timer for levels 10+
    @State private var timeRemaining: Int = 0
    @State private var timerBudget: Int = 0   // 0 = no timer
    @State private var timerActive: Bool = false
    @State private var timerPulse: Bool = false
    @State private var lostToTimer: Bool = false
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    /// Whether this is a daily challenge game.
    let isDailyChallenge: Bool
    /// The daily challenge date string (shown on screen).
    let dailyChallengeDate: String?
    @Environment(\.dismiss) private var dismiss

    init(levelNumber: Int = 1) {
        _currentLevelNumber = State(initialValue: levelNumber)
        let data = LevelStore.level(levelNumber) ?? LevelStore.levels[0]
        _currentLevelData = State(initialValue: data)
        let board = FloodBoard.generateBoard(from: data)
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
                    lightHaptic.prepare()
                    mediumHaptic.prepare()
                    heavyHaptic.prepare()
                    rigidHaptic.prepare()
                    warningHaptic.prepare()
                    scene.onTallyTick = {
                        DispatchQueue.main.async {
                            gameState.scoreState.applyTallyTick()
                            if let current = tallyMovesDisplay, current > 0 {
                                tallyMovesDisplay = current - 1
                            }
                        }
                    }
                    scene.onPerfectBonus = {
                        DispatchQueue.main.async {
                            gameState.scoreState.applyPerfectBonus()
                        }
                    }
                    scene.onWinAnimationComplete = {
                        DispatchQueue.main.async {
                            timerActive = false  // BUG-15: stop timer on win
                            tallyMovesDisplay = nil
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
                                isNewBest = ProgressStore.shared.updateScore(for: currentLevelNumber, score: gameState.scoreState.totalScore)
                                // BUG-8: Advance currentLevel pointer when level completed
                                ProgressStore.shared.updateCurrentLevel(currentLevelNumber + 1)
                            }
                            ProgressStore.shared.recordPlay()
                            for i in 0..<stars {
                                let delay = 0.5 + Double(i) * 0.3
                                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                        starScales[i] = 1.0
                                    }
                                    SoundManager.shared.playStarChime(noteIndex: i)
                                    // 3-star: trigger fireworks on the last star
                                    if stars == 3 && i == 2 {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                            scene.triggerFireworks()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    scene.onLoseAnimationComplete = {
                        DispatchQueue.main.async {
                            timerActive = false  // BUG-15: stop timer on lose
                            showLoseCard = true
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                loseCardOffset = 0
                            }
                        }
                    }
                    // MARK: P14-T10 Grid tap shortcut
                    scene.onGridTap = { color in
                        DispatchQueue.main.async {
                            tapColorButton(color)
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
                // BUG-9/BUG-12: HUD with dynamic safe area inset
                VStack(spacing: 0) {
                    // BUG-9: Daily challenge date header — full-width, clearly separated
                    if isDailyChallenge, let dateStr = dailyChallengeDate {
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 13, weight: .semibold))
                                Text(dateStr)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white.opacity(0.65))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                            Spacer()
                        }
                        .padding(.bottom, 6)
                    }

                    HStack(alignment: .center, spacing: 0) {
                        // Left: back + level number
                        HStack(spacing: 8) {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .accessibilityIdentifier("backButton")

                            if !isDailyChallenge {
                                Text("Lv. \(currentLevelNumber)")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.55))
                                    .accessibilityIdentifier("levelLabel")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Center: moves remaining + optional timer
                        VStack(spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(moveCounterColor.opacity(0.8))

                                Text("\(tallyMovesDisplay ?? gameState.movesRemaining)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded).monospacedDigit())
                                    .foregroundColor(tallyMovesDisplay != nil ? Color(red: 1.0, green: 0.84, blue: 0.0) : moveCounterColor)
                                    .opacity(gameState.movesRemaining <= 5 ? (moveCounterPulse ? 0.65 : 1.0) : 1.0)
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
                                        if newValue <= 2 {
                                            withAnimation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true)) {
                                                moveCounterPulse = true
                                            }
                                        } else if newValue <= 5 {
                                            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                                moveCounterPulse = true
                                            }
                                        } else {
                                            moveCounterPulse = false
                                        }
                                    }
                            }

                            // BUG-15: Timer row (only when timer is active for this level)
                            if timerBudget > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: timeRemaining <= 5 ? "timer" : "clock")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(timerColor)
                                    Text(timerText)
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(timerColor)
                                        .scaleEffect(timeRemaining <= 5 && timerPulse ? 1.15 : 1.0)
                                }
                                .accessibilityIdentifier("timerLabel")
                            }
                        }
                        .frame(maxWidth: .infinity)

                        // Right: score + hint + settings + restart
                        HStack(spacing: 12) {
                            // Score
                            Text("\(gameState.scoreState.totalScore)")
                                .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
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

                            // BUG-11: Hint button — question mark, gold pulse, count badge
                            if hintsRemaining > 0 {
                                Button(action: { showHint() }) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(systemName: "questionmark.circle.fill")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(hintColor != nil || hintPulsing
                                                ? Color(red: 1.0, green: 0.84, blue: 0.0)
                                                : .white.opacity(0.7))
                                            .shadow(color: hintPulsing ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8) : .clear, radius: 6)
                                        Text("\(hintsRemaining)")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(Color(red: 0.06, green: 0.06, blue: 0.12))
                                            .frame(width: 13, height: 13)
                                            .background(Circle().fill(Color(red: 1.0, green: 0.84, blue: 0.0)))
                                            .offset(x: 4, y: -4)
                                    }
                                }
                                .accessibilityIdentifier("hintButton")
                                .disabled(gameState.gameStatus != .playing)
                            }

                            Button(action: { showSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .accessibilityIdentifier("settingsButton")

                            Button(action: { resetGame() }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .accessibilityIdentifier("restartButton")
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)

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
                        .disabled(gameState.gameStatus != .playing || isWinningMove)
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

                        loseScoreSection

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
                    } else if nearMissPercentage >= 75 {
                        // MARK: P14-T14 Near-miss lose screen (75%+ completion)
                        Text("So Close!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        loseScoreSection

                        // Progress bar
                        VStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(height: 12)
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(red: 1.0, green: 0.84, blue: 0.0))
                                        .frame(width: geo.size.width * CGFloat(nearMissPercentage) / 100.0, height: 12)
                                }
                            }
                            .frame(height: 12)

                            Text("Board \(nearMissPercentage)% complete!")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))

                            Text("Just \(gameState.unfloodedCellCount) cell\(gameState.unfloodedCellCount == 1 ? "" : "s") left!")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }

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
                        Text(lostToTimer ? "Time's Up!" : "Out of Moves")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        loseScoreSection

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

                VStack(spacing: 16) {
                    Text("Solved!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))

                    // Hero: Final score in large gold text
                    Text("\(gameState.scoreState.totalScore)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), radius: 8, x: 0, y: 0)

                    // NEW BEST badge
                    if isNewBest && !isDailyChallenge {
                        Text("NEW BEST!")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.06, green: 0.06, blue: 0.12))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(red: 1.0, green: 0.84, blue: 0.0))
                            .clipShape(Capsule())
                            .offset(y: -6)
                    }

                    // Moves used / budget
                    HStack(spacing: 4) {
                        Text("\(gameState.movesMade)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("/ \(gameState.totalMoves) moves")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }

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

                    // Best score (for replays)
                    if !isDailyChallenge {
                        let best = ProgressStore.shared.bestScore(for: currentLevelNumber)
                        if best > 0 {
                            Text("Best: \(best)")
                                .font(.system(size: 13, weight: .medium, design: .rounded).monospacedDigit())
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }

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
                        } else if LevelStore.level(currentLevelNumber + 1) != nil {
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
                        } else {
                            // Final level — no next level available
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Done")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(red: 0.06, green: 0.06, blue: 0.12))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.white)
                                    .clipShape(Capsule())
                            }
                            .accessibilityIdentifier("doneButton")

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
                    .padding(.top, 4)
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

            // BUG-12: Level intro splash — "Level N / N moves"
            if showLevelIntro && !isDailyChallenge {
                levelIntroSplash
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSettings)
        .onAppear {
            if !isDailyChallenge {
                showLevelIntroAnimation()
            }
            setupTimer(forLevel: currentLevelNumber)
        }
        .onReceive(timerPublisher) { _ in
            guard timerActive, timerBudget > 0, gameState.gameStatus == .playing else { return }
            if timeRemaining > 1 {
                timeRemaining -= 1
                // Urgency pulse at ≤5s
                if timeRemaining <= 5 {
                    withAnimation(.easeInOut(duration: 0.2).repeatForever(autoreverses: true)) {
                        timerPulse = true
                    }
                }
            } else {
                timeRemaining = 0
                timerActive = false
                lostToTimer = true
                // Time's up — trigger loss
                gameState.triggerTimeLoss()
                SoundManager.shared.playLoseTone()
                scene.animateLose()
            }
        }
    }

    // MARK: - BUG-12 Level Intro Splash

    private var levelIntroSplash: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 10) {
                Text("Level \(currentLevelNumber)")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(currentLevelData.moveBudget) moves")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .opacity(levelIntroOpacity)
        }
        .allowsHitTesting(false)
    }

    private func showLevelIntroAnimation() {
        showLevelIntro = true
        levelIntroOpacity = 0
        withAnimation(.easeIn(duration: 0.3)) {
            levelIntroOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeOut(duration: 0.4)) {
                levelIntroOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showLevelIntro = false
            }
        }
    }

    // MARK: - BUG-15 Timer

    /// Returns the timer budget in seconds for the given level (0 = no timer).
    static func timerBudgetSeconds(forLevel level: Int, isDaily: Bool) -> Int {
        if isDaily { return 90 }
        if level < 10 { return 0 }
        if level <= 30 { return 120 }
        if level <= 60 { return 90 }
        if level <= 80 { return 75 }
        return 60
    }

    private func setupTimer(forLevel level: Int) {
        let budget = Self.timerBudgetSeconds(forLevel: level, isDaily: isDailyChallenge)
        timerBudget = budget
        if budget > 0 {
            timeRemaining = budget
            timerPulse = false
            // Start timer after the level intro splash disappears (~1.8s)
            DispatchQueue.main.asyncAfter(deadline: .now() + (isDailyChallenge ? 0 : 1.8)) {
                timerActive = true
            }
        } else {
            timerActive = false
        }
    }

    private func resetTimer() {
        timerActive = false
        timerPulse = false
        timeRemaining = timerBudget
        if timerBudget > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + (isDailyChallenge ? 0 : 1.8)) {
                timerActive = true
            }
        }
    }

    /// Colour for the timer display based on urgency.
    private var timerColor: Color {
        if timeRemaining <= 5 { return Color(red: 1.0, green: 0.2, blue: 0.15) }
        if timeRemaining <= 15 { return Color(red: 1.0, green: 0.6, blue: 0.1) }
        return Color.white.opacity(0.7)
    }

    /// Formatted MM:SS string.
    private var timerText: String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return m > 0 ? "\(m):\(String(format: "%02d", s))" : "\(s)"
    }

    /// Number of unflooded cells if ≤2 (for "Almost!" mechanic), 0 otherwise.
    private var almostCellCount: Int {
        let count = gameState.unfloodedCellCount
        return count <= 2 ? count : 0
    }

    /// Flood completion percentage rounded to integer (for near-miss lose screen).
    private var nearMissPercentage: Int {
        Int(gameState.floodCompletionPercentage * 100)
    }

    /// Score and completion percentage shown on lose cards.
    private var loseScoreSection: some View {
        VStack(spacing: 4) {
            Text("Score: \(gameState.scoreState.totalScore)")
                .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundColor(.white)
            Text("\(nearMissPercentage)% complete")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
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
            // Set up tally: after this move, movesRemaining will be decremented by 1
            let movesAfterWin = gameState.movesRemaining - 1
            scene.tallyTickCount = movesAfterWin
            tallyMovesDisplay = movesAfterWin
            // Perfect badge: optimal+1 or fewer (3 stars)
            let movesMadeAfterWin = gameState.movesMade + 1
            scene.showPerfectBadge = movesMadeAfterWin <= gameState.optimalMoves + 1
        }

        let prevCombo = gameState.comboCount
        let result = gameState.performFlood(color: color)

        // MARK: P14-T7 Tiered haptics based on cells absorbed
        let allWaves = result.waves + result.cascadeWaves
        let cellsAbsorbed = allWaves.flatMap { $0 }.count
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

        // Combo audio (matches score multiplier which activates at comboCount >= 2)
        if gameState.comboCount >= 2 {
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

        if allWaves.isEmpty {
            scene.updateColors(from: gameState.board)
        } else {
            scene.animateFlood(
                board: gameState.board,
                waves: allWaves,
                newColor: color,
                previousColors: result.previousColors,
                isWinningMove: willComplete,
                cascadeStartIndex: result.waves.count
            )
            // MARK: P14-T5/T6 Floating text
            if cellsAbsorbed > 0 {
                scene.spawnFloatingCellsText(waves: allWaves, cellsAbsorbed: cellsAbsorbed)
                let comboMult = gameState.comboCount >= 2 ? Double(gameState.comboCount) : 1.0
                scene.spawnFloatingPointsText(waves: allWaves, points: gameState.scoreState.lastMoveScore, multiplier: comboMult)
            }
            // MARK: P15-T6 Cascade text
            if result.cascadeCount >= 1 {
                let chainCount = result.cascadeCount + 1  // +1 because cascade count doesn't include the initial wave
                // Delay cascade text to appear when cascade animation starts
                let cascadeTextDelay = Double(result.waves.count) * 0.03 + 0.1
                scene.spawnCascadeText(chainCount: chainCount, delay: cascadeTextDelay)
            }
        }

        // Update combo visuals (matches score multiplier which activates at comboCount >= 2)
        if gameState.comboCount >= 2 {
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
        guard hintsRemaining > 0, gameState.gameStatus == .playing else { return }
        hintsRemaining -= 1

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
        // Highlight the hint color with gold pulse for 2s
        hintColor = bestColor
        hintPulsing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            hintColor = nil
            hintPulsing = false
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
        // Cancel any pending win/lose animations to prevent stale callbacks from firing
        scene.cancelLevelAnimations()

        // Dismiss win card
        showWinCard = false
        winCardOffset = 600
        isWinningMove = false
        starScales = [0, 0, 0]
        isNewBest = false
        tallyMovesDisplay = nil
        hintColor = nil
        scene.tallyTickCount = 0
        scene.showPerfectBadge = false

        // Update level tracking
        currentLevelNumber = nextNumber
        currentLevelData = data
        ProgressStore.shared.updateCurrentLevel(nextNumber)
        // Reset hints for new level
        hintsRemaining = 3
        lostToTimer = false
        // Reset timer for new level
        timerActive = false
        setupTimer(forLevel: nextNumber)

        // Build new board (must use generateBoard(from:) to preserve obstacles)
        let newBoard = FloodBoard.generateBoard(from: data)

        // Transition animation: scatter out old cells, then scale in new ones
        scene.transitionToNewBoard(newBoard) {
            gameState.reset(board: newBoard, totalMoves: data.moveBudget)
            // Show level intro after board appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                showLevelIntroAnimation()
            }
        }
    }

    private func resetGame() {
        showWinCard = false
        winCardOffset = 600
        showLoseCard = false
        loseCardOffset = 600
        isWinningMove = false
        starScales = [0, 0, 0]
        isNewBest = false
        tallyMovesDisplay = nil
        hintColor = nil
        hintsRemaining = 3
        lostToTimer = false
        scene.tallyTickCount = 0
        scene.showPerfectBadge = false
        resetTimer()
        let board = FloodBoard.generateBoard(from: currentLevelData)
        gameState.reset(board: board, totalMoves: currentLevelData.moveBudget)
        scene.configure(with: board)
        if !isDailyChallenge {
            showLevelIntroAnimation()
        }
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
