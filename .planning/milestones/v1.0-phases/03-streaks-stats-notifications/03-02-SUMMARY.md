---
phase: 03-streaks-stats-notifications
plan: 02
subsystem: stats-view
status: completed
tasks_completed: 2
files_modified:
  created:
    - VitaminG/VitaminG/VitaminG/ViewModels/StatsViewModel.swift
    - VitaminG/VitaminG/VitaminG/Views/StatsView.swift
    - VitaminG/VitaminG/VitaminG/Views/HeatmapView.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
tags: [stats, heatmap, streak, swiftui, mvvm]
dependency_graph:
  requires:
    - StreakEngine (Plan 03-01)
    - CompletionEvent model (SchemaV1)
    - GoalTier enum (Goal.swift)
  provides:
    - StatsViewModel — @Observable class computing global/per-tier streaks, completion rates, heatmap data
    - StatsView — full stats screen with global streak card, per-tier grid, heatmap section
    - HeatmapView — reusable 90-day GitHub-style activity grid
  affects:
    - ContentView.swift — Stats tab replaced with real StatsView; Settings tab added by orchestrator (Plan 03-03)
tech_stack:
  added: []
  patterns:
    - "@Observable ViewModel with manual refresh(events:goals:) trigger"
    - "LazyVGrid for both tier card grid and heatmap cells"
    - "@Query + .onAppear + .onChange pattern for reactivity"
    - "Pre-built [Date: Int] dictionary for O(1) heatmap cell lookup (T-03-06)"
    - "guard let nil safety on completedAt (T-03-05)"
key_files:
  created:
    - path: VitaminG/VitaminG/VitaminG/ViewModels/StatsViewModel.swift
      role: Computes globalStreak, tierStreaks, tierCompletionRates, tierGoalCounts, heatmapData via StreakEngine
    - path: VitaminG/VitaminG/VitaminG/Views/StatsView.swift
      role: Stats screen — global streak gradient card, 2-column tier grid (TierStatCard), heatmap section
    - path: VitaminG/VitaminG/VitaminG/Views/HeatmapView.swift
      role: Pure display component — 90-day 7-column LazyVGrid with intensity-stepped green colors
  modified:
    - path: VitaminG/VitaminG/VitaminG/Views/ContentView.swift
      role: Stats tab wired to StatsView; Settings tab added (SettingsView, Plan 03-03)
decisions:
  - "StatsViewModel uses manual refresh(events:goals:) rather than internal @Query to keep VM free of SwiftUI/SwiftData dependency — consistent with GoalViewModel pattern"
  - "HeatmapView is a pure [Date: Int] consumer — no data fetching; pre-building in ViewModel enables O(1) per-cell rendering (T-03-06)"
  - "onChange watches both events.count and goals.count — goal additions change tierGoalCounts even without new events"
  - "TierStatCard uses a 4pt leading accent bar matching GoalRowView's tier pip pattern for visual consistency"
metrics:
  duration: "~15 minutes"
  completed_date: "2026-04-04"
next_plan_notes: |
  Plan 03-03 has already been executed (NotificationScheduler). No pending plan work in Phase 03.
---

# Phase 03 Plan 02: Stats View Summary

**One-liner:** StatsViewModel + StatsView with warm-gradient global streak card, per-tier LazyVGrid with color-accent bars, and 90-day GitHub-style HeatmapView — all wired into ContentView Stats tab via @Query + StreakEngine.

## What Was Built

**Task 1 — StatsViewModel and StatsView**

`StatsViewModel.swift` is an `@Observable` class with a single `refresh(events:goals:)` method that populates:
- `globalStreak` — via `StreakEngine.currentStreak(from: events)`
- `tierStreaks[tier]` — via `StreakEngine.currentStreak(from: events, tier: tier)` for each `GoalTier.ordered` member
- `tierCompletionRates[tier]` — via `StreakEngine.completionRate(events:totalGoals:tier:)`
- `tierGoalCounts[tier]` — count of goals filtered by tier
- `heatmapData` — `[Date: Int]` dictionary keyed by `Calendar.current.startOfDay(for:)`, built via `buildHeatmapData(from:)` with nil guard on `completedAt`

`StatsView.swift` uses `@Query` for `[CompletionEvent]` and `[Goal]`, `@State private var viewModel = StatsViewModel()`, and calls `viewModel.refresh` on `.onAppear` and `.onChange` of both event and goal counts. The layout is a `ScrollView` containing:
1. **Global streak card** — `LinearGradient` orange-to-violet background, `.font(.system(size: 48, weight: .bold, design: .rounded))` streak number
2. **Tier grid** — `LazyVGrid` with 2 columns, one `TierStatCard` per tier showing streak, goal count, and completion rate
3. **Heatmap section** — header label + `HeatmapView(data: viewModel.heatmapData)`

**Task 2 — HeatmapView and ContentView wiring**

`HeatmapView.swift` is a pure display component that accepts `let data: [Date: Int]` and renders a `LazyVGrid` with 7 columns of 12x12 rounded cells, covering the past 90 days. Cell color intensity steps: `Color(.systemFill)` (0), `.green.opacity(0.3)` (1), `.green.opacity(0.6)` (2), `.green` (3+).

`ContentView.swift` Stats tab updated from `Text("Stats")` placeholder to `NavigationStack { StatsView() }`.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as specified.

### Orchestrator Modification

ContentView was updated by the Plan 03-03 orchestrator (concurrently executing) to add a Settings tab with `SettingsView()` and wire `case .settings:` to `SettingsView()`. This is correct forward-compatible behavior — `SettingsView.swift` exists on disk and the build succeeds with these additions.

## Known Stubs

None — all data sources are wired to real `@Query` results. `viewModel.heatmapData` returns empty `[:]` when no events exist, producing all-gray heatmap cells which is correct behavior.

## Threat Surface Scan

No new network endpoints or auth paths introduced. StatsView only reads from local SwiftData store via `@Query`. Threat mitigations T-03-05 and T-03-06 from the plan's threat model are both implemented:
- T-03-05: `buildHeatmapData` uses `guard let date = event.completedAt else { continue }`
- T-03-06: Pre-built `[Date: Int]` dictionary enables O(1) per-cell lookup in HeatmapView

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| StatsViewModel.swift exists | FOUND |
| StatsView.swift exists | FOUND |
| HeatmapView.swift exists | FOUND |
| ContentView.swift contains StatsView() | FOUND |
| Task 1 commit ad66f37 | FOUND |
| Task 2 commit 0ffe6c6 | FOUND |
| Build succeeds (iPhone 17 simulator) | PASSED |
