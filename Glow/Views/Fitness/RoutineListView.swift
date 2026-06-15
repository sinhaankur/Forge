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

                    if filtered.isEmpty {
                        Text("No \(kind.title.lowercased()) routines yet. Tap + to create one.")
                            .font(GlowTheme.body(15))
                            .foregroundStyle(GlowTheme.inkMuted)
                            .padding(.vertical, 30)
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
