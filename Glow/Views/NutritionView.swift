import SwiftUI
import SwiftData

/// Nutrition tab — the Bihari body-recomposition plan as a daily meal checklist
/// plus fat-loss guidance and a running protein total.
struct NutritionView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Meal.slotRaw) private var meals: [Meal]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

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
                    Text("Nutrition")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(GlowTheme.ink)
                        .padding(.top, 8)

                    proteinCard

                    if let tips = geneticFuelingTips, !tips.isEmpty {
                        geneticFuelingCard(tips)
                    }

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

    /// Personalized fueling guidance derived from the user's on-device genetic
    /// trait toggles. Returns nil when no traits are set.
    private var geneticFuelingTips: [(icon: String, text: String)]? {
        guard let p = profile else { return nil }
        var tips: [(String, String)] = []
        if p.carb == .resilient {
            tips.append(("leaf.circle.fill",
                "Carb-resilient: keep clean carbs (oats, brown rice, sweet potato) around your workout windows to fuel training — no need to fear them."))
        }
        if p.lactoseTolerant {
            tips.append(("cup.and.saucer.fill",
                "Dairy-friendly: Greek yogurt, cottage cheese, paneer, and whey isolate are excellent, highly bioavailable recovery protein for you."))
        }
        if p.aerobic == .high {
            tips.append(("wind",
                "High aerobic response: prioritize steady fueling for zone-2 work — slightly more carbs on long-cardio days."))
        }
        if p.caffeine == .fast {
            tips.append(("bolt.fill",
                "Fast caffeine metabolizer: a black coffee 30–45 min pre-workout gives a clean boost without disrupting sleep."))
        }
        if p.vitaminD == .lower {
            tips.append(("sun.max.fill",
                "Vitamin D tends to run low for you: prioritize sun, fatty fish, eggs, and consider testing levels with your doctor."))
        }
        if p.b12 == .reduced {
            tips.append(("pills.fill",
                "Reduced methylation: favor B12/folate-rich foods (eggs, dairy, leafy greens); methylated B-vitamin forms may suit you better."))
        }
        return tips
    }

    private func geneticFuelingCard(_ tips: [(icon: String, text: String)]) -> some View {
        GlowPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label("GENETIC FUELING", systemImage: "dna")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.accent)
                ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: tip.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(GlowTheme.accent)
                            .frame(width: 18)
                        Text(tip.text)
                            .font(GlowTheme.body(14))
                            .foregroundStyle(GlowTheme.ink)
                    }
                }
                Text("Based on the genetic traits in your profile · stays on this device")
                    .font(GlowTheme.caption()).foregroundStyle(GlowTheme.inkMuted)
            }
        }
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
