---
phase: 25-smart-notifications-enhancement
verified: 2026-06-01T00:00:00Z
status: gaps_found
score: 3/4 must-haves verified
overrides_applied: 0
gaps:
  - truth: "SettingsView .onAppear computes modalCheckInHour and shows the suggestion banner when |modal - current| >= 2 AND !nudgeSuggestionDismissed, gated on >= 14 check-in history entries"
    status: partial
    reason: "The banner display logic is implemented but the D-10 guard requiring checkInHourHistory().count >= 14 before running modal analysis is absent. Without this guard the banner can appear after even a single check-in, violating NOTIF-03, ROADMAP SC-3, and the 25-03 Plan acceptance criterion line 292."
    artifacts:
      - path: "VitaminG/VitaminG/VitaminG/Views/SettingsView.swift"
        issue: "onAppear block is missing `guard NotificationPreferences.checkInHourHistory().count >= 14 else { return }` before the modal analysis. The .onAppear block at lines 226-233 goes directly to `modalCheckInHour()` without the count check."
    missing:
      - "Add `guard NotificationPreferences.checkInHourHistory().count >= 14 else { return }` immediately before the `if !NotificationPreferences.nudgeSuggestionDismissed` block in SettingsView .onAppear (D-10 guard)"
human_verification:
  - test: "NOTIF-01 tone tier — morning notification copy"
    expected: "User with streak >= 7 receives celebratory copy; user with streak 1–6 receives neutral-building copy; user with streak 0 or broken receives encouraging copy. All determined from local StreakEngine, no network call."
    why_human: "Requires triggering a real UNCalendarNotificationTrigger through the iOS notification system; cannot verify delivered content via grep"
  - test: "NOTIF-02 goal-title injection — notification body format"
    expected: "Notification body shows tone message on the first line, then up to 2 active goal titles on subsequent lines (newline-separated). Completed goals are excluded."
    why_human: "Requires triggering a real notification and reading the delivered banner text on a device or simulator"
  - test: "NOTIF-03 suggestion banner — after 14 check-ins at consistent hour"
    expected: "After seeding 14 check-in history entries at hour 7 and setting the notification time to 11 AM (diff >= 2), opening SettingsView shows the suggestion banner above the DatePicker. Tapping Apply updates the DatePicker immediately to 7:00 AM, hides the banner, and re-opening SettingsView does NOT show the banner again. Tapping X hides the banner without changing the time, and re-opening also does NOT show the banner."
    why_human: "Requires seeding App Group UserDefaults and manual UI interaction; banner rendering and persistent dismissal cannot be verified programmatically"
  - test: "NOTIF-04 one-shot 7 PM cancellation on check-in"
    expected: "Before 19:00, opening SettingsView triggers reschedule, which schedules a pending notification with identifier globalStreakAtRiskIdentifier and repeats=false at 19:00. Checking in via any path (iOS, widget) causes the alert to disappear from the pending notification list."
    why_human: "Requires confirming pending notification list state before and after a check-in in a running simulator"
---

# Phase 25: Smart Notifications Enhancement Verification Report

**Phase Goal:** Users receive daily notifications that know who they are — referencing their actual goal titles, adapting tone to their streak health, alerting them in the evening only when a streak is genuinely at risk, and surfacing a nudge-time suggestion when the app detects a systematic mismatch between their check-in patterns and their current notification schedule
**Verified:** 2026-06-01
**Status:** gaps_found
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Morning notification copy bank adapts to streak tier: celebratoryCopy (>=7), neutralBuildingCopy (1–6), encouragingCopy (0/broken) | VERIFIED | `NotificationScheduler.swift` lines 25–64: three named static arrays (5 entries each), `copyBank(for:)` helper with correct tier thresholds, `makeContent(activeGoals:currentStreak:)` at line 70 selects bank via dayOfYear rotation |
| 2 | Notification body contains up to 2 active non-completed goal titles, newline-separated below tone message | VERIFIED | `makeContent` lines 78–90: filters isCompleted, compactMap title, filter empty, prefix(2); joins with "\n"; falls back to tone-only when no active goals |
| 3 | SettingsView shows suggestion banner when modal check-in hour differs from current notification hour by >= 2, and has not been dismissed; banner requires >= 14 check-in history entries (D-10 / NOTIF-03 / ROADMAP SC-3) | FAILED | Banner logic wired (`.onAppear` at lines 226–233, `nudgeSuggestionBanner` @ViewBuilder at lines 285–333), but the D-10 guard `checkInHourHistory().count >= 14` is absent. Banner fires after any single check-in with a sufficient modal/current hour delta. This violates NOTIF-03 and ROADMAP SC-3. |
| 4 | scheduleOneShotStreakAtRisk schedules a `repeats: false` UNCalendarNotificationTrigger at 19:00 with cap guard and evening-skip guard; cancelled on check-in via cancelGlobalStreakAtRiskNudge | VERIFIED | `NotificationScheduler.swift` lines 160–222: evening-skip guard (`currentHour < 19`), 60-slot cap guard, remove-before-add (`removePendingNotificationRequests([globalStreakAtRiskIdentifier])`), `UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: 19, minute: 0), repeats: false)`. `GoalViewModel.swift` line 222: `cancelGlobalStreakAtRiskNudge()` called after check-in. |

**Score:** 3/4 truths verified

### Deferred Items

None.

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift` | checkInHourHistoryKey, nudgeSuggestionDismissedKey, appendCheckInHour, checkInHourHistory, modalCheckInHour, nudgeSuggestionDismissed, markNudgeSuggestionDismissed | VERIFIED | All 7 new members present at lines 104–175; all read/write through `UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")` |
| `VitaminG/VitaminGTests/NotificationSchedulerPhase25Tests.swift` | 14 test functions, @MainActor, @testable import VitaminG | VERIFIED | File exists; 14 test functions confirmed; class declaration matches plan requirements |
| `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` | celebratoryCopy, neutralBuildingCopy, encouragingCopy, makeContent(activeGoals:currentStreak:), schedule(hour:minute:activeGoals:completionEvents:), reschedule(activeGoals:completionEvents:), scheduleOneShotStreakAtRisk | VERIFIED | All symbols present; old `inspirationalMessages` absent; old 3-param `schedule` and 1-param `reschedule` overloads absent |
| `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` | appendCheckInHour call in addCheckIn, FetchDescriptor<CompletionEvent> in rescheduleNotification | VERIFIED | `appendCheckInHour` at line 218 (before `cancelGlobalStreakAtRiskNudge` at line 222 — ordering correct per D-09); `FetchDescriptor<CompletionEvent>()` at line 376; `reschedule(activeGoals:completionEvents:)` at line 379 |
| `VitaminG/VitaminG/VitaminG/VitaminGApp.swift` | reschedule(activeGoals:[], completionEvents:[]), no standalone scheduleGlobalStreakAtRiskNudge call | VERIFIED | Line 113: `reschedule(activeGoals: [], completionEvents: [])` confirmed; grep of VitaminGApp.swift shows zero `scheduleGlobalStreakAtRiskNudge` calls |
| `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift` | showNudgeSuggestion @State, nudgeSuggestionBanner @ViewBuilder, onAppear modal analysis, Apply/X handlers, updated reschedule calls | PARTIAL | @State vars present (lines 56–57); banner @ViewBuilder present (lines 285–333); Apply writes time, marks dismissed, hides banner (lines 306–314); X marks dismissed, hides banner (lines 322–323); both reschedule call sites pass `completionEvents: Array(allEvents)` (lines 128, 252). MISSING: the D-10 guard `checkInHourHistory().count >= 14` in `.onAppear`. |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `GoalViewModel.addCheckIn` | `NotificationPreferences.appendCheckInHour` | synchronous call before cancelGlobalStreakAtRiskNudge Task | WIRED | Line 218 calls `appendCheckInHour(Calendar.current.component(.hour, from: Date()))` synchronously; line 222 has the cancel Task |
| `SettingsView.onAppear` | `NotificationPreferences.modalCheckInHour()` | modal analysis gated on !nudgeSuggestionDismissed | PARTIAL | Modal call at line 227 is present and gated on `!nudgeSuggestionDismissed`. Missing: the `checkInHourHistory().count >= 14` pre-check from D-10 |
| `SettingsView Apply` | `NotificationScheduler.shared.reschedule(activeGoals:completionEvents:)` | fire-and-forget Task with new signature | WIRED | Line 314: `Task { await NotificationScheduler.shared.reschedule(activeGoals: Array(activeGoals), completionEvents: Array(allEvents)) }` |
| `VitaminGApp launch` | `NotificationScheduler.shared.reschedule(activeGoals: [], completionEvents: [])` | direct call, scheduleGlobalStreakAtRiskNudge removed | WIRED | Line 113 confirmed; scheduleGlobalStreakAtRiskNudge absent from VitaminGApp.swift |
| `schedule(hour:minute:activeGoals:completionEvents:)` | `StreakEngine.currentStreak(from:)` | in-method call to compute tone tier | WIRED | `NotificationScheduler.swift` line 118: `let streak = StreakEngine.currentStreak(from: completionEvents)` |
| `schedule()` | `scheduleOneShotStreakAtRisk` | follow-up call after morning notification add succeeds | WIRED | Lines 129–130: called inside the `do` block after `try await center.add(request)` |
| `scheduleOneShotStreakAtRisk` | `removePendingNotificationRequests([globalStreakAtRiskIdentifier])` | remove-before-add invariant | WIRED | Line 187: remove-before-add present in `scheduleOneShotStreakAtRisk`; line 631: `cancelGlobalStreakAtRiskNudge` also removes via same identifier |

---

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `makeContent(activeGoals:currentStreak:)` | `currentStreak` | `StreakEngine.currentStreak(from: completionEvents)` called in `schedule()` | Yes — real CompletionEvent array from SwiftData fetch | FLOWING |
| `makeContent(activeGoals:currentStreak:)` | `activeGoals` titles | `GoalViewModel.rescheduleNotification` FetchDescriptor<Goal> from ModelContext | Yes — real Goal objects fetched at reschedule time | FLOWING |
| `SettingsView nudgeSuggestionBanner` | `suggestedHour` | `NotificationPreferences.modalCheckInHour()` from App Group UserDefaults history | Yes — real FIFO history via `appendCheckInHour` in `addCheckIn` | FLOWING |
| `scheduleOneShotStreakAtRisk` | `topTitle` / `streak` | `activeGoals` and `streak` passed through `schedule()` from `reschedule()` call chain | Yes — same active goals array fetched from SwiftData | FLOWING |

---

## Behavioral Spot-Checks

Step 7b: SKIPPED — production code runs inside an iOS simulator; no runnable entry points accessible without launching Xcode. Test results are the closest proxy available.

---

## Probe Execution

Step 7c: No probe scripts found or declared for this phase.

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| NOTIF-01 | 25-02 | Morning notification copy tone adapts to streak (celebratory >=7, encouraging <3 or broken, neutral in between) | SATISFIED | Three copy banks with 5 entries each in `NotificationScheduler.swift`; `copyBank(for:)` correctly routes by tier; `makeContent` applies day-of-year rotation within bank |
| NOTIF-02 | 25-02 | Morning notification body references up to 2 active goal titles | SATISFIED | `makeContent` filters non-completed goals, takes prefix(2), joins with "\n" below tone message |
| NOTIF-03 | 25-01, 25-03 | App analyses last 14 check-in timestamps; if modal hour differs from nudge time by 2+ hours, shows non-intrusive Settings banner | BLOCKED | Modal analysis implemented in SettingsView `.onAppear`; `appendCheckInHour` called from `addCheckIn`; but the "last 14 days" data requirement guard (`checkInHourHistory().count >= 14`) is missing from `.onAppear`. Banner can appear after even 1 check-in. ROADMAP SC-3, REQUIREMENTS.md NOTIF-03, and 25-03 PLAN acceptance criterion (line 292) all require the 14-entry minimum before the banner shows. |
| NOTIF-04 | 25-02, 25-03 | Each morning when daily nudge fires, schedules a second UNCalendarNotificationTrigger at 7 PM (repeats: false); cancelled on check-in | SATISFIED | `scheduleOneShotStreakAtRisk` with `repeats: false` trigger at `{hour: 19, minute: 0}`; cap guard (60 slots); evening-skip guard; remove-before-add; cancelled via `cancelGlobalStreakAtRiskNudge()` in `addCheckIn` |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift` | 135 | Stale UI copy: "up to 3 of your active goal titles" — NOTIF-02 caps at 2 titles, not 3 | Warning | Misleads user about notification content; not a logic error but copy was not updated when the 2-goal cap was introduced in Plan 02 |
| `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` | 583–625 | `scheduleGlobalStreakAtRiskNudge()` — dead code; no call sites remain after VitaminGApp launch caller was removed in Plan 03 | Warning | Acknowledged in T-25-03-05 as deferred cleanup; method is benign and has no active callers in production code |

---

## Human Verification Required

### 1. NOTIF-01 Tone Tier Delivery

**Test:** Trigger a morning notification with streak >= 7 (advance simulator clock 7+ days with one check-in each day). Read the delivered notification body.
**Expected:** Body starts with one of the `celebratoryCopy` messages. Repeat with streak 3 → body starts with `neutralBuildingCopy`. Repeat with streak 0 → body starts with `encouragingCopy`.
**Why human:** Requires a real UNCalendarNotificationTrigger delivery through the iOS notification system; grep cannot verify delivered banner content.

### 2. NOTIF-02 Goal-Title Body Format

**Test:** Create two active non-completed goals "Drink water" and "Walk daily". Trigger the morning notification.
**Expected:** Notification body is three lines: tone message, "Drink water", "Walk daily" (newline-separated). Completing one goal and re-triggering shows only the remaining goal title.
**Why human:** Requires reading the delivered notification banner content on simulator.

### 3. NOTIF-03 Suggestion Banner Full Flow (after gap fix)

**Note:** This check should only be run after the missing `checkInHourHistory().count >= 14` guard is added to SettingsView `.onAppear`. Without the fix, the banner may appear prematurely.

**Test:** Seed 14 App Group UserDefaults entries for `checkInHourHistory` all at hour 7. Set notification time to 11:00 AM in SettingsView. Close and reopen SettingsView.
**Expected:** A banner appears above the DatePicker reading approximately "You usually check in around 7:00 AM. Switch your reminder to match?" with Apply and X buttons. Tap Apply: DatePicker immediately shows 7:00 AM, banner disappears, reopening Settings does not show the banner again. Independently seed fresh state and tap X: banner disappears, time unchanged, reopening Settings does not show banner.
**Why human:** Requires seeding App Group UserDefaults directly and interacting with the live SwiftUI View.

### 4. NOTIF-04 One-Shot Cancel on Check-In

**Test:** Open SettingsView before 19:00 (which triggers reschedule → scheduleOneShotStreakAtRisk). Inspect pending notifications and confirm a request with identifier `com.kyleharrington.VitaminG.streakAtRisk.global` exists with `repeats=false` at 19:00. Check in on any goal via the iOS app.
**Expected:** After check-in, the pending one-shot notification is removed from the pending list.
**Why human:** Requires inspecting `UNUserNotificationCenter.pendingNotificationRequests()` state before and after a check-in gesture in a running simulator.

---

## Gaps Summary

**One blocking gap:** NOTIF-03 is partially implemented but missing its data-sufficiency guard.

The SettingsView `.onAppear` correctly runs modal analysis and shows the banner when the modal check-in hour differs from the current notification hour by 2+ hours and the user has not dismissed the banner. However, the D-10 requirement that the banner only triggers after accumulating at least 14 check-in history entries is not enforced. Without this guard:

- A single check-in at hour 7 when the notification is set to 10 AM is enough to show the banner
- This violates NOTIF-03 ("App analyses the user's **last 14 days** of check-in timestamps")
- This violates ROADMAP SC-3 ("after **14 days** of consistent check-ins")
- This violates 25-03 PLAN acceptance criterion: "File contains substring `checkInHourHistory().count >= 14`"
- The human UAT in 25-03 PLAN expects "after 14 check-ins" before the banner shows

**Fix required:** Add `guard NotificationPreferences.checkInHourHistory().count >= 14 else { return }` (or equivalent `if` block early-exit) inside the `.onAppear` NOTIF-03 analysis block, immediately before the `if !NotificationPreferences.nudgeSuggestionDismissed` check.

A secondary non-blocking issue: the static text in the Daily Reminder section (`SettingsView` line 135) still reads "up to 3 of your active goal titles" when NOTIF-02 caps at 2. This is a cosmetic copy error, not a logic or requirement failure.

---

_Verified: 2026-06-01T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
