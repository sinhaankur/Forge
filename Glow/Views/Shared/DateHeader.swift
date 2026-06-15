import SwiftUI

/// The big-numeral date header from the reference: huge day number, month/year,
/// and weekday on the right.
struct DateHeader: View {
    var date: Date = .now
    var subtitle: String? = nil

    private var dayNumber: String {
        let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: date)
    }
    private var monthYear: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: date).uppercased()
    }
    private var weekday: String {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(dayNumber)
                .font(GlowTheme.numeral())
                .foregroundStyle(GlowTheme.ink)
            HStack(alignment: .firstTextBaseline) {
                Text(monthYear)
                    .font(GlowTheme.headline(15))
                    .kerning(1)
                    .foregroundStyle(GlowTheme.inkMuted)
                Spacer()
                Text(weekday)
                    .font(GlowTheme.title())
                    .foregroundStyle(GlowTheme.ink)
            }
            if let subtitle {
                Text(subtitle)
                    .font(GlowTheme.caption())
                    .foregroundStyle(GlowTheme.accent)
                    .padding(.top, 4)
            }
        }
    }
}
