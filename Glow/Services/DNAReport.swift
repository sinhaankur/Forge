import Foundation

/// The detailed DNA insight engine. Holds Forge's wellness-SNP panel with the
/// science for each, and turns a user's genotypes into rich, honest insight
/// cards: genotype, meaning, effect size, population frequency, confidence,
/// personalized action, and the research note.
///
/// Wellness/education only — never diagnostic. All on-device.
enum DNAReport {

    enum Confidence: String { case established = "Well-established", moderate = "Moderate evidence", preliminary = "Preliminary"
        var systemImage: String {
            switch self {
            case .established: return "checkmark.seal.fill"
            case .moderate: return "checkmark.circle"
            case .preliminary: return "questionmark.circle"
            }
        }
    }

    struct Insight: Identifiable {
        let id = UUID()
        let category: String          // "Fitness", "Nutrition", "Recovery"...
        let gene: String
        let rsid: String
        let title: String
        let genotype: String          // the user's actual call, e.g. "CT"
        let result: String            // interpreted, e.g. "Mixed power/endurance"
        let meaning: String
        let effect: String            // effect-size / how strong
        let frequency: String         // population context
        let action: String            // personalized recommendation
        let confidence: Confidence
        let favorable: Bool
    }

    /// One SNP definition: how to interpret each genotype.
    private struct SNP {
        let gene: String
        let rsid: String
        let category: String
        let title: String
        let confidence: Confidence
        let frequency: String
        /// Given a normalized genotype (e.g. "CT"), return interpretation.
        let interpret: (String) -> (result: String, meaning: String, effect: String, action: String, favorable: Bool)?
    }

    /// The panel of SNPs Forge interprets (the only ones we read/store).
    static let panelRsids: [String] = panel.map { $0.rsid }

    private static let panel: [SNP] = [
        SNP(gene: "ACTN3", rsid: "rs1815739", category: "Fitness",
            title: "Power vs Endurance", confidence: .established,
            frequency: "~18% of people are XX (no α-actinin-3)") { g in
            if g.contains("T") && !g.contains("C") { // TT = XX
                return ("Endurance-leaning", "You lack the fast-twitch α-actinin-3 protein (XX). Muscles favor endurance and efficiency over explosive power.",
                        "Moderate effect on sprint/power performance.",
                        "Lean into endurance & higher-rep work; build power deliberately with progressive overload.", true)
            } else if !g.contains("T") { // CC = RR
                return ("Power-leaning", "You produce α-actinin-3 (RR) — associated with explosive, fast-twitch power.",
                        "Moderate effect favoring sprint/strength.",
                        "You respond well to heavy lifting, sprints, and plyometrics.", true)
            } else { // CT = RX
                return ("Mixed power/endurance", "One copy (RX) — a balanced profile suiting both strength and endurance.",
                        "Intermediate.", "Train both: mix strength and conditioning — you adapt to both.", true)
            }
        },
        SNP(gene: "PPARGC1A", rsid: "rs8192678", category: "Fitness",
            title: "Aerobic Response", confidence: .moderate,
            frequency: "C allele common worldwide") { g in
            g.contains("C") ?
                ("High aerobic response", "C allele supports mitochondrial biogenesis (PGC-1α) — strong endurance-training adaptation.",
                 "Moderate effect on VO₂max trainability.",
                 "Prioritize zone-2 and interval work — your engine adapts well.", true)
              : ("Typical aerobic response", "Standard endurance adaptation.",
                 "Baseline.", "Progressive cardio still builds a strong engine.", true)
        },
        SNP(gene: "CYP1A2", rsid: "rs762551", category: "Nutrition",
            title: "Caffeine Metabolism", confidence: .established,
            frequency: "~40% are fast metabolizers (AA)") { g in
            g.contains("C") ?
                ("Slow metabolizer", "A C allele slows caffeine clearance — it lingers longer.",
                 "Notable: higher doses/late intake affect sleep & may not aid performance.",
                 "Cap caffeine (~200mg) and cut off by early afternoon.", false)
              : ("Fast metabolizer", "AA clears caffeine efficiently.",
                 "Performance benefit from pre-workout caffeine is more likely.",
                 "Black coffee 30–45 min pre-session works well; cycle to keep it effective.", true)
        },
        SNP(gene: "FTO", rsid: "rs9939609", category: "Nutrition",
            title: "Appetite & Carbs", confidence: .established,
            frequency: "~40% carry an A allele") { g in
            g.contains("A") ?
                ("Higher appetite tendency", "A allele links to stronger appetite/satiety signaling and weight response to diet.",
                 "Small per-allele effect on BMI; very modifiable.",
                 "Protein-forward meals, fiber, sleep & steps blunt this strongly.", false)
              : ("Carb-resilient (TT)", "Protective genotype — stable satiety, resilient to complex carbs.",
                 "Lower genetic appetite risk.",
                 "Keep clean carbs around workouts; total calories still matter.", true)
        },
        SNP(gene: "MCM6/LCT", rsid: "rs4988235", category: "Nutrition",
            title: "Lactose", confidence: .established,
            frequency: "Persistence common in N. European ancestry") { g in
            g.contains("T") ?
                ("Lactose tolerant", "T allele keeps lactase active into adulthood.",
                 "Strong, well-characterized effect.",
                 "Dairy & whey are great, bioavailable recovery protein for you.", true)
              : ("May be lactose sensitive (GG)", "Ancestral genotype — lactase often declines after childhood.",
                 "Strong effect, but varies with gut adaptation.",
                 "Try lactose-free dairy, hard cheeses, yogurt, or lactase enzymes.", false)
        },
        SNP(gene: "GC", rsid: "rs2282679", category: "Recovery",
            title: "Vitamin D", confidence: .moderate,
            frequency: "G allele common") { g in
            g.contains("G") ?
                ("Tends to run lower", "G allele lowers vitamin-D binding protein / circulating 25(OH)D.",
                 "Moderate effect on baseline levels.",
                 "Get sun, fatty fish & eggs; test levels and consider D3.", false)
              : ("Typical vitamin D", "No reduced-transport association.",
                 "Baseline.", "Maintain sun + dietary vitamin D.", true)
        },
        SNP(gene: "MTHFR", rsid: "rs1801133", category: "Recovery",
            title: "B-vitamin Methylation", confidence: .moderate,
            frequency: "~T allele in 30–40%") { g in
            g.contains("T") ?
                ("Reduced methylation", "677T lowers MTHFR enzyme activity — folate processing is less efficient.",
                 "Modest; fully diet-modifiable.",
                 "Favor leafy greens (folate) + B12; methylated forms may suit you. Limit alcohol.", false)
              : ("Efficient methylation (CC)", "Full MTHFR activity.",
                 "Baseline.", "Maintain folate/B12 intake; vegans still supplement B12.", true)
        },
        SNP(gene: "IL6", rsid: "rs1800795", category: "Recovery",
            title: "Inflammation / Recovery", confidence: .preliminary,
            frequency: "G/C alleles both common") { g in
            g.contains("C") ?
                ("Higher inflammatory tendency", "C allele linked to higher IL-6 inflammatory signaling in some studies.",
                 "Preliminary; mixed evidence.",
                 "Respect recovery: sleep, easy days, omega-3s, manage training load.", false)
              : ("Typical inflammatory response", "Baseline IL-6 profile.",
                 "Preliminary.", "Standard recovery practices apply.", true)
        },
        SNP(gene: "COL1A1", rsid: "rs1800012", category: "Injury",
            title: "Connective Tissue", confidence: .preliminary,
            frequency: "T allele protective, less common") { g in
            g.contains("T") ?
                ("More resilient tissue", "T allele associated with stronger collagen / lower soft-tissue injury risk.",
                 "Preliminary.", "Still warm up & progress load gradually.", true)
              : ("Typical tissue (GG)", "Common genotype; no protective variant.",
                 "Preliminary.", "Prioritize warm-ups, mobility & gradual loading to protect joints/tendons.", false)
        },
        SNP(gene: "TAS1R2", rsid: "rs35874116", category: "Nutrition",
            title: "Sweet Preference", confidence: .preliminary,
            frequency: "varies") { g in
            ("Sweet-taste profile", "Variation here is linked to sugar preference/intake.",
             "Preliminary.", "Be mindful of liquid sugars; build meals around protein & fiber.", true)
        },
    ]

    /// Parse a stored panel CSV ("rsid:GT,rsid:GT") into insights.
    static func insights(fromPanelCSV csv: String) -> [Insight] {
        let map = Dictionary(uniqueKeysWithValues: csv
            .split(separator: ",")
            .compactMap { pair -> (String, String)? in
                let kv = pair.split(separator: ":")
                guard kv.count == 2 else { return nil }
                return (String(kv[0]), String(kv[1]).uppercased())
            })
        return panel.compactMap { snp in
            guard let gt = map[snp.rsid], let i = snp.interpret(gt) else { return nil }
            return Insight(category: snp.category, gene: snp.gene, rsid: snp.rsid,
                           title: snp.title, genotype: gt, result: i.result, meaning: i.meaning,
                           effect: i.effect, frequency: snp.frequency, action: i.action,
                           confidence: snp.confidence, favorable: i.favorable)
        }
    }
}
