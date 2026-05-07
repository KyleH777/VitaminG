---
plan: 13-08
phase: 13-challenge-platform-core-engine
status: complete
completed: 2026-05-07
key-files:
  modified:
    - VitaminG/VitaminG/VitaminG/Services/NotificationDelegate.swift
    - VitaminG/VitaminG/VitaminG/VitaminGApp.swift
---

## Summary

Wired challenge reminder notification taps to the check-in modal. Closes CR-01 from 13-REVIEW.md and gap 1 from 13-VERIFICATION.md. CHAL-12 / SC-6 now addressable.

## What Was Built

**Task 1 — NotificationDelegate.swift:** Changed callback signature from `(String) -> Void` to `(String, [AnyHashable: Any]) -> Void`. The `userNotificationCenter(_:didReceive:withCompletionHandler:)` method now extracts `userInfo` before the deepLink guard and forwards both values: `onDeepLink(deepLink, userInfo)`. The `willPresent` method and all other behaviour unchanged.

**Task 2 — VitaminGApp.swift:** Updated the `NotificationDelegate { ... }` closure to accept `(deepLink, userInfo)` parameters. Added `else if` branch:

```swift
} else if deepLink == "challengeCheckIn",
          let idString = userInfo["userChallengeID"] as? String {
    appRouter.pendingChallengeCheckInID = idString
}
```

Existing `goalList` → `appRouter.popToRoot()` path preserved (NOTIF-07 not regressed). The `.onOpenURL` URL-scheme handler in `body` remains untouched.

## Diff Regions

**NotificationDelegate.swift** — changed lines 12, 15, 31–32:
- Before: `private let onDeepLink: (String) -> Void`
- After: `private let onDeepLink: (String, [AnyHashable: Any]) -> Void`
- Before: `onDeepLink(deepLink)` inside `didReceive`
- After: `let userInfo = response...userInfo` + `onDeepLink(deepLink, userInfo)`

**VitaminGApp.swift** — changed lines 22–27:
- Before: `NotificationDelegate { deepLink in` with only `goalList` branch
- After: `NotificationDelegate { deepLink, userInfo in` with `goalList` + `challengeCheckIn` branches

## Verification

All acceptance grep checks passed:
- ✓ `(String, [AnyHashable: Any]) -> Void` present in NotificationDelegate.swift
- ✓ `onDeepLink(deepLink, userInfo)` present
- ✓ old `(String) -> Void` gone
- ✓ `NotificationDelegate { deepLink, userInfo in` in VitaminGApp.swift
- ✓ `else if deepLink == "challengeCheckIn"` present
- ✓ `appRouter.pendingChallengeCheckInID = idString` present
- ✓ `appRouter.popToRoot()` preserved
- ✓ `.onOpenURL { url in` preserved

## Self-Check: PASSED
