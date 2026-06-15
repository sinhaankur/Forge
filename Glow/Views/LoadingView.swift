import SwiftUI

/// Branded loading screen shown briefly at launch — the chevron mark animates
/// up (level-up motion) on pure black, then hands off to the app. Lightweight,
/// pure SwiftUI (no assets).
struct LoadingView: View {
    @State private var appeared = false
    @State private var glow = false

    var body: some View {
        ZStack {
            GlowTheme.background.ignoresSafeArea()
            VStack(spacing: 22) {
                AnimatedChevrons(progress: appeared)
                    .frame(width: 96, height: 96)
                    .shadow(color: GlowTheme.accent.opacity(glow ? 0.7 : 0.2),
                            radius: glow ? 22 : 8)

                VStack(spacing: 4) {
                    Text("FORGE")
                        .font(.system(size: 22, weight: .heavy))
                        .kerning(4)
                        .foregroundStyle(GlowTheme.ink)
                        .opacity(appeared ? 1 : 0)
                    Text("Built daily.")
                        .font(GlowTheme.caption())
                        .foregroundStyle(GlowTheme.accent)
                        .opacity(appeared ? 1 : 0)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { glow = true }
        }
    }
}

/// Three ascending chevrons that rise into place — matches the app icon/logo.
private struct AnimatedChevrons: View {
    var progress: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w / 2
            let armW = w * 0.30
            let thick = w * 0.10
            let rise = w * 0.16
            ForEach(0..<3, id: \.self) { i in
                ChevronShape(armW: armW, thick: thick, rise: rise)
                    .fill(GlowTheme.accentGradient)
                    .frame(width: w, height: h)
                    .offset(y: chevronY(i, h: h))
                    .opacity(progress ? 1 : 0)
                    .offset(y: progress ? 0 : 16)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.12), value: progress)
                    .position(x: cx, y: chevronCenterY(i, h: h))
            }
        }
    }

    private func chevronCenterY(_ i: Int, h: CGFloat) -> CGFloat {
        [h * 0.32, h * 0.52, h * 0.72][i]
    }
    private func chevronY(_ i: Int, h: CGFloat) -> CGFloat { 0 }
}

private struct ChevronShape: Shape {
    var armW: CGFloat; var thick: CGFloat; var rise: CGFloat
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let y = rect.midY
        var p = Path()
        p.move(to: CGPoint(x: cx - armW, y: y))
        p.addLine(to: CGPoint(x: cx, y: y + rise))
        p.addLine(to: CGPoint(x: cx + armW, y: y))
        p.addLine(to: CGPoint(x: cx + armW, y: y - thick))
        p.addLine(to: CGPoint(x: cx, y: y + rise - thick))
        p.addLine(to: CGPoint(x: cx - armW, y: y - thick))
        p.closeSubpath()
        return p
    }
}
