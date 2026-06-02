---
plan: 26-02
phase: 26-analytics-dashboard
status: complete
completed: 2026-06-02
commits:
  - 97a7722
  - 750513a
requirements:
  - ANLT-02
  - ANLT-03
subsystem: analytics
tags: [viewmodel, swiftdata, xctesting, tdd, analytics]
dependency-graph:
  requires: [26-01]
  provides: [AnalyticsViewModel, BucketItem, ChartGranularity]
  affects: [AnalyticsView (Plan 03)]
tech-stack:
  added: []
  patterns:
    - "@MainActor @Observable final class mirroring StatsViewModel pattern"
    - "Set<Date> unique-day counting for O(1) per-week/month aggregation"
    - "String (goal.id.uuidString) as heatmapDataByGoal key — avoids PersistentIdentifier hashability concerns"
key-files:
  created:
    - VitaminG/VitaminG/VitaminG/ViewModels/AnalyticsViewModel.swift
  modified:
    - VitaminG/VitaminG/VitaminGTests/Phase26AnalyticsViewModelTests.swift
decisions:
  - "Keyed heatmapDataByGoal by goal.id.uuidString (String) instead of PersistentIdentifier to avoid SwiftData version-specific hashability issues"
  - "AnalyticsViewModel.refresh() is synchronous (matches StatsViewModel pattern); no async needed for O(N) local data"
metrics:
  duration: "~8 minutes"
  tasks: 2
  files: 2
---

# Phase 26 Plan 02: AnalyticsViewModel — Bucket Computation and Heatmap Data Summary

AnalyticsViewModel implemented as @MainActor @Observable final class with weekly/monthly bucket computation (D-05 unique-day formula) and per-goal heatmap data; all 5 RED stubs turned GREEN.

## What Was Built

**AnalyticsViewModel.swift** (new) — `@MainActor @Observable final class AnalyticsViewModel` in `ViewModels/`. Imports: SwiftData, Observation, Foundation (no SwiftUI per constraint). Published state: `weeklyBuckets: [BucketItem]`, `monthlyBuckets: [BucketItem]`, `heatmapDataByGoal: [String: [Date: Int]]`, `allGoals: [Goal]`. Keyed by `goal.id.uuidString` (stable String, avoids PersistentIdentifier hashability concerns).

Supporting types declared at file scope:
- `struct BucketItem: Identifiable` — id (UUID auto), periodStart (Date), completionRate (Double)
- `enum ChartGranularity: String, Hashable` — `.weekly`, `.monthly`

Methods:
- `refresh(events:goals:frozenDates:)` — populates all four state vars synchronously
- `buildWeeklyBuckets(_:)` — groups by `dateInterval(of: .weekOfYear)`, unique Set<Date> per week, rate = count/7.0
- `buildMonthlyBuckets(_:)` — groups by `dateInterval(of: .month)`, unique Set<Date> per month, rate = count/daysInMonth
- `buildGoalHeatmapData(goal:events:frozenDates:)` — filters events by `event.goal?.id == goal.id`, builds [Date:Int] dict with -1 sentinel for frozen days
- `heatmapStartDate(for:)` — fallback chain: creationDate ?? earliest completedAt ?? 90-days-ago

**Phase26AnalyticsViewModelTests.swift** (updated) — Replaced all 5 XCTFail stubs with real implementations:
- `testWeeklyBuckets` — 3 events Mon/Tue/Wed → 1 bucket rate=3/7; +1 next-week event → 2 buckets
- `testMonthlyBuckets` — Jan 2025 (1 event) + Feb 2025 (1 event) → 2 buckets; rates 1/31 and 1/28 verified
- `testCompletionRateFormula` — Mon+Wed events → rate=2/7 exactly; same-day duplicate stays 2/7 (unique-day counting)
- `testHeatmapStartDateFallback` — nil creationDate fallback to earliest event date; no-event fallback = 90 days ago (2s tolerance)
- `testAllGoalsIncluded` — 2 active + 1 completed (isCompleted=true) goal → allGoals.count==3

## Test Results

- Phase26AnalyticsViewModelTests: **5/5 passed GREEN** (testAllGoalsIncluded, testCompletionRateFormula, testHeatmapStartDateFallback, testMonthlyBuckets, testWeeklyBuckets)
- Phase26CSVExportServiceTests: **4/4 passed GREEN** (no regression)

## Deviations from Plan

**1. [Rule 1 - Bug] File written to main repo path instead of worktree path**
- **Found during:** Task 1 commit preparation
- **Issue:** Write tool wrote AnalyticsViewModel.swift to `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/...` (main repo) instead of worktree path. The Xcode project references the worktree symlink directory for builds, so the build succeeded from both locations, but `git status` in the worktree showed no new file.
- **Fix:** Copied file to worktree path and removed from main repo before staging.
- **Files modified:** AnalyticsViewModel.swift path corrected to worktree
- **Commit:** 97a7722

None — plan executed exactly as designed after path correction.

## Known Stubs

None. All AnalyticsViewModel methods are fully implemented and tested.

## Threat Flags

No new security-relevant surface beyond what the plan's threat model covers. AnalyticsViewModel.refresh() operates on local SwiftData arrays with no network calls, no external input boundaries, and no new persistence paths.

## Self-Check: PASSED

- `ls AnalyticsViewModel.swift` in worktree → FOUND
- `git log --oneline | grep 97a7722` → FOUND (Task 1 commit)
- `git log --oneline | grep 750513a` → FOUND (Task 2 commit)
- Phase26AnalyticsViewModelTests: 5/5 passed GREEN
- Phase26CSVExportServiceTests: 4/4 passed GREEN
- No SwiftUI import in AnalyticsViewModel.swift
- BucketItem.completionRate is Double
- @MainActor and @Observable declarations verified
- BucketItem and ChartGranularity declared at file scope
