---
phase: 21-community-tab-redesign
plan: "04"
subsystem: community-compose
tags: [community, photo-picker, camera, reply-sheet, profanity-gate, cloudkit, tdd]
dependency_graph:
  requires: [21-01, 21-02, 21-03]
  provides: [CommunityReplySheetView, camera-confirmationDialog-in-PostComposeSheet]
  affects: [GlobalFeedSection, PostComposeSheet, CommunityService]
tech_stack:
  added: []
  patterns: [UIImagePickerController-representable, confirmationDialog, closure-injection-for-testability, saveOverride-hook]
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Views/Community/CommunityReplySheetView.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/CommunityHubViewModel.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/PostComposeSheet.swift
    - VitaminG/VitaminG/VitaminG/Services/CommunityService.swift
    - VitaminG/VitaminG/VitaminGTests/CommunityFeedViewModelTests.swift
    - VitaminG/VitaminG/VitaminGTests/Phase21ReplyTests.swift
decisions:
  - "CommunityReplySheetView uses onWriteReply closure injection for testability instead of direct CommunityService call in the view"
  - "ImagePickerRepresentable defined in PostComposeSheet.swift (not a shared utilities file) to keep context bounded"
  - "saveOverride parameter added to CommunityService.writeReply following createOverride pattern from CommunityFeedViewModel"
  - "InputSanitizer.sanitizeForPublic applied in CommunityReplySheetView.submit() before onWriteReply (defense in depth; service also sanitizes)"
metrics:
  duration: "13 minutes"
  completed: "2026-05-23"
  tasks_completed: 2
  files_modified: 6
---

# Phase 21 Plan 04: Compose Flows — Camera Dialog and Reply Sheet Summary

PostComposeSheet extended with camera/photo-library confirmationDialog (D-10) and CommunityReplySheetView built as a CloudKit-backed reply sheet with profanity gate and 300-char cap (COMM-06).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extend PostComposeSheet with camera/confirmationDialog | bcfc47b | PostComposeSheet.swift, CommunityFeedViewModelTests.swift, CommunityHubViewModel.swift |
| 2 | Build CommunityReplySheetView — CloudKit-backed reply sheet | eec9808 | CommunityReplySheetView.swift, Phase21ReplyTests.swift, CommunityService.swift |

## What Was Built

### Task 1: PostComposeSheet camera/confirmationDialog (D-10)

- Added `showPhotoSourceDialog`, `showLibraryPicker`, `showCamera` state vars
- Replaced direct `PhotosPicker` view with a `Button` that sets `showPhotoSourceDialog = true`
- `.confirmationDialog("Add Photo")` with three options: "Photo Library", "Camera", "Cancel"
- "Photo Library" triggers `.photosPicker(isPresented: $showLibraryPicker)` modifier
- "Camera" opens `.sheet(isPresented: $showCamera)` presenting `ImagePickerRepresentable`
- `ImagePickerRepresentable` (UIViewControllerRepresentable wrapping UIImagePickerController) defined at the bottom of PostComposeSheet.swift — mirrors ProfileView.swift camera pattern
- Inline 80x80pt thumbnail with `.transition(.opacity)` retained from prior implementation
- COMM-07 photo test added to `CommunityFeedViewModelTests` — verifies `imageData` is passed through to `createOverride` when non-nil (6 tests, 0 failures)

### Task 2: CommunityReplySheetView — CloudKit-backed reply sheet (D-08)

- `CommunityReplySheetView`: NavigationStack with TextEditor, character counter (shown when count > 250), profanity inline error, Cancel + "Post Reply" toolbar buttons
- Uses `onWriteReply: (String) async -> Bool` closure injection — no direct CloudKit call in view
- `submit()`: profanity gate (ProfanityFilter.containsProfanity) fires first; InputSanitizer.sanitizeForPublic applied before `onWriteReply` call (defense in depth)
- 300-char hard cap enforced via `.onChange(of: text)` + `String.prefix(300)` (T-21-04-04)
- Alert presented on failed write
- `saveOverride` testability hook added to `CommunityService.writeReply` (mirrors `createOverride` pattern)
- Phase21ReplyTests: 3 tests GREEN — profanity rejection, text sanitization, clean-text success

## Test Results

- `CommunityFeedViewModelTests`: 6/6 passed (includes new COMM-07 photo test)
- `Phase21ReplyTests`: 3/3 passed (all previously RED stubs now GREEN)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CommunityHubViewModel async let actor-isolation compile errors**
- **Found during:** Task 1 initial build
- **Issue:** `CommunityHubViewModel.swift` (created by Plan 21-03) had 5 errors: `async let` closures accessing `@MainActor`-isolated properties (`fetchGlimpsesOverride`, etc.) from outside the actor
- **Fix:** Capture override closures into local constants on the MainActor before spawning `async let` tasks
- **Files modified:** `VitaminG/VitaminG/VitaminG/ViewModels/CommunityHubViewModel.swift`
- **Commit:** bcfc47b

**2. [Rule 1 - Bug] CommunityService.writeReply accessed CloudKit db before saveOverride check**
- **Found during:** Task 2 test run (tests for sanitization and clean text were hanging)
- **Issue:** `CKContainer.default().publicCloudDatabase` was accessed before the `saveOverride` check, causing potential CloudKit initialization delay in test environment
- **Fix:** Moved `let db = ...` to after the `saveOverride` early-return path
- **Files modified:** `VitaminG/VitaminG/VitaminG/Services/CommunityService.swift`
- **Commit:** eec9808

## Known Stubs

None. All compose flows are wired:
- PostComposeSheet writes to `CommunityFeedViewModel.submitPost` (CloudKit-backed)
- CommunityReplySheetView writes via `onWriteReply` closure (production: `CommunityService.writeReply`)

## Threat Flags

No new threat surface beyond what is declared in the plan's threat model. All T-21-04-* mitigations implemented:
- T-21-04-01: ProfanityFilter gate + InputSanitizer in both view and service
- T-21-04-04: 300-char hard cap in .onChange(of: text)

## Self-Check: PASSED

- [x] `VitaminG/VitaminG/VitaminG/Views/PostComposeSheet.swift` — exists, confirmationDialog present
- [x] `VitaminG/VitaminG/VitaminG/Views/Community/CommunityReplySheetView.swift` — exists, onWriteReply present
- [x] `VitaminG/VitaminG/VitaminG/Services/CommunityService.swift` — saveOverride hook present
- [x] Commit bcfc47b — verified in git log
- [x] Commit eec9808 — verified in git log
- [x] CommunityFeedViewModelTests: 6/6 GREEN
- [x] Phase21ReplyTests: 3/3 GREEN
