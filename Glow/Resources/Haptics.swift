import UIKit

/// Tiny haptic helper — makes interactions feel responsive and rewarding.
/// Lightweight, no dependencies.
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func toggle() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func celebrate() {
        // A little double-tap rhythm for completing something.
        let gen = UIImpactFeedbackGenerator(style: .rigid)
        gen.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
