import SwiftUI
import SwiftData

/// Captures the user's body metrics, experience, injuries, and limitations, and
/// generates a personalized CrossFit schedule on-device.
struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var heightCm: Double = 175
    @State private var weightKg: Double = 75
    @State private var bodyShape: BodyShape = .mesomorph
    @State private var experience: ExperienceLevel = .intermediate
    @State private var injuries: Set<InjuryArea> = []
    @State private var limitations = ""
    @State private var daysPerWeek = 4
    @State private var aerobic: AerobicResponse = .unknown
    @State private var caffeine: CaffeineMetabolism = .unknown
    @State private var carb: CarbResponse = .unknown
    @State private var lactoseTolerant = false
    @State private var generated = false

    private var bmi: Double {
        let m = heightCm / 100
        return m > 0 ? weightKg / (m * m) : 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Body") {
                    Stepper("Height: \(Int(heightCm)) cm", value: $heightCm, in: 130...220)
                    Stepper("Weight: \(Int(weightKg)) kg", value: $weightKg, in: 40...180)
                    HStack {
                        Text("BMI")
                        Spacer()
                        Text(String(format: "%.1f", bmi)).foregroundStyle(GlowTheme.accent)
                    }
                    Picker("Build", selection: $bodyShape) {
                        ForEach(BodyShape.allCases) { Text($0.title).tag($0) }
                    }
                }

                Section("Training") {
                    Picker("Experience", selection: $experience) {
                        ForEach(ExperienceLevel.allCases) { Text($0.title).tag($0) }
                    }
                    Stepper("Days per week: \(daysPerWeek)", value: $daysPerWeek, in: 1...6)
                }

                Section("Injuries & limitations") {
                    Text("We'll exclude movements that load these areas and modify warm-ups accordingly.")
                        .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                    ForEach(InjuryArea.allCases) { area in
                        Toggle(area.title, isOn: Binding(
                            get: { injuries.contains(area) },
                            set: { on in if on { injuries.insert(area) } else { injuries.remove(area) } }
                        ))
                    }
                    TextField("Other limitations (free text)", text: $limitations, axis: .vertical)
                }

                Section("Genetic insights (optional)") {
                    Text("If you know these from a DNA report, Forge tunes your plan. Stored only on this device — never uploaded.")
                        .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                    Button {
                        // Quick-apply: the endurance-leaning, dairy-friendly,
                        // carb-resilient, fast-caffeine profile.
                        aerobic = .high
                        caffeine = .fast
                        carb = .resilient
                        lactoseTolerant = true
                    } label: {
                        Label("Apply my DNA markers", systemImage: "sparkles")
                    }
                    Picker("Aerobic response", selection: $aerobic) {
                        ForEach(AerobicResponse.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Caffeine metabolism", selection: $caffeine) {
                        ForEach(CaffeineMetabolism.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Carb response", selection: $carb) {
                        ForEach(CarbResponse.allCases) { Text($0.title).tag($0) }
                    }
                    Toggle("Lactose tolerant (dairy OK)", isOn: $lactoseTolerant)
                }

                Section {
                    Button {
                        save(); generate()
                    } label: {
                        Label("Generate my CrossFit plan", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    if generated {
                        Label("Plan generated — check the Fitness tab.", systemImage: "checkmark.circle.fill")
                            .font(GlowTheme.caption()).foregroundStyle(GlowTheme.accent)
                    }
                }
            }
            .navigationTitle("Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { save(); dismiss() } } }
            .onAppear(perform: load)
        }
    }

    private func currentProfile() -> UserProfile {
        if let p = profiles.first { return p }
        let p = UserProfile()
        context.insert(p)
        return p
    }

    private func load() {
        guard let p = profiles.first else { return }
        heightCm = p.heightCm; weightKg = p.weightKg
        bodyShape = p.bodyShape; experience = p.experience
        injuries = Set(p.injuries); limitations = p.limitationsNote
        daysPerWeek = p.daysPerWeek
        aerobic = p.aerobic; caffeine = p.caffeine
        carb = p.carb; lactoseTolerant = p.lactoseTolerant
    }

    private func save() {
        let p = currentProfile()
        p.heightCm = heightCm; p.weightKg = weightKg
        p.bodyShape = bodyShape; p.experience = experience
        p.injuries = Array(injuries); p.limitationsNote = limitations
        p.daysPerWeek = daysPerWeek
        p.aerobic = aerobic; p.caffeine = caffeine
        p.carb = carb; p.lactoseTolerant = lactoseTolerant
        try? context.save()
    }

    private func generate() {
        WorkoutGenerator.generate(for: currentProfile(), in: context)
        ConnectivityService.shared.push(RoutineStore.snapshot(in: context))
        withAnimation { generated = true }
    }
}
