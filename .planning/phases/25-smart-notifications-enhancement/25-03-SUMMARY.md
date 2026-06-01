---
plan: 25-03
phase: 25-smart-notifications-enhancement
status: complete
completed: 2026-06-01
wave: 3
---

# Plan 25-03 Summary — Caller Wiring + SettingsView Suggestion Banner

## Objective

Close the cascade from Plan 02's signature change and ship the NOTIF-03 suggestion banner. Wired GoalViewModel.addCheckIn to record check-in hours, updated all stale callers of reschedule() to the new 2-parameter signature, retired the standalone scheduleGlobalStreakAtRiskNudge launch call, and added SettingsView .onAppear modal analysis with conditional suggestion banner.

## What Was Built

### GoalViewModel.swift
- `addCheckIn`: now calls `NotificationPreferences.appendCheckInHour(Calendar.current.component(.hour, from: Date()))` synchronously before the `cancelGlobalStreakAtRiskNudge` Task — satisfies NOTIF-03 (D-09)
- `rescheduleNotification`: now fetches all `CompletionEvent` records via `FetchDescriptor<CompletionEvent>()` and passes them to `reschedule(activeGoals:completionEvents:)` — enables streak-aware tone selection on every goal mutation

### VitaminGApp.swift
- Launch reschedule call cleaned up: `reschedule(activeGoals: [], completionEvents: [])` (correct — no events fetched at launch)
- Removed standalone `scheduleGlobalStreakAtRiskNudge()` launch call — `schedule()` now schedules the one-shot internally via `scheduleOneShotStreakAtRisk`

### SettingsView.swift
- Added `@State private var showNudgeSuggestion: Bool = false`
- Added `@State private var suggestedHour: Int = 0`
- `.onAppear`: computes `NotificationPreferences.modalCheckInHour()`, shows banner when `|modal - current| >= 2` AND `!nudgeSuggestionDismissed`
- `nudgeSuggestionBanner` @ViewBuilder: displays suggested time, Apply and X buttons
  - Apply: saves new hour via `NotificationPreferences.save`, updates `notificationTime` @State, calls `reschedule(activeGoals:completionEvents:)`, marks dismissed, hides banner
  - X: marks dismissed, hides banner (no scheduler call)
- Banner never reappears after Apply or X (persisted via App Group UserDefaults `nudgeSuggestionDismissed` key)
- Wired remaining `completionEvents: []` stubs in `.onChange` and `authorizationRow` to `Array(allEvents)`

## Commits
- `7b1edaa` feat(25-03): wire GoalViewModel addCheckIn hour append and reschedule completionEvents
- `a7cb8dc` feat(25-03): update VitaminGApp launch reschedule signature, remove standalone scheduleGlobalStreakAtRiskNudge call
- `423f496` feat(25-03): add SettingsView modal check-in hour suggestion banner with Apply/X handlers

## Build Verification
- `xcodebuild -scheme VitaminG -destination "platform=iOS Simulator,name=iPhone 17" build` → **BUILD SUCCEEDED** (3 pre-existing warnings, 0 errors)

## Self-Check: PASSED

### Must-Haves Verified
- [x] GoalViewModel.addCheckIn writes check-in hour to NotificationPreferences.appendCheckInHour before cancelGlobalStreakAtRiskNudge
- [x] GoalViewModel.rescheduleNotification fetches activeGoals and completionEvents, passes both to reschedule(activeGoals:completionEvents:)
- [x] VitaminGApp launch calls reschedule(activeGoals: [], completionEvents: []) with no standalone scheduleGlobalStreakAtRiskNudge call
- [x] SettingsView .onAppear computes modalCheckInHour, shows banner when |modal - current| >= 2 AND !nudgeSuggestionDismissed
- [x] Banner row above DatePicker with Apply and X dismiss buttons
- [x] Apply writes new time, fires reschedule, marks dismissed, updates notificationTime @State
- [x] X marks dismissed, hides banner, no scheduler call
- [x] Banner never reappears once Apply or X tapped

## Human Verification Required

The following behaviors require manual testing in the simulator:

1. **NOTIF-01**: Morning notification body starts with a streak-appropriate message (celebratory ≥7, building 1-6, encouraging 0)
2. **NOTIF-02**: Notification body includes up to 2 active goal titles below the tone message
3. **NOTIF-03**: After sufficient check-ins at a consistent hour, SettingsView shows the suggestion banner when modal hour differs from current by ≥2; Apply updates time picker and hides banner permanently
4. **NOTIF-04**: At launch (before 19:00), a one-shot notification scheduled at 7 PM with repeats=false; cap guard prevents scheduling when 60+ pending requests exist
