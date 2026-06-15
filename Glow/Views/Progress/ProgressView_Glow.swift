import SwiftUI
import SwiftData

/// Progress dashboard — a bento card-grid of stats plus the dot-calendar
/// consistency view. Big numbers, one dark accent card, monochrome surfaces.
struct ProgressView_Glow: View {
    @Environment(\.modelContext) private var context
    @Query private var completions: [RoutineCompletion]
    @StateObject private var health = HealthService.shared
    @StateObject private var motion = MotionService.shared
    @State private var activeEnergy: Double = 0
    @State private var steps: Double = 0
    @State private var weekDistance: Double = 0
    @State private var activities: [ActivitySummary] = []
    @State private var showPrivacy = false

    private var streak: Int { RoutineStore.currentStreak(in: context) }
    private var weekFitness: Int { RoutineStore.completionCount(kind: .fitness, lastDays: 7, in: context) }
    private var weekSkincare: Int { RoutineStore.completionCount(kind: .skincare, lastDays: 7, in: context) }
    private var targetHitRate: Int {
        let withTarget = completions.filter { $0.routine?.hasTarget == true }
        guard !withTarget.isEmpty else { return 0 }
        let hit = withTarget.filter { $0.metTarget }.count
        return Int((Double(hit) / Double(withTarget.count)) * 100)
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Progress")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(GlowTheme.ink)
                        .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 12) {
                        StatCard(label: "Current Streak", value: "\(streak)", unit: "days",
                                 systemImage: "flame.fill", style: .accent)
                        StatCard(label: "Target Hit Rate", value: "\(targetHitRate)", unit: "%",
                                 systemImage: "target", style: .dark)
                        StatCard(label: "Fitness · 7d", value: "\(weekFitness)", unit: "done",
                                 systemImage: "figure.strengthtraining.traditional", style: .light)
                        StatCard(label: "Skincare · 7d", value: "\(weekSkincare)", unit: "done",
                                 systemImage: "drop.fill", style: .light)
                    }

                    if health.isAvailable {
                        LazyVGrid(columns: columns, spacing: 12) {
                            StatCard(label: "Active Energy", value: "\(Int(activeEnergy))", unit: "kcal",
                                     systemImage: "bolt.heart.fill", style: .light)
                            StatCard(label: "Steps Today", value: "\(Int(steps))", unit: "",
                                     systemImage: "figure.walk", style: .light)
                            StatCard(label: "Distance · 7d", value: String(format: "%.1f", weekDistance), unit: "km",
                                     systemImage: "map.fill", style: .accent)
                        }
                    } else if motion.isAvailable {
                        // Free-account fallback: CoreMotion pedometer (no HealthKit needed).
                        LazyVGrid(columns: columns, spacing: 12) {
                            StatCard(label: "Steps Today", value: "\(motion.stepsToday)", unit: "",
                                     systemImage: "figure.walk", style: .accent)
                            StatCard(label: "Distance Today", value: String(format: "%.1f", motion.distanceKmToday), unit: "km",
                                     systemImage: "map.fill", style: .light)
                        }
                    }

                    if !activities.isEmpty {
                        ActivitiesPanel(activities: activities)
                    }

                    ConsistencyCalendar(completedDays: RoutineStore.completedDays(in: context))

                    Button { showPrivacy = true } label: {
                        Label("How Forge handles your health data", systemImage: "lock.shield.fill")
                            .font(GlowTheme.caption())
                            .foregroundStyle(GlowTheme.inkMuted)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
            }
            .background(GlowTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPrivacy) { PrivacySheet() }
            .task {
                await health.requestAuthorization()
                activeEnergy = await health.activeEnergyToday()
                steps = await health.stepsToday()
                weekDistance = await health.distanceKmThisWeek()
                activities = await health.recentActivities(limit: 8)
                // Free-account activity fallback.
                if !health.isAvailable { await motion.refreshToday() }
            }
        }
    }
}

/// Recent activities pulled from Apple Health (Strava walks/runs/rides, Apple
/// Watch workouts, etc.) — read on-device, never uploaded.
struct ActivitiesPanel: View {
    let activities: [ActivitySummary]

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE d"; return f
    }()

    var body: some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 12) {
                Label("RECENT ACTIVITY", systemImage: "figure.run")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                ForEach(activities) { a in
                    HStack(spacing: 12) {
                        Image(systemName: a.systemImage)
                            .font(.system(size: 16))
                            .foregroundStyle(GlowTheme.accent)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(a.kind).font(GlowTheme.headline(15)).foregroundStyle(GlowTheme.ink)
                            Text(Self.dateFmt.string(from: a.date))
                                .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            if a.distanceKm > 0 {
                                Text(String(format: "%.1f km", a.distanceKm))
                                    .font(GlowTheme.headline(14)).foregroundStyle(GlowTheme.ink)
                            }
                            Text("\(Int(a.minutes)) min · \(Int(a.calories)) kcal")
                                .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                        }
                    }
                }
            }
        }
    }
}

/// One bento stat card. Three visual styles per the reference grid.
struct StatCard: View {
    enum Style { case light, dark, accent }
    var label: String
    var value: String
    var unit: String
    var systemImage: String
    var style: Style

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label).font(GlowTheme.caption())
                Spacer()
                Image(systemName: systemImage).font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(secondaryColor)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(GlowTheme.numeral(40))
                if !unit.isEmpty {
                    Text(unit).font(GlowTheme.headline(14)).foregroundStyle(secondaryColor)
                }
            }
            .foregroundStyle(primaryColor)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding(16)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: GlowTheme.cornerRadius, style: .continuous))
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .light: GlowTheme.surface
        case .dark: Color(hex: "#161616")
        case .accent: GlowTheme.accentGradient
        }
    }
    private var primaryColor: Color {
        switch style {
        case .light: return GlowTheme.ink
        case .dark, .accent: return .white
        }
    }
    private var secondaryColor: Color {
        switch style {
        case .light: return GlowTheme.inkMuted
        case .dark: return Color(white: 0.6)
        case .accent: return .white.opacity(0.85)
        }
    }
}

/// The dot-calendar from the reference: a month grid of dots; each day with a
/// completion is filled, today is the warm-accent dot.
struct ConsistencyCalendar: View {
    var completedDays: Set<Date>
    private let cal = Calendar.current

    private var days: [Date] {
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let start = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: now) else { return [] }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("CONSISTENCY")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                HStack {
                    ForEach(Array(["M","T","W","T","F","S","S"].enumerated()), id: \.offset) { _, d in
                        Text(d).font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                            .frame(maxWidth: .infinity)
                    }
                }
                LazyVGrid(columns: columns, spacing: 8) {
                    // Leading blanks so the 1st lands under the right weekday (Mon-first).
                    ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 16) }
                    ForEach(days, id: \.self) { day in
                        dot(for: day).frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var leadingBlanks: Int {
        guard let first = days.first else { return 0 }
        // Convert Sun=1..Sat=7 into Mon=0..Sun=6.
        let weekday = cal.component(.weekday, from: first)
        return (weekday + 5) % 7
    }

    private func dot(for day: Date) -> some View {
        let start = cal.startOfDay(for: day)
        let isToday = cal.isDateInToday(day)
        let done = completedDays.contains(start)
        let state: GlowDot.State = isToday ? .today : (done ? .filled : .empty)
        return GlowDot(state: state, size: 16)
    }
}

/// In-app privacy explainer for HealthKit usage.
struct PrivacySheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GlowMark(size: 56)
                    Text("Your data stays yours")
                        .font(GlowTheme.title())
                        .foregroundStyle(GlowTheme.ink)
                    Text(HealthService.privacyStatement)
                        .font(GlowTheme.body(15))
                        .foregroundStyle(GlowTheme.ink)
                    Label("No account · No server · No analytics", systemImage: "checkmark.shield.fill")
                        .font(GlowTheme.headline(14))
                        .foregroundStyle(GlowTheme.accent)
                }
                .padding(24)
            }
            .background(GlowTheme.background.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
