---
phase: 23-milestone-features-streak-freeze
plan: "01"
subsystem: data-and-services
tags: [swiftdata, migration, schema, streak-freeze, milestone-gate, tdd, iso8601]
dependency_graph:
  requires: []
  provides:
    - SchemaV10 with streakMilestonesShownJSON and completionCelebrationShown on Goal
    - StreakFreezeService with ISO8601 weekly gate + canFreezeRelativeTo helper
    - StreakMilestoneGate with vg_streakMilestonesShown UserDefaults persistence
  affects:
    - VitaminG/VitaminG/VitaminG/Models/Schema8pV2.swift (typealias updated to V10)
    - VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift (V9→V10 stage added)
    - VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift (now uses SchemaV10)
tech_stack:
  added:
    - SwiftData SchemaV10 (Schema.Version(10,0,0))
    - Foundation ISO8601 Calendar (Calendar(identifier: .iso8601))
    - JSONEncoder/JSONDecoder for Set<String> persistence in StreakMilestoneGate
  patterns:
    - VersionedSchema lightweight migration (all new fields Optional with nil defaults)
    - ApplauseGate pattern mirrored in StreakMilestoneGate (static enum + UserDefaults JSON)
    - canFreezeRelativeTo helper for testable date injection without clock mocking
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Models/SchemaV10.swift
    - VitaminG/VitaminG/VitaminG/Services/StreakMilestoneGate.swift
    - VitaminG/VitaminG/VitaminGTests/Phase23MilestoneGateTests.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Services/StreakFreezeService.swift
    - VitaminG/VitaminG/VitaminGTests/StreakFreezeTests.swift
    - VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift
    - VitaminG/VitaminG/VitaminG/Models/Schema8pV2.swift
    - VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift
    - VitaminG/VitaminG/VitaminGApp.swift
    - VitaminG/VitaminG/VitaminG/Services/PublicGoalService.swift
    - VitaminG/VitaminG/VitaminGTests/Phase22SchemaV9Tests.swift
    - VitaminG/VitaminG/VitaminGTests/Phase22DiscoverViewModelTests.swift
    - VitaminG/VitaminG/VitaminGTests/Phase22PublicGoalServiceTests.swift
decisions:
  - "canFreezeRelativeTo(_ date:) added to StreakFreezeService for testable year-boundary check without clock mocking"
  - "StreakMilestoneGate uses composite key format goalID.uuidString-threshold to independently track all 6 milestones per goal"
  - "SchemaV10 typealiases in Schema8pV2.swift advanced from V9 to V10 — all existing V9 data properties are preserved verbatim in V10"
  - "XCTestSessionIdentifier guard in VitaminGApp.init() sets no-op PublicGoalService overrides to prevent pre-existing CKContainer entitlement crash during test bootstrap"
metrics:
  duration: "18m 28s"
  completed: "2026-05-26T16:56:32Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 3
  files_modified: 10
---

# Phase 23 Plan 01: Schema + Services Foundation Summary

**One-liner:** SwiftData SchemaV10 lightweight migration adding two optional Goal fields, StreakFreezeService rewritten to ISO8601 weekly gate with year-boundary safety, and new StreakMilestoneGate service following the ApplauseGate shown-once pattern.

## Tasks Completed

| # | Task | Commit | Key Output |
|---|------|--------|-----------|
| 1 | Create SchemaV10 with two new optional Goal fields | 4e62802 | SchemaV10.swift + V9→V10 migration stage + typealias advancement |
| 2 | Fix StreakFreezeService weekly ISO8601 gate + create StreakMilestoneGate | 0e0c17d | StreakFreezeService (iso8601), StreakMilestoneGate.swift, 11 tests GREEN |

## What Was Built

### SchemaV10.swift
New VersionedSchema file adding two Optional fields to Goal:
- `streakMilestonesShownJSON: String? = nil` — JSON-encoded threshold array (belt-and-suspenders alongside StreakMilestoneGate UserDefaults)
- `completionCelebrationShown: Bool? = nil` — gate flag for MILE-06 "You did it" celebration

Both fields are Optional with nil defaults, qualifying for lightweight migration (no willMigrate/didMigrate handlers needed). VitaminGMigrationPlan updated with `migrateV9toV10` lightweight stage. ModelContainerFactory now uses SchemaV10 as the current schema version. Schema8pV2 typealiases advanced from V9 to V10.

### StreakFreezeService (rewritten canFreeze)
Changed from monthly Gregorian granularity check to ISO8601 weekly gate:
```swift
func canFreezeRelativeTo(_ date: Date) -> Bool {
    guard let lastDate = lastFreezeDate else { return true }
    let iso = Calendar(identifier: .iso8601)
    let lastWeek = iso.component(.weekOfYear, from: lastDate)
    let thisWeek = iso.component(.weekOfYear, from: date)
    let lastYear = iso.component(.yearForWeekOfYear, from: lastDate)
    let thisYear = iso.component(.yearForWeekOfYear, from: date)
    return lastWeek != thisWeek || lastYear != thisYear
}
var canFreeze: Bool { canFreezeRelativeTo(.now) }
```
Uses `yearForWeekOfYear` (not `.year`) for correct ISO8601 year component — week 52/week 1 boundary is handled correctly.

### StreakMilestoneGate.swift
New static enum service following the ApplauseGate pattern:
- Key: `vg_streakMilestonesShown` in UserDefaults
- Storage: JSON-encoded `Set<String>` with composite keys `"\(goalID.uuidString)-\(threshold)"`
- `goalStreakThresholds: [Int] = [7, 14, 30, 60, 90, 365]` — six independently trackable thresholds
- `hasShown(goalID:threshold:defaults:)` — returns false for any unseen combination
- `markShown(goalID:threshold:defaults:)` — idempotent, persists across instance recreation

## Tests

11 tests total, all GREEN:

**Phase23MilestoneGateTests (5 tests):**
- `test_hasShown_falseForFreshKey` — PASS
- `test_markShown_then_hasShown_returnsTrue` — PASS
- `test_differentThreshold_trackedIndependently` — PASS
- `test_differentGoalID_trackedIndependently` — PASS
- `test_allSixThresholdsAreDefined` — PASS

**StreakFreezeTests (6 tests):**
- `test_canFreeze_trueOnFreshInstall` — PASS
- `test_afterFreeze_canFreezeIsFalse` — PASS
- `test_frozenDates_containsTodayAfterFreeze` — PASS
- `test_freezeOnDifferentWeek_resetsAvailability` — PASS (replaces monthly test)
- `test_twoFreezesInSameWeek_secondIsIgnored` — PASS (replaces monthly test)
- `test_yearBoundary_week52ToWeek1_resetsAvailability` — PASS (new year-boundary test)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Pre-existing CKContainer entitlement crash blocking test bootstrap**
- **Found during:** Task 2 test run
- **Issue:** `VitaminGApp.body` calls `PublicGoalService.syncOwnedPublicGoals` which instantiates `CKContainer(identifier:)` — this triggers an OS-level `_os_crash` when the app lacks iCloud entitlements in the simulator test environment. Crash occurs before XCTest connection is established, preventing all tests from running.
- **Fix:** Added `syncOwnedPublicGoalsOverride` test seam to `PublicGoalService` and added `XCTestSessionIdentifier` guard in `VitaminGApp.init()` that installs no-op overrides before app body fires. Also set `writePublicGoalOverride = { _, _ in return "" }` to guard the write path.
- **Files modified:** `VitaminG/Services/PublicGoalService.swift`, `VitaminG/VitaminGApp.swift`
- **Commit:** 0e0c17d

**2. [Rule 1 - Bug] Phase22 tests broken by SchemaV9→V10 typealias advancement**
- **Found during:** Task 2 (after advancing typealias in Task 1)
- **Issue:** `Phase22SchemaV9Tests.swift` had compile-time typealias check tests asserting `Goal = SchemaV9.Goal` and `UserProfile = SchemaV9.UserProfile`. `Phase22PublicGoalServiceTests.swift` and `Phase22DiscoverViewModelTests.swift` used `SchemaV9.Goal` in `ModelContainer` constructors with functions that now expect `Goal` (aka `SchemaV10.Goal`).
- **Fix:** Updated Phase22SchemaV9Tests typealias check tests to assert V10 (tests renamed to `test_typealias_*_isV10`). Updated Phase22PublicGoalServiceTests and Phase22DiscoverViewModelTests to use `SchemaV10.Goal`.
- **Files modified:** `VitaminGTests/Phase22SchemaV9Tests.swift`, `VitaminGTests/Phase22DiscoverViewModelTests.swift`, `VitaminGTests/Phase22PublicGoalServiceTests.swift`
- **Commit:** 0e0c17d

## Known Stubs

None — all three new files are fully wired. SchemaV10 fields will be consumed by Phase 23 downstream plans (milestone UI views, celebration screen).

## Threat Surface Scan

No new network endpoints or auth paths introduced. StreakMilestoneGate and StreakFreezeService are local-only UserDefaults services. SchemaV10 adds optional CloudKit-synced fields to an existing model — no new trust boundaries. All threats are within the plan's threat model (T-23-01-01, T-23-01-02, T-23-01-03 — all accepted as soft gates).

## Self-Check

Checking created files exist:
- SchemaV10.swift: FOUND
- StreakMilestoneGate.swift: FOUND
- Phase23MilestoneGateTests.swift: FOUND

Checking commits exist:
- 4e62802: Task 1
- 0e0c17d: Task 2

## Self-Check: PASSED
