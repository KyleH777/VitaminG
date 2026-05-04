---
phase: 12
slug: goal-progress-visualization
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-03
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Apple, bundled with Xcode) |
| **Config file** | Xcode scheme (no external config file) |
| **Quick run command** | `xcodebuild build -scheme VitaminG -destination "platform=iOS Simulator,name=iPhone 15"` |
| **Full suite command** | `xcodebuild test -scheme VitaminG -destination "platform=iOS Simulator,name=iPhone 15"` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run build (Xcode build succeeds — no test run required per task)
- **After every plan wave:** Run `xcodebuild test -scheme VitaminG -destination "platform=iOS Simulator,name=iPhone 15"`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 0 | PROG-01,02,03,04 | — | N/A | unit | `xcodebuild test -scheme VitaminG` | ❌ W0 | ⬜ pending |
| 12-02-01 | 02 | 1 | PROG-01 | — | N/A | build | `xcodebuild build -scheme VitaminG` | ❌ W0 | ⬜ pending |
| 12-02-02 | 02 | 1 | PROG-01 | — | N/A | manual | Visual ring on goal card | — | ⬜ pending |
| 12-03-01 | 03 | 1 | PROG-02 | — | N/A | build | `xcodebuild build -scheme VitaminG` | ❌ W0 | ⬜ pending |
| 12-03-02 | 03 | 1 | PROG-02 | — | N/A | manual | Charts bar chart renders in GoalDetailView | — | ⬜ pending |
| 12-04-01 | 04 | 1 | PROG-03 | — | N/A | build | `xcodebuild build -scheme VitaminG` | ❌ W0 | ⬜ pending |
| 12-04-02 | 04 | 1 | PROG-03 | — | N/A | manual | Milestone badge fires at 5/10/25/50 completions | — | ⬜ pending |
| 12-05-01 | 05 | 1 | PROG-04 | — | N/A | build | `xcodebuild build -scheme VitaminG` | ❌ W0 | ⬜ pending |
| 12-05-02 | 05 | 1 | PROG-04 | — | N/A | manual | Momentum row shows color dot in GoalDetailView | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/ProgressViewModelTests.swift` — stubs for PROG-01 through PROG-04 (11 test cases: ringProgress, momentumScore, chartData, milestoneJustCrossed)
- [ ] Verify `VitaminGTests/StreakEngineTests.swift` still passes (baseline sanity before modifications)
- [ ] Verify existing `SchemaV1Tests` model count assertion passes (no accidental model addition — PROG-05)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Progress ring renders correctly (28pt, clockwise from 12 o'clock, tier color) | PROG-01 | SwiftUI rendering not automatable via XCTest | Launch on iPhone 15 Simulator; create goal, log completions, verify ring fills proportionally |
| Milestone badge animation fires and fades (non-blocking) | PROG-03 | Animation timing not automatable | Tap complete 5 times on one goal; badge appears, holds ~1.5s, fades without modal |
| Badge visible above List row (not clipped) | PROG-03 | List clipping is a runtime layout concern | Verify badge appears in full — if clipped, add `.zIndex(1)` or `.clipped(false)` |
| Reduced motion: static badge, no animation | PROG-03 | Accessibility setting must be toggled manually | Enable "Reduce Motion" in Simulator Settings; repeat milestone trigger — badge appears static |
| Swift Charts bar chart shows 30 bars, last 7 labeled | PROG-02 | Chart axis rendering is visual-only | Open GoalDetailView for a goal with 30+ days of history; verify axis labels on last 7 days only |
| Momentum color dot (green/amber/gray) correct | PROG-04 | Color rendering not automatable | Create goals with 0, 1, 4 completions in last 7 days; verify gray, amber, green dot respectively |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
