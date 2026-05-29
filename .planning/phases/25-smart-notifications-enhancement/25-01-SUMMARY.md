---
phase: 25-smart-notifications-enhancement
plan: "01"
subsystem: notifications
tags: [tdd, user-defaults, app-group, notif-03, wave-0]
dependency_graph:
  requires: []
  provides:
    - NotificationPreferences.checkInHourHistoryKey
    - NotificationPreferences.nudgeSuggestionDismissedKey
    - NotificationPreferences.appendCheckInHour(_:)
    - NotificationPreferences.checkInHourHistory()
    - NotificationPreferences.modalCheckInHour()
    - NotificationPreferences.nudgeSuggestionDismissed
    - NotificationPreferences.markNudgeSuggestionDismissed()
    - NotificationSchedulerPhase25Tests (RED scaffold for NOTIF-01 through NOTIF-04)
  affects:
    - VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift
    - VitaminG/VitaminG/VitaminGTests/NotificationSchedulerPhase25Tests.swift
tech_stack:
  added: []
  patterns:
    - App Group UserDefaults FIFO array (last-14 eviction)
    - Modal computation with earliest-occurrence tie-breaking
    - TDD RED scaffold with XCTFail stubs for symbols not yet implemented
key_files:
  created:
    - VitaminG/VitaminG/VitaminGTests/NotificationSchedulerPhase25Tests.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift
decisions:
  - appendCheckInHour writes to App Group suite only (D-08, Pitfall 6 avoidance)
  - modalCheckInHour filters out-of-range hours at read-time (T-25-01-01 Tampering mitigation)
  - Tie-breaking by earliest first-occurrence index matches D-10 / Claude's Discretion
  - 8 scheduler RED tests use XCTFail stubs so build-for-testing succeeds while symbols are absent
metrics:
  duration: "~30 minutes"
  completed: "2026-05-29"
  tasks_completed: 2
  files_changed: 2
---

# Phase 25 Plan 01: TDD Scaffold and NotificationPreferences Extension Summary

**One-liner:** App Group FIFO check-in hour history, modal-hour computation, and nudge-dismissed flag added to NotificationPreferences; 14-test RED scaffold in place for NOTIF-01 through NOTIF-04.

## What Was Built

### Task 1: NotificationPreferences Extension (feat commit b0d10d5)

Extended `VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift` with seven new members at the end of the existing enum:

**New key constants:**
- `static let checkInHourHistoryKey = "checkInHourHistory"`
- `static let nudgeSuggestionDismissedKey = "nudgeSuggestionDismissed"`

**New functions and computed property:**
- `static func appendCheckInHour(_ hour: Int)` — reads `[Int]` array from App Group suite, appends `hour`, applies FIFO eviction to keep max 14 entries, writes back to App Group suite only (D-08; does NOT touch `UserDefaults.standard`)
- `static func checkInHourHistory() -> [Int]` — reads `[Int]` from App Group suite; returns `[]` when key absent or value is non-`[Int]`
- `static func modalCheckInHour() -> Int?` — applies `filter { $0 >= 0 && $0 <= 23 }` (T-25-01-01 Tampering mitigation), then computes mode; ties broken by earliest first-occurrence index in filtered history (Claude's Discretion per D-10); returns `nil` for empty filtered history
- `static var nudgeSuggestionDismissed: Bool` — reads via `.bool(forKey:)` for safe `false` default on absent or type-mismatched key (T-25-01-02 Tampering mitigation)
- `static func markNudgeSuggestionDismissed()` — writes `true` to App Group suite for permanent dismissal (D-13)

All existing members (`hourKey`, `minuteKey`, `winHourKey`, `winMinuteKey`, `save(hour:minute:)`, `saveWinTime`, `sharedHour`, `sharedMinute`, `sharedWinHour`, `sharedWinMinute`) are untouched.

### Task 2: NotificationSchedulerPhase25Tests RED Scaffold (test commit 56c7cb2)

Created `VitaminG/VitaminG/VitaminGTests/NotificationSchedulerPhase25Tests.swift` with 14 test functions:

**NOTIF-01 tone selection tests (3) — RED until Plan 02:**
1. `test_makeContent_celebratoryCopy_whenStreakGe7`
2. `test_makeContent_neutralBuildingCopy_whenStreak1To6`
3. `test_makeContent_encouragingCopy_whenStreak0`

**NOTIF-02 goal-title injection tests (3) — RED until Plan 02:**
4. `test_makeContent_twoGoalTitles`
5. `test_makeContent_singleGoal`
6. `test_makeContent_noActiveGoals_bodyIsToneMessageOnly`

**NOTIF-04 one-shot 7 PM tests (2) — RED until Plan 02:**
7. `test_schedule_oneShotStreakAtRisk_repeats_false`
8. `test_schedule_oneShotSkipped_atCapBoundary`

**NOTIF-03 pure helper tests (6) — GREEN after Task 1:**
9. `test_appendCheckInHour_fifo14`
10. `test_modalHour_returnsMode`
11. `test_modalHour_tieBreakByFirstOccurrence`
12. `test_modalHour_filtersOutOfRange`
13. `test_nudgeSuggestionDismissed_defaultsFalse`
14. `test_markNudgeSuggestionDismissed_setsTrue`

## Test Results

### NOTIF-03 Helper Tests: 6/6 GREEN

```
test_appendCheckInHour_fifo14            PASSED (0.016s)
test_markNudgeSuggestionDismissed_setsTrue PASSED (0.006s)
test_modalHour_filtersOutOfRange         PASSED (0.008s)
test_modalHour_returnsMode               PASSED (0.009s)
test_modalHour_tieBreakByFirstOccurrence PASSED (0.008s)
test_nudgeSuggestionDismissed_defaultsFalse PASSED (0.004s)
```

### Scheduler-Side Tests: 8/8 RED (expected — awaiting Plan 02)

All 8 tests fail with `XCTFail("Plan 02 required: ...")` — this is the expected RED scaffolding state. The stubs document exactly which Plan 02 symbol each test needs.

### Regression Tests: All Passing

- `NotificationSchedulerTests`: 12/12 tests PASS (existing `makeContent(activeGoals:)` signature unchanged)
- `Phase23NotificationTests`: 2/2 tests PASS (existing cap guard and identifier stability)

## Commits

| Task | Type | Hash | Files |
|------|------|------|-------|
| Task 2 (RED scaffold) | test(25-01) | 56c7cb2 | VitaminGTests/NotificationSchedulerPhase25Tests.swift |
| Task 1 (GREEN helpers) | feat(25-01) | b0d10d5 | Services/NotificationPreferences.swift |

## Deviations from Plan

### No Deviation: Execution Order

The plan's EXECUTOR NOTE explicitly stated "Run Task 2 (create test file) before Task 1's verify step." Task 2 was created first (RED), then Task 1 landed the production code (turning NOTIF-03 tests GREEN). This matches the TDD sequence.

### Minor Deviation: RED State Implementation

The 8 scheduler-side RED tests are stubs using `XCTFail("Plan 02 required: ...")` rather than referencing non-existent production symbols. This deviation was necessary because Swift cannot compile a test file that references undefined symbols — the acceptance criterion "build-for-testing succeeds" is incompatible with direct references to symbols that don't exist yet.

The stubs accurately describe what Plan 02 must implement and include commented-out code blocks showing the full GREEN test bodies, ready for Plan 02 to activate.

**Impact:** The RED scaffolding intent is fully preserved — 8 tests fail, 6 pass. Plan 02 will replace the `XCTFail` stubs with real assertions against the new production symbols.

## Known Stubs

None — the 6 NOTIF-03 helper tests exercise real production code paths that are fully wired. The 8 RED scaffold tests are intentional stubs documented as waiting for Plan 02.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The new UserDefaults keys (`checkInHourHistory`, `nudgeSuggestionDismissed`) are written to the App Group suite (`group.com.kyleharrington.VitaminG`) which is an intentionally shared space (T-25-01-03 accepted). All threat mitigations from the plan's threat model are in place:

- T-25-01-01 (out-of-range hours): `filter { $0 >= 0 && $0 <= 23 }` in `modalCheckInHour()`
- T-25-01-02 (non-bool nudgeDismissed): `.bool(forKey:)` safe-default
- T-25-01-04 (RED scaffold compile failure): verified via `build-for-testing` passing

## Self-Check: PASSED

- [x] `VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift` — exists, contains all 7 new members
- [x] `VitaminG/VitaminG/VitaminGTests/NotificationSchedulerPhase25Tests.swift` — exists, 14 test functions
- [x] Commit `56c7cb2` exists (test RED scaffold)
- [x] Commit `b0d10d5` exists (feat NotificationPreferences extension)
- [x] 6 NOTIF-03 tests GREEN, 8 scheduler tests RED
- [x] Existing NotificationSchedulerTests and Phase23NotificationTests all pass
