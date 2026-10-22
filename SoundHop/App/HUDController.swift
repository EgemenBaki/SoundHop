import AppKit
import SwiftUI

/// A small, non-activating panel modelled on the system volume overlay.
@MainActor
final class HUDController {
    static let shared = HUDController()

    private var panel: HUDPanel?
    private var hideTask: Task<Void, Never>?
    private let visibleDuration: Duration = .seconds(1.5)
    private let panelSize = NSSize(width: 252, height: 64)

    private init() {}

    func present(_ feedback: DeviceActionFeedback) {
        guard Preferences.showHUD else { return }

        let panel = panel ?? makePanel()
        panel.contentView = NSHostingView(rootView: HUDView(feedback: feedback))
        panel.setContentSize(panelSize)

        let destination = destinationOrigin()
        panel.setFrameOrigin(NSPoint(x: destination.x, y: destination.y + 5))
        hideTask?.cancel()
        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
            panel.animator().setFrameOrigin(destination)
        }

        let duration = visibleDuration
        hideTask = Task { [weak self, weak panel] in
            do {
                try await Task.sleep(for: duration)
            } catch {
                return
            }
            guard let self, let panel, !Task.isCancelled else { return }
            self.hide(panel)
        }
    }

    private func hide(_ panel: HUDPanel) {
        var destination = panel.frame.origin
        destination.y += 4

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
            panel.animator().setFrameOrigin(destination)
        } completionHandler: {
            Task { @MainActor in
                panel.orderOut(nil)
            }
        }
    }

    private func makePanel() -> HUDPanel {
        let panel = HUDPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.ignoresMouseEvents = true
        panel.animationBehavior = .none
        self.panel = panel
        return panel
    }

    private func destinationOrigin() -> NSPoint {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first {
            NSMouseInRect(mouseLocation, $0.frame, false)
        } ?? NSScreen.main

        guard let screen else { return .zero }
        let frame = screen.visibleFrame
        return NSPoint(
            x: frame.midX - panelSize.width / 2,
            y: frame.maxY - panelSize.height - 10
        )
    }
}

private final class HUDPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private struct HUDView: View {
    let feedback: DeviceActionFeedback

    var body: some View {
        HStack(spacing: 10) {
            icon

            Text(feedback.hudText)
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)
                .truncationMode(.middle)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(width: 252, height: 64)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        }
    }

    private var icon: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint.opacity(0.18))
                .frame(width: 32, height: 32)

            Image(systemName: feedback.hudSymbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .symbolEffect(.bounce, value: feedback.id)

            if !feedback.isError {
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 12, height: 12)
                    .background(Circle().fill(Color.green))
                    .overlay {
                        Circle().strokeBorder(.white.opacity(0.55), lineWidth: 0.5)
                    }
                    .offset(x: 2, y: 2)
            }
        }
        .frame(width: 34, height: 34)
    }

    private var tint: Color {
        if feedback.isError {
            return .orange
        }

        switch feedback.transport {
        case .builtIn: return .blue
        case .bluetooth, .bluetoothLE: return .purple
        case .usb: return .orange
        case .hdmi, .displayPort: return .indigo
        case .airPlay: return .teal
        case .aggregate, .virtual: return .gray
        default: return .accentColor
        }
    }
}
