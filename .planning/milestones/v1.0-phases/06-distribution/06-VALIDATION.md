---
phase: 06
slug: distribution
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-27
---

# Phase 06 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (existing) + Manual checklist |
| **Config file** | VitaminGTests/VitaminGTests.swift |
| **Quick run command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 15'` |
| **Full suite command** | Same — all unit tests in a single scheme |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run existing unit tests to confirm no regressions
- **Phase is primarily manual checklist** — CloudKit Console, TestFlight, and App Store Connect steps cannot be automated

---

## Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SYNC-03 | CloudKit schema promoted to Production | Manual | CloudKit Console → Production → verify record types present | Manual only |

**Note:** SYNC-03 is a deployment task. Automated tests cannot verify CloudKit Console state. Validation is human inspection of the Production schema plus physical device TestFlight sync verification.

---

## Wave 0 Gaps

None — Phase 6 has no new Swift code requiring unit tests. The sole code artifact is `PrivacyInfo.xcprivacy` (XML file), validated by Xcode archive validation.

---

## Manual Validation Checklist

These items require human verification and cannot be automated:

1. **AppIcon alpha channel removed** — Verify `sips -g hasAlpha AppIcon.png` returns `hasAlpha: no`
2. **PrivacyInfo.xcprivacy present in main target** — Archive validates this automatically
3. **PrivacyInfo.xcprivacy present in widget target** — Archive validates this automatically
4. **CloudKit schema promoted to Production** — CloudKit Console shows all record types (CD_Goal, CD_CompletionEvent, CD_UserProfile) in Production environment
5. **TestFlight build installs without crash** — Physical iPhone running TestFlight build completes core flows
6. **Privacy Policy URL configured** — App Store Connect App Information has a valid hosted URL
