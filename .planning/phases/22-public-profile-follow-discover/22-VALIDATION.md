---
phase: 22
slug: public-profile-follow-discover
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-24
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (existing VitaminGTests target) |
| **Config file** | Xcode scheme — no separate config file |
| **Quick run command** | `xcodebuild test -scheme VitaminG -only-testing:VitaminGTests/Phase22*` |
| **Full suite command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~120 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme VitaminG -only-testing:VitaminGTests/Phase22*`
- **After every plan wave:** Run `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|-------------|-----------|-------------------|-------------|--------|
| SchemaV9 migration | n/a | unit | `xcodebuild test -only-testing:VitaminGTests/Phase22SchemaV9Tests` | ❌ Wave 0 | ⬜ pending |
| PublicProfileData struct | PROF-01 | unit | `xcodebuild test -only-testing:VitaminGTests/Phase22PublicProfileViewModelTests` | ❌ Wave 0 | ⬜ pending |
| ProfileSharingService.fetchProfile | PROF-01 | unit (mock) | `xcodebuild test -only-testing:VitaminGTests/Phase22PublicProfileViewModelTests` | ❌ Wave 0 | ⬜ pending |
| FollowService.writeFollow | PROF-02 | unit (mock save) | `xcodebuild test -only-testing:VitaminGTests/Phase22FollowServiceTests` | ❌ Wave 0 | ⬜ pending |
| FollowService.fetchFollowState | PROF-02 | unit (mock) | `xcodebuild test -only-testing:VitaminGTests/Phase22FollowServiceTests` | ❌ Wave 0 | ⬜ pending |
| FollowButton state machine | PROF-02 | unit | `xcodebuild test -only-testing:VitaminGTests/Phase22FollowServiceTests` | ❌ Wave 0 | ⬜ pending |
| canCheerToday (cheer gate) | PROF-03 | unit | `xcodebuild test -only-testing:VitaminGTests/Phase21ApplauseDailyGateTests` | ✅ exists | ⬜ pending |
| PublicGoalService.fetchGoalsForUser | PROF-04 | unit (mock) | `xcodebuild test -only-testing:VitaminGTests/Phase22PublicGoalServiceTests` | ❌ Wave 0 | ⬜ pending |
| DiscoverViewModel 500ms debounce | DISC-01 | unit (mock clock) | `xcodebuild test -only-testing:VitaminGTests/Phase22DiscoverViewModelTests` | ❌ Wave 0 | ⬜ pending |
| DiscoverViewModel default segment | DISC-01 | unit | `xcodebuild test -only-testing:VitaminGTests/Phase22DiscoverViewModelTests` | ❌ Wave 0 | ⬜ pending |
| People search BEGINSWITH[cd] | DISC-02 | unit (predicate) | `xcodebuild test -only-testing:VitaminGTests/Phase22DiscoverViewModelTests` | ❌ Wave 0 | ⬜ pending |
| joinGoal creates SwiftData Goal | DISC-04 | unit (in-memory) | `xcodebuild test -only-testing:VitaminGTests/Phase22DiscoverViewModelTests` | ❌ Wave 0 | ⬜ pending |
| joinGoal increments participantCount | DISC-04 | unit (mock) | `xcodebuild test -only-testing:VitaminGTests/Phase22DiscoverViewModelTests` | ❌ Wave 0 | ⬜ pending |
| backfillPublicGoals skips existing | n/a | unit | `xcodebuild test -only-testing:VitaminGTests/Phase22PublicGoalServiceTests` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/Phase22PublicProfileViewModelTests.swift` — covers PROF-01, PROF-02 ViewModel state machine; extends/replaces existing `PublicProfileViewModelTests.swift`
- [ ] `VitaminGTests/Phase22FollowServiceTests.swift` — covers PROF-02 (deterministic record name, fetchFollowState, button states)
- [ ] `VitaminGTests/Phase22PublicGoalServiceTests.swift` — covers PROF-04, DISC-04, backfill logic
- [ ] `VitaminGTests/Phase22DiscoverViewModelTests.swift` — covers DISC-01 (debounce), DISC-02 (predicate), DISC-04 (join action)
- [ ] `VitaminGTests/Phase22SchemaV9Tests.swift` — covers SchemaV9 model field defaults (motto, cloudKitPublicGoalRecordID)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CloudKit Console: PublicGoal record type with Queryable indexes | DISC-01, DISC-02 | CloudKit schema deployment requires human action in CloudKit Console | Deploy to Production in CloudKit Console; verify Queryable indexes on `title` and `creatorUsername` |
| CloudKit Console: Follow record type deployment | PROF-02 | Same as above | Deploy Follow record type to CloudKit Production |
| Applause animation plays on CheerButton tap | PROF-03 | UI animation not testable in XCTest | Test on device: tap "Cheer them on today" → applause animation fires → button disables |
| Follow button state persists across app restart | PROF-02 | Requires live CloudKit + app relaunch | Follow user, kill app, relaunch, verify button still shows "Following" |
| Discover search returns results within 500ms | DISC-01 | Real CloudKit network timing | Test on device with production CloudKit; results appear before 500ms debounce |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
