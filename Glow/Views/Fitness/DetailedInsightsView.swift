import SwiftUI

/// Detailed DNA insights — rich cards grouped by category (Fitness, Nutrition,
/// Recovery, Injury), each with genotype, meaning, effect size, frequency,
/// confidence, and a personalized action. Plus a category visualization.
struct DetailedInsightsView: View {
    let insights: [DNAReport.Insight]

    private var byCategory: [(String, [DNAReport.Insight])] {
        let order = ["Fitness", "Nutrition", "Recovery", "Injury"]
        let grouped = Dictionary(grouping: insights, by: \.category)
        return order.compactMap { c in grouped[c].map { (c, $0) } }
            + grouped.keys.filter { !order.contains($0) }.sorted().compactMap { c in grouped[c].map { (c, $0) } }
    }

    var body: some View {
        if insights.isEmpty {
            GlowPanel {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No detailed markers yet").font(GlowTheme.headline()).foregroundStyle(GlowTheme.ink)
                    Text("Re-import your DNA file to read Forge's full wellness-SNP panel for detailed insights.")
                        .font(GlowTheme.body(14)).foregroundStyle(GlowTheme.inkMuted)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                categoryViz
                ForEach(byCategory, id: \.0) { category, items in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(category.uppercased())
                            .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                        ForEach(items) { InsightCard(insight: $0) }
                    }
                }
            }
        }
    }

    /// A compact bar showing how many markers per category — a quick visual map.
    private var categoryViz: some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label("MARKERS READ: \(insights.count)", systemImage: "dna")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.accent)
                ForEach(byCategory, id: \.0) { category, items in
                    HStack(spacing: 10) {
                        Text(category).font(GlowTheme.body(13)).foregroundStyle(GlowTheme.ink).frame(width: 78, alignment: .leading)
                        GeometryReader { geo in
                            let favorable = items.filter { $0.favorable }.count
                            HStack(spacing: 3) {
                                ForEach(0..<items.count, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(i < favorable ? AnyShapeStyle(GlowTheme.accentGradient) : AnyShapeStyle(GlowTheme.faint))
                                }
                            }
                            .frame(width: geo.size.width)
                        }.frame(height: 10)
                        Text("\(items.count)").font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                    }
                }
            }
        }
    }
}

private struct InsightCard: View {
    let insight: DNAReport.Insight
    @State private var expanded = false

    var body: some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title).font(.system(size: 16, weight: .bold)).foregroundStyle(GlowTheme.ink)
                        Text(insight.result)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(insight.favorable ? GlowTheme.accent : GlowTheme.ink)
                    }
                    Spacer()
                    // Genotype pill.
                    Text(insight.genotype)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(GlowTheme.accent)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(GlowTheme.accent.opacity(0.12)).clipShape(Capsule())
                }

                // Gene · rsid · confidence chips.
                HStack(spacing: 6) {
                    chip(insight.gene, icon: "dna")
                    chip(insight.rsid, icon: "number")
                    chip(insight.confidence.rawValue, icon: insight.confidence.systemImage)
                }

                Text(insight.meaning).font(GlowTheme.body(14)).foregroundStyle(GlowTheme.ink)

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "arrow.turn.down.right").font(.system(size: 11)).foregroundStyle(GlowTheme.accent)
                    Text(insight.action).font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                }

                Button { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } } label: {
                    Text(expanded ? "Less" : "Effect size & frequency")
                        .font(GlowTheme.caption()).foregroundStyle(GlowTheme.accent)
                }.buttonStyle(.plain)
                if expanded {
                    VStack(alignment: .leading, spacing: 4) {
                        detailRow("Effect", insight.effect)
                        detailRow("Population", insight.frequency)
                        Text("Wellness insight, not diagnostic.")
                            .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                    }
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(GlowTheme.surfaceHigh).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private func detailRow(_ k: String, _ v: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(k).font(.system(size: 11, weight: .bold)).foregroundStyle(GlowTheme.inkMuted).frame(width: 70, alignment: .leading)
            Text(v).font(GlowTheme.caption()).foregroundStyle(GlowTheme.ink)
        }
    }
    private func chip(_ t: String, icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9, weight: .bold))
            Text(t).font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(GlowTheme.inkMuted)
        .padding(.horizontal, 7).padding(.vertical, 4)
        .background(GlowTheme.surfaceHigh).clipShape(Capsule())
    }
}
