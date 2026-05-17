---
phase: 17
slug: onboarding-overhaul
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-16
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (unit) + XCUITest (UI) + iOS Simulator manual flows |
| **Config file** | VitaminG.xcodeproj |
| **Quick run command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests 2>&1 | tail -20` |
| **Full suite command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30` |
| **Estimated runtime** | ~90 seconds (unit); ~5 min (full with UI) |

---

## Sampling Rate

- **After every task commit:** Build succeeds (`xcodebuild build`) + unit tests green
- **After every plan wave:** Full suite + manual simulator walkthrough for the wave's screens
- **Before `/gsd:verify-work`:** Full suite must be green; all manual verifications signed off
- **Max feedback latency:** 90 seconds (unit); 5 min (full)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 17-01-01 | 01 | 1 | AUTH-01 | — | WelcomeScreen shows only Apple Sign-In button | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-01-02 | 01 | 1 | AUTH-07 | — | LoginScreen shows Apple Sign-In re-auth button | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-01-03 | 01 | 1 | AUTH-01 | — | OnboardingStep enum compiles with new cases | unit | `xcodebuild build` | ❌ W0 | ⬜ pending |
| 17-02-01 | 02 | 1 | AUTH-02 | — | T&C PDF opens in QuickLook sheet from TermsAndConditionsScreen | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-02-02 | 02 | 1 | AUTH-02 | — | "I Agree — Continue" advances to NameScreen | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-03-01 | 03 | 2 | AUTH-03 | — | Username debounce fires at 500ms; spinner shown during check | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-03-02 | 03 | 2 | AUTH-03 | — | Taken username shows ✗ inline; Continue button disabled | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-03-03 | 03 | 2 | AUTH-03 | — | Available username shows ✓ inline; Continue button enabled | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-04-01 | 04 | 2 | AUTH-04 | — | NameScreen pre-fills from Apple credential fullName | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-04-02 | 04 | 2 | AUTH-04 | — | ProfilePictureScreen shows PHPicker + camera option | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-04-03 | 04 | 2 | AUTH-04 | — | ProfilePictureScreen skip advances flow without crash | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-04-04 | 04 | 2 | AUTH-05 | — | NotificationOnboardingScreen appears in correct step position | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-04-05 | 04 | 2 | AUTH-06 | — | CameraPermissionScreen priming slide shown before system alert | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-04-06 | 04 | 2 | AUTH-06 | — | "Allow Camera" CTA triggers AVCaptureDevice.requestAccess | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-05-01 | 05 | 3 | PROF-05 | — | BlockListService CRUD passes XCTest unit tests | unit | `xcodebuild test -only-testing:VitaminGTests/BlockListServiceTests` | ❌ W0 | ⬜ pending |
| 17-05-02 | 05 | 3 | PROF-05 | — | Long-press on avatar shows Report/Block context menu | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-05-03 | 05 | 3 | PROF-05 | — | Block confirmation alert appears before blocking | manual | Build + simulator | ❌ W0 | ⬜ pending |
| 17-05-04 | 05 | 3 | PROF-05 | — | Blocked user ID persists in UserDefaults after app relaunch | unit | XCTest BlockListServiceTests | ❌ W0 | ⬜ pending |
| 17-05-05 | 05 | 3 | PROF-05 | — | Report action opens mail compose or mailto: URL | manual | Build + simulator | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Verify `NSCameraUsageDescription` key present in Info.plist (Phase 15 may have added it)
- [ ] Verify CloudKit Console: `PublicProfile` record type has `username` as queryable String field — required before AUTH-03 device testing
- [ ] `Vitamin_G_Terms_and_Conditions.pdf` added to Xcode project bundle (new file, Wave 0)
- [ ] Existing test infrastructure — no new framework install needed (XCTest ships with Xcode)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Apple Sign-In credential delivers fullName on first sign-in only | AUTH-01, D-04 | ASAuthorizationAppleIDCredential.fullName is nil on repeat sign-in by Apple design | Reset Apple Sign-In from Settings > Apple ID > Apps on device; sign in fresh |
| Username displaced race condition | AUTH-03 | Requires two simultaneous sign-ups with the same username | Run two simulators; type same username within 500ms window |
| CloudKit uniqueness rejection | AUTH-03 | Requires live CloudKit public DB with queryable username index | Test on device with live iCloud account |
| QuickLook PDF renders legibly on device | AUTH-02 | Simulator PDF rendering differs from device | Run on physical device |
| MFMailComposeViewController availability | PROF-05 | Simulator has no Mail app; `canSendMail()` returns false | Verify mailto: URL fallback fires on simulator; MFMailCompose on device |
| Returning user "Welcome Back" routing | AUTH-07 | Requires stored appleUserID in UserDefaults + reinstall simulation | Delete app, reinstall, sign in once, delete, reinstall — should hit LoginScreen |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (CloudKit index, PDF bundle, Info.plist key)
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s (unit)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
