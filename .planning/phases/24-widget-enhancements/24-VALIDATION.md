---
phase: 24
slug: widget-enhancements
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 24 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (existing `VitaminGTests` target) |
| **Config file** | Xcode target `VitaminGTests` |
| **Quick run command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -testClass Phase24WidgetDataProviderTests 2>&1 | tail -20` |
| **Full suite command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30` |
| **Estimated runtime** | ~60 seconds (quick), ~180 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run quick command (`Phase24WidgetDataProviderTests`)
- **After every plan wave:** Run full suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 24-P01-01 | 01 | 0 | WID-01 | — | N/A | unit | `-testClass Phase24WidgetDataProviderTests` | ❌ W0 | ⬜ pending |
| 24-P01-02 | 01 | 1 | WID-01 | — | N/A | unit | `-testClass Phase24WidgetDataProviderTests -only-testing:.../test_activeGoal_immediateWinsOverShortTerm` | ❌ W0 | ⬜ pending |
| 24-P01-03 | 01 | 1 | WID-01 | — | N/A | unit | `-testClass Phase24WidgetDataProviderTests -only-testing:.../test_activeGoalProgress_clampedToUnit` | ❌ W0 | ⬜ pending |
| 24-P01-04 | 01 | 1 | WID-01 | — | N/A | unit | `-testClass Phase24WidgetDataProviderTests -only-testing:.../test_activeGoalProgress_nilWhenNoDuration` | ❌ W0 | ⬜ pending |
| 24-P01-05 | 01 | 1 | WID-01 | — | N/A | unit | `-testClass Phase24WidgetDataProviderTests -only-testing:.../test_activeGoal_nilWhenAllCompleted` | ❌ W0 | ⬜ pending |
| 24-P02-01 | 02 | 2 | WID-02 | — | N/A | manual | Freeze streak in StatsView, verify widget updates | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/Phase24WidgetDataProviderTests.swift` — stubs/tests for new `activeGoalTitle` + `activeGoalProgress` fields in `WidgetDataProvider.build()`, covering WID-01

*Existing `VitaminGTests/WidgetDataProviderTests.swift` covers pre-Phase-24 behavior — no changes needed, but new Phase24 file required for new field logic.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Widget updates after streak freeze in StatsView | WID-02 | WidgetKit timeline refresh cannot be asserted in XCTest without a live simulator session | (1) Run app on iPhone 16 sim, (2) freeze streak in StatsView, (3) force widget timeline reload via Home Screen, (4) confirm streak count + goal row reflect change |
| Widget updates after goal check-in | WID-02 | Same as above | (1) Check in on a goal via GoalDetailView, (2) wait ~5s or background/foreground app, (3) confirm widget reflects new progress |
| GoalSummaryWidget gallery preview shows correct states | WID-01 | Widget gallery previews use `.placeholder` / `.snapshot` paths, not live data | (1) Add widget from widget gallery, (2) confirm placeholder shows "3 day streak" + sample goal title with partial bar |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
