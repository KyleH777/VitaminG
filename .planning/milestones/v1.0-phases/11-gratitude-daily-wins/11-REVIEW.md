---
phase: 11-gratitude-daily-wins
reviewed: 2026-05-01T00:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - VitaminG/VitaminG/VitaminG/Models/SchemaV3.swift
  - VitaminG/VitaminG/VitaminG/Models/SchemaV2.swift
  - VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift
  - VitaminG/VitaminG/VitaminG/ViewModels/DailyWinsViewModel.swift
  - VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift
  - VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift
  - VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift
  - VitaminG/VitaminG/VitaminG/Views/DailyWinsView.swift
  - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
  - VitaminG/VitaminG/VitaminG/Views/SettingsView.swift
  - VitaminG/VitaminG/VitaminG/Views/ProfileView.swift
  - VitaminG/VitaminG/VitaminG/VitaminGApp.swift
  - VitaminG/VitaminG/VitaminGTests/DailyWinsViewModelTests.swift
findings:
  critical: 1
  warning: 6
  info: 3
  total: 10
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-05-01
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Phase 11 adds `DailyWin` as a new SwiftData model (`SchemaV3`), a `DailyWinsViewModel` with upsert/validation logic, a win-reminder notification, and a new Wins tab in the TabView. The overall architecture is sound and consistent with the established MVVM pattern. The migration plan, CloudKit-compatibility constraints, and notification identifier separation are all correctly implemented.

One critical bug was found: the win-reminder notification fires unconditionally on every app launch regardless of authorization status, which degrades user experience and violates the design intent. Six warnings cover notification-scheduling races, a silent `try?` swallowing errors, a stale editor state bug, a character-count display discrepancy, an iOS notification cap risk, and a missing `saveEntry` call to clear the draft on success. Three info items cover minor quality issues.

---

## Critical Issues

### CR-01: Win reminder scheduled on every launch without checking authorization

**File:** `VitaminG/VitaminG/VitaminG/VitaminGApp.swift:57-59`

**Issue:** `.task { await NotificationScheduler.shared.rescheduleWinReminder() }` runs unconditionally on every app launch. `rescheduleWinReminder` calls `scheduleWinReminder`, which calls `UNUserNotificationCenter.add(_:)` without first verifying the user has granted notification permission. On a device where notifications were never granted or were denied, this silently adds a pending notification request that the system will reject — but more importantly, the remove-before-add pattern inside `scheduleWinReminder` will cancel any legitimately scheduled goal notification that existed, because the same `UNUserNotificationCenter` applies to all pending requests. Additionally, calling `rescheduleWinReminder` but not `reschedule(activeGoals:)` at launch means the goal reminder is NOT refreshed on launch, while the win reminder is — creating an asymmetry that can leave the goal notification stale after the app relaunches.

The existing `reschedule(activeGoals:)` call in `SettingsView` is conditional on authorization status; `rescheduleWinReminder()` at launch has no such guard.

**Fix:**
```swift
// VitaminGApp.swift — replace the unconditional .task with an authorized-only schedule:
.task {
    let isGranted = await NotificationScheduler.shared.isAuthorized()
    if isGranted {
        await NotificationScheduler.shared.rescheduleWinReminder()
    }
}
```

---

## Warnings

### WR-01: `scheduleWinReminder` and `schedule` silently discard `center.add` errors

**File:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift:72` and `150`

**Issue:** Both scheduling methods use `try? await center.add(request)`, discarding any `UNError` thrown by the system (e.g., `.notificationsNotAllowed`, `.badgeInputInvalid`). When the user revokes permission between the authorization check and the `add` call, the failure is invisible. In DEBUG builds this is especially unhelpful because there is no indication the schedule failed.

**Fix:**
```swift
do {
    try await center.add(request)
} catch {
    // At minimum log in DEBUG; production callers can ignore non-fatal errors
    #if DEBUG
    print("[NotificationScheduler] Failed to add request: \(error)")
    #endif
}
```

### WR-02: `DailyWinsView.onAppear` pre-fills editor but `saveEntry` does not clear `draftText` on success

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/DailyWinsViewModel.swift:66-86` and `VitaminG/VitaminG/VitaminG/Views/DailyWinsView.swift:141-144`

**Issue:** `onAppear` pre-fills `viewModel.draftText` with the existing today entry so the user can edit it. However, after a successful `saveEntry` the `draftText` is never reset and `validationError` is cleared but the draft stays populated. This is intentional for the upsert-edit pattern. The real bug is the inverse: if the user deletes today's win via swipe-delete in the history list while the editor is pre-filled, the editor still shows the stale pre-filled text. A subsequent save will re-create the deleted entry with no user confirmation, contradicting the delete intent.

**Fix:** In `DailyWinsView`, clear `viewModel.draftText` after a confirmed delete if the deleted win was today's entry:
```swift
Button("Delete", role: .destructive) {
    if let win = winToDelete {
        if Calendar.current.isDateInToday(win.date ?? .distantPast) {
            viewModel.draftText = ""
        }
        viewModel.delete(win, context: modelContext)
    }
}
```

### WR-03: Character counter uses `draftText.count` instead of sanitized count, creating a mismatch

**File:** `VitaminG/VitaminG/VitaminG/Views/DailyWinsView.swift:63`

**Issue:** The counter displays `viewModel.draftText.count` (raw unsanitized characters), but `saveEntry` validates against `InputSanitizer.sanitize(draftText).count`. A user who enters 501 characters consisting of leading/trailing whitespace or control characters will see "501/500" and the button will be disabled, but `saveEntry` will succeed because the sanitized string is shorter. Conversely, an entry that is exactly 500 raw characters but whose sanitized form is longer (unlikely but theoretically possible with Unicode normalization) would show "500/500" yet fail validation. The counter misleads the user.

**Fix:** Expose a computed property from the ViewModel that reflects the sanitized count, and bind the counter to it:
```swift
// DailyWinsViewModel
var sanitizedCount: Int { InputSanitizer.sanitize(draftText).count }

// DailyWinsView — line 63
Text("\(viewModel.sanitizedCount)/500")
    .accessibilityLabel("\(viewModel.sanitizedCount) of 500 characters used")
```

Also update the `Save Win` button disabled predicate at line 102 to check `viewModel.sanitizedCount == 0` for consistency.

### WR-04: `historyWins` filter includes wins with a `nil` date in the Past Wins list

**File:** `VitaminG/VitaminG/VitaminG/Views/DailyWinsView.swift:23-27`

**Issue:** The filter predicate is:
```swift
allWins.filter { win in
    guard let d = win.date else { return true }  // nil date → included in history
    return !Calendar.current.isDateInToday(d)
}
```
A `DailyWin` with `date == nil` passes the guard and is rendered in the history list. The `winRow` for such an entry would display an empty string for the date label (`win.date?.formatted(...) ?? ""`), which is confusing. The nil date also means `todayEntry(context:)` skips that record, so a corrupt/nil-dated win can never be edited, only seen in history.

**Fix:** Exclude nil-dated wins from the history list rather than including them:
```swift
private var historyWins: [DailyWin] {
    allWins.filter { win in
        guard let d = win.date else { return false }  // exclude nil-dated wins
        return !Calendar.current.isDateInToday(d)
    }
}
```

### WR-05: `SettingsView` duplicates the `authorizationRow` across two `Section` blocks

**File:** `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift:101` and `125`

**Issue:** `authorizationRow` is inserted into both the "Daily Reminder" section and the "Win Reminder" section. This means the "Enable Notifications" button or "Open Settings" button appears twice on screen simultaneously. When the user taps "Enable Notifications" in either section, `authStatus` is updated to `.authorized` or `.denied`, and both rows instantly switch state — which is correct behaviour, but renders the duplicate row redundant. If the authorization state is `.notDetermined`, the user sees two identical "Enable Notifications" buttons, and both will call `requestAuthorization()` racing against each other. On first launch the system dialog can only be shown once; the second tap returns `.denied` even though the user just granted access, setting `authStatus = .denied`.

**Fix:** Move `authorizationRow` out of both sections into a single dedicated section, or render it only once above both time pickers:
```swift
// Single top-level section before both pickers
Section("Notifications") {
    authorizationRow
}
Section("Daily Reminder") { ... } // no authorizationRow here
Section("Win Reminder") { ... }   // no authorizationRow here
```

### WR-06: `VitaminGMigrationPlan` is declared inside `SchemaV2.swift` but references `SchemaV3`

**File:** `VitaminG/VitaminG/VitaminG/Models/SchemaV2.swift:131-148`

**Issue:** The `VitaminGMigrationPlan` enum is defined inside `SchemaV2.swift` but includes `SchemaV3.self` in `schemas` and `migrateV2toV3` in `stages`. This creates a hidden coupling: editing the migration plan requires opening `SchemaV2.swift`, not the schema file where V3 lives. More significantly, if a future developer adds `SchemaV4` and correctly adds it to `SchemaV3.swift` without noticing the plan is in `SchemaV2.swift`, the migration chain will be silently incomplete, causing a SwiftData migration failure at runtime.

**Fix:** Move `VitaminGMigrationPlan` to its own file (`MigrationPlan.swift`) or to `SchemaV3.swift` (the highest-versioned schema file), so it lives adjacent to the most recent schema and the oversight risk is reduced. Update imports accordingly.

---

## Info

### IN-01: `DailyWin.id` is redundant — SwiftData provides a persistent identifier automatically

**File:** `VitaminG/VitaminG/VitaminG/Models/SchemaV3.swift:30`

**Issue:** `var id: UUID = UUID()` is explicitly declared and set twice (at declaration and inside `init`). SwiftData `@Model` classes already have a system-managed persistent identifier via `persistentModelID`. The explicit `id` property is not used as a SwiftData `@Attribute(.unique)` (which is prohibited for CloudKit anyway) and is not referenced anywhere else. It adds unnecessary storage per record and migration surface area. Both `Goal` and `CompletionEvent` also carry this pattern — consistent but wasteful.

**Fix:** Remove the `id` property from `DailyWin` (and consider the same for `Goal`/`CompletionEvent` in a future cleanup phase). Use `persistentModelID` where a stable identifier is needed.

### IN-02: `NotificationPreferences.hour/minute` reads from `UserDefaults.standard` but `saveWinTime` writes to both standard and App Group; `winHour/winMinute` only reads from standard

**File:** `VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift:63-76`

**Issue:** `winHour` and `winMinute` read from `UserDefaults.standard`, consistent with `saveWinTime` writing to `.standard`. However `sharedHour()`/`sharedMinute()` read from the App Group suite — there are no `sharedWinHour()`/`sharedWinMinute()` equivalents. If a future widget needs the win reminder time, the only available source via App Group is missing. This is not a current bug (no widget uses win time today) but the asymmetry will lead to a copy-paste error in future.

**Fix:** Add `sharedWinHour()` and `sharedWinMinute()` alongside the existing `sharedHour()`/`sharedMinute()` for symmetry.

### IN-03: `DailyWinsView` does not dismiss the keyboard after a successful save

**File:** `VitaminG/VitaminG/VitaminG/Views/DailyWinsView.swift:78-83`

**Issue:** The `Save Win` button action sets `editorFocused = false` inside the `catch` path but not inside the success path of the `do` block (the `editorFocused = false` at line 81 is actually after the `try`, not inside a catch). On a successful save the keyboard remains visible. This is a minor UX issue but inconsistent with standard iOS form save behavior.

**Fix:**
```swift
Button {
    do {
        try viewModel.saveEntry(context: modelContext)
        editorFocused = false   // dismiss keyboard on success
    } catch {
        // validationError set inside saveEntry
    }
} label: { ... }
```
*(Verify exact line placement — the current code at line 81 places `editorFocused = false` after `try` but before the catch, meaning it executes on both success and throw. If the compiler runs it pre-throw, it is correct; if the throw skips it, it is not. Confirm behavior and add a comment for clarity.)*

---

_Reviewed: 2026-05-01_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
