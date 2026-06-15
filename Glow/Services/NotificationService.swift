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
}
