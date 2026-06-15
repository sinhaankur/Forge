import SwiftUI
import SwiftData

/// "Your DNA" — visualizes the trait categories derived from the user's DNA
/// file as insight cards. Shows the result, a plain-English meaning, and how
/// Forge uses it. Never displays raw genotypes; reads only the on-device
/// trait fields on the profile.
struct DNAInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    enum Mode: String, CaseIterable, Identifiable {
        case cards = "Cards"
        case detailed = "Detailed"
        case radar = "Radar"
        case genome = "Genome"
        var id: String { rawValue }
    }
    @State private var mode: Mode = .cards

    private var detailedInsights: [DNAReport.Insight] {
        guard let csv = profile?.dnaPanel, !csv.isEmpty else { return [] }
        return DNAReport.insights(fromPanelCSV: csv)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    Picker("View", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    if let cards = insightCards, !cards.isEmpty {
                        switch mode {
                        case .cards:
                            ForEach(cards) { card in DNACard(card: card) }
                        case .detailed:
                            DetailedInsightsView(insights: detailedInsights)
                        case .radar:
                            RadarChartView(scores: radarScores)
                        case .genome:
                            GenomeMapView(markers: genomeMarkers)
                        }
                    } else {
                        emptyState
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Derived on this device from your DNA file. Raw genetic data is never stored or uploaded.",
                              systemImage: "lock.shield.fill")
                        Label("Wellness insights only — not medical or diagnostic advice. Genes are predispositions, not destiny. Talk to a professional before major changes.",
                              systemImage: "stethoscope")
                    }
                    .font(GlowTheme.caption())
                    .foregroundStyle(GlowTheme.inkMuted)
                    .padding(.top, 4)
                }
                .padding(20)
            }
            .background(GlowTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("YOUR DNA")
                .font(GlowTheme.display(38))
                .foregroundStyle(GlowTheme.ink)
            Text("How your genetics shape your Forge plan")
                .font(GlowTheme.body(15))
                .foregroundStyle(GlowTheme.inkMuted)
        }
    }

    private var emptyState: some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 8) {
                Text("No DNA traits set yet")
                    .font(GlowTheme.headline()).foregroundStyle(GlowTheme.ink)
                Text("In your profile, tap “Upload DNA / CSV file” to read your markers, or set them manually.")
                    .font(GlowTheme.body(14)).foregroundStyle(GlowTheme.inkMuted)
            }
        }
    }

    struct Card: Identifiable {
        let id = UUID()
        let emoji: String
        let title: String
        let result: String
        let meaning: String
        let usedFor: String
        let lifestyle: String   // how lifestyle can change/express this trait
        let gene: String        // e.g. "PPARGC1A"
        let snp: String         // e.g. "rs8192678"
        let determination: String // how the genotype maps to the result
        let isStrength: Bool    // highlight (accent) vs neutral
    }

    /// Normalized 0...1 scores for the radar chart (favorable trait = higher).
    private var radarScores: [(label: String, value: Double)] {
        guard let p = profile else { return [] }
        func score(_ on: Bool?, neutral: Double = 0.5) -> Double {
            guard let on else { return neutral }
            return on ? 1.0 : 0.4
        }
        return [
            ("Aerobic", p.aerobic == .unknown ? 0.5 : (p.aerobic == .high ? 1.0 : 0.5)),
            ("Caffeine", p.caffeine == .unknown ? 0.5 : (p.caffeine == .fast ? 1.0 : 0.4)),
            ("Carbs", p.carb == .unknown ? 0.5 : (p.carb == .resilient ? 1.0 : 0.4)),
            ("Dairy", score(p.lactoseTolerant)),
            ("Vit D", p.vitaminD == .unknown ? 0.5 : (p.vitaminD == .normal ? 1.0 : 0.4)),
            ("B12", p.b12 == .unknown ? 0.5 : (p.b12 == .efficient ? 1.0 : 0.4)),
        ]
    }

    /// Markers placed on a simplified genome map (chromosome + relative position).
    private var genomeMarkers: [GenomeMapView.Marker] {
        guard profile != nil else { return [] }
        // Chromosome + approximate fractional position for the 6 analyzed SNPs.
        return [
            .init(label: "PPARGC1A", chromosome: 4, pos: 0.55, trait: "Aerobic"),
            .init(label: "CYP1A2", chromosome: 15, pos: 0.62, trait: "Caffeine"),
            .init(label: "FTO", chromosome: 16, pos: 0.48, trait: "Carbs"),
            .init(label: "MCM6", chromosome: 2, pos: 0.60, trait: "Lactose"),
            .init(label: "GC", chromosome: 4, pos: 0.30, trait: "Vitamin D"),
            .init(label: "MTHFR", chromosome: 1, pos: 0.08, trait: "B12"),
        ]
    }

    private var insightCards: [Card]? {
        guard let p = profile else { return nil }
        var cards: [Card] = []

        switch p.aerobic {
        case .high:
            cards.append(Card(emoji: "⭐️", title: "Aerobic Response", result: "HIGH",
                meaning: "Your muscles adapt well to oxygen-demanding training.",
                usedFor: "Your plan leans into zone-2 cardio + engine work.",
                lifestyle: "This is a ceiling, not a guarantee — consistent zone-2 + interval training is what actually builds the mitochondria. Detraining reverses it within weeks.",
                gene: "PPARGC1A", snp: "rs8192678",
                determination: "PPARGC1A makes PGC-1α, the master switch for building mitochondria. The C allele (Gly482) is linked to a higher aerobic-training response. You carry C → HIGH.",
                isStrength: true))
        case .normal:
            cards.append(Card(emoji: "🫀", title: "Aerobic Response", result: "Normal",
                meaning: "Standard cardiovascular adaptation.",
                usedFor: "Balanced strength + conditioning mix.",
                lifestyle: "Genetics set a smaller head start here — but trainable. Progressive cardio still drives big VO₂max gains regardless of genotype.",
                gene: "PPARGC1A", snp: "rs8192678",
                determination: "The A/Ser482 variant is associated with a more typical aerobic-training response. Your genotype lacks the favorable C → Normal.",
                isStrength: false))
        case .unknown: break
        }

        switch p.caffeine {
        case .fast:
            cards.append(Card(emoji: "☕️", title: "Caffeine", result: "FAST metabolizer",
                meaning: "Your liver clears caffeine efficiently.",
                usedFor: "Coffee 30–45 min pre-workout for a clean boost.",
                lifestyle: "Tolerance still builds with daily use — cycle caffeine to keep the pre-workout effect sharp. Heavy late-day intake can still cost sleep.",
                gene: "CYP1A2", snp: "rs762551",
                determination: "CYP1A2 is the liver enzyme that breaks down caffeine. The AA genotype = the fast-metabolizer form. You're AA → FAST.",
                isStrength: true))
        case .slow:
            cards.append(Card(emoji: "☕️", title: "Caffeine", result: "Slow metabolizer",
                meaning: "Caffeine lingers longer in your system.",
                usedFor: "Keep caffeine earlier in the day to protect sleep.",
                lifestyle: "Capping intake (~200mg) and a midday cutoff largely offsets this — behavior matters more than the gene here.",
                gene: "CYP1A2", snp: "rs762551",
                determination: "Carrying a C allele slows the CYP1A2 enzyme, so caffeine clears more slowly. You carry C → Slow.",
                isStrength: false))
        case .unknown: break
        }

        switch p.carb {
        case .resilient:
            cards.append(Card(emoji: "🍞", title: "Carb Response", result: "RESILIENT",
                meaning: "You process complex carbs well; stable satiety.",
                usedFor: "Clean carbs around your workout windows.",
                lifestyle: "Resilience isn't a free pass — total calories and food quality still drive body composition. Pair carbs with protein/fiber.",
                gene: "FTO", snp: "rs9939609",
                determination: "FTO influences appetite/satiety signaling. The A allele is the higher-appetite risk variant; the TT genotype is protective. You're TT → Resilient.",
                isStrength: true))
        case .sensitive:
            cards.append(Card(emoji: "🍞", title: "Carb Response", result: "Carb-sensitive",
                meaning: "Appetite/weight may respond more to carbs.",
                usedFor: "Favor protein + fiber; mind portions.",
                lifestyle: "Highly modifiable: sleep, steps, and protein-forward meals blunt this effect substantially. The gene nudges, it doesn't decide.",
                gene: "FTO", snp: "rs9939609",
                determination: "You carry the FTO A allele, linked to stronger appetite drive and weight response to diet → Carb-sensitive.",
                isStrength: false))
        case .unknown: break
        }

        cards.append(Card(emoji: "🥛", title: "Lactose",
            result: p.lactoseTolerant ? "Tolerant" : "May be sensitive",
            meaning: p.lactoseTolerant ? "You produce lactase into adulthood."
                                       : "Dairy may cause digestive issues.",
            usedFor: p.lactoseTolerant ? "Dairy/whey are great recovery protein."
                                       : "Lean on non-dairy protein sources.",
            lifestyle: p.lactoseTolerant ? "Tolerance can still drift with gut health — fermented dairy (yogurt, kefir) is easiest to digest."
                                         : "Lactase enzymes, lactose-free dairy, or hard cheeses/yogurt often let you include dairy comfortably.",
            gene: "MCM6 / LCT", snp: "rs4988235",
            determination: p.lactoseTolerant
                ? "The T allele keeps the lactase (LCT) gene switched on into adulthood (lactase persistence). You carry T → Tolerant."
                : "The GG genotype is the ancestral form where lactase switches off after weaning → may be sensitive.",
            isStrength: p.lactoseTolerant))

        if p.vitaminD != .unknown {
            cards.append(Card(emoji: "☀️", title: "Vitamin D",
                result: p.vitaminD == .lower ? "Tends to run low" : "Normal",
                meaning: p.vitaminD == .lower ? "Lower circulating vitamin D."
                                              : "Typical vitamin D levels.",
                usedFor: p.vitaminD == .lower ? "Prioritize sun, fatty fish, eggs; consider testing."
                                              : "Maintain with sun + diet.",
                lifestyle: p.vitaminD == .lower ? "Very modifiable: sensible sun exposure and/or D3 supplementation reliably normalize levels. Test, don't guess."
                                                : "Keep regular sun + dietary D; levels can still drop in winter or with indoor lifestyles.",
                gene: "GC (VDBP)", snp: "rs2282679",
                determination: p.vitaminD == .lower
                    ? "GC encodes the vitamin-D binding protein. The G allele is linked to lower circulating 25(OH)D. You carry G → tends low."
                    : "Your GC genotype isn't associated with reduced vitamin-D transport → Normal.",
                isStrength: p.vitaminD != .lower))
        }

        if p.b12 != .unknown {
            cards.append(Card(emoji: "🧪", title: "B12 / Methylation",
                result: p.b12 == .reduced ? "Reduced" : "Efficient",
                meaning: p.b12 == .reduced ? "Slightly reduced methylation efficiency."
                                           : "Efficient B12/folate processing.",
                usedFor: p.b12 == .reduced ? "Favor B12/folate-rich foods; methylated forms."
                                           : "No special action needed.",
                lifestyle: p.b12 == .reduced ? "Diet fully compensates: leafy greens (folate) + eggs/dairy/meat (B12), or methylfolate/methyl-B12 forms. Alcohol depletes both."
                                             : "Maintain B12/folate intake; vegans of any genotype should still supplement B12.",
                gene: "MTHFR", snp: "rs1801133",
                determination: p.b12 == .reduced
                    ? "MTHFR processes folate for methylation. The T (677T) allele lowers enzyme activity. You carry T → Reduced."
                    : "The CC genotype keeps MTHFR at full activity → Efficient methylation.",
                isStrength: p.b12 != .reduced))
        }

        return cards
    }
}

/// A radar/spider chart of the genetic trait scores.
struct RadarChartView: View {
    let scores: [(label: String, value: Double)]

    var body: some View {
        GlowPanel {
            VStack(spacing: 12) {
                Text("GENETIC PROFILE")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Canvas { ctx, size in
                    let n = scores.count
                    guard n >= 3 else { return }
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = min(size.width, size.height) / 2 - 28
                    func point(_ i: Int, _ r: Double) -> CGPoint {
                        let angle = (Double(i) / Double(n)) * 2 * .pi - .pi / 2
                        return CGPoint(x: center.x + cos(angle) * radius * r,
                                       y: center.y + sin(angle) * radius * r)
                    }
                    // Grid rings.
                    for ring in [0.25, 0.5, 0.75, 1.0] {
                        var path = Path()
                        for i in 0..<n {
                            let p = point(i, ring)
                            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                        }
                        path.closeSubpath()
                        ctx.stroke(path, with: .color(GlowTheme.faint), lineWidth: 1)
                    }
                    // Spokes + labels.
                    for i in 0..<n {
                        var spoke = Path()
                        spoke.move(to: center); spoke.addLine(to: point(i, 1.0))
                        ctx.stroke(spoke, with: .color(GlowTheme.faint), lineWidth: 1)
                        let labelPt = point(i, 1.18)
                        ctx.draw(Text(scores[i].label).font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted),
                                 at: labelPt)
                    }
                    // Data polygon.
                    var data = Path()
                    for i in 0..<n {
                        let p = point(i, max(0.05, scores[i].value))
                        if i == 0 { data.move(to: p) } else { data.addLine(to: p) }
                    }
                    data.closeSubpath()
                    ctx.fill(data, with: .color(GlowTheme.accent.opacity(0.25)))
                    ctx.stroke(data, with: .color(GlowTheme.accent), lineWidth: 2)
                    for i in 0..<n {
                        let p = point(i, max(0.05, scores[i].value))
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)),
                                 with: .color(GlowTheme.accent))
                    }
                }
                .frame(height: 280)
                Text("Larger shape = more performance-favorable trait baseline.")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
            }
        }
    }
}

/// A simplified genome map: chromosomes as bars with analyzed SNPs marked.
struct GenomeMapView: View {
    struct Marker: Identifiable {
        let id = UUID()
        let label: String
        let chromosome: Int
        let pos: Double      // 0...1 along the chromosome
        let trait: String
    }
    let markers: [Marker]

    private var chromosomes: [Int] { Array(Set(markers.map(\.chromosome))).sorted() }

    var body: some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 14) {
                Text("GENOME MAP")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                Text("Marker positions are approximate (illustrative, not to scale).")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                Text("Origin note: these variants arose across human populations — e.g. lactase persistence (MCM6) spread with dairy-herding cultures, and FTO/CYP1A2 frequencies vary by ancestry. Your traits reflect that shared heritage, not a single origin.")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                ForEach(chromosomes, id: \.self) { chr in
                    let onChr = markers.filter { $0.chromosome == chr }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("chr \(chr)")
                            .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(GlowTheme.faint).frame(height: 8)
                                ForEach(onChr) { m in
                                    Circle().fill(GlowTheme.accentGradient)
                                        .frame(width: 12, height: 12)
                                        .offset(x: geo.size.width * m.pos - 6)
                                }
                            }
                        }
                        .frame(height: 14)
                        ForEach(onChr) { m in
                            Text("● \(m.label) — \(m.trait)")
                                .font(GlowTheme.caption()).foregroundStyle(GlowTheme.ink)
                        }
                    }
                }
            }
        }
    }
}

private struct DNACard: View {
    let card: DNAInsightsView.Card
    @State private var showScience = false

    var body: some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(card.emoji).font(.system(size: 22))
                    Text(card.title.uppercased())
                        .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                    Spacer()
                    Text(card.result)
                        .font(GlowTheme.headline(15))
                        .foregroundStyle(card.isStrength ? GlowTheme.accent : GlowTheme.ink)
                }
                Text(card.meaning)
                    .font(GlowTheme.body(15)).foregroundStyle(GlowTheme.ink)

                // Gene · SNP chips — the "what determines this".
                HStack(spacing: 6) {
                    chip(card.gene, icon: "dna")
                    chip(card.snp, icon: "number")
                }

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.system(size: 11)).foregroundStyle(GlowTheme.accent)
                    Text(card.usedFor)
                        .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                }

                Divider().overlay(GlowTheme.faint)
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "figure.walk.motion")
                        .font(.system(size: 11)).foregroundStyle(GlowTheme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WHAT YOU CAN CHANGE")
                            .font(GlowTheme.caption()).foregroundStyle(GlowTheme.accent)
                        Text(card.lifestyle)
                            .font(GlowTheme.body(13)).foregroundStyle(GlowTheme.ink)
                    }
                }

                // Expandable "how this is determined".
                Button { withAnimation(.easeInOut(duration: 0.2)) { showScience.toggle() } } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showScience ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(showScience ? "Hide the science" : "How is this determined?")
                            .font(GlowTheme.caption())
                    }
                    .foregroundStyle(GlowTheme.accent)
                }
                .buttonStyle(.plain)
                if showScience {
                    Text(card.determination)
                        .font(GlowTheme.body(13))
                        .foregroundStyle(GlowTheme.inkMuted)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(GlowTheme.surfaceHigh)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private func chip(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9, weight: .bold))
            Text(text).font(.system(size: 11, weight: .semibold, design: .monospaced))
        }
        .foregroundStyle(GlowTheme.accent)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(GlowTheme.accent.opacity(0.12))
        .clipShape(Capsule())
    }
}
