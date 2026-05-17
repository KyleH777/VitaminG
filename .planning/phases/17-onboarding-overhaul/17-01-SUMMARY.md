---
phase: "17"
plan: "01"
subsystem: onboarding
tags: [auth, routing, apple-sign-in, onboarding-step, welcome-screen, login-screen]
dependency_graph:
  requires: []
  provides:
    - OnboardingStep enum with 9 cases including 4 new Phase 17 cases
    - WelcomeScreen Apple Sign-In only auth gate
    - WelcomeScreen returning/new-user routing branch
    - LoginScreen Apple re-auth button wired to onSkip()
  affects:
    - All onboarding screens that switch on OnboardingStep
    - NameScreen routing (now → .username instead of .motivationCategories)
    - TiersScreen routing (now → .communityGoal instead of .createGoal)
    - CommunityGoalOnboardingScreen advance (now calls onSkip() instead of .createGoal)
tech_stack:
  added: []
  patterns:
    - SignInWithAppleButton onCompletion routing branch (savedName check)
    - NavigationStack path.append placeholder stubs for future plans
key_files:
  created: []
  modified:
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/WelcomeScreen.swift
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/OnboardingView.swift
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/LoginScreen.swift
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/NameScreen.swift
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/TiersScreen.swift
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/CommunityGoalOnboardingScreen.swift
decisions:
  - "NavigationDestination stubs (Text placeholder) for termsAndConditions/username/profilePicture/cameraPermission — real screens wired in Plans 2-5"
  - "CommunityGoalOnboardingScreen advance() now calls onSkip() since .createGoal removed per D-16"
  - "TiersScreen routed to .communityGoal as legacy safe landing after .createGoal removal"
metrics:
  duration: "~5 minutes"
  completed: "2026-05-17T15:45:00Z"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 6
---

# Phase 17 Plan 01: Auth Gate Scaffold Summary

Apple Sign-In as sole auth entry on WelcomeScreen, OnboardingStep enum expanded with 4 new Phase 17 cases and 2 removed cases, LoginScreen Apple re-auth button wired to onSkip() on success.

## What Was Built

**Task 1 — WelcomeScreen cleanup + routing (commit d978f34)**

Three surgical changes to WelcomeScreen.swift:
1. Removed Create account Button, Google stub Button (with @State showGoogleComingSoon and .alert), and "I'll set this up later" ghost Button. Only the SignInWithAppleButton remains.
2. Moved "GOALS. GROWTH. COMMUNITY." tagline from below the app name to above the RoundedRectangle app icon block (line 133 < line 140). Replaced .padding(.top, 10) with .padding(.bottom, 16).
3. Updated onCompletion routing: returning user (savedName non-empty) → `path.append(.login)`; new user → `path.append(.termsAndConditions)`. Both branches inside .success case only (T-17-01-01 mitigated — .failure does nothing).

**Task 2 — OnboardingStep enum expansion (commit edc9753)**

OnboardingView.swift updated:
- Added 4 new enum cases: `.termsAndConditions`, `.username`, `.profilePicture`, `.cameraPermission`
- Removed `.motivationCategories` and `.createGoal` cases entirely (D-05, D-16)
- Added 4 navigationDestination placeholder Text stubs for the new cases (Plans 2-5 will replace them)
- Removed MotivationCategoryScreen and GoalCreationWizardView destination blocks
- Final enum: 9 cases — name, login, recovery, termsAndConditions, username, profilePicture, notifications, cameraPermission, communityGoal

**Task 3 — LoginScreen Apple re-auth (commit f95980b)**

LoginScreen.swift updated:
- Added `import AuthenticationServices`
- Added `@State private var reAuthFailed: Bool = false`
- Inserted SignInWithAppleButton(.signIn) above "Having trouble?" link in bottomButtons
- On .success: clears reAuthFailed, calls onSkip() (completes re-auth, enters app)
- On .failure: sets reAuthFailed = true
- Inline error "Sign in failed. Please try again." shown when reAuthFailed (13pt .light, VGTheme.terra)
- "Having trouble?" and "This isn't me" links preserved unchanged

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed NameScreen: .motivationCategories → .username**
- **Found during:** Task 1 verification (build would fail due to removed enum case)
- **Issue:** NameScreen.swift line 114 called `path.append(.motivationCategories)` which no longer exists
- **Fix:** Changed to `path.append(.username)` per PATTERNS.md §NameScreen routing change
- **Files modified:** VitaminG/VitaminG/VitaminG/Views/Onboarding/NameScreen.swift
- **Commit:** d978f34

**2. [Rule 3 - Blocking] Fixed TiersScreen: .createGoal → .communityGoal**
- **Found during:** Task 1 verification (build would fail due to removed enum case)
- **Issue:** TiersScreen.swift line 54 called `path.append(.createGoal)` which no longer exists
- **Fix:** Changed to `path.append(.communityGoal)` — community goal is the final onboarding step
- **Files modified:** VitaminG/VitaminG/VitaminG/Views/Onboarding/TiersScreen.swift
- **Commit:** d978f34

**3. [Rule 3 - Blocking] Fixed CommunityGoalOnboardingScreen: advance() → onSkip()**
- **Found during:** Task 1 verification (build would fail due to removed enum case)
- **Issue:** CommunityGoalOnboardingScreen.swift line 169 advance() called `path.append(.createGoal)` which no longer exists
- **Fix:** Changed advance() to call `onSkip()` directly — this is the final step before completing onboarding
- **Files modified:** VitaminG/VitaminG/VitaminG/Views/Onboarding/CommunityGoalOnboardingScreen.swift
- **Commit:** d978f34

## Verification Results

Post-task build: **BUILD SUCCEEDED** (zero errors, iPhone 17 Pro simulator)

| Criterion | Result |
|-----------|--------|
| WelcomeScreen has only SignInWithAppleButton | PASS |
| Tagline above RoundedRectangle icon (line 133 < 140) | PASS |
| New user routing: path.append(.termsAndConditions) | PASS |
| Returning user routing: path.append(.login) | PASS |
| OnboardingStep has 4 new cases | PASS |
| OnboardingStep does NOT have .motivationCategories or .createGoal | PASS (comments only) |
| LoginScreen has import AuthenticationServices | PASS |
| LoginScreen SignInWithAppleButton calls onSkip() on .success | PASS |
| LoginScreen reAuthFailed inline error | PASS |
| Existing links preserved (Having trouble?, This isn't me) | PASS |
| Build zero errors | PASS |

## Known Stubs

The 4 new navigationDestination cases in OnboardingView.swift use placeholder Text views — this is intentional per the plan design:
- `.termsAndConditions` → `Text("T&C — Plan 2")` — replaced by Plan 2
- `.username` → `Text("Username — Plan 3")` — replaced by Plan 3
- `.profilePicture` → `Text("Profile Picture — Plan 4")` — replaced by Plan 4
- `.cameraPermission` → `Text("Camera Permission — Plan 5")` — replaced by Plan 5

These stubs do NOT prevent the plan's goal (auth gate scaffold) from being achieved. NavigationStack lazy-loads these only when navigated to, and WelcomeScreen now correctly routes to `.termsAndConditions` for new users.

## Threat Surface

No new network endpoints or trust boundaries introduced. Apple ASAuthorizationAppleIDCredential flow unchanged. Threat register mitigations T-17-01-01 and T-17-01-03 confirmed applied:
- T-17-01-01: path mutation only in .success case — .failure does nothing
- T-17-01-03: branch condition checks savedName (stored at name-entry step), clean install = empty = new user flow

## Self-Check: PASSED

- WelcomeScreen.swift: exists and modified correctly
- OnboardingView.swift: exists and modified correctly
- LoginScreen.swift: exists and modified correctly
- d978f34: confirmed in git log
- edc9753: confirmed in git log
- f95980b: confirmed in git log
