---
phase: 16-tab-restructuring-approute-updates
plan: "01"
subsystem: navigation
tags:
  - navigation
  - swiftui
  - tab-bar
  - ios
  - tab-enum
dependency_graph:
  requires: []
  provides:
    - Tab enum (Navigation/Tab.swift) with string raw values for deep link stability
    - ExplorePlaceholderView for Phase 20
    - CommunityPlaceholderView for Phase 21
    - Tab-typed selectedTab binding across ContentView/VGTabBar/CommunityTabView
  affects:
    - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
    - VitaminG/VitaminG/VitaminG/Views/Components/VGTabBar.swift
    - VitaminG/VitaminG/VitaminG/Views/CommunityTabView.swift
    - VitaminG/VitaminG/VitaminG/Navigation/Tab.swift
    - VitaminG/VitaminG/VitaminG/Views/Placeholders/ExplorePlaceholderView.swift
    - VitaminG/VitaminG/VitaminG/Views/Placeholders/CommunityPlaceholderView.swift
    - VitaminG/VitaminG/VitaminG.xcodeproj/project.pbxproj
tech_stack:
  added:
    - "Tab enum: String raw values, CaseIterable, Hashable — pure Foundation model type"
  patterns:
    - "Tab.allCases zipped with tabs array for ForEach in VGTabBar — preserves 1:1 ordering without index arithmetic"
    - "NavigationStack { PlaceholderView() }.tag(Tab.xxx) for unimplemented tab slots"
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Navigation/Tab.swift
    - VitaminG/VitaminG/VitaminG/Views/Placeholders/ExplorePlaceholderView.swift
    - VitaminG/VitaminG/VitaminG/Views/Placeholders/CommunityPlaceholderView.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
    - VitaminG/VitaminG/VitaminG/Views/Components/VGTabBar.swift
    - VitaminG/VitaminG/VitaminG/Views/CommunityTabView.swift
    - VitaminG/VitaminG/VitaminG.xcodeproj/project.pbxproj
decisions:
  - "Tab enum uses String raw values (not Int) so widget intent and deep link tab parameters remain stable across index reorders (D-06, TAB-04)"
  - "ForEach in VGTabBar uses zip(Tab.allCases, tabs) rather than enumeration — eliminates Int offset and keeps selection comparison type-safe"
  - "Explore and Community slots in ContentView use static placeholder views; v1.0 ChallengeDiscoveryView and CommunityTabView wiring removed from ContentView (they will be replaced in Phases 20 and 21)"
  - "CommunityTabView file retained on disk (not deleted) — only its ContentView wiring is removed; the file's view declaration may be referenced or adapted in Phase 21"
metrics:
  duration: "31m 10s"
  completed: "2026-05-17"
  tasks_completed: 2
  tasks_total: 2
  files_created: 3
  files_modified: 4
---

# Phase 16 Plan 01: Tab Enum + Navigation Restructure Summary

Tab enum with String raw values (home/goals/explore/community/profile) and full migration of selectedTab binding from Int to Tab across ContentView, VGTabBar, and CommunityTabView; Community and Explore tab positions swapped; static placeholder views added for Phase 20 and Phase 21 slots; project builds with zero errors.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create Tab enum and Explore/Community placeholder views | 4f8ec84 | Tab.swift, ExplorePlaceholderView.swift, CommunityPlaceholderView.swift, project.pbxproj |
| 2 | Migrate ContentView, VGTabBar, CommunityTabView to Tab enum | b661439 | ContentView.swift, VGTabBar.swift, CommunityTabView.swift |

## What Was Built

**Tab enum (Navigation/Tab.swift):** Pure Foundation model type (`enum Tab: String, CaseIterable, Hashable`) with five string-raw-value cases in v2.0 display order: `.home`, `.goals`, `.explore`, `.community`, `.profile`. No SwiftUI import — model layer only. Satisfies TAB-04 and D-06/D-07.

**ExplorePlaceholderView (Views/Placeholders/ExplorePlaceholderView.swift):** Static "Coming soon" / "Something exciting is brewing." view using `VGTheme.serif(28)` heading and `.system(size: 16)` body, centered on `VGTheme.heroBackground`. No user data, no interaction. Phase 16 placeholder until Phase 20.

**CommunityPlaceholderView (Views/Placeholders/CommunityPlaceholderView.swift):** Same structure, body line "Your community is on its way." Phase 16 placeholder until Phase 21.

**ContentView.swift:** `@State private var selectedTab: Tab = .home`; tab slots reordered (Explore at position 3, Community at position 4) with `.tag(Tab.xxx)` enum tags; Explore slot wired to `ExplorePlaceholderView()`, Community slot wired to `CommunityPlaceholderView()`; `.stats` and `.wins` removed from `goalsTab.navigationDestination`; `challengesNavPath` state and old ChallengeDiscoveryView wiring removed.

**VGTabBar.swift:** `@Binding var selection: Tab`; `tabs` array updated to `[("Home","house"), ("Goals","circle.circle"), ("Explore","magnifyingglass"), ("Community","person.2"), ("Profile","person")]`; `ForEach` uses `zip(Tab.allCases, tabs)` for type-safe iteration; `tabItem` function takes `Tab` parameter; selection comparison and button action use `Tab` values.

**CommunityTabView.swift:** `@Binding var selectedTab: Tab`; `selectedTab = .explore` replaces hard-coded `selectedTab = 3`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] SchemaV8.swift missing from VitaminGWidgetExtension Sources build phase**

- **Found during:** Task 1 build verification
- **Issue:** `VitaminGMigrationPlan.swift` references `SchemaV8.self` and `Schema8pV2.swift` has `typealias UserProfile = SchemaV8.UserProfile`, but `SchemaV8.swift` was not listed in the `VitaminGWidgetExtension` target's manually-specified Sources build phase in `project.pbxproj`. The main `VitaminG` target uses `PBXFileSystemSynchronizedRootGroup` (auto-includes all files), but the widget extension target uses an explicit file list that omitted SchemaV8.swift when it was added in Phase 15. Under Xcode 26.5, this caused a "cannot find 'SchemaV8' in scope" compile error that blocked all builds.
- **Fix:** Added `PBXBuildFile` (`AA01000000000028`) and `PBXFileReference` (`AA01000000000029`) entries for SchemaV8.swift to `project.pbxproj`, and added the build file reference to the widget extension's `AA010000000000015` Sources build phase. Also added to the Recovered References group.
- **Files modified:** `VitaminG/VitaminG/VitaminG.xcodeproj/project.pbxproj`
- **Commit:** 4f8ec84

**2. [Rule 1 - Bug] contentView `goalsTab` switch became non-exhaustive after .stats and .wins removal**

- **Found during:** Task 2 code review
- **Issue:** After removing `case .stats: StatsView()` and `case .wins: DailyWinsView()` from `goalsTab.navigationDestination`, the switch over `AppRoute` was no longer exhaustive. Some cases (`publicProfile`, `challengeDetail`, `challengeCheckIn`, `communityFeed`, `communityGoals`, `settings`, `profile`, `goalDetail`) remained but implicit exhaustiveness required listing all cases or adding a `default` catch-all.
- **Fix:** Added `default: EmptyView()` as the final case in the `goalsTab` switch, matching the catch-all pattern used in other non-goals tab NavigationStack blocks throughout the codebase.
- **Files modified:** `VitaminG/VitaminG/VitaminG/Views/ContentView.swift`
- **Commit:** b661439

**3. [Rule 3 - Blocker] Files initially written to main repo instead of worktree**

- **Found during:** Task 1 file creation
- **Issue:** The first Write tool calls used absolute paths resolved from the main repository (`/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/...`) instead of the worktree path (`/Users/kyleharrington/Desktop/AI/Vitamin G/.claude/worktrees/agent-a887eaae7a6e6bbe9/VitaminG/...`). Files were silently written to the main repo as untracked files.
- **Fix:** Removed the incorrectly placed files from the main repo (they were untracked), then re-created them at the correct worktree-relative absolute paths derived from `git rev-parse --show-toplevel`.
- **Files affected:** No lingering impact — corrected before first commit.

## Known Stubs

None. The placeholder views are intentional temporary stubs documented in the plan (Phases 20 and 21 replace them). They display only static copy and no data flows through them.

## Threat Surface Scan

No new security-relevant surface introduced beyond what the plan's threat model covers:
- T-16-01 (Tab enum protects against stale Int deep link routing): Tab enum created per plan.
- T-16-02 (placeholder views prevent crashes): Both placeholder views are non-crashing static SwiftUI views.
- T-16-03 (placeholder views do not leak state): Confirmed — no user data, no @Query, no environment values read.
- T-16-SC (no new package installs): Confirmed — only Foundation and SwiftUI (first-party).

## Self-Check: PASSED

| Item | Status |
|------|--------|
| Tab.swift exists | FOUND |
| ExplorePlaceholderView.swift exists | FOUND |
| CommunityPlaceholderView.swift exists | FOUND |
| Task 1 commit 4f8ec84 exists | FOUND |
| Task 2 commit b661439 exists | FOUND |
| Build succeeds (no compile errors) | PASSED |
