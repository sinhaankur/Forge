import SwiftUI

/// About / Settings — what Forge is, version, privacy posture, the pillars,
/// credits, and the health disclaimer. Reachable from the profile/Today.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private let pillars: [(String, String, String)] = [
        ("checklist", "Today & Focus", "Your day at a glance, plus a guided 'press play' session player."),
        ("figure.strengthtraining.traditional", "Fitness", "Personalized CrossFit plans, warm-ups, how-to guides, AI plan import."),
        ("moon.stars.fill", "Sleep & Readiness", "Sleep tracking + a daily readiness score that adjusts training."),
        ("drop.fill", "Skincare", "Morning & evening routines with reminders."),
        ("fork.knife", "Nutrition", "High-protein plan with DNA-aware fueling guidance."),
        ("dna", "DNA Insights", "Import your DNA file on-device to personalize training & nutrition."),
        ("chart.bar.fill", "Progress", "Streaks, activity patterns, and your Apple Health data."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Brand header.
                    VStack(alignment: .leading, spacing: 12) {
                        GlowMark(size: 64)
                        Text("Forge").font(.system(size: 34, weight: .heavy)).foregroundStyle(GlowTheme.ink)
                        Text("Built daily.").font(GlowTheme.body(16)).foregroundStyle(GlowTheme.accent)
                        Text("A private, on-device app for the human basics — move, sleep, skin, fuel — personalized by your biology.")
                            .font(GlowTheme.body(15)).foregroundStyle(GlowTheme.inkMuted)
                    }
                    .padding(.top, 8)

                    card("PRIVACY", icon: "lock.shield.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            bullet("No account, no server, no analytics.")
                            bullet("Health, sleep, calendar & DNA data stay on your device.")
                            bullet("On-device AI (Apple Foundation Models) — prompts never leave your phone.")
                            bullet("Open source — anyone can inspect exactly what it does.")
                        }
                    }

                    card("WHAT'S INSIDE", icon: "square.grid.2x2.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(pillars, id: \.1) { icon, title, desc in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: icon).font(.system(size: 16)).foregroundStyle(GlowTheme.accent).frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(GlowTheme.ink)
                                        Text(desc).font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                                    }
                                }
                            }
                        }
                    }

                    card("HEALTH DISCLAIMER", icon: "stethoscope") {
                        Text("Forge provides general wellness and fitness information only — including optional genetic-trait and readiness insights. It is not a medical device and does not diagnose, treat, or prevent any condition. Consult a qualified professional before starting any exercise, nutrition, or health program, especially with existing injuries or conditions.")
                            .font(GlowTheme.body(13)).foregroundStyle(GlowTheme.inkMuted)
                    }

                    card("ABOUT", icon: "info.circle.fill") {
                        VStack(alignment: .leading, spacing: 6) {
                            row("Version", version)
                            row("Made by", "Ankur Sinha")
                            row("License", "MIT — open source")
                            Link(destination: URL(string: "https://github.com/sinhaankur/Forge")!) {
                                HStack {
                                    Text("Source code").font(GlowTheme.body(14)).foregroundStyle(GlowTheme.ink)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square").foregroundStyle(GlowTheme.accent)
                                }
                            }
                            Link(destination: URL(string: "https://www.sinhaankur.com")!) {
                                HStack {
                                    Text("Website").font(GlowTheme.body(14)).foregroundStyle(GlowTheme.ink)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square").foregroundStyle(GlowTheme.accent)
                                }
                            }
                        }
                    }

                    Text("Made with care for healthier days. 🌿")
                        .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                        .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
            .background(GlowTheme.background.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func bullet(_ t: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 12)).foregroundStyle(GlowTheme.accent).padding(.top, 2)
            Text(t).font(GlowTheme.body(14)).foregroundStyle(GlowTheme.ink)
        }
    }
    private func row(_ k: String, _ v: String) -> some View {
        HStack { Text(k).foregroundStyle(GlowTheme.inkMuted); Spacer(); Text(v).foregroundStyle(GlowTheme.ink) }
            .font(GlowTheme.body(14))
    }
    @ViewBuilder private func card<C: View>(_ title: String, icon: String, @ViewBuilder content: () -> C) -> some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: icon).font(GlowTheme.caption()).foregroundStyle(GlowTheme.accent)
                content()
            }
        }
    }
}
