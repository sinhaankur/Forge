import Foundation
#if canImport(CoreMotion)
import CoreMotion
#endif

/// Reads step / distance activity from the device's motion coprocessor via
/// CoreMotion (the "Activity Monitor"). Unlike HealthKit, CMPedometer works on a
/// **free** Apple account (no special entitlement) — so it gives Forge real
/// movement data on-device even without the paid HealthKit setup.
///
/// Privacy: read-only, on-device; nothing is stored remotely or transmitted.
@MainActor
final class MotionService: ObservableObject {
    static let shared = MotionService()

    @Published var isAvailable = false
    @Published var stepsToday = 0
    @Published var distanceKmToday = 0.0
    @Published var activityMinutes: [ActivityKind: Int] = [:]

    /// Activity types CoreMotion can classify from phone + wrist motion.
    enum ActivityKind: String, CaseIterable, Identifiable {
        case driving, walking, running, cycling, stationary
        var id: String { rawValue }
        var title: String {
            switch self {
            case .driving: return "Driving"
            case .walking: return "Walking"
            case .running: return "Running"
            case .cycling: return "Cycling"
            case .stationary: return "Sitting / Still"
            }
        }
        var systemImage: String {
            switch self {
            case .driving: return "car.fill"
            case .walking: return "figure.walk"
            case .running: return "figure.run"
            case .cycling: return "bicycle"
            case .stationary: return "chair.fill"
            }
        }
    }

    #if canImport(CoreMotion)
    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()

    private init() {
        isAvailable = CMPedometer.isStepCountingAvailable()
    }

    var activityAvailable: Bool { CMMotionActivityManager.isActivityAvailable() }

    /// Build today's activity-type breakdown (minutes per kind) from the motion
    /// coprocessor's classified activity history. On-device.
    func refreshActivityTimeline() async {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        let start = Calendar.current.startOfDay(for: .now)
        let activities: [CMMotionActivity] = await withCheckedContinuation { cont in
            activityManager.queryActivityStarting(from: start, to: .now, to: .main) { acts, _ in
                cont.resume(returning: acts ?? [])
            }
        }
        // Each CMMotionActivity marks the start of a segment; sum durations to
        // the next segment, bucketed by the dominant classification.
        var minutes: [ActivityKind: Int] = [:]
        for (i, a) in activities.enumerated() {
            let end = (i + 1 < activities.count) ? activities[i + 1].startDate : Date()
            let secs = end.timeIntervalSince(a.startDate)
            guard secs > 0, a.confidence != .low else { continue }
            let kind: ActivityKind?
            if a.automotive { kind = .driving }
            else if a.cycling { kind = .cycling }
            else if a.running { kind = .running }
            else if a.walking { kind = .walking }
            else if a.stationary { kind = .stationary }
            else { kind = nil }
            if let kind { minutes[kind, default: 0] += Int(secs / 60) }
        }
        activityMinutes = minutes
    }

    /// Query today's step count and distance from the motion coprocessor.
    func refreshToday() async {
        guard isAvailable else { return }
        let start = Calendar.current.startOfDay(for: .now)
        let data: CMPedometerData? = await withCheckedContinuation { cont in
            pedometer.queryPedometerData(from: start, to: .now) { data, _ in
                cont.resume(returning: data)
            }
        }
        guard let data else { return }
        stepsToday = data.numberOfSteps.intValue
        if let meters = data.distance?.doubleValue {
            distanceKmToday = meters / 1000
        }
    }
    #else
    private init() { isAvailable = false }
    var activityAvailable: Bool { false }
    func refreshToday() async {}
    func refreshActivityTimeline() async {}
    #endif
}
