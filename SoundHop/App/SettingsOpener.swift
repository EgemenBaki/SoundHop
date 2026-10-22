import AppKit
import SwiftUI

extension Notification.Name {
    static let soundHopOpenSettings = Notification.Name("soundhop.openSettings")
    static let soundHopSettingsWindowClosed = Notification.Name("soundhop.settingsWindowClosed")
}

enum SettingsOpener {
    static func open() {
        NotificationCenter.default.post(name: .soundHopOpenSettings, object: nil)
    }

    @MainActor
    static func findSettingsWindow() -> NSWindow? {
        NSApp.windows.first { window in
            // Never mistake the invisible context window for the real one.
            if window.identifier?.rawValue.contains("HiddenWindow") == true
                || window.title == "Hidden" {
                return false
            }

            if window.title.localizedCaseInsensitiveContains("settings")
                || window.title.localizedCaseInsensitiveContains("preferences") {
                return true
            }

            if window.identifier?.rawValue.contains("Settings") == true {
                return true
            }

            if let contentViewController = window.contentViewController,
               String(describing: type(of: contentViewController)).contains("Settings") {
                return true
            }

            return false
        }
    }
}

/// A one-pixel, invisible window that gives SwiftUI a live render tree.
///
/// SwiftUI's `openSettings` action silently does nothing in a menu bar-only app
/// unless some SwiftUI scene is already rendered. This hidden window provides
/// that context. It must be declared before the `Settings` scene.
struct HiddenSettingsContextView: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .background(OffscreenWindowConfigurator())
            .onReceive(NotificationCenter.default.publisher(for: .soundHopOpenSettings)) { _ in
                Task { @MainActor in
                    NSApp.setActivationPolicy(.regular)
                    try? await Task.sleep(for: .milliseconds(100))

                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()

                    try? await Task.sleep(for: .milliseconds(250))
                    if let settingsWindow = SettingsOpener.findSettingsWindow() {
                        settingsWindow.makeKeyAndOrderFront(nil)
                        settingsWindow.orderFrontRegardless()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .soundHopSettingsWindowClosed)) { _ in
                Task { @MainActor in
                    let aboutIsOpen = AboutWindowController.shared.window?.isVisible == true
                    if !aboutIsOpen {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
            }
    }
}

private struct OffscreenWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        OffscreenView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class OffscreenView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }

        window.alphaValue = 0
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isMovable = false
        window.isExcludedFromWindowsMenu = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
    }
}
