---
phase: 13-challenge-platform-core-engine
reviewed: 2026-05-06T18:00:00Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - VitaminG/VitaminG/VitaminG/Models/ChallengeTemplate+Featured.swift
  - VitaminG/VitaminG/VitaminG/Models/SchemaV4.swift
  - VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift
  - VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift
  - VitaminG/VitaminG/VitaminG/Navigation/AppRouter.swift
  - VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift
  - VitaminG/VitaminG/VitaminG/Services/ChallengeStreakEngine.swift
  - VitaminG/VitaminG/VitaminG/Services/DeepLinkBuilder.swift
  - VitaminG/VitaminG/VitaminG/Services/DeepLinkParser.swift
  - VitaminG/VitaminG/VitaminG/Services/NotificationDelegate.swift
  - VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift
  - VitaminG/VitaminG/VitaminG/ViewModels/ChallengeViewModel.swift
  - VitaminG/VitaminG/VitaminG/Views/ChallengeCheckInView.swift
  - VitaminG/VitaminG/VitaminG/Views/ChallengeDetailView.swift
  - VitaminG/VitaminG/VitaminG/Views/ChallengeDiscoveryView.swift
  - VitaminG/VitaminG/VitaminG/Views/Components/StreakChainView.swift
  - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
  - VitaminG/VitaminG/VitaminG/Views/MilestoneCelebrationView.swift
  - VitaminG/VitaminG/VitaminG/VitaminGApp.swift
findings:
  critical: 3
  warning: 5
  info: 3
  total: 11
status: issues_found
---

# Phase 13: Code Review Report

**Reviewed:** 2026-05-06T18:00:00Z
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

Phase 13 introduces the Challenge Platform core engine: three new SwiftData models (`ChallengeTemplate`, `UserChallenge`, `CheckIn`) in SchemaV4, a lightweight V3→V4 migration, `ChallengeStreakEngine`, featured template seeds, `ChallengeViewModel` with type-blind check-in dispatch, AppRoute/AppRouter extensions, DeepLinkBuilder/Parser for the new `vitaming://challengeCheckIn/` URL scheme, per-challenge notification scheduling, and six new Views.

The schema design is correct: all properties are optional or carry default values, no `@Attribute(.unique)`, and inverse relationships are declared on both sides. `ChallengeStreakEngine` is pure, injectable, and algorithmically correct. `CheckInPayload` dispatch avoids `switch checkInType` in the ViewModel as required. `NotificationDelegate` correctly passes the full `userInfo` dictionary to the closure, and `VitaminGApp` correctly extracts `userChallengeID` from it — the notification routing plumbing is wired.

Three blockers were found:

1. **Win-reminder notification tap is completely unrouted.** `NotificationScheduler.makeWinContent()` fires a daily notification with `"deepLink": "wins"`. The `NotificationDelegate` callback in `VitaminGApp.init()` only handles `"goalList"` and `"challengeCheckIn"`. Tapping the win reminder opens the app but performs no navigation.

2. **`seedFeaturedTemplates` idempotency guard is too coarse.** It returns early if any featured template exists, permanently blocking recovery from a partial seed (e.g., 1 of 3 templates inserted before a crash/force-quit). It also creates a duplicate-insertion window: `onAppear` fires on every tab switch; if called twice before the first auto-save, the guard finds an empty store both times and inserts all three templates twice.

3. **`progressValue` divides by zero when `durationDays` is `0`.** The `?? 90` guard protects against `nil` but not an explicit `0` stored in the model, producing `NaN` passed to `ProgressView` which has undefined rendering behavior.

Five warnings cover: `longestStreak` using a `max` shortcut that diverges under CloudKit-synced deletes, a hardcoded "Days Alcohol-Free" label wrong for any non-sobriety `dateBound` challenge, business logic (model mutation + async notification scheduling) living inside a View computed property, `static var` computed properties creating new floating `@Model` instances on every access, and `CheckInError.noteTooLong` not caught with a user-facing message.

---

## Critical Issues

### CR-01: Win-reminder notification tap is completely unrouted — tapping does nothing

**File:** `VitaminG/VitaminG/VitaminG/VitaminGApp.swift:22-32`

**Issue:** `NotificationScheduler.makeWinContent()` (NotificationScheduler.swift line 133) sets:
```swift
content.userInfo = ["deepLink": "wins"]
```
`NotificationDelegate` correctly extracts this value and calls `onDeepLink("wins", userInfo)`. The closure in `VitaminGApp.init()` handles only `"goalList"` and `"challengeCheckIn"`:
```swift
let delegate = NotificationDelegate { deepLink, userInfo in
    if deepLink == "goalList" {
        appRouter.popToRoot()
    } else if deepLink == "challengeCheckIn",
              let idString = userInfo["userChallengeID"] as? String {
        appRouter.pendingChallengeCheckInID = idString
    }
    // "wins" falls through — no navigation occurs
}
```
The `AppRoute.wins` case exists, `AppRouter.navigate(to:)` is available, and `DailyWinsView` is the tab destination. The routing is not wired. A user who taps a win reminder notification is silently dropped at whatever screen they were on last.

**Fix:** Add a `"wins"` branch to the delegate closure. Because `AppRouter.path` drives the Goals tab's `NavigationStack`, and the Wins tab is a sibling tab, the simplest correct approach is to use a dedicated pending state on `AppRouter` (parallel to `pendingChallengeCheckInID`) to switch the `TabView` selection to the Wins tab:

```swift
// AppRouter.swift — add pending wins state
var pendingWinsDeepLink: Bool = false

// VitaminGApp.init() — handle wins case
} else if deepLink == "wins" {
    appRouter.pendingWinsDeepLink = true
}
```

Then in `ContentView`, observe `router.pendingWinsDeepLink` with `.onChange` and switch the `TabView` selection to the Wins tab when it fires.

---

### CR-02: `seedFeaturedTemplates` idempotency guard blocks partial-seed recovery and creates a duplicate-insertion window

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/ChallengeViewModel.swift:75-84`

**Issue:** Line 80:
```swift
guard existing.isEmpty else { return }
```
This guard treats the presence of any one featured template as proof all three are seeded. Two failure modes follow:

**Partial-seed recovery gap:** If the app is force-quit between inserting template 1 and template 3 (before `ModelContext` auto-saves), subsequent launches find `existing.count == 1` and return without inserting the remaining two. The incomplete catalog is permanent.

**Duplicate-insertion window on rapid tab switches:** `seedFeaturedTemplates` is called from `ChallengeDiscoveryView.onAppear` (ChallengeDiscoveryView.swift line 34). SwiftUI fires `onAppear` on every tab switch. If the Challenges tab is visited twice in quick succession before the first `ModelContext` auto-save commits the inserted objects, the second call also finds `existing.isEmpty == true` and inserts all three templates again, creating duplicates.

**Fix:** Guard per-title, inserting only the templates not yet present:
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
This is idempotent per-template and safe to call on every `onAppear`.

---

### CR-03: `progressValue` divides by zero when `durationDays` is `0`, producing `NaN` passed to `ProgressView`

**File:** `VitaminG/VitaminG/VitaminG/Views/ChallengeDetailView.swift:219-222`

**Issue:**
```swift
private var progressValue: Double {
    let total = userChallenge.template?.durationDays ?? 90
    return min(1.0, Double(userChallenge.totalCheckIns) / Double(total))
}
```
`durationDays` is `Int?`. The `?? 90` nil-coalescing default handles `nil`, but does not guard against an explicit `0`. A value of `0` can reach the model through a corrupted CloudKit sync record or via a future custom-challenge path where the user does not set a duration. When `total == 0` and `totalCheckIns > 0`, the result is `+Infinity`; `min(1.0, +Infinity)` incidentally returns `1.0`. When `total == 0` and `totalCheckIns == 0`, the result is `NaN`; `min(1.0, NaN)` returns `NaN` under IEEE 754 semantics in Swift. Passing `NaN` to `ProgressView(value:)` has undefined rendering behavior.

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

### WR-01: `longestStreak` is updated via `max` shortcut and permanently overstates after check-in deletion

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/ChallengeViewModel.swift:190`

**Issue:**
```swift
challenge.longestStreak = max(challenge.longestStreak, challenge.currentStreak)
```
`currentStreak` is the length of the current consecutive run ending today. Taking `max(stored, currentStreak)` is correct for append-only history, but SwiftData with CloudKit delivers deletions when a record is deleted on another device. If a `CheckIn` record is deleted and synced, `challenge.checkIns` shrinks and `currentStreak` drops — but `challenge.longestStreak` is never recomputed downward. The stored value permanently overstates the historical best.

Additionally, `currentStreak` can never exceed the true `longestStreak` during a single check-in event unless the current run is the longest ever. There are intermediate states (e.g., a 6-day current run that is shorter than a previous 10-day run) where `max(10, 6)` is correctly 10, but the stored `10` is never verified against the actual data.

**Fix:** Replace the `max` shortcut with a full recompute that stays consistent with the actual check-in set:
```swift
challenge.longestStreak = ChallengeStreakEngine.longestStreak(from: allDates)
```
This is O(n log n) bounded to 90 check-ins per challenge, which is negligible.

---

### WR-02: Business logic (model mutation + async notification scheduling) lives inside a View computed property — MVVM violation

**File:** `VitaminG/VitaminG/VitaminG/Views/ChallengeDetailView.swift:231-252`

**Issue:** `reminderBinding` is a `Binding<Date>` declared as a `private var` computed property directly in the View:
```swift
private var reminderBinding: Binding<Date> {
    Binding<Date>(
        get: { ... },
        set: { newDate in
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
            let h = comps.hour ?? 20
            let m = comps.minute ?? 0
            userChallenge.reminderHour = h      // <-- SwiftData model mutation in View
            userChallenge.reminderMinute = m    // <-- SwiftData model mutation in View
            Task {
                await NotificationScheduler.shared.scheduleChallengeReminder(
                    for: userChallenge, hour: h, minute: m   // <-- async side effect in View
                )
            }
        }
    )
}
```
The `setter` directly mutates SwiftData `@Model` properties and fires an async `Task` that calls the notification service. Per the project's MVVM constraint (CLAUDE.md: "MVVM strictly enforced — no business logic in Views"), both the model mutation and the notification scheduling belong in `ChallengeViewModel`.

**Fix:** Move the logic to `ChallengeViewModel`:
```swift
// ChallengeViewModel.swift
func setReminder(for challenge: UserChallenge, hour: Int, minute: Int) async {
    challenge.reminderHour = hour
    challenge.reminderMinute = minute
    await NotificationScheduler.shared.scheduleChallengeReminder(
        for: challenge, hour: hour, minute: minute
    )
}
```
Then the View's `reminderBinding` setter becomes a single call:
```swift
set: { newDate in
    let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
    Task { await viewModel.setReminder(for: userChallenge,
                                        hour: comps.hour ?? 20,
                                        minute: comps.minute ?? 0) }
}
```

---

### WR-03: `progressSection` hardcodes "Days Alcohol-Free" for all `dateBound` goal types

**File:** `VitaminG/VitaminG/VitaminG/Views/ChallengeDetailView.swift:133-136`

**Issue:**
```swift
if userChallenge.template?.goalType == "dateBound" {
    Text("Days Alcohol-Free")
```
The `goalType` field is a free-form `String?`. Any future date-bound challenge (fitness, finance, etc.) would display the sobriety-specific label "Days Alcohol-Free". None of the three current featured templates use `goalType == "dateBound"` (they use `"streak"` and `"target"`), making this branch dead code with a categorically wrong label waiting to mislead users.

**Fix:** Derive the label from the template's category:
```swift
if userChallenge.template?.goalType == "dateBound" {
    let label = userChallenge.template?.category == "sobriety"
        ? "Days Alcohol-Free"
        : "Days Completed"
    Text(label)
```
Or add a `progressLabel: String?` field to `ChallengeTemplate` to make it fully data-driven.

---

### WR-04: `ChallengeTemplate.featuredTemplates` is a `static var` computed property — allocates new `@Model` instances on every access

**File:** `VitaminG/VitaminG/VitaminG/Models/ChallengeTemplate+Featured.swift:32-36`

**Issue:** `featuredTemplates`, `summerBodyTemplate`, `save5000Template`, and `drySummerTemplate` are all declared as `static var` computed properties. Every access re-evaluates them and allocates new `ChallengeTemplate()` instances. Because `ChallengeTemplate` is a SwiftData `@Model` class, these are persistent model objects instantiated with `init()` outside any `ModelContext`. SwiftData tracks `@Model` objects by context; floating instances created this way are not tracked and may trigger internal SwiftData consistency checks or assertions on iOS 17 in certain code paths. The current single call site (`seedFeaturedTemplates`) happens to insert them immediately and never reads `featuredTemplates` a second time, but nothing prevents a future caller from iterating `featuredTemplates` repeatedly.

**Fix:** Rename to factory functions to make the allocation cost explicit and single-use intent clear:
```swift
static func makeFeaturedTemplates() -> [ChallengeTemplate] {
    [makeSummerBodyTemplate(), makeSave5000Template(), makeDrySummerTemplate()]
}
static func makeSummerBodyTemplate() -> ChallengeTemplate { ... }
// etc.
```

---

### WR-05: `ChallengeCheckInView.save` does not catch `CheckInError.noteTooLong` specifically — user receives a misleading generic error

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
`ChallengeViewModel.recordCheckIn` is declared to throw `CheckInError.noteTooLong` when a multiStep note exceeds 500 characters post-sanitization (ChallengeViewModel.swift lines 12-13). This error falls into the generic `catch` branch displaying "Couldn't save your check-in. Please try again." — an actionable error that gives the user no information that the note is the problem.

The multiStep wizard currently passes `note: multiStepBool ? "completed" : "skipped"`, which never exceeds 500 characters, so this error cannot be triggered today. However, `noteTooLong` is a defined public contract of `recordCheckIn`, and any future UI extension (free-text multiStep notes) will silently display the wrong error message.

**Fix:**
```swift
} catch CheckInError.noteTooLong {
    saveError = "Your note is too long (500 character limit). Please shorten it and try again."
} catch {
    saveError = "Couldn't save your check-in. Please try again."
}
```

---

## Info

### IN-01: `CheckIn` declares both `date` and `timestamp` with no documented semantic distinction

**File:** `VitaminG/VitaminG/VitaminG/Models/SchemaV4.swift:89-90`

**Issue:** `CheckIn` has `var date: Date?` and `var timestamp: Date?`. In `ChallengeViewModel.recordCheckIn` both are set to `Date()` at the same instant (lines 170-171). One-per-day enforcement queries `ci.date` (ChallengeViewModel.swift line 101). Without inline documentation distinguishing the two fields, a future developer may write to `timestamp` when they intend `date` (or vice versa), silently breaking duplicate detection.

**Fix:** Add clarifying comments to the model:
```swift
var date: Date?       // Calendar day anchor — used for one-per-day enforcement (startOfDay range)
var timestamp: Date?  // Exact wall-clock submission time — reserved for future ordering/audit use
```

---

### IN-02: `AppRoute.publicProfile` and `AppRoute.challengeCheckIn` resolve to `EmptyView()` in `navigationDestination` with no development-time guard

**File:** `VitaminG/VitaminG/VitaminG/Views/ContentView.swift:92-101`

**Issue:** Both routes are documented as sheet-only and should never be pushed onto the Goals tab's `NavigationStack`. If a future developer calls `router.navigate(to: .challengeCheckIn(...))` or `.publicProfile(...)`, the NavigationStack pushes a blank white screen with a back button and no visible content, with no development-time feedback that this is wrong.

**Fix:** Add `#if DEBUG` assertions to make accidental pushes immediately visible during development:
```swift
case .publicProfile:
    let _ = { assertionFailure(
        ".publicProfile must be presented as a sheet; do not push onto NavigationStack") }()
    EmptyView()
case .challengeCheckIn:
    let _ = { assertionFailure(
        ".challengeCheckIn via NavigationStack is not supported; use the sheet path") }()
    EmptyView()
```

---

### IN-03: `ChallengeDiscoveryView` category chips are decorative-only with no filter behavior and no disabled/selected state

**File:** `VitaminG/VitaminG/VitaminG/Views/ChallengeDiscoveryView.swift:78-92`

**Issue:** The "Browse by Category" row renders tappable-looking `Text` chips for "Fitness", "Finance", and "Sobriety" but attaches no action or selection state. Tapping a chip does nothing. There is no visual feedback distinguishing selected from unselected, no filtering of the featured list, and no accessibility hint indicating the chips are non-interactive. Users who tap a chip expecting to filter challenges will see no response and may assume the app is broken.

**Fix:** Either make the chips functional (add a `@State var selectedCategory: String?` and filter `templates` by matching category), or mark them visually and accessibly as non-interactive labels:
```swift
Text(category)
    // ...
    .allowsHitTesting(false)
    .accessibilityLabel("\(category) category")
    .accessibilityHint("Category filter coming soon")
```

---

_Reviewed: 2026-05-06T18:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
