import Foundation
import SwiftData

// MARK: - Enums

/// Which pillar of the app a routine belongs to.
enum RoutineKind: String, Codable, CaseIterable, Identifiable {
    case fitness
    case skincare

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fitness: return "Fitness"
        case .skincare: return "Skincare"
        }
    }

    var systemImage: String {
        switch self {
        case .fitness: return "figure.strengthtraining.traditional"
        case .skincare: return "drop.fill"
        }
    }
}

/// When a routine is meant to be performed. Used for grouping and reminders.
enum TimeOfDay: String, Codable, CaseIterable, Identifiable {
    case morning, afternoon, evening, anytime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .anytime: return "Anytime"
        }
    }

    var systemImage: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        case .anytime: return "clock.fill"
        }
    }
}

/// The metric a workout target is measured in.
enum TargetMetric: String, Codable, CaseIterable, Identifiable {
    case reps          // total reps across the session
    case weightKg      // working weight in kilograms
    case durationMin   // minutes of activity
    case distanceKm    // distance in kilometers
    case calories      // active calories burned

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reps: return "Reps"
        case .weightKg: return "Weight"
        case .durationMin: return "Duration"
        case .distanceKm: return "Distance"
        case .calories: return "Calories"
        }
    }

    var unit: String {
        switch self {
        case .reps: return "reps"
        case .weightKg: return "kg"
        case .durationMin: return "min"
        case .distanceKm: return "km"
        case .calories: return "kcal"
        }
    }

    var systemImage: String {
        switch self {
        case .reps: return "repeat"
        case .weightKg: return "dumbbell.fill"
        case .durationMin: return "timer"
        case .distanceKm: return "figure.run"
        case .calories: return "flame.fill"
        }
    }
}

// MARK: - Routine

/// A routine groups an ordered list of steps the user performs together,
/// and (for fitness) an optional measurable target for the session.
@Model
final class Routine {
    var name: String
    var kindRaw: String
    var timeOfDayRaw: String
    var notes: String
    var colorHex: String
    /// Weekdays (1 = Sunday ... 7 = Saturday) on which this routine is active.
    var activeWeekdays: [Int]
    /// Reminder time stored as minutes since midnight. nil = no reminder.
    var reminderMinutes: Int?
    var createdAt: Date

    // --- Fitness target for the session (nil metric = no target set) ---
    var targetMetricRaw: String?
    var targetValue: Double

    @Relationship(deleteRule: .cascade, inverse: \RoutineStep.routine)
    var steps: [RoutineStep]

    @Relationship(deleteRule: .cascade, inverse: \RoutineCompletion.routine)
    var completions: [RoutineCompletion]

    init(
        name: String,
        kind: RoutineKind,
        timeOfDay: TimeOfDay = .anytime,
        notes: String = "",
        colorHex: String = "#FF7E5F",
        activeWeekdays: [Int] = Array(1...7),
        reminderMinutes: Int? = nil,
        targetMetric: TargetMetric? = nil,
        targetValue: Double = 0
    ) {
        self.name = name
        self.kindRaw = kind.rawValue
        self.timeOfDayRaw = timeOfDay.rawValue
        self.notes = notes
        self.colorHex = colorHex
        self.activeWeekdays = activeWeekdays
        self.reminderMinutes = reminderMinutes
        self.targetMetricRaw = targetMetric?.rawValue
        self.targetValue = targetValue
        self.createdAt = .now
        self.steps = []
        self.completions = []
    }

    var kind: RoutineKind {
        get { RoutineKind(rawValue: kindRaw) ?? .fitness }
        set { kindRaw = newValue.rawValue }
    }

    var timeOfDay: TimeOfDay {
        get { TimeOfDay(rawValue: timeOfDayRaw) ?? .anytime }
        set { timeOfDayRaw = newValue.rawValue }
    }

    var targetMetric: TargetMetric? {
        get { targetMetricRaw.flatMap(TargetMetric.init(rawValue:)) }
        set { targetMetricRaw = newValue?.rawValue }
    }

    var hasTarget: Bool { targetMetric != nil && targetValue > 0 }

    var orderedSteps: [RoutineStep] {
        steps.sorted { $0.order < $1.order }
    }

    func isActive(on date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return activeWeekdays.contains(weekday)
    }

    /// A short human-readable description of the session target, if any.
    var targetSummary: String? {
        guard let metric = targetMetric, targetValue > 0 else { return nil }
        let value = targetValue.rounded() == targetValue
            ? String(Int(targetValue))
            : String(format: "%.1f", targetValue)
        return "\(value) \(metric.unit)"
    }
}

/// A single step within a routine.
/// For fitness this is an exercise (sets/reps/duration); for skincare a product/action.
@Model
final class RoutineStep {
    var title: String
    var detail: String
    var order: Int

    // Fitness-oriented fields (zero for skincare).
    var sets: Int
    var reps: Int
    var durationSeconds: Int

    var routine: Routine?

    init(
        title: String,
        detail: String = "",
        order: Int = 0,
        sets: Int = 0,
        reps: Int = 0,
        durationSeconds: Int = 0
    ) {
        self.title = title
        self.detail = detail
        self.order = order
        self.sets = sets
        self.reps = reps
        self.durationSeconds = durationSeconds
    }

    var summary: String {
        var parts: [String] = []
        if sets > 0 && reps > 0 {
            parts.append("\(sets) × \(reps)")
        } else if reps > 0 {
            parts.append("\(reps) reps")
        }
        if durationSeconds > 0 {
            parts.append(durationSeconds >= 60 ? "\(durationSeconds / 60)m \(durationSeconds % 60)s" : "\(durationSeconds)s")
        }
        if parts.isEmpty && !detail.isEmpty { return detail }
        return parts.joined(separator: " · ")
    }
}

/// A logged completion of a routine on a particular day, recording how the
/// user did against the routine's target (if there was one).
@Model
final class RoutineCompletion {
    var date: Date
    /// Normalized to start of day for streak/grouping queries.
    var dayStart: Date
    /// The value the user actually achieved for the routine's target metric.
    var achievedValue: Double
    var routine: Routine?

    init(date: Date = .now, achievedValue: Double = 0, routine: Routine? = nil) {
        self.date = date
        self.dayStart = Calendar.current.startOfDay(for: date)
        self.achievedValue = achievedValue
        self.routine = routine
    }

    /// Whether the achieved value met or exceeded the routine's target.
    var metTarget: Bool {
        guard let routine, routine.hasTarget else { return true }
        return achievedValue >= routine.targetValue
    }
}

// MARK: - User Profile (for personalized CrossFit generation)

enum BodyShape: String, Codable, CaseIterable, Identifiable {
    case ectomorph   // lean, hard to gain
    case mesomorph   // muscular, athletic
    case endomorph   // softer, gains/holds fat easily

    var id: String { rawValue }
    var title: String {
        switch self {
        case .ectomorph: return "Ectomorph (lean)"
        case .mesomorph: return "Mesomorph (athletic)"
        case .endomorph: return "Endomorph (softer build)"
        }
    }
}

enum ExperienceLevel: String, Codable, CaseIterable, Identifiable {
    case beginner, intermediate, advanced
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    /// Scales rounds/intensity in generated workouts.
    var rounds: Int {
        switch self {
        case .beginner: return 3
        case .intermediate: return 4
        case .advanced: return 5
        }
    }
}

/// Body regions a user may need to protect. Used to filter movements.
enum InjuryArea: String, Codable, CaseIterable, Identifiable {
    case shoulder, lowerBack, knee, wrist, elbow, ankle, hip, neck
    var id: String { rawValue }
    var title: String {
        switch self {
        case .lowerBack: return "Lower Back"
        default: return rawValue.capitalized
        }
    }
}

/// Optional genetic-trait categories the user can set from their own DNA report.
/// These are coarse trait buckets — NOT raw genotypes — and are stored only on
/// device. They let the plan adapt (e.g. more aerobic work, dairy-friendly
/// protein) without the app ever holding identifying genetic data.
enum AerobicResponse: String, Codable, CaseIterable, Identifiable {
    case unknown, normal, high
    var id: String { rawValue }
    var title: String {
        switch self {
        case .unknown: return "Not set"
        case .normal: return "Normal aerobic response"
        case .high: return "High aerobic response"
        }
    }
}

enum CaffeineMetabolism: String, Codable, CaseIterable, Identifiable {
    case unknown, slow, fast
    var id: String { rawValue }
    var title: String {
        switch self {
        case .unknown: return "Not set"
        case .slow: return "Slow caffeine metabolizer"
        case .fast: return "Fast caffeine metabolizer"
        }
    }
}

enum CarbResponse: String, Codable, CaseIterable, Identifiable {
    case unknown, sensitive, resilient
    var id: String { rawValue }
    var title: String {
        switch self {
        case .unknown: return "Not set"
        case .sensitive: return "Carb-sensitive"
        case .resilient: return "Carb-resilient"
        }
    }
}

/// Single-row profile capturing the metrics needed to personalize CrossFit plans.
@Model
final class UserProfile {
    var heightCm: Double
    var weightKg: Double
    var bodyShapeRaw: String
    var experienceRaw: String
    var injuryRaws: [String]
    var limitationsNote: String
    var daysPerWeek: Int

    // --- Optional genetic traits (on-device only) ---
    var aerobicRaw: String
    var caffeineRaw: String
    var carbRaw: String
    var lactoseTolerant: Bool

    init(
        heightCm: Double = 175,
        weightKg: Double = 75,
        bodyShape: BodyShape = .mesomorph,
        experience: ExperienceLevel = .intermediate,
        injuries: [InjuryArea] = [],
        limitationsNote: String = "",
        daysPerWeek: Int = 4,
        aerobic: AerobicResponse = .unknown,
        caffeine: CaffeineMetabolism = .unknown,
        carb: CarbResponse = .unknown,
        lactoseTolerant: Bool = false
    ) {
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.bodyShapeRaw = bodyShape.rawValue
        self.experienceRaw = experience.rawValue
        self.injuryRaws = injuries.map(\.rawValue)
        self.limitationsNote = limitationsNote
        self.daysPerWeek = daysPerWeek
        self.aerobicRaw = aerobic.rawValue
        self.caffeineRaw = caffeine.rawValue
        self.carbRaw = carb.rawValue
        self.lactoseTolerant = lactoseTolerant
    }

    var aerobic: AerobicResponse {
        get { AerobicResponse(rawValue: aerobicRaw) ?? .unknown }
        set { aerobicRaw = newValue.rawValue }
    }
    var caffeine: CaffeineMetabolism {
        get { CaffeineMetabolism(rawValue: caffeineRaw) ?? .unknown }
        set { caffeineRaw = newValue.rawValue }
    }
    var carb: CarbResponse {
        get { CarbResponse(rawValue: carbRaw) ?? .unknown }
        set { carbRaw = newValue.rawValue }
    }

    var bodyShape: BodyShape {
        get { BodyShape(rawValue: bodyShapeRaw) ?? .mesomorph }
        set { bodyShapeRaw = newValue.rawValue }
    }
    var experience: ExperienceLevel {
        get { ExperienceLevel(rawValue: experienceRaw) ?? .intermediate }
        set { experienceRaw = newValue.rawValue }
    }
    var injuries: [InjuryArea] {
        get { injuryRaws.compactMap(InjuryArea.init(rawValue:)) }
        set { injuryRaws = newValue.map(\.rawValue) }
    }

    var bmi: Double {
        guard heightCm > 0 else { return 0 }
        let m = heightCm / 100
        return weightKg / (m * m)
    }
}

// MARK: - Nutrition

enum MealSlot: String, Codable, CaseIterable, Identifiable {
    case breakfast, midMorning, lunch, eveningSnack, dinner

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .midMorning: return "Mid-Morning"
        case .lunch: return "Lunch"
        case .eveningSnack: return "Evening Snack"
        case .dinner: return "Dinner"
        }
    }

    var systemImage: String {
        switch self {
        case .breakfast: return "sunrise"
        case .midMorning: return "cup.and.saucer.fill"
        case .lunch: return "fork.knife"
        case .eveningSnack: return "leaf.fill"
        case .dinner: return "moon.fill"
        }
    }

    /// Display order through the day.
    var sortIndex: Int {
        switch self {
        case .breakfast: return 0
        case .midMorning: return 1
        case .lunch: return 2
        case .eveningSnack: return 3
        case .dinner: return 4
        }
    }
}

/// A meal suggestion in the user's nutrition plan (e.g. the Bihari recomp plan).
@Model
final class Meal {
    var slotRaw: String
    var title: String
    /// What to eat — the concrete option.
    var option: String
    /// Why it works — the rationale shown to the user.
    var rationale: String
    var approxProteinGrams: Int
    var approxCalories: Int
    /// Whether the user has logged eating this today (reset daily in the UI layer).
    var lastLoggedDay: Date?

    init(
        slot: MealSlot,
        title: String,
        option: String,
        rationale: String = "",
        approxProteinGrams: Int = 0,
        approxCalories: Int = 0
    ) {
        self.slotRaw = slot.rawValue
        self.title = title
        self.option = option
        self.rationale = rationale
        self.approxProteinGrams = approxProteinGrams
        self.approxCalories = approxCalories
        self.lastLoggedDay = nil
    }

    var slot: MealSlot {
        get { MealSlot(rawValue: slotRaw) ?? .breakfast }
        set { slotRaw = newValue.rawValue }
    }

    var isLoggedToday: Bool {
        guard let day = lastLoggedDay else { return false }
        return Calendar.current.isDateInToday(day)
    }
}
