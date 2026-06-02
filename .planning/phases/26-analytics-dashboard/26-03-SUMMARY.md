---
plan: 26-03
phase: 26-analytics-dashboard
status: complete
completed: 2026-06-02
commits:
  - aed99ac
  - b07835e
requirements:
  - ANLT-02
  - ANLT-03
  - ANLT-04
subsystem: analytics
tags: [views, swiftui, swift-charts, sharelink, navigation, heatmap, csv-export]
dependency-graph:
  requires: [26-01, 26-02]
  provides: [AllTimeHeatmapView, GoalAllTimeHeatmapView, AnalyticsView, analytics-nav-wiring]
  affects: [StatsView (nav row added), ContentView (analytics destination added)]
tech-stack:
  added: [Charts framework (BarMark)]
  patterns:
    - "LazyHStack horizontal heatmap scrolled to most recent week via ScrollViewReader"
    - "FloatingPointFormatStyle<Double>.Percent() for unambiguous chartYAxis percent formatting"
    - "FileSystemSynchronizedGroups — new Swift files auto-included in Xcode target, no project.pbxproj edits needed"
    - "ShareLink(item: String, preview: SharePreview) for CSV export via system share sheet"
key-files:
  created:
    - VitaminG/VitaminG/VitaminG/Views/AllTimeHeatmapView.swift
    - VitaminG/VitaminG/VitaminG/Views/GoalAllTimeHeatmapView.swift
    - VitaminG/VitaminG/VitaminG/Views/AnalyticsView.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/StatsView.swift
    - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
decisions:
  - "Used FloatingPointFormatStyle<Double>.Percent() instead of .percent shorthand to resolve Swift Charts AxisMarks format ambiguity"
  - "heatmapDataByGoal keyed by goal.id.uuidString (String) per Plan 02 decision — AnalyticsView looks up data[goal.id.uuidString]"
  - "GoalAllTimeHeatmapView receives pre-computed heatmapData from AnalyticsViewModel to avoid redundant computation; fetches its own @Query events for accurate per-goal CSV export"
metrics:
  duration: "~4 minutes"
  tasks: 2
  files: 5
---

# Phase 26 Plan 03: Views + Navigation Wiring Summary

Analytics dashboard views wired end-to-end: BarMark chart with Weekly/Monthly toggle, LazyHStack all-time heatmap scrolling to most recent week, and two CSV export surfaces via ShareLink.

## What Was Built

**AllTimeHeatmapView.swift** (new) — Pure display component. `ScrollViewReader` wrapping `ScrollView(.horizontal)` containing a `LazyHStack` of week-columns. Each column is a `VStack` of 7 day-cells. `cellColor(for:)` copied verbatim from `HeatmapView.swift` — sentinel -1 renders blue-tinted `Color.blue.opacity(0.25)` background with `Image(systemName: "snowflake")` overlay. Future days render as `Color.clear` placeholders. `.onAppear { proxy.scrollTo(weeks.count - 1, anchor: .trailing) }` ensures the most recent week is visible without manual scroll. `weeks` computed property anchors to the ISO week containing `startDate` and loops weekly until today.

**GoalAllTimeHeatmapView.swift** (new) — Full-screen view for a single goal. Accepts `goal: Goal`, `heatmapData: [Date: Int]` (pre-built by `AnalyticsViewModel`), `frozenDates: [Date]`. Owns a `@Query` of `CompletionEvent` for per-goal CSV accuracy. `startDate` mirrors `AnalyticsViewModel.heatmapStartDate(for:)` fallback chain: `creationDate` → earliest `completedAt` → 90 days ago. Per-goal `ShareLink` uses `CSVExportService.buildGoalCSV(goal:events:frozenDates:)`.

**AnalyticsView.swift** (new) — `@MainActor struct` with `@Query` for events and goals, `@State private var viewModel = AnalyticsViewModel()`, `@State private var freezeService = StreakFreezeService()`, and `@State private var granularity: ChartGranularity = .weekly`. Three sections:
- `chartSection`: Segmented `Picker` (Weekly/Monthly) + `Chart(buckets) { BarMark(...) }` with `VGTheme.accentTerra` fill and `FloatingPointFormatStyle<Double>.Percent()` Y-axis labels. Height: 180pt.
- `goalListSection`: `ForEach(viewModel.allGoals)` in a rounded card — each row is a `NavigationLink(destination: GoalAllTimeHeatmapView(...))` with `heatmapData: viewModel.heatmapDataByGoal[goal.id.uuidString] ?? [:]`.
- `globalExportButton`: `ShareLink(item: CSVExportService.buildGlobalCSV(...))` with `.borderedProminent` style tinted `VGTheme.accentTerra`.

**StatsView.swift** (modified) — Added `analyticsNavigationRow` private computed var (D-01). Renders as a rounded card with `chart.bar.xaxis` icon and chevron. Uses `NavigationLink(value: AppRoute.analytics)`. Added to the existing `VStack(spacing: 20)` after `heatmapSection`. No existing content modified.

**ContentView.swift** (modified) — Added `case .analytics: AnalyticsView()` to the Home tab's `navigationDestination(for: AppRoute.self)` switch block. One line added, no other routing logic changed.

## Deviations from Plan

**1. [Rule 1 - Bug] Ambiguous `.percent` in chartYAxis AxisMarks**
- **Found during:** Task 2 build verification
- **Issue:** `AxisMarks(format: .percent)` was ambiguous — compiler could not resolve between `FloatingPointFormatStyle.Percent` and another overload in the Charts framework.
- **Fix:** Replaced with `AxisMarks(format: FloatingPointFormatStyle<Double>.Percent())` to be explicit about the type.
- **Files modified:** `AnalyticsView.swift`
- **Commit:** b07835e (included in Task 2 commit)

## Known Stubs

None. All views render live SwiftData data via `@Query` and `AnalyticsViewModel`.

## Threat Flags

No new threat surface beyond the plan's threat model. `ShareLink` only fires on explicit user tap (T-26-04 accepted). All data is local SwiftData; no network calls introduced.

## Self-Check: PASSED

- `AllTimeHeatmapView.swift`: FOUND
- `GoalAllTimeHeatmapView.swift`: FOUND
- `AnalyticsView.swift`: FOUND
- `StatsView.swift` contains `AppRoute.analytics`: CONFIRMED (line 173)
- `ContentView.swift` contains `case .analytics: AnalyticsView()`: CONFIRMED (line 19)
- `grep "LazyHStack" AllTimeHeatmapView.swift`: FOUND (line 48)
- `grep "BarMark" AnalyticsView.swift`: FOUND (line 78)
- `grep "buildGlobalCSV" AnalyticsView.swift`: FOUND (line 142)
- `grep "buildGoalCSV" GoalAllTimeHeatmapView.swift`: FOUND (line 83)
- Build result: `** BUILD SUCCEEDED **`
- Commit aed99ac: FOUND (Task 1 — AllTimeHeatmapView + GoalAllTimeHeatmapView)
- Commit b07835e: FOUND (Task 2 — AnalyticsView + StatsView + ContentView)
