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
    @State private var vitaminD: VitaminDTendency = .unknown
    @State private var b12: B12Methylation = .unknown
    @State private var generated = false
    @State private var showImporter = false
    @State private var showDNAInsights = false

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
                    Text("Upload a raw DNA file (23andMe / AncestryDNA) and Forge reads the relevant markers on this device. Or set them manually. Nothing is uploaded — the file is parsed locally and not stored.")
                        .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                    Button {
                        showImporter = true
                    } label: {
                        Label("Upload DNA / CSV file", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        // Endurance-leaning preset (high aerobic, fast caffeine,
                        // carb-resilient). Matches a PPARGC1A/CYP1A2/FTO favorable profile.
                        aerobic = .high; caffeine = .fast; carb = .resilient
                        lactoseTolerant = false; vitaminD = .normal; b12 = .efficient
                    } label: {
                        Label("Apply endurance preset", systemImage: "sparkles")
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
                    Picker("Vitamin D", selection: $vitaminD) {
                        ForEach(VitaminDTendency.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("B12 methylation", selection: $b12) {
                        ForEach(B12Methylation.allCases) { Text($0.title).tag($0) }
                    }
                    Button {
                        save(); showDNAInsights = true
                    } label: {
                        Label("Visualize my DNA", systemImage: "dna")
                    }
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
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: DNAImporter.allowedTypes,
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("DNA imported", isPresented: $importAlert) {
                Button("OK") {}
            } message: { Text(importMessage) }
            .sheet(isPresented: $showDNAInsights) { DNAInsightsView() }
            .overlay {
                if importing {
                    ZStack {
                        Color.black.opacity(0.6).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView().tint(GlowTheme.accent)
                            Text("Reading your DNA on this device…")
                                .font(GlowTheme.caption()).foregroundStyle(GlowTheme.ink)
                        }
                        .padding(24)
                        .background(GlowTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
    }

    @State private var importAlert = false
    @State private var importMessage = ""
    @State private var importing = false

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result, let url = urls.first else { return }
        importing = true
        Task {
            // Read + parse OFF the main thread (files can be ~20MB / 600k lines).
            let parsed: DNAImporter.Traits? = await Task.detached(priority: .userInitiated) {
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
                return DNAImporter.parse(text)
            }.value

            await MainActor.run {
                importing = false
                guard let traits = parsed else {
                    importMessage = "Couldn't read that file. Pick the raw DNA text/CSV export (23andMe, AncestryDNA, MyHeritage)."
                    importAlert = true
                    return
                }
                if let a = traits.aerobic { aerobic = a }
                if let c = traits.caffeine { caffeine = c }
                if let cb = traits.carb { carb = cb }
                if let l = traits.lactoseTolerant { lactoseTolerant = l }
                if let vd = traits.vitaminD { vitaminD = vd }
                if let b = traits.b12 { b12 = b }
                save()
                if traits.foundCount > 0 {
                    // Jump straight to the visualization on success.
                    showDNAInsights = true
                } else {
                    importMessage = traits.summary
                    importAlert = true
                }
            }
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
        vitaminD = p.vitaminD; b12 = p.b12
    }

    private func save() {
        let p = currentProfile()
        p.heightCm = heightCm; p.weightKg = weightKg
        p.bodyShape = bodyShape; p.experience = experience
        p.injuries = Array(injuries); p.limitationsNote = limitations
        p.daysPerWeek = daysPerWeek
        p.aerobic = aerobic; p.caffeine = caffeine
        p.carb = carb; p.lactoseTolerant = lactoseTolerant
        p.vitaminD = vitaminD; p.b12 = b12
        try? context.save()
    }

    private func generate() {
        WorkoutGenerator.generate(for: currentProfile(), in: context)
        ConnectivityService.shared.push(RoutineStore.snapshot(in: context))
        withAnimation { generated = true }
    }
}
