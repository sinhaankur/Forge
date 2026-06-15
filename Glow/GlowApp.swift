import SwiftUI
import SwiftData

@main
struct GlowApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Routine.self, RoutineStep.self, RoutineCompletion.self, Meal.self,
                UserProfile.self, SleepLog.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        // Seed on first launch.
        SeedData.seedIfNeeded(container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootContainer()
                .tint(GlowTheme.accent)
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}

/// Shows the branded loading screen briefly, then the app.
struct RootContainer: View {
    @State private var loading = true
    var body: some View {
        ZStack {
            RootView()
            if loading {
                LoadingView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_300_000_000) // ~1.3s splash
            withAnimation(.easeInOut(duration: 0.4)) { loading = false }
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var routines: [Routine]
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "checklist") }

            RoutineListView(kind: .fitness)
                .tabItem { Label("Fitness", systemImage: "figure.strengthtraining.traditional") }

            SleepView()
                .tabItem { Label("Sleep", systemImage: "moon.stars.fill") }

            CareView()
                .tabItem { Label("Care", systemImage: "heart.fill") }

            ProgressView_Glow()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
        }
        .fullScreenCover(isPresented: .init(get: { !hasSeenWelcome }, set: { _ in })) {
            WelcomeView { hasSeenWelcome = true }
        }
        .task {
            await NotificationService.shared.requestAuthorization()
            await NotificationService.shared.reschedule(for: routines)
            await NotificationService.shared.scheduleSmartReminders()
            pushSnapshot()
            // Handle completion commands coming from the watch.
            ConnectivityService.shared.onCommand = { command in
                if case let .complete(routineID, achieved) = command {
                    if let r = routines.first(where: { String($0.persistentModelID.hashValue) == routineID }) {
                        RoutineStore.toggleCompletion(r, on: .now, achievedValue: achieved, in: context)
                        pushSnapshot()
                    }
                } else if case .requestSnapshot = command {
                    pushSnapshot()
                }
            }
        }
        .onChange(of: routines.count) {
            Task { await NotificationService.shared.reschedule(for: routines) }
            pushSnapshot()
        }
    }

    private func pushSnapshot() {
        ConnectivityService.shared.push(RoutineStore.snapshot(in: context))
    }
}
