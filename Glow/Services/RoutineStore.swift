import Foundation
import SwiftData

/// Query + mutation helpers over the SwiftData store, plus streak math and
/// building the watch snapshot. Pure functions so both targets can reuse them.
enum RoutineStore {

    // MARK: Today

    static func routines(on date: Date, in context: ModelContext) -> [Routine] {
        let all = (try? context.fetch(FetchDescriptor<Routine>())) ?? []
        return all.filter { $0.isActive(on: date) }
            .sorted { lhs, rhs in
                if lhs.timeOfDay.sortRank != rhs.timeOfDay.sortRank {
                    return lhs.timeOfDay.sortRank < rhs.timeOfDay.sortRank
                }
                return lhs.name < rhs.name
            }
    }

    static func isCompleted(_ routine: Routine, on date: Date) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        return routine.completions.contains { $0.dayStart == day }
    }

    static func completion(for routine: Routine, on date: Date) -> RoutineCompletion? {
        let day = Calendar.current.startOfDay(for: date)
        return routine.completions.first { $0.dayStart == day }
    }

    /// Toggle a routine's completion for a given day. When completing, records
    /// the achieved value against any target.
    @discardableResult
    static func toggleCompletion(
        _ routine: Routine,
        on date: Date,
        achievedValue: Double = 0,
        in context: ModelContext
    ) -> Bool {
        if let existing = completion(for: routine, on: date) {
            context.delete(existing)
            try? context.save()
            return false
        } else {
            let c = RoutineCompletion(date: date, achievedValue: achievedValue, routine: routine)
            context.insert(c)
            try? context.save()
            return true
        }
    }

    // MARK: Streaks & stats

    /// All distinct days (start-of-day) on which at least one routine was completed.
    static func completedDays(in context: ModelContext) -> Set<Date> {
        let all = (try? context.fetch(FetchDescriptor<RoutineCompletion>())) ?? []
        return Set(all.map { $0.dayStart })
    }

    /// Current consecutive-day streak ending today (or yesterday if today not yet done).
    static func currentStreak(in context: ModelContext) -> Int {
        let days = completedDays(in: context)
        guard !days.isEmpty else { return 0 }
        let cal = Calendar.current
        var streak = 0
        var cursor = cal.startOfDay(for: .now)
        // Allow the streak to count from today, else start at yesterday.
        if !days.contains(cursor) {
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
            if !days.contains(cursor) { return 0 }
        }
        while days.contains(cursor) {
            streak += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }

    /// Completion counts per kind over the last `days` days.
    static func completionCount(kind: RoutineKind?, lastDays days: Int, in context: ModelContext) -> Int {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -days, to: cal.startOfDay(for: .now))!
        let all = (try? context.fetch(FetchDescriptor<RoutineCompletion>())) ?? []
        return all.filter { c in
            guard c.dayStart >= cutoff else { return false }
            guard let k = kind else { return true }
            return c.routine?.kind == k
        }.count
    }

    // MARK: Watch snapshot

    static func snapshot(in context: ModelContext, date: Date = .now) -> TodaySnapshot {
        let routines = routines(on: date, in: context)
        let items = routines.map { r in
            TodaySnapshot.Item(
                id: String(r.persistentModelID.hashValue),
                name: r.name,
                kind: r.kindRaw,
                timeOfDay: r.timeOfDayRaw,
                stepCount: r.steps.count,
                targetSummary: r.targetSummary,
                completedToday: isCompleted(r, on: date)
            )
        }
        return TodaySnapshot(date: date, items: items, streak: currentStreak(in: context))
    }
}

private extension TimeOfDay {
    var sortRank: Int {
        switch self {
        case .morning: return 0
        case .afternoon: return 1
        case .evening: return 2
        case .anytime: return 3
        }
    }
}
