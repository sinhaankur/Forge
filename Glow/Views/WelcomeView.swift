import SwiftUI

/// A concise first-run welcome that orients the user to Forge's pillars and the
/// key actions, so the app feels intuitive on first open. Shown once.
struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    var onGetStarted: () -> Void

    private let features: [(icon: String, title: String, body: String)] = [
        ("checklist", "Today", "Your routines as a tap-to-complete checklist. Build streaks."),
        ("figure.strengthtraining.traditional", "Personalized training", "Set your profile and generate an injury-aware CrossFit plan — every session starts with a proper warm-up."),
        ("dna", "DNA-powered", "Upload a DNA file (23andMe / AncestryDNA / MyHeritage) — parsed on your device — to tune training & nutrition."),
        ("fork.knife", "Nutrition", "A high-protein meal plan with fueling guidance personalized to you."),
        ("chart.bar.fill", "Progress", "Streaks, a consistency calendar, and your Apple Health activity — all private."),
    ]

    var body: some View {
        ZStack {
            GlowTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 14) {
                            GlowMark(size: 64)
                            Text("Welcome to Forge")
                                .font(GlowTheme.display(34))
                                .foregroundStyle(GlowTheme.ink)
                            Text("Built daily. Private by design — nothing leaves your device.")
                                .font(GlowTheme.body(16))
                                .foregroundStyle(GlowTheme.inkMuted)
                        }
                        .padding(.top, 24)

                        VStack(spacing: 12) {
                            ForEach(features, id: \.title) { f in
                                HStack(alignment: .top, spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(GlowTheme.surfaceHigh)
                                            .frame(width: 44, height: 44)
                                        Image(systemName: f.icon)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(GlowTheme.accent)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(f.title).font(GlowTheme.headline(16)).foregroundStyle(GlowTheme.ink)
                                        Text(f.body).font(GlowTheme.body(14)).foregroundStyle(GlowTheme.inkMuted)
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                VStack(spacing: 10) {
                    GlowButton(title: "Get started", systemImage: "arrow.right") {
                        onGetStarted(); dismiss()
                    }
                    Text("Not medical advice · No account · No tracking")
                        .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                }
                .padding(20)
            }
        }
    }
}
