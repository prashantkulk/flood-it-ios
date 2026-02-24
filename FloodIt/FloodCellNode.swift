import SpriteKit
import UIKit

/// Custom SKNode with layered 3D raised-button appearance for each board cell.
/// Layers (bottom to top): glow, shadow, gradient body, highlight, bevel, gloss dot.
final class FloodCellNode: SKNode {

    let cellSize: CGFloat
    private(set) var gameColor: GameColor
    private(set) var isStone = false
    private(set) var isVoid = false
    private(set) var iceLayers: Int = 0
    private var iceOverlayNode: SKSpriteNode?
    private(set) var countdownValue: Int = 0
    private var countdownLabel: SKLabelNode?
    private(set) var portalPairId: Int = -1
    private var portalVortexNode: SKSpriteNode?
    private(set) var bonusMultiplier: Int = 0
    private var bonusLabel: SKLabelNode?
    private var bonusGlowNode: SKSpriteNode?

    // Layer nodes
    private var glowNode: SKSpriteNode!
    private var shadowNode: SKSpriteNode!
    private var bodyNode: SKSpriteNode!
    private var highlightNode: SKSpriteNode!
    private var bevelNode: SKShapeNode!
    private var glossNode: SKShapeNode!

    let cornerFraction: CGFloat = 0.30

    init(color: GameColor, cellSize: CGFloat) {
        self.gameColor = color
        self.cellSize = cellSize
        super.init()
        buildLayers()
        applyColor(color)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not supported") }

    private func buildLayers() {
        let sz = CGSize(width: cellSize, height: cellSize)
        let glowSize = CGSize(width: cellSize * 1.45, height: cellSize * 1.45)

        // Glow — oversized radial gradient behind cell
        glowNode = SKSpriteNode(color: .clear, size: glowSize)
        glowNode.zPosition = -2
        glowNode.alpha = 0.6
        glowNode.blendMode = .add
        addChild(glowNode)

        // Shadow — offset below body, color-matched (3px for deeper 3D depth)
        shadowNode = SKSpriteNode(color: .clear, size: sz)
        shadowNode.zPosition = -1
        shadowNode.position = CGPoint(x: 3, y: -3)
        shadowNode.alpha = 0.75
        addChild(shadowNode)

        // Body — gradient fill
        bodyNode = SKSpriteNode(color: .clear, size: sz)
        bodyNode.zPosition = 0
        addChild(bodyNode)

        let cornerRadius = cellSize * cornerFraction

        // Top highlight — white-to-transparent at top 30%
        highlightNode = SKSpriteNode(color: .clear, size: sz)
        highlightNode.zPosition = 1
        addChild(highlightNode)

        // Edge bevel — white top/left, dark bottom/right
        let bevelRect = CGRect(x: -cellSize / 2, y: -cellSize / 2, width: cellSize, height: cellSize)
        let bevelPath = UIBezierPath(roundedRect: bevelRect, cornerRadius: cornerRadius)
        bevelNode = SKShapeNode(path: bevelPath.cgPath)
        bevelNode.fillColor = .clear
        bevelNode.lineWidth = 1.0
        bevelNode.strokeColor = UIColor.white.withAlphaComponent(0.22)
        bevelNode.zPosition = 2
        addChild(bevelNode)

        // Gloss dot — bright highlight circle in top-left (larger and brighter for 3D)
        let glossRadius = cellSize * 0.15
        glossNode = SKShapeNode(circleOfRadius: glossRadius)
        glossNode.fillColor = UIColor.white.withAlphaComponent(0.40)
        glossNode.strokeColor = .clear
        glossNode.position = CGPoint(x: -cellSize * 0.26, y: cellSize * 0.26)
        glossNode.zPosition = 3
        addChild(glossNode)
    }

    func applyColor(_ color: GameColor) {
        guard !isStone && !isVoid else { return }
        self.gameColor = color
        let sz = CGSize(width: cellSize, height: cellSize)
        let cornerRadius = cellSize * cornerFraction

        // Glow texture
        let glowSize = CGSize(width: cellSize * 1.45, height: cellSize * 1.45)
        let glowTex = CellTextureCache.shared.glow(for: color, size: glowSize)
        glowNode.texture = glowTex
        glowNode.size = glowSize

        // Shadow texture (color-matched, soft)
        let shadowTex = CellTextureCache.shared.shadow(for: color, size: sz, cornerRadius: cornerRadius)
        shadowNode.texture = shadowTex
        shadowNode.size = sz

        // Gradient body texture (light → dark, top-left to bottom-right)
        let bodyTex = CellTextureCache.shared.gradient(for: color, size: sz, cornerRadius: cornerRadius)
        bodyNode.texture = bodyTex
        bodyNode.size = sz

        // Highlight texture
        let highlightTex = CellTextureCache.shared.highlight(size: sz, cornerRadius: cornerRadius)
        highlightNode.texture = highlightTex
        highlightNode.size = sz
    }

    /// Configure this cell as a stone block: gray gradient, X mark to show it's impassable.
    func configureAsStone() {
        isStone = true
        let sz = CGSize(width: cellSize, height: cellSize)
        let cornerRadius = cellSize * cornerFraction

        bodyNode.texture = CellTextureCache.shared.stoneGradient(size: sz, cornerRadius: cornerRadius)
        shadowNode.texture = CellTextureCache.shared.stoneShadow(size: sz, cornerRadius: cornerRadius)
        glowNode.alpha = 0
        glossNode.isHidden = true
        highlightNode.alpha = 0.15
        bevelNode.strokeColor = UIColor.white.withAlphaComponent(0.10)

        // X mark — communicates "blocked / impassable"
        let margin = cellSize * 0.25
        let xPath = UIBezierPath()
        xPath.move(to: CGPoint(x: -cellSize / 2 + margin, y:  cellSize / 2 - margin))
        xPath.addLine(to: CGPoint(x:  cellSize / 2 - margin, y: -cellSize / 2 + margin))
        xPath.move(to: CGPoint(x:  cellSize / 2 - margin, y:  cellSize / 2 - margin))
        xPath.addLine(to: CGPoint(x: -cellSize / 2 + margin, y: -cellSize / 2 + margin))
        let xNode = SKShapeNode(path: xPath.cgPath)
        xNode.strokeColor = UIColor.white.withAlphaComponent(0.28)
        xNode.lineWidth = max(1.5, cellSize * 0.055)
        xNode.lineCap = .round
        xNode.zPosition = 4
        xNode.name = "stoneMark"
        addChild(xNode)
    }

    /// Configure this cell with an ice overlay. 2 layers = thicker/more opaque, 1 = thinner.
    func configureAsIce(layers: Int) {
        iceLayers = layers
        let sz = CGSize(width: cellSize, height: cellSize)
        let cornerRadius = cellSize * cornerFraction

        let overlay = SKSpriteNode(color: .clear, size: sz)
        overlay.texture = CellTextureCache.shared.iceOverlay(size: sz, cornerRadius: cornerRadius, layers: layers)
        overlay.zPosition = 3.5
        overlay.name = "iceOverlay"
        addChild(overlay)
        iceOverlayNode = overlay

        // Snowflake crystal lines — makes "frozen" immediately recognisable
        addIceCrystal(layers: layers)
    }

    private func addIceCrystal(layers: Int) {
        children.filter { $0.name == "iceCrystal" }.forEach { $0.removeFromParent() }
        let crystalPath = UIBezierPath()
        let r = cellSize * 0.28
        let branches = 6
        for i in 0..<branches {
            let angle = CGFloat(i) * (.pi / CGFloat(branches))
            let dx = r * cos(angle)
            let dy = r * sin(angle)
            crystalPath.move(to: CGPoint(x: -dx, y: -dy))
            crystalPath.addLine(to: CGPoint(x: dx, y: dy))
            // Small tick marks at 60% along each arm
            let arm: CGFloat = 0.55
            for sign: CGFloat in [-1, 1] {
                let mx = arm * dx
                let my = arm * dy
                let perpAngle = angle + .pi / 2
                let tx = mx + sign * r * 0.18 * cos(perpAngle)
                let ty = my + sign * r * 0.18 * sin(perpAngle)
                crystalPath.move(to: CGPoint(x: mx, y: my))
                crystalPath.addLine(to: CGPoint(x: tx, y: ty))
            }
        }
        let crystalNode = SKShapeNode(path: crystalPath.cgPath)
        crystalNode.strokeColor = UIColor.white.withAlphaComponent(layers >= 2 ? 0.65 : 0.45)
        crystalNode.lineWidth = 1.5
        crystalNode.lineCap = .round
        crystalNode.zPosition = 4.5
        crystalNode.name = "iceCrystal"
        addChild(crystalNode)
    }

    /// Update ice layers with crack animation when a layer is removed.
    func updateIceLayers(_ newLayers: Int) {
        guard newLayers != iceLayers else { return }
        iceLayers = newLayers

        if newLayers <= 0 {
            // Fully cracked — dissolve overlay and crystal
            playCrackAnimation()
            SoundManager.shared.playCrack()
            iceOverlayNode?.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ]))
            iceOverlayNode = nil
            children.filter { $0.name == "iceCrystal" }.forEach {
                $0.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()]))
            }
        } else {
            // Layer removed — update texture + crack + update crystal opacity
            let sz = CGSize(width: cellSize, height: cellSize)
            let cornerRadius = cellSize * cornerFraction
            iceOverlayNode?.texture = CellTextureCache.shared.iceOverlay(size: sz, cornerRadius: cornerRadius, layers: newLayers)
            addIceCrystal(layers: newLayers)
            playCrackAnimation()
            SoundManager.shared.playCrack()
        }
    }

    /// White fracture lines that appear briefly when ice cracks.
    private func playCrackAnimation() {
        let sz = cellSize
        let crackPath = UIBezierPath()
        crackPath.move(to: CGPoint(x: -sz * 0.3, y: sz * 0.3))
        crackPath.addLine(to: CGPoint(x: 0, y: 0))
        crackPath.addLine(to: CGPoint(x: sz * 0.25, y: -sz * 0.35))
        crackPath.move(to: CGPoint(x: 0, y: 0))
        crackPath.addLine(to: CGPoint(x: sz * 0.3, y: sz * 0.2))

        let crack = SKShapeNode(path: crackPath.cgPath)
        crack.strokeColor = UIColor.white.withAlphaComponent(0.85)
        crack.lineWidth = 1.5
        crack.zPosition = 4
        crack.name = "crackLines"
        addChild(crack)

        crack.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
    }

    /// Configure this cell with a countdown number overlay and urgency-colored body.
    func configureAsCountdown(movesLeft: Int) {
        countdownValue = movesLeft
        applyCountdownStyle(movesLeft: movesLeft)

        // Bomb/timer icon above the number
        let iconLabel = SKLabelNode(text: movesLeft <= 2 ? "💣" : "⏱")
        iconLabel.fontSize = cellSize * 0.28
        iconLabel.verticalAlignmentMode = .center
        iconLabel.horizontalAlignmentMode = .center
        iconLabel.position = CGPoint(x: 0, y: cellSize * 0.14)
        iconLabel.zPosition = 4
        iconLabel.name = "countdownIcon"
        addChild(iconLabel)

        let label = SKLabelNode(text: "\(movesLeft)")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = cellSize * 0.35
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -cellSize * 0.14)
        label.zPosition = 4
        label.name = "countdownLabel"
        addChild(label)
        countdownLabel = label

        if movesLeft <= 2 {
            startCountdownPulse()
        }
    }

    private func applyCountdownStyle(movesLeft: Int) {
        let sz = CGSize(width: cellSize, height: cellSize)
        let cornerRadius = cellSize * cornerFraction
        let urgency = min(movesLeft, 3)
        bodyNode.texture = CellTextureCache.shared.countdownGradient(size: sz, cornerRadius: cornerRadius, urgency: urgency)
        shadowNode.texture = CellTextureCache.shared.stoneShadow(size: sz, cornerRadius: cornerRadius)
        glowNode.alpha = movesLeft <= 2 ? 0.5 : 0.15
        if movesLeft <= 2 {
            // Reddish glow
            let glowSize = CGSize(width: cellSize * 1.45, height: cellSize * 1.45)
            glowNode.texture = CellTextureCache.shared.glow(
                for: .coral, size: glowSize)
        }
        highlightNode.alpha = 0.2
        glossNode.isHidden = movesLeft <= 2
        bevelNode.strokeColor = UIColor(red: 1.0, green: 0.4, blue: 0.2, alpha: 0.25)
    }

    /// Update countdown number, animating changes.
    func updateCountdown(_ newValue: Int) {
        guard newValue != countdownValue else { return }
        countdownValue = newValue

        if newValue <= 0 {
            countdownLabel?.removeFromParent()
            countdownLabel = nil
            children.filter { $0.name == "countdownIcon" }.forEach { $0.removeFromParent() }
        } else {
            countdownLabel?.text = "\(newValue)"
            applyCountdownStyle(movesLeft: newValue)
            // Update icon
            if let icon = children.first(where: { $0.name == "countdownIcon" }) as? SKLabelNode {
                icon.text = newValue <= 2 ? "💣" : "⏱"
            }
            if newValue <= 2 {
                startCountdownPulse()
            } else {
                stopCountdownPulse()
            }
        }
    }

    /// Remove the countdown label and icon (for defused or exploded cells).
    func removeCountdownLabel() {
        countdownLabel?.removeAllActions()
        countdownLabel?.removeFromParent()
        countdownLabel = nil
        countdownValue = 0
        children.filter { $0.name == "countdownIcon" }.forEach { $0.removeFromParent() }
    }

    private func startCountdownPulse() {
        guard let label = countdownLabel else { return }
        let toRed = SKAction.run { label.fontColor = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0) }
        let scaleUp = SKAction.scale(to: 1.15, duration: 0.3)
        scaleUp.timingMode = .easeInEaseOut
        let toWhite = SKAction.run { label.fontColor = .white }
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)
        scaleDown.timingMode = .easeInEaseOut
        let pulse = SKAction.sequence([toRed, scaleUp, toWhite, scaleDown])
        label.run(SKAction.repeatForever(pulse), withKey: "countdownPulse")
    }

    private func stopCountdownPulse() {
        countdownLabel?.removeAction(forKey: "countdownPulse")
        countdownLabel?.fontColor = .white
        countdownLabel?.setScale(1.0)
    }

    /// Configure this cell as a portal with a swirling vortex and pulsing colored ring.
    func configureAsPortal(pairId: Int) {
        portalPairId = pairId
        let vortexSize = CGSize(width: cellSize * 0.7, height: cellSize * 0.7)
        let vortexNode = SKSpriteNode(color: .clear, size: vortexSize)
        vortexNode.texture = CellTextureCache.shared.portalVortex(size: vortexSize, pairId: pairId)
        vortexNode.zPosition = 3.5
        vortexNode.alpha = 0.7
        vortexNode.blendMode = .add
        vortexNode.name = "portalVortex"
        addChild(vortexNode)
        portalVortexNode = vortexNode

        // Continuous rotation
        let rotate = SKAction.rotate(byAngle: 2 * .pi, duration: 3.0)
        vortexNode.run(SKAction.repeatForever(rotate), withKey: "portalRotate")

        // Pulsing colored border ring — communicates "this cell is connected to another"
        let ringColor = CellTextureCache.portalColor(for: pairId)
        let cornerRadius = cellSize * cornerFraction
        let inset: CGFloat = 2
        let ringRect = CGRect(x: -cellSize / 2 + inset, y: -cellSize / 2 + inset,
                              width: cellSize - inset * 2, height: cellSize - inset * 2)
        let ringPath = UIBezierPath(roundedRect: ringRect, cornerRadius: cornerRadius)
        let ringNode = SKShapeNode(path: ringPath.cgPath)
        ringNode.fillColor = .clear
        ringNode.strokeColor = ringColor.withAlphaComponent(0.85)
        ringNode.lineWidth = 2.0
        ringNode.zPosition = 4.5
        ringNode.name = "portalRing"
        addChild(ringNode)

        let fadeIn  = SKAction.fadeAlpha(to: 1.0, duration: 0.7)
        let fadeOut = SKAction.fadeAlpha(to: 0.25, duration: 0.7)
        fadeIn.timingMode  = .easeInEaseOut
        fadeOut.timingMode = .easeInEaseOut
        ringNode.run(SKAction.repeatForever(SKAction.sequence([fadeIn, fadeOut])), withKey: "portalPulse")
    }

    /// Configure this cell as a bonus tile with golden glow, star icon, and multiplier text.
    func configureAsBonus(multiplier: Int) {
        bonusMultiplier = multiplier

        // Brighter golden glow (replaces normal glow)
        let glowSize = CGSize(width: cellSize * 1.6, height: cellSize * 1.6)
        let goldGlow = SKSpriteNode(color: .clear, size: glowSize)
        goldGlow.texture = CellTextureCache.shared.bonusGlow(size: glowSize)
        goldGlow.zPosition = -2.5
        goldGlow.alpha = 0.8
        goldGlow.blendMode = .add
        goldGlow.name = "bonusGlow"
        addChild(goldGlow)
        bonusGlowNode = goldGlow

        // Pulsing glow
        let pulseUp = SKAction.fadeAlpha(to: 0.9, duration: 0.6)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.fadeAlpha(to: 0.5, duration: 0.6)
        pulseDown.timingMode = .easeInEaseOut
        goldGlow.run(SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown])), withKey: "bonusPulse")

        // 5-pointed star above the label
        let starPath = makeStarPath(points: 5, outerRadius: cellSize * 0.20, innerRadius: cellSize * 0.09)
        let starNode = SKShapeNode(path: starPath)
        starNode.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        starNode.strokeColor = SKColor(red: 1.0, green: 0.96, blue: 0.55, alpha: 0.7)
        starNode.lineWidth = 0.5
        starNode.position = CGPoint(x: 0, y: cellSize * 0.18)
        starNode.zPosition = 4
        starNode.name = "bonusStar"
        addChild(starNode)

        // Gold multiplier text below the star
        let label = SKLabelNode(text: "x\(multiplier)")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = cellSize * 0.32
        label.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -cellSize * 0.14)
        label.zPosition = 4
        label.name = "bonusLabel"
        addChild(label)
        bonusLabel = label
    }

    private func makeStarPath(points: Int, outerRadius: CGFloat, innerRadius: CGFloat) -> CGPath {
        let path = UIBezierPath()
        let total = points * 2
        for i in 0..<total {
            let angle = CGFloat(i) * (.pi / CGFloat(points)) - .pi / 2
            let r = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let pt = CGPoint(x: r * cos(angle), y: r * sin(angle))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.close()
        return path.cgPath
    }

    /// Remove bonus overlay (when absorbed).
    func removeBonusOverlay() {
        bonusLabel?.removeFromParent()
        bonusLabel = nil
        bonusGlowNode?.removeAllActions()
        bonusGlowNode?.removeFromParent()
        bonusGlowNode = nil
        bonusMultiplier = 0
        children.filter { $0.name == "bonusStar" }.forEach { $0.removeFromParent() }
    }

    /// Configure this cell as a void: dark recessed tile so the board shape is clear.
    func configureAsVoid() {
        isVoid = true
        let sz = CGSize(width: cellSize, height: cellSize)
        let cornerRadius = cellSize * cornerFraction
        bodyNode.texture = CellTextureCache.shared.voidGradient(size: sz, cornerRadius: cornerRadius)
        shadowNode.alpha = 0
        glowNode.alpha = 0
        highlightNode.alpha = 0
        glossNode.isHidden = true
        bevelNode.strokeColor = UIColor.white.withAlphaComponent(0.06)
        alpha = 0.7
    }

    /// Smoothly crossfade from old color to new color over given duration.
    /// Creates a temporary overlay with the old body texture and fades it out.
    func crossfadeToColor(_ newColor: GameColor, duration: TimeInterval = 0.15) {
        guard !isStone && !isVoid else { return }
        // Capture old body texture before changing
        let oldBodyTex = bodyNode.texture
        let oldGlowTex = glowNode.texture
        let oldShadowTex = shadowNode.texture

        // Apply new color underneath
        applyColor(newColor)

        guard let oldBody = oldBodyTex else { return }

        // Create overlay with old body texture
        let sz = CGSize(width: cellSize, height: cellSize)
        let overlay = SKSpriteNode(texture: oldBody, size: sz)
        overlay.zPosition = bodyNode.zPosition + 0.1
        overlay.name = "crossfadeOverlay"
        addChild(overlay)

        // Also overlay old glow
        if let oldGlow = oldGlowTex {
            let glowSize = CGSize(width: cellSize * 1.45, height: cellSize * 1.45)
            let glowOverlay = SKSpriteNode(texture: oldGlow, size: glowSize)
            glowOverlay.zPosition = glowNode.zPosition + 0.1
            glowOverlay.alpha = 0.6
            glowOverlay.blendMode = .add
            glowOverlay.name = "crossfadeGlowOverlay"
            addChild(glowOverlay)
            glowOverlay.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: duration),
                SKAction.removeFromParent()
            ]))
        }

        // Also overlay old shadow
        if let oldShadow = oldShadowTex {
            let shadowOverlay = SKSpriteNode(texture: oldShadow, size: sz)
            shadowOverlay.zPosition = shadowNode.zPosition + 0.1
            shadowOverlay.position = shadowNode.position
            shadowOverlay.alpha = 0.7
            shadowOverlay.name = "crossfadeShadowOverlay"
            addChild(shadowOverlay)
            shadowOverlay.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: duration),
                SKAction.removeFromParent()
            ]))
        }

        // Fade out the body overlay to reveal new color
        overlay.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: duration),
            SKAction.removeFromParent()
        ]))
    }

    /// Desaturate the cell to grayscale over the given duration.
    /// Colorizes body, shadow, and glow toward gray while reducing glow/gloss.
    func desaturate(duration: TimeInterval = 0.5) {
        let grayColor = UIColor(white: 0.35, alpha: 1.0)
        bodyNode.run(SKAction.colorize(with: grayColor, colorBlendFactor: 0.85, duration: duration), withKey: "desat")
        shadowNode.run(SKAction.colorize(with: .darkGray, colorBlendFactor: 0.9, duration: duration), withKey: "desatShadow")
        glowNode.run(SKAction.fadeAlpha(to: 0.1, duration: duration), withKey: "desatGlow")
        glossNode.run(SKAction.fadeAlpha(to: 0.1, duration: duration), withKey: "desatGloss")
        highlightNode.run(SKAction.fadeAlpha(to: 0.05, duration: duration), withKey: "desatHighlight")
    }

    /// Remove any lingering crossfade overlays (used when snapping animation).
    func removeCrossfadeOverlays() {
        children.filter { $0.name?.hasPrefix("crossfade") == true }.forEach { $0.removeFromParent() }
    }

    private var isFlooded = false

    /// Start or stop breathing animation for flooded cells.
    /// Flooded cells gently oscillate 2% scale over 3s cycle.
    func setFlooded(_ flooded: Bool) {
        guard flooded != isFlooded else { return }
        isFlooded = flooded
        if flooded {
            let half: TimeInterval = 1.5
            let up = SKAction.scale(to: 1.02, duration: half)
            up.timingMode = .easeInEaseOut
            let down = SKAction.scale(to: 0.98, duration: half)
            down.timingMode = .easeInEaseOut
            run(SKAction.repeatForever(SKAction.sequence([up, down])), withKey: "breathe")
        } else {
            removeAction(forKey: "breathe")
            run(SKAction.scale(to: 1.0, duration: 0.15))
        }
    }
}
