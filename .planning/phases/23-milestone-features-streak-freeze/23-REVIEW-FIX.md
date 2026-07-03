---
phase: 23-milestone-features-streak-freeze
fixed_at: 2026-05-27T00:00:00Z
review_path: .planning/phases/23-milestone-features-streak-freeze/23-REVIEW.md
iteration: 1
findings_in_scope: 12
fixed: 12
skipped: 0
status: all_fixed
---

# Phase 23: Code Review Fix Report

**Fixed at:** 2026-05-27
**Source review:** `.planning/phases/23-milestone-features-streak-freeze/23-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 12 (5 Critical + 7 Warning; Info excluded per fix scope)
- Fixed: 12
- Skipped: 0

## Fixed Issues

### CR-01: StreakMilestoneGate uses wrong UserDefaults suite

**Files modified:** `VitaminG/VitaminG/VitaminG/Services/StreakMilestoneGate.swift`
**Commit:** 7901c5d
**Applied fix:** Added `private static let defaultSuite = "group.com.kyleharrington.VitaminG"` and updated both `hasShown` and `markShown` to default to `UserDefaults(suiteName: defaultSuite) ?? .standard`, matching the app-group suite used by `StreakFreezeService`.

---

### WR-01: markShown silently drops write on JSONEncoder failure

**Files modified:** `VitaminG/VitaminG/VitaminG/Services/StreakMilestoneGate.swift`
**Commit:** 7901c5d (same commit as CR-01)
**Applied fix:** Replaced `if let encoded = try? JSONEncoder().encode(set)` with `guard let encoded = try? JSONEncoder().encode(set) else { assertionFailure(...); return }`. Encode failures now surface in DEBUG builds.

---

### CR-02: Off-by-one in milestone detection loop

**Files modified:** `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift`
**Commit:** 3c209c2
**Applied fix:** Changed loop to iterate `StreakMilestoneGate.goalStreakThresholds.sorted(by: >)` (descending) and use exact equality `goalStreak == threshold` instead of the fragile `goalStreak >= threshold && goalStreak - 1 < threshold` condition. Eliminates loop-order sensitivity and the integer subtraction.

---

### WR-02: addCheckIn reads goal.completionEvents twice with inconsistent comment

**Files modified:** `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift`
**Commit:** 3c209c2 (same commit as CR-02)
**Applied fix:** Added canonical comment immediately after `event.goal = goal`: "SwiftData synchronously updates goal.completionEvents on @MainActor — all subsequent reads of goal.completionEvents in this method reflect the new event." Provides a single authoritative statement to prevent future regressions.

---

### CR-03: Stale completionCount (+1 adjustment) in addCheckIn progress-percent calculation

**Files modified:** `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift`
**Commit:** 3c209c2 (same commit as CR-02)
**Applied fix:** Removed `+ 1` from `let completionCount = (goal.completionEvents?.count ?? 0) + 1`. SwiftData synchronously updates the relationship, so the inserted event is already in `goal.completionEvents`. Added explanatory comment.

---

### CR-04: reporterID computed var race in GlobalFeedSection

**Files modified:** `VitaminG/VitaminG/VitaminG/Views/Community/GlobalFeedSection.swift`
**Commit:** 43f8303
**Applied fix:** Converted `private var reporterID: String { ... }` to `private let reporterID: String = { ... }()` (stored property with self-executing closure). Initialises exactly once per view instance, eliminating the concurrent-access race that could generate two distinct reporter IDs. Removed the now-unused `private static let reporterIDKey` in favour of the inline key string within the closure.

---

### CR-05: Global streak-at-risk nudge swallows scheduling errors silently

**Files modified:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift`, `VitaminG/VitaminG/VitaminGTests/Phase23NotificationTests.swift`
**Commit:** 8f05852
**Applied fix:**
- Production: replaced `try? await center.add(request)` with `do { try await center.add(request) } catch { #if DEBUG print(...) #endif }`, consistent with every other `schedule*` method.
- Tests: added `setUp` and `tearDown` overrides calling `UNUserNotificationCenter.current().removeAllPendingNotificationRequests()` to ensure a clean notification center slate for each test run.

---

### WR-03: Check-in celebration shown even on same-day duplicate attempt

**Files modified:** `VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift`
**Commit:** 386e6cc
**Applied fix:** Captured `goal.completionEvents?.count` before and after `addCheckIn`. Only sets `showingCheckInCelebration = true` if `newCount > priorCount`, so the celebration is suppressed for same-day duplicates or rapid double-taps.

---

### WR-04: completionCelebrationShown set before celebration is presented

**Files modified:** `VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift`
**Commit:** 386e6cc (same commit as WR-03)
**Applied fix:** Removed `goal.completionCelebrationShown = true` from the `.onChange` handler. Moved it into the `onDismiss` closure of `GoalCompletionCelebrationView` so the flag is only set after the user actually sees and dismisses the screen.

---

### WR-05: createAchievementPost missing category field

**Files modified:** `VitaminG/VitaminG/VitaminG/Services/CommunityService.swift`
**Commit:** d3a5f51
**Applied fix:** Added `record["category"] = "achievement" as CKRecordValue` after the existing record fields. Prevents CloudKit save failures when category is schema-required and ensures achievement posts are queryable by category filter.

---

### WR-06: GoalListView onShareToCommunity closure is a no-op

**Files modified:** `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift`
**Commit:** 895b971
**Applied fix:** Added `@Query private var profiles: [UserProfile]` to `GoalListView`. Replaced the `/* no-op */` closure with a proper call to `viewModel.shareGoalMilestone(goalID:threshold:goalTitle:username:colorHex:)` using the existing `matchedGoal` variable and `profiles.first` for user data, matching the GoalDetailView implementation per MILE-05 spec.

---

### WR-07: Phase23GoalViewModelTests uses .standard defaults — pollutes shared state

**Files modified:** `VitaminG/VitaminG/VitaminGTests/Phase23GoalViewModelTests.swift`
**Commit:** ad34f60
**Applied fix:** Added `var testDefaults: UserDefaults!` as a class-level property, initialised in `setUpWithError` with `UserDefaults(suiteName: UUID().uuidString)!`, and set to `nil` in `tearDown`. Updated `StreakMilestoneGate.hasShown` and `markShown` calls to pass `defaults: testDefaults` explicitly. Removed the inline `let testDefaults` from test 1 (now superseded by the class-level property).

---

## Skipped Issues

None.

---

_Fixed: 2026-05-27_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
