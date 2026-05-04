---
phase: 12
plan: "04"
status: complete
wave: 1
completed: 2026-05-03T00:00:00.000Z
key-files:
  modified:
    - VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
---

## Summary

GoalViewModel now signals milestone celebrations via `pendingMilestone`. After each `toggleCompletion` completion event, it checks cumulative count against thresholds (5, 10, 25, 50) using ProgressViewModel.milestoneJustCrossed and fires the signal at most once per threshold per session.

## What Was Built

- `pendingMilestone: (goalID: UUID, threshold: Int)?` — observable property Plan 03 watches via .onChange
- `firedMilestones: Set<String>` — in-memory dedup, keyed "{goalID}-{threshold}" (D-13)
- `progressVM: ProgressViewModel` — stateless delegate
- Modified `toggleCompletion` — inserts milestone check after CompletionEvent insert

## Self-Check: PASSED

- Build green
- GoalViewModelTests pass (19/19, no regression)
- pendingMilestone declared, firedMilestones declared, progressVM declared, milestoneJustCrossed called
