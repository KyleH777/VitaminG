import XCTest
@testable import VitaminG

// MARK: - TipStoreTests
// Plan 19-03: Unit tests for TipProductID enum and initial TipStore state.
// These are pure unit tests — no live StoreKit fetch is asserted.
// Live sandbox verification is handled by the human checkpoint (Task 4).

final class TipStoreTests: XCTestCase {

    // MARK: - TipProductID Tests

    func test_tipProductID_hasExactlyThreeCases() {
        XCTAssertEqual(TipProductID.allCases.count, 3, "TipProductID must have exactly 3 cases")
    }

    func test_tipProductID_rawValuesHaveCorrectPrefix() {
        let prefix = "com.kyleharrington.VitaminG.tip."
        for id in TipProductID.allCases {
            XCTAssertTrue(
                id.rawValue.hasPrefix(prefix),
                "TipProductID raw value '\(id.rawValue)' must begin with '\(prefix)'"
            )
        }
    }

    func test_tipProductID_rawValuesMatchStorekitConfig() {
        let expected: Set<String> = [
            "com.kyleharrington.VitaminG.tip.small",
            "com.kyleharrington.VitaminG.tip.large",
            "com.kyleharrington.VitaminG.tip.supporter"
        ]
        let actual = Set(TipProductID.allCases.map(\.rawValue))
        XCTAssertEqual(actual, expected, "TipProductID raw values must exactly match VitaminGTips.storekit product IDs")
    }

    // MARK: - TipStore Initial State Tests

    @MainActor
    func test_tipStore_initialState_productsIsEmpty() {
        let store = TipStore()
        XCTAssertTrue(store.products.isEmpty, "A freshly constructed TipStore must have products == []")
    }

    @MainActor
    func test_tipStore_initialState_isLoadingIsFalse() {
        let store = TipStore()
        XCTAssertFalse(store.isLoading, "A freshly constructed TipStore must have isLoading == false")
    }

    @MainActor
    func test_tipStore_initialState_purchaseErrorIsNil() {
        let store = TipStore()
        XCTAssertNil(store.purchaseError, "A freshly constructed TipStore must have purchaseError == nil")
    }
}
