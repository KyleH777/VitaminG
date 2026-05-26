---
phase: 22-public-profile-follow-discover
plan: 2
subsystem: services
tags: [cloudkit, service-layer, tdd, xctest, follow, public-goals, discover]

# Dependency graph
requires:
  - phase: 22-public-profile-follow-discover
    plan: 1
    provides: SchemaV9 (Goal.cloudKitPublicGoalRecordID, UserProfile.motto), CommunityHubModels value types (PublicProfileData, PublicGoalItem, DiscoverGoalResult, DiscoverPersonResult)
provides:
  - ProfileSharingService.publishProfile with streakLength/goalCount/motto additive parameters
  - ProfileSharingService.fetchProfile returns PublicProfileData struct
  - ProfileSharingService.fetchFollowState + writeFollow with deterministic record names and rate limiting
  - PublicGoalService with 8 static methods: writePublicGoal, deletePublicGoal, searchGoals, searchPeople, fetchGoalsForUser, incrementParticipantCount, backfillPublicGoals, syncOwnedPublicGoals
  - Test seam overrides for all CloudKit-dependent methods
affects:
  - 22-03 (PublicProfileViewModel calls fetchProfile -> PublicProfileData, followState/onFollow added)
  - 22-04 (DiscoverViewModel calls searchGoals/searchPeople/fetchGoalsForUser/incrementParticipantCount)
  - 22-05 (UI binds to DiscoverViewModel and PublicProfileViewModel)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ProfileSharingService.fetchFollowState/writeFollow: deterministic record name follower_followee (D-13)"
    - "UserDefaults rate-limit pattern: vg_follow_write_times rolling 1-hour window, 10 max writes"
    - "PublicGoalService.incrementParticipantCount: non-throwing fire-and-forget, .serverRecordChanged one-retry (D-16)"
    - "Static test seam overrides (writePublicGoalOverride etc.) for CloudKit-free unit tests"
    - "backfillPublicGoals writeOverride parameter allows per-method seam without global state"
    - "ViewState.loaded(profile: PublicProfileData) — breaking change from tuple to struct, all callers updated in same commit"

key-files:
  created:
    - VitaminG/VitaminG/VitaminG/Services/PublicGoalService.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/PublicProfileViewModel.swift
    - VitaminG/VitaminG/VitaminG/Views/PublicProfileView.swift
    - VitaminG/VitaminG/VitaminGTests/Phase22FollowServiceTests.swift
    - VitaminG/VitaminG/VitaminGTests/Phase22PublicProfileViewModelTests.swift
    - VitaminG/VitaminG/VitaminGTests/Phase22PublicGoalServiceTests.swift
    - VitaminG/VitaminG/VitaminGTests/PublicProfileViewModelTests.swift

key-decisions:
  - "ProfileSharingService.publishProfile new fields (streakLength, goalCount, motto) gated by non-default values (if > 0, if != nil) to prevent silent overwrite of existing CK fields (Pitfall 3 / T-22-02-02)"
  - "fetchFollowState/writeFollow use static closure overrides instead of CKDatabase subclass seam — CKDatabase is not mockable without elaborate infrastructure"
  - "PublicGoalService test seams are static var closures at service level — matches CommunityService.writeReply saveOverride pattern"
  - "deletePublicGoal catches .unknownItem from both CloudKit path AND the override path — same do/catch wraps both"
  - "PublicProfileViewModel.ViewState.loaded updated from tuple (displayName, avatarColorHex) to .loaded(profile: PublicProfileData) in Plan 02 alongside ProfileSharingService change — not deferred to Plan 03"

patterns-established:
  - "Static override closure seams: static var xyzOverride: ((Args) async throws -> Return)? = nil"
  - "backfillPublicGoals writeOverride parameter (not static) for fine-grained test isolation without tearDown pollution"
  - "Non-throwing incrementParticipantCount: fire-and-forget async func that catches all errors silently"

requirements-completed:
  - PROF-01
  - PROF-02
  - PROF-04
  - DISC-01
  - DISC-02
  - DISC-04

# Metrics
duration: ~30min
completed: 2026-05-25
---

# Phase 22 Plan 2: Service Layer — ProfileSharingService Expansion + PublicGoalService Summary

**ProfileSharingService expanded with streakLength/goalCount/motto fields, PublicProfileData struct return type, and fetchFollowState/writeFollow methods; PublicGoalService created with 8 static methods covering write/delete/search/fetch/increment/backfill/sync**

## Performance

- **Duration:** ~30 min
- **Completed:** 2026-05-25T21:53:00Z
- **Tasks:** 2 of 2
- **Files modified:** 8 (1 created, 7 modified)

## Accomplishments

- ProfileSharingService.publishProfile: 3 additive parameters (streakLength: Int = 0, goalCount: Int = 0, motto: String? = nil) with non-clobbering guards
- ProfileSharingService.fetchProfile: return type changed from (displayName: String?, avatarColorHex: String?) tuple to PublicProfileData struct
- ProfileSharingService.fetchFollowState: deterministic record name pattern, .unknownItem -> false
- ProfileSharingService.writeFollow: idempotent (fetch-or-create), UserDefaults rate-limit (10/hr), InputSanitizer on both username fields
- PublicGoalService created: 8 static methods, all using CKContainer(identifier:), InputSanitizer on all String writes, .serverRecordChanged one-retry pattern
- All Phase22FollowServiceTests (5 tests) active with no XCTSkip
- Phase22PublicProfileViewModelTests fetch-path tests (2) active; 4 follow/cheer tests remain XCTSkip pending Plan 03
- Phase22PublicGoalServiceTests (6 tests) all active with no XCTSkip

## Task Commits

1. **Task 1: Expand ProfileSharingService, update ViewState, enable tests** - `8459c56` (feat)
2. **Task 2: Create PublicGoalService, enable Phase22PublicGoalServiceTests** - `79e2cdf` (feat)

## Files Created/Modified

- `VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift` - EDIT: publishProfile expanded, fetchProfile returns PublicProfileData, fetchFollowState + writeFollow added, test seam closures added
- `VitaminG/VitaminG/VitaminG/Services/PublicGoalService.swift` - NEW: 8-method service enum with test seams
- `VitaminG/VitaminG/VitaminG/ViewModels/PublicProfileViewModel.swift` - EDIT: ViewState.loaded now `.loaded(profile: PublicProfileData)`; fetchOverride updated to PublicProfileData return type
- `VitaminG/VitaminG/VitaminG/Views/PublicProfileView.swift` - EDIT: content switch updated to `.loaded(profile:)` pattern
- `VitaminG/VitaminG/VitaminGTests/Phase22FollowServiceTests.swift` - EDIT: all 5 tests active, 3 CloudKit tests use override seams
- `VitaminG/VitaminG/VitaminGTests/Phase22PublicProfileViewModelTests.swift` - EDIT: fetch-path tests live; follow/cheer remain XCTSkip to Plan 03
- `VitaminG/VitaminG/VitaminGTests/Phase22PublicGoalServiceTests.swift` - EDIT: all 6 tests live using override seams + NSPredicate inspection
- `VitaminG/VitaminG/VitaminGTests/PublicProfileViewModelTests.swift` - EDIT: updated to new PublicProfileData/ViewState.loaded(profile:) signatures

## Decisions Made

- ProfileSharingService.publishProfile non-clobbering: `if streakLength > 0` and `if let motto` guards prevent silent overwrite of existing CK fields (T-22-02-02 / Pitfall 3)
- ViewState.loaded breaking change handled in Plan 02 (not deferred to 03): changing fetchProfile return type requires updating ViewModel.fetchOverride signature and all switch consumers atomically
- Test seams as static closure vars: `static var fetchFollowStateOverride: ((String, String) async throws -> Bool)?` — simpler than CKDatabase subclassing, matches writeReply saveOverride pattern in CommunityService
- deletePublicGoal catches .unknownItem from both production CloudKit path and override closure — the do/catch wraps the entire operation branch selection

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated PublicProfileViewModel.ViewState and fetchOverride in same commit as ProfileSharingService.fetchProfile return type change**
- **Found during:** Task 1
- **Issue:** Changing fetchProfile from tuple to PublicProfileData immediately breaks PublicProfileViewModel (uses return type in result handling) and PublicProfileView (pattern matches on .loaded(displayName:avatarColorHex:)). Both must update atomically.
- **Fix:** Updated PublicProfileViewModel.ViewState.loaded from `case loaded(displayName:avatarColorHex:)` to `case loaded(profile: PublicProfileData)`. Updated fetchOverride closure type. Updated PublicProfileView.content switch to match new associated value.
- **Files modified:** PublicProfileViewModel.swift, PublicProfileView.swift
- **Committed in:** `8459c56` (Task 1 commit)

**2. [Rule 1 - Bug] Updated PublicProfileViewModelTests.swift to match new signatures**
- **Found during:** Task 1 verification
- **Issue:** Existing PublicProfileViewModelTests used `fetchOverride = { _ in ("Alice", "#FF8C44") }` (tuple) and `case .loaded(let name, let hex)` which fail to compile after PublicProfileData change.
- **Fix:** Updated all tests to use `PublicProfileData(...)` and `case .loaded(let profile)` patterns.
- **Files modified:** PublicProfileViewModelTests.swift
- **Committed in:** `8459c56` (Task 1 commit)

**3. [Rule 1 - Bug] Fixed deletePublicGoal to wrap override in same .unknownItem catch**
- **Found during:** Task 2 test run
- **Issue:** test_deletePublicGoal_swallowsUnknownItem threw CKError Code=11 because the override path returned before the catch block could swallow the error.
- **Fix:** Restructured deletePublicGoal to wrap both the override call and the direct CloudKit call in a single do/catch block that swallows .unknownItem.
- **Files modified:** PublicGoalService.swift
- **Committed in:** `79e2cdf` (Task 2 commit)

**4. [Rule 2 - Missing Critical Functionality] Added UserDefaults rate-limit to writeFollow**
- **Found during:** Task 1 (plan requirement, threat model T-22-02-03)
- **Issue:** Plan acceptance criteria requires `vg_follow_write_times` rate-limit (10 writes per rolling hour); plan action explicitly describes this behavior.
- **Fix:** Added rolling-window rate-limit using UserDefaults key `vg_follow_write_times` — filters to last 3600s timestamps, throws NSError(domain: "VGRateLimit", code: 429) on breach.
- **Files modified:** ProfileSharingService.swift
- **Committed in:** `8459c56` (Task 1 commit)

---

**Total deviations:** 4 auto-fixed (3 Rule 1 bugs, 1 Rule 2 missing security control)
**Impact on plan:** All fixes required for correctness. No scope creep.

## Test Results

- Phase22FollowServiceTests: 5/5 passed (0 skipped, 0 failures)
- Phase22PublicProfileViewModelTests: 2/6 live passed, 4 skipped to Plan 03 (follow/cheer)
- Phase22PublicGoalServiceTests: 6/6 passed (0 skipped, 0 failures)
- PublicProfileViewModelTests: 4/4 passed (updated to new signatures)
- Full Phase22 suite: 17 tests, 4 skipped, 0 failures — TEST SUCCEEDED

## Known Stubs

None. All services are fully implemented. Phase22PublicProfileViewModelTests follow/cheer tests are intentional XCTSkip stubs for Plan 03 (not production code stubs).

## Threat Flags

No new security-relevant surface beyond the plan's threat model:
- T-22-02-01: motto sanitized via InputSanitizer.sanitizeForPublic before CK write ✓
- T-22-02-02: streakLength/goalCount/motto only written when non-default values provided ✓
- T-22-02-06: resultsLimit 25 hard cap on searchGoals/searchPeople ✓
- T-22-02-07: InputSanitizer.sanitizeForPublic on all String CK field writes (count >= 3 in ProfileSharingService, >= 4 in PublicGoalService) ✓
- UserDefaults rate-limit on writeFollow: T-22-02-03 accept-with-control implemented as additional control

## Self-Check: PASSED

Files verified:
- FOUND: VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift
- FOUND: VitaminG/VitaminG/VitaminG/Services/PublicGoalService.swift
- FOUND: VitaminG/VitaminG/VitaminG/ViewModels/PublicProfileViewModel.swift
- FOUND: VitaminG/VitaminG/VitaminG/Views/PublicProfileView.swift
- FOUND: VitaminG/VitaminG/VitaminGTests/Phase22FollowServiceTests.swift
- FOUND: VitaminG/VitaminG/VitaminGTests/Phase22PublicProfileViewModelTests.swift
- FOUND: VitaminG/VitaminG/VitaminGTests/Phase22PublicGoalServiceTests.swift
- FOUND: VitaminG/VitaminG/VitaminGTests/PublicProfileViewModelTests.swift

Commits verified:
- 8459c56: feat(22-02): expand ProfileSharingService with Phase 22 fields and Follow methods
- 79e2cdf: feat(22-02): create PublicGoalService with CRUD, search, increment, backfill, and sync

Test results confirmed:
- Phase22FollowServiceTests: 5/5 passed (TEST SUCCEEDED)
- Phase22PublicGoalServiceTests: 6/6 passed (TEST SUCCEEDED)
- Phase22PublicProfileViewModelTests: 2 live passed, 4 skipped to Plan 03 (TEST SUCCEEDED)
- Full combined suite: 17 tests, 4 skipped, 0 failures (TEST SUCCEEDED)

---
*Phase: 22-public-profile-follow-discover*
*Completed: 2026-05-25*
