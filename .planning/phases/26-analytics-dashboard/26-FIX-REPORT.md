---
phase: 26-analytics-dashboard
fixed_at: 2026-06-02T16:45:00Z
review_path: .planning/phases/26-analytics-dashboard/26-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 8
skipped: 0
status: all_fixed
---

# Phase 26: Code Review Fix Report

**Fixed at:** 2026-06-02
**Source review:** `.planning/phases/26-analytics-dashboard/26-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 8 (3 Critical + 5 Warning)
- Fixed: 8
- Skipped: 0

---

## Fixed Issues

### CR-01: CSV Injection via Unescaped Newlines in `goal.title`

**Files modified:** `VitaminG/VitaminG/VitaminG/Services/CSVExportService.swift`
**Commit:** 5d413d4
**Applied fix:** The `csvEscaped` computed property now strips `\r\n`, `\r`, and `\n` (replacing each with a space) before wrapping in double-quotes and escaping internal `"` characters. This prevents spreadsheet applications from interpreting embedded newlines in goal titles as literal record breaks, which would corrupt the CSV output. The original RFC 4180 quoting behavior is preserved for commas and embedded double-quotes.

---

### CR-02: `goalTitle` Injected Directly into ShareLink `preview` Label Without Sanitization

**Files modified:** `VitaminG/VitaminG/VitaminG/Views/GoalAllTimeHeatmapView.swift`
**Commit:** 3d141c0
**Applied fix:** `perGoalExportButton` now derives `safeTitle` from `goal.title` before constructing the `SharePreview` filename: `/` and `:` are replaced with `-`, control characters are stripped via `.components(separatedBy: .controlCharacters).joined()`, and leading/trailing whitespace is trimmed. The `SharePreview` now uses `"vitamin-g-\(safeTitle)-\(dateStamp).csv"` instead of the raw title.

---

### CR-03: Global CSV Built on Every `body` Re-evaluation (MVVM Violation)

**Files modified:** `VitaminG/VitaminG/VitaminG/ViewModels/AnalyticsViewModel.swift`, `VitaminG/VitaminG/VitaminG/Views/AnalyticsView.swift`
**Commit:** d82d64c
**Applied fix:** Added `private(set) var globalCSVContent: String = ""` to `AnalyticsViewModel`. The call to `CSVExportService.buildGlobalCSV(...)` was moved from `AnalyticsView.globalExportButton` into `AnalyticsViewModel.refresh(...)`, where it executes at the end of each refresh alongside the chart buckets. `AnalyticsView.globalExportButton` now references `viewModel.globalCSVContent` — no business logic remains in the View body.

---

### WR-01: `AllTimeHeatmapView.weeks` Computed Property Defeats `LazyHStack` Laziness

**Files modified:** `VitaminG/VitaminG/VitaminG/Views/AllTimeHeatmapView.swift`
**Commit:** 258635b
**Applied fix:** The `private var weeks: [[Date]]` computed property was replaced with a `private func buildWeeks() -> [[Date]]` function backed by `@State private var cachedWeeks: [[Date]]? = nil`. The `body` now resolves `let weeks = cachedWeeks ?? buildWeeks()` and `.onAppear` populates `cachedWeeks` on first appearance (guarded by `if cachedWeeks == nil`). The date-arithmetic loop now runs exactly once per view lifetime rather than on every render pass.

---

### WR-02: `onChange(of:)` Tracks Only `.count` — Misses In-Place Mutations

**Files modified:** `VitaminG/VitaminG/VitaminG/Views/AnalyticsView.swift` (commit d82d64c), `VitaminG/VitaminG/VitaminG/Views/StatsView.swift` (commit aa70f35)
**Applied fix:** Both views changed `.onChange(of: events.count)` and `.onChange(of: goals.count)` to `.onChange(of: events.map(\.id))` and `.onChange(of: goals.map(\.id))`. This causes `refresh()` to fire when any item's identity changes — catching in-place mutations such as `completedAt` corrections or goal title updates that preserve count but change the displayed data.

Note: `.map(\.id)` arrays are compared by value on each render; for very large event collections this adds a linear scan per body evaluation. If performance becomes a concern, a stable hash of all IDs (e.g., `events.reduce(into: 0) { $0 ^= $1.id.hashValue }`) would reduce the comparison cost.

---

### WR-03: Force-Unwrap in `heatmapStartDate` 90-Day Fallback

**Files modified:** `VitaminG/VitaminG/VitaminG/ViewModels/AnalyticsViewModel.swift` (commit d82d64c), `VitaminG/VitaminG/VitaminG/Views/GoalAllTimeHeatmapView.swift` (commit 3d141c0)
**Applied fix:** Both `heatmapStartDate(for:)` in `AnalyticsViewModel` and `startDate` in `GoalAllTimeHeatmapView` replaced `Calendar.current.date(byAdding: .day, value: -90, to: Date())!` with `Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date(timeIntervalSinceNow: -90 * 86400)`. The force-unwrap crash surface is eliminated; a corrupted calendar/locale now silently falls back to an arithmetic offset.

Note: The duplication between the two files (flagged in the review as a DRY concern) was left in place. Consolidating requires either injecting the computed start date as a `let` parameter into `GoalAllTimeHeatmapView` or making the `AnalyticsViewModel` instance accessible from that view — both are architectural changes that should be planned separately.

---

### WR-04: `StreakFreezeService` Instantiated Independently in Both Views — Divergent State

**Files modified:** `VitaminG/VitaminG/VitaminG/Views/AnalyticsView.swift` (commit d82d64c), `VitaminG/VitaminG/VitaminG/Views/StatsView.swift` (commit aa70f35)
**Applied fix:** Per the review recommendation, the independent-instance pattern was documented with an explanatory comment in both files rather than refactored. Each comment explains the divergent-state risk (a freeze applied in `StatsView` may not appear in `AnalyticsView`'s `frozenDates` until the next `onAppear`) and identifies the full fix path: lift `StreakFreezeService` to a shared `@Environment` object at the `NavigationStack` root.

The architectural refactor is deferred for a dedicated phase.

---

### WR-05: `buildGoalCSV` Filters Events by Identity (`===`) Across Context Boundaries

**Files modified:** `VitaminG/VitaminG/VitaminG/Services/CSVExportService.swift`
**Commit:** 5d413d4
**Applied fix:** `buildGoalCSV` now filters events using `$0.goal?.id == goal.id` (value equality on the UUID) instead of `$0.goal === goal` (reference identity). This ensures correct filtering when `events` and `goal` originate from different `ModelContext` instances — a scenario that occurs after a CloudKit sync triggers a context refresh, where identity comparison would silently produce an empty CSV body.

---

_Fixed: 2026-06-02_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
