import SwiftUI
import SwiftData

/// The Today screen — big date header + a checklist of today's routines, in the
/// minimal day-stack style. Tapping a routine row toggles completion; tapping
/// the chevron opens the detail/log sheet.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var allRoutines: [Routine]
    @State private var logTarget: Routine?

    private var todays: [Routine] { RoutineStore.routines(on: .now, in: context) }
    private var streak: Int { RoutineStore.currentStreak(in: context) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    DateHeader(subtitle: streak > 0 ? "🔥 \(streak)-day streak" : nil)

                    if todays.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 0) {
                            ForEach(todays) { routine in
                                ChecklistRow(
                                    routine: routine,
                                    isDone: RoutineStore.isCompleted(routine, on: .now),
                                    onToggle: { toggle(routine) },
                                    onOpen: { logTarget = routine }
                                )
                                if routine.id != todays.last?.id {
                                    Divider().overlay(GlowTheme.faint)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .background(GlowTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: GlowTheme.cornerRadius, style: .continuous))
                    }
                }
                .padding(20)
            }
            .background(GlowTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $logTarget) { routine in
                RoutineDetailView(routine: routine)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            GlowMark(size: 56)
            Text("Nothing scheduled today")
                .font(GlowTheme.headline())
                .foregroundStyle(GlowTheme.ink)
            Text("Add routines from the Fitness or Skincare tabs.")
                .font(GlowTheme.body(14))
                .foregroundStyle(GlowTheme.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func toggle(_ routine: Routine) {
        // Routines with a target open the log sheet instead of a blind toggle.
        if routine.hasTarget && !RoutineStore.isCompleted(routine, on: .now) {
            logTarget = routine
        } else {
            RoutineStore.toggleCompletion(routine, on: .now, in: context)
            ConnectivityService.shared.push(RoutineStore.snapshot(in: context))
        }
    }
}

/// A single checklist row: checkbox, name (struck through + accent when done),
/// time-of-day & target meta, and a chevron to open details.
struct ChecklistRow: View {
    var routine: Routine
    var isDone: Bool
    var onToggle: () -> Void
    var onOpen: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: isDone ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isDone ? GlowTheme.accent : GlowTheme.inkMuted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(routine.name)
                    .font(GlowTheme.headline())
                    .foregroundStyle(isDone ? GlowTheme.inkMuted : GlowTheme.ink)
                    .strikethrough(isDone, color: GlowTheme.accent)
                HStack(spacing: 8) {
                    Label(routine.timeOfDay.title, systemImage: routine.timeOfDay.systemImage)
                    Text("· \(routine.steps.count) steps")
                    if let t = routine.targetSummary {
                        Text("· 🎯 \(t)")
                    }
                }
                .font(GlowTheme.caption())
                .foregroundStyle(GlowTheme.inkMuted)
            }

            Spacer()

            Button(action: onOpen) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(GlowTheme.faint)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}
