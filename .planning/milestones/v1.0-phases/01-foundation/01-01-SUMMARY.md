---
phase: 01-foundation
plan: 01
subsystem: data-layer
tags: [swiftdata, cloudkit, versioned-schema, app-groups, widget-stub, entitlements]
dependency_graph:
  requires: []
  provides: [SchemaV1, ModelContainerFactory, VitaminGApp, entitlements, widget-stub]
  affects: [02-mvvm-views, 03-notifications, 04-widget, 06-cloudkit]
tech_stack:
  added: [SwiftData, CloudKit, WidgetKit]
  patterns: [VersionedSchema, ModelContainerFactory, App-Groups-shared-container]
key_files:
  created:
    - VitaminG/Models/SchemaV1.swift
    - VitaminG/Persistence/ModelContainerFactory.swift
    - VitaminG/VitaminGApp.swift
    - VitaminG/VitaminG.entitlements
    - VitaminGWidget/VitaminGWidgetBundle.swift
    - VitaminGWidget/VitaminGWidget.entitlements
  modified:
    - VitaminG/Models/Goal.swift
key_decisions:
  - "SchemaV1 VersionedSchema declared from first commit — cannot be retrofitted once user data exists"
  - "All Goal/CompletionEvent properties optional or defaulted for CloudKit compatibility"
  - "No @Attribute(.unique) anywhere — CloudKit cannot enforce atomic uniqueness across devices"
  - "goalDescription used instead of description to avoid NSObject.description shadowing"
  - "App Group group.com.kyleharrington.VitaminG identical in both entitlements — retrofitting causes store path change"
  - "Widget target scaffolded in Phase 1 with App Group entitlement but zero widget UI (D-06)"
  - "initializeCloudKitSchema gated by #if DEBUG — slow but non-fatal; ensures full schema registration"
metrics:
  duration: "~5 minutes"
  completed: "2026-04-04"
  tasks: 2
  files_created: 6
  files_modified: 1
---

# Phase 01 Plan 01: SwiftData Foundation Summary

**One-liner:** SchemaV1 VersionedSchema wrapping Goal+CompletionEvent models, ModelContainerFactory with App Group + CloudKit configuration, entitlements on both targets, and widget scaffold stub.

## What Was Built

The permanent data layer foundation for Vitamin G — all decisions that cannot change after user data exists are locked in:

1. **SchemaV1 VersionedSchema** (`VitaminG/Models/SchemaV1.swift`): Both `Goal` and `CompletionEvent` `@Model` classes declared inside `SchemaV1: VersionedSchema`. All properties optional or defaulted. No `@Attribute(.unique)`. `goalDescription` avoids NSObject.description shadow. Relationship declared with `deleteRule: .cascade`. Typealiases exported for clean call sites.

2. **GoalTier enum preserved** (`VitaminG/Models/Goal.swift`): `@Model` classes removed; only `GoalTier` enum remains with display metadata (icon, color, typographicWeight).

3. **ModelContainerFactory** (`VitaminG/Persistence/ModelContainerFactory.swift`): Static `makeContainer(inMemory:)` creates either production container (App Group + CloudKit) or in-memory container for testing. `#if DEBUG` extension adds `initializeCloudKitSchema` via `NSPersistentCloudKitContainer` to force full CloudKit attribute registration.

4. **App entry point** (`VitaminG/VitaminGApp.swift`): Uses `.modelContainer(container)` on WindowGroup (not `.modelContext`) per iOS 18 safety. `#if DEBUG` block calls `initializeCloudKitSchema`.

5. **Main target entitlements** (`VitaminG/VitaminG.entitlements`): App Groups + iCloud container identifier + CloudKit service.

6. **Widget stub** (`VitaminGWidget/VitaminGWidgetBundle.swift` + `VitaminGWidget/VitaminGWidget.entitlements`): Placeholder widget with `.containerBackground` iOS 17+ compliance. App Group entitlement only (no iCloud — widget is read-only). Zero widget UI — Phase 4 fills this in.

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| VersionedSchema from day one | Cannot be retrofitted after user data exists without a migration |
| App Group in Phase 1 | Retrofitting App Group changes the store path, losing all existing user data |
| All properties optional/defaulted | CloudKit requirement — non-optional without default silently breaks sync |
| No @Attribute(.unique) | CloudKit cannot enforce atomic uniqueness across devices |
| goalDescription not description | Shadows NSObject.description causing subtle runtime bugs |
| Widget target stub in Phase 1 | Same store path risk as App Group — must exist before any data persisted |
| .modelContainer on WindowGroup | Avoids iOS 18 auto-save bug when using .modelContext |

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

- `VitaminGWidget/VitaminGWidgetBundle.swift`: `VitaminGWidgetPlaceholder` is an intentional stub per D-06. Phase 4 will add `AppIntentConfiguration` and real widget UI. The stub satisfies `WidgetBundle` requirements and ensures the App Group entitlement is configured.

## Self-Check: PASSED

All 7 files verified on disk. Both task commits (9650c9a, f10d97e) verified in git log.
