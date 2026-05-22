---
plan: 19-05
phase: 19-tip-jar-about-page-settings
status: complete
completed_at: 2026-05-22
---

# Plan 19-05 Summary: Rotating Notification Copy

## Objective
Update `NotificationScheduler.makeContent` so the daily notification uses a day-of-year-seeded inspirational message plus the top active goal title, replacing the old joined-titles body.

## What Was Built

### NotificationScheduler.swift
- Added `internal static let inspirationalMessages: [String]` — 7 messages (D-16 contract)
- Rewrote `makeContent(activeGoals:)`:
  - `content.title = "Good morning"` (replaces "Your Vitamin G for today")
  - Day-of-year rotation: `(dayOfYear - 1) % inspirationalMessages.count`
  - Body: `"{message}\n{topGoalTitle}"` when active goal exists, else message alone
  - `topGoalTitle`: first non-completed, non-nil, non-empty goal title

### NotificationSchedulerTests.swift
- Updated 5 test methods to match new format (title, newline body, inspirational fallback)
- `allCompleted` and `noActiveGoals` tests assert body is one of the 7 known messages
- All other NotificationScheduler tests (perGoalIdentifier, cancelPerGoal, sound, userInfo) unchanged

## Key Files
- `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift`
- `VitaminG/VitaminG/VitaminGTests/NotificationSchedulerTests.swift`

## Self-Check: PASSED
- Build: clean
- NotificationSchedulerTests: all passing
- Requirements NOTIF-02 (D-16/D-17): rotating copy delivered ✓
