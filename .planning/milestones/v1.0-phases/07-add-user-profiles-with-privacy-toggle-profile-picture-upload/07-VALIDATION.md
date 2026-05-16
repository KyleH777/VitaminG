---
phase: 07
slug: add-user-profiles-with-privacy-toggle-profile-picture-upload
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-14
---

# Phase 07 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (existing VitaminGTests scheme) |
| **Config file** | Xcode scheme — VitaminGTests |
| **Quick run command** | `xcodebuild test -project VitaminG/VitaminG/VitaminG.xcodeproj -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/SchemaV2Tests 2>&1 \| tail -10` |
| **Full suite command** | `xcodebuild test -project VitaminG/VitaminG/VitaminG.xcodeproj -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -20` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick command for the task's test file
- **After every plan wave:** Run full VitaminGTests suite
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | PROF-01, PROF-02, PROF-03 | T-07-01 | Goal.isPublic defaults false; existing records preserved | unit | `xcodebuild test ... -only-testing:VitaminGTests/SchemaV2Tests` | ❌ W0 | ⬜ pending |
| 07-01-02 | 01 | 1 | PROF-01 | T-07-02 | Widget container opens migrated store without crash | build | `xcodebuild build -scheme VitaminG ...` | N/A | ⬜ pending |
| 07-02-01 | 02 | 2 | PROF-04, PROF-05, PROF-06, PROF-07 | T-07-05 | Display name max 50 chars, sanitized before insert | unit | `xcodebuild test ... -only-testing:VitaminGTests/ProfileViewModelTests` | ❌ W0 | ⬜ pending |
| 07-02-02 | 02 | 2 | PROF-10 | T-07-04 | Goal isPublic defaults false; toggle persists | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalViewModelTests` | ❌ W0 | ⬜ pending |
| 07-03-01 | 03 | 3 | PROF-08, PROF-09 | T-07-07, T-07-08 | shareURL nil when no recordID; public record only has safe fields | unit | `xcodebuild test ... -only-testing:VitaminGTests/ProfileViewModelTests` | ❌ W0 | ⬜ pending |
| 07-03-02 | 03 | 3 | PROF-09 | T-07-06 | Deep link scheme registered, URL builds correctly | build | `xcodebuild build -scheme VitaminG ...` | N/A | ⬜ pending |
| 07-04-01 | 04 | 4 | PROF-05 | — | Initials derived correctly from displayName | unit | `xcodebuild test ... -only-testing:VitaminGTests/ProfileViewModelTests` | ❌ W0 | ⬜ pending |
| 07-04-02 | 04 | 4 | PROF-05 | — | AvatarView renders without crash when photoData is nil | build | `xcodebuild build -scheme VitaminG ...` | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/SchemaV2Tests.swift` — stubs for PROF-01, PROF-02, PROF-03
- [ ] `VitaminGTests/ProfileViewModelTests.swift` — stubs for PROF-04 through PROF-09
- [ ] `VitaminGTests/GoalViewModelTests.swift` — extend to cover PROF-10 (updateGoalPublicStatus)

---

## Requirements → Behavior Map

| Req ID | Behavior | Test Type | File |
|--------|----------|-----------|------|
| PROF-01 | SchemaV2 declares 3 models (Goal, CompletionEvent, UserProfile) | unit | `SchemaV2Tests.swift` |
| PROF-02 | V1→V2 lightweight migration preserves existing Goal records | unit | `SchemaV2Tests.swift` |
| PROF-03 | Goal.isPublic defaults to false on existing and new records | unit | `SchemaV2Tests.swift` |
| PROF-04 | ProfileViewModel creates exactly one UserProfile on first call | unit | `ProfileViewModelTests.swift` |
| PROF-05 | ProfileViewModel.initials returns correct 1-2 char string | unit | `ProfileViewModelTests.swift` |
| PROF-06 | ProfileViewModel.displayName validation rejects empty/whitespace | unit | `ProfileViewModelTests.swift` |
| PROF-07 | ProfileViewModel.displayName validation rejects >50 chars | unit | `ProfileViewModelTests.swift` |
| PROF-08 | ProfileViewModel.shareURL returns nil when cloudKitPublicRecordID is nil | unit | `ProfileViewModelTests.swift` |
| PROF-09 | ProfileViewModel.shareURL returns valid vitaming:// URL when recordID is set | unit | `ProfileViewModelTests.swift` |
| PROF-10 | GoalViewModel.updateGoalPublicStatus persists isPublic change | unit | `GoalViewModelTests.swift` |
