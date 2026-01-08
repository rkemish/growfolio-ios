//
//  Color+Extensions.swift
//  Growfolio
//
//  Color utility extensions.
//

import SwiftUI

extension Color {

    // MARK: - Hex Initialization

    /// Initialize Color from hex string
    /// - Parameter hex: Hex color string (e.g., "#FF5733" or "FF5733")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Hex Output

    /// Convert Color to hex string
    var hexString: String? {
        guard let components = cgColor?.components, components.count >= 3 else {
            return nil
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])

        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)
        )
    }

    // MARK: - Wealth Growth Theme

    /// Trust Blue - Primary brand color for headers, navigation
    static let trustBlue = Color(hex: "#1E3A5F")

    /// Growth Green - Positive returns, gains, success states
    static let growthGreen = Color(hex: "#2E7D5A")

    /// Prosperity Gold - Highlights, premium features, CTAs
    static let prosperityGold = Color(hex: "#D4A84B")

    /// Clean White - Card backgrounds, surfaces
    static let cleanWhite = Color(hex: "#FAFBFC")

    /// Light Mint - Subtle success backgrounds
    static let lightMint = Color(hex: "#E8F5F0")

    /// Light Gold - Subtle accent backgrounds
    static let lightGold = Color(hex: "#FDF6E3")

    // MARK: - App Colors

    /// Primary accent color
    static let primaryAccent = Color("AccentColor")

    /// Success color (growth green)
    static let success = Color(hex: "#2E7D5A")

    /// Warning color (prosperity gold)
    static let warning = Color(hex: "#D4A84B")

    /// Error color (red)
    static let error = Color(hex: "#DC3545")

    /// Positive change color (growth green)
    static let positive = Color(hex: "#2E7D5A")

    /// Negative change color (loss red)
    static let negative = Color(hex: "#DC3545")

    /// Neutral color
    static let neutral = Color(hex: "#8E8E93")

    // MARK: - Glass-Aware Colors (iOS 26)

    /// High contrast primary text color for glass surfaces
    static var glassText: Color {
        Color.primary.opacity(0.95)
    }

    /// Secondary text color optimized for glass readability
    static var glassSecondaryText: Color {
        Color.secondary.opacity(0.9)
    }

    /// Vibrant version of Trust Blue for glass backgrounds
    static let trustBlueVibrant = Color(hex: "#1E3A5F").opacity(0.85)

    /// Vibrant version of Growth Green for glass backgrounds
    static let growthGreenVibrant = Color(hex: "#2E7D5A").opacity(0.85)

    /// Vibrant version of Prosperity Gold for glass backgrounds
    static let prosperityGoldVibrant = Color(hex: "#D4A84B").opacity(0.85)

    // MARK: - Chart Colors

    /// Colors for charts and graphs (theme-consistent)
    static let chartColors: [Color] = [
        Color(hex: "#1E3A5F"),  // Trust Blue
        Color(hex: "#2E7D5A"),  // Growth Green
        Color(hex: "#D4A84B"),  // Prosperity Gold
        Color(hex: "#4A6FA5"),  // Light Blue
        Color(hex: "#3D9970"),  // Bright Green
        Color(hex: "#5856D6"),  // Purple
        Color(hex: "#00C7BE"),  // Teal
        Color(hex: "#AF52DE"),  // Violet
        Color(hex: "#DC3545"),  // Loss Red
        Color(hex: "#E5B84D"),  // Bright Gold
    ]

    /// Get chart color at index (cycles)
    static func chartColor(at index: Int) -> Color {
        chartColors[index % chartColors.count]
    }

    // MARK: - Adjustments

    /// Lighten color by percentage
    func lighter(by percentage: CGFloat = 0.2) -> Color {
        adjustBrightness(by: abs(percentage))
    }

    /// Darken color by percentage
    func darker(by percentage: CGFloat = 0.2) -> Color {
        adjustBrightness(by: -abs(percentage))
    }

    private func adjustBrightness(by amount: CGFloat) -> Color {
        guard let components = cgColor?.components, components.count >= 3 else {
            return self
        }

        let r = min(max(components[0] + amount, 0), 1)
        let g = min(max(components[1] + amount, 0), 1)
        let b = min(max(components[2] + amount, 0), 1)
        let a = components.count >= 4 ? components[3] : 1

        return Color(
            .sRGB,
            red: Double(r),
            green: Double(g),
            blue: Double(b),
            opacity: Double(a)
        )
    }

    // MARK: - Contrast

    /// Check if color is dark
    var isDark: Bool {
        guard let components = cgColor?.components, components.count >= 3 else {
            return false
        }

        // Calculate perceived luminance
        let luminance = 0.299 * components[0] + 0.587 * components[1] + 0.114 * components[2]
        return luminance < 0.5
    }

    /// Get contrasting text color (black or white)
    var contrastingTextColor: Color {
        isDark ? .white : .black
    }
}

// MARK: - CGColor Extension

extension CGColor {
    /// Initialize CGColor from hex string
    static func hex(_ hex: String) -> CGColor {
        Color(hex: hex).cgColor ?? CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    }
}
