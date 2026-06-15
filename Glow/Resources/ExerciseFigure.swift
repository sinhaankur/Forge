import SwiftUI

/// Maps an exercise/warm-up title to a representative Apple `figure.*` workout
/// symbol. Used as the always-available illustration; if a rendered figure
/// asset of the same name exists in the catalog, the UI prefers that.
enum ExerciseFigure {

    /// Best-matching SF Symbol for a movement title (case-insensitive keywords).
    static func symbol(for title: String) -> String {
        let t = title.lowercased()
        func has(_ words: String...) -> Bool { words.contains { t.contains($0) } }

        // Warm-up phases (titles are prefixed with the phase, e.g. "🔥 Raise: …").
        if has("row", "bike", "assault") { return "figure.indoor.cycle" }
        if has("jump rope", "jump rope", "skip") { return "figure.jumprope" }
        if has("jumping jack", "high knee", "butt kick", "march") { return "figure.highintensity.intervaltraining" }
        if has("run", "jog", "sprint", "shuttle") { return "figure.run" }
        if has("walk", "cooldown", "step-up", "step up") { return "figure.walk" }

        // Strength / lifts.
        if has("squat", "goblet", "wall ball", "thruster") { return "figure.strengthtraining.functional" }
        if has("deadlift", "hinge", "swing", "kettlebell", "good morning", "row ", "pull") {
            return "figure.strengthtraining.traditional"
        }
        if has("press", "push-up", "push up", "pushup", "bench", "dip") { return "figure.strengthtraining.functional" }

        // Core / gymnastics.
        if has("plank", "hollow", "dead bug", "sit-up", "crunch", "knee raise", "leg raise", "core", "shoulder tap") {
            return "figure.core.training"
        }
        if has("pull-up", "pull up", "chin-up", "ring") { return "figure.play" }

        // Mobility / stretch.
        if has("stretch", "mobil", "swing", "circle", "cat", "cow", "inchworm", "bridge", "glute") {
            return "figure.flexibility"
        }
        if has("yoga") { return "figure.yoga" }
        if has("cool", "rest") { return "figure.cooldown" }

        return "figure.mixed.cardio"
    }

    /// Asset name for a rendered figure, if we bundle one (e.g. Blender renders).
    /// Falls back to nil so the UI uses the SF Symbol.
    static func renderedAssetName(for title: String) -> String? {
        let key = title.lowercased()
        for (needle, asset) in renderedAssets where key.contains(needle) {
            return asset
        }
        return nil
    }

    /// Map of movement keyword -> bundled image asset name (added as assets ship).
    private static let renderedAssets: [(String, String)] = [
        ("squat", "fig-squat"),
        ("push-up", "fig-pushup"),
        ("push up", "fig-pushup"),
        ("plank", "fig-plank"),
        ("deadlift", "fig-deadlift"),
        ("burpee", "fig-burpee"),
        ("lunge", "fig-lunge"),
    ]
}
