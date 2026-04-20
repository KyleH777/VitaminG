# Phase 10: Profile Deep Link Handler - Pattern Map

**Mapped:** 2026-04-19
**Files analyzed:** 9
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Navigation/AppRoute.swift` | config / route enum | request-response | `Navigation/AppRoute.swift` (self) | self — additive change only |
| `Navigation/AppRouter.swift` | config / navigation state | request-response | `Navigation/AppRouter.swift` (self) | self — additive change only |
| `VitaminGApp.swift` | app entry point | event-driven | `VitaminGApp.swift` + `NotificationDelegate.swift` | exact — same event-dispatch pattern |
| `Views/ContentView.swift` | view / root layout | request-response | `Views/ProfileView.swift` | role-match — sheet binding pattern |
| `Services/ProfileSharingService.swift` | service | CRUD / request-response | `Services/ProfileSharingService.swift` (self) | self — additive method only |
| `Views/PublicProfileView.swift` | view / sheet card | request-response | `Views/ProfileView.swift` | role-match — avatar + name display, sheet structure |
| `ViewModels/PublicProfileViewModel.swift` | view model | request-response | `ViewModels/ProfileViewModel.swift` | exact — `@MainActor @Observable`, async CloudKit task, state-driven UI |
| `VitaminGTests/DeepLinkParserTests.swift` | test | transform | `VitaminGTests/GoalViewModelTests.swift` | role-match — XCTest, `@MainActor`, `@testable import` |
| `VitaminGTests/PublicProfileViewModelTests.swift` | test | request-response | `VitaminGTests/NotificationSchedulerTests.swift` | role-match — async test, fake-injection pattern |

---

## Pattern Assignments

### `Navigation/AppRoute.swift` (config, additive)

**Analog:** Self (`/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift`)

**Full current file** (lines 1-12):
```swift
import Foundation

enum AppRoute: Hashable {
    case goalDetail(Goal)
    case stats
    case settings
    case profile    // Phase 7 — owns NOTIF-07; do NOT modify
}
```

**Addition pattern** — append one case after `case profile`:
```swift
case publicProfile(recordID: String)   // Phase 10 — D-04, D-05; sheet only, never pushed onto NavigationStack path
```

**Hashable note:** `String` is `Hashable`, so no manual conformance is needed. The existing `case goalDetail(Goal)` with its associated value demonstrates this pattern is already established.

**Exhaustive switch note:** Adding this case triggers a compiler warning in `ContentView.goalsTab`'s `navigationDestination(for: AppRoute.self)` switch. Add `case .publicProfile: EmptyView()` or a `default` branch there — this case is never pushed onto the NavigationStack.

---

### `Navigation/AppRouter.swift` (config, additive)

**Analog:** Self (`/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Navigation/AppRouter.swift`)

**Full current file** (lines 1-21):
```swift
import Observation

@Observable
final class AppRouter {
    var path: [AppRoute] = []

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
```

**Addition pattern** — insert after `var path: [AppRoute] = []`:
```swift
/// Trigger for presenting PublicProfileView as a sheet (Phase 10, D-07).
/// Set to a non-nil recordID by the .onOpenURL handler in VitaminGApp.
/// Setting nil dismisses the sheet.
var pendingPublicProfileRecordID: String? = nil
```

**`Identifiable` wrapper** — define in this file (navigation concern, not view concern — Open Question 2):
```swift
/// Thin Identifiable wrapper enabling .sheet(item:) binding on pendingPublicProfileRecordID.
/// Defined alongside AppRouter because it is a navigation type, not a view type.
struct ProfileDeepLinkItem: Identifiable {
    let id: String  // id == recordID
}
```

---

### `VitaminGApp.swift` (app entry point, event-driven)

**Analog:** Self + `Services/NotificationDelegate.swift`
**Source files:**
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/VitaminGApp.swift`
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Services/NotificationDelegate.swift`

**Existing deep-link dispatch pattern** (VitaminGApp.swift lines 22-28 — the exact analog):
```swift
let delegate = NotificationDelegate { deepLink in
    if deepLink == "goalList" {
        appRouter.popToRoot()
    }
}
```

**Existing WindowGroup body** (lines 45-57):
```swift
var body: some Scene {
    WindowGroup {
        Group {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(container)
        .environment(router)
    }
}
```

**Addition pattern** — append `.onOpenURL` modifier to the `WindowGroup` (same level as `.modelContainer` / `.environment`):
```swift
var body: some Scene {
    WindowGroup {
        // ... existing Group ...
    }
    .modelContainer(container)
    .environment(router)
    .onOpenURL { url in
        // D-08, D-09: Parse vitaming://profile/<recordID>
        // Uses DeepLinkBuilder.scheme constant to avoid string duplication
        guard url.scheme == DeepLinkBuilder.scheme,
              url.host == "profile",
              let recordID = url.pathComponents.dropFirst().first,
              !recordID.isEmpty else { return }
        router.pendingPublicProfileRecordID = recordID
    }
}
```

**Cold-launch safety:** `router` is a stored `let` property on `VitaminGApp`, identical to the `appRouter` reference captured by `NotificationDelegate`. Setting `router.pendingPublicProfileRecordID` before `ContentView` renders is safe — when `ContentView` renders, it reads the already-set value and presents the sheet immediately.

---

### `Views/ContentView.swift` (view, additive)

**Analog:** `Views/ProfileView.swift` (sheet binding pattern)
**Source:** `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/ContentView.swift`

**Existing sheet binding pattern in ProfileView.swift** (line 35):
```swift
.sheet(isPresented: $viewModel.showingEditSheet) {
    ProfileEditSheet(viewModel: viewModel)
}
```

**Existing `@Bindable` usage in ContentView.swift** (lines 42-43):
```swift
private var goalsTab: some View {
    @Bindable var router = router
    return NavigationStack(path: $router.path) {
```

**Addition 1** — hoist `@Bindable` to `body` level so it is shared between `goalsTab` and the new sheet modifier (Open Question 3):
```swift
var body: some View {
    @Bindable var router = router  // moved here from goalsTab
    TabView {
        // ... existing tabs unchanged ...
    }
    .sheet(item: Binding(
        get: { router.pendingPublicProfileRecordID.map { ProfileDeepLinkItem(id: $0) } },
        set: { _ in router.pendingPublicProfileRecordID = nil }
    )) { item in
        PublicProfileView(recordID: item.id)
    }
}
```

**Addition 2** — add `default` or `case .publicProfile` to the `navigationDestination` switch in `goalsTab` (Pitfall 2):
```swift
.navigationDestination(for: AppRoute.self) { route in
    switch route {
    case .goalDetail(let goal):  GoalDetailView(goal: goal)
    case .stats:                 StatsView()
    case .settings:              SettingsView()
    case .profile:               ProfileView()
    case .publicProfile:         EmptyView()  // never pushed; sheet path handles this
    }
}
```

---

### `Services/ProfileSharingService.swift` (service, additive)

**Analog:** Self
**Source:** `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift`

**Existing CloudKit fetch pattern** (lines 28-30 — `publishProfile` updates an existing record with the same API):
```swift
let container = CKContainer(identifier: containerID)
let publicDB = container.publicCloudDatabase
let record = try await publicDB.record(for: recordID)
```

**Existing CKError handling pattern** (lines 51-54 — `unpublishProfile` handles `.unknownItem`):
```swift
} catch let error as CKError where error.code == .unknownItem {
    // Record already deleted — not an error
}
```

**Existing field names** (lines 36-37 — must match exactly in `fetchProfile`):
```swift
record["displayName"] = (displayName ?? "") as CKRecordValue
record["avatarColorHex"] = (avatarColorHex ?? "") as CKRecordValue
```

**Addition pattern** — append after `unpublishProfile`:
```swift
/// Reads a PublicProfile record from CloudKit public database by recordID.
/// Returns only displayName and avatarColorHex — the two fields written by publishProfile.
/// Throws CKError on network failure or missing record; callers handle CKError.unknownItem.
static func fetchProfile(recordID: String) async throws -> (displayName: String?, avatarColorHex: String?) {
    let container = CKContainer(identifier: containerID)   // reuse existing constant — never hardcode
    let publicDB = container.publicCloudDatabase
    let ckRecordID = CKRecord.ID(recordName: recordID)
    let record = try await publicDB.record(for: ckRecordID)
    let displayName = record["displayName"] as? String
    let avatarColorHex = record["avatarColorHex"] as? String
    return (displayName: displayName, avatarColorHex: avatarColorHex)
}
```

---

### `Views/PublicProfileView.swift` (view, new)

**Analog:** `Views/ProfileView.swift`
**Source:** `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/ProfileView.swift`

**Imports pattern** (ProfileView.swift lines 1-4):
```swift
import SwiftUI
import SwiftData
import UIKit
```
PublicProfileView needs only `SwiftUI` and `UIKit` (no SwiftData — no local model queries).

**View struct + @State ViewModel pattern** (ProfileView.swift line 10):
```swift
struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
```
Copy for PublicProfileView:
```swift
struct PublicProfileView: View {
    let recordID: String
    @State private var viewModel = PublicProfileViewModel()
    @Environment(\.dismiss) private var dismiss
```

**AvatarView call signature** (ProfileView.swift lines 48-53):
```swift
AvatarView(
    displayName: viewModel.profile?.displayName,
    avatarColorHex: viewModel.profile?.avatarColorHex,
    photoData: viewModel.profile?.photoData,
    size: 88
)
```
PublicProfileView version (photoData always nil — D-02; size 72 per research):
```swift
AvatarView(
    displayName: displayName,
    avatarColorHex: avatarColorHex,
    photoData: nil,        // D-02: no photo stored in public record
    size: 72
)
```

**Display name typography pattern** (ProfileView.swift lines 63-66):
```swift
Text(name)
    .font(.title2.weight(.semibold)).fontDesign(.rounded)
    .foregroundStyle(.primary)
```

**Empty / placeholder pattern** (ProfileView.swift lines 68-71):
```swift
Text("Add your name")
    .font(.title2.weight(.semibold)).fontDesign(.rounded)
    .foregroundStyle(.secondary)
```

**Animation pattern** (ProfileView.swift line 168):
```swift
.animation(.easeOut(duration: 0.25), value: publicGoals.count)
```
PublicProfileView version (requires `ViewState: Equatable`):
```swift
.animation(.easeOut(duration: 0.25), value: viewModel.state)
```

**Background pattern** (ProfileView.swift line 29):
```swift
.background(Color(UIColor.systemGroupedBackground))
```

**onAppear trigger** (ProfileView.swift lines 33-35):
```swift
.onAppear {
    viewModel.loadOrCreateProfile(context: modelContext)
}
```
PublicProfileView version:
```swift
.onAppear {
    viewModel.fetchProfile(recordID: recordID)
}
```

---

### `ViewModels/PublicProfileViewModel.swift` (view model, new)

**Analog:** `ViewModels/ProfileViewModel.swift`
**Source:** `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/ViewModels/ProfileViewModel.swift`

**Imports + class declaration pattern** (ProfileViewModel.swift lines 1-13):
```swift
import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class ProfileViewModel {
```
PublicProfileViewModel needs only `Observation` and `CloudKit`:
```swift
import Observation
import CloudKit

@MainActor
@Observable
final class PublicProfileViewModel {
```

**`@MainActor` is required** — RESEARCH.md verified: `ProfileViewModel.swift` line 11 uses `@MainActor @Observable`. State mutations from `Task` completions inside `@MainActor` classes are safely dispatched to main thread.

**State enum pattern** (no direct analog in codebase; pattern recommended by research):
```swift
enum ViewState: Equatable {
    case loading
    case loaded(displayName: String?, avatarColorHex: String?)
    case error(message: String)
}

var state: ViewState = .loading
```
`Equatable` conformance is required for `.animation(..., value: viewModel.state)`.

**Async Task + CKError dispatch pattern** (ProfileViewModel.swift lines 136-150 — `toggleProfilePublic` Task):
```swift
Task { @MainActor in
    do {
        let recordID = try await ProfileSharingService.publishProfile(...)
        profile.cloudKitPublicRecordID = recordID
        try? context.save()
    } catch {
        cloudKitError = error.localizedDescription
        showingCloudKitError = true
    }
}
```
PublicProfileViewModel version with typed CKError switch:
```swift
func fetchProfile(recordID: String) {
    state = .loading
    Task {
        do {
            let result = try await ProfileSharingService.fetchProfile(recordID: recordID)
            state = .loaded(displayName: result.displayName, avatarColorHex: result.avatarColorHex)
        } catch let error as CKError {
            switch error.code {
            case .unknownItem:
                state = .error(message: "This profile is no longer available.")
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
```

---

### `VitaminGTests/DeepLinkParserTests.swift` (test, new)

**Analog:** `VitaminGTests/GoalViewModelTests.swift`
**Source:** `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminGTests/GoalViewModelTests.swift`

**Imports + class declaration pattern** (GoalViewModelTests.swift lines 1-6):
```swift
import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class GoalViewModelTests: XCTestCase {
```
DeepLinkParserTests version (no SwiftData needed — pure URL parsing):
```swift
import XCTest
@testable import VitaminG

final class DeepLinkParserTests: XCTestCase {
```

**Test naming convention** (GoalViewModelTests.swift lines 26-27):
```swift
// Pattern: test_<subject>_<condition>_<expectedResult>
func test_createGoal_emptyTitle_throwsTitleEmpty() throws {
```
Apply same convention:
```swift
func test_onOpenURL_validProfileURL_setsRecordID()
func test_onOpenURL_wrongScheme_ignored()
func test_onOpenURL_missingRecordID_ignored()
func test_onOpenURL_emptyRecordID_ignored()
```

**Note on test scope:** The `.onOpenURL` handler is a closure (`guard … router.pendingPublicProfileRecordID = recordID`). To test it without launching the full app, extract the URL parsing logic into a pure static function — e.g., `DeepLinkParser.recordID(from url: URL) -> String?` — and test that directly. The closure in `VitaminGApp` calls this function. This avoids the need for a full `App` instance in tests.

---

### `VitaminGTests/PublicProfileViewModelTests.swift` (test, new)

**Analog:** `VitaminGTests/NotificationSchedulerTests.swift`
**Source:** `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminGTests/NotificationSchedulerTests.swift`

**Async setUp pattern** (NotificationSchedulerTests.swift lines 14-16):
```swift
override func setUp() async throws {
    container = try ModelContainerFactory.makeContainer(inMemory: true)
}
```
PublicProfileViewModelTests version:
```swift
@MainActor
final class PublicProfileViewModelTests: XCTestCase {
    var sut: PublicProfileViewModel!

    override func setUp() async throws {
        sut = PublicProfileViewModel()
    }

    override func tearDown() async throws {
        sut = nil
    }
```

**Fake-injection pattern** (NotificationSchedulerTests.swift pattern — inject test fakes, not live framework types):
CloudKit `fetchProfile` makes a live network call. Inject a closure override so tests run without network:
```swift
// In PublicProfileViewModel — add optional override for testing
var fetchOverride: ((String) async throws -> (String?, String?))? = nil

func fetchProfile(recordID: String) {
    state = .loading
    Task {
        do {
            let result: (displayName: String?, avatarColorHex: String?)
            if let override = fetchOverride {
                let (d, a) = try await override(recordID)
                result = (displayName: d, avatarColorHex: a)
            } else {
                result = try await ProfileSharingService.fetchProfile(recordID: recordID)
            }
            state = .loaded(displayName: result.displayName, avatarColorHex: result.avatarColorHex)
        } catch { /* ... CKError switch ... */ }
    }
}
```

**Async test for state transitions** (matches Swift async testing pattern in NotificationSchedulerTests):
```swift
func test_fetchProfile_success_transitionsToLoaded() async throws {
    sut.fetchOverride = { _ in ("Alice", "#FF8C44") }
    sut.fetchProfile(recordID: "abc123")
    // Drain the Task — wait for state to leave .loading
    try await Task.sleep(nanoseconds: 10_000_000)
    if case .loaded(let name, let hex) = sut.state {
        XCTAssertEqual(name, "Alice")
        XCTAssertEqual(hex, "#FF8C44")
    } else {
        XCTFail("Expected .loaded state, got \(sut.state)")
    }
}

func test_fetchProfile_unknownItem_transitionsToError() async throws {
    sut.fetchOverride = { _ in throw CKError(.unknownItem) }
    sut.fetchProfile(recordID: "gone")
    try await Task.sleep(nanoseconds: 10_000_000)
    if case .error(let msg) = sut.state {
        XCTAssertTrue(msg.contains("no longer available"))
    } else {
        XCTFail("Expected .error state, got \(sut.state)")
    }
}
```

---

## Shared Patterns

### `@MainActor @Observable` ViewModel
**Source:** `ViewModels/ProfileViewModel.swift` lines 11-13
**Apply to:** `PublicProfileViewModel.swift`
```swift
@MainActor
@Observable
final class ProfileViewModel {
```
All ViewModels in this project use this exact declaration. `@MainActor` is required to prevent off-thread SwiftUI state mutations from async Task completions.

### Async CloudKit Task pattern
**Source:** `ViewModels/ProfileViewModel.swift` lines 136-150 (`toggleProfilePublic`)
**Apply to:** `PublicProfileViewModel.fetchProfile`
```swift
Task { @MainActor in
    do {
        let result = try await ProfileSharingService.<method>(...)
        // update @Observable state
    } catch {
        // update error state
    }
}
```

### Sheet trigger via `@Observable` router property
**Source:** `Views/ProfileView.swift` line 35, `Navigation/AppRouter.swift`
**Apply to:** `ContentView.swift` `.sheet` modifier, `AppRouter.swift` new property
```swift
// ProfileView pattern (isPresented):
.sheet(isPresented: $viewModel.showingEditSheet) { ... }

// ContentView new pattern (item: with Identifiable wrapper):
.sheet(item: Binding(
    get: { router.pendingPublicProfileRecordID.map { ProfileDeepLinkItem(id: $0) } },
    set: { _ in router.pendingPublicProfileRecordID = nil }
)) { item in
    PublicProfileView(recordID: item.id)
}
```

### AvatarView reuse
**Source:** `Views/AvatarView.swift` (full file), `Views/ProfileView.swift` lines 48-53
**Apply to:** `PublicProfileView.swift`
```swift
AvatarView(
    displayName: displayName,
    avatarColorHex: avatarColorHex,
    photoData: nil,   // D-02: no photo in public record
    size: 72
)
```

### Visual tone (warm orange accent, rounded font, systemGroupedBackground)
**Source:** `Views/ProfileView.swift` lines 76, 95, 29
**Apply to:** `PublicProfileView.swift`
```swift
.foregroundStyle(Color(red: 0.98, green: 0.55, blue: 0.27))  // warm orange
.font(.title2.weight(.semibold)).fontDesign(.rounded)
.background(Color(UIColor.systemGroupedBackground))
```

### CloudKit container constant
**Source:** `Services/ProfileSharingService.swift` line 8
**Apply to:** Any new CloudKit usage (do not hardcode)
```swift
private static let containerID = "iCloud.com.kyleharrington.VitaminG"
```

### XCTest class structure
**Source:** `VitaminGTests/GoalViewModelTests.swift` lines 1-21
**Apply to:** Both new test files
```swift
import XCTest
@testable import VitaminG

@MainActor
final class <Name>Tests: XCTestCase {
    var sut: <Type>!

    override func setUpWithError() throws { sut = <Type>() }
    override func tearDownWithError() throws { sut = nil }

    // test_<subject>_<condition>_<expectedResult>
}
```

---

## No Analog Found

All 9 files have close analogs in the codebase. No files require falling back to RESEARCH.md patterns exclusively.

---

## Metadata

**Analog search scope:** `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/` (Navigation, Views, ViewModels, Services) and `VitaminGTests/`
**Files scanned:** 10 source files, 7 test files
**Pattern extraction date:** 2026-04-19
