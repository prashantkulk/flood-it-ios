import SwiftUI

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
