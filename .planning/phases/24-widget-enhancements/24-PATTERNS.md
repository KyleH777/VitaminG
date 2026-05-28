# Phase 24: Widget Enhancements - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 4 (2 modified + 1 one-line fix + 1 new test)
**Analogs found:** 4 / 4

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `VitaminG/Services/WidgetDataProvider.swift` | service (pure struct) | transform / batch | itself — existing file being extended | exact (self-analog) |
| `VitaminGWidget/GoalSummaryWidget.swift` | component (widget view) | request-response | `VitaminGWidget/StreakWidget.swift` (StreakWidgetView) | exact |
| `VitaminG/Views/StatsView.swift` | view (one-line fix) | request-response | `VitaminG/ViewModels/GoalViewModel.swift` (reloadWidgetTimelines) | role-adjacent |
| `VitaminGTests/Phase24WidgetDataProviderTests.swift` | test | batch | `VitaminGTests/WidgetDataProviderTests.swift` | exact |

---

## Pattern Assignments

### `VitaminG/Services/WidgetDataProvider.swift` (service, transform)

**Analog:** itself — `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Services/WidgetDataProvider.swift`

**Imports pattern** (lines 1):
```swift
import Foundation
```
No other imports. `WidgetDataProvider` is intentionally pure Foundation — `Goal` and `CompletionEvent` are accessible without `import SwiftData` because the model is in the `VitaminG` module. Adding any other import breaks the purity contract.

**Existing struct shape** (lines 8-34) — what to extend:
```swift
struct WidgetDisplayData {
    struct TierRow {
        let tier: GoalTier
        let topGoalTitle: String?  // nil = show empty state prompt
    }

    let tierRows: [TierRow]     // Always GoalTier.ordered order (4 elements)
    let globalStreak: Int
    // ADD: let activeGoalTitle: String?   (nil = no active non-completed goal)
    // ADD: let activeGoalProgress: Double? (nil = no durationDays; 0.0–1.0 clamped)

    static let placeholder = WidgetDisplayData(
        tierRows: [
            TierRow(tier: .immediate, topGoalTitle: "Meditate for 10 minutes"),
            TierRow(tier: .shortTerm, topGoalTitle: "Read 12 books this quarter"),
            TierRow(tier: .longTerm, topGoalTitle: "Run a half marathon"),
            TierRow(tier: .lifeGoal, topGoalTitle: "Write a novel"),
        ],
        globalStreak: 7
        // ADD: activeGoalTitle: "Meditate for 10 minutes",
        // ADD: activeGoalProgress: 0.43
    )

    static let empty = WidgetDisplayData(
        tierRows: GoalTier.ordered.map { TierRow(tier: $0, topGoalTitle: nil) },
        globalStreak: 0
        // ADD: activeGoalTitle: nil,
        // ADD: activeGoalProgress: nil
    )
}
```

**Core build() pattern** (lines 49-67) — what to extend after existing tierRows block:
```swift
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
    // AFTER this block, add active goal selection (D-03 / D-04):
    // let activeGoal = GoalTier.ordered.compactMap { tier in
    //     goals
    //         .filter { $0.tier == tier && !$0.isCompleted }
    //         .sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
    //         .first
    // }.first
    //
    // let activeGoalTitle = activeGoal?.title
    // let activeGoalProgress: Double? = {
    //     guard let goal = activeGoal,
    //           let duration = goal.durationDays,
    //           duration > 0 else { return nil }
    //     let count = Double(goal.completionEvents?.count ?? 0)
    //     return min(1.0, count / Double(duration))
    // }()

    return WidgetDisplayData(tierRows: tierRows, globalStreak: globalStreak)
    // UPDATE return to pass new fields:
    // return WidgetDisplayData(
    //     tierRows: tierRows,
    //     globalStreak: globalStreak,
    //     activeGoalTitle: activeGoalTitle,
    //     activeGoalProgress: activeGoalProgress
    // )
}
```

**Key model facts for active goal logic:**
- `Goal.durationDays: Int?` — defined in `SchemaV10.swift` line 70; nil = open-ended goal
- `Goal.completionEvents: [SchemaV2.CompletionEvent]?` — relationship, may be nil (use `?? 0`)
- `Goal.isCompleted: Bool` — direct property, no optional
- `Goal.creationDate: Date?` — optional; use `.distantPast` as sort fallback (matches existing pattern in build())
- `GoalTier.ordered` = `[.immediate, .shortTerm, .longTerm, .lifeGoal]` — defined in `Goal.swift` line 56

---

### `VitaminGWidget/GoalSummaryWidget.swift` (component, request-response)

**Analog:** `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminGWidget/StreakWidget.swift`

**Imports pattern** (lines 1-3 of StreakWidget.swift — identical in GoalSummaryWidget.swift):
```swift
import WidgetKit
import SwiftUI
import SwiftData
```

**Provider pattern** (lines 7-38 of StreakWidget.swift — GoalSummaryProvider already follows this; do not change):
```swift
struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> GoalEntry {
        GoalEntry(date: .now, displayData: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (GoalEntry) -> Void) {
        completion(GoalEntry(date: .now, displayData: .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalEntry>) -> Void) {
        do {
            let container = try WidgetContainerCache.shared
            let modelContext = ModelContext(container)
            let goals = try modelContext.fetch(FetchDescriptor<Goal>())
            let events = try modelContext.fetch(FetchDescriptor<CompletionEvent>())
            let displayData = WidgetDataProvider.build(goals: goals, events: events)
            let entry = GoalEntry(date: .now, displayData: displayData)
            // Push-only refresh policy — NEVER change to .atEnd or .after
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        } catch {
            let entry = GoalEntry(date: .now, displayData: .empty)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        }
    }
}
```

**Core view pattern** (lines 42-87 of StreakWidget.swift — adapt for GoalSummaryWidgetView):

The existing `StreakWidgetView` demonstrates all structural patterns the new `GoalSummaryWidgetView` must follow:
- `Group {}` / `VStack` as root container
- `.containerBackground(.fill.tertiary, for: .widget)` as last modifier on root (required iOS 17+)
- `entry.displayData.globalStreak` access pattern
- `entry.displayData.tierRows.first(where: { $0.tier == .immediate })` for StreakWidget's State B (read-only; this field stays)
- `HStack(spacing: 4)` for icon + count + label row
- `Image(systemName: "flame.fill")` with `.widgetAccentable()` for lock screen (GoalSummaryWidget does NOT use `.widgetAccentable()` per D-06)
- `.accessibilityElement(children: .combine)` + `.accessibilityLabel(...)` on combined rows

**New GoalSummaryWidgetView body pattern** (replace entire existing body — drop TierRowView and footer):
```swift
struct GoalSummaryWidgetView: View {
    let entry: GoalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            streakRow
            if let title = entry.displayData.activeGoalTitle {
                activeGoalRow(title: title, progress: entry.displayData.activeGoalProgress)
            } else {
                Text("Add your first goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Add your first goal")
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var streakRow: some View {
        HStack(spacing: 4) {
            if entry.displayData.globalStreak > 0 {
                Image(systemName: "flame.fill")
                    .foregroundStyle(VGTheme.accentTerra)
                    .font(.caption)
                Text("\(entry.displayData.globalStreak)")
                    .font(.title2.bold().monospacedDigit())
                Text("day streak")
                    .font(.caption)
                    .fontWeight(.semibold)
            } else {
                Text("Start your streak")
                    .font(.caption)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            entry.displayData.globalStreak > 0
                ? "\(entry.displayData.globalStreak) day streak"
                : "Start your streak"
        )
    }

    private func activeGoalRow(title: String, progress: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .truncationMode(.tail)
            if let p = progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(VGTheme.accentTerra.opacity(0.20))
                            .frame(height: 4)
                        Capsule()
                            .fill(VGTheme.accentTerra)
                            .frame(width: geo.size.width * p, height: 4)
                    }
                }
                .frame(height: 4)   // CRITICAL: fixes GeometryReader height (Pitfall 6)
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            progress != nil
                ? "\(title), \(Int((progress ?? 0) * 100))% complete"
                : title
        )
    }
}
```

**Widget configuration update** (lines 136-148 of GoalSummaryWidget.swift — description string only):
```swift
// Change .description from:
.description("See your top goal for each tier at a glance.")
// To:
.description("Your active goal and current streak at a glance.")
```

**TierRowView removal:** Delete the entire `private struct TierRowView` block (lines 97-133 of GoalSummaryWidget.swift). The new `GoalSummaryWidgetView` does not reference it. Leaving it causes Pitfall 4 (double-render of old layout).

**VGTheme.accentTerra** (source: `VGTheme.swift` lines 120-124):
```swift
static let accentTerra = Color(uiColor: UIColor { t in
    t.userInterfaceStyle == .dark
        ? UIColor(red: 1.000, green: 0.541, blue: 0.361, alpha: 1)  // terraGlow #FF8A5C
        : UIColor(red: 0.769, green: 0.404, blue: 0.227, alpha: 1)  // terra #C4673A
})
```
Use `VGTheme.accentTerra` directly — not the inline `UIColor { t in ... }` block that currently appears in `GoalSummaryWidgetView`'s old footer.

---

### `VitaminG/Views/StatsView.swift` (view, one-line fix)

**Analog:** `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift`

**Reload pattern from GoalViewModel** (lines 361-363):
```swift
private func reloadWidgetTimelines() {
    WidgetCenter.shared.reloadAllTimelines()
}
```

**Exact insertion point in StatsView** (lines 105-108 of StatsView.swift):
```swift
// CURRENT (missing reload):
Button("Freeze Streak") {
    freezeService.freeze()
    viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
}

// AFTER FIX (D-08):
Button("Freeze Streak") {
    freezeService.freeze()
    WidgetCenter.shared.reloadAllTimelines()   // INSERT THIS LINE
    viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
}
```

**Required import:** `WidgetKit` must be added to `StatsView.swift` imports if not already present. Current imports are `import SwiftUI` and `import SwiftData` (lines 1-2). Add `import WidgetKit` as line 3.

---

### `VitaminGTests/Phase24WidgetDataProviderTests.swift` (test, batch)

**Analog:** `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminGTests/WidgetDataProviderTests.swift`

**Imports and class declaration pattern** (lines 1-18):
```swift
import XCTest
import SwiftData
@testable import VitaminG

final class Phase24WidgetDataProviderTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }
```

**Test method pattern** (lines 21-51 of WidgetDataProviderTests.swift — copy structure):
```swift
func test_activeGoal_immediateWinsOverShortTerm() throws {
    let immediate = Goal(title: "Immediate Goal", tier: .immediate)
    immediate.creationDate = Date(timeIntervalSince1970: 1000)
    let shortTerm = Goal(title: "Short Term Goal", tier: .shortTerm)
    shortTerm.creationDate = Date(timeIntervalSince1970: 500)
    context.insert(immediate)
    context.insert(shortTerm)
    try context.save()

    let goals = try context.fetch(FetchDescriptor<Goal>())
    let result = WidgetDataProvider.build(goals: goals, events: [])

    XCTAssertEqual(result.activeGoalTitle, "Immediate Goal",
                   "Immediate tier must win over Short Term regardless of creationDate")
}
```

**Goals to cover per RESEARCH.md validation map:**
- `test_activeGoal_immediateWinsOverShortTerm` — D-03 tier priority
- `test_activeGoal_earliestCreationDate` — D-03 within-tier tiebreak
- `test_activeGoalProgress_clampedToUnit` — D-04 clamp to 1.0
- `test_activeGoalProgress_nilWhenNoDuration` — D-04 nil sentinel
- `test_activeGoal_nilWhenAllCompleted` — empty state
- `test_placeholder_hasActiveGoalFields` — `WidgetDisplayData.placeholder` carries new fields
- `test_empty_hasNilActiveGoalFields` — `WidgetDisplayData.empty` has nil for new fields

**Key model construction for tests** (from SchemaV10.swift lines 88-105 — current Goal init):
```swift
// Goal with durationDays (needed for progress tests):
let goal = Goal(title: "My Goal", tier: .immediate, durationDays: 30)
// Goal without duration:
let goal = Goal(title: "Open Ended", tier: .immediate)  // durationDays defaults to nil
// Mark as completed:
goal.isCompleted = true
// Set creationDate for ordering tests:
goal.creationDate = Date(timeIntervalSince1970: 1000)
```

**CompletionEvent construction for progress tests** (from SchemaV1.swift lines 78-83):
```swift
let event = CompletionEvent(goal: goal)
event.completedAt = Date()
context.insert(event)
// Then fetch via context before passing to build():
// goal.completionEvents is populated via the relationship after fetch
```

---

## Shared Patterns

### Widget containerBackground (required iOS 17+)
**Source:** Both `GoalSummaryWidget.swift` line 91 and `StreakWidget.swift` line 85
**Apply to:** `GoalSummaryWidgetView.body` root container
```swift
.containerBackground(.fill.tertiary, for: .widget)
```
Must be the last modifier on the root container view. Missing it causes the widget to appear with a blank background on iOS 17+.

### Push-only timeline policy
**Source:** `GoalSummaryWidget.swift` lines 48-50; `StreakWidget.swift` lines 28-30
**Apply to:** Both provider `getTimeline()` implementations (do not change)
```swift
let timeline = Timeline(entries: [entry], policy: .never)
completion(timeline)
```
This is a deliberate project architecture decision (STATE.md). `.never` means WidgetKit does not self-poll — the app signals refresh via `WidgetCenter.shared.reloadAllTimelines()`.

### Widget reload call site pattern
**Source:** `GoalViewModel.swift` lines 361-363; `GoalViewModel.swift` line 354 (direct call)
**Apply to:** `StatsView.swift` freeze handler (D-08)
```swift
// Private helper pattern (GoalViewModel):
private func reloadWidgetTimelines() {
    WidgetCenter.shared.reloadAllTimelines()
}

// Direct call pattern (StatsView — use this form, no private helper needed):
WidgetCenter.shared.reloadAllTimelines()
```

### Static-data-only placeholder/snapshot
**Source:** `GoalSummaryWidget.swift` lines 27-34; `StreakWidget.swift` lines 9-14
**Apply to:** Both providers' `placeholder()` and `getSnapshot()` — no changes needed, just do not break
```swift
func placeholder(in context: Context) -> GoalEntry {
    GoalEntry(date: .now, displayData: .placeholder)
}
func getSnapshot(in context: Context, completion: @escaping (GoalEntry) -> Void) {
    completion(GoalEntry(date: .now, displayData: .placeholder))
}
```
Never call `WidgetContainerCache.shared` here — only in `getTimeline()`.

### Accessibility on widget rows
**Source:** `StreakWidget.swift` lines 60-61
**Apply to:** Each row in `GoalSummaryWidgetView`
```swift
.accessibilityElement(children: .combine)
.accessibilityLabel("...")
```

---

## No Analog Found

None. All four files have close analogs in the codebase. The new test file (`Phase24WidgetDataProviderTests.swift`) is an exact match to the existing `WidgetDataProviderTests.swift` pattern.

---

## Critical Anti-Patterns (from RESEARCH.md — do not copy these)

| Anti-Pattern | Where to Avoid | Correct Pattern |
|---|---|---|
| `import SwiftUI` / `import SwiftData` in WidgetDataProvider | `WidgetDataProvider.swift` | `import Foundation` only |
| `.widgetAccentable()` on progress bar fill | `GoalSummaryWidgetView.activeGoalRow` | Use `VGTheme.accentTerra` directly |
| `GeometryReader` without `.frame(height: 4)` after it | progress bar in `activeGoalRow` | Always `.frame(height: 4)` immediately after `GeometryReader { }` |
| Removing `tierRows` from `WidgetDisplayData` | struct extension | Keep `tierRows` — `StreakWidgetView` State B depends on it |
| SwiftData fetch in `placeholder()` / `getSnapshot()` | Both widget providers | Static `WidgetDisplayData.placeholder` only |
| `policy: .atEnd` or `.after(...)` | `getTimeline()` in both providers | `policy: .never` — push-only architecture |

---

## Metadata

**Analog search scope:** `VitaminG/VitaminG/VitaminG/` (app target) + `VitaminG/VitaminG/VitaminGWidget/` (widget extension) + `VitaminG/VitaminG/VitaminGTests/` (test target)
**Files read:** 9 source files (WidgetDataProvider.swift, GoalSummaryWidget.swift, StreakWidget.swift, WidgetTimelineEntry.swift, StatsView.swift, GoalViewModel.swift grep, Goal.swift, SchemaV1.swift, SchemaV10.swift, VGTheme.swift, WidgetDataProviderTests.swift)
**Pattern extraction date:** 2026-05-27
