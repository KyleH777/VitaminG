---
phase: 16-tab-restructuring-approute-updates
plan: "02"
subsystem: navigation
tags:
  - navigation
  - swiftui
  - home
  - stats
  - wins
  - ios
dependency_graph:
  requires:
    - 16-01  # Tab enum + NavigationStack structure with AppTab tags
  provides:
    - Home tab navigationDestination handling AppRoute.stats and AppRoute.wins
    - Tappable Quick Stats row routing to StatsView via AppRoute.stats
    - Daily Wins entry button routing to DailyWinsView via AppRoute.wins
  affects:
    - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
    - VitaminG/VitaminG/VitaminG/Views/HomeView.swift
tech_stack:
  added: []
  patterns:
    - "NavigationLink(value: AppRoute.xxx) with .buttonStyle(.plain) for programmatic NavigationStack routing"
    - "navigationDestination(for: AppRoute.self) on Home tab NavigationStack matching existing tab pattern"
    - "Combined accessibilityElement(children: .ignore) + accessibilityLabel for multi-cell rows"
key_files:
  created: []
  modified:
    - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
    - VitaminG/VitaminG/VitaminG/Views/HomeView.swift
decisions:
  - "dailyWinsEntry placed after checkInCTA conditional block and before quickStatsRow — always visible regardless of check-in state, matching D-03 spec"
  - "Quick Stats NavigationLink uses accessibilityElement(children: .ignore) with combined label so VoiceOver reads a single meaningful summary rather than three separate statCell values"
  - "chevron.right placed as trailing element in outer HStack with 8pt leading padding (padding(.leading, 8)) to separate it from rightmost statCell — matches 16-UI-SPEC.md spacing spec"
metrics:
  duration: "6m 10s"
  completed: "2026-05-17"
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 2
---

# Phase 16 Plan 02: Stats and Daily Wins Home Tab Routing Summary

Home tab NavigationStack wired with AppRoute.stats → StatsView() and AppRoute.wins → DailyWinsView(); quickStatsRow wrapped in NavigationLink with trailing chevron and combined VoiceOver label; dailyWinsEntry "See your wins →" button added to HomeView body; project builds with zero errors.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Wire .stats and .wins navigationDestination on Home tab in ContentView | 72a6798 | ContentView.swift |
| 2 | Add tappable Quick Stats NavigationLink and Daily Wins entry button to HomeView | 20f7e1e | HomeView.swift |

## What Was Built

**ContentView.swift — Home tab navigationDestination:** Added `navigationDestination(for: AppRoute.self)` modifier to the Home tab's `NavigationStack { HomeView() }` block. The switch handles `case .stats: StatsView()`, `case .wins: DailyWinsView()`, and `default: EmptyView()` as catch-all, matching the pattern used by other tab destination switches. The `goalsTab` computed property continues to not handle `.stats` or `.wins` (removed by Plan 01, no regression here).

**HomeView.swift — quickStatsRow as NavigationLink:** The existing 3-cell HStack (Active Goals / Check-ins / Badges) is now wrapped in `NavigationLink(value: AppRoute.stats)` with `.buttonStyle(.plain)`. A trailing `chevron.right` SF Symbol (12pt semibold, `VGTheme.textMuted` foreground, 8pt leading padding) signals navigability. Accessibility: `.accessibilityElement(children: .ignore)` collapses the three cells into a single VoiceOver element; `.accessibilityLabel` delivers a combined summary using the same computed values rendered in the cells; `.accessibilityHint("Opens your full statistics")`; chevron is `.accessibilityHidden(true)`. Padding (`.horizontal, 24` and `.top, 16`) preserved from prior layout.

**HomeView.swift — dailyWinsEntry computed property:** New `private var dailyWinsEntry: some View` returns a `NavigationLink(value: AppRoute.wins)` with a terra-gradient full-width button labeled "See your wins →". Styled to match `checkInCTA` exactly: `.system(size: 16, weight: .semibold)` white foreground, `LinearGradient([VGTheme.accentTerra, VGTheme.terra], leading → trailing)` background, 14pt corner radius, 16pt vertical padding, 24pt horizontal screen margin. `.accessibilityLabel("Daily Wins")` excludes the "→" arrow from VoiceOver. `.accessibilityHint("Opens your gratitude and daily wins log")`. `.buttonStyle(.plain)` prevents default link tint override.

**HomeView.swift — body placement:** `dailyWinsEntry.padding(.top, 12)` inserted after the `checkInCTA` conditional block and before `quickStatsRow` in the ScrollView VStack. Always visible — not gated on `primaryGoal` or `todayCheckedIn`.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All NavigationLinks route to existing, fully-implemented views (StatsView, DailyWinsView) with no required init arguments.

## Threat Surface Scan

No new security-relevant surface introduced beyond what the plan's threat model covers:
- T-16-05 (stale Goals-tab routes): Mitigated — `.stats` and `.wins` now live exclusively on the Home tab navigationDestination. Any code that previously pushed these onto the Goals tab path falls through to `default: EmptyView()` — graceful degradation.
- T-16-06 (crash on tap): Mitigated — Both NavigationLinks push existing zero-arg views; `default: EmptyView()` catch-all prevents unhandled route crashes.
- T-16-07 (VoiceOver discloses user counts): Accepted — same data already visible on screen; accessibilityLabel makes visible info available to VoiceOver users, no new data surface.
- No new @Query, @State, network endpoints, auth paths, or file access patterns introduced.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| ContentView.swift modified | FOUND |
| HomeView.swift modified | FOUND |
| ContentView contains `case .stats: StatsView()` (count=1) | PASSED |
| ContentView contains `case .wins: DailyWinsView()` (count=1) | PASSED |
| goalsTab does NOT contain .stats or .wins | PASSED |
| HomeView contains `NavigationLink(value: AppRoute.stats)` | PASSED |
| HomeView contains `NavigationLink(value: AppRoute.wins)` | PASSED |
| HomeView contains `See your wins →` | PASSED |
| HomeView contains `chevron.right` | PASSED |
| HomeView declares `private var dailyWinsEntry` | PASSED |
| HomeView contains `accessibilityLabel("Stats:` combined label | PASSED |
| HomeView contains `accessibilityLabel("Daily Wins")` | PASSED |
| HomeView contains both accessibilityHints | PASSED |
| dailyWinsEntry referenced in body (2+ occurrences) | PASSED |
| checkInCTA still pushes GoalDetailView | PASSED |
| Task 1 commit 72a6798 exists | FOUND |
| Task 2 commit 20f7e1e exists | FOUND |
| Build succeeds (no compile errors) | PASSED |
