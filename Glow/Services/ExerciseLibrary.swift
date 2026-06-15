import Foundation

/// A structured, reusable knowledge base of CrossFit warm-ups and movements.
///
/// Every entry carries enough prescription detail (sets/reps/tempo/rest, plus a
/// coaching cue and a scaling/modification option) that a generated session
/// reads like a real program rather than a list of names. Each movement is
/// tagged with the body regions it loads so the generator can screen it against
/// a user's injuries.
enum ExerciseLibrary {

    // MARK: Types

    /// A warm-up phase. A complete warm-up runs through all four phases in order.
    enum WarmupPhase: String, CaseIterable {
        case general = "Raise"        // raise heart rate / body temp
        case mobility = "Mobilize"    // joint mobility through range
        case activation = "Activate"  // switch on key muscles
        case specific = "Potentiate"  // movement-specific primers

        var blurb: String {
            switch self {
            case .general: return "Raise core temperature and heart rate."
            case .mobility: return "Take the joints you'll use through full range."
            case .activation: return "Switch on the muscles that protect you under load."
            case .specific: return "Rehearse today's patterns at light load."
            }
        }
    }

    struct WarmupDrill {
        let title: String
        let phase: WarmupPhase
        let cue: String          // how to do it well
        let loads: Set<InjuryArea>
        let modification: String // safe alternative if an area is flagged
        var reps = 0
        var seconds = 0
    }

    /// Primary training emphasis for a session.
    enum Theme: String, CaseIterable {
        case strength = "Strength"
        case metcon = "Conditioning (MetCon)"
        case gymnastics = "Gymnastics & Core"
        case engine = "Engine / Cardio"
        case fullBody = "Full-Body Mix"

        var focus: String {
            switch self {
            case .strength: return "Heavy compound lifts, long rest, low reps."
            case .metcon: return "Mixed-modal intervals at high effort."
            case .gymnastics: return "Bodyweight skill, midline control."
            case .engine: return "Sustained cardio capacity."
            case .fullBody: return "Balanced push/pull/hinge/squat."
            }
        }
    }

    struct Movement {
        let title: String
        let theme: Theme
        let cue: String          // coaching cue
        let scaling: String      // how a beginner or injured athlete scales it
        let loads: Set<InjuryArea>
        let pattern: Pattern
        var sets = 0, reps = 0, seconds = 0
        var restSeconds = 0
        var tempo: String? = nil // e.g. "31X1"
    }

    /// Movement pattern — used to keep a session balanced.
    enum Pattern: String, CaseIterable {
        case squat, hinge, push, pull, core, monostructural, carry
    }

    // MARK: Warm-up catalog (the "enough data" the plan draws from)

    static let warmups: [WarmupDrill] = [
        // --- Raise ---
        WarmupDrill(title: "Row or Bike", phase: .general,
                    cue: "Conversational pace, nasal breathing, Zone 1–2.",
                    loads: [], modification: "March in place if no machine.", seconds: 180),
        WarmupDrill(title: "Jumping Jacks", phase: .general,
                    cue: "Smooth and rhythmic; land softly through the foot.",
                    loads: [.knee, .ankle], modification: "Step-jacks (no jump).", seconds: 60),
        WarmupDrill(title: "High Knees → Butt Kicks", phase: .general,
                    cue: "Light feet, tall posture, quick turnover.",
                    loads: [.knee, .ankle], modification: "Brisk march.", seconds: 60),

        // --- Mobilize ---
        WarmupDrill(title: "Leg Swings (front/side)", phase: .mobility,
                    cue: "Controlled, hold something for balance, full pain-free range.",
                    loads: [.hip], modification: "Standing knee circles.", reps: 10),
        WarmupDrill(title: "World's Greatest Stretch", phase: .mobility,
                    cue: "Lunge, rotate, reach — open hips and thoracic spine.",
                    loads: [.hip, .lowerBack], modification: "Half-kneeling thoracic rotations.", reps: 6),
        WarmupDrill(title: "Shoulder Pass-throughs (band/PVC)", phase: .mobility,
                    cue: "Wide grip, slow, keep ribs down — never force end range.",
                    loads: [.shoulder], modification: "Band pull-aparts only.", reps: 12),
        WarmupDrill(title: "Cat–Cow / Spinal Waves", phase: .mobility,
                    cue: "Move segment by segment with the breath.",
                    loads: [.lowerBack, .neck], modification: "Seated gentle rounds.", reps: 10),
        WarmupDrill(title: "Ankle Rocks to Wall", phase: .mobility,
                    cue: "Knee tracks over toes, heel glued down.",
                    loads: [.ankle], modification: "Seated ankle circles.", reps: 10),

        // --- Activate ---
        WarmupDrill(title: "Glute Bridges", phase: .activation,
                    cue: "Squeeze glutes at top, ribs down, no lower-back arch.",
                    loads: [.lowerBack], modification: "Standing glute squeezes.", reps: 15),
        WarmupDrill(title: "Band Monster Walks", phase: .activation,
                    cue: "Band above knees, soft squat, push knees out.",
                    loads: [.knee, .hip], modification: "Standing band abductions.", reps: 12),
        WarmupDrill(title: "Scapular Push-ups", phase: .activation,
                    cue: "Arms straight, protract/retract — wake up the serratus.",
                    loads: [.wrist, .shoulder], modification: "Wall scap push-ups.", reps: 12),
        WarmupDrill(title: "Dead Bugs", phase: .activation,
                    cue: "Low back pinned to floor; move opposite arm/leg slowly.",
                    loads: [], modification: "Heel taps only.", reps: 10),

        // --- Potentiate (movement-specific) ---
        WarmupDrill(title: "Air Squats (tempo)", phase: .specific,
                    cue: "3 sec down, stand tall — groove the squat.",
                    loads: [.knee], modification: "Box squats to a bench.", reps: 12),
        WarmupDrill(title: "PVC Good Mornings", phase: .specific,
                    cue: "Soft knees, hinge from hips, flat back.",
                    loads: [.lowerBack], modification: "Hands-on-hips hip hinge.", reps: 10),
        WarmupDrill(title: "Empty-Bar Strict Press", phase: .specific,
                    cue: "Brace, press through the midline, finish with biceps by ears.",
                    loads: [.shoulder], modification: "Light DB front raises.", reps: 8),
        WarmupDrill(title: "Inchworm to Plank", phase: .specific,
                    cue: "Walk hands out, hold a tight plank for 2 sec.",
                    loads: [.wrist, .shoulder, .lowerBack], modification: "Incline plank on a box.", reps: 6),
    ]

    /// Returns a full, injury-aware warm-up: one or two drills per phase,
    /// substituting the modification when a drill loads a flagged area.
    static func warmupRoutine(injuries: Set<InjuryArea>) -> [(phase: WarmupPhase, drill: WarmupDrill)] {
        var result: [(WarmupPhase, WarmupDrill)] = []
        for phase in WarmupPhase.allCases {
            let pool = warmups.filter { $0.phase == phase }
            // Take up to two drills per phase, preferring ones that don't need modifying.
            let safe = pool.filter { $0.loads.isDisjoint(with: injuries) }
            let chosen = (safe.isEmpty ? pool : safe).prefix(2)
            for drill in chosen {
                if drill.loads.isDisjoint(with: injuries) {
                    result.append((phase, drill))
                } else {
                    var mod = drill
                    mod = WarmupDrill(title: "\(drill.title) — modified",
                                      phase: phase, cue: drill.modification,
                                      loads: [], modification: drill.modification,
                                      reps: drill.reps, seconds: drill.seconds)
                    result.append((phase, mod))
                }
            }
        }
        return result
    }

    // MARK: Movement catalog

    static let movements: [Movement] = [
        // STRENGTH
        Movement(title: "Back Squat", theme: .strength, cue: "Brace, knees out, drive through midfoot.",
                 scaling: "Goblet squat with a single DB/KB.", loads: [.knee, .lowerBack, .hip],
                 pattern: .squat, sets: 5, reps: 5, restSeconds: 150, tempo: "30X1"),
        Movement(title: "Front Squat", theme: .strength, cue: "Elbows high, upright torso, full depth.",
                 scaling: "Box front squat to control depth.", loads: [.knee, .wrist, .lowerBack],
                 pattern: .squat, sets: 5, reps: 3, restSeconds: 150),
        Movement(title: "Deadlift", theme: .strength, cue: "Bar over midfoot, flat back, push the floor away.",
                 scaling: "Trap-bar or kettlebell deadlift.", loads: [.lowerBack, .hip],
                 pattern: .hinge, sets: 5, reps: 3, restSeconds: 180),
        Movement(title: "Strict Press", theme: .strength, cue: "Squeeze glutes, press in a straight line, head through.",
                 scaling: "Seated DB press for shoulder support.", loads: [.shoulder, .wrist],
                 pattern: .push, sets: 5, reps: 5, restSeconds: 120),
        Movement(title: "Bench Press", theme: .strength, cue: "Shoulder blades pinned, controlled descent to chest.",
                 scaling: "Floor press or push-ups.", loads: [.shoulder, .elbow, .wrist],
                 pattern: .push, sets: 5, reps: 5, restSeconds: 150, tempo: "31X1"),
        Movement(title: "Pendlay Row", theme: .strength, cue: "Flat back, explode the bar to the sternum.",
                 scaling: "Chest-supported DB row.", loads: [.lowerBack],
                 pattern: .pull, sets: 4, reps: 8, restSeconds: 90),

        // METCON
        Movement(title: "Wall Balls", theme: .metcon, cue: "Full squat, drive the ball to the target, breathe at the top.",
                 scaling: "Lighter ball or squat-to-target without throw.", loads: [.shoulder, .knee],
                 pattern: .squat, reps: 15),
        Movement(title: "Kettlebell Swings", theme: .metcon, cue: "Hinge not squat; snap the hips, float the bell.",
                 scaling: "Russian (chest-height) swings, lighter bell.", loads: [.lowerBack],
                 pattern: .hinge, reps: 20),
        Movement(title: "Box Step-ups (loaded)", theme: .metcon, cue: "Full hip extension at the top, control the descent.",
                 scaling: "Lower box, bodyweight only.", loads: [.knee],
                 pattern: .squat, reps: 20),
        Movement(title: "Burpees", theme: .metcon, cue: "Chest to floor, jump and clap; pace to keep moving.",
                 scaling: "Step-back burpees, no jump.", loads: [.wrist, .shoulder, .knee],
                 pattern: .monostructural, reps: 12),
        Movement(title: "Dumbbell Thrusters", theme: .metcon, cue: "Squat, then use leg drive to press overhead in one move.",
                 scaling: "Lighter DBs or split into squat + press.", loads: [.shoulder, .knee, .wrist],
                 pattern: .squat, reps: 12),
        Movement(title: "Sled Push / Farmer Carry", theme: .metcon, cue: "Tall posture, brace, drive in a straight line.",
                 scaling: "Lighter load, shorter distance.", loads: [],
                 pattern: .carry, seconds: 40),

        // GYMNASTICS & CORE
        Movement(title: "Pull-ups", theme: .gymnastics, cue: "Active shoulders, full lockout, chin over bar.",
                 scaling: "Banded or ring-row pull-ups.", loads: [.shoulder, .elbow],
                 pattern: .pull, sets: 4, reps: 6, restSeconds: 90),
        Movement(title: "Push-ups", theme: .gymnastics, cue: "Body in one line, elbows ~45°, full range.",
                 scaling: "Incline push-ups on a box.", loads: [.wrist, .shoulder, .elbow],
                 pattern: .push, sets: 4, reps: 12),
        Movement(title: "Hollow Body Hold", theme: .gymnastics, cue: "Low back glued down, ribs in, point the toes.",
                 scaling: "Tuck hold with knees bent.", loads: [],
                 pattern: .core, sets: 4, seconds: 30, restSeconds: 45),
        Movement(title: "Hanging Knee Raises", theme: .gymnastics, cue: "No swing; lift with the lower abs, control down.",
                 scaling: "Lying leg raises on the floor.", loads: [.shoulder],
                 pattern: .core, sets: 4, reps: 12),
        Movement(title: "Plank Shoulder Taps", theme: .gymnastics, cue: "Hips still, tap slowly — anti-rotation.",
                 scaling: "From the knees.", loads: [.wrist, .shoulder],
                 pattern: .core, sets: 3, reps: 20),
        Movement(title: "Ring Rows", theme: .gymnastics, cue: "Straight body, pull rings to the ribs, squeeze.",
                 scaling: "Raise the rings to reduce angle.", loads: [.elbow],
                 pattern: .pull, sets: 4, reps: 10),

        // ENGINE
        Movement(title: "Row Intervals", theme: .engine, cue: "Legs–hips–arms order; strong finish each stroke.",
                 scaling: "Reduce interval length / intensity.", loads: [.lowerBack],
                 pattern: .monostructural, sets: 5, seconds: 120, restSeconds: 60),
        Movement(title: "Assault Bike Sprints", theme: .engine, cue: "Push and pull the handles, brace the core.",
                 scaling: "Lower RPM target, longer rest.", loads: [],
                 pattern: .monostructural, sets: 6, seconds: 30, restSeconds: 60),
        Movement(title: "Jump Rope", theme: .engine, cue: "Wrists turn the rope, small hops, stay relaxed.",
                 scaling: "Single-unders or low-impact step jumps.", loads: [.ankle, .knee],
                 pattern: .monostructural, sets: 5, seconds: 60, restSeconds: 30),
        Movement(title: "Shuttle Runs", theme: .engine, cue: "Decelerate under control, low turn, accelerate out.",
                 scaling: "Walk the recovery, shorten distance.", loads: [.knee, .ankle],
                 pattern: .monostructural, sets: 6, seconds: 30, restSeconds: 45),
    ]

    /// Movements for a theme that are safe given the user's injuries.
    static func safeMovements(theme: Theme, injuries: Set<InjuryArea>) -> [Movement] {
        movements.filter { $0.theme == theme && $0.loads.isDisjoint(with: injuries) }
    }
}
