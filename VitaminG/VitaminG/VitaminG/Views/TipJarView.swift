import SwiftUI
import StoreKit

// MARK: - TipJarView
// Three-tier consumable tip jar screen.
// Reached via NavigationLink from AboutView (Plan 19-04).
// MON-02: renders 3 tiers with product.displayPrice from StoreKit.
// MON-03 / T-19-03-03: zero external payment URLs (grep-verified).
// T-19-03-01: fullScreenCover shown ONLY on success == true (verified transaction).
// T-19-03-05: purchasingProductID disables Buy during in-flight purchase.
// T-19-03-06: empty product list is surfaced as a visible error, not a silent failure.

struct TipJarView: View {

    @State private var store = TipStore()
    @State private var showThankYou = false
    @State private var purchasingProductID: String? = nil

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Section heading
                Text("Support the Developer")
                    .font(VGTheme.serif(28, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                // State machine: loading / error / loaded
                if store.isLoading && store.products.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 120)

                } else if store.products.isEmpty && !store.isLoading {
                    // T-19-03-06: surface error rather than silent empty state
                    Text("Couldn't load tips. Check your connection and try again.")
                        .font(.callout)
                        .foregroundStyle(VGTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .onAppear {
                            AccessibilityNotification.Announcement("Couldn't load tips. Check your connection and try again.").post()
                        }

                } else {
                    ForEach(store.products, id: \.id) { product in
                        TipTierCard(
                            product: product,
                            isPurchasing: purchasingProductID != nil
                        ) {
                            purchasingProductID = product.id
                            Task {
                                let (success, _) = await store.purchase(product)
                                purchasingProductID = nil
                                // T-19-03-01: set showThankYou ONLY on verified success
                                if success {
                                    showThankYou = true
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(VGTheme.sandLight.ignoresSafeArea())
        .navigationTitle("Tip Jar")
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.fetchProducts() }
        .fullScreenCover(isPresented: $showThankYou) {
            TipThankYouView { showThankYou = false }
                .interactiveDismissDisabled(true)
        }
    }
}

// MARK: - TipTierCard

private struct TipTierCard: View {

    let product: Product
    let isPurchasing: Bool
    let onTap: () -> Void

    // Emoji mapped by product ID suffix
    private var emoji: String {
        if product.id == TipProductID.smallCoffee.rawValue {
            return "☕"
        } else if product.id == TipProductID.largeCoffee.rawValue {
            return "☕☕"
        } else {
            return "💛"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.title)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(VGTheme.textPrimary)
                Text(product.displayPrice)
                    .font(.callout)
                    .foregroundStyle(VGTheme.accentTerra)
            }

            Spacer()

            Button("Buy") {
                onTap()
            }
            .font(.callout.weight(.semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(VGTheme.accentTerra)
            .foregroundStyle(VGTheme.warmWhite)
            .clipShape(Capsule())
            .frame(minHeight: 44)
            // T-19-03-05: disable all Buy buttons while any purchase is in-flight
            .disabled(isPurchasing)
            .accessibilityLabel("Buy \(product.displayName) tip for \(product.displayPrice)")
        }
        .padding(16)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
