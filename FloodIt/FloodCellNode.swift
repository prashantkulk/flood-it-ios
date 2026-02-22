import SpriteKit
import UIKit

/// Custom SKNode with layered 3D raised-button appearance for each board cell.
/// Layers (bottom to top): glow, shadow, gradient body, highlight, bevel, gloss dot.
final class FloodCellNode: SKNode {

    let cellSize: CGFloat
    private(set) var gameColor: GameColor

    // Layer nodes
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

        // Body — rounded rect with solid color (gradient in T2)
        bodyNode = SKSpriteNode(color: .clear, size: sz)
        bodyNode.zPosition = 0
        addChild(bodyNode)
    }

    func applyColor(_ color: GameColor) {
        self.gameColor = color
        let sz = CGSize(width: cellSize, height: cellSize)
        let cornerRadius = cellSize * cornerFraction

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
