import SwiftUI

/// Minimal theme for the watch target — just the brand accent. Kept separate
/// from the iOS `GlowTheme` (which pulls in UIKit-heavy helpers) so the watch
/// target stays lean.
enum GlowTheme {
    static let accent = Color(red: 1.0, green: 0.494, blue: 0.372) // #FF7E5F

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.494, blue: 0.372),
                     Color(red: 0.996, green: 0.706, blue: 0.482)],
            startPoint: .leading, endPoint: .trailing
        )
    }
}
