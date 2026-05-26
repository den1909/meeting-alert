# Airplane Meetings ✈

Ein kleines Cartoon-Flugzeug zieht 5 Minuten vor jedem Termin oder jeder Erinnerung ein Banner mit dem Titel über alle deine Bildschirme.

Native macOS-Menüleisten-App. Liest Termine aus der Kalender-App und Erinnerungen aus der Erinnerungen-App — funktioniert daher mit allem was du in macOS synchronisiert hast (Google Calendar, iCloud, Exchange, Outlook etc.).

## Features

- ✈ Cartoon-Flugzeug mit wehendem Stoff-Banner fliegt über **alle** angeschlossenen Bildschirme
- ⏰ Triggert automatisch **5 Minuten** vor jedem Termin/jeder Erinnerung
- 📅 Liest aus **Kalender** und **Erinnerungen** (EventKit) — alle synchronisierten Konten werden unterstützt
- 🖥 Multi-Display-Support: Banner fliegt durchgehend von rechts nach links über alle Monitore
- 🚀 Optionaler Autostart beim Anmelden (`SMAppService`)
- 🌟 Findbar via Spotlight nach Installation
- 🔒 Komplett lokal — keine Cloud, keine Tracker, keine Internetverbindung

## Voraussetzungen

- macOS 13 (Ventura) oder neuer
- Xcode Command Line Tools (für `swift build`)

```sh
xcode-select --install
```

## Installation

```sh
git clone https://github.com/den1909/meeting-alert.git
cd meeting-alert
./build.sh        # baut die .app
./install.sh      # kopiert nach ~/Applications, registriert bei Spotlight
```

Nach `install.sh`:
- Spotlight (`Cmd+Space`) → "Airplane Meetings" → Enter
- Beim ersten Start fragt macOS nach Kalender- und Erinnerungen-Berechtigung
- Im ✈-Menü oben rechts: **"Beim Anmelden starten"** für Autostart

## Bedienung

In der Menüleiste erscheint ein ✈-Icon. Klick öffnet das Menü:

| Eintrag                  | Funktion                                                                 |
| ------------------------ | ------------------------------------------------------------------------ |
| Nächster Termin          | Übersicht der nächsten 6 Termine/Erinnerungen (`·` = Termin, `○` = Erinnerung) |
| **Test-Flug starten** (⌘T) | Löst sofort eine Animation aus — gut zum Testen                          |
| **Kalender neu laden** (⌘R) | Forciert einen Refresh                                                   |
| **Beim Anmelden starten**  | Toggle für Autostart                                                     |
| Beenden (⌘Q)             | App beenden                                                              |

## Konfiguration

Aktuell sind die wichtigsten Werte als Konstanten im Code:

| Wert                | Datei                                            | Default |
| ------------------- | ------------------------------------------------ | ------- |
| Vorlaufzeit         | `Sources/.../Calendar/AlertScheduler.swift`      | 5 min   |
| Poll-Intervall      | `Sources/.../Calendar/AlertScheduler.swift`      | 20 s    |
| Geschwindigkeit     | `Sources/.../UI/AirplaneOverlayWindow.swift`     | 260 px/s |
| Banner-Farbe / -Größe | `Sources/.../UI/AirplaneFlightView.swift`      | rot / 600×120 px |
| Y-Position (% von unten) | `Sources/.../UI/AirplaneOverlayWindow.swift` | 0.68    |

## Architektur

```
Sources/AirplaneMeetings/
├── main.swift                    Entry Point
├── App/
│   ├── AppDelegate.swift         App-Lifecycle, wiring
│   ├── MenuBarController.swift   NSStatusItem + Menü
│   └── LoginItemManager.swift    SMAppService Wrapper
├── Calendar/
│   ├── EventManager.swift        EventKit (EKEvent + EKReminder → FlightTrigger)
│   └── AlertScheduler.swift      Timer-basierter Trigger (5min vor startDate)
└── UI/
    ├── AirplaneOverlayWindow.swift  Per-Screen-Window-Animation (Timer-driven)
    └── AirplaneFlightView.swift     SwiftUI Banner (Canvas), gerendert via ImageRenderer
```

**Wie die Animation funktioniert:**

1. Beim Trigger wird ein statisches Banner-Bild (Flugzeug + roter Banner + Text) einmalig per `ImageRenderer` aus einer SwiftUI-View erzeugt.
2. Für jeden angeschlossenen Bildschirm wird ein transparentes, klick-durchlässiges `NSWindow` über alle Spaces erstellt — Window-Frame deckt den Bildschirm + Padding ab.
3. Ein 60-fps-Timer berechnet jede Frame die globale X-Position. Jedes Fenster setzt sein internes `NSImageView` auf die Window-lokale X-Koordinate. Das Banner ist immer nur auf einem Bildschirm sichtbar — auf den anderen ist es off-bounds geclippt. Visuell wirkt es wie ein durchgehender Flug.
4. Y-Position ist pro Bildschirm relativ (68% von unten), sodass sie auf unterschiedlich großen / versetzten Bildschirmen jeweils sinnvoll sitzt.

Die ImageRenderer-Variante umgeht ein hartnäckiges macOS-SwiftUI-Problem, bei dem `Text`-Views in separaten CATextLayern gerendert werden und nicht synchron mit Container-Animationen mitlaufen.

## Bauen & Entwickeln

```sh
# Nur kompilieren (in .build/)
swift build -c release

# .app-Bundle erzeugen (in build/Airplane Meetings.app)
./build.sh

# Nach ~/Applications installieren
./install.sh
```

Nach Code-Änderungen: `./build.sh` neu ausführen und App neu starten (im Menü ✈ → Beenden, dann wieder via Spotlight starten).

## Lizenz

MIT — siehe `LICENSE`.
