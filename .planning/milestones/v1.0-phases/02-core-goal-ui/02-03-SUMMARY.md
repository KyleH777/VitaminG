---
phase: 02-core-goal-ui
plan: "03"
subsystem: goal-sort-ui
tags: [swiftui, swiftdata, tdd, sort, goal-list]
dependency_graph:
  requires: [02-02, 02-01, 01-foundation]
  provides: [GoalSorter, SortOption, sort-toolbar]
  affects: [GoalListView]
tech_stack:
  added: []
  patterns: [TDD-RED-GREEN, SortOption-enum, computed-sort-property, Menu+Picker-toolbar, two-section-list]
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Views/GoalSorter.swift
    - VitaminG/VitaminG/VitaminGTests/GoalSortTests.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/GoalListView.swift
decisions:
  - GoalSorter extracted as a standalone testable struct (not nested in View) — enables unit testing without SwiftUI
  - "@Query has no sort descriptor — dynamic sort via sortedGoals computed property avoids double-sort confusion (Pitfall 2 from RESEARCH.md)"
  - byCompletionStatus uses two flat sections (Active/Completed) rather than per-tier sections — D-08 compliance
  - goalRow helper extracted to eliminate duplication between tier-section and completion-status layout modes
metrics:
  duration_minutes: 15
  completed_date: "2026-04-04"
  tasks_completed: 1
  files_modified: 3
---

# Phase 02 Plan 03: Sort Toolbar + GoalSorter Summary

**One-liner:** Sort toolbar with three modes (byTier/byCreationDate/byCompletionStatus) backed by a standalone GoalSorter struct, with byCompletionStatus rendering Active/Completed two-section layout per D-08.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (TDD RED) | Failing GoalSortTests for all SortOption cases | c9de187 | GoalSortTests.swift |
| 1 (GREEN) | GoalSorter + SortOption + GoalListView sort integration | 0f4f79f | GoalSorter.swift, GoalListView.swift |

## What Was Built

**GoalSorter.swift** — New 55-line file containing:
- `SortOption` enum: `byTier`, `byCreationDate`, `byCompletionStatus`. Conforms to `Hashable` and `CaseIterable`. Each case has `displayName` and `systemImage` properties for toolbar rendering.
- `GoalSorter` struct with `static func sort(_ goals: [Goal], by option: SortOption) -> [Goal]`:
  - `byTier`: sorts by `GoalTier.ordered` index; active before completed within same tier (D-09)
  - `byCreationDate`: ascending by `creationDate` (oldest first)
  - `byCompletionStatus`: active goals tier-sorted first, completed goals appended flat (D-08)

**GoalSortTests.swift** — 84-line TDD test file with 5 test methods, all using in-memory `ModelContainerFactory`:
- `test_sort_byTier_ordersImmediateFirst`
- `test_sort_byTier_activeBeforeCompletedWithinTier`
- `test_sort_byCreationDate_ascendingOrder`
- `test_sort_byCompletionStatus_activeSectionFirst`
- `test_sort_byCompletionStatus_activeGoalsSortedByTier`

**GoalListView.swift** — Updated with:
- `@Query` sort descriptor removed (was `sort: \Goal.creationDate`) — dynamic sort via computed property
- `@State private var sortOption: SortOption = .byTier` — default is tier sort
- `private var sortedGoals: [Goal]` computed property delegating to `GoalSorter.sort`
- `goals(for tier:)` now sources from `sortedGoals` instead of raw `goals`
- `goalList` body split: `byCompletionStatus` renders Active/Completed sections; other modes render `TierSectionView` sections
- `goalRow(for:)` `@ViewBuilder` helper eliminates code duplication between both layout modes
- Sort toolbar: `ToolbarItem(.secondaryAction)` with `Menu { Picker(...) }` showing all 3 SortOption cases
- `.animation(.easeOut(duration: 0.25), value: sortOption)` on list for smooth reorder

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. SortOption is session-only `@State` — resets to `.byTier` on cold launch (T-02-08 accepted). Sort runs on bounded in-memory array (T-02-07 accepted).

## Self-Check

Files created/modified:
- [x] VitaminG/VitaminG/VitaminG/Views/GoalSorter.swift — FOUND (55 lines, contains GoalSorter + SortOption)
- [x] VitaminG/VitaminG/VitaminGTests/GoalSortTests.swift — FOUND (84 lines, 5 test methods, contains test_sort_byTier)
- [x] VitaminG/VitaminG/VitaminG/Views/GoalListView.swift — FOUND (sortOption state, sortedGoals, sort menu)

Commits:
- [x] c9de187 — test(02-03): add failing GoalSortTests for all SortOption cases
- [x] 0f4f79f — feat(02-03): add sort toolbar and GoalSorter with three sort modes

Build: TEST BUILD SUCCEEDED (xcodebuild build-for-testing)

## Self-Check: PASSED
