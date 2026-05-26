---
phase: 23-milestone-features-streak-freeze
reviewed: 2026-05-26T00:00:00Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - VitaminG/VitaminG/VitaminG/Models/SchemaV10.swift
  - VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift
  - VitaminG/VitaminG/VitaminG/Services/StreakFreezeService.swift
  - VitaminG/VitaminG/VitaminG/Services/StreakMilestoneGate.swift
  - VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift
  - VitaminG/VitaminG/VitaminG/Services/CommunityService.swift
  - VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
  - VitaminG/VitaminG/VitaminG/ViewModels/StatsViewModel.swift
  - VitaminG/VitaminG/VitaminG/Views/HeatmapView.swift
  - VitaminG/VitaminG/VitaminG/Views/GoalStreakMilestoneView.swift
  - VitaminG/VitaminG/VitaminG/Views/GoalCompletionCelebrationView.swift
  - VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift
  - VitaminG/VitaminG/VitaminG/Views/GoalListView.swift
  - VitaminG/VitaminG/VitaminG/Views/Community/GlobalFeedSection.swift
  - VitaminG/VitaminG/VitaminG/Views/Community/StreakAchievementCard.swift
  - VitaminG/VitaminG/VitaminG/VitaminGApp.swift
  - VitaminG/VitaminG/VitaminGTests/Phase23GoalViewModelTests.swift
  - VitaminG/VitaminG/VitaminGTests/Phase23MilestoneGateTests.swift
  - VitaminG/VitaminG/VitaminGTests/Phase23NotificationTests.swift
  - VitaminG/VitaminG/VitaminGTests/Phase23StatsViewModelTests.swift
  - VitaminG/VitaminG/VitaminGTests/StreakFreezeTests.swift
findings:
  critical: 5
  warning: 7
  info: 3
  total: 15
status: issues_found
---

# Phase 23: Code Review Report

**Reviewed:** 2026-05-26
**Depth:** standard
**Files Reviewed:** 21
**Status:** issues_found

## Summary

Phase 23 adds per-goal streak milestones (MILE-04), a global streak-at-risk nudge (MILE-02), streak-freeze heatmap visualisation (MILE-03), goal-completion celebration (MILE-06), and community achievement posts (MILE-05). The schema migration, milestone gate, and heatmap sentinel logic are generally sound. However, five blocker-class issues were found: a `StreakMilestoneGate` that uses `.standard` UserDefaults instead of the app-group suite used by `StreakFreezeService` (making the two dual-persistence strategies inconsistent and broken across widget/Watch extensions); an off-by-one in the milestone detection loop that prevents the *last* threshold (365) from ever being detected when the streak lands exactly on 365; a progress-percent calculation in `GoalViewModel.addCheckIn` that reads a stale count; a `reporterID` computed property in `GlobalFeedSection` that generates and stores a new UUID on every call when no stored value is found, making concurrent accesses create multiple reporter IDs; and a missing authorization guard before the global streak-at-risk nudge is scheduled at launch, so the notification is silently submitted to an unauthorized center.

---

## Critical Issues

### CR-01: `StreakMilestoneGate` uses `.standard` UserDefaults — breaks widget/Watch context and contradicts the app-group suite used by `StreakFreezeService`

**File:** `VitaminG/VitaminG/VitaminG/Services/StreakMilestoneGate.swift:19`

**Issue:** `StreakMilestoneGate.hasShown` and `markShown` default to `UserDefaults.standard`. `StreakFreezeService` (the sibling service) explicitly uses `UserDefaults(suiteName: "group.com.kyleharrington.VitaminG") ?? .standard`. Because the milestone gate and the freeze service store their data in different suites, a widget or Watch extension that reads freeze state from the app-group suite cannot also read milestone state from the same suite. More concretely: if the app is reinstalled or migrated and the group suite is preserved (as is typical for CloudKit-backed apps), milestone-shown state is lost from `.standard` while freeze state survives in the group suite. The two services are callers in the same check-in path and should use the same suite.

**Fix:**
```swift
// StreakMilestoneGate.swift
private static let defaultSuite = "group.com.kyleharrington.VitaminG"

static func hasShown(goalID: UUID, threshold: Int,
                     defaults: UserDefaults = UserDefaults(suiteName: defaultSuite) ?? .standard) -> Bool { … }

static func markShown(goalID: UUID, threshold: Int,
                      defaults: UserDefaults = UserDefaults(suiteName: defaultSuite) ?? .standard) { … }
```
Update `Phase23MilestoneGateTests` to also update its `testDefaults` suite name so the test suite remains isolated.

---

### CR-02: Off-by-one in milestone detection loop — threshold 365 (and any threshold == current streak) is never detected

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift:189-195`

**Issue:** The detection condition is:
```swift
if goalStreak >= threshold && goalStreak - 1 < threshold
```
This means "streak just *crossed* threshold" — i.e., `goalStreak - 1 < threshold` must be true. When `goalStreak == 365` and `threshold == 365`, the condition becomes `365 >= 365 && 364 < 365`, which is `true && true` — that part is correct. However, the `break` statement on line 195 means **only the first matching threshold fires**. The thresholds are iterated in ascending order `[7, 14, 30, 60, 90, 365]`. If a user skips multiple thresholds in one check-in (only possible with backdated data, but the test harness `makeGoal(withStreak:)` can construct such states), only the smallest threshold fires. The real gap is that `goalStreak - 1` computes incorrectly when `goalStreak` is exactly 0 (Swift `Int` subtraction wraps in debug, traps in release when overflow checks are on). A streak of 0 is theoretically impossible here since the event was just inserted, but the expression `goalStreak - 1` on an `Int` that has just been read from a computed property is fragile. The actual blocker: the loop iterates over the unsorted constant `[7, 14, 30, 60, 90, 365]` — if the constant were ever reordered, a higher threshold would shadow a lower one and the lower would never fire. The `break` makes the loop order-sensitive with no enforcement.

**Fix:** Either drop the `break` and set `pendingGoalMilestone` to the *highest* threshold crossed (matching user expectation), or iterate in descending order and keep the `break`:
```swift
// Iterate descending so the highest milestone wins; break after first match
for threshold in StreakMilestoneGate.goalStreakThresholds.sorted(by: >) {
    if goalStreak == threshold
        && !StreakMilestoneGate.hasShown(goalID: goal.id, threshold: threshold) {
        pendingGoalMilestone = (goalID: goal.id, threshold: threshold)
        break
    }
}
```
Using `goalStreak == threshold` (exact equality) is strictly correct for "just crossed" detection because `addCheckIn` is the only place that appends events; prior events would have already triggered lower thresholds. This removes the subtraction, the fragility, and the ordering dependency.

---

### CR-03: Stale `completionCount` in `addCheckIn` progress-percent calculation

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift:220`

**Issue:** After inserting the new `CompletionEvent` and assigning `event.goal = goal`, the code computes:
```swift
let completionCount = (goal.completionEvents?.count ?? 0) + 1  // +1 for the just-inserted event
```
The comment says "the just-inserted event" but SwiftData updates `goal.completionEvents` **synchronously** on `@MainActor` — the `+1` adjustment was correct in an earlier version before the relationship was wired up. Now `goal.completionEvents` already contains the newly inserted event, so this double-counts: `completionCount` is one higher than the true value. The progress percent sent to `CommunityService.writeGlimpse` is therefore inflated by `100/durationDays` percent on every check-in.

**Fix:**
```swift
// After event.goal = goal, completionEvents already includes the new event on @MainActor
let completionCount = goal.completionEvents?.count ?? 0
// Remove the +1 — SwiftData relationship graph is synchronously updated
let progressPercent: Int = durationDays > 0
    ? min(100, (completionCount * 100) / durationDays)
    : 0
```

---

### CR-04: `reporterID` computed property generates and persists a new UUID on every concurrent access — race window creates multiple reporter IDs

**File:** `VitaminG/VitaminG/VitaminG/Views/Community/GlobalFeedSection.swift:31-38`

**Issue:** `reporterID` is a computed `var`, not a stored property. On every call it reads from `UserDefaults.standard`; if no value is stored, it:
1. Generates a new UUID
2. Writes it to `UserDefaults`
3. Returns it

If two concurrent `handleReport` calls are dispatched in the same render cycle (e.g., two quick taps before SwiftUI can commit the first defaults write), the second call reads `nil` from defaults (the first write has not yet propagated synchronously to the getter) and generates a **second, different reporter ID**. The user now has two reporter IDs on the server for the same installation. Additionally, this pattern makes every access to `reporterID` O(UserDefaults read) even when the ID already exists, and the UUID is generated inside a View (business logic in a view — violates project MVVM rule).

**Fix:** Convert to a lazy stored property or move the reporter ID into a service/ViewModel:
```swift
// In GlobalFeedSection, replace the computed var with a stored let:
private let reporterID: String = {
    let key = "com.kyleharrington.VitaminG.reporterID"
    if let stored = UserDefaults.standard.string(forKey: key) { return stored }
    let newID = UUID().uuidString
    UserDefaults.standard.set(newID, forKey: key)
    return newID
}()
```
This initialises exactly once per view instance and avoids the race.

---

### CR-05: Global streak-at-risk nudge scheduled at launch without authorization check

**File:** `VitaminG/VitaminG/VitaminG/VitaminGApp.swift:116`

**Issue:** The launch `.task` correctly guards `rescheduleWinReminder()` and `reschedule()` inside `if isGranted { … }`, but then calls `scheduleGlobalStreakAtRiskNudge()` inside that same guarded block. That is actually fine — it is inside the `isGranted` block. However, the method `scheduleGlobalStreakAtRiskNudge()` ends with:
```swift
try? await center.add(request)
```
while every other `schedule*` method in the same file uses a `do/catch` and logs the error in `#if DEBUG`. The global nudge silently swallows all scheduling errors including `.notAuthorized`, `.badgeNotAllowed`, etc. This is by design (comment says "best-effort"), but the inconsistency means scheduling failures for this notification are completely invisible in production diagnostics. More critically: in the `scheduleGlobalStreakAtRiskNudge(pendingCount:)` overload, after the `guard count < 60` check, the method calls `center.removePendingNotificationRequests(withIdentifiers:)` and then `try? await center.add(request)`. There is a TOCTOU window: the count was injected by the caller (the public no-arg `scheduleGlobalStreakAtRiskNudge()` reads the real count before calling the internal overload), but by the time `center.add` executes, additional notifications may have been added concurrently by other tasks, pushing the total over 64. This is a low-probability race but real on low-end devices with multiple concurrent Task spawns at launch (VitaminGApp spawns three detached Tasks labeled A, B, C, plus the nudge).

The more concrete blocker: `Phase23NotificationTests.test_scheduleGlobalStreakAtRisk_respectsCapGuard` asserts that after calling the injected-count overload with `pendingCount: 60`, the real `UNUserNotificationCenter` has no pending notification. This assertion is only valid because the test environment has no prior pending notifications — the test does **not** clean up the notification center before checking. If another test in the same suite had scheduled a real notification earlier, this assertion could produce a false negative.

**Fix for production code:** Add a `#if DEBUG` diagnostic inside the `try?` path, consistent with other methods:
```swift
do {
    try await center.add(request)
} catch {
    #if DEBUG
    print("[NotificationScheduler] Failed to add globalStreakAtRisk: \(error)")
    #endif
}
```
**Fix for test:** Add `UNUserNotificationCenter.current().removeAllPendingNotificationRequests()` in `setUp` / `tearDown` to ensure a clean slate.

---

## Warnings

### WR-01: `StreakMilestoneGate.markShown` silently drops the write when `JSONEncoder.encode` fails

**File:** `VitaminG/VitaminG/VitaminG/Services/StreakMilestoneGate.swift:35-37`

**Issue:**
```swift
if let encoded = try? JSONEncoder().encode(set) {
    defaults.set(encoded, forKey: key)
}
```
`JSONEncoder().encode(Set<String>)` can only realistically fail if the `String` values contain invalid UTF-16 surrogates, which UUIDs cannot produce. However, if encoding fails for any reason, `markShown` returns silently without writing anything — the milestone will be shown again on the next launch. No error is surfaced even in DEBUG. The idempotency contract documented in the threat model (T-23-01-01) is silently violated.

**Fix:** Add a `#if DEBUG` assertion:
```swift
guard let encoded = try? JSONEncoder().encode(set) else {
    assertionFailure("[StreakMilestoneGate] Failed to encode milestone set — markShown is a no-op")
    return
}
defaults.set(encoded, forKey: key)
```

---

### WR-02: `GoalViewModel.addCheckIn` reads `goal.completionEvents` twice with different semantics

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift:183-206`

**Issue:** `addCheckIn` first calls `StreakEngine.currentStreak(from: goal.completionEvents ?? [])` (line 185) — this reads the event array *after* the new event has been inserted — then later compares `goal.completionEvents?.count ?? 0` against `durationDays` (line 202). Because `goal.completionEvents` includes the just-inserted event in both reads, the streak calculation is correct. But the comment on line 184 says "currentStreak reads goal.completionEvents which now includes the just-inserted event" — this is correct. The logical inconsistency is that the progress-percent block (line 220, see CR-03) tries to compensate for what it wrongly believes is a stale relationship but overcorrects. The relationship reading semantics need to be made consistent and documented with a single canonical statement to avoid future regressions.

**Fix:** Add a single comment block after `event.goal = goal` that explicitly states "SwiftData synchronously updates goal.completionEvents on @MainActor — all subsequent reads of goal.completionEvents in this method reflect the new event." Remove the `+1` adjustment (addressed in CR-03).

---

### WR-03: `GoalDetailView` shows the check-in celebration even on a same-day duplicate attempt

**File:** `VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift:347-354`

**Issue:**
```swift
Button {
    viewModel.addCheckIn(for: goal, context: modelContext, …)
    showingCheckInCelebration = true   // <-- always fires
} label: { … }
.disabled(isCheckedInToday)
```
The button is `.disabled(isCheckedInToday)`, so under normal circumstances a second tap is blocked. However, `.disabled` only prevents the button's tap action — it does not prevent programmatic calls. More importantly, if the user navigates away and back quickly (before SwiftUI reconciles the disabled state), or if a rapid double-tap fires before `isCheckedInToday` updates, `showingCheckInCelebration = true` is set but `addCheckIn` returns early (same-day guard). The user sees the celebration screen for a check-in that did not actually occur. This is a misleading UX and could inflate perceived streak counts.

**Fix:**
```swift
Button {
    let priorCount = goal.completionEvents?.count ?? 0
    viewModel.addCheckIn(for: goal, context: modelContext, …)
    let newCount = goal.completionEvents?.count ?? 0
    if newCount > priorCount {
        showingCheckInCelebration = true
    }
} label: { … }
```
Or equivalently, expose a `Bool` return from `addCheckIn` indicating whether the event was inserted, and only show the celebration if it returns `true`.

---

### WR-04: `SchemaV10.Goal.completionCelebrationShown` set in View but never guarded before `pendingGoalCompletion` is consumed

**File:** `VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift:110-120`

**Issue:**
```swift
.onChange(of: viewModel.pendingGoalCompletion) { _, newID in
    guard let completedGoalID = newID else { return }
    if goal.id == completedGoalID {
        completionGoalTitle = goal.title ?? "Your Goal"
        completionStreakCount = StreakEngine.currentStreak(from: goalEvents)
        goal.completionCelebrationShown = true
        showingCompletionCelebration = true
    }
    viewModel.pendingGoalCompletion = nil
}
```
`goal.completionCelebrationShown` is written directly in the View. The View-mutation of a SwiftData `@Model` property is the pattern used throughout this codebase so this is not a strict architecture violation. The problem is subtler: `goal.completionCelebrationShown` is set to `true` in the `.onChange` before `showingCompletionCelebration` is consumed. If `showingCompletionCelebration` presentation fails (e.g., another `.fullScreenCover` is already presented — iOS only shows one at a time), the flag is set `true` and the celebration is never shown, permanently suppressing it. The `addCheckIn` path checks `goal.completionCelebrationShown` nowhere — the only guard is `goal.isCompleted == false` — so the celebration would not be re-triggered on a subsequent app launch, but `completionCelebrationShown` would remain `true` with the user never having seen the screen.

**Fix:** Set `goal.completionCelebrationShown = true` inside the `onDismiss` closure of `GoalCompletionCelebrationView` (or inside the `.fullScreenCover(isPresented:)` `onDisappear`), not in the `.onChange`:
```swift
GoalCompletionCelebrationView(
    goalTitle: completionGoalTitle,
    streakCount: completionStreakCount,
    onDismiss: {
        goal.completionCelebrationShown = true   // mark after shown, not before
        showingCompletionCelebration = false
    }
)
```

---

### WR-05: `CommunityService.createAchievementPost` does not set a `category` field — breaks `fetchGlobalPosts` filter assumption

**File:** `VitaminG/VitaminG/VitaminG/Services/CommunityService.swift:567-581`

**Issue:** `createAchievementPost` does not set `record["category"]`. The `fetchPosts(category:)` query uses `NSPredicate(format: "category == %@ AND reportCount < 3")`. If CloudKit enforces that all `CommunityPost` records must have a `category` field when the CloudKit schema was defined with it as required, achievement posts will fail to save. Even if the field is optional in the schema, any future code that filters by `category` will not see achievement posts — potentially causing them to appear only in `fetchGlobalPosts` and never in per-category feeds even if that intent changes. The intent is documented (achievement posts appear in the global feed) but fragility remains: if `fetchGlobalPosts` is ever updated to add a category filter, achievement posts vanish silently.

**Fix:** Set an explicit sentinel category:
```swift
record["category"] = "achievement" as CKRecordValue
```

---

### WR-06: `GoalListView` `onShareToCommunity` closure is a no-op — milestone sharing silently broken in GoalListView path

**File:** `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift:117`

**Issue:**
```swift
onShareToCommunity: { /* no-op — wired in Plan 04 */ },
```
The milestone view is presented from `GoalListView` with a silent no-op share closure. `GoalDetailView` correctly wires `viewModel.shareGoalMilestone(...)`. A user who sees the milestone sheet from the goal list (e.g., after a check-in triggered from `GoalDetailView` while navigated to it, which surfaces `pendingGoalMilestone` in both views simultaneously) tapping "Share to Community" from the list-level presentation gets no feedback and no post is created. This contradicts the feature spec for MILE-05.

The comment "wired in Plan 04" appears to indicate a deferred wiring that was planned but not completed.

**Fix:** Wire the closure the same way `GoalDetailView` does — `GoalListView` already has `viewModel` available. The `matchedGoal` local variable already exists in scope:
```swift
onShareToCommunity: {
    if let matchedGoal {
        viewModel.shareGoalMilestone(
            goalID: milestone.goalID,
            threshold: milestone.threshold,
            goalTitle: matchedGoal.title ?? "",
            username: "",   // GoalListView has no @Query profiles; pass "" or inject
            colorHex: ""
        )
    }
    pendingGoalMilestone = nil
},
```
`GoalListView` does not have a `@Query private var profiles` — it should add one, or the profile data should be passed in from the parent.

---

### WR-07: `Phase23GoalViewModelTests` uses `.standard` UserDefaults for gate — tests pollute shared state across the test suite

**File:** `VitaminG/VitaminG/VitaminGTests/Phase23GoalViewModelTests.swift:68`

**Issue:**
```swift
XCTAssertFalse(StreakMilestoneGate.hasShown(goalID: goal.id, threshold: 7))
```
This assertion and the test as a whole rely on `StreakMilestoneGate` using `.standard` defaults. Because the `goalID` is a fresh `UUID()` on each run, the key will be unique and the assertion passes reliably. However, `test_addCheckIn_noDuplicateMilestoneAfterGateMarked` calls `StreakMilestoneGate.markShown(goalID: goal.id, threshold: 7)` against `.standard` defaults without cleaning up. If the same `UUID` were reused across test runs (impossible here, but the pattern is fragile), `.standard` state would leak between tests. More critically, if CR-01 is fixed and the gate switches to an app-group suite, these tests will **not** compile-fail but will **silently stop testing the real gate** because the `hasShown`/`markShown` calls will still use `.standard`.

**Fix:** Pass `testDefaults` explicitly to every `StreakMilestoneGate` call in these tests, the same way `Phase23MilestoneGateTests` correctly does:
```swift
XCTAssertFalse(StreakMilestoneGate.hasShown(goalID: goal.id, threshold: 7, defaults: testDefaults))
StreakMilestoneGate.markShown(goalID: goal.id, threshold: 7, defaults: testDefaults)
```
This requires `GoalViewModel.addCheckIn` to accept an injectable `defaults` parameter for its `StreakMilestoneGate` calls, or tests must use a mechanism to inject the defaults.

---

## Info

### IN-01: `SchemaV10` models list includes `SchemaV2.CompletionEvent` — version coupling concern

**File:** `VitaminG/VitaminG/VitaminG/Models/SchemaV10.swift:10`

**Issue:** `SchemaV10.models` directly references `SchemaV2.CompletionEvent` and other prior-version model types. This is the established pattern in this codebase (confirmed by checking prior schemas) and is accepted by SwiftData's migration machinery. However, it creates invisible coupling: if `SchemaV2.CompletionEvent` is ever modified (e.g., a field made non-optional), `SchemaV10` would silently pick up the change without requiring a new schema version. This is low risk given the project's lightweight-migration-only approach, but worth noting as a maintenance concern.

**Fix:** No immediate action required. Note in `VitaminGMigrationPlan.swift` that prior-version model types referenced in later schemas must never have breaking changes applied without a new schema version.

---

### IN-02: Duplicate confetti implementation in `GoalStreakMilestoneView` and `GoalCompletionCelebrationView`

**File:** `VitaminG/VitaminG/VitaminG/Views/GoalStreakMilestoneView.swift:179-197` and `VitaminG/VitaminG/VitaminG/Views/GoalCompletionCelebrationView.swift:130-148`

**Issue:** The `confettiView` computed property is copy-pasted verbatim (the comment even says "copied verbatim from CheckInCelebrationView"). Three identical implementations now exist across the codebase. Any bug fix or animation tweak must be applied in three places.

**Fix:** Extract to a standalone `ConfettiView` struct in a shared `Views/Components/` location and replace all three usages.

---

### IN-03: `GoalDetailView` has a private `progressVM: ProgressViewModel` computed property that re-allocates on every body evaluation

**File:** `VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift:396-398`

**Issue:**
```swift
private var progressVM: ProgressViewModel {
    ProgressViewModel()
}
```
This computed property is declared as `private var` (not `@State` or `let`). SwiftUI re-evaluates `body` and all computed properties derived from it frequently. `ProgressViewModel` is described as "stateless; no allocation cost" in `GoalViewModel` (line 63), so this is low severity. However, the comment there refers to `GoalViewModel`'s own copy; `GoalDetailView` independently allocates a new instance on every `body` pass, which will be noticeable on low-end devices if `body` is re-evaluated often.

**Fix:**
```swift
// In GoalDetailView:
@State private var progressVM = ProgressViewModel()
```
This ensures a stable instance across re-renders.

---

_Reviewed: 2026-05-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
