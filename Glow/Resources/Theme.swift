import SwiftUI

/// Glow brand design system.
/// Minimal monochrome layout (off-white / near-black, big bold type, whitespace)
/// with a single warm coral→amber accent. Light + dark adaptive.
enum GlowTheme {

    // MARK: Accent

    /// Electric cyan-teal hero accent (dark-first design).
    static let teal = Color(hex: "#19E3C2")
    static let tealBright = Color(hex: "#3DF0D6")

    /// The accent gradient — used for rings, primary actions, key numerals.
    static var accentGradient: LinearGradient {
        LinearGradient(colors: [teal, tealBright], startPoint: .leading, endPoint: .trailing)
    }

    /// Flat accent for text / small marks.
    static let accent = teal

    // MARK: Pure-black bento surfaces (forced dark regardless of system setting)

    /// Page background — true black (matches the reference).
    static let background = Color(hex: "#000000")

    /// Raised bento card / panel.
    static let surface = Color(hex: "#141414")

    /// A slightly lighter inner surface (nested cards, progress tracks).
    static let surfaceHigh = Color(hex: "#1E1E1E")

    /// Primary text — white.
    static let ink = Color(hex: "#FFFFFF")

    /// Secondary / muted text.
    static let inkMuted = Color(hex: "#7C7C80")

    /// Empty/uncompleted dot, hairline, or unfilled track.
    static let faint = Color(hex: "#2C2C2E")

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

    static let cornerRadius: CGFloat = 24
    static let cardPadding: CGFloat = 18
}

// MARK: - Reusable components

/// A dark bento card surface.
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

/// A circular progress ring (used on bento stat cards, like the references).
struct ProgressRing: View {
    var progress: Double          // 0...1
    var lineWidth: CGFloat = 4
    var label: String? = nil      // centered text, e.g. "1"
    var tint: AnyShapeStyle = AnyShapeStyle(GlowTheme.accentGradient)

    var body: some View {
        ZStack {
            Circle().stroke(GlowTheme.faint, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if let label {
                Text(label).font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(GlowTheme.ink)
            }
        }
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
            case .filled: Circle().fill(GlowTheme.ink.opacity(0.85))
            case .today:  Circle().fill(GlowTheme.accentGradient)
            }
        }
        .frame(width: size, height: size)
    }
}

/// The Forge mark: three ascending chevrons (level-up / forward motion) in the
/// accent gradient — matches the app icon.
struct GlowMark: View {
    var size: CGFloat = 64
    var body: some View {
        Canvas { ctx, canvas in
            let w = canvas.width
            let cx = w / 2
            let armW = w * 0.30
            let thick = w * 0.10
            let rise = w * 0.16
            let gradient = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [GlowTheme.teal, GlowTheme.tealBright]),
                startPoint: .zero, endPoint: CGPoint(x: w, y: canvas.height))
            for (i, baseY) in [0.30, 0.52, 0.74].enumerated() {
                _ = i
                let y = canvas.height * baseY
                var p = Path()
                p.move(to: CGPoint(x: cx - armW, y: y))
                p.addLine(to: CGPoint(x: cx, y: y + rise))
                p.addLine(to: CGPoint(x: cx + armW, y: y))
                p.addLine(to: CGPoint(x: cx + armW, y: y - thick))
                p.addLine(to: CGPoint(x: cx, y: y + rise - thick))
                p.addLine(to: CGPoint(x: cx - armW, y: y - thick))
                p.closeSubpath()
                ctx.fill(p, with: gradient)
            }
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
