import SwiftUI
import SwiftData

/// On-device AI coach (Apple Intelligence / Foundation Models). Generates a
/// daily focus, a plain-English DNA summary, and answers free-text questions —
/// all grounded in your profile + DNA + readiness, entirely on the phone.
struct AICoachView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @StateObject private var ai = AIService.shared

    @State private var daily: String?
    @State private var summary: String?
    @State private var question = ""
    @State private var answer: String?
    @State private var thinking = false

    private var ctx: String {
        AIService.personalContext(profile: profiles.first,
                                  readiness: SleepStore.readiness(in: context))
    }
    private var insights: [DNAReport.Insight] {
        profiles.first.map { DNAReport.insights(fromPanelCSV: $0.dnaPanel) } ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Coach").font(.system(size: 34, weight: .heavy)).foregroundStyle(GlowTheme.ink)

                    if !ai.isAvailable {
                        GlowPanel {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("On-device AI unavailable", systemImage: "cpu")
                                    .font(GlowTheme.headline(15)).foregroundStyle(GlowTheme.ink)
                                Text("Apple Intelligence (iOS 26+) powers the coach. It runs fully on your device — nothing is sent anywhere. Your built-in insights still work.")
                                    .font(GlowTheme.body(13)).foregroundStyle(GlowTheme.inkMuted)
                            }
                        }
                    }

                    aiCard("TODAY'S FOCUS", icon: "sun.max.fill", text: daily)
                    aiCard("YOUR BIOLOGY", icon: "dna", text: summary)

                    // Ask anything.
                    GlowPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("ASK YOUR COACH", systemImage: "bubble.left.and.text.bubble.right")
                                .font(GlowTheme.caption()).foregroundStyle(GlowTheme.accent)
                            HStack {
                                TextField("e.g. best post-workout meal for me?", text: $question)
                                    .textFieldStyle(.plain).foregroundStyle(GlowTheme.ink)
                                Button { ask() } label: {
                                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 26)).foregroundStyle(GlowTheme.accent)
                                }.disabled(question.trimmingCharacters(in: .whitespaces).isEmpty || thinking)
                            }
                            .padding(10).background(GlowTheme.surfaceHigh).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            if thinking { ProgressView().tint(GlowTheme.accent) }
                            if let answer {
                                Text(answer).font(GlowTheme.body(14)).foregroundStyle(GlowTheme.ink)
                                    .padding(.top, 2)
                            }
                        }
                    }

                    Label("All answers are generated on your device and are general wellness guidance, not medical advice.",
                          systemImage: "lock.shield.fill")
                        .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                }
                .padding(20)
            }
            .background(GlowTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task {
                daily = await ai.dailyCoaching(context: ctx)
                summary = await ai.dnaSummary(insights: insights, context: ctx)
            }
        }
    }

    private func aiCard(_ title: String, icon: String, text: String?) -> some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon).font(GlowTheme.caption()).foregroundStyle(GlowTheme.accent)
                if let text {
                    Text(text).font(GlowTheme.body(15)).foregroundStyle(GlowTheme.ink)
                } else {
                    HStack(spacing: 8) {
                        ProgressView().tint(GlowTheme.accent).scaleEffect(0.8)
                        Text("Thinking on-device…").font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                    }
                }
            }
        }
    }

    private func ask() {
        let q = question
        thinking = true; answer = nil
        Task {
            let a = await ai.answer(q, context: ctx)
            answer = a ?? "On-device AI isn't available on this device, but your built-in insights cover the essentials."
            thinking = false
        }
    }
}
