---
phase: 07-add-user-profiles-with-privacy-toggle-profile-picture-upload
plan: 01
subsystem: data-layer
tags: [swiftdata, schema-migration, cloudkit, user-profile, versioned-schema]
dependency_graph:
  requires: []
  provides: [SchemaV2, UserProfile, VitaminGMigrationPlan, Goal.isPublic]
  affects: [ModelContainerFactory, AppRoute, ContentView, VitaminGWidgetExtension]
tech_stack:
  added: [SwiftData SchemaMigrationPlan, VitaminGMigrationPlan]
  patterns: [VersionedSchema, lightweight migration, PBXFileSystemSynchronizedRootGroup + manual widget sources]
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Models/SchemaV2.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Models/SchemaV1.swift
    - VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift
    - VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift
    - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
    - VitaminG/VitaminG/VitaminG.xcodeproj/project.pbxproj
decisions:
  - "SchemaV2 redeclares all models (Goal, CompletionEvent, UserProfile) inside enum per VersionedSchema pattern"
  - "VitaminGMigrationPlan uses MigrationStage.lightweight for V1->V2 — adding isPublic with default and new UserProfile both qualify"
  - "Both makeContainer and makeWidgetContainer use identical schema + migration plan to prevent store mismatch crash (T-07-02)"
  - "ContentView .profile navigation case added as EmptyView placeholder — ProfileView wired in Plan 02"
  - "SchemaV2.swift added to VitaminGWidgetExtension target Sources manually (widget uses explicit file list, not PBXFileSystemSynchronizedRootGroup)"
metrics:
  duration_minutes: 25
  completed_date: "2026-04-13"
  tasks_completed: 2
  files_changed: 6
---

# Phase 7 Plan 01: SchemaV2 Migration — Data Layer Foundation Summary

**One-liner:** Lightweight SwiftData V1→V2 migration adding UserProfile model and Goal.isPublic via VitaminGMigrationPlan, wired into both main and widget containers.

## What Was Built

Plan 07-01 establishes the data layer foundation for Phase 7 user profiles. Two tasks:

**Task 1 — SchemaV2.swift created:**
- `SchemaV2.Goal` with all V1 fields plus `isPublic: Bool = false` (D-08, D-10)
- `SchemaV2.CompletionEvent` redeclared unchanged (all V2 models must live in SchemaV2 enum)
- `SchemaV2.UserProfile` with all D-13 fields: id, displayName, avatarColorHex, isPublic, cloudKitPublicRecordID, photoData (reserved nil)
- `VitaminGMigrationPlan` with `MigrationStage.lightweight(from: SchemaV1, to: SchemaV2)`
- V2 typealiases: `Goal`, `CompletionEvent`, `UserProfile` pointing to SchemaV2 types
- `Color+Hex` extension for avatar color persistence
- V1 typealiases removed from SchemaV1.swift (schema frozen)
- SchemaV2.swift registered in pbxproj for both VitaminG (auto-sync) and VitaminGWidgetExtension (manual sources list) targets

**Task 2 — Factory and navigation updated:**
- `ModelContainerFactory.makeContainer`: Schema(SchemaV2.models) + migrationPlan: VitaminGMigrationPlan.self
- `ModelContainerFactory.makeWidgetContainer`: same schema + migration plan (T-07-02 mitigation — prevents store mismatch crash)
- `initializeCloudKitSchema` (DEBUG): UserProfile.self added to model list
- `AppRoute.profile` case added for deep-link navigation (D-11)
- `ContentView` navigationDestination switch exhaustiveness fixed (EmptyView placeholder for .profile until Plan 02)

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 9895721 | feat(07-01): create SchemaV2 with UserProfile, isPublic migration, and VitaminGMigrationPlan |
| 2 | 8a0dcba | feat(07-01): wire SchemaV2 + VitaminGMigrationPlan into ModelContainerFactory and AppRoute |

## Verification Results

1. Project builds with `** BUILD SUCCEEDED **` — no errors
2. SchemaV2.swift contains Goal (isPublic), CompletionEvent, UserProfile, VitaminGMigrationPlan
3. ModelContainerFactory references SchemaV2.models in both makeContainer and makeWidgetContainer
4. SchemaV1.swift typealiases removed; SchemaV2.swift typealiases point to V2 types
5. AppRoute has .profile case

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ContentView.swift exhaustive switch broken by .profile addition**
- **Found during:** Task 2
- **Issue:** Adding `case .profile` to `AppRoute` caused a compiler error in ContentView.swift: "switch must be exhaustive"
- **Fix:** Added `case .profile: EmptyView()` placeholder to the navigationDestination switch. ProfileView will replace this in Plan 02.
- **Files modified:** VitaminG/VitaminG/VitaminG/Views/ContentView.swift
- **Commit:** 8a0dcba

**2. [Rule 3 - Blocking] SchemaV2.swift not included in VitaminGWidgetExtension target**
- **Found during:** Task 1 build verification
- **Issue:** The widget target uses an explicit manual Sources list (not PBXFileSystemSynchronizedRootGroup like the main app target), so SchemaV2.swift was not automatically compiled for the widget extension.
- **Fix:** Added PBXBuildFile and PBXFileReference entries to the worktree's project.pbxproj and added SchemaV2.swift to the `AA010000000000015 /* Sources (VitaminGWidgetExtension) */` build phase.
- **Files modified:** VitaminG/VitaminG/VitaminG.xcodeproj/project.pbxproj
- **Commit:** 9895721

## Known Stubs

- `ContentView.swift` line 44: `case .profile: EmptyView()` — placeholder until ProfileView is created in Plan 02. Does not block Plan 01 goal (data layer migration); intentional stub documented here.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries beyond what the plan's threat model covers. T-07-01 (lightweight migration default values), T-07-02 (widget store mismatch), and T-07-03 (photoData reserved nil) are all addressed as planned.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| SchemaV2.swift exists | FOUND |
| ModelContainerFactory.swift exists | FOUND |
| AppRoute.swift exists | FOUND |
| Commit 9895721 (Task 1) | FOUND |
| Commit 8a0dcba (Task 2) | FOUND |
