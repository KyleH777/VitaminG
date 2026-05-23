---
phase: 20
plan: "02"
name: Mood Prompt Card
subsystem: explore-tab
tags: [mood, daily-gate, userdefaults, animation, accessibility]
dependency_graph:
  requires: [20-01]
  provides: [EXPLORE-03]
  affects: [ExploreView, ExploreViewModel, ExploreModels, ExploreViewModelTests]
tech_stack:
  added: []
  patterns: [once-per-day-userdefaults-gate, reduce-motion-guard, haptic-feedback, swiftui-transition]
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Views/Explore/MoodPromptCard.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Models/ExploreModels.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/ExploreViewModel.swift
    - VitaminG/VitaminG/VitaminGTests/ExploreViewModelTests.swift
    - VitaminG/VitaminG/VitaminG/Views/Explore/ExploreView.swift
decisions:
  - "Dismiss-without-selection (checkmark button) uses .okay as sentinel — marks date gate without recording preference"
  - "hasMoodSelectedToday is a computed property (not stored) so midnight transitions work without restart"
  - "PBXFileSystemSynchronizedRootGroup means MoodPromptCard.swift auto-included — no project.pbxproj edit needed"
metrics:
  duration: "~15 minutes"
  completed: "2026-05-23"
  tasks_completed: 2
  files_changed: 5
---

# Phase 20 Plan 02: Mood Prompt Card Summary

## One-liner

Once-per-day "How are you feeling?" card with 5 emoji chips, UserDefaults gate, and easeOut collapse animation — no SwiftData writes.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 20-02-01 | Add MoodOption enum and mood gate to ViewModel | cd1a1e9 | ExploreModels.swift, ExploreViewModel.swift, ExploreViewModelTests.swift |
| 20-02-02 | Create MoodPromptCard.swift and wire into ExploreView | 5964d4e | MoodPromptCard.swift (new), ExploreView.swift |

## What Was Built

**MoodOption enum** (in ExploreModels.swift): 5 cases — Amazing, Good, Okay, Low, Push — each with emoji and a `String` raw value. Conforms to `CaseIterable` and `Identifiable`.

**Mood gate in ExploreViewModel**: `hasMoodSelectedToday` computed property reads `UserDefaults` key `vg_explore_moodDate` and checks `Calendar.current.isDateInToday(_:)`. `selectMood(_:)` writes `Date()` to that key. No stored @Published property — midnight transitions work naturally.

**MoodPromptCard.swift**: SwiftUI `View` with `@Bindable var viewModel: ExploreViewModel`. Header row with title (`VGTheme.serif(18)`) and checkmark dismiss button (44pt tap target). Horizontal `ScrollView` of capsule chips, one per `MoodOption`. `@Environment(\.accessibilityReduceMotion)` guards all animations — under reduce motion, state updates immediately. Chip tap and dismiss both trigger `UIImpactFeedbackGenerator(.light)`. Card collapses via `.transition(.opacity.combined(with: .move(edge: .top)))` inside `withAnimation(.easeOut(duration: 0.3))`.

**ExploreView wire-up**: "Daily Mood" section label + `MoodPromptCard(viewModel: viewModel)` inserted directly after the "Today's Gift" section, using the existing `sectionLabel` helper.

**testMoodGate**: Verifies `hasMoodSelectedToday` is false before action, true after `selectMood(.good)`. Cleans up `vg_explore_moodDate` in setUp/tearDown.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. The card's dismiss sentinel (`.okay`) is intentional per plan spec: "use .okay as the 'dismissed without selection' sentinel." The mood value is not persisted beyond the date gate, which is the correct behavior per EXPLORE-03.

## Threat Flags

None. No new network endpoints, auth paths, or trust-boundary schema changes. UserDefaults usage is write-only (date stamp) with no PII stored.

## Self-Check: PASSED

- MoodPromptCard.swift: FOUND at VitaminG/VitaminG/VitaminG/Views/Explore/MoodPromptCard.swift
- ExploreModels.swift MoodOption: FOUND (appended, existing content intact)
- ExploreViewModel.swift mood gate: FOUND (hasMoodSelectedToday, selectMood, moodDate key)
- ExploreViewModelTests.swift testMoodGate: FOUND at line 70
- ExploreView.swift wiring: FOUND (sectionLabel + MoodPromptCard inserted)
- Commit cd1a1e9: FOUND (Task 20-02-01)
- Commit 5964d4e: FOUND (Task 20-02-02)
- No context.insert in mood files: VERIFIED
- No NavigationStack added: VERIFIED
- No SchemaV7.MoodEntry reference: VERIFIED
