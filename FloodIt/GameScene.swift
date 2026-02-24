import SpriteKit
import UIKit

class GameScene: SKScene {
    private var cellNodes: [[FloodCellNode]] = []
    private var wallNodes: [SKShapeNode] = []
    private var board: FloodBoard?
    private let gridPadding: CGFloat = 16
    private var gridGap: CGFloat = 4

    // Dynamic background layers
    private var bgCurrent: SKSpriteNode?
    private var bgNext: SKSpriteNode?

    // Ambient particles
    private var particleEmitter: SKEmitterNode?

    // Camera for screen shake
    private var cameraNode = SKCameraNode()

    // Idle shimmer
    private var idleTimer: TimeInterval = 0
    private var lastInteractionTime: TimeInterval = 0
    private var isIdleShimmering: Bool = false
    private let idleDelay: TimeInterval = 7.0  // 5-10s range, use 7
    private let shimmerRepeatInterval: TimeInterval = 9.0  // 8-10s range
    private var lastShimmerTime: TimeInterval = 0

    func configure(with board: FloodBoard) {
        self.board = board
        if size.width > 0 {
            renderBoard()
        }
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)
        scaleMode = .resizeFill

        // Setup camera for screen shake
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cameraNode)
        camera = cameraNode

        setupDynamicBackground()
        setupParticles()
        if board != nil {
            renderBoard()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // MARK: P14-T13 Idle shimmer check
        if lastInteractionTime == 0 { lastInteractionTime = currentTime }
        let idleTime = currentTime - lastInteractionTime
        if idleTime >= idleDelay && !isAnimating {
            if lastShimmerTime == 0 || (currentTime - lastShimmerTime) >= shimmerRepeatInterval {
                triggerIdleShimmer()
                lastShimmerTime = currentTime
            }
        }
    }

    /// Reset the idle timer (called on any interaction).
    func resetIdleTimer() {
        lastInteractionTime = CACurrentMediaTime()
        lastShimmerTime = 0
    }

    /// Diagonal light sweep across the board.
    private func triggerIdleShimmer() {
        guard let board = board, !cellNodes.isEmpty else { return }
        let n = board.gridSize
        let shimmerDelay: TimeInterval = 0.015  // 15ms per diagonal

        for row in 0..<n {
            for col in 0..<n {
                guard row < cellNodes.count, col < cellNodes[row].count else { continue }
                let diag = row + col
                let node = cellNodes[row][col]
                let delay = Double(diag) * shimmerDelay

                let wait = SKAction.wait(forDuration: delay)
                let brighten = SKAction.fadeAlpha(to: 1.2, duration: 0.06)
                brighten.timingMode = .easeOut
                let restore = SKAction.fadeAlpha(to: 1.0, duration: 0.10)
                restore.timingMode = .easeIn
                node.run(SKAction.sequence([wait, brighten, restore]), withKey: "idleShimmer")
            }
        }
    }

    // MARK: - Dynamic Background

    private func setupDynamicBackground() {
        let bgA = SKSpriteNode(color: SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1), size: size)
        bgA.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bgA.zPosition = -10
        addChild(bgA)
        bgCurrent = bgA

        let bgB = SKSpriteNode(color: .clear, size: size)
        bgB.position = bgA.position
        bgB.zPosition = -9
        bgB.alpha = 0
        addChild(bgB)
        bgNext = bgB
    }

    func updateBackground(for color: GameColor?, animated: Bool = true) {
        guard let bgCurrent = bgCurrent, let bgNext = bgNext else { return }
        let tex = makeBackgroundTexture(for: color)
        bgNext.texture = tex
        bgNext.size = size
        bgNext.alpha = 0
        bgNext.removeAllActions()
        if animated {
            bgNext.run(SKAction.fadeIn(withDuration: 0.5)) {
                bgCurrent.texture = tex
                bgCurrent.size = self.size
                bgCurrent.alpha = 1
                bgNext.alpha = 0
                bgNext.texture = nil
            }
        } else {
            bgCurrent.texture = tex
            bgCurrent.size = size
            bgCurrent.alpha = 1
        }
    }

    private func makeBackgroundTexture(for color: GameColor?) -> SKTexture {
        let sz = size
        let img = UIGraphicsImageRenderer(size: sz).image { ctx in
            let cgCtx = ctx.cgContext
            let cs = CGColorSpaceCreateDeviceRGB()
            let bottomColor = UIColor(red: 0.03, green: 0.03, blue: 0.07, alpha: 1)
            let topColor: UIColor
            if let c = color {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
                c.uiDarkColor.getRed(&r, green: &g, blue: &b, alpha: nil)
                topColor = UIColor(red: min(1, r * 0.28 + 0.04),
                                   green: min(1, g * 0.28 + 0.03),
                                   blue: min(1, b * 0.28 + 0.08), alpha: 1)
            } else {
                topColor = UIColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)
            }
            let colors = [topColor.cgColor, bottomColor.cgColor] as CFArray
            let locs: [CGFloat] = [0, 1]
            if let g = CGGradient(colorsSpace: cs, colors: colors, locations: locs) {
                cgCtx.drawLinearGradient(g,
                    start: CGPoint(x: sz.width / 2, y: sz.height),
                    end: CGPoint(x: sz.width / 2, y: 0), options: [])
            }
        }
        return SKTexture(image: img)
    }

    // MARK: - Ambient Floating Particles

    private func setupParticles() {
        let e = SKEmitterNode()
        e.particleTexture = makeParticleTexture()
        e.particleBirthRate = 1.2
        e.particleLifetime = 8.0
        e.particleLifetimeRange = 3.0
        e.particlePositionRange = CGVector(dx: size.width * 0.9, dy: 0)
        e.position = CGPoint(x: size.width / 2, y: -5)
        e.emissionAngle = .pi / 2
        e.emissionAngleRange = .pi / 5
        e.particleSpeed = 28
        e.particleSpeedRange = 18
        e.particleScale = 0.35
        e.particleScaleRange = 0.25
        e.particleAlpha = 0.0
        e.particleAlphaSpeed = 0
        let alphaSeq = SKKeyframeSequence(
            keyframeValues: [Float(0.0), Float(0.30), Float(0.30), Float(0.0)],
            times: [0.0, 0.15, 0.85, 1.0]
        )
        e.particleAlphaSequence = alphaSeq
        e.particleColor = UIColor(red: 0.5, green: 0.65, blue: 1.0, alpha: 1.0)
        e.particleColorBlendFactor = 1.0
        e.particleBlendMode = .add
        e.zPosition = 5
        addChild(e)
        particleEmitter = e
    }

    private func makeParticleTexture() -> SKTexture {
        let radius: CGFloat = 4
        let sz = CGSize(width: radius * 2, height: radius * 2)
        let img = UIGraphicsImageRenderer(size: sz).image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: sz))
        }
        return SKTexture(image: img)
    }

    func updateParticleColor(for color: GameColor?) {
        guard let e = particleEmitter else { return }
        if let c = color {
            e.particleColor = c.uiLightColor
        } else {
            e.particleColor = UIColor(red: 0.5, green: 0.65, blue: 1.0, alpha: 1.0)
        }
    }

    // MARK: - Animation State

    private var isAnimating = false
    private var pendingFlood: (() -> Void)?

    /// Immediately finish any running flood animation.
    func snapAnimationToEnd() {
        guard isAnimating else { return }
        isAnimating = false
        removeAction(forKey: "floodCompletion")

        // Remove ripple rings, sparkles, and touch highlights
        children.filter { $0.name == "rippleRing" || $0.name == "sparkle" || $0.name == "touchRing" }.forEach { $0.removeFromParent() }
        highlightRing = nil
        highlightedCell = nil

        // Snap all cell nodes to final state
        guard let board = board else { return }
        let floodKeys = Set(board.floodRegion.map { "\($0.row),\($0.col)" })
        for row in 0..<board.gridSize {
            for col in 0..<board.gridSize {
                guard row < cellNodes.count, col < cellNodes[row].count else { continue }
                let node = cellNodes[row][col]
                node.removeAction(forKey: "floodAnim")
                node.removeCrossfadeOverlays()
                guard !node.isStone && !node.isVoid else { continue }
                let cell = board.cells[row][col]
                if node.gameColor != cell {
                    node.applyColor(cell)
                }
                node.alpha = 1.0
                node.setFlooded(floodKeys.contains("\(row),\(col)"))
            }
        }
    }

    // MARK: - Level Transition

    /// Transition to a new board: scatter/shrink out current cells (300ms), then scale in new cells (300ms).
    func transitionToNewBoard(_ newBoard: FloodBoard, onReset: @escaping () -> Void) {
        let scatterDuration: TimeInterval = 0.3
        let scaleInDuration: TimeInterval = 0.3

        // Phase 1: Scatter/shrink out current cells
        for row in cellNodes {
            for node in row {
                let randomDX = CGFloat.random(in: -60...60)
                let randomDY = CGFloat.random(in: -60...60)
                let scatter = SKAction.group([
                    SKAction.moveBy(x: randomDX, y: randomDY, duration: scatterDuration),
                    SKAction.scale(to: 0, duration: scatterDuration),
                    SKAction.fadeOut(withDuration: scatterDuration)
                ])
                scatter.timingMode = .easeIn
                node.run(scatter)
            }
        }

        // Phase 2: After scatter completes, configure new board and scale in
        run(SKAction.sequence([
            SKAction.wait(forDuration: scatterDuration),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                onReset()
                self.configure(with: newBoard)

                // Scale all new cells from 0 → 1
                for row in self.cellNodes {
                    for node in row {
                        let targetScale = node.xScale
                        node.setScale(0)
                        node.alpha = 0
                        let scaleIn = SKAction.scale(to: targetScale, duration: scaleInDuration)
                        scaleIn.timingMode = .easeOut
                        let fadeIn = SKAction.fadeIn(withDuration: scaleInDuration * 0.5)
                        let delay = SKAction.wait(forDuration: Double.random(in: 0...0.1))
                        node.run(SKAction.sequence([delay, SKAction.group([scaleIn, fadeIn])]))
                    }
                }
            }
        ]))
    }

    // MARK: - Board Rendering

    func updateColors(from board: FloodBoard) {
        self.board = board
        let floodKeys = Set(board.floodRegion.map { "\($0.row),\($0.col)" })
        for row in 0..<board.gridSize {
            for col in 0..<board.gridSize {
                guard row < cellNodes.count, col < cellNodes[row].count else { continue }
                let node = cellNodes[row][col]
                guard !node.isStone && !node.isVoid else { continue }
                let cell = board.cells[row][col]
                if node.gameColor != cell {
                    node.applyColor(cell)
                }
                node.setFlooded(floodKeys.contains("\(row),\(col)"))
            }
        }
        let floodColor = board.cells[0][0]
        updateBackground(for: floodColor)
        updateParticleColor(for: floodColor)
        updateObstacleOverlays(from: board)
    }

    /// Callback invoked after the winning animation sequence finishes (before overlays).
    var onWinAnimationComplete: (() -> Void)?

    /// Callback for grid tap shortcut: invoked with the tapped cell's color.
    var onGridTap: ((GameColor) -> Void)?

    /// Animate the flood with staggered waves. Flood region cells change instantly;
    /// absorbed cells animate wave-by-wave with pop + crossfade.
    func animateFlood(board: FloodBoard, waves: [[CellPosition]], newColor: GameColor, previousColors: [CellPosition: GameColor], isWinningMove: Bool = false, cascadeStartIndex: Int = 0, completion: (() -> Void)? = nil) {
        self.board = board
        resetIdleTimer()

        // If currently animating, snap to end first
        if isAnimating {
            snapAnimationToEnd()
        }

        // Instantly update the existing flood region cells (color change, no pop)
        let floodKeys = Set(board.floodRegion.map { "\($0.row),\($0.col)" })
        let absorbedSet = Set(waves.flatMap { $0 })
        for row in 0..<board.gridSize {
            for col in 0..<board.gridSize {
                guard row < cellNodes.count, col < cellNodes[row].count else { continue }
                let pos = CellPosition(row: row, col: col)
                let node = cellNodes[row][col]
                // Skip absorbed cells — they'll be animated
                if absorbedSet.contains(pos) { continue }
                let cell = board.cells[row][col]
                if node.gameColor != cell {
                    node.applyColor(cell)
                }
                node.setFlooded(floodKeys.contains("\(row),\(col)"))
            }
        }

        // Update background, particles, and obstacle overlays
        updateBackground(for: newColor)
        updateParticleColor(for: newColor)
        updateObstacleOverlays(from: board)

        guard !waves.isEmpty else {
            completion?()
            return
        }

        isAnimating = true

        if isWinningMove {
            animateWinningFlood(waves: waves, newColor: newColor, completion: completion)
            return
        }

        let waveDelay: TimeInterval = 0.03  // 30ms per wave
        let cascadePause: TimeInterval = 0.10  // 100ms pause before each cascade round

        // Ascending pitch scale: C4 through C5 for normal waves
        let wavePitches: [Double] = [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25]
        // Cascade pitches start higher (C5 upward)
        let cascadePitches: [Double] = [523.25, 587.33, 659.25, 698.46, 783.99, 880.00, 987.77, 1046.50]

        let perCellDuration: TimeInterval = 0.15

        // P14-T8: Scale ripple rings larger for big absorptions
        let precomputedTotal = waves.flatMap { $0 }.count
        let rippleScale: CGFloat = precomputedTotal >= 10 ? 6.0 : 4.0

        // Compute cumulative delay for each wave, adding cascade pauses
        var waveDelays = [TimeInterval]()
        var cumulativeDelay: TimeInterval = 0
        for waveIndex in 0..<waves.count {
            if waveIndex > 0 && waveIndex == cascadeStartIndex {
                // Add pause before first cascade wave
                cumulativeDelay += cascadePause
            } else if waveIndex > cascadeStartIndex && cascadeStartIndex > 0 {
                // Add pause between cascade rounds
                cumulativeDelay += cascadePause
            }
            waveDelays.append(cumulativeDelay)
            cumulativeDelay += waveDelay
        }

        let hasCascade = cascadeStartIndex > 0 && cascadeStartIndex < waves.count

        for (waveIndex, wave) in waves.enumerated() {
            let delay = waveDelays[waveIndex]
            let isCascadeWave = hasCascade && waveIndex >= cascadeStartIndex
            let cascadeRound = isCascadeWave ? waveIndex - cascadeStartIndex : 0

            // Play ascending pitch plip for this wave
            if isCascadeWave {
                let pitchIndex = min(cascadeRound, cascadePitches.count - 1)
                let pitch = cascadePitches[pitchIndex]
                let round = cascadeRound
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    SoundManager.shared.playPlip(frequency: pitch)
                    SoundManager.shared.playCascadeWhoosh(round: round)
                }
            } else {
                let pitchIndex = min(waveIndex, wavePitches.count - 1)
                let pitch = wavePitches[pitchIndex]
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    SoundManager.shared.playPlip(frequency: pitch)
                }
            }

            // Ripple ring — cascade rounds get bigger rings
            let cascadeRippleScale = isCascadeWave ? rippleScale * (1.0 + CGFloat(cascadeRound) * 0.3) : rippleScale
            spawnRippleRing(for: wave, delay: delay, color: newColor, expandScale: cascadeRippleScale)

            // Cascade rounds get escalating screen flash
            if isCascadeWave {
                let flashDelay = delay
                let flashAlpha: CGFloat = min(0.15 + CGFloat(cascadeRound) * 0.08, 0.4)
                DispatchQueue.main.asyncAfter(deadline: .now() + flashDelay) { [weak self] in
                    self?.spawnCascadeFlash(alpha: flashAlpha)
                }
            }

            for pos in wave {
                guard pos.row < cellNodes.count, pos.col < cellNodes[pos.row].count else { continue }
                let node = cellNodes[pos.row][pos.col]

                // Build the animation sequence for this cell
                let waitAction = SKAction.wait(forDuration: delay)

                // Pop: cascade waves get bigger overshoot
                let overshootScale: CGFloat = isCascadeWave ? 1.10 + CGFloat(cascadeRound) * 0.03 : 1.05
                let shrink = SKAction.scale(to: 0.85, duration: 0.04)
                shrink.timingMode = .easeIn
                let overshoot = SKAction.scale(to: overshootScale, duration: 0.08)
                overshoot.timingMode = .easeOut
                let settle = SKAction.scale(to: 1.0, duration: 0.06)
                settle.timingMode = .easeInEaseOut
                let popSequence = SKAction.sequence([shrink, overshoot, settle])

                // Brief brightness flash during pop — brighter for cascade
                let flashBrightness: CGFloat = isCascadeWave ? 0.6 : 0.8
                let flashUp = SKAction.fadeAlpha(to: flashBrightness, duration: 0.04)
                let flashDown = SKAction.fadeAlpha(to: 1.0, duration: 0.14)
                let flash = SKAction.sequence([flashUp, flashDown])

                // Color crossfade at pop moment (150ms blend)
                let colorChange = SKAction.run { [weak node] in
                    node?.crossfadeToColor(newColor, duration: 0.15)
                }

                // Combined: wait → (color change + pop + flash simultaneously)
                let animGroup = SKAction.group([popSequence, colorChange, flash])
                let fullSequence = SKAction.sequence([waitAction, animGroup])

                node.run(fullSequence, withKey: "floodAnim")
            }
        }

        // Large cluster particle burst: 5+ cells absorbed → sparkle burst
        let totalAbsorbed = waves.flatMap { $0 }.count
        if totalAbsorbed >= 5 {
            spawnParticleBurst(for: waves, color: newColor)
        }

        // Cascade gets extra particle bursts per round + bass swell for long chains
        if hasCascade {
            let cascadeCount = waves.count - cascadeStartIndex
            for cascadeIdx in 0..<cascadeCount {
                let cascadeWave = waves[cascadeStartIndex + cascadeIdx]
                let burstDelay = waveDelays[cascadeStartIndex + cascadeIdx]
                DispatchQueue.main.asyncAfter(deadline: .now() + burstDelay) { [weak self] in
                    guard let self = self else { return }
                    self.spawnParticleBurst(for: [cascadeWave], color: newColor)
                }
            }
            // Long chains (3+ cascade waves): crescendo bass swell
            if cascadeCount >= 3 {
                let bassDelay = waveDelays[cascadeStartIndex]
                DispatchQueue.main.asyncAfter(deadline: .now() + bassDelay) {
                    SoundManager.shared.playCascadeBassSwell()
                }
            }
        }

        // MARK: P14-T8/T9 Tiered particles + camera shake
        if totalAbsorbed >= 20 {
            spawnScreenFlash()
            cameraShake()
        }

        // Schedule completion after all waves finish
        let lastDelay = waveDelays.last ?? 0
        let totalDuration = lastDelay + perCellDuration + 0.05
        let completionAction = SKAction.sequence([
            SKAction.wait(forDuration: totalDuration),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.isAnimating = false
                // Ensure all absorbed cells are marked flooded
                for wave in waves {
                    for pos in wave {
                        guard pos.row < self.cellNodes.count, pos.col < self.cellNodes[pos.row].count else { continue }
                        self.cellNodes[pos.row][pos.col].setFlooded(true)
                    }
                }
                completion?()
            }
        ])
        run(completionAction, withKey: "floodCompletion")
    }

    // MARK: - Winning Flood Animation

    /// Dam-break winning animation: 500ms pause → dim to 60% → rapid BFS flood at 10ms per wave.
    private func animateWinningFlood(waves: [[CellPosition]], newColor: GameColor, completion: (() -> Void)?) {
        let pauseDuration: TimeInterval = 0.5
        let dimDuration: TimeInterval = 0.3
        let waveDelay: TimeInterval = 0.01  // 10ms per wave (rapid)

        // Phase 1: 500ms pause, then rumble + dim all cells to 60%
        let dimAction = SKAction.sequence([
            SKAction.wait(forDuration: pauseDuration),
            SKAction.run {
                SoundManager.shared.playDamBreakRumble()
            },
            SKAction.run { [weak self] in
                guard let self = self else { return }
                for row in self.cellNodes {
                    for node in row {
                        node.run(SKAction.fadeAlpha(to: 0.6, duration: dimDuration), withKey: "winDim")
                    }
                }
            },
            SKAction.wait(forDuration: dimDuration)
        ])

        // Phase 2: Rapid dam-break flood with plip torrent
        let damBreakAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            // Rapid-fire plip torrent (random pitches)
            let torrentDuration = Double(waves.count) * waveDelay + 0.1
            SoundManager.shared.playPlipTorrent(count: min(waves.count * 2, 20), over: torrentDuration)
            // Deep boom at end
            DispatchQueue.main.asyncAfter(deadline: .now() + torrentDuration) {
                SoundManager.shared.playDeepBoom()
            }
            for (waveIndex, wave) in waves.enumerated() {
                let delay = Double(waveIndex) * waveDelay
                for pos in wave {
                    guard pos.row < self.cellNodes.count, pos.col < self.cellNodes[pos.row].count else { continue }
                    let node = self.cellNodes[pos.row][pos.col]
                    let waitAction = SKAction.wait(forDuration: delay)
                    let colorChange = SKAction.run { [weak node] in
                        node?.crossfadeToColor(newColor, duration: 0.08)
                    }
                    let brighten = SKAction.fadeAlpha(to: 1.0, duration: 0.08)
                    let anim = SKAction.sequence([waitAction, SKAction.group([colorChange, brighten])])
                    node.run(anim, withKey: "floodAnim")
                }
            }
        }

        // Calculate total dam-break duration
        let totalWaves = waves.count
        let damBreakDuration = Double(totalWaves - 1) * waveDelay + 0.15

        let finishAction = SKAction.sequence([
            SKAction.wait(forDuration: damBreakDuration),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                // Mark all cells as flooded (stop breathing)
                for row in self.cellNodes {
                    for node in row {
                        node.removeAction(forKey: "breathe")
                        node.run(SKAction.scale(to: 1.0, duration: 0.05))
                    }
                }
                // Start completion rush sequence
                self.runCompletionRush {
                    self.isAnimating = false
                    self.onWinAnimationComplete?()
                    completion?()
                }
            }
        ])

        run(SKAction.sequence([dimAction, damBreakAction, finishAction]), withKey: "floodCompletion")
    }

    // MARK: - Completion Rush

    /// Runs the full completion rush sequence: pulse → shimmer → confetti.
    private func runCompletionRush(completion: @escaping () -> Void) {
        completionRushPulse { [weak self] in
            self?.completionRushShimmer {
                self?.completionRushConfetti()
                // Don't wait for confetti to finish — signal completion for overlay
                completion()
            }
        }
    }

    /// Phase 1: All cells scale to 1.15x then back to 1.0x over 400ms + chord swell.
    private func completionRushPulse(completion: @escaping () -> Void) {
        SoundManager.shared.playChordSwell()
        let scaleUp = SKAction.scale(to: 1.15, duration: 0.2)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        scaleDown.timingMode = .easeInEaseOut
        let pulse = SKAction.sequence([scaleUp, scaleDown])

        for row in cellNodes {
            for node in row {
                node.run(pulse, withKey: "winPulse")
            }
        }

        // Wait for pulse to finish, then call completion
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.run { completion() }
        ]), withKey: "rushPulse")
    }

    /// Phase 2: Light sweep + arpeggio sound.
    private func completionRushShimmer(completion: @escaping () -> Void) {
        SoundManager.shared.playArpeggio()
        guard let board = board else { completion(); return }
        let n = board.gridSize
        let shimmerDelay: TimeInterval = 0.015  // 15ms per diagonal

        // Group cells by diagonal index (row + col)
        var maxDiag = 0
        for row in 0..<n {
            for col in 0..<n {
                guard row < cellNodes.count, col < cellNodes[row].count else { continue }
                let diag = row + col
                if diag > maxDiag { maxDiag = diag }
                let node = cellNodes[row][col]
                let delay = Double(diag) * shimmerDelay

                let wait = SKAction.wait(forDuration: delay)
                let brighten = SKAction.fadeAlpha(to: 1.4, duration: 0.08)
                brighten.timingMode = .easeOut
                let restore = SKAction.fadeAlpha(to: 1.0, duration: 0.12)
                restore.timingMode = .easeIn
                let shimmer = SKAction.sequence([wait, brighten, restore])
                node.run(shimmer, withKey: "winShimmer")
            }
        }

        let totalDuration = Double(maxDiag) * shimmerDelay + 0.2 + 0.1
        run(SKAction.sequence([
            SKAction.wait(forDuration: totalDuration),
            SKAction.run { completion() }
        ]), withKey: "rushShimmer")
    }

    /// Phase 3: Confetti burst + sparkle sound.
    private func completionRushConfetti() {
        SoundManager.shared.playConfettiSparkle()
        let center = CGPoint(x: size.width / 2, y: size.height / 2 + 40)
        let count = Int.random(in: 60...80)
        let colors = GameColor.allCases

        for _ in 0..<count {
            let color = colors.randomElement()!
            let w = CGFloat.random(in: 4...8)
            let h = CGFloat.random(in: 6...12)
            let confetti = SKSpriteNode(color: color.skColor, size: CGSize(width: w, height: h))
            confetti.position = center
            confetti.zPosition = 10
            confetti.zRotation = CGFloat.random(in: 0...(2 * .pi))
            confetti.name = "confetti"
            addChild(confetti)

            // Initial velocity: shoot upward with horizontal spread
            let vx = CGFloat.random(in: -180...180)
            let vy = CGFloat.random(in: 200...450)
            let gravity: CGFloat = -400
            let lifetime: TimeInterval = 2.0
            let steps = 60
            let dt = lifetime / Double(steps)

            // Build path with gravity
            var actions = [SKAction]()
            let curVx = vx
            var curVy = vy
            for _ in 0..<steps {
                let dx = curVx * CGFloat(dt)
                let dy = curVy * CGFloat(dt)
                actions.append(SKAction.moveBy(x: dx, y: dy, duration: dt))
                curVy += gravity * CGFloat(dt)
                _ = curVx // horizontal stays constant
            }

            let moveSeq = SKAction.sequence(actions)
            let spin = SKAction.rotate(byAngle: CGFloat.random(in: -8...8), duration: lifetime)
            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: lifetime * 0.6),
                SKAction.fadeOut(withDuration: lifetime * 0.4)
            ])

            let group = SKAction.group([moveSeq, spin, fadeOut])
            confetti.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }
    }

    // MARK: - Lose Animation

    /// Callback invoked after the lose animation sequence finishes.
    var onLoseAnimationComplete: (() -> Void)?

    /// Lose animation: non-flooded cells fade to 40%, then board shakes.
    func animateLose() {
        guard let board = board else {
            onLoseAnimationComplete?()
            return
        }

        let floodRegion = board.floodRegion

        // Phase 1: Fade non-flooded cells to 40%
        for row in 0..<board.gridSize {
            for col in 0..<board.gridSize {
                guard row < cellNodes.count, col < cellNodes[row].count else { continue }
                let pos = CellPosition(row: row, col: col)
                if !floodRegion.contains(pos) {
                    cellNodes[row][col].run(SKAction.fadeAlpha(to: 0.4, duration: 0.3), withKey: "loseFade")
                }
            }
        }

        // Phase 2: Board shake after fade (3 cycles, 4px amplitude, 300ms total)
        let shakeCount = 3
        let shakeDuration: TimeInterval = 0.3 / Double(shakeCount * 2)
        let amplitude: CGFloat = 4
        var shakeActions = [SKAction]()
        for _ in 0..<shakeCount {
            shakeActions.append(SKAction.moveBy(x: amplitude, y: 0, duration: shakeDuration))
            shakeActions.append(SKAction.moveBy(x: -amplitude * 2, y: 0, duration: shakeDuration))
            shakeActions.append(SKAction.moveBy(x: amplitude, y: 0, duration: shakeDuration * 0.5))
        }
        let shakeSeq = SKAction.sequence(shakeActions)

        // Apply shake to all cell nodes via a container approach (move each node)
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),  // Wait for fade
            SKAction.run { [weak self] in
                guard let self = self else { return }
                for row in self.cellNodes {
                    for node in row {
                        node.run(shakeSeq, withKey: "loseShake")
                    }
                }
            },
            SKAction.wait(forDuration: 0.35),
            SKAction.run { [weak self] in
                self?.onLoseAnimationComplete?()
            }
        ]), withKey: "loseAnimation")
    }

    /// Pulse unflooded cells with a glow effect for the "Almost!" mechanic.
    func pulseUnfloodedCells() {
        guard let board = board else { return }
        let floodRegion = board.floodRegion
        for row in 0..<board.gridSize {
            for col in 0..<board.gridSize {
                guard row < cellNodes.count, col < cellNodes[row].count else { continue }
                let pos = CellPosition(row: row, col: col)
                if !floodRegion.contains(pos) {
                    let node = cellNodes[row][col]
                    // Restore alpha first
                    node.run(SKAction.fadeAlpha(to: 1.0, duration: 0.15))
                    // Pulsing scale
                    let up = SKAction.scale(to: 1.2, duration: 0.4)
                    up.timingMode = .easeInEaseOut
                    let down = SKAction.scale(to: 0.9, duration: 0.4)
                    down.timingMode = .easeInEaseOut
                    node.run(SKAction.repeatForever(SKAction.sequence([up, down])), withKey: "almostPulse")
                }
            }
        }
    }

    /// Stop pulsing unflooded cells.
    func stopPulseUnfloodedCells() {
        guard let board = board else { return }
        for row in 0..<board.gridSize {
            for col in 0..<board.gridSize {
                guard row < cellNodes.count, col < cellNodes[row].count else { continue }
                cellNodes[row][col].removeAction(forKey: "almostPulse")
                cellNodes[row][col].run(SKAction.scale(to: 1.0, duration: 0.15))
            }
        }
    }

    // MARK: - Ripple Ring Effect

    private func spawnRippleRing(for wave: [CellPosition], delay: TimeInterval, color: GameColor, expandScale: CGFloat = 4.0) {
        guard !wave.isEmpty else { return }

        // Calculate centroid of this wave's cells
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        var count: CGFloat = 0
        for pos in wave {
            guard pos.row < cellNodes.count, pos.col < cellNodes[pos.row].count else { continue }
            let node = cellNodes[pos.row][pos.col]
            sumX += node.position.x
            sumY += node.position.y
            count += 1
        }
        guard count > 0 else { return }
        let centroid = CGPoint(x: sumX / count, y: sumY / count)

        // Create ring shape
        let initialRadius: CGFloat = 8
        let ring = SKShapeNode(circleOfRadius: initialRadius)
        ring.strokeColor = color.skColor.withAlphaComponent(0.5)
        ring.fillColor = .clear
        ring.lineWidth = 2.0
        ring.position = centroid
        ring.zPosition = 4
        ring.alpha = 0.6
        ring.setScale(1.0)
        ring.name = "rippleRing"
        addChild(ring)

        // Animate: wait → expand + fade out → remove
        let wait = SKAction.wait(forDuration: delay)
        let expand = SKAction.scale(to: expandScale, duration: 0.35)
        expand.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.35)
        let animGroup = SKAction.group([expand, fadeOut])
        let sequence = SKAction.sequence([wait, animGroup, SKAction.removeFromParent()])
        ring.run(sequence)
    }

    // MARK: - Particle Burst Effect

    private func spawnParticleBurst(for waves: [[CellPosition]], color: GameColor) {
        // Calculate centroid of ALL absorbed cells
        let allCells = waves.flatMap { $0 }
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        var count: CGFloat = 0
        for pos in allCells {
            guard pos.row < cellNodes.count, pos.col < cellNodes[pos.row].count else { continue }
            let node = cellNodes[pos.row][pos.col]
            sumX += node.position.x
            sumY += node.position.y
            count += 1
        }
        guard count > 0 else { return }
        let centroid = CGPoint(x: sumX / count, y: sumY / count)

        // Spawn 8-12 sparkle dots
        let particleCount = Int.random(in: 8...12)
        let sparkleColor = color.uiLightColor

        // Delay burst until midway through animation
        let burstDelay = Double(waves.count / 2) * 0.03

        for _ in 0..<particleCount {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            dot.fillColor = sparkleColor
            dot.strokeColor = .clear
            dot.position = centroid
            dot.zPosition = 6
            dot.alpha = 0
            dot.blendMode = .add
            dot.name = "sparkle"
            addChild(dot)

            // Random direction and distance
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...80)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let wait = SKAction.wait(forDuration: burstDelay)
            let fadeIn = SKAction.fadeAlpha(to: CGFloat.random(in: 0.6...1.0), duration: 0.05)
            let move = SKAction.moveBy(x: dx, y: dy, duration: CGFloat.random(in: 0.3...0.5))
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let shrink = SKAction.scale(to: 0.2, duration: 0.3)

            let anim = SKAction.sequence([
                wait,
                fadeIn,
                SKAction.group([move, SKAction.sequence([SKAction.wait(forDuration: 0.15), fadeOut]), shrink]),
                SKAction.removeFromParent()
            ])
            dot.run(anim)
        }
    }

    // MARK: - Floating Score Text

    /// Spawn floating '+N' text at the centroid of absorbed cells.
    func spawnFloatingCellsText(waves: [[CellPosition]], cellsAbsorbed: Int) {
        guard cellsAbsorbed > 0 else { return }
        let allCells = waves.flatMap { $0 }
        guard let centroid = centroidOf(positions: allCells) else { return }

        let label = SKLabelNode(text: "+\(cellsAbsorbed)")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 18
        label.fontColor = .white
        label.position = centroid
        label.zPosition = 12
        label.alpha = 0
        label.name = "floatingText"
        addChild(label)

        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        let moveUp = SKAction.moveBy(x: 0, y: 40, duration: 0.8)
        moveUp.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let anim = SKAction.sequence([
            fadeIn,
            SKAction.group([moveUp, SKAction.sequence([SKAction.wait(forDuration: 0.5), fadeOut])]),
            SKAction.removeFromParent()
        ])
        label.run(anim)
    }

    /// Spawn floating '+X pts' text in gold, 0.15s after cells text.
    func spawnFloatingPointsText(waves: [[CellPosition]], points: Int, multiplier: Double) {
        guard points > 0 else { return }
        let allCells = waves.flatMap { $0 }
        guard let centroid = centroidOf(positions: allCells) else { return }

        let label = SKLabelNode(text: "+\(points) pts")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = multiplier >= 1.5 ? 22 : 16
        label.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        label.position = CGPoint(x: centroid.x, y: centroid.y - 16)
        label.zPosition = 12
        label.alpha = 0
        label.name = "floatingText"
        addChild(label)

        let delay = SKAction.wait(forDuration: 0.15)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        let moveUp = SKAction.moveBy(x: 0, y: 60, duration: 1.0)
        moveUp.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        var actions: [SKAction] = [delay, fadeIn]

        // Gold particle burst for high multiplier
        if multiplier >= 1.5 {
            let burstAction = SKAction.run { [weak self, weak label] in
                guard let self = self, let pos = label?.position else { return }
                self.spawnGoldBurst(at: pos)
            }
            actions.append(burstAction)
        }

        actions.append(SKAction.group([moveUp, SKAction.sequence([SKAction.wait(forDuration: 0.7), fadeOut])]))
        actions.append(SKAction.removeFromParent())
        label.run(SKAction.sequence(actions))
    }

    private func spawnGoldBurst(at position: CGPoint) {
        for _ in 0..<6 {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.0))
            dot.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            dot.strokeColor = .clear
            dot.position = position
            dot.zPosition = 11
            dot.alpha = 0.8
            dot.blendMode = .add
            dot.name = "goldBurst"
            addChild(dot)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 10...25)
            let move = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.3)
            move.timingMode = .easeOut
            dot.run(SKAction.sequence([
                SKAction.group([move, SKAction.fadeOut(withDuration: 0.3)]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Cascade Text

    /// Spawn floating golden 'CASCADE xN!' text at the center of the board.
    func spawnCascadeText(chainCount: Int, delay: TimeInterval = 0) {
        guard chainCount >= 2 else { return }
        let text = "CASCADE x\(chainCount)!"
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 32
        label.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        label.position = CGPoint(x: size.width / 2, y: size.height / 2 + 40)
        label.zPosition = 20
        label.alpha = 0
        label.setScale(0.5)
        label.name = "cascadeText"
        addChild(label)

        let waitAction = SKAction.wait(forDuration: delay)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.12)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.12)
        scaleUp.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.08)
        settle.timingMode = .easeInEaseOut
        let hold = SKAction.wait(forDuration: 0.8)
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.5)
        moveUp.timingMode = .easeIn
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)

        let burstAction = SKAction.run { [weak self, weak label] in
            guard let self = self, let pos = label?.position else { return }
            self.spawnGoldenCascadeBurst(at: pos, intensity: chainCount)
        }

        let anim = SKAction.sequence([
            waitAction,
            SKAction.group([fadeIn, scaleUp]),
            settle,
            burstAction,
            hold,
            SKAction.group([moveUp, fadeOut]),
            SKAction.removeFromParent()
        ])
        label.run(anim)
    }

    /// Golden particle burst behind cascade text.
    private func spawnGoldenCascadeBurst(at position: CGPoint, intensity: Int) {
        let count = min(8 + intensity * 4, 24)
        for _ in 0..<count {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            dot.fillColor = SKColor(red: 1.0, green: CGFloat.random(in: 0.7...0.9), blue: 0.0, alpha: 1.0)
            dot.strokeColor = .clear
            dot.position = position
            dot.zPosition = 19
            dot.alpha = 0.9
            dot.blendMode = .add
            dot.name = "cascadeBurst"
            addChild(dot)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 20...60)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let move = SKAction.moveBy(x: dx, y: dy, duration: CGFloat.random(in: 0.3...0.6))
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let shrink = SKAction.scale(to: 0.2, duration: 0.4)

            dot.run(SKAction.sequence([
                SKAction.group([move, SKAction.sequence([SKAction.wait(forDuration: 0.2), fadeOut]), shrink]),
                SKAction.removeFromParent()
            ]))
        }
    }

    /// Camera shake for large absorptions (20+ cells).
    /// Random offset 2-3px, dampened over 0.15s (3-4 oscillations).
    func cameraShake() {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let oscillations = 4
        let totalDuration: TimeInterval = 0.15
        let stepDuration = totalDuration / Double(oscillations * 2)

        var actions = [SKAction]()
        for i in 0..<oscillations {
            let damping = 1.0 - Double(i) / Double(oscillations)
            let amplitude = CGFloat(damping * Double.random(in: 2...3))
            let dx = CGFloat.random(in: -1...1) * amplitude
            let dy = CGFloat.random(in: -1...1) * amplitude
            actions.append(SKAction.move(to: CGPoint(x: center.x + dx, y: center.y + dy), duration: stepDuration))
            actions.append(SKAction.move(to: CGPoint(x: center.x - dx * 0.5, y: center.y - dy * 0.5), duration: stepDuration))
        }
        actions.append(SKAction.move(to: center, duration: stepDuration * 0.5))
        cameraNode.run(SKAction.sequence(actions), withKey: "cameraShake")
    }

    /// Cascade-specific flash with configurable intensity.
    private func spawnCascadeFlash(alpha: CGFloat) {
        let flash = SKSpriteNode(color: SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0), size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 15
        flash.alpha = alpha
        flash.name = "cascadeFlash"
        addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
    }

    /// Full-screen white flash for 20+ cell absorptions.
    private func spawnScreenFlash() {
        let flash = SKSpriteNode(color: .white, size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 15
        flash.alpha = 0.15
        flash.name = "screenFlash"
        addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
    }

    /// Calculate centroid of cell positions in scene coordinates.
    private func centroidOf(positions: [CellPosition]) -> CGPoint? {
        guard !positions.isEmpty else { return nil }
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        var count: CGFloat = 0
        for pos in positions {
            guard pos.row < cellNodes.count, pos.col < cellNodes[pos.row].count else { continue }
            let node = cellNodes[pos.row][pos.col]
            sumX += node.position.x
            sumY += node.position.y
            count += 1
        }
        guard count > 0 else { return nil }
        return CGPoint(x: sumX / count, y: sumY / count)
    }

    // MARK: - Combo Glow

    private var comboGlowNodes: [SKShapeNode] = []

    /// Show or update a pulsing golden glow on flood region boundary cells.
    func showComboGlow(board: FloodBoard, intensity: Int) {
        removeComboGlow()
        guard intensity > 0 else { return }

        let region = board.floodRegion
        // Find boundary cells: flood region cells adjacent to non-region cells
        var boundaryCells = Set<CellPosition>()
        for pos in region {
            let dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)]
            for (dr, dc) in dirs {
                let nr = pos.row + dr
                let nc = pos.col + dc
                guard nr >= 0, nr < board.gridSize, nc >= 0, nc < board.gridSize else { continue }
                let neighbor = CellPosition(row: nr, col: nc)
                if !region.contains(neighbor) {
                    boundaryCells.insert(pos)
                    break
                }
            }
        }

        let glowAlpha: CGFloat = intensity >= 2 ? 0.6 : 0.4
        let glowScale: CGFloat = intensity >= 2 ? 1.6 : 1.4

        for pos in boundaryCells {
            guard pos.row < cellNodes.count, pos.col < cellNodes[pos.row].count else { continue }
            let cellNode = cellNodes[pos.row][pos.col]

            let n = board.gridSize
            let sceneW = size.width
            let available = sceneW - gridPadding * 2
            let cellSize = (available - CGFloat(n - 1) * gridGap) / CGFloat(n)

            let glow = SKShapeNode(circleOfRadius: cellSize / 2 * glowScale)
            glow.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            glow.strokeColor = .clear
            glow.alpha = glowAlpha
            glow.position = cellNode.position
            glow.zPosition = -0.5
            glow.blendMode = .add
            glow.name = "comboGlow"
            addChild(glow)
            comboGlowNodes.append(glow)

            // Pulsing animation
            let pulseUp = SKAction.fadeAlpha(to: glowAlpha, duration: 0.5)
            pulseUp.timingMode = .easeInEaseOut
            let pulseDown = SKAction.fadeAlpha(to: glowAlpha * 0.4, duration: 0.5)
            pulseDown.timingMode = .easeInEaseOut
            glow.run(SKAction.repeatForever(SKAction.sequence([pulseDown, pulseUp])), withKey: "comboPulse")
        }
    }

    /// Remove all combo glow nodes.
    func removeComboGlow() {
        for node in comboGlowNodes {
            node.removeFromParent()
        }
        comboGlowNodes.removeAll()
    }

    /// Increase brightness of all cells by 10% for combo x4+.
    func applyComboSaturation() {
        for row in cellNodes {
            for node in row {
                node.run(SKAction.colorize(with: .white, colorBlendFactor: 0.1, duration: 0.15), withKey: "comboSat")
            }
        }
    }

    /// Remove combo saturation boost.
    func removeComboSaturation() {
        for row in cellNodes {
            for node in row {
                node.removeAction(forKey: "comboSat")
                node.run(SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.15), withKey: "comboSatRemove")
            }
        }
    }

    /// Subtle screen shake: 2px amplitude, 100ms total.
    func comboScreenShake() {
        let amplitude: CGFloat = 2
        let shakeDur: TimeInterval = 0.025
        var actions = [SKAction]()
        for _ in 0..<2 {
            actions.append(SKAction.moveBy(x: amplitude, y: 0, duration: shakeDur))
            actions.append(SKAction.moveBy(x: -amplitude * 2, y: 0, duration: shakeDur))
            actions.append(SKAction.moveBy(x: amplitude, y: 0, duration: shakeDur * 0.5))
        }
        let shakeSeq = SKAction.sequence(actions)
        for row in cellNodes {
            for node in row {
                node.run(shakeSeq, withKey: "comboShake")
            }
        }
    }

    /// Spawn spark particles along the flood boundary for combo x3+.
    func spawnComboSparks(board: FloodBoard) {
        let region = board.floodRegion
        var boundaryCells = [CellPosition]()
        for pos in region {
            let dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)]
            for (dr, dc) in dirs {
                let nr = pos.row + dr
                let nc = pos.col + dc
                guard nr >= 0, nr < board.gridSize, nc >= 0, nc < board.gridSize else { continue }
                if !region.contains(CellPosition(row: nr, col: nc)) {
                    boundaryCells.append(pos)
                    break
                }
            }
        }

        // Spawn 2-3 sparks per boundary cell (capped at 30 total)
        let sparkCount = min(boundaryCells.count * 2, 30)
        let selectedCells = boundaryCells.shuffled().prefix(sparkCount)

        for pos in selectedCells {
            guard pos.row < cellNodes.count, pos.col < cellNodes[pos.row].count else { continue }
            let cellNode = cellNodes[pos.row][pos.col]

            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.0))
            let isGolden = Bool.random()
            spark.fillColor = isGolden
                ? SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
                : SKColor.white
            spark.strokeColor = .clear
            spark.position = cellNode.position
            spark.zPosition = 8
            spark.alpha = 0
            spark.blendMode = .add
            spark.name = "comboSpark"
            addChild(spark)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 15...40)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let fadeIn = SKAction.fadeAlpha(to: CGFloat.random(in: 0.7...1.0), duration: 0.05)
            let move = SKAction.moveBy(x: dx, y: dy, duration: CGFloat.random(in: 0.3...0.6))
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let shrink = SKAction.scale(to: 0.1, duration: 0.4)

            let delay = SKAction.wait(forDuration: Double.random(in: 0...0.15))
            let anim = SKAction.sequence([
                delay,
                fadeIn,
                SKAction.group([move, SKAction.sequence([SKAction.wait(forDuration: 0.2), fadeOut]), shrink]),
                SKAction.removeFromParent()
            ])
            spark.run(anim)
        }
    }

    /// Fade out combo glow over a duration, then remove.
    func fadeOutComboGlow(duration: TimeInterval = 0.3) {
        let nodes = comboGlowNodes
        comboGlowNodes.removeAll()
        for node in nodes {
            node.removeAllActions()
            node.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: duration),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Touch Highlighting

    private var highlightedCell: (row: Int, col: Int)?
    private var highlightRing: SKShapeNode?
    private var ghostOverlays: [SKSpriteNode] = []

    private func cellAt(point: CGPoint) -> (row: Int, col: Int)? {
        guard let board = board, !cellNodes.isEmpty else { return nil }
        let n = board.gridSize
        let sceneW = size.width
        let available = sceneW - gridPadding * 2
        let cellSize = (available - CGFloat(n - 1) * gridGap) / CGFloat(n)
        let gridWidth = CGFloat(n) * cellSize + CGFloat(n - 1) * gridGap
        let gridHeight = CGFloat(n) * cellSize + CGFloat(n - 1) * gridGap
        let originX = (sceneW - gridWidth) / 2
        let originY = (size.height - gridHeight) / 2 + 40

        for row in 0..<n {
            for col in 0..<n {
                let x = originX + CGFloat(col) * (cellSize + gridGap) + cellSize / 2
                let y = originY + CGFloat(n - 1 - row) * (cellSize + gridGap) + cellSize / 2
                let halfSize = (cellSize + gridGap) / 2
                if abs(point.x - x) <= halfSize && abs(point.y - y) <= halfSize {
                    return (row, col)
                }
            }
        }
        return nil
    }

    private func applyHighlight(row: Int, col: Int) {
        guard row < cellNodes.count, col < cellNodes[row].count else { return }
        guard let board = board else { return }
        let n = board.gridSize

        // Remove previous highlights
        removeHighlight()

        highlightedCell = (row, col)
        let node = cellNodes[row][col]

        // Brighten touched cell (+15% brightness via colorize)
        let brighten = SKAction.run { node.alpha = 1.15 }
        node.run(brighten, withKey: "touchHighlight")

        // Pulsing white ring
        let sceneW = size.width
        let available = sceneW - gridPadding * 2
        let cellSize = (available - CGFloat(n - 1) * gridGap) / CGFloat(n)
        let ringRadius = cellSize / 2 + 2
        let ring = SKShapeNode(circleOfRadius: ringRadius)
        ring.strokeColor = UIColor.white.withAlphaComponent(0.6)
        ring.fillColor = .clear
        ring.lineWidth = 1.5
        ring.position = node.position
        ring.zPosition = 7
        ring.name = "touchRing"

        let pulseUp = SKAction.fadeAlpha(to: 0.8, duration: 0.4)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.fadeAlpha(to: 0.3, duration: 0.4)
        pulseDown.timingMode = .easeInEaseOut
        ring.run(SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown])))
        addChild(ring)
        highlightRing = ring

        // Dim adjacent cells to 85%
        let adjacentOffsets = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        for (dr, dc) in adjacentOffsets {
            let ar = row + dr
            let ac = col + dc
            guard ar >= 0 && ar < n && ac >= 0 && ac < n else { continue }
            guard ar < cellNodes.count, ac < cellNodes[ar].count else { continue }
            let adjNode = cellNodes[ar][ac]
            adjNode.run(SKAction.fadeAlpha(to: 0.85, duration: 0.08), withKey: "touchDim")
        }
    }

    private func removeHighlight() {
        guard let board = board else { return }
        let n = board.gridSize

        if let prev = highlightedCell {
            // Restore touched cell
            if prev.row < cellNodes.count, prev.col < cellNodes[prev.row].count {
                cellNodes[prev.row][prev.col].run(SKAction.fadeAlpha(to: 1.0, duration: 0.08), withKey: "touchHighlight")
            }
            // Restore adjacent cells
            let adjacentOffsets = [(-1, 0), (1, 0), (0, -1), (0, 1)]
            for (dr, dc) in adjacentOffsets {
                let ar = prev.row + dr
                let ac = prev.col + dc
                guard ar >= 0 && ar < n && ac >= 0 && ac < n else { continue }
                guard ar < cellNodes.count, ac < cellNodes[ar].count else { continue }
                cellNodes[ar][ac].run(SKAction.fadeAlpha(to: 1.0, duration: 0.08), withKey: "touchDim")
            }
        }

        highlightRing?.removeFromParent()
        highlightRing = nil
        highlightedCell = nil
        removeGhostOverlays()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetIdleTimer()
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        if let cell = cellAt(point: point) {
            applyHighlight(row: cell.row, col: cell.col)
            showGhostPreview(row: cell.row, col: cell.col)
        }
    }

    // MARK: P14-T11 Ghost Preview

    private func showGhostPreview(row: Int, col: Int) {
        removeGhostOverlays()
        guard let board = board else { return }
        let tappedColor = board.cells[row][col]
        let currentColor = board.cells[0][0]

        // Same color as flood region → small shake
        if tappedColor == currentColor {
            let shakeR = SKAction.moveBy(x: 2, y: 0, duration: 0.03)
            let shakeL = SKAction.moveBy(x: -4, y: 0, duration: 0.03)
            let shakeBack = SKAction.moveBy(x: 2, y: 0, duration: 0.03)
            let shake = SKAction.sequence([shakeR, shakeL, shakeBack])
            if row < cellNodes.count, col < cellNodes[row].count {
                cellNodes[row][col].run(shake, withKey: "ghostShake")
            }
            return
        }

        // Show preview overlay on cells that would be absorbed
        let waves = board.cellsAbsorbedBy(color: tappedColor)
        let allAbsorbed = waves.flatMap { $0 }
        let n = board.gridSize
        let sceneW = size.width
        let available = sceneW - gridPadding * 2
        let cellSize = (available - CGFloat(n - 1) * gridGap) / CGFloat(n)

        for pos in allAbsorbed {
            guard pos.row < cellNodes.count, pos.col < cellNodes[pos.row].count else { continue }
            let cellNode = cellNodes[pos.row][pos.col]
            let overlay = SKSpriteNode(color: .white, size: CGSize(width: cellSize, height: cellSize))
            overlay.alpha = 0.3
            overlay.position = cellNode.position
            overlay.zPosition = 9
            overlay.name = "ghostOverlay"
            addChild(overlay)
            ghostOverlays.append(overlay)

            // Fade in quickly, then fade out after 150ms
            overlay.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.15),
                SKAction.fadeOut(withDuration: 0.1),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func removeGhostOverlays() {
        for overlay in ghostOverlays {
            overlay.removeFromParent()
        }
        ghostOverlays.removeAll()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        let cell = cellAt(point: point)
        if cell?.row != highlightedCell?.row || cell?.col != highlightedCell?.col {
            removeHighlight()
            if let cell = cell {
                applyHighlight(row: cell.row, col: cell.col)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { removeHighlight(); return }
        let point = touch.location(in: self)
        if let cell = cellAt(point: point), let board = board {
            let tappedColor = board.cells[cell.row][cell.col]
            removeHighlight()
            onGridTap?(tappedColor)
        } else {
            removeHighlight()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        removeHighlight()
    }

    // MARK: - Obstacle Overlay Updates

    /// Update obstacle overlays (ice layers, countdown numbers, etc.) based on board state.
    func updateObstacleOverlays(from board: FloodBoard) {
        let floodRegion = board.floodRegion
        for row in 0..<board.gridSize {
            for col in 0..<board.gridSize {
                guard row < cellNodes.count, col < cellNodes[row].count else { continue }
                let node = cellNodes[row][col]
                let type = board.cellType(atRow: row, col: col)

                // Ice layer updates
                switch type {
                case .ice(let layers):
                    if node.iceLayers != layers {
                        node.updateIceLayers(layers)
                    }
                case .countdown(let movesLeft):
                    if node.countdownValue != movesLeft {
                        node.updateCountdown(movesLeft)
                    }
                default:
                    // Cell was ice but is now normal (fully cracked)
                    if node.iceLayers > 0 {
                        node.updateIceLayers(0)
                    }
                    // Cell was countdown — check if defused or exploded
                    if node.countdownValue > 0 {
                        let pos = CellPosition(row: row, col: col)
                        if floodRegion.contains(pos) {
                            // Defused — absorbed into flood region
                            node.removeCountdownLabel()
                            spawnDefusedText(at: node.position)
                            SoundManager.shared.playDefuseChime()
                        } else {
                            // Exploded — countdown reached 0
                            node.removeCountdownLabel()
                            playCountdownExplosion(at: CellPosition(row: row, col: col))
                        }
                    }
                }
            }
        }
    }

    /// Green "Defused!" text floating upward from the cell.
    private func spawnDefusedText(at position: CGPoint) {
        let label = SKLabelNode(text: "Defused!")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 14
        label.fontColor = SKColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 1.0)
        label.position = position
        label.zPosition = 12
        label.alpha = 0
        label.name = "defusedText"
        addChild(label)

        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        let moveUp = SKAction.moveBy(x: 0, y: 40, duration: 0.8)
        moveUp.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        label.run(SKAction.sequence([
            fadeIn,
            SKAction.group([moveUp, SKAction.sequence([SKAction.wait(forDuration: 0.5), fadeOut])]),
            SKAction.removeFromParent()
        ]))
    }

    /// Red flash + 3x3 jitter for countdown explosion.
    private func playCountdownExplosion(at pos: CellPosition) {
        guard let board = board, pos.row < cellNodes.count, pos.col < cellNodes[pos.row].count else { return }
        let centerNode = cellNodes[pos.row][pos.col]

        // Red flash on the cell
        let flash = SKSpriteNode(color: .red, size: CGSize(width: centerNode.cellSize, height: centerNode.cellSize))
        flash.position = centerNode.position
        flash.zPosition = 10
        flash.alpha = 0.6
        flash.name = "explosionFlash"
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))

        // Jitter 3x3 area
        for dr in -1...1 {
            for dc in -1...1 {
                let r = pos.row + dr
                let c = pos.col + dc
                guard r >= 0, r < board.gridSize, c >= 0, c < board.gridSize else { continue }
                guard r < cellNodes.count, c < cellNodes[r].count else { continue }
                let node = cellNodes[r][c]
                let origPos = node.position
                let jitter = SKAction.sequence([
                    SKAction.move(to: CGPoint(x: origPos.x + CGFloat.random(in: -3...3),
                                              y: origPos.y + CGFloat.random(in: -3...3)), duration: 0.04),
                    SKAction.move(to: CGPoint(x: origPos.x + CGFloat.random(in: -3...3),
                                              y: origPos.y + CGFloat.random(in: -3...3)), duration: 0.04),
                    SKAction.move(to: origPos, duration: 0.04)
                ])
                node.run(jitter, withKey: "explosionJitter")
            }
        }

        SoundManager.shared.playCountdownExplosion()
    }

    private func renderBoard() {
        guard let board = board else { return }
        for row in cellNodes { for node in row { node.removeFromParent() } }
        cellNodes.removeAll()

        let n = board.gridSize
        let sceneW = size.width
        let available = sceneW - gridPadding * 2
        let cellSize = (available - CGFloat(n - 1) * gridGap) / CGFloat(n)
        let gridWidth = CGFloat(n) * cellSize + CGFloat(n - 1) * gridGap
        let gridHeight = CGFloat(n) * cellSize + CGFloat(n - 1) * gridGap
        let originX = (sceneW - gridWidth) / 2
        let originY = (size.height - gridHeight) / 2 + 40

        let floodKeys = Set(board.floodRegion.map { "\($0.row),\($0.col)" })
        for row in 0..<n {
            var rowNodes: [FloodCellNode] = []
            for col in 0..<n {
                let color = board.cells[row][col]
                let node = FloodCellNode(color: color, cellSize: cellSize)
                let x = originX + CGFloat(col) * (cellSize + gridGap) + cellSize / 2
                let y = originY + CGFloat(n - 1 - row) * (cellSize + gridGap) + cellSize / 2
                node.position = CGPoint(x: x, y: y)
                node.name = "cell_\(row)_\(col)"

                // Configure obstacle appearance
                let cellType = board.cellType(atRow: row, col: col)
                switch cellType {
                case .stone:
                    node.configureAsStone()
                case .void:
                    node.configureAsVoid()
                case .ice(let layers):
                    node.configureAsIce(layers: layers)
                case .countdown(let movesLeft):
                    node.configureAsCountdown(movesLeft: movesLeft)
                default:
                    break
                }

                node.setFlooded(floodKeys.contains("\(row),\(col)"))
                addChild(node)
                rowNodes.append(node)
            }
            cellNodes.append(rowNodes)
        }

        renderWalls(board: board, cellSize: cellSize, originX: originX, originY: originY)

        let floodColor = board.cells[0][0]
        updateBackground(for: floodColor, animated: false)
        updateParticleColor(for: floodColor)
    }

    // MARK: - Wall Rendering

    private func renderWalls(board: FloodBoard, cellSize: CGFloat, originX: CGFloat, originY: CGFloat) {
        wallNodes.forEach { $0.removeFromParent() }
        wallNodes.removeAll()

        let n = board.gridSize

        // Only draw south and east walls to avoid duplicates
        for wall in board.walls {
            let pos = wall.position
            guard pos.row >= 0, pos.row < n, pos.col >= 0, pos.col < n else { continue }
            guard wall.direction == .south || wall.direction == .east else { continue }

            let cellX = originX + CGFloat(pos.col) * (cellSize + gridGap) + cellSize / 2
            let cellY = originY + CGFloat(n - 1 - pos.row) * (cellSize + gridGap) + cellSize / 2

            let path = UIBezierPath()
            let halfCell = cellSize / 2

            switch wall.direction {
            case .south:
                let lineY = cellY - halfCell - gridGap / 2
                path.move(to: CGPoint(x: cellX - halfCell, y: lineY))
                path.addLine(to: CGPoint(x: cellX + halfCell, y: lineY))
            case .east:
                let lineX = cellX + halfCell + gridGap / 2
                path.move(to: CGPoint(x: lineX, y: cellY - halfCell))
                path.addLine(to: CGPoint(x: lineX, y: cellY + halfCell))
            default:
                continue
            }

            let wallLine = SKShapeNode(path: path.cgPath)
            wallLine.strokeColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.70)
            wallLine.lineWidth = 2
            wallLine.zPosition = 5
            wallLine.lineCap = .round
            wallLine.name = "wall"
            addChild(wallLine)
            wallNodes.append(wallLine)
        }
    }
}
