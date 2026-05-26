# Phase 23: Milestone Features + Streak Freeze — Validation

## Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest |
| Quick run | `cd VitaminG/VitaminG && xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:VitaminGTests/<TestClass>` |
| Full suite | `cd VitaminG/VitaminG && xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` |

## Requirements → Test Map

| Req | Behavior | Type | Test Class |
|-----|----------|------|-----------|
| MILE-01 | `canFreeze` resets on ISO8601 Monday boundary | unit | `StreakFreezeTests` (extend) |
| MILE-01 | Year-boundary (week 52 → week 1) does not reset freeze mid-week | unit | `StreakFreezeTests` (extend) |
| MILE-01 | Frozen day preserves streak count in `StreakEngine` | unit | `StreakEngineTests` (existing) |
| MILE-03 | `buildHeatmapData` writes `-1` sentinel for frozen days with no check-in | unit | `Phase23StatsViewModelTests` |
| MILE-03 | `buildHeatmapData` does NOT write `-1` if check-in exists on frozen day | unit | `Phase23StatsViewModelTests` |
| MILE-04 | `StreakMilestoneGate.hasShown` returns false on fresh install | unit | `Phase23MilestoneGateTests` |
| MILE-04 | `StreakMilestoneGate.markShown` + `hasShown` returns true | unit | `Phase23MilestoneGateTests` |
| MILE-04 | All thresholds `[7, 14, 30, 60, 90, 365]` fire independently | unit | `Phase23MilestoneGateTests` |
| MILE-04 | Per-goal: milestone on goal A does not affect goal B | unit | `Phase23MilestoneGateTests` |
| MILE-02 | `scheduleStreakAtRiskNudge` respects 64-cap guard | unit | `Phase23NotificationTests` |
| MILE-02 | Notification identifier includes goalID + threshold | unit | `Phase23NotificationTests` |
| MILE-05 | `writeStreakAchievement` de-duplicates by username+goalID+threshold | unit (mock) | `Phase23CommunityServiceTests` |
| MILE-06 | `addCheckIn` sets `pendingGoalCompletion` when count reaches `durationDays` | unit | `Phase23GoalViewModelTests` |

## Wave 0 Gaps (RED tests — created in Plan 23-01)

- [ ] `Phase23StatsViewModelTests.swift` — MILE-03 sentinel logic
- [ ] `Phase23MilestoneGateTests.swift` — MILE-04 gate persistence
- [ ] `Phase23NotificationTests.swift` — MILE-02 cap guard
- [ ] `Phase23GoalViewModelTests.swift` — MILE-06 auto-complete trigger
- [ ] Extend `StreakFreezeTests.swift` — ISO8601 weekly reset, year-boundary

## Human Verify Checklist (Plan 23-04 Task 3)

1. Streak freeze: activate "Life happened." — streak count unchanged, ❄️ appears in heatmap for missed day
2. Freeze resets Monday: simulate Monday crossing — `canFreeze` returns true again
3. Milestone unlocked: goal with 7 check-ins — full-screen celebration fires exactly once
4. Milestone not re-shown: force-reopen — celebration does NOT appear again
5. Share to Community: tap Share on milestone screen — achievement appears in Community feed
6. Goal completion: complete a goal — "You did it" screen with confetti and ShareLink
7. At-risk nudge: check pending notifications after 7 PM (no check-in, freeze available) — notification scheduled
