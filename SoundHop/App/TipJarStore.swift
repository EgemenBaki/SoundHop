import AppKit
import StoreKit

@MainActor
final class TipJarStore: ObservableObject {
    enum ProductID: String, CaseIterable {
        case small = "com.egemenbaki.soundhop.tip.small"
        case medium = "com.egemenbaki.soundhop.tip.medium"
        case large = "com.egemenbaki.soundhop.tip.large"

        var fallbackDisplayName: String {
            switch self {
            case .small: "Small Tip"
            case .medium: "Medium Tip"
            case .large: "Large Tip"
            }
        }
    }

    struct TipProduct: Identifiable {
        let id: String
        let displayName: String
        let displayPrice: String
        let product: Product?
    }

    enum PurchaseState: Equatable {
        case idle
        case purchasing(productID: String)
        case pending
        case thankYou(productID: String)
    }

    enum TipJarError: LocalizedError {
        case verificationFailed

        var errorDescription: String? {
            "The App Store could not verify this purchase."
        }
    }

    @Published private(set) var products: [TipProduct] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoadedProducts = false
    @Published private(set) var purchaseState: PurchaseState = .idle
    @Published private(set) var errorMessage: String?
    @Published private(set) var isStoreKitTestMode = false

    var isPurchasing: Bool {
        if case .purchasing = purchaseState {
            return true
        }
        return false
    }

    func prepareForPresentation() {
        if case .thankYou = purchaseState {
            purchaseState = .idle
        }
        errorMessage = nil
    }

    func loadProducts() async {
        guard !isLoading else { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoadedProducts = true
        }

        do {
            let loaded = try await Product.products(
                for: ProductID.allCases.map(\.rawValue)
            )
            let byID = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
            products = ProductID.allCases.map { productID in
                let product = byID[productID.rawValue]
                return TipProduct(
                    id: productID.rawValue,
                    displayName: product?.displayName ?? productID.fallbackDisplayName,
                    displayPrice: product?.displayPrice ?? "",
                    product: product
                )
            }
            errorMessage = nil
            await detectTestMode()
        } catch {
            errorMessage = error.localizedDescription
            products = ProductID.allCases.map {
                TipProduct(
                    id: $0.rawValue,
                    displayName: $0.fallbackDisplayName,
                    displayPrice: "",
                    product: nil
                )
            }
        }
    }

    func purchase(_ tip: TipProduct, in window: NSWindow? = nil) async {
        guard let product = tip.product, !isPurchasing else { return }

        purchaseState = .purchasing(productID: tip.id)
        errorMessage = nil

        do {
            let result: Product.PurchaseResult
            if #available(macOS 15.2, *), let window {
                result = try await product.purchase(confirmIn: window)
            } else {
                result = try await product.purchase()
            }

            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                await transaction.finish()
                purchaseState = .thankYou(productID: tip.id)
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .pending
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            errorMessage = error.localizedDescription
            purchaseState = .idle
        }
    }

    func resetPurchaseState() {
        purchaseState = .idle
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw TipJarError.verificationFailed
        }
    }

    private func detectTestMode() async {
        guard let result = try? await AppTransaction.shared,
              case .verified(let appTransaction) = result
        else {
            return
        }
        isStoreKitTestMode = appTransaction.environment == .xcode
    }
}
