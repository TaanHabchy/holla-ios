import SwiftUI

/// Visual design tokens for the app: an original, energetic/athletic-social
/// palette + type/spacing/radius/elevation scale. Deliberately not a copy of
/// any existing brand's colors, logo, or wordmark.
enum Theme {

    // MARK: Color

    /// Bold burnt-orange/red accent. Used sparingly: the availability hero,
    /// the "open to call" status ring/badge/text, and the add-friend action —
    /// nowhere else, so it stays meaningful.
    static let accent = Color.dynamic(light: 0xC1440E, dark: 0xE2591F)

    static let background = Color.dynamic(light: 0xFBF9F7, dark: 0x1A1714)
    static let surface = Color.dynamic(light: 0xFFFFFF, dark: 0x242019)
    static let hairline = Color.dynamic(light: 0xECE7E3, dark: 0x35302A)

    static let textPrimary = Color.dynamic(light: 0x1C1815, dark: 0xFAF7F4)
    static let textSecondary = Color.dynamic(light: 0x6B6560, dark: 0xB5AEA6)
    /// "Not available" status text and other muted/tertiary text. Meets 4.5:1
    /// contrast against `background`/`surface` in both modes — this is the
    /// text half of the non-color status cue, so it can't be too faint.
    static let textTertiary = Color.dynamic(light: 0x726C63, dark: 0x9C948A)

    /// Background behind initials when a friend has no photo.
    static let avatarFill = Color.dynamic(light: 0xF4F1ED, dark: 0x2E2921)
    /// Row chevrons and the "not available" badge fill.
    static let divider = Color.dynamic(light: 0xD8D2CB, dark: 0x4A443B)

    // MARK: Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: Radius

    enum Radius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }

    // MARK: Elevation

    static func restingShadow() -> some View {
        Color.clear.shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    struct ElevationModifier: ViewModifier {
        let raised: Bool
        func body(content: Content) -> some View {
            content.shadow(
                color: .black.opacity(raised ? 0.10 : 0.06),
                radius: raised ? 10 : 4,
                x: 0,
                y: raised ? 6 : 2
            )
        }
    }

    // MARK: Type

    /// Big, glanceable headline (e.g. the availability hero). No custom font —
    /// heavy weight + rounded design + tight tracking on SF Pro instead, so
    /// there's no font-licensing/embedding to manage.
    static func display(_ size: CGFloat = 26) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func title(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func overline(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
}

extension View {
    func elevation(raised: Bool = false) -> some View {
        modifier(Theme.ElevationModifier(raised: raised))
    }
}

extension Color {
    /// A color that resolves to `light` or `dark` depending on the active
    /// UITraitCollection, so it responds to Dark Mode automatically without
    /// needing entries in the asset catalog.
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255
        let g = CGFloat((hex & 0x00FF00) >> 8) / 255
        let b = CGFloat(hex & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
