---
phase: 04-icloud-sync-widgets
plan: 01
subsystem: widget-integration
tags: [widgetkit, swiftdata, app-group, userdefaults, streak, settings]
dependency_graph:
  requires: []
  provides:
    - WidgetCenter reload on all goal mutations
    - Widget-safe ModelContainer factory (cloudKitDatabase: .none)
    - Settings global streak row with brand gradient
    - App Group UserDefaults writes for notification time
    - Wave 0 test stubs for WidgetDataProvider and timeline logic
  affects:
    - VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
    - VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift
    - VitaminG/VitaminG/VitaminG/Views/SettingsView.swift
    - VitaminG/VitaminG/VitaminGTests/WidgetDataProviderTests.swift
    - VitaminG/VitaminG/VitaminGTests/WidgetTimelineTests.swift
tech_stack:
  added:
    - WidgetKit (imported in GoalViewModel for WidgetCenter)
  patterns:
    - reloadWidgetTimelines() private helper called after every goal mutation
    - makeWidgetContainer() with cloudKitDatabase: .none for widget process safety
    - App Group UserDefaults written on onChange and onAppear for widget read access
    - XCTExpectFailure for Wave 0 stub tests to keep suite green
key_files:
  created:
    - VitaminG/VitaminG/VitaminGTests/WidgetDataProviderTests.swift
    - VitaminG/VitaminG/VitaminGTests/WidgetTimelineTests.swift
  modified:
    - VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
    - VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift
    - VitaminG/VitaminG/VitaminG/Views/SettingsView.swift
decisions:
  - "reloadWidgetTimelines() extracted as private helper (not inline) so each call site is a single clean line matching CLAUDE.md MVVM conventions"
  - "makeWidgetContainer() uses cloudKitDatabase: .none — widget process has no iCloud entitlement so .automatic would crash on device (Pitfall 2)"
  - "App Group UserDefaults written on both onAppear and onChange — onAppear ensures widget can read defaults even before user changes the time"
  - "XCTExpectFailure used for Wave 0 stubs — test suite stays green while clearly marking unimplemented logic for Plan 02"
  - "iPhone 16 simulator unavailable — used iPhone 17 for all xcodebuild invocations (same iOS 26.4 runtime)"
metrics:
  duration: "~27 minutes"
  completed_date: "2026-04-07"
  tasks_completed: 3
  files_modified: 5
requirements:
  - SYNC-01
  - SYNC-02
  - WIDGET-03
  - WIDGET-05
---

# Phase 04 Plan 01: Widget Integration Wiring Summary

**One-liner:** Wired GoalViewModel WidgetCenter reload on all 4 mutations, added widget-safe ModelContainer factory with `cloudKitDatabase: .none`, added Settings global streak row with brand gradient, and wrote notification time to App Group UserDefaults; Wave 0 XCTExpectFailure stubs enable TDD for Plan 02.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 0 | Create Wave 0 test stubs (Nyquist) | `969a4d4` | WidgetDataProviderTests.swift, WidgetTimelineTests.swift |
| 1 | Wire GoalViewModel WidgetCenter reload + ModelContainerFactory widget variant | `e94dbea` | GoalViewModel.swift, ModelContainerFactory.swift |
| 2 | Settings streak row + App Group UserDefaults for notification time | `6e9076e` | SettingsView.swift |

## What Was Built

### Task 0 — Wave 0 Test Stubs
Two new test files added to VitaminGTests:

- `WidgetDataProviderTests.swift`: 5 stubs covering WIDGET-01 (tier rows, top goal selection, empty tier) and WIDGET-02 (global streak, empty goals). All use `XCTExpectFailure` so the suite stays green.
- `WidgetTimelineTests.swift`: 3 stubs covering WIDGET-05 (`nextMorningRefreshDate` before/after target time and default 8AM fallback). All use `XCTExpectFailure`.

Project uses `PBXFileSystemSynchronizedRootGroup` — no pbxproj editing required; files are picked up automatically.

### Task 1 — GoalViewModel + ModelContainerFactory
**GoalViewModel.swift:**
- Added `import WidgetKit` 
- Added `private func reloadWidgetTimelines()` helper calling `WidgetCenter.shared.reloadAllTimelines()`
- Added `reloadWidgetTimelines()` call as last line of `addGoal`, `toggleCompletion`, `updateGoal`, and `delete` — after `rescheduleNotification`

**ModelContainerFactory.swift:**
- Added `static func makeWidgetContainer() throws -> ModelContainer`
- Uses `cloudKitDatabase: .none` on device (widget process has no iCloud entitlement; `.automatic` would crash)
- Uses same `groupContainer: .identifier("group.com.kyleharrington.VitaminG")` as main container
- Simulator path uses simple `ModelConfiguration` without App Group (same simulator guard pattern as `makeContainer`)

### Task 2 — SettingsView
**Streak motivational row (D-02):**
- Added `@Query private var allEvents: [CompletionEvent]`
- Added `private var globalStreak: Int` computed via `StreakEngine.currentStreak(from: allEvents)`
- When `globalStreak > 0`: shows large bold monospaced number with `LinearGradient` (orange `Color(red: 0.98, green: 0.55, blue: 0.27)` → purple `Color(red: 0.78, green: 0.48, blue: 0.95)`), subtitle "day streak" / "days streak", and `accessibilityLabel` for VoiceOver
- When `globalStreak == 0`: shows "Start completing goals to build your streak" encouragement

**App Group UserDefaults writes (D-06, Pitfall 3):**
- In `.onChange(of: notificationTime)`: writes `notificationHour` and `notificationMinute` to `UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")` after the existing `UserDefaults.standard` writes
- In `.onAppear`: reads current `notificationTime` components and syncs to App Group suite — ensures widget can read the default 8:00 AM before the user ever changes the time

## Verification Results

| Check | Result |
|-------|--------|
| `xcodebuild build -scheme VitaminG` | SUCCEEDED |
| `xcodebuild test VitaminGTests` (full suite) | SUCCEEDED |
| Wave 0 stubs pass via XCTExpectFailure | 8/8 expected failures recorded |
| `WidgetCenter.shared.reloadAllTimelines()` in GoalViewModel | Confirmed (line 149) |
| `makeWidgetContainer` in ModelContainerFactory | Confirmed (line 36) |
| `UserDefaults(suiteName:` in SettingsView | Confirmed (lines 94, 121 — 2 occurrences) |
| `largeTitle` + `LinearGradient` in SettingsView | Confirmed |

## Deviations from Plan

### Auto-adjusted: Simulator name

- **Found during:** Tasks 0, 1, 2 (all verification steps)
- **Issue:** iPhone 16 simulator not available — system has iOS 26.4 with iPhone 17 family
- **Fix:** Used `platform=iOS Simulator,name=iPhone 17` for all xcodebuild invocations
- **Impact:** None — same iOS runtime, equivalent testing surface

No other deviations — plan executed as written.

## Known Stubs

None — all stubs are in the Wave 0 test files and are intentional (`XCTExpectFailure`). They do not affect runtime behavior. Plan 02 will implement the actual `WidgetDataProvider` and `nextMorningRefreshDate` logic against these stubs.

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes introduced. App Group UserDefaults writes are within the existing sandboxed developer team boundary (T-04-01 accepted). WidgetCenter reload calls are on actual goal mutations only — no timer or loop abuse (T-04-03 mitigated as designed).

## Self-Check: PASSED

All files exist:
- FOUND: VitaminG/VitaminG/VitaminGTests/WidgetDataProviderTests.swift
- FOUND: VitaminG/VitaminG/VitaminGTests/WidgetTimelineTests.swift
- FOUND: VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
- FOUND: VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift
- FOUND: VitaminG/VitaminG/VitaminG/Views/SettingsView.swift

All commits present:
- 969a4d4: test(04-01): add Wave 0 test stubs for WidgetDataProvider and timeline refresh
- e94dbea: feat(04-01): wire WidgetCenter reload on goal mutations + widget-safe ModelContainer
- 6e9076e: feat(04-01): Settings streak row with brand gradient + App Group UserDefaults sync
