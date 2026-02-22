import SpriteKit
import UIKit

class GameScene: SKScene {
    private var cellNodes: [[FloodCellNode]] = []
    private var board: FloodBoard?
    private let gridPadding: CGFloat = 16
    private var gridGap: CGFloat = 4

    // Dynamic background layers
    private var bgCurrent: SKSpriteNode?
    private var bgNext: SKSpriteNode?

    // Ambient particles
    private var particleEmitter: SKEmitterNode?

    func configure(with board: FloodBoard) {
        self.board = board
        if size.width > 0 {
            renderBoard()
        }
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1)
        scaleMode = .resizeFill
        setupDynamicBackground()
        setupParticles()
        if board != nil {
            renderBoard()
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

        // Remove ripple rings and sparkles
        children.filter { $0.name == "rippleRing" || $0.name == "sparkle" }.forEach { $0.removeFromParent() }

        // Snap all cell nodes to final state
        guard let board = board else { return }
        let floodKeys = Set(board.floodRegion.map { "\($0.row),\($0.col)" })
        for row in 0..<board.gridSize {
            for col in 0..<board.gridSize {
                guard row < cellNodes.count, col < cellNodes[row].count else { continue }
                let node = cellNodes[row][col]
                node.removeAction(forKey: "floodAnim")
                node.removeCrossfadeOverlays()
                let cell = board.cells[row][col]
                if node.gameColor != cell {
                    node.applyColor(cell)
                }
                node.alpha = 1.0
                node.setFlooded(floodKeys.contains("\(row),\(col)"))
            }
        }
    }

    // MARK: - Board Rendering

    func updateColors(from board: FloodBoard) {
        self.board = board
        let floodKeys = Set(board.floodRegion.map { "\($0.row),\($0.col)" })
        for row in 0..<board.gridSize {
            for col in 0..<board.gridSize {
                guard row < cellNodes.count, col < cellNodes[row].count else { continue }
                let node = cellNodes[row][col]
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
    }

    /// Animate the flood with staggered waves. Flood region cells change instantly;
    /// absorbed cells animate wave-by-wave with pop + crossfade.
    func animateFlood(board: FloodBoard, waves: [[CellPosition]], newColor: GameColor, previousColors: [CellPosition: GameColor], completion: (() -> Void)? = nil) {
        self.board = board

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

        // Update background and particles
        updateBackground(for: newColor)
        updateParticleColor(for: newColor)

        guard !waves.isEmpty else {
            completion?()
            return
        }

        isAnimating = true
        let waveDelay: TimeInterval = 0.03  // 30ms per wave

        // Calculate total animation duration for completion callback
        let totalWaves = waves.count
        let lastWaveStart = Double(totalWaves - 1) * waveDelay
        let perCellDuration: TimeInterval = 0.15

        for (waveIndex, wave) in waves.enumerated() {
            let delay = Double(waveIndex) * waveDelay

            // Ripple ring at wave centroid
            spawnRippleRing(for: wave, delay: delay, color: newColor)

            for pos in wave {
                guard pos.row < cellNodes.count, pos.col < cellNodes[pos.row].count else { continue }
                let node = cellNodes[pos.row][pos.col]

                // Build the animation sequence for this cell
                let waitAction = SKAction.wait(forDuration: delay)

                // Pop: scale 0.85 → 1.05 → 1.0 with spring feel
                let shrink = SKAction.scale(to: 0.85, duration: 0.04)
                shrink.timingMode = .easeIn
                let overshoot = SKAction.scale(to: 1.05, duration: 0.08)
                overshoot.timingMode = .easeOut
                let settle = SKAction.scale(to: 1.0, duration: 0.06)
                settle.timingMode = .easeInEaseOut
                let popSequence = SKAction.sequence([shrink, overshoot, settle])

                // Brief brightness flash during pop
                let flashUp = SKAction.fadeAlpha(to: 0.8, duration: 0.04)
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

        // Schedule completion after all waves finish
        let totalDuration = lastWaveStart + perCellDuration + 0.05
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

    // MARK: - Ripple Ring Effect

    private func spawnRippleRing(for wave: [CellPosition], delay: TimeInterval, color: GameColor) {
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
        let expand = SKAction.scale(to: 4.0, duration: 0.35)
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
                node.setFlooded(floodKeys.contains("\(row),\(col)"))
                addChild(node)
                rowNodes.append(node)
            }
            cellNodes.append(rowNodes)
        }

        let floodColor = board.cells[0][0]
        updateBackground(for: floodColor, animated: false)
        updateParticleColor(for: floodColor)
    }
}
