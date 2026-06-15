import SwiftUI

/// Glow brand design system.
/// Minimal monochrome layout (off-white / near-black, big bold type, whitespace)
/// with a single warm coral→amber accent. Light + dark adaptive.
enum GlowTheme {

    // MARK: Accent (the only color)

    static let coral = Color(hex: "#FF7E5F")
    static let amber = Color(hex: "#FEB47B")

    /// The single warm accent gradient — used sparingly (today's dot, completed
    /// strike-throughs, primary actions).
    static var accentGradient: LinearGradient {
        LinearGradient(colors: [coral, amber], startPoint: .leading, endPoint: .trailing)
    }

    /// Flat accent for text / small marks.
    static let accent = coral

    // MARK: Monochrome surfaces

    /// Page background — warm off-white in light, near-black in dark.
    static var background: Color {
        Color(uiColorLightDark: (light: UIColor(white: 0.95, alpha: 1),
                                 dark: UIColor(white: 0.10, alpha: 1)))
    }

    /// Slightly raised surface / panel.
    static var surface: Color {
        Color(uiColorLightDark: (light: .white,
                                 dark: UIColor(white: 0.16, alpha: 1)))
    }

    /// Primary text.
    static var ink: Color {
        Color(uiColorLightDark: (light: UIColor(white: 0.07, alpha: 1),
                                 dark: UIColor(white: 0.96, alpha: 1)))
    }

    /// Secondary / muted text.
    static var inkMuted: Color {
        Color(uiColorLightDark: (light: UIColor(white: 0.45, alpha: 1),
                                 dark: UIColor(white: 0.62, alpha: 1)))
    }

    /// Empty/uncompleted dot or hairline.
    static var faint: Color {
        Color(uiColorLightDark: (light: UIColor(white: 0.83, alpha: 1),
                                 dark: UIColor(white: 0.28, alpha: 1)))
    }

    // MARK: Type — big, bold, condensed-feeling

    /// Huge date numeral, e.g. "11".
    static func numeral(_ size: CGFloat = 92) -> Font {
        .system(size: size, weight: .heavy, design: .default)
    }
    /// Big UPPERCASE day/section heading.
    static func display(_ size: CGFloat = 40) -> Font {
        .system(size: size, weight: .heavy, design: .default)
    }
    static func title(_ size: CGFloat = 22) -> Font { .system(size: size, weight: .bold) }
    static func headline(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .semibold) }
    static func body(_ size: CGFloat = 16) -> Font { .system(size: size, weight: .regular) }
    static func caption(_ size: CGFloat = 12) -> Font { .system(size: size, weight: .semibold) }

    // MARK: Metrics

    static let cornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
}

// MARK: - Reusable components

/// A minimal panel surface with a hairline separator feel.
struct GlowPanel<Content: View>: View {
    var content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(GlowTheme.cardPadding)
            .background(GlowTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: GlowTheme.cornerRadius, style: .continuous))
    }
}

/// One dot in the consistency calendar.
struct GlowDot: View {
    enum State { case empty, filled, today }
    var state: State
    var size: CGFloat = 14
    var body: some View {
        Group {
            switch state {
            case .empty:  Circle().fill(GlowTheme.faint)
            case .filled: Circle().fill(GlowTheme.ink)
            case .today:  Circle().fill(GlowTheme.accentGradient)
            }
        }
        .frame(width: size, height: size)
    }
}

/// The Glow mark: a filled accent dot with a small flame — fits the dot-calendar motif.
struct GlowMark: View {
    var size: CGFloat = 64
    var body: some View {
        ZStack {
            Circle().fill(GlowTheme.accentGradient)
            Image(systemName: "flame.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

/// Primary action button: filled accent, squared-soft corners to match minimal look.
struct GlowButton: View {
    var title: String
    var systemImage: String?
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title.uppercased()).font(GlowTheme.headline()).kerning(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(GlowTheme.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// MARK: - Color helpers

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    init(uiColorLightDark pair: (light: UIColor, dark: UIColor)) {
        self.init(UIColor { trait in
            trait.userInterfaceStyle == .dark ? pair.dark : pair.light
        })
    }
}
