# Plan 15-04 Summary

## Objective
Fix D1 mood picker, D2 camera badge, add UIADD-07 username display/edit.

## Completed Tasks
1. D1: Mood picker conditionally hidden when today's mood logged; feeling badge with change link shown instead
2. D2: Camera badge wrapped in Button, permission check via AVCaptureDevice, PhotosPicker, handlePhotoSelection moved to ProfileViewModel (MVVM)
3. UIADD-07: @username shown in ProfileView below displayName, username TextField in ProfileEditSheet with ViewModel validation

## Artifacts Modified
- Views/ProfileView.swift
- Views/ProfileEditSheet.swift
- ViewModels/ProfileViewModel.swift

## Status
COMPLETE
