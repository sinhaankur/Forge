import SwiftUI
import EventKit

/// A Today card that reads the user's calendar to suggest the best free slot for
/// a workout around their meetings, and schedules smart reminders. Privacy-first:
/// calendar is read on-device only.
struct PlanAroundDayCard: View {
    @StateObject private var calendar = CalendarService.shared
    @State private var slotLabel: String?
    @State private var nextMeeting: String?
    @State private var scheduled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Plan around your day", systemImage: "calendar")
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(GlowTheme.ink)
                Spacer()
            }

            if !calendar.isAuthorized {
                Text("Let Forge find free time around your meetings and remind you to train & warm up.")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                Button {
                    Task { await calendar.requestAccess(); refresh() }
                } label: {
                    Text("Connect calendar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(GlowTheme.accentGradient)
                        .clipShape(Capsule())
                }
            } else if let slot = slotLabel {
                HStack(spacing: 10) {
                    Image(systemName: "figure.run.circle.fill").foregroundStyle(GlowTheme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Best workout slot").font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                        Text(slot).font(.system(size: 15, weight: .semibold)).foregroundStyle(GlowTheme.ink)
                    }
                }
                if let m = nextMeeting {
                    Text("Next up: \(m)").font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                }
                Button {
                    Task { await NotificationService.shared.scheduleSmartReminders(); scheduled = true }
                } label: {
                    Label(scheduled ? "Reminders set" : "Remind me to train + warm up",
                          systemImage: scheduled ? "checkmark.circle.fill" : "bell.badge")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(scheduled ? GlowTheme.accent : GlowTheme.ink)
                }
                .disabled(scheduled)
            } else {
                Text("Your day looks fully booked — even a 10-minute walk or warm-up counts.")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GlowTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .task { refresh() }
    }

    private func refresh() {
        guard calendar.isAuthorized else { return }
        if let slot = calendar.bestWorkoutSlot(minMinutes: 45) {
            slotLabel = calendar.label(for: slot)
        } else {
            slotLabel = nil
        }
        if let next = calendar.todayEvents().first(where: { $0.startDate > Date() }) {
            let f = DateFormatter(); f.dateFormat = "h:mm a"
            nextMeeting = "\(next.title ?? "Meeting") · \(f.string(from: next.startDate))"
        }
    }
}
