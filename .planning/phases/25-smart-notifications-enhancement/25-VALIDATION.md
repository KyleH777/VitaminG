---
phase: 25
slug: smart-notifications-enhancement
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-29
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (existing, no new setup needed) |
| **Config file** | Xcode scheme — no separate config file |
| **Quick run command** | `xcodebuild test -scheme VitaminG -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests` |
| **Full suite command** | `xcodebuild test -scheme VitaminG -destination "platform=iOS Simulator,name=iPhone 16"` |
| **Estimated runtime** | ~60 seconds (quick), ~3 minutes (full) |

---

## Sampling Rate

- **After every task commit:** Run quick run command (NotificationSchedulerPhase25Tests only)
- **After every plan wave:** Run full suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds (quick run)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 25-01-01 | 01 | 0 | NOTIF-01 | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_makeContent_celebratoryCopy_whenStreakGe7` | No — Wave 0 | ⬜ pending |
| 25-01-02 | 01 | 0 | NOTIF-01 | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_makeContent_neutralBuildingCopy_whenStreak1To6` | No — Wave 0 | ⬜ pending |
| 25-01-03 | 01 | 0 | NOTIF-01 | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_makeContent_encouragingCopy_whenStreak0` | No — Wave 0 | ⬜ pending |
| 25-01-04 | 01 | 0 | NOTIF-02 | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_makeContent_twoGoalTitles` | No — Wave 0 | ⬜ pending |
| 25-01-05 | 01 | 0 | NOTIF-02 | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_makeContent_singleGoal` | No — Wave 0 | ⬜ pending |
| 25-02-01 | 02 | 0 | NOTIF-03 | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_appendCheckInHour_fifo14` | No — Wave 0 | ⬜ pending |
| 25-02-02 | 02 | 0 | NOTIF-03 | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_modalHour_returnsMode` | No — Wave 0 | ⬜ pending |
| 25-02-03 | 02 | 0 | NOTIF-03 | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_modalHour_tieBreakByFirstOccurrence` | No — Wave 0 | ⬜ pending |
| 25-03-01 | 03 | 0 | NOTIF-04 | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_schedule_oneShotStreakAtRisk_repeats_false` | No — Wave 0 | ⬜ pending |
| 25-03-02 | 03 | 0 | NOTIF-04 | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_schedule_oneShotSkipped_atCapBoundary` | No — Wave 0 | ⬜ pending |
| regression | all | — | regression | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerTests` | Yes — update signature only | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/NotificationSchedulerPhase25Tests.swift` — stub test file covering NOTIF-01 through NOTIF-04 (10 test methods)

*All other test infrastructure is pre-existing.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Morning notification displays celebratory/neutral/encouraging copy and correct goal title(s) | NOTIF-01, NOTIF-02 | Requires physical device or simulator push delivery | Schedule a test notification for 1 minute in future; verify body text format |
| 7 PM streak-at-risk alert fires for user with streak ≥ 3 who hasn't checked in | NOTIF-04 | Calendar trigger requires real time passage or simulator time override | Advance simulator time to 18:59, then 19:00; verify notification fires |
| Check-in cancels pending 7 PM alert | NOTIF-04 | Requires pending notification + check-in action sequence | Schedule alert, then complete a check-in; verify `pendingNotificationRequests` no longer contains `globalStreakAtRiskIdentifier` |
| Nudge suggestion banner appears in Settings after 14 days at consistent early hour | NOTIF-03 | Requires 14-entry UserDefaults history injection | Inject 14 identical early hours via debug helper; open Settings; verify banner text and Apply button |
