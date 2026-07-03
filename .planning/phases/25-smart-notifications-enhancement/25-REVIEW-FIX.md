---
phase: 25-smart-notifications-enhancement
fixed_at: 2026-06-01T00:00:00Z
review_path: .planning/phases/25-smart-notifications-enhancement/25-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 25: Code Review Fix Report

**Fixed at:** 2026-06-01
**Source review:** `.planning/phases/25-smart-notifications-enhancement/25-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 5 (2 Critical, 3 Warning)
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: "0-day run alive" sent to users with no streak yet

**Files modified:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift`
**Commit:** `9529e41`
**Applied fix:** Added `if streak > 0` guard inside the `if let topTitle` branch of `scheduleOneShotStreakAtRisk`. When streak == 0 and a goal title is present, the body now reads "You haven't started your \(topTitle) streak yet — check in today." instead of the nonsensical "0-day run alive" copy. The `streak > 0` branch retains the original at-risk wording. The `else` (no title) branch is unchanged.

---

### CR-02: SettingsView says "up to 3 goal titles" but code caps at 2

**Files modified:** `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift`, `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift`
**Commit:** `7d64a8c`
**Applied fix (Option A — code is correct, UI is wrong):**
- `SettingsView.swift` line 136: changed "up to 3" to "up to 2" in the explanatory `Text` view.
- `NotificationScheduler.swift` line 11 doc comment: updated "up to 3" to "up to 2" to match the actual `.prefix(2)` in `makeContent`. `NotificationSchedulerTests.swift` already asserts exactly 2 newlines, so no test changes were needed.

---

### WR-01: Dead code `scheduleGlobalStreakAtRiskNudge` is unreachable in production

**Files modified:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift`, `VitaminG/VitaminG/VitaminGTests/Phase23NotificationTests.swift`
**Commit:** `42a6e67`
**Applied fix:** Verified with grep that `scheduleGlobalStreakAtRiskNudge` had zero production callers (only `Phase23NotificationTests.swift` called it). Deleted both the no-arg entry point and the `pendingCount:` overload from the Phase 23 extension in `NotificationScheduler.swift`. `cancelGlobalStreakAtRiskNudge` and `globalStreakAtRiskIdentifier` were preserved — they remain in active use by `GoalViewModel` and the one-shot path. Updated `Phase23NotificationTests.swift` to replace the deleted-function test with an equivalent cap-guard test for `scheduleOneShotStreakAtRisk`.

Note: WR-01 and WR-02 were committed together because the updated Phase23 test calls `scheduleOneShotStreakAtRisk` with the `currentHour:` parameter introduced by WR-02.

---

### WR-02: Test silently skips after 7 PM due to wall-clock dependency

**Files modified:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift`, `VitaminG/VitaminG/VitaminGTests/NotificationSchedulerPhase25Tests.swift`, `VitaminG/VitaminG/VitaminGTests/Phase23NotificationTests.swift`
**Commit:** `42a6e67`
**Applied fix:** Added `currentHour: Int? = nil` parameter to `scheduleOneShotStreakAtRisk`. Inside the function, the guard now uses `let hour = currentHour ?? Calendar.current.component(.hour, from: Date())` so production behaviour is unchanged while tests inject a fixed value. Updated both Phase25 test call sites (`test_schedule_oneShotStreakAtRisk_repeats_false` and `test_schedule_oneShotSkipped_atCapBoundary`) to pass `currentHour: 8`, eliminating the silent post-7-PM skip. The Phase23 replacement test also passes `currentHour: 8`.

---

### WR-03: Nudge suggestion uses linear difference instead of circular clock distance

**Files modified:** `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift`
**Commit:** `3143bba`
**Applied fix:** Replaced `if abs(modal - currentHour) >= 2` with two-step circular distance calculation:
```swift
let diff = abs(modal - currentHour)
let circularDiff = min(diff, 24 - diff)
if circularDiff >= 2 {
```
This correctly handles midnight-straddling cases (e.g., modal=0, setting=23 → circularDiff=1, no banner shown; previously linear diff was 23 and banner was incorrectly shown).

---

## Skipped Issues

None — all in-scope findings were successfully fixed.

---

_Fixed: 2026-06-01_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
