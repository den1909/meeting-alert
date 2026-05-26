import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBar = MenuBarController()
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "HH:mm"
        return f
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        menuBar.install()

        AlertScheduler.shared.onTrigger = { [weak self] trigger in
            self?.triggerFlight(for: trigger)
        }

        Task {
            await EventManager.shared.requestAccess()
            if EventManager.shared.hasAnyAccess {
                AlertScheduler.shared.start()
            }
        }
    }

    private func triggerFlight(for trigger: FlightTrigger) {
        let subtitle = "um \(dateFormatter.string(from: trigger.startDate)) Uhr"
        AirplaneOverlayController.shared.show(title: trigger.title, subtitle: subtitle)
    }
}
