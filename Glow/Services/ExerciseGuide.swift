import Foundation

/// Lightweight "how to do it" knowledge for common movements — step-by-step
/// form, target muscles, common mistakes, and a scaling option. Pure text +
/// keyword matching so it stays tiny and instant (no media bundled).
enum ExerciseGuide {

    struct Guide {
        let name: String
        let targets: [String]      // muscles worked
        let steps: [String]        // ordered how-to cues
        let mistakes: [String]     // common errors to avoid
        let scaling: String        // easier variation
        let breathing: String      // breath pattern
    }

    /// Best matching guide for a movement title, else a sensible generic one.
    static func guide(for title: String) -> Guide {
        let t = title.lowercased()
        for (needles, g) in table where needles.contains(where: { t.contains($0) }) {
            return g
        }
        return generic(title)
    }

    private static func generic(_ title: String) -> Guide {
        Guide(
            name: cleaned(title),
            targets: ["Full body"],
            steps: [
                "Set up with a tall, braced posture and neutral spine.",
                "Move through a controlled, full range of motion.",
                "Keep tension on the working muscles; don't rush.",
                "Exhale on the effort, inhale on the return."
            ],
            mistakes: ["Rushing reps", "Holding your breath", "Using momentum instead of muscle"],
            scaling: "Reduce range, load, or reps until the movement feels clean.",
            breathing: "Exhale on exertion, inhale on the way back."
        )
    }

    /// Strip warm-up phase prefixes / emoji so the title reads cleanly.
    static func cleaned(_ title: String) -> String {
        var s = title
        for p in ["🔥 ", "Raise: ", "Mobilize: ", "Activate: ", "Potentiate: "] {
            s = s.replacingOccurrences(of: p, with: "")
        }
        return s.trimmingCharacters(in: .whitespaces)
    }

    private static let table: [([String], Guide)] = [
        (["squat", "goblet"], Guide(
            name: "Squat",
            targets: ["Quads", "Glutes", "Core"],
            steps: [
                "Stand with feet shoulder-width, toes slightly out.",
                "Brace your core and keep your chest up.",
                "Push hips back and bend knees, tracking them over your toes.",
                "Descend until thighs are about parallel (or your clean depth).",
                "Drive through mid-foot to stand tall, squeezing glutes at the top."
            ],
            mistakes: ["Knees caving inward", "Heels lifting off the floor", "Rounding the lower back"],
            scaling: "Squat to a box/chair, or hold a light weight at your chest (goblet).",
            breathing: "Inhale on the way down, exhale as you stand."
        )),
        (["push-up", "push up", "pushup"], Guide(
            name: "Push-up",
            targets: ["Chest", "Triceps", "Shoulders", "Core"],
            steps: [
                "Hands slightly wider than shoulders, body in one straight line.",
                "Brace your core and squeeze your glutes.",
                "Lower with elbows at ~45° until your chest nearly touches the floor.",
                "Press back up to full extension without sagging your hips."
            ],
            mistakes: ["Hips sagging or piking", "Flaring elbows to 90°", "Half range of motion"],
            scaling: "Elevate your hands on a bench, or drop to your knees.",
            breathing: "Inhale down, exhale as you press up."
        )),
        (["plank"], Guide(
            name: "Plank",
            targets: ["Core", "Shoulders", "Glutes"],
            steps: [
                "Forearms under shoulders, elbows bent 90°.",
                "Form a straight line from head to heels.",
                "Brace your abs and squeeze glutes — pull belly button to spine.",
                "Hold steady, breathing normally for the set time."
            ],
            mistakes: ["Hips too high or sagging", "Holding breath", "Letting the lower back arch"],
            scaling: "Drop to your knees, or shorten the hold to 15–20s.",
            breathing: "Breathe steadily — never hold your breath."
        )),
        (["deadlift", "hinge", "swing", "kettlebell"], Guide(
            name: "Hip Hinge / Deadlift",
            targets: ["Hamstrings", "Glutes", "Back", "Core"],
            steps: [
                "Feet hip-width, bar/weight over mid-foot.",
                "Hinge from the hips, soft knees, flat back.",
                "Grip and brace; pull the slack out before lifting.",
                "Drive the floor away, standing tall with glutes — bar stays close.",
                "Lower under control by pushing hips back first."
            ],
            mistakes: ["Rounding the back", "Squatting instead of hinging", "Jerking the weight"],
            scaling: "Use a kettlebell or trap bar; reduce range to a comfortable hinge.",
            breathing: "Big breath and brace before the lift; exhale at the top."
        )),
        (["press", "overhead", "shoulder"], Guide(
            name: "Overhead / Strict Press",
            targets: ["Shoulders", "Triceps", "Upper chest", "Core"],
            steps: [
                "Stand tall, weights at shoulder height, elbows under wrists.",
                "Brace your core and squeeze your glutes.",
                "Press straight overhead, moving your head 'through' the window.",
                "Finish with biceps by your ears; lower under control."
            ],
            mistakes: ["Arching the lower back", "Pressing the bar forward", "Shrugging at the bottom"],
            scaling: "Use lighter dumbbells or do a seated press for support.",
            breathing: "Exhale as you press up, inhale on the way down."
        )),
        (["pull-up", "pull up", "chin-up", "row", "pull"], Guide(
            name: "Pull / Row",
            targets: ["Lats", "Upper back", "Biceps"],
            steps: [
                "Start from a full hang or with arms extended (row).",
                "Set your shoulders down and back (no shrug).",
                "Pull your elbows down/back, leading with the chest.",
                "Squeeze at the top, then lower with control to full stretch."
            ],
            mistakes: ["Using momentum/kipping unintentionally", "Half reps", "Shrugging shoulders up"],
            scaling: "Use a band for assistance, or do ring/inverted rows.",
            breathing: "Exhale as you pull, inhale as you lower."
        )),
        (["burpee"], Guide(
            name: "Burpee",
            targets: ["Full body", "Conditioning"],
            steps: [
                "From standing, drop into a squat and place hands on the floor.",
                "Jump or step your feet back to a plank.",
                "Lower your chest to the floor (optional push-up).",
                "Drive feet back in, then jump up with arms overhead."
            ],
            mistakes: ["Sagging hips in the plank", "Skipping full hip extension on the jump", "Going too fast and losing form"],
            scaling: "Step back/in instead of jumping; skip the push-up.",
            breathing: "Find a steady rhythm — don't hold your breath."
        )),
        (["run", "jog", "row", "bike", "zone-2", "zone 2", "cardio", "engine"], Guide(
            name: "Steady Cardio (Zone 2)",
            targets: ["Heart", "Lungs", "Endurance"],
            steps: [
                "Warm up easy for 3–5 minutes.",
                "Settle into a conversational pace — you can talk in short sentences.",
                "Keep a relaxed, repeatable rhythm and good posture.",
                "Cool down with an easy few minutes at the end."
            ],
            mistakes: ["Going too hard for 'zone 2'", "Tensing shoulders", "Skipping the cool-down"],
            scaling: "Walk/jog intervals; reduce duration and build up weekly.",
            breathing: "Nasal or relaxed rhythmic breathing; stay conversational."
        )),
        (["stretch", "mobility", "cool", "yoga", "warm-up", "circle", "swing"], Guide(
            name: "Mobility / Warm-up",
            targets: ["Joints", "Range of motion"],
            steps: [
                "Move slowly and deliberately through a pain-free range.",
                "Gradually increase range as the tissue warms.",
                "Avoid bouncing — control each rep.",
                "Breathe into the stretch; relax into the position."
            ],
            mistakes: ["Forcing end range", "Bouncing", "Holding your breath"],
            scaling: "Reduce range; support yourself on a wall or chair.",
            breathing: "Slow, deep breaths; exhale as you ease deeper."
        )),
    ]
}
