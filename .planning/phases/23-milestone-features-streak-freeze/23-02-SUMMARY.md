---
phase: 23-milestone-features-streak-freeze
plan: "02"
subsystem: ui-and-viewmodels
tags: [swiftui, swiftdata, heatmap, streak-freeze, milestone-gate, tdd, observable]
dependency_graph:
  requires:
    - phase: 23-01
      provides: StreakMilestoneGate with goalStreakThresholds + hasShown/markShown, StreakFreezeService with frozenDates, SchemaV10
  provides:
    - StatsViewModel.buildHeatmapData writes sentinel -1 for frozen dates with no check-in
    - HeatmapView renders blue cell + snowflake SF Symbol for sentinel -1 cells
    - GoalViewModel.addCheckIn detects per-goal streak milestones via StreakMilestoneGate
    - GoalViewModel.addCheckIn detects auto-completion when completionEvents >= durationDays
    - pendingGoalMilestone and pendingGoalCompletion observable properties on GoalViewModel
  affects:
    - GoalDetailView/GoalListView — should consume pendingGoalMilestone via .onChange (Wave 3)
    - GoalCompletionCelebrationView — should consume pendingGoalCompletion (MILE-06, Wave 3)
    - StatsView — frozen days now automatically display with blue tint + snowflake
tech_stack:
  added: []
  patterns:
    - Sentinel-value pattern: -1 in [Date:Int] heatmap dict signals frozen day (no-check-in)
    - Per-goal streak milestone detection via threshold-crossing gate in addCheckIn
    - ZStack overlay pattern for conditional SF Symbol badge on heatmap cells
key_files:
  created:
    - VitaminG/VitaminG/VitaminGTests/Phase23StatsViewModelTests.swift
    - VitaminG/VitaminG/VitaminGTests/Phase23GoalViewModelTests.swift
  modified:
    - VitaminG/VitaminG/VitaminG/ViewModels/StatsViewModel.swift
    - VitaminG/VitaminG/VitaminG/Views/HeatmapView.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
decisions:
  - "Sentinel -1 approach: frozen days inject -1 directly into heatmapData dict — no new View parameter required, HeatmapView remains fully data-driven"
  - "buildHeatmapData nil-guard: frozen day only writes -1 when dict[day] == nil, preserving real check-in counts on the same day"
  - "freezeService = StreakFreezeService() stored on GoalViewModel: no DI needed since StreakFreezeService reads from App Group UserDefaults shared with the widget target"
  - "pendingGoalMilestone separate from existing pendingMilestone: avoids breaking the challenge-completion path which uses different thresholds [5,10,25,50]"
requirements_completed:
  - MILE-01
  - MILE-03
  - MILE-04
metrics:
  duration: "4m 22s"
  completed: "2026-05-26T17:07:01Z"
  tasks_completed: 3
  tasks_total: 3
  files_created: 2
  files_modified: 3
---

# Phase 23 Plan 02: ViewModel + View Wiring Summary

**StatsViewModel frozen-day sentinel (-1) wired to HeatmapView snowflake SF Symbol; GoalViewModel.addCheckIn now detects per-goal milestone threshold crossings and auto-completion via StreakMilestoneGate and StreakEngine.**

## Performance

- **Duration:** 4m 22s
- **Started:** 2026-05-26T17:02:39Z
- **Completed:** 2026-05-26T17:07:01Z
- **Tasks:** 3
- **Files modified:** 5 (3 source, 2 test)

## Accomplishments

- StatsViewModel.buildHeatmapData now accepts `frozenDates:[Date]`, writes sentinel -1 for frozen days with no real check-in, and preserves existing check-in counts when a freeze coincides with a check-in
- HeatmapView renders a blue-tinted cell with a `snowflake` SF Symbol overlay (accessibilityLabel: "Streak freeze") for any cell with sentinel value -1
- GoalViewModel.addCheckIn performs per-goal streak milestone detection using StreakMilestoneGate.goalStreakThresholds [7, 14, 30, 60, 90, 365], and detects auto-completion when completionEvents.count >= durationDays
- 5 new tests GREEN: Phase23StatsViewModelTests (2) + Phase23GoalViewModelTests (3), all via RED→GREEN TDD cycles

## Task Commits

Each task was committed atomically:

1. **Task 1: StatsViewModel frozen-day sentinel + Phase23StatsViewModelTests** - `09a9281` (feat + test, TDD)
2. **Task 2: HeatmapView ❄️ glyph for frozen cells** - `4a956be` (feat)
3. **Task 3: GoalViewModel per-goal milestone detection + auto-completion** - `234aaf9` (feat + test, TDD)

## Files Created/Modified

- `VitaminG/VitaminG/VitaminG/ViewModels/StatsViewModel.swift` — buildHeatmapData updated with frozenDates parameter and sentinel-1 write loop
- `VitaminG/VitaminG/VitaminG/Views/HeatmapView.swift` — ZStack overlay with conditional snowflake SF Symbol; cellColor handles -1 → blue tint
- `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` — freezeService, pendingGoalMilestone, pendingGoalCompletion added; addCheckIn expanded with MILE-04 and MILE-06 detection blocks
- `VitaminG/VitaminG/VitaminGTests/Phase23StatsViewModelTests.swift` — 2 tests for heatmap sentinel logic (new file)
- `VitaminG/VitaminG/VitaminGTests/Phase23GoalViewModelTests.swift` — 3 tests for milestone/completion detection (new file)

## Decisions Made

- **Sentinel -1 approach:** frozen days inject -1 directly into the existing `heatmapData: [Date: Int]` dict — no new View parameter required. HeatmapView remains a pure data-driven view.
- **nil-guard for overwrite prevention:** `if dict[day] == nil { dict[day] = -1 }` — a frozen day WITH a real check-in retains its real count.
- **freezeService stored on GoalViewModel:** `private let freezeService = StreakFreezeService()` — no DI needed since StreakFreezeService reads from App Group UserDefaults shared with widget target.
- **pendingGoalMilestone separate from pendingMilestone:** The existing `pendingMilestone` serves the challenge-completion path [5, 10, 25, 50]; the new `pendingGoalMilestone` uses StreakMilestoneGate.goalStreakThresholds [7, 14, 30, 60, 90, 365]. Keeping them separate avoids any risk of collision.
- **Phase23GoalViewModelTests as separate file:** The existing GoalViewModelTests.swift covers CRUD/validation; the new file isolates MILE-04/MILE-06 milestone behavior tests for clarity.

## Deviations from Plan

None - plan executed exactly as written. The acceptance criterion `grep -c "== -1" StatsViewModel.swift` in the plan is a minor wording inaccuracy — the implementation correctly uses assignment `dict[day] = -1` (not comparison `== -1`), which is the intended behavior. The comparison `data[day] == -1` exists in HeatmapView where it is used to conditionally show the snowflake glyph.

## Known Stubs

None — all three files are fully wired. HeatmapView immediately renders frozen cells with the sentinel from StatsViewModel. GoalViewModel fires pendingGoalMilestone/pendingGoalCompletion signals that Wave 3 plans (GoalDetailView, GoalListView .onChange consumers) will consume.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or trust boundary schema changes introduced. All changes are local computation within existing @MainActor ViewModels and a pure SwiftUI display view. No new threats beyond the accepted T-23-02-xx items in the plan's threat model.

## Self-Check

Checking created files exist:
- Phase23StatsViewModelTests.swift: FOUND
- Phase23GoalViewModelTests.swift: FOUND

Checking commits exist:
- 09a9281: Task 1 — StatsViewModel + StatsViewModelTests
- 4a956be: Task 2 — HeatmapView
- 234aaf9: Task 3 — GoalViewModel + GoalViewModelTests

## Self-Check: PASSED

---
*Phase: 23-milestone-features-streak-freeze*
*Completed: 2026-05-26*
