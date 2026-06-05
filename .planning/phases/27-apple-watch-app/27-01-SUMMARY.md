---
phase: 27-apple-watch-app
plan: "01"
subsystem: watch-foundation
tags: [watchos, entitlements, deployment-target, tdd, red-tests]
dependency_graph:
  requires: []
  provides:
    - watchOS 10.0 deployment target in VitaminGWatch target
    - VitaminGWatch.entitlements with Watch-scoped App Group (registered in Apple Developer Portal)
    - VitaminGWatchWidget.entitlements with Watch-scoped App Group
    - VitaminGWatchWidget Xcode target wired with VGRingView + VGWatchTheme membership
    - RED XCTest stubs for WatchSnapshot, WatchSessionManager, WatchReceiver
  affects:
    - VitaminG/VitaminG/VitaminG.xcodeproj/project.pbxproj
    - VitaminG/VitaminGWatch/
    - VitaminG/VitaminGWatchWidget/
    - VitaminG/VitaminG/VitaminGTests/
tech_stack:
  added: []
  patterns:
    - plist entitlements file for watchOS App Group
    - RED XCTest stub pattern with XCTFail placeholders
    - Apple Developer Portal App Group registration (manual)
key_files:
  created:
    - VitaminG/VitaminGWatch/VitaminGWatch.entitlements
    - VitaminG/VitaminGWatchWidget/VitaminGWatchWidget.entitlements
    - VitaminG/VitaminG/VitaminGTests/WatchSnapshotTests.swift
    - VitaminG/VitaminG/VitaminGTests/WatchSessionManagerTests.swift
    - VitaminG/VitaminG/VitaminGTests/WatchReceiverTests.swift
  modified:
    - VitaminG/VitaminG/VitaminG.xcodeproj/project.pbxproj
decisions:
  - "Watch-scoped App Group identifier is group.com.kyleharrington.VitaminGWatch (distinct from iOS group.com.kyleharrington.VitaminG)"
  - "RED test stubs reference unresolved types only in TODO comments, not in compile-time code"
  - "VitaminGWatchWidget directory created on disk; Xcode target wiring confirmed by user at checkpoint"
metrics:
  duration: "~20 minutes (including human checkpoint)"
  completed: "2026-06-05"
  tasks_completed: 4
  tasks_total: 4
  files_created: 5
  files_modified: 1
---

# Phase 27 Plan 01: Watch Foundation Setup Summary

Watch foundation fully established: watchOS 10.0 deployment target raised, Watch-scoped App Group (`group.com.kyleharrington.VitaminGWatch`) registered in Apple Developer Portal and wired in both Watch targets, entitlements files created, VitaminGWatchWidget target exists with VGRingView/VGWatchTheme membership, and three RED XCTest stubs committed — all confirming the correct Wave 0 state (build succeeds, tests fail with XCTFail messages).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Raise VitaminGWatch deployment target to watchOS 10.0 | f404e85 | VitaminG.xcodeproj/project.pbxproj |
| 2 | Create VitaminGWatch and VitaminGWatchWidget entitlements files | fb281cb | VitaminGWatch.entitlements, VitaminGWatchWidget.entitlements |
| 3 | Create RED XCTest stubs for WatchSnapshot, WatchSessionManager, WatchReceiver | 70370f0 | WatchSnapshotTests.swift, WatchSessionManagerTests.swift, WatchReceiverTests.swift |
| 4 | Human checkpoint: Apple Developer Portal + Xcode wiring — approved | (human action) | Apple Developer Portal, Xcode target settings |

## Verification Results

### Task 1
- `grep -c "WATCHOS_DEPLOYMENT_TARGET = 10.0" project.pbxproj` → `2` (PASS)
- `grep -c "WATCHOS_DEPLOYMENT_TARGET = 7.0" project.pbxproj` → `0` (PASS)
- IPHONEOS_DEPLOYMENT_TARGET lines unchanged (PASS)

### Task 2
- Both entitlements files exist at correct paths (PASS)
- Both contain `group.com.kyleharrington.VitaminGWatch` (PASS)
- Neither contains iOS-only `group.com.kyleharrington.VitaminG` without Watch suffix (PASS)
- XML structure matches VitaminGWidget.entitlements reference (PASS)

### Task 3
- All three stub files exist at correct paths (PASS)
- `xcodebuild build-for-testing` exits 0 — test bundle compiles (PASS)
- WatchSnapshotTests.swift: 7 XCTFail entries (≥6 required) (PASS)
- WatchSessionManagerTests.swift: 6 XCTFail entries (≥5 required) (PASS)
- WatchReceiverTests.swift: 6 XCTFail entries (≥5 required) (PASS)
- All files begin with `import XCTest` and `@testable import VitaminG` (PASS)
- No file imports `WatchConnectivity` or `WidgetKit` (PASS)
- WatchReceiverTests.swift: 6 `watchSnapshot_` occurrences (≥5 required) (PASS)

### Task 4 — Human Checkpoint Cleared
- App Group `group.com.kyleharrington.VitaminGWatch` registered in Apple Developer Portal (user confirmed)
- VitaminGWatch target: App Group entitlement applied in Xcode (user confirmed)
- VitaminGWatchWidget target: App Group entitlement applied in Xcode (user confirmed)
- VitaminGWatchWidget target: VGRingView.swift and VGWatchTheme.swift in Target Membership (user confirmed)
- `xcodebuild -scheme VitaminG ... build` → **BUILD SUCCEEDED** (PASS)
- RED test run (`WatchSnapshotTests`): All 6 tests FAILED with correct `XCTFail` messages (PASS — expected Wave 0 state)
  - `test_build_returnsActiveGoalTitle_fromHighestPriorityTier` — FAILED (RED stub)
  - `test_build_returnsActiveGoalProgress_zeroToOne` — FAILED (RED stub)
  - `test_build_returnsGlobalStreak_fromStreakEngine` — FAILED (RED stub)
  - `test_build_returnsHasCheckedInToday_trueWhenTodayEventExists` — FAILED (RED stub)
  - `test_build_returnsActiveGoalId_uuidString` — FAILED (RED stub)
  - `test_codable_roundTripsThroughJSONEncoderDecoder` — FAILED (RED stub)

## Deviations from Plan

None — plan executed exactly as written. Human checkpoint cleared as expected.

## Known Stubs

None — no production code stubs. The test stubs are intentional RED stubs per TDD plan; downstream plans 27-02 through 27-05 will make them GREEN.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Entitlements files are local filesystem artifacts; App Group registration in Apple Developer Portal establishes the runtime trust boundary that Plans 27-02+ depend on. No new threats beyond those already enumerated in the plan's threat register (T-27-01-01 through T-27-01-04).

## Self-Check: PASSED

- [x] `VitaminG/VitaminGWatch/VitaminGWatch.entitlements` exists
- [x] `VitaminG/VitaminGWatchWidget/VitaminGWatchWidget.entitlements` exists
- [x] `VitaminG/VitaminG/VitaminGTests/WatchSnapshotTests.swift` exists
- [x] `VitaminG/VitaminG/VitaminGTests/WatchSessionManagerTests.swift` exists
- [x] `VitaminG/VitaminG/VitaminGTests/WatchReceiverTests.swift` exists
- [x] Commit f404e85 exists (Task 1)
- [x] Commit fb281cb exists (Task 2)
- [x] Commit 70370f0 exists (Task 3)
- [x] Build succeeded (Task 4 post-checkpoint verification)
- [x] RED tests confirmed failing with XCTFail messages (Wave 0 state correct)
