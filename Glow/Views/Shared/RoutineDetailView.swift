import SwiftUI
import SwiftData

/// Run-through / completion sheet for a routine. Shows the steps as a checklist
/// and, for routines with a target, lets the user log their achieved value
/// (pre-filled from Health where possible).
struct RoutineDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var health = HealthService.shared

    let routine: Routine
    @State private var checked: Set<PersistentIdentifier> = []
    @State private var achieved = ""

    private var alreadyDone: Bool { RoutineStore.isCompleted(routine, on: .now) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(routine.name)
                        .font(GlowTheme.display(34))
                        .foregroundStyle(GlowTheme.ink)

                    if !routine.notes.isEmpty {
                        Text(routine.notes)
                            .font(GlowTheme.body(15))
                            .foregroundStyle(GlowTheme.inkMuted)
                    }

                    VStack(spacing: 0) {
                        ForEach(routine.orderedSteps) { step in
                            stepRow(step)
                            if step.id != routine.orderedSteps.last?.id {
                                Divider().overlay(GlowTheme.faint)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .background(GlowTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: GlowTheme.cornerRadius, style: .continuous))

                    if routine.hasTarget, let metric = routine.targetMetric {
                        targetSection(metric)
                    }

                    GlowButton(
                        title: alreadyDone ? "Mark Incomplete" : "Complete Routine",
                        systemImage: alreadyDone ? "arrow.uturn.backward" : "checkmark"
                    ) { complete() }
                }
                .padding(20)
            }
            .background(GlowTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .task {
                if routine.hasTarget, let m = routine.targetMetric, achieved.isEmpty {
                    let suggested = await health.suggestedAchievedValue(for: m)
                    if suggested > 0 { achieved = String(Int(suggested)) }
                }
            }
        }
    }

    private func stepRow(_ step: RoutineStep) -> some View {
        Button {
            if checked.contains(step.persistentModelID) { checked.remove(step.persistentModelID) }
            else { checked.insert(step.persistentModelID) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: checked.contains(step.persistentModelID) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(checked.contains(step.persistentModelID) ? GlowTheme.accent : GlowTheme.faint)
                // Exercise figure — a workout symbol illustrating the movement.
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(GlowTheme.surfaceHigh)
                        .frame(width: 46, height: 46)
                    Image(systemName: ExerciseFigure.symbol(for: step.title))
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(GlowTheme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(step.title)
                        .font(GlowTheme.headline(15))
                        .foregroundStyle(GlowTheme.ink)
                        .strikethrough(checked.contains(step.persistentModelID), color: GlowTheme.accent)
                    if !step.summary.isEmpty {
                        Text(step.summary).font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func targetSection(_ metric: TargetMetric) -> some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label("Target: \(routine.targetSummary ?? "")", systemImage: metric.systemImage)
                    .font(GlowTheme.headline())
                    .foregroundStyle(GlowTheme.accent)
                HStack {
                    Text("Achieved")
                        .font(GlowTheme.body(15)).foregroundStyle(GlowTheme.ink)
                    Spacer()
                    TextField("0", text: $achieved)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text(metric.unit).foregroundStyle(GlowTheme.inkMuted)
                }
                if health.isAvailable {
                    Text("Tip: pre-filled from Apple Health when available — stays on your device.")
                        .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                }
            }
        }
    }

    private func complete() {
        let value = Double(achieved) ?? 0
        RoutineStore.toggleCompletion(routine, on: .now, achievedValue: value, in: context)
        ConnectivityService.shared.push(RoutineStore.snapshot(in: context))
        dismiss()
    }
}
