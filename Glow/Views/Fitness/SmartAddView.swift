import SwiftUI
import SwiftData

/// Two fast ways to create a workout:
///  1) Suggest today's session based on time of day + readiness (health-aware).
///  2) Paste notes from any AI (Gemini/ChatGPT/etc.) and turn them into an
///     editable routine.
/// Both hand back a routine the user can immediately modify.
struct SmartAddView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    var onCreated: (Routine) -> Void

    @State private var notes = ""

    private var timeOfDay: TimeOfDay {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<24, 0..<5: return .evening
        default: return .anytime
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 1) Smart suggestion.
                    GlowPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("SUGGESTED FOR NOW", systemImage: "sparkles")
                                .font(GlowTheme.caption()).foregroundStyle(GlowTheme.accent)
                            let s = suggestion
                            Text(s.title).font(.system(size: 18, weight: .bold)).foregroundStyle(GlowTheme.ink)
                            Text(s.reason).font(GlowTheme.body(14)).foregroundStyle(GlowTheme.inkMuted)
                            GlowButton(title: "Create & edit", systemImage: "plus") {
                                let r = buildSuggested(s)
                                context.insert(r); try? context.save()
                                dismiss(); onCreated(r)
                            }
                        }
                    }

                    // 2) Paste AI notes.
                    GlowPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("PASTE A PLAN", systemImage: "doc.on.clipboard")
                                .font(GlowTheme.caption()).foregroundStyle(GlowTheme.accent)
                            Text("Paste a workout from Gemini, ChatGPT, or your notes. Forge turns it into an editable routine.")
                                .font(GlowTheme.body(13)).foregroundStyle(GlowTheme.inkMuted)
                            TextEditor(text: $notes)
                                .frame(minHeight: 140)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(GlowTheme.surfaceHigh)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .foregroundStyle(GlowTheme.ink)
                            GlowButton(title: "Create from notes", systemImage: "wand.and.stars") {
                                let r = PlanParser.makeRoutine(from: notes, kind: .fitness, timeOfDay: timeOfDay)
                                context.insert(r); try? context.save()
                                dismiss(); onCreated(r)
                            }
                            .disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                        }
                    }
                }
                .padding(20)
            }
            .background(GlowTheme.background.ignoresSafeArea())
            .navigationTitle("Add workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    // MARK: Suggestion logic (time-of-day + readiness)

    private struct Suggestion { let title: String; let reason: String; let theme: ExerciseLibrary.Theme }

    private var suggestion: Suggestion {
        let r = SleepStore.readiness(in: context)
        // Low readiness → recovery regardless of time.
        if r.score < 45 {
            return Suggestion(title: "Recovery: Mobility + Zone-2 Walk",
                              reason: "Readiness is \(r.score) (\(r.label)). Keep it easy today — mobility and a steady walk aid recovery.",
                              theme: .engine)
        }
        switch timeOfDay {
        case .morning:
            return Suggestion(title: "Morning Strength",
                              reason: "Readiness \(r.score). Mornings suit focused strength work — compound lifts while you're fresh.",
                              theme: .strength)
        case .afternoon:
            return Suggestion(title: "Midday Conditioning",
                              reason: "Readiness \(r.score). A brisk metcon fits an afternoon energy window.",
                              theme: .metcon)
        case .evening, .anytime:
            return Suggestion(title: "Evening Engine + Mobility",
                              reason: "Readiness \(r.score). Evenings favor zone-2 cardio and mobility — lower arousal before sleep.",
                              theme: .engine)
        }
    }

    private func buildSuggested(_ s: Suggestion) -> Routine {
        let injuries = Set(profiles.first?.injuries ?? [])
        let routine = Routine(name: s.title, kind: .fitness, timeOfDay: timeOfDay,
                              notes: "Suggested from your readiness & time of day — edit freely.",
                              colorHex: "#19E3C2",
                              activeWeekdays: [Calendar.current.component(.weekday, from: .now)])
        var order = 0
        // Always warm up first.
        for (phase, drill) in ExerciseLibrary.warmupRoutine(injuries: injuries).prefix(4) {
            let step = RoutineStep(title: "🔥 \(phase.rawValue): \(drill.title)", detail: drill.cue,
                                   order: order, reps: drill.reps, durationSeconds: drill.seconds)
            step.routine = routine; routine.steps.append(step); order += 1
        }
        for m in ExerciseLibrary.safeMovements(theme: s.theme, injuries: injuries) {
            let step = RoutineStep(title: m.title, detail: m.cue, order: order,
                                   sets: m.sets, reps: m.reps, durationSeconds: m.seconds)
            step.routine = routine; routine.steps.append(step); order += 1
        }
        return routine
    }
}
