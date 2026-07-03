---
phase: 20
plan: "04"
name: Trending Now + Gifts for Stuck Days
subsystem: explore-tab
tags: [trending, cloudkit, stuck-day, user-defaults, unit-tests]
dependency_graph:
  requires: [20-01, 20-02, 20-03]
  provides: [EXPLORE-05, EXPLORE-06]
  affects: [ExploreView, ExploreViewModel, ExploreModels, ExploreService, ExploreViewModelTests]
tech_stack:
  added: [CloudKit public DB fetch]
  patterns: [once-per-day-userdefaults-gate, day-of-year-seeding, cloudkit-silent-fallback, horizontal-scroll-cards]
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Services/ExploreService.swift
    - VitaminG/VitaminG/VitaminG/Views/Explore/TrendingNowSection.swift
    - VitaminG/VitaminG/VitaminG/Views/Explore/StuckDayGiftsSection.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Models/ExploreModels.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/ExploreViewModel.swift
    - VitaminG/VitaminG/VitaminG/Views/Explore/ExploreView.swift
    - VitaminG/VitaminG/VitaminGTests/ExploreViewModelTests.swift
decisions:
  - "TrendingGoal CKRecord schema not yet in CloudKit — fetch silently falls back to staticTrendingGoals"
  - "StuckDayGift.id is a stable string (not UUID) for reproducible UserDefaults hide keys"
  - "3 gifts derived by (dayOfYear-1) % 12 pool with wrap, matching gifter determinism pattern"
  - "StuckDayGift field renamed subtitle (not description) to avoid CustomStringConvertible protocol conflict"
metrics:
  duration: "~20 minutes"
  completed: "2026-05-23"
  tasks_completed: 4
  files_changed: 7
---

# Phase 20 Plan 04: Trending Now + Gifts for Stuck Days Summary

JWT auth with refresh rotation using jose library

Implements EXPLORE-05 and EXPLORE-06: TrendingNowSection shows a horizontal scroll of community goals fetched from CloudKit public DB (with static fallback), and StuckDayGiftsSection shows 3 daily curated easy-win goals seeded by day-of-year with per-card UserDefaults hide gate.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Append TrendingGoalItem, StuckDayGift, pools to ExploreModels.swift | 6d4810f | ExploreModels.swift |
| 2 | Create ExploreService.swift + extend ExploreViewModel + add tests | 6d4810f | ExploreService.swift, ExploreViewModel.swift, ExploreViewModelTests.swift |
| 3 | Create TrendingNowSection.swift + StuckDayGiftsSection.swift | 6d4810f | TrendingNowSection.swift, StuckDayGiftsSection.swift |
| 4 | Wire sections into ExploreView.swift | 6d4810f | ExploreView.swift |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Renamed StuckDayGift.description to StuckDayGift.subtitle**
- **Found during:** Task 1 (pre-emptive — would have caused protocol conflict)
- **Issue:** A struct named `description` conflicts with `CustomStringConvertible.description`. Swift would synthesize or shadow the protocol witness, causing confusing compiler behavior or subtle bugs.
- **Fix:** Used `subtitle` instead throughout ExploreModels.swift, StuckDayGiftsSection.swift, and all plan-provided code blocks. The plan's "Common issues" section flagged this exact risk.
- **Files modified:** ExploreModels.swift, StuckDayGiftsSection.swift
- **Commit:** 6d4810f

## Human Action Required (CloudKit Console)

Before live-data testing on a real device:
1. Create `TrendingGoal` record type with fields: `title` (String), `category` (String), `participantCount` (Int64), `completedCount` (Int64), `createdAt` (DateTime)
2. Add Queryable index on `participantCount`
3. Deploy schema to Production
4. Seed 3-5 records in Development and Production

The app works correctly without this step — static fallback is active.

## Known Stubs

None — all data is wired. TrendingNowSection uses static fallback pool (not a stub — intentional design with CloudKit fetch). StuckDayGiftsSection derives gifts deterministically from the pool.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: cloudkit-input | ExploreService.swift | TrendingGoal.title from CloudKit passes through InputSanitizer.sanitize() per ASVS V5 — mitigated |

## Self-Check: PASSED

- ExploreService.swift: FOUND
- TrendingNowSection.swift: FOUND
- StuckDayGiftsSection.swift: FOUND
- Commit 6d4810f: FOUND
- BUILD SUCCEEDED
