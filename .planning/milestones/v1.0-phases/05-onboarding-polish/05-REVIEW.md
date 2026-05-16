---
phase: 05-onboarding-polish
reviewed: 2026-04-15T00:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - VitaminG/VitaminG/VitaminG/ViewModels/OnboardingViewModel.swift
  - VitaminG/VitaminG/VitaminG/Views/Onboarding/OnboardingView.swift
  - VitaminG/VitaminG/VitaminG/Views/Onboarding/WelcomeScreen.swift
  - VitaminG/VitaminG/VitaminG/Views/Onboarding/TiersScreen.swift
  - VitaminG/VitaminG/VitaminG/Views/Onboarding/CreateFirstGoalScreen.swift
  - VitaminG/VitaminG/VitaminG/Views/Sheets/NotificationPermissionSheet.swift
  - VitaminG/VitaminG/VitaminG/VitaminGApp.swift
  - VitaminG/VitaminG/VitaminG/Views/Components/EmptyTierView.swift
  - VitaminG/VitaminG/VitaminG/Views/GoalListView.swift
  - VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift
  - VitaminG/VitaminG/VitaminG/Views/ProfileView.swift
  - VitaminG/VitaminG/VitaminG/Views/ProfileEditSheet.swift
  - VitaminG/VitaminG/VitaminG/Views/StatsView.swift
  - VitaminG/VitaminG/VitaminG/Assets.xcassets/AppIcon.appiconset/Contents.json
  - VitaminG/VitaminG/VitaminGTests/VitaminGTests.swift
findings:
  critical: 0
  warning: 4
  info: 5
  total: 9
status: issues_found
---

# Phase 05: Code Review Report

**Reviewed:** 2026-04-15
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

Reviewed 15 files covering the onboarding flow (ViewModel, three onboarding screens, notification sheet), the app entry point, shared components (EmptyTierView, GoalListView, GoalDetailView, ProfileView, ProfileEditSheet, StatsView), the AppIcon asset catalog, and the test suite.

The architecture is sound: MVVM is consistently enforced, `@Observable` replaces `ObservableObject` throughout, `NavigationStack` is used in place of the deprecated `NavigationView`, and SwiftData constraints for CloudKit compatibility are correctly observed. The onboarding flow itself follows the documented design decisions well.

Four warnings surface issues that can cause silent data loss, unhandled error state, or user-visible bugs in edge cases. Five info items flag dead-button UX, duplicated constants, redundant test coverage, and minor quality improvements.

---

## Warnings

### WR-01: `finish()` races hasCompletedOnboarding against async notification check — onboarding may close before sheet can display

**File:** `VitaminG/VitaminG/VitaminG/Views/Onboarding/OnboardingView.swift:59-62`

**Issue:** `finish()` sets `hasCompletedOnboarding = true` synchronously on line 60, which causes `VitaminGApp.body` to immediately swap `OnboardingView` out of the view hierarchy and present `ContentView`. The `Task { await onboardingVM.completeOnboarding() }` launched on line 61 runs after the view has been removed. Because `onboardingVM.showNotificationSheet = true` is set inside that async task (in `completeOnboarding()`), the `.sheet` modifier in `OnboardingView` is now attached to a view that is no longer displayed — iOS will silently discard the sheet presentation. Users whose notification status is `.notDetermined` will never see the permission sheet.

**Fix:** Reverse the order: complete the async notification check first, then set the flag. Pass a completion handler into `completeOnboarding()` or chain the flag set after the task resolves:

```swift
private func finish() {
    Task {
        await onboardingVM.completeOnboarding()
        // Set flag only after the sheet has been offered (or skipped)
        hasCompletedOnboarding = true
    }
}
```

If the sheet must remain inside `OnboardingView`, hold it open until the user responds. Alternatively, move the notification sheet to `ContentView` so it can be presented after the transition completes.

---

### WR-02: `saveAndComplete()` swallows non-`GoalValidationError` exceptions without surfacing a message

**File:** `VitaminG/VitaminG/VitaminG/Views/Onboarding/CreateFirstGoalScreen.swift:157-160`

**Issue:** The final `catch` block sets `showingValidationAlert = true` but leaves `viewModel.validationError` as `nil`. The alert's `presenting:` parameter is `viewModel.validationError`, so when it is `nil` the alert body closure is never called and the alert is presented with no message. On iOS 17 this renders as an alert with a blank message area — confusing to users. Additionally, a SwiftData `ModelContext` insertion failure (e.g., disk full, store corruption) is silently treated as if no message is needed.

**Fix:** Provide a fallback message for unexpected errors:

```swift
} catch {
    // Surface a generic message for unexpected errors (e.g. SwiftData failure)
    viewModel.validationError = GoalValidationError.titleEmpty  // use a sentinel, or add a new case
    viewModel.showingValidationAlert = true
}
```

A cleaner approach is to add a `GoalValidationError.unknown(String)` case and populate it here, or use a separate `unexpectedErrorMessage: String?` property on the ViewModel displayed via a second `.alert` modifier.

---

### WR-03: `StatsView` refreshes only when `events.count` or `goals.count` changes — completion toggle of an existing goal does not trigger refresh

**File:** `VitaminG/VitaminG/VitaminG/Views/StatsView.swift:33-38`

**Issue:** `viewModel.refresh` is triggered in `onChange(of: events.count)` and `onChange(of: goals.count)`. Toggling a goal's completion status changes `goal.isCompleted` and inserts a new `CompletionEvent` (which does increment `events.count`), so that path is covered. However, *un*-toggling (reactivating) a goal does **not** delete the corresponding `CompletionEvent` — it only sets `goal.isCompleted = false`. The streak and heatmap displayed in `StatsView` will therefore show stale data until the next count-changing event. Additionally, if a goal's `tier` changes (via the edit sheet), `goals.count` is unchanged and stats are not refreshed.

**Fix:** Observe a more granular signal, or add a refresh on `onChange(of: goals)` using the full array comparison available in iOS 17+:

```swift
.onChange(of: goals) { _, _ in
    viewModel.refresh(events: events, goals: goals)
}
.onChange(of: events) { _, _ in
    viewModel.refresh(events: events, goals: goals)
}
```

This replaces the `.count`-only observation with full-value observation, which SwiftData's `@Query` results support via `Equatable` conformance.

---

### WR-04: `NotificationPermissionSheet` — "Allow Notifications" dismisses the sheet before `requestAuthorization()` completes, so the system dialog appears over an already-dismissed sheet

**File:** `VitaminG/VitaminG/VitaminG/Views/Onboarding/OnboardingView.swift:42-46`

**Issue:** The `onAllow` closure on line 44 fires `Task { await NotificationScheduler.shared.requestAuthorization() }` and then immediately sets `onboardingVM.showNotificationSheet = false` on line 45. The sheet is dismissed before the `UNUserNotificationCenter` system dialog appears. On device, the system permission dialog is a UIKit `UIAlertController` presented modally — presenting it while its host sheet is being dismissed can cause the system dialog to appear in an incorrect context or, on some iOS versions, fail to appear at all.

**Fix:** Dismiss the sheet from inside the `Task`, after the authorization call completes:

```swift
onAllow: {
    Task {
        await NotificationScheduler.shared.requestAuthorization()
        onboardingVM.showNotificationSheet = false
    }
}
```

Note: this also requires that the sheet's hosting view remain alive during the authorization call, which ties back to WR-01. Both issues should be resolved together.

---

## Info

### IN-01: Gradient colors are duplicated as inline literals across six files — no shared design token

**Files:**
- `WelcomeScreen.swift:19-21`
- `TiersScreen.swift:23-25`
- `NotificationPermissionSheet.swift:16-18`
- `GoalListView.swift:264-272` (EmptyStateView)
- `StatsView.swift:48-50`
- `ProfileView.swift:76`

**Issue:** The accent gradient `[Color(red: 0.98, green: 0.55, blue: 0.27), Color(red: 0.78, green: 0.48, blue: 0.95)]` appears as raw RGB literals in at least six separate places. If the design changes (e.g., a darker orange for accessibility), every instance must be updated manually.

**Fix:** Extract into a shared extension or constant:

```swift
// In a shared DesignSystem.swift or Color+Brand.swift
extension Color {
    static let brandOrange = Color(red: 0.98, green: 0.55, blue: 0.27)
    static let brandViolet = Color(red: 0.78, green: 0.48, blue: 0.95)
    static let accentGradient: [Color] = [.brandOrange, .brandViolet]
}
```

---

### IN-02: `ProfileView` — "Share Profile" button when `shareURL == nil` is a fully rendered button with no action

**File:** `VitaminG/VitaminG/VitaminG/Views/ProfileView.swift:191-204`

**Issue:** The disabled button branch (lines 191-204) renders a full `.borderedProminent` button with `.disabled(true)`. On iOS, a disabled `.borderedProminent` button is visually indistinguishable from an enabled one to many users, and the `accessibilityHint` ("Set your profile to public to enable sharing") is present but the button's visual state does not communicate why it is disabled. Additionally, the button action closure is an explicit empty block `{}` — a no-op behind disabled — which is unnecessary clutter.

**Fix:** Prefer a single `ShareLink` branch conditional on `shareURL`, and either hide the button entirely when no URL is available or use `.opacity(0.5)` to visually communicate the disabled state:

```swift
.opacity(viewModel.shareURL == nil ? 0.5 : 1.0)
```

---

### IN-03: `AppIcon.appiconset/Contents.json` has Mac idiom entries with no `filename` — App Store submission will warn

**File:** `VitaminG/VitaminG/VitaminG/Assets.xcassets/AppIcon.appiconset/Contents.json:33-79`

**Issue:** The asset catalog includes 10 Mac icon slots (idiom `"mac"`, sizes 16x16 through 512x512) with no `filename` key. For a pure iOS app these entries are harmless at runtime, but Xcode's asset compiler and App Store Connect validation will generate warnings about missing Mac icon assets if the Mac Catalyst capability is absent. If Catalyst is ever added, these unfilled slots become errors.

**Fix:** Either remove the Mac idiom entries (since the project targets iOS only per CLAUDE.md) or provide actual Mac-sized icon assets. The simplest fix is to delete the Mac blocks and keep only the three universal iOS entries.

---

### IN-04: `VitaminGTests` — `EmptyTierViewTests.warmCopyExistsForAllTiers` does not actually test the prompt copy

**File:** `VitaminG/VitaminG/VitaminGTests/VitaminGTests.swift:73-84`

**Issue:** The test instantiates `EmptyTierView` for each tier but only asserts that `tier.displayName.isEmpty == false`. It does not verify that `EmptyTierView.promptCopy` returns a non-empty string for each tier — the actual behavior being documented in the test name. If the `switch` inside `EmptyTierView` accidentally returned `""` for a case, this test would still pass.

**Fix:** The `promptCopy` property is `private`, so direct testing requires either making it `internal` or testing via the rendered view. A simpler approach: test the tier description at the model level as a proxy:

```swift
@Test func warmCopyExistsForAllTiers() {
    for tier in GoalTier.ordered {
        // GoalTier.description acts as a proxy for EmptyTierView's private promptCopy
        #expect(!tier.description.isEmpty)
    }
}
```

Or rename the test to `tierDisplayNamesAreNonEmpty` so the name matches the actual assertion.

---

### IN-05: `GoalViewModel.rescheduleNotification` uses `!$0.isCompleted` predicate but `Goal.completed` is the exposed property — subtle aliasing risk

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift:150`

**Issue:** The `FetchDescriptor` predicate reads `!$0.isCompleted` (the stored property), while all other callers throughout the app use the `goal.completed` computed wrapper. These are functionally equivalent today because `completed` is a simple get/set on `isCompleted`, but the inconsistency means a future refactor that changes `isCompleted` independently from `completed` (e.g., adding a "paused" state) could silently diverge the notification body from what the UI shows.

**Fix:** Keep one access pattern. Since `@Query` predicates require stored properties, the `isCompleted` reference is technically necessary in the predicate — add a comment to make the intent explicit:

```swift
// Must use stored property `isCompleted` here — SwiftData predicates cannot reference computed wrappers
let descriptor = FetchDescriptor<Goal>(predicate: #Predicate { !$0.isCompleted })
```

---

_Reviewed: 2026-04-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
