import SwiftUI
import SwiftData

/// Lists all routines of a given kind (Fitness or Skincare) and offers an editor.
struct RoutineListView: View {
    let kind: RoutineKind
    @Environment(\.modelContext) private var context
    @Query private var routines: [Routine]
    @State private var editing: Routine?
    @State private var showingNew = false
    @State private var showingProfile = false
    @State private var showingSmartAdd = false

    private var filtered: [Routine] {
        routines.filter { $0.kind == kind }.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(kind.title)
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(GlowTheme.ink)
                        .padding(.top, 8)

                    if kind == .fitness {
                        DNABanner(onOpen: { showingProfile = true })
                    }

                    if filtered.isEmpty {
                        if kind == .fitness {
                            EmptyState(
                                icon: "figure.strengthtraining.traditional",
                                title: "No workouts yet",
                                message: "Tap ✨ to get a workout suggested for right now, generate a personalized plan from your profile, or paste one from any AI.",
                                actionTitle: "Suggest a workout",
                                action: { showingSmartAdd = true }
                            )
                        } else {
                            EmptyState(
                                icon: "drop.fill",
                                title: "No skincare routines",
                                message: "Add a morning or evening routine and Forge will remind you to keep it consistent.",
                                actionTitle: "Add a routine",
                                action: { showingNew = true }
                            )
                        }
                    }

                    ForEach(filtered) { routine in
                        Button { editing = routine } label: {
                            RoutineCardView(routine: routine)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(GlowTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if kind == .fitness {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { showingProfile = true } label: {
                            Image(systemName: "person.crop.circle.badge.plus")
                        }
                    }
                }
                if kind == .fitness {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showingSmartAdd = true } label: { Image(systemName: "wand.and.stars") }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(item: $editing) { routine in
                RoutineEditorView(routine: routine, kind: kind)
            }
            .sheet(isPresented: $showingNew) {
                RoutineEditorView(routine: nil, kind: kind)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingSmartAdd) {
                SmartAddView(onCreated: { editing = $0 })
            }
        }
    }
}

/// A prominent banner making DNA feel central to the app — shows the user's key
/// genetic edge if set, or invites them to import their DNA.
struct DNABanner: View {
    @Query private var profiles: [UserProfile]
    var onOpen: () -> Void
    private var p: UserProfile? { profiles.first }
    private var hasDNA: Bool {
        guard let p else { return false }
        return p.aerobic != .unknown || p.caffeine != .unknown || p.carb != .unknown
    }

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(GlowTheme.accent.opacity(0.15)).frame(width: 46, height: 46)
                    Image(systemName: "dna").font(.system(size: 20, weight: .semibold)).foregroundStyle(GlowTheme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    if hasDNA, let p {
                        Text("Tuned to your DNA").font(.system(size: 15, weight: .semibold)).foregroundStyle(GlowTheme.ink)
                        Text(dnaSummary(p)).font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted).lineLimit(1)
                    } else {
                        Text("Make it yours — add your DNA").font(.system(size: 15, weight: .semibold)).foregroundStyle(GlowTheme.ink)
                        Text("Import a DNA file to personalize training & fuel").font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(GlowTheme.faint)
            }
            .padding(16)
            .background(GlowTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func dnaSummary(_ p: UserProfile) -> String {
        var bits: [String] = []
        if p.aerobic == .high { bits.append("High aerobic") }
        if p.caffeine == .fast { bits.append("Fast caffeine") }
        if p.carb == .resilient { bits.append("Carb-resilient") }
        return bits.isEmpty ? "View your genetic insights" : bits.joined(separator: " · ")
    }
}

struct RoutineCardView: View {
    let routine: Routine
    var body: some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(routine.name)
                        .font(GlowTheme.title(20))
                        .foregroundStyle(GlowTheme.ink)
                    Spacer()
                    Label(routine.timeOfDay.title, systemImage: routine.timeOfDay.systemImage)
                        .font(GlowTheme.caption())
                        .foregroundStyle(GlowTheme.inkMuted)
                }
                if let target = routine.targetSummary {
                    HStack(spacing: 6) {
                        Image(systemName: routine.targetMetric?.systemImage ?? "target")
                        Text("Target: \(target)")
                    }
                    .font(GlowTheme.caption())
                    .foregroundStyle(GlowTheme.accent)
                }
                ForEach(routine.orderedSteps.prefix(4)) { step in
                    HStack(spacing: 8) {
                        Circle().fill(GlowTheme.faint).frame(width: 5, height: 5)
                        Text(step.title).font(GlowTheme.body(14)).foregroundStyle(GlowTheme.ink)
                        if !step.summary.isEmpty {
                            Text(step.summary).font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                        }
                    }
                }
                if routine.steps.count > 4 {
                    Text("+\(routine.steps.count - 4) more")
                        .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                }
            }
        }
    }
}
