---
phase: 07-add-user-profiles-with-privacy-toggle-profile-picture-upload
plan: "02"
subsystem: ProfileUI
tags: [profile, privacy, swiftui, swiftdata, observable, mvvm]
dependency_graph:
  requires: [07-01]
  provides: [ProfileView, ProfileViewModel, ProfileEditSheet, GoalPublicToggle]
  affects: [ContentView, GoalDetailView, GoalViewModel]
tech_stack:
  added: []
  patterns: ["@Observable ProfileViewModel", "@Bindable in sheets", "Color(hex:) extension from SchemaV2"]
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/ViewModels/ProfileViewModel.swift
    - VitaminG/VitaminG/VitaminG/Views/ProfileView.swift
    - VitaminG/VitaminG/VitaminG/Views/ProfileEditSheet.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
    - VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
decisions:
  - "GoalDetailView houses the per-goal isPublic toggle (publicToggleSection) rather than AddGoalView — goals are private by default at creation; toggling from detail screen is the intended UX"
  - "@Bindable required on ProfileEditSheet.viewModel for $viewModel bindings with @Observable class"
  - "import UIKit added to ProfileView for Color(UIColor.systemGroupedBackground) usage"
metrics:
  duration: "~15 min"
  completed: "2026-04-13"
  tasks_completed: 2
  files_changed: 6
---

# Phase 07 Plan 02: Profile UI Layer Summary

ProfileView, ProfileViewModel, and ProfileEditSheet with per-goal public/private toggle wired into GoalDetailView and GoalViewModel.

## What Was Built

### ProfileViewModel (new)
`@Observable` class managing the singleton UserProfile lifecycle:
- `loadOrCreateProfile(context:)` — fetches or creates UserProfile on first tab visit, assigns random avatar color from 6-color palette, persists hex string
- `validateAndSaveDisplayName(context:)` — sanitizes input (mirrors GoalViewModel.sanitize), enforces 50-char cap, saves
- `toggleProfilePublic(context:)` — flips isPublic on UserProfile, persists
- `initials` computed from displayName (max 2 chars, uppercase, returns "?" when empty)
- `avatarColor` parsed from avatarColorHex via `Color(hex:)` extension in SchemaV2
- `shareURL` stub returning nil until Plan 03 populates cloudKitPublicRecordID

### ProfileView (new)
4th tab view with:
- Avatar circle (88pt) filled with avatarColor, showing initials
- Display name row with pencil edit button triggering ProfileEditSheet
- Privacy toggle section with contextual explanatory text
- Public Goals section: live `@Query` for `isPublic == true` goals, empty state, tier pip list
- Share Profile button (disabled when profile is private)

### ProfileEditSheet (new)
Sheet for editing display name:
- 50-char inline enforcement via `onChange`
- Character counter
- Validate-and-save on "Update Name" tap, dismiss on success

### ContentView (modified)
Added 4th Profile tab with `person.crop.circle.fill` icon, `ProfileView()` wired inside `NavigationStack`. Added `.profile` route to `navigationDestination`.

### GoalDetailView (modified)
Added `publicToggleSection` — "Share this goal" toggle calling `viewModel.updateGoalPublicStatus(goal:isPublic:context:)`. Accessible with combined label and value.

### GoalViewModel (modified)
Added `updateGoalPublicStatus(goal:isPublic:context:)` — sets `goal.isPublic`, saves context, reloads WidgetKit timelines.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ProfileEditSheet missing @Bindable on viewModel**
- **Found during:** Build verification
- **Issue:** `ProfileEditSheet` declared `var viewModel: ProfileViewModel` without `@Bindable`, causing `$viewModel` bindings (TextField, alert) to fail with "cannot find '$viewModel' in scope"
- **Fix:** Added `@Bindable` to the property declaration
- **Files modified:** ProfileEditSheet.swift
- **Commit:** f87ecdf

**2. [Rule 2 - Missing import] ProfileView missing import UIKit**
- **Found during:** Pre-build analysis per task instructions
- **Issue:** `Color(UIColor.systemGroupedBackground)` on line 30 requires UIKit, but only SwiftUI and SwiftData were imported
- **Fix:** Added `import UIKit` after existing imports
- **Files modified:** ProfileView.swift
- **Commit:** f87ecdf

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| `shareURL` always nil | ProfileViewModel.swift | 89-92 | Plan 03 wires CloudKit public record ID; share URL cannot be constructed until profile is published to CloudKit public DB |
| Share Profile button action | ProfileView.swift | 185-188 | `UIActivityViewController` presentation deferred to Plan 03 which wires the full share flow |

## Self-Check: PASSED

Files confirmed present:
- VitaminG/VitaminG/VitaminG/ViewModels/ProfileViewModel.swift: FOUND
- VitaminG/VitaminG/VitaminG/Views/ProfileView.swift: FOUND
- VitaminG/VitaminG/VitaminG/Views/ProfileEditSheet.swift: FOUND

Commits confirmed:
- f60d4ab: feat(07-02): add ProfileViewModel with display name validation and privacy toggle
- f87ecdf: feat(07-02): add ProfileView, ProfileEditSheet, and wire Profile tab in ContentView
