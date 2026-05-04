---
phase: 12
plan: "03"
status: complete
wave: 1
completed: 2026-05-04T00:00:00.000Z
key-files:
  modified:
    - VitaminG/VitaminG/VitaminG/Views/GoalListView.swift
---

## Summary

GoalListView now shows a ProgressRingView (28pt ring) in every goal card's trailing slot, replacing the tier pip. CompletionEvents flow from @Query down to each GoalRowView. Milestone badge overlay fires at 5/10/25/50 thresholds via .onChange consumer on the list.

## What Was Built

- `@Query private var events: [CompletionEvent]` — fetches all events, passed to each GoalRowView
- GoalRowView gained `events: [CompletionEvent]`, `milestoneThreshold: Int?` params + @State badge vars (`showMilestoneBadge`, `badgeOpacity`, `badgeScale`)
- Tier-pip `RoundedRectangle` replaced by `ProgressRingView(progress:tier:isCompleted:)` using `ProgressViewModel().ringProgress(for:events:)`
- `@State private var pendingMilestone: (goalID: UUID, threshold: Int)?` on GoalListView routes milestone to matching row
- `.onChange(of: viewModel.pendingMilestone?.goalID)` consumer routes milestone to matching row and auto-clears after 3s
- `goalRow(for:)` derives per-row `milestoneThreshold` from `pendingMilestone` @State
- `fireMilestoneBadge(threshold:)` — star.fill (or trophy.fill at 50), reduced-motion gated, VoiceOver announcement via UIAccessibility.post

## Commits

| Task | Commit | Message |
|------|--------|---------|
| Task 1 | 1b508a4 | feat(12-03): GoalListView — @Query events, replace tier pip with ProgressRingView (PROG-01) |
| Task 2 | 24dedbf | feat(12-03): GoalListView — milestone badge overlay + .onChange consumer (PROG-03) |

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- `grep -c "ProgressRingView(" GoalListView.swift` == 1
- `grep -c "RoundedRectangle(cornerRadius: 3)" GoalListView.swift` == 0
- `grep -c ".onChange(of: viewModel.pendingMilestone" GoalListView.swift` == 1
- Build green (BUILD SUCCEEDED)
- Full unit test suite green (TEST SUCCEEDED, 20+ tests passing)
- UI test target failed to launch (pre-existing simulator infrastructure issue — no test cases executed, not caused by this plan's changes)
