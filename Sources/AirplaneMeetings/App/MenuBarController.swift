import AppKit
import EventKit
import Combine

@MainActor
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var cancellables = Set<AnyCancellable>()
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "HH:mm"
        return f
    }()

    func install() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let img = NSImage(systemSymbolName: "airplane", accessibilityDescription: "Airplane Meetings")
            img?.isTemplate = true
            button.image = img
        }

        EventManager.shared.$upcomingTriggers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)

        EventManager.shared.$eventAuthStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)

        EventManager.shared.$reminderAuthStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        if !EventManager.shared.hasAnyAccess {
            let item = NSMenuItem(
                title: "Kalender-Zugriff erforderlich…",
                action: #selector(requestAccess),
                keyEquivalent: ""
            )
            item.target = self
            menu.addItem(item)
            menu.addItem(.separator())
        } else if let next = EventManager.shared.nextTrigger {
            let timeStr = dateFormatter.string(from: next.startDate)
            let kindLabel = next.kind == .reminder ? "Nächste Erinnerung" : "Nächster Termin"
            let header = NSMenuItem(
                title: "\(kindLabel) · \(timeStr)",
                action: nil,
                keyEquivalent: ""
            )
            header.isEnabled = false
            menu.addItem(header)

            let title = NSMenuItem(
                title: "  \(next.title)",
                action: nil,
                keyEquivalent: ""
            )
            title.isEnabled = false
            menu.addItem(title)
            menu.addItem(.separator())

            let upcoming = Array(EventManager.shared.upcomingTriggers.dropFirst().prefix(5))
            if !upcoming.isEmpty {
                let label = NSMenuItem(title: "Danach:", action: nil, keyEquivalent: "")
                label.isEnabled = false
                menu.addItem(label)
                for ev in upcoming {
                    let t = dateFormatter.string(from: ev.startDate)
                    let kindIcon = ev.kind == .reminder ? "○" : "·"
                    let item = NSMenuItem(
                        title: "  \(t)  \(kindIcon)  \(ev.title)",
                        action: nil,
                        keyEquivalent: ""
                    )
                    item.isEnabled = false
                    menu.addItem(item)
                }
                menu.addItem(.separator())
            }
        } else {
            let item = NSMenuItem(title: "Keine kommenden Einträge", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(.separator())
        }

        let testItem = NSMenuItem(
            title: "Test-Flug starten",
            action: #selector(triggerTestFlight),
            keyEquivalent: "t"
        )
        testItem.target = self
        menu.addItem(testItem)

        let refreshItem = NSMenuItem(
            title: "Kalender neu laden",
            action: #selector(refreshCalendar),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(
            title: "Beim Anmelden starten",
            action: #selector(toggleLoginItem),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = LoginItemManager.isEnabled ? .on : .off
        menu.addItem(loginItem)

        let aboutItem = NSMenuItem(
            title: "Über Airplane Meetings",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(
            title: "Beenden",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func requestAccess() {
        Task { await EventManager.shared.requestAccess() }
    }

    @objc private func triggerTestFlight() {
        let title: String
        let subtitle: String
        if let trigger = EventManager.shared.nextTrigger {
            title = trigger.title
            subtitle = "um \(dateFormatter.string(from: trigger.startDate)) Uhr"
        } else {
            title = "Test-Flug"
            subtitle = "Alles fliegt wie es soll!"
        }
        AirplaneOverlayController.shared.show(title: title, subtitle: subtitle)
    }

    @objc private func refreshCalendar() {
        EventManager.shared.refresh()
    }

    @objc private func toggleLoginItem() {
        LoginItemManager.setEnabled(!LoginItemManager.isEnabled)
        rebuildMenu()
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Airplane Meetings"
        alert.informativeText = "Ein kleines Flugzeug zieht 5 Minuten vor jedem Termin oder jeder Erinnerung ein Banner über deinen Bildschirm.\n\nDaten werden aus der macOS-Kalender- und Erinnerungen-App gelesen."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
