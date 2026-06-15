import SwiftUI
import SwiftData

/// Nutrition tab — the Bihari body-recomposition plan as a daily meal checklist
/// plus fat-loss guidance and a running protein total.
struct NutritionView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Meal.slotRaw) private var meals: [Meal]

    private var sortedMeals: [Meal] {
        meals.sorted { $0.slot.sortIndex < $1.slot.sortIndex }
    }
    private var proteinLogged: Int {
        sortedMeals.filter { $0.isLoggedToday }.reduce(0) { $0 + $1.approxProteinGrams }
    }
    private var proteinTotal: Int {
        sortedMeals.reduce(0) { $0 + $1.approxProteinGrams }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("NUTRITION")
                        .font(GlowTheme.display())
                        .foregroundStyle(GlowTheme.ink)
                        .padding(.top, 8)

                    proteinCard

                    Text("TODAY'S PLAN")
                        .font(GlowTheme.headline(14)).kerning(1)
                        .foregroundStyle(GlowTheme.inkMuted)

                    ForEach(sortedMeals) { meal in
                        mealRow(meal)
                    }

                    Text("FAT-LOSS TIPS")
                        .font(GlowTheme.headline(14)).kerning(1)
                        .foregroundStyle(GlowTheme.inkMuted)
                        .padding(.top, 6)

                    ForEach(SeedData.fatLossTips, id: \.title) { tip in
                        GlowPanel {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tip.title).font(GlowTheme.headline(15)).foregroundStyle(GlowTheme.accent)
                                Text(tip.body).font(GlowTheme.body(14)).foregroundStyle(GlowTheme.ink)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(GlowTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var proteinCard: some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 6) {
                Text("PROTEIN LOGGED TODAY")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(proteinLogged)")
                        .font(GlowTheme.numeral(56))
                        .foregroundStyle(GlowTheme.ink)
                    Text("/ \(proteinTotal) g")
                        .font(GlowTheme.title())
                        .foregroundStyle(GlowTheme.inkMuted)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(GlowTheme.faint).frame(height: 8)
                        Capsule().fill(GlowTheme.accentGradient)
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
    }

    private var progress: CGFloat {
        guard proteinTotal > 0 else { return 0 }
        return min(1, CGFloat(proteinLogged) / CGFloat(proteinTotal))
    }

    private func mealRow(_ meal: Meal) -> some View {
        Button {
            meal.lastLoggedDay = meal.isLoggedToday ? nil : .now
            try? context.save()
        } label: {
            GlowPanel {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: meal.isLoggedToday ? "checkmark.circle.fill" : meal.slot.systemImage)
                        .font(.system(size: 20))
                        .foregroundStyle(meal.isLoggedToday ? GlowTheme.accent : GlowTheme.inkMuted)
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(meal.slot.title.uppercased())
                                .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                            Spacer()
                            Text("\(meal.approxProteinGrams)g P · \(meal.approxCalories) kcal")
                                .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
                        }
                        Text(meal.title).font(GlowTheme.headline(16)).foregroundStyle(GlowTheme.ink)
                        Text(meal.option).font(GlowTheme.body(14)).foregroundStyle(GlowTheme.ink)
                        if !meal.rationale.isEmpty {
                            Text(meal.rationale).font(GlowTheme.caption()).foregroundStyle(GlowTheme.accent)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
