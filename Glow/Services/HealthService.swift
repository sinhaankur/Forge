import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

/// A lightweight, on-device summary of a recent workout (from Strava, Apple
/// Watch, or any app that writes to Health). Defined outside the HealthKit
/// conditional so both build configurations can reference it.
struct ActivitySummary: Identifiable {
    let id = UUID()
    let kind: String          // e.g. "Walking", "Running", "Cycling"
    let date: Date
    let minutes: Double
    let distanceKm: Double
    let calories: Double
    let systemImage: String
}

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
    Forge reads a small amount of health data — active energy, step count, and \
    workout sessions — only on this device, to automatically fill in how you \
    did against your workout targets and to show your progress stats.

    This data never leaves your iPhone. There is no account, no server, and no \
    analytics. Forge requests read-only access and writes nothing to Health.
    """

    @Published var isAuthorized = false
    @Published var isAvailable = false

    #if canImport(HealthKit)
    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(energy) }
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        if let dist = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) { types.insert(dist) }
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

    /// Distance walked/run today in kilometers, on-device.
    func distanceKmToday() async -> Double {
        await sumQuantityToday(.distanceWalkingRunning, unit: .meterUnit(with: .kilo))
    }

    /// Distance walked/run over the last 7 days, in kilometers.
    func distanceKmThisWeek() async -> Double {
        guard isAvailable, isAuthorized,
              let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return 0 }
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Calendar.current.startOfDay(for: .now))!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, stats, _ in
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0)
            }
            store.execute(q)
        }
    }

    /// The most recent workouts (walks/runs/rides etc.) from any Health source,
    /// including Strava. Returns up to `limit`, newest first. On-device only.
    func recentActivities(limit: Int = 10) async -> [ActivitySummary] {
        guard isAvailable, isAuthorized else { return [] }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: .workoutType(), predicate: nil,
                                  limit: limit, sortDescriptors: [sort]) { _, samples, _ in
                let workouts = (samples as? [HKWorkout]) ?? []
                let summaries = workouts.map { w in
                    ActivitySummary(
                        kind: Self.name(for: w.workoutActivityType),
                        date: w.endDate,
                        minutes: w.duration / 60,
                        distanceKm: w.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0,
                        calories: w.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                        systemImage: Self.icon(for: w.workoutActivityType)
                    )
                }
                cont.resume(returning: summaries)
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
        case .distanceKm: return await distanceKmToday()
        case .reps, .weightKg: return 0 // not available from Health; manual entry
        }
    }

    private static func name(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: return "Walking"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .hiking: return "Hiking"
        case .swimming: return "Swimming"
        case .rowing: return "Rowing"
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "Strength"
        case .highIntensityIntervalTraining: return "HIIT"
        case .yoga: return "Yoga"
        default: return "Workout"
        }
    }

    private static func icon(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .hiking: return "figure.hiking"
        case .swimming: return "figure.pool.swim"
        case .rowing: return "figure.rower"
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "dumbbell.fill"
        case .highIntensityIntervalTraining: return "flame.fill"
        case .yoga: return "figure.yoga"
        default: return "figure.mixed.cardio"
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
    func distanceKmToday() async -> Double { 0 }
    func distanceKmThisWeek() async -> Double { 0 }
    func recentActivities(limit: Int = 10) async -> [ActivitySummary] { [] }
    func suggestedAchievedValue(for metric: TargetMetric) async -> Double { 0 }
    #endif
}
