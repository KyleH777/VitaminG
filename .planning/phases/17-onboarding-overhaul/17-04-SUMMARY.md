---
phase: "17"
plan: "04"
subsystem: onboarding
tags: [auth, profile-picture, camera-permission, apple-credential, phpicker, avfoundation, photo-compression]
dependency_graph:
  requires:
    - "17-01: OnboardingStep enum with .profilePicture and .cameraPermission cases + Text placeholders"
    - "17-03: OnboardingViewModel with appleFullName: PersonNameComponents? and profilePhotoData: Data? properties"
  provides:
    - NameScreen prefilledName parameter + updated StepBarView(current:1, total:7)
    - WelcomeScreen viewModel parameter + appleFullName passthrough from Apple credential
    - ProfilePictureScreen: PHPicker + CameraPickerView + avatar preview + skip link
    - CameraPickerView UIViewControllerRepresentable for UIImagePickerController
    - CommunityService.resizeAndCompress: pixel-exact resize to ≤512px + JPEG 0.75 compression
    - CameraPermissionScreen: dark-clay priming slide mirroring NotificationOnboardingScreen
    - OnboardingView: .profilePicture and .cameraPermission destinations wired to real screens
  affects:
    - New user onboarding flow: NameScreen → UsernameScreen → ProfilePictureScreen → NotificationOnboardingScreen → CameraPermissionScreen → CommunityGoalOnboardingScreen
tech_stack:
  added: []
  patterns:
    - PhotosUI PhotosPickerItem + .photosPicker modifier (from ProfileView.swift)
    - UIViewControllerRepresentable three-part bridge (from ContactPickerRepresentable.swift)
    - UIGraphicsImageRenderer pixel-exact resize before jpegData compression
    - AVCaptureDevice.requestAccess callback dispatched to main thread (T-17-04-03)
    - NotificationOnboardingScreen dark-clay priming slide pattern (exact mirror)
    - PersonNameComponentsFormatter().string(from:) for Apple fullName formatting
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/ProfilePictureScreen.swift
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/CameraPermissionScreen.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/NameScreen.swift
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/WelcomeScreen.swift
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/OnboardingView.swift
    - VitaminG/VitaminG/VitaminG/Services/CommunityService.swift
decisions:
  - "NameScreen uses custom init with prefilledName: String? = nil default — preserves backward compatibility with call sites that don't pass it"
  - "PersonNameComponentsFormatter().string(from:) result guarded for empty string — passes nil if formatted result is empty so NameScreen shows blank field"
  - "ProfilePictureScreen skip link and Continue button both route to .notifications — the photo step is fully skippable per AUTH-04"
  - "CameraPermissionScreen allow() advances to .communityGoal regardless of grant/deny — the permission dialog educates; the flow proceeds either way per AUTH-06"
  - "CommunityService.resizeAndCompress placed alongside compressToJPEG for cohesion — both are compression utilities"
  - "CameraPickerView defined in same file as ProfilePictureScreen — two closely related structs, single file per Swift idiom"
  - "AUTH-05 preservation confirmed by grep gate — .notifications case verified present after all OnboardingView edits"
metrics:
  duration: "~45 minutes"
  completed: "2026-05-17T22:39:07Z"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 4
  files_created: 2
---

# Phase 17 Plan 04: Profile Picture + Camera Permission Summary

NameScreen pre-fill from Apple credential fullName (D-04), WelcomeScreen viewModel passthrough, ProfilePictureScreen with PHPicker + camera + skip wired to viewModel.profilePhotoData, CommunityService.resizeAndCompress utility for ≤512px JPEG 0.75 compression, and CameraPermissionScreen as a dark-clay priming slide mirroring NotificationOnboardingScreen exactly.

## What Was Built

**Task 1 — NameScreen prefill + WelcomeScreen fullName passthrough (commit 6d27e66)**

Three coordinated changes:

1. `NameScreen.swift` — added `prefilledName: String?` parameter with custom init (default nil). Updated `.onAppear` to use prefill when storedName is empty. Updated `StepBarView(current: 0, total: 4)` → `StepBarView(current: 1, total: 7)`. The `.username` routing in `advanceIfValid()` was already in place from Plan 1's deviation fix.

2. `WelcomeScreen.swift` — added `var viewModel: OnboardingViewModel` parameter. In the `onCompletion .success` case, replaced the `TODO Plan 4` comment with `viewModel.appleFullName = cred.fullName`.

3. `OnboardingView.swift` — updated `WelcomeScreen(path: $path, onSkip: finish)` to pass `viewModel: onboardingVM`. Updated `NameScreen(path: $path, onSkip: finish)` to pass `prefilledName: onboardingVM.appleFullName.map { PersonNameComponentsFormatter().string(from: $0) }.flatMap { $0.isEmpty ? nil : $0 }`. AUTH-05 `.notifications` case confirmed present after edit.

**Task 2 — ProfilePictureScreen + resizeAndCompress utility (commit bbd8256)**

`CommunityService.swift` extended:
- Added `static func resizeAndCompress(_ image: UIImage, maxDimension: CGFloat = 512, quality: CGFloat = 0.75) -> Data?` below `compressToJPEG`
- Uses `UIGraphicsImageRenderer(size:)` for pixel-exact resize, then `jpegData(compressionQuality:)` — T-17-04-01 mitigation

New file `ProfilePictureScreen.swift`:
- `struct ProfilePictureScreen: View` with `@Binding var path`, `let onSkip`, `var viewModel: OnboardingViewModel`
- `@State` for `selectedPhotoItem`, `showLibraryPicker`, `showCameraPicker`, `cameraPermissionDenied`, `previewImage`
- Layout: sandLight bg, back arrow, `StepBarView(current: 3, total: 7)`, avatar preview circle (96pt), two outlined picker buttons (side by side, sandMid border), "Skip for now" link → `.notifications`, Continue CTA → `.notifications`
- `requestCameraAccess()`: switches on `AVCaptureDevice.authorizationStatus` — .authorized shows picker, .notDetermined requests access (dispatched to main thread, T-17-04-03), default sets `cameraPermissionDenied`
- `handlePhotoSelection(_:)` and `handleCapturedImage(_:)`: both compress via `resizeAndCompress` and store in `viewModel.profilePhotoData` on MainActor
- `struct CameraPickerView: UIViewControllerRepresentable` with `UIImagePickerController` camera source, `Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate`

`OnboardingView.swift` — replaced `.profilePicture: Text("Profile Picture — Plan 4")` with `ProfilePictureScreen(path: $path, onSkip: finish, viewModel: onboardingVM)`

**Task 3 — CameraPermissionScreen + .cameraPermission destination (commit 321c076)**

New file `CameraPermissionScreen.swift`:
- `struct CameraPermissionScreen: View` — exact structural mirror of `NotificationOnboardingScreen`
- `ZStack` with `VGTheme.clay.ignoresSafeArea()` + `RadialGradient(colors: [VGTheme.clayMid, VGTheme.clay], center: UnitPoint(x:0.5, y:0.3), startRadius:0, endRadius:400)`
- Glassmorphism camera preview card: `.ultraThinMaterial.opacity(0.3)` + `Color.white.opacity(0.11)` + `strokeBorder Color.white.opacity(0.14)` — app icon row (terra RoundedRectangle 34x34 with "G" Georgia-Italic) + camera viewfinder rectangle with `camera.fill` SF Symbol
- Headline: `"Share your\n\(Text("journey.").font(Font.custom("Georgia-Italic", size: 42)).foregroundStyle(VGTheme.terraSoft))"` in Georgia 42pt VGTheme.sand
- Body: 14pt SF Pro .light, VGTheme.muted
- `.safeAreaInset(edge: .bottom)` CTA tray (VGTheme.clay background): "Allow Camera" (VGTheme.sand fill, VGTheme.clay text) + "Skip for now" (VGTheme.sand.opacity(0.55))
- `allow()`: `AVCaptureDevice.requestAccess(for: .video) { _ in DispatchQueue.main.async { path.append(.communityGoal) } }` — advances regardless of grant
- `skip()`: `path.append(.communityGoal)`

`OnboardingView.swift` — replaced `.cameraPermission: Text("Camera Permission — Plan 5")` with `CameraPermissionScreen(path: $path, onSkip: finish)`

## Deviations from Plan

None — plan executed exactly as written.

The `advanceIfValid()` routing in NameScreen already contained `.username` (fixed by Plan 1's deviation), so no change was needed there — the plan correctly identified this and the acceptance criteria still checked for its presence (PASS).

## Verification Results

Post-plan build: **BUILD SUCCEEDED** (zero errors, iPhone 17 Pro simulator)

| Criterion | Result |
|-----------|--------|
| NameScreen.swift contains "let prefilledName: String?" | PASS |
| NameScreen.swift contains "path.append(.username)" in advanceIfValid() | PASS |
| NameScreen.swift does NOT contain "path.append(.motivationCategories)" | PASS |
| NameScreen.swift contains "StepBarView(current: 1, total: 7)" | PASS |
| WelcomeScreen.swift contains "viewModel.appleFullName = cred.fullName" | PASS |
| WelcomeScreen.swift does NOT contain "TODO Plan 4" | PASS |
| OnboardingView.swift contains WelcomeScreen with viewModel: onboardingVM | PASS |
| OnboardingView.swift contains NameScreen with prefilledName: | PASS |
| OnboardingView.swift contains "case .notifications:" | PASS (AUTH-05 preserved) |
| CommunityService.swift contains "static func resizeAndCompress" | PASS |
| CommunityService.swift resizeAndCompress contains "maxDimension: CGFloat = 512" | PASS |
| ProfilePictureScreen.swift exists with struct ProfilePictureScreen: View | PASS |
| ProfilePictureScreen.swift contains "struct CameraPickerView: UIViewControllerRepresentable" | PASS |
| ProfilePictureScreen.swift contains "UIImagePickerController()" | PASS |
| ProfilePictureScreen.swift contains "PhotosPickerItem" | PASS |
| ProfilePictureScreen.swift contains "StepBarView(current: 3, total: 7)" | PASS |
| ProfilePictureScreen.swift contains "path.append(.notifications)" (skip + continue) | PASS |
| ProfilePictureScreen.swift contains "viewModel.profilePhotoData = compressed" | PASS |
| OnboardingView.swift contains ProfilePictureScreen wired | PASS |
| CameraPermissionScreen.swift exists with struct CameraPermissionScreen: View | PASS |
| CameraPermissionScreen.swift contains "AVCaptureDevice.requestAccess(for: .video)" | PASS |
| CameraPermissionScreen.swift contains "path.append(.communityGoal)" in both allow() and skip() | PASS (2 occurrences) |
| CameraPermissionScreen.swift contains "RadialGradient" | PASS |
| CameraPermissionScreen.swift contains "VGTheme.clay.ignoresSafeArea()" | PASS |
| CameraPermissionScreen.swift contains "Allow Camera" | PASS |
| CameraPermissionScreen.swift contains "Skip for now" | PASS |
| CameraPermissionScreen.swift contains "Share your" | PASS |
| OnboardingView.swift contains CameraPermissionScreen wired | PASS |
| OnboardingView.swift does NOT contain "Camera Permission — Plan 5" | PASS |
| Build zero errors | PASS |

## Known Stubs

None. All navigationDestination placeholder Text views for `.profilePicture` and `.cameraPermission` have been replaced with real screens. The `.termsAndConditions` and `.username` destinations were wired in Plans 2 and 3 respectively. All 9 OnboardingStep cases are now wired to real screens.

## Threat Surface

T-17-04-01 mitigated: `CommunityService.resizeAndCompress` compresses photos to ≤512px JPEG 0.75 before storing in `viewModel.profilePhotoData`. No full-resolution photo is stored in Phase 17.

T-17-04-02 accepted: fullName from Apple credential is advisory — user can edit the pre-filled NameScreen field before continuing. `storedName` is only written on `advanceIfValid()`.

T-17-04-03 mitigated: All `AVCaptureDevice.requestAccess` callbacks are dispatched to `DispatchQueue.main.async` before any `@State` mutation, in both `ProfilePictureScreen.requestCameraAccess()` and `CameraPermissionScreen.allow()`.

T-17-04-04 confirmed: `NSCameraUsageDescription` verified present in Info.plist — camera code will not crash on first camera access.

No new trust boundaries beyond those registered in the plan threat model.

## Self-Check: PASSED

- NameScreen.swift: modified, prefilledName parameter present, StepBarView updated
- WelcomeScreen.swift: modified, viewModel parameter present, fullName captured
- OnboardingView.swift: modified, all 4 destinations wired to real screens
- CommunityService.swift: modified, resizeAndCompress added below compressToJPEG
- ProfilePictureScreen.swift: created at correct path
- CameraPermissionScreen.swift: created at correct path
- 6d27e66: confirmed in git log (Task 1)
- bbd8256: confirmed in git log (Task 2)
- 321c076: confirmed in git log (Task 3)
- Build: SUCCEEDED with zero errors
