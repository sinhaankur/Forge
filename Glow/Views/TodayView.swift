import SwiftUI
import SwiftData

/// The Today / home screen — pure-black bento layout matching the reference:
/// big title + icon buttons, ring + big-numeral stat cards, a wide dot-calendar
/// card with a docked routine row, a split stat row, and an add tile.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var allRoutines: [Routine]
    @Query private var profiles: [UserProfile]
    @State private var logTarget: Routine?
    @State private var showNew = false
    @State private var showProfile = false

    private var profile: UserProfile? { profiles.first }

    private var todays: [Routine] { RoutineStore.routines(on: .now, in: context) }
    private var streak: Int { RoutineStore.currentStreak(in: context) }
    private var doneToday: Int { todays.filter { RoutineStore.isCompleted($0, on: .now) }.count }
    private var weekFitness: Int { RoutineStore.completionCount(kind: .fitness, lastDays: 7, in: context) }

    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ProfileHeader(name: profile?.displayName ?? "",
                                  imageData: profile?.avatarData,
                                  subtitle: streak > 0 ? "🔥 \(streak)" : nil) {
                        showProfile = true
                    }
                    .padding(.bottom, 2)

                    titleBar
                        .padding(.bottom, 4)

                    // Top row: ring card + big-numeral stat card.
                    LazyVGrid(columns: cols, spacing: 12) {
                        ringCard
                        streakCard
                    }

                    // Daily readiness (sleep + recovery + consistency).
                    readinessRow

                    // Calendar-aware workout planner.
                    PlanAroundDayCard()

                    // Wide dot-calendar card with a docked routine row.
                    calendarCard

                    // Split stat row.
                    volumeRow

                    // Add tile.
                    addTile
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(GlowTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(item: $logTarget) { RoutineDetailView(routine: $0) }
            .sheet(isPresented: $showNew) { RoutineEditorView(routine: nil, kind: .fitness) }
            .sheet(isPresented: $showProfile) { ProfileView() }
        }
    }

    // MARK: Title bar

    private var titleBar: some View {
        HStack {
            Text("Today")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(GlowTheme.ink)
            Spacer()
            iconButton("slider.horizontal.3") {}
            iconButton("plus") { showNew = true }
        }
    }

    private func iconButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(GlowTheme.ink)
                .frame(width: 42, height: 42)
                .background(GlowTheme.surface)
                .clipShape(Circle())
        }
    }

    // MARK: Cards

    private var nextRoutine: Routine? {
        todays.first { !RoutineStore.isCompleted($0, on: .now) } ?? todays.first
    }

    private var ringCard: some View {
        Button { if let r = nextRoutine { logTarget = r } } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    ProgressRing(progress: todays.isEmpty ? 0 : Double(doneToday) / Double(todays.count),
                                 lineWidth: 4, label: "\(doneToday)")
                        .frame(width: 52, height: 52)
                    Spacer()
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13)).foregroundStyle(GlowTheme.inkMuted)
                }
                Spacer(minLength: 28)
                Text(nextRoutine?.name ?? "All done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(GlowTheme.ink)
                    .lineLimit(1)
                Text(nextRoutine.map { $0.timeOfDay.title } ?? "Rest day")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
            }
            .padding(16)
            .frame(height: 168, alignment: .topLeading)
            .frame(maxWidth: .infinity)
            .background(GlowTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .pressable()
    }

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(streak)")
                    .font(.system(size: 46, weight: .heavy))
                    .foregroundStyle(streak > 0 ? AnyShapeStyle(GlowTheme.accentGradient) : AnyShapeStyle(GlowTheme.ink))
                Text("days").font(.system(size: 15, weight: .semibold)).foregroundStyle(GlowTheme.inkMuted)
                Spacer()
                Image(systemName: "flame")
                    .font(.system(size: 13)).foregroundStyle(GlowTheme.inkMuted)
            }
            Spacer(minLength: 28)
            Text("Current streak").font(.system(size: 17, weight: .semibold)).foregroundStyle(GlowTheme.ink)
            Text("\(doneToday)/\(todays.count) done today")
                .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
        }
        .padding(16)
        .frame(height: 168, alignment: .topLeading)
        .frame(maxWidth: .infinity)
        .background(GlowTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var calendarCard: some View {
        VStack(spacing: 14) {
            MiniMonthsStrip(completedDays: RoutineStore.completedDays(in: context))
            if let r = nextRoutine {
                Button { logTarget = r } label: {
                    HStack(spacing: 12) {
                        ProgressRing(progress: RoutineStore.isCompleted(r, on: .now) ? 1 : 0,
                                     lineWidth: 3, label: "\(todays.firstIndex(where: { $0.id == r.id }).map { $0 + 1 } ?? 1)")
                            .frame(width: 40, height: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(GlowTheme.ink)
                            Text(r.activeWeekdayLabel).font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(GlowTheme.faint)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(GlowTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var readinessRow: some View {
        let r = SleepStore.readiness(in: context)
        return HStack(spacing: 14) {
            ZStack {
                ProgressRing(progress: Double(r.score) / 100, lineWidth: 4)
                    .frame(width: 46, height: 46)
                Text("\(r.score)").font(.system(size: 15, weight: .heavy)).foregroundStyle(GlowTheme.ink)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Readiness · \(r.label)")
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(GlowTheme.ink)
                Text(r.advice).font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted).lineLimit(2)
            }
            Spacer()
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .background(GlowTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var volumeRow: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Workouts").font(.system(size: 17, weight: .semibold)).foregroundStyle(GlowTheme.ink)
                Text("Last 7 days").font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(weekFitness)").font(.system(size: 30, weight: .heavy)).foregroundStyle(GlowTheme.ink)
                Text("done").font(.system(size: 13, weight: .semibold)).foregroundStyle(GlowTheme.inkMuted)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 18)
        .background(GlowTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var addTile: some View {
        Button { showNew = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(GlowTheme.inkMuted)
                .frame(width: 92, height: 92)
                .background(GlowTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .pressable()
    }
}

/// Three-month dot strip (Jan/Feb/Mar style) like the reference.
struct MiniMonthsStrip: View {
    var completedDays: Set<Date>
    private let cal = Calendar.current

    private var months: [(label: String, days: [Date])] {
        let now = Date()
        return (0..<3).reversed().compactMap { back in
            guard let m = cal.date(byAdding: .month, value: -back, to: now),
                  let comps = cal.dateComponents([.year, .month], from: m) as DateComponents?,
                  let start = cal.date(from: comps),
                  let range = cal.range(of: .day, in: .month, for: m) else { return nil }
            let f = DateFormatter(); f.dateFormat = "MMM"
            let days = range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: start) }
            return (f.string(from: m), days)
        }
    }

    private let rows = Array(repeating: GridItem(.fixed(7), spacing: 4), count: 5)

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ForEach(months, id: \.label) { month in
                VStack(spacing: 8) {
                    Text(month.label).font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                    LazyHGrid(rows: rows, spacing: 4) {
                        ForEach(month.days, id: \.self) { day in
                            let done = completedDays.contains(cal.startOfDay(for: day))
                            let today = cal.isDateInToday(day)
                            Circle()
                                .fill(today ? AnyShapeStyle(GlowTheme.accentGradient)
                                      : (done ? AnyShapeStyle(GlowTheme.ink) : AnyShapeStyle(GlowTheme.faint)))
                                .frame(width: 5, height: 5)
                                .shadow(color: today ? GlowTheme.accent.opacity(0.8) : .clear, radius: 3)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private extension Routine {
    /// A short label like "Mondays" / "Mon·Wed·Fri" / "Daily".
    var activeWeekdayLabel: String {
        if activeWeekdays.count == 7 { return "Daily" }
        let syms = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        if activeWeekdays.count == 1, let d = activeWeekdays.first { return syms[d] + "s" }
        return activeWeekdays.sorted().map { syms[$0] }.joined(separator: "·")
    }
}
