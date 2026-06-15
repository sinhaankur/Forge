import SwiftUI

/// "How to do it" sheet for a single movement: figure, target muscles,
/// step-by-step form, common mistakes, scaling, and breathing. Lightweight —
/// text + SF Symbols only.
struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let stepTitle: String
    let summary: String

    private var guide: ExerciseGuide.Guide { ExerciseGuide.guide(for: stepTitle) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header: big figure + name + summary.
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(GlowTheme.surfaceHigh).frame(width: 84, height: 84)
                            Image(systemName: ExerciseFigure.symbol(for: stepTitle))
                                .font(.system(size: 40)).foregroundStyle(GlowTheme.accent)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ExerciseGuide.cleaned(stepTitle))
                                .font(.system(size: 24, weight: .heavy)).foregroundStyle(GlowTheme.ink)
                            if !summary.isEmpty {
                                Text(summary).font(GlowTheme.body(14)).foregroundStyle(GlowTheme.inkMuted)
                            }
                        }
                        Spacer(minLength: 0)
                    }

                    chips(guide.targets)

                    section("HOW TO DO IT", icon: "list.number") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(guide.steps.enumerated()), id: \.offset) { i, step in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(i + 1)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.black)
                                        .frame(width: 20, height: 20)
                                        .background(GlowTheme.accentGradient).clipShape(Circle())
                                    Text(step).font(GlowTheme.body(15)).foregroundStyle(GlowTheme.ink)
                                }
                            }
                        }
                    }

                    section("COMMON MISTAKES", icon: "exclamationmark.triangle") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(guide.mistakes, id: \.self) { m in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12)).foregroundStyle(GlowTheme.inkMuted).padding(.top, 2)
                                    Text(m).font(GlowTheme.body(14)).foregroundStyle(GlowTheme.ink)
                                }
                            }
                        }
                    }

                    section("MAKE IT EASIER", icon: "arrow.down.right.circle") {
                        Text(guide.scaling).font(GlowTheme.body(15)).foregroundStyle(GlowTheme.ink)
                    }

                    section("BREATHING", icon: "wind") {
                        Text(guide.breathing).font(GlowTheme.body(15)).foregroundStyle(GlowTheme.ink)
                    }
                }
                .padding(20)
            }
            .background(GlowTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func chips(_ items: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GlowTheme.accent)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(GlowTheme.accent.opacity(0.12)).clipShape(Capsule())
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: icon)
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.accent)
                content()
            }
        }
    }
}
