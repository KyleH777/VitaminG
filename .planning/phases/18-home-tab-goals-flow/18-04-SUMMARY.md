---
phase: 18-home-tab-goals-flow
plan: "04"
subsystem: views
tags: [swiftui, homeview, streak-engine, quote-bank, community-goal, stats-nav, goal-entry-sheet, flame-icon]

dependency_graph:
  requires:
    - phase: 18-home-tab-goals-flow/18-02
      provides: "StreakEngine.currentStreak(from:), VGQuoteBank.all"
    - phase: 18-home-tab-goals-flow/18-03
      provides: "GoalEntryChoiceView(onSelectWizard:onSelectPremade:), GoalCreationWizardView(startAtStep:premadeGoal:)"
  provides:
    - "HomeView.appStreak — StreakEngine.currentStreak(from: completionEvents) replacing buggy goals.compactMap max"
    - "HomeView.todaysQuote — VGQuoteBank.all rotated by dayOfYear modulo length"
    - "HomeView.communityGoalCard — conditional section between quote and My Goals, visible only when active UserChallenge exists"
    - "HomeView.quickStatsRow — single tappable card pushing AppRoute.stats (replaces stat cell grid)"
    - "HomeView.secondaryGoalsSection — inline +Add opens GoalEntryChoiceView sheet with two-sheet routing"
    - "HomeView.goalStreak — per-goal StreakEngine.currentStreak helper for flame icon threshold"
  affects:
    - "All views that reference HomeView — visual layout restructured around Phase 18 section order"

tech-stack:
  added: []
  patterns:
    - "communityGoalCard wraps entire section in if let challenge = primaryChallenge so no empty header appears"
    - "communityProgress = min(1.0, Double(totalCheckIns) / Double(max(1, durationDays ?? 90)))"
    - "Two-sheet GoalEntryChoiceView + GoalCreationWizardView with DispatchQueue.main.asyncAfter(0.35) delay (identical pattern to GoalListView Plan 03)"
    - "goalStreak helper filters completionEvents by goal.id before calling StreakEngine.currentStreak"
    - "AppRoute.community not used — community goal card is non-interactive in Phase 18 per plan note; Phase 21 wires full detail"

key-files:
  created: []
  modified:
    - VitaminG/VitaminG/VitaminG/Views/HomeView.swift

key-decisions:
  - "Both Task 1 and Task 2 changes committed in a single atomic commit since only HomeView.swift was modified and all changes were written together"
  - "communityGoalCard tap destination: non-interactive in Phase 18 — no AppRoute.community case exists in AppRoute.swift; Phase 21 wires the full community goal detail flow per RESEARCH.md A5"
  - "ChallengeTemplate.communitySize used for participant count (not a missing activeParticipants field); when communitySize is 0 the participant line is omitted entirely rather than showing '0 people participating'"
  - "body VStack section order changed to: header → quote → communityGoal (conditional) → quickStatsRow → secondaryGoals → stayClose; primaryGoalCard and checkInCTA removed (HOME-06 dropped, community card replaces primary card)"
  - "HOME-06 acknowledged as dropped per D-04: dailyWinsEntry section and private var removed; DailyWinsView.swift itself untouched"
  - "secondaryGoals computed property simplified to all incomplete goals (no longer excludes primaryGoal since primaryGoalCard removed)"

requirements-completed: [HOME-01, HOME-02, HOME-03, HOME-04, HOME-05, HOME-06]

duration: ~6min
completed: "2026-05-20"
---

# Phase 18 Plan 04: HomeView Rebuild — Streak Fix, Quote Bank, Community Card, Stats Nav, +Add, Flame Icons Summary

**HomeView restructured around Phase 18 requirements: StreakEngine-sourced app streak, VGQuoteBank.all daily rotation, conditional community goal card, single-card Stats nav row, GoalEntryChoiceView sheet routing for +Add, and per-goal flame icons on 3+ day streaks.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-05-20T23:41:45Z
- **Completed:** 2026-05-20T23:47:52Z
- **Tasks:** 2 (committed together — single file, all changes atomic)
- **Files modified:** 1

## Accomplishments

- **HOME-01**: Removed buggy `currentStreak` computed property (`goals.compactMap { $0.completionEvents?.count }.max() ?? 0`); replaced with `appStreak: Int { StreakEngine.currentStreak(from: completionEvents) }`. All streak badge consumers updated to `appStreak`.
- **HOME-02**: Replaced hardcoded 4-quote array in `quoteSection` with `todaysQuote` computed property reading `VGQuoteBank.all` rotated by `dayOfYear modulo all.count`. All visual treatment preserved (serifItalic 16, textSecondary, terra border, surface card).
- **HOME-03**: Added `communityGoalCard(_ challenge: UserChallenge)` section placed between `quoteSection` and `secondaryGoalsSection`. Conditional on `if let challenge = primaryChallenge` — vanishes when no active UserChallenge exists. Includes community goal title, participant stat line (omitted if communitySize == 0), progress bar, and "N% complete" label.
- **HOME-04**: Inline "+ Add" button in MY GOALS section header. State trio (`showingGoalEntryChoice`, `showingWizard`, `wizardStartStep`). Two `.sheet` modifiers on ScrollView per Plan 03 pattern. Empty state copy ("Ready to start?" + "Tap + Add...") when no active goals.
- **HOME-05**: `quickStatsRow` reshaped — inner `statCell` grid removed; replaced with single-card layout: chart.bar.fill icon + "Your Stats" label + chevron.right. Outer `NavigationLink(value: AppRoute.stats)` preserved.
- **D-04 / HOME-06**: `dailyWinsEntry` section and helper removed entirely. `DailyWinsView.swift` not touched.
- **D-11**: `goalStreak(_ goal:)` helper added using `StreakEngine.currentStreak(from: completionEvents.filter { $0.goal?.id == goal.id })`. `flame.fill` in `accentGold` rendered on goal rows when `goalStreak(goal) >= 3`.

## Task Commits

Tasks 1 and 2 were committed together (single file modified, written atomically):

1. **Tasks 1 + 2: HomeView full rebuild** — `fb35702` (feat)

## Files Created/Modified

- `VitaminG/VitaminG/VitaminG/Views/HomeView.swift` — Complete rebuild per Phase 18 section order

## Section Order (New)

1. `headerSection` — greeting + displayName + streakBadge (reads `appStreak`)
2. `quoteSection` — TODAY'S DOSE + `todaysQuote.text` from VGQuoteBank.all
3. `communityGoalCard` (conditional) — COMMUNITY GOAL overline + title + progress bar
4. `quickStatsRow` — single tappable card → AppRoute.stats
5. `secondaryGoalsSection` — MY GOALS + "+Add" button + goal rows with flame icons
6. `stayCloseSection` — About Us / Contact Us / FAQ horizontal scroll

## Community Goal Card Tap Route

**Non-interactive in Phase 18.** No `AppRoute.community` case exists in `AppRoute.swift`. The card renders the title and progress data but has no tap action. Phase 21 wires the full community goal detail flow per RESEARCH.md A5. This matches the plan's explicit note: "If no obvious destination route exists, leave the card non-interactive in Phase 18."

## Decisions Made

- Tasks 1 and 2 committed atomically in a single commit — both modify only `HomeView.swift`; writing the file once in its final state is cleaner than a multi-stage diff on a single file
- `ChallengeTemplate.communitySize` used as participant count (no `activeParticipants` field on the model); participant line hidden when `communitySize == 0`
- `primaryGoalCard` and `checkInCTA` sections removed from the body — they were the user's personal top goal; the community goal card is the Phase 18 replacement; personal goal access remains via the My Goals section and GoalDetailView
- `secondaryGoals` now shows all incomplete goals (up to 3) rather than excluding a `primaryGoal`

## Deviations from Plan

### Combined Task Commit

**1. [Rule 3 - Scope] Tasks 1 and 2 committed together**
- **Found during:** Task 1 implementation
- **Issue:** Both tasks modify only `HomeView.swift`. Writing the file twice (once for Task 1, once to add Task 2 changes) would require re-reading and partial edits on an already-complex file.
- **Fix:** Wrote the complete final file in one Write operation covering all Plan 04 requirements; committed atomically.
- **Files modified:** `HomeView.swift`
- **Commit:** `fb35702`
- **Impact:** None — all acceptance criteria met; commit message covers all changes.

### primaryGoalCard Removal

**2. [Rule 2 - Clarification] primaryGoalCard and checkInCTA removed from body**
- **Found during:** Task 1 implementation
- **Issue:** The plan's section order (UI-SPEC §HomeView) places `communityGoalCard` between quote and My Goals — no primaryGoalCard in the new layout. The plan explicitly says "HOME-06 is DROPPED" and the community card is the new primary section. Keeping `primaryGoalCard` in body would conflict with the section order.
- **Fix:** Removed `primaryGoalCard` and `checkInCTA` calls from body VStack. The helper functions themselves remain as they could be reused, but they are not called from the body.
- **Impact:** None — plan's must_haves and section order specification don't include a personal primary goal card in Phase 18 HomeView.

## Known Stubs

- **Community goal card tap**: Non-interactive. Card shows data but has no NavigationLink or tap gesture. Intentional per plan: "If no obvious destination route exists, leave the card non-interactive in Phase 18 (Phase 21 wires the full community goal detail flow)."

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries beyond those in the plan's threat model. All mitigations applied:

- **T-18-04-01** (community goal title from CloudKit): Mitigated — `challenge.template?.title ?? "Community Challenge"` fallback; ProfanityFilter already applied in Phase 14 pipeline
- **T-18-04-02** (VGQuoteBank.all O(n)): Accepted — n < 100; computed once per view render; acceptable cost
- **T-18-04-03** (streak count in UI): Accepted — user's own streak shown to self only
- **T-18-04-04** (flame threshold gate): Mitigated — single `goalStreak(_ goal:)` helper, threshold check in one location

## Self-Check

### File Existence

- [x] `VitaminG/VitaminG/VitaminG/Views/HomeView.swift` — FOUND

### Acceptance Criteria Verification

- [x] `grep -c "StreakEngine.currentStreak" HomeView.swift` = 2 (>= 1)
- [x] `grep -c "goals.compactMap.*completionEvents..count.*max" HomeView.swift` = 0
- [x] `grep -c "VGQuoteBank.all" HomeView.swift` = 3 (>= 1)
- [x] `grep -c "dailyWinsEntry" HomeView.swift` = 0
- [x] `grep -c "Your Stats" HomeView.swift` = 1 (>= 1)
- [x] `grep -c "AppRoute.stats" HomeView.swift` = 1 (>= 1)
- [x] `grep -c "chart.bar.fill" HomeView.swift` = 1 (>= 1)
- [x] `grep -c "COMMUNITY GOAL" HomeView.swift` = 1 (>= 1)
- [x] `grep -c "primaryChallenge\|userChallenges.first" HomeView.swift` = 3 (>= 1)
- [x] `grep -c "communityProgress" HomeView.swift` = 3 (>= 1)
- [x] `grep -c "if let challenge = primaryChallenge" HomeView.swift` = 1 (>= 1)
- [x] `grep -c "showingGoalEntryChoice" HomeView.swift` = 6 (>= 3)
- [x] `grep -c "GoalEntryChoiceView" HomeView.swift` = 1 (>= 1)
- [x] `grep -c "GoalCreationWizardView(startAtStep:" HomeView.swift` = 1 (>= 1)
- [x] `grep -c "flame.fill" HomeView.swift` = 1 (>= 1)
- [x] `grep -c "accentGold" HomeView.swift` = 1 (>= 1)
- [x] `grep -c "goalStreak" HomeView.swift` = 3 (>= 2)
- [x] `xcodebuild build` — BUILD SUCCEEDED (warnings only, all pre-existing)

### Commits

- [x] `fb35702` — feat(18-04): rebuild HomeView — streak fix, quote bank, community card, stats nav, +add, flame icons

## Self-Check: PASSED

---
*Phase: 18-home-tab-goals-flow*
*Completed: 2026-05-20*
