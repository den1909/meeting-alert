# Airplane Meetings ✈

A tiny cartoon airplane tows a banner with the upcoming event's title across all your displays — 5 minutes before every calendar event or reminder.

Native macOS menu bar app. Reads events from the Calendar app and reminders from the Reminders app, so it works with whatever you have synced into macOS (Google Calendar, iCloud, Exchange, Outlook, …).

## Features

- ✈ Cartoon airplane with a waving fabric banner flies across **all** connected displays
- ⏰ Auto-triggers **5 minutes** before every event / reminder
- 📅 Reads from **Calendar** and **Reminders** (EventKit) — all synced accounts supported
- 🖥 Multi-display support: banner flies continuously from the rightmost screen to the leftmost
- 🚀 Optional auto-start at login (`SMAppService`)
- 🌟 Spotlight-searchable after installation
- 🔒 Fully local — no cloud, no tracking, no network

## Requirements

- macOS 13 (Ventura) or newer
- Xcode Command Line Tools (for `swift build`)

```sh
xcode-select --install
```

## Installation

```sh
git clone https://github.com/den1909/meeting-alert.git
cd meeting-alert
./build.sh        # builds the .app
./install.sh      # copies to ~/Applications, registers with Spotlight
```

After `install.sh`:
- Spotlight (`Cmd+Space`) → "Airplane Meetings" → Enter
- On first launch macOS asks for Calendar and Reminders permissions
- In the ✈ menu (top right): **"Start at Login"** for auto-start

## Usage

A ✈ icon appears in the menu bar. Clicking it opens the menu:

| Item                       | What it does                                                                |
| -------------------------- | --------------------------------------------------------------------------- |
| Next event                 | List of the next 6 events / reminders (`·` = event, `○` = reminder)         |
| **Test Flight** (⌘T)       | Fires the animation immediately — useful for testing                        |
| **Reload Calendar** (⌘R)   | Forces a refresh                                                            |
| **Start at Login**         | Toggle auto-start                                                           |
| Quit (⌘Q)                  | Quit the app                                                                |

## Configuration

Key values are currently exposed as constants in the code:

| Value                       | File                                              | Default          |
| --------------------------- | ------------------------------------------------- | ---------------- |
| Lead time                   | `Sources/.../Calendar/AlertScheduler.swift`       | 5 min            |
| Poll interval               | `Sources/.../Calendar/AlertScheduler.swift`       | 20 s             |
| Animation speed             | `Sources/.../UI/AirplaneOverlayWindow.swift`      | 260 px/s         |
| Banner color / size         | `Sources/.../UI/AirplaneFlightView.swift`         | red / 600×120 px |
| Y position (% from bottom)  | `Sources/.../UI/AirplaneOverlayWindow.swift`      | 0.68             |

## Architecture

```
Sources/AirplaneMeetings/
├── main.swift                    Entry point
├── App/
│   ├── AppDelegate.swift         App lifecycle, wiring
│   ├── MenuBarController.swift   NSStatusItem + menu
│   └── LoginItemManager.swift    SMAppService wrapper
├── Calendar/
│   ├── EventManager.swift        EventKit (EKEvent + EKReminder → FlightTrigger)
│   └── AlertScheduler.swift      Timer-based trigger (5 min before startDate)
└── UI/
    ├── AirplaneOverlayWindow.swift  Per-screen window animation (timer-driven)
    └── AirplaneFlightView.swift     SwiftUI banner (Canvas), rendered via ImageRenderer
```

**How the animation works:**

1. On trigger, a static banner image (airplane + red banner + text) is rendered once from a SwiftUI view via `ImageRenderer`.
2. For every connected display, a transparent, click-through `NSWindow` is created above all spaces — the window's frame covers that screen plus padding.
3. A 60 fps timer computes the global X position every frame. Each window updates its inner `NSImageView` to the window-local X. The banner is only visible on a single display at any moment — on the others it's clipped off-bounds. Visually it looks like one continuous flight.
4. Y position is per-screen-relative (68 % from bottom), so it sits sensibly on differently sized or vertically offset displays.

The ImageRenderer approach sidesteps a stubborn SwiftUI/macOS issue where `Text` views render in separate `CATextLayer`s and don't stay in sync with parent container animations.

## Build & Develop

```sh
# Compile only (output in .build/)
swift build -c release

# Produce the .app bundle (in build/Airplane Meetings.app)
./build.sh

# Install to ~/Applications
./install.sh
```

After code changes: re-run `./build.sh` and restart the app (✈ menu → Quit, then launch via Spotlight again).

## License

MIT — see `LICENSE`.
