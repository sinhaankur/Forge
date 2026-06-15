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
    @Query private var profiles: [UserProfile]
    @State private var checked: Set<PersistentIdentifier> = []
    @State private var achieved = ""
    @State private var howToStep: RoutineStep?
    @State private var showFocus = false

    private var boosts: [HormoneInsight.Boost] {
        HormoneInsight.boosts(for: routine, profile: profiles.first)
    }

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

                    if !routine.orderedSteps.isEmpty {
                        Button { showFocus = true } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                Text("Start guided session").font(GlowTheme.headline())
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .foregroundStyle(.black).background(GlowTheme.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }

                    if !boosts.isEmpty { moodBoostCard }

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
            .sheet(item: $howToStep) { step in
                ExerciseDetailView(stepTitle: step.title, summary: step.summary)
            }
            .fullScreenCover(isPresented: $showFocus) {
                FocusSessionView(routine: routine)
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
                // "How to do it" — opens the form guide for this movement.
                Button { howToStep = step } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18)).foregroundStyle(GlowTheme.inkMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var moodBoostCard: some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label("FEEL-GOOD BOOST", systemImage: "sparkles")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.accent)
                Text("Likely brain-chemistry lift from this session" +
                     (profiles.first?.aerobic == .high ? ", tuned to your high aerobic genetics:" : ":"))
                    .font(GlowTheme.body(13)).foregroundStyle(GlowTheme.inkMuted)
                ForEach(boosts) { b in
                    HStack(spacing: 10) {
                        Image(systemName: b.chemical.systemImage)
                            .font(.system(size: 14)).foregroundStyle(GlowTheme.accent).frame(width: 22)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(b.chemical.title).font(.system(size: 15, weight: .semibold)).foregroundStyle(GlowTheme.ink)
                            Text(b.chemical.blurb).font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                        }
                        Spacer()
                        Text(b.label).font(.system(size: 11)).foregroundStyle(GlowTheme.accent)
                    }
                }
                Text("General wellness estimate — not a measurement or medical advice.")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
            }
        }
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
        let nowDone = RoutineStore.toggleCompletion(routine, on: .now, achievedValue: value, in: context)
        if nowDone { Haptics.celebrate() } else { Haptics.tap() }
        ConnectivityService.shared.push(RoutineStore.snapshot(in: context))
        dismiss()
    }
}
