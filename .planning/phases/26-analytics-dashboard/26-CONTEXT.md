# Phase 26: Analytics Dashboard - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

A new `AnalyticsView` reachable from a navigation row at the bottom of the existing `StatsView`. It delivers three capabilities — all computed from existing `CompletionEvent` data with no schema migration required:

1. **Completion rate trends chart** (ANLT-02) — bar chart with Weekly/Monthly segmented control; Y-axis = % of days with at least one check-in
2. **All-time per-goal heatmap** (ANLT-03) — horizontally scrolling `LazyHStack` heatmap from goal creation date to today; accessible by tapping any goal in a list inside `AnalyticsView`; covers all goals (active + completed)
3. **CSV export** (ANLT-04) — two surfaces: global export on `AnalyticsView` (all goals) and per-goal export on each goal's heatmap view; columns: `goal_name, date, tier, is_frozen`; ISO 8601 dates; delivered via `ShareLink`

</domain>

<decisions>
## Implementation Decisions

### Entry Point & Navigation

- **D-01:** `AnalyticsView` is a new view. Entry point is a navigation row/button at the **bottom of `StatsView`** — zero new wiring required since `StatsView` is already wired off the Home tab.
- **D-02:** Nav title: `"Analytics"` (`.navigationTitle("Analytics")`, `.navigationBarTitleDisplayMode(.large)`).

### Completion Rate Trends Chart (ANLT-02)

- **D-03:** Chart type is **bar chart** (`BarMark`) — same component pattern as `GoalDetailView`. Discrete weekly/monthly buckets are naturally categorical, not continuous.
- **D-04:** **Segmented control toggle** (`Picker` with `.segmented` style) switches between Weekly and Monthly granularity. Standard iOS pattern (mirrors Health app D/W/M/Y). Single chart area — no stacking.
- **D-05:** Y-axis definition: **% of days with at least one check-in** in the period. Formula: `(days with any CompletionEvent in window) / (total calendar days in window) × 100`. Consistent with the existing `ConsistencyEngine` approach.

### All-Time Per-Goal Heatmap (ANLT-03)

- **D-06:** Heatmap lives **inside `AnalyticsView`** — a scrollable goal list; tapping a goal navigates to (or expands) its all-time heatmap section. `GoalDetailView` is unchanged.
- **D-07:** **Horizontal scroll via `LazyHStack`** as mandated by REQUIREMENTS.md ANLT-03 note. Each row = one week or one month column of day cells. Must render without stutter for 1000+ days.
- **D-08:** Goal list shows **all goals** — active and completed. Completed goals have valuable historical heatmap data and must be accessible.

### CSV Export (ANLT-04)

- **D-09:** **Two export surfaces:**
  - Global export button on `AnalyticsView` → exports every `CompletionEvent` across all goals
  - Per-goal export on each goal's all-time heatmap view → exports only that goal's events
- **D-10:** CSV columns: `goal_name, date, tier, is_frozen`. Header row included. `is_frozen` distinguishes real check-ins from streak-freeze days (sentinel value -1 in `heatmapData`).
- **D-11:** Date format: **ISO 8601 (`YYYY-MM-DD`)** — timezone-unambiguous, lexicographically sortable, compatible with Excel/Numbers/Google Sheets.

### Claude's Discretion

- Tier display names in CSV (e.g., "immediate", "short_term", "long_term", "life" — or the raw `tierRawValue` strings from the model)
- Export filename convention (e.g., `vitamin-g-history-YYYY-MM-DD.csv` for global; `vitamin-g-[goal-name]-YYYY-MM-DD.csv` for per-goal)
- Sort order of CompletionEvents in CSV (by date ascending is the obvious default)
- Color palette for bar chart (use `VGTheme.accentTerra` / `VGTheme.accentPurple` gradient or a single accent color consistent with existing stats cards)
- Week/month bucket label format on chart X-axis (e.g., "Jun 2", "W23", "Jun 2026")
- Whether the goal list in AnalyticsView uses inline-expand or push-navigation to the heatmap

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Requirements
- `.planning/ROADMAP.md` §Phase 26 — goal, success criteria, requirements (ANLT-02, ANLT-03, ANLT-04)
- `.planning/REQUIREMENTS.md` §ANLT-02, ANLT-03, ANLT-04 — full requirement definitions including LazyHStack mandate for ANLT-03

### Existing Analytics / Stats Code (read before touching)
- `VitaminG/VitaminG/VitaminG/Views/StatsView.swift` — existing stats screen; Phase 26 adds a navigation row at the bottom; do not modify existing cards/sections
- `VitaminG/VitaminG/VitaminG/ViewModels/StatsViewModel.swift` — existing `heatmapData`, `tierCompletionRates`, `consistencyScore`; Phase 26 adds an `AnalyticsViewModel` (new) alongside it, or extends `StatsViewModel` — planner to decide
- `VitaminG/VitaminG/VitaminG/Views/HeatmapView.swift` — 90-day window, `LazyVGrid` with 12px cells; Phase 26 needs a new all-time variant with `LazyHStack` (different scroll axis and dynamic start date — do not modify `HeatmapView`, create `AllTimeHeatmapView`)

### Swift Charts Reference (existing usage)
- `VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift` — `import Charts`, `BarMark` usage at line ~453; replicate this pattern for the completion rate bar chart

### Streak / Completion Engine
- `VitaminG/VitaminG/VitaminG/Services/StreakEngine.swift` — `StreakEngine.completionRate(events:totalGoals:tier:)` — may be reused or extended for per-period bucketing; planner to verify
- `VitaminG/VitaminG/VitaminG/Services/ConsistencyEngine.swift` — existing `score(events:)` and `recentDays(events:)` — D-05 definition aligns with this approach

### Data Model
- `VitaminG/VitaminG/VitaminG/Models/SchemaV10.swift` — current schema; `CompletionEvent` fields: `completedAt: Date?`, `goal: Goal`, `tierRawValue: String?`. `Goal` fields include `title: String` and `createdAt: Date` (confirm `createdAt` field name before planning)

### Prior Phase Context
- `.planning/STATE.md` — key decisions: "No SchemaV11 required for v3.0 — all v3.0 state lives in UserDefaults", "v3.0 build order: Notifications → Analytics → Watch → AI"
- `.planning/phases/25-smart-notifications-enhancement/25-CONTEXT.md` — patterns for App Group UserDefaults (not directly relevant but establishes coding conventions)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HeatmapView(data: [Date: Int], windowDays: Int)` — reuse the color/cell rendering logic; create `AllTimeHeatmapView(data: [Date: Int], startDate: Date)` as a sibling that uses `LazyHStack` instead of `LazyVGrid`
- `StatsViewModel.buildHeatmapData(from:frozenDates:)` — existing `[Date: Int]` builder with `-1` sentinel for frozen days; reuse for per-goal heatmap by filtering events to a single goal
- `GoalDetailView` `BarMark` chart at line ~453 — copy the `Chart(chartItems) { item in BarMark(...) }` pattern for the completion rate chart
- `VGTheme` color constants — use existing accent colors; do not introduce new color names

### Established Patterns
- **`@Query` + `@MainActor @Observable ViewModel`** — all views use SwiftData `@Query` for raw arrays, pass them to a ViewModel's `refresh()` method; follow this for `AnalyticsViewModel`
- **`LazyVGrid` for 90-day heatmap** — Phase 26 introduces a `LazyHStack`-based all-time heatmap; this is deliberately different per the requirement; do not conflate the two
- **`ShareLink`** — already used in `ProfileView.swift` for profile sharing; follow the same `ShareLink(item: ..., preview: ...)` pattern for CSV export
- **Pure view components** — `HeatmapView`, `ConsistencyScoreCard` etc. are pure display components that receive pre-computed data; keep `AllTimeHeatmapView` and the chart view the same way

### Integration Points
- `StatsView.swift` — add a `NavigationLink` to `AnalyticsView` at the bottom of the `VStack` inside the `ScrollView`; `.navigationDestination` already wired on HomeView's navigation stack (confirm before adding a new one)
- `ContentView.swift` / `HomeView.swift` — confirm where `navigationDestination(for:)` for Stats is registered before adding a new destination for Analytics
- `Goal.swift` (current schema alias) — confirm `createdAt` field name for the all-time heatmap start date

</code_context>

<specifics>
## Specific Ideas

- The all-time heatmap should start from the goal's `createdAt` date, not from a fixed window — this is what makes it "all-time" vs. the existing 90-day view
- CSV `is_frozen` column maps directly to the `-1` sentinel in `heatmapData` / `CompletionEvent` context; values: `true` for freeze days, `false` for real check-ins
- Horizontal scroll heatmap should snap or anchor near the most recent week on initial render (scroll-to-end behavior)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 26-analytics-dashboard*
*Context gathered: 2026-06-01*
