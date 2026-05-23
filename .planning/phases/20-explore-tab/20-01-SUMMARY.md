---
phase: 20
plan: "01"
subsystem: explore-tab
tags: [explore, gifter, confetti, shake, swiftdata, mvvm]
dependency_graph:
  requires: []
  provides: [ExploreView, ExploreViewModel, GoalGifterCard, ExploreConfettiOverlay, ShakeDetectorView, ExploreModels]
  affects: [ContentView]
tech_stack:
  added: [ShakeDetectorView (UIViewControllerRepresentable)]
  patterns: [daily-gate via UserDefaults, deterministic pool selection by day-of-year, Canvas+TimelineView confetti]
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Models/ExploreModels.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/ExploreViewModel.swift
    - VitaminG/VitaminG/VitaminG/Utilities/ShakeDetectorView.swift
    - VitaminG/VitaminG/VitaminG/Views/Explore/ExploreConfettiOverlay.swift
    - VitaminG/VitaminG/VitaminG/Views/Explore/GoalGifterCard.swift
    - VitaminG/VitaminG/VitaminG/Views/Explore/ExploreView.swift
    - VitaminG/VitaminG/VitaminGTests/ExploreViewModelTests.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
decisions:
  - "Confetti canvas uses Canvas+TimelineView (no SpriteKit) copied verbatim from CheckInCelebrationView"
  - "ShakeDetectorView uses becomeFirstResponder in viewDidAppear (not viewDidLoad) for NavStack re-acquire"
  - "Daily gate stored as Date under vg_explore_gifterDate in UserDefaults.standard"
  - "Goal pool determinism via day-of-year ordinality, identical to VGQuoteBank.todaysQuote() pattern"
  - "associatedInspiration = vg_gifter set post-insert to enable @Query filter in ExploreView"
metrics:
  duration_seconds: 245
  completed_date: "2026-05-22"
  tasks_completed: 5
  tasks_total: 5
  files_created: 7
  files_modified: 1
---

# Phase 20 Plan 01: ExploreView Scaffold + Daily Goal Gifter Summary

## One-liner

ExploreView scaffold with daily goal gifter (shake or tap), SwiftUI Canvas confetti overlay, UserDefaults daily gate, and 20-item deterministic pool — replacing the "Coming soon" placeholder.

## What Was Built

### Task 1 — ExploreModels.swift
Defines `GifterGoal` (Identifiable struct, title + category) and `ExploreContent` enum with a 20-item `gifterPool`. `todaysGifterGoal` is deterministic: uses `Calendar.current.ordinality(of: .day, in: .year, for: Date())` as a day-of-year seed, mirrors `VGQuoteBank.todaysQuote()`.

### Task 2 — ExploreViewModel.swift
`@MainActor @Observable final class` (no `ObservableObject`, no `@Published`). Owns `isDispensing`, `dispensedGoal`, and computed `hasGiftedToday` reading live from `UserDefaults.standard`. `onGifterActivated()` enforces the one-per-day gate and triggers an interpolatingSpring animation. `markGiftedToday()` persists the gate after SwiftData insert.

### Task 3 — ShakeDetectorView.swift
`UIViewControllerRepresentable` wrapping `ShakeVC: UIViewController`. `becomeFirstResponder()` called in `viewDidAppear` (not `viewDidLoad`) to survive NavigationStack push/pop cycles. `motionEnded` forwards `.motionShake` to `onShake` closure. Placed as a zero-size `.background` on `ExploreView`'s `ScrollView`.

### Task 4 — GoalGifterCard.swift + ExploreConfettiOverlay.swift
`GoalGifterCard` has three UI states: not-yet-activated ("Surprise me"), dispensed (goal title + "Add this goal"), and gated ("Come back tomorrow"). `addGiftedGoal` calls `GoalViewModel.addGoal(input:context:)` (never `modelContext.insert` directly), then sets `associatedInspiration = "vg_gifter"` and calls `markGiftedToday()`. Haptic feedback on both actions. `ExploreConfettiOverlay` copies the 60-particle Canvas+TimelineView confetti from `CheckInCelebrationView` verbatim, gated on `accessibilityReduceMotion`.

### Task 5 — ExploreView.swift + ContentView.swift + ExploreViewModelTests.swift
`ExploreView` is a `ScrollView` (no `NavigationStack` — the one in `ContentView` wraps it). Includes `.navigationTitle("Explore")`, toolbar badge (`star.circle.fill`) visible when `todayGiftedCount > 0`. `@Query` on all `Goal` objects filtered to `associatedInspiration == "vg_gifter"` and `creationDate >= today`. `ContentView.swift` line 28: replaced `ExplorePlaceholderView()` with `ExploreView()`. 6 unit tests covering: first activation returns goal, gate blocks second activation, gate resets on yesterday's date, pool size == 20, determinism, and vitamin shelf category count.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. The ExploreView renders real data — the gifter card is fully functional. Plans 20-02 and 20-03 add additional sections (placeholder comments left in the VStack per the plan's design).

## Threat Flags

None. No new network endpoints, auth paths, file access, or schema changes at trust boundaries. `associatedInspiration` is an existing optional `String?` field on `Goal` (SchemaV6); writing to it does not require a schema migration.

## Self-Check: PASSED

All 7 created files confirmed present on disk. All 5 task commits verified in git log:
- 182dd74: feat(20-01): create ExploreModels.swift
- e5332e1: feat(20-01): create ExploreViewModel.swift
- cb4782d: feat(20-01): create ShakeDetectorView.swift
- 7bdc0bf: feat(20-01): create GoalGifterCard and ExploreConfettiOverlay
- 7aad7a6: feat(20-01): ExploreView scaffold, ContentView wiring, ExploreViewModelTests
