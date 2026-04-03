# Architecture Research: Vitamin G

**Domain:** iOS goal-tracking / habit app (SwiftUI + SwiftData + CloudKit + WidgetKit)
**Researched:** 2026-04-03
**Overall confidence:** HIGH (primary claims verified against Apple Developer Documentation, Hacking with Swift SwiftData by Example, and Apple Developer Forums)

---

## Component Map

### Main App Process

| Component | Role | Technology |
|-----------|------|------------|
| `VitaminGApp` | Entry point; owns and injects `ModelContainer` | SwiftUI `@main`, `.modelContainer()` |
| `SharedModelContainer` | Singleton that builds the one true `ModelContainer` for both app and widget | SwiftData `ModelContainer`, `ModelConfiguration` |
| `Goal` (`@Model`) | Persisted entity: id, title, description, tier, isCompleted, creationDate, inspiration | SwiftData `@Model` |
| `GoalTier` (enum) | Immediate / ShortTerm / LongTerm / LifeGoal — stored as raw `String` for CloudKit compat | Swift enum : String |
| `GoalListView` | Root view per tier; owns `@Query` for that tier's goals | SwiftUI View + `@Query` |
| `GoalDetailView` | Shows one goal; binds to `Goal` instance from parent query | SwiftUI View |
| `GoalFormView` | Add / edit form; all user input funneled through `GoalFormViewModel` | SwiftUI View |
| `GoalFormViewModel` | Validation, dirty-state, save logic; holds `ModelContext` reference | `@Observable` final class |
| `GoalListViewModel` | Tier-scoped operations: delete, reorder, completion toggle | `@Observable` final class |
| `StatsViewModel` | Computes streak and completion rate from `@Query` results passed in | `@Observable` final class |
| `NotificationScheduler` | Schedules / reschedules the single daily morning notification | `UNUserNotificationCenter` |
| `NotificationPermissionViewModel` | Requests auth, surfaces permission state to UI | `@Observable` final class |

### Widget Extension Process

| Component | Role | Technology |
|-----------|------|------------|
| `GoalWidgetBundle` | Widget entry point; registers all widget kinds | WidgetKit `@main` |
| `GoalWidget` (home screen) | Shows top active goals summary | `StaticConfiguration` |
| `LockScreenGoalWidget` | Lock screen companion widget | `StaticConfiguration` |
| `GoalWidgetProvider` | Generates `Timeline` entries; queries SwiftData via shared container | `TimelineProvider` |
| `GoalWidgetEntry` | Snapshot of goal data at a point in time (value type) | `TimelineEntry` struct |
| `GoalWidgetEntryView` | Renders the widget UI | SwiftUI View |

### Shared (both targets compile this code)

| Component | Role |
|-----------|------|
| `Goal.swift` | `@Model` definition — must be in both targets' Compile Sources |
| `GoalTier.swift` | Enum — both targets need it |
| `SharedModelContainer.swift` | Builds `ModelContainer` pointing at the App Group store URL |

---

## Data Flow

### Write path (main app only)

```
User input
  → GoalFormView (SwiftUI)
  → GoalFormViewModel.save() [validation happens here]
  → ModelContext.insert(goal) / goal.title = validated value
  → SwiftData persists to shared App Group SQLite store
  → CloudKit background sync daemon picks up change (automatic)
```

### Read path (main app)

```
Shared App Group SQLite store
  ← @Query(filter:, sort:) in GoalListView        [automatic, reactive]
  ← StatsViewModel receives [Goal] from view       [computed properties]
```

### Read path (widget)

```
Shared App Group SQLite store
  ← GoalWidgetProvider.getTimeline()
  → creates GoalWidgetEntry (value-type snapshot)
  → WidgetKit renders GoalWidgetEntryView
```

### Notification path

```
App launch / goal change
  → NotificationScheduler.rescheduleDaily(goals: [Goal])
  → UNUserNotificationCenter removes all pending
  → schedules UNCalendarNotificationTrigger(hour:8, minute:0, repeats:true)
  → system delivers notification
  → user taps → deep link opens main app
```

### CloudKit sync flow

```
Local SwiftData write
  → NSPersistentCloudKitContainer (SwiftData's backing layer) batches changes
  → pushes to iCloud CloudKit private database
  → other devices receive silent push → pull changes
  → SwiftData merges into local store → @Query views update
```

---

## Shared Container Strategy

### Why App Groups are mandatory

The widget extension runs in a separate OS process. By default each process gets its own sandboxed container. Without an App Group, the widget cannot see the main app's SQLite store at all. App Groups create a shared filesystem location both processes can read.

### Configuration pattern

Both targets (main app and widget extension) must:

1. Have the **same App Group** entitlement added in Xcode Signing & Capabilities.
   Identifier convention: `group.com.YOURNAME.vitamingapp`

2. Both targets must compile `Goal.swift`, `GoalTier.swift`, and `SharedModelContainer.swift`
   (add files to both targets' Compile Sources, or extract them into a local Swift Package).

3. `SharedModelContainer.swift` builds the container once:

```swift
// SharedModelContainer.swift
import SwiftData

enum SharedModelContainer {
    static let shared: ModelContainer = {
        let config = ModelConfiguration(
            schema: Schema([Goal.self]),
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.YOURNAME.vitamingapp"),
            cloudKitDatabase: .automatic   // enables iCloud sync
        )
        return try! ModelContainer(for: Goal.self, configurations: config)
    }()
}
```

4. **Main app** injects it at the root:

```swift
@main
struct VitaminGApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(SharedModelContainer.shared)
    }
}
```

5. **Widget** attaches it to its configuration:

```swift
struct GoalWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GoalWidget", provider: GoalWidgetProvider()) { entry in
            GoalWidgetEntryView(entry: entry)
        }
        .modelContainer(SharedModelContainer.shared)
    }
}
```

### CloudKit + App Groups compatibility note

`cloudKitDatabase: .automatic` and `groupContainer: .identifier(...)` can coexist in the same `ModelConfiguration` (MEDIUM confidence — verified by Apple Developer Forums thread 732986 and community implementations, but Apple's official docs describe them as independent parameters). Both parameters are set on `ModelConfiguration` before passing to `ModelContainer`. No conflict has been reported in current iOS 17+ implementations.

### CloudKit model constraints (critical)

SwiftData with CloudKit imposes strict schema rules — plan these from day one or migration becomes painful:

- All `@Model` properties must be **optional or have default values** (no required non-optional non-defaulted properties)
- All relationships must be **optional**
- `@Attribute(.unique)` is **forbidden** on any CloudKit-synced property
- Use computed properties to wrap optionals for cleaner internal API:

```swift
@Model
final class Goal {
    var title: String? = ""          // CloudKit-safe
    var tierRaw: String? = GoalTier.immediate.rawValue
    var isCompleted: Bool = false
    var creationDate: Date = Date()

    // Clean internal API via computed property
    var tier: GoalTier {
        get { GoalTier(rawValue: tierRaw ?? "") ?? .immediate }
        set { tierRaw = newValue.rawValue }
    }
}
```

---

## MVVM Mapping onto SwiftData's @Query Pattern

This is the central architectural tension: `@Query` is a SwiftUI property wrapper that only works inside a `View`. ViewModels do not have access to the SwiftUI environment, so they cannot own `@Query`.

### Resolution: split responsibility at a clear boundary

| Concern | Lives in | Why |
|---------|----------|-----|
| Reactive list data | `@Query` in the **View** | `@Query` requires SwiftUI environment; it IS the single source of truth |
| CRUD operations | **ViewModel** receives `ModelContext` via init | ViewModel performs writes without touching query machinery |
| Validation state | **ViewModel** (`@Observable`) | Pure Swift, fully testable, no SwiftUI dependency |
| Streak / stats computation | **ViewModel** receives `[Goal]` array from view's `@Query` | Computed properties on plain Swift arrays |

### Concrete pattern

```swift
// View owns the query — not a violation of MVVM because @Query is a data binding, not logic
struct GoalListView: View {
    @Query(filter: #Predicate<Goal> { $0.tierRaw == "immediate" },
           sort: \.creationDate)
    private var goals: [Goal]

    @Environment(\.modelContext) private var modelContext
    @State private var vm = GoalListViewModel()

    var body: some View {
        List(goals) { goal in GoalRowView(goal: goal) }
            .onChange(of: goals) { vm.goalsDidChange($0) }   // push array to VM if stats needed
            .toolbar {
                Button("Add") { vm.startAdding() }
            }
    }
}

// ViewModel owns logic — receives ModelContext at creation or via method parameter
@Observable
final class GoalListViewModel {
    private(set) var isAddingGoal = false

    func startAdding() { isAddingGoal = true }

    func delete(_ goal: Goal, in context: ModelContext) {
        context.delete(goal)
    }

    func toggleComplete(_ goal: Goal) {
        goal.isCompleted.toggle()   // @Model properties are observable; change propagates
    }
}
```

### Form ViewModel (validation-heavy)

```swift
@Observable
final class GoalFormViewModel {
    var titleInput: String = ""
    var descriptionInput: String = ""
    var selectedTier: GoalTier = .immediate
    var validationError: String? = nil

    private let maxTitleLength = 100
    private let maxDescriptionLength = 500

    func save(context: ModelContext) throws {
        guard validate() else { return }
        let goal = Goal()
        goal.title = titleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        goal.descriptionText = descriptionInput.trimmingCharacters(in: .whitespacesAndNewlines)
        goal.tier = selectedTier
        context.insert(goal)
    }

    private func validate() -> Bool {
        if titleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "Title is required."
            return false
        }
        if titleInput.count > maxTitleLength {
            validationError = "Title must be \(maxTitleLength) characters or fewer."
            return false
        }
        if descriptionInput.count > maxDescriptionLength {
            validationError = "Description must be \(maxDescriptionLength) characters or fewer."
            return false
        }
        validationError = nil
        return true
    }
}
```

### Input validation placement (decision)

Validation lives **exclusively in the ViewModel layer**, not in the `@Model` itself. Rationale:

- SwiftData's `@Model` can produce opaque Core Data validation errors; surfacing those to users is brittle.
- ViewModels are testable without SwiftUI or a running `ModelContainer`.
- The `@Model` enforces structural constraints (optionals, CloudKit rules); the ViewModel enforces business rules (length limits, non-empty, sanitization).
- The View enforces nothing — it only displays ViewModel-provided error state.

---

## Daily Notification Scheduling

### Architecture decision: scheduled from app, not background

The `NotificationScheduler` is a plain Swift service (no SwiftUI dependency). It is called:

- On first launch (after permission is granted)
- Whenever the user changes their preferred notification time (future feature)
- On every cold launch as a re-registration safety measure (idempotent)

No background processing entitlement is needed. The system delivers the notification without the app being alive.

### Implementation pattern

```swift
// NotificationScheduler.swift
import UserNotifications

struct NotificationScheduler {

    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    /// Call on launch and after goal changes. Removes existing daily and reschedules.
    static func scheduleDailyReminder(hour: Int = 8, minute: Int = 0, activeGoalCount: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-goal-reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Your daily dose of intention"
        content.body = activeGoalCount == 1
            ? "You have 1 active goal. Let's make it happen."
            : "You have \(activeGoalCount) active goals. Let's go."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily-goal-reminder",
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }
}
```

### Permission gating

- Request permission on first meaningful engagement (not on cold launch before the user understands the app).
- Check `UNUserNotificationCenter.current().notificationSettings()` on each launch; if denied, surface a settings deep-link, do not re-request.
- Never request notification permission as a condition of using the app.

---

## Streak and Statistics Architecture

Streak tracking does not require a separate persisted entity for v1. Compute on read from the `Goal` array:

```swift
// StatsViewModel.swift
@Observable
final class StatsViewModel {
    private(set) var completionRate: Double = 0.0
    private(set) var currentStreak: Int = 0  // days in a row with at least one completion

    func update(goals: [Goal]) {
        let total = goals.count
        let completed = goals.filter { $0.isCompleted }.count
        completionRate = total > 0 ? Double(completed) / Double(total) : 0.0
        // Streak: count consecutive days backwards from today where any goal was completed.
        // Requires completionDate on Goal model (add in Phase 2).
        currentStreak = computeStreak(from: goals)
    }
}
```

Note: Accurate streak tracking requires a `completionDate: Date?` field on `Goal`. Add this to the model from day one; retrofitting after CloudKit sync is enabled requires a migration.

---

## Suggested Build Order

Build order is driven by hard dependency chains: you cannot write to a store that doesn't exist, cannot query what hasn't been defined, and cannot share what isn't in an App Group.

### Phase 1 — Foundation (no UI yet)

Establish the load-bearing structure everything else attaches to.

1. Create App Group identifier in Apple Developer Portal; add to both targets.
2. Define `Goal` `@Model` with all fields including CloudKit-compatible optionals.
3. Define `GoalTier` enum.
4. Write `SharedModelContainer` with `groupContainer` and `cloudKitDatabase: .automatic`.
5. Wire `VitaminGApp` to inject `SharedModelContainer.shared`.
6. Enable iCloud + CloudKit capability; add Remote Notifications background mode.
7. Add `Goal.swift` and `GoalTier.swift` to widget target's Compile Sources.

**Why first:** Every other component depends on a working, shared, CloudKit-compatible store. Getting this wrong early means migration pain later.

### Phase 2 — Core CRUD and ViewModel layer

8. Implement `GoalFormViewModel` with full validation.
9. Implement `GoalListViewModel` with delete and toggle.
10. Build `GoalFormView` and `GoalListView` using `@Query`.
11. Build navigation structure (tab per tier or unified list with tier filter — TBD in design phase).
12. Wire `@Environment(\.modelContext)` from root down to views.

**Why second:** UI is worthless without a data layer; this phase proves the MVVM seam works before adding complexity.

### Phase 3 — Statistics and Notifications

13. Add `completionDate: Date?` to `Goal` model (do this before any production CloudKit data exists).
14. Implement `StatsViewModel` streak computation.
15. Build stats UI.
16. Implement `NotificationScheduler`.
17. Implement `NotificationPermissionViewModel` and permission-gating UI.
18. Test notification delivery on device (Simulator is unreliable for this).

**Why third:** Depends on a working CRUD layer; notifications need real goal data to summarize.

### Phase 4 — Widget Extension

19. Add widget target to Xcode project.
20. Add App Group entitlement to widget target.
21. Add `Goal.swift`, `GoalTier.swift`, `SharedModelContainer.swift` to widget target.
22. Implement `GoalWidgetProvider` using `ModelContext` from `SharedModelContainer.shared`.
23. Implement `GoalWidgetEntryView` (read-only — widgets do not write).
24. Implement `LockScreenGoalWidget` variant.
25. Test on physical device (widget rendering on Simulator is unreliable).

**Why fourth:** Requires a stable, finalized model schema. Schema changes after widget ships require careful migration.

### Phase 5 — Polish, Validation Hardening, App Store Prep

26. Audit all `GoalFormViewModel` validation paths.
27. Add `.onChange` limiters in views to prevent validation bypass.
28. Implement settings for notification time preference.
29. Deep-link from notification tap to relevant goal tier.
30. App Store metadata, screenshots, privacy manifest.

---

## Component Dependency Graph

```
Apple Developer Portal (App Group ID)
  └── SharedModelContainer
        ├── VitaminGApp  ──► GoalListView (@Query) ──► GoalListViewModel
        │                                           └── GoalFormView ──► GoalFormViewModel
        │                                           └── StatsView ──► StatsViewModel
        │                    NotificationScheduler (independent, called from App)
        └── GoalWidget ──► GoalWidgetProvider ──► GoalWidgetEntryView
```

Communication rules:
- Views read via `@Query` (reactive, automatic)
- Views write via `ModelContext` passed to ViewModels
- ViewModels never import SwiftUI (exception: `@Observable` requires Foundation/Observation)
- Widget reads only — never writes to the store
- `NotificationScheduler` is stateless; called imperatively, returns async results

---

## Architecture Anti-Patterns to Avoid

### Anti-Pattern 1: Business logic in Views

Putting validation, save logic, or streak computation in View `body` makes it untestable and leaks when views are re-created.

**Prevention:** All logic lives in ViewModel or service types. Views bind to ViewModel-published state only.

### Anti-Pattern 2: @Query in ViewModel

`@Query` silently does nothing outside a SwiftUI View. Developers who try to put `@Query` in an `@Observable` class get stale data with no warning.

**Prevention:** `@Query` stays in Views. ViewModels receive `[Goal]` arrays passed from the View's `@Query` result when they need to compute (e.g., stats).

### Anti-Pattern 3: Building widget before App Group is confirmed working

Widget + App Groups + SwiftData must all be validated together. If App Group is wired wrong, the widget gets an empty store with no error.

**Prevention:** Phase 1 explicitly validates App Group sharing with a debug print of goal count in the widget provider before building any widget UI.

### Anti-Pattern 4: Non-optional @Model properties with CloudKit

Adding a required non-optional property (e.g., `var title: String`) to a CloudKit-synced model will fail sync silently or crash on devices where records arrive before the property.

**Prevention:** All `@Model` properties are optional or have defaults. Computed properties wrap optionals for internal cleanliness.

### Anti-Pattern 5: Scheduling notifications in the background

Attempting to update notification content via BGTaskScheduler or background fetch adds App Review risk and complexity for no benefit. The `UNCalendarNotificationTrigger` with `repeats: true` fires without the app running.

**Prevention:** Schedule once at launch; use `repeats: true`. No background processing needed.

### Anti-Pattern 6: Writing to SwiftData from the widget

WidgetKit view code runs in a sandboxed timeline rendering context. Even though `ModelConfiguration` can be set to `readOnly: false` in the widget, writes from widget views are unreliable and can corrupt the shared store.

**Prevention:** Widgets are read-only consumers. All writes happen in the main app.

---

## Scalability Considerations

| Concern | At 10 goals | At 500 goals | At 5000 goals |
|---------|-------------|--------------|---------------|
| @Query performance | Instant | Fast, no index needed | Add `#Index([\.tier, \.isCompleted])` on @Model |
| Streak computation | In-memory, trivial | In-memory, trivial | May need date-indexed fetch predicate |
| CloudKit sync | Near-instant | Seconds on first sync | Batches fine; no action needed |
| Widget timeline | Instant | Limit to top 3-5 goals in entry | Limit query in provider |
| Notification content | Trivial | Trivial | Trivial (count summary) |

Goal-tracking apps do not reach scale where SwiftData becomes a bottleneck. Focus on correctness over optimization.

---

## Sources

- [How to access a SwiftData container from widgets — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-access-a-swiftdata-container-from-widgets) — HIGH confidence
- [How to use MVVM to separate SwiftData from your views — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-use-mvvm-to-separate-swiftdata-from-your-views) — HIGH confidence
- [Is SwiftData incompatible with MVVM? — Matteo Manferdini](https://matteomanferdini.com/swiftdata-mvvm/) — MEDIUM confidence (thorough analysis, single author)
- [How to sync SwiftData with iCloud — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-sync-swiftdata-with-icloud) — HIGH confidence
- [Designing Models for CloudKit Sync: Core Data and SwiftData Rules — fatbobman](https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/) — HIGH confidence (well-documented community expert source)
- [Syncing model data across a person's devices — Apple Developer Documentation](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices) — HIGH confidence (authoritative)
- [Scheduling a notification locally from your app — Apple Developer Documentation](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app) — HIGH confidence (authoritative)
- [SwiftData and correct setup for App Groups — Apple Developer Forums thread 732986](https://developer.apple.com/forums/thread/732986) — MEDIUM confidence (official forum, community answer)
- [Add App Group to Existing SwiftData — Apple Developer Forums thread 789173](https://developer.apple.com/forums/thread/789173) — MEDIUM confidence
- [How to Build a Configurable SwiftUI Widget with App Intents and SwiftData — AppMakers.DEV (Jun 2025)](https://medium.com/app-makers/how-to-build-a-configurable-swiftui-widget-with-app-intents-and-swiftdata-e4db410cfd12) — MEDIUM confidence (recent, practical)
