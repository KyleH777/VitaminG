---
phase: 14
slug: challenge-platform-community-modules
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-07
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built into Xcode) |
| **Config file** | VitaminG.xcodeproj (scheme: VitaminGTests) |
| **Quick run command** | `xcodebuild test -project "VitaminG.xcodeproj" -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -project "VitaminG.xcodeproj" -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -30` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick suite (`-only-testing:VitaminGTests`)
- **After every plan wave:** Run full suite
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| SchemaV5 models | Wave 1 | 1 | CHAL-18, CHAL-20, CHAL-21 | T-14-01 | All properties optional/defaulted; @Attribute(.externalStorage) on imageData | unit | `VitaminGTests/SchemaV5Tests` | ❌ W0 | ⬜ pending |
| ProfanityFilter | Wave 1 | 1 | CHAL-16 | T-14-02 | Whole-word match; blocked words rejected; clean text passes | unit | `VitaminGTests/ProfanityFilterTests` | ❌ W0 | ⬜ pending |
| CommunityService fetch | Wave 2 | 2 | CHAL-13 | T-14-03 | Category predicate scopes results correctly | unit | `VitaminGTests/CommunityFeedViewModelTests` | ❌ W0 | ⬜ pending |
| CommunityService reactions | Wave 2 | 2 | CHAL-14 | T-14-04 | toggleReaction increments count; one reaction type per user | unit | `VitaminGTests/CommunityFeedViewModelTests` | ❌ W0 | ⬜ pending |
| CommunityService report | Wave 2 | 2 | CHAL-15 | T-14-05 | reporterIDsJSON de-duplicates; count not shown publicly | unit | `VitaminGTests/CommunityFeedViewModelTests` | ❌ W0 | ⬜ pending |
| NotificationScheduler streak-at-risk | Wave 3 | 3 | CHAL-24 | T-14-06 | identifier scheme correct; 20:00 trigger; remove-before-add | unit | `VitaminGTests/NotificationSchedulerPhase14Tests` | ❌ W0 | ⬜ pending |
| NotificationScheduler milestone | Wave 3 | 3 | CHAL-24 | T-14-07 | UNTimeIntervalNotificationTrigger(1); correct title/body | unit | `VitaminGTests/NotificationSchedulerPhase14Tests` | ❌ W0 | ⬜ pending |
| Buddy ping cooldown | Wave 3 | 3 | CHAL-22 | T-14-08 | buddyPingLastSent stored; 24h cooldown enforced | unit | `VitaminGTests/NotificationSchedulerPhase14Tests` | ❌ W0 | ⬜ pending |
| CloudKit public DB write | Wave 2 | 2 | CHAL-17 | T-14-03 | CKRecord fields correct; InputSanitizer applied | manual | CloudKit Dashboard inspection | N/A | ⬜ pending |
| Box breathing animation | Wave 4 | 4 | CHAL-19 | — | Phase cycle: Inhale→HoldFull→Exhale→HoldEmpty; Reduce Motion: static | visual | Human check in Simulator | N/A | ⬜ pending |
| Custom challenge builder | Wave 4 | 4 | CHAL-23 | — | Produces ChallengeTemplate with correct fields; builder validation | visual | Human check in Simulator | N/A | ⬜ pending |
| Empty state copy | Wave 4 | 4 | CHAL-25 | — | "Be the First to Share" shown; no red failure states | visual | Human check in Simulator | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/ProfanityFilterTests.swift` — stubs for CHAL-16
- [ ] `VitaminGTests/CommunityFeedViewModelTests.swift` — stubs for CHAL-13, CHAL-14, CHAL-15
- [ ] `VitaminGTests/SchemaV5Tests.swift` — stubs for CHAL-18, CHAL-20, CHAL-21
- [ ] `VitaminGTests/NotificationSchedulerPhase14Tests.swift` — stubs for CHAL-22, CHAL-24
- [ ] Bundle resource: `profanity_list.txt` added to Copy Bundle Resources phase — required for ProfanityFilter

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CloudKit public DB post visible in Dashboard | CHAL-17 | CKRecord lives outside SwiftData; no in-process mock | Post in app → verify record appears in CloudKit Dashboard under publicDB container |
| Box breathing phases cycle correctly | CHAL-19 | Animation/timing requires visual check | Open Craving Tools → verify Inhale(4s)→Hold(4s)→Exhale(4s)→Hold(4s) cycle; enable Reduce Motion and verify animation disabled |
| Custom Challenge builder end-to-end | CHAL-23 | 2-step sheet flow with validation states | Tap "Build Your Own" → complete Step 1 → Next → complete Step 2 → Create → verify new template appears in discovery |
| Empty community feed copy | CHAL-25 | UI text rendering requires visual check | Fresh challenge with no posts → verify "Be the First to Share" heading, no red states |
| Transformation photo private (not in public DB) | CHAL-20 | CloudKit Dashboard verification | Add transformation photo → verify imageData NOT in publicDB container |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
