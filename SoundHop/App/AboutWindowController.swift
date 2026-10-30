import AppKit
import SwiftUI

@MainActor
final class AboutWindowController: NSWindowController, NSWindowDelegate {
    static let shared = AboutWindowController()

    private init() {
        super.init(window: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        if window == nil {
            configureWindow()
        }

        guard let window else { return }

        NSApp.setActivationPolicy(.regular)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    func windowWillClose(_ notification: Notification) {
        let settingsIsOpen = SettingsOpener.findSettingsWindow()?.isVisible == true
        if !settingsIsOpen {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func configureWindow() {
        let content = NSHostingController(rootView: AboutView())
        let window = NSWindow(contentViewController: content)
        window.title = "About SoundHop"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.collectionBehavior = [.moveToActiveSpace]
        window.setContentSize(NSSize(width: 460, height: 460))
        window.minSize = NSSize(width: 460, height: 460)
        window.maxSize = NSSize(width: 460, height: 460)
        self.window = window
    }
}
