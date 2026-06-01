# Phase 26: Analytics Dashboard - Research

**Researched:** 2026-06-01
**Domain:** Swift Charts, SwiftUI LazyHStack virtualization, CSV export via ShareLink, SwiftData query patterns
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Entry Point & Navigation**
- D-01: `AnalyticsView` is a new view. Entry point is a navigation row/button at the bottom of `StatsView` — zero new wiring required since `StatsView` is already wired off the Home tab.
- D-02: Nav title: `"Analytics"` (`.navigationTitle("Analytics")`, `.navigationBarTitleDisplayMode(.large)`).

**Completion Rate Trends Chart (ANLT-02)**
- D-03: Chart type is `BarMark` — same component pattern as `GoalDetailView`.
- D-04: Segmented control toggle (`Picker` with `.segmented` style) switches between Weekly and Monthly granularity. Single chart area — no stacking.
- D-05: Y-axis definition: % of days with at least one check-in in the period. Formula: `(days with any CompletionEvent in window) / (total calendar days in window) × 100`. Consistent with the existing `ConsistencyEngine` approach.

**All-Time Per-Goal Heatmap (ANLT-03)**
- D-06: Heatmap lives inside `AnalyticsView` — a scrollable goal list; tapping a goal navigates to (or expands) its all-time heatmap section. `GoalDetailView` is unchanged.
- D-07: Horizontal scroll via `LazyHStack` as mandated by REQUIREMENTS.md ANLT-03 note. Each row = one week or one month column of day cells. Must render without stutter for 1000+ days.
- D-08: Goal list shows all goals — active and completed.

**CSV Export (ANLT-04)**
- D-09: Two export surfaces: Global on `AnalyticsView` (all goals) and per-goal on each goal's all-time heatmap view.
- D-10: CSV columns: `goal_name, date, tier, is_frozen`. Header row included. `is_frozen` maps to sentinel -1.
- D-11: Date format: ISO 8601 (`YYYY-MM-DD`).

### Claude's Discretion
- Tier display names in CSV (e.g., "immediate", "short_term", or raw `tierRawValue` strings)
- Export filename convention (e.g., `vitamin-g-history-YYYY-MM-DD.csv` / `vitamin-g-[goal-name]-YYYY-MM-DD.csv`)
- Sort order of CompletionEvents in CSV (date ascending is the obvious default)
- Color palette for bar chart (use `VGTheme.accentTerra` / `VGTheme.accentPurple` gradient or single accent)
- Week/month bucket label format on chart X-axis
- Whether goal list in AnalyticsView uses inline-expand or push-navigation to the heatmap

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ANLT-02 | User opens Analytics view and sees a bar chart (Swift Charts) of weekly and monthly goal completion rate across all active and completed goals | BarMark with `unit: .weekOfYear` / `.month`; `Picker(.segmented)` drives granularity enum; data computed in `AnalyticsViewModel` from all `CompletionEvent` records |
| ANLT-03 | User taps any goal and sees full all-time GitHub-style heatmap from goal creation date to today; renders without stutter for 1000+ days (LazyHStack) | `AllTimeHeatmapView` with `LazyHStack` + `ScrollViewReader.scrollTo(lastID, anchor: .trailing)` on `.onAppear`; column = 1 week, cell = 12×12 pt; reuses `HeatmapView` color logic |
| ANLT-04 | User taps Export on Analytics view and receives CSV via `ShareLink` — goal name, date, tier — no truncation for large histories | `CSVExportService` builds `String` in O(N); `ShareLink(item: csvString, preview: ...)` pattern from `ProfileView.swift`; no file I/O required for in-memory strings |
</phase_requirements>

---

## Summary

Phase 26 delivers three analytics capabilities — all computed from existing `CompletionEvent` and `Goal` SwiftData records with no schema migration. The work is purely additive: one new view (`AnalyticsView`), one new sub-view (`AllTimeHeatmapView`), one new ViewModel (`AnalyticsViewModel`), and one new service (`CSVExportService`).

The completion rate trends chart reuses the `BarMark` pattern already established in `GoalDetailView` at line 453. The chart buckets events by week (`Calendar.weekOfYear`) or month based on a segmented control, and the Y-axis represents percentage of days with at least one check-in — consistent with `ConsistencyEngine`'s philosophy. Swift Charts handles date bucketing natively when `unit:` is passed to `.value("Date", date, unit: .weekOfYear)`.

The all-time heatmap is the most novel piece. The existing `HeatmapView` uses a fixed 90-day `LazyVGrid`; `AllTimeHeatmapView` must use a **horizontal** `LazyHStack` where each column is a week (7 cells). For a goal created 1000+ days ago (~143 weeks), a non-lazy layout would instantiate ~1001 views simultaneously. `LazyHStack` inside a horizontal `ScrollView` only renders visible columns, preventing frame drops. `ScrollViewReader` with a tagged last-column ID scrolls to the most recent week on `.onAppear`. The cell color and snowflake logic is copied verbatim from `HeatmapView.cellColor(for:)`.

CSV export builds an in-memory `String` (never writes to disk), uses `ShareLink(item: csvString, preview: ...)` which already appears in `ProfileView.swift`. The `is_frozen` column reads the -1 sentinel from `StatsViewModel.buildHeatmapData`'s frozen-date logic.

**Primary recommendation:** Create `AnalyticsViewModel` (new) alongside `StatsViewModel` (do not extend); create `AllTimeHeatmapView` alongside `HeatmapView` (do not modify); create `CSVExportService` as a pure function struct; wire `AnalyticsView` as a `NavigationLink` destination added at the bottom of `StatsView`'s `VStack`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Completion rate computation (D-05 formula) | ViewModel (`AnalyticsViewModel`) | Service (`StreakEngine` extension or standalone method) | Business logic must not live in View; `StreakEngine` precedent for pure computation structs |
| Chart rendering (ANLT-02) | View (`AnalyticsView`) | — | Swift Charts is a pure display framework; data pre-computed by ViewModel |
| All-time heatmap data builder | ViewModel (`AnalyticsViewModel`) | Reuses `buildHeatmapData` logic | Per-goal `[Date: Int]` dict must be pre-built for O(1) cell lookup — same pattern as `StatsViewModel` |
| Heatmap rendering (ANLT-03) | View (`AllTimeHeatmapView`) | — | Pure display component; receives pre-built `[Date: Int]` + `startDate` |
| CSV string construction (ANLT-04) | Service (`CSVExportService`) | — | Pure function; no SwiftUI or SwiftData dependency; testable in isolation |
| Navigation entry point | View (`StatsView`) | — | D-01: NavigationLink added at bottom of existing StatsView VStack |

---

## Standard Stack

### Core
| Framework | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Swift Charts | iOS 16+ (VERIFIED in codebase) | `BarMark` for completion rate chart | Already imported in `GoalDetailView`; no new dependency |
| SwiftUI `LazyHStack` | iOS 14+ | Virtualized horizontal heatmap | Built-in; required by ANLT-03 mandate |
| SwiftUI `ScrollViewReader` | iOS 14+ | Scroll-to-end on heatmap appear | Built-in; pairs with `LazyHStack` |
| SwiftUI `ShareLink` | iOS 16+ | CSV file sharing | Already used in `ProfileView.swift`; no new dependency |
| SwiftData `@Query` | iOS 17+ | Fetching `CompletionEvent` + `Goal` | Project minimum; established pattern |
| `@Observable` (`@MainActor`) | iOS 17+ | `AnalyticsViewModel` | Project convention; matches `StatsViewModel` |

### No New Package Dependencies
This phase introduces zero new third-party dependencies. All required APIs are part of the iOS SDK.

---

## Package Legitimacy Audit

No external packages are installed in this phase. All capabilities are implemented using Apple SDK frameworks (Swift Charts, SwiftUI, SwiftData). This section is not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
StatsView (existing, unmodified except bottom nav row)
    │
    └─► NavigationLink ──► AnalyticsView
                                │
                ┌───────────────┼──────────────────┐
                ▼               ▼                  ▼
         Chart section    Goal list           Export button
         (BarMark)        (scrollable)        (ShareLink)
                               │
                               └─► AllTimeHeatmapView (per goal)
                                        │           │
                               LazyHStack        Export button
                               columns          (per-goal ShareLink)
                               (weeks)

Data flow:
@Query([CompletionEvent]) ──► AnalyticsViewModel.refresh()
@Query([Goal])             ──►     │
                                   ├── completionRateBuckets: [BucketItem]
                                   ├── heatmapDataByGoal: [UUID: [Date: Int]]
                                   └── (passed to views as plain value types)

CSVExportService.buildGlobalCSV(events:goals:frozenDates:) → String
CSVExportService.buildGoalCSV(goal:events:frozenDates:) → String
    └── ShareLink(item: csvString, preview: SharePreview(filename))
```

### Recommended Project Structure

New files to create:
```
VitaminG/
├── ViewModels/
│   └── AnalyticsViewModel.swift     # new — @MainActor @Observable
├── Views/
│   ├── AnalyticsView.swift          # new — top-level analytics screen
│   └── AllTimeHeatmapView.swift     # new — LazyHStack heatmap
├── Services/
│   └── CSVExportService.swift       # new — pure struct, no SwiftUI dependency
VitaminGTests/
└── Phase26AnalyticsViewModelTests.swift  # new — Wave 0 test scaffold
```

Files to modify:
```
Views/StatsView.swift               # add NavigationLink at bottom of VStack (D-01)
Navigation/AppRoute.swift           # add .analytics case
Views/ContentView.swift             # add case .analytics: AnalyticsView() in Home tab destination
```

### Pattern 1: BarMark with Date Bucketing (ANLT-02)

**What:** Weekly/monthly completion rate chart using Swift Charts `BarMark` with temporal `unit:` parameter.
**When to use:** Aggregating discrete events into time-period buckets for display.

```swift
// Source: GoalDetailView.swift line 453 (codebase) — adapted for period buckets
// Granularity enum drives the Picker toggle
enum ChartGranularity { case weekly, monthly }

// BucketItem fed to Chart
struct BucketItem: Identifiable {
    let id = UUID()
    let periodStart: Date
    let completionRate: Double  // 0.0–1.0
}

// In AnalyticsView:
Chart(viewModel.buckets) { item in
    BarMark(
        x: .value("Period", item.periodStart, unit: granularity == .weekly ? .weekOfYear : .month),
        y: .value("Rate", item.completionRate)
    )
    .foregroundStyle(VGTheme.accentTerra)
}
.chartYAxis {
    AxisMarks(format: .percent)
}
.frame(height: 180)
```

**D-05 Formula Implementation in `AnalyticsViewModel`:**

```swift
// Source: ConsistencyEngine.swift (codebase) — adapted for bucketed periods
func buildWeeklyBuckets(events: [CompletionEvent]) -> [BucketItem] {
    let calendar = Calendar.current
    // Group events by start-of-week
    var weekMap: [Date: Set<Date>] = [:]  // weekStart -> Set of unique day dates
    for event in events {
        guard let date = event.completedAt else { continue }
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start
            ?? calendar.startOfDay(for: date)
        let day = calendar.startOfDay(for: date)
        weekMap[weekStart, default: []].insert(day)
    }
    return weekMap.sorted { $0.key < $1.key }.map { (weekStart, days) in
        // Calendar days in this week (always 7 unless it's the current partial week)
        let daysInPeriod: Double = 7
        BucketItem(
            periodStart: weekStart,
            completionRate: Double(days.count) / daysInPeriod
        )
    }
}
```

### Pattern 2: LazyHStack All-Time Heatmap (ANLT-03)

**What:** Horizontally scrolling heatmap where each column = one week of 7 day cells.
**When to use:** Displaying 1000+ day activity grids without frame drops.

```swift
// Source: HeatmapView.swift (codebase) — axis changed, start date dynamic
// AllTimeHeatmapView.swift
struct AllTimeHeatmapView: View {
    let data: [Date: Int]         // pre-built by AnalyticsViewModel
    let startDate: Date           // goal.creationDate

    private var weeks: [[Date]] {
        // Build array of weeks from startDate to today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var weeks: [[Date]] = []
        var weekStart = calendar.dateInterval(of: .weekOfYear, for: startDate)?.start ?? startDate
        while weekStart <= today {
            let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
            weeks.append(days)
            weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? today
        }
        return weeks
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 3) {
                    ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                        VStack(spacing: 3) {
                            ForEach(week, id: \.self) { day in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(cellColor(for: data[day] ?? 0))
                                        .frame(width: 12, height: 12)
                                    if data[day] == -1 {
                                        Image(systemName: "snowflake")
                                            .font(.system(size: 7))
                                            .foregroundStyle(Color.blue)
                                    }
                                }
                            }
                        }
                        .id(index)  // tag for ScrollViewReader
                    }
                }
                .padding(.horizontal, 8)
            }
            .onAppear {
                // Scroll to most recent week without animation (no flash)
                proxy.scrollTo(weeks.count - 1, anchor: .trailing)
            }
        }
    }

    // Verbatim from HeatmapView.cellColor(for:)
    private func cellColor(for count: Int) -> Color { ... }
}
```

### Pattern 3: CSV Export via ShareLink (ANLT-04)

**What:** In-memory CSV string built by a pure service, shared via `ShareLink`.
**When to use:** Exporting structured data to Files, Mail, or any share-sheet recipient.

```swift
// Source: ProfileView.swift line 472 (codebase) — same ShareLink pattern
// CSVExportService.swift
struct CSVExportService {
    static func buildGlobalCSV(events: [CompletionEvent], goals: [Goal], frozenDates: [Date]) -> String {
        var rows = ["goal_name,date,tier,is_frozen"]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]  // YYYY-MM-DD only

        // Build frozen-date lookup from StatsViewModel.buildHeatmapData logic
        let frozenDaySet = Set(frozenDates.map { Calendar.current.startOfDay(for: $0) })

        // Sort events by date ascending (Claude's discretion default)
        let sorted = events.sorted {
            ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast)
        }
        for event in sorted {
            guard let date = event.completedAt else { continue }
            let goalName = (event.goal?.title ?? "Unknown").csvEscaped
            let dateStr = formatter.string(from: date)
            let tier = event.tierRawValue ?? "unknown"
            let day = Calendar.current.startOfDay(for: date)
            let isFrozen = frozenDaySet.contains(day) ? "true" : "false"
            rows.append("\(goalName),\(dateStr),\(tier),\(isFrozen)")
        }
        return rows.joined(separator: "\n")
    }
}

// In AnalyticsView:
let today = Date().formatted(.iso8601.year().month().day())
ShareLink(
    item: CSVExportService.buildGlobalCSV(events: events, goals: goals, frozenDates: frozenDates),
    preview: SharePreview("vitamin-g-history-\(today).csv", image: Image(systemName: "doc.text"))
) {
    Label("Export CSV", systemImage: "square.and.arrow.up")
}
```

### Pattern 4: Navigation Wiring (AppRoute + ContentView)

**What:** Add `.analytics` case to `AppRoute` and register destination in Home tab's `NavigationStack`.
**When to use:** Any new full-screen navigation destination reachable from the Home tab stack.

```swift
// AppRoute.swift — add one case:
case analytics   // Phase 26 — ANLT-02/03/04

// ContentView.swift — Home tab navigationDestination, add one case:
case .analytics: AnalyticsView()

// StatsView.swift — at bottom of ScrollView VStack, before closing brace:
NavigationLink(value: AppRoute.analytics) {
    HStack {
        Label("Analytics", systemImage: "chart.bar.doc.horizontal")
            .font(.body).fontDesign(.rounded)
        Spacer()
        Image(systemName: "chevron.right")
            .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 4)
}
.buttonStyle(.plain)
```

### Anti-Patterns to Avoid

- **Modifying `HeatmapView`:** The 90-day `LazyVGrid` view is used by `StatsView` and must remain unchanged. Create `AllTimeHeatmapView` as a sibling, sharing only the `cellColor` logic (copy or extract to a shared helper).
- **Modifying `GoalDetailView`:** D-06 is explicit — `GoalDetailView` is unchanged. The all-time heatmap is only in `AnalyticsView`.
- **Extending `StatsViewModel`:** Create `AnalyticsViewModel` separately to keep `StatsViewModel` focused on the existing Stats screen. Shared logic (bucket building, heatmap builder) belongs in a service struct, not in `StatsViewModel`.
- **Writing CSV to disk:** `ShareLink` accepts a `String` directly (iOS 16+). No `FileManager` or `URL` needed for in-memory strings. Avoid creating temporary files — memory is cheaper and avoids cleanup obligations.
- **Fetching inside `AllTimeHeatmapView`:** Keep it a pure display component per project convention. `AnalyticsViewModel` owns data preparation; the view receives pre-computed `[Date: Int]`.
- **Non-lazy column rendering for large heatmaps:** Using `HStack` (not `LazyHStack`) would instantiate all ~143+ week columns at once for a 1000-day goal. This causes visible lag on scroll entry. Use `LazyHStack` even for shorter histories.
- **Force-unwrapping `goal.creationDate`:** `creationDate` is `Date?` in `SchemaV10.Goal`. Always guard against nil — fall back to `goal.completionEvents?.compactMap(\.completedAt).min() ?? Date()`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Date bucketing into weeks/months | Custom calendar arithmetic | `BarMark(x: .value("P", date, unit: .weekOfYear))` | Swift Charts handles grouping and x-axis labels natively |
| CSV special characters (commas, quotes in goal names) | Custom escape logic | Simple `String` extension: replace `"` with `""`, wrap field in quotes if contains comma/quote/newline | RFC 4180 escaping is 4 lines; no library needed |
| Scroll-to-end on heatmap | Manual `CGPoint` offset calculation | `ScrollViewReader { proxy in ... proxy.scrollTo(lastID, anchor: .trailing) }` | SwiftUI built-in; handles content size changes |
| Per-goal event filtering | Raw loop over all events | `events.filter { $0.goal?.id == goal.id }` | SwiftData relationship traversal is O(N) but data already in memory; no new query needed |
| Heatmap color intensity | Custom gradient math | Copy `cellColor(for:)` from `HeatmapView.swift` | Logic already verified and tested; duplication is correct here since the views are separate |

**Key insight:** Swift Charts' `unit:` parameter on date values is the key to avoiding all manual week/month bucketing. Pass the raw event dates — let Swift Charts aggregate. The only custom computation needed is the Y-axis percentage formula (D-05).

---

## Common Pitfalls

### Pitfall 1: Goal `creationDate` Is Optional
**What goes wrong:** `AllTimeHeatmapView` crashes or shows a heatmap from epoch if `goal.creationDate` is nil-unwrapped.
**Why it happens:** `SchemaV10.Goal.creationDate: Date?` — all properties optional for CloudKit compatibility.
**How to avoid:** In `AnalyticsViewModel`, compute heatmap start date as:
```swift
let start = goal.creationDate
    ?? goal.completionEvents?.compactMap(\.completedAt).min()
    ?? Calendar.current.date(byAdding: .day, value: -90, to: Date())!
```
**Warning signs:** Heatmap shows data from 1970 or crashes on tap of a goal without a creation date.

### Pitfall 2: Segmented Control State Not Propagated to ViewModel
**What goes wrong:** Switching from Weekly to Monthly (or vice versa) does not update the chart because the picker binding is `@State` in the view but `AnalyticsViewModel` holds pre-computed buckets.
**Why it happens:** `@Observable` ViewModels do not automatically re-run computation when a view-local enum changes.
**How to avoid:** Either (a) compute both weekly and monthly bucket arrays in `refresh()` and select by granularity in the view body, or (b) expose a `granularity` property on the ViewModel and trigger recompute in `didSet`. Option (a) is simpler and avoids the timing issue.

### Pitfall 3: CSV Goal Name Contains Comma or Quote
**What goes wrong:** CSV is malformed — Numbers/Excel treats the comma as a column delimiter and splits goal titles.
**Why it happens:** Goal titles are user-entered strings with no character restriction on commas or double-quotes.
**How to avoid:** RFC 4180 escaping — wrap every field in double-quotes and double any embedded double-quotes:
```swift
extension String {
    var csvEscaped: String {
        let escaped = self.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
```
Apply to `goal_name` and `tier` fields (tier values are enum rawValues so safe, but apply consistently).
**Warning signs:** Test with a goal title like `"My "dream" goal, for real"`.

### Pitfall 4: LazyHStack Column Count Off-by-One at Week Boundaries
**What goes wrong:** The most recent day is in a partial week column; the last column is cut short or the scroll target is wrong.
**Why it happens:** `Calendar.dateInterval(of: .weekOfYear, for: today)` returns the ISO Monday-anchored week. If today is Wednesday, the current week column only has 3 cells (Mon–Wed).
**How to avoid:** Build the weeks array from `startDate` forward to "start of week containing today" + fill remaining days. Cap each day cell render at `<= today` — future day cells within the current week are rendered with count 0 (no check-in yet). The `ScrollViewReader` target is `weeks.count - 1` regardless of column length.
**Warning signs:** Week column shows 7 greyed cells for the current week even on a Wednesday.

### Pitfall 5: Chart Performance with Large Event Arrays
**What goes wrong:** The chart hangs on first render for users with 2+ years of data (~730 daily events, potentially more with multiple goals).
**Why it happens:** Computing bucket arrays synchronously on the main thread during `onAppear` blocks the render pass.
**How to avoid:** `AnalyticsViewModel.refresh()` should be called with `Task { await MainActor.run { ... } }` or, more simply, compute on a background actor and assign back to `@MainActor` properties. Given the project's existing pattern (all ViewModels are `@MainActor @Observable` with synchronous `refresh()`), the pragmatic mitigation is to keep the computation O(N) and trust that even 10,000 events processes in <1ms in Swift. Only add `Task` background dispatch if profiling shows a real issue.

### Pitfall 6: ShareLink on iOS 16 with String Type
**What goes wrong:** `ShareLink(item: csvString, ...)` may not show correct file extension hint on iOS 16.
**Why it happens:** `ShareLink` with a plain `String` item uses the `UTType.plainText` type, which may not present as a `.csv` file in some share destinations.
**How to avoid:** Use `ShareLink` with a `String` and `SharePreview` that includes a filename ending in `.csv`. iOS 17+ handles this correctly. For the project target (iOS 17+), this is a non-issue. If iOS 16 compatibility were needed, wrap in a `URL` pointing to a temp file — but this project is iOS 17 minimum.

---

## Code Examples

### Critical Field Verification: Goal `creationDate`
[VERIFIED: codebase SchemaV10.swift line 48–118]

```swift
// SchemaV10.Goal uses:
var creationDate: Date?   // NOT createdAt — field name is creationDate
```

The CONTEXT.md canonical ref says "confirm `createdAt` field name before planning." The actual field is `creationDate` (not `createdAt`). This is verified by reading `SchemaV10.swift` directly.

### CompletionEvent Fields Available for CSV
[VERIFIED: codebase Schema8pV2.swift (SchemaV2.CompletionEvent)]

```swift
// CompletionEvent fields:
var completedAt: Date?          // → ISO 8601 date column
var tierRawValue: String?       // → tier column; rawValues: "Immediate", "Short-Term", "Long-Term", "Life Goal"
var goal: SchemaV10.Goal?       // → goal?.title for goal_name column
```

The `is_frozen` column (D-10) is **not** stored on `CompletionEvent`. It must be derived at export time by checking if the event's day is in the `frozenDates` set from `StreakFreezeService`.

### GoalTier Raw Values (for CSV tier column)
[VERIFIED: codebase Goal.swift]

```swift
case immediate  = "Immediate"
case shortTerm  = "Short-Term"
case longTerm   = "Long-Term"
case lifeGoal   = "Life Goal"
```

Claude's discretion (from CONTEXT.md): use `tierRawValue` directly — these are the authoritative string representations. No transformation needed.

### Existing BarMark Pattern (exact reuse target)
[VERIFIED: codebase GoalDetailView.swift line 453–467]

```swift
Chart(chartItems) { item in
    BarMark(
        x: .value("Day", item.date, unit: .day),  // change .day to .weekOfYear or .month
        y: .value("Count", item.count)             // change to completionRate (Double)
    )
    .foregroundStyle(goal.tier.color)              // change to VGTheme.accentTerra
}
.frame(height: 80)                                 // increase to ~180 for analytics chart
.chartYAxis(.hidden)                               // show Y-axis with .percent format
```

### NavigationLink to AnalyticsView (StatsView integration)
[VERIFIED: codebase — AppRoute enum uses value-based NavigationLink pattern; StatsView confirmed uses Home tab's NavigationStack]

```swift
// StatsView.swift — inside the ScrollView VStack, after heatmapSection:
NavigationLink(value: AppRoute.analytics) {
    Label("Analytics", systemImage: "chart.bar.doc.horizontal")
}
// ContentView.swift — Home tab navigationDestination, add:
case .analytics: AnalyticsView()
// AppRoute.swift — add:
case analytics   // Phase 26
```

Note: `StatsView` is reached via `.stats` case in the Home tab's `navigationDestination(for: AppRoute.self)`. Adding `.analytics` to the same destination block maintains the navigation stack correctly. `AnalyticsView` does NOT need to be added to the Goals tab's separate `NavigationStack`.

### ShareLink Pattern (ProfileView.swift reference)
[VERIFIED: codebase ProfileView.swift line 472]

```swift
// Existing usage:
ShareLink(item: url, subject: Text("Vitamin G Profile"),
          message: Text("Check out my goals on Vitamin G!")) {
    Label("Share Profile", systemImage: "square.and.arrow.up")
        .font(.body.weight(.semibold)).fontDesign(.rounded)
}

// Phase 26 adaptation for CSV string:
ShareLink(
    item: csvString,
    preview: SharePreview("vitamin-g-history-\(dateStamp).csv")
) {
    Label("Export CSV", systemImage: "square.and.arrow.up")
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual date bucketing for charts | `BarMark(x: .value("D", date, unit: .weekOfYear))` | iOS 16 / Xcode 14 | Swift Charts aggregates automatically; no custom grouping code needed |
| `ScrollView` + `HStack` for grids | `ScrollView` + `LazyHStack` | iOS 14 | Virtualization prevents memory spikes for large date ranges |
| `UIActivityViewController` for sharing | `ShareLink` | iOS 16 | Declarative SwiftUI; no `UIViewControllerRepresentable` needed |

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (existing) |
| Config file | none — standard Xcode test target |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -testPlan VitaminGTests 2>&1 | grep -E "passed|failed"` |
| Full suite command | Same as quick run — all tests run in one target |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ANLT-02 | Weekly bucket: 7-day window divides correctly | unit | `Phase26AnalyticsViewModelTests/testWeeklyBuckets` | ❌ Wave 0 |
| ANLT-02 | Monthly bucket: calendar month divides correctly | unit | `Phase26AnalyticsViewModelTests/testMonthlyBuckets` | ❌ Wave 0 |
| ANLT-02 | D-05 formula: days-with-checkin / total-days-in-period | unit | `Phase26AnalyticsViewModelTests/testCompletionRateFormula` | ❌ Wave 0 |
| ANLT-03 | `AllTimeHeatmapView` start date uses `goal.creationDate` fallback | unit | `Phase26AnalyticsViewModelTests/testHeatmapStartDateFallback` | ❌ Wave 0 |
| ANLT-03 | All goals (active + completed) appear in goal list | unit | `Phase26AnalyticsViewModelTests/testAllGoalsIncluded` | ❌ Wave 0 |
| ANLT-04 | CSV header row is correct | unit | `Phase26CSVExportServiceTests/testCSVHeader` | ❌ Wave 0 |
| ANLT-04 | CSV goal_name with comma is RFC 4180 escaped | unit | `Phase26CSVExportServiceTests/testCSVEscaping` | ❌ Wave 0 |
| ANLT-04 | CSV is_frozen column reflects -1 sentinel | unit | `Phase26CSVExportServiceTests/testIsFrozenColumn` | ❌ Wave 0 |
| ANLT-04 | CSV rows sorted date ascending | unit | `Phase26CSVExportServiceTests/testSortOrder` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `VitaminGTests/Phase26AnalyticsViewModelTests.swift` — covers ANLT-02, ANLT-03 (bucket logic, start date, all-goals filter)
- [ ] `VitaminGTests/Phase26CSVExportServiceTests.swift` — covers ANLT-04 (header, escaping, frozen column, sort)

---

## Open Questions

1. **Inline-expand vs. push-navigation for per-goal heatmap (D-06, Claude's Discretion)**
   - What we know: D-06 says "tapping a goal navigates to (or expands) its all-time heatmap section."
   - What's unclear: Inline expansion (DisclosureGroup/animation) vs. `NavigationLink` push. Push is simpler and consistent with the rest of the app's navigation pattern. Inline requires managing expanded-ID state.
   - Recommendation: Use `NavigationLink` push to a `GoalAllTimeHeatmapView` screen — consistent with `GoalDetailView` navigation precedent. Simpler state management.

2. **`AnalyticsViewModel.refresh()` called where?**
   - What we know: `StatsViewModel.refresh()` is called in `.onAppear` and `.onChange` of events/goals count.
   - What's unclear: `AnalyticsView` will have its own `@Query` for events and goals, or pass them from `StatsView`?
   - Recommendation: Give `AnalyticsView` its own `@Query` declarations (same pattern as `StatsView`). Do not pass arrays across view boundaries — it contradicts the established `@Query`-in-view pattern.

3. **`is_frozen` for per-goal CSV export**
   - What we know: `StreakFreezeService.frozenDates` returns the global frozen dates. Frozen days are not per-goal.
   - What's unclear: Should per-goal export include the `is_frozen` column? A goal's heatmap may show ❄️ on days when the user froze (even if no completion event for that goal exists).
   - Recommendation: Include `is_frozen` in per-goal CSV using the same global `frozenDates` set. A day is frozen regardless of which goal. Mark it `true` only if the event's date is a frozen day — or add a header-only `is_frozen` column that says `false` for all per-goal events (since CompletionEvents only exist for real check-ins, not freeze days). The planner should decide: include frozen-day phantom rows in per-goal export or only real check-ins. The global export includes all CompletionEvents (real ones only) plus `is_frozen=true` on any that happen to land on a freeze day.

---

## Environment Availability

Step 2.6: SKIPPED — this phase makes no calls to external services, installs no packages, and has no runtime dependencies beyond Xcode + iOS Simulator already confirmed present in the project.

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Goal titles are user-entered strings; CSV export must escape them (RFC 4180); no length-limit enforcement needed at export time since input was already validated at goal creation |
| V6 Cryptography | no | — |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| CSV injection (formula injection via `=`, `+`, `-`, `@` prefix in goal names) | Tampering | Wrap all fields in double-quotes per RFC 4180; most spreadsheet apps do not execute formulas in quoted fields |
| CSV size denial-of-service | Denial of Service | Not applicable — data source is local SwiftData; maximum row count bounded by user's own history; no network payload |

**CSV Injection Note:** The standard CSV escaping (wrapping in double-quotes) is sufficient for this use case. The app targets personal use — the export is generated from the user's own data and shared by the user themselves. Aggressive sanitization (stripping `=`, `+` prefixes) is not required for this threat model.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `ShareLink(item: String, ...)` in iOS 17+ renders correctly as a shareable text payload for CSV recipients like Files and Mail | Pattern 3, Code Examples | If wrong, must wrap in a `URL(fileURLWithPath:)` temp file — adds `FileManager` complexity and cleanup obligation |
| A2 | Swift Charts `BarMark(x: .value("P", date, unit: .weekOfYear))` aggregates multiple events with the same week into one bar automatically | Pattern 1 | If wrong, must manually group events into `[weekStart: count]` before passing to `Chart`; extra ViewModel code |
| A3 | `StreakFreezeService.frozenDates` is accessible from `AnalyticsView` without modification | Architecture | If wrong, need to read frozen dates from UserDefaults directly in AnalyticsView; minor refactor |

**If this table is empty:** Not empty — three low-risk assumptions noted. All are API behavior assumptions for built-in iOS frameworks.

---

## Sources

### Primary (HIGH confidence)
- Codebase: `GoalDetailView.swift` line 453 — confirmed `BarMark` with `unit: .day` pattern
- Codebase: `HeatmapView.swift` — confirmed `LazyVGrid` + `cellColor(for:)` pattern to replicate
- Codebase: `SchemaV10.swift` — confirmed `Goal.creationDate: Date?` (NOT `createdAt`)
- Codebase: `Schema8pV2.swift` — confirmed `CompletionEvent` fields: `completedAt`, `tierRawValue`, `goal`
- Codebase: `StatsViewModel.swift` — confirmed `buildHeatmapData` sentinel pattern for frozen days
- Codebase: `ProfileView.swift` line 472 — confirmed `ShareLink` usage pattern
- Codebase: `AppRoute.swift` — confirmed current route cases; `.analytics` case does not yet exist
- Codebase: `ContentView.swift` — confirmed Home tab NavigationStack owns `.stats` destination; `.analytics` goes in the same switch block
- Codebase: `VGTheme.swift` — confirmed `accentTerra` and `accentPurple` exist as adaptive semantic tokens
- Codebase: `Goal.swift` — confirmed `GoalTier` raw values: "Immediate", "Short-Term", "Long-Term", "Life Goal"

### Secondary (MEDIUM confidence)
- [LazyHStack lazy loading — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-lazy-load-views-using-lazyvstack-and-lazyhstack) — confirms LazyHStack only renders visible views
- [ScrollView new features in SwiftUI 5 — fatbobman](https://fatbobman.com/en/posts/new-features-of-scrollview-in-swiftui5/) — confirms `ScrollViewReader.scrollTo` works with `LazyHStack`

### Tertiary (LOW confidence)
- A2: Swift Charts `BarMark` date aggregation with `unit:` — assumed from `GoalDetailView.swift` pattern and Swift Charts documentation behavior [ASSUMED]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all frameworks verified in existing codebase; no new dependencies
- Architecture: HIGH — all integration points confirmed by reading actual source files
- Data model fields: HIGH — verified from SchemaV10.swift and Schema8pV2.swift directly
- Pitfalls: HIGH — derived from direct codebase reading + established Swift/SwiftUI patterns
- Swift Charts date bucketing: MEDIUM — confirmed pattern exists in codebase; `unit: .weekOfYear` behavior assumed from API design

**Research date:** 2026-06-01
**Valid until:** 2026-07-01 (stable Apple SDK; 30 days)
