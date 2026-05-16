---
phase: 05
slug: onboarding-polish
status: complete
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-16
audited: 2026-04-16
---

# Phase 05 — Validation Strategy

> Per-phase validation contract reconstructed from artifacts (State B — no prior VALIDATION.md).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`) |
| **Config file** | VitaminG.xcodeproj (scheme: VitaminG, target: VitaminGTests) |
| **Quick run command** | `cd "VitaminG/VitaminG" && xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests -quiet 2>&1 \| tail -15` |
| **Full suite command** | `cd "VitaminG/VitaminG" && xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 \| tail -15` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command (VitaminGTests only)
- **After every plan wave:** Run full suite
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Test Type | Automated Command | Status |
|---------|------|------|-------------|------------|-----------|-------------------|--------|
| 05-01-T1 | 01 | 1 | ONBOARD-01, ONBOARD-02 | T-05-01 | unit | `GoalTierTests/orderedContainsExactlyFourTiers` | ✅ green |
| 05-01-T1 | 01 | 1 | ONBOARD-01 | — | unit | `GoalTierTests/orderedContainsAllExpectedCases` | ✅ green |
| 05-01-T1 | 01 | 1 | ONBOARD-01 | — | unit | `GoalTierTests/allTiersHaveNonEmptyDisplayName` | ✅ green |
| 05-01-T1 | 01 | 1 | ONBOARD-01 | — | unit | `GoalTierTests/allTiersHaveNonEmptyIcon` | ✅ green |
| 05-01-T2 | 01 | 1 | ONBOARD-02 | T-05-01 | unit | `OnboardingViewModelTests/initialStateNotCompleted` | ✅ green |
| 05-01-T2 | 01 | 1 | ONBOARD-02 | T-05-01 | unit | `OnboardingViewModelTests/hasCompletedOnboardingDefaultsToFalseWhenNotSet` | ✅ green |
| 05-01-T3 | 01 | 1 | ONBOARD-03, NOTIF-01 | T-05-02 | manual | See Manual-Only table | ⚠️ manual |
| 05-02-T1 | 02 | 2 | ONBOARD-04 | — | unit | `EmptyTierViewTests/warmCopyExistsForAllTiers` | ✅ green |
| 05-02-T2 | 02 | 2 | ONBOARD-04 | — | unit | `EmptyTierViewTests/orderedHasExactlyFourTiersForEmptyStateRendering` | ✅ green |
| 05-03-T1 | 03 | 3 | UI-05 | — | manual | See Manual-Only table | ⚠️ manual |
| 05-03-T2 | 03 | 3 | UI-06 | — | manual | See Manual-Only table | ⚠️ manual |
| 05-04-T1 | 04 | 4 | UI-04, UI-06 | — | manual | See Manual-Only table | ⚠️ manual |
| 05-04-T2 | 04 | 4 | UI-04 | — | manual | See Manual-Only table | ⚠️ manual |
| 05-05-T1 | 05 | 5 | UI-05, UI-06 | — | manual | See Manual-Only table | ⚠️ manual |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ manual*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Notification half-sheet appears after first goal creation or skip — never on cold launch | ONBOARD-03, NOTIF-01 | Requires simulator E2E + UNUserNotificationCenter timing observation | Delete app, reinstall, complete onboarding (create a goal). Verify notification sheet appears. Force-quit and relaunch — verify sheet does NOT appear again. |
| No placeholder UI (Text("TODO"), Text("Coming soon"), debug overlays) in release build | UI-04 | Verified by code inspection; not automatable as a Swift unit test | Run release build on simulator. Navigate all screens. No "TODO" or debug text should appear. |
| Tier picker cards adapt to Dark Mode (no white card in dark appearance) | UI-05 | Dark Mode rendering requires visual runtime inspection | Enable Dark Mode in Settings. Open Add Goal. Tier cards should show dark-adapted background (not white). |
| Tier card labels (displayName, description) scale with Dynamic Type | UI-06 | Dynamic Type scaling requires visual runtime verification | Set Text Size to "Accessibility Extra Extra Extra Large" in Settings > Accessibility. Open Add Goal. Tier card text should scale. |
| VoiceOver navigates full onboarding flow meaningfully | UI-06 | VoiceOver navigation requires on-device/Accessibility Inspector testing | Enable VoiceOver. Delete app, reinstall, launch fresh. Navigate Welcome → Tiers → Create Goal. Verify each tier card announces displayName + description. Sort button announces "Sort goals". |
| First-launch onboarding gate persists across relaunches | ONBOARD-02 | @AppStorage persistence requires end-to-end behavioral testing | Complete onboarding. Force-quit. Relaunch. Verify GoalListView shown immediately (no onboarding). |

---

## Validation Audit 2026-04-16

| Metric | Count |
|--------|-------|
| Requirements audited | 8 |
| Automated tests found (pre-audit) | 2 (OnboardingViewModelTests, EmptyTierViewTests — partial) |
| Automated tests added | 6 (GoalTierTests x4, enhanced OnboardingViewModelTests x1, enhanced EmptyTierViewTests x1) |
| Manual-only gaps | 6 behaviors across UI-04, UI-05, UI-06, ONBOARD-03, NOTIF-01, ONBOARD-02 behavioral |
| Escalated | 0 |

## Validation Audit 2026-04-16 (re-audit)

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Note | All 15 automated tests verified green on iPhone 17 simulator (iOS 26.4). Tests reside in VitaminGTests.swift (GoalTierTests, OnboardingViewModelTests, EmptyTierViewTests structs). No new automatable gaps found. Manual-only coverage remains maximal. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or manual-only entry
- [x] GoalTierTests covers ONBOARD-01 data completeness
- [x] EmptyTierViewTests covers ONBOARD-04 per-tier rendering
- [x] OnboardingViewModelTests covers ONBOARD-02 initial state + @AppStorage default
- [x] Manual-only behaviors documented with clear test instructions
- [ ] Visual behaviors verified on device (Dark Mode, Dynamic Type, VoiceOver)
- [ ] End-to-end first-launch flow verified on simulator

**nyquist_compliant: false** — UI-04, UI-05, UI-06, ONBOARD-03, NOTIF-01 require human verification. Automated coverage is maximal given Swift Testing constraints on private view state and platform behavioral APIs.

**Approval:** pending human verification of manual-only items
