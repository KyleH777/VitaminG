# Features Spec — Vitamin G
**Date:** 2026-05-13  
**Scope:** Phone OTP, Tip jar, Quote rotation, Notification quotes, Dark mode

---

## 1. Phone OTP Verification

### Dependency
Firebase Auth (`FirebaseAuth` SDK) — justified exception to no-third-party-dependency rule. No other iOS-native path provides arbitrary SMS OTP without a custom backend.

Add to project via Swift Package Manager: `https://github.com/firebase/firebase-ios-sdk`, product `FirebaseAuth` only (no Analytics, no Crashlytics).

### Current state
`PhoneSignupScreen.swift` captures phone/email and stores in `AppStorage`. No verification occurs.

### New flow
1. User enters phone number + dial code → taps "Send Code"
2. `PhoneAuthProvider.provider().verifyPhoneNumber("+1\(phone)", uiDelegate: nil)` called
3. On success: `verificationID` stored in `@State`, view transitions to OTP entry field (6-digit)
4. User enters code → `PhoneAuthCredential` created → `Auth.auth().signIn(with:)` called
5. On success: `AppStorage("vg_phoneVerified") = true`, `AppStorage("vg_signupPhone")` already set — proceed to next onboarding step
6. On error: inline error message below the field (no alert), retry allowed

### ViewModel
New `PhoneVerificationViewModel` (`@Observable`):
```swift
enum VerificationStep { case phoneEntry, codeEntry }
var step: VerificationStep = .phoneEntry
var phoneNumber: String = ""
var verificationCode: String = ""
var verificationID: String? = nil
var isLoading: Bool = false
var errorMessage: String? = nil

func sendCode(dialCode: String) async  // calls FirebaseAuth
func verifyCode() async -> Bool         // returns true on success
```

### PhoneSignupScreen changes
- Wire "Send Code" button to `viewModel.sendCode()`
- Add OTP entry view (6 individual digit boxes, auto-advance on input) shown when `step == .codeEntry`
- Loading state: disable button, show `ProgressView` inline
- Skip option preserved for users who don't want to verify

### Security
- `verificationID` stored in `@State` only (never persisted)
- 6-digit code validated as numeric before submission
- Firebase rate-limits abuse automatically

---

## 2. Tip Jar (StoreKit 2)

### Products
Three consumable in-app purchases configured in App Store Connect:
| Product ID | Price | Label |
|------------|-------|-------|
| `com.kyleharrington.VitaminG.tip_small` | $0.99 | "Buy me a coffee ☕" |
| `com.kyleharrington.VitaminG.tip_medium` | $2.99 | "Treat me to lunch 🥗" |
| `com.kyleharrington.VitaminG.tip_large` | $4.99 | "You're amazing 🙌" |

Consumables — no entitlement to unlock, purely gratitude.

### New file: `Views/SupportCreatorView.swift`

Layout (`ScrollView` on `VGTheme.sandLight`):

**Header**: `VGTheme.serif(28)` "Support the Creator", `VGTheme.clay`

**Creator card**: `VGTheme.warmWhite` card, 18pt radius. Avatar (existing `AvatarView`), name, short thank-you message: *"Vitamin G is built by one person. If it's brought value to your day, a tip means the world."*

**Tip buttons**: Three `VStack` cards, each:
- Emoji + label (14pt bold `VGTheme.clay`)
- Price in `VGTheme.terra` (13pt)
- Terra-filled purchase button ("Send Tip")
- Loading spinner replaces button during purchase

**Success state**: Full-width `VGTheme.sageLight` card with ✅ "Thank you! Your support keeps Vitamin G growing." Dismisses after 3 seconds.

**Restore purchases**: Ghost button at bottom ("Restore Purchases") — calls `AppStore.sync()`.

### TipViewModel (`@Observable`)
```swift
var products: [Product] = []
var purchaseState: PurchaseState = .idle  // .idle | .loading(id) | .success | .failed(Error)

func loadProducts() async    // Product.products(for: productIDs)
func purchase(_ product: Product) async
```

Uses StoreKit 2 (`import StoreKit`). No third-party dependency needed.

### Access point
`NavigationLink` to `SupportCreatorView` added to `SettingsView` (new row: "Support the Creator ❤️").

---

## 3. Quote Rotation (No-Repeat Within Year)

### Current state
`VGQuoteBank.swift` has categorized quote arrays but no rotation/scheduling logic.

### All-quotes pool
Add computed property to `VGQuoteBank`:
```swift
static let all: [VGQuote] = action + resilience + /* all category arrays */
```

### Yearly shuffle algorithm
`VGQuoteScheduler` — new file `Services/VGQuoteScheduler.swift`:

```swift
enum VGQuoteScheduler {
    private static let shuffleKey = "vg_quoteShuffleYear"
    private static let orderKey   = "vg_quoteShuffleOrder"

    /// Returns today's quote. Regenerates the shuffled order each calendar year.
    static func todayQuote() -> VGQuote {
        let year = Calendar.current.component(.year, from: Date())
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1

        // Regenerate shuffle if year changed or order missing
        if UserDefaults.standard.integer(forKey: shuffleKey) != year
            || UserDefaults.standard.array(forKey: orderKey) == nil {
            regenerateShuffle(for: year)
        }

        let order = UserDefaults.standard.array(forKey: orderKey) as? [Int] ?? []
        let count = VGQuoteBank.all.count
        // Wrap index within the shuffled order, cycling if day > quote count
        let index = order[(dayOfYear - 1) % max(order.count, 1)] % count
        return VGQuoteBank.all[index]
    }

    private static func regenerateShuffle(for year: Int) {
        // Seeded Fisher-Yates using year as seed for reproducibility
        var indices = Array(0..<VGQuoteBank.all.count)
        var rng = SeededRNG(seed: UInt64(year))
        for i in stride(from: indices.count - 1, through: 1, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            indices.swapAt(i, j)
        }
        UserDefaults.standard.set(year, forKey: shuffleKey)
        UserDefaults.standard.set(indices, forKey: orderKey)
    }
}

// Minimal seeded LCG RNG — no Foundation/GameplayKit dependency
struct SeededRNG {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
```

### ProfileViewModel update
Replace the static `quotes` array in `ProfileView` with `VGQuoteScheduler.todayQuote().displayText`.

### QuoteWidget update
`QuoteProvider` uses `VGQuoteScheduler.todayQuote()` instead of a hardcoded array with day-index rotation.

---

## 4. Notification Quotes

### Current state
`NotificationScheduler.makeContent(activeGoals:)` builds a body from goal titles only.

### Change
Append today's quote to the notification body:

```swift
func makeContent(activeGoals: [Goal]) -> UNMutableNotificationContent {
    // ... existing goal title logic ...
    let quote = VGQuoteScheduler.todayQuote()
    content.subtitle = ""\(quote.displayText)""  // new: italic quote as subtitle
    // body stays as goal titles
    return content
}
```

`subtitle` renders below title in the notification banner and lock screen — no layout changes needed. Quote attribution omitted in notification (too long).

---

## 5. Dark Mode

### Strategy
Replace hardcoded `VGTheme` static colors with **semantic adaptive colors** that resolve differently in light vs dark. Use `Color(uiColor: UIColor { trait in ... })` pattern.

### Dark palette (mirrors design spec's clay-background screens)
| Semantic token | Light | Dark |
|----------------|-------|------|
| `background` | `sandLight` #FAF5EE | `clay` #3D2F1E |
| `backgroundSecondary` | `warmWhite` #FDFAF6 | `clayMid` #5A4232 |
| `surface` | `warmWhite` #FDFAF6 | `clayMid` #5A4232 |
| `surfaceSecondary` | `sandMid` #E8D9C4 | `#4A3828` |
| `textPrimary` | `clay` #3D2F1E | `sand` #F2E8D9 |
| `textSecondary` | `muted` #9A8A78 | `#C4B09A` |
| `separator` | `sandMid` #E8D9C4 | `#5A4232` |
| `terra` | unchanged | unchanged (accent stays) |
| `sage` | unchanged | unchanged |
| `gold` | unchanged | unchanged |
| `purple` | unchanged | unchanged |

### VGTheme extension
Add to `VGTheme.swift`:
```swift
// MARK: - Adaptive semantic tokens (light/dark)
static let background = Color(uiColor: UIColor { t in
    t.userInterfaceStyle == .dark
        ? UIColor(red: 0.239, green: 0.184, blue: 0.118, alpha: 1)  // clay
        : UIColor(red: 0.980, green: 0.961, blue: 0.933, alpha: 1)  // sandLight
})
static let backgroundSecondary = Color(uiColor: UIColor { t in
    t.userInterfaceStyle == .dark
        ? UIColor(red: 0.353, green: 0.259, blue: 0.196, alpha: 1)  // clayMid
        : UIColor(red: 0.992, green: 0.980, blue: 0.965, alpha: 1)  // warmWhite
})
static let surface = backgroundSecondary
static let textPrimary = Color(uiColor: UIColor { t in
    t.userInterfaceStyle == .dark
        ? UIColor(red: 0.949, green: 0.910, blue: 0.851, alpha: 1)  // sand
        : UIColor(red: 0.239, green: 0.184, blue: 0.118, alpha: 1)  // clay
})
static let textSecondary = Color(uiColor: UIColor { t in
    t.userInterfaceStyle == .dark
        ? UIColor(red: 0.769, green: 0.690, blue: 0.604, alpha: 1)  // lightened muted
        : UIColor(red: 0.604, green: 0.541, blue: 0.471, alpha: 1)  // muted
})
static let separator = Color(uiColor: UIColor { t in
    t.userInterfaceStyle == .dark
        ? UIColor(red: 0.353, green: 0.259, blue: 0.196, alpha: 1)
        : UIColor(red: 0.910, green: 0.851, blue: 0.769, alpha: 1)  // sandMid
})
```

### View migration rule
In all views modified by the visual redesign spec, replace:
- `VGTheme.sandLight` → `VGTheme.background`
- `VGTheme.warmWhite` / `Color(.systemBackground)` → `VGTheme.surface`
- `VGTheme.clay` (when used as text color) → `VGTheme.textPrimary`
- `VGTheme.muted` (when used as secondary text) → `VGTheme.textSecondary`
- `VGTheme.sandMid` (dividers/separators) → `VGTheme.separator`
- `VGTheme.clay` / `VGTheme.clayMid` (hero banner gradient) — **keep as-is** (hero is intentionally dark in both modes)
- `VGTheme.terra`, `VGTheme.sage`, `VGTheme.gold`, `VGTheme.purple` — **keep as-is** (accents unchanged)

### Widget dark mode
`.containerBackground(VGTheme.surface, for: .widget)` — adaptive token handles light/dark automatically.

### Hero banner in dark mode
The clay gradient hero (ProfileView, GoalListView primary challenge card) stays clay in both modes — it's an intentional brand element, not a surface color.

### App-level setting
No manual dark mode toggle — respects iOS system setting (`@Environment(\.colorScheme)`). Do not override `preferredColorScheme` globally.

---

## Files Touched

| File | Change |
|------|--------|
| `Views/Onboarding/PhoneSignupScreen.swift` | Wire Firebase OTP flow |
| `ViewModels/PhoneVerificationViewModel.swift` | New file |
| `Views/SupportCreatorView.swift` | New file |
| `ViewModels/TipViewModel.swift` | New file |
| `Views/SettingsView.swift` | Add "Support the Creator" link |
| `Services/VGQuoteScheduler.swift` | New file |
| `Services/VGQuoteBank.swift` | Add `all` computed pool |
| `Services/NotificationScheduler.swift` | Add quote subtitle |
| `VitaminGWidget/QuoteWidget.swift` | Use VGQuoteScheduler |
| `VitaminG/VGTheme.swift` | Add adaptive semantic tokens |
| All views in visual redesign spec | Swap to semantic tokens |
| `Package.swift` / SPM | Add FirebaseAuth |

## Dependencies Added
| Package | Justification |
|---------|--------------|
| `FirebaseAuth` (Firebase iOS SDK via SPM) | Only viable SMS OTP path without custom backend |
