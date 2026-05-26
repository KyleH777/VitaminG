---
phase: 22-public-profile-follow-discover
plan: 3
subsystem: ui
tags: [swiftui, viewmodel, observable, swiftdata, cloudkit, follow, discover, search, debounce]

# Dependency graph
requires:
  - phase: 22-02
    provides: ProfileSharingService.fetchFollowState/writeFollow, PublicGoalService.searchGoals/searchPeople/incrementParticipantCount, PublicProfileData/DiscoverGoalResult/DiscoverPersonResult model structs

provides:
  - PublicProfileViewModel expanded with FollowState enum, followState/followError, canCheerToday/onCheer via ApplauseGate, onFollow with spring animation
  - DiscoverViewModel with 500ms debounced search, SearchSegment (goals/people), joinGoal with Set<String> dedup, onFollowPerson MVVM seam
  - PublicGoalCard: 44pt progress ring component for PublicProfileView
  - FollowButton: three-state pill button (idle/loading/followed) with terra→sage spring transition
  - CheerButton: gold-tinted applause button with ApplauseButtonView float animation pattern
  - GoalSearchResultCard: compact Discover goal result card with Join action
  - PeopleSearchResultCard: Discover people result card with AvatarView + FollowButton + row tap
  - All Phase22PublicProfileViewModelTests live (6/6 green, 0 XCTSkip)
  - All Phase22DiscoverViewModelTests live (7/7 green, 0 XCTSkip) including test_onFollowPerson_callsWriteFollowOverride

affects:
  - 22-05 (PublicProfileView and DiscoverOverlayView screen integration — consumes all 5 components and both VMs)
  - 22-04 (parallel plan — zero file overlap confirmed)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - FollowState enum at file scope (importable by FollowButton without VM module import)
    - Task.sleep + prior-task cancellation debounce pattern (no Combine, consistent with codebase)
    - Set<String> joinedGoalIDs dedup (mark BEFORE insert — T-22-03-01 idempotency guarantee)
    - writeApplauseOverride/writeFollowOverride instance seams on VM (vs. static seams on Service in Plan 02)
    - DiscoverViewModel.onFollowPerson MVVM seam: View never calls ProfileSharingService directly

key-files:
  created:
    - VitaminG/VitaminG/VitaminG/ViewModels/DiscoverViewModel.swift
    - VitaminG/VitaminG/VitaminG/Views/Components/PublicGoalCard.swift
    - VitaminG/VitaminG/VitaminG/Views/Components/FollowButton.swift
    - VitaminG/VitaminG/VitaminG/Views/Components/CheerButton.swift
    - VitaminG/VitaminG/VitaminG/Views/Explore/Discover/GoalSearchResultCard.swift
    - VitaminG/VitaminG/VitaminG/Views/Explore/Discover/PeopleSearchResultCard.swift
  modified:
    - VitaminG/VitaminG/VitaminG/ViewModels/PublicProfileViewModel.swift
    - VitaminG/VitaminG/VitaminGTests/Phase22PublicProfileViewModelTests.swift
    - VitaminG/VitaminG/VitaminGTests/Phase22DiscoverViewModelTests.swift

key-decisions:
  - "FollowState enum placed at file scope in PublicProfileViewModel.swift so FollowButton.swift can consume it without a cross-module import — avoids a circular reference or redundant type"
  - "CheerButton reuses ApplauseButtonView float mechanic inline (identical state machine) rather than extracting a shared modifier — avoids risk to existing ApplauseButtonView tests"
  - "GoalTier.daily does not exist — test used .immediate instead (only immediate/shortTerm/longTerm/lifeGoal are valid cases)"
  - "Font chaining .fontDesign() not available on Font in this Xcode version — used .font(.system(size:design:)) parameter directly throughout all new components"
  - "onFollow() guard is followState == .idle (not != .followed) so that .loading blocks re-tap; T-22-03-02 double-tap protection"

patterns-established:
  - "Instance override seams pattern: VM exposes var xxxOverride on instance (not static on service) for isolation in @MainActor tests"
  - "Task.sleep debounce: cancel previous Task, sleep 500ms, check Task.isCancelled before calling search — no Combine"
  - "joinedGoalIDs.insert BEFORE context.insert(goal) — mark joined first to prevent race-condition duplicates on rapid taps"
  - "Views/Explore/Discover/ subdirectory established for Discover-specific card components"

requirements-completed: [PROF-01, PROF-02, PROF-03, PROF-04, DISC-01, DISC-02, DISC-04]

# Metrics
duration: 10min
completed: 2026-05-25
---

# Phase 22 Plan 3: ViewModel Behavior Layer + Presentation Components Summary

**PublicProfileViewModel expanded with FollowState/cheer gate, DiscoverViewModel created with 500ms debounce and Set-dedup joinGoal, and five pure-SwiftUI components shipped ready for Plan 05 screen integration**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-05-25T22:18:00Z
- **Completed:** 2026-05-25T22:28:22Z
- **Tasks:** 3
- **Files modified:** 9 (6 created, 3 modified)

## Accomplishments

- PublicProfileViewModel now carries full FollowState machine (.idle → .loading → .followed) with spring animation, auto-clearing followError, and ApplauseGate-delegated cheer gate — all three override seams (fetchFollowStateOverride, writeFollowOverride, writeApplauseOverride) injectable for testing
- DiscoverViewModel is the single owner of Discover search state with 500ms Task.sleep debounce, 20/60s in-session rate limiter, SearchSegment switching, and Set<String>-based joinGoal dedup; onFollowPerson MVVM seam enforces CLAUDE.md rule that Views never call services
- Five pure-presentation SwiftUI components compile and include Xcode Preview blocks: PublicGoalCard (44pt ring), FollowButton (three-state pill), CheerButton (gold float animation), GoalSearchResultCard (32pt ring + Join), PeopleSearchResultCard (AvatarView + FollowButton + tap row)
- All 13 Phase22 VM tests live: 6/6 PublicProfileViewModelTests + 7/7 DiscoverViewModelTests — zero XCTSkip remaining in both files
- Full scheme build passes

## Task Commits

1. **Task 1: Expand PublicProfileViewModel** - `ff66f08` (feat)
2. **Task 2: Create DiscoverViewModel** - `36cc9bb` (feat)
3. **Task 3: Build five SwiftUI components** - `c3d3ac8` (feat)

## Files Created/Modified

- `VitaminG/VitaminG/VitaminG/ViewModels/PublicProfileViewModel.swift` — Added FollowState enum, followState/followError, three override seams, resolveFollowState(), onFollow(), canCheerToday(), onCheer()
- `VitaminG/VitaminG/VitaminG/ViewModels/DiscoverViewModel.swift` — New: SearchSegment enum, debounced search, segment switching, joinGoal with Set dedup, onFollowPerson MVVM seam
- `VitaminG/VitaminG/VitaminG/Views/Components/PublicGoalCard.swift` — New: 44pt Circle().trim() ring + title + metadata, reduced motion aware
- `VitaminG/VitaminG/VitaminG/Views/Components/FollowButton.swift` — New: three-state pill with terra→sage spring animation, 44pt HIG touch target
- `VitaminG/VitaminG/VitaminG/Views/Components/CheerButton.swift` — New: accentGold, float animation inline, disabled opacity 0.35
- `VitaminG/VitaminG/VitaminG/Views/Explore/Discover/GoalSearchResultCard.swift` — New: 32pt ring + Join button with isJoined optimistic state
- `VitaminG/VitaminG/VitaminG/Views/Explore/Discover/PeopleSearchResultCard.swift` — New: AvatarView(size:40) + FollowButton + contentShape row tap
- `VitaminG/VitaminG/VitaminGTests/Phase22PublicProfileViewModelTests.swift` — Enabled 4 XCTSkip-wrapped tests; all 6 tests live
- `VitaminG/VitaminG/VitaminGTests/Phase22DiscoverViewModelTests.swift` — Enabled 6 XCTSkip-wrapped tests + added test_onFollowPerson_callsWriteFollowOverride; all 7 tests live

## Decisions Made

- FollowState declared at file scope in PublicProfileViewModel.swift so FollowButton can import the type without a VM module dependency
- CheerButton implements the ApplauseButtonView float mechanic inline (identical state machine: showFloat/floatOffset/floatOpacity) rather than extracting a shared modifier, to avoid regression risk to existing ApplauseButtonView tests
- GoalTier enum has no `.daily` case — test corrected to use `.immediate` (Rule 1 auto-fix)
- `.fontDesign()` method chaining not available in this Xcode SDK — all components use `.font(.system(size:design:))` parameter form

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] GoalTier.daily does not exist**
- **Found during:** Task 2 (Phase22DiscoverViewModelTests enablement)
- **Issue:** Test used `tier: .daily` but GoalTier enum only has immediate/shortTerm/longTerm/lifeGoal
- **Fix:** Changed `tier: .daily` to `tier: .immediate` in the idempotency test
- **Files modified:** Phase22DiscoverViewModelTests.swift
- **Committed in:** 36cc9bb (Task 2 commit)

**2. [Rule 3 - Blocking] .fontDesign() chaining unavailable**
- **Found during:** Task 3 (component build)
- **Issue:** `.font(.system(size: 16).fontDesign(.rounded))` produced compile error in this Xcode version
- **Fix:** Changed to `.font(.system(size: 16, design: .rounded))` in PublicGoalCard, GoalSearchResultCard, PeopleSearchResultCard
- **Files modified:** PublicGoalCard.swift, GoalSearchResultCard.swift, PeopleSearchResultCard.swift
- **Committed in:** c3d3ac8 (Task 3 commit)

**3. [Rule 3 - Blocking] withAnimation not in scope without SwiftUI import**
- **Found during:** Task 1 (PublicProfileViewModel compile)
- **Issue:** withAnimation used in onFollow() but PublicProfileViewModel only imported Observation/CloudKit
- **Fix:** Added `import SwiftUI` to PublicProfileViewModel.swift
- **Files modified:** PublicProfileViewModel.swift
- **Committed in:** ff66f08 (Task 1 commit)

---

**Total deviations:** 3 auto-fixed (2 Rule 3 blocking, 1 Rule 1 bug)
**Impact on plan:** All auto-fixes necessary for compilation. No scope creep. No architectural changes.

## Issues Encountered

- iPhone 16 simulator not available on this machine — used iPhone 17 instead for all xcodebuild commands. Tests pass identically.

## User Setup Required

None - no external service configuration required. CloudKit record types (PublicGoal, Follow) were already configured in Plan 02.

## Next Phase Readiness

- Plan 04 (parallel: VitaminGApp launch hooks, GoalViewModel check-in hook, ProfileEditSheet motto field) — zero file overlap with Plan 03
- Plan 05 (PublicProfileView redesign + DiscoverOverlayView integration) — all 5 components and both VMs are ready to be wired into screens
- Plan 06 (Phase 22 tests and verification) — Phase22PublicProfileViewModelTests and Phase22DiscoverViewModelTests are fully green

---
*Phase: 22-public-profile-follow-discover*
*Completed: 2026-05-25*
