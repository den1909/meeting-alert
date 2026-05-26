import AppKit
import SwiftUI

@MainActor
final class AirplaneOverlayWindow: NSWindow {
    init(initialFrame: NSRect) {
        super.init(
            contentRect: initialFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .screenSaver
        self.ignoresMouseEvents = true
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
        self.isMovable = false
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class AirplaneOverlayController {
    static let shared = AirplaneOverlayController()

    private struct ScreenTarget {
        let window: NSWindow
        let imageView: NSImageView
        let windowMinX: CGFloat
        let yLocal: CGFloat
    }

    private var targets: [ScreenTarget] = []
    private var animationTimer: Timer?
    private var isFlying: Bool = false

    private init() {}

    func show(title: String, subtitle: String, duration: TimeInterval? = nil) {
        guard !isFlying else { return }
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }
        isFlying = true

        let bannerSize = NSSize(width: 600, height: 120)
        let rendered = renderBannerImage(title: title, subtitle: subtitle, size: bannerSize)

        let overallMaxX = screens.map(\.frame.maxX).max() ?? 0
        let overallMinX = screens.map(\.frame.minX).min() ?? 0
        let startGlobalX = overallMaxX + 50
        let endGlobalX = overallMinX - bannerSize.width - 50
        let totalDistance = startGlobalX - endGlobalX
        let pixelsPerSecond: CGFloat = 260
        let computedDuration = duration ?? max(10.0, Double(totalDistance / pixelsPerSecond))

        let padding: CGFloat = bannerSize.width + 100

        var newTargets: [ScreenTarget] = []
        for screen in screens {
            let windowFrame = NSRect(
                x: screen.frame.minX - padding,
                y: screen.frame.minY,
                width: screen.frame.width + padding * 2,
                height: screen.frame.height
            )

            let window = AirplaneOverlayWindow(initialFrame: windowFrame)
            let container = NSView(frame: NSRect(origin: .zero, size: windowFrame.size))

            // Y konstant 32% vom oberen Bildschirmrand (=68% vom unteren Rand)
            let yLocal = screen.frame.height * 0.68 - bannerSize.height / 2

            let imageView = NSImageView()
            imageView.image = rendered
            imageView.imageScaling = .scaleNone
            imageView.imageAlignment = .alignTopLeft
            imageView.autoresizingMask = []
            imageView.frame = NSRect(
                x: windowFrame.width + 100,
                y: yLocal,
                width: bannerSize.width,
                height: bannerSize.height
            )
            container.addSubview(imageView)
            window.contentView = container
            window.orderFrontRegardless()

            newTargets.append(ScreenTarget(
                window: window,
                imageView: imageView,
                windowMinX: windowFrame.minX,
                yLocal: yLocal
            ))
        }
        targets = newTargets

        let startTime = Date()
        animationTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(max(elapsed / computedDuration, 0), 1)
            let globalX = startGlobalX + (endGlobalX - startGlobalX) * CGFloat(progress)

            guard let self = self else { timer.invalidate(); return }
            for target in self.targets {
                let xLocal = globalX - target.windowMinX
                target.imageView.setFrameOrigin(NSPoint(x: xLocal, y: target.yLocal))
            }

            if progress >= 1.0 {
                timer.invalidate()
                Task { @MainActor in
                    self.animationTimer = nil
                    self.dismiss()
                }
            }
        }
        animationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func renderBannerImage(title: String, subtitle: String, size: NSSize) -> NSImage? {
        let view = StaticAirplaneBanner(title: title, subtitle: subtitle)
            .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = .init(width: size.width, height: size.height)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
        return renderer.nsImage
    }

    func dismiss() {
        animationTimer?.invalidate()
        animationTimer = nil
        for target in targets {
            target.window.orderOut(nil)
        }
        targets.removeAll()
        isFlying = false
    }
}
