import SwiftUI
import SpriteKit

/// A color theme provides 5 gradient pairs + shadow colors for the game's colors.
struct ColorTheme: Identifiable {
    let id: String
    let name: String
    let starsRequired: Int

    /// Light gradient color per GameColor raw value (0-4).
    let lightColors: [UInt32]
    /// Dark gradient color per GameColor raw value (0-4).
    let darkColors: [UInt32]
    /// Shadow opacity per GameColor raw value (0-4).
    let shadowOpacities: [CGFloat]

    func lightColor(for color: GameColor) -> Color {
        Color(hex: lightColors[color.rawValue])
    }

    func darkColor(for color: GameColor) -> Color {
        Color(hex: darkColors[color.rawValue])
    }

    func skColor(for color: GameColor) -> SKColor {
        let hex = lightColors[color.rawValue]
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        return SKColor(red: r, green: g, blue: b, alpha: 1)
    }

    func shadowColor(for color: GameColor) -> Color {
        let hex = darkColors[color.rawValue]
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b, opacity: Double(shadowOpacities[color.rawValue]))
    }

    func uiLightColor(for color: GameColor) -> UIColor {
        let hex = lightColors[color.rawValue]
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }

    func uiDarkColor(for color: GameColor) -> UIColor {
        let hex = darkColors[color.rawValue]
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }

    func uiShadowColor(for color: GameColor) -> UIColor {
        let hex = darkColors[color.rawValue]
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: shadowOpacities[color.rawValue])
    }
}

/// Manages color themes: stores selection, provides active theme.
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    private static let selectedThemeKey = "theme_selectedId"

    static let defaultTheme = ColorTheme(
        id: "default",
        name: "Classic",
        starsRequired: 0,
        lightColors: [0xFF6B6B, 0xFFD93D, 0x6BCB77, 0x4D96FF, 0xC77DFF],
        darkColors:   [0xC0392B, 0xE0A800, 0x27AE60, 0x1A6BC4, 0x8E44AD],
        shadowOpacities: [0.4, 0.35, 0.35, 0.4, 0.4]
    )

    static let oceanTheme = ColorTheme(
        id: "ocean",
        name: "Ocean",
        starsRequired: 50,
        lightColors: [0x00CEC9, 0x74B9FF, 0xDFE6E9, 0x0984E3, 0x6C5CE7],
        darkColors:   [0x009688, 0x2980B9, 0xB2BEC3, 0x0652DD, 0x4834D4],
        shadowOpacities: [0.4, 0.35, 0.3, 0.4, 0.4]
    )

    static let sunsetTheme = ColorTheme(
        id: "sunset",
        name: "Sunset",
        starsRequired: 100,
        lightColors: [0xFD7272, 0xFFA502, 0xFF6348, 0xE056A0, 0x8854D0],
        darkColors:   [0xC44569, 0xE17055, 0xD63031, 0xA363D9, 0x6C3483],
        shadowOpacities: [0.4, 0.4, 0.4, 0.35, 0.4]
    )

    static let allThemes: [ColorTheme] = [defaultTheme, oceanTheme, sunsetTheme]

    @Published private(set) var activeTheme: ColorTheme

    init() {
        let savedId = UserDefaults.standard.string(forKey: Self.selectedThemeKey) ?? "default"
        self.activeTheme = Self.allThemes.first(where: { $0.id == savedId }) ?? Self.defaultTheme
    }

    func selectTheme(_ theme: ColorTheme) {
        activeTheme = theme
        UserDefaults.standard.set(theme.id, forKey: Self.selectedThemeKey)
        // Clear texture cache so cells re-render with new theme colors
        CellTextureCache.shared.clearAll()
    }

    func isUnlocked(_ theme: ColorTheme) -> Bool {
        ProgressStore.shared.totalStars >= theme.starsRequired
    }
}
