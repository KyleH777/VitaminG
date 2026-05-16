---
phase: 07-add-user-profiles-with-privacy-toggle-profile-picture-upload
plan: "04"
subsystem: AvatarView
tags: [avatar, swiftui, profile, reusable-component, initials, photo-fallback]
dependency_graph:
  requires: [07-03]
  provides: [AvatarView]
  affects: [ProfileView, ProfileEditSheet]
tech_stack:
  added: []
  patterns: ["Reusable SwiftUI component with size parameter", "Photo-or-initials conditional rendering", "UIImage(data:) safe decode fallback", "Live initials preview in edit sheet"]
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Views/AvatarView.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/ProfileView.swift
    - VitaminG/VitaminG/VitaminG/Views/ProfileEditSheet.swift
decisions:
  - "Initials computed locally in AvatarView (not from ProfileViewModel) so component is usable anywhere without ViewModel coupling"
  - "size param drives proportional scaling of font size (38.6% ratio), shadow radius, and shadow Y offset"
  - "UIImage(data:) safely returns nil for malformed photoData — automatic fallback to initials avatar (T-07-13 mitigation)"
  - "Edit sheet uses draftDisplayName falling back to profile.displayName for live initials update without needing a separate binding"
metrics:
  duration: "~5 min"
  completed: "2026-04-14"
  tasks_completed: 2
  files_changed: 3
---

# Phase 07 Plan 04: AvatarView Component Summary

Standalone reusable AvatarView component that renders a warm-colored circle with initials (or a photo when photoData is available), wired into ProfileView (88pt) and ProfileEditSheet (64pt live preview).

## What Was Built

### AvatarView (new)
Reusable SwiftUI view at `VitaminG/VitaminG/VitaminG/Views/AvatarView.swift`:
- Shows `UIImage` from `photoData` when non-nil (safe decode via `UIImage(data:)` — nil on malformed data)
- Falls back to colored circle + initials when `photoData` is nil
- `displayName` processed locally: split by whitespace, first char of each word, uppercase, max 2 chars; "?" if empty
- `avatarColorHex` parsed via `Color(hex:)` extension from SchemaV2.swift; falls back to `.gray`
- `size` parameter (default 88pt) drives all proportional values:
  - Initials font: `size * 0.386` (yields 34pt at 88pt — matches UI-SPEC)
  - Shadow radius: 8pt for size >= 64, else 4pt
  - Shadow Y: 4pt for size >= 64, else 2pt
- Accessibility: `.accessibilityLabel("Profile avatar for \(displayName ?? "you")")`
- No ViewModel coupling — pure value-type inputs

### ProfileView (modified)
`avatarSection` computed property replaced: inline `ZStack { Circle()... Text(viewModel.initials)... }` removed, replaced with `AvatarView(displayName:avatarColorHex:photoData:size: 88)`. Shadow and accessibility label now handled inside AvatarView.

### ProfileEditSheet (modified)
New `Section` prepended to Form containing a centered `AvatarView(size: 64)`. Avatar preview uses `draftDisplayName` (falling back to `profile?.displayName`) so initials update in real time as the user types. `listRowBackground(.clear)` removes the default form row background behind the avatar.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. `photoData` is nil in all current UserProfile instances (D-03 deferral) — AvatarView correctly falls back to initials. The photo rendering path is fully implemented and will activate automatically when a future phase populates `photoData`.

## Threat Surface Scan

No new threat surface beyond the plan's threat model:
- `UIImage(data:)` decode is safe — returns nil for invalid data, no code execution risk (T-07-13 mitigated)
- Initials computation is bounded O(n) on displayName length, max 50 chars enforced upstream (T-07-14 accepted)

## Self-Check: PASSED

Files confirmed present:
- VitaminG/VitaminG/VitaminG/Views/AvatarView.swift: FOUND
- ProfileView.swift references AvatarView: FOUND (line 50)
- ProfileEditSheet.swift references AvatarView size: 64: FOUND (line 25)
- No inline ZStack+Circle avatar code remains in ProfileView: CONFIRMED

Commits confirmed:
- 76cfcb0: feat(07-04): create AvatarView component with photo fallback and scalable size
- 6631cda: feat(07-04): replace inline avatar in ProfileView and add live preview to ProfileEditSheet
