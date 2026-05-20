---
phase: 18
slug: home-tab-goals-flow
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-17
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (existing project) |
| **Config file** | none — inline test targets |
| **Quick run command** | `xcodebuild build -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Full suite command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~60 seconds (build) / ~120 seconds (full test) |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild build -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'`
- **After every plan wave:** Run full suite `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Before `/gsd:verify-work`:** Full suite must be green + manual walkthrough of all 5 success criteria
- **Max feedback latency:** 60 seconds (build check)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| HOME-01 | TBD | 1 | HOME-01 | — | appStreak uses StreakEngine, not completionEvents.count | unit | `xcodebuild test ... -only-testing:VitaminGTests/StreakEngineTests` | ❌ Wave 0 | ⬜ pending |
| HOME-02 | TBD | 1 | HOME-02 | — | Quote rotates daily from VGQuoteBank | unit | `xcodebuild test ... -only-testing:VitaminGTests/QuoteBankTests` | ❌ Wave 0 | ⬜ pending |
| HOME-03 | TBD | 1 | HOME-03 | — | Community goal card hidden when no active challenge | manual | visual on simulator | ✅ manual | ⬜ pending |
| HOME-04 | TBD | 1 | HOME-04 | — | "+add" triggers GoalEntryChoiceView sheet | manual | visual on simulator | ✅ manual | ⬜ pending |
| HOME-05 | TBD | 1 | HOME-05 | — | Stats row navigates to StatsView | manual | visual on simulator | ✅ manual | ⬜ pending |
| GOAL2-01 | TBD | 2 | GOAL2-01 | — | Step 3 includes duration field; GoalInput carries durationDays | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalInputTests` | ❌ Wave 0 | ⬜ pending |
| GOAL2-02 | TBD | 2 | GOAL2-02 | — | Pre-made goals list has all GoalCategory suggestions (33 goals) | unit | `xcodebuild test ... -only-testing:VitaminGTests/PremadeGoalsTests` | ❌ Wave 0 | ⬜ pending |
| GOAL2-03 | TBD | 2 | GOAL2-03 | — | "Already have a goal" opens wizard at step 1 | manual | visual on simulator | ✅ manual | ⬜ pending |
| GOAL2-04a | TBD | 2 | GOAL2-04 | — | Check-in creates CompletionEvent, does not set isCompleted | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalViewModelTests` | ❌ Wave 0 | ⬜ pending |
| GOAL2-04b | TBD | 2 | GOAL2-04 | — | Same-day duplicate check-in is blocked | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalViewModelTests` | ❌ Wave 0 | ⬜ pending |
| GOAL2-05a | TBD | 3 | GOAL2-05 | — | Day grid shows correct filled/empty cells for given CompletionEvents | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalDayGridTests` | ❌ Wave 0 | ⬜ pending |
| GOAL2-05b | TBD | 3 | GOAL2-05 | — | Flame icon appears when consecutive streak >= 3 | unit | `xcodebuild test ... -only-testing:VitaminGTests/StreakEngineTests` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/StreakEngineTests.swift` — covers HOME-01 streak source fix + GOAL2-05 flame threshold (3+ consecutive days)
- [ ] `VitaminGTests/GoalViewModelTests.swift` — covers GOAL2-04 addCheckIn, same-day dedup, isCompleted unchanged
- [ ] `VitaminGTests/GoalDayGridTests.swift` — covers GOAL2-05 grid cell filled/empty logic, month bounds
- [ ] `VitaminGTests/PremadeGoalsTests.swift` — covers GOAL2-02 category.suggestions count and no-empty-title guard
- [ ] `VitaminGTests/GoalInputTests.swift` — covers GOAL2-01 durationDays field persistence round-trip

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Community goal card shows/hides | HOME-03 | Requires active UserChallenge data in CloudKit | Run on simulator with test account; verify card appears with progress bar |
| "+add" opens GoalEntryChoiceView | HOME-04 | Sheet presentation requires UI interaction | Tap "+add" on Home screen; verify 3-path choice sheet appears |
| Stats row navigates to StatsView | HOME-05 | NavigationStack push requires live navigation | Tap Stats row on Home; verify StatsView appears |
| "Already have a goal" opens wizard | GOAL2-03 | Sheet + navigation flow requires UI interaction | Tap "Already have a goal"; verify wizard at step 1 (or blank goal form) |
| Check-in celebration auto-dismisses | GOAL2-04 | 2-second timer requires real-time testing | Check in a goal; verify celebration appears and auto-dismisses in ~2s |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
