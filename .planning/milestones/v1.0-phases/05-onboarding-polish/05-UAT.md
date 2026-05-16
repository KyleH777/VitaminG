---
status: complete
phase: 05-onboarding-polish
source: [05-01-SUMMARY.md, 05-02-SUMMARY.md, 05-03-SUMMARY.md, 05-04-SUMMARY.md, 05-05-SUMMARY.md]
started: 2026-04-16T18:00:00Z
updated: 2026-04-16T18:30:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[testing complete]

## Tests

### 1. First Launch Shows Onboarding
expected: On first launch (or with AppStorage "hasCompletedOnboarding" cleared), the app shows the Welcome screen — not the main goal list. Welcome screen has a pulsing gradient circle with a star icon, a "Get Started" button, and a "Skip" toolbar button.
result: pass

### 2. Onboarding Navigation Flow
expected: Tapping "Get Started" navigates to the Tiers screen (showing 4 tier cards with warm copy). Tapping "Continue" navigates to the Create First Goal screen with a goal form and tier picker.
result: pass

### 3. Skip Button Works
expected: Tapping "Skip" on any onboarding screen dismisses the entire onboarding flow and shows the main app (goal list). The app does not show onboarding again on next launch.
result: pass

### 4. Create Goal During Onboarding
expected: On the Create First Goal screen, entering a goal title and tapping save creates the goal, dismisses onboarding, and shows the main goal list with the new goal present.
result: pass

### 5. Notification Permission Sheet
expected: After completing onboarding (not skipping), a half-sheet appears asking for notification permission. It shows a mock notification preview, "Allow Notifications" button, and "Not now" secondary action. (Only appears if notifications not already authorized.)
result: pass

### 6. Onboarding Not Shown Again
expected: After completing or skipping onboarding once, relaunching the app goes directly to the main goal list — no onboarding shown.
result: pass

### 7. Per-Tier Empty States
expected: When a tier section has no goals (in the by-tier view), instead of a blank section, warm copy appears with the tier icon and an "Add your first [tier] goal" button. Each tier shows its own appropriate copy (e.g., "What's one small win you can chase today?" for Immediate).
result: pass

### 8. Empty State Add Button Pre-selects Tier
expected: Tapping the "Add your first [tier] goal" button in an empty tier section opens the Add Goal sheet with that tier already selected in the tier picker.
result: pass

### 9. Dark Mode Appearance
expected: Toggle device to Dark Mode. The app background is dark (not pure white), goal cards adapt correctly, and no elements appear as harsh white blocks against the dark background.
result: pass

### 10. App Icon on Home Screen
expected: After installing/building to a device or simulator, the VitaminG app icon appears correctly on the home screen/springboard (not a blank or placeholder icon).
result: skipped
reason: unable to verify at this time

## Summary

total: 10
passed: 9
issues: 0
pending: 0
skipped: 1
blocked: 0

## Gaps

[none yet]
