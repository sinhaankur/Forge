import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

/// Privacy-first HealthKit access.
///
/// Design principles:
/// - **On-device only.** Every value read here is used locally to fill in
///   workout-target progress and dashboard stats. Nothing is ever transmitted
///   off the device, logged remotely, or shared with third parties.
/// - **Read-only & minimal scope.** We request the smallest set of read types
///   needed (active energy, steps, workouts). We request no write access.
/// - **Fail open.** If HealthKit is unavailable or denied, the app works fully;
///   the user just logs targets manually.
@MainActor
final class HealthService: ObservableObject {
    static let shared = HealthService()

    /// Human-readable summary of exactly what we read and our privacy posture,
    /// shown in the in-app privacy explainer.
    static let privacyStatement = """
    Glow reads a small amount of health data — active energy, step count, and \
    workout sessions — only on this device, to automatically fill in how you \
    did against your workout targets and to show your progress stats.

    This data never leaves your iPhone. There is no account, no server, and no \
    analytics. Glow requests read-only access and writes nothing to Health.
    """

    @Published var isAuthorized = false
    @Published var isAvailable = false

    #if canImport(HealthKit)
    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(energy) }
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        types.insert(HKObjectType.workoutType())
        return types
    }

    private init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }

    /// Request read-only authorization. We never request share (write) access.
    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    /// Active energy (kcal) burned today, on-device.
    func activeEnergyToday() async -> Double {
        await sumQuantityToday(.activeEnergyBurned, unit: .kilocalorie())
    }

    /// Step count today, on-device.
    func stepsToday() async -> Double {
        await sumQuantityToday(.stepCount, unit: .count())
    }

    /// Total workout minutes today, on-device.
    func workoutMinutesToday() async -> Double {
        guard isAvailable, isAuthorized else { return 0 }
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: .workoutType(), predicate: predicate,
                                  limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let minutes = (samples as? [HKWorkout])?.reduce(0.0) { $0 + $1.duration / 60 } ?? 0
                cont.resume(returning: minutes)
            }
            store.execute(q)
        }
    }

    /// Suggest an achieved value for a routine's target metric from Health data,
    /// so the user doesn't have to type it. Returns 0 when not derivable.
    func suggestedAchievedValue(for metric: TargetMetric) async -> Double {
        switch metric {
        case .calories: return await activeEnergyToday()
        case .durationMin: return await workoutMinutesToday()
        case .distanceKm: return 0 // could read distanceWalkingRunning; left manual for now
        case .reps, .weightKg: return 0 // not available from Health; manual entry
        }
    }

    private func sumQuantityToday(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        guard isAvailable, isAuthorized,
              let type = HKQuantityType.quantityType(forIdentifier: id) else { return 0 }
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, stats, _ in
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(q)
        }
    }
    #else
    private init() { isAvailable = false }
    func requestAuthorization() async {}
    func activeEnergyToday() async -> Double { 0 }
    func stepsToday() async -> Double { 0 }
    func workoutMinutesToday() async -> Double { 0 }
    func suggestedAchievedValue(for metric: TargetMetric) async -> Double { 0 }
    #endif
}
