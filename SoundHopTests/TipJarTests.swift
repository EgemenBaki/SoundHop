import StoreKit
import StoreKitTest
import XCTest
@testable import SoundHop

@MainActor
final class TipJarTests: XCTestCase {
    private var session: SKTestSession!

    override func setUp() async throws {
        let url = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "SoundHop", withExtension: "storekit")
        )
        session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
    }

    override func tearDown() async throws {
        session = nil
    }

    func testLoadsThreeProductsInDisplayOrder() async throws {
        let store = TipJarStore()
        await store.loadProducts()

        XCTAssertTrue(store.hasLoadedProducts)
        XCTAssertEqual(
            store.products.map(\.id),
            TipJarStore.ProductID.allCases.map(\.rawValue)
        )
        XCTAssertTrue(store.products.allSatisfy { $0.product != nil })
        XCTAssertEqual(store.products.map(\.displayPrice), ["$1.99", "$4.99", "$9.99"])
        XCTAssertEqual(
            store.products.map(\.displayName),
            ["Small Tip", "Medium Tip", "Large Tip"]
        )
    }

    func testConsumablePurchaseShowsThankYou() async throws {
        let store = TipJarStore()
        await store.loadProducts()
        let tip = try XCTUnwrap(store.products.first)

        await store.purchase(tip)

        XCTAssertEqual(store.purchaseState, .thankYou(productID: tip.id))
        XCTAssertNil(store.errorMessage)
    }
}
