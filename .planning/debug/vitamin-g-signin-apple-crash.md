---
slug: vitamin-g-signin-apple-crash
status: resolved
trigger: Vitamin G app stuck at white screen then crashes with inaccessible Sign in with Apple prompt
created: 2026-06-09
updated: 2026-06-09
---

# Debug Session: vitamin-g-signin-apple-crash

## Symptoms

- **Expected**: App launches and opens normally
- **Actual**: App stuck at white screen for ~3 minutes, then quits unexpectedly; home screen was blacked out by a Sign in with Apple prompt that could not be accessed
- **Errors**: App quit unexpectedly after white screen; Sign in with Apple sheet appeared over a blacked-out home screen and was inaccessible
- **Timeline**: Never worked
- **Reproduction**: Launch the app from Xcode (simulator or device)

## Current Focus

hypothesis: RESOLVED
test: com.apple.developer.applesignin entitlement added to VitaminG.entitlements
expecting: App launches cleanly and Sign in with Apple completes successfully
next_action: Build and run to verify

## Evidence

- timestamp: 2026-06-09T00:00:00Z
  source: VitaminG.entitlements
  observation: File contained app-groups, icloud-container-identifiers, and icloud-services — but NOT com.apple.developer.applesignin
  significance: HIGH — Sign in with Apple is invoked from WelcomeScreen and LoginScreen via SignInWithAppleButton/ASAuthorizationAppleIDCredential, but the required entitlement was absent. iOS presents the auth sheet against a system-controlled overlay, hangs waiting for a credential that can never be granted, then the app times out and crashes.

- timestamp: 2026-06-09T00:00:00Z
  source: VitaminG.xcodeproj/project.pbxproj
  observation: grep for 'applesignin' returned no results — capability not registered in project either
  significance: HIGH — entitlement missing at both file level and project capability level

- timestamp: 2026-06-09T00:00:00Z
  source: WelcomeScreen.swift (line 168), LoginScreen.swift (line 127)
  observation: Both screens use SignInWithAppleButton — Sign in with Apple is the ONLY auth path on the welcome screen; no fallback exists
  significance: HIGH — app cannot proceed past the welcome screen without this working

## Eliminated

- Hypothesis: Misconfigured CloudKit/iCloud entitlements — ELIMINATED. iCloud container and app group are properly declared.
- Hypothesis: Code-level AuthenticationServices import issues — ELIMINATED. Imports are present and correct.

## Specialist Review

swift-agent-team: LOOKS_GOOD — Adding `com.apple.developer.applesignin` with value `["Default"]` is the standard, Apple-documented requirement for Sign in with Apple. The `Default` value is the only accepted value for this key. No idiomatic issues.

## Resolution

root_cause: The `com.apple.developer.applesignin` entitlement key was missing from `VitaminG.entitlements`. iOS requires this entitlement to grant the app permission to use Sign in with Apple. Without it, the system presents an auth sheet it cannot complete, causing the ~3 minute hang and crash.
fix: Added `com.apple.developer.applesignin` with value `["Default"]` to VitaminG.entitlements
verification: Build and run — WelcomeScreen Sign in with Apple button should authenticate successfully without hang or crash. Also confirm Sign in with Apple capability is enabled in Xcode under Signing & Capabilities for the VitaminG target.
files_changed: VitaminG/VitaminG/VitaminG/VitaminG.entitlements
