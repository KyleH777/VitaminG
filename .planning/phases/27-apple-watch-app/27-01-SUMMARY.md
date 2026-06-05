---
phase: 27-apple-watch-app
plan: "01"
subsystem: watch-foundation
tags: [watchos, entitlements, deployment-target, tdd, red-tests]
dependency_graph:
  requires: []
  provides:
    - watchOS 10.0 deployment target in VitaminGWatch target
    - VitaminGWatch.entitlements with Watch-scoped App Group
    - VitaminGWatchWidget.entitlements with Watch-scoped App Group
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
  - "VitaminGWatchWidget directory created on disk; Xcode target wiring is a human checkpoint"
metrics:
  duration: "~15 minutes"
  completed: "2026-06-05"
  tasks_completed: 3
  tasks_total: 4
  files_created: 5
  files_modified: 1
---

# Phase 27 Plan 01: Watch Foundation Setup Summary

Watch foundation setup complete: watchOS 10.0 deployment target raised, Watch-scoped App Group entitlements created, and three RED XCTest stubs committed — all buildable under VitaminGTests target.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Raise VitaminGWatch deployment target to watchOS 10.0 | f404e85 | VitaminG.xcodeproj/project.pbxproj |
| 2 | Create VitaminGWatch and VitaminGWatchWidget entitlements files | fb281cb | VitaminGWatch.entitlements, VitaminGWatchWidget.entitlements |
| 3 | Create RED XCTest stubs for WatchSnapshot, WatchSessionManager, WatchReceiver | 70370f0 | WatchSnapshotTests.swift, WatchSessionManagerTests.swift, WatchReceiverTests.swift |

## Task 4 — Human Checkpoint (Blocking)

Task 4 is a `checkpoint:human-action` requiring manual steps in Xcode and Apple Developer Portal. Execution paused here. See checkpoint details below.

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

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — no production code stubs. The test stubs are intentional RED stubs per TDD plan.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Entitlements files are local filesystem artifacts; no runtime trust boundary crossed until Apple Developer Portal registration (human checkpoint) and Xcode wiring (human checkpoint).

## Self-Check: PASSED

- [x] `VitaminG/VitaminGWatch/VitaminGWatch.entitlements` exists
- [x] `VitaminG/VitaminGWatchWidget/VitaminGWatchWidget.entitlements` exists
- [x] `VitaminG/VitaminG/VitaminGTests/WatchSnapshotTests.swift` exists
- [x] `VitaminG/VitaminG/VitaminGTests/WatchSessionManagerTests.swift` exists
- [x] `VitaminG/VitaminG/VitaminGTests/WatchReceiverTests.swift` exists
- [x] Commit f404e85 exists (Task 1)
- [x] Commit fb281cb exists (Task 2)
- [x] Commit 70370f0 exists (Task 3)
