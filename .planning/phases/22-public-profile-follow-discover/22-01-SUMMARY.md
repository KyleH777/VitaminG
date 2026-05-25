---
phase: 22-public-profile-follow-discover
plan: 1
subsystem: database
tags: [swiftdata, cloudkit, schema-migration, tdd, xctest]

# Dependency graph
requires:
  - phase: 21-community-tab-redesign
    provides: ApplauseGate, CommunityHubModels struct pattern, @MainActor @Observable ViewModel pattern
  - phase: 15-ui-additions-fixes
    provides: SchemaV8 with UserProfile.username field (basis for lightweight V9 migration)
provides:
  - SchemaV9 VersionedSchema with UserProfile.motto (String? = nil) and Goal.cloudKitPublicGoalRecordID (String? = nil)
  - VitaminGMigrationPlan extended to V9 via lightweight migrateV8toV9 stage
  - Schema8pV2 typealiases Goal and UserProfile both resolve to SchemaV9 types
  - CommunityHubModels with four new value types: PublicProfileData, PublicGoalItem, DiscoverGoalResult, DiscoverPersonResult
  - Five Phase22*Tests files: Phase22SchemaV9Tests passes 6/6 green; four others compile with XCTSkip stubs
affects:
  - 22-02 (ProfileSharingService expansion uses PublicProfileData struct)
  - 22-03 (PublicProfileViewModel uses PublicProfileData + followState from new SchemaV9 UserProfile)
  - 22-04 (PublicGoalService uses Goal.cloudKitPublicGoalRecordID + PublicGoalItem struct)
  - 22-05 (DiscoverViewModel uses DiscoverGoalResult + DiscoverPersonResult structs)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SchemaV9 lightweight migration: two optional fields with = nil defaults appended to UserProfile and Goal (CLAUDE.md CloudKit sync rule)"
    - "Schema8pV2 CompletionEvent.goal relationship updated when Goal typealias changes schema version"
    - "XCTSkip + #if false COMPILE-GATE pattern for Wave 0 test stubs that reference symbols from later plans"

key-files:
  created:
    - VitaminG/VitaminG/VitaminG/Models/SchemaV9.swift
    - VitaminG/VitaminG/VitaminGTests/Phase22SchemaV9Tests.swift
    - VitaminG/VitaminG/VitaminGTests/Phase22PublicProfileViewModelTests.swift
    - VitaminG/VitaminG/VitaminGTests/Phase22FollowServiceTests.swift
    - VitaminG/VitaminG/VitaminGTests/Phase22PublicGoalServiceTests.swift
    - VitaminG/VitaminG/VitaminGTests/Phase22DiscoverViewModelTests.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift
    - VitaminG/VitaminG/VitaminG/Models/Schema8pV2.swift
    - VitaminG/VitaminG/VitaminG/Models/CommunityHubModels.swift
    - VitaminG/VitaminG/VitaminG.xcodeproj/project.pbxproj
    - VitaminG/VitaminG/VitaminGTests/BiometricLockServiceTests.swift

key-decisions:
  - "SchemaV9.Goal includes cloudKitPublicGoalRecordID: String? = nil for lightweight V9 migration (D-10)"
  - "SchemaV9.UserProfile includes motto: String? = nil for lightweight V9 migration (D-07)"
  - "SchemaV2.CompletionEvent.goal updated from SchemaV6.Goal? to SchemaV9.Goal? when Goal typealias changes"
  - "Phase22SchemaV9Tests: 6 live tests (no XCTSkip) because SchemaV9 ships in Plan 01"
  - "Four other Phase22*Tests files use XCTSkip + #if false COMPILE-GATE for symbols in Plans 02-04"

patterns-established:
  - "COMPILE-GATE: #if false block containing real assertion, enabled when production symbol ships in later plan"
  - "XCTSkip with descriptive message citing plan number that implements the symbol"
  - "CompletionEvent.goal relationship type must be updated in same commit as Goal typealias update"

requirements-completed:
  - PROF-01
  - PROF-02
  - PROF-04
  - DISC-01
  - DISC-02
  - DISC-04

# Metrics
duration: 75min
completed: 2026-05-25
---

# Phase 22 Plan 1: Data Layer + RED Test Scaffolding Summary

**SchemaV9 lightweight migration (motto + cloudKitPublicGoalRecordID), four Phase 22 CommunityHubModels value types, and five Phase22*Tests files with Phase22SchemaV9Tests passing 6/6 green**

## Performance

- **Duration:** ~75 min
- **Started:** 2026-05-25T18:10:00Z
- **Completed:** 2026-05-25T19:25:44Z
- **Tasks:** 4 of 4 (Task 4 human-verified: CloudKit schema deployed to Production)
- **Files modified:** 10

## Accomplishments
- SchemaV9 created with UserProfile.motto and Goal.cloudKitPublicGoalRecordID as optional nil-defaulting fields qualifying for lightweight SwiftData migration
- VitaminGMigrationPlan extended: SchemaV9.self in schemas array, migrateV8toV9 lightweight stage added
- Schema8pV2 typealiases updated: Goal -> SchemaV9.Goal, UserProfile -> SchemaV9.UserProfile
- CommunityHubModels expanded with PublicProfileData (Equatable+Sendable), PublicGoalItem, DiscoverGoalResult, DiscoverPersonResult (all Identifiable+Sendable)
- Five Phase22*Tests files created: Phase22SchemaV9Tests 6/6 passing; 4 others compile with XCTSkip stubs ready for Plans 02-04

## Task Commits

Each task was committed atomically:

1. **Task 1: Add SchemaV9, extend migration plan, update typealiases** - `1962fbc` (feat)
2. **Task 2: Add Phase 22 value-type structs to CommunityHubModels** - `9488976` (feat)
3. **Task 3: Create five Phase22 RED test stub files** - `0f2aa87` (test)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `VitaminG/VitaminG/VitaminG/Models/SchemaV9.swift` - NEW: SchemaV9 VersionedSchema with UserProfile (+ motto) and Goal (+ cloudKitPublicGoalRecordID)
- `VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift` - EDIT: added SchemaV9.self to schemas[], migrateV8toV9 to stages[], static let migrateV8toV9
- `VitaminG/VitaminG/VitaminG/Models/Schema8pV2.swift` - EDIT: typealiases Goal->SchemaV9.Goal, UserProfile->SchemaV9.UserProfile; CompletionEvent.goal->SchemaV9.Goal?
- `VitaminG/VitaminG/VitaminG/Models/CommunityHubModels.swift` - EDIT: added PublicProfileData, PublicGoalItem, DiscoverGoalResult, DiscoverPersonResult under Phase 22 MARK
- `VitaminG/VitaminG/VitaminG.xcodeproj/project.pbxproj` - EDIT: added SchemaV9.swift to Recovered References group and widget Sources build phase
- `VitaminG/VitaminG/VitaminGTests/Phase22SchemaV9Tests.swift` - NEW: 6 live tests (motto defaults/persist, cloudKitPublicGoalRecordID defaults/persist, typealias compile-time checks)
- `VitaminG/VitaminG/VitaminGTests/Phase22PublicProfileViewModelTests.swift` - NEW: PROF-01/02/03 stubs with XCTSkip (Plan 03)
- `VitaminG/VitaminG/VitaminGTests/Phase22FollowServiceTests.swift` - NEW: 2 deterministic record-name tests green; 3 CloudKit stubs XCTSkip (Plan 02)
- `VitaminG/VitaminG/VitaminGTests/Phase22PublicGoalServiceTests.swift` - NEW: 6 stubs XCTSkip (Plan 02)
- `VitaminG/VitaminG/VitaminGTests/Phase22DiscoverViewModelTests.swift` - NEW: 6 stubs XCTSkip (Plan 04)
- `VitaminG/VitaminG/VitaminGTests/BiometricLockServiceTests.swift` - EDIT: Rule 3 fix (see Deviations)

## Decisions Made
- SchemaV9.Goal includes cloudKitPublicGoalRecordID as optional String? = nil (D-10 lightweight migration constraint)
- SchemaV9.UserProfile includes motto as optional String? = nil (D-07 lightweight migration constraint)
- Phase22SchemaV9Tests: zero XCTSkip calls — all 6 tests run live since SchemaV9 ships in Plan 01
- COMPILE-GATE pattern (#if false blocks) used for test assertions referencing symbols from Plans 02-04

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated SchemaV2.CompletionEvent.goal relationship from SchemaV6.Goal? to SchemaV9.Goal?**
- **Found during:** Task 1 (build verification after typealias update)
- **Issue:** When `typealias Goal = SchemaV9.Goal`, GoalViewModel.swift failed to compile: `cannot assign value of type 'Goal' (aka 'SchemaV9.Goal') to type 'SchemaV6.Goal'`. The SchemaV2.CompletionEvent.goal property was still typed as SchemaV6.Goal? (its previous version), but all call sites now pass SchemaV9.Goal (via typealias).
- **Fix:** Updated Schema8pV2.swift SchemaV2.CompletionEvent.goal property and init parameter from SchemaV6.Goal? to SchemaV9.Goal?. This is consistent with how V8 updated UserProfile — when a new schema version introduces the active type, the shared CompletionEvent must reflect the current active Goal type.
- **Files modified:** VitaminG/VitaminG/VitaminG/Models/Schema8pV2.swift
- **Verification:** Build succeeded after fix: `** BUILD SUCCEEDED **`
- **Committed in:** `1962fbc` (Task 1 commit)

**2. [Rule 3 - Blocking] Fixed BiometricLockServiceTests.swift Swift 6 actor isolation errors**
- **Found during:** Task 3 (test build verification for Phase22SchemaV9Tests)
- **Issue:** Pre-existing errors in BiometricLockServiceTests.swift: "call to main actor-isolated instance method 'resetForTesting()' in a synchronous nonisolated context" (Swift 6 strict concurrency). These prevented the entire VitaminGTests target from building, blocking Phase22SchemaV9Tests from running.
- **Fix:** Added @MainActor annotation to BiometricLockServiceTests class. BiometricLockService is already @MainActor-isolated; the test class must match.
- **Files modified:** VitaminG/VitaminG/VitaminGTests/BiometricLockServiceTests.swift
- **Verification:** All 6 Phase22SchemaV9Tests passed after fix: `Executed 6 tests, with 0 failures (0 unexpected) in 0.064 seconds`
- **Committed in:** `0f2aa87` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (1 Rule 1 bug, 1 Rule 3 blocking)
**Impact on plan:** Both fixes necessary for correctness and test execution. No scope creep.

## Issues Encountered
- Xcode simulator available as "iPhone 17" (not "iPhone 16" as specified in plan verification commands) — used iPhone 17 throughout. All commands succeeded.
- SchemaV9 required explicit addition to Xcode project file (project.pbxproj) since it was not in the filesystem-synchronized root group — added to Recovered References group and widget Sources build phase.

## Checkpoint: Task 4 — CloudKit Console Deployment

**Status:** COMPLETE — human-verified 2026-05-25

Task 4 `checkpoint:human-verify` gate satisfied. Both `PublicGoal` and `Follow` record types are live in CloudKit Production. New `PublicProfile` fields (`streakLength`, `goalCount`, `motto`) and the Queryable index on `username` are deployed and active.

## Known Stubs

None. All structs added to CommunityHubModels are fully defined value types (no placeholder data). Phase22*Tests stubs are intentional Wave 0 scaffolding documented via XCTSkip messages.

## Threat Flags

No new security-relevant surface introduced beyond what the threat model in the plan already covers. All new fields (motto, cloudKitPublicGoalRecordID) are additive SwiftData optional fields with nil defaults — no trust boundary impact at this data layer stage.

## Next Phase Readiness
- Plans 02-05 in Phase 22 can proceed once CloudKit Console Task 4 checkpoint is resolved
- SchemaV9 migration chain is complete — no further data model changes needed for Phase 22
- All four Phase 22 value types are importable by services, ViewModels, and views in later plans
- Phase22*Tests files provide compile-time gates that will activate as Plans 02-04 add production symbols

## Self-Check: PASSED

Files verified:
- FOUND: VitaminG/VitaminG/VitaminG/Models/SchemaV9.swift
- FOUND: VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift
- FOUND: VitaminG/VitaminG/VitaminG/Models/Schema8pV2.swift
- FOUND: VitaminG/VitaminG/VitaminG/Models/CommunityHubModels.swift
- FOUND: VitaminG/VitaminG/VitaminGTests/Phase22SchemaV9Tests.swift
- FOUND: VitaminG/VitaminG/VitaminGTests/Phase22PublicProfileViewModelTests.swift
- FOUND: VitaminG/VitaminG/VitaminGTests/Phase22FollowServiceTests.swift
- FOUND: VitaminG/VitaminG/VitaminGTests/Phase22PublicGoalServiceTests.swift
- FOUND: VitaminG/VitaminG/VitaminGTests/Phase22DiscoverViewModelTests.swift

Commits verified:
- 1962fbc: feat(22-01): add SchemaV9, extend migration plan, update typealiases
- 9488976: feat(22-01): add Phase 22 value-type structs to CommunityHubModels
- 0f2aa87: test(22-01): create five Phase22 RED test stub files and fix BiometricLockServiceTests

Test results:
- Phase22SchemaV9Tests: 6/6 passed (BUILD SUCCEEDED + TEST SUCCEEDED)
- Phase22* full suite: 29 tests, 21 skipped, 0 failures (TEST SUCCEEDED)

---
*Phase: 22-public-profile-follow-discover*
*Completed: 2026-05-25*
