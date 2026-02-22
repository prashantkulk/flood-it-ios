import SwiftUI
import SpriteKit

/// The 5 game colors used in Flood It, each with gradient and shadow colors.
enum GameColor: Int, CaseIterable {
    case coral
    case amber
    case emerald
    case sapphire
    case violet

    /// Light gradient color (top/left of cell).
    var lightColor: Color {
        switch self {
        case .coral:    return Color(hex: 0xFF6B6B)
        case .amber:    return Color(hex: 0xFFD93D)
        case .emerald:  return Color(hex: 0x6BCB77)
        case .sapphire: return Color(hex: 0x4D96FF)
        case .violet:   return Color(hex: 0xC77DFF)
        }
    }

    /// Dark gradient color (bottom/right of cell).
    var darkColor: Color {
        switch self {
        case .coral:    return Color(hex: 0xC0392B)
        case .amber:    return Color(hex: 0xE0A800)
        case .emerald:  return Color(hex: 0x27AE60)
        case .sapphire: return Color(hex: 0x1A6BC4)
        case .violet:   return Color(hex: 0x8E44AD)
        }
    }

    /// SKColor for SpriteKit rendering (uses the light gradient color).
    var skColor: SKColor {
        switch self {
        case .coral:    return SKColor(red: 0xFF/255, green: 0x6B/255, blue: 0x6B/255, alpha: 1)
        case .amber:    return SKColor(red: 0xFF/255, green: 0xD9/255, blue: 0x3D/255, alpha: 1)
        case .emerald:  return SKColor(red: 0x6B/255, green: 0xCB/255, blue: 0x77/255, alpha: 1)
        case .sapphire: return SKColor(red: 0x4D/255, green: 0x96/255, blue: 0xFF/255, alpha: 1)
        case .violet:   return SKColor(red: 0xC7/255, green: 0x7D/255, blue: 0xFF/255, alpha: 1)
        }
    }

    /// Shadow color with appropriate opacity for depth effect.
    var shadowColor: Color {
        switch self {
        case .coral:    return Color(red: 192/255, green: 57/255, blue: 43/255, opacity: 0.4)
        case .amber:    return Color(red: 224/255, green: 168/255, blue: 0/255, opacity: 0.35)
        case .emerald:  return Color(red: 39/255, green: 174/255, blue: 96/255, opacity: 0.35)
        case .sapphire: return Color(red: 26/255, green: 107/255, blue: 196/255, opacity: 0.4)
        case .violet:   return Color(red: 142/255, green: 68/255, blue: 173/255, opacity: 0.4)
        }
    }

    /// UIColor shadow color for SpriteKit drop shadow rendering.
    var uiShadowColor: UIColor {
        switch self {
        case .coral:    return UIColor(red: 192/255, green: 57/255, blue: 43/255, alpha: 0.5)
        case .amber:    return UIColor(red: 224/255, green: 168/255, blue: 0/255, alpha: 0.45)
        case .emerald:  return UIColor(red: 39/255, green: 174/255, blue: 96/255, alpha: 0.45)
        case .sapphire: return UIColor(red: 26/255, green: 107/255, blue: 196/255, alpha: 0.5)
        case .violet:   return UIColor(red: 142/255, green: 68/255, blue: 173/255, alpha: 0.5)
        }
    }

    /// UIColor version of lightColor for Core Graphics rendering.
    var uiLightColor: UIColor {
        switch self {
        case .coral:    return UIColor(red: 0xFF/255, green: 0x6B/255, blue: 0x6B/255, alpha: 1)
        case .amber:    return UIColor(red: 0xFF/255, green: 0xD9/255, blue: 0x3D/255, alpha: 1)
        case .emerald:  return UIColor(red: 0x6B/255, green: 0xCB/255, blue: 0x77/255, alpha: 1)
        case .sapphire: return UIColor(red: 0x4D/255, green: 0x96/255, blue: 0xFF/255, alpha: 1)
        case .violet:   return UIColor(red: 0xC7/255, green: 0x7D/255, blue: 0xFF/255, alpha: 1)
        }
    }

    /// UIColor version of darkColor for Core Graphics rendering.
    var uiDarkColor: UIColor {
        switch self {
        case .coral:    return UIColor(red: 0xC0/255, green: 0x39/255, blue: 0x2B/255, alpha: 1)
        case .amber:    return UIColor(red: 0xE0/255, green: 0xA8/255, blue: 0x00/255, alpha: 1)
        case .emerald:  return UIColor(red: 0x27/255, green: 0xAE/255, blue: 0x60/255, alpha: 1)
        case .sapphire: return UIColor(red: 0x1A/255, green: 0x6B/255, blue: 0xC4/255, alpha: 1)
        case .violet:   return UIColor(red: 0x8E/255, green: 0x44/255, blue: 0xAD/255, alpha: 1)
        }
    }
}

// MARK: - Color hex initializer

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
