import Foundation

/// Maps a workout to the feel-good neurochemistry it tends to promote, weighted
/// by the user's genetic traits (and, when available, heart-rate intensity as an
/// objective marker from the watch).
///
/// IMPORTANT: This is general wellness education, NOT a measurement of your
/// actual hormone levels and not medical advice. Exercise's effects on mood
/// chemistry are well-documented at the population level; individual response
/// varies. Forge estimates *likely* boosts to help you pick activities.
enum HormoneInsight {

    /// A feel-good chemical exercise can influence.
    enum Chemical: String, CaseIterable, Identifiable {
        case endorphins, dopamine, serotonin, bdnf, cortisolDown, testosterone
        var id: String { rawValue }
        var title: String {
            switch self {
            case .endorphins: return "Endorphins"
            case .dopamine: return "Dopamine"
            case .serotonin: return "Serotonin"
            case .bdnf: return "BDNF"
            case .cortisolDown: return "Lower cortisol"
            case .testosterone: return "Growth / Test."
            }
        }
        var systemImage: String {
            switch self {
            case .endorphins: return "bolt.heart.fill"
            case .dopamine: return "sparkles"
            case .serotonin: return "sun.max.fill"
            case .bdnf: return "brain.head.profile"
            case .cortisolDown: return "wind"
            case .testosterone: return "figure.strengthtraining.traditional"
            }
        }
        var blurb: String {
            switch self {
            case .endorphins: return "The post-workout 'high' — natural pain relief and euphoria."
            case .dopamine: return "Drive, focus, and reward — boosted by intensity and novelty."
            case .serotonin: return "Calm, steady mood — helped by rhythmic movement and daylight."
            case .bdnf: return "Brain-derived growth factor — learning, memory, neuroplasticity."
            case .cortisolDown: return "Lower stress hormone — recovery and parasympathetic tone."
            case .testosterone: return "Anabolic hormones supporting strength and recovery."
            }
        }
    }

    struct Boost: Identifiable {
        let chemical: Chemical
        let strength: Int   // 1...3 (light / solid / strong)
        var id: String { chemical.rawValue }
        var label: String { String(repeating: "●", count: strength) + String(repeating: "○", count: 3 - strength) }
    }

    /// Estimate the feel-good boosts for a routine, tuned by the user's profile.
    /// `peakHeartRate` (optional, from the watch/Health) sharpens the intensity
    /// read: high HR → more adrenaline/dopamine; low steady HR → more serotonin.
    static func boosts(for routine: Routine, profile: UserProfile?, peakHeartRate: Int? = nil) -> [Boost] {
        guard routine.kind == .fitness else { return [] }
        let name = routine.name.lowercased()
        let steps = routine.orderedSteps.map { $0.title.lowercased() }.joined(separator: " ")
        let text = name + " " + steps

        func has(_ ws: String...) -> Bool { ws.contains { text.contains($0) } }

        var score: [Chemical: Int] = [:]
        func add(_ c: Chemical, _ v: Int) { score[c, default: 0] += v }

        // Endurance / zone-2 / engine → endorphins + BDNF + serotonin.
        if has("zone-2", "zone 2", "engine", "run", "row", "bike", "cardio", "conditioning", "walk") {
            add(.endorphins, 2); add(.bdnf, 2); add(.serotonin, 2); add(.cortisolDown, 1)
        }
        // High intensity / metcon / intervals → dopamine + endorphins + adrenaline.
        if has("metcon", "hiit", "interval", "sprint", "burpee", "thruster", "assault") {
            add(.dopamine, 3); add(.endorphins, 2); add(.bdnf, 1)
        }
        // Strength → testosterone / growth hormone + dopamine.
        if has("strength", "squat", "deadlift", "press", "lift", "row", "pull") {
            add(.testosterone, 2); add(.dopamine, 1); add(.endorphins, 1)
        }
        // Mobility / yoga / cooldown / breath → cortisol down + serotonin.
        if has("yoga", "mobility", "stretch", "cooldown", "breath", "warm-up") {
            add(.cortisolDown, 2); add(.serotonin, 1)
        }
        // Default for any fitness session.
        if score.isEmpty { add(.endorphins, 2); add(.dopamine, 1) }

        // --- DNA weighting ---
        if profile?.aerobic == .high {
            // High aerobic responders get a bigger endurance/BDNF payoff.
            if score[.bdnf] != nil { add(.bdnf, 1) }
            if score[.endorphins] != nil { add(.endorphins, 1) }
        }
        if profile?.caffeine == .fast {
            // Fast caffeine clearance pairs well with dopamine-driving intensity.
            if score[.dopamine] != nil { add(.dopamine, 1) }
        }

        // --- Watch heart-rate marker (objective intensity proxy) ---
        if let hr = peakHeartRate {
            if hr >= 150 { add(.dopamine, 1); add(.endorphins, 1) }   // hard effort
            else if hr > 0 && hr < 110 { add(.cortisolDown, 1); add(.serotonin, 1) } // easy/zone-2
        }

        return score
            .map { Boost(chemical: $0.key, strength: min(3, max(1, $0.value))) }
            .sorted { $0.strength > $1.strength }
    }
}
