import SwiftUI

// MARK: - Theme (hardware-inspired Electra palette)

enum ElectraTheme {
    static let background = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let surface = Color(red: 0.16, green: 0.16, blue: 0.18)
    static let surfaceSecondary = Color(red: 0.22, green: 0.22, blue: 0.25)
    static let accent = Color(red: 0.96, green: 0.58, blue: 0.0) // Electra orange
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.45)
    static let bezel = Color(red: 0.15, green: 0.15, blue: 0.17)
    static let bezelHighlight = Color.white.opacity(0.08)

    static let titleFont = Font.system(size: 20, weight: .semibold)
    static let headlineFont = Font.system(size: 15, weight: .semibold)
    static let monoFont = Font.system(size: 11, weight: .regular, design: .monospaced)

    static let controlCornerRadius: CGFloat = 4
    static let bezelCornerRadius: CGFloat = 14
}

extension Color {
    init(electraHex hex: String) {
        var s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(rgb: UInt32(truncatingIfNeeded: v))
    }

    /// Build a Color from a 24-bit RGB integer (as Electra `graphics` uses).
    init(rgb: UInt32) {
        self = Color(red: Double((rgb >> 16) & 0xff) / 255,
                     green: Double((rgb >> 8) & 0xff) / 255,
                     blue: Double(rgb & 0xff) / 255)
    }
}
