import Foundation
import Combine

@MainActor
final class AlertScheduler {
    static let shared = AlertScheduler()

    private let leadTime: TimeInterval = 5 * 60
    private let pollInterval: TimeInterval = 20
    private let triggeredKey = "triggeredEventTokens"

    private var timer: Timer?
    var onTrigger: ((FlightTrigger) -> Void)?

    private init() {}

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        EventManager.shared.refresh()
        let now = Date()
        let triggers = EventManager.shared.upcomingTriggers
        for trigger in triggers {
            let triggerTime = trigger.startDate.addingTimeInterval(-leadTime)
            guard triggerTime <= now else { continue }
            guard trigger.startDate > now else { continue }
            let token = token(for: trigger)
            if hasTriggered(token) { continue }
            markTriggered(token)
            onTrigger?(trigger)
        }
        cleanupOldTokens()
    }

    private func token(for trigger: FlightTrigger) -> String {
        let timestamp = Int(trigger.startDate.timeIntervalSince1970)
        return "\(trigger.id)#\(timestamp)"
    }

    private func hasTriggered(_ token: String) -> Bool {
        let store = UserDefaults.standard.dictionary(forKey: triggeredKey) as? [String: TimeInterval] ?? [:]
        return store[token] != nil
    }

    private func markTriggered(_ token: String) {
        var store = UserDefaults.standard.dictionary(forKey: triggeredKey) as? [String: TimeInterval] ?? [:]
        store[token] = Date().timeIntervalSince1970
        UserDefaults.standard.set(store, forKey: triggeredKey)
    }

    private func cleanupOldTokens() {
        var store = UserDefaults.standard.dictionary(forKey: triggeredKey) as? [String: TimeInterval] ?? [:]
        let cutoff = Date().timeIntervalSince1970 - 60 * 60 * 24
        store = store.filter { $0.value > cutoff }
        UserDefaults.standard.set(store, forKey: triggeredKey)
    }
}
