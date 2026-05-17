---
phase: "17"
plan: "03"
subsystem: onboarding
tags: [auth, username, cloudkit, debounce, race-condition, state-machine, xctest]
dependency_graph:
  requires:
    - "17-01: OnboardingStep enum with .username case and Text placeholder"
    - "17-02: OnboardingView OnboardingViewModel instance available"
  provides:
    - UsernameLookupService (isUsernameTaken, writeUsername, countRecordsWithUsername)
    - ProfileSharingService.publishProfile extended with username: String? parameter
    - UsernameCheckState enum (idle/checking/available/taken/invalid)
    - OnboardingViewModel: onUsernameChanged debounce, claimUsername D-17 race condition mitigation
    - OnboardingViewModel: appleFullName PersonNameComponents? and profilePhotoData Data? properties
    - UsernameScreen: inline ✓/✗ feedback, race condition inline error, .available-gated Continue
    - .username navigationDestination wired in OnboardingView
    - XCTest unit tests (4 tests, no CloudKit dependency)
  affects:
    - New user onboarding flow: TermsAndConditionsScreen → NameScreen → UsernameScreen → ProfilePictureScreen
    - completeOnboarding() now calls publishProfile(username:storedUsername) for write coordination
tech_stack:
  added: []
  patterns:
    - Swift Concurrency Task debounce with cancellation (onUsernameChanged → debounceTask.cancel())
    - CKContainer publicCloudDatabase async/await CKQuery with NSPredicate parameterized binding (%@)
    - D-17 post-save race condition: writeUsername → countRecords → delete if count > 1
    - UsernameCheckState state machine tested synchronously without CloudKit
    - ProfileSharingService.publishProfile additive parameter extension (username: String? = nil default)
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Services/UsernameLookupService.swift
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/UsernameScreen.swift
    - VitaminGTests/OnboardingViewModelUsernameTests.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/OnboardingViewModel.swift
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/OnboardingView.swift
decisions:
  - "claimUsername posts writeUsername FIRST, then countRecords post-save — D-17 race condition mitigation enforced at claim time"
  - "completeOnboarding reads vg_onboardingUsername and vg_appleUserID from UserDefaults to coordinate publishProfile write with same record"
  - "ProfileSharingService.publishProfile username parameter defaults to nil for backward compatibility — existing call sites unchanged"
  - "usernameCheckState reset to .idle on CloudKit error (not .taken) — silent fallback allows user to retry without incorrect feedback"
  - "isClaiming guard in advanceIfAvailable prevents double-tap claim races"
  - "TDD RED commit before implementation GREEN commit per protocol — 4 synchronous guard path tests"
  - "UsernameScreen uses @AppStorage vg_appleUserID (not OnboardingViewModel) for claimUsername appleUserID parameter — matches WelcomeScreen/NameScreen pattern"
metrics:
  duration: "~30 minutes"
  completed: "2026-05-17T22:30:12Z"
  tasks_completed: 3
  tasks_total: 4
  files_modified: 3
  files_created: 3
---

# Phase 17 Plan 03: Username Claim Screen Summary

UsernameLookupService with async CKQuery uniqueness check (isUsernameTaken/writeUsername/countRecords), ProfileSharingService.publishProfile extended with username field, OnboardingViewModel extended with UsernameCheckState enum and 500ms debounce, UsernameScreen with inline ✓/✗ feedback and D-17 race condition recovery, and 4 XCTest unit tests for the state machine without CloudKit dependency.

## What Was Built

**Task 1 (checkpoint:human-action) — SKIPPED per execution objective**

CloudKit Console index setup is a deferred human action. Code execution proceeded without this step. The username Queryable index in CloudKit Console is required before real-device testing.

**Task 2 — Create UsernameLookupService + extend ProfileSharingService (commit 6b51874)**

New file `VitaminG/VitaminG/VitaminG/Services/UsernameLookupService.swift`:
- `enum UsernameLookupService` (namespace-only, no instances)
- `isUsernameTaken(_ username: String) async throws -> Bool`: CKQuery on PublicProfile where username == %@, resultsLimit: 1, returns !results.isEmpty
- `writeUsername(_ username: String, appleUserID: String) async throws -> CKRecord.ID`: fetch-or-create PublicProfile by CKRecord.ID(recordName: appleUserID), writes record["username"] = lowercased, saves record
- `countRecordsWithUsername(_ username: String) async throws -> Int`: same query, resultsLimit: 2, returns count for D-17 race detection

`ProfileSharingService.publishProfile` extended:
- Added `username: String? = nil` parameter (default nil for backward compatibility with all existing call sites)
- Inside record write block: `if let username = username { record["username"] = username.lowercased() as CKRecordValue }`
- Both UsernameLookupService.writeUsername and ProfileSharingService.publishProfile target CKRecord.ID(recordName: appleUserID) — same record, no orphan writes

**Task 3a — Extend OnboardingViewModel + XCTest unit tests (commits 9bb103e, fb586b5)**

TDD RED (commit 9bb103e): `VitaminGTests/OnboardingViewModelUsernameTests.swift` with 4 failing test cases targeting the not-yet-implemented synchronous guard paths.

TDD GREEN (commit fb586b5): `OnboardingViewModel.swift` extended with:
- `enum UsernameCheckState: Equatable` (idle/checking/available/taken/invalid(String))
- `var appleFullName: PersonNameComponents? = nil` — for Plan 4 NameScreen pre-fill
- `var profilePhotoData: Data? = nil` — for Plan 4 ProfilePictureScreen
- `var usernameCheckState: UsernameCheckState = .idle`
- `private var debounceTask: Task<Void, Never>? = nil`
- `func onUsernameChanged(_ newValue: String)`: cancels debounceTask, guards empty/<3/invalid chars (synchronous), then fires `Task { try? await Task.sleep(for: .milliseconds(500)); await checkUsernameAvailability(lowercased) }`
- `private func checkUsernameAvailability(_ username: String) async`: sets .checking → calls UsernameLookupService.isUsernameTaken → .available | .taken | .idle on error
- `func claimUsername(_ username: String, appleUserID: String) async -> Bool`: writeUsername → countRecords post-save → delete record if count > 1 (D-17) → return false; return true if count == 1
- `completeOnboarding()`: reads vg_onboardingUsername and vg_appleUserID from UserDefaults; calls ProfileSharingService.publishProfile(username: storedUsername) to coordinate write paths

All 4 tests pass:
- testInvalidChars_setsInvalidState: PASS
- testShortInput_setsIdleState: PASS
- testEmptyInput_setsIdleState: PASS
- testValidInput_remainsIdleBeforeDebounce: PASS

**Task 3b — Create UsernameScreen + wire .username destination (commit 518869a)**

New file `VitaminG/VitaminG/VitaminG/Views/Onboarding/UsernameScreen.swift`:
- `struct UsernameScreen: View` with `@Binding var path`, `let onSkip`, `var viewModel: OnboardingViewModel`
- `@AppStorage("vg_appleUserID")`, `@AppStorage("vg_onboardingUsername")`
- `@State private var usernameInput`, `isClaiming`, `raceConditionError`
- Layout: ZStack(alignment: .bottom) sandLight bg, back arrow, StepBarView(current: 2, total: 7)
- Field label "USERNAME" (13pt .semibold, ALL CAPS, kerning 1.5), headline "Claim your\nusername" (Georgia 42pt, clay)
- Subtitle 14pt .light muted, TextField CormorantGaramond-Regular 34pt, terra underline Rectangle (height: 2)
- Inline state indicator: Group switching on viewModel.usernameCheckState
  - .idle → EmptyView
  - .checking → HStack { ProgressView() + "Checking..." }
  - .available → Label("✓ Available", systemImage: "checkmark.circle.fill") in VGTheme.sage
  - .taken → Label("✗ Already taken", systemImage: "xmark.circle.fill") in VGTheme.terra
  - .invalid(msg) → Text(msg) in VGTheme.terra
- raceConditionError Text below state indicator
- Continue button: terra/warmWhite when canContinue (.available), sandMid/sandDeep when disabled
- `advanceIfAvailable()`: claimUsername → success → storedUsername = input + path.append(.profilePicture); failure → clear field + .idle + raceConditionError
- `.onChange(of: usernameInput)` → `viewModel.onUsernameChanged(newValue)`

`OnboardingView.swift` updated:
- Replaced `Text("Username — Plan 3")` placeholder with `UsernameScreen(path: $path, onSkip: finish, viewModel: onboardingVM)`

## Deviations from Plan

None — plan executed exactly as written.

Task 1 (checkpoint:human-action) was skipped per the execution objective: "Skip any checkpoint:human-action tasks and execute all auto tasks." CloudKit Console index configuration is documented as a pending prerequisite.

## Verification Results

Post-plan build: **BUILD SUCCEEDED** (zero errors, iPhone 17 Pro simulator)

Post-plan tests: **4/4 PASSED** (OnboardingViewModelUsernameTests, no CloudKit dependency)

| Criterion | Result |
|-----------|--------|
| UsernameLookupService.swift exists | PASS |
| Contains isUsernameTaken | PASS |
| Contains writeUsername | PASS |
| Contains countRecordsWithUsername | PASS |
| Contains publicCloudDatabase | PASS |
| Contains NSPredicate format "username == %@" | PASS |
| ProfileSharingService publishProfile has username: String? parameter | PASS |
| ProfileSharingService contains record["username"] write | PASS |
| Both services use CKRecord.ID(recordName: appleUserID) | PASS |
| OnboardingViewModel contains enum UsernameCheckState | PASS |
| OnboardingViewModel contains func onUsernameChanged | PASS |
| OnboardingViewModel contains func claimUsername | PASS |
| OnboardingViewModel contains Task.sleep(for: .milliseconds(500)) | PASS |
| OnboardingViewModel contains var appleFullName: PersonNameComponents? | PASS |
| OnboardingViewModel contains var profilePhotoData: Data? | PASS |
| completeOnboarding() calls publishProfile with stored username (not nil) | PASS |
| UsernameScreen.swift exists with struct UsernameScreen: View | PASS |
| UsernameScreen contains vg_onboardingUsername | PASS |
| UsernameScreen contains path.append(.profilePicture) in advanceIfAvailable | PASS |
| UsernameScreen contains StepBarView(current: 2, total: 7) | PASS |
| UsernameScreen contains raceConditionError | PASS |
| OnboardingView contains UsernameScreen(path: $path, onSkip: finish, viewModel: onboardingVM) | PASS |
| VitaminGTests/OnboardingViewModelUsernameTests.swift exists with 4 tests | PASS |
| All 4 OnboardingViewModelUsernameTests pass | PASS |
| Build zero errors | PASS |

## Known Stubs

The CloudKit Console index setup (Task 1) is a deferred human action. Without the Queryable index on the `username` field in CloudKit Console, `isUsernameTaken` and `countRecordsWithUsername` will throw `CKError.invalidArguments` on real devices/simulators with CloudKit Dev configured. The code handles this gracefully (catch → .idle state) so it does not crash, but availability checks will silently fail without the index.

**Action required before real-device testing:** Configure Queryable index on `username` field in CloudKit Console → Container iCloud.com.kyleharrington.VitaminG → Schema → Record Types → PublicProfile.

## Threat Surface

T-17-03-02 mitigated: Character set validation fires synchronously in `onUsernameChanged` before any CloudKit query. NSPredicate uses parameterized `%@` binding (not string concatenation) as defense-in-depth.

T-17-03-04 mitigated: D-17 race condition post-save count re-check implemented in `claimUsername`. If `countRecordsWithUsername > 1`, this device's record is deleted and `false` is returned — UsernameScreen shows inline error and clears field.

T-17-03-05 mitigated: 500ms debounce with `debounceTask?.cancel()` on each keystroke — only one in-flight check at a time.

No new network endpoints beyond the PublicProfile CloudKit public DB table already registered in the plan threat model.

## Self-Check: PASSED

- UsernameLookupService.swift: exists at VitaminG/VitaminG/VitaminG/Services/UsernameLookupService.swift
- ProfileSharingService.swift: modified, publishProfile has username parameter
- OnboardingViewModel.swift: modified, contains UsernameCheckState, onUsernameChanged, claimUsername
- UsernameScreen.swift: exists at VitaminG/VitaminG/VitaminG/Views/Onboarding/UsernameScreen.swift
- OnboardingView.swift: modified, UsernameScreen wired, placeholder removed
- OnboardingViewModelUsernameTests.swift: exists at VitaminGTests/OnboardingViewModelUsernameTests.swift
- 6b51874: confirmed in git log (Task 2)
- 9bb103e: confirmed in git log (Task 3a RED)
- fb586b5: confirmed in git log (Task 3a GREEN)
- 518869a: confirmed in git log (Task 3b)
- Build: SUCCEEDED with zero errors
- Tests: 4/4 PASSED
