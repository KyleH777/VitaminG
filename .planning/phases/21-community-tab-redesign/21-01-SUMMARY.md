---
phase: 21-community-tab-redesign
plan: "01"
subsystem: community
tags: [models, tdd, scaffolding, value-types, red-tests]
dependency_graph:
  requires: []
  provides:
    - GoalGlimpseItem
    - UserPresenceItem
    - ApplauseItem
    - CommunityReplyItem
    - Phase21CommunityHubViewModelTests
    - Phase21ApplauseDailyGateTests
    - Phase21GlowingSelectionTests
    - Phase21ReplyTests
  affects:
    - VitaminGTests target (four new test classes)
    - Plan 21-02 CommunityService (consumes model types)
    - Plan 21-03 CommunityHubViewModel (must make RED tests pass)
tech_stack:
  added: []
  patterns:
    - Pure value type models with Identifiable + Sendable (mirrors ExploreModels pattern)
    - XCTest RED stubs with commented assertion bodies for implementor guidance
    - Isolated UserDefaults suites per test (UUID-suffixed suiteName)
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Models/CommunityHubModels.swift
    - VitaminG/VitaminG/VitaminGTests/Phase21CommunityHubViewModelTests.swift
    - VitaminG/VitaminG/VitaminGTests/Phase21ApplauseDailyGateTests.swift
    - VitaminG/VitaminG/VitaminGTests/Phase21GlowingSelectionTests.swift
    - VitaminG/VitaminG/VitaminGTests/Phase21ReplyTests.swift
  modified: []
decisions:
  - CommunityHubModels.swift imports Foundation only — no CloudKit dependency; CommunityService (Plan 02) owns the CKRecord-to-value-type mapping
  - Test stubs use XCTFail("Not yet implemented") with commented assertion bodies so Plan 03 implementors see exactly what each test must verify
  - UserDefaults isolation via UUID-suffixed suiteName prevents cross-test state contamination for applause gate tests
  - Xcode 26 fileSystemSynchronizedGroups (PBXFileSystemSynchronizedRootGroup) means new Swift files placed in target folders are auto-included in the build — no pbxproj edits required
metrics:
  duration: "5m 6s"
  completed: "2026-05-23T22:35:46Z"
  tasks_completed: 2
  files_created: 5
  files_modified: 0
---

# Phase 21 Plan 01: Wave 0 Scaffolding Summary

**One-liner:** Four pure value-type structs in CommunityHubModels.swift plus four RED XCTest stub files establishing the Nyquist test contract for all Phase 21 logic requirements.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create CommunityHubModels.swift | 5317c7c | VitaminG/VitaminG/VitaminG/Models/CommunityHubModels.swift |
| 2 | Create four RED test stub files | 04a7213 | VitaminGTests/Phase21CommunityHubViewModelTests.swift, Phase21ApplauseDailyGateTests.swift, Phase21GlowingSelectionTests.swift, Phase21ReplyTests.swift |

## What Was Built

**CommunityHubModels.swift** defines four pure value types that mirror CloudKit CKRecord field keys from RESEARCH.md:

- `GoalGlimpseItem` — username, goalTitle, progressPercent (Int), authorColorHex, photoFileURL (URL?), dayKey
- `UserPresenceItem` — username, authorColorHex, lastActiveDate (Date)
- `ApplauseItem` — giverUsername, recipientUsername, creationDate (Date)
- `CommunityReplyItem` — parentPostID, text, authorDisplayName, authorColorHex, creationDate (Date)

All structs conform to `Identifiable` (id: String) and `Sendable`. Import Foundation only.

**Four RED test files** establish the Nyquist contract for every substantive logic item in Phase 21:

- `Phase21CommunityHubViewModelTests`: loadAll fan-out (COMM-06), activeToday 2-hour filter (COMM-04), fire reaction fieldKey (COMM-06)
- `Phase21ApplauseDailyGateTests`: canApplaud fresh state (SOC-01), same-day block (SOC-01), per-recipient gate (SOC-01)
- `Phase21GlowingSelectionTests`: deterministic result (COMM-05), nil for empty array (COMM-05), ISO8601 weekOfYear index (COMM-05)
- `Phase21ReplyTests`: profanity rejection (COMM-06), sanitized text write (COMM-06)

All test methods call `XCTFail("Not yet implemented")` with commented assertion bodies documenting exact expectations for Plan 03 implementors.

## Verification Results

- Build: **BUILD SUCCEEDED** (zero Swift errors)
- `grep "struct GoalGlimpseItem"`: FOUND in CommunityHubModels.swift
- `grep "class Phase21CommunityHubViewModelTests"`: FOUND
- `grep "class Phase21ApplauseDailyGateTests"`: FOUND
- `grep "class Phase21GlowingSelectionTests"`: FOUND
- `grep "class Phase21ReplyTests"`: FOUND

## Deviations from Plan

None — plan executed exactly as written.

The only notable discovery: Xcode 26 uses `fileSystemSynchronizedGroups` (PBXFileSystemSynchronizedRootGroup) for both the VitaminG and VitaminGTests targets. New Swift files placed in the correct filesystem directories are automatically included in the build — no `project.pbxproj` modifications required.

## Known Stubs

None. This plan creates stub test files by design (RED TDD state). The stubs are intentional Wave 0 scaffolding — they will be made to pass by Plan 03 implementation work.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. CommunityHubModels.swift is pure value types with no mutable global state; Sendable conformance prevents data races (T-21-01-01 accepted).

## Self-Check: PASSED

- VitaminG/VitaminG/VitaminG/Models/CommunityHubModels.swift: FOUND
- VitaminG/VitaminG/VitaminGTests/Phase21CommunityHubViewModelTests.swift: FOUND
- VitaminG/VitaminG/VitaminGTests/Phase21ApplauseDailyGateTests.swift: FOUND
- VitaminG/VitaminG/VitaminGTests/Phase21GlowingSelectionTests.swift: FOUND
- VitaminG/VitaminG/VitaminGTests/Phase21ReplyTests.swift: FOUND
- Commit 5317c7c: FOUND (Task 1)
- Commit 04a7213: FOUND (Task 2)
