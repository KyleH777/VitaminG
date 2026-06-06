---
phase: 27-apple-watch-app
plan: "05"
subsystem: watch-connectivity-checkin
tags: [watchos, watchconnectivity, wcsession, transferuserinfo, swiftdata, mainactor, tdd, goalviewmodel]
dependency_graph:
  requires:
    - 27-02 (WatchSessionManager.swift iOS singleton with pushSnapshot; empty didReceiveUserInfo body)
    - 27-03 (WatchReceiver + TodayGlanceView live via @AppStorage — hasCheckedInToday already wired)
  provides:
    - TodayGlanceView Check In button sends WCSession.transferUserInfo(["action":"checkIn","goalId":activeGoalId])
    - CheckInSuccessView presented optimistically on button tap via .fullScreenCover
    - WatchSessionManager.handleCheckIn validates payload + invokes onCheckIn + cancelStreakAtRiskNudge + reloadWidgetTimelines
    - VitaminGApp.init wires onCheckIn closure capturing ModelContainer (fetches Goal, calls GoalViewModel.addCheckIn)
    - WatchSessionManager.shared.activate() called after closure wired
    - GoalViewModel.addCheckIn calls WatchSessionManager.shared.pushSnapshot after every check-in
    - WatchSessionManagerTests 5/5 GREEN — all handleCheckIn paths tested via closure-injection seams
  affects:
    - 27-06 (physical-device E2E verification — transferUserInfo delivery confirmed on hardware)
    - iOS check-in path (GoalViewModel.addCheckIn now also calls pushSnapshot after every check-in)
tech_stack:
  added: []
  patterns:
    - Closure-injection seam pattern for WatchSessionManager — onCheckIn/cancelStreakAtRiskNudge/reloadWidgetTimelines are injectable so tests replace production side-effects with recording stubs
    - VitaminGApp captures ModelContainer in WCSession closure — avoids storing container in service singleton (no circular dep with GoalViewModel)
    - FetchDescriptor<CompletionEvent>() for events fetch in addCheckIn watch push — avoids SwiftData KeyPath crash from relationship traversal
key_files:
  created: []
  modified:
    - VitaminG/VitaminGWatch/Screens/TodayGlanceView.swift
    - VitaminG/VitaminG/VitaminG/Services/WatchSessionManager.swift
    - VitaminG/VitaminG/VitaminG/VitaminGApp.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
    - VitaminG/VitaminG/VitaminGTests/WatchSessionManagerTests.swift
key-decisions:
  - "FetchDescriptor<CompletionEvent>() instead of compactMap{$0.completionEvents}.flatMap{$0} in pushSnapshot call — relationship traversal via KeyPath crashes SwiftData in tests when called synchronously in addCheckIn body"
  - "onCheckIn closure assigned BEFORE activate() in VitaminGApp.init — ensures any queued userInfo delivered immediately on activation is routed to the closure (RESEARCH.md Pitfall 1)"
  - "GoalViewModel() constructed transiently in onCheckIn closure — no shared property exists; addCheckIn is method-level with no view-state dependency, so a local instance is correct"
  - "Side-effect seams (cancelStreakAtRiskNudge, reloadWidgetTimelines) are separate from onCheckIn — defensive idempotency so cancel/reload fires even when goal is not found by onCheckIn"
requirements-completed: [WATCH-03]

# Metrics
duration: ~16min
completed: "2026-06-06"
---

# Phase 27 Plan 05: Watch Check-In Relay (transferUserInfo) Summary

**Watch Check In button wired to WCSession.transferUserInfo with closure-injection architecture; WatchSessionManager.handleCheckIn validates payload on @MainActor and calls GoalViewModel.addCheckIn via same path as iOS/widget (STATE.md locked decision); GoalViewModel.addCheckIn now pushes WatchSnapshot after every check-in; WatchSessionManagerTests 5/5 GREEN**

## Performance

- **Duration:** ~16 min
- **Started:** 2026-06-06T00:25:22Z
- **Completed:** 2026-06-06T00:40:57Z
- **Tasks:** 3 of 3
- **Files modified:** 5

## Accomplishments

- `TodayGlanceView.swift` Check In button now calls `WCSession.default.transferUserInfo(["action": "checkIn", "goalId": activeGoalId])` with activation guard, presents `CheckInSuccessView` optimistically via `.fullScreenCover`, and is disabled when `hasCheckedInToday || activeGoalId.isEmpty`
- `WatchSessionManager.swift` `session(_:didReceiveUserInfo:)` dispatches to `DispatchQueue.main.async` → `handleCheckIn`; `handleCheckIn` is `@MainActor` with UUID validation guard (T-27-05-02), invokes `onCheckIn?`, `cancelStreakAtRiskNudge?`, `reloadWidgetTimelines?` — all injectable for testing
- `VitaminGApp.swift` wires `WatchSessionManager.shared.onCheckIn` to closure that fetches Goal by UUID from `container.mainContext` and calls `GoalViewModel.addCheckIn(for:context:)` — the same code path used by iOS-side and widget check-ins (locked decision)
- `GoalViewModel.addCheckIn` now calls `WatchSessionManager.shared.pushSnapshot` immediately after `reloadWidgetTimelines()` so the Watch complication and TodayGlanceView reflect `hasCheckedInToday: true` after every check-in
- `WatchSessionManagerTests.swift` all 5 tests GREEN: `invokesAddCheckInForCorrectGoal`, `callsCancelGlobalStreakAtRiskNudge`, `callsWidgetCenterReloadAllTimelines`, `ignoresPayloadWithoutActionCheckIn`, `ignoresPayloadWithInvalidGoalId`

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire Watch Check In button to transferUserInfo + optimistic navigation** — `27bef83` (feat)
2. **Task 2 RED: Add failing WatchSessionManagerTests** — `ed294c3` (test)
3. **Task 2 GREEN: Implement WatchSessionManager.handleCheckIn + closure injection seams** — `d632c5c` (feat)
4. **Task 3: Wire WatchSessionManager activation + onCheckIn closure at VitaminGApp.init; pushSnapshot after addCheckIn** — `a3223d6` (feat)

## Files Created/Modified

- `VitaminG/VitaminGWatch/Screens/TodayGlanceView.swift` — MODIFIED: added `import WatchConnectivity`, `activeGoalId` @AppStorage, `showSuccessView` @State, replaced `checkedIn = true` with `transferUserInfo` payload + optimistic navigation, added `.disabled(hasCheckedInToday || activeGoalId.isEmpty)`, `.fullScreenCover(isPresented: $showSuccessView) { CheckInSuccessView() }`, removed unused `@State private var checkedIn`
- `VitaminG/VitaminG/VitaminG/Services/WatchSessionManager.swift` — MODIFIED: added `onCheckIn: ((UUID) -> Void)?`, `cancelStreakAtRiskNudge: (() -> Void)?`, `reloadWidgetTimelines: (() -> Void)?` closure properties with production defaults; `session(_:didReceiveUserInfo:)` body dispatches via `DispatchQueue.main.async`; `@MainActor func handleCheckIn(userInfo:)` added with full UUID validation and three seam invocations; added `import WidgetKit`
- `VitaminG/VitaminG/VitaminG/VitaminGApp.swift` — MODIFIED: Step 4b adds `WatchSessionManager.shared.onCheckIn` closure capturing `container`, then `WatchSessionManager.shared.activate()` — both inserted after ModelContainer creation, before StoreKit listener
- `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` — MODIFIED: `addCheckIn` now fetches `FetchDescriptor<Goal>()` and `FetchDescriptor<CompletionEvent>()` and calls `WatchSessionManager.shared.pushSnapshot` after `reloadWidgetTimelines()`
- `VitaminG/VitaminG/VitaminGTests/WatchSessionManagerTests.swift` — MODIFIED: all 5 XCTFail stubs replaced with real assertions; tests are `@MainActor`, use closure-injection recording stubs, reset closures in tearDown

## Decisions Made

- **FetchDescriptor<CompletionEvent>() instead of relationship traversal in pushSnapshot call**: Using `allGoals.compactMap { $0.completionEvents }.flatMap { $0 }` in `addCheckIn`'s synchronous body triggers `Fatal error: This KeyPath does not appear to relate Goal to anything` in SwiftData during unit tests. Switching to a direct `FetchDescriptor<CompletionEvent>()` fetch is the correct pattern (same approach used in `rescheduleNotification`).
- **onCheckIn assigned before activate()**: RESEARCH.md Pitfall 1 warns that queued `userInfo` may be delivered immediately when activation completes; having the closure assigned first ensures no check-in relay is silently dropped.
- **Transient `GoalViewModel()` in onCheckIn closure**: `GoalViewModel` has no `shared` singleton. `addCheckIn(for:context:)` is a pure method call with no view-state dependency. A local instance is correct and consistent with how `VitaminGApp.body` uses it via `@Query`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] SwiftData KeyPath crash from relationship traversal in addCheckIn**
- **Found during:** Task 3 (full test suite run after pushSnapshot wiring)
- **Issue:** `allGoalsForWatch.compactMap { $0.completionEvents }.flatMap { $0 }` caused `Fatal error: This KeyPath does not appear to relate Goal to anything - \Goal.completionEvents` in SwiftData test context when called synchronously in `addCheckIn` body (not inside a `Task {}`)
- **Fix:** Replaced with `(try? context.fetch(FetchDescriptor<CompletionEvent>())) ?? []` — a direct fetch consistent with the pattern used in `rescheduleNotification(context:)`
- **Files modified:** `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift`
- **Verification:** Full test suite passes; WatchSessionManagerTests, WatchSnapshotTests, WatchReceiverTests all GREEN
- **Committed in:** `a3223d6` (Task 3 commit, incorporated)

---

**Total deviations:** 1 auto-fixed (Rule 1 — SwiftData runtime crash from relationship KeyPath traversal)
**Impact on plan:** Fix necessary for test suite to pass. The corrected fetch is semantically equivalent and more robust.

## Issues Encountered

- **Pre-existing test failure — `PublicProfileViewModelTests.test_fetchProfile_networkFailure_transitionsToError`**: This test was already failing before any Plan 05 changes (verified by stash/revert check). It tests CloudKit network error handling; the failure is due to a network error message assertion mismatch unrelated to Watch connectivity. Not introduced by this plan.

## Verification Results

### Watch Tests

- `WatchSessionManagerTests` — 5/5 GREEN (invokesAddCheckInForCorrectGoal, callsCancelGlobalStreakAtRiskNudge, callsWidgetCenterReloadAllTimelines, ignoresPayloadWithoutActionCheckIn, ignoresPayloadWithInvalidGoalId)
- `WatchSnapshotTests` — 6/6 GREEN (build_returnsActiveGoalId, build_returnsActiveGoalProgress, build_returnsActiveGoalTitle, build_returnsGlobalStreak, build_returnsHasCheckedInToday, codable_roundTrips)
- `WatchReceiverTests` — 5/5 GREEN (all writesToUserDefaults tests)

### Task 1 Acceptance Criteria

- `grep -c "import WatchConnectivity" TodayGlanceView.swift` → 1 (PASS)
- `grep -c "WCSession.default.transferUserInfo" TodayGlanceView.swift` → 1 (PASS)
- `grep -c '"action": "checkIn"' TodayGlanceView.swift` → 1 (PASS)
- `grep -c '"goalId"' TodayGlanceView.swift` → 1 (PASS)
- `grep -c '\.disabled(' TodayGlanceView.swift` → 1 (PASS)
- `grep -c 'CheckInSuccessView' TodayGlanceView.swift` → 3 (≥1 required) (PASS)
- `grep -c '@State private var checkedIn' TodayGlanceView.swift` → 0 (removed) (PASS)
- `grep -c 'WCSession.isSupported' TodayGlanceView.swift` → 1 (PASS)
- `xcodebuild build -scheme VitaminG` → BUILD SUCCEEDED (PASS)

### Task 2 Acceptance Criteria

- `grep -c "onCheckIn" WatchSessionManager.swift` → 4 (≥2 required) (PASS)
- `grep -c "DispatchQueue.main.async" WatchSessionManager.swift` → 4 (≥1 required) (PASS)
- `grep -c "@MainActor func handleCheckIn" WatchSessionManager.swift` → 1 (PASS)
- `grep -c "cancelStreakAtRiskNudge\|cancelGlobalStreakAtRiskNudge" WatchSessionManager.swift` → 4 (≥1 required) (PASS)
- `grep -c "reloadWidgetTimelines\|WidgetCenter.shared.reloadAllTimelines" WatchSessionManager.swift` → 4 (≥1 required) (PASS)
- `grep -c "XCTFail" WatchSessionManagerTests.swift` → 0 (PASS)
- 5/5 WatchSessionManagerTests GREEN (PASS)

### Task 3 Acceptance Criteria

- `grep -c "WatchSessionManager.shared.activate" VitaminGApp.swift` → 1 (PASS)
- `grep -c "WatchSessionManager.shared.onCheckIn" VitaminGApp.swift` → 1 (PASS)
- `grep -c "WatchSessionManager.shared.pushSnapshot" GoalViewModel.swift` → 1 (PASS)
- pushSnapshot appears at line 220, after `reloadWidgetTimelines()` at line 215, before `NOTIF-03` at line 222 (PASS)
- Full test suite passes (pre-existing PublicProfileViewModelTests failure excluded — confirmed pre-existing)

## Known Stubs

None — all files implement production behavior. CheckInSuccessView still shows hardcoded streak numbers ("Day 65 logged. Streak: 13 🔥") but that view was not a target of this plan and its dynamic data wiring is deferred to a future plan per CONTEXT.md Open Question 2.

## Threat Surface Scan

No new network endpoints or auth paths introduced. WatchSessionManager.handleCheckIn validates all untrusted input (T-27-05-02: UUID(uuidString:) guard on goalId). WCSession delegate queue dispatch is properly guarded with DispatchQueue.main.async before any SwiftData access (T-27-05-04). Same-day dedup in GoalViewModel.addCheckIn (line 171-174) prevents replay (T-27-05-05). No STRIDE mitigations from the plan's threat register are missing.

## Self-Check: PASSED

- [x] `VitaminG/VitaminGWatch/Screens/TodayGlanceView.swift` modified with WatchConnectivity import + transferUserInfo
- [x] `VitaminG/VitaminG/VitaminG/Services/WatchSessionManager.swift` has handleCheckIn + three closure seams
- [x] `VitaminG/VitaminG/VitaminG/VitaminGApp.swift` has WatchSessionManager.shared.activate + onCheckIn
- [x] `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` has WatchSessionManager.shared.pushSnapshot after reloadWidgetTimelines
- [x] `VitaminG/VitaminG/VitaminGTests/WatchSessionManagerTests.swift` has 0 XCTFail, all 5 tests pass
- [x] Commit 27bef83 exists (Task 1)
- [x] Commit ed294c3 exists (Task 2 RED)
- [x] Commit d632c5c exists (Task 2 GREEN)
- [x] Commit a3223d6 exists (Task 3)
- [x] WatchSessionManagerTests 5/5 GREEN
- [x] WatchSnapshotTests 6/6 GREEN
- [x] WatchReceiverTests 5/5 GREEN

---
*Phase: 27-apple-watch-app*
*Completed: 2026-06-06*
