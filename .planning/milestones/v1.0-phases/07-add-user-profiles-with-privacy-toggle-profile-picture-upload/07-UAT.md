---
status: complete
phase: 07-add-user-profiles-with-privacy-toggle-profile-picture-upload
source: [07-01-SUMMARY.md, 07-02-SUMMARY.md, 07-03-SUMMARY.md, 07-04-SUMMARY.md]
started: 2026-04-14T00:00:00Z
updated: 2026-04-14T00:00:00Z
completed: 2026-04-14T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start — SwiftData Migration Smoke Test
expected: Kill the app on a simulator or device that has existing V1 data (any saved goals). Relaunch from scratch. The app should launch without crashing, the SwiftData migration should complete silently, and all existing goals should still appear in the list.
result: pass

### 2. Profile Tab Appears
expected: A 4th tab should be visible in the tab bar with a person.crop.circle.fill icon. Tapping it opens the Profile screen.
result: pass

### 3. Avatar Shows Initials
expected: On the Profile screen, a colored circle (88pt) should display your initials — first letter of each word in your display name, max 2 chars, uppercase. If display name is empty it shows "?".
result: pass

### 4. Edit Display Name
expected: Tapping the pencil button next to the display name opens a sheet. Typing a new name updates the 64pt avatar preview in real time. Tapping "Update Name" saves and dismisses. Input is capped at 50 characters.
result: pass

### 5. Privacy Toggle and Explanatory Text
expected: The Profile screen has a privacy toggle. Contextual explanatory text appears near the toggle. When the toggle is off (private), the Share Profile button is disabled.
result: pass

### 6. Per-Goal Public/Private Toggle
expected: Opening a goal's detail view shows a "Share this goal" toggle. Flipping it changes that goal's isPublic status. The goal should appear/disappear in the Public Goals section of the Profile tab accordingly.
result: pass

### 7. Go Public — Share Button Activates
expected: Flipping the profile privacy toggle to public optimistically flips the toggle immediately. Once the CloudKit publish completes and cloudKitPublicRecordID is saved, the Share Profile button becomes an active ShareLink (not a disabled button). Tapping it brings up the system share sheet with a vitaming:// URL.
result: pass

### 8. Go Private — Share Button Disables
expected: Flipping the profile privacy toggle back to private immediately disables the Share Profile button and clears the share URL — before the async CloudKit delete finishes. The toggle state and disabled button should be visible instantly.
result: pass

### 9. AvatarView Live Initials Preview in Edit Sheet
expected: While typing in the edit display name sheet, the small 64pt avatar circle at the top of the sheet updates its initials in real time as each character is typed. No "Update Name" tap required to see the preview change.
result: pass

## Summary

total: 9
passed: 9
issues: 0
pending: 0
skipped: 0

## Gaps

[none yet]
