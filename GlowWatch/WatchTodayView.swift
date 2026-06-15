import SwiftUI

/// Watch home: today's routines as a check-off list, with the current streak at
/// the top. Reads the snapshot pushed by the phone via WatchConnectivity and
/// sends completion commands back.
struct WatchTodayView: View {
    @StateObject private var connectivity = ConnectivityService.shared

    private var items: [TodaySnapshot.Item] {
        connectivity.snapshot?.items ?? []
    }
    private var streak: Int { connectivity.snapshot?.streak ?? 0 }

    var body: some View {
        NavigationStack {
            List {
                if streak > 0 {
                    HStack {
                        Image(systemName: "flame.fill").foregroundStyle(GlowTheme.accent)
                        Text("\(streak)-day streak")
                            .font(.system(.headline, design: .rounded))
                    }
                    .listRowBackground(Color.clear)
                }

                if items.isEmpty {
                    Text("Open Glow on your iPhone to sync today's routines.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items) { item in
                        WatchRoutineRow(item: item) { complete(item) }
                    }
                }
            }
            .navigationTitle("Today")
            .onAppear { connectivity.send(.requestSnapshot) }
        }
    }

    private func complete(_ item: TodaySnapshot.Item) {
        // The phone owns the data model; it records the completion and pushes
        // back an updated snapshot.
        connectivity.send(.complete(routineID: item.id, achievedValue: 0))
    }
}

struct WatchRoutineRow: View {
    let item: TodaySnapshot.Item
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                Image(systemName: item.completedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.completedToday ? GlowTheme.accent : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(.headline, design: .rounded))
                        .strikethrough(item.completedToday, color: GlowTheme.accent)
                    HStack(spacing: 4) {
                        Text("\(item.stepCount) steps")
                        if let t = item.targetSummary { Text("· 🎯 \(t)") }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}
