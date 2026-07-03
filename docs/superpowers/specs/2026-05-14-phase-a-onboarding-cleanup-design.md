# Phase A — Onboarding Cleanup Design

**Date:** 2026-05-14  
**Status:** Approved  
**Scope:** Remove phone/OTP signup, add profile-aware Login + Recovery screens, wire flow end-to-end.

---

## Problem

The onboarding `NavigationStack` routes through `phoneSignup` and `verificationCode` steps that require a backend SMS service. VitaminG is a local-first app (SwiftData + CloudKit) with no auth server. These screens are dead weight and create a broken first-run experience.

Additionally, returning users (e.g., after reinstall) hit the generic Welcome screen with no way to resume their existing profile gracefully.

---

## Goal

1. Remove the phone/OTP screens and their associated code entirely.
2. Wire "Get Started" directly to the Name step for new users.
3. Add a profile-aware "Login" screen for returning users (recognizes saved `@AppStorage` name).
4. Add a "Recovery" screen with iCloud restore, start-fresh, and contact-support paths.

---

## What Changes

### 1. `OnboardingStep` enum (`OnboardingView.swift`)

**Remove:**
- `case phoneSignup`
- `case verificationCode`

**Add:**
- `case login`
- `case recovery`

**Final enum:**
```swift
enum OnboardingStep: Hashable {
    case name
    case login
    case recovery
    case motivationCategories
    case notifications
    case communityGoal
    case createGoal
}
```

### 2. `OnboardingView` NavigationStack

Remove the `case .phoneSignup` and `case .verificationCode` switch arms.

Add:
```swift
case .login:
    LoginScreen(path: $path, onSkip: finish)
case .recovery:
    RecoveryScreen(path: $path, onRestartOnboarding: restartOnboarding)
```

Add `restartOnboarding()` helper that clears `@AppStorage("vg_onboardingName")` and pops to root.

### 3. `WelcomeScreen.swift`

**"Get Started" button:** Navigate to `.name` (was `.phoneSignup`).

**"Sign in" / "I'll set this up later" button:**
- If `@AppStorage("vg_onboardingName")` is non-empty → navigate to `.login`
- Otherwise → navigate to `.name` (treat as new user who skipped naming)

The button label changes to "Sign in" when a saved name is detected, stays "I'll set this up later" otherwise.

### 4. New `LoginScreen.swift`

**Location:** `Views/Onboarding/LoginScreen.swift`

**Reads:** `@AppStorage("vg_onboardingName") var savedName: String`

**Layout (matches handoff warm serif style):**
- Back arrow (top left)
- Row: app icon thumbnail (48 × 48, rounded) + "WELCOME BACK" chip + "Vitamin G" title
- Large serif heading: *"Good to see you again."*
- Body text: *"Your goals and streaks are right where you left them."*
- "Continue as [savedName]" primary button → calls `onSkip()` (sets `hasCompletedOnboarding = true`)
- "This isn't me" ghost button → clears `@AppStorage("vg_onboardingName")`, then appends `.name` to the navigation path (so the user moves forward, not back to Splash)
- "Having trouble?" text button → pushes `.recovery`

**Edge case:** If `savedName` is empty when this screen appears (shouldn't happen from the flow, but defensively), immediately pop and push `.name`.

### 5. New `RecoveryScreen.swift`

**Location:** `Views/Onboarding/RecoveryScreen.swift`

**Layout:**
- Back arrow
- Large emoji header: 📱
- Serif title: *"Let's get you back in."*
- Body: *"Your goals and streaks are safe. We just need to verify it's you."*
- Three recovery option cards (tappable rows):
  1. 🔄 **Restore from iCloud** — *"Sync your goals and streak from iCloud backup"* — sets `hasCompletedOnboarding = true`, CloudKit sync handles the rest
  2. 🔑 **Start fresh** — *"Clear everything and start a new profile"* — shows a confirmation alert, then calls `onRestartOnboarding()`
  3. 🤝 **Contact support** — *"Real human · usually within 24h"* — opens `mailto:` to the support address stored in `Info.plist` key `VGSupportEmail` (defaults to `support@vitamingapp.com` if key absent)
- Reassurance banner (terracotta light): *"Your streak is protected. Your data lives in iCloud."*
- Primary button: **"Restore from iCloud"** → same as row 1

### 6. File Deletions

- `Views/Onboarding/PhoneSignupScreen.swift` — deleted
- `Views/Onboarding/VerificationCodeScreen.swift` — deleted

---

## Navigation Flow After This Change

```
New user:
  Splash (WelcomeScreen)
    ↓ "Get Started"
  Name → Motivation → Notifications → CommunityGoal → CreateFirstGoal → Home

Returning user (savedName exists):
  Splash (WelcomeScreen)
    ↓ "Sign in"
  LoginScreen
    ↓ "Continue as [Name]"
  Home

Lost/reset user:
  Splash → Sign in → LoginScreen
    ↓ "Having trouble?"
  RecoveryScreen
    ↓ "Restore from iCloud"
  Home (CloudKit syncs in background)

Fresh start from Recovery:
  RecoveryScreen
    ↓ "Start fresh" (confirmed)
  Name → … full onboarding
```

---

## Out of Scope for This Phase

- Backend auth, OTP, or Firebase (never)
- Email/password login
- Multi-account switching
- Any feature from Phases B–G of the broader roadmap

---

## Files Touched

| File | Action |
|------|--------|
| `Views/Onboarding/OnboardingView.swift` | Modify — enum + switch |
| `Views/Onboarding/WelcomeScreen.swift` | Modify — button wiring |
| `Views/Onboarding/LoginScreen.swift` | Create |
| `Views/Onboarding/RecoveryScreen.swift` | Create |
| `Views/Onboarding/PhoneSignupScreen.swift` | Delete |
| `Views/Onboarding/VerificationCodeScreen.swift` | Delete |

---

## Success Criteria

- App builds with zero compile errors after the phone/OTP cases are removed.
- Tapping "Get Started" on Welcome lands on the Name screen.
- Tapping "Sign in" when a name is saved lands on LoginScreen showing that name.
- Tapping "Continue as [Name]" on LoginScreen enters the main app.
- Tapping "This isn't me" clears the name and lands on NameScreen.
- Tapping "Having trouble?" lands on RecoveryScreen.
- "Start fresh" shows a confirmation alert before clearing data.
- No references to `phoneSignup` or `verificationCode` remain anywhere in the codebase.
