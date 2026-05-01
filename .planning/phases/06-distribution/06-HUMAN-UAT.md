---
status: partial
phase: 06-distribution
source: [06-01-PLAN.md]
started: 2026-05-01T00:00:00Z
updated: 2026-05-01T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. AppIcon.png has no alpha channel
expected: `sips -g hasAlpha VitaminG/VitaminG/VitaminG/Assets.xcassets/AppIcon.appiconset/AppIcon.png` returns `hasAlpha: no`
result: passed (automated — confirmed during execution)

### 2. Both PrivacyInfo.xcprivacy files appear in Xcode Target Membership
expected: Xcode Project Navigator → select VitaminG/PrivacyInfo.xcprivacy → Target Membership shows VitaminG only; select VitaminGWidget/PrivacyInfo.xcprivacy → shows VitaminGWidgetExtension only
result: [pending]

### 3. Archive succeeds without ITMS validation errors
expected: Xcode Organizer → Validate App → no ITMS errors for alpha channel or missing privacy manifest
result: [pending]

### 4. CloudKit Console Production schema shows all record types
expected: cloudkit.developer.apple.com → container iCloud.com.kyleharrington.VitaminG → Production → Schema shows CD_Goal, CD_CompletionEvent, CD_UserProfile (with CD_isPublic on CD_Goal)
result: [pending]

### 5. TestFlight build installs on physical iPhone without crash
expected: TestFlight app on iOS 17+ iPhone installs and opens the app without crash on all core flows
result: [pending]

### 6. CloudKit Production sync confirmed (SYNC-03 gate)
expected: Create a goal on TestFlight device → CloudKit Console Production → Private Database → CD_Goal record appears. This is the SYNC-03 gate.
result: [pending]

### 7. Scheduled notification received on physical device
expected: Settings tab → set notification time ~1-2 min from now → notification arrives at scheduled time; tapping it opens the app
result: [pending]

### 8. vitaming:// deep link opens correct profile view
expected: Share profile → copy vitaming://profile/<recordID> → open on second device or paste in Safari → app opens to ProfileView for that user
result: [pending]

### 9. Privacy Policy URL is live before submission
expected: Browser opens the hosted Privacy Policy URL without error
result: [pending]

### 10. Screenshots upload to all 5 slots in App Store Connect without size rejection
expected: App Store Connect → Version → Screenshots → iPhone 6.9" slot accepts all 5 at 1290×2796 px
result: [pending]

### 11. App Store Review accepts submission
expected: App Store Connect version status changes to "Waiting for Review" → eventually "Ready for Sale"
result: [pending]

## Summary

total: 11
passed: 1
issues: 0
pending: 10
skipped: 0
blocked: 0

## Gaps
