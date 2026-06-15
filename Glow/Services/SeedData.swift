import Foundation
import SwiftData

/// Populates the store with starter routines and the Bihari body-recomposition
/// nutrition plan on first launch.
enum SeedData {

    /// Inserts seed content if the store is empty.
    static func seedIfNeeded(_ context: ModelContext) {
        let routineCount = (try? context.fetchCount(FetchDescriptor<Routine>())) ?? 0
        let mealCount = (try? context.fetchCount(FetchDescriptor<Meal>())) ?? 0
        let profileCount = (try? context.fetchCount(FetchDescriptor<UserProfile>())) ?? 0
        if routineCount == 0 { seedRoutines(context) }
        if mealCount == 0 { seedMeals(context) }
        if profileCount == 0 { seedProfile(context) }
        try? context.save()
    }

    /// Seed a starter profile with sensible defaults. Genetic-trait fields are
    /// left unset (.unknown) — the user fills them by uploading their DNA file
    /// or tapping "Apply my DNA markers". (No genotypes are stored in code.)
    private static func seedProfile(_ context: ModelContext) {
        context.insert(UserProfile())
    }

    // MARK: Fitness + Skincare routines

    private static func seedRoutines(_ context: ModelContext) {
        // --- Fitness: morning strength session with a session target ---
        let strength = Routine(
            name: "Morning Strength",
            kind: .fitness,
            timeOfDay: .morning,
            notes: "Protect the muscle base; midsection fat loss focus.",
            colorHex: "#FF7E5F",
            activeWeekdays: [2, 4, 6], // Mon, Wed, Fri
            reminderMinutes: 7 * 60,
            targetMetric: .reps,
            targetValue: 120
        )
        strength.steps = [
            RoutineStep(title: "Goblet Squats", detail: "Controlled, full depth", order: 0, sets: 4, reps: 12),
            RoutineStep(title: "Push-ups", detail: "Chest to floor", order: 1, sets: 4, reps: 15),
            RoutineStep(title: "Bent-over Rows", detail: "Squeeze shoulder blades", order: 2, sets: 4, reps: 12),
            RoutineStep(title: "Plank", detail: "Brace the core", order: 3, durationSeconds: 60),
        ]
        context.insert(strength)

        // --- Fitness: conditioning with a calorie target ---
        let cardio = Routine(
            name: "Fat-Burn Conditioning",
            kind: .fitness,
            timeOfDay: .evening,
            notes: "Keep heart rate up; aim for the calorie target.",
            colorHex: "#FF7E5F",
            activeWeekdays: [3, 5, 7], // Tue, Thu, Sat
            reminderMinutes: 18 * 60,
            targetMetric: .calories,
            targetValue: 350
        )
        cardio.steps = [
            RoutineStep(title: "Brisk Walk / Jog", detail: "Zone 2", order: 0, durationSeconds: 20 * 60),
            RoutineStep(title: "Jump Rope", detail: "Intervals", order: 1, sets: 5, durationSeconds: 60),
            RoutineStep(title: "Mountain Climbers", order: 2, sets: 3, reps: 30),
        ]
        context.insert(cardio)

        // --- Skincare: morning ---
        let amSkin = Routine(
            name: "Morning Skincare",
            kind: .skincare,
            timeOfDay: .morning,
            notes: "Keep it simple and consistent.",
            colorHex: "#4F8CFF",
            activeWeekdays: Array(1...7),
            reminderMinutes: 7 * 60 + 30
        )
        amSkin.steps = [
            RoutineStep(title: "Gentle Cleanser", detail: "Lukewarm water", order: 0),
            RoutineStep(title: "Vitamin C Serum", detail: "Antioxidant protection", order: 1),
            RoutineStep(title: "Moisturizer", order: 2),
            RoutineStep(title: "Sunscreen SPF 50", detail: "Reapply midday if outdoors", order: 3),
        ]
        context.insert(amSkin)

        // --- Skincare: evening ---
        let pmSkin = Routine(
            name: "Evening Skincare",
            kind: .skincare,
            timeOfDay: .evening,
            notes: "Repair overnight.",
            colorHex: "#4F8CFF",
            activeWeekdays: Array(1...7),
            reminderMinutes: 22 * 60
        )
        pmSkin.steps = [
            RoutineStep(title: "Double Cleanse", detail: "Oil cleanser then gentle cleanser", order: 0),
            RoutineStep(title: "Retinol", detail: "Start 2–3× per week", order: 1),
            RoutineStep(title: "Night Moisturizer", order: 2),
        ]
        context.insert(pmSkin)
    }

    // MARK: Nutrition — Bihari body-recomposition plan

    private static func seedMeals(_ context: ModelContext) {
        let meals: [Meal] = [
            Meal(
                slot: .breakfast,
                title: "High-Protein Start",
                option: "3 egg whites + 1 whole egg scrambled with onion & green chili, OR a savory sattu cheela with a side of curd.",
                rationale: "High protein to kickstart muscle repair.",
                approxProteinGrams: 25, approxCalories: 280
            ),
            Meal(
                slot: .midMorning,
                title: "Sattu Sharbat",
                option: "2–3 tbsp sattu in water with lemon, roasted cumin, black salt & mint (unsweetened).",
                rationale: "High fiber + protein curbs hunger and prevents overeating at lunch.",
                approxProteinGrams: 10, approxCalories: 120
            ),
            Meal(
                slot: .lunch,
                title: "Balanced Plate",
                option: "2 whole-wheat or millet rotis + a large bowl of thick dal + a big portion of bhindi/parwal bhujia (minimal oil) + 150g grilled chicken, paneer, or fish.",
                rationale: "Balanced carbs, heavy on protein and vegetable volume.",
                approxProteinGrams: 45, approxCalories: 650
            ),
            Meal(
                slot: .eveningSnack,
                title: "Light & Crunchy",
                option: "Roasted makhana tossed with a drop of ghee & turmeric, or a handful of roasted chana.",
                rationale: "Low-calorie, crunchy, packed with micronutrients.",
                approxProteinGrams: 8, approxCalories: 150
            ),
            Meal(
                slot: .dinner,
                title: "Light Dinner",
                option: "Chicken or paneer curry in a tomato-onion base (limit mustard oil) + large cucumber–tomato salad + small portion brown rice or 1 roti.",
                rationale: "Lower carbs before sleep to favor overnight fat-burning.",
                approxProteinGrams: 35, approxCalories: 450
            ),
        ]
        meals.forEach(context.insert)
    }

    /// Static guidance tips shown on the Nutrition tab.
    static let fatLossTips: [(title: String, body: String)] = [
        ("The Oil Audit",
         "Mustard oil is healthy but calorie-dense. Measure with a spoon — aim for 1–2 tsp per meal, don't pour."),
        ("Watch the Aloo",
         "Swap half the potato in sabzis/chokha for high-fiber veg like cauliflower, spinach, ridge gourd (nenua), or parwal."),
        ("Hydration",
         "Drink 3–4 liters of water a day. Thirst is often mistaken for hunger and drives extra snacking."),
        ("Protein First",
         "Build each meal around protein: sattu, thick dals, paneer/tofu, eggs, chicken, or fish."),
        ("Smart Carbs",
         "Prefer whole-wheat rotis, oats, jowar/bajra millets over white rice and litti. Keep rice portions small."),
    ]
}
