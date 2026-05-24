---
phase: 21-community-tab-redesign
plan: "05"
subsystem: community-hub-sections
tags:
  - community
  - carousel
  - timer
  - swiftui
  - cloudkit
  - accessibility
dependency_graph:
  requires:
    - "21-03: CommunityHubViewModel (glimpses, activeUsers, glowingUser, feedPosts, writeApplauseForUser, canApplaud)"
    - "21-04: CommunityReplySheetView (onWriteReply closure), PostComposeSheet (camera dialog)"
  provides:
    - "GlimpsesCarouselSection: TabView(.page) carousel with 5s auto-advance + DragGesture pause + applause + nav tap"
    - "ActiveTodaySection: horizontal ScrollView of UserPresenceItem avatar cards with profile nav tap"
    - "GlowingSpotlightSection: hero card with gold ring, username serif(20), goal title, ApplauseButtonView"
    - "GlobalFeedSection: LazyVStack CommunityPostCard feed with optimistic reaction, reply sheet, compose CTA"
    - "CommunityHubViewModel: toggleReaction, reportPost, writeReply delegates added"
  affects:
    - "Plan 21-06: CommunityTabView assembles these four section views into the final hub layout"
tech_stack:
  added:
    - "Combine (Timer.publish autoconnect for carousel auto-advance)"
  patterns:
    - "Timer.publish(every:5).autoconnect() + isDragging guard for carousel (T-21-05-03 mitigation)"
    - "TabView(.page indexDisplayMode:.automatic) for carousel page dots"
    - "Optimistic mutual-exclusion reaction toggle (mirrors CommunityFeedView.handleReact)"
    - "CommunityReplySheetView via showReplySheet + activeReplyPostID String binding"
    - "Local CommunityFeedViewModel for PostComposeSheet in GlobalFeedSection"
    - "Button .buttonStyle(.plain) on card wrapper to allow embedded ApplauseButtonView to retain own tap"
key_files:
  created:
    - path: "VitaminG/VitaminG/VitaminG/Views/Community/GlimpsesCarouselSection.swift"
      role: "TabView(.page) carousel with 5s Timer auto-advance, DragGesture pause, GlimpseCard subview with AvatarView + ApplauseButtonView"
    - path: "VitaminG/VitaminG/VitaminG/Views/Community/ActiveTodaySection.swift"
      role: "Horizontal ScrollView of UserPresenceItem avatar cards with profile nav accessibility labels"
    - path: "VitaminG/VitaminG/VitaminG/Views/Community/GlowingSpotlightSection.swift"
      role: "Hero card with accentGold border (2pt), GLOWING THIS WEEK allcaps label, serif(20) username, ApplauseButtonView"
    - path: "VitaminG/VitaminG/VitaminG/Views/Community/GlobalFeedSection.swift"
      role: "LazyVStack CommunityPostCard feed with optimistic reactions, CommunityReplySheetView, PostComposeSheet compose CTA"
  modified:
    - path: "VitaminG/VitaminG/VitaminG/ViewModels/CommunityHubViewModel.swift"
      role: "Added toggleReaction, reportPost, writeReply instance methods delegating to CommunityService"
decisions:
  - "GlobalFeedSection uses a local @State CommunityFeedViewModel for PostComposeSheet injection — avoids adding a new parameter to CommunityHubViewModel and matches the established CommunityFeedView pattern"
  - "GlimpsesCarouselSection adds Combine import for Timer.publish — only file in Views/ that requires it"
  - "Font API: .fontDesign(.rounded) is a View modifier, not a Font method — applied as separate modifier after .font()"
  - "GlimpseCard height 200pt (not 180pt) to accommodate ApplauseButtonView and maintain 44pt touch target — trade between spec and HIG"
metrics:
  duration_minutes: 9
  tasks_completed: 2
  tasks_total: 2
  files_created: 4
  files_modified: 1
  tests_passing: 12
  tests_total: 12
  completed_date: "2026-05-23"
---

# Phase 21 Plan 05: Community Section Components Summary

Four Community tab section sub-views built: GlimpsesCarouselSection (5s Timer auto-advance carousel with DragGesture pause), ActiveTodaySection (horizontal avatar strip), GlowingSpotlightSection (gold-ring hero card with serif typography), and GlobalFeedSection (optimistic-reaction LazyVStack feed with CommunityReplySheetView and PostComposeSheet). All 12 Phase21 tests GREEN.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Build GlimpsesCarouselSection + ActiveTodaySection | 874765c | GlimpsesCarouselSection.swift, ActiveTodaySection.swift |
| 2 | Build GlowingSpotlightSection + GlobalFeedSection + ViewModel additions | b4405a9 | GlowingSpotlightSection.swift, GlobalFeedSection.swift, CommunityHubViewModel.swift |

## Verification Results

- Build: BUILD SUCCEEDED (both tasks verified)
- Phase21ApplauseDailyGateTests: 3/3 PASSED
- Phase21CommunityHubViewModelTests: 3/3 PASSED
- Phase21GlowingSelectionTests: 3/3 PASSED
- Phase21ReplyTests: 3/3 PASSED
- Full test suite: All tests PASSED
- `Timer.publish(every: 5` in GlimpsesCarouselSection.swift: 1 match
- `isDragging` in GlimpsesCarouselSection.swift: 5 matches (state decl + onChanged + onEnded + onReceive guard)
- `GLOWING THIS WEEK` in GlowingSpotlightSection.swift: 1 match
- `accentGold` in GlowingSpotlightSection.swift: 2 matches (label + border stroke)
- `LazyVStack` in GlobalFeedSection.swift: 2 matches
- `CommunityReplySheetView` in GlobalFeedSection.swift: 2 matches (sheet + init)
- `showReplySheet` in GlobalFeedSection.swift: 3 matches (state + sheet binding + toggle)
- `Community is quiet right now` in GlobalFeedSection.swift: 1 match

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Font API: `.fontDesign(.rounded)` is a View modifier, not a Font method**
- **Found during:** Task 1 first build
- **Issue:** Plan action spec used `.font(.system(size: N).fontDesign(.rounded))` — `fontDesign` is a `View` modifier, not a property of `Font`. Compiler error: `value of type 'Font' has no member 'fontDesign'`.
- **Fix:** Split into two modifiers: `.font(.system(size: N))` followed by `.fontDesign(.rounded)` — matches pattern used throughout existing codebase (CommunityReplySheetView, ApplauseButtonView, etc.)
- **Files modified:** GlimpsesCarouselSection.swift, ActiveTodaySection.swift (both fixed before second build)

**2. [Rule 3 - Blocking] Missing Combine import for Timer.publish**
- **Found during:** Task 1 first build
- **Issue:** `Timer.publish(every:).autoconnect()` requires Combine. SwiftUI auto-imports do not include Combine's `autoconnect()` on `Timer.TimerPublisher`.
- **Fix:** Added `import Combine` to GlimpsesCarouselSection.swift
- **Files modified:** GlimpsesCarouselSection.swift

## Known Stubs

None. All four sections wire directly to CommunityHubViewModel properties:
- `GlimpsesCarouselSection` — reads `glimpses: [GoalGlimpseItem]` (CloudKit-backed via CommunityService.fetchGlimpses)
- `ActiveTodaySection` — reads `activeUsers: [UserPresenceItem]` (CloudKit-backed via CommunityService.fetchActiveUsers)
- `GlowingSpotlightSection` — reads `glowingUser: GoalGlimpseItem?` (deterministic selection via GlowingSelector)
- `GlobalFeedSection` — reads `feedPosts: [CKRecord]` (CloudKit-backed via CommunityService.fetchGlobalPosts)

## Threat Flags

No new trust boundaries beyond what is declared in the plan's threat model. T-21-05-03 (carousel timer fires while user is interacting) mitigated via `isDragging` guard in `onReceive(timer)`.

## Self-Check: PASSED

Files exist:
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/Community/GlimpsesCarouselSection.swift` — FOUND
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/Community/ActiveTodaySection.swift` — FOUND
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/Community/GlowingSpotlightSection.swift` — FOUND
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/Community/GlobalFeedSection.swift` — FOUND
- `/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/ViewModels/CommunityHubViewModel.swift` — FOUND (modified)

Commits exist:
- 874765c — feat(21-05): add GlimpsesCarouselSection + ActiveTodaySection
- b4405a9 — feat(21-05): add GlowingSpotlightSection, GlobalFeedSection, ViewModel reply/react/report
