---
phase: 21-community-tab-redesign
plan: "06"
subsystem: community-hub-assembly
tags:
  - community
  - swiftui
  - cloudkit
  - navigation
  - applause
  - soc-02
  - soc-03

dependency_graph:
  requires:
    - "21-03: CommunityHubViewModel (loadAll, canApplaud, writeApplauseForUser, glimpses, activeUsers, glowingUser, feedPosts)"
    - "21-04: GlobalFeedSection, PostComposeSheet, CommunityReplySheetView, CommunityService.writeReply"
    - "21-05: GlimpsesCarouselSection, ActiveTodaySection, GlowingSpotlightSection, GlobalFeedSection"
    - "Phase 15: CommunityGoalsLandingView (COMM-01 tap destination)"
    - "Phase 17: PublicProfileView (COMM-03 and COMM-04 tap destination)"
  provides:
    - "CommunityTabView: rebuilt 5-section hub — COMM-01 card, Glimpses, Active Today, Glowing Spotlight, Community Feed"
    - "ContentView: CommunityPlaceholderView replaced with CommunityTabView"
    - "CommunityPostCard: fireCount accessor + 🔥 ReactionPill (COMM-07 extension)"
    - "ExploreView: ChallengeDiscoveryView section added at bottom (D-06 migration)"
    - "ProfileView: ApplauseStreamOverlay on self-view for SOC-02 ambient applause"
    - "PublicProfileView: 'X cheers given' counter display for SOC-03"
    - "CommunityService.fetchApplauseGivenCount: read-only SOC-03 count query"
  affects:
    - "Phase 22: follow system will add feed scoping to GlobalFeedSection"
    - "PublicProfileView: Phase 22 will expand profile details"

tech_stack:
  added: []
  patterns:
    - "CommunityTabView uses @Bindable var router = router in computed sub-views for Environment access"
    - "SOC-02 overlay placement: .overlay(alignment:.bottom) outside ScrollView content with .ignoresSafeArea()"
    - "ProfileView reuses viewModel.profile?.displayName for applause recipient username (no extra @Query)"
    - "PublicProfileView uses recordID (username string from router) as giverUsername for Applause query"

key_files:
  created: []
  modified:
    - path: "VitaminG/VitaminG/VitaminG/Views/CommunityTabView.swift"
      role: "Fully rebuilt: 5-section hub with CommunityHubViewModel, COMM-01 card, all section labels, writeUserPresence on appear"
    - path: "VitaminG/VitaminG/VitaminG/Views/ContentView.swift"
      role: "CommunityPlaceholderView swapped to CommunityTabView(selectedTab: $selectedTab)"
    - path: "VitaminG/VitaminG/VitaminG/Views/Components/CommunityPostCard.swift"
      role: "Added fireCount accessor + 🔥 ReactionPill alongside heart and thumbsUp pills"
    - path: "VitaminG/VitaminG/VitaminG/Views/Explore/ExploreView.swift"
      role: "Added DISCOVER CHALLENGES section with ChallengeDiscoveryView at bottom (D-06)"
    - path: "VitaminG/VitaminG/VitaminG/Views/ProfileView.swift"
      role: "Added receivedApplause state + ApplauseStreamOverlay overlay + .task for SOC-02"
    - path: "VitaminG/VitaminG/VitaminG/Views/PublicProfileView.swift"
      role: "Added cheersGivenCount state + .task + 'X cheers given' display for SOC-03"
    - path: "VitaminG/VitaminG/VitaminG/Services/CommunityService.swift"
      role: "Added fetchApplauseGivenCount(giverUsername:) for SOC-03 count query"

key-decisions:
  - "CommunityTabView sub-view computed properties use '@Bindable var router = router' inside the property to safely pass the @Observable AppRouter as Bindable (Swift 5.9 pattern)"
  - "ProfileView SOC-02 applause loads via viewModel.profile?.displayName — no extra @Query needed since ProfileViewModel already holds the profile"
  - "PublicProfileView uses 'recordID' as the giverUsername for fetchApplauseGivenCount — router assigns username strings to pendingPublicProfileRecordID, so recordID == username"
  - "CommunityTabView uses 'statusRaw == active' predicate for @Query(filter:) on UserChallenge — consistent with existing CommunityTabView pattern"

requirements-completed:
  - COMM-01
  - COMM-02
  - COMM-03
  - COMM-04
  - COMM-05
  - COMM-06
  - COMM-07
  - SOC-01
  - SOC-02
  - SOC-03

duration: 18min
completed: 2026-05-23
---

# Phase 21 Plan 06: Community Tab Final Assembly Summary

**Live Community hub assembled: 5-section CommunityTabView with CommunityHubViewModel, COMM-01 goal card, Glimpses/Active Today/Glowing Spotlight/Feed sections, 🔥 reaction in CommunityPostCard, ChallengeDiscovery migrated to Explore tab, SOC-02 ambient applause overlay on ProfileView, and SOC-03 cheers-given counter on PublicProfileView.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-05-23T00:00:00Z
- **Completed:** 2026-05-23
- **Tasks:** 3 of 3
- **Files modified:** 7

## Accomplishments

- Rebuilt CommunityTabView from scratch: removed CommunitySegment enum and Feed/Ideas Picker, replaced with 5-section hub driven by CommunityHubViewModel
- Swapped ContentView community tab slot from CommunityPlaceholderView to CommunityTabView; added 🔥 ReactionPill + fireCount accessor to CommunityPostCard
- Migrated ChallengeDiscoveryView to ExploreView (D-06), wired SOC-02 ambient applause overlay to ProfileView, and implemented SOC-03 "X cheers given" counter on PublicProfileView via new CommunityService.fetchApplauseGivenCount

## Task Commits

1. **Task 1: Extend CommunityPostCard (🔥 reaction) + Rebuild CommunityTabView + Swap ContentView** - `2036aa4` (feat)
2. **Task 2: Migrate ChallengeDiscoveryView to ExploreView + Wire SOC-02 to ProfileView** - `54acf51` (feat)
3. **Task 3: Add SOC-03 fetchApplauseGivenCount to CommunityService + display in PublicProfileView** - `153cc34` (feat)

## Files Created/Modified

- `VitaminG/VitaminG/VitaminG/Views/CommunityTabView.swift` — Fully rebuilt 5-section hub; CommunitySegment enum gone
- `VitaminG/VitaminG/VitaminG/Views/ContentView.swift` — CommunityPlaceholderView → CommunityTabView
- `VitaminG/VitaminG/VitaminG/Views/Components/CommunityPostCard.swift` — fireCount + 🔥 ReactionPill
- `VitaminG/VitaminG/VitaminG/Views/Explore/ExploreView.swift` — DISCOVER CHALLENGES section with ChallengeDiscoveryView
- `VitaminG/VitaminG/VitaminG/Views/ProfileView.swift` — receivedApplause state + ApplauseStreamOverlay overlay + .task
- `VitaminG/VitaminG/VitaminG/Views/PublicProfileView.swift` — cheersGivenCount + .task + "X cheers given" display
- `VitaminG/VitaminG/VitaminG/Services/CommunityService.swift` — fetchApplauseGivenCount(giverUsername:)

## Decisions Made

- `@Bindable var router = router` pattern used inside computed sub-view properties — required to pass `@Observable AppRouter` as Bindable binding to child views in Swift 5.9
- SOC-02 overlay placed with `.overlay(alignment: .bottom)` on the outer view in ProfileView body, after `.background` — ensures the overlay renders above all profile content without being clipped by the ScrollView
- ProfileView reuses `viewModel.profile?.displayName` as the applause recipient username — avoids adding a redundant `@Query private var profiles: [UserProfile]` since `ProfileViewModel.profile` already holds the same data
- `recordID` used as `giverUsername` in PublicProfileView's Applause count query — the AppRouter assigns username strings (from GoalGlimpseItem.username and UserPresenceItem.username) to `pendingPublicProfileRecordID`, making `recordID == username` a valid identity

## Deviations from Plan

None — plan executed exactly as written. All three tasks completed successfully on first build attempt.

## Issues Encountered

None. BUILD SUCCEEDED on all three task verifications.

## User Setup Required

CloudKit Console must be configured for real-device / production use. Code works in Development simulator (CloudKit creates record types lazily on first write in dev containers):

1. Create `GoalGlimpse` record type with Queryable index on `username` and `dayKey` fields
2. Create `UserPresence` record type with Queryable index on `username` and `lastActiveDate` fields
3. Create `Applause` record type with Queryable index on `giverUsername` and `recipientUsername` fields
4. Create `CommunityReply` record type with Queryable index on `parentPostID` field
5. Add `fireCount` Int64 field to existing `CommunityPost` record type and deploy

All steps performed in CloudKit Console → iCloud.com.kyleharrington.VitaminG → Schema → Record Types.

## Known Stubs

None. All sections wire directly to CloudKit-backed CommunityHubViewModel properties:
- COMM-01 card: reads live `activeChallenges` via `@Query(filter:)` from SwiftData
- Glimpses: `viewModel.glimpses` from `CommunityService.fetchGlimpses`
- Active Today: `viewModel.activeUsers` from `CommunityService.fetchActiveUsers`
- Glowing Spotlight: `viewModel.glowingUser` from deterministic `GlowingSelector`
- Feed: `viewModel.feedPosts` from `CommunityService.fetchGlobalPosts`
- SOC-02 applause: `receivedApplause` from `CommunityService.fetchReceivedApplause`
- SOC-03 cheers given: `cheersGivenCount` from `CommunityService.fetchApplauseGivenCount`

## Threat Flags

No new trust boundaries beyond those declared in the plan's threat model. All boundaries covered:
- T-21-06-01: username from CloudKit passed to AppRouter — display-only, no privileged action
- T-21-06-02: ApplauseStreamOverlay on self-view only — user sees own received applause
- T-21-06-03: ChallengeDiscoveryView in Explore is read-only — no new write surfaces
- T-21-06-04: COMM-01 card tap to CommunityGoalsLandingView — no new write surfaces
- T-21-06-05: writeUserPresence at tab appear — sanitized via InputSanitizer in CommunityService
- T-21-06-06: SOC-03 cheers count from public giverUsername — read-only, no PII beyond public profile

## Next Phase Readiness

- Community tab fully assembled and operational in Simulator
- Phase 22: follow system (PROF-02) will add feed scoping to GlobalFeedSection
- Phase 22: PublicProfileView will be expanded with full profile details
- CloudKit Console user setup required before real-device testing populates any data

---
*Phase: 21-community-tab-redesign*
*Completed: 2026-05-23*

## Self-Check: PASSED

Files exist:
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/CommunityTabView.swift` — FOUND (rebuilt)
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/ContentView.swift` — FOUND (modified)
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/Components/CommunityPostCard.swift` — FOUND (modified)
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/Explore/ExploreView.swift` — FOUND (modified)
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/ProfileView.swift` — FOUND (modified)
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/PublicProfileView.swift` — FOUND (modified)
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Services/CommunityService.swift` — FOUND (modified)

Commits exist:
- 2036aa4 — feat(21-06): rebuild CommunityTabView 5-section hub, add fireCount to CommunityPostCard, swap ContentView
- 54acf51 — feat(21-06): migrate ChallengeDiscoveryView to ExploreView, wire SOC-02 ApplauseStreamOverlay to ProfileView
- 153cc34 — feat(21-06): add fetchApplauseGivenCount to CommunityService + SOC-03 cheers given counter in PublicProfileView
