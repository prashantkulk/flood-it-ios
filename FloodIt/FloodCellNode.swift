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
    }

    /// Mark cell as flooded or not (used for breathing animation in T9).
    func setFlooded(_ flooded: Bool) {
        // Breathing animation will be added in T9
    }
}
