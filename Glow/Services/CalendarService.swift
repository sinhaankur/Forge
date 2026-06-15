import Foundation
import EventKit

/// Reads the user's calendar on-device to find free gaps around meetings, so
/// Forge can schedule workout/warm-up reminders at times that actually fit the
/// day (around standups, meetings, etc.). Privacy-first: events are read locally
/// and never stored or transmitted.
@MainActor
final class CalendarService: ObservableObject {
    static let shared = CalendarService()
    private let store = EKEventStore()

    @Published var isAuthorized = false

    private init() {}

    func requestAccess() async {
        do {
            if #available(iOS 17, *) {
                isAuthorized = try await store.requestFullAccessToEvents()
            } else {
                isAuthorized = try await store.requestAccess(to: .event)
            }
        } catch {
            isAuthorized = false
        }
    }

    /// Today's timed events (skips all-day), sorted by start.
    func todayEvents() -> [EKEvent] {
        guard isAuthorized else { return [] }
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
    }

    /// A free slot in the day's schedule.
    struct FreeSlot { let start: Date; let end: Date; var minutes: Int { Int(end.timeIntervalSince(start) / 60) } }

    /// Find free gaps of at least `minMinutes`, within waking hours
    /// (default 06:00–22:00), between today's meetings.
    func freeSlots(minMinutes: Int = 30, dayStartHour: Int = 6, dayEndHour: Int = 22) -> [FreeSlot] {
        let cal = Calendar.current
        let now = Date()
        let windowStart = max(now, cal.date(bySettingHour: dayStartHour, minute: 0, second: 0, of: now)!)
        let windowEnd = cal.date(bySettingHour: dayEndHour, minute: 0, second: 0, of: now)!
        guard windowStart < windowEnd else { return [] }

        let events = todayEvents().filter { $0.endDate > windowStart }
        var slots: [FreeSlot] = []
        var cursor = windowStart
        for e in events {
            if e.startDate > cursor {
                let gap = FreeSlot(start: cursor, end: min(e.startDate, windowEnd))
                if gap.minutes >= minMinutes { slots.append(gap) }
            }
            cursor = max(cursor, e.endDate)
            if cursor >= windowEnd { break }
        }
        if cursor < windowEnd {
            let tail = FreeSlot(start: cursor, end: windowEnd)
            if tail.minutes >= minMinutes { slots.append(tail) }
        }
        return slots
    }

    /// The best free slot for a workout of `minMinutes` — prefers morning, then
    /// the longest available gap. Returns nil if the day is fully booked.
    func bestWorkoutSlot(minMinutes: Int = 45) -> FreeSlot? {
        let slots = freeSlots(minMinutes: minMinutes)
        // Prefer a morning slot if one exists, else the longest.
        let morning = slots.first { Calendar.current.component(.hour, from: $0.start) < 12 }
        return morning ?? slots.max { $0.minutes < $1.minutes }
    }

    /// A short label like "9:30–10:15 AM gap".
    func label(for slot: FreeSlot) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm"
        return "\(f.string(from: slot.start))–\(f.string(from: slot.end)) (\(slot.minutes)m free)"
    }
}
