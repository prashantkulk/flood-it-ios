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

    static func glow(for gameColor: GameColor, size: CGSize) -> SKTexture {
        let key = "glow_\(gameColor.rawValue)_\(Int(size.width))"
        if let t = cache[key] { return t }
        let tex = SKTexture(image: drawGlow(color: gameColor.uiLightColor, size: size))
        cache[key] = tex
        return tex
    }

    static func shadow(for gameColor: GameColor, size: CGSize, cornerRadius: CGFloat) -> SKTexture {
        let key = "shadow_\(gameColor.rawValue)_\(Int(size.width))"
        if let t = cache[key] { return t }
        let shadowColor = gameColor.uiShadowColor
        let tex = SKTexture(image: drawRoundedRect(color: shadowColor, size: size, cornerRadius: cornerRadius))
        cache[key] = tex
        return tex
    }

    static func highlight(size: CGSize, cornerRadius: CGFloat) -> SKTexture {
        let key = "highlight_\(Int(size.width))"
        if let t = cache[key] { return t }
        let tex = SKTexture(image: drawHighlight(size: size, cornerRadius: cornerRadius))
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
