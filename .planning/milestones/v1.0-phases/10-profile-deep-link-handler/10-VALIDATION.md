---
phase: 10
slug: profile-deep-link-handler
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-19
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Test`, `#expect`) — confirmed in `VitaminGTests.swift` |
| **Config file** | Xcode scheme — no separate config file |
| **Quick run command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Full suite command** | Same — single test target |
| **Estimated runtime** | ~30 seconds (simulator boot + unit tests) |

---

## Sampling Rate

- **After every task commit:** Verify the modified file compiles (Xcode build check)
- **After every plan wave:** Run URL parsing unit tests + build passes
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | PROF-06 | T-10-01 | Non-empty recordID guard; malformed URLs silently dropped | unit | `xcodebuild test -only-testing VitaminGTests/DeepLinkParserTests` | ❌ W0 | ⬜ pending |
| 10-01-02 | 01 | 1 | PROF-06 | T-10-01 | Unknown URL schemes silently ignored | unit | `xcodebuild test -only-testing VitaminGTests/DeepLinkParserTests` | ❌ W0 | ⬜ pending |
| 10-02-01 | 01 | 1 | PROF-07 | — | ViewModel transitions .loading → .loaded on success | unit | `xcodebuild test -only-testing VitaminGTests/PublicProfileViewModelTests` | ❌ W0 | ⬜ pending |
| 10-02-02 | 01 | 1 | PROF-07 | — | ViewModel transitions .loading → .error on CKError.unknownItem | unit | `xcodebuild test -only-testing VitaminGTests/PublicProfileViewModelTests` | ❌ W0 | ⬜ pending |
| 10-03-01 | 01 | 2 | PROF-07 | — | Sheet presents when pendingPublicProfileRecordID set | integration (manual) | Visual check on simulator | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/DeepLinkParserTests.swift` — stubs for PROF-06 URL parsing (pure URL logic, no UIKit/SwiftUI required)
- [ ] `VitaminGTests/PublicProfileViewModelTests.swift` — stubs for PROF-07 state transitions (requires async test support via Swift Testing)

*Note on CloudKit testing: `ProfileSharingService.fetchProfile` makes a live network call. ViewModel tests should inject a fake/closure override to avoid network dependency. See `NotificationSchedulerTests` for the project pattern of injecting test fakes.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sheet presents when tapping vitaming:// link from Messages | PROF-07 | SwiftUI sheet presentation requires device/simulator UI; not unit-testable | 1. Build and run on simulator. 2. Open Safari and navigate to a `vitaming://profile/testID` URL. 3. Confirm app opens and PublicProfileView sheet appears. |
| Cold launch opens directly to profile sheet | PROF-07 | Cold launch URL delivery timing requires device/simulator | 1. Terminate app. 2. Tap a `vitaming://profile/<recordID>` link. 3. Confirm app launches and sheet appears. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
