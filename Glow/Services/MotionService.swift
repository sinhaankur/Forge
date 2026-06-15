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

    #if canImport(CoreMotion)
    private let pedometer = CMPedometer()

    private init() {
        isAvailable = CMPedometer.isStepCountingAvailable()
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
    func refreshToday() async {}
    #endif
}
