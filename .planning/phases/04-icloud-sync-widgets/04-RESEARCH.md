# Phase 4: iCloud Sync & Widgets - Research

**Researched:** 2026-04-06
**Domain:** WidgetKit (systemMedium + accessoryRectangular), SwiftData + App Group, CloudKit transparent sync, WidgetCenter reload
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Sync is truly invisible — no sync status indicator, no spinner, no "last synced" row in Settings. CloudKit sync is an expectation, not a feature to surface.
- **D-02:** Settings shows the current global streak count (e.g., 🔥 12 days) as a motivational element. Not related to sync; it's a persistent motivational anchor.
- **D-03:** The home screen widget (systemMedium) displays 4 tier rows (Immediate → Short-Term → Long-Term → Life Goal). Each row shows the top active goal for that tier with its tier color and icon. Empty tiers show a gentle prompt (e.g., "No Immediate goals yet").
- **D-04:** A footer row at the bottom of the widget shows the global streak count (e.g., 🔥 12 days). If streak is 0, the footer is omitted or shows a neutral encouragement.
- **D-05:** Smart display logic for lock screen widget: show global streak count if streak > 0; fall back to the top active Immediate goal title when streak is 0. Always has something meaningful to show.
- **D-06:** Timeline refreshes once daily (morning, aligned with the notification time set by the user). The main app calls `WidgetCenter.shared.reloadAllTimelines()` after any goal add, edit, delete, or completion toggle.
- **D-07:** Widgets read directly from the shared App Group SwiftData store using the same `ModelContainerFactory.makeContainer()` pattern. No separate JSON/plist snapshot needed.

### Claude's Discretion

- Exact widget visual design (spacing, typography, line truncation for long goal titles)
- Empty tier prompt copy in the home screen widget
- Widget display name and description strings in Xcode
- Exact footer layout when streak is 0 (omit vs. neutral copy)
- Unit test coverage pattern for widget timeline provider (follow StreakEngine/GoalSorter standalone struct pattern)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SYNC-01 | All Goal and CompletionEvent data syncs across user's devices via CloudKit private database | CloudKit is already wired via `cloudKitDatabase: .automatic` in ModelContainerFactory — no additional code needed; entitlements already configured |
| SYNC-02 | Sync works transparently — no manual sync button in v1 | SwiftData + `cloudKitDatabase: .automatic` handles all sync in background automatically; locked by D-01 |
| WIDGET-01 | Home screen widget (systemMedium) shows top active goals across tiers | `StaticConfiguration` + `TimelineProvider` pattern; GoalSummaryWidget with 4-tier row layout using GoalTier.ordered |
| WIDGET-02 | Lock screen widget (accessoryRectangular) shows current global streak or top active goal title | Separate Widget struct in the bundle, accessoryRectangular family, StreakWidget; smart D-05 fallback logic |
| WIDGET-03 | Widget reads from shared App Group SwiftData store — same data as main app | `ModelContainerFactory.makeContainer()` called in TimelineProvider; same group container identifier; target membership required |
| WIDGET-04 | Widgets are read-only in v1 — no write operations from widget context | `StaticConfiguration` (no App Intents); no `modelContext.insert/delete` in widget code |
| WIDGET-05 | Widget timeline refreshes at least once daily (aligns with morning notification) | `Timeline(entries:policy:.after(nextMorning))` + `WidgetCenter.shared.reloadAllTimelines()` on goal mutations |
</phase_requirements>

---

## Summary

Phase 4 has two distinct implementation tracks: (1) verifying that CloudKit transparent sync already works correctly given the infrastructure laid in Phase 1, and (2) building the real widget UI to replace the placeholder stub. The CloudKit sync track is almost entirely already done — the `ModelContainer` is configured with `cloudKitDatabase: .automatic`, both entitlements files declare the iCloud container identifier, and `initializeCloudKitSchema()` exists in DEBUG mode. The work here is validation on a physical device plus verifying the iCloud capability checkboxes in Xcode's Signing & Capabilities.

The widget track is more substantial. Two widgets must be built: a `systemMedium` home screen widget (`GoalSummaryWidget`) and an `accessoryRectangular` lock screen widget (`StreakWidget`). Both share a single `VitaminGWidgetBundle` entry point. The critical architectural constraint is that the widget process is a separate process from the main app — it cannot import the app module. Instead, shared Swift files (SchemaV1.swift, Goal.swift, StreakEngine.swift) must be added to the widget target's target membership in Xcode. The `ModelContainer` must be instantiated inside `getTimeline` (or as a lazy property on the provider) using the same `ModelContainerFactory.makeContainer()` call, with the simulator guard carried through identically.

The timeline refresh strategy uses `Timeline(entries: [...], policy: .after(nextMorning))` to schedule once-daily auto-refresh aligned with the user's notification time, combined with `WidgetCenter.shared.reloadAllTimelines()` called from `GoalViewModel` after every goal mutation. The widget store uses `cloudKitDatabase: .none` (or simply omit it — widget process does not handle CloudKit sync; the main app process owns sync).

**Primary recommendation:** Add target membership for shared model files first. Build a standalone `WidgetDataProvider` struct (pure, no SwiftUI/SwiftData dependency) that holds the display-layer data and is unit-testable, exactly following the StreakEngine/GoalSorter pattern. Build widget views last.

---

## Project Constraints (from CLAUDE.md)

| Directive | Impact on Phase 4 |
|-----------|-------------------|
| No third-party dependencies | Widgets use only WidgetKit, SwiftUI, SwiftData — no additional packages |
| iOS 17+ minimum | `StaticConfiguration`, `.containerBackground(for: .widget)`, `@Observable` all available; lock screen widgets available since iOS 16 so no floor issue |
| SwiftData properties must be optional/defaulted | Already done in SchemaV1; widget reads but never writes — no new model mutations |
| MVVM strictly enforced | Widgets do NOT use ViewModels (WidgetKit has no `@Observable` context); use TimelineProvider + entry struct instead |
| `@Attribute(.unique)` forbidden | Not relevant — no new model attributes added |
| `.containerBackground(for: .widget)` required on iOS 17 | MUST be used on all widget views; omitting it causes rendering artifacts in iOS 17+ |
| Widget target already has App Groups entitlement | Confirmed: `VitaminGWidget.entitlements` already has `group.com.kyleharrington.VitaminG` |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| WidgetKit | iOS 14+ (lock screen iOS 16+) | Widget host process, timeline management | Apple-native; only supported widget framework [VERIFIED: Apple docs] |
| SwiftUI | iOS 17+ | Widget view rendering | Required for WidgetKit views in this project [VERIFIED: CLAUDE.md] |
| SwiftData | iOS 17+ | Read model data from App Group store in widget process | Already used by main app; shared store via App Group [VERIFIED: codebase] |
| WidgetCenter | Part of WidgetKit | Signal widget refresh from main app after mutations | `WidgetCenter.shared.reloadAllTimelines()` [VERIFIED: Apple docs] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Foundation | iOS 17+ | Calendar arithmetic for next-morning timeline entry date | Computing `policy: .after(nextMorning)` |
| UserDefaults (App Group suite) | N/A | Read user's notification time preference in widget for alignment | Reading `notificationHour`/`notificationMinute` keys set by SettingsView |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SwiftData direct read in widget | JSON/plist snapshot written by main app | Snapshot is simpler but adds a secondary sync step; D-07 locked SwiftData direct read |
| `StaticConfiguration` | `AppIntentConfiguration` | App Intents enable interactive widgets but require v2 scope; WIDGET-04 requires read-only; use `StaticConfiguration` |
| `policy: .after(nextMorning)` | `policy: .atEnd` with 24h entries | `.after(nextMorning)` is cleaner for once-daily alignment; `.atEnd` also acceptable fallback |

**Installation:** No new packages to install. All required frameworks are part of the iOS SDK.

---

## Architecture Patterns

### Recommended Widget Target Structure

```
VitaminGWidget/
├── VitaminGWidgetBundle.swift        -- @main bundle (replace placeholder with real widgets)
├── GoalSummaryWidget.swift           -- systemMedium widget: 4-tier row layout
├── StreakWidget.swift                 -- accessoryRectangular lock screen widget
├── WidgetDataProvider.swift          -- Standalone pure struct: fetches + shapes display data
└── WidgetTimelineEntry.swift         -- TimelineEntry struct: holds WidgetDataProvider output
```

**Files to add to widget target membership** (already exist in app target):
- `VitaminG/Models/SchemaV1.swift`
- `VitaminG/Models/Goal.swift`
- `VitaminG/Persistence/ModelContainerFactory.swift`
- `VitaminG/Services/StreakEngine.swift`

### Pattern 1: Standalone WidgetDataProvider

**What:** A pure struct with no SwiftUI/SwiftData import that holds pre-computed display data for the widget. Fetching from SwiftData happens only in the TimelineProvider; the result is baked into the entry.

**When to use:** Always — enables unit testing without mocking WidgetKit; follows GoalSorter/StreakEngine pattern already established.

```swift
// Source: established project pattern (StreakEngine.swift, GoalSorter.swift)
struct WidgetDisplayData {
    struct TierRow {
        let tier: GoalTier
        let topGoalTitle: String?  // nil = show empty state prompt
    }
    let tierRows: [TierRow]     // GoalTier.ordered order
    let globalStreak: Int
}

struct WidgetDataProvider {
    /// Pure function — takes fetched data, returns display data.
    /// No SwiftData, no SwiftUI, no WidgetKit import required.
    static func build(
        goals: [Goal],
        events: [CompletionEvent],
        calendar: Calendar = .current
    ) -> WidgetDisplayData {
        let globalStreak = StreakEngine.currentStreak(from: events, calendar: calendar)
        let tierRows: [WidgetDisplayData.TierRow] = GoalTier.ordered.map { tier in
            let topTitle = goals
                .filter { $0.tier == tier && !$0.isCompleted }
                .sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
                .first?.title
            return WidgetDisplayData.TierRow(tier: tier, topGoalTitle: topTitle)
        }
        return WidgetDisplayData(tierRows: tierRows, globalStreak: globalStreak)
    }
}
```

### Pattern 2: TimelineProvider with SwiftData Fetch

**What:** The `getTimeline` method creates a `ModelContext`, fetches `Goal` and `CompletionEvent` records, builds display data, and produces a single entry with a once-daily refresh policy.

**When to use:** Inside both widget TimelineProviders. The simulator guard from ModelContainerFactory carries through here.

```swift
// Source: established ModelContainerFactory pattern + WidgetKit docs
struct GoalSummaryProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalEntry>) -> Void) {
        do {
            let container = try ModelContainerFactory.makeContainer()
            let modelContext = ModelContext(container)

            let goals = try modelContext.fetch(FetchDescriptor<Goal>())
            let events = try modelContext.fetch(FetchDescriptor<CompletionEvent>())

            let displayData = WidgetDataProvider.build(goals: goals, events: events)
            let entry = GoalEntry(date: .now, displayData: displayData)

            // Refresh once daily at next morning aligned with notification time
            let nextRefresh = nextMorningRefreshDate()
            let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
            completion(timeline)
        } catch {
            // Fallback: empty data, retry in 1 hour
            let entry = GoalEntry(date: .now, displayData: WidgetDisplayData.empty)
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
            completion(timeline)
        }
    }

    func placeholder(in context: Context) -> GoalEntry {
        GoalEntry(date: .now, displayData: WidgetDisplayData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (GoalEntry) -> Void) {
        // Snapshot is shown in widget gallery — use placeholder data to avoid
        // requiring a live store during App Store screenshots
        completion(GoalEntry(date: .now, displayData: WidgetDisplayData.placeholder))
    }

    private func nextMorningRefreshDate() -> Date {
        let hour = UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")?
            .integer(forKey: "notificationHour") ?? 8
        let minute = UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")?
            .integer(forKey: "notificationMinute") ?? 0
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        let today = Calendar.current.date(from: components) ?? Date()
        // If morning time has already passed today, schedule for tomorrow
        return today > Date() ? today : Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
    }
}
```

### Pattern 3: Widget Views with containerBackground

**What:** All widget views MUST use `.containerBackground(for: .widget)` on iOS 17+. Omitting it causes a runtime crash / rendering artifact in iOS 17.

```swift
// Source: CLAUDE.md, Apple WWDC23 "Bring widgets to new places"
struct GoalSummaryWidgetView: View {
    let entry: GoalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(entry.displayData.tierRows, id: \.tier) { row in
                TierRowView(row: row)
            }
            if entry.displayData.globalStreak > 0 {
                Divider()
                Text("🔥 \(entry.displayData.globalStreak) days")
                    .font(.caption.bold())
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

### Pattern 4: Widget Bundle — Two Real Widgets

```swift
// Replace VitaminGWidgetPlaceholder in VitaminGWidgetBundle.swift
@main
struct VitaminGWidgetBundle: WidgetBundle {
    var body: some Widget {
        GoalSummaryWidget()   // systemMedium
        StreakWidget()         // accessoryRectangular
    }
}

struct GoalSummaryWidget: Widget {
    let kind = "GoalSummaryWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GoalSummaryProvider()) { entry in
            GoalSummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Your Goals")
        .description("See your top active goals at a glance.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()  // For precise padding control
    }
}

struct StreakWidget: Widget {
    let kind = "StreakWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Your current goal streak or top Immediate goal.")
        .supportedFamilies([.accessoryRectangular])
    }
}
```

### Pattern 5: WidgetCenter Reload in GoalViewModel

**What:** `WidgetCenter.shared.reloadAllTimelines()` must be called after every goal mutation in the main app. It is a suggestion to the system — it is not guaranteed to fire immediately but will fire within the system's scheduling window.

```swift
// Add to each mutation method in GoalViewModel (addGoal, updateGoal, delete, toggleCompletion)
// Source: CLAUDE.md, established pattern from Phase 3 notification rescheduling
import WidgetKit

func reloadWidgetTimelines() {
    WidgetCenter.shared.reloadAllTimelines()
}
```

**Add `import WidgetKit` to GoalViewModel.swift** — the main app target must link WidgetKit framework. Verify the framework is linked in Build Phases for the app target (it should be since the widget stub already exists).

### Pattern 6: NotificationHour in App Group UserDefaults

**What:** The `nextMorningRefreshDate()` helper in the TimelineProvider must read `notificationHour`/`notificationMinute` from the shared App Group UserDefaults suite — NOT the standard UserDefaults — because the widget process runs sandboxed and cannot access the main app's standard UserDefaults.

**Critical:** `SettingsView` currently writes notification time to `UserDefaults.standard`. This must be **also written to** `UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")` so the widget can read it. Write to BOTH — the notification scheduler reads from `.standard`, so that must not change.

### Anti-Patterns to Avoid

- **Importing the app module from the widget target:** Widgets cannot `import VitaminG`. Instead, add individual Swift files to widget target membership in Xcode File Inspector.
- **Using `cloudKitDatabase: .automatic` in the widget's ModelContainer:** The widget process should not own CloudKit sync. Use `cloudKitDatabase: .none` (or the simulator guard path, which already omits CloudKit). The main app owns sync.
- **Modifying data from the widget context:** WIDGET-04 forbids writes. `StaticConfiguration` has no App Intent; there is no `modelContext.insert` anywhere in widget code.
- **Reading UserDefaults.standard in widget:** Widget process sandbox does not share standard UserDefaults with the main app. Use `UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")`.
- **Omitting `.containerBackground(for: .widget)`:** Required on iOS 17+; crashes or breaks widget rendering if missing.
- **Fetching data in `placeholder(in:)`:** Placeholder is called synchronously and must return static data. Do not attempt SwiftData fetch there.
- **Forgetting simulator guard in widget ModelContainer:** The `ModelContainerFactory.makeContainer()` already has the `#if targetEnvironment(simulator)` guard. The widget calls this same factory — the guard carries through automatically.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Streak count in widget | Custom streak calculation | `StreakEngine.currentStreak(from:)` (already exists) | Already tested; add StreakEngine.swift to widget target membership |
| Top goal per tier selection | Custom sort in widget view | `WidgetDataProvider.build()` (new standalone struct) | Keeps widget view dumb; enables unit testing |
| Widget refresh on goal change | Timer or background fetch | `WidgetCenter.shared.reloadAllTimelines()` | System-managed, battery-efficient; no background entitlement needed |
| CloudKit sync progress UI | Custom sync status row | Nothing — sync is invisible (D-01) | SwiftData + CloudKit handles sync automatically |
| Separate JSON snapshot for widget | Custom serialization layer | SwiftData direct read from shared App Group store (D-07) | Infrastructure already exists; adds no complexity |
| iCloud capability setup | Manual plist editing | Xcode Signing & Capabilities UI | Generates correct entitlements; already done for main app target |

---

## Common Pitfalls

### Pitfall 1: Model Files Not in Widget Target Membership

**What goes wrong:** Widget fails to compile with "cannot find type 'Goal' in scope" or "use of unresolved identifier 'GoalTier'".
**Why it happens:** Widget is a separate process/target. Xcode does not automatically include app target files.
**How to avoid:** For each shared file (SchemaV1.swift, Goal.swift, ModelContainerFactory.swift, StreakEngine.swift), open File Inspector (right panel in Xcode), check the VitaminGWidget target checkbox under "Target Membership".
**Warning signs:** Build errors mentioning unresolved types; linker errors.

### Pitfall 2: Widget Process Crash from cloudKitDatabase in Widget ModelContainer

**What goes wrong:** Widget process crashes on launch or fails silently because CloudKit is initialized in a process that has no CloudKit entitlement on the widget target.
**Why it happens:** The widget's entitlements file (`VitaminGWidget.entitlements`) only has App Groups, not iCloud/CloudKit. If `ModelContainerFactory.makeContainer()` passes `cloudKitDatabase: .automatic` in a real-device (non-simulator) widget context, CloudKit tries to initialize and fails.
**How to avoid:** The widget must use a `cloudKitDatabase: .none` version of the container. Add a `widgetContainer` variant to `ModelContainerFactory` that uses App Group path but omits CloudKit. The `#if targetEnvironment(simulator)` guard already handles simulator — add a `isWidget: Bool` parameter or a separate static factory for the widget use case.
**Warning signs:** Widget shows stale placeholder data; widget process crashes silently on device.

### Pitfall 3: Reading UserDefaults.standard in Widget Process

**What goes wrong:** `nextMorningRefreshDate()` always returns 8:00 AM even after user changes notification time.
**Why it happens:** Widget process sandbox cannot access the main app's `UserDefaults.standard` domain.
**How to avoid:** Write notification time to `UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")` in addition to `UserDefaults.standard` in `SettingsView`. Read from the App Group suite in the widget.
**Warning signs:** Widget refresh time doesn't follow the user's configured notification time.

### Pitfall 4: reloadAllTimelines Is a Suggestion, Not Immediate

**What goes wrong:** Developer expects widget to refresh immediately after a goal mutation; widget shows stale data for minutes.
**Why it happens:** WidgetKit rate-limits reloads based on system resources and widget usage frequency. A fresh install or infrequently-used widget may not reload for several minutes.
**How to avoid:** This is expected system behavior. Do not add delays or loops to force immediate reload. Trust that the next scheduled timeline entry (policy: .after(nextMorning)) provides the backstop.
**Warning signs:** Widget appears stale after goal edit during development — use the Xcode debug widget timeline tools to force reload during testing.

### Pitfall 5: Placeholder and Snapshot Require Static Data (No SwiftData)

**What goes wrong:** Widget crashes or shows blank during App Store screenshots or initial widget gallery preview.
**Why it happens:** `placeholder(in:)` and `getSnapshot(in:)` may be called before the App Group store is accessible or in a context without live data.
**How to avoid:** `placeholder` must return a hard-coded `WidgetDisplayData.placeholder` value (static sample goals). `getSnapshot` should also use placeholder data unless `context.isPreview == false` and a fast SwiftData fetch is feasible.
**Warning signs:** Widget gallery shows blank/crash during Xcode preview or App Store screenshot tool.

### Pitfall 6: Widget Cannot Access iCloud-Synced Data That Hasn't Synced Yet

**What goes wrong:** On a second device, widget shows empty data even though the main app has synced correctly.
**Why it happens:** Widget reads the local App Group store. CloudKit sync happens in the main app process. If the main app hasn't been opened on that device yet, the store may be empty even though iCloud has the data.
**How to avoid:** This is expected CloudKit behavior for widgets. The widget's empty state must handle `[]` data gracefully. Empty tiers show the "No goals yet" prompt (D-03).
**Warning signs:** Appears as a bug report from users who installed the app fresh on a second device without opening the main app.

---

## Code Examples

Verified patterns from codebase and official sources:

### ModelContainer Setup in Widget (Widget-Safe Variant)

```swift
// Source: ModelContainerFactory.swift pattern + known CloudKit widget limitation
// Add as a static method to ModelContainerFactory (shared file, both targets)
static func makeWidgetContainer() throws -> ModelContainer {
    let schema = Schema(SchemaV1.models, version: SchemaV1.versionIdentifier)

    #if targetEnvironment(simulator)
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    #else
    // Widget process does NOT own CloudKit sync — omit cloudKitDatabase
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        groupContainer: .identifier("group.com.kyleharrington.VitaminG"),
        cloudKitDatabase: .none
    )
    #endif

    return try ModelContainer(for: schema, configurations: config)
}
```

### WidgetCenter Reload (GoalViewModel addition)

```swift
// Source: CLAUDE.md + GoalViewModel.swift existing pattern
// Add after every mutation: addGoal, updateGoal, delete, toggleCompletion
import WidgetKit

private func reloadWidgetTimelines() {
    WidgetCenter.shared.reloadAllTimelines()
}

// In addGoal, after context.insert(goal):
reloadWidgetTimelines()

// In toggleCompletion, after completion toggle:
reloadWidgetTimelines()

// In updateGoal, after mutating goal properties:
reloadWidgetTimelines()

// In delete, after context.delete(goal):
reloadWidgetTimelines()
```

### App Group UserDefaults Write in SettingsView

```swift
// Source: SettingsView.swift existing pattern — extend to write to App Group suite
// In the .onChange(of: notificationTime) handler, add:
let appGroupDefaults = UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")
appGroupDefaults?.set(hour, forKey: "notificationHour")
appGroupDefaults?.set(minute, forKey: "notificationMinute")
// Keep existing UserDefaults.standard writes for NotificationScheduler
```

### Lock Screen Widget View (accessoryRectangular)

```swift
// Source: CLAUDE.md WidgetKit notes + Lock Screen Widgets in SwiftUI (Swift with Majid)
struct StreakWidgetView: View {
    let entry: StreakEntry

    var body: some View {
        HStack {
            Image(systemName: entry.showStreak ? "flame.fill" : "bolt.fill")
                .foregroundStyle(entry.showStreak ? .orange : GoalTier.immediate.color)
            Text(entry.displayText)
                .font(.caption.bold())
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
// entry.displayText = "12 days" (streak > 0) or top immediate goal title (streak == 0)
// entry.showStreak = displayData.globalStreak > 0
```

### Streak Display in SettingsView (D-02)

```swift
// Add a new section to SettingsView Form — reads global streak from CompletionEvents via @Query
@Query private var allCompletionEvents: [CompletionEvent]

// Computed property:
private var globalStreak: Int {
    StreakEngine.currentStreak(from: allCompletionEvents)
}

// In Form body, add before "Daily Reminder" section:
if globalStreak > 0 {
    Section {
        HStack {
            Text("🔥")
                .font(.largeTitle)
            VStack(alignment: .leading) {
                Text("\(globalStreak) day streak")
                    .font(.title2.bold())
                Text("Keep it going!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `IntentConfiguration` + SiriKit Intents extension | `StaticConfiguration` (non-configurable) or `AppIntentConfiguration` (App Intents, iOS 17) | iOS 17 / WWDC23 | Use `StaticConfiguration` for Phase 4 (read-only); `AppIntentConfiguration` deferred to v2 interactive widgets |
| `ObservableObject` ViewModels in widgets | No ViewModel in widgets — TimelineProvider + entry struct | Always the case for WidgetKit | Widgets never use `@Observable` or `@State` — entry struct holds all data |
| Separate plist/JSON snapshot for widget | Direct SwiftData read from shared App Group | iOS 17 SwiftData introduction | Simpler, consistent with main app store |
| `@Environment(\.widgetFamily)` for layout switching | `@Environment(\.widgetFamily)` still applies | — | Use if a single view handles multiple families; Phase 4 has separate Widget structs so not needed |

**Deprecated/outdated:**
- `IntentConfiguration` + Intents Extension: Old widget configuration API; CLAUDE.md explicitly forbids this; use `StaticConfiguration`
- `NavigationView` inside widgets: Widgets cannot push new screens; not applicable
- `containerBackground` modifier omission: Fatal on iOS 17+ — must be present

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Widget target must use `cloudKitDatabase: .none` to avoid crash; widget entitlements do not include iCloud capability | Architecture Patterns (Pitfall 2), Code Examples | If widget entitlement does include CloudKit, `.automatic` might work — but conservative `.none` is safe either way |
| A2 | `UserDefaults.standard` is not accessible from widget process; App Group suite required | Anti-Patterns, Pitfall 3, Code Examples | If Apple changed this, the extra App Group write is harmless overhead |
| A3 | `WidgetCenter.shared.reloadAllTimelines()` is available on the main app target after linking WidgetKit framework | Standard Stack | If the main app target doesn't link WidgetKit, `import WidgetKit` will fail — verify Build Phases |
| A4 | Phase 1 iCloud + CloudKit entitlements are correctly set and functional on physical device (MEDIUM confidence from STATE.md research flag) | Summary | If `cloudKitDatabase: .automatic` + App Group combination doesn't work on device, SYNC-01 requires debugging — validate early in Plan 1 |

---

## Open Questions

1. **Does `ModelContainerFactory.makeContainer()` need a `makeWidgetContainer()` variant or can a parameter be added?**
   - What we know: Both app and widget call the same factory; widget needs `cloudKitDatabase: .none`
   - What's unclear: Whether the existing `inMemory: Bool` flag is sufficient, or a new `isWidget: Bool` flag is cleaner
   - Recommendation: Add `static func makeWidgetContainer()` as a separate static method — makes intent explicit and avoids boolean parameter ambiguity

2. **Does the main app target already link WidgetKit.framework?**
   - What we know: Widget target exists and app target contains a widget stub that was extracted; `import WidgetKit` in GoalViewModel needs the framework linked to the app target
   - What's unclear: Whether Xcode auto-linked WidgetKit to the app target when the widget extension was added
   - Recommendation: Verify in Xcode Build Phases > Link Binary With Libraries for the VitaminG app target before writing GoalViewModel widget reload code

3. **CloudKit sync validation on physical device**
   - What we know: STATE.md explicitly flags this as MEDIUM confidence — "validate on physical device in Phase 1 before proceeding"
   - What's unclear: Whether sync was ever validated on device (ROADMAP shows Phase 1 as "Complete" but this flag remains)
   - Recommendation: Plan 1 of Phase 4 should include an explicit verification step: create a goal on one device, confirm it appears on a second device, before building widget UI

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode 15+ | SwiftData, @Observable, WidgetKit lock screen | Assumed (project already builds) [ASSUMED] | Unknown | — |
| Physical iOS device (2 devices for sync test) | SYNC-01 verification | Unknown [ASSUMED] | — | Single device: manually verify iCloud dashboard shows records |
| iCloud account signed in to device | SYNC-01, SYNC-02 | Unknown | — | Cannot verify without iCloud; must test on physical device |

**Missing dependencies with no fallback:**
- Two physical iOS 17+ devices are required to validate SYNC-01. This cannot be verified on Simulator.

**Missing dependencies with fallback:**
- Single device iCloud validation: Create a goal, check CloudKit dashboard in developer console for record existence as a partial SYNC-01 verification.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (existing VitaminGTests target) |
| Config file | Xcode scheme — no separate pytest.ini equivalent |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Full suite command | Same — all tests are in one target |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SYNC-01 | Goal created on device A appears on device B | Manual (requires 2 physical devices + iCloud) | Manual only — cannot automate cross-device sync | N/A |
| SYNC-02 | No manual sync button in UI | Manual (UI inspection) | Manual only | N/A |
| WIDGET-01 | systemMedium shows top active goals per tier | Unit (WidgetDataProvider) | `xcodebuild test -scheme VitaminG ...` | ❌ Wave 0 |
| WIDGET-02 | accessoryRectangular shows streak or top Immediate goal | Unit (WidgetDataProvider) | `xcodebuild test -scheme VitaminG ...` | ❌ Wave 0 |
| WIDGET-03 | Widget reads from shared App Group store | Integration (physical device) | Manual — Simulator App Group unreliable | N/A |
| WIDGET-04 | No write operations from widget context | Code review / static analysis | No writes in widget code — enforced by `StaticConfiguration` | N/A |
| WIDGET-05 | Timeline refreshes at least once daily | Unit (nextMorningRefreshDate logic) | `xcodebuild test -scheme VitaminG ...` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests` (existing unit tests must stay green)
- **Per wave merge:** Full test suite green
- **Phase gate:** All unit tests pass + manual widget rendering verified on device before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `VitaminGTests/WidgetDataProviderTests.swift` — covers WIDGET-01, WIDGET-02: tests `WidgetDataProvider.build()` with mocked goals/events
- [ ] `VitaminGTests/WidgetTimelineTests.swift` — covers WIDGET-05: tests `nextMorningRefreshDate()` logic (pure function, extract from provider)

*(Existing test infrastructure: VitaminGTests target exists with 6 test files — no new target needed)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A — single-user, device-local |
| V3 Session Management | No | N/A |
| V4 Access Control | No | Widget reads only; no new surfaces |
| V5 Input Validation | No | No new input surfaces in Phase 4 (widgets are read-only) |
| V6 Cryptography | No | No crypto — CloudKit handles transport security |

### Known Threat Patterns for WidgetKit + SwiftData

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Widget reads stale/empty data from App Group store | Information Disclosure (data inaccuracy) | Graceful empty state rendering (D-03 prompts) |
| Another app reading shared App Group data | Information Disclosure | App Group entitlement is sandboxed to same team ID — only apps with matching entitlement can access |
| CloudKit data visible to Apple | Privacy | CloudKit private database — Apple cannot read user data by design |

**Security assessment:** Phase 4 has minimal new security surface. Widgets are read-only; no new input validation required. CloudKit private DB maintains existing data privacy posture. App Group is scoped to the team ID.

---

## Sources

### Primary (HIGH confidence)
- CLAUDE.md (project) — WidgetKit constraints, `containerBackground` requirement, `StaticConfiguration` vs `AppIntentConfiguration` guidance, iOS 17 minimum
- `VitaminGWidget.entitlements` (codebase) — App Group `group.com.kyleharrington.VitaminG` confirmed on widget target
- `VitaminG.entitlements` (codebase) — iCloud container `iCloud.com.kyleharrington.VitaminG` + CloudKit confirmed on app target
- `ModelContainerFactory.swift` (codebase) — Exact configuration for App Group + CloudKit; simulator guard pattern confirmed
- `StreakEngine.swift` (codebase) — Standalone pure struct pattern confirmed; importable to widget target
- `VitaminGWidgetBundle.swift` (codebase) — Placeholder confirmed; `StaticConfiguration` + `TimelineProvider` pattern already present
- `GoalViewModel.swift` (codebase) — Mutation methods confirmed (`addGoal`, `updateGoal`, `delete`, `toggleCompletion`) — all need `reloadWidgetTimelines()` added
- Apple Developer Documentation — `TimelineProvider` [CITED: developer.apple.com/documentation/widgetkit/timelineprovider]
- Apple Developer Documentation — `WidgetCenter.reloadAllTimelines()` [CITED: developer.apple.com/documentation/widgetkit/widgetcenter/reloadalltimelines()]
- Apple Developer Documentation — `StaticConfiguration` [CITED: developer.apple.com/documentation/widgetkit/staticconfiguration]

### Secondary (MEDIUM confidence)
- CLAUDE.md sources section — Multiple official Apple docs and Hacking with Swift tutorials cited for WidgetKit + SwiftData integration patterns
- Web search findings: Widget process cannot import app module — confirmed by multiple Apple Developer Forum threads [CITED: forums.developer.apple.com/thread/756788]
- Web search findings: `UserDefaults.standard` inaccessible in widget process — confirmed by multiple sources [CITED: forums.developer.apple.com/thread/651799]
- Web search findings: `cloudKitDatabase: .none` for widget container — confirmed by developer forum discussions [MEDIUM]
- Swift with Majid — Lock screen widgets in SwiftUI [CITED: swiftwithmajid.com/2022/08/30/lock-screen-widgets-in-swiftui/]

### Tertiary (LOW confidence)
- Web search: `reloadAllTimelines` may need to be called twice or with delay on some iOS versions — single source, Apple Developer Forums thread; flagged but not confirmed [LOW]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all frameworks are Apple-native; versions confirmed in CLAUDE.md and codebase
- Architecture: HIGH — patterns derived from existing codebase (StreakEngine, GoalSorter) and confirmed Apple documentation
- CloudKit sync: MEDIUM — infrastructure confirmed in code; physical device validation flagged as unverified (STATE.md research flag carried forward)
- Widget + SwiftData pitfalls: MEDIUM — confirmed by multiple Apple Developer Forum threads and community sources; not from Context7/official docs directly
- Pitfalls: MEDIUM — well-documented in community but not all verified against official Apple release notes

**Research date:** 2026-04-06
**Valid until:** 2026-05-06 (WidgetKit + SwiftData APIs stable in iOS 17; no significant churn expected in 30 days)
