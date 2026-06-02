---
phase: 26-analytics-dashboard
reviewed: 2026-06-02T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - VitaminG/VitaminG/VitaminG/ViewModels/AnalyticsViewModel.swift
  - VitaminG/VitaminG/VitaminG/Views/AllTimeHeatmapView.swift
  - VitaminG/VitaminG/VitaminG/Views/AnalyticsView.swift
  - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
  - VitaminG/VitaminG/VitaminG/Views/GoalAllTimeHeatmapView.swift
  - VitaminG/VitaminG/VitaminG/Views/StatsView.swift
  - VitaminG/VitaminG/VitaminGTests/Phase26AnalyticsViewModelTests.swift
  - VitaminG/VitaminG/VitaminG/Services/CSVExportService.swift
  - VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift
findings:
  critical: 3
  warning: 5
  info: 3
  total: 11
status: issues_found
---

# Phase 26: Code Review Report

**Reviewed:** 2026-06-02
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Phase 26 introduces an analytics dashboard (completion-rate bar chart, per-goal all-time heatmaps, CSV export) across `AnalyticsViewModel`, `AnalyticsView`, `AllTimeHeatmapView`, `GoalAllTimeHeatmapView`, `CSVExportService`, and supporting navigation. The core ViewModel logic is well-structured and correctly placed. The major concerns are: (1) CSV injection is only partially mitigated — the `date` and `is_frozen` columns are never escaped, and `goal.title` contains a known, validated user-input path that can still inject newlines; (2) the global CSV is built on every SwiftUI body re-evaluation of `AnalyticsView`, which violates the MVVM constraint and causes correctness surprises; (3) `AllTimeHeatmapView.weeks` is a computed property that re-executes on every render inside `LazyHStack`, defeating lazy rendering.

---

## Critical Issues

### CR-01: CSV Injection via Unescaped Newlines in `goal.title`

**File:** `VitaminG/VitaminG/VitaminG/Services/CSVExportService.swift:91`

**Issue:** `csvEscaped` wraps the value in double-quotes and escapes internal `"` characters but does **not** strip or escape embedded newline (`\n`) and carriage-return (`\r`) characters. RFC 4180 §2.6 states that fields containing line breaks MUST be enclosed in double-quotes; the implementation does enclose them, so the file is technically RFC-4180 conformant. However, virtually every spreadsheet application (Excel, Numbers, Google Sheets) interprets an embedded `\n` inside a quoted field as a literal record break, splitting one row into multiple rows. A goal title such as `"Morning run\nDrop column"` produces a spurious extra row in the spreadsheet with no `date`, `tier`, or `is_frozen` value — corrupting the exported data. Because goal titles are arbitrary user input (no newline sanitization is enforced at the model layer), this is a data-corruption path that ships in the export feature.

**Fix:**
```swift
var csvEscaped: String {
    // Strip CR and LF before quoting — spreadsheet apps treat embedded
    // newlines as record breaks even inside quoted fields.
    let sanitized = self
        .replacingOccurrences(of: "\r\n", with: " ")
        .replacingOccurrences(of: "\r", with: " ")
        .replacingOccurrences(of: "\n", with: " ")
    let escaped = sanitized.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escaped)\""
}
```

---

### CR-02: `goalTitle` Injected Directly into ShareLink `preview` Label Without Sanitization

**File:** `VitaminG/VitaminG/VitaminG/Views/GoalAllTimeHeatmapView.swift:82-92`

**Issue:** The `SharePreview` filename is constructed as:

```swift
let goalTitle = goal.title ?? "goal"
// ...
preview: SharePreview("vitamin-g-\(goalTitle)-\(dateStamp).csv", ...)
```

`goalTitle` is raw user input. Any `/` character in the title produces an invalid file path component (iOS will either reject the share or silently truncate). Characters such as `:`, `*`, `?`, `<`, `>`, `|` are illegal in file names on Windows (a common export target). A title like `"Finance / Budget"` produces a preview name of `"vitamin-g-Finance / Budget-2026-06-02.csv"` — the slash causes silent truncation to `"vitamin-g-Finance "` on many share destinations. This is a user-visible data loss and could confuse users into thinking the export failed.

**Fix:**
```swift
// Sanitize goal title for use in a filename: strip path-separator and
// control characters, collapse whitespace.
let safeTitle = (goal.title ?? "goal")
    .replacingOccurrences(of: "/", with: "-")
    .replacingOccurrences(of: ":", with: "-")
    .components(separatedBy: .controlCharacters).joined(separator: "")
    .trimmingCharacters(in: .whitespaces)
let csvContent = CSVExportService.buildGoalCSV(
    goal: goal, events: Array(events), frozenDates: frozenDates
)
// Use safeTitle in SharePreview
```

---

### CR-03: Global CSV Built on Every `body` Re-evaluation (MVVM Violation + Stale-Data Risk)

**File:** `VitaminG/VitaminG/VitaminG/Views/AnalyticsView.swift:141-162`

**Issue:** `globalExportButton` is a `private var` (computed property), so `CSVExportService.buildGlobalCSV(...)` executes on every SwiftUI body re-render of `AnalyticsView`. This violates the MVVM rule from `CLAUDE.md` ("no business logic in Views"). More critically, there is a stale-data risk: `AnalyticsView.body` can render using a stale `events` / `goals` snapshot before `viewModel.refresh` has been called (e.g., on the very first render, `onAppear` has not fired yet). The CSV content handed to `ShareLink` is captured at render time, not at share time — so a user who opens Analytics and immediately taps Export before scrolling may receive a CSV built from the stale pre-`onAppear` state. Additionally, building the full CSV string eagerly on every re-render (granularity picker change, sheet dismiss, etc.) is wasteful and produces a new `String` allocation each time even though the user may never tap Export.

**Fix:** Move CSV computation into `AnalyticsViewModel` and expose it as a lazy property or compute it only when the export action fires:

```swift
// In AnalyticsViewModel:
private(set) var globalCSVContent: String = ""

func refresh(events: [CompletionEvent], goals: [Goal], frozenDates: [Date] = []) {
    allGoals = goals
    weeklyBuckets  = buildWeeklyBuckets(events: events)
    monthlyBuckets = buildMonthlyBuckets(events: events)
    // build heatmap data...
    globalCSVContent = CSVExportService.buildGlobalCSV(
        events: events, goals: goals, frozenDates: frozenDates
    )
}

// In AnalyticsView.globalExportButton:
ShareLink(item: viewModel.globalCSVContent, ...)
```

---

## Warnings

### WR-01: `AllTimeHeatmapView.weeks` Computed Property Defeats `LazyHStack` Laziness

**File:** `VitaminG/VitaminG/VitaminG/Views/AllTimeHeatmapView.swift:24-41`

**Issue:** `weeks` is a `private var` (computed property, not `private let` or cached). `LazyHStack` calls the `ForEach` initializer eagerly to build its internal column index, which dereferences `weeks` — evaluating the full date-arithmetic loop from `startDate` to today. For a goal created years ago this loop runs hundreds of iterations on each render pass. Because `weeks` has no `@State` or memoization backing, it recomputes on every view update (e.g., every time the parent `ScrollView` scrolls). The property should be converted to a stored, lazily-computed value.

**Fix:**
```swift
// Replace the computed `var weeks` with a stored property set once in body
// or cache via @State:
@State private var cachedWeeks: [[Date]]? = nil

private func buildWeeks() -> [[Date]] { /* existing logic */ }

var body: some View {
    let weeks = cachedWeeks ?? buildWeeks()
    // ...
    .onAppear { cachedWeeks = buildWeeks() }
}
```
Or simply change the property to `private let weeks: [[Date]]` by making the view a struct that takes the computed value as a parameter from its parent.

---

### WR-02: `onChange(of:)` Tracks Only `.count` — Misses In-Place Mutations

**File:** `VitaminG/VitaminG/VitaminG/Views/AnalyticsView.swift:44-49`
**File:** `VitaminG/VitaminG/VitaminG/Views/StatsView.swift:41-46`

**Issue:** Both views refresh the ViewModel only when `events.count` or `goals.count` changes:

```swift
.onChange(of: events.count) { viewModel.refresh(...) }
.onChange(of: goals.count) { viewModel.refresh(...) }
```

If a `CompletionEvent`'s `completedAt` date is corrected, or a `Goal`'s `title` is updated, the count stays the same and `refresh` is never called. The chart and CSV will display stale data until the user navigates away and back. The same pattern is used in `StatsView` and likely reflects a deliberate tradeoff, but it creates a known inconsistency for mutation-without-count-change.

**Fix:** Use a stable hash of the relevant fields rather than raw count:
```swift
// Track a combined hash of IDs + timestamps to detect mutations
.onChange(of: events.map(\.id)) { viewModel.refresh(...) }
// Or accept the stale-on-mutation limitation and document it explicitly.
```
If count-only tracking is intentional, add a comment explaining the tradeoff so future developers do not introduce bugs trying to "fix" it.

---

### WR-03: Force-Unwrap in `heatmapStartDate` 90-Day Fallback

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/AnalyticsViewModel.swift:90`
**File:** `VitaminG/VitaminG/VitaminG/Views/GoalAllTimeHeatmapView.swift:35`

**Issue:** Both `AnalyticsViewModel.heatmapStartDate(for:)` and the identical fallback in `GoalAllTimeHeatmapView.startDate` use a force-unwrap:

```swift
return Calendar.current.date(byAdding: .day, value: -90, to: Date())!
```

`Calendar.date(byAdding:value:to:)` returning `nil` is exceedingly rare in practice, but the crash surface is real — on a device with a severely corrupted calendar or locale, this will crash with no recovery path. The same logic is duplicated across two files (ViewModel and View), violating DRY.

**Fix:** Use nil-coalescing and consolidate to one call site:
```swift
// In AnalyticsViewModel only:
func heatmapStartDate(for goal: Goal) -> Date {
    if let creation = goal.creationDate { return creation }
    if let earliest = goal.completionEvents?
        .compactMap({ $0.completedAt }).min() { return earliest }
    // Safe fallback — if calendar arithmetic fails, use a fixed 90-day offset
    return Calendar.current.date(byAdding: .day, value: -90, to: Date())
        ?? Date(timeIntervalSinceNow: -90 * 86400)
}
```
Remove the duplicate in `GoalAllTimeHeatmapView` and call `viewModel.heatmapStartDate(for: goal)` — but since `GoalAllTimeHeatmapView` does not hold a reference to the ViewModel, either inject the computed start date as a `let` parameter alongside `heatmapData`, or move the helper to a shared utility.

---

### WR-04: `StreakFreezeService` Instantiated Independently in Both `AnalyticsView` and `StatsView` — Divergent State

**File:** `VitaminG/VitaminG/VitaminG/Views/AnalyticsView.swift:23`
**File:** `VitaminG/VitaminG/VitaminG/Views/StatsView.swift:18`

**Issue:** Both views create their own `@State private var freezeService = StreakFreezeService()`. `StreakFreezeService` reads and writes `UserDefaults` (via `group.com.kyleharrington.VitaminG` suite). Creating two independent instances means each view holds its own in-memory `defaults` reference. A freeze performed in `StatsView` will persist to `UserDefaults`, but `AnalyticsView`'s instance will reflect the new state only after it reads from `UserDefaults` again (i.e., on next `onAppear`). If both views are active in the same `NavigationStack` session the `frozenDates` arrays can transiently diverge, causing the CSV export in `AnalyticsView` to omit a freeze that `StatsView` just applied. The service should be injected as a single instance from the environment.

**Fix:** Inject a shared `StreakFreezeService` via `@Environment` or hold it at the `NavigationStack` root so all descendant views share one instance.

---

### WR-05: `buildGoalCSV` Filters Events by Identity (`===`) Against Events Queried Without a Predicate

**File:** `VitaminG/VitaminG/VitaminG/Services/CSVExportService.swift:46`
**File:** `VitaminG/VitaminG/VitaminG/Views/GoalAllTimeHeatmapView.swift:21,83-87`

**Issue:** `GoalAllTimeHeatmapView` passes `Array(events)` — all events fetched by `@Query` without any predicate — to `buildGoalCSV`, which then uses identity comparison (`===`) to filter:

```swift
let filtered = events.filter { $0.goal === goal }
```

Reference-identity comparison (`===`) against SwiftData `@Model` objects is unreliable when objects are fetched across different `ModelContext` instances. The `goal` received as a `let` parameter was fetched in the parent `AnalyticsView`'s context, while `events` are fetched by `GoalAllTimeHeatmapView`'s own `@Query` in the same or a child context. If the contexts differ (e.g., after a CloudKit sync triggers a context refresh), `===` will fail to match any events, producing an empty CSV body with only the header row. The filter should use value equality on `goal.id`:

```swift
// Safe across context boundaries:
let filtered = events.filter { $0.goal?.id == goal.id }
```

---

## Info

### IN-01: `BucketItem.id` Uses Non-Stable `UUID()` — Breaks SwiftUI Diffing

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/AnalyticsViewModel.swift:9`

**Issue:**
```swift
struct BucketItem: Identifiable {
    let id = UUID()
    ...
}
```
Each call to `refresh` creates new `BucketItem` instances with fresh UUIDs. SwiftUI's `Chart(buckets)` and any `ForEach` over buckets will treat every refresh as a full replacement (no identity continuity), preventing smooth animated transitions. The natural stable identity for a bucket is its `periodStart`.

**Fix:**
```swift
struct BucketItem: Identifiable {
    var id: Date { periodStart }
    let periodStart: Date
    let completionRate: Double
}
```

---

### IN-02: `AppRoute.publicProfile` Carries a Raw `String` Instead of a Typed ID

**File:** `VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift:13`

**Issue:**
```swift
case publicProfile(recordID: String)
```
The comment acknowledges this case is "sheet-only, never pushed onto NavigationStack", yet it still lives in the route enum and the `ContentView` `navigationDestination` handler returns `EmptyView()` for it. The raw `String` recordID has no validation at the type level. This is a pre-existing quality issue surfaced by the Phase 26 `ContentView` changes (adding the `.analytics` case) that touches this switch.

**Fix:** Either validate/type the associated value (`CKRecord.ID`) or document the raw-string requirement with a comment explaining why a typed value is not used.

---

### IN-03: `Phase26AnalyticsViewModelTests` Uses a Separate `ModelContext` Per `makeEvent` Call

**File:** `VitaminG/VitaminG/VitaminGTests/Phase26AnalyticsViewModelTests.swift:41-47`

**Issue:** The `makeEvent` helper creates a new `ModelContext(container)` on each call and inserts the goal a second time. The test for `testWeeklyBuckets` creates a `context` in the test body and also calls `context.insert(goal)` in the helper — meaning the goal object is inserted into two separate contexts derived from the same container. This is not exercised by the current tests (which bypass the helper in favour of inline setup), but the helper as written is misleading and would cause a duplicate-insert crash if called with an already-inserted goal. The helper should be removed or corrected before it is reused.

**Fix:** Remove the `makeEvent` helper (it is unused by any of the four test methods) or rewrite it to accept a context parameter and omit the redundant `context.insert(goal)`.

---

_Reviewed: 2026-06-02_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
