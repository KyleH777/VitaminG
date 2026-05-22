---
phase: 19
slug: tip-jar-about-page-settings
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-21
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (unit) + SwiftUI Previews (visual) |
| **Config file** | VitaminGTests/VitaminGTests.swift (existing) |
| **Quick run command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests` |
| **Full suite command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick test suite
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 19-Wave0-01 | Wave 0 | 0 | MON-01 | — | StoreKit config file present for Simulator testing | manual | Xcode: open scheme → Product → Edit Scheme → Run → Options → StoreKit Configuration | ✅ | ⬜ pending |
| 19-01-01 | About | 1 | MON-01 | — | AboutView renders founder bio + app version | unit | `xcodebuild test -only-testing:VitaminGTests/AboutViewTests` | ❌ W0 | ⬜ pending |
| 19-01-02 | About | 1 | MON-02 | — | Floating tip button visible after scroll | manual | Launch app → Profile → Settings → About Vitamin G → scroll down | ✅ | ⬜ pending |
| 19-02-01 | TipJar | 1 | MON-01 | — | TipJarView loads 3 products from StoreKit | unit | `xcodebuild test -only-testing:VitaminGTests/TipJarViewTests` | ❌ W0 | ⬜ pending |
| 19-02-02 | TipJar | 1 | MON-02 | — | Purchase flow triggers fullScreenCover thank-you | manual | Sandbox purchase on device/Simulator | ✅ | ⬜ pending |
| 19-03-01 | Settings | 1 | SET-01 | — | SettingsView shows Appearance, Privacy, Support sections | unit | `xcodebuild test -only-testing:VitaminGTests/SettingsViewTests` | ❌ W0 | ⬜ pending |
| 19-03-02 | Settings | 1 | SET-04 | — | Color scheme change applies immediately | manual | Launch app → Settings → Appearance → toggle Dark | ✅ | ⬜ pending |
| 19-04-01 | Onboarding | 2 | NOTIF-01 | — | Nudge-time picker shown only when permission granted | unit | `xcodebuild test -only-testing:VitaminGTests/OnboardingFlowTests` | ❌ W0 | ⬜ pending |
| 19-05-01 | Notification | 2 | NOTIF-02 | — | Notification body uses rotating message + top goal | unit | `xcodebuild test -only-testing:VitaminGTests/NotificationSchedulerTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTips.storekit` — local StoreKit configuration file with 3 consumable products (com.vitamingapp.tip.small, com.vitamingapp.tip.large, com.vitamingapp.tip.supporter)
- [ ] `VitaminGTests/AboutViewTests.swift` — stubs for MON-01 (bio text visible, version string present)
- [ ] `VitaminGTests/TipJarViewTests.swift` — stubs for MON-01 (product count = 3)
- [ ] `VitaminGTests/SettingsViewTests.swift` — stubs for SET-01 (section count, toggle state)
- [ ] `VitaminGTests/OnboardingFlowTests.swift` — stubs for NOTIF-01 (conditional step routing)
- [ ] `VitaminGTests/NotificationSchedulerTests.swift` — stubs for NOTIF-02 (body format, day-of-year rotation)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sandbox IAP purchase completes | MON-02 | Requires Simulator or real device with StoreKit config | Xcode → Product → Run → tap tier card → confirm purchase |
| Post-purchase fullScreenCover animates | MON-02 | Animation is visual-only | Observe heart/confetti animation after sandbox purchase |
| Dark mode applies to system chrome | SET-04 | Tab bar / modal chrome requires runtime observation | Toggle dark in Settings → observe tab bar color change |
| Nudge-time persists across app restart | NOTIF-01 | UserDefaults + UNCalendarNotificationTrigger verify | Set custom time → force-quit → relaunch → check Settings |
| Daily notification shows rotating message | NOTIF-02 | Requires UNNotification delivery | Advance system clock or use `simulateDelivery` in debug |
| About Vitamin G NavigationLink push works | SET-05 | Navigation stack wiring | Settings → tap "About Vitamin G" → verify push |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
