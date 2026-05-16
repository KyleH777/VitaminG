---
phase: 2
slug: core-goal-ui
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-04
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Xcode UI Tests (XCTest / XCUITest) + SwiftUI previews |
| **Config file** | WaterRingToss.xcodeproj (reuse build scheme) |
| **Quick run command** | `xcodebuild test -scheme "Vitamin G" -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Full suite command** | `xcodebuild test -scheme "Vitamin G" -destination 'platform=iOS Simulator,name=iPhone 16' -testPlan AllTests` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Build succeeds with `xcodebuild build -scheme "Vitamin G"`
- **After every plan wave:** Run full UI test suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 1 | GOAL-01 | build | `xcodebuild build -scheme "Vitamin G"` | ❌ W0 | ⬜ pending |
| 2-01-02 | 01 | 1 | GOAL-02 | build | `xcodebuild build -scheme "Vitamin G"` | ❌ W0 | ⬜ pending |
| 2-02-01 | 02 | 1 | GOAL-03 | build | `xcodebuild build -scheme "Vitamin G"` | ❌ W0 | ⬜ pending |
| 2-02-02 | 02 | 1 | UI-01 | build | `xcodebuild build -scheme "Vitamin G"` | ❌ W0 | ⬜ pending |
| 2-03-01 | 03 | 2 | GOAL-04 | build | `xcodebuild build -scheme "Vitamin G"` | ❌ W0 | ⬜ pending |
| 2-03-02 | 03 | 2 | GOAL-05 | build | `xcodebuild build -scheme "Vitamin G"` | ❌ W0 | ⬜ pending |
| 2-04-01 | 04 | 2 | GOAL-06 | build | `xcodebuild build -scheme "Vitamin G"` | ❌ W0 | ⬜ pending |
| 2-04-02 | 04 | 2 | GOAL-07 | build | `xcodebuild build -scheme "Vitamin G"` | ❌ W0 | ⬜ pending |
| 2-05-01 | 05 | 3 | UI-02 | build | `xcodebuild build -scheme "Vitamin G"` | ❌ W0 | ⬜ pending |
| 2-05-02 | 05 | 3 | UI-03 | build | `xcodebuild build -scheme "Vitamin G"` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Build compiles clean after each task (no new warnings/errors)
- [ ] SwiftData model schema matches Goal, CompletionEvent shapes from Phase 1

*Existing build infrastructure covers all phase requirements — no new test framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Tier colors, icons, typographic weights are visually distinct | UI-01 | Visual/aesthetic — not assertable via XCTest text | Launch app, navigate to goal list; verify each tier section has distinct color chip, SF Symbol icon, and font weight |
| Completed goals show distinct visual state | GOAL-05 | Visual state — completion badge/strikethrough not machine-assertable | Toggle completion on a goal; verify visual treatment changes |
| associatedInspiration displayed in detail view | GOAL-07 | UI layout verification | Open goal detail; confirm inspiration field is prominently visible |
| Re-activation works from completed list | GOAL-06 | Interaction flow | Mark goal complete, then tap re-activate; verify goal returns to active state |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
