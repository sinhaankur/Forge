import Foundation
import WatchConnectivity

/// A lightweight, Codable snapshot of today's routines shared phone <-> watch.
struct TodaySnapshot: Codable, Equatable {
    struct Item: Codable, Equatable, Identifiable {
        var id: String
        var name: String
        var kind: String          // RoutineKind raw value
        var timeOfDay: String     // TimeOfDay raw value
        var stepCount: Int
        var targetSummary: String?
        var completedToday: Bool
    }
    var date: Date
    var items: [Item]
    /// Current overall completion streak in days.
    var streak: Int
}

/// Messages the watch can send back to the phone.
enum WatchCommand: Codable {
    case complete(routineID: String, achievedValue: Double)
    case requestSnapshot
}

/// Wraps WatchConnectivity for both targets. The phone pushes a `TodaySnapshot`
/// via application context; the watch sends `WatchCommand`s back as messages.
final class ConnectivityService: NSObject, ObservableObject {
    static let shared = ConnectivityService()

    /// Latest snapshot received (used by the watch UI).
    @Published var snapshot: TodaySnapshot?

    /// Called on the phone when the watch asks to complete a routine.
    var onCommand: ((WatchCommand) -> Void)?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: Phone -> Watch

    func push(_ snapshot: TodaySnapshot) {
        guard WCSession.isSupported() else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? WCSession.default.updateApplicationContext(["snapshot": data])
    }

    // MARK: Watch -> Phone

    func send(_ command: WatchCommand) {
        guard WCSession.isSupported() else { return }
        guard let data = try? JSONEncoder().encode(command) else { return }
        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(["command": data], replyHandler: nil, errorHandler: nil)
        } else {
            // Queue for delivery when the counterpart becomes available.
            try? session.transferUserInfo(["command": data]) as Void
        }
    }

    private func decodeSnapshot(from context: [String: Any]) {
        guard let data = context["snapshot"] as? Data,
              let snap = try? JSONDecoder().decode(TodaySnapshot.self, from: data) else { return }
        DispatchQueue.main.async { self.snapshot = snap }
    }

    private func handleIncoming(_ payload: [String: Any]) {
        guard let data = payload["command"] as? Data,
              let command = try? JSONDecoder().decode(WatchCommand.self, from: data) else { return }
        DispatchQueue.main.async { self.onCommand?(command) }
    }
}

extension ConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        decodeSnapshot(from: applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncoming(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handleIncoming(userInfo)
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif
}
