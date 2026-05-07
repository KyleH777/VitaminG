---
phase: 13-challenge-platform-core-engine
reviewed: 2026-05-06T12:00:00Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - VitaminG/VitaminG/VitaminG/Models/SchemaV4.swift
  - VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift
  - VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift
  - VitaminG/VitaminG/VitaminG/Services/ChallengeStreakEngine.swift
  - VitaminG/VitaminG/VitaminG/Models/ChallengeTemplate+Featured.swift
  - VitaminG/VitaminG/VitaminG/ViewModels/ChallengeViewModel.swift
  - VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift
  - VitaminG/VitaminG/VitaminG/Navigation/AppRouter.swift
  - VitaminG/VitaminG/VitaminG/Services/DeepLinkBuilder.swift
  - VitaminG/VitaminG/VitaminG/Services/DeepLinkParser.swift
  - VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift
  - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
  - VitaminG/VitaminG/VitaminG/Views/Components/StreakChainView.swift
  - VitaminG/VitaminG/VitaminG/Views/ChallengeDiscoveryView.swift
  - VitaminG/VitaminG/VitaminG/Views/ChallengeDetailView.swift
  - VitaminG/VitaminG/VitaminG/Views/ChallengeCheckInView.swift
  - VitaminG/VitaminG/VitaminG/Views/MilestoneCelebrationView.swift
  - VitaminG/VitaminG/VitaminG/VitaminGApp.swift
findings:
  critical: 4
  warning: 5
  info: 3
  total: 12
status: issues_found
---

# Phase 13: Code Review Report

**Reviewed:** 2026-05-06T12:00:00Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

Phase 13 adds the Challenge Platform core engine: three new SwiftData models (`ChallengeTemplate`, `UserChallenge`, `CheckIn`) in SchemaV4, a lightweight migration, `ChallengeStreakEngine`, featured template seeds, `ChallengeViewModel` with type-blind check-in dispatch, AppRoute/AppRouter extensions, DeepLinkBuilder/Parser for the new URL scheme, per-challenge notification scheduling, and six new Views.

The schema design is correct — all properties are optional or defaulted, no `@Attribute(.unique)`, inverse relationships are declared on both sides. The streak engine is pure, injectable, and algorithmically sound. The `CheckInPayload` dispatch pattern is clean and avoids `switch checkInType` in the ViewModel as required by CHAL-07.

Four blockers were found:

1. **Challenge notification tap is completely unrouted** — `NotificationDelegate` forwards the raw `"challengeCheckIn"` string to `VitaminGApp`, but the closure only handles `"goalList"`. The `userChallengeID` from `userInfo` is never extracted, `AppRouter.pendingChallengeCheckInID` is never set from notification taps, and no check-in sheet appears. The entire CHAL-12/D-06 notification flow is wired but dead.

2. **`multiStepBool` from Step 1 of the wizard is silently discarded** — the Toggle on page 0 captures the user's "Did you work out today?" answer but it is never included in the `CheckInPayload.multiStep` sent on page 1. The boolean value is dead state.

3. **`seedFeaturedTemplates` idempotency guard is too coarse** — guards on `existing.isEmpty`, so a partial seed (1 of 3 templates inserted before a crash) permanently blocks the other 2 templates from ever being inserted.

4. **`progressValue` divides by zero when `durationDays == 0`** — the nil-coalescing default of `90` does not protect against an explicit zero stored in the model, producing NaN passed to `ProgressView`.

Five warnings cover: `scheduleChallengeReminder` not persisting `reminderHour`/`reminderMinute` to the model, the `longestStreak` denormalization shortcut diverging under CloudKit sync-driven deletes, a hardcoded "Days Alcohol-Free" label that is wrong for non-sobriety `dateBound` challenges, `featuredTemplates` being `static var` computed properties that create floating `@Model` instances on each access, and `ChallengeCheckInView` not catching `CheckInError.noteTooLong` specifically.

---

## Critical Issues

### CR-01: Challenge notification tap is completely unrouted — tapping a reminder does nothing

**File:** `VitaminG/VitaminG/VitaminG/VitaminGApp.swift:22-26` and `VitaminG/VitaminG/VitaminG/Services/NotificationDelegate.swift:31-33`

**Issue:** `NotificationScheduler.scheduleChallengeReminder` stores two keys in `userInfo`:
```
"deepLink": "challengeCheckIn"
"userChallengeID": challengeID.uuidString
```
`NotificationDelegate.userNotificationCenter(_:didReceive:)` correctly extracts the `deepLink` string and calls `onDeepLink("challengeCheckIn")`. However, the `onDeepLink` closure wired in `VitaminGApp.init()` (line 23) only handles the literal string `"goalList"`. The `"challengeCheckIn"` value falls through the `if` with no `else if` branch. `AppRouter.pendingChallengeCheckInID` is never set, `ChallengeCheckInDeepLinkItem` is never created, and the check-in sheet declared in `ContentView` is never triggered. The user taps the notification, the app opens, nothing happens.

Additionally, the `onDeepLink` callback signature is `(String) -> Void` — it receives only the `deepLink` string, not the full `userInfo`. Even if an `else if deepLink == "challengeCheckIn"` branch were added, it could not read `userChallengeID` because `NotificationDelegate` discards `userInfo` after extracting `deepLink`.

**Fix:** Change `NotificationDelegate` to pass the full `userInfo` to the callback, then handle the challenge case in `VitaminGApp`:

```swift
// NotificationDelegate.swift — change callback signature
private let onDeepLink: (String, [AnyHashable: Any]) -> Void

func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
) {
    if let deepLink = response.notification.request.content.userInfo["deepLink"] as? String {
        onDeepLink(deepLink, response.notification.request.content.userInfo)
    }
    completionHandler()
}

// VitaminGApp.init() — handle challenge case
let delegate = NotificationDelegate { deepLink, userInfo in
    if deepLink == "goalList" {
        appRouter.popToRoot()
    } else if deepLink == "challengeCheckIn",
              let idString = userInfo["userChallengeID"] as? String {
        appRouter.pendingChallengeCheckInID = idString
    }
}
```

---

### CR-02: `multiStepBool` from Step 1 of the wizard is silently discarded — user data is lost

**File:** `VitaminG/VitaminG/VitaminG/Views/ChallengeCheckInView.swift:112-158`

**Issue:** `multiStepCheckInSection` shows a Toggle bound to `@State private var multiStepBool: Bool` on page 0 with the prompt "Did you work out today?". When the user taps "Next Step" and proceeds to page 1, `save(payload:)` is called with:
```swift
CheckInPayload.multiStep(note: "", numericValue: Double(multiStepNumericText))
```
`multiStepBool` is never referenced here. The user's boolean answer from step 1 is permanently lost — it is not passed in the payload, not stored in `CheckIn`, and not used anywhere. The `CheckInPayload.multiStep` case has a `note: String` parameter that could carry the boolean as a string, or the payload could be extended. As implemented, Step 1 of the wizard collects data that is thrown away.

**Fix:** Include the step 1 value in the payload. The simplest approach using the existing `note` field:
```swift
save(payload: CheckInPayload.multiStep(
    note: multiStepBool ? "completed" : "skipped",
    numericValue: Double(multiStepNumericText)
))
```
A more robust fix adds a `numericBool` field to the `multiStep` case and extends `CheckInPayload.apply(to:)` to write `payloadBool` on the `CheckIn`.

---

### CR-03: `seedFeaturedTemplates` idempotency guard blocks partial-seed recovery

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/ChallengeViewModel.swift:75-84`

**Issue:** Line 80: `guard existing.isEmpty else { return }`. This returns immediately if any featured template exists, regardless of whether all three are present. If the app crashes mid-seed (after inserting 1 of 3 templates but before the context auto-saves), or if a future phase adds a 4th featured template, the incomplete catalog is never repaired. The user sees a permanently incomplete list of challenges with no error or recovery path.

Additionally, `seedFeaturedTemplates` is called from `ChallengeDiscoveryView.onAppear` (line 34 of `ChallengeDiscoveryView.swift`). On tab-switching, `onAppear` fires repeatedly. If the first call inserts templates and auto-save has not yet committed, a second `onAppear` call will find `existing.isEmpty == true` (unflushed context), re-insert all three templates, and create duplicates.

**Fix:** Use per-title deduplication to insert only the missing templates:
```swift
func seedFeaturedTemplates(context: ModelContext) {
    let descriptor = FetchDescriptor<ChallengeTemplate>(
        predicate: #Predicate<ChallengeTemplate> { $0.isFeatured == true }
    )
    let existing = (try? context.fetch(descriptor)) ?? []
    let existingTitles = Set(existing.compactMap { $0.title })
    for template in ChallengeTemplate.featuredTemplates {
        if let title = template.title, !existingTitles.contains(title) {
            context.insert(template)
        }
    }
}
```

---

### CR-04: `progressValue` divides by zero when `durationDays` is `0`, producing NaN passed to `ProgressView`

**File:** `VitaminG/VitaminG/VitaminG/Views/ChallengeDetailView.swift:219-222`

**Issue:**
```swift
private var progressValue: Double {
    let total = userChallenge.template?.durationDays ?? 90
    return min(1.0, Double(userChallenge.totalCheckIns) / Double(total))
}
```
`durationDays` is `Int?`. The nil-coalescing `?? 90` guards against `nil`, but if `durationDays` is stored as `0` (possible via corrupted CloudKit sync, a future custom-challenge feature, or direct model tampering), `total = 0`, and `Double(n) / Double(0)` is `+Infinity` (for n > 0) or `NaN` (for n == 0). `min(1.0, +Infinity) == 1.0` (incidentally correct), but `min(1.0, NaN)` is NaN in Swift's IEEE 754 implementation. `ProgressView(value: NaN)` has undefined rendering behavior — it typically renders as a full bar but may crash on some UIKit-backed implementations.

**Fix:**
```swift
private var progressValue: Double {
    let total = userChallenge.template?.durationDays ?? 90
    guard total > 0 else { return 0.0 }
    return min(1.0, Double(userChallenge.totalCheckIns) / Double(total))
}
```

---

## Warnings

### WR-01: `scheduleChallengeReminder` does not write back `reminderHour`/`reminderMinute` to the model — data lost after CloudKit restore

**File:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift:188-227`

**Issue:** `UserChallenge` declares `reminderHour: Int?` and `reminderMinute: Int?` (SchemaV4.swift lines 73-74), and these fields are read in `ChallengeDetailView.reminderLabel` and `reminderBinding`. The intent is clear: these persist the user's chosen reminder time in the model so it survives app reinstalls and CloudKit restores. However, `NotificationScheduler.scheduleChallengeReminder(for:hour:minute:)` never writes `challenge.reminderHour = hour` or `challenge.reminderMinute = minute`. The fields are only written by `ChallengeDetailView.reminderBinding.set` (line 244-245 of ChallengeDetailView.swift), which correctly sets them before calling the scheduler. If `scheduleChallengeReminder` is called from any other path (e.g., a future "reschedule all on launch" function that reads reminders from models), the hour/minute will be `nil` because the scheduler was never responsible for persisting them. The current call site happens to work, but the contract is fragile.

**Fix:** Make `scheduleChallengeReminder` own the write-back so the contract is always satisfied:
```swift
func scheduleChallengeReminder(for challenge: UserChallenge, hour: Int, minute: Int) async {
    challenge.reminderHour = hour
    challenge.reminderMinute = minute
    // ... rest of scheduling
}
```
Then `ChallengeDetailView.reminderBinding.set` can remove its duplicate assignment.

---

### WR-02: `longestStreak` uses a `max` shortcut that diverges under check-in deletion or CloudKit out-of-order sync

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/ChallengeViewModel.swift:190`

**Issue:**
```swift
challenge.longestStreak = max(challenge.longestStreak, challenge.currentStreak)
```
This is correct for append-only check-in history, but SwiftData with CloudKit can deliver deletes. If a CheckIn record is deleted (by the user on another device) and the relationship syncs, `challenge.checkIns` shrinks — but `challenge.longestStreak` is never recomputed downward. The stored value permanently overstates the true longest streak. Additionally, `currentStreak` is the current consecutive run, not the all-time longest; taking `max(longestStreak, currentStreak)` will miss a historical run that was longer than the current one but shorter than the stored value. (Example: stored longestStreak=10 from a previous run, current run is 6 — the max correctly stays 10. But if the historical 10-day run's check-ins are deleted via sync, longestStreak stays 10 even though no run of 10 days ever existed in the remaining data.)

**Fix:**
```swift
challenge.longestStreak = ChallengeStreakEngine.longestStreak(from: allDates)
```
This keeps `longestStreak` consistent with the actual check-in history on every write, at O(n log n) cost bounded to 90 days.

---

### WR-03: `progressSection` hardcodes "Days Alcohol-Free" for all `dateBound` goal types

**File:** `VitaminG/VitaminG/VitaminG/Views/ChallengeDetailView.swift:133-136`

**Issue:**
```swift
if userChallenge.template?.goalType == "dateBound" {
    Text("Days Alcohol-Free")
```
This label is sobriety-specific. The `goalType` field is a free-form string that could represent any date-bound challenge (a future fitness or finance challenge with a fixed end date, for example). The hardcoded string would incorrectly label a non-sobriety challenge as "Days Alcohol-Free". Even within the current catalog there is no `dateBound` template, making this branch dead code with a wrong label ready to mislead users when such a template is added.

**Fix:** Read the label from the template or derive it from the category:
```swift
if userChallenge.template?.goalType == "dateBound" {
    Text(userChallenge.template?.category == "sobriety" ? "Days Alcohol-Free" : "Days Completed")
```
Or add a `progressLabel: String?` field to `ChallengeTemplate` to make it data-driven.

---

### WR-04: `ChallengeTemplate.featuredTemplates` is a `static var` computed property — allocates new `@Model` instances on every access

**File:** `VitaminG/VitaminG/VitaminG/Models/ChallengeTemplate+Featured.swift:32-36`

**Issue:** `static var featuredTemplates: [ChallengeTemplate]` (line 32) and each of `summerBodyTemplate`, `save5000Template`, `drySummerTemplate` are computed properties — Swift recomputes them on every access. Each call to `featuredTemplates` allocates three new `ChallengeTemplate()` instances. Because `ChallengeTemplate` is a SwiftData `@Model` class, these are persistent model objects created outside any `ModelContext`. Accessing `ChallengeTemplate.featuredTemplates` from anywhere other than `seedFeaturedTemplates` (e.g., a future view that wants to display catalog metadata without inserting) creates floating model objects that are not tracked by any context and may trigger SwiftData assertions on iOS 17.

**Fix:** Change to factory functions with explicit naming to signal single-use intent:
```swift
static func makeFeaturedTemplates() -> [ChallengeTemplate] {
    [makeSummerBodyTemplate(), makeSave5000Template(), makeDrySummerTemplate()]
}
// rename individual statics to makeSummerBodyTemplate(), etc.
```
This makes the allocation cost explicit at every call site and prevents accidental repeated access.

---

### WR-05: `ChallengeCheckInView.save` does not catch `CheckInError.noteTooLong` — user sees a generic error message

**File:** `VitaminG/VitaminG/VitaminG/Views/ChallengeCheckInView.swift:177-186`

**Issue:**
```swift
private func save(payload: CheckInPayload) {
    do {
        try viewModel.recordCheckIn(for: userChallenge, payload: payload, context: modelContext)
        dismiss()
    } catch CheckInError.alreadyCheckedInToday {
        saveError = "Already checked in today."
    } catch {
        saveError = "Couldn't save your check-in. Please try again."
    }
}
```
`recordCheckIn` can throw `CheckInError.noteTooLong` (line 12-13 of `ChallengeViewModel.swift`) when a multiStep note exceeds 500 characters after sanitization. This error falls into the generic `catch` branch and displays "Couldn't save your check-in. Please try again." — a misleading message that gives the user no indication that the note is too long. As implemented with the multiStep wizard always passing `note: ""`, this error can never be triggered today (see CR-02). But the error is defined in the public API and should be handled correctly now to avoid a confusing UX regression when CR-02 is fixed.

**Fix:**
```swift
} catch CheckInError.noteTooLong {
    saveError = "Your note is too long. Please shorten it to 500 characters or fewer."
} catch {
    saveError = "Couldn't save your check-in. Please try again."
}
```

---

## Info

### IN-01: `CheckIn` declares both `date` and `timestamp` with no documented semantic distinction

**File:** `VitaminG/VitaminG/VitaminG/Models/SchemaV4.swift:83-87`

**Issue:** `CheckIn` has `var date: Date?` and `var timestamp: Date?`. In `ChallengeViewModel.recordCheckIn`, both are set to `Date()` at the same moment (lines 170-171). There is no comment distinguishing them. The one-per-day enforcement in `todayCheckIn` queries `ci.date` — if a future developer uses `ci.timestamp` for the same purpose, the behavior differs only if the two fields ever diverge. The duplication adds maintenance risk with no documented benefit.

**Fix:** Add inline comments:
```swift
var date: Date?       // Calendar day anchor — used for one-per-day enforcement (startOfDay range query)
var timestamp: Date?  // Exact submission wall-clock time — retained for future audit or ordering use
```
If the two will always be set together, consider whether a single `Date?` field is sufficient.

---

### IN-02: `StreakChainView.checkedInDays` uses `.map` instead of `.compactMap` — not a crash risk but skips nil-safety

**File:** `VitaminG/VitaminG/VitaminG/Views/Components/StreakChainView.swift:32-34`

**Issue:**
```swift
private var checkedInDays: Set<Date> {
    Set(checkInDates.map { Calendar.current.startOfDay(for: $0) })
}
```
`checkInDates: [Date]` is non-optional (declared `let checkInDates: [Date]`), so there is no nil risk here. However, `ChallengeStreakEngine` uses `.compactMap` throughout for the same transformation, and the parallel caller in `ChallengeDetailView` line 29 also uses `.compactMap { $0.date }` before passing dates to this view. The inconsistency between `.map` here and `.compactMap` in the engine is a minor style divergence that could confuse readers who expect the nil-safety pattern to be consistent.

**Fix:** No code change required (the type is already `[Date]`, so `.map` is correct). Add a comment confirming the array is pre-filtered:
```swift
// checkInDates is already [Date] (non-optional) — .map is safe here
```

---

### IN-03: `AppRoute.publicProfile` and `AppRoute.challengeCheckIn` are handled with `EmptyView()` in `navigationDestination` — accidental pushes produce silent empty screens

**File:** `VitaminG/VitaminG/VitaminG/Views/ContentView.swift:92-101`

**Issue:** Both `case .publicProfile` and `case .challengeCheckIn` resolve to `EmptyView()` in the `navigationDestination` switch, with comments noting they are sheet-only paths. If either route is ever accidentally appended to `router.path` (e.g., by a future developer calling `router.navigate(to: .challengeCheckIn(...))`), the NavigationStack pushes a blank white screen with a back button but no visible content. There is no assertion to catch this during development.

**Fix:** Add `#if DEBUG` assertions to make accidental pushes visible:
```swift
case .publicProfile:
    let _ = { assertionFailure("Route .publicProfile must be presented as a sheet via pendingPublicProfileRecordID, not pushed") }()
    EmptyView()
case .challengeCheckIn:
    let _ = { assertionFailure("Route .challengeCheckIn from NavigationStack push is not supported; use the sheet path") }()
    EmptyView()
```

---

_Reviewed: 2026-05-06T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
