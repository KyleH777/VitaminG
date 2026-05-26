---
phase: 22-public-profile-follow-discover
plan: 4
subsystem: ui
tags: [swiftui, swiftdata, cloudkit, publishprofile, publicgoal, mvvm]

# Dependency graph
requires:
  - phase: 22-02
    provides: ProfileSharingService.publishProfile (expanded signature with streakLength, goalCount, motto), PublicGoalService.backfillPublicGoals + syncOwnedPublicGoals

provides:
  - App launch fires three fire-and-forget Phase 22 refresh tasks (publishProfile streak/count, backfill PublicGoal, sync owned PublicGoal)
  - GoalViewModel.addCheckIn fires two fire-and-forget Phase 22 tasks (publishProfile refreshed streak, syncOwnedPublicGoals) after each check-in
  - ProfileEditSheet exposes Motto TextField with 100-char limit and char counter
  - ProfileViewModel holds draftMotto, persists on save, passes motto to publishProfile

affects:
  - 22-05
  - 22-06

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Fire-and-forget Task wrappers (Task { await ... }) for non-blocking async launch hooks (Pitfall 7)"
    - "FetchDescriptor used inside Task closures to read SwiftData from container.mainContext"
    - "isPublic consent gate on all publishProfile launch calls (T-22-04-05)"
    - "motto: nil on non-ProfileEditSheet publishProfile calls to avoid overwriting user motto (T-22-04-06)"

key-files:
  created: []
  modified:
    - VitaminG/VitaminG/VitaminG/VitaminGApp.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
    - VitaminG/VitaminG/VitaminG/Views/ProfileEditSheet.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/ProfileViewModel.swift

key-decisions:
  - "Read username from UserProfile.username (SwiftData) not @AppStorage - username field exists only in UserProfile model per Phase 17/18 implementation"
  - "Use container.mainContext directly in VitaminGApp launch Task blocks - container is a stored property, mainContext is safe on @MainActor"
  - "backfillPublicGoals requires creatorUsername param (different from plan description) - fetched from UserProfile.username inside Task"
  - "motto persisted in validateAndSaveDisplayName (save path) so a single Save action persists all three draft fields atomically"
  - "updatePublicRecordIfNeeded captures mottoValue before Task to avoid data races on @Observable state"

patterns-established:
  - "Pattern 1: VitaminGApp launch hooks use container.mainContext + FetchDescriptor inside fire-and-forget Task blocks"
  - "Pattern 2: Phase 22 check-in hooks appended after writeGlimpse Task in addCheckIn - non-destructive append pattern"
  - "Pattern 3: ProfileEditSheet motto Section mirrors username Section pattern exactly (Section/TextField/onChange/HStack counter)"

requirements-completed: [PROF-01]

# Metrics
duration: 25min
completed: 2026-05-25
---

# Phase 22 Plan 4: Launch Hooks + Check-in Hooks + Motto Field Summary

**Phase 22 data refresh cadence wired into app launch (3 fire-and-forget Tasks) and goal check-in (2 fire-and-forget Tasks), plus Motto editing in ProfileEditSheet with 100-char limit and CloudKit publish on save**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-25T22:30:00Z
- **Completed:** 2026-05-25T22:55:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- VitaminGApp.task fires three Phase 22 fire-and-forget Tasks: publishProfile (streak/count, isPublic-gated), backfillPublicGoals (D-11), syncOwnedPublicGoals (D-12)
- GoalViewModel.addCheckIn appended with two Phase 22 fire-and-forget Tasks: publishProfile (refreshed streak post-check-in, D-08) and syncOwnedPublicGoals (D-12)
- ProfileEditSheet gains Motto Section with vertical TextField, 100-char onChange clamp, char counter, and copywritten footer
- ProfileViewModel gains draftMotto, maxMottoLength = 100, load/save/publish wiring through validateAndSaveDisplayName + updatePublicRecordIfNeeded

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Phase 22 launch hooks to VitaminGApp** - `e4295a3` (feat)
2. **Task 2: Add Phase 22 check-in hooks to GoalViewModel.addCheckIn** - `dc3749a` (feat)
3. **Task 3: Add Motto field to ProfileEditSheet + ProfileViewModel** - `bc7d723` (feat)

## Files Created/Modified
- `VitaminG/VitaminG/VitaminG/VitaminGApp.swift` - Three Phase 22 fire-and-forget launch Tasks added after notification scheduling block
- `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` - Two Phase 22 fire-and-forget Tasks appended in addCheckIn after writeGlimpse Task
- `VitaminG/VitaminG/VitaminG/Views/ProfileEditSheet.swift` - Motto Section added after Username Section
- `VitaminG/VitaminG/VitaminG/ViewModels/ProfileViewModel.swift` - maxMottoLength constant, draftMotto property, load/persist/publish wiring

## Decisions Made
- Username read from `UserProfile.username` (SwiftData) not `@AppStorage("vg_username")` - the plan referenced AppStorage but the actual implementation stores username on the UserProfile model; adapted accordingly
- `backfillPublicGoals` requires a `creatorUsername` parameter not mentioned in plan description - the actual Plan 02 signature has this param; passed from UserProfile.username inside the Task
- Motto saving integrated into `validateAndSaveDisplayName` rather than creating a separate `saveMotto()` method - keeps the single Save action atomic across all three editable fields
- Used `container.mainContext` (the App's stored container property) to access SwiftData from within the fire-and-forget launch Tasks - no new ModelContainer initialization path added

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] backfillPublicGoals actual signature requires creatorUsername param**
- **Found during:** Task 1 (launch hooks)
- **Issue:** The plan described `backfillPublicGoals(goals:context:)` but the actual Plan 02 implementation is `backfillPublicGoals(goals:context:creatorUsername:writeOverride:)` - the plan description omitted the required creatorUsername argument
- **Fix:** Added inner fetch of UserProfile.username inside the Task B closure; guard on empty username before calling backfill
- **Files modified:** VitaminG/VitaminG/VitaminG/VitaminGApp.swift
- **Verification:** Build succeeded; function signature matched
- **Committed in:** e4295a3 (Task 1 commit)

**2. [Rule 1 - Bug] Username stored in UserProfile.username not @AppStorage**
- **Found during:** Task 1 and Task 2
- **Issue:** Plan referenced reading username from `@AppStorage("vg_username")` but the codebase stores it on `UserProfile.username` (SwiftData model, set in Phase 17 onboarding)
- **Fix:** Fetched UserProfile via FetchDescriptor inside each Task to read `.username`
- **Files modified:** VitaminG/VitaminG/VitaminG/VitaminGApp.swift, GoalViewModel.swift
- **Verification:** Code matches existing codebase pattern (OnboardingViewModel, UsernameScreen)
- **Committed in:** e4295a3 and dc3749a

---

**Total deviations:** 2 auto-fixed (both Rule 1 - plan description vs actual implementation mismatch)
**Impact on plan:** Both fixes were necessary to call the correct function signatures. No scope creep.

## Issues Encountered
- The test runner crashes before establishing connection in the test environment (pre-existing issue, verified by running tests on the commit before Task 1 - identical failure). The crash is unrelated to this plan's changes and appears to be a Simulator/entitlement bootstrap issue in the CI environment.

## Known Stubs
None - all three tasks implement real behavior wired to actual services.

## Threat Flags
None - all new code paths were in the plan's threat model. T-22-04-05 (isPublic privacy gate) and T-22-04-06 (motto: nil on launch refresh) mitigations are implemented as specified.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- PublicProfileViewModel (Plan 03) and DiscoverViewModel can now rely on up-to-date PublicProfile.streakLength, PublicProfile.goalCount, and PublicGoal records in CloudKit
- Motto field is wired end-to-end from UI to CloudKit - Plan 05 PublicProfileView can display it immediately
- Plans 05 and 06 can proceed; no blockers from Plan 04

## Self-Check: PASSED
- VitaminGApp.swift contains `PublicGoalService.backfillPublicGoals` and `PublicGoalService.syncOwnedPublicGoals`
- All three launch Tasks are wrapped in `Task { ... }` - no direct await in outer .task body
- isPublic guard present in launch Task A
- GoalViewModel.swift contains `ProfileSharingService.publishProfile` and `PublicGoalService.syncOwnedPublicGoals` inside addCheckIn
- ProfileEditSheet.swift has `viewModel.draftMotto` binding (TextField + char counter) and `Text("Motto")` header
- ProfileViewModel.swift has `static let maxMottoLength = 100` and `var draftMotto: String = ""`
- Build exits 0 (verified post each task)
- Commits e4295a3, dc3749a, bc7d723 verified in git log

---
*Phase: 22-public-profile-follow-discover*
*Completed: 2026-05-25*
