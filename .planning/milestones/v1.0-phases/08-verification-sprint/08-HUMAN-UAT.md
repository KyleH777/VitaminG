---
status: partial
phase: 08-verification-sprint
source: [08-VERIFICATION.md]
started: 2026-04-17T00:00:00Z
updated: 2026-04-17T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Stats Tab Display
expected: Run app, navigate to Stats tab (2nd tab). Streak cards render with current streak count and calendar heatmap renders without blank or placeholder sections.
result: [pending]

### 2. Settings Notification Time Change
expected: Navigate to Settings tab. Change the DatePicker notification time. Background notification reschedules to the new time (verify via device notification settings or wait for next trigger).
result: [pending]

### 3. TabView Navigation
expected: Tap all 3 main tabs (Goals, Stats, Settings). Each tab loads without blank screens or navigation errors.
result: [pending]

### 4. Profile Tab Visual Verification
expected: Navigate to Profile tab (4th tab). AvatarView circle shows warm color + initials (88pt). Display name row has pencil edit button. Public/Private toggle visible with explanatory text. Public Goals section visible. Share Profile button present (disabled when Private, ShareLink when Public).
result: [pending]

### 5. CloudKit Public Database Verification
expected: On a physical device with signed-in iCloud account, toggle profile to Public. Share button becomes a ShareLink with a vitaming://profile/<non-empty-recordID> URL. Toggling back to Private immediately disables the Share button.
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
