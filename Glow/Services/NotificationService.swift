import Foundation
import UserNotifications

/// Schedules local reminder notifications for routines based on their
/// reminder time and active weekdays.
@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    /// Ask the user for notification permission. Safe to call repeatedly.
    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Rebuild all scheduled reminders from the current set of routines.
    /// Call after any routine edit.
    func reschedule(for routines: [Routine]) async {
        center.removeAllPendingNotificationRequests()

        for routine in routines {
            guard let minutes = routine.reminderMinutes else { continue }
            let hour = minutes / 60
            let minute = minutes % 60

            for weekday in routine.activeWeekdays {
                var components = DateComponents()
                components.weekday = weekday
                components.hour = hour
                components.minute = minute

                let content = UNMutableNotificationContent()
                content.title = routine.name
                content.body = body(for: routine)
                content.sound = .default
                content.categoryIdentifier = "ROUTINE_REMINDER"
                content.userInfo = ["routineName": routine.name]

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let id = "\(routine.persistentModelID.hashValue)-\(weekday)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }

    private func body(for routine: Routine) -> String {
        if let target = routine.targetSummary {
            return "Time for \(routine.timeOfDay.title.lowercased()) — target \(target). \(routine.orderedSteps.count) steps."
        }
        switch routine.kind {
        case .fitness: return "Let's move. \(routine.orderedSteps.count) exercises waiting."
        case .skincare: return "Glow time. \(routine.orderedSteps.count) steps to go."
        }
    }

    // MARK: Calendar-aware smart reminders

    /// Schedule today's smart nudges around the user's calendar:
    /// - a morning "plan your day" reminder
    /// - a workout reminder placed in the best free slot around meetings
    /// - a 5-min warm-up nudge just before that slot
    /// Existing smart notifications (prefix "smart-") are cleared first.
    func scheduleSmartReminders(workoutMinutes: Int = 45) async {
        let pending = await center.pendingNotificationRequests()
        let smartIDs = pending.map(\.identifier).filter { $0.hasPrefix("smart-") }
        center.removePendingNotificationRequests(withIdentifiers: smartIDs)

        // Morning plan-your-day nudge at 7:30 (only if still upcoming today).
        scheduleMorningPlan()

        guard CalendarService.shared.isAuthorized else { return }
        guard let slot = CalendarService.shared.bestWorkoutSlot(minMinutes: workoutMinutes) else {
            // Fully booked — nudge to fit something small.
            await add(id: "smart-busy", at: Date().addingTimeInterval(60),
                      title: "Busy day?", body: "No clear gap — even a 10-min walk or warm-up counts. Squeeze one in.")
            return
        }

        // Warm-up nudge 5 min before the slot.
        let warmupTime = slot.start.addingTimeInterval(-5 * 60)
        if warmupTime > Date() {
            await add(id: "smart-warmup", at: warmupTime,
                      title: "Warm-up time 🔥",
                      body: "Your \(CalendarService.shared.label(for: slot)) is coming up — start your warm-up.")
        }
        // Workout reminder at the slot start.
        if slot.start > Date() {
            await add(id: "smart-workout", at: slot.start,
                      title: "Workout window",
                      body: "You've got \(slot.minutes) min free now — perfect for today's session.")
        }
    }

    private func scheduleMorningPlan() {
        let cal = Calendar.current
        guard let time = cal.date(bySettingHour: 7, minute: 30, second: 0, of: .now), time > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Plan your day"
        content.body = "Check today's readiness and slot your workout around your meetings."
        content.sound = .default
        let comps = cal.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: "smart-morning", content: content, trigger: trigger))
    }

    private func add(id: String, at date: Date, title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body; content.sound = .default
        let interval = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
