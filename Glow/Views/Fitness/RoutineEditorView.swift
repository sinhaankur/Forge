import SwiftUI
import SwiftData

/// Create or edit a routine: name, schedule, reminder, steps, and (for fitness)
/// a measurable session target.
struct RoutineEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// nil = creating new.
    var routine: Routine?
    let kind: RoutineKind

    @State private var name = ""
    @State private var timeOfDay: TimeOfDay = .anytime
    @State private var notes = ""
    @State private var weekdays: Set<Int> = Set(1...7)
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var steps: [DraftStep] = []
    @State private var targetEnabled = false
    @State private var targetMetric: TargetMetric = .reps
    @State private var targetValue = ""

    struct DraftStep: Identifiable {
        let id = UUID()
        var title = ""
        var detail = ""
        var sets = ""
        var reps = ""
        var seconds = ""
    }

    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Morning Strength", text: $name)
                }

                Section("Schedule") {
                    Picker("Time of day", selection: $timeOfDay) {
                        ForEach(TimeOfDay.allCases) { Text($0.title).tag($0) }
                    }
                    HStack {
                        ForEach(1...7, id: \.self) { day in
                            let on = weekdays.contains(day)
                            Button {
                                if on { weekdays.remove(day) } else { weekdays.insert(day) }
                            } label: {
                                Text(weekdaySymbols[day - 1])
                                    .font(GlowTheme.caption())
                                    .frame(width: 32, height: 32)
                                    .background(on ? AnyShapeStyle(GlowTheme.accentGradient) : AnyShapeStyle(GlowTheme.faint))
                                    .foregroundStyle(on ? .white : GlowTheme.inkMuted)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Reminder") {
                    Toggle("Remind me", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }

                if kind == .fitness {
                    Section("Workout target") {
                        Toggle("Set a target", isOn: $targetEnabled)
                        if targetEnabled {
                            Picker("Metric", selection: $targetMetric) {
                                ForEach(TargetMetric.allCases) { Label($0.title, systemImage: $0.systemImage).tag($0) }
                            }
                            HStack {
                                TextField("Value", text: $targetValue)
                                    .keyboardType(.decimalPad)
                                Text(targetMetric.unit).foregroundStyle(GlowTheme.inkMuted)
                            }
                        }
                    }
                }

                Section("Steps") {
                    ForEach($steps) { $step in
                        VStack(alignment: .leading, spacing: 6) {
                            TextField(kind == .fitness ? "Exercise" : "Product / action", text: $step.title)
                                .font(GlowTheme.headline(15))
                            if kind == .fitness {
                                HStack {
                                    TextField("Sets", text: $step.sets).keyboardType(.numberPad)
                                    TextField("Reps", text: $step.reps).keyboardType(.numberPad)
                                    TextField("Secs", text: $step.seconds).keyboardType(.numberPad)
                                }
                                .font(GlowTheme.caption())
                            } else {
                                TextField("Note (optional)", text: $step.detail).font(GlowTheme.caption())
                            }
                        }
                    }
                    .onDelete { steps.remove(atOffsets: $0) }

                    Button {
                        steps.append(DraftStep())
                    } label: {
                        Label("Add step", systemImage: "plus.circle.fill")
                    }
                }

                if routine != nil {
                    Section {
                        Button(role: .destructive) { delete() } label: {
                            Text("Delete routine")
                        }
                    }
                }
            }
            .navigationTitle(routine == nil ? "New \(kind.title)" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let r = routine else {
            if steps.isEmpty { steps = [DraftStep()] }
            return
        }
        name = r.name
        timeOfDay = r.timeOfDay
        notes = r.notes
        weekdays = Set(r.activeWeekdays)
        if let mins = r.reminderMinutes {
            reminderEnabled = true
            reminderTime = Calendar.current.date(bySettingHour: mins / 60, minute: mins % 60, second: 0, of: .now) ?? .now
        }
        if let m = r.targetMetric, r.targetValue > 0 {
            targetEnabled = true
            targetMetric = m
            targetValue = String(r.targetValue)
        }
        steps = r.orderedSteps.map {
            DraftStep(title: $0.title, detail: $0.detail,
                      sets: $0.sets > 0 ? String($0.sets) : "",
                      reps: $0.reps > 0 ? String($0.reps) : "",
                      seconds: $0.durationSeconds > 0 ? String($0.durationSeconds) : "")
        }
    }

    private func reminderMinutes() -> Int? {
        guard reminderEnabled else { return nil }
        let c = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    private func save() {
        let target: TargetMetric? = (kind == .fitness && targetEnabled) ? targetMetric : nil
        let tValue = Double(targetValue) ?? 0

        let r: Routine
        if let existing = routine {
            r = existing
            r.name = name
            r.timeOfDay = timeOfDay
            r.notes = notes
            r.activeWeekdays = weekdays.sorted()
            r.reminderMinutes = reminderMinutes()
            r.targetMetric = target
            r.targetValue = tValue
            // Rebuild steps.
            r.steps.forEach { context.delete($0) }
            r.steps = []
        } else {
            r = Routine(name: name, kind: kind, timeOfDay: timeOfDay, notes: notes,
                        colorHex: kind == .skincare ? "#4F8CFF" : "#FF7E5F",
                        activeWeekdays: weekdays.sorted(), reminderMinutes: reminderMinutes(),
                        targetMetric: target, targetValue: tValue)
            context.insert(r)
        }

        for (i, draft) in steps.enumerated() where !draft.title.isEmpty {
            let step = RoutineStep(
                title: draft.title, detail: draft.detail, order: i,
                sets: Int(draft.sets) ?? 0, reps: Int(draft.reps) ?? 0,
                durationSeconds: Int(draft.seconds) ?? 0
            )
            step.routine = r
            r.steps.append(step)
        }

        try? context.save()
        dismiss()
    }

    private func delete() {
        if let r = routine { context.delete(r); try? context.save() }
        dismiss()
    }
}
