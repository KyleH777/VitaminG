---
phase: 1
slug: foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-04
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built into Xcode) |
| **Config file** | None — uses default Xcode test target |
| **Quick run command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` |
| **Full suite command** | Same as quick (Phase 1 suite is small; single command covers all) |
| **Estimated runtime** | ~30–60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- **After every plan wave:** Full suite + physical device smoke test for FOUND-06
- **Before `/gsd:verify-work`:** All unit tests green + physical device smoke test passing
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-T1 | 01-01 | 1 | FOUND-02, FOUND-03, FOUND-04, FOUND-05, FOUND-06 | unit + manual | `xcodebuild test -scheme VitaminG` | ❌ W0 | ⬜ pending |
| 01-01-T2 | 01-01 | 1 | FOUND-05 | manual | N/A (Xcode Signing & Capabilities) | — | ⬜ pending |
| 01-02-T1 | 01-02 | 1 | FOUND-01, FOUND-08 | unit + code review | `xcodebuild test -scheme VitaminG` | ❌ W0 | ⬜ pending |
| 01-02-T2 | 01-02 | 1 | FOUND-01, FOUND-07 | unit | `xcodebuild test -scheme VitaminG` | ❌ W0 | ⬜ pending |
| 01-03-T1 | 01-03 | 2 | FOUND-02, FOUND-03, FOUND-04, FOUND-07 | unit | `xcodebuild test -scheme VitaminG` | ❌ W0 | ⬜ pending |
| 01-03-T2 | 01-03 | 2 | FOUND-03 | unit | `xcodebuild test -scheme VitaminG` | ❌ W0 | ⬜ pending |
| 01-03-T3 | 01-03 | 2 | FOUND-06 | smoke (physical device) | Manual | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/GoalViewModelTests.swift` — covers FOUND-02, FOUND-03, FOUND-04, FOUND-07 (validation scenarios)
- [ ] `VitaminGTests/SchemaV1Tests.swift` — confirms VersionedSchema declaration compiles and model types are included
- [ ] `VitaminG/Persistence/ModelContainerFactory.swift` — shared factory used by both app and test suite (in-memory config for tests)

*(No existing test infrastructure — greenfield project. Full test scaffolding is a Wave 0 / Plan 01-03 task.)*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App Group entitlement on both targets | FOUND-05 | Xcode Signing & Capabilities UI; not scriptable | Open project → select VitaminG target → Signing & Capabilities → confirm `group.com.kyleharrington.VitaminG` present; repeat for VitaminGWidget target |
| ModelContainer launches on physical device | FOUND-06 | Simulator does not fully test CloudKit + App Group entitlements | Build and run on physical iPhone → confirm no crash at launch → check Console for CloudKit init errors |
