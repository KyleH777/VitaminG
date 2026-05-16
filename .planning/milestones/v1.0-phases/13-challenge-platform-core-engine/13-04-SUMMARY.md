---
phase: 13-challenge-platform-core-engine
plan: "04"
subsystem: ui-discovery
tags: [swiftui, challenges-tab, discovery-view, streak-chain, navigation]
dependency_graph:
  requires: [13-01, 13-02, 13-03]
  provides: [ChallengeDiscoveryView, StreakChainView, ContentView-5th-tab, challengeDetail-route-wired]
  affects: [ContentView]
tech_stack:
  added: []
  patterns: [horizontal-scroll-dot-chain, query-viewmodel-split, navigationlink-value-route]
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Views/Components/StreakChainView.swift
    - VitaminG/VitaminG/VitaminG/Views/ChallengeDiscoveryView.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
decisions:
  - StreakChainView uses ZStack per day-dot to layer filled circle + today-stroke overlay — cleaner than conditional strokeBorder only
  - ChallengeCardView is private struct within ChallengeDiscoveryView.swift (not a separate file) — used only here, avoids file proliferation
  - communitySize guard uses non-optional Int > 0 check (matches SchemaV4 property with default 0)
  - ChallengeDetailView route wired in ContentView even though ChallengeDetailView is created in Plan 05 — parallel wave execution means both land before merge
metrics:
  completed_date: "2026-05-06"
  tasks_completed: 2
  files_modified: 3
requirements: [CHAL-08, CHAL-11]
---

# Phase 13 Plan 04: Challenges Tab UI — ChallengeDiscoveryView + StreakChainView Summary

**One-liner:** 5th Challenges tab wired to ChallengeDiscoveryView with featured cards, category browse, and Build Your Own CTA; StreakChainView delivers 30-day dot chain component with filled/outlined states and aggregate VoiceOver label.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Create StreakChainView component | [see commit] | Views/Components/StreakChainView.swift (created) |
| 2 | Create ChallengeDiscoveryView + add 5th Challenges tab | [see commit] | Views/ChallengeDiscoveryView.swift (created), Views/ContentView.swift (modified) |

## Must-Haves Satisfied

- StreakChainView: 30 day-dot circles (20pt diameter, 4pt HStack spacing) in horizontal ScrollView
- StreakChainView: filled (accentColor) for checked-in days, strokeBorder (accentColor.opacity 0.25) for missed
- StreakChainView: today's circle gets additional 2pt full-accent stroke overlay via ZStack
- StreakChainView: aggregate `.accessibilityLabel("Streak chain: N check-ins in the last 30 days")` on ScrollView
- StreakChainView: individual dots `.accessibilityHidden(true)`
- StreakChainView: "Your Streak" section label, `.title2.semibold.rounded`
- StreakChainView: no SwiftData import, no modelContext — pure display component
- ChallengeDiscoveryView: "Featured Challenges" + "Browse by Category" + "Build Your Own" sections
- ChallengeDiscoveryView: `.onAppear { viewModel.seedFeaturedTemplates(context: modelContext) }`
- ChallengeDiscoveryView: `NavigationLink(value: AppRoute.challengeDetail(challenge))` for View Progress
- ChallengeDiscoveryView: empty state with "No Challenges Yet" heading and descriptive body
- ChallengeDiscoveryView: Build Your Own sheet shows coming-soon placeholder with "Got It" dismiss
- ContentView: 5 tabs total — Goals · Stats · Wins · Challenges · Profile (grep returns 5)
- ContentView: Challenges tab at slot 4 (before Profile) with `Label("Challenges", systemImage: "flame.fill")`
- ContentView: `.challengeDetail(let challenge)` route wired to `ChallengeDetailView(userChallenge: challenge)` (EmptyView stub replaced)

## Deviations from Plan

**1. [Rule 1 - Bug] Fixed communitySize optional binding**
- **Found during:** Task 2 implementation
- **Issue:** Plan code template used `if let size = template.communitySize, size > 0` — but SchemaV4.communitySize is `Int = 0` (non-optional with default). Optional binding on a non-optional property is a compile error.
- **Fix:** Changed to `if template.communitySize > 0 { Text("\(template.communitySize.formatted()) people") }`
- **Files modified:** ChallengeDiscoveryView.swift
- **Impact:** None — functionally identical behavior, correct Swift for non-optional Int

## Known Stubs

- `ChallengeDetailView` is referenced in ContentView.swift but created in Plan 05 (Wave 3 parallel). The reference compiles only after Plan 05 lands. This is intentional parallel-execution behavior — both plans merge before verification.
- "Build Your Own" sheet shows a coming-soon placeholder per UI-SPEC.md Interaction Contract — deferred to Phase 14.

## Threat Flags

None — all threat register entries for this plan accepted per plan spec:
- T-13-16: Color(hex:) handles malformed accentColorHex strings with fallback
- T-13-17: ChallengeTemplate data is on-device only; no user PII in template fields

## Self-Check: PASSED

- StreakChainView.swift exists with struct StreakChainView: FOUND
- ChallengeDiscoveryView.swift exists with struct ChallengeDiscoveryView: FOUND
- ContentView.swift has flame.fill and 5 tabItem entries: FOUND
- ContentView.swift has ChallengeDetailView(userChallenge: challenge): FOUND
- Challenges tab appears before Profile tab in file (lines 32-38 vs 40-46): CONFIRMED
