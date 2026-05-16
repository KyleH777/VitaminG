# Phase 1: Foundation - Research

**Researched:** 2026-04-03
**Domain:** SwiftData + CloudKit + App Groups + MVVM (iOS 17+)
**Confidence:** MEDIUM-HIGH (high on API shapes; medium on cloudKitDatabase + groupContainer coexistence — physical-device gate required)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Bundle ID: `com.kyleharrington.VitaminG`
- **D-02:** App Display Name: "Vitamin G"
- **D-03:** App Group identifier: `group.com.kyleharrington.VitaminG`
- **D-04:** `.xcodeproj` lives at `Desktop/AI/Vitamin G/VitaminG.xcodeproj`
- **D-05:** Source files organized under `VitaminG/` (main target) and `VitaminGWidget/` (widget stub target)
- **D-06:** Widget target is scaffolded in Phase 1 with App Group entitlement but zero widget code — this prevents the store path change that would occur if App Group were retrofitted in Phase 4
- **D-07:** All ViewModels use `@Observable` macro (iOS 17+) — no `ObservableObject` / `@Published`
- **D-08:** Phase 1 includes a `NavigationStack` routing layer: an `AppRoute` enum + `AppRouter` observable class, so Phase 2 views have a navigation contract to build against
- **D-09:** Zero business logic in Views — enforced from the first line of code
- **D-10:** All `Goal` and `CompletionEvent` properties are optional or have defaults (CloudKit requirement)
- **D-11:** `VersionedSchema` declared from day one as `SchemaV1` — no unversioned schema ships
- **D-12:** No `@Attribute(.unique)` on any property — CloudKit does not support atomic uniqueness
- **D-13:** `ModelContainer` uses `groupContainer: .identifier("group.com.kyleharrington.VitaminG")` + `cloudKitDatabase: .automatic`
- **D-14:** Validation enforced in `GoalViewModel` before any SwiftData insert: title max 100 chars non-empty, description max 500 chars, associatedInspiration max 300 chars
- **D-15:** Sanitization strips control characters and normalises whitespace before validation

### Claude's Discretion

- File naming and folder structure within targets (follow Xcode defaults)
- `#if DEBUG` CloudKit schema initialization call verbosity
- Error type design for validation failures
- `AppRoute` enum cases (can be empty stubs in Phase 1 — Phase 2 fills them in)

### Deferred Ideas (OUT OF SCOPE)

- Widget UI and `AppIntentConfiguration` — Phase 4
- Navigation routes for all screens — Phase 1 creates the `AppRoute` enum stub; Phase 2 adds cases as views are built
- Onboarding flow — Phase 5
- CloudKit schema promotion to Production — Phase 6
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FOUND-01 | MVVM architecture — zero business logic in Views, all state in `@Observable` ViewModels | @Observable pattern, GoalViewModel design, ViewModel-layer validation |
| FOUND-02 | SwiftData `Goal` model with UUID id, optional String properties, String? tier, Bool isCompleted, Date?, String? associatedInspiration — all optional for CloudKit | CloudKit property rules, model declaration pattern |
| FOUND-03 | `Goal` model uses `VersionedSchema` from day one — no unversioned schema ships | VersionedSchema/SchemaV1 declaration pattern |
| FOUND-04 | `CompletionEvent` model: UUID id, UUID goalID, String? tier, Date? completedAt — CloudKit-compatible | Same CloudKit property rules; no @Relationship needed in Phase 1 |
| FOUND-05 | App Group entitlement configured on both targets (`group.com.kyleharrington.VitaminG`) | App Group setup steps, Signing & Capabilities, entitlements file |
| FOUND-06 | `ModelContainer` uses `groupContainer: .identifier(...)` + `cloudKitDatabase: .automatic` from Phase 1 | ModelConfiguration initializer API, coexistence pattern |
| FOUND-07 | All String inputs validated at model layer: title max 100, description max 500, associatedInspiration max 300 — enforced before SwiftData insert | ViewModel validation pattern, Result/error enum design |
</phase_requirements>

---

## Summary

Phase 1 establishes the permanent data foundation for Vitamin G: SwiftData models declared with `VersionedSchema` from the first commit, a `ModelContainer` that writes to a shared App Group container and mirrors to CloudKit, and an `@Observable` MVVM scaffold the rest of the phases build on. All decisions that cannot be changed after users have data — model schema shape, App Group identifier, CloudKit enablement, VersionedSchema — must be correct here.

The highest-risk item is the combination of `groupContainer: .identifier(...)` and `cloudKitDatabase: .automatic` in a single `ModelConfiguration`. Apple's documentation confirms both parameters exist on the initializer; community reports confirm developers use this combination successfully, but also report it is sensitive to entitlement mismatches, missing CloudKit container IDs, and iOS version differences. The plan must include a physical-device smoke test as a hard gate before Phase 2 begins.

The `@Query` property wrapper can only live in SwiftUI Views — it cannot be moved into a ViewModel. The correct MVVM pattern for SwiftData is to perform `@Query`-equivalent fetches imperatively via `modelContext.fetch(FetchDescriptor)` inside the ViewModel, and to pass `ModelContext` into the ViewModel via initializer. Views use `@Query` for display-only reactive lists; ViewModels own all mutation and validation logic. For Phase 1 the ViewModels need only the insert + validate path, not a full query layer.

SwiftData's `VersionedSchema` pattern is straightforward for a v1 greenfield project: declare `SchemaV1` as an enum conforming to `VersionedSchema`, list model types in `models`, set `versionIdentifier`. No migration plan is needed in Phase 1 — migration plans only come into play when a SchemaV2 is added. Critically, if CloudKit sync is active, only lightweight migration is supported; custom migration plans are incompatible with `cloudKitDatabase: .automatic`. Declaring VersionedSchema now without a migration plan is safe and correct.

**Primary recommendation:** Declare models in `SchemaV1`, set all properties optional/defaulted, configure `ModelContainer` with both `groupContainer` + `cloudKitDatabase`, add the `#if DEBUG` `initializeCloudKitSchema` call, then gate Phase 2 on a passing physical-device smoke test.

---

## Standard Stack

### Core

| Framework / Tool | Version / iOS Min | Purpose | Why Standard |
|------------------|-------------------|---------|--------------|
| Swift | 6.2 (Swift 5.9+ language mode on Xcode 15+) | Primary language | Required; project minimum |
| SwiftUI | iOS 17+ | App entry point, environment injection | Project minimum; `@Query` integration |
| SwiftData | iOS 17+ | Local persistence, CloudKit sync path | Only Apple-blessed SwiftUI persistence with CloudKit |
| Observation (`@Observable`) | iOS 17+ | ViewModel macro | Replaces ObservableObject; property-level invalidation |
| XCTest | Xcode 15+ | Unit tests for ViewModel validation | Built-in; no third-party needed for Phase 1 |

### Supporting

| Framework / Tool | Purpose | When to Use |
|------------------|---------|-------------|
| CloudKit (via SwiftData) | iCloud sync private DB | Configured in ModelContainer; transparent |
| WidgetKit (stub target only) | Widget extension shell | Phase 1 scaffolds the target only — no widget code |
| Foundation (`CharacterSet`) | Control character stripping in sanitizer | Used in GoalViewModel.sanitize() |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `@Observable` macro | `ObservableObject` + `@Published` | `ObservableObject` causes whole-object invalidation, more boilerplate; CLAUDE.md explicitly forbids it |
| SwiftData | Core Data | SwiftData is the Swift-native successor; CLAUDE.md explicitly forbids Core Data |
| `NavigationStack` | `NavigationView` | `NavigationView` is deprecated iOS 16; CLAUDE.md forbids it |

**Installation:** No package manager. All frameworks are built into the iOS 17+ SDK. No `Package.swift` or third-party dependencies for Phase 1.

---

## Architecture Patterns

### Recommended Project Structure

```
VitaminG.xcodeproj
├── VitaminG/                      # Main app target
│   ├── VitaminGApp.swift          # @main, ModelContainer init, environment injection
│   ├── Models/
│   │   ├── SchemaV1.swift         # VersionedSchema enum, Goal + CompletionEvent inside
│   ├── ViewModels/
│   │   ├── GoalViewModel.swift    # @Observable, validation, insert, modelContext
│   ├── Navigation/
│   │   ├── AppRoute.swift         # AppRoute enum (stub cases in Phase 1)
│   │   ├── AppRouter.swift        # @Observable AppRouter, path: [AppRoute]
│   ├── Persistence/
│   │   └── ModelContainerFactory.swift  # Static makeContainer() for app + tests
│   └── VitaminG.entitlements      # App Groups entitlement
│
├── VitaminGWidget/                # Widget stub target (Phase 1: target only)
│   ├── VitaminGWidgetBundle.swift # @main widget bundle (stub)
│   └── VitaminGWidget.entitlements # App Groups entitlement (same group ID)
│
└── VitaminGTests/
    └── GoalViewModelTests.swift   # Validation tests with in-memory ModelContainer
```

### Pattern 1: VersionedSchema Declaration (SchemaV1)

**What:** Wrap all model types inside a `VersionedSchema`-conforming enum from the first commit. This is permanent infrastructure — it cannot be retrofitted after data exists without a migration.

**When to use:** Always for CloudKit-enabled apps. Required by D-11.

```swift
// Source: https://atomicrobot.com/blog/an-unauthorized-guide-to-swiftdata-migrations/
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Goal.self, CompletionEvent.self]
    }

    @Model
    final class Goal {
        var id: UUID = UUID()
        var title: String?
        var goalDescription: String?  // 'description' shadows NSObject.description — use goalDescription
        var tier: String?             // "immediate" | "shortTerm" | "longTerm" | "lifeGoal"
        var isCompleted: Bool = false
        var creationDate: Date?
        var associatedInspiration: String?

        init() {}
    }

    @Model
    final class CompletionEvent {
        var id: UUID = UUID()
        var goalID: UUID?
        var tier: String?
        var completedAt: Date?

        init() {}
    }
}

// Typealiases make callsites shorter throughout the app
typealias Goal = SchemaV1.Goal
typealias CompletionEvent = SchemaV1.CompletionEvent
```

**CloudKit property rules enforced here:**
- All properties optional (`?`) OR have default values (`= UUID()`, `= false`)
- No `@Attribute(.unique)` anywhere
- No non-optional relationships
- `description` property name avoided — it shadows `NSObject.description` causing subtle bugs

### Pattern 2: ModelContainer Factory with groupContainer + cloudKitDatabase

**What:** Centralise `ModelContainer` creation in a factory function so the same configuration is used by the app entry point and tests can swap in an in-memory variant.

**When to use:** Required by D-13. The factory pattern is especially important because `ModelContainer` init is failable and the configuration must be identical everywhere.

```swift
// Source: Apple Developer Documentation — ModelConfiguration initializer
// https://developer.apple.com/documentation/swiftdata/modelconfiguration/init(_:schema:isstoredinmemoryonly:allowssave:groupcontainer:cloudkitdatabase:)
import SwiftData

enum ModelContainerFactory {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(SchemaV1.models, version: SchemaV1.versionIdentifier)

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: inMemory ? .none : .identifier("group.com.kyleharrington.VitaminG"),
            cloudKitDatabase: inMemory ? .none : .automatic
        )

        return try ModelContainer(for: schema, configurations: config)
    }
}
```

**In app entry point (`VitaminGApp.swift`):**

```swift
@main
struct VitaminGApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainerFactory.makeContainer()

            #if DEBUG
            ModelContainerFactory.initializeCloudKitSchema(container: container)
            #endif
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(AppRouter())
        }
    }
}
```

### Pattern 3: initializeCloudKitSchema in #if DEBUG

**What:** Force CloudKit to register every attribute and relationship in the schema so sync works for all properties — not just properties that have been written at least once.

**Why it matters:** CloudKit's "just-in-time" schema inference only discovers fields when records containing them are first saved. If a field is never written in a test session, it may not sync on other devices. Running `initializeCloudKitSchema` on a physical device once during development guarantees the full schema is registered.

**Implementation:** SwiftData does not expose this API directly. You must drop to Core Data's `NSPersistentCloudKitContainer` temporarily:

```swift
// Source: https://fatbobman.com/en/snippet/resolving-incomplete-icloud-data-sync-in-ios-development-using-initializecloudkitschema/
#if DEBUG
import CoreData
import SwiftData

extension ModelContainerFactory {
    static func initializeCloudKitSchema(container: ModelContainer) {
        do {
            // Mirror the store URL from the SwiftData container
            guard let storeURL = container.configurations.first?.url else { return }

            let desc = NSPersistentStoreDescription(url: storeURL)
            let opts = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.kyleharrington.VitaminG"
            )
            desc.cloudKitContainerOptions = opts
            desc.shouldAddStoreAsynchronously = false  // Required — schema init must be synchronous

            if let mom = NSManagedObjectModel.makeManagedObjectModel(
                for: [Goal.self, CompletionEvent.self]
            ) {
                let ckContainer = NSPersistentCloudKitContainer(
                    name: "VitaminG",
                    managedObjectModel: mom
                )
                ckContainer.persistentStoreDescriptions = [desc]
                ckContainer.loadPersistentStores { _, error in
                    if let error { print("Schema init load error: \(error)") }
                }
                try ckContainer.initializeCloudKitSchema()
                // Remove store to avoid double-open with SwiftData
                if let store = ckContainer.persistentStoreCoordinator.persistentStores.first {
                    try ckContainer.persistentStoreCoordinator.remove(store)
                }
                print("[DEBUG] initializeCloudKitSchema completed successfully")
            }
        } catch {
            print("[DEBUG] initializeCloudKitSchema error: \(error)")
            // Non-fatal in DEBUG — log and continue
        }
    }
}
#endif
```

**Call once** during development until CloudKit console shows all attributes. Comment out afterwards (or leave guarded by `#if DEBUG` — it is slow but harmless).

### Pattern 4: @Observable ViewModel with ModelContext Injection

**What:** The `@Query` macro only works inside SwiftUI Views. ViewModels receive `ModelContext` via initializer and use `modelContext.fetch(FetchDescriptor)` for imperative queries. Views own the `@Query` binding for reactive list display; ViewModels own mutation and validation.

**When to use:** Every ViewModel that performs SwiftData inserts/deletes (D-07, D-09).

```swift
// Source: https://developer.apple.com/forums/thread/787918
import SwiftData
import Observation

@Observable
final class GoalViewModel {
    private let modelContext: ModelContext

    // Validation state — exposed to View for error display
    var validationError: GoalValidationError?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func createGoal(
        title: String,
        description: String?,
        tier: String?,
        inspiration: String?
    ) throws {
        let sanitizedTitle = sanitize(title)
        let sanitizedDescription = description.map { sanitize($0) }
        let sanitizedInspiration = inspiration.map { sanitize($0) }

        try validate(
            title: sanitizedTitle,
            description: sanitizedDescription,
            inspiration: sanitizedInspiration
        )

        let goal = Goal()
        goal.title = sanitizedTitle
        goal.goalDescription = sanitizedDescription
        goal.tier = tier
        goal.creationDate = Date()
        goal.associatedInspiration = sanitizedInspiration

        modelContext.insert(goal)
        // modelContext.autosaveEnabled defaults to true — explicit save only needed in tests
    }

    // MARK: - Validation (D-14, D-15, FOUND-07)

    private func validate(
        title: String,
        description: String?,
        inspiration: String?
    ) throws {
        guard !title.isEmpty else {
            throw GoalValidationError.titleEmpty
        }
        guard title.count <= 100 else {
            throw GoalValidationError.titleTooLong
        }
        if let desc = description, desc.count > 500 {
            throw GoalValidationError.descriptionTooLong
        }
        if let insp = inspiration, insp.count > 300 {
            throw GoalValidationError.inspirationTooLong
        }
    }

    // MARK: - Sanitization (D-15)

    private func sanitize(_ input: String) -> String {
        // Strip control characters (ASCII 0-31 except tab/newline, and 127+)
        let stripped = input.unicodeScalars
            .filter { scalar in
                let value = scalar.value
                // Allow tab (9), newline (10), carriage return (13)
                if value == 9 || value == 10 || value == 13 { return true }
                // Strip other C0 controls (0-31) and DEL (127)
                if value < 32 || value == 127 { return false }
                return true
            }
        let result = String(String.UnicodeScalarView(stripped))
        // Normalise whitespace: collapse runs of spaces/tabs to single space
        return result.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Validation Error Type

enum GoalValidationError: LocalizedError, Equatable {
    case titleEmpty
    case titleTooLong        // > 100 chars
    case descriptionTooLong  // > 500 chars
    case inspirationTooLong  // > 300 chars

    var errorDescription: String? {
        switch self {
        case .titleEmpty:        return "Title cannot be empty."
        case .titleTooLong:      return "Title must be 100 characters or fewer."
        case .descriptionTooLong: return "Description must be 500 characters or fewer."
        case .inspirationTooLong: return "Inspiration must be 300 characters or fewer."
        }
    }
}
```

### Pattern 5: AppRoute + AppRouter Navigation Scaffold

**What:** Type-safe routing layer using `NavigationStack` + a `Hashable` route enum + an `@Observable` router class. Phase 1 declares the enum with no cases (empty stub); Phase 2 adds cases as views are built. The router is injected into the environment so any view can navigate without coupling.

```swift
// Source: https://azamsharp.com/2024/07/29/navigation-patterns-in-swiftui.html
import SwiftUI
import Observation

// Phase 1: empty stub — Phase 2 adds cases
enum AppRoute: Hashable {
    // e.g. case goalList, goalDetail(Goal), createGoal
}

@Observable
final class AppRouter {
    var path: [AppRoute] = []

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func pop() {
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
```

**Usage in root ContentView (Phase 1 stub):**

```swift
struct ContentView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            // Phase 1: placeholder
            Text("Vitamin G")
                .navigationDestination(for: AppRoute.self) { route in
                    // Phase 2 fills this in
                    EmptyView()
                }
        }
    }
}
```

### Pattern 6: App Group Entitlements Setup

**What:** Both targets need the same App Group entitlement before any data is persisted. Adding App Group after data exists changes the SQLite store path, causing data loss.

**Steps (must be done in Xcode, not code):**
1. Select `VitaminG` target → Signing & Capabilities → `+ Capability` → App Groups
2. Add group: `group.com.kyleharrington.VitaminG`
3. Xcode creates `VitaminG.entitlements` with `com.apple.security.application-groups` = `["group.com.kyleharrington.VitaminG"]`
4. Repeat for `VitaminGWidget` target — must use **exactly the same group identifier**
5. Verify both targets have the same group ID in their respective `.entitlements` files

**CloudKit container entitlement** (for `cloudKitDatabase: .automatic`):
- Xcode adds `iCloud` capability on `VitaminG` target → check "CloudKit" → use container `iCloud.com.kyleharrington.VitaminG`
- This adds `com.apple.developer.icloud-container-identifiers` to the entitlements
- Widget target does NOT need iCloud capability (widgets are read-only via App Group)

### Pattern 7: XCTest Validation Unit Tests

**What:** Use an in-memory `ModelContainer` to unit-test ViewModel validation without touching disk or CloudKit.

```swift
// Source: https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code
import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class GoalViewModelTests: XCTestCase {
    var container: ModelContainer!
    var sut: GoalViewModel!

    override func setUpWithError() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        sut = GoalViewModel(modelContext: container.mainContext)
    }

    override func tearDownWithError() throws {
        sut = nil
        container = nil
    }

    func test_createGoal_titleTooLong_throwsError() throws {
        let longTitle = String(repeating: "a", count: 101)
        XCTAssertThrowsError(
            try sut.createGoal(title: longTitle, description: nil, tier: nil, inspiration: nil)
        ) { error in
            XCTAssertEqual(error as? GoalValidationError, .titleTooLong)
        }
    }

    func test_createGoal_emptyTitle_throwsError() throws {
        XCTAssertThrowsError(
            try sut.createGoal(title: "   ", description: nil, tier: nil, inspiration: nil)
        ) { error in
            XCTAssertEqual(error as? GoalValidationError, .titleEmpty)
        }
    }

    func test_createGoal_validInputs_persistsGoal() throws {
        try sut.createGoal(
            title: "Run a marathon",
            description: "Complete my first 26.2 miles",
            tier: "shortTerm",
            inspiration: nil
        )
        let goals = try container.mainContext.fetch(FetchDescriptor<Goal>())
        XCTAssertEqual(goals.count, 1)
        XCTAssertEqual(goals.first?.title, "Run a marathon")
    }

    func test_createGoal_descriptionTooLong_throwsError() throws {
        let longDesc = String(repeating: "x", count: 501)
        XCTAssertThrowsError(
            try sut.createGoal(title: "Valid", description: longDesc, tier: nil, inspiration: nil)
        )
    }

    func test_createGoal_inspirationTooLong_throwsError() throws {
        let longInsp = String(repeating: "y", count: 301)
        XCTAssertThrowsError(
            try sut.createGoal(title: "Valid", description: nil, tier: nil, inspiration: longInsp)
        )
    }

    func test_sanitize_stripsControlCharacters() throws {
        // Title with embedded NUL and BEL characters
        let dirtyTitle = "My\u{00}Goal\u{07}Title"
        try sut.createGoal(title: dirtyTitle, description: nil, tier: nil, inspiration: nil)
        let goals = try container.mainContext.fetch(FetchDescriptor<Goal>())
        XCTAssertEqual(goals.first?.title, "My Goal Title")
    }
}
```

### Anti-Patterns to Avoid

- **Non-optional properties without defaults:** Any `@Model` property that is `let name: String` (non-optional, no default) will silently break CloudKit sync. Every property must be `var name: String?` or `var name: String = ""`.
- **`@Attribute(.unique)` on any CloudKit-synced model:** CloudKit cannot enforce uniqueness atomically across devices. Using this attribute causes sync failures. Use application-level duplicate detection instead.
- **`description` as a property name:** Shadows `NSObject.description` on SwiftData models and causes compiler warnings or runtime issues. Use `goalDescription` instead.
- **Business logic in Views:** Never put validation, persistence calls, or domain logic in a `View` struct. Views only bind to ViewModel state.
- **`ObservableObject` / `@Published`:** CLAUDE.md forbids these. Use `@Observable` macro exclusively.
- **Retrofitting App Group after data exists:** Changes the SQLite store path. Data in the old location is abandoned. Must be configured before the first launch.
- **Using `SchemaMigrationPlan` with CloudKit enabled:** Custom migration is incompatible with `cloudKitDatabase: .automatic`. Only lightweight migration (adding optional properties) is allowed when CloudKit sync is active.
- **Using `.modelContext` environment key on iOS 18 in shared context scenarios:** A known iOS 18 bug prevents auto-save when using `.modelContext`. Use `.modelContainer` on the root Scene and let SwiftData create the main context.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CloudKit schema sync | Manual CKRecord mapping | `cloudKitDatabase: .automatic` in `ModelConfiguration` | SwiftData handles the mapping layer, conflict resolution, and merge policies |
| Model versioning | Custom version tracking | `VersionedSchema` + `SchemaMigrationPlan` | Built-in migration infrastructure handles lightweight migrations automatically |
| Observable state management | Manual publishers/callbacks | `@Observable` macro | Property-level dependency tracking, no `@Published` needed |
| Navigation state | Global `NavigationController` wrapper | `NavigationStack(path:)` + `AppRouter` | Type-safe, testable, SwiftUI-native |
| Input sanitisation library | Third-party validators | `CharacterSet` + `String` APIs | Foundation covers the needs here — no third-party needed |
| In-memory test store | Custom mock persistence layer | `ModelConfiguration(isStoredInMemoryOnly: true)` | SwiftData built-in; no seams to maintain |

**Key insight:** SwiftData + CloudKit eliminates the entire sync/conflict/merge problem space. The cost is strict schema constraints (all optional). Paying that cost in Phase 1 unlocks transparent multi-device sync for free in Phase 4.

---

## Common Pitfalls

### Pitfall 1: App Group Identifier Mismatch

**What goes wrong:** Main app uses `group.com.kyleharrington.VitaminG` but widget target has a typo or different capitalisation. App writes to one container; widget reads from a different (empty) one.

**Why it happens:** Xcode does not validate that extension entitlements match app entitlements at build time.

**How to avoid:** After setting up both targets, `diff` the two `.entitlements` files and confirm the group ID string is byte-for-byte identical.

**Warning signs:** Widget shows stale or empty data even after the main app writes goals.

---

### Pitfall 2: cloudKitDatabase + groupContainer Coexistence Sensitivity

**What goes wrong:** App crashes at launch with `NSPersistentStore` errors, or CloudKit sync silently fails, when both `groupContainer: .identifier(...)` and `cloudKitDatabase: .automatic` are set.

**Why it happens:** `cloudKitDatabase: .automatic` reads the iCloud container identifier from the app's entitlements. If the CloudKit entitlement is missing (iCloud capability not added), or the container doesn't exist in the CloudKit console, the init fails. Additionally, on some iOS 17.x betas there were crashes related to this combination.

**How to avoid:**
- Add iCloud capability to the main app target **before** running on a physical device
- Create (or confirm existence of) the `iCloud.com.kyleharrington.VitaminG` container in the CloudKit console
- Test on physical device — Simulator may not reproduce the failure
- Keep `ModelContainerFactory.makeContainer(inMemory: true)` available for unit tests (skips both GroupContainer and CloudKit)

**Warning signs:** `fatalError("Could not create ModelContainer")` at launch; no CloudKit records appearing in CloudKit console dashboard.

---

### Pitfall 3: Non-Optional Properties Break CloudKit Sync Silently

**What goes wrong:** A `@Model` property is declared `var name: String` (non-optional, no default). The app works on-device but records never sync to other devices.

**Why it happens:** CloudKit requires all record fields to be nullable. SwiftData with a non-optional, non-defaulted property generates a schema that CloudKit cannot represent; sync is silently disabled for affected records or the entire container.

**How to avoid:** Every property is either `var name: String?` or `var name: String = "default"`. Review all models before first run.

**Warning signs:** Records present on device 1, absent on device 2, no errors shown.

---

### Pitfall 4: description Property Name Conflict

**What goes wrong:** A `@Model` property named `description` shadows `NSObject.description` and causes compiler warnings or subtle runtime issues.

**Why it happens:** `@Model` macro generates a class; `NSObject.description` is an inherited property.

**How to avoid:** Name the property `goalDescription` in code. The CloudKit attribute name (as stored) is independent — CloudKit will store it as `goalDescription` which is fine.

**Warning signs:** Compiler warning "declaration 'description' is incompatible with protocol requirement".

---

### Pitfall 5: @Query Cannot Live in ViewModel

**What goes wrong:** Developer puts `@Query var goals: [Goal]` inside the `@Observable` GoalViewModel. This causes a compile error: `@Query` requires a SwiftUI View context.

**Why it happens:** `@Query` uses the SwiftUI environment to access the model context and register view invalidation.

**How to avoid:** In Phase 1, ViewModels only *write* (insert). For Phase 2's read path, ViewModels use `modelContext.fetch(FetchDescriptor<Goal>())` for imperative queries, and Views use `@Query` for reactive display lists. These two approaches are complementary, not competing.

**Warning signs:** Compile error mentioning `@Query` outside a View.

---

### Pitfall 6: Custom Migration Plan Incompatible with CloudKit

**What goes wrong:** In a future phase, a `SchemaMigrationPlan` is added along with `cloudKitDatabase: .automatic`. The `willMigrate`/`didMigrate` closures are never called, and in some cases the container fails to initialize.

**Why it happens:** CloudKit's underlying Core Data stack only supports lightweight migration. Custom migration plans bypass the CloudKit merge process.

**How to avoid:** When the schema needs to change in a future phase, only add new **optional** properties (lightweight migration). Never rename, remove, or change property types on a CloudKit-synced model.

**Warning signs:** Migration stage callbacks not firing; Apple Developer Forums thread 742899 documents this.

---

### Pitfall 7: iOS 18 .modelContext Environment Key Bug

**What goes wrong:** On iOS 18.0/18.1, passing a `ModelContext` via `.modelContext(ctx)` on a scene or view results in auto-save not working reliably. New inserts do not persist across relaunches.

**Why it happens:** iOS 18 regression in the `modelContext` environment key handling.

**How to avoid:** Use `.modelContainer(container)` on the `WindowGroup` scene and let SwiftData derive `mainContext` automatically. Do not pass a pre-created context via `.modelContext`. This is the correct pattern anyway.

**Warning signs:** Data visible in a session disappears after app relaunch.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17 / WWDC 2023 | Property-level invalidation; no `@Published` annotations needed |
| `NavigationView` | `NavigationStack(path:)` | iOS 16 | Programmatic navigation, type-safe route enum |
| Core Data + NSPersistentCloudKitContainer | SwiftData + `cloudKitDatabase: .automatic` | iOS 17 | Declarative model layer; eliminates boilerplate |
| Unversioned SwiftData schema | `VersionedSchema` from day one | iOS 17 best practice | Safe migrations; no data loss risk |
| `IntentConfiguration` for widgets | `AppIntentConfiguration` | iOS 17 | Required for interactive widgets (Phase 4) |

**Deprecated / outdated:**
- `NavigationView`: Deprecated iOS 16, removal expected. CLAUDE.md forbids.
- `ObservableObject` / `@Published`: Superseded by `@Observable` for iOS 17+. CLAUDE.md forbids.
- SiriKit Intents extension for widget configuration: Replaced by App Intents. Not applicable in Phase 1.

---

## Open Questions

1. **initializeCloudKitSchema store URL access**
   - What we know: The `NSPersistentCloudKitContainer`-based approach requires the SQLite store URL from the SwiftData container. `container.configurations.first?.url` returns it when `groupContainer` is set.
   - What's unclear: Whether `container.configurations.first?.url` reliably returns the correct App Group path at init time, or whether it needs to be fetched after first insert.
   - Recommendation: Log the URL during the DEBUG call and verify it points to the App Group path (`/private/var/.../group.com.kyleharrington.VitaminG/...`). If nil, pass the URL constructed via `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`.

2. **Widget target needs CloudKit entitlement?**
   - What we know: The widget target reads from the shared App Group store (local SQLite). CloudKit sync is handled by the main app process. Widget does not need `cloudKitDatabase: .automatic`.
   - What's unclear: Whether the widget's `ModelConfiguration` should also specify `.cloudKitDatabase: .none` explicitly or simply omit the parameter (which defaults to `.none`).
   - Recommendation: Widget uses `ModelConfiguration(schema: schema, groupContainer: .identifier("group.com.kyleharrington.VitaminG"), cloudKitDatabase: .none)`. No iCloud capability needed on widget target.

3. **Swift 6 concurrency and @Observable on main thread**
   - What we know: Swift 6.2 (detected on this machine) introduces strict concurrency checking. `@Observable` ViewModels must be `@MainActor`-isolated if they touch `ModelContext` (which is not `Sendable`).
   - What's unclear: Whether Xcode's current language mode for this project is Swift 5 or Swift 6 concurrency checking.
   - Recommendation: Mark `GoalViewModel` as `@MainActor` from the start. This ensures `ModelContext` access is always on the main actor and eliminates concurrency warnings.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Xcode (full IDE) | Building iOS app, signing, entitlements, Simulator | **Not found** | — | None — must install Xcode to proceed |
| Swift compiler | Compiling Swift source | Partial (CLT only) | 6.2.4 | Full Xcode required for iOS builds |
| Physical iOS device | CloudKit + App Group smoke test (hard gate for Phase 2) | Unknown | — | Cannot be replaced — Simulator is unreliable for CloudKit and App Group filesystem |
| CloudKit container | `cloudKitDatabase: .automatic` at runtime | Unknown — must be created in CloudKit console | — | Development container auto-creates on first push but must be verified |
| Apple Developer account | Signing, CloudKit, App Group provisioning | Unknown | — | Required for physical device testing |

**Missing dependencies with no fallback:**
- **Xcode**: The Swift command-line tools are present but Xcode IDE is not installed. All iOS development (project creation, UI canvas, Simulator, signing) requires the full Xcode application. This must be installed before Phase 1 implementation begins.
- **Physical iOS device**: The cloudKitDatabase + groupContainer coexistence smoke test (Phase 1 success criterion 2) requires a physical device. Simulator does not reliably reproduce App Group filesystem access issues or CloudKit entitlement errors.

**Missing dependencies with fallback:**
- CloudKit container existence: Will be auto-created by CloudKit when the app first runs in Development mode, but the developer must sign in with an iCloud account on the test device. Document the container ID `iCloud.com.kyleharrington.VitaminG` and verify it appears in CloudKit console after first run.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (built into Xcode) |
| Config file | None — uses default Xcode test target |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Full suite command | Same as above (Phase 1 test suite is small; single command covers all) |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FOUND-01 | Zero business logic in Views — all in GoalViewModel | Code review / unit | N/A (architectural) | — |
| FOUND-02 | Goal model persists and reads back — all properties optional | Unit | `xcodebuild test -scheme VitaminG` | Wave 0 |
| FOUND-03 | Goal uses SchemaV1 VersionedSchema | Unit (compile + runtime check) | `xcodebuild test -scheme VitaminG` | Wave 0 |
| FOUND-04 | CompletionEvent persists and reads back | Unit | `xcodebuild test -scheme VitaminG` | Wave 0 |
| FOUND-05 | App Group entitlement present on both targets | Manual (Xcode Signing & Capabilities) | N/A | — |
| FOUND-06 | ModelContainer launches without error on physical device | Smoke test (physical device) | Manual | — |
| FOUND-07 | Validation rejects oversized inputs before insert | Unit | `xcodebuild test -scheme VitaminG` | Wave 0 |

### Sampling Rate

- **Per task commit:** Run unit test suite via `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- **Per wave merge:** Full suite + physical device smoke test for FOUND-06
- **Phase gate:** All unit tests green + physical device smoke test passing before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `VitaminGTests/GoalViewModelTests.swift` — covers FOUND-02, FOUND-03, FOUND-04, FOUND-07 (validation scenarios)
- [ ] `VitaminGTests/SchemaV1Tests.swift` — confirms VersionedSchema declaration compiles and model types are included
- [ ] `VitaminG/Persistence/ModelContainerFactory.swift` — shared factory used by both app and test suite

*(No existing test infrastructure — greenfield project. Full test scaffolding is a Wave 0 task.)*

---

## Project Constraints (from CLAUDE.md)

The following directives from `CLAUDE.md` (Vitamin G) are mandatory and override any research recommendations that contradict them:

| Directive | Source | Constraint |
|-----------|--------|------------|
| No third-party dependencies unless necessary | CLAUDE.md §Constraints | Phase 1 uses zero external packages |
| iOS 17+ minimum | CLAUDE.md §Constraints | No back-deployment; no `#available` guards for SwiftData/`@Observable` |
| MVVM strictly enforced — no business logic in Views | CLAUDE.md §Constraints | All validation, persistence in ViewModels |
| All String inputs must have strict character limits and validation | CLAUDE.md §Constraints | Enforced in GoalViewModel before insert (D-14, D-15) |
| Local SwiftData storage must be treated as untrusted input boundary | CLAUDE.md §Constraints | Sanitisation strips control characters on write |
| Do not use `ObservableObject` / `@Published` | CLAUDE.md §What NOT to Use | `@Observable` macro only |
| Do not use `NavigationView` | CLAUDE.md §What NOT to Use | `NavigationStack` only |
| Do not use `@Attribute(.unique)` on CloudKit-synced properties | CLAUDE.md §What NOT to Use | Prohibited on Goal and CompletionEvent |
| Do not use Core Data | CLAUDE.md §What NOT to Use | SwiftData only (except the DEBUG `initializeCloudKitSchema` helper which is a one-time dev tool) |
| Do not use Firebase / non-Apple sync | CLAUDE.md §What NOT to Use | CloudKit via SwiftData only |
| GSD workflow enforcement | CLAUDE.md §GSD Workflow | Use `/gsd:execute-phase` for all phase work — no direct repo edits outside GSD |

---

## Sources

### Primary (HIGH confidence)

- Apple Developer Documentation — `ModelConfiguration.GroupContainer` — https://developer.apple.com/documentation/swiftdata/modelconfiguration/groupcontainer-swift.struct
- Apple Developer Documentation — `ModelConfiguration` init with groupContainer + cloudKitDatabase — https://developer.apple.com/documentation/swiftdata/modelconfiguration/init(_:schema:isstoredinmemoryonly:allowssave:groupcontainer:cloudkitdatabase:)
- Apple Developer Documentation — `ModelConfiguration.CloudKitDatabase.automatic` — https://developer.apple.com/documentation/swiftdata/modelconfiguration/cloudkitdatabase-swift.struct/automatic
- fatbobman — initializeCloudKitSchema for SwiftData — https://fatbobman.com/en/snippet/resolving-incomplete-icloud-data-sync-in-ios-development-using-initializecloudkitschema/
- fatbobman — Key considerations before using SwiftData — https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/

### Secondary (MEDIUM confidence)

- Atomic Robot — Unauthorized Guide to SwiftData Migrations (VersionedSchema pattern verified against Apple docs) — https://atomicrobot.com/blog/an-unauthorized-guide-to-swiftdata-migrations/
- Medium / Rishabh Sharma — SwiftData with Widgets in SwiftUI (App Group setup steps) — https://medium.com/@rishixcode/swiftdata-with-widgets-in-swiftui-0aab327a35d8
- Apple Developer Forums thread 742899 — SwiftData+CloudKit migration incompatibility (custom migration + CloudKit) — https://developer.apple.com/forums/thread/742899
- Apple Developer Forums thread 763056 — SwiftData .modelContext iOS 18 auto-save bug — https://developer.apple.com/forums/thread/763056
- AzamSharp — Navigation patterns in SwiftUI 2024 — https://azamsharp.com/2024/07/29/navigation-patterns-in-swiftui.html

### Tertiary (LOW confidence — flag for validation)

- Apple Developer Forums thread 744183 — SwiftData+CloudKit+AppGroups error (page rendered as forum homepage; content not extracted) — https://developer.apple.com/forums/thread/744183
- Hacking with Swift — SwiftData unit test patterns (403 on fetch) — https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code
  - Pattern described is consistent with multiple other sources; HIGH confidence in pattern itself despite fetch failure

---

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — All frameworks are Apple first-party on iOS 17+; no version uncertainty
- SwiftData model patterns: HIGH — Verified against Apple docs and multiple independent sources
- VersionedSchema SchemaV1: HIGH — Pattern verified via atomic robot article + Apple docs
- ModelContainer groupContainer + cloudKitDatabase coexistence: MEDIUM — API confirmed in Apple docs; runtime behaviour confirmed to be sensitive to entitlement setup; physical device gate mandatory
- initializeCloudKitSchema: MEDIUM-HIGH — Verified pattern from fatbobman (authoritative SwiftData blogger) + Apple Developer Forums threads
- MVVM + @Observable: HIGH — Apple's own WWDC23 recommendation; @Query-in-ViewModel limitation is well-documented
- Validation pattern: HIGH — Straightforward Swift; no framework dependency
- iOS 18 .modelContext bug: MEDIUM — Multiple Apple Developer Forum reports; workaround (use .modelContainer) is the canonical pattern anyway

**Research date:** 2026-04-03
**Valid until:** 2026-07-03 (stable APIs; 90-day window; re-verify if iOS 18.x or Xcode 16.x releases change SwiftData behaviour)
