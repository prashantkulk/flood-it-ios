import SwiftUI
import SpriteKit

/// The 5 game colors used in Flood It, each with gradient and shadow colors.
/// Color values are provided by the active theme via ThemeManager.
enum GameColor: Int, CaseIterable {
    case coral
    case amber
    case emerald
    case sapphire
    case violet

    private var theme: ColorTheme { ThemeManager.shared.activeTheme }

    /// Light gradient color (top/left of cell).
    var lightColor: Color { theme.lightColor(for: self) }

    /// Dark gradient color (bottom/right of cell).
    var darkColor: Color { theme.darkColor(for: self) }

    /// SKColor for SpriteKit rendering (uses the light gradient color).
    var skColor: SKColor { theme.skColor(for: self) }

    /// Shadow color with appropriate opacity for depth effect.
    var shadowColor: Color { theme.shadowColor(for: self) }

    /// UIColor shadow color for SpriteKit drop shadow rendering.
    var uiShadowColor: UIColor { theme.uiShadowColor(for: self) }

    /// UIColor version of lightColor for Core Graphics rendering.
    var uiLightColor: UIColor { theme.uiLightColor(for: self) }

    /// Bandpass center frequency for button click sound.
    var clickFrequency: Double {
        switch self {
        case .coral:    return 800   // warm
        case .amber:    return 1200  // bright
        case .emerald:  return 1000  // neutral
        case .sapphire: return 1500  // crisp
        case .violet:   return 900   // mellow
        }
    }

    /// UIColor version of darkColor for Core Graphics rendering.
    var uiDarkColor: UIColor { theme.uiDarkColor(for: self) }
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
