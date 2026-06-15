import SwiftUI

/// A friendly empty-state placeholder — icon, message, and an optional action —
/// so new users (and family) are never staring at a blank screen.
struct EmptyState: View {
    var icon: String
    var title: String
    var message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(GlowTheme.surface).frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(GlowTheme.accent)
            }
            Text(title)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(GlowTheme.ink)
            Text(message)
                .font(GlowTheme.body(14))
                .foregroundStyle(GlowTheme.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 20).padding(.vertical, 11)
                        .background(GlowTheme.accentGradient)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 24)
    }
}
