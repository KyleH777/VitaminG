---
phase: 24-widget-enhancements
reviewed: 2026-05-28T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - VitaminG/VitaminG/VitaminG/Services/WidgetDataProvider.swift
  - VitaminG/VitaminG/VitaminG/Views/StatsView.swift
  - VitaminG/VitaminG/VitaminGTests/Phase24WidgetDataProviderTests.swift
  - VitaminG/VitaminG/VitaminGWidget/GoalSummaryWidget.swift
findings:
  critical: 2
  warning: 3
  info: 2
  total: 7
status: issues_found
---

# Phase 24: Code Review Report

**Reviewed:** 2026-05-28T00:00:00Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Phase 24 adds `activeGoalTitle` and `activeGoalProgress` fields to `WidgetDisplayData`, wires them into `GoalSummaryWidget`, and adds a streak-freeze button to `StatsView`. The core data-transformation logic in `WidgetDataProvider` is sound and the test coverage for that logic is reasonable. Two blockers were found: a user-visible freeze-limit contract mismatch (UI advertises "one per month" but the service enforces "one per week"), and a non-thread-safe singleton in `WidgetContainerCache` that can crash or corrupt state on concurrent timeline refreshes. Three warnings cover a stale-data window in `StatsView`, a silent wrong-tier fallback in the `Goal.tier` accessor, and an accessibility label that double-evaluates a force-unwrap in the progress row.

---

## Critical Issues

### CR-01: Freeze-limit UI contract mismatches the service: "once per month" vs "once per ISO week"

**File:** `VitaminG/VitaminG/VitaminG/Views/StatsView.swift:113`

**Issue:** The confirmation dialog message shown to the user reads:

> "You get one freeze per month. This will protect today's streak even if you miss a day."

`StreakFreezeService.canFreezeRelativeTo(_:)` enforces exactly one freeze per ISO 8601 calendar **week** (keyed on `weekOfYear` + `yearForWeekOfYear`). The doc-comment on `canFreeze` also says "once per ISO8601 week." A user who freezes on, say, Monday of week 20 will find the button disabled again on Tuesday of the same week — but they were told they had a monthly allowance. Conversely, a user can freeze up to ~4 times per month because the window resets every Monday. This is a product-level correctness bug: one branch of the UI/service pair is wrong, and whichever is intended, they must agree.

**Fix:** Choose the intended cadence and make both sides consistent.

*If the intent is weekly (matches service):*
```swift
// StatsView.swift line 113 — change dialog message
Text("You get one freeze per week. This will protect today's streak even if you miss a day.")
```
*If the intent is monthly (change service):*
```swift
// StreakFreezeService.swift — replace canFreezeRelativeTo with month-based check
func canFreezeRelativeTo(_ date: Date) -> Bool {
    guard let lastDate = lastFreezeDate else { return true }
    let cal = Calendar(identifier: .iso8601)
    let lastMonth = cal.component(.month, from: lastDate)
    let thisMonth = cal.component(.month, from: date)
    let lastYear  = cal.component(.year,  from: lastDate)
    let thisYear  = cal.component(.year,  from: date)
    return lastMonth != thisMonth || lastYear != thisYear
}
```
Also update the `canFreeze` doc-comment in `StreakFreezeService` to match.

---

### CR-02: `WidgetContainerCache.shared` is not thread-safe — concurrent timeline refreshes can race and crash

**File:** `VitaminG/VitaminG/VitaminGWidget/GoalSummaryWidget.swift:27-34`

**Issue:** `WidgetContainerCache.shared` is a computed property on an `enum` (no synchronisation primitive). The comment acknowledges that `GoalSummaryProvider` and `StreakProvider` share this singleton "to avoid redundant allocations." WidgetKit can call `getTimeline` on multiple providers concurrently in the same extension process. Two concurrent callers can both observe `_container == nil`, both call `ModelContainerFactory.makeWidgetContainer()`, and both assign to `_container`, racing on a stored `Optional<ModelContainer>`. Swift does not guarantee atomic reads/writes to class-reference stored properties on enums. The result is either:
- A second `ModelContainer` instance is created and immediately orphaned (non-crashing but defeats the purpose of the cache), or
- A torn read delivers a partially-constructed pointer to the second caller (crash).

```swift
enum WidgetContainerCache {
    private static var _container: ModelContainer?  // ← unprotected mutable static

    static var shared: ModelContainer {
        get throws {
            if let existing = _container { return existing }  // ← first race window
            let container = try ModelContainerFactory.makeWidgetContainer()
            _container = container                             // ← second race window
            return container
        }
    }
}
```

**Fix:** Protect with an `NSLock` or restructure as a `lazy` property on an actor:

```swift
enum WidgetContainerCache {
    private static let lock = NSLock()
    private static var _container: ModelContainer?

    static var shared: ModelContainer {
        get throws {
            lock.lock()
            defer { lock.unlock() }
            if let existing = _container { return existing }
            let container = try ModelContainerFactory.makeWidgetContainer()
            _container = container
            return container
        }
    }
}
```

Alternatively, since `ModelContainerFactory.makeWidgetContainer()` is not `async`, a `lazy static` initializer in a struct or actor provides guaranteed one-time initialisation without a manual lock.

---

## Warnings

### WR-01: `StatsView` refresh does not fire when a goal's `isCompleted` field changes — only on count changes

**File:** `VitaminG/VitaminG/VitaminG/Views/StatsView.swift:40-45`

**Issue:** The view refreshes `viewModel` only when `events.count` or `goals.count` changes:

```swift
.onChange(of: events.count) { … }
.onChange(of: goals.count)  { … }
```

If a goal is marked complete (or un-complete), the `goals` array has the **same count** — one element changed from `isCompleted = false` to `isCompleted = true`. The `onChange` will not fire, so `globalStreak`, `tierStreaks`, `tierCompletionRates`, and `tierGoalCounts` all show stale values until the view disappears and reappears.

In practice this means: a user checks in on their last goal for the day, the streak increments in the underlying data, but the Stats screen continues to show the old streak number. This is a visible correctness regression.

**Fix:** Observe a stable hash of the completion state alongside the count, or trigger on a property that changes on every mutation. The idiomatic SwiftUI approach for `@Query` arrays is to observe the full array itself (Swift 5.9 / iOS 17 two-argument form handles identity changes):

```swift
.onChange(of: events) {
    viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
}
.onChange(of: goals) {
    viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
}
```

If array-level diffing is too broad for performance, observe a computed summary value:
```swift
.onChange(of: goals.map { $0.isCompleted }) {
    viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
}
```

---

### WR-02: Silent wrong-tier fallback in `Goal.tier` accessor can silently misroute goals in the widget

**File:** `VitaminG/VitaminG/VitaminG/Models/SchemaV10.swift:109` (used by `WidgetDataProvider.swift:69`)

**Issue:** `WidgetDataProvider.build` filters goals by `$0.tier == tier`. The `tier` computed accessor falls back to `.immediate` when `tierRawValue` is nil or an unrecognised string:

```swift
var tier: GoalTier {
    get { GoalTier(rawValue: tierRawValue ?? "") ?? .immediate }
```

A goal with a missing or corrupted `tierRawValue` (possible after a failed CloudKit sync write or a schema migration that doesn't backfill the field) silently appears as an **Immediate** goal in every tier-filtered widget row. This means:
1. The Immediate tier row shows a goal that doesn't belong there.
2. The correct tier row shows nothing (or the wrong "top" goal).
3. The `activeGoal` computation picks this ghost goal as the highest-priority item.

Because `WidgetDataProvider` is built from whatever array is fetched, it has no defence against this silent misclassification.

**Fix:** Filter out goals with unrecognised tier values before building the tier rows. In `WidgetDataProvider.build`, add a guard:

```swift
let topTitle = goals
    .filter {
        $0.tier == tier          // existing filter
        && $0.tierRawValue != nil  // exclude unclassifiable goals
        && $0.tierRawValue != ""
        && !$0.isCompleted
    }
    // …
```

Or, more robustly, define a failable computed property on `Goal`:
```swift
var tierIfKnown: GoalTier? {
    GoalTier(rawValue: tierRawValue ?? "")
}
```
and use `$0.tierIfKnown == tier` in the filter.

---

### WR-03: Accessibility label in `activeGoalRow` force-unwraps `progress` via `?? 0` after already unwrapping it via `if let`

**File:** `VitaminG/VitaminG/VitaminGWidget/GoalSummaryWidget.swift:147-150`

**Issue:**

```swift
.accessibilityLabel(
    progress != nil
        ? "\(title), \(Int((progress ?? 0) * 100))% complete"
        : title
)
```

The outer call site `activeGoalRow(title:progress:)` is invoked only when `entry.displayData.activeGoalTitle != nil` (line 82). Inside the function, `progress` is the raw `Double?` parameter — not the locally bound `p` from the `if let p = progress` block above. The ternary `progress != nil ? … (progress ?? 0) …` is correct in the sense that it only calls `progress ?? 0` when `progress != nil`, so it will never actually use the `0` fallback. But the `?? 0` is misleading dead code — it implies to readers that `progress` might be nil in that branch, leading to confusion. More importantly, this pattern already existed as dead code before Phase 24; it is being extended with new fields without being cleaned up.

**Fix:** Use the locally bound optional directly:

```swift
.accessibilityLabel(
    p != nil
        ? "\(title), \(Int(p! * 100))% complete"
        : title
)
```

Or restructure so the label is built inside the `if let p = progress` scope:

```swift
private func activeGoalRow(title: String, progress: Double?) -> some View {
    let label = progress.map { p in "\(title), \(Int(p * 100))% complete" } ?? title
    return VStack(alignment: .leading, spacing: 4) {
        // …
    }
    .accessibilityLabel(label)
}
```

---

## Info

### IN-01: `WidgetDataProvider.build` performs identical sort twice — active-goal search duplicates tier-row sort

**File:** `VitaminG/VitaminG/VitaminG/Services/WidgetDataProvider.swift:65-82`

**Issue:** The `tierRows` loop (lines 65–73) and the `activeGoal` computation (lines 77–82) both iterate over `GoalTier.ordered`, filter by tier, sort by `creationDate`, and pick `.first`. The two code blocks are semantically identical for the Immediate tier (which is always the active goal's tier when non-empty). For a small goal list this is harmless, but it is duplicated logic that must be kept in sync if the selection rule changes.

**Fix:** Capture the per-tier top-goal during the first pass and reuse it:

```swift
var tierRows: [WidgetDisplayData.TierRow] = []
var activeGoal: Goal? = nil

for tier in GoalTier.ordered {
    let top = goals
        .filter { $0.tier == tier && !$0.isCompleted }
        .sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
        .first
    tierRows.append(WidgetDisplayData.TierRow(tier: tier, topGoalTitle: top?.title))
    if activeGoal == nil, let top { activeGoal = top }
}
```

---

### IN-02: Test suite has no coverage for `durationDays == 0` (the guard condition distinct from `nil`)

**File:** `VitaminG/VitaminG/VitaminGTests/Phase24WidgetDataProviderTests.swift:75-85`

**Issue:** Test 4 covers `durationDays: nil → activeGoalProgress == nil`. The production guard in `WidgetDataProvider.swift:90-91` is:

```swift
guard let duration = goal.durationDays, duration > 0 else { return nil }
```

The `duration > 0` branch (where `durationDays` is a non-nil integer set to `0`) is a distinct code path that is not tested. A goal created with `durationDays: 0` via direct SwiftData mutation (e.g., a buggy migration or edit flow) would silently return `nil` for progress rather than producing `0.0` or crashing. If the intent is that `0` is treated identically to `nil`, a test asserting that is both documentation and a regression guard.

**Fix:** Add a test:

```swift
func test_activeGoalProgress_nilWhenDurationIsZero() throws {
    let goal = Goal(title: "Zero Duration Goal", tier: .immediate, durationDays: 0)
    context.insert(goal)
    try context.save()

    let goals = try context.fetch(FetchDescriptor<Goal>())
    let result = WidgetDataProvider.build(goals: goals, events: [])

    XCTAssertNil(result.activeGoalProgress,
                 "activeGoalProgress must be nil when durationDays is 0")
}
```

---

_Reviewed: 2026-05-28T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
