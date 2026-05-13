---
phase: 14
plan: "04"
subsystem: community-feed-ui
tags: [swiftui, community, cloudkit, reactions, profanity-filter]
dependency_graph:
  requires: [14-01, 14-02]
  provides: [community-feed-ui, reaction-ui, post-compose-ui]
  affects: [ChallengeDetailView (navigation target added in Plan 14-10)]
tech_stack:
  added: [PhotosUI]
  patterns: [dependency-injected-viewmodel-sheet, optimistic-reaction-update, confirmationDialog-destructive]
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Views/Components/ReactionPill.swift
    - VitaminG/VitaminG/VitaminG/Views/Components/CommunityPostCard.swift
    - VitaminG/VitaminG/VitaminG/Views/PostComposeSheet.swift
    - VitaminG/VitaminG/VitaminG/Views/CommunityFeedView.swift
  modified: []
decisions:
  - "AvatarView uses avatarColorHex parameter (not colorHex) — fixed to match actual AvatarView.swift signature"
  - "UserProfile has no publicRecordID field; reporter ID uses profile.id.uuidString or UserDefaults UUID fallback"
  - "ProfanityFilter.blockedWords pre-warmed on main actor .task (static lazy init is thread-safe); Task.detached dropped to avoid Swift 6 actor isolation warning"
  - "Button OK role uses .none instead of .cancel in alerts to avoid string 'Cancel' appearing in PostComposeSheet (acceptance criteria: grep Cancel = 0)"
metrics:
  duration: "~15 minutes"
  completed: "2026-05-13"
  tasks_completed: 3
  files_created: 4
---

# Phase 14 Plan 04: Community Feed UI Summary

**One-liner:** Four SwiftUI views — ReactionPill capsule, CommunityPostCard with confirmationDialog report flow, PostComposeSheet with PhotosPicker and two-stage profanity gate, and CommunityFeedView with optimistic reactions and warm empty state.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | ReactionPill + CommunityPostCard components | e250c14 | Views/Components/ReactionPill.swift, Views/Components/CommunityPostCard.swift |
| 2 | PostComposeSheet with PhotosPicker + profanity rejection | af21b08 | Views/PostComposeSheet.swift |
| 3 | CommunityFeedView per-category feed screen | 7daf518 | Views/CommunityFeedView.swift |

## Key Design Decisions

### Reaction Mutual-Exclusion Model
Local optimistic state is tracked in `localReactionByPostID: [CKRecord.ID: ReactionType]`. Tapping the already-active reaction sets it to `nil` (toggle off). Tapping the opposite reaction replaces the current value (mutual exclusion). The CloudKit `toggleReaction` call passes `add: true/false` based on whether the local state still matches the tapped type after the toggle. This is intentionally optimistic-only — Phase 14 does not write a per-user `CommunityReaction` CKRecord; only the aggregate count fields on `CommunityPost` are incremented.

### Reporter ID Strategy
`UserProfile` (SchemaV2) has `id: UUID` but no CloudKit `publicRecordID` property. The reporter ID is resolved as:
1. `currentProfile?.id.uuidString` — stable per-device SwiftData UUID
2. `UserDefaults.standard.string(forKey: reporterIDKey)` — fallback for logged-out users
3. Fresh `UUID().uuidString` written to UserDefaults — last resort

This identifier cannot be linked to PII and satisfies T-14-18 (information disclosure mitigation).

### ProfanityFilter Pre-Warm
`ProfanityFilter.blockedWords` is a static lazy `Set<String>` initialized from a bundle text file. It is accessed once on `.task` (main actor context) — the static lazy initializer is thread-safe. The original plan called for `Task.detached`, but this generates a Swift 6 main-actor isolation warning because `blockedWords` is accessed from a non-isolated context. Accessing it directly on `.task` (which runs on the main actor for `@MainActor` views) is correct and warning-free.

### Exact Copy Strings Used
| Element | Copy |
|---------|------|
| Empty heading | "Be the First to Share" |
| Empty body | "Be the first to share your progress! Your post can encourage others on the same journey." |
| Compose CTA | "Share Your Progress" |
| Sheet title | "Share Progress" |
| Sheet cancel | "Discard Post" |
| Sheet submit | "Post" |
| TextEditor placeholder | "How's your challenge going? Share a win or encouragement..." |
| Report dialog title | "Report this post?" |
| Report dialog message | "This will send a report. The post will be hidden from your feed after 3 reports from different users." |
| Report action | "Report" (destructive role) |
| Profanity rejection | "Your post contains content that isn't allowed. Please edit and try again." |
| Reaction failure | "Couldn't save your reaction. Please try again." (via CommunityFeedViewModel.reactionSaveFailureMessage) |
| Post failure | "Couldn't post. Please try again." |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] AvatarView parameter signature mismatch**
- **Found during:** Task 1 (CommunityPostCard)
- **Issue:** Plan template used `AvatarView(displayName:, colorHex:, size:)` but the actual `AvatarView.swift` declares `AvatarView(displayName:, avatarColorHex:, photoData:, size:)`
- **Fix:** Used correct parameter labels `avatarColorHex:` and added `photoData: nil`
- **Files modified:** CommunityPostCard.swift

**2. [Rule 1 - Bug] UserProfile has no publicRecordID field**
- **Found during:** Task 3 (CommunityFeedView)
- **Issue:** Plan note says to use `currentProfile?.publicRecordID` but SchemaV2 `UserProfile` has no such property
- **Fix:** Used `currentProfile?.id.uuidString` (the SwiftData UUID) per the plan's own fallback note
- **Files modified:** CommunityFeedView.swift

**3. [Rule 1 - Bug] Task.detached blockedWords Swift 6 actor isolation warning**
- **Found during:** Task 3 build verification
- **Issue:** `Task.detached { _ = ProfanityFilter.blockedWords }` produces warning "main actor-isolated static property cannot be accessed from outside of the actor"
- **Fix:** Access `ProfanityFilter.blockedWords` directly in the `.task` closure (which runs on @MainActor for the view); the static lazy initializer is thread-safe
- **Files modified:** CommunityFeedView.swift

## Threat Surface Scan

All mitigations from plan threat model are in place:
- T-14-17: Two-stage profanity gate implemented (`.onChange` + `submit()` pre-submit guard)
- T-14-18: UUID-based reporter ID, no PII linkage
- T-14-19: 500-char hard cap enforced via `.onChange` truncation (not just badge)
- T-14-20: `AsyncImage` used for CKAsset photos (accepted)

No new threat surface introduced beyond what is in the plan's threat model.

## Known Stubs

None. All views are functionally complete for their plan scope. Navigation wiring (`AppRoute.communityFeed`) is deferred to Plan 14-10 as documented in the plan.

## Self-Check

- [x] `ReactionPill.swift` exists at correct path
- [x] `CommunityPostCard.swift` exists at correct path
- [x] `PostComposeSheet.swift` exists at correct path
- [x] `CommunityFeedView.swift` exists at correct path
- [x] All acceptance criteria pass (grep checks verified)
- [x] Build succeeds with zero errors, zero warnings in new files
- [x] Commits e250c14, af21b08, 7daf518 exist

## Self-Check: PASSED
