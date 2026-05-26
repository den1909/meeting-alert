import Foundation
import EventKit
import Combine

struct FlightTrigger: Identifiable, Equatable {
    enum Kind {
        case event
        case reminder
    }

    let id: String
    let title: String
    let startDate: Date
    let kind: Kind
}

@MainActor
final class EventManager: ObservableObject {
    static let shared = EventManager()

    @Published private(set) var upcomingTriggers: [FlightTrigger] = []
    @Published private(set) var eventAuthStatus: EKAuthorizationStatus = .notDetermined
    @Published private(set) var reminderAuthStatus: EKAuthorizationStatus = .notDetermined

    private let store = EKEventStore()
    private var refreshTimer: Timer?
    private var changeObserver: NSObjectProtocol?

    private init() {
        eventAuthStatus = EKEventStore.authorizationStatus(for: .event)
        reminderAuthStatus = EKEventStore.authorizationStatus(for: .reminder)
    }

    func requestAccess() async {
        do {
            if #available(macOS 14.0, *) {
                _ = try await store.requestFullAccessToEvents()
            } else {
                _ = try await store.requestAccess(to: .event)
            }
            eventAuthStatus = EKEventStore.authorizationStatus(for: .event)
        } catch {
            NSLog("AirplaneMeetings: Fehler bei Kalender-Berechtigung: \(error)")
        }

        do {
            if #available(macOS 14.0, *) {
                _ = try await store.requestFullAccessToReminders()
            } else {
                _ = try await store.requestAccess(to: .reminder)
            }
            reminderAuthStatus = EKEventStore.authorizationStatus(for: .reminder)
        } catch {
            NSLog("AirplaneMeetings: Fehler bei Erinnerungen-Berechtigung: \(error)")
        }

        if hasAnyAccess {
            start()
        }
    }

    func start() {
        refresh()
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        if changeObserver == nil {
            changeObserver = NotificationCenter.default.addObserver(
                forName: .EKEventStoreChanged,
                object: store,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            }
        }
    }

    func refresh() {
        guard hasAnyAccess else { return }
        let now = Date()
        let horizon = now.addingTimeInterval(60 * 60 * 12)
        var triggers: [FlightTrigger] = []

        if hasEventAccess {
            let calendars = store.calendars(for: .event)
            let predicate = store.predicateForEvents(withStart: now, end: horizon, calendars: calendars)
            let events = store.events(matching: predicate)
                .filter { !$0.isAllDay }
                .filter { $0.startDate > now.addingTimeInterval(-30) }
            for event in events {
                guard let id = event.eventIdentifier else { continue }
                triggers.append(FlightTrigger(
                    id: "event:\(id)",
                    title: event.title ?? "Termin",
                    startDate: event.startDate,
                    kind: .event
                ))
            }
        }

        if hasReminderAccess {
            let reminderCalendars = store.calendars(for: .reminder)
            let predicate = store.predicateForIncompleteReminders(
                withDueDateStarting: now.addingTimeInterval(-30),
                ending: horizon,
                calendars: reminderCalendars
            )
            let semaphore = DispatchSemaphore(value: 0)
            var fetchedReminders: [EKReminder] = []
            store.fetchReminders(matching: predicate) { reminders in
                fetchedReminders = reminders ?? []
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 2)
            for reminder in fetchedReminders {
                guard let due = reminder.dueDateComponents?.date else { continue }
                guard due > now.addingTimeInterval(-30) else { continue }
                triggers.append(FlightTrigger(
                    id: "reminder:\(reminder.calendarItemIdentifier)",
                    title: reminder.title ?? "Erinnerung",
                    startDate: due,
                    kind: .reminder
                ))
            }
        }

        upcomingTriggers = triggers.sorted { $0.startDate < $1.startDate }
    }

    var hasEventAccess: Bool {
        if #available(macOS 14.0, *) {
            return eventAuthStatus == .fullAccess || eventAuthStatus == .writeOnly
        } else {
            return eventAuthStatus == .authorized
        }
    }

    var hasReminderAccess: Bool {
        if #available(macOS 14.0, *) {
            return reminderAuthStatus == .fullAccess || reminderAuthStatus == .writeOnly
        } else {
            return reminderAuthStatus == .authorized
        }
    }

    var hasAnyAccess: Bool { hasEventAccess || hasReminderAccess }

    var nextTrigger: FlightTrigger? {
        upcomingTriggers.first { $0.startDate > Date() }
    }
}
