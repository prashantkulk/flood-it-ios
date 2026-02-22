import SpriteKit
import UIKit

/// Custom SKNode with layered 3D raised-button appearance for each board cell.
/// Layers (bottom to top): glow, shadow, gradient body, highlight, bevel, gloss dot.
final class FloodCellNode: SKNode {

    let cellSize: CGFloat
    private(set) var gameColor: GameColor

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

        // Shadow — offset below body, color-matched
        shadowNode = SKSpriteNode(color: .clear, size: sz)
        shadowNode.zPosition = -1
        shadowNode.position = CGPoint(x: 2, y: -2)
        shadowNode.alpha = 0.7
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

        // Gloss dot — small white circle in top-left
        let glossRadius = cellSize * 0.09
        glossNode = SKShapeNode(circleOfRadius: glossRadius)
        glossNode.fillColor = UIColor.white.withAlphaComponent(0.25)
        glossNode.strokeColor = .clear
        glossNode.position = CGPoint(x: -cellSize * 0.28, y: cellSize * 0.28)
        glossNode.zPosition = 3
        addChild(glossNode)
    }

    func applyColor(_ color: GameColor) {
        self.gameColor = color
        let sz = CGSize(width: cellSize, height: cellSize)
        let cornerRadius = cellSize * cornerFraction

        // Glow texture
        let glowSize = CGSize(width: cellSize * 1.45, height: cellSize * 1.45)
        let glowTex = CellTextureCache.glow(for: color, size: glowSize)
        glowNode.texture = glowTex
        glowNode.size = glowSize

        // Shadow texture (color-matched, soft)
        let shadowTex = CellTextureCache.shadow(for: color, size: sz, cornerRadius: cornerRadius)
        shadowNode.texture = shadowTex
        shadowNode.size = sz

        // Gradient body texture (light → dark, top-left to bottom-right)
        let bodyTex = CellTextureCache.gradient(for: color, size: sz, cornerRadius: cornerRadius)
        bodyNode.texture = bodyTex
        bodyNode.size = sz

        // Highlight texture
        let highlightTex = CellTextureCache.highlight(size: sz, cornerRadius: cornerRadius)
        highlightNode.texture = highlightTex
        highlightNode.size = sz
    }

    /// Mark cell as flooded or not (used for breathing animation in T9).
    func setFlooded(_ flooded: Bool) {
        // Breathing animation will be added in T9
    }
}
