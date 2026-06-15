import Foundation
import SwiftData

/// Sleep logging + the daily readiness score. Pure helpers so any view can use
/// them. On-device only.
enum SleepStore {

    // MARK: Logs

    static func log(for date: Date, in context: ModelContext) -> SleepLog? {
        let day = Calendar.current.startOfDay(for: date)
        let all = (try? context.fetch(FetchDescriptor<SleepLog>())) ?? []
        return all.first { $0.dayStart == day }
    }

    /// Insert or update tonight's (this morning's) sleep record.
    @discardableResult
    static func record(hours: Double, quality: Int = 0, fromHealth: Bool = false,
                       for date: Date = .now, in context: ModelContext) -> SleepLog {
        let day = Calendar.current.startOfDay(for: date)
        if let existing = log(for: day, in: context) {
            existing.hours = hours
            if quality > 0 { existing.quality = quality }
            existing.fromHealth = fromHealth
            try? context.save()
            return existing
        }
        let entry = SleepLog(dayStart: day, hours: hours, quality: quality, fromHealth: fromHealth)
        context.insert(entry)
        try? context.save()
        return entry
    }

    static func recent(days: Int, in context: ModelContext) -> [SleepLog] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Calendar.current.startOfDay(for: .now))!
        let all = (try? context.fetch(FetchDescriptor<SleepLog>())) ?? []
        return all.filter { $0.dayStart >= cutoff }.sorted { $0.dayStart < $1.dayStart }
    }

    static func averageHours(days: Int, in context: ModelContext) -> Double {
        let logs = recent(days: days, in: context).filter { $0.hours > 0 }
        guard !logs.isEmpty else { return 0 }
        return logs.reduce(0) { $0 + $1.hours } / Double(logs.count)
    }

    // MARK: Readiness score

    /// A 0–100 daily readiness score combining last night's sleep, recent
    /// training load, and whether the body has had recovery. Simple, transparent
    /// heuristic — not a medical metric.
    struct Readiness {
        let score: Int           // 0...100
        let label: String        // "Primed" / "Ready" / "Take it easy" / "Recover"
        let advice: String       // training guidance
        let sleepHours: Double
        let factors: [(String, Int)]  // contribution breakdown for transparency
    }

    static func readiness(in context: ModelContext) -> Readiness {
        // 1) Sleep component (0–55): 7.5–9h is ideal.
        let sleep = log(for: .now, in: context)?.hours
            ?? averageHours(days: 3, in: context)
        let sleepScore: Int
        switch sleep {
        case 7.5...9.5: sleepScore = 55
        case 6.5..<7.5, 9.5...10.5: sleepScore = 42
        case 5.5..<6.5: sleepScore = 28
        case 0.1..<5.5: sleepScore = 14
        default: sleepScore = 35 // no data → neutral
        }

        // 2) Training-load component (0–30): hard recent volume lowers readiness.
        let last2 = RoutineStore.completionCount(kind: .fitness, lastDays: 2, in: context)
        let loadScore: Int
        switch last2 {
        case 0: loadScore = 30      // rested
        case 1: loadScore = 24
        case 2: loadScore = 16
        default: loadScore = 8      // 3+ hard days back-to-back
        }

        // 3) Consistency component (0–15): a current streak signals adaptation.
        let streak = RoutineStore.currentStreak(in: context)
        let streakScore = min(15, streak * 3)

        let total = min(100, sleepScore + loadScore + streakScore)

        let label: String, advice: String
        switch total {
        case 80...100:
            label = "Primed"
            advice = "Great recovery. Go for a hard or PR session today."
        case 60..<80:
            label = "Ready"
            advice = "Solid. Train as planned at normal intensity."
        case 40..<60:
            label = "Take it easy"
            advice = "Dial intensity back ~20%, or do zone-2 / mobility."
        default:
            label = "Recover"
            advice = "Prioritize sleep and a light walk. Skip heavy lifting today."
        }

        return Readiness(
            score: total, label: label, advice: advice,
            sleepHours: sleep,
            factors: [("Sleep", sleepScore), ("Recovery", loadScore), ("Consistency", streakScore)]
        )
    }
}
