import SpriteKit
import UIKit

/// Pre-renders and caches SKTextures used by FloodCellNode layers.
class CellTextureCache {
    static let shared = CellTextureCache()

    private var cache: [String: SKTexture] = [:]

    func clearAll() {
        cache.removeAll()
    }

    // MARK: - Public API

    func solid(color: UIColor, size: CGSize, cornerRadius: CGFloat) -> SKTexture {
        let key = "solid_\(color.hashValue)_\(Int(size.width))"
        if let t = cache[key] { return t }
        let tex = SKTexture(image: Self.drawRoundedRect(color: color, size: size, cornerRadius: cornerRadius))
        cache[key] = tex
        return tex
    }

    func gradient(for gameColor: GameColor, size: CGSize, cornerRadius: CGFloat) -> SKTexture {
        let themeId = ThemeManager.shared.activeTheme.id
        let key = "grad_\(themeId)_\(gameColor.rawValue)_\(Int(size.width))"
        if let t = cache[key] { return t }
        let tex = SKTexture(image: Self.drawGradient(light: gameColor.uiLightColor, dark: gameColor.uiDarkColor, size: size, cornerRadius: cornerRadius))
        cache[key] = tex
        return tex
    }

    func glow(for gameColor: GameColor, size: CGSize) -> SKTexture {
        let themeId = ThemeManager.shared.activeTheme.id
        let key = "glow_\(themeId)_\(gameColor.rawValue)_\(Int(size.width))"
        if let t = cache[key] { return t }
        let tex = SKTexture(image: Self.drawGlow(color: gameColor.uiLightColor, size: size))
        cache[key] = tex
        return tex
    }

    func shadow(for gameColor: GameColor, size: CGSize, cornerRadius: CGFloat) -> SKTexture {
        let themeId = ThemeManager.shared.activeTheme.id
        let key = "shadow_\(themeId)_\(gameColor.rawValue)_\(Int(size.width))"
        if let t = cache[key] { return t }
        let shadowColor = gameColor.uiShadowColor
        let tex = SKTexture(image: Self.drawRoundedRect(color: shadowColor, size: size, cornerRadius: cornerRadius))
        cache[key] = tex
        return tex
    }

    func highlight(size: CGSize, cornerRadius: CGFloat) -> SKTexture {
        let key = "highlight_\(Int(size.width))"
        if let t = cache[key] { return t }
        let tex = SKTexture(image: Self.drawHighlight(size: size, cornerRadius: cornerRadius))
        cache[key] = tex
        return tex
    }

    // MARK: - Obstacle Textures

    func stoneGradient(size: CGSize, cornerRadius: CGFloat) -> SKTexture {
        let key = "stone_grad_\(Int(size.width))"
        if let t = cache[key] { return t }
        let light = UIColor(red: 0.45, green: 0.43, blue: 0.40, alpha: 1.0)
        let dark = UIColor(red: 0.25, green: 0.23, blue: 0.20, alpha: 1.0)
        let tex = SKTexture(image: Self.drawGradient(light: light, dark: dark, size: size, cornerRadius: cornerRadius))
        cache[key] = tex
        return tex
    }

    func iceOverlay(size: CGSize, cornerRadius: CGFloat, layers: Int) -> SKTexture {
        let key = "ice_\(layers)_\(Int(size.width))"
        if let t = cache[key] { return t }
        let alpha: CGFloat = layers >= 2 ? 0.50 : 0.30
        let color = UIColor(red: 0.75, green: 0.88, blue: 1.0, alpha: alpha)
        let tex = SKTexture(image: Self.drawRoundedRect(color: color, size: size, cornerRadius: cornerRadius))
        cache[key] = tex
        return tex
    }

    func portalVortex(size: CGSize, pairId: Int) -> SKTexture {
        let key = "portal_\(pairId)_\(Int(size.width))"
        if let t = cache[key] { return t }
        let color = Self.portalColor(for: pairId)
        let tex = SKTexture(image: Self.drawGlow(color: color, size: size))
        cache[key] = tex
        return tex
    }

    static func portalColor(for pairId: Int) -> UIColor {
        let colors: [UIColor] = [
            UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0),   // cyan
            UIColor(red: 1.0, green: 0.3, blue: 0.8, alpha: 1.0),   // magenta
            UIColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0),   // yellow
            UIColor(red: 0.5, green: 1.0, blue: 0.3, alpha: 1.0),   // lime
        ]
        return colors[pairId % colors.count]
    }

    func stoneShadow(size: CGSize, cornerRadius: CGFloat) -> SKTexture {
        let key = "stone_shadow_\(Int(size.width))"
        if let t = cache[key] { return t }
        let color = UIColor(red: 0.15, green: 0.13, blue: 0.10, alpha: 0.7)
        let tex = SKTexture(image: Self.drawRoundedRect(color: color, size: size, cornerRadius: cornerRadius))
        cache[key] = tex
        return tex
    }

    // MARK: - Renderers

    private static func drawHighlight(size: CGSize, cornerRadius: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            let cgCtx = ctx.cgContext
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: cornerRadius)
            path.addClip()
            let cs = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor.white.withAlphaComponent(0.38).cgColor,
                UIColor.white.withAlphaComponent(0.0).cgColor
            ] as CFArray
            let locs: [CGFloat] = [0, 1]
            if let g = CGGradient(colorsSpace: cs, colors: colors, locations: locs) {
                // White-to-transparent covering top 30%
                cgCtx.drawLinearGradient(g,
                    start: CGPoint(x: size.width / 2, y: size.height),
                    end: CGPoint(x: size.width / 2, y: size.height * 0.65),
                    options: [])
            }
        }
    }

    private static func drawGlow(color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            let cgCtx = ctx.cgContext
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.width / 2
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: nil)
            let cs = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(red: r, green: g, blue: b, alpha: 0.55).cgColor,
                UIColor(red: r, green: g, blue: b, alpha: 0.0).cgColor
            ] as CFArray
            let locs: [CGFloat] = [0, 1]
            if let gradient = CGGradient(colorsSpace: cs, colors: colors, locations: locs) {
                cgCtx.drawRadialGradient(gradient,
                    startCenter: center, startRadius: 0,
                    endCenter: center, endRadius: radius,
                    options: [])
            }
        }
    }

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
