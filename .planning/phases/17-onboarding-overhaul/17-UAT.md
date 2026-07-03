---
status: partial
phase: 17-onboarding-overhaul
source:
  - 17-01-SUMMARY.md
  - 17-02-SUMMARY.md
  - 17-03-SUMMARY.md
  - 17-04-SUMMARY.md
  - 17-05-SUMMARY.md
started: "2026-05-17T23:59:00Z"
updated: "2026-05-20T00:00:00Z"
---

## Current Test

[testing complete]

## Tests

### 1. WelcomeScreen — Apple Sign-In only
expected: |
  Open the app as a new install (or reset onboarding). The WelcomeScreen shows exactly
  one button: "Sign in with Apple". No "Create account" button, no Google button,
  no "I'll set this up later" ghost link. The tagline "GOALS. GROWTH. COMMUNITY."
  appears ABOVE the rounded-rectangle app icon block, not below the app name.
result: skipped

### 2. New user routing — T&C after sign-in
expected: |
  Sign in with Apple as a new user (first install, or after clearing vg_onboardingName
  from UserDefaults). After successful Apple Sign-In, the app navigates to a screen
  titled "Before we begin" — NOT directly to the name field.
result: issue
reported: "no, it wont even allow me to open the app. white screen now then failure"
severity: blocker

### 3. T&C screen layout and PDF viewer
expected: |
  The T&C screen shows: a step progress bar (step 0 of 7), a Georgia-font headline
  "Before we begin", body text asking to read the T&C, a "Read Terms" outlined capsule
  button, and an "I Agree — Continue" terra-colored CTA. Tapping "Read Terms" opens
  the T&C PDF in a full-screen QuickLook sheet. The sheet can be dismissed.
result: skipped

### 4. T&C agreement advances to Name entry
expected: |
  After tapping "I Agree — Continue" on the T&C screen, the app navigates to the
  Name entry screen (the step that asks for a display name). The vg_hasAgreedToTerms
  flag is now true (can verify in UserDefaults if desired).
result: skipped

### 5. NameScreen — Apple credential pre-fill
expected: |
  The Name entry screen has the display name field pre-populated with the full name
  from the Apple credential (e.g., "Kyle Harrington" if that's the Apple ID name).
  The user can edit or clear it before continuing. The step bar shows step 1 of 7.
result: skipped

### 6. UsernameScreen — availability check with debounce
expected: |
  After the Name screen, the Username screen appears. Typing in the username field
  shows a "Checking..." indicator ~500ms after you stop typing. The indicator then
  changes to "✓ Available" (green) or "✗ Already taken" (red). Invalid characters
  (anything other than letters, numbers, underscores) show an inline "Invalid" error
  immediately without firing a CloudKit check.
result: skipped

### 7. Username Continue button gating
expected: |
  On the Username screen, the "Continue" button is disabled (greyed out with sandMid
  fill) until the username check shows "Available". Once available, the button
  becomes active. Tapping it claims the username and advances to Profile Picture.
result: skipped

### 8. ProfilePictureScreen — picker options and skip
expected: |
  The Profile Picture screen appears with two options: "Choose from Library" and
  "Take Photo", plus a "Skip for now" link at the bottom. Tapping "Skip for now"
  advances to the next step without selecting a photo. The step bar shows step 3 of 7.
result: skipped

### 9. CameraPermissionScreen — priming slide
expected: |
  Before the iOS camera permission dialog, a dark clay-background priming slide
  appears titled "Share your journey." with a glassmorphism camera preview card.
  It has an "Allow Camera" CTA and a "Skip for now" link. Tapping "Skip for now"
  advances without asking for camera permission. Tapping "Allow Camera" triggers
  the iOS camera permission dialog.
result: skipped

### 10. Returning user routing — Welcome Back screen
expected: |
  If a user has previously entered their name (vg_onboardingName is non-empty) and
  taps "Sign in with Apple" on the WelcomeScreen, they are routed to the "Welcome
  Back" / Login screen — NOT to the T&C screen. The Login screen shows their profile
  card, a Sign in with Apple button, "Having trouble?", and "This isn't me".
result: skipped

### 11. LoginScreen — Apple re-auth button
expected: |
  On the Login screen, a "Sign in with Apple" button appears ABOVE the "Having
  trouble?" link. Tapping it and completing Apple Sign-In successfully logs the user
  in and enters the app. If sign-in fails, an inline error "Sign in failed. Please
  try again." appears in terra color below the button.
result: skipped

### 12. PublicProfileView — Report or Block button
expected: |
  Navigate to any public profile (via Community tab or a shared profile link).
  Below the profile card, a "Report or Block" button is visible in terra color.
  Tapping it opens options to report or block the user.
result: skipped

### 13. PublicProfileView — contextMenu on avatar and name
expected: |
  On a public profile view, long-press the avatar (profile photo) OR the display
  name. A context menu appears with two items: "Report User" (flag icon) and
  "Block User" (slash.circle icon, destructive style in red).
result: skipped

### 14. Block user — confirmation and persistence
expected: |
  Tapping "Block User" (from contextMenu or Report or Block button) shows an alert:
  "Block this user?" with "Block" (destructive, red) and "Cancel" buttons. Tapping
  "Block" dismisses the alert. The blocked user's ID is saved to vg_blockedUserIDs
  in UserDefaults and persists if the app is force-quit and reopened.
result: skipped

### 15. Report user — mail compose
expected: |
  Tapping "Report User" opens MFMailComposeViewController (on a device with mail
  configured) pre-filled with subject "[Vitamin G] Report User: @{displayName}"
  and the body pre-populated. On a simulator without mail configured, it falls back
  to opening a mailto: URL (may show "no mail app" alert — that's expected).
result: skipped

## Summary

total: 15
passed: 0
issues: 1
pending: 0
skipped: 14
blocked: 0

## Gaps

- truth: "After successful Apple Sign-In as a new user, the app navigates to the T&C screen ('Before we begin') — NOT directly to the name field."
  status: failed
  reason: "User reported: no, it wont even allow me to open the app. white screen now then failure"
  severity: blocker
  test: 2
  artifacts: []
  missing: []
