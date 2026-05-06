---
phase: 13
slug: challenge-platform-core-engine
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-04
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built into Xcode) |
| **Config file** | `VitaminG/VitaminG/VitaminG.xcodeproj` (scheme: VitaminG) |
| **Quick run command** | `xcodebuild test -project VitaminG/VitaminG/VitaminG.xcodeproj -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -project VitaminG/VitaminG/VitaminG.xcodeproj -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -30` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick test suite
- **After every plan wave:** Run full suite — new ChallengeStreakEngineTests + ChallengeViewModelTests must be green
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | CHAL-01 | — | N/A | unit | XCTest in-memory: ChallengeTemplate model persists and fetches | ❌ W0 | ⬜ pending |
| 13-01-02 | 01 | 1 | CHAL-02 | — | N/A | unit | XCTest in-memory: UserChallenge links to template; streak=0 | ❌ W0 | ⬜ pending |
| 13-01-03 | 01 | 1 | CHAL-03 | T-13-01 | payloadNote sanitized to 500 chars | unit | ChallengeViewModelTests: one-per-day throws on second insert | ❌ W0 | ⬜ pending |
| 13-01-04 | 01 | 1 | CHAL-04 | — | N/A | unit | Migration test: V3→V4 preserves existing DailyWin + Goal records | ❌ W0 | ⬜ pending |
| 13-02-01 | 02 | 1 | CHAL-05 | — | N/A | unit | ChallengeStreakEngineTests: gap breaks streak; DST-safe calendar | ❌ W0 | ⬜ pending |
| 13-02-02 | 02 | 1 | CHAL-06 | T-13-04 | idempotent seed guard prevents duplicates | unit | ChallengeViewModelTests: seedFeaturedTemplates inserts 3; idempotent on 2nd call | ❌ W0 | ⬜ pending |
| 13-02-03 | 02 | 1 | CHAL-07 | — | N/A | unit | ChallengeViewModelTests: boolean/numeric/multiStep payloads accepted without engine branching | ❌ W0 | ⬜ pending |
| 13-02-04 | 02 | 1 | CHAL-10 | — | N/A | unit | ChallengeViewModelTests: pendingMilestone fires once per threshold; not twice | ❌ W0 | ⬜ pending |
| 13-03-01 | 03 | 2 | CHAL-12 | T-13-02 | UUID validated before use; malformed URL returns nil | unit | NotificationSchedulerChallengeTests: correct identifier; remove on abandon | ❌ W0 | ⬜ pending |
| 13-04-01 | 04 | 2 | CHAL-08 | — | N/A | visual/manual | Human: Discovery screen shows 3 featured cards, category browse, "Build Your Own" CTA | N/A | ⬜ pending |
| 13-05-01 | 05 | 2 | CHAL-09 | T-13-01 | payloadNote ≤500 chars enforced in UI | visual/manual | Human: boolean/numeric/multi-step check-in modals render correctly per checkInType | N/A | ⬜ pending |
| 13-06-01 | 06 | 2 | CHAL-11 | — | N/A | visual/manual | Human: StreakChainView shows filled/outlined dots, today highlighted, accent color applied | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/ChallengeStreakEngineTests.swift` — stubs for CHAL-05 (currentStreak, longestStreak, DST safety)
- [ ] `VitaminGTests/ChallengeViewModelTests.swift` — stubs for CHAL-01, CHAL-02, CHAL-03, CHAL-06, CHAL-07, CHAL-10
- [ ] `VitaminGTests/NotificationSchedulerChallengeTests.swift` — stubs for CHAL-12

*Existing infrastructure (ModelContainerFactory.makeContainer(inMemory:), StreakEngineTests pattern) covers the test container setup.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Discovery screen: 3 featured cards, category browse, "Build Your Own" CTA | CHAL-08 | UI rendering requires simulator | Run app in simulator → tap Challenges tab → verify 3 cards visible, CTA present |
| Check-in modal adapts to checkInType | CHAL-09 | View-layer type switching requires visual inspection | Join Summer Body (multiStep) → tap Check In → verify 2-step wizard; Join Dry Summer (boolean) → verify toggle UI |
| StreakChainView: day dots, filled/outlined, today highlighted | CHAL-11 | Visual component requires simulator | Check in for 3+ days → open challenge detail → verify filled dots, today highlighted in accent color |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (3 new test files)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
