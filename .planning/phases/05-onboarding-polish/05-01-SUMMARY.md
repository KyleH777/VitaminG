---
phase: 05-onboarding-polish
plan: 01
subsystem: onboarding
tags: [onboarding, navigation, notifications, swiftui, appStorage]
dependency_graph:
  requires: []
  provides:
    - onboarding-flow
    - notification-permission-sheet
    - hasCompletedOnboarding-gate
  affects:
    - VitaminGApp.swift
    - ContentView (now gated by onboarding)
tech_stack:
  added: []
  patterns:
    - NavigationStack with OnboardingStep enum (matches AppRoute pattern)
    - "@MainActor @Observable OnboardingViewModel (matches GoalViewModel)"
    - "@AppStorage gate in App.body (not init)"
    - ".presentationDetents([.medium]) for notification half-sheet"
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/ViewModels/OnboardingViewModel.swift
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/OnboardingView.swift
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/WelcomeScreen.swift
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/TiersScreen.swift
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/CreateFirstGoalScreen.swift
    - VitaminG/VitaminG/VitaminG/Views/Sheets/NotificationPermissionSheet.swift
  modified:
    - VitaminG/VitaminG/VitaminG/VitaminGApp.swift
decisions:
  - "@AppStorage gate placed as stored property on VitaminGApp struct (not inside init) per Pitfall 5"
  - "hasCompletedOnboarding set synchronously in finish() before async notification check per Pitfall 2"
  - "Group wrapper in VitaminGApp.body ensures both branches get .modelContainer and .environment per Pitfall 1"
  - "No nested NavigationStack in CreateFirstGoalScreen — uses OnboardingView's NavigationStack per Open Question 2"
  - "OnboardingStep enum has only .tiers and .createGoal cases — WelcomeScreen is the NavigationStack root (not a step)"
metrics:
  duration_minutes: 4
  completed_date: "2026-04-16"
  tasks_completed: 2
  files_created: 6
  files_modified: 1
requirements:
  - ONBOARD-01
  - ONBOARD-02
  - ONBOARD-03
  - ONBOARD-04
  - NOTIF-01
---

# Phase 05 Plan 01: Onboarding Flow Summary

**One-liner:** 3-screen NavigationStack onboarding (Welcome → Tiers → Create Goal) with notification half-sheet, gated by @AppStorage in VitaminGApp.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | OnboardingViewModel, OnboardingView shell, 3 onboarding screens | d157f09 | OnboardingViewModel.swift, OnboardingView.swift, WelcomeScreen.swift, TiersScreen.swift, CreateFirstGoalScreen.swift |
| 2 | NotificationPermissionSheet and @AppStorage gate in VitaminGApp | f000c0c | NotificationPermissionSheet.swift, VitaminGApp.swift |

## What Was Built

### OnboardingViewModel (`@MainActor @Observable`)
- `hasCreatedFirstGoal: Bool` and `showNotificationSheet: Bool` state
- `completeOnboarding() async` — checks `authorizationStatus()` and only shows sheet if `.notDetermined`
- Satisfies Pitfall 6: avoids showing permission dialog when already authorized/denied

### OnboardingView (NavigationStack shell)
- `enum OnboardingStep: Hashable { case tiers, createGoal }` — type-safe routing
- `@AppStorage("hasCompletedOnboarding")` reactive gate
- `.sheet(isPresented: $onboardingVM.showNotificationSheet)` with `.presentationDetents([.medium])`
- `finish()` sets `hasCompletedOnboarding = true` synchronously, then async `completeOnboarding()`

### WelcomeScreen (Screen 1)
- Accent gradient circle (160pt) with `"star.circle.fill"` (72pt SF Symbol)
- Pulse animation guarded by `@Environment(\.accessibilityReduceMotion)` per D-13/D-10
- "Get Started" gradient capsule CTA, "Skip" toolbar button (D-01)
- `.navigationBarBackButtonHidden(true)` — first screen

### TiersScreen (Screen 2)
- ScrollView with cards for all 4 GoalTier tiers
- D-07 warm copy: "Quick wins you can chase today" / "Goals for the coming weeks and months" / "What would make this year meaningful" / "What you want your life to stand for"
- "Skip" toolbar button, "Continue" gradient capsule to CreateFirstGoalScreen

### CreateFirstGoalScreen (Screen 3)
- Reuses `GoalViewModel` and `TierPickerView` — no duplicated form logic
- No nested `NavigationStack` (uses parent OnboardingView's stack)
- "Maybe later" `safeAreaInset` button calls `onSkipGoal()`
- Saves via `viewModel.addGoal(context: modelContext)` then calls `onComplete()` → `finish()`
- Validation alert matching AddGoalView pattern

### NotificationPermissionSheet
- Mock notification preview card with `.accessibilityElement(children: .combine)`
- "Wake up to your goals every morning." headline
- "Allow Notifications" gradient capsule CTA with `.accessibilityLabel`
- "Not now" secondary action
- `.presentationDetents([.medium])` applied from OnboardingView (not inside sheet file)

### VitaminGApp.swift
- `@AppStorage("hasCompletedOnboarding")` as stored property on struct (not inside `init()`)
- `Group { if hasCompletedOnboarding { ContentView() } else { OnboardingView() } }` pattern
- `.modelContainer(container)` and `.environment(router)` on the `Group` — both branches receive environment
- `init()` unchanged

## Deviations from Plan

None — plan executed exactly as written.

The only minor implementation choice: `OnboardingStep` enum has cases `.tiers` and `.createGoal` (not `.welcome`) because WelcomeScreen is the NavigationStack root view, not a destination. This is consistent with the RESEARCH.md pattern and avoids a redundant enum case.

## Known Stubs

None. All onboarding screens display real data:
- Tier names and colors from `GoalTier.ordered`
- Goal creation via `GoalViewModel.addGoal()` with full SwiftData persistence
- Notification permission via `NotificationScheduler.requestAuthorization()`

## Threat Surface Scan

No new threat surface introduced beyond what the threat model documented:
- T-05-01 (AppStorage tampering): accepted — local Bool, no security impact
- T-05-02 (input validation in CreateFirstGoalScreen): mitigated — reuses `GoalViewModel.validate()` with existing char limits

## Self-Check

### Files exist:
- FOUND: ViewModels/OnboardingViewModel.swift
- FOUND: Views/Onboarding/OnboardingView.swift
- FOUND: Views/Onboarding/WelcomeScreen.swift
- FOUND: Views/Onboarding/TiersScreen.swift
- FOUND: Views/Onboarding/CreateFirstGoalScreen.swift
- FOUND: Views/Sheets/NotificationPermissionSheet.swift
- FOUND: VitaminGApp.swift (modified)

### Commits exist:
- FOUND: d157f09 feat(05-01): add OnboardingViewModel and 3-screen onboarding flow
- FOUND: f000c0c feat(05-01): add NotificationPermissionSheet and wire @AppStorage gate in VitaminGApp

### Build: SUCCEEDED (iPhone 17 Simulator, iOS 26.4)

## Self-Check: PASSED
