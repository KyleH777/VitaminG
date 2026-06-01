---
phase: 26
slug: analytics-dashboard
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-01
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (existing) |
| **Config file** | none — standard Xcode test target |
| **Quick run command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -testPlan VitaminGTests 2>&1 \| grep -E "passed\|failed"` |
| **Full suite command** | Same as quick run — all tests run in one target |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 26-WT-01 | TBD | 0 | ANLT-02 | — | N/A | unit | `Phase26AnalyticsViewModelTests/testWeeklyBuckets` | ❌ Wave 0 | ⬜ pending |
| 26-WT-02 | TBD | 0 | ANLT-02 | — | N/A | unit | `Phase26AnalyticsViewModelTests/testMonthlyBuckets` | ❌ Wave 0 | ⬜ pending |
| 26-WT-03 | TBD | 0 | ANLT-02 | — | N/A | unit | `Phase26AnalyticsViewModelTests/testCompletionRateFormula` | ❌ Wave 0 | ⬜ pending |
| 26-WT-04 | TBD | 0 | ANLT-03 | — | N/A | unit | `Phase26AnalyticsViewModelTests/testHeatmapStartDateFallback` | ❌ Wave 0 | ⬜ pending |
| 26-WT-05 | TBD | 0 | ANLT-03 | — | N/A | unit | `Phase26AnalyticsViewModelTests/testAllGoalsIncluded` | ❌ Wave 0 | ⬜ pending |
| 26-WT-06 | TBD | 0 | ANLT-04 | — | No formula injection | unit | `Phase26CSVExportServiceTests/testCSVHeader` | ❌ Wave 0 | ⬜ pending |
| 26-WT-07 | TBD | 0 | ANLT-04 | — | RFC 4180 escaping prevents injection | unit | `Phase26CSVExportServiceTests/testCSVEscaping` | ❌ Wave 0 | ⬜ pending |
| 26-WT-08 | TBD | 0 | ANLT-04 | — | N/A | unit | `Phase26CSVExportServiceTests/testIsFrozenColumn` | ❌ Wave 0 | ⬜ pending |
| 26-WT-09 | TBD | 0 | ANLT-04 | — | N/A | unit | `Phase26CSVExportServiceTests/testSortOrder` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/Phase26AnalyticsViewModelTests.swift` — stubs for ANLT-02, ANLT-03 (bucket logic, start date, all-goals filter)
- [ ] `VitaminGTests/Phase26CSVExportServiceTests.swift` — stubs for ANLT-04 (header, escaping, frozen column, sort)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Navigation from StatsView to AnalyticsView | ANLT-02, ANLT-03 | UI integration — NavigationLink in simulator | Open app in simulator, tap Analytics row at bottom of StatsView, verify AnalyticsView loads |
| Horizontal scroll without stutter for 1000+ days | ANLT-03 | Performance — requires real data in simulator | Add goal with creation date 3+ years ago, open heatmap, verify smooth scroll |
| ShareLink triggers system share sheet | ANLT-04 | UIKit integration — requires simulator interaction | Tap Export button, verify iOS share sheet appears with CSV file option |
| CSV integrity in Files/Mail app | ANLT-04 | End-to-end — requires simulator share action | Export and open CSV in Files; verify all columns and rows present |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
