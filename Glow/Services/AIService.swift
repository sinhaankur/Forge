import Foundation
import SwiftData
#if canImport(FoundationModels)
import FoundationModels
#endif

/// On-device intelligence for Forge using Apple's **Foundation Models** (the LLM
/// built into iOS 26+). Zero app-size cost, fully private — prompts and your data
/// never leave the device. Gracefully falls back to the rule-based `PlanParser`
/// when the model is unavailable (older iOS, or model not ready).
@MainActor
final class AIService: ObservableObject {
    static let shared = AIService()
    private init() {}

    /// Whether on-device generation is currently available.
    var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    /// A short status string for the UI.
    var statusText: String {
        isAvailable ? "On-device AI ready" : "Using built-in parser"
    }

    /// Convert free-text workout notes into a structured routine. Uses the LLM
    /// to extract clean exercises with sets/reps/duration when available; always
    /// returns a usable routine (falls back to PlanParser).
    func routine(fromNotes notes: String, kind: RoutineKind, timeOfDay: TimeOfDay) async -> Routine {
        #if canImport(FoundationModels)
        if #available(iOS 26, *), isAvailable {
            if let r = try? await llmRoutine(notes: notes, kind: kind, timeOfDay: timeOfDay) {
                return r
            }
        }
        #endif
        return PlanParser.makeRoutine(from: notes, kind: kind, timeOfDay: timeOfDay)
    }

    /// Plain-English explanation/coaching about the user's plan or data.
    /// Returns nil if on-device AI isn't available (caller can hide the feature).
    func answer(_ question: String, context: String) async -> String? {
        #if canImport(FoundationModels)
        if #available(iOS 26, *), isAvailable {
            let session = LanguageModelSession(instructions: """
            You are a concise, encouraging fitness & wellness coach inside the Forge app. \
            Give practical, safe, non-medical guidance in 2–4 sentences. \
            Never claim to diagnose or measure anything.
            """)
            let prompt = "Context: \(context)\n\nQuestion: \(question)"
            if let resp = try? await session.respond(to: prompt) {
                return resp.content
            }
        }
        #endif
        return nil
    }

    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private func llmRoutine(notes: String, kind: RoutineKind, timeOfDay: TimeOfDay) async throws -> Routine {
        let session = LanguageModelSession(instructions: """
        Extract a workout from the user's notes as a clean exercise list. \
        For each movement give a short name and, if present, sets, reps, and \
        duration in seconds. Keep it faithful to the notes; don't invent exercises.
        """)
        let response = try await session.respond(
            to: "Notes:\n\(notes)",
            generating: GeneratedPlan.self
        )
        let plan = response.content
        let routine = Routine(name: plan.name.isEmpty ? "Imported Plan" : plan.name,
                              kind: kind, timeOfDay: timeOfDay,
                              notes: "Created on-device from your notes — edit freely.",
                              colorHex: "#19E3C2")
        for (i, e) in plan.exercises.prefix(30).enumerated() {
            let step = RoutineStep(title: e.name, detail: e.detail ?? "", order: i,
                                   sets: e.sets ?? 0, reps: e.reps ?? 0,
                                   durationSeconds: e.durationSeconds ?? 0)
            step.routine = routine
            routine.steps.append(step)
        }
        return routine.steps.isEmpty
            ? PlanParser.makeRoutine(from: notes, kind: kind, timeOfDay: timeOfDay)
            : routine
    }
    #endif
}

#if canImport(FoundationModels)
@available(iOS 26, *)
@Generable
struct GeneratedPlan {
    @Guide(description: "A short title for the workout")
    var name: String
    var exercises: [GeneratedExercise]
}

@available(iOS 26, *)
@Generable
struct GeneratedExercise {
    @Guide(description: "The exercise name, e.g. 'Back Squat'")
    var name: String
    @Guide(description: "Number of sets if stated, else omit")
    var sets: Int?
    @Guide(description: "Reps per set if stated, else omit")
    var reps: Int?
    @Guide(description: "Duration in seconds if the exercise is timed, else omit")
    var durationSeconds: Int?
    @Guide(description: "Any short form cue from the notes")
    var detail: String?
}
#endif
