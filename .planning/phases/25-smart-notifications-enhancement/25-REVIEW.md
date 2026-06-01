---
phase: 25-smart-notifications-enhancement
reviewed: 2026-06-01T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift
  - VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift
  - VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
  - VitaminG/VitaminG/VitaminG/Views/SettingsView.swift
  - VitaminG/VitaminG/VitaminG/VitaminGApp.swift
  - VitaminG/VitaminG/VitaminGTests/NotificationSchedulerPhase25Tests.swift
  - VitaminG/VitaminG/VitaminGTests/NotificationSchedulerTests.swift
findings:
  critical: 2
  warning: 3
  info: 2
  total: 7
status: issues_found
---

# Phase 25: Code Review Report

**Reviewed:** 2026-06-01
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Phase 25 introduces the NOTIF-03 check-in hour history/modal analysis, the nudge suggestion banner in SettingsView, a one-shot 7 PM streak-at-risk alert embedded inside `schedule()`, and tone-adaptive notification copy banks. The new `NotificationPreferences` helpers (`appendCheckInHour`, `modalCheckInHour`, `nudgeSuggestionDismissed`) are solid and well-tested. The App Group write discipline and tamper-filtering in `modalCheckInHour` are correct.

Two user-visible defects survive into production: a nonsensical "0-day run" string in the at-risk notification body, and a stale comment in `SettingsView` that tells users they will see up to 3 goal titles when the code caps at 2. There is also dead production code (`scheduleGlobalStreakAtRiskNudge`) that was superseded by the Phase 25 `scheduleOneShotStreakAtRisk` path but never removed, and a test that silently skips its core assertion when run after 7 PM.

---

## Critical Issues

### CR-01: "0-day run alive" sent to users who have no streak yet

**File:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift:198`

**Issue:** `scheduleOneShotStreakAtRisk` builds the alert body with string interpolation:

```swift
content.body = "Your \(topTitle) streak is at risk — check in to keep your \(streak)-day run alive."
```

`streak` is the value passed in from `schedule()`, which calls `StreakEngine.currentStreak(from: completionEvents)`. When a new user creates their first goal but has never completed a check-in, `streak = 0` and `topTitle` is non-nil (the goal title is present). The alert body becomes:

> "Your Meditate streak is at risk — check in to keep your **0-day** run alive."

The "0-day run" phrasing is nonsensical and erodes trust. The `else` branch at line 200 handles the case where `topTitle` is `nil`, but there is no guard for `streak == 0` when a topTitle exists. Both `GoalViewModel.rescheduleNotification` (which passes live goals and all events) and the `VitaminGApp` launch path (which passes `[]` for both — streak also 0, but topTitle nil there) can produce this state in normal use.

**Fix:**
```swift
if let topTitle {
    if streak > 0 {
        content.body = "Your \(topTitle) streak is at risk — check in to keep your \(streak)-day run alive."
    } else {
        content.body = "You haven't started your \(topTitle) streak yet — check in today."
    }
} else {
    content.body = "You haven't checked in today — keep your streak alive."
}
```

---

### CR-02: SettingsView tells users "up to 3 goal titles" but `makeContent` caps at 2

**File:** `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift:136`

**Issue:** The user-facing explanatory text in SettingsView reads:

> "Your notification will include up to **3** of your active goal titles as a daily reminder."

The actual implementation in `NotificationScheduler.makeContent` uses `.prefix(2)` (line 83 of `NotificationScheduler.swift`), limiting goal titles to two. The file-level doc comment on `NotificationScheduler` also says "up to 3" (line 11) — a stale remnant. Users who see the settings explanation and check their notifications will observe only two goal titles, not three. This is a direct user-visible lie in the UI.

**Fix — choose one and make all three sites consistent:**

Option A (code is correct, UI is wrong): change SettingsView line 136 to "up to 2":
```swift
Text("Your notification will include up to 2 of your active goal titles as a daily reminder.")
```
And update `NotificationScheduler.swift` line 11 doc comment to "up to 2".

Option B (UI intent is correct, code is wrong): change `NotificationScheduler.swift` line 83 to `.prefix(3)` and update tests in `NotificationSchedulerTests.swift` (lines 47–53) that assert exactly 2 newlines.

---

## Warnings

### WR-01: `scheduleGlobalStreakAtRiskNudge` is unreachable dead code in production

**File:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift:583-633`

**Issue:** `scheduleGlobalStreakAtRiskNudge()` and its `pendingCount:` overload are never called from any production file in the app target. A grep of the entire source tree shows only one call site: `Phase23NotificationTests.swift`. Meanwhile, Phase 25 introduced `scheduleOneShotStreakAtRisk` (called from `schedule()` on line 130), which supersedes the Phase 23 repeating nudge for the same `globalStreakAtRiskIdentifier`. Both functions write to the same identifier — one with `repeats: true`, one with `repeats: false` — so any future caller of `scheduleGlobalStreakAtRiskNudge` would silently replace a one-shot notification registered by `schedule()` with a repeating one. The dead code also has different notification copy ("Life happened?") vs the Phase 25 personalized copy, creating a maintenance hazard.

**Fix:** Delete `scheduleGlobalStreakAtRiskNudge()` and its overload. Update `Phase23NotificationTests.swift` to test `scheduleOneShotStreakAtRisk` instead. If repeating global nudge behavior is ever needed again, it should use a distinct identifier to avoid colliding with the one-shot path.

---

### WR-02: `test_schedule_oneShotStreakAtRisk_repeats_false` silently skips its core assertion at runtime after 7 PM

**File:** `VitaminG/VitaminG/VitaminGTests/NotificationSchedulerPhase25Tests.swift:115-127`

**Issue:** `scheduleOneShotStreakAtRisk` has an early-return guard at line 164 of `NotificationScheduler.swift`:

```swift
let currentHour = Calendar.current.component(.hour, from: Date())
guard currentHour < 19 else { return }
```

When the test runs after 7 PM, this guard fires and no notification is added. The test then finds `request == nil` and calls `XCTSkipIf`, silently passing. The test passes in CI if the CI job runs after 7 PM local time of the test host, giving false confidence that the trigger configuration is correct. The `pendingCount: 0` injection bypasses the cap guard correctly, but there is no equivalent injection for the time-of-day guard.

**Fix:** Add a `currentHour` injection parameter analogous to `pendingCount`:

```swift
func scheduleOneShotStreakAtRisk(
    activeGoals: [Goal],
    streak: Int,
    pendingCount: Int? = nil,
    currentHour: Int? = nil
) async {
    let hour = currentHour ?? Calendar.current.component(.hour, from: Date())
    guard hour < 19 else { return }
    // ...
}
```

The test then passes `currentHour: 8` to always exercise the scheduling path regardless of wall-clock time.

---

### WR-03: Nudge suggestion threshold uses linear difference rather than circular clock distance

**File:** `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift:229`

**Issue:** The condition for showing the "Suggested Time" banner is:

```swift
if abs(modal - currentHour) >= 2 {
```

This treats hours as integers on a number line rather than on a 24-hour clock. A user whose modal check-in hour is 23 (11 PM) and whose notification is set to 1 (1 AM) has a circular distance of 2 hours — the minimum threshold — but `abs(23 - 1) = 22`, so the banner appears. Conversely, a user with modal = 0 and setting = 22 has `abs(0 - 22) = 22` despite a 2-hour circular gap. The banner correctly appears in both cases by accident of large magnitude, but the logic will also surface the suggestion for users who are only 1 clock-hour apart when the hours straddle midnight (e.g., modal=0, setting=23: `abs = 23 >= 2`).

**Fix:** Use circular distance:
```swift
let diff = abs(modal - currentHour)
let circularDiff = min(diff, 24 - diff)
if circularDiff >= 2 {
```

---

## Info

### IN-01: `toggleCompletion` does not cancel the streak-at-risk nudge after a check-in

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift:128-153`

**Issue:** `addCheckIn` correctly cancels the 7 PM streak-at-risk nudge at line 222:

```swift
Task { await NotificationScheduler.shared.cancelGlobalStreakAtRiskNudge() }
```

`toggleCompletion` (the permanent "goal achieved" path) does not call `cancelGlobalStreakAtRiskNudge`. A user who marks a goal as permanently complete via `toggleCompletion` before 7 PM will still receive a "You haven't checked in today" alert at 7 PM, which is incorrect — they did take an action on their goals that day.

**Fix:** Add the same cancellation call in `toggleCompletion` after the completion event is inserted:
```swift
Task { await NotificationScheduler.shared.cancelGlobalStreakAtRiskNudge() }
```

---

### IN-02: `scheduleOneShotStreakAtRisk` depends on daily app launch to re-register its one-shot trigger

**File:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift:160-222`

**Issue:** The one-shot 7 PM notification uses `repeats: false`. After it fires, it is consumed and will not fire the next day. Re-registration requires `schedule()` to be called, which happens on app launch (`VitaminGApp.swift` line 113) or any goal mutation. A user who never opens the app (e.g., relies entirely on widgets and habit) will not receive the 7 PM reminder on any day they don't launch the app. This is a fragile delivery model for what is described as a reliable daily nudge.

This is noted as a design constraint ("one-shot" in D-05), so this finding is informational rather than requiring an immediate code change. If reliable daily delivery is intended, switching to `repeats: true` (matching the behavior of `scheduleGlobalStreakAtRiskNudge`) and adding a cancellation-on-check-in is a more robust pattern.

---

_Reviewed: 2026-06-01_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
