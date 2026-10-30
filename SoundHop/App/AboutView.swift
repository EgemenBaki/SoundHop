import AppKit
import SwiftUI

struct AboutView: View {
    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 34)

            Divider()
                .padding(.horizontal, 32)
                .padding(.vertical, 22)

            VStack(spacing: 14) {
                Text("A tiny macOS menu bar app for switching your sound output with a global shortcut.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Link(destination: URL(string: "https://github.com/EgemenBaki/SoundHop")!) {
                    Label("View source on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .font(.subheadline.weight(.medium))
                .buttonStyle(.bordered)
                .controlSize(.large)

                Text("MIT licensed · Free and open source")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 44)

            Spacer(minLength: 20)

            footer
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
        .frame(width: 460, height: 460)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(spacing: 10) {
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 84, height: 84)
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "hifispeaker.2.fill")
                    .font(.system(size: 62, weight: .medium))
                    .frame(width: 84, height: 84)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
            }

            Text("SoundHop")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(versionText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Switch your Mac’s sound output with a shortcut.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var footer: some View {
        VStack(spacing: 5) {
            Text("SoundHop collects no data.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("© 2026 Egemen Baki")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
