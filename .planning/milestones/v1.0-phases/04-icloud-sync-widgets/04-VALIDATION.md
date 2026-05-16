---
phase: 4
slug: icloud-sync-widgets
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-06
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (existing VitaminGTests target) |
| **Config file** | Xcode scheme — no separate config file |
| **Quick run command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests` |
| **Full suite command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command (existing unit tests must stay green)
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite green + manual widget rendering verified on device
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | SYNC-01 | — | N/A | Manual (2 devices + iCloud) | Manual only — cross-device sync | N/A | ⬜ pending |
| 4-01-02 | 01 | 1 | SYNC-02 | — | N/A | Manual (UI inspection) | Manual only — no sync button visible | N/A | ⬜ pending |
| 4-02-01 | 02 | 1 | WIDGET-01 | — | Read-only from App Group store | Unit | `xcodebuild test -scheme VitaminG ...` | ❌ W0 | ⬜ pending |
| 4-02-02 | 02 | 1 | WIDGET-02 | — | Read-only from App Group store | Unit | `xcodebuild test -scheme VitaminG ...` | ❌ W0 | ⬜ pending |
| 4-02-03 | 02 | 1 | WIDGET-03 | — | Widget uses App Group store only | Manual (physical device) | Manual — Simulator App Group unreliable | N/A | ⬜ pending |
| 4-02-04 | 02 | 1 | WIDGET-04 | — | No write ops in widget process | Static analysis / code review | Enforced by StaticConfiguration + review | N/A | ⬜ pending |
| 4-02-05 | 02 | 2 | WIDGET-05 | — | Timeline refreshes at least daily | Unit | `xcodebuild test -scheme VitaminG ...` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/WidgetDataProviderTests.swift` — stubs for WIDGET-01, WIDGET-02: tests `WidgetDataProvider.build()` with mocked goals
- [ ] `VitaminGTests/WidgetTimelineTests.swift` — stubs for WIDGET-05: tests `nextMorningRefreshDate()` pure function logic

*Existing infrastructure: VitaminGTests target exists with 6 test files — no new target needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Goal created on device A appears on device B | SYNC-01 | Requires 2 physical devices signed into same iCloud account | Create goal on device 1, wait ~30s, confirm appearance on device 2 |
| No manual sync button in UI | SYNC-02 | UI inspection | Audit Settings and goal list views — no "Sync" control present |
| Widget reads from shared App Group store | WIDGET-03 | Simulator App Group behavior is unreliable | Install on physical device, create/modify goals, verify widget updates |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
