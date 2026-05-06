---
phase: 13-challenge-platform-core-engine
plan: "01"
subsystem: data-layer
tags: [swiftdata, schema-migration, challenge-platform, cloudkit]
dependency_graph:
  requires: []
  provides: [SchemaV4, ChallengeTemplate, UserChallenge, CheckIn, migrateV3toV4]
  affects: [VitaminGMigrationPlan, ModelContainerFactory]
tech_stack:
  added: []
  patterns: [VersionedSchema, lightweight-migration, CloudKit-compatible-model-properties]
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Models/SchemaV4.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift
    - VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift
    - VitaminG/VitaminG/VitaminG.xcodeproj/project.pbxproj
decisions:
  - SchemaV4 follows exact SchemaV3 enum pattern with all properties optional or defaulted for CloudKit compatibility
  - V3 to V4 migration uses lightweight stage (purely additive — 3 new models, no existing model changes)
  - Widget container updated to SchemaV4 alongside main container to prevent store schema mismatch crash (Pitfall 2)
  - SchemaV4.swift registered in project.pbxproj as explicit file reference for VitaminGWidgetExtension target (Rule 3 deviation)
metrics:
  duration_seconds: 262
  completed_date: "2026-05-06"
  tasks_completed: 3
  files_modified: 4
requirements: [CHAL-01, CHAL-02, CHAL-03, CHAL-04]
---

# Phase 13 Plan 01: Challenge Platform Data Layer — SchemaV4 Summary

**One-liner:** SwiftData SchemaV4 with ChallengeTemplate, UserChallenge, CheckIn @Model classes via additive lightweight V3→V4 migration, wired into both main and widget ModelContainers.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Create SchemaV4 with ChallengeTemplate, UserChallenge, CheckIn | a44a15c | VitaminG/Models/SchemaV4.swift (created) |
| 2 | Add migrateV3toV4 to VitaminGMigrationPlan | 8cb83e9 | VitaminG/Models/VitaminGMigrationPlan.swift |
| 3 | Update ModelContainerFactory to SchemaV4 + project.pbxproj | ecce595 | VitaminG/Persistence/ModelContainerFactory.swift, project.pbxproj |

## Must-Haves Satisfied

- ChallengeTemplate, UserChallenge, and CheckIn @Model types declared in SchemaV4 with all properties optional or defaulted — CloudKit compatible
- Migration plan extends V1→V2→V3→V4 chain with lightweight stage (additive-only; no data loss to existing Goal/CompletionEvent/UserProfile/DailyWin records)
- Both makeContainer and makeWidgetContainer reference SchemaV4.models (Pitfall 2 avoided)
- DEBUG initializeCloudKitSchema includes all 7 model types (Pitfall 3 avoided)
- No @Attribute(.unique) on any new model property
- Both sides of every @Relationship declare inverse: (ChallengeTemplate↔UserChallenge, UserChallenge↔CheckIn)
- Build verified: BUILD SUCCEEDED on iPhone 17 simulator

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocker] Added SchemaV4.swift to project.pbxproj for widget extension target**

- **Found during:** Task 3 build verification
- **Issue:** The widget extension (VitaminGWidgetExtension) uses explicit file references (PBXBuildFile / PBXFileReference — "Recovered References" group) rather than PBXFileSystemSynchronizedRootGroup. SchemaV4.swift was placed in the `Models/` folder (picked up automatically by the main app's synchronized root group) but was absent from the widget extension's Sources build phase, causing `error: cannot find 'SchemaV4' in scope` at VitaminGMigrationPlan.swift line 21 and 40 during widget compilation.
- **Fix:** Added PBXFileReference (`AA01000000000021`) and PBXBuildFile (`AA01000000000020`) entries to project.pbxproj; added build file to widget extension Sources build phase (`AA010000000000015`); added file ref to "Recovered References" group.
- **Files modified:** VitaminG/VitaminG/VitaminG.xcodeproj/project.pbxproj
- **Commit:** ecce595

## Known Stubs

None — this plan creates data models only. No UI rendering, no computed display values, no placeholder text.

## Threat Flags

None — all three threat register mitigations applied:
- T-13-01: All new model properties optional or defaulted; no @Attribute(.unique); @Relationship inverses declared on both sides
- T-13-02: Lightweight migration (additive-only); both containers updated together
- T-13-03: makeWidgetContainer updated to SchemaV4 (grep -c "SchemaV4.models" returns 2)
- T-13-04: DEBUG initializeCloudKitSchema includes ChallengeTemplate/UserChallenge/CheckIn

## Self-Check: PASSED

- SchemaV4.swift exists: FOUND
- VitaminGMigrationPlan.swift contains migrateV3toV4: FOUND
- ModelContainerFactory.swift: SchemaV4.models count = 2, SchemaV3.models count = 0: FOUND
- Build: BUILD SUCCEEDED
- Commits a44a15c, 8cb83e9, ecce595: all present in git log
