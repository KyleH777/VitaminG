---
phase: 27
slug: apple-watch-app
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-02
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (existing VitaminGTests target) |
| **Config file** | None — uses Xcode test scheme |
| **Quick run command** | `xcodebuild test -only-testing:VitaminGTests/WatchSessionManagerTests -only-testing:VitaminGTests/WatchSnapshotTests -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Full suite command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~60 seconds (quick) / ~120 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green + physical device E2E verification
- **Max feedback latency:** 60 seconds (quick), 120 seconds (full)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 27-W0-01 | W0 | 0 | WATCH-02/03 | — | N/A | infra | `ls VitaminGTests/WatchSnapshotTests.swift` | ❌ W0 | ⬜ pending |
| 27-W0-02 | W0 | 0 | WATCH-02/03 | — | N/A | infra | `ls VitaminGTests/WatchSessionManagerTests.swift` | ❌ W0 | ⬜ pending |
| 27-W0-03 | W0 | 0 | WATCH-02/03 | — | N/A | infra | `ls VitaminGTests/WatchReceiverTests.swift` | ❌ W0 | ⬜ pending |
| 27-01 | 01 | 1 | WATCH-02 | — | Snapshot fields correct | unit | `xcodebuild test -only-testing:VitaminGTests/WatchSnapshotTests` | ❌ W0 | ⬜ pending |
| 27-02 | 01 | 1 | WATCH-02 | — | UserDefaults written correctly | unit | `xcodebuild test -only-testing:VitaminGTests/WatchReceiverTests` | ❌ W0 | ⬜ pending |
| 27-03 | 02 | 2 | WATCH-03 | — | Check-in dispatched to correct goal | unit | `xcodebuild test -only-testing:VitaminGTests/WatchSessionManagerTests` | ❌ W0 | ⬜ pending |
| 27-04 | 02 | 2 | WATCH-03 | — | cancelGlobalStreakAtRiskNudge called | unit | `xcodebuild test -only-testing:VitaminGTests/WatchSessionManagerTests` | ❌ W0 | ⬜ pending |
| 27-05 | 02 | 2 | WATCH-03 | — | WidgetCenter.reloadAllTimelines called | unit (mock) | `xcodebuild test -only-testing:VitaminGTests/WatchSessionManagerTests` | ❌ W0 | ⬜ pending |
| 27-E2E | E2E | final | WATCH-02/03 | — | Full round-trip relay | manual | Physical device — see Manual Verifications | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/WatchSnapshotTests.swift` — unit tests for `WatchSnapshot.build()` field computation (WATCH-02)
- [ ] `VitaminGTests/WatchSessionManagerTests.swift` — unit tests for `WatchSessionManager.handleCheckIn()`: correct goal, `cancelGlobalStreakAtRiskNudge`, `WidgetCenter.reloadAllTimelines` (WATCH-03)
- [ ] `VitaminGTests/WatchReceiverTests.swift` — unit tests for `WatchReceiver.didReceiveApplicationContext()` UserDefaults write (WATCH-02)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `transferUserInfo` payload received on iPhone | WATCH-03 | Simulator cannot simulate WCSession `transferUserInfo` delivery | Pair physical Watch + iPhone, tap Check In on Watch, confirm iPhone streak updates |
| `updateApplicationContext` complication refresh | WATCH-02 | Simulator cannot test real complication on watch face | Add complication to watch face, trigger check-in on iPhone, confirm complication reflects new state within WCSession session |
| Streak-at-risk notification cancelled by Watch check-in | WATCH-03 | Notification cancellation requires real notification scheduling | Schedule test streak-at-risk notification for 1 minute, check in from Watch, confirm notification does not fire |
| Duplicate Watch notification suppression | WATCH-03 | Requires real Watch notification mirroring | Verify only one streak-at-risk alert appears on Watch face per day |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
