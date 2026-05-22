# Phase 19: Tip Jar + About Page + Settings - Pattern Map

**Mapped:** 2026-05-21
**Files analyzed:** 9 (5 new, 4 modified)
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Views/AboutView.swift` | view | request-response (read-only display) | `Views/Support/AboutUsView.swift` | exact |
| `Views/TipJarView.swift` | view | request-response (async StoreKit fetch) | `Views/GoalListView.swift` (fullScreenCover trigger) + `Views/ChallengeDetailView.swift` | role-match |
| `Views/TipThankYouView.swift` | view | event-driven (post-purchase) | `Views/MilestoneCelebrationView.swift` | exact |
| `Services/TipStore.swift` | service/viewmodel | request-response (async StoreKit 2) | `ViewModels/DailyWinsViewModel.swift` + `@Observable` pattern from any VM | role-match |
| `Views/Onboarding/NudgeTimePickerScreen.swift` | view | request-response | `Views/Onboarding/CameraPermissionScreen.swift` | exact |
| `Views/SettingsView.swift` (MODIFY) | view | CRUD | self — `Views/SettingsView.swift` | self |
| `VitaminGApp.swift` (MODIFY) | config/entry-point | event-driven | self — `VitaminGApp.swift` | self |
| `Services/NotificationScheduler.swift` (MODIFY) | service | batch | self — `Services/NotificationScheduler.swift` | self |
| `Views/Onboarding/OnboardingView.swift` + `NotificationOnboardingScreen.swift` (MODIFY) | view/routing | event-driven | self + `CameraPermissionScreen.swift` | self + exact |

---

## Pattern Assignments

### `Views/AboutView.swift` (view, request-response)

**Analog:** `Views/Support/AboutUsView.swift`

**Imports pattern** (lines 1–2 of AboutUsView):
```swift
import SwiftUI
```

**Core layout pattern** (lines 4–61 of AboutUsView) — header gradient + scrollable content sections:
```swift
struct AboutUsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Terra gradient header
                ZStack {
                    LinearGradient(
                        colors: [VGTheme.terra, VGTheme.terraSoft],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 200)
                    VStack(spacing: 12) {
                        Text("About Vitamin G")
                            .font(VGTheme.serif(28, weight: .semibold))
                            .foregroundStyle(VGTheme.sand)
                    }
                }
                // Content area
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("OUR STORY")
                            .font(.system(size: 10, weight: .semibold))
                            .kerning(1.2)
                            .foregroundStyle(VGTheme.muted)
                        Text("...")
                            .font(.system(size: 15))
                            .fontDesign(.rounded)
                            .foregroundStyle(VGTheme.textPrimary)
                            .lineSpacing(5)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(VGTheme.background)
        .navigationTitle("About Us")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

**Sticky footer / NavigationLink tip button pattern** (RESEARCH.md Pattern 4 — `.safeAreaInset` from NotificationOnboardingScreen lines 95–118):
```swift
// AboutView: sticky tip CTA via .safeAreaInset — same pattern as NotificationOnboardingScreen
ScrollView {
    VStack(alignment: .leading, spacing: 24) { /* bio content */ }
    .padding(.horizontal, 24)
    .padding(.bottom, 100) // breathing room so sticky footer never occludes last content line
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

**App version display** (established in TermsAndConditionsScreen — from RESEARCH.md Code Examples):
```swift
private var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    return "Version \(version) (\(build))"
}
```

**Section heading style** (lines 27–31 of AboutUsView):
```swift
Text("OUR STORY")
    .font(.system(size: 10, weight: .semibold))
    .kerning(1.2)
    .foregroundStyle(VGTheme.muted)
```

---

### `Views/TipJarView.swift` (view, request-response)

**Analog:** `Views/ChallengeDetailView.swift` for `.fullScreenCover` trigger; `Views/MilestoneCelebrationView.swift` for the cover itself.

**Imports pattern:**
```swift
import SwiftUI
import StoreKit
```

**Core state pattern** — `@State` ViewModel + `.task` fetch + `.fullScreenCover`:
```swift
struct TipJarView: View {
    @State private var store = TipStore()
    @State private var showThankYou = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // heading
                ForEach(store.products) { product in
                    TipTierCard(product: product) {
                        Task {
                            let (success, _) = await store.purchase(product)
                            if success { showThankYou = true }
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(VGTheme.sandLight.ignoresSafeArea())
        .task { await store.fetchProducts() }
        .fullScreenCover(isPresented: $showThankYou) {
            TipThankYouView { showThankYou = false }
        }
    }
}
```

**Tier card surface pattern** (from CONTEXT.md code_context and VGTheme):
```swift
// Each tier card — mirrors VGTheme.surface card style used in ChallengeDetailView
VStack(alignment: .leading, spacing: 8) {
    HStack {
        Text(/* emoji */).font(.system(size: 32))
        VStack(alignment: .leading) {
            Text(product.displayName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(VGTheme.textPrimary)
            Text(product.displayPrice)
                .font(.system(size: 15))
                .foregroundStyle(VGTheme.muted)
        }
        Spacer()
        Button("Tip") { onTap() }
            .font(.system(size: 15, weight: .semibold))
            .padding(.horizontal, 18).padding(.vertical, 10)
            .background(VGTheme.accentTerra)
            .foregroundStyle(VGTheme.warmWhite)
            .clipShape(Capsule())
    }
}
.padding(16)
.background(VGTheme.surface)
.clipShape(RoundedRectangle(cornerRadius: 12))
```

---

### `Views/TipThankYouView.swift` (view, event-driven)

**Analog:** `Views/MilestoneCelebrationView.swift` — exact structural copy.

**Full pattern** (lines 16–166 of MilestoneCelebrationView.swift):
```swift
// Copy this structure exactly from MilestoneCelebrationView.swift
struct TipThankYouView: View {
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: Double = 0.3
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()          // line 57 pattern
            confettiView.ignoresSafeArea().accessibilityHidden(true)  // line 59–61 pattern
            VStack(spacing: 24) {
                Spacer()
                Text("☕")
                    .font(.system(size: 64))
                    .scaleEffect(scale).opacity(opacity)
                Text("Thank you!\nYou're the best.")
                    .font(.title2.weight(.semibold)).fontDesign(.rounded)
                    .foregroundStyle(.white).multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                Button("Done") { onDismiss() }           // line 90–99 dismiss button pattern
                    .font(.body.weight(.semibold)).fontDesign(.rounded)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(VGTheme.accentTerra)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24).padding(.bottom, 48)
            }
        }
        .onAppear {                                              // line 102–118 animation pattern
            if reduceMotion {
                scale = 1.0; opacity = 1.0
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    scale = 1.0; opacity = 1.0
                }
            }
        }
    }

    // confettiView: copy TimelineView(.animation) Canvas block verbatim from
    // MilestoneCelebrationView.swift lines 123–141
    private var confettiView: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let count = 60
                for i in 0..<count {
                    let seed = Double(i) * 137.5
                    let x = (sin(seed + now * 0.8 + Double(i)) * 0.5 + 0.5) * size.width
                    let rawY = (now * 80.0 + seed * 3.7).truncatingRemainder(dividingBy: size.height)
                    let y = rawY < 0 ? rawY + size.height : rawY
                    let hue = (seed / 360.0).truncatingRemainder(dividingBy: 1.0)
                    let color = Color(hue: hue, saturation: 0.8, brightness: 0.9)
                    let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}
```

---

### `Services/TipStore.swift` (service/viewmodel, request-response)

**Analog:** `ViewModels/ProfileViewModel.swift` for `@Observable @MainActor final class` pattern; `Services/NotificationScheduler.swift` for async service shape; RESEARCH.md Pattern 1 for StoreKit 2 specifics.

**Imports + class declaration** (mirrors ProfileViewModel.swift lines 1–14):
```swift
import Observation
import StoreKit

@MainActor
@Observable
final class TipStore {
    var products: [Product] = []
    var isLoading = false
    var purchaseError: String? = nil
}
```

**fetchProducts pattern** (RESEARCH.md Pattern 1):
```swift
enum TipProductID: String, CaseIterable {
    case smallCoffee = "com.kyleharrington.VitaminG.tip.small"
    case largeCoffee = "com.kyleharrington.VitaminG.tip.large"
    case supporter   = "com.kyleharrington.VitaminG.tip.supporter"
}

func fetchProducts() async {
    isLoading = true
    defer { isLoading = false }
    do {
        products = try await Product.products(
            for: Set(TipProductID.allCases.map(\.rawValue))
        )
        products.sort { $0.price < $1.price }
    } catch {
        purchaseError = "Couldn't load tips: \(error.localizedDescription)"
    }
}
```

**purchase pattern** (RESEARCH.md Pattern 1 — verified via Apple docs):
```swift
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
```

---

### `Views/Onboarding/NudgeTimePickerScreen.swift` (view, request-response)

**Analog:** `Views/Onboarding/CameraPermissionScreen.swift` — exact structural clone; same clay dark background, `.safeAreaInset` CTA tray, `@Binding var path`, `let onSkip` signature.

**Imports + signature** (mirrors CameraPermissionScreen.swift lines 1–16):
```swift
import SwiftUI

struct NudgeTimePickerScreen: View {
    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void
    // NudgeTimePickerScreen uses sandLight background (light screen), not clay dark
    // — mirrors NameScreen.swift pattern (light onboarding steps)
}
```

**StepBarView usage** (NameScreen.swift line 41 + RESEARCH.md Code Examples):
```swift
// NudgeTimePickerScreen is conditional step 7 of 8 when shown
StepBarView(current: 6, total: 8)
    .padding(.bottom, 28)
```

**Time chip pattern** (RESEARCH.md Code Examples — chip selection):
```swift
let quickSelectHours = [6, 7, 8, 9, 10]
@State private var selectedHour: Int = NotificationPreferences.defaultHour  // 8 per D-15

HStack(spacing: 8) {
    ForEach(quickSelectHours, id: \.self) { hour in
        let label = "\(hour) AM"
        Button(label) { selectedHour = hour }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(selectedHour == hour ? VGTheme.accentTerra : VGTheme.surface)
            .foregroundStyle(selectedHour == hour ? VGTheme.warmWhite : VGTheme.textPrimary)
            .clipShape(Capsule())
    }
}
```

**Save + advance pattern** (mirrors SettingsView.swift lines 89–99 for NotificationPreferences.save):
```swift
private func save() {
    NotificationPreferences.save(hour: selectedHour, minute: 0)
    Task {
        await NotificationScheduler.shared.reschedule(activeGoals: [])
        // Note: reschedule without active goals is fine — notification body will update
        // on next SettingsView appear which re-fetches active goals
    }
    path.append(.cameraPermission)
}

private func skip() {
    path.append(.cameraPermission)  // mirrors CameraPermissionScreen.skip() pattern
}
```

**safeAreaInset CTA tray** (CameraPermissionScreen.swift lines 95–118 — copy verbatim, swap button labels):
```swift
.safeAreaInset(edge: .bottom) {
    VStack(spacing: 10) {
        Button(action: save) {
            Text("Set Reminder Time")
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(VGTheme.terra)
                .foregroundStyle(VGTheme.warmWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        Button(action: skip) {
            Text("Skip for now")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(VGTheme.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
    }
    .padding(.horizontal, 28)
    .padding(.bottom, 12)
}
.navigationBarHidden(true)
```

---

### `Views/SettingsView.swift` (MODIFY — extend Form)

**Analog:** Self — `Views/SettingsView.swift`. Add sections following exact Form section style at lines 82–135.

**Existing Form section style to copy** (lines 82–108):
```swift
Section("Daily Reminder") {
    DatePicker(
        "Reminder Time",
        selection: $notificationTime,
        displayedComponents: .hourAndMinute
    )
    .disabled(!isAuthorized)
    .onChange(of: notificationTime) { _, newValue in
        // ... persist + reschedule ...
    }
    authorizationRow
}

Section {
    Text("Your notification will include up to 3 of your active goal titles as a daily reminder.")
        .font(.footnote)
        .foregroundStyle(.secondary)
}
```

**New Appearance section** (D-10, D-11 — @AppStorage pattern from CONTEXT.md):
```swift
// Add at top of SettingsView (with existing @AppStorage("hasCompletedOnboarding")):
@AppStorage("vg_colorScheme") private var colorSchemePref: ColorSchemePreference = .system

// New section in Form body:
Section("Appearance") {
    Picker("Appearance", selection: $colorSchemePref) {
        ForEach(ColorSchemePreference.allCases, id: \.self) { pref in
            Text(pref.displayName).tag(pref)
        }
    }
    .pickerStyle(.segmented)
}
```

**New Privacy section** (D-10, SET-03 — @Query + ProfileViewModel pattern):
```swift
// Add to SettingsView — see RESEARCH.md Pitfall 7 for required @Query + @Environment setup:
@Query private var profiles: [UserProfile]
@Environment(\.modelContext) private var modelContext
@State private var profileVM = ProfileViewModel()

Section("Privacy") {
    if let profile = profileVM.profile {
        Toggle("Public Profile", isOn: Binding(
            get: { profile.isPublic ?? false },
            set: { newValue in
                profile.isPublic = newValue
                try? modelContext.save()
            }
        ))
    }
}
```

**New Support section** (D-10, D-12, D-01 — openURL pattern from SettingsView line 44):
```swift
// @Environment(\.openURL) already declared at line 44 of SettingsView — reuse it

Section("Support") {
    Button("Contact Support") {
        if let url = URL(string: "mailto:VitaminG.info@gmail.com?subject=Vitamin%20G%20Support") {
            openURL(url)
        }
    }
    .foregroundStyle(VGTheme.accentTerra)

    NavigationLink("About Vitamin G") {
        AboutView()
    }
}
```

---

### `VitaminGApp.swift` (MODIFY — add colorScheme + Transaction.updates)

**Analog:** Self — `VitaminGApp.swift`.

**Existing stored property pattern** (lines 8–13 of VitaminGApp.swift) — add alongside existing `let` properties:
```swift
// Add as stored property (not local var) — Task must persist for app lifetime
private let transactionUpdatesTask: Task<Void, Never>

// ColorSchemePreference — add alongside existing @AppStorage at line 48:
@AppStorage("vg_colorScheme") private var colorSchemePref: ColorSchemePreference = .system
```

**init() extension** (mirrors existing init() pattern at lines 14–46):
```swift
// At end of existing init(), after UNUserNotificationCenter.current().delegate = delegate:
transactionUpdatesTask = Task.detached {
    for await result in Transaction.updates {
        switch result {
        case .verified(let transaction):
            await transaction.finish()  // consumables: no entitlement to grant
        case .unverified:
            break
        }
    }
}
```

**WindowGroup modifier** (add to existing Group at lines 52–83, after `.environment(router)`):
```swift
.preferredColorScheme(colorSchemePref.colorScheme)
// IMPORTANT: must be on the Group{} directly inside WindowGroup, not on ContentView
```

**ColorSchemePreference enum** — new standalone type (add to VitaminGApp.swift or a new file):
```swift
enum ColorSchemePreference: String, CaseIterable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var displayName: String {
        switch self { case .system: "System"; case .light: "Light"; case .dark: "Dark" }
    }

    var colorScheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
}
```

---

### `Services/NotificationScheduler.swift` (MODIFY — rotating notification copy)

**Analog:** Self + `Services/VGQuoteBank.swift` for day-of-year rotation.

**Day-of-year rotation formula** (VGQuoteBank.swift lines 102–106 — exact pattern):
```swift
// VGQuoteBank.todaysQuote() — the formula to replicate in NotificationScheduler:
static func todaysQuote() -> VGQuote {
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    let index = (dayOfYear - 1) % all.count
    return all[index]
}
```

**New makeContent pattern** (replaces lines 26–46 of NotificationScheduler.swift):
```swift
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
    content.title = "Good morning"

    // Day-of-year seeded rotation — same message all day, changes daily (D-17)
    // Pattern sourced from VGQuoteBank.swift lines 102–106
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
    content.userInfo = ["deepLink": "goalList"]  // T-03-09: unchanged
    return content
}
```

---

### `Views/Onboarding/OnboardingView.swift` + `NotificationOnboardingScreen.swift` (MODIFY)

**Analog:** Self — both files already read.

**OnboardingStep enum extension** (OnboardingView.swift lines 6–18 — add one case):
```swift
enum OnboardingStep: Hashable {
    case name
    case login
    case recovery
    case termsAndConditions
    case username
    case profilePicture
    case notifications
    case nudgeTimePicker   // NEW (Phase 19 — D-13)
    case cameraPermission
    case communityGoal
}
```

**navigationDestination addition** (OnboardingView.swift lines 33–53 — add one case before `.cameraPermission`):
```swift
case .nudgeTimePicker:
    NudgeTimePickerScreen(path: $path, onSkip: finish)
```

**NotificationOnboardingScreen.allow() replacement** (lines 122–125 — conditional push):
```swift
// BEFORE (line 122–125):
private func allow() {
    Task { await NotificationScheduler.shared.requestAuthorization() }
    path.append(.communityGoal)
}

// AFTER (D-13):
private func allow() {
    Task {
        let granted = await NotificationScheduler.shared.requestAuthorization()
        if granted {
            path.append(.nudgeTimePicker)   // D-13: conditional step shown only if granted
        } else {
            path.append(.cameraPermission)
        }
    }
}

// skip() unchanged — always goes to .cameraPermission (line 127–129)
private func skip() {
    path.append(.cameraPermission)
}
```

---

## Shared Patterns

### VGTheme Tokens
**Source:** `VGTheme.swift` lines 1–139
**Apply to:** AboutView, TipJarView, TipThankYouView, NudgeTimePickerScreen

Key tokens used in Phase 19:
```swift
VGTheme.sandLight          // scroll view backgrounds (light screens)
VGTheme.accentTerra        // primary CTA buttons, selected chip state
VGTheme.warmWhite          // button foreground text on terra background
VGTheme.surface            // tip tier card backgrounds
VGTheme.textPrimary        // body text (adaptive light/dark)
VGTheme.muted              // secondary labels, section labels
VGTheme.terra              // header gradient start, onboarding dark screens
VGTheme.terraSoft          // header gradient end
```

### @AppStorage Key Convention
**Source:** OnboardingView.swift line 25, SettingsView implicit, CONTEXT.md code_context
**Apply to:** VitaminGApp.swift, SettingsView.swift
```swift
// All @AppStorage keys use vg_ prefix:
@AppStorage("vg_colorScheme") private var colorSchemePref: ColorSchemePreference = .system
@AppStorage("vg_onboardingName") private var storedName: String = ""
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
// Note: "hasCompletedOnboarding" predates the vg_ prefix convention — do not rename
```

### openURL Environment Pattern
**Source:** SettingsView.swift line 44
**Apply to:** SettingsView.swift (Contact Support), AboutView.swift if any mailto links needed
```swift
@Environment(\.openURL) private var openURL

// Usage (D-12):
if let url = URL(string: "mailto:VitaminG.info@gmail.com?subject=Vitamin%20G%20Support") {
    openURL(url)
}
```

### @Observable ViewModel Pattern
**Source:** `ViewModels/ProfileViewModel.swift` lines 1–14
**Apply to:** `Services/TipStore.swift`
```swift
import Observation
// ...
@MainActor
@Observable
final class TipStore { ... }
```

### Remove-Before-Add Notification Pattern
**Source:** `Services/NotificationScheduler.swift` lines 53–79
**Apply to:** NotificationScheduler.swift (makeContent modification only — scheduling pattern unchanged)
```swift
// Pattern is already established — do not change schedule() or reschedule() signatures
center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
// then: try await center.add(request)
```

### async/await Task in View Pattern
**Source:** SettingsView.swift lines 96–98, 146–148
**Apply to:** TipJarView.swift, NudgeTimePickerScreen.swift
```swift
// In View body:
.task { await store.fetchProducts() }

// In Button action:
Button(action: allow) {
    // ...
}
// where allow() is:
private func allow() {
    Task {
        let granted = await NotificationScheduler.shared.requestAuthorization()
        // ...
    }
}
```

### .fullScreenCover Trigger Pattern
**Source:** GoalListView.swift (per CONTEXT.md code_context — "same `.fullScreenCover` pattern as GoalListView milestone celebrations")
**Apply to:** TipJarView.swift
```swift
@State private var showThankYou = false

.fullScreenCover(isPresented: $showThankYou) {
    TipThankYouView { showThankYou = false }
}
```

---

## No Analog Found

All Phase 19 files have close analogs. The only truly new API surface is StoreKit 2 (`import StoreKit`, `Product.products(for:)`, `product.purchase()`, `Transaction.updates`) — no existing file in the codebase uses StoreKit. Use RESEARCH.md Patterns 1 and 2 as the canonical reference for TipStore.swift and VitaminGApp.swift Transaction.updates.

| File / Concept | Reason No Codebase Analog Exists |
|----------------|----------------------------------|
| StoreKit 2 Product fetch + purchase | No prior IAP in codebase; RESEARCH.md Pattern 1 is the reference |
| `Transaction.updates` listener | First IAP phase; RESEARCH.md Pattern 2 is the reference |
| `ColorSchemePreference` enum | New enum; pattern from RESEARCH.md Pattern 3 (verified against SwiftUI docs) |

---

## Metadata

**Analog search scope:** `VitaminG/VitaminG/VitaminG/` (all subdirectories)
**Files scanned:** 11 files read in full; 2 read partially (VGTheme.swift, ProfileViewModel.swift)
**Pattern extraction date:** 2026-05-21
