---
phase: 21-community-tab-redesign
plan: "03"
subsystem: community-hub
tags:
  - viewmodel
  - cloudkit
  - applause
  - animation
  - accessibility
  - tdd
dependency_graph:
  requires:
    - "21-01: CommunityHubModels (GoalGlimpseItem, UserPresenceItem, ApplauseItem)"
    - "21-02: CommunityService Phase 21 extension (fetchGlimpses, fetchActiveUsers, fetchGlowingUser, fetchGlobalPosts, writeApplause, fetchReceivedApplause)"
  provides:
    - "CommunityHubViewModel: @MainActor @Observable 5-section coordinator for CommunityTabView"
    - "ApplauseGate: daily-per-recipient gate backed by UserDefaults [String:Date] dict"
    - "GlowingSelector: deterministic ISO 8601 weekOfYear % count selection"
    - "ApplauseButtonView: reusable 👏 component with animation and daily gate display"
    - "ApplauseStreamOverlay: GeometryReader floating applause particle overlay"
  affects:
    - "Plans 05+06: CommunityTabView hub sections bind to CommunityHubViewModel"
    - "ProfileView: ApplauseStreamOverlay embedded for received applause (SOC-02)"
tech_stack:
  added:
    - "ApplauseGate enum (UserDefaults-backed, JSONEncoder/Decoder, [String:Date])"
    - "GlowingSelector enum (Calendar(identifier: .iso8601) weekOfYear % count)"
  patterns:
    - "async let parallelism for 5-section CloudKit fan-out (T-21-03-04 mitigation)"
    - "test override closure injection (mirrors CommunityFeedViewModel pattern)"
    - "per-test UserDefaults suite isolation (UUID-named suite, tearDown cleanup)"
    - "easeOut(duration: 1.0) float animation suppressed under accessibilityReduceMotion"
    - "allowsHitTesting(false) on overlay to preserve interaction with UI beneath"
key_files:
  created:
    - path: "VitaminG/VitaminG/VitaminG/ViewModels/CommunityHubViewModel.swift"
      role: "Central @Observable data source for Community tab — 5 async let parallel fetches, applause gate wrappers, glowingUser selection"
    - path: "VitaminG/VitaminG/VitaminG/Views/Community/ApplauseButtonView.swift"
      role: "Reusable 👏 button with daily gate display, float animation, accessibility labels"
    - path: "VitaminG/VitaminG/VitaminG/Views/Community/ApplauseStreamOverlay.swift"
      role: "GeometryReader particle overlay for ProfileView received applause (SOC-02)"
  modified:
    - path: "VitaminG/VitaminG/VitaminGTests/Phase21CommunityHubViewModelTests.swift"
      role: "Turned GREEN: 3 tests for loadAll() fan-out, activeToday filter, ReactionType.fire"
    - path: "VitaminG/VitaminG/VitaminGTests/Phase21ApplauseDailyGateTests.swift"
      role: "Turned GREEN: 3 tests for ApplauseGate canApplaud/markApplauseGiven per-recipient gate"
    - path: "VitaminG/VitaminG/VitaminGTests/Phase21GlowingSelectionTests.swift"
      role: "Turned GREEN: 3 tests for GlowingSelector determinism, empty array safety, ISO8601 index"
decisions:
  - "ApplauseGate and GlowingSelector extracted as standalone enums (not nested in ViewModel) — required by test stubs which call ApplauseGate.canApplaud() and GlowingSelector.selectGlowingUser() as static free functions"
  - "CommunityHubViewModel captures override closures as local vars before async let — required by Swift @MainActor isolation rules for async let child tasks"
  - "test_activeToday sets all 5 overrides — prevents EXC_BREAKPOINT from real CloudKit calls crashing the simulator test runner"
  - "fetchGlowingUserOverride typed as ((String) async throws -> [GoalGlimpseItem]?) — matches test stub comment returning nil for the override"
  - "fetchAppreciationsOverride name (not fetchApplauseOverride) — exact name required by test stubs in Phase21CommunityHubViewModelTests"
metrics:
  duration_minutes: 19
  tasks_completed: 2
  tasks_total: 2
  files_created: 3
  files_modified: 3
  tests_passing: 9
  tests_total: 9
  completed_date: "2026-05-23"
---

# Phase 21 Plan 03: CommunityHubViewModel + Applause Components Summary

CommunityHubViewModel with async let parallel 5-section fan-out, ApplauseGate (per-recipient UserDefaults daily gate), GlowingSelector (ISO 8601 weekOfYear determinism), ApplauseButtonView (float animation + a11y), and ApplauseStreamOverlay (particle overlay) — 9/9 RED tests turned GREEN.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Build CommunityHubViewModel — 5-section coordinator | 976fc05 | CommunityHubViewModel.swift, 3 test files |
| 2 | Build ApplauseButtonView + ApplauseStreamOverlay | a89b784 | ApplauseButtonView.swift, ApplauseStreamOverlay.swift |

## Verification Results

- Phase21CommunityHubViewModelTests: 3/3 PASSED
- Phase21ApplauseDailyGateTests: 3/3 PASSED
- Phase21GlowingSelectionTests: 3/3 PASSED
- Total: 9/9 tests GREEN
- Build: ** BUILD SUCCEEDED **
- `async let` count in CommunityHubViewModel.swift: 9 occurrences
- `iso8601` in CommunityHubViewModel.swift: confirmed
- `vg_community_applauseGiven` in CommunityHubViewModel.swift: 2 matches
- `accessibilityReduceMotion` in ApplauseButtonView.swift: 2 matches
- `allowsHitTesting(false)` in ApplauseStreamOverlay.swift: 1 match

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test stubs use different override names than plan specified**
- **Found during:** Task 1 — reading the RED test stubs
- **Issue:** Plan specified `fetchApplauseOverride` and `fetchFeedOverride` but test stubs used `fetchAppreciationsOverride` and `fetchPostsOverride`. Plan also specified `fetchGlowingUserOverride` returning `[GoalGlimpseItem]` but test comments showed it returning `nil` (optional return).
- **Fix:** Used exact names from test stubs (`fetchAppreciationsOverride`, `fetchPostsOverride`, `fetchGlowingUserOverride: ((String) async throws -> [GoalGlimpseItem]?)? = nil`)
- **Files modified:** CommunityHubViewModel.swift

**2. [Rule 1 - Bug] Test stubs expect ApplauseGate and GlowingSelector as standalone types**
- **Found during:** Task 1 — reading Phase21ApplauseDailyGateTests and Phase21GlowingSelectionTests
- **Issue:** Plan described applause gate and glowing selector as instance methods on CommunityHubViewModel. Test stubs call `ApplauseGate.canApplaud(recipientUsername:defaults:)` and `GlowingSelector.selectGlowingUser(from:)` as static functions on standalone enum types.
- **Fix:** Extracted as standalone enums `ApplauseGate` and `GlowingSelector` in the same file. CommunityHubViewModel delegates to them as wrappers.
- **Files modified:** CommunityHubViewModel.swift

**3. [Rule 1 - Bug] test_activeToday crashed simulator with EXC_BREAKPOINT from real CloudKit call**
- **Found during:** Task 1 verification — test passed with -only-testing filter but crashed test runner
- **Issue:** `test_activeToday_excludesUsersOlderThan2Hours` only set `fetchActiveUsersOverride` but left 4 other overrides nil. `loadAll()` then attempted a real `CommunityService.fetchGlowingUser()` CloudKit call which triggered EXC_BREAKPOINT in the simulator (no CloudKit available). `try?` swallows thrown errors but not Swift runtime traps.
- **Fix:** Added all 5 override assignments in the test to prevent any real CloudKit calls.
- **Files modified:** Phase21CommunityHubViewModelTests.swift

**4. [Rule 3 - Blocking] Simulator state contamination between test runs**
- **Found during:** Task 1 verification — first 3 test runs showed crash from Phase21ReplyTests stack frame
- **Issue:** Leftover simulator process from Phase21ReplyTests (a pre-existing RED test referencing a non-existent `saveOverride` parameter) was contaminating crash reports, causing the test runner to show TEST FAILED.
- **Fix:** Rebooted the simulator fresh via `xcrun simctl boot`. Tests then ran cleanly.
- **Impact:** Pre-existing Phase21ReplyTests crash (from Plan 04's RED stubs) is a known pre-existing issue out of scope.

## Known Stubs

None. All 5 override closures return real data or empty arrays. No placeholder text or hardcoded mock data in production code paths.

## Threat Flags

No new trust boundaries introduced beyond what was in the plan's threat model. ApplauseButtonView and ApplauseStreamOverlay render only String username data (no PII beyond self-disclosed display names, T-21-03-03 accepted).

## Self-Check: PASSED

Files exist:
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/ViewModels/CommunityHubViewModel.swift` — FOUND
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/Community/ApplauseButtonView.swift` — FOUND
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/Community/ApplauseStreamOverlay.swift` — FOUND

Commits exist:
- 976fc05 — FOUND (feat(21-03): implement CommunityHubViewModel...)
- a89b784 — FOUND (feat(21-03): add ApplauseButtonView + ApplauseStreamOverlay...)
