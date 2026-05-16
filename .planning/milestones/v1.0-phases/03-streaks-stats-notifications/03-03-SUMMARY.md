---
phase: 03-streaks-stats-notifications
plan: 03
subsystem: notifications
status: completed
tasks_completed: 2
files_modified:
  created:
    - VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift
    - VitaminG/VitaminG/VitaminG/Services/NotificationDelegate.swift
    - VitaminG/VitaminG/VitaminG/Views/SettingsView.swift
    - VitaminG/VitaminG/VitaminGTests/NotificationSchedulerTests.swift
  modified:
    - VitaminG/VitaminG/VitaminG/VitaminGApp.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
    - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
tests_added: 9
tests_passing: 9
tags: [notifications, UNUserNotificationCenter, settings, deep-link, UNCalendarNotificationTrigger]
dependency_graph:
  requires:
    - 03-01 — AppRoute.settings case, TabView structure in ContentView
  provides:
    - NotificationScheduler — daily repeating notification with personalized goal titles
    - NotificationDelegate — UNUserNotificationCenterDelegate for deep-link tap routing
    - SettingsView — DatePicker for notification time with immediate reschedule
    - GoalViewModel.rescheduleNotification — automatic reschedule on every mutation
  affects:
    - VitaminGApp.swift — router and notificationDelegate stored as properties, delegate set in init()
    - GoalViewModel.swift — rescheduleNotification called after addGoal, toggleCompletion, updateGoal, delete
    - ContentView.swift — third Settings tab added; .settings route renders SettingsView()
tech_stack:
  added:
    - UserNotifications framework (UNUserNotificationCenter, UNCalendarNotificationTrigger, UNUserNotificationCenterDelegate)
  patterns:
    - Singleton NotificationScheduler.shared for testable makeContent isolation
    - Remove-before-add pattern (removePendingNotificationRequests) stays within iOS 64-cap
    - NotificationDelegate stored as App property to prevent weak-reference deallocation
    - AppRouter stored as property so NotificationDelegate closure captures stable reference
    - rescheduleNotification(context:) fetches active goals and calls NotificationScheduler.shared.reschedule
key_files:
  created:
    - path: VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift
      role: Schedules single repeating daily notification with up to 3 active goal titles
    - path: VitaminG/VitaminG/VitaminG/Services/NotificationDelegate.swift
      role: UNUserNotificationCenterDelegate — routes "goalList" deepLink tap to AppRouter.popToRoot
    - path: VitaminG/VitaminG/VitaminG/Views/SettingsView.swift
      role: DatePicker for daily reminder time, persists to UserDefaults, reschedules on change
    - path: VitaminG/VitaminG/VitaminGTests/NotificationSchedulerTests.swift
      role: 9 unit tests covering makeContent — active goals, 3-title limit, fallback, completed exclusion, userInfo, nil/empty title, sound
  modified:
    - path: VitaminG/VitaminG/VitaminG/VitaminGApp.swift
      role: router and notificationDelegate stored as properties; delegate wired in init() before container
    - path: VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
      role: rescheduleNotification(context:) added and called after every goal mutation
    - path: VitaminG/VitaminG/VitaminG/Views/ContentView.swift
      role: Settings tab added (3 tabs total); .settings navigation destination renders SettingsView()
decisions:
  - NotificationScheduler is a singleton with makeContent as pure function for easy unit testing without mocking UNUserNotificationCenter
  - Hour clamped 0-23 and minute clamped 0-59 in schedule() — satisfies T-03-08 tamper mitigation
  - NotificationDelegate stored on App struct (not local) to prevent UNUserNotificationCenter's weak delegate reference from being deallocated
  - AppRouter stored as App property (not created inline in .environment()) so NotificationDelegate closure captures a stable reference
  - Settings exposed as a third tab rather than a toolbar button — simpler, non-invasive to GoalListView's existing toolbar
  - ContentView.swift also wires .settings AppRoute destination to SettingsView() for deep-link navigation from within the Goals stack
metrics:
  duration: "~6 minutes"
  completed_date: "2026-04-04"
next_plan_notes: |
  Plan 04 will add the WidgetKit extension. NotificationScheduler is independent — no changes needed.
  SettingsView is complete. AppRouter and ContentView are in their final Phase 3 state.
---

# Phase 03 Plan 03: Notification System Summary

**One-liner:** UNCalendarNotificationTrigger daily reminder with personalized goal titles, deep-link tap routing via NotificationDelegate, DatePicker SettingsView, and automatic reschedule on every GoalViewModel mutation.

## What Was Built

**Task 1 — NotificationScheduler + Tests**

`NotificationScheduler.swift` implements a singleton in `Services/` with:

- `makeContent(activeGoals:)` — builds `UNMutableNotificationContent` with up to 3 non-completed goal titles joined by middle-dot separator; falls back to generic message when no valid titles exist; includes `userInfo["deepLink"] = "goalList"` for tap routing (NOTIF-03, NOTIF-07).
- `schedule(hour:minute:activeGoals:)` — removes existing pending notification (remove-before-add, NOTIF-05), clamps hour/minute (T-03-08), creates `UNCalendarNotificationTrigger(dateMatching:repeats:true)` (NOTIF-02, NOTIF-04), and calls `center.add(request)`.
- `reschedule(activeGoals:)` — reads user preference from UserDefaults (defaults to 8:00 AM per NOTIF-02) and delegates to `schedule`.
- `isAuthorized()` — async check of `UNNotificationSettings.authorizationStatus` for SettingsView status display.

`NotificationSchedulerTests.swift` adds 9 unit tests covering: active goals in body, 3-title limit (separator count), fallback message, completed goal exclusion, userInfo deepLink value, nil title skip, empty title skip, all-completed fallback, and default sound. All 9 pass.

**Task 2 — NotificationDelegate, SettingsView, App Wiring**

`NotificationDelegate.swift` — `NSObject` subclass conforming to `UNUserNotificationCenterDelegate`. `didReceive` handler extracts `userInfo["deepLink"] as? String` and calls the injected closure (T-03-09: only "goalList" triggers navigation). `willPresent` handler shows `.banner` + `.sound` when app is in foreground.

`SettingsView.swift` — `Form` with a `DatePicker` (`.hourAndMinute`). `onChange` persists hour/minute to UserDefaults and calls `NotificationScheduler.shared.reschedule(activeGoals:)` via `Task`. Uses `@Query` to fetch current active goals so the rescheduled notification body stays current. Shows authorization status via `.task`.

`VitaminGApp.swift` — `router: AppRouter` and `notificationDelegate: NotificationDelegate` are stored properties. `init()` creates `AppRouter` first, then `NotificationDelegate` (capturing router in closure), sets `UNUserNotificationCenter.current().delegate`, then initializes the `ModelContainer`. `body` passes `router` via `.environment(router)`.

`GoalViewModel.swift` — `rescheduleNotification(context:)` fetches active goals via `FetchDescriptor<Goal>` and calls `NotificationScheduler.shared.reschedule` in a `Task`. Called at end of `addGoal`, `toggleCompletion`, `updateGoal`, and `delete` (T-03-10).

`ContentView.swift` — Third Settings tab added with `NavigationStack { SettingsView() }`. The `.settings` case in `goalsTab`'s `navigationDestination` now renders `SettingsView()` instead of `Text("Settings")` placeholder. The Stats tab's `StatsView()` from Plan 02 is preserved.

## Deviations from Plan

None — plan executed exactly as written.

The only contextual difference: when this plan ran, Plan 02 had already updated `ContentView.swift` to use `StatsView()`. The Settings tab was added on top of that state, preserving the Stats tab rather than reverting it.

## Known Stubs

None. All notification system components are fully wired:
- `NotificationScheduler.shared.schedule` sends real `UNNotificationRequest` to `UNUserNotificationCenter`
- `NotificationDelegate` is set as the live delegate on `UNUserNotificationCenter.current()`
- `SettingsView` reads/writes real `UserDefaults` and reschedules real notifications
- `GoalViewModel` reschedules after every mutation

## Threat Surface Scan

All threats in the plan's threat register are mitigated:

| Threat | Mitigation | Location |
|--------|-----------|----------|
| T-03-08 UserDefaults tampering | Hour clamped 0-23, minute clamped 0-59 | `NotificationScheduler.schedule()` |
| T-03-09 userInfo spoofing | Guard cast; only "goalList" triggers navigation | `NotificationDelegate.didReceive` |
| T-03-10 Content staleness | rescheduleNotification on every mutation | `GoalViewModel` (4 methods) |

No new network endpoints, auth paths, or file access patterns introduced. All notification data is local (UserDefaults + UNUserNotificationCenter).

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| NotificationScheduler.swift exists | FOUND |
| NotificationDelegate.swift exists | FOUND |
| SettingsView.swift exists | FOUND |
| NotificationSchedulerTests.swift exists | FOUND |
| Task 1 commit 926c25a | FOUND |
| Task 2 commit c55e140 | FOUND |
| All 9 NotificationSchedulerTests pass | PASSED |
| xcodebuild BUILD SUCCEEDED | PASSED |
