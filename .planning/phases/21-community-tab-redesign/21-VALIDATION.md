---
phase: 21
slug: community-tab-redesign
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-23
---

# Phase 21 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest |
| **Config file** | `VitaminG.xcodeproj` (VitaminGTests target) |
| **Quick run command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/Phase21CommunityHubViewModelTests 2>&1 \| xcpretty` |
| **Full suite command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -testPlan VitaminGTests 2>&1 \| xcpretty` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command targeting the relevant Phase21 test file
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 21-xx-01 | TBD | 1 | COMM-02 | — | Carousel auto-advance timer fires every 5 seconds | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21CommunityHubViewModelTests` | ❌ W0 | ⬜ pending |
| 21-xx-02 | TBD | 1 | COMM-04 | — | Active Today filter excludes users lastActiveDate > 2 hours ago | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21CommunityHubViewModelTests` | ❌ W0 | ⬜ pending |
| 21-xx-03 | TBD | 1 | COMM-05 | — | Glowing This Week selection is deterministic for same weekOfYear | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21GlowingSelectionTests` | ❌ W0 | ⬜ pending |
| 21-xx-04 | TBD | 1 | COMM-06 | T-21-01 | 🔥 reaction field key is "fireCount"; reply write sanitizes profanity before CloudKit | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21CommunityHubViewModelTests` | ❌ W0 | ⬜ pending |
| 21-xx-05 | TBD | 1 | COMM-06 | — | CommunityHubViewModel.loadAll() calls all 5 CloudKit fetches via overrides | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21CommunityHubViewModelTests` | ❌ W0 | ⬜ pending |
| 21-xx-06 | TBD | 1 | COMM-06 | T-21-01 | Reply write: profanity-gated text rejected; sanitized text accepted | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21ReplyTests` | ❌ W0 | ⬜ pending |
| 21-xx-07 | TBD | 1 | COMM-07 | — | PostComposeSheet submits with imageData non-nil when photo attached | unit | `xcodebuild test ... -only-testing:VitaminGTests/CommunityFeedViewModelTests` | ✅ extend | ⬜ pending |
| 21-xx-08 | TBD | 1 | SOC-01 | T-21-02 | Applause daily gate: second call same day for same recipient is blocked | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21ApplauseDailyGateTests` | ❌ W0 | ⬜ pending |
| 21-xx-09 | TBD | 1 | SOC-01 | T-21-02 | Applause gate is per-recipient: can applaud B after applauding A same day | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21ApplauseDailyGateTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/Phase21CommunityHubViewModelTests.swift` — stubs for COMM-02, COMM-04, COMM-06 (loadAll + fire reaction)
- [ ] `VitaminGTests/Phase21ApplauseDailyGateTests.swift` — stubs for SOC-01 daily gate (same-day block + per-recipient)
- [ ] `VitaminGTests/Phase21GlowingSelectionTests.swift` — stubs for COMM-05 deterministic selection
- [ ] `VitaminGTests/Phase21ReplyTests.swift` — stubs for COMM-06 reply write + profanity gate

*Existing infrastructure to extend (not create):*
- [ ] `VitaminGTests/CommunityFeedViewModelTests.swift` — extend with COMM-07 photo attach test

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| COMM-01 goal card shows at top of Community tab | COMM-01 | Requires active UserChallenge or CloudKit FeaturedGoal record in Simulator | Open app → Community tab → verify first card shows progress circle + participant count + days remaining |
| Tapping Glimpse card opens PublicProfileView | COMM-03 | Navigation flow requires running app | Open Community tab → tap a Today's Glimpses card → verify PublicProfileView sheet appears |
| ChallengeDiscoveryView visible in Explore tab | D-06 | Tab navigation requires running app | Open Explore tab → verify ChallengeDiscovery section present; open Community tab → verify no Feed/Ideas picker |
| Ambient applause stream animates on ProfileView | SOC-02 | Requires real CloudKit Applause records for current user | Receive applause from another user → open own ProfileView → verify 👏 emojis float upward |
| "Cheers given" counter on public profile card | SOC-03 | Requires real CloudKit Applause records | Open another user's PublicProfileView → verify "Cheers given: N" count displayed |
| Floating 👏 animation on applause tap | SOC-01 D-05 | Animation timing requires visual verification | Tap applause button → verify 👏 + giverUsername label floats upward and fades; button disables after tap |
| COMM-01 fallback when no UserChallenge exists | COMM-01 | Edge case with no active challenge enrollment | Delete all active UserChallenge records → open Community tab → verify fallback UI shown (not crash or blank) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
