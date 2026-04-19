# Phase 10: Profile Deep Link Handler - Research

**Researched:** 2026-04-19
**Domain:** SwiftUI deep link handling, CloudKit public database reads, @Observable navigation patterns
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Build a new `PublicProfileView` — a lightweight sheet showing the linked user's color avatar (initials + hex color) and display name, fetched from CloudKit public database using the `recordID`.
- **D-02:** Content is avatar + display name only. Public goal titles are NOT stored in the CloudKit public record (only `displayName` and `avatarColorHex`). Showing goals would require a data model redesign — out of scope.
- **D-03:** A new `ProfileSharingService.fetchProfile(recordID:)` function must be added to read a `PublicProfile` CKRecord from CloudKit public database.
- **D-04:** Add a new `AppRoute.publicProfile(recordID: String)` case. Do NOT modify the existing `.profile` case.
- **D-05:** `AppRoute.publicProfile` is the route the `.onOpenURL` handler resolves to. `AppRoute.profile` remains the route for own-profile navigation.
- **D-06:** `PublicProfileView` is presented as a sheet over whatever tab is active. No tab switching. No push onto NavigationStack.
- **D-07:** `AppRouter` owns the sheet trigger: add `pendingPublicProfileRecordID: String?` property. Setting it to non-nil presents the sheet; clearing it dismisses.
- **D-08:** `VitaminGApp.body` gets `.onOpenURL { url in ... }` on the `WindowGroup`. Handler parses the URL, extracts the recordID, sets `router.pendingPublicProfileRecordID = recordID`.
- **D-09:** URL format is `vitaming://profile/<recordID>`. Parser checks: scheme == "vitaming", host == "profile", first path component == recordID. Unknown URLs are silently ignored.
- **D-10:** `PublicProfileView` shows a loading state while fetching, then transitions to content or an inline error message ("This profile is no longer available.") with a Dismiss button. No separate alert — inline state keeps the sheet self-contained.

### Claude's Discretion

- Exact visual design of `PublicProfileView` (layout, typography, padding) — match the warm tone established in `ProfileView`
- Loading skeleton vs. spinner during CloudKit fetch
- Whether to use `@Observable` ViewModel pattern or inline `@State` for the simple fetch (recommend ViewModel for MVVM consistency)
- Specific error messages for different CKError codes (network vs. record-not-found)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROF-06 | App handles incoming `vitaming://profile/<recordID>` deep links via `.onOpenURL` handler in `VitaminGApp` | `.onOpenURL` modifier on `WindowGroup` already used in the codebase pattern (NotificationDelegate); handler parses URL and sets `router.pendingPublicProfileRecordID` |
| PROF-07 | Programmatic navigation to a specific profile via deep link resolves and navigates correctly | `AppRouter` is already `@Observable` and environment-injected; adding `pendingPublicProfileRecordID: String?` property + `ContentView` `.sheet` binding closes this requirement |
</phase_requirements>

---

## Summary

Phase 10 is a focused integration phase — almost all infrastructure already exists. The URL scheme `vitaming://` is registered in Info.plist (Phase 7). The send-side `DeepLinkBuilder.profileURL()` and `ProfileSharingService.publishProfile()` are already implemented. The `AppRouter` is `@Observable`, stored as a stable `App` struct property, and environment-injected into `ContentView`. The pattern for responding to external events (NotificationDelegate / `.onOpenURL`) is already established in `VitaminGApp`.

What is missing is the receive side: four targeted additions to existing files plus two new files (`PublicProfileViewModel` and `PublicProfileView`). The largest architectural risk is threading — `@MainActor` must be applied correctly to `PublicProfileViewModel` to prevent UI state updates from a background CloudKit completion. The second risk is the `.sheet(item:)` binding pattern when `pendingPublicProfileRecordID` is a `String?` rather than an `Identifiable` — the planner must choose `.sheet(isPresented:)` with `Binding<Bool>` or use `.sheet(item:)` with a thin `Identifiable` wrapper.

**Primary recommendation:** Add `pendingPublicProfileRecordID: String?` to `AppRouter`, bind the `ContentView` sheet via `.sheet(item:)` using an `Identifiable` wrapper struct, implement `PublicProfileViewModel` as `@MainActor @Observable` with a `.loading / .loaded / .error` state enum, add `fetchProfile(recordID:)` to `ProfileSharingService`, and add `.onOpenURL` to `VitaminGApp.body` using the same pattern as the `NotificationDelegate` closure.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| URL receive / parsing | App entry point (`VitaminGApp`) | — | `.onOpenURL` is a SwiftUI Scene modifier; must attach to `WindowGroup` |
| Navigation state mutation | AppRouter (shared `@Observable`) | — | Router is already the single source of navigation truth; adding a property here is consistent |
| Sheet presentation trigger | `ContentView` | — | ContentView already owns the `TabView` root; sheet must overlay all tabs |
| CloudKit public record fetch | Service layer (`ProfileSharingService`) | ViewModel | Keeps networking out of views; ViewModel drives the async task |
| UI state management | `PublicProfileViewModel` (`@Observable`) | — | MVVM enforcement per CLAUDE.md — no business logic in Views |
| Avatar/initials rendering | `AvatarView` (reuse) | — | Already encapsulates all avatar rendering; no duplication |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | `.onOpenURL`, `.sheet`, `@Environment` | Project-mandated; all UI is SwiftUI |
| CloudKit (`CKContainer`, `CKRecord`) | iOS 17+ | Public database record fetch | Already used in `ProfileSharingService` |
| Observation (`@Observable`) | iOS 17+ | `PublicProfileViewModel`, `AppRouter` mutation | Project-mandated; replaces `ObservableObject` |
| Swift Concurrency (`async/await`) | Swift 5.9+ | `fetchProfile(recordID:)` task | Already used throughout `ProfileSharingService` |

No new dependencies. All libraries are already imported and in active use in the project.

**Installation:** No new packages — existing project setup is sufficient.

---

## Architecture Patterns

### System Architecture Diagram

```
User taps vitaming://profile/<recordID> link
           │
           ▼
[iOS] delivers URL via UIScene / openURL
           │
           ▼
VitaminGApp.body  ──.onOpenURL──►  parse URL
  WindowGroup                       │
                     scheme == "vitaming"?  NO → silent drop
                                    │ YES
                     host == "profile"?     NO → silent drop
                                    │ YES
                     pathComponents[1] exists? NO → silent drop
                                    │ YES
                                    ▼
                     router.pendingPublicProfileRecordID = recordID
                                    │
                                    ▼ (@Observable change observed by ContentView)
ContentView (.sheet bound to pendingPublicProfileRecordID)
                                    │
                                    ▼
                          PublicProfileView
                           ├── .onAppear → viewModel.fetchProfile(recordID)
                           │
                           ▼
                    PublicProfileViewModel
                     └─ Task { ProfileSharingService.fetchProfile(recordID:) }
                                    │
                          ┌─────────┴──────────┐
                        success              failure
                          │                    │
                    .loaded(displayName,   .error(message)
                     avatarColorHex)
                          │
                    AvatarView + Text      SF Symbol + Text + Dismiss
```

### Recommended File Changes

```
VitaminG/VitaminG/VitaminG/
├── Navigation/
│   ├── AppRoute.swift          # ADD .publicProfile(recordID: String) case
│   └── AppRouter.swift         # ADD pendingPublicProfileRecordID: String?
├── VitaminGApp.swift           # ADD .onOpenURL on WindowGroup
├── Views/
│   ├── ContentView.swift       # ADD .sheet bound to pendingPublicProfileRecordID
│   └── PublicProfileView.swift # NEW — sheet card UI
├── ViewModels/
│   └── PublicProfileViewModel.swift  # NEW — @Observable, state enum
└── Services/
    └── ProfileSharingService.swift   # ADD fetchProfile(recordID:)
```

### Pattern 1: `.onOpenURL` on `WindowGroup`

**What:** SwiftUI modifier that receives custom URL scheme invocations from iOS.
**When to use:** App needs to respond to `vitaming://` URLs opened from Messages, Safari, or other apps.

```swift
// Source: Apple Developer Documentation — openURL environment value
// https://developer.apple.com/documentation/swiftui/environmentvalues/openurl
var body: some Scene {
    WindowGroup {
        // ... existing content ...
    }
    .onOpenURL { url in
        guard url.scheme == DeepLinkBuilder.scheme,
              url.host == "profile",
              let recordID = url.pathComponents.dropFirst().first,
              !recordID.isEmpty else { return }
        router.pendingPublicProfileRecordID = recordID
    }
}
```

**Key constraint:** `.onOpenURL` must be on the `Scene` (or `WindowGroup` body), not on an individual view, to catch cold-launch URLs reliably. [VERIFIED: existing VitaminGApp.swift shows `.modelContainer` and `.environment` applied at the `WindowGroup` body level — the same attachment point is correct for `.onOpenURL`]

### Pattern 2: `AppRouter` as `@Observable` sheet trigger

**What:** Add a `String?` property to the already-`@Observable` `AppRouter`; `ContentView` observes it.
**When to use:** Sheet must be presented from `ContentView` which already has `@Environment(AppRouter.self)`.

```swift
// AppRouter addition
@Observable
final class AppRouter {
    var path: [AppRoute] = []
    var pendingPublicProfileRecordID: String? = nil  // NEW — D-07
    // ... existing methods unchanged ...
}
```

**Sheet binding options** — two valid approaches:

Option A — `Identifiable` wrapper (recommended for type safety):
```swift
// Thin wrapper so String conforms to Identifiable for .sheet(item:)
struct ProfileDeepLinkItem: Identifiable {
    let id: String  // recordID is the identity
}

// ContentView
.sheet(item: Binding(
    get: { router.pendingPublicProfileRecordID.map { ProfileDeepLinkItem(id: $0) } },
    set: { _ in router.pendingPublicProfileRecordID = nil }
)) { item in
    PublicProfileView(recordID: item.id)
}
```

Option B — `isPresented` with computed Bool:
```swift
@Bindable var router = router
.sheet(isPresented: Binding(
    get: { router.pendingPublicProfileRecordID != nil },
    set: { if !$0 { router.pendingPublicProfileRecordID = nil } }
)) {
    if let recordID = router.pendingPublicProfileRecordID {
        PublicProfileView(recordID: recordID)
    }
}
```

Option A is preferred — avoids optional force-unwrap risk in the sheet content closure and is more idiomatic SwiftUI. [ASSUMED — both patterns are valid SwiftUI; Option A preference is based on idiomatic patterns, not a verified official recommendation between the two]

### Pattern 3: `PublicProfileViewModel` — state enum with `@MainActor @Observable`

```swift
// Source: Apple Developer Documentation — Observation
// https://developer.apple.com/documentation/observation
@MainActor
@Observable
final class PublicProfileViewModel {

    enum ViewState {
        case loading
        case loaded(displayName: String?, avatarColorHex: String?)
        case error(message: String)
    }

    var state: ViewState = .loading

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    func fetchProfile(recordID: String) {
        state = .loading
        Task {
            do {
                let result = try await ProfileSharingService.fetchProfile(recordID: recordID)
                state = .loaded(displayName: result.displayName, avatarColorHex: result.avatarColorHex)
            } catch let error as CKError {
                switch error.code {
                case .unknownItem:
                    state = .error(message: "Profile not found. This profile link is no longer available. It may have been made private.")
                case .networkFailure, .networkUnavailable:
                    state = .error(message: "Couldn't load profile. Check your internet connection and try again.")
                default:
                    state = .error(message: "Couldn't load profile. Check your internet connection and try again.")
                }
            } catch {
                state = .error(message: "Couldn't load profile. Check your internet connection and try again.")
            }
        }
    }
}
```

**`@MainActor` is required** because `state` mutations drive SwiftUI view updates. Without it, state changes from the async CloudKit task completion would occur off-main-thread. `ProfileViewModel` already uses `@MainActor` — this is established project pattern. [VERIFIED: ProfileViewModel.swift line 11 — `@MainActor @Observable final class ProfileViewModel`]

### Pattern 4: `ProfileSharingService.fetchProfile(recordID:)`

```swift
// Extends existing ProfileSharingService
// Source: Apple Developer Documentation — CKDatabase.record(for:)
// https://developer.apple.com/documentation/cloudkit/ckdatabase/record(for:)
static func fetchProfile(recordID: String) async throws -> (displayName: String?, avatarColorHex: String?) {
    let container = CKContainer(identifier: containerID)  // reuse existing constant
    let publicDB = container.publicCloudDatabase
    let ckRecordID = CKRecord.ID(recordName: recordID)
    let record = try await publicDB.record(for: ckRecordID)
    let displayName = record["displayName"] as? String
    let avatarColorHex = record["avatarColorHex"] as? String
    return (displayName: displayName, avatarColorHex: avatarColorHex)
}
```

Field names `"displayName"` and `"avatarColorHex"` must match exactly what `publishProfile()` writes. [VERIFIED: ProfileSharingService.swift lines 36–37 — `record["displayName"]` and `record["avatarColorHex"]`]

### Pattern 5: `AppRoute.publicProfile` case

```swift
// Source: AppRoute.swift — existing enum
enum AppRoute: Hashable {
    case goalDetail(Goal)
    case stats
    case settings
    case profile                              // UNCHANGED — owns NOTIF-07
    case publicProfile(recordID: String)      // NEW — D-04, D-05
}
```

**`Hashable` conformance:** `String` is `Hashable`, so the associated value requires no extra conformance work. [VERIFIED: existing `case goalDetail(Goal)` has an associated value that conforms to Hashable — same pattern applies]

**Important:** `AppRoute.publicProfile` does NOT need a `navigationDestination` entry in `ContentView`'s `goalsTab` since it is presented as a sheet, not pushed onto the NavigationStack. Adding it to `switch route` in `goalsTab.navigationDestination` would cause a non-exhaustive switch warning — the planner should handle this with a default case or by not routing `.publicProfile` through the stack at all.

### Anti-Patterns to Avoid

- **Modifying `AppRoute.profile`:** It is in active use for NOTIF-07 (notification deep link to own profile). Any modification risks breaking the notification routing path.
- **Presenting `PublicProfileView` as a NavigationStack push:** D-06 explicitly prohibits this. Cold-launch timing makes push navigation unreliable.
- **Calling `AppRouter.navigate(to: .publicProfile)` instead of setting `pendingPublicProfileRecordID`:** The router's `path` is a NavigationStack path. A sheet trigger requires its own `Bool` or `Optional` property, not a path append. Appending to `path` would try to push a view that has no `navigationDestination`.
- **Performing CloudKit fetch in `VitaminGApp.onOpenURL`:** The handler must only set state; async work belongs in the ViewModel, triggered by `PublicProfileView.onAppear`.
- **Missing `@MainActor` on `PublicProfileViewModel`:** State mutations from async Task completions off-main-thread will cause SwiftUI rendering warnings on iOS 17 and potential crashes on iOS 18+.
- **Hardcoding CloudKit container ID:** `ProfileSharingService.containerID` is already defined as `"iCloud.com.kyleharrington.VitaminG"`. All CloudKit access must reuse this constant — no duplication.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| URL parsing | Custom regex or string splitting | `URL`, `URLComponents`, native Swift URL path parsing | URL type already handles percent-encoding, scheme/host/path decomposition correctly |
| CloudKit record fetch | Custom URLSession CloudKit REST calls | `CKContainer` / `CKDatabase.record(for:)` | Already used in `ProfileSharingService`; CloudKit framework handles auth, retry, error codes |
| Avatar rendering | New initials + color component | `AvatarView` (reuse) | Already handles hex parsing, initials extraction, photo fallback, shadow, accessibility label |
| Sheet dismiss | Custom gesture recognizer | `router.pendingPublicProfileRecordID = nil` + SwiftUI `.sheet` dismiss binding | SwiftUI manages sheet lifecycle; setting the bound value to nil is the idiomatic dismiss |
| Async error classification | String-matching on `localizedDescription` | `CKError.Code` enum switch | Type-safe, exhaustive, not locale-dependent |

---

## Common Pitfalls

### Pitfall 1: Cold Launch URL Delivery Timing

**What goes wrong:** On cold launch (app not in memory), `VitaminGApp.init()` runs before `body` is evaluated. If the `.onOpenURL` handler fires before the `AppRouter` is available to `ContentView` via `.environment()`, the property is set but `ContentView` hasn't yet observed `router` — the sheet never appears.

**Why it happens:** SwiftUI environment injection happens when `body` is first rendered. Cold launch URL delivery can occur before first render completes on some iOS versions.

**How to avoid:** The `AppRouter` is stored as a stored property on `VitaminGApp` (`let router: AppRouter`) — this is already the pattern. Setting `router.pendingPublicProfileRecordID` in `.onOpenURL` is safe because the stored property is the same object injected via `.environment(router)`. When `ContentView` renders, it reads the already-set value and presents the sheet immediately.

**Warning signs:** Sheet not appearing on cold launch but appearing correctly on foreground launch.

### Pitfall 2: `ContentView` NavigationStack Switch Exhaustiveness

**What goes wrong:** Adding `AppRoute.publicProfile(recordID:)` to the enum triggers a Swift compiler warning or error for non-exhaustive switches in `ContentView.goalsTab`'s `navigationDestination(for: AppRoute.self)`.

**Why it happens:** The `switch route` in `goalsTab` handles all existing cases. New associated-value cases require a handler or default.

**How to avoid:** Add a default case to the switch, or add a no-op `case .publicProfile: EmptyView()` entry. The planner should address this explicitly in the `ContentView` modification task.

### Pitfall 3: Double Sheet Presentation

**What goes wrong:** If the user taps a second deep link while `PublicProfileView` is already presented, the sheet does not update to the new `recordID` — `pendingPublicProfileRecordID` changes but the already-presented sheet was initialized with the first value.

**Why it happens:** `.sheet(item:)` in SwiftUI does not automatically re-present for the same sheet type when the `item` changes while the sheet is open.

**How to avoid:** Since `ProfileDeepLinkItem.id` is the `recordID`, SwiftUI's `.sheet(item:)` will dismiss and re-present when the item's identity changes. This is the correct behavior. [ASSUMED — SwiftUI `.sheet(item:)` identity-based re-presentation behavior; consistent with documented behavior but not verified in this session against official docs for this exact scenario]

### Pitfall 4: `Hashable` Synthesis for `AppRoute.publicProfile`

**What goes wrong:** Synthesized `Hashable` on an enum with `String` associated values works correctly, but if the enum is used in a `NavigationStack` path and the new case is accidentally appended there, it will produce a runtime warning because no `navigationDestination` handles it.

**How to avoid:** Never call `router.navigate(to: .publicProfile(recordID:))`. The sheet path uses `pendingPublicProfileRecordID` directly. The `.publicProfile` case exists for type-system completeness per D-04 but is never pushed onto `router.path`.

### Pitfall 5: Empty `pathComponents` on Malformed URL

**What goes wrong:** `URL(string: "vitaming://profile/")` produces `pathComponents == ["/"]`. `dropFirst()` then yields an empty sequence, and `first` returns `nil` — correct behavior. But `URL(string: "vitaming://profile")` (no trailing slash) produces `pathComponents == []`, so `dropFirst().first` is also `nil`. Both cases are handled correctly by the guard.

**How to avoid:** The guard `let recordID = url.pathComponents.dropFirst().first, !recordID.isEmpty` handles both gracefully. Verified by tracing through URL path component documentation. [VERIFIED: `DeepLinkBuilder.profileURL()` always produces `vitaming://profile/<recordID>` with a non-empty recordID — the guard is defensive against malformed incoming URLs from other sources]

---

## Code Examples

### Verified: Existing CloudKit public database pattern

```swift
// Source: ProfileSharingService.swift lines 25-41 (VERIFIED in codebase)
let container = CKContainer(identifier: containerID)
let publicDB = container.publicCloudDatabase
let record = try await publicDB.record(for: recordID)
```

### Verified: Existing NotificationDelegate deep-link handler pattern in VitaminGApp

```swift
// Source: VitaminGApp.swift lines 22-28 (VERIFIED in codebase)
let delegate = NotificationDelegate { deepLink in
    if deepLink == "goalList" {
        appRouter.popToRoot()
    }
}
// The .onOpenURL pattern is the URL-based analogue of this closure pattern
```

### Verified: Existing AppRouter @Observable pattern

```swift
// Source: AppRouter.swift (VERIFIED in codebase)
@Observable
final class AppRouter {
    var path: [AppRoute] = []
    // Adding var pendingPublicProfileRecordID: String? = nil follows this pattern exactly
}
```

### Verified: AvatarView call signature

```swift
// Source: ProfileView.swift lines 47-53, AvatarView.swift (VERIFIED in codebase)
AvatarView(
    displayName: displayName,       // String?
    avatarColorHex: avatarColorHex, // String?
    photoData: nil,                 // Data? — always nil for PublicProfileView (D-02)
    size: 72                        // CGFloat — between 88 (ProfileView) and 64 (EditSheet)
)
```

### Verified: State-driven animation pattern (matching ProfileView)

```swift
// Source: ProfileView.swift line 168 (VERIFIED in codebase)
.animation(.easeOut(duration: 0.25), value: publicGoals.count)
// PublicProfileView should use .animation(.easeOut(duration: 0.25), value: viewModel.state)
// Requires ViewState to be Equatable
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `UIApplicationDelegate` `application(_:open:options:)` | SwiftUI `.onOpenURL` modifier on `WindowGroup` | iOS 14+ (SwiftUI 2.0) | No UIKit bridge required; pure SwiftUI |
| `ObservableObject` / `@Published` | `@Observable` macro | iOS 17 | Single property-level observation; no whole-object invalidation |
| `CKFetchRecordsOperation` (batch) | `CKDatabase.record(for:)` async | iOS 15+ async CloudKit | Simpler for single-record fetch; no operation subclass needed |

**Deprecated/outdated:**
- `UIApplicationDelegate.application(_:open:)`: Still works but UIKit bridge is unnecessary in a SwiftUI-only app. The `.onOpenURL` modifier is the modern replacement. [ASSUMED — based on Apple's SwiftUI adoption guidance; not verified against a specific deprecation notice in this session]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Option A (Identifiable wrapper) is preferred over Option B (isPresented + Bool) for the sheet binding | Architecture Patterns, Pattern 2 | Low — both patterns work; preference is stylistic |
| A2 | `.sheet(item:)` dismisses and re-presents when item identity changes while sheet is open | Common Pitfalls, Pitfall 3 | Medium — if wrong, a second tap while sheet is open would silently show stale profile; add `onChange` handler as fallback |
| A3 | `UIApplicationDelegate.application(_:open:)` is deprecated in favor of `.onOpenURL` | State of the Art | Low — the `.onOpenURL` approach is verified working from documentation; the deprecation framing is stylistic |

---

## Open Questions

1. **Should `ViewState` conform to `Equatable`?**
   - What we know: `.animation(..., value:)` requires `Equatable`. The `ViewState` enum has associated values (`String?`) — synthesis requires `String?` to be `Equatable`, which it is.
   - What's unclear: Whether the animation is worth the conformance noise for a simple loading → loaded state.
   - Recommendation: Add `Equatable` conformance to `ViewState` and use `.animation(.easeOut(duration: 0.25), value: viewModel.state)` for consistency with `ProfileView`.

2. **Where should `ProfileDeepLinkItem` struct be defined?**
   - What we know: It is a thin `Identifiable` wrapper used only in `ContentView`.
   - What's unclear: Whether it belongs in `AppRouter.swift`, `ContentView.swift`, or a dedicated `NavigationTypes.swift`.
   - Recommendation: Define it in `AppRouter.swift` alongside `AppRouter` — it is a navigation concern, not a view concern.

3. **`@Bindable` usage in `ContentView` for the new sheet**
   - What we know: `ContentView` already uses `@Bindable var router = router` inside `goalsTab` to bind `router.path`. The new sheet binding also needs `router` to be bindable.
   - What's unclear: Whether `@Bindable` needs to be hoisted to `ContentView.body` level or if it can stay in-place.
   - Recommendation: Move `@Bindable var router = router` to be declared once at the top of `body`, shared between `goalsTab` and the new `.sheet` modifier.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| CloudKit (CKContainer) | `ProfileSharingService.fetchProfile` | Already in use | iOS 17+ | None — CloudKit is the only public profile store |
| Swift Concurrency (async/await) | `fetchProfile` task | Already in use | Swift 5.9+ (Xcode 15+) | None needed |
| `@Observable` macro | `PublicProfileViewModel` | Already in use | iOS 17+ | None needed |
| `vitaming://` URL scheme | `.onOpenURL` | Already registered (Phase 7, Info.plist) | N/A | None needed |

No new environment dependencies. All required infrastructure is confirmed present from Phase 7 completion.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Test`, `#expect`) — confirmed in `VitaminGTests.swift` |
| Config file | Xcode scheme — no separate config file |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Full suite command | Same — single test target |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROF-06 | `.onOpenURL` handler parses `vitaming://profile/<recordID>` and sets `router.pendingPublicProfileRecordID` | unit | `xcodebuild test -only-testing VitaminGTests/DeepLinkParserTests` | ❌ Wave 0 |
| PROF-06 | Malformed URLs (wrong scheme, missing recordID) are silently ignored | unit | `xcodebuild test -only-testing VitaminGTests/DeepLinkParserTests` | ❌ Wave 0 |
| PROF-07 | `AppRouter.pendingPublicProfileRecordID` set → sheet presents with correct recordID | integration (manual-only) | Visual check on device/simulator | N/A |
| PROF-07 | `PublicProfileViewModel.fetchProfile` transitions from `.loading` to `.loaded` on success | unit (mock required) | `xcodebuild test -only-testing VitaminGTests/PublicProfileViewModelTests` | ❌ Wave 0 |
| PROF-07 | `PublicProfileViewModel.fetchProfile` transitions to `.error` on `CKError.unknownItem` | unit (mock required) | `xcodebuild test -only-testing VitaminGTests/PublicProfileViewModelTests` | ❌ Wave 0 |

**Note on CloudKit unit testing:** `ProfileSharingService.fetchProfile` makes a live network call. The ViewModel test should inject a fake/mock fetch function to avoid network dependency. Consider adding a `fetchOverride: ((String) async throws -> (String?, String?))?` parameter to `fetchProfile` in tests, or extract a protocol/closure. The existing `NotificationSchedulerTests` already demonstrate the project pattern of injecting test fakes rather than mocking framework types.

### Sampling Rate

- **Per task commit:** Verify the modified file compiles (Xcode build check)
- **Per wave merge:** Run URL parsing unit tests + build passes
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `VitaminGTests/DeepLinkParserTests.swift` — covers PROF-06 URL parsing logic (can test pure URL parsing without UIKit/SwiftUI)
- [ ] `VitaminGTests/PublicProfileViewModelTests.swift` — covers PROF-07 state transitions (requires async test support, already available in Swift Testing)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not applicable — public profile read requires no auth |
| V3 Session Management | no | No session created by reading a public CloudKit record |
| V4 Access Control | yes | CloudKit public database is read-only for this operation; no write path in Phase 10 |
| V5 Input Validation | yes | `recordID` extracted from URL must be validated (non-empty, no path traversal) |
| V6 Cryptography | no | No encryption required for public read |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed `vitaming://` URL with crafted recordID (path traversal, injection) | Tampering | Guard: non-empty, `pathComponents.dropFirst().first` — only first path segment used; never passed to file system or SQL |
| CloudKit recordID used to enumerate public profiles | Information Disclosure | Acceptable risk — CloudKit public database is intentionally public; only `displayName` and `avatarColorHex` are stored |
| XSS-equivalent via `displayName` displayed in SwiftUI `Text` | Tampering | `Text(displayName)` in SwiftUI renders plain text, not HTML — no injection risk; `InputSanitizer.sanitizeForPublic` was applied at publish time |
| URL scheme hijacking by a malicious app registering `vitaming://` | Spoofing | Universal Links are the mitigation (Phase 10 uses custom scheme per D-09); custom scheme hijacking risk is accepted — identical to existing Phase 7 send-side design |

**`recordID` validation requirement (PROF-06):** The URL handler must validate that `recordID` is non-empty before setting `pendingPublicProfileRecordID`. A zero-length recordID would cause `CKRecord.ID(recordName: "")` which produces an immediate CloudKit error — acceptable but wasteful. The guard `!recordID.isEmpty` in the URL parser prevents this.

---

## Sources

### Primary (HIGH confidence)

- Codebase — `ProfileSharingService.swift`, `AppRouter.swift`, `AppRoute.swift`, `VitaminGApp.swift`, `ContentView.swift`, `AvatarView.swift`, `ProfileView.swift`, `NotificationDelegate.swift`, `VitaminGTests.swift` — all read directly in this session
- `10-CONTEXT.md` — User decisions D-01 through D-10 — read directly
- `10-UI-SPEC.md` — Visual contract approved by gsd-ui-checker — read directly

### Secondary (MEDIUM confidence)

- Apple Developer Documentation pattern for `.onOpenURL` — [ASSUMED based on training knowledge of SwiftUI Scene modifiers; behavior is consistent with observed codebase patterns]
- CloudKit `CKDatabase.record(for:)` async API — [ASSUMED based on training knowledge; consistent with existing `publishProfile` implementation in ProfileSharingService]

### Tertiary (LOW confidence)

- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in active use in the codebase
- Architecture: HIGH — patterns verified directly from existing code; no new patterns introduced
- Pitfalls: HIGH (Pitfalls 1, 2, 4, 5) / MEDIUM (Pitfall 3 — sheet re-presentation behavior assumed)
- Test approach: MEDIUM — Swift Testing framework confirmed; specific test file names are new additions

**Research date:** 2026-04-19
**Valid until:** 2026-05-19 (stable iOS/SwiftUI APIs; no fast-moving dependencies)
