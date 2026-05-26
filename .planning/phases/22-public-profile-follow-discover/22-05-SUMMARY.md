---
phase: 22-public-profile-follow-discover
plan: 5
subsystem: ui
tags: [swiftui, mvvm, public-profile, discover, search, cloudkit, spritekit]

# Dependency graph
requires:
  - phase: 22-03
    provides: PublicProfileViewModel, DiscoverViewModel, PublicGoalCard, FollowButton, CheerButton, GoalSearchResultCard, PeopleSearchResultCard
  - phase: 22-04
    provides: Motto field in ProfileViewModel, Phase 22 launch/check-in hooks
  - phase: 17
    provides: PublicProfileView shell (NavigationStack, Done toolbar, block/report alert, MailComposeView)
provides:
  - PublicProfileView redesigned with full UI-SPEC §PublicProfileView card (hero, stats, action, goals, footer)
  - Explore tab .searchable on NavigationStack — three-branch body (normal / trending-only / discover results)
  - DiscoverOverlayView with segmented Goals/People picker, tier-picker Join dialog, PublicProfileView sheet on People tap
  - PublicProfileViewModel extended with publicGoals property and fetchGoalsForUser call
  - All eight Phase 22 requirements reachable from running app (PROF-01–04, DISC-01–04)
affects:
  - phase 23 (any community or social expansion builds on this public-profile + discover surface)
  - phase 17 (block/report regression baseline verified)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Three-branch ExploreView body driven by @Environment(\\.isSearching) + searchText.isEmpty"
    - ".searchable placed on NavigationStack ancestor (not ScrollView) per Pitfall 1 in 22-RESEARCH.md"
    - "DiscoverViewModel.onFollowPerson as MVVM seam — Views never call ProfileSharingService directly"
    - "fetchGoalsForUserOverride test seam on PublicProfileViewModel for unit test injection"
    - "GoalTier.allCases confirmationDialog buttons — closed enum prevents tier injection (T-22-05-03)"

key-files:
  created:
    - VitaminG/VitaminG/VitaminG/Views/Explore/Discover/DiscoverOverlayView.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/PublicProfileView.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/PublicProfileViewModel.swift
    - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
    - VitaminG/VitaminG/VitaminG/Views/Explore/ExploreView.swift

key-decisions:
  - "Per-row follow state on PeopleSearchResultCard deferred to future phase — MVP shortcut documented with // MVP NOTE: comment; authoritative follow state visible when user taps through to PublicProfileView"
  - ".searchable placed on the NavigationStack that wraps ExploreView in ContentView (not inside ExploreView or its ScrollView) to satisfy @Environment(\\.isSearching) requirement"
  - "existingScrollContent private computed var pattern preserves all six ExploreView sections without modification while enabling three-branch body"
  - "fetchGoalsForUserOverride test seam added to PublicProfileViewModel so Phase 22 unit tests can inject mock goal lists without CloudKit"

patterns-established:
  - "MVVM seam pattern: DiscoverViewModel.onFollowPerson wraps fire-and-forget service call; View must not call ProfileSharingService.writeFollow directly"
  - "Three-branch search body: isSearching && searchText.isEmpty -> trending, isSearching -> overlay, else -> normal content"
  - "Human-verify checkpoint gate for animation/responsiveness that cannot be automated — return 'approved' signal before docs commit"

requirements-completed: [PROF-01, PROF-02, PROF-03, PROF-04, DISC-01, DISC-02, DISC-03, DISC-04]

# Metrics
duration: ~25min
completed: 2026-05-25
---

# Phase 22 Plan 5: Screen Integration + Human Verify Summary

**PublicProfileView redesigned to full UI-SPEC card (80pt hero, stats row, Follow/Cheer action row, public goals list, block/report footer); Explore tab wired with .searchable on NavigationStack driving a three-branch ExploreView body; DiscoverOverlayView created with segmented Goals/People picker, Join tier-picker dialog, and People-row sheet navigation — human verified on simulator and approved**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-25T22:40:00Z
- **Completed:** 2026-05-26T03:05:23Z
- **Tasks:** 3 (2 auto + 1 human-verify)
- **Files modified:** 5

## Accomplishments
- Redesigned PublicProfileView from Phase 17's minimal stub into the full UI-SPEC §PublicProfileView layout — hero card, three-cell stats row, Follow/Cheer action row, MY PUBLIC GOALS LazyVStack, Report/Block footer — while preserving the Phase 17 NavigationStack shell, Done toolbar, block/report alert, and MailComposeView verbatim
- Wired Explore tab with .searchable on ContentView's NavigationStack and created DiscoverOverlayView — ExploreView body now branches between three states: normal 6-section Explore, trending-only (active + empty search), and Goals/People discover results (active + typed search)
- Extended PublicProfileViewModel with publicGoals property and fetchGoalsForUser call (with test seam); DiscoverOverlayView routes all follow actions through DiscoverViewModel.onFollowPerson MVVM seam — no direct service calls from Views
- Human verified all UI flows on iPhone 16 simulator — PublicProfileView card, Explore search branching, Join tier picker, People-row sheet navigation, block/report footer, and accessibility (Reduce Motion) all approved

## Task Commits

Each task was committed atomically:

1. **Task 1: Redesign PublicProfileView per UI-SPEC** - `9f3c921` (feat)
2. **Task 2: Add .searchable and create DiscoverOverlayView** - `5a3809d` (feat)
3. **Task 3: Human verify — simulator approval** - `3c044d8` (test)

**Plan metadata:** _(docs commit follows this SUMMARY)_

## Files Created/Modified
- `VitaminG/VitaminG/VitaminG/Views/PublicProfileView.swift` - Full UI-SPEC §PublicProfileView card replacing Phase 17 minimal stub; NavigationStack shell preserved verbatim
- `VitaminG/VitaminG/VitaminG/ViewModels/PublicProfileViewModel.swift` - Added publicGoals: [PublicGoalItem], fetchGoalsForUserOverride test seam, fetchGoalsForUser call in fetchProfile success path
- `VitaminG/VitaminG/VitaminG/Views/ContentView.swift` - Added @State exploreSearchText + .searchable(placement: .navigationBarDrawer, prompt: "Search goals or people…") on ExploreView's NavigationStack
- `VitaminG/VitaminG/VitaminG/Views/Explore/ExploreView.swift` - Added @Environment(\.isSearching), moved existing body to existingScrollContent, three-branch body for D-02/D-03/D-04
- `VitaminG/VitaminG/VitaminG/Views/Explore/Discover/DiscoverOverlayView.swift` - NEW: segmented Picker, LazyVStack with GoalSearchResultCard + PeopleSearchResultCard, confirmationDialog tier picker, PublicProfileView sheet on People row tap

## Decisions Made
- Per-row follow state on PeopleSearchResultCard deferred to a future phase (MVP shortcut) — each row shows `.idle` state; authoritative follow state is visible when tapping through to the PublicProfileView sheet. Documented with `// MVP NOTE:` comment in DiscoverOverlayView.swift.
- `.searchable` placed on the NavigationStack in ContentView (not inside ExploreView or its ScrollView) — required for `@Environment(\.isSearching)` to propagate correctly per Pitfall 1 in 22-RESEARCH.md.
- `existingScrollContent` private computed var preserves all six ExploreView sections untouched while enabling the three-branch body switch.
- `fetchGoalsForUserOverride` test seam added to PublicProfileViewModel so Phase 22 XCTest suite can inject mock [PublicGoalItem] without CloudKit.

## Deviations from Plan

None — plan executed exactly as written. All acceptance criteria verified, MVVM constraints maintained, Phase 17 block/report shell preserved verbatim.

## Issues Encountered
None — build was clean on first attempt for both tasks. Human verify checkpoint returned "approved" without identified regressions.

## User Setup Required
None — no external service configuration required.

## Known Stubs
- **Per-row follow state (DiscoverOverlayView):** Each PeopleSearchResultCard receives `followState: .idle` — the per-row follow state is not freshly fetched from CloudKit on search load. This is an explicit MVP shortcut documented with `// MVP NOTE:` in DiscoverOverlayView.swift. Future plan: add per-row FollowState resolution in DiscoverViewModel when the People segment is selected.

## Next Phase Readiness
- All eight Phase 22 requirements (PROF-01–04, DISC-01–04) are reachable from the running app — this completes Phase 22's public profile and discover feature surface
- Phase 17 block/report regression verified intact — PROF-05 baseline maintained
- Per-row follow state freshness (DiscoverOverlayView MVP shortcut) is a known deferred item for a future community/social phase
- Ready for Phase 23 or any follow-on that builds on the public profile + discover screens

---
*Phase: 22-public-profile-follow-discover*
*Completed: 2026-05-25*
