import SwiftUI
import SwiftData

/// The Sleep pillar — daily readiness score, last night's sleep (Apple Health
/// or manual), a 7-day trend, and evidence-based sleep-hygiene guidance.
struct SleepView: View {
    @Environment(\.modelContext) private var context
    @Query private var logs: [SleepLog]
    @StateObject private var health = HealthService.shared

    @State private var manualHours: Double = 7.5
    @State private var manualQuality = 3
    @State private var showLog = false

    private var readiness: SleepStore.Readiness { SleepStore.readiness(in: context) }
    private var lastNight: SleepLog? { SleepStore.log(for: .now, in: context) }
    private var avg7: Double { SleepStore.averageHours(days: 7, in: context) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Sleep")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(GlowTheme.ink)
                        .padding(.bottom, 2)

                    readinessCard
                    lastNightCard
                    trendCard
                    tipsCard
                }
                .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 24)
            }
            .background(GlowTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showLog) { logSheet }
            .task {
                await health.requestAuthorization()
                let h = await health.sleepHoursLastNight()
                if h > 0 { SleepStore.record(hours: h, fromHealth: true, in: context) }
            }
        }
    }

    // MARK: Readiness

    private var readinessCard: some View {
        let r = readiness
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    ProgressRing(progress: Double(r.score) / 100, lineWidth: 7)
                        .frame(width: 96, height: 96)
                    VStack(spacing: 0) {
                        Text("\(r.score)").font(.system(size: 30, weight: .heavy)).foregroundStyle(GlowTheme.ink)
                        Text("ready").font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(r.label).font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(GlowTheme.accent)
                    Text(r.advice).font(GlowTheme.body(14)).foregroundStyle(GlowTheme.ink)
                }
            }
            // Factor breakdown bars (transparent scoring).
            HStack(spacing: 8) {
                ForEach(r.factors, id: \.0) { name, val in
                    VStack(spacing: 4) {
                        GeometryReader { geo in
                            let maxH: CGFloat = 36
                            VStack { Spacer()
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(GlowTheme.accentGradient)
                                    .frame(height: max(3, maxH * CGFloat(val) / 55))
                            }.frame(maxHeight: .infinity, alignment: .bottom)
                            .frame(width: geo.size.width)
                        }.frame(height: 36)
                        Text(name).font(.system(size: 10, weight: .semibold)).foregroundStyle(GlowTheme.inkMuted)
                    }.frame(maxWidth: .infinity)
                }
            }
        }
        .padding(18)
        .background(GlowTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    // MARK: Last night

    private var lastNightCard: some View {
        Button { showLog = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last night").font(.system(size: 16, weight: .semibold)).foregroundStyle(GlowTheme.ink)
                    Text(lastNight?.fromHealth == true ? "From Apple Health" : "Tap to log")
                        .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(lastNight.map { String(format: "%.1f", $0.hours) } ?? "—")
                        .font(.system(size: 30, weight: .heavy)).foregroundStyle(GlowTheme.ink)
                    Text("h").font(.system(size: 14, weight: .semibold)).foregroundStyle(GlowTheme.inkMuted)
                }
            }
            .padding(18)
            .background(GlowTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }.buttonStyle(.plain)
    }

    // MARK: 7-day trend

    private var trendCard: some View {
        let recent = SleepStore.recent(days: 7, in: context)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("7-day average").font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                Spacer()
                Text(avg7 > 0 ? String(format: "%.1f h", avg7) : "—")
                    .font(.system(size: 15, weight: .bold)).foregroundStyle(GlowTheme.accent)
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { i in
                    let day = Calendar.current.date(byAdding: .day, value: -6 + i, to: .now)!
                    let h = recent.first { Calendar.current.isDate($0.dayStart, inSameDayAs: day) }?.hours ?? 0
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(h > 0 ? AnyShapeStyle(GlowTheme.accentGradient) : AnyShapeStyle(GlowTheme.faint))
                            .frame(height: max(4, CGFloat(h) / 10 * 60))
                        Text(Self.dayLetter(day)).font(.system(size: 10, weight: .semibold)).foregroundStyle(GlowTheme.inkMuted)
                    }.frame(maxWidth: .infinity)
                }
            }.frame(height: 80)
        }
        .padding(18)
        .background(GlowTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private static func dayLetter(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEEE"; return f.string(from: d)
    }

    // MARK: Tips

    private let tips: [(String, String)] = [
        ("Consistent schedule", "Same sleep/wake time daily — even weekends — anchors your circadian rhythm."),
        ("Wind-down", "Dim lights & screens 60 min before bed; blue light delays melatonin."),
        ("Cool & dark", "~18°C and blackout — core temperature needs to drop to fall asleep."),
        ("Caffeine cutoff", "Stop caffeine ~8–10h before bed (more if you're a slow metabolizer)."),
        ("Train, don't strain late", "Hard workouts within 2h of bed can delay sleep onset."),
    ]

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SLEEP HYGIENE").font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
            ForEach(tips, id: \.0) { tip in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "moon.zzz.fill").font(.system(size: 12)).foregroundStyle(GlowTheme.accent).padding(.top, 2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tip.0).font(.system(size: 15, weight: .semibold)).foregroundStyle(GlowTheme.ink)
                        Text(tip.1).font(GlowTheme.body(13)).foregroundStyle(GlowTheme.inkMuted)
                    }
                }
            }
        }
        .padding(18)
        .background(GlowTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    // MARK: Manual log sheet

    private var logSheet: some View {
        NavigationStack {
            Form {
                Section("Hours slept") {
                    Stepper(String(format: "%.1f hours", manualHours), value: $manualHours, in: 0...14, step: 0.5)
                }
                Section("Quality") {
                    Picker("How rested?", selection: $manualQuality) {
                        Text("Poor").tag(1); Text("Fair").tag(2); Text("OK").tag(3)
                        Text("Good").tag(4); Text("Great").tag(5)
                    }.pickerStyle(.segmented)
                }
            }
            .navigationTitle("Log sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        SleepStore.record(hours: manualHours, quality: manualQuality, in: context)
                        showLog = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showLog = false } }
            }
            .onAppear { if let l = lastNight { manualHours = l.hours; manualQuality = max(1, l.quality) } }
        }
    }
}
