import SpriteKit
import UIKit

/// Pre-renders and caches SKTextures used by FloodCellNode layers.
enum CellTextureCache {

    private static var cache: [String: SKTexture] = [:]

    // MARK: - Public API

    static func solid(color: UIColor, size: CGSize, cornerRadius: CGFloat) -> SKTexture {
        let key = "solid_\(color.hashValue)_\(Int(size.width))"
        if let t = cache[key] { return t }
        let tex = SKTexture(image: drawRoundedRect(color: color, size: size, cornerRadius: cornerRadius))
        cache[key] = tex
        return tex
    }

    // MARK: - Renderers

    private static func drawRoundedRect(color: UIColor, size: CGSize, cornerRadius: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: cornerRadius)
            color.setFill()
            path.fill()
        }
    }
}
