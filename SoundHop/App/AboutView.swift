import AppKit
import SwiftUI

struct AboutView: View {
    @ObservedObject var tipJar: TipJarStore

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

            tipSection
                .padding(.horizontal, 32)

            Spacer(minLength: 20)

            footer
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
        .frame(width: 460, height: 580)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            if !tipJar.hasLoadedProducts {
                await tipJar.loadProducts()
            }
        }
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

            Text("Switch your Mac's sound output with a shortcut.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tip Jar")
                .font(.headline)

            Text("Tips support development and unlock nothing.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            switch tipJar.purchaseState {
            case .thankYou:
                thankYou
            case .pending:
                pending
            default:
                tipButtons
            }

            if let errorMessage = tipJar.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if tipJar.isStoreKitTestMode {
                Text("Local StoreKit testing")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var tipButtons: some View {
        VStack(spacing: 9) {
            if tipJar.isLoading && !tipJar.hasLoadedProducts {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading tips…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)
            } else if tipJar.hasLoadedProducts && tipJar.products.allSatisfy({ $0.product == nil }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tips are unavailable right now.")
                        .font(.subheadline)
                    Button("Try Again") {
                        Task { await tipJar.loadProducts() }
                    }
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(tipJar.products) { tip in
                    Button {
                        Task {
                            await tipJar.purchase(tip, in: NSApp.keyWindow)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(tip.displayName)
                                .font(.body.weight(.medium))
                            Spacer(minLength: 8)
                            Text(tip.displayPrice)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(tip.product == nil || tipJar.isPurchasing)
                    .accessibilityLabel(
                        tip.displayPrice.isEmpty
                            ? "Tip: \(tip.displayName)"
                            : "Tip \(tip.displayPrice): \(tip.displayName)"
                    )
                }
            }
        }
    }

    private var thankYou: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.fill")
                .font(.system(size: 34))
                .foregroundStyle(.pink)
                .accessibilityHidden(true)

            Text("Thank you!")
                .font(.title3.weight(.semibold))

            Text("Your support helps keep SoundHop going.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Done") {
                tipJar.resetPurchaseState()
            }
            .controlSize(.large)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var pending: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your purchase is pending approval.")
                .font(.subheadline)
            Text("The tip will be completed once the App Store approves it.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("OK") {
                tipJar.resetPurchaseState()
            }
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
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
