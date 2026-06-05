---
phase: 27-apple-watch-app
plan: "02"
subsystem: watch-connectivity-ios
tags: [watchos, watchconnectivity, wcsession, tdd, green-tests, codable, snapshot]
dependency_graph:
  requires:
    - 27-01 (Watch foundation: deployment target, App Group, entitlements, RED tests)
  provides:
    - WatchSnapshot: Codable+Equatable struct with build() delegating to WidgetDataProvider
    - WatchSessionManager: iOS-side WCSession singleton with activate() and pushSnapshot()
    - WatchSnapshotTests: 6/6 GREEN (flipped from RED stubs in Plan 01)
  affects:
    - VitaminG/VitaminG/VitaminG/Models/WatchSnapshot.swift (new)
    - VitaminG/VitaminG/VitaminG/Services/WatchSessionManager.swift (new)
    - VitaminG/VitaminG/VitaminGTests/WatchSnapshotTests.swift (updated from RED stubs to GREEN)
tech_stack:
  added:
    - WatchConnectivity framework (iOS-side: WCSession, WCSessionDelegate)
  patterns:
    - Codable+Equatable value type for WCSession JSON payload
    - NSObject+WCSessionDelegate singleton pattern (mirrors NotificationScheduler.shared)
    - WCSession.updateApplicationContext for last-writer-wins snapshot delivery
    - #if os(iOS) guard for sessionDidBecomeInactive / sessionDidDeactivate
    - #if DEBUG print logging pattern for WCSession errors (T-27-02-03 mitigation)
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Models/WatchSnapshot.swift
    - VitaminG/VitaminG/VitaminG/Services/WatchSessionManager.swift
  modified:
    - VitaminG/VitaminG/VitaminGTests/WatchSnapshotTests.swift
decisions:
  - "WatchSnapshot.build() delegates to WidgetDataProvider.build() — guaranteed identical active goal selection on iPhone and Watch"
  - "activeGoalProgress coerced to 0.0 (not nil) in WatchSnapshot per D-01: Watch progress ring requires concrete Double"
  - "activeGoalId stored as UUID.uuidString (String) for WCSession property-list safety"
  - "WatchSessionManager.pushSnapshot encodes snapshot as Data under key 'snapshot' in applicationContext dictionary"
  - "didReceiveUserInfo body left empty with TODO(Plan 27-05) — Wave 4 wires the check-in receive handler"
  - "sessionDidDeactivate calls session.activate() to re-activate after Watch switch"
metrics:
  duration: "~6 minutes"
  completed: "2026-06-05"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 1
---

# Phase 27 Plan 02: WatchSnapshot + WatchSessionManager Summary

iOS-side WatchConnectivity data layer established: `WatchSnapshot` Codable struct delegates to `WidgetDataProvider.build()` for active goal selection/progress/streak, computes `hasCheckedInToday` via `Calendar.isDateInToday`, and round-trips through `JSONEncoder/JSONDecoder` without loss. `WatchSessionManager.shared` singleton activates WCSession and pushes encoded snapshots via `updateApplicationContext(["snapshot": data])` when activated. All 6 WatchSnapshotTests flipped from RED stubs to GREEN.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Implement WatchSnapshot Codable struct + build() + GREEN tests | 09b281c | WatchSnapshot.swift (new), WatchSnapshotTests.swift (updated) |
| 2 | Implement WatchSessionManager singleton with activate() and pushSnapshot() | 361b62e | WatchSessionManager.swift (new) |

## Verification Results

### Task 1 — WatchSnapshot
- `struct WatchSnapshot: Codable, Equatable` exists (PASS)
- `grep -c "WidgetDataProvider.build"` → 3 (PASS — delegates computation)
- `grep -c "isDateInToday"` → 1 (PASS — hasCheckedInToday)
- `grep -c "static let placeholder"` → 1 (PASS)
- `grep -c "XCTFail" WatchSnapshotTests.swift` → 0 (PASS — all stubs replaced)
- `xcodebuild test -only-testing:VitaminGTests/WatchSnapshotTests` → **TEST SUCCEEDED** — 6/6 GREEN

### Task 2 — WatchSessionManager
- `final class WatchSessionManager: NSObject, WCSessionDelegate` → 1 (PASS)
- `static let shared = WatchSessionManager()` → 1 (PASS)
- `import WatchConnectivity` → 1 (PASS)
- `WCSession.isSupported()` → 3 occurrences (PASS)
- `activationState == .activated` → 3 occurrences (PASS)
- `updateApplicationContext` → 7 occurrences (PASS)
- `#if os(iOS)` → 2 occurrences (PASS)
- `xcodebuild build -scheme VitaminG` → **BUILD SUCCEEDED** (PASS)

### Plan Verification
- `xcodebuild build -scheme VitaminG` → BUILD SUCCEEDED (PASS)
- `xcodebuild test -only-testing:VitaminGTests/WatchSnapshotTests` → TEST SUCCEEDED — 6/6 GREEN (PASS)
- WatchSessionManagerTests remain RED (PASS — Wave 4 makes them GREEN, per plan success criteria 5)
- WatchReceiverTests remain RED (PASS — Wave 2/3 makes them GREEN)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| `static let placeholder` | WatchSnapshot.swift | 41 | Intentional — spec-required for widget gallery preview; not a data stub |
| `session(_:didReceiveUserInfo:)` empty body | WatchSessionManager.swift | 107 | Intentional — Wave 4 (Plan 27-05) wires check-in relay per plan `<action>` specification; documented with TODO(Plan 27-05) comment |

The `didReceiveUserInfo` empty body is not a blocking stub — the plan explicitly states "Do NOT modify VitaminGApp.swift or GoalViewModel.swift in this wave — wiring at the call site happens in Wave 4." Plan 02's success criteria are fully met.

## Threat Surface Scan

No new network endpoints, auth paths, or untrusted input boundaries introduced. The `WatchConnectivity` channel is Apple-managed (iPhone↔Watch same user). The `updateApplicationContext` `do/catch` wrapper implements T-27-02-03 mitigation (no app crash on WCSession unavailability). The `#if os(iOS)` guards for iOS-only delegate methods follow the RESEARCH.md Pitfall 6 warning. No new threats beyond the plan's threat register (T-27-02-01 through T-27-02-04).

## Self-Check: PASSED

- [x] `VitaminG/VitaminG/VitaminG/Models/WatchSnapshot.swift` exists
- [x] `VitaminG/VitaminG/VitaminG/Services/WatchSessionManager.swift` exists
- [x] `VitaminG/VitaminG/VitaminGTests/WatchSnapshotTests.swift` updated (0 XCTFail)
- [x] Commit 09b281c exists (Task 1)
- [x] Commit 361b62e exists (Task 2)
- [x] WatchSnapshotTests: 6/6 GREEN
- [x] WatchSessionManagerTests: still RED (expected)
- [x] Build succeeded
