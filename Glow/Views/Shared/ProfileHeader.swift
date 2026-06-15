import SwiftUI

/// A circular avatar — shows the user's photo if set, else their initials on the
/// accent gradient. Lightweight (no image library).
struct Avatar: View {
    var name: String
    var imageData: Data?
    var size: CGFloat = 44

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let s = parts.compactMap { $0.first }.map(String.init).joined()
        return s.isEmpty ? "·" : s.uppercased()
    }

    var body: some View {
        Group {
            if let data = imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                ZStack {
                    GlowTheme.accentGradient
                    Text(initials)
                        .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

/// A compact greeting header: avatar + "Hello, <name>" — makes the app feel
/// personally the user's. Tapping the avatar fires `onTap` (open profile).
struct ProfileHeader: View {
    var name: String
    var imageData: Data?
    var subtitle: String? = nil
    var onTap: () -> Void = {}

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Avatar(name: name, imageData: imageData, size: 46)
                VStack(alignment: .leading, spacing: 1) {
                    Text(name.isEmpty ? greeting : "\(greeting),")
                        .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                    Text(name.isEmpty ? "Set up your profile" : name)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(GlowTheme.ink)
                }
                Spacer()
                if let subtitle {
                    Text(subtitle).font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
