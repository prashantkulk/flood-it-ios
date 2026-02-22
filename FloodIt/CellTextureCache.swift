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

    static func gradient(for gameColor: GameColor, size: CGSize, cornerRadius: CGFloat) -> SKTexture {
        let key = "grad_\(gameColor.rawValue)_\(Int(size.width))"
        if let t = cache[key] { return t }
        let tex = SKTexture(image: drawGradient(light: gameColor.uiLightColor, dark: gameColor.uiDarkColor, size: size, cornerRadius: cornerRadius))
        cache[key] = tex
        return tex
    }

    // MARK: - Renderers

    private static func drawGradient(light: UIColor, dark: UIColor, size: CGSize, cornerRadius: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            let cgCtx = ctx.cgContext
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: cornerRadius)
            path.addClip()
            let cs = CGColorSpaceCreateDeviceRGB()
            let colors = [light.cgColor, dark.cgColor] as CFArray
            let locs: [CGFloat] = [0, 1]
            if let g = CGGradient(colorsSpace: cs, colors: colors, locations: locs) {
                cgCtx.drawLinearGradient(g,
                    start: CGPoint(x: 0, y: size.height),
                    end: CGPoint(x: size.width, y: 0),
                    options: [])
            }
        }
    }

    private static func drawRoundedRect(color: UIColor, size: CGSize, cornerRadius: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: cornerRadius)
            color.setFill()
            path.fill()
        }
    }
}
