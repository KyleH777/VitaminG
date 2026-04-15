---
phase: 07-add-user-profiles-with-privacy-toggle-profile-picture-upload
plan: "03"
subsystem: ProfileSharing
tags: [profile, cloudkit, deeplink, sharing, swiftui, ios, privacy]
dependency_graph:
  requires: [07-02]
  provides: [ProfileSharingService, DeepLinkBuilder, vitaming-url-scheme, ShareLink-integration]
  affects: [ProfileViewModel, ProfileView, Info.plist]
tech_stack:
  added: [CloudKit (public database direct API)]
  patterns: ["async throws CloudKit write/delete", "ShareLink with pre-populated message", "DeepLinkBuilder enum pattern", "optimistic UI toggle with async CloudKit sync"]
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift
    - VitaminG/VitaminG/VitaminG/Services/DeepLinkBuilder.swift
  modified:
    - VitaminG/VitaminG/VitaminG/ViewModels/ProfileViewModel.swift
    - VitaminG/VitaminG/VitaminG/Views/ProfileView.swift
    - VitaminG/VitaminG/VitaminG/Info.plist
decisions:
  - "Going private immediately clears cloudKitPublicRecordID and disables ShareLink — CloudKit delete is fire-and-forget (unpublishProfile swallows unknownItem errors)"
  - "Going public is optimistic — toggle flips locally first, CloudKit write runs async; failure shows alert but does not revert toggle (T-07-11)"
  - "shareURL computed via DeepLinkBuilder.profileURL — returns nil when cloudKitPublicRecordID is nil, driving ShareLink vs disabled-button conditional in ProfileView"
  - "ProfileView share button is a conditional Group: ShareLink when URL available, disabled Button otherwise — avoids conditional view identity issues"
  - "updatePublicRecordIfNeeded called at end of validateAndSaveDisplayName to keep CloudKit record in sync when displayName changes while profile is public"
metrics:
  duration: "~10 min"
  completed: "2026-04-14"
  tasks_completed: 2
  files_changed: 5
---

# Phase 07 Plan 03: CloudKit Profile Sharing and Deep Link Summary

CloudKit public database write/delete for PublicProfile records wired to the privacy toggle, with vitaming:// deep-link generation and ShareLink integration in ProfileView.

## What Was Built

### ProfileSharingService (new)
Async service for CloudKit public database operations on PublicProfile records:
- `publishProfile(displayName:avatarColorHex:existingRecordID:)` — creates or updates a `PublicProfile` CKRecord in the public database; returns `recordID.recordName` for local storage. Explicit field allowlist: only `displayName` and `avatarColorHex` written (T-07-08 mitigation — photoData and goal data never included).
- `unpublishProfile(recordID:)` — deletes the CKRecord; silently succeeds on `.unknownItem` (already deleted). Prevents orphaned publicly accessible records when user goes private.
- Uses `CKContainer(identifier: "iCloud.com.kyleharrington.VitaminG")` and `publicCloudDatabase` for unauthenticated-read access.

### DeepLinkBuilder (new)
Enum with `profileURL(recordID:) -> URL?` that builds `vitaming://profile/<recordID>` URLs. Returns nil for nil or empty recordID. Outgoing link generation only — incoming parsing deferred to a future phase.

### Info.plist (modified)
Added `CFBundleURLTypes` entry registering the `vitaming` URL scheme with bundle ID `com.kyleharrington.VitaminG`. Required for system to recognize outgoing deep links from ShareLink.

### ProfileViewModel (modified)
- `toggleProfilePublic(context:)` — fully wired: flips `isPublic` locally, persists, then async-publishes to CloudKit (going public) or async-unpublishes (going private). CloudKit publish failure shows alert without reverting toggle (optimistic UI, T-07-11). Going private immediately clears `cloudKitPublicRecordID` so the share URL disappears before the async delete completes.
- `shareURL` — now computed via `DeepLinkBuilder.profileURL(recordID: profile?.cloudKitPublicRecordID)`. Returns nil when no record ID is stored.
- `updatePublicRecordIfNeeded(context:)` — new method called at end of `validateAndSaveDisplayName` to sync displayName changes to the CloudKit public record while profile is public.

### ProfileView (modified)
Share Profile button replaced with a conditional `Group`:
- When `viewModel.shareURL` is non-nil: `ShareLink(item: url, subject: "Vitamin G Profile", message: "Check out my goals on Vitamin G!")` — presents system share sheet.
- When nil: disabled `Button` with accessibility hint "Set your profile to public to enable sharing".
- Animated with `.easeInOut(duration: 0.2)` on `shareURL != nil` change.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All stubs from Plan 02 have been resolved:
- `shareURL` now returns a real `vitaming://` URL (no longer nil stub)
- Share Profile button now uses `ShareLink` with real pre-populated content

## Threat Surface Scan

No new threat surface beyond what was already in the plan's threat model. All T-07-08 through T-07-12 mitigations implemented as designed.

## Self-Check: PASSED

Files confirmed present:
- VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift: FOUND
- VitaminG/VitaminG/VitaminG/Services/DeepLinkBuilder.swift: FOUND
- VitaminG/VitaminG/VitaminG/Info.plist: contains vitaming scheme

Commits confirmed:
- bd06bf0: feat(07-03): add ProfileSharingService, DeepLinkBuilder, and register vitaming:// URL scheme
- b7680fa: feat(07-03): wire CloudKit sharing and ShareLink into ProfileViewModel and ProfileView
