import Observation
import StoreKit

// MARK: - TipProductID
// Product IDs must exactly match VitaminGTips.storekit and App Store Connect.

enum TipProductID: String, CaseIterable {
    case smallCoffee = "com.kyleharrington.VitaminG.tip.small"
    case largeCoffee = "com.kyleharrington.VitaminG.tip.large"
    case supporter   = "com.kyleharrington.VitaminG.tip.supporter"
}

// MARK: - TipStore
// StoreKit 2 ViewModel for the consumable tip jar.
// MON-02: fetches 3 consumable products with real prices.
// MON-03: no external payment URLs — all purchase flow is StoreKit.
// T-19-03-01: unverified transactions return (false, false) — never trigger showThankYou.
// T-19-03-05: purchasingProductID in TipJarView disables Buy during in-flight purchase.

@MainActor
@Observable
final class TipStore {

    // MARK: - Published State

    /// Sorted by price ascending: Small Coffee -> Large Coffee -> Supporter.
    var products: [Product] = []
    var isLoading: Bool = false
    var purchaseError: String? = nil

    // MARK: - Fetch Products

    /// Fetches the three consumable tip products from StoreKit (or local .storekit config in Simulator).
    /// Sorts ascending by price so tier order matches design spec.
    func fetchProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await Product.products(
                for: Set(TipProductID.allCases.map(\.rawValue))
            )
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            purchaseError = "Couldn't load tips. Check your connection and try again."
        }
    }

    // MARK: - Purchase

    /// Executes a StoreKit 2 purchase and verifies the transaction signature.
    /// Returns (success: true, cancelled: false) ONLY on a verified transaction.
    /// T-19-03-01: .unverified returns (false, false) — no feature delivery, no thank-you screen.
    /// T-19-03-05: caller (TipJarView) must disable the Buy button while this is in-flight.
    func purchase(_ product: Product) async -> (success: Bool, cancelled: Bool) {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Consumable: finish the transaction without granting any entitlement (MON-04)
                    await transaction.finish()
                    return (true, false)
                case .unverified:
                    // T-19-03-01: forged/tampered transaction — do not deliver anything
                    return (false, false)
                }
            case .userCancelled:
                return (false, true)
            case .pending:
                return (false, false)
            @unknown default:
                return (false, false)
            }
        } catch {
            purchaseError = error.localizedDescription
            return (false, false)
        }
    }
}
