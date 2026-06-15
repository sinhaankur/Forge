import Foundation
import SwiftData

/// Turns free-text workout notes (e.g. pasted from Gemini/ChatGPT/any AI, or
/// typed by hand) into a Forge routine the user can then edit. Fully on-device —
/// no AI call, just lightweight text parsing of common list formats.
enum PlanParser {

    /// Parse pasted text into a draft routine: a name + ordered steps with any
    /// sets/reps/duration it can detect.
    static func makeRoutine(from text: String, kind: RoutineKind = .fitness,
                            timeOfDay: TimeOfDay = .anytime) -> Routine {
        let lines = text.split(whereSeparator: \.isNewline).map { String($0) }

        // Title: first non-empty line that looks like a heading, else a default.
        var name = "Imported Plan"
        var bodyLines = lines
        if let first = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            let t = first.trimmingCharacters(in: .whitespaces)
            if t.count <= 40 && !looksLikeExercise(t) {
                name = stripBullet(t)
                if let idx = bodyLines.firstIndex(of: first) { bodyLines.remove(at: idx) }
            }
        }

        let routine = Routine(name: name, kind: kind, timeOfDay: timeOfDay,
                              notes: "Imported from notes — edit to fit you.",
                              colorHex: "#19E3C2")

        var order = 0
        for raw in bodyLines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, line.count > 1 else { continue }
            // Skip pure section headers / prose lines without an exercise feel.
            let clean = stripBullet(line)
            guard !clean.isEmpty else { continue }

            let (title, sets, reps, secs, detail) = parseExercise(clean)
            guard !title.isEmpty else { continue }
            let step = RoutineStep(title: title, detail: detail, order: order,
                                   sets: sets, reps: reps, durationSeconds: secs)
            step.routine = routine
            routine.steps.append(step)
            order += 1
            if order >= 30 { break } // sanity cap
        }
        return routine
    }

    // MARK: helpers

    private static func stripBullet(_ s: String) -> String {
        var t = s
        for p in ["- ", "• ", "* ", "– ", "› ", "→ "] where t.hasPrefix(p) { t.removeFirst(p.count) }
        // Strip leading "1. " / "1) " numbering.
        if let r = t.range(of: #"^\d+[.)]\s*"#, options: .regularExpression) {
            t.removeSubrange(r)
        }
        return t.trimmingCharacters(in: .whitespaces)
    }

    private static func looksLikeExercise(_ s: String) -> Bool {
        let l = s.lowercased()
        return l.contains("squat") || l.contains("push") || l.contains("run") ||
               l.contains("x ") || l.range(of: #"\d"#, options: .regularExpression) != nil
    }

    /// Extract title + sets/reps/seconds from a line like
    /// "Push-ups 3x12", "Plank — 60s", "Squats: 4 sets of 10".
    private static func parseExercise(_ line: String) -> (String, Int, Int, Int, String) {
        var sets = 0, reps = 0, secs = 0
        let lower = line.lowercased()

        // "3x12" or "3 x 12"
        if let m = firstMatch(#"(\d+)\s*[x×]\s*(\d+)"#, in: lower) {
            sets = Int(m[1]) ?? 0; reps = Int(m[2]) ?? 0
        } else if let m = firstMatch(#"(\d+)\s*sets?\s*(?:of|x)?\s*(\d+)"#, in: lower) {
            sets = Int(m[1]) ?? 0; reps = Int(m[2]) ?? 0
        } else if let m = firstMatch(#"(\d+)\s*reps?"#, in: lower) {
            reps = Int(m[1]) ?? 0
        }
        // Duration "60s" / "45 sec" / "2 min"
        if let m = firstMatch(#"(\d+)\s*(?:s|sec|secs|seconds)\b"#, in: lower) {
            secs = Int(m[1]) ?? 0
        } else if let m = firstMatch(#"(\d+)\s*(?:m|min|mins|minutes)\b"#, in: lower) {
            secs = (Int(m[1]) ?? 0) * 60
        }

        // Title = text before the first digit/colon/dash separator.
        var title = line
        if let sepRange = title.range(of: #"\s*[:\-–—]\s*|\s+\d"#, options: .regularExpression) {
            title = String(title[..<sepRange.lowerBound])
        }
        title = title.trimmingCharacters(in: .whitespaces)
        if title.isEmpty { title = line }
        return (title, sets, reps, secs, "")
    }

    private static func firstMatch(_ pattern: String, in s: String) -> [String]? {
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m = re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) else { return nil }
        return (0..<m.numberOfRanges).compactMap {
            Range(m.range(at: $0), in: s).map { String(s[$0]) }
        }
    }
}
