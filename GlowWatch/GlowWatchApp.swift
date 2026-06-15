import SwiftUI

@main
struct GlowWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchTodayView()
                .tint(GlowTheme.accent)
        }
    }
}
