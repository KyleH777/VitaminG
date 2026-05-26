---
status: partial
phase: 23-milestone-features-streak-freeze
source: [23-VERIFICATION.md]
started: 2026-05-26T00:00:00Z
updated: 2026-05-26T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Heatmap Frozen Day Display (MILE-01 + MILE-03)
expected: Frozen date cell shows blue-tinted background with snowflake SF Symbol overlay. Days with real check-ins show green without the snowflake.
result: [pending]

### 2. Achievement Unlocked Screen (MILE-04)
expected: GoalStreakMilestoneView appears full-screen once with "Achievement Unlocked", "7-Day Streak!", confetti, Share to Community, and Continue buttons. An 8th check-in must NOT re-show the screen.
result: [pending]

### 3. Community Achievement Sharing (MILE-05)
expected: StreakAchievementCard appears in global feed with trophy icon and milestone text after tapping "Share to Community". No crash.
result: [pending]

### 4. Goal Completion Celebration (MILE-06)
expected: GoalCompletionCelebrationView appears once with "You did it.", goal title, streak count, confetti, Share button (opens iOS share sheet), and "Back to Goals" button.
result: [pending]

### 5. Streak-at-Risk Notification (MILE-02)
expected: "com.kyleharrington.VitaminG.streakAtRisk.global" present in pending notifications before check-in with repeating 19:00 trigger. Removed after check-in.
result: [pending]

### 6. Reduce Motion — Confetti Suppression
expected: Celebration appears with badge and text; confetti canvas is not rendered when Reduce Motion is enabled.
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
