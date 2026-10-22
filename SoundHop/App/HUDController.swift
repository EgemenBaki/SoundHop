import AppKit
import SwiftUI

/// A small, non-activating panel modelled on the system volume overlay.
@MainActor
final class HUDController {
    static let shared = HUDController()

    private var panel: HUDPanel?
    private var hideTask: Task<Void, Never>?
    private let visibleDuration: Duration = .seconds(1.5)
    private let panelSize = NSSize(width: 320, height: 92)

    private init() {}

    func present(_ feedback: DeviceActionFeedback) {
        guard Preferences.showHUD else { return }

        let panel = panel ?? makePanel()
        panel.contentView = NSHostingView(rootView: HUDView(feedback: feedback))
        panel.setContentSize(panelSize)
        position(panel)

        hideTask?.cancel()
        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
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
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
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

    private func position(_ panel: HUDPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first {
            NSMouseInRect(mouseLocation, $0.frame, false)
        } ?? NSScreen.main

        guard let screen else { return }
        let frame = screen.visibleFrame
        let origin = NSPoint(
            x: frame.midX - panelSize.width / 2,
            y: frame.maxY - panelSize.height - 14
        )
        panel.setFrameOrigin(origin)
    }
}

private final class HUDPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private struct HUDView: View {
    let feedback: DeviceActionFeedback

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: feedback.hudSymbolName)
                .font(.system(size: 28, weight: .medium))
                .frame(width: 36, height: 36)
                .foregroundStyle(feedback.isError ? Color.orange : Color.primary)

            VStack(alignment: .leading, spacing: 3) {
                Text(feedback.hudTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(feedback.hudDetail)
                    .font(.headline)
                    .lineLimit(2)
                    .truncationMode(.middle)
                if feedback.isVirtual && feedback.kind == .switched {
                    Text("Virtual output")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(width: 320, height: 92)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
    }
}
