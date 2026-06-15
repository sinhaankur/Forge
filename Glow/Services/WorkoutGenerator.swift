import Foundation
import SwiftData

/// Builds a personalized weekly CrossFit-style schedule entirely on-device
/// (privacy-first — no network). Rules consider the user's body metrics,
/// experience, and goal (body recomposition), exclude movements contraindicated
/// by injuries, and ALWAYS prepend a warm-up to every session.
enum WorkoutGenerator {

    typealias Theme = ExerciseLibrary.Theme

    /// Generate `profile.daysPerWeek` CrossFit routines and insert them into the
    /// store. Existing generated routines (kind fitness with the marker note)
    /// are removed first so re-generating is idempotent.
    static func generate(for profile: UserProfile, in context: ModelContext) {
        let injuries = Set(profile.injuries)
        let marker = "Generated CrossFit"

        // Clear previously generated routines.
        let existing = (try? context.fetch(FetchDescriptor<Routine>())) ?? []
        for r in existing where r.notes.hasPrefix(marker) { context.delete(r) }

        let days = max(1, min(7, profile.daysPerWeek))
        // Spread across the week (e.g. 4 days -> Mon/Tue/Thu/Fri-ish).
        let weekdayPlan = distribute(days: days)
        // Theme rotation is tuned to the user's aerobic response (from genetics).
        let themes = themeRotation(for: profile)

        // Optional pre-workout note for fast caffeine metabolizers.
        let caffeineNote = profile.caffeine == .fast
            ? " Pre-workout: a black coffee ~30–45 min before works well for you (fast caffeine metabolizer)."
            : ""

        for i in 0..<days {
            let theme = themes[i % themes.count]
            let weekday = weekdayPlan[i]

            let routine = Routine(
                name: "Forge · \(theme.rawValue)",
                kind: .fitness,
                timeOfDay: .morning,
                notes: "\(marker) for \(profile.bodyShape.title), BMI \(String(format: "%.0f", profile.bmi)). Warm-up included.\(caffeineNote)",
                colorHex: "#FF7E5F",
                activeWeekdays: [weekday],
                reminderMinutes: 7 * 60,
                targetMetric: targetMetric(for: theme),
                targetValue: targetValue(for: theme, profile: profile)
            )
            context.insert(routine)

            var order = 0
            // 1) Mandatory, structured warm-up (Raise → Mobilize → Activate → Potentiate).
            for (phase, drill) in ExerciseLibrary.warmupRoutine(injuries: injuries) {
                let step = RoutineStep(
                    title: "🔥 \(phase.rawValue): \(drill.title)",
                    detail: drill.cue,
                    order: order, reps: drill.reps, durationSeconds: drill.seconds
                )
                step.routine = routine; routine.steps.append(step); order += 1
            }
            // 2) Main work, screened against injuries, with cue + scaling + tempo/rest.
            var safe = ExerciseLibrary.safeMovements(theme: theme, injuries: injuries)
            if safe.isEmpty { // injuries removed everything for this theme — fall back to engine.
                safe = ExerciseLibrary.safeMovements(theme: .engine, injuries: injuries)
            }
            for m in safe {
                var detail = m.cue
                if let tempo = m.tempo { detail += " · Tempo \(tempo)" }
                if m.restSeconds > 0 { detail += " · Rest \(m.restSeconds)s" }
                detail += " · Scale: \(m.scaling)"
                let step = RoutineStep(title: m.title, detail: detail,
                                       order: order, sets: m.sets, reps: m.reps, durationSeconds: m.seconds)
                step.routine = routine; routine.steps.append(step); order += 1
            }
            // 3) Cooldown.
            let cool = RoutineStep(title: "Cooldown: Walk + Stretch",
                                   detail: "5 min easy walk, then stretch the day's prime movers.",
                                   order: order, durationSeconds: 300)
            cool.routine = routine; routine.steps.append(cool)
        }
        try? context.save()
    }

    /// Order the weekly themes based on the user's aerobic genetics.
    /// High aerobic response → a hybrid that leans into engine / zone-2 work
    /// alongside strength (their muscles adapt well to oxygen-demanding training).
    private static func themeRotation(for profile: UserProfile) -> [Theme] {
        switch profile.aerobic {
        case .high:
            // Strength + lots of engine, interleaved with metcon/gymnastics.
            return [.strength, .engine, .metcon, .engine, .gymnastics, .fullBody]
        case .normal, .unknown:
            return [.strength, .metcon, .gymnastics, .engine, .fullBody]
        }
    }

    private static func targetMetric(for theme: Theme) -> TargetMetric {
        switch theme {
        case .strength: return .weightKg
        case .metcon, .gymnastics, .fullBody: return .reps
        case .engine: return .calories
        }
    }

    /// Scale the session target by experience and bodyweight where relevant.
    private static func targetValue(for theme: Theme, profile: UserProfile) -> Double {
        let rounds = Double(profile.experience.rounds)
        switch theme {
        case .strength: return (profile.weightKg * 0.6).rounded() // suggested working load
        case .metcon, .gymnastics, .fullBody: return rounds * 40
        case .engine: return rounds * 80 // approx kcal
        }
    }

    /// Pick weekdays (1=Sun..7=Sat) spread through the week with rest gaps.
    private static func distribute(days: Int) -> [Int] {
        switch days {
        case 1: return [2]
        case 2: return [2, 5]
        case 3: return [2, 4, 6]
        case 4: return [2, 3, 5, 6]
        case 5: return [2, 3, 4, 6, 7]
        case 6: return [2, 3, 4, 5, 6, 7]
        default: return Array(1...7)
        }
    }
}
