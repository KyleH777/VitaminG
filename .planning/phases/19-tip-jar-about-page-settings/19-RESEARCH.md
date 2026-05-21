# Phase 19: Tip Jar + About Page + Settings - Research

**Researched:** 2026-05-21
**Domain:** StoreKit 2 consumable IAP, SwiftUI color scheme management, onboarding flow extension, notification copy
**Confidence:** HIGH

## Summary

Phase 19 adds three interconnected feature areas to an existing SwiftUI/SwiftData iOS app: (1) an AboutView with a sticky tip CTA navigating to a TipJarView backed by StoreKit 2 consumable IAPs, (2) expansion of the existing SettingsView Form with Appearance/Privacy/Support sections wired to @AppStorage and SwiftData, and (3) a conditional onboarding step for nudge-time selection plus a notification copy overhaul.

All decisions are locked in CONTEXT.md via D-01 through D-17. The architecture is entirely native — no third-party IAP wrappers, no external payment links, no ad SDKs. The codebase already has strong patterns to reuse: MilestoneCelebrationView's `.fullScreenCover` confetti pattern, VGQuoteBank's day-of-year rotation formula, NotificationScheduler's remove-before-add pattern, ProfileViewModel's `toggleProfilePublic`, and the StepBarView component for onboarding progress bars.

The most complex task is StoreKit 2 integration, which requires a new `.storekit` configuration file for sandbox testing, App Store Connect product IDs, a `TipStore` ViewModel, and a `Transaction.updates` listener wired at `VitaminGApp.init`. The second most complex is the conditional onboarding step: the `OnboardingStep` enum must gain a `.nudgeTimePicker` case and `NotificationOnboardingScreen.allow()` must conditionally push `.nudgeTimePicker` instead of directly `.cameraPermission`.

**Primary recommendation:** Build in five waves — (1) Settings expansion, (2) AboutView, (3) TipJarView + StoreKit, (4) post-purchase celebration, (5) onboarding nudge-time step + notification copy update.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** About page via "About Vitamin G" NavigationLink row at bottom of SettingsView (not second link in ProfileView)
- **D-02:** Tip button is floating sticky footer on AboutView; reads "Buy me a coffee ☕" or "Tip the Developer"
- **D-03:** About page content: app name, version from Bundle.main.infoDictionary, and founder bio (cancer recovery + goal-setting story — verbatim)
- **D-04:** TipJarView via NavigationLink push from AboutView (not a sheet)
- **D-05:** Three consumable tiers: Small Coffee (~$0.99), Large Coffee (~$2.99), Supporter (~$4.99); prices via `product.displayPrice`
- **D-06:** Post-purchase: `.fullScreenCover` thank-you with animation; dismissed via "Done" button; no auto-dismiss
- **D-07:** Consumables always purchasable — no "already purchased" state
- **D-08:** `Transaction.updates` listener at `VitaminGApp` init; TipJarView fetches prices with `Product.products(for:)` on appear
- **D-09:** No external payment links anywhere (App Store Guideline 3.1.1)
- **D-10:** Extend existing SettingsView Form — new sections: Appearance (Picker), Privacy (Toggle), Support (Contact + About row)
- **D-11:** Dark mode via `@AppStorage("vg_colorScheme")` on `ColorSchemePreference` enum; `.preferredColorScheme()` on WindowGroup; immediate effect
- **D-12:** Contact Support opens `mailto:VitaminG.info@gmail.com?subject=Vitamin%20G%20Support` via `openURL`
- **D-13:** Nudge-time picker is conditional onboarding step — only shown if Step 6 (NotificationOnboardingScreen) grants permission
- **D-14:** Nudge-time screen has 5 chips (6–10 AM) + "Custom time" DatePicker + "Skip for now" link
- **D-15:** 8 AM pre-selected (matches `NotificationPreferences.defaultHour`)
- **D-16:** Daily notification body: rotating inspirational message (day-of-year seeded) + user's top active goal title on line 2
- **D-17:** Message array in `NotificationScheduler.swift` or new `NotificationCopy.swift`; rotation: `Calendar.current.ordinality(of: .day, in: .year, for: Date()) % messages.count`

### Claude's Discretion
- Exact chip pre-selection for NOTIF-01 (8 AM per D-15)
- Visual layout of AboutView (header photo, bio text styling — VGTheme clay/sand, Cormorant Garamond headings)
- TipJarView tier card layout (emoji size, card border/shadow — VGTheme surface/card patterns)
- Exact inspirational message copy array (short, warm, on-brand)
- StepBarView `total:` when NOTIF-01 shown: use `total: 8` on the new nudge-time step (existing screens use `total: 7`; nudge step is step 7 of 8)

### Deferred Ideas (OUT OF SCOPE)
- "Watch an ad" monetization — violates no-third-party-dependency policy
- Block reversal from Settings (Phase 17 D-15 blocks) — future phase
- Supporter tier perks / feature gates behind tips
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MON-01 | About page: app name, version, founder bio (scrollable) | Bundle.main.infoDictionary pattern verified; VGTheme layout patterns apply |
| MON-02 | Tip jar: 3 consumable IAP tiers with StoreKit 2 displayPrice | StoreKit 2 Product.products(for:) + product.displayPrice verified via official docs |
| MON-03 | Consumable IAPs only — no external payment links | App Store Guideline 3.1.1; confirmed no external URL pattern needed |
| MON-04 | Post-purchase animated thank-you, no feature gates | .fullScreenCover pattern from MilestoneCelebrationView; TimelineView Canvas confetti reusable |
| SET-01 | Settings accessible from Profile tab | Already wired via NavigationLink at ProfileView line 471; no change needed |
| SET-02 | Settings shows/edits daily nudge time | Existing DatePicker + NotificationPreferences.save() pattern already in SettingsView |
| SET-03 | Settings shows public/private profile toggle | ProfileViewModel.toggleProfilePublic() exists; wire Toggle to it via @Query UserProfile |
| SET-04 | Settings shows dark mode selector System/Light/Dark | @AppStorage + ColorSchemePreference enum + .preferredColorScheme() on WindowGroup |
| SET-05 | Settings includes Contact Support link | mailto: openURL pattern; email VitaminG.info@gmail.com confirmed in CONTEXT.md |
| NOTIF-01 | Nudge-time picker in onboarding after notification permission | New OnboardingStep.nudgeTimePicker case; conditional push from NotificationOnboardingScreen |
| NOTIF-02 | Notification time picker accessible from Settings | Existing DatePicker in SettingsView already handles this (labeled "Daily Reminder") |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| StoreKit 2 IAP product fetch + purchase | ViewModel (TipStore) | View (TipJarView) | Async StoreKit calls belong in ViewModel/ObservableObject, not View body |
| Transaction.updates listener | App entry point (VitaminGApp.init) | — | Must persist for app lifetime; D-08 locks this placement |
| Color scheme preference | App root (VitaminGApp) | Settings UI (SettingsView) | .preferredColorScheme() must be on WindowGroup; @AppStorage propagates to Settings picker |
| Notification copy rotation | Service (NotificationScheduler) | — | D-17: message array lives in NotificationScheduler or NotificationCopy.swift |
| Conditional onboarding step routing | View (OnboardingView / NotificationOnboardingScreen) | — | Path navigation is View-level; permission check triggers the conditional push |
| Profile isPublic toggle | ViewModel (ProfileViewModel) | Settings UI (SettingsView) | toggleProfilePublic() already encapsulates CloudKit write logic; Settings just calls it |
| About page content + version display | View (AboutView) | — | Read-only display; no business logic needed |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| StoreKit (native) | iOS 17+ (StoreKit 2 API) | Consumable IAP fetch, purchase, transaction listening | Locked: no third-party wrappers (CLAUDE.md, D-09, STATE.md) |
| SwiftUI | iOS 17+ | All views — AboutView, TipJarView, NudgeTimePickerScreen | Project standard |
| @AppStorage | iOS 14+ | ColorSchemePreference persistence (vg_colorScheme key) | Established vg_ prefix pattern in codebase |
| UserNotifications | iOS 10+ | NotificationScheduler extension for rotating copy | Existing service |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| TimelineView + Canvas | iOS 15+ | Confetti animation in post-purchase celebration | Reuse MilestoneCelebrationView pattern exactly |
| openURL Environment | iOS 14+ | mailto: Contact Support link | Avoid UIKit/MFMailComposeViewController dependency |
| Bundle.main | iOS — | App version display on About page | Standard; no extra dependency |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native StoreKit 2 | RevenueCat | Locked out by no-third-party policy; StoreKit 2 covers all requirements natively |
| openURL (mailto:) | MFMailComposeViewController | MFMailComposeViewController requires UIKit bridge; openURL simpler, sufficient |
| Canvas confetti | SpriteKit / third-party | Pattern already established in MilestoneCelebrationView — reuse exactly |

**Installation:** No new packages. All dependencies are native Apple frameworks. A `.storekit` configuration file must be created for Xcode sandbox testing (zero external packages).

---

## Package Legitimacy Audit

No external packages are installed in this phase. All capabilities use native Apple frameworks: `import StoreKit`, `import SwiftUI`, `import UserNotifications`. No npm/PyPI/crates packages applicable.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
User taps "About Vitamin G" in SettingsView
           |
           v
    AboutView (NavigationLink push)
    +---------------------------+
    | App name, version, bio    |
    | Scrollable content        |
    |                           |
    | [Floating sticky footer]  |
    |  "Tip the Developer" btn  |
    +---------------------------+
           |  (NavigationLink push)
           v
    TipJarView
    +---------------------------+
    | TipStore @Observable VM   |
    | .task { fetch products }  |
    |                           |
    | [Small Coffee  $0.99]     |  <-- product.displayPrice from App Store
    | [Large Coffee  $2.99]     |
    | [Supporter     $4.99]     |
    +---------------------------+
    User taps tier
           |
    product.purchase() -> VerificationResult
           |
    .verified(transaction) -> transaction.finish()
           |
    @State showThankYou = true
           v
    ThankYouView (.fullScreenCover)
    +---------------------------+
    | "Thank you! You're the   |
    |  best."                   |
    | Canvas confetti           |
    | [Done] button             |
    +---------------------------+

Parallel at app launch (VitaminGApp.init):
    Task.detached { for await result in Transaction.updates { ... } }

Settings path (Profile → Settings):
    SettingsView (existing Form, extended)
    +-- Daily Reminder section (existing DatePicker)
    +-- Win Reminder section (existing DatePicker)
    +-- Appearance section (NEW: segmented Picker)
    +-- Privacy section (NEW: Toggle isPublic)
    +-- Support section (NEW: Contact Support + About row)

    Appearance picker change:
    @AppStorage("vg_colorScheme") -> VitaminGApp reads ->
    .preferredColorScheme(colorScheme) on WindowGroup

Onboarding conditional step (NOTIF-01):
    NotificationOnboardingScreen (Step 6)
    "Allow Notifications" tapped
           |
    granted = await requestAuthorization()
           |
    if granted: path.append(.nudgeTimePicker)
    else:       path.append(.cameraPermission)

    NudgeTimePickerScreen (Step 7, conditional)
    +-- 5 chips: 6–10 AM (8 AM pre-selected)
    +-- Custom DatePicker
    +-- "Skip for now" link
    |
    save via NotificationPreferences.save(hour:minute:)
    reschedule via NotificationScheduler.shared.reschedule(activeGoals:)
    path.append(.cameraPermission)
```

### Recommended Project Structure

```
VitaminG/
├── Services/
│   ├── NotificationScheduler.swift   (MODIFY — add rotating copy to makeContent)
│   ├── NotificationPreferences.swift  (no change)
│   └── TipStore.swift                 (NEW — @Observable ViewModel for StoreKit 2)
├── Views/
│   ├── SettingsView.swift             (MODIFY — add Appearance/Privacy/Support sections)
│   ├── AboutView.swift                (NEW)
│   ├── TipJarView.swift               (NEW)
│   ├── ThankYouView.swift             (NEW — post-purchase .fullScreenCover)
│   └── Onboarding/
│       ├── OnboardingView.swift       (MODIFY — add .nudgeTimePicker case)
│       ├── NotificationOnboardingScreen.swift (MODIFY — conditional step push)
│       └── NudgeTimePickerScreen.swift (NEW)
└── VitaminGApp.swift                  (MODIFY — add @AppStorage + .preferredColorScheme + Transaction.updates)
```

### Pattern 1: StoreKit 2 Consumable IAP ViewModel

**What:** An `@Observable` class that fetches products on appear and executes purchases.
**When to use:** TipJarView owns a `TipStore` instance via `@State private var store = TipStore()`.

```swift
// Source: Apple Developer Documentation + Superwall tutorial (verified pattern)
import StoreKit

// Product IDs must match App Store Connect exactly
enum TipProductID: String, CaseIterable {
    case smallCoffee  = "com.kyleharrington.VitaminG.tip.small"
    case largeCoffee  = "com.kyleharrington.VitaminG.tip.large"
    case supporter    = "com.kyleharrington.VitaminG.tip.supporter"
}

@Observable
final class TipStore {
    var products: [Product] = []
    var isLoading = false
    var purchaseError: String? = nil

    func fetchProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: Set(TipProductID.allCases.map(\.rawValue)))
            // Sort by price ascending (Small → Large → Supporter)
            products.sort { $0.price < $1.price }
        } catch {
            purchaseError = "Couldn't load tips: \(error.localizedDescription)"
        }
    }

    /// Returns (success: Bool, cancelled: Bool)
    func purchase(_ product: Product) async -> (success: Bool, cancelled: Bool) {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    return (true, false)
                case .unverified:
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
```

### Pattern 2: Transaction.updates Listener at VitaminGApp.init

**What:** Long-lived Task that processes transactions delivered outside normal purchase flow (restored purchases, interrupted transactions).
**When to use:** D-08 locks this to `VitaminGApp.init`. For consumables, just call `finish()` — no entitlement logic needed.

```swift
// Source: Apple Developer Documentation Transaction.updates
// Place in VitaminGApp.init() alongside existing NotificationDelegate setup
private var transactionUpdatesTask: Task<Void, Never>?

init() {
    // ... existing setup ...

    // D-08: Transaction.updates listener for IAP delivery (consumables: just finish)
    transactionUpdatesTask = Task.detached {
        for await result in Transaction.updates {
            switch result {
            case .verified(let transaction):
                // Consumables: no entitlement to grant — just finish to clear the queue
                await transaction.finish()
            case .unverified:
                // Signature invalid — do not deliver; silently discard
                break
            }
        }
    }
}
```

Note: `transactionUpdatesTask` must be stored as a property so the Task is not immediately cancelled when `init()` returns.

### Pattern 3: ColorSchemePreference Enum + WindowGroup

**What:** Persists user color scheme preference and applies it at the root without a restart.
**When to use:** SET-04. The @AppStorage key `"vg_colorScheme"` follows the project's `vg_` prefix convention.

```swift
// Source: Multiple verified SwiftUI dark mode tutorials + Apple .preferredColorScheme docs [ASSUMED for exact API]
enum ColorSchemePreference: String, CaseIterable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    /// Maps to SwiftUI ColorScheme? (nil = follow system)
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// In VitaminGApp.swift:
struct VitaminGApp: App {
    // Existing stored properties ...
    @AppStorage("vg_colorScheme") private var colorSchemePref: ColorSchemePreference = .system

    var body: some Scene {
        WindowGroup {
            Group { /* existing content */ }
                .modelContainer(container)
                .environment(router)
                .preferredColorScheme(colorSchemePref.colorScheme)  // SET-04
                // ... existing .task and .onOpenURL ...
        }
    }
}

// In SettingsView.swift, new Appearance section:
@AppStorage("vg_colorScheme") private var colorSchemePref: ColorSchemePreference = .system

Section("Appearance") {
    Picker("Appearance", selection: $colorSchemePref) {
        ForEach(ColorSchemePreference.allCases, id: \.self) { pref in
            Text(pref.displayName).tag(pref)
        }
    }
    .pickerStyle(.segmented)
}
```

Note: `@AppStorage` with a RawRepresentable (String rawValue) enum works natively in SwiftUI iOS 17+. [ASSUMED: no documented breaking changes to this API]

### Pattern 4: Floating Sticky Tip Footer on AboutView

**What:** Sticky footer that stays at the bottom of the screen while content scrolls.
**When to use:** D-02 specifies floating sticky footer on AboutView.

```swift
// Source: SwiftUI .safeAreaInset pattern (established in NotificationOnboardingScreen + CameraPermissionScreen)
ScrollView {
    VStack(alignment: .leading, spacing: 24) {
        // App name, version, bio content
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 100) // leave space so sticky footer doesn't cover last content
}
.background(VGTheme.sandLight.ignoresSafeArea())
.safeAreaInset(edge: .bottom) {
    NavigationLink(destination: TipJarView()) {
        Text("Tip the Developer ☕")
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(VGTheme.accentTerra)
            .foregroundStyle(VGTheme.warmWhite)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 12)
    .background(VGTheme.sandLight)
}
```

### Pattern 5: Conditional OnboardingStep Push

**What:** NotificationOnboardingScreen pushes `.nudgeTimePicker` if permission granted, else `.cameraPermission`.
**When to use:** D-13 is locked. Requires adding `nudgeTimePicker` to the `OnboardingStep` enum and adding a `navigationDestination` case in `OnboardingView`.

```swift
// In NotificationOnboardingScreen.swift (MODIFY existing):
private func allow() {
    Task {
        let granted = await NotificationScheduler.shared.requestAuthorization()
        if granted {
            path.append(.nudgeTimePicker)   // D-13: conditional step
        } else {
            path.append(.cameraPermission)
        }
    }
}

private func skip() {
    path.append(.cameraPermission)  // unchanged
}

// In OnboardingStep enum (OnboardingView.swift):
enum OnboardingStep: Hashable {
    // ... existing cases ...
    case nudgeTimePicker   // NEW (Phase 19 — D-13)
}

// In OnboardingView navigationDestination:
case .nudgeTimePicker:
    NudgeTimePickerScreen(path: $path, onSkip: finish)
```

### Pattern 6: Rotating Notification Copy

**What:** Daily notification body uses a hardcoded message array seeded by day-of-year, followed by top goal title.
**When to use:** D-16/D-17 update `makeContent(activeGoals:)` in NotificationScheduler.

```swift
// Source: VGQuoteBank.swift and HomeView.swift day-of-year rotation pattern (verified in codebase)
// In NotificationScheduler.makeContent(activeGoals:):

private static let inspirationalMessages: [String] = [
    "You got this! 💪",
    "Take your daily Vitamin G 💊",
    "Your goals are waiting ☀️",
    "One step closer today 🌱",
    "Make it happen 🔥",
    "Progress, not perfection 🌿",
    "Small steps, big results ⭐",
]

func makeContent(activeGoals: [Goal]) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.title = "Good morning"  // or "Vitamin G" — Claude's discretion

    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    let message = Self.inspirationalMessages[(dayOfYear - 1) % Self.inspirationalMessages.count]

    let topGoalTitle = activeGoals
        .filter { !$0.isCompleted }
        .first
        .flatMap { $0.title }
        .flatMap { $0.isEmpty ? nil : $0 }

    if let goalTitle = topGoalTitle {
        content.body = "\(message)\n\(goalTitle)"
    } else {
        content.body = message
    }

    content.sound = .default
    content.userInfo = ["deepLink": "goalList"]
    return content
}
```

### Pattern 7: Post-Purchase ThankYouView (.fullScreenCover)

**What:** Full-screen celebration after successful purchase, mirroring MilestoneCelebrationView.
**When to use:** D-06. TipJarView shows it via `@State private var showThankYou = false`.

```swift
// Source: MilestoneCelebrationView.swift pattern (verified in codebase)
struct ThankYouView: View {
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: Double = 0.3
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
            confettiView.ignoresSafeArea().accessibilityHidden(true)
            VStack(spacing: 24) {
                Spacer()
                Text("☕").font(.system(size: 64))
                    .scaleEffect(scale).opacity(opacity)
                Text("Thank you!\nYou're the best.")
                    .font(.title2.bold()).fontDesign(.rounded)
                    .foregroundStyle(.white).multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                Button("Done") { onDismiss() }
                    .font(.body.weight(.semibold)).fontDesign(.rounded)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(VGTheme.accentTerra).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24).padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1; opacity = 1
            }
        }
    }
    // confettiView: copy TimelineView(.animation) Canvas pattern from MilestoneCelebrationView exactly
}
```

### Anti-Patterns to Avoid

- **Calling `Transaction.updates` in TipJarView:** The listener must live at app init, not in a transient view. Views are destroyed; a Task in a View body is cancelled when the view disappears.
- **Force-unwrapping `product.displayPrice`:** `displayPrice` is a non-optional String in StoreKit 2 — no unwrapping needed, but the product array may be empty if fetch fails. Always show a fallback loading state.
- **Setting `@AppStorage("vg_colorScheme")` raw String manually:** Use the enum's `rawValue`; @AppStorage with RawRepresentable handles serialization automatically.
- **Adding `.preferredColorScheme()` to a child view:** Must be on the WindowGroup's root view to affect the entire app including system chrome.
- **Storing `Transaction.updates` Task in a local variable:** It will be immediately deallocated. Store as a `let` property on `VitaminGApp`.
- **Calling `product.purchase()` from within `Transaction.updates`:** The listener is read-only; purchases are initiated by user action only.
- **Inserting NudgeTimePickerScreen into the onboarding path unconditionally:** It must only appear if permission was granted — the conditional is in `allow()`, not in `OnboardingView`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Consumable IAP delivery | Custom server receipt validation | StoreKit 2 `VerificationResult.verified` | StoreKit 2 validates JWS signatures from Apple automatically; server validation adds backend infra for zero benefit on consumables |
| Price display | Parse price from product ID string | `product.displayPrice` | Locale-formatted currency string, handles all App Store storefronts |
| Confetti animation | SpriteKit / third-party particle system | TimelineView + Canvas (existing MilestoneCelebrationView pattern) | Already in codebase, no new dependency |
| Dark mode toggle implementation | Custom `@Environment` injection | `.preferredColorScheme()` on WindowGroup | SwiftUI's built-in modifier handles system chrome, sheets, alerts correctly |
| Email support action | MFMailComposeViewController | `openURL(URL(string: "mailto:...")!)` | UIKit dependency avoided; simpler; matches D-12 |
| Color scheme persistence | Custom UserDefaults wrapper | `@AppStorage` with RawRepresentable enum | Zero-boilerplate, reactive, invalidates views automatically |

**Key insight:** StoreKit 2 eliminates the need for server-side receipt validation on consumables. The framework verifies JWS signatures from Apple's servers automatically — calling `verificationResult.payloadValue` (or switching on `.verified`) is the only check needed. Consumables don't have entitlements to restore, so `Transaction.currentEntitlements` is irrelevant for tips.

---

## Common Pitfalls

### Pitfall 1: Product IDs Don't Match App Store Connect
**What goes wrong:** `Product.products(for:)` returns an empty array, TipJarView shows no products.
**Why it happens:** The product identifiers hardcoded in `TipProductID` must exactly match what's configured in App Store Connect. If App Store Connect products aren't set up yet (noted as a pending todo in STATE.md), sandbox testing requires a local `.storekit` configuration file.
**How to avoid:** Create `VitaminGTips.storekit` configuration file in Xcode with the three product IDs and prices. Set it as the StoreKit configuration in the active scheme's Run options. This allows Simulator testing before App Store Connect setup.
**Warning signs:** Empty `products` array after `fetchProducts()` completes without throwing.

### Pitfall 2: Transaction.updates Task Cancellation
**What goes wrong:** Transactions from the queue are not processed after the first IAP because the Task listening to `Transaction.updates` was cancelled.
**Why it happens:** If the Task is stored in a local variable inside a function, it is cancelled when that function returns. In SwiftUI Views, Tasks are cancelled when the view disappears.
**How to avoid:** Store as `private let transactionUpdatesTask: Task<Void, Never>` on `VitaminGApp` (a struct that persists for the app lifetime). D-08 already mandates this placement.
**Warning signs:** Purchases appear to succeed in sandbox but the thank-you screen doesn't always show on second purchase.

### Pitfall 3: .preferredColorScheme on Wrong View
**What goes wrong:** Dark mode toggle changes the app content area but system sheets, alerts, and the tab bar ignore the preference.
**Why it happens:** `.preferredColorScheme()` only affects the nearest enclosing presentation. Applied to a child view, it doesn't propagate to system chrome.
**How to avoid:** Apply exclusively to the WindowGroup's direct content view (the `Group { ... }` in `VitaminGApp.body`), not to `ContentView` or any subview.
**Warning signs:** Settings and app body change appearance but tab bar or presented sheets remain in system mode.

### Pitfall 4: @AppStorage Enum Serialization
**What goes wrong:** App crashes on launch with a "Could not decode" error, or color scheme resets to system on every launch.
**Why it happens:** `@AppStorage` requires the enum to conform to `RawRepresentable` with `RawValue == String`. If the raw values contain any mismatch with stored UserDefaults data, decoding fails silently (reverts to default).
**How to avoid:** Use stable lowercase string raw values (`"system"`, `"light"`, `"dark"`). Never change raw values after shipping. Test by toggling in Settings and relaunching.
**Warning signs:** Selected appearance resets to System after app relaunch despite user setting.

### Pitfall 5: Missing `.nudgeTimePicker` navigationDestination Causes Crash
**What goes wrong:** App crashes at runtime with "NavigationStack: Missing destination for OnboardingStep.nudgeTimePicker".
**Why it happens:** OnboardingView's `navigationDestination(for:)` switch must handle every case of the `OnboardingStep` enum. Swift switches on non-exhaustive enums without `@unknown default` will warn at compile time — but if the destination is an `EmptyView()` stub and the enum case is not added at all, the NavigationStack cannot resolve the destination.
**How to avoid:** Add the `.nudgeTimePicker` case to both the enum and the `navigationDestination` switch before pushing to it from `NotificationOnboardingScreen`.
**Warning signs:** Compile-time warning "Switch must be exhaustive" on the `OnboardingStep` switch.

### Pitfall 6: NotificationScheduler.makeContent Test Regression
**What goes wrong:** Existing `NotificationSchedulerTests` fail after modifying `makeContent(activeGoals:)`.
**Why it happens:** Current tests assert `content.title == "Your Vitamin G for today"` and check that `content.body` contains joined goal titles. D-16 changes both the title (possibly) and the body format.
**How to avoid:** Update tests in `NotificationSchedulerTests.swift` to reflect the new body format (message + newline + top goal title, or message alone when no active goals). Add tests for the day-of-year rotation formula.
**Warning signs:** `xcodebuild test` failures in `NotificationSchedulerTests` after modifying `makeContent`.

### Pitfall 7: Public Profile Toggle Requires ProfileViewModel Access
**What goes wrong:** SET-03 toggle in SettingsView has no way to call `toggleProfilePublic(context:)` because SettingsView doesn't have a ProfileViewModel or access to the UserProfile SwiftData model.
**Why it happens:** SettingsView currently only uses `@Query` for Goals and CompletionEvents. UserProfile is not in scope.
**How to avoid:** Add `@Query private var profiles: [UserProfile]` (using the current schema's UserProfile type) and `@Environment(\.modelContext) private var modelContext` to SettingsView. Then create a local ProfileViewModel instance or call the toggle logic inline. The simplest approach given existing patterns: instantiate a `ProfileViewModel` as `@State private var profileVM = ProfileViewModel()` and call `profileVM.loadOrCreateProfile(context:)` in `.onAppear`, then expose the Toggle binding to `profile.isPublic`.
**Warning signs:** Compiler error "cannot find 'profile' in scope" when adding the Toggle in SettingsView.

---

## Code Examples

### App Version Display (AboutView)

```swift
// Source: Established Bundle.main pattern (verified in TermsAndConditionsScreen.swift, RecoveryScreen.swift)
private var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    return "Version \(version) (\(build))"
}
```

### StepBarView for NudgeTimePickerScreen

```swift
// Source: NameScreen.swift pattern (verified in codebase)
// NudgeTimePickerScreen is step 7 of 8 when shown (0-indexed: current=6, total=8)
StepBarView(current: 6, total: 8)
// When NOTIF-01 step is skipped, CameraPermissionScreen continues at current=5, total=7 (no change)
```

### mailto: Contact Support

```swift
// Source: SwiftUI openURL + D-12 specification
@Environment(\.openURL) private var openURL

Button("Contact Support") {
    if let url = URL(string: "mailto:VitaminG.info@gmail.com?subject=Vitamin%20G%20Support") {
        openURL(url)
    }
}
```

### Time Chip Selection Pattern (NudgeTimePickerScreen)

```swift
// Source: Established chip pattern from Explore phase + D-14/D-15 specification
let quickSelectHours = [6, 7, 8, 9, 10]
@State private var selectedHour: Int = NotificationPreferences.defaultHour  // 8 per D-15

// Chips:
HStack(spacing: 8) {
    ForEach(quickSelectHours, id: \.self) { hour in
        let label = hour <= 11 ? "\(hour) AM" : "\(hour - 12) PM"
        Button(label) { selectedHour = hour }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(selectedHour == hour ? VGTheme.accentTerra : VGTheme.surface)
            .foregroundStyle(selectedHour == hour ? VGTheme.warmWhite : VGTheme.textPrimary)
            .clipShape(Capsule())
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| StoreKit 1 (SKPaymentQueue, completion handlers) | StoreKit 2 (async/await, automatic JWS verification) | iOS 15 (StoreKit 2 introduced); fully stable iOS 17+ | No server-side validation needed; `Transaction.updates` replaces `paymentQueue(_:updatedTransactions:)` |
| `ObservableObject` + `@Published` for IAP store | `@Observable` macro | iOS 17 | Project already uses @Observable; TipStore must use the same pattern |
| `UIApplication.keyWindow.overrideUserInterfaceStyle` | `.preferredColorScheme()` on WindowGroup | iOS 13+ SwiftUI | No UIKit access needed; reactive to @AppStorage changes |

**Deprecated/outdated:**
- `SKPaymentQueue` / `SKProduct`: Replaced by StoreKit 2 — do not use in Phase 19
- `paymentQueue(_:updatedTransactions:)` delegate: Replaced by `Transaction.updates` async sequence
- `UIApplication.keyWindow`: Deprecated; `.preferredColorScheme()` is the SwiftUI-native approach

---

## Runtime State Inventory

This phase does not rename or migrate any existing state. However, the notification copy change (D-16) affects all users who already have `dailyReminder` scheduled:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | UserDefaults `notificationHour`, `notificationMinute` (existing) | No change — keys preserved |
| Stored data | UserDefaults `vg_colorScheme` (new key) | No migration — new key with default `.system`; missing key = system |
| Live service config | Active `com.kyleharrington.VitaminG.dailyReminder` notification scheduled via UNCalendarNotificationTrigger | Code edit: `makeContent` update changes body text; `reschedule()` must be called once at Settings appear or app launch to propagate new copy to existing scheduled notification |
| OS-registered state | None — no Task Scheduler / launchd / systemd items | None |
| Secrets/env vars | App Store Connect IAP product IDs (3 new products must be created) | Pending todo noted in STATE.md; developer action required before real-device testing |
| Build artifacts | No egg-info, no installed packages | None |

**Key observation:** Existing users with the old notification copy will see the new rotating message format only after `reschedule(activeGoals:)` is called. SettingsView already calls `reschedule()` on `onAppear` (line 139–145 in SettingsView.swift). This means the notification copy updates the next time the user opens Settings. For users who never open Settings, the old copy persists until the next app launch triggers the startup reschedule path. The startup path currently only reschedules the Win Reminder, not the Daily Reminder — so a dedicated `reschedule()` call on app launch may be warranted (planner decision).

---

## Open Questions

1. **Founder bio text location**
   - What we know: D-03 says "exact text must be preserved verbatim as provided in the codebase or a resource file"
   - What's unclear: The bio text was not found in any existing Swift file or resource during research. It may need to be provided by the user for AboutView content.
   - Recommendation: Planner should include a Wave 0 task to confirm whether the bio text exists in the codebase (grep for unique phrases) or must be obtained from the developer. A `AboutContent.swift` constants file is the right location.

2. **App Store Connect IAP Product ID naming convention**
   - What we know: STATE.md notes "configure 3 consumable IAP products" as a pending todo. No product IDs are established in the codebase.
   - What's unclear: The exact bundle identifier prefix to use (`com.kyleharrington.VitaminG.tip.small` is proposed here but not confirmed).
   - Recommendation: Planner should define product IDs in the `TipProductID` enum with a clear note that the developer must create matching products in App Store Connect before real-device/TestFlight testing.

3. **Daily notification reschedule on app launch**
   - What we know: SettingsView reschedules on appear. VitaminGApp.init only reschedules the win reminder (not daily reminder).
   - What's unclear: Should D-16 notification copy be rescheduled on every app launch (to ensure all users get the new copy promptly) or only when Settings is visited?
   - Recommendation: Add a `reschedule(activeGoals:)` call to the VitaminGApp `.task` block alongside the existing win reminder reschedule, guarded by `isAuthorized`. This is the minimal-risk approach.

4. **StepBarView `total:` for NudgeTimePickerScreen**
   - What we know: Existing screens use `StepBarView(current:X, total:7)`. With NOTIF-01 inserted, the total becomes 8 when shown.
   - What's unclear: CameraPermissionScreen and CommunityGoalOnboardingScreen currently have no StepBarView at all (not observed in code). The visual mismatch may not matter.
   - Recommendation: NudgeTimePickerScreen uses `StepBarView(current: 6, total: 8)`. Existing screens' `total: 7` values need not change since they are shown before the conditional step branches.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode (StoreKit config file) | Sandbox testing TipJarView | ✓ | Xcode detected | — |
| iOS Simulator | Build/test | ✓ | iOS 17+ simulators available | — |
| App Store Connect IAP products | Real-device + TestFlight testing | ✗ | Not configured (STATE.md pending todo) | Local .storekit file for Simulator |
| xcodebuild | CI test runs | ✓ | Available at /Applications/Xcode.app | — |

**Missing dependencies with no fallback:**
- App Store Connect IAP products — required for real-device sandbox testing; Simulator can use local `.storekit` config as fallback for development.

**Missing dependencies with fallback:**
- App Store Connect IAP products — use local `VitaminGTips.storekit` configuration file in Xcode scheme for all Simulator testing. Real-device testing blocked until developer creates products in App Store Connect.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (existing VitaminGTests target) |
| Config file | VitaminG.xcodeproj (no separate config file) |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing VitaminGTests/NotificationSchedulerTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -30` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MON-01 | About page displays version string from Bundle | unit | `xcodebuild test ... -only-testing VitaminGTests/AboutViewTests` | ❌ Wave 0 |
| MON-02 | TipStore.fetchProducts() populates products array | unit | `xcodebuild test ... -only-testing VitaminGTests/TipStoreTests` | ❌ Wave 0 |
| MON-03 | No external payment URLs in TipJarView | manual | Code review — grep for "http" in TipJarView.swift | — |
| MON-04 | Post-purchase ThankYouView shown on purchase success | unit | `xcodebuild test ... -only-testing VitaminGTests/TipStoreTests` | ❌ Wave 0 |
| SET-03 | isPublic Toggle wires to ProfileViewModel.toggleProfilePublic | unit | `xcodebuild test ... -only-testing VitaminGTests/SettingsViewTests` | ❌ Wave 0 |
| SET-04 | ColorSchemePreference enum maps to correct ColorScheme? | unit | `xcodebuild test ... -only-testing VitaminGTests/ColorSchemePreferenceTests` | ❌ Wave 0 |
| NOTIF-01 | NudgeTimePickerScreen saves correct hour via NotificationPreferences | unit | `xcodebuild test ... -only-testing VitaminGTests/NudgeTimePickerTests` | ❌ Wave 0 |
| NOTIF-02 | Notification rotating copy: day-of-year selection correct | unit | Update `xcodebuild test ... -only-testing VitaminGTests/NotificationSchedulerTests` | ✅ (needs update) |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing VitaminGTests/NotificationSchedulerTests 2>&1 | tail -20`
- **Per wave merge:** `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `VitaminGTests/TipStoreTests.swift` — covers MON-02, MON-04 (mock StoreKit with local config)
- [ ] `VitaminGTests/ColorSchemePreferenceTests.swift` — covers SET-04 (pure unit test on enum)
- [ ] `VitaminGTests/NudgeTimePickerTests.swift` — covers NOTIF-01 (NotificationPreferences.save integration)
- [ ] `VitaminGTests/NotificationSchedulerTests.swift` — UPDATE existing tests to match new makeContent format (NOTIF-02)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | StoreKit handles App Store auth; no user credential exchange |
| V3 Session Management | no | No session state introduced |
| V4 Access Control | no | No gating behind tips (D-07, MON-04) |
| V5 Input Validation | yes | Notification copy messages are hardcoded — no user input path. `makeContent` clamps hour/minute (existing T-03-08). Email subject in mailto: URL must be percent-encoded (already specified in D-12). |
| V6 Cryptography | no | StoreKit 2 handles JWS verification internally — do not hand-roll |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unverified IAP transaction delivery | Tampering | Switch on `.verified` case only; discard `.unverified`; call `finish()` after verified |
| External payment links bypassing App Store | Information disclosure / policy violation | D-09 locked: no external URLs; App Store Guideline 3.1.1 |
| Malformed `mailto:` URL causing crash | Denial of Service | Guard with `URL(string:)` optional binding before calling `openURL` |
| Storing `vg_colorScheme` key mismatch across versions | Tampering | Use stable lowercase raw values; enum has default fallback |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `@AppStorage` with `RawRepresentable` (String rawValue) enum works on iOS 17+ without additional conformance | Standard Stack, Pattern 3 | ColorSchemePreference picker fails to persist; workaround: store raw String and convert manually |
| A2 | `VitaminGApp` struct persists for the full app lifetime so a `let transactionUpdatesTask` stored property is sufficient | Pattern 2 | Transaction updates listener deallocated; consumable purchases not processed; fix: wrap in an `@Observable` singleton |
| A3 | The founder bio text does not currently exist as a resource file in the codebase | Open Questions | If it does exist, Wave 0 gap for obtaining text is moot |
| A4 | App Store Connect product ID naming convention `com.kyleharrington.VitaminG.tip.*` | Pattern 1 | IDs must match exactly between code and App Store Connect; mismatch = empty product list |
| A5 | `StepBarView(current: 6, total: 8)` is the correct step index for NudgeTimePickerScreen | Patterns | StepBar shows wrong progress dot; cosmetic only |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed. (Table is not empty — A1–A5 need monitoring but are low-risk.)

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation — `Transaction` (StoreKit 2): https://developer.apple.com/documentation/storekit/transaction
- Apple Developer Documentation — `Product` (StoreKit 2): https://developer.apple.com/documentation/storekit/product
- Codebase: `MilestoneCelebrationView.swift` — `.fullScreenCover` + Canvas confetti pattern (verified)
- Codebase: `VGQuoteBank.swift` + `HomeView.swift` — `Calendar.current.ordinality(of: .day, in: .year, for: Date())` rotation pattern (verified)
- Codebase: `NotificationScheduler.swift` — existing `makeContent(activeGoals:)` pattern (verified)
- Codebase: `NotificationPreferences.swift` — `save(hour:minute:)` dual UserDefaults write (verified)
- Codebase: `OnboardingView.swift` + `NotificationOnboardingScreen.swift` — step routing and path.append pattern (verified)
- Codebase: `SettingsView.swift` — existing Form structure, authorization flow, DatePicker pattern (verified)
- Codebase: `ProfileViewModel.swift` — `toggleProfilePublic(context:)` existing business logic (verified)
- Codebase: `VGTheme.swift` — full color token set and `VGTheme.serif()` typography helper (verified)

### Secondary (MEDIUM confidence)
- Superwall tutorial: StoreKit 2 consumable IAP ViewModel pattern with `Product.products(for:)`, `product.purchase()`, `VerificationResult` switch — https://superwall.com/blog/make-a-swiftui-app-with-in-app-purchases-and-subscriptions-using-storekit-2/
- Nayana N P (Medium): SwiftUI `@AppStorage` + enum + `.preferredColorScheme()` on WindowGroup — https://medium.com/@nayananp/swiftui-toggle-between-dark-light-system-across-whole-app-e29c7d9d25b3

### Tertiary (LOW confidence)
- (None — all key claims verified against official docs or codebase)

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — native Apple frameworks only; no third-party packages
- Architecture: HIGH — all patterns traced to verified codebase files
- StoreKit 2 API: MEDIUM — core APIs verified via official docs; VerificationResult enum pattern confirmed via multiple tutorials cross-checked
- Pitfalls: HIGH — drawn from codebase structure and known StoreKit 2 gotchas
- Notification copy: HIGH — day-of-year formula verified identically in VGQuoteBank.swift and HomeView.swift

**Research date:** 2026-05-21
**Valid until:** 2026-06-20 (stable Apple frameworks; StoreKit 2 API has been stable since iOS 15)
