import SwiftUI

/// Minimal theme for the watch target — just the brand accent. Kept separate
/// from the iOS `GlowTheme` (which pulls in UIKit-heavy helpers) so the watch
/// target stays lean.
enum GlowTheme {
    static let accent = Color(red: 0.098, green: 0.890, blue: 0.761) // #19E3C2

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.098, green: 0.890, blue: 0.761),
                     Color(red: 0.239, green: 0.941, blue: 0.839)],
            startPoint: .leading, endPoint: .trailing
        )
    }
}
