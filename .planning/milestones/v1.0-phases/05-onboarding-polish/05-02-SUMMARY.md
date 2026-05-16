---
phase: 05-onboarding-polish
plan: "02"
subsystem: GoalListView / Empty States
tags: [empty-state, ui, onboarding, swift, swiftui]
one_liner: "Per-tier empty states in GoalListView with warm D-07 copy, tier icon, and pre-selected tier add button"

dependency_graph:
  requires: ["05-01"]
  provides: ["per-tier-empty-states"]
  affects: ["GoalListView", "EmptyTierView"]

tech_stack:
  added: []
  patterns:
    - "EmptyTierView: self-contained View accepting tier enum + onAdd closure"
    - "PBXFileSystemSynchronizedRootGroup: new files in Views/Components/ auto-included in Xcode build"

key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Views/Components/EmptyTierView.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/GoalListView.swift

decisions:
  - "EmptyTierView placed in Views/Components/ subfolder — auto-picked up by PBXFileSystemSynchronizedRootGroup, no pbxproj edit needed"
  - "No animation on tier icon per D-10 scope note — static image only"
  - "All four tier sections always render in byTier mode, even when empty — removes invisible blank sections"

metrics:
  duration_minutes: 10
  completed_date: "2026-04-16T03:00:22Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 1
---

# Phase 05 Plan 02: Per-Tier Empty States Summary

**One-liner:** Per-tier empty states in GoalListView with warm D-07 copy, tier icon, and pre-selected tier add button.

## What Was Built

### EmptyTierView (new)

`VitaminG/VitaminG/VitaminG/Views/Components/EmptyTierView.swift`

Self-contained SwiftUI View accepting `tier: GoalTier` and `onAdd: () -> Void`. Renders:
- Tier icon (`tier.icon`) in `.font(.title2).foregroundStyle(tier.color)`
- Warm D-07 prompt copy in `.font(.footnote).fontDesign(.rounded).foregroundStyle(.secondary)`
- "Add your first [tier] goal" button with `.font(.caption.weight(.semibold)).fontDesign(.rounded).foregroundStyle(tier.color)`

D-07 copy strings (exact):
- `.immediate`: "What's one small win you can chase today?"
- `.shortTerm`: "What are you working toward this week or month?"
- `.longTerm`: "What would make this year meaningful?"
- `.lifeGoal`: "What do you want your life to stand for?"

No animations (D-10 scope note: icon is static, no `accessibilityReduceMotion` needed).

### GoalListView wiring

The tier section loop in the `else` branch (byTier/byCreationDate modes) now always renders `TierSectionView` for every tier. Inside, it branches:
- `tieredGoals.isEmpty` → shows `EmptyTierView` with onAdd closure that sets `viewModel.draftTier = tier` then `showingAddGoal = true`
- Otherwise → renders goal rows via `ForEach`

The `.byCompletionStatus` branch and the global `EmptyStateView` (shown when zero goals exist) are untouched.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | 210e231 | feat(05-02): add EmptyTierView component with per-tier warm copy |
| Task 2 | c969831 | feat(05-02): wire EmptyTierView into GoalListView tier sections |

## Verification

- Build: `BUILD SUCCEEDED` (iPhone 17 Simulator)
- All four D-07 copy strings present in EmptyTierView.swift
- `EmptyTierView(tier: tier)` present in GoalListView tier ForEach
- `viewModel.draftTier = tier` set before `showingAddGoal = true` in onAdd closure
- Old `if !tieredGoals.isEmpty` guard removed — all four sections always render in byTier mode
- byCompletionStatus branch unchanged (lines 89-106)
- Global EmptyStateView unchanged (lines 38-41)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. EmptyTierView is fully wired with real tier data and functional onAdd closure.

## Threat Flags

None. `GoalTier` is a compile-time enum — tier parameter cannot carry untrusted input. No new network surface.

## Self-Check: PASSED

- [x] `VitaminG/VitaminG/VitaminG/Views/Components/EmptyTierView.swift` — FOUND
- [x] Commit 210e231 — FOUND
- [x] Commit c969831 — FOUND
- [x] `GoalListView.swift` contains `EmptyTierView(tier: tier)` — FOUND
- [x] `GoalListView.swift` contains `viewModel.draftTier = tier` — FOUND
- [x] Old `if !tieredGoals.isEmpty` guard — NOT FOUND (correctly removed)
