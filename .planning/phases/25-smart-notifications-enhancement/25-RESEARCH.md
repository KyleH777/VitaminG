# Phase 25: Smart Notifications Enhancement - Research

**Researched:** 2026-05-29
**Domain:** iOS UserNotifications, UserDefaults, SwiftUI Settings UI, streak-aware scheduling
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Morning Notification Copy (NOTIF-01, NOTIF-02)**
- D-01: Replace 7 generic `inspirationalMessages` with three static arrays: `celebratoryCopy` (streak >= 7), `neutralBuildingCopy` (streak 1-6), `encouragingCopy` (streak 0 or broken). ~4-7 messages per bank. Day-of-year rotation selects within the matching bank.
- D-02: `makeContent()` gains `currentStreak: Int` parameter. Signature: `makeContent(activeGoals: [Goal], currentStreak: Int) -> UNMutableNotificationContent`. Pure function — no hidden state reads.
- D-03: Callers pass `[CompletionEvent]` as a new parameter alongside `[Goal]`; scheduler calls `StreakEngine.currentStreak(from:)` internally and passes result to `makeContent`.
- D-04: Up to 2 active goal titles in body, newline-separated: `"{tone message}\n{Goal 1 title}\n{Goal 2 title}"`. Second title only when >= 2 non-completed goals with non-empty titles exist. Single-title body when only one active goal; tone message alone when none.

**Streak-at-Risk Per-Day Alert (NOTIF-04)**
- D-05: NOTIF-04 replaces the Phase 23 repeating `globalStreakAtRiskNudge`. Identifier `globalStreakAtRiskIdentifier` is reused but notification is no longer repeating. Each call to `schedule()` removes the old nudge and schedules a one-time `UNCalendarNotificationTrigger(dateMatching: {hour:19, minute:0}, repeats: false)`.
- D-06: Streak-at-risk alert body: `"Your \(topGoalTitle) streak is at risk — check in to keep your \(streak)-day run alive."` Falls back to generic when no active goal title available.
- D-07: `schedule()` schedules both the morning notification (repeating) and today's 7 PM one-shot alert. One-shot at next occurrence of 19:00 — if called after 7 PM, fires following day (acceptable).

**Check-In Hour Tracking (NOTIF-03)**
- D-08: UserDefaults key `"checkInHourHistory"` stores `[Int]` (hours 0-23), last 14 entries, FIFO. Written to App Group suite (`group.com.kyleharrington.VitaminG`). Added to `NotificationPreferences`.
- D-09: `GoalViewModel.addCheckIn()` appends `Calendar.current.component(.hour, from: Date())` immediately before `cancelGlobalStreakAtRiskNudge()`. Drops oldest entry when count exceeds 14.
- D-10: Modal analysis runs in `SettingsView.onAppear`. Condition to show banner: `history.count >= 14` AND `|modalHour - NotificationPreferences.hour| >= 2`. Modal hour = most frequently occurring hour (mode; ties broken by earliest occurrence).

**Nudge-Time Suggestion Banner (NOTIF-03 UI)**
- D-11: Banner is a conditional row inserted above the DatePicker in the Notifications section of SettingsView. Shown when `@State var showNudgeSuggestion: Bool` is true (computed in `.onAppear`).
- D-12: Banner displays: `"You usually check in around [modal time]. Shift your nudge to [modal time]?"` with Apply and X dismiss buttons. Apply calls `NotificationPreferences.save(hour:minute:)` and `NotificationScheduler.shared.reschedule(activeGoals:)`.
- D-13: Once acted on (Apply or X), set `UserDefaults` key `"nudgeSuggestionDismissed"` to `true`. Permanent — not re-exposed to user. Added to `NotificationPreferences`.

### Claude's Discretion

- Exact copy text for each of the three tone banks (~5 messages per bank)
- Exact copy for streak-at-risk fallback (no active goal)
- Dismiss button style (SF Symbol `xmark` icon button vs. "Dismiss" text)
- Mode tie-breaking logic for check-in hour histogram
- Whether `schedule()` skips one-shot 7 PM scheduling when current time is already past 7 PM

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NOTIF-01 | Daily morning notification copy tone adapts to current streak (celebratory >= 7 days, encouraging < 3 or broken, neutral in between); tone selection local, no network call | Three static copy banks in NotificationScheduler; StreakEngine.currentStreak() provides the Int; pure function makeContent pattern already established |
| NOTIF-02 | Daily morning notification body references actual active goal titles (up to 2) rather than generic placeholder copy | Existing makeContent already injects goal titles; extend to 2 titles with newline separator; D-04 specifies exact body format |
| NOTIF-03 | App analyses last 14 days of check-in timestamps; if modal check-in hour differs from nudge time by >= 2 hours, non-intrusive banner in Settings suggests shift — tapping applies change | UserDefaults FIFO [Int] array; modal computation in SettingsView.onAppear; banner as conditional row above DatePicker |
| NOTIF-04 | Each morning when daily nudge fires, app schedules a second UNCalendarNotificationTrigger (streak-at-risk) for 7 PM that day; alert cancelled automatically when user checks in via iOS app, widget, or Apple Watch | Replace repeating Phase 23 nudge with one-shot repeats:false per D-05; cancelGlobalStreakAtRiskNudge() already called in addCheckIn() |
</phase_requirements>

---

## Summary

Phase 25 is a contained extension of the existing `NotificationScheduler` service with four closely related behavioral upgrades. All work is local — no network calls, no SwiftData schema changes, no new widget families. The implementation surface spans four files: `NotificationScheduler.swift`, `NotificationPreferences.swift`, `GoalViewModel.swift`, and `SettingsView.swift`.

The most architectural change is the **signature evolution of `schedule()` and `reschedule()`** to accept `[CompletionEvent]` alongside `[Goal]`, enabling streak computation inside the scheduler. This change cascades to `GoalViewModel.rescheduleNotification()` (the only internal caller) and `SettingsView` (the only external caller of `reschedule()`). VitaminGApp also calls `reschedule(activeGoals: [])` at launch — that call site needs updating too.

The **one-shot 7 PM alert** (D-05) is the highest-risk change: it replaces a repeating notification with a per-call one-shot. The key invariant is that the same identifier (`globalStreakAtRiskIdentifier`) is used, so remove-before-add guarantees at most one pending instance regardless of how many times `schedule()` is called per day.

The **nudge suggestion banner** is pure UI in `SettingsView.onAppear` — no background computation, no reactive observation. The mode computation over a small `[Int]` array is trivial and safe on the main thread.

**Primary recommendation:** Extend `NotificationScheduler.schedule()/reschedule()` signatures first (Wave 0), then add copy banks + `makeContent` update (Wave 1), then one-shot 7 PM scheduling (Wave 2), then NOTIF-03 UserDefaults tracking + SettingsView banner (Wave 3).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tone-adaptive copy selection (NOTIF-01) | Service (NotificationScheduler) | — | Pure function; streak computed from events; no UI involvement |
| Goal-title injection (NOTIF-02) | Service (NotificationScheduler) | ViewModel (GoalViewModel) | Scheduler builds content; ViewModel fetches goals and passes them |
| One-shot 7 PM scheduling (NOTIF-04) | Service (NotificationScheduler) | App entry point (VitaminGApp) | Scheduler owns all UNUserNotificationCenter interactions |
| Check-in cancellation (NOTIF-04) | ViewModel (GoalViewModel.addCheckIn) | — | Already in place via cancelGlobalStreakAtRiskNudge(); no new sites |
| Check-in hour tracking (NOTIF-03 data) | ViewModel (GoalViewModel.addCheckIn) | Service (NotificationPreferences) | Appended at check-in time; stored in App Group UserDefaults |
| Modal analysis + banner trigger (NOTIF-03 UI) | View (SettingsView.onAppear) | — | Runs at view appearance; @State drives conditional row |
| UserDefaults key management | Service (NotificationPreferences) | — | Enum is single source of truth for all UDefaults keys |

---

## Standard Stack

No new external dependencies. This phase is 100% first-party Apple frameworks.

### Core
| Framework | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| UserNotifications | iOS 10+ | Schedule, cancel, and manage local notifications | The only framework for local push on iOS — already in use |
| Foundation (UserDefaults) | iOS 2+ | Persist check-in hour history and banner dismissed flag | Lightweight, synchronous, App Group-capable — no persistence overhead needed |
| SwiftUI | iOS 17+ | SettingsView banner row | Already the project UI layer |
| SwiftData | iOS 17+ | CompletionEvent fetch for streak computation | Already in use — passed into schedule() by callers |

### No New Packages Required

The package legitimacy audit is not applicable — this phase installs zero third-party dependencies.

---

## Package Legitimacy Audit

Not applicable. Phase 25 adds no external package dependencies.

---

## Architecture Patterns

### System Architecture Diagram

```
App Launch / Settings time change
        |
        v
GoalViewModel.rescheduleNotification(context:)
        |
        |-- FetchDescriptor<Goal>(predicate: !isCompleted)  --> [Goal]
        |-- FetchDescriptor<CompletionEvent>()              --> [CompletionEvent]
        |
        v
NotificationScheduler.schedule(hour:minute:activeGoals:completionEvents:)
        |
        |-- StreakEngine.currentStreak(from: completionEvents) --> streak: Int
        |-- makeContent(activeGoals:, currentStreak:)
        |       |-- select copy bank by streak tier
        |       |-- pick up to 2 active goal titles
        |       |-- assemble body string
        |       v
        |   UNMutableNotificationContent (morning, repeats: true)
        |
        |-- scheduleOneShotStreakAtRisk()
        |       |-- remove globalStreakAtRiskIdentifier (remove-before-add)
        |       |-- 64-cap guard (count < 60)
        |       v
        |   UNMutableNotificationContent (7 PM, repeats: false)
        |
        v
UNUserNotificationCenter.add(morningRequest)
UNUserNotificationCenter.add(oneShotRequest)

                    ----

User checks in (iOS / widget / Watch)
        |
        v
GoalViewModel.addCheckIn(for:context:)
        |
        |-- append hour to checkInHourHistory (NotificationPreferences)
        |-- cancelGlobalStreakAtRiskNudge()  --> removePendingNotificationRequests([globalStreakAtRiskIdentifier])
        |
        v
7 PM one-shot silently disappears from pending queue

                    ----

SettingsView.onAppear
        |
        |-- read checkInHourHistory from App Group UserDefaults
        |-- check nudgeSuggestionDismissed flag
        |-- if history.count >= 14 AND !dismissed:
        |       compute modalHour
        |       if |modalHour - NotificationPreferences.hour| >= 2:
        |           showNudgeSuggestion = true
        |
        v
Conditional banner row rendered above DatePicker
        |-- Apply → NotificationPreferences.save(hour:minute:)
        |           NotificationScheduler.shared.reschedule(activeGoals:completionEvents:)
        |           UserDefaults["nudgeSuggestionDismissed"] = true
        |           showNudgeSuggestion = false
        |-- X   → UserDefaults["nudgeSuggestionDismissed"] = true
                   showNudgeSuggestion = false
```

### Recommended Project Structure

No new files needed. All changes are extensions/modifications to existing files:

```
VitaminG/VitaminG/VitaminG/
├── Services/
│   ├── NotificationScheduler.swift   [MODIFY: makeContent, schedule, reschedule, one-shot]
│   └── NotificationPreferences.swift [MODIFY: add checkInHourHistory, nudgeSuggestionDismissed keys]
├── ViewModels/
│   └── GoalViewModel.swift           [MODIFY: rescheduleNotification, addCheckIn]
├── Views/
│   └── SettingsView.swift            [MODIFY: onAppear modal analysis, conditional banner row]
VitaminG/VitaminG/VitaminGTests/
├── NotificationSchedulerTests.swift          [MODIFY: update existing tests for new signature]
└── NotificationSchedulerPhase25Tests.swift   [NEW: tone selection, goal title formatting, one-shot]
```

### Pattern 1: Three-Bank Copy Selection by Streak Tier

**What:** Replace the single `inspirationalMessages` array with three arrays. A single `makeCopyBankIndex(streak:)` helper selects the correct bank.
**When to use:** In `makeContent(activeGoals:currentStreak:)` before assembling the body string.

```swift
// Source: [ASSUMED] — Swift idiomatic pattern
internal static let celebratoryCopy: [String] = [
    "You're on a roll! 🔥",
    "10 days strong — keep going!",
    // ... ~5 total
]
internal static let neutralBuildingCopy: [String] = [
    "Building something great one day at a time.",
    // ... ~5 total
]
internal static let encouragingCopy: [String] = [
    "Every day is a fresh start. 🌱",
    // ... ~5 total
]

private static func copyBank(for streak: Int) -> [String] {
    if streak >= 7 { return celebratoryCopy }
    if streak >= 1 { return neutralBuildingCopy }
    return encouragingCopy
}

func makeContent(activeGoals: [Goal], currentStreak: Int) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.title = "Good morning"
    let bank = Self.copyBank(for: currentStreak)
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    let message = bank[(dayOfYear - 1) % bank.count]
    // ... title injection as before
}
```

### Pattern 2: One-Shot 7 PM Alert with Remove-Before-Add

**What:** Schedule a non-repeating `UNCalendarNotificationTrigger` for 19:00 today using the stable `globalStreakAtRiskIdentifier`. Called from within `schedule()` after the morning request is added.
**When to use:** Every call to `schedule()`, subject to the 64-cap guard.

```swift
// Source: existing scheduleMilestoneNotification + scheduleGlobalStreakAtRiskNudge patterns [VERIFIED: codebase]
// One-shot: repeats: false
let trigger = UNCalendarNotificationTrigger(
    dateMatching: DateComponents(hour: 19, minute: 0),
    repeats: false
)
let request = UNNotificationRequest(
    identifier: Self.globalStreakAtRiskIdentifier,
    content: atRiskContent,
    trigger: trigger
)
```

Note: `UNCalendarNotificationTrigger` with `repeats: false` fires at the next matching time. If current time is past 19:00, the trigger fires at 19:00 the following day. This is the documented acceptable behavior per D-07. [CITED: Apple Developer Documentation — UNCalendarNotificationTrigger]

### Pattern 3: FIFO [Int] Array in App Group UserDefaults

**What:** Maintain a rolling 14-entry array of check-in hours in App Group UserDefaults.
**When to use:** In `addCheckIn()` before the `cancelGlobalStreakAtRiskNudge()` call.

```swift
// Source: NotificationPreferences.save(hour:minute:) pattern [VERIFIED: codebase]
static func appendCheckInHour(_ hour: Int) {
    let suite = UserDefaults(suiteName: suiteName)
    var history = (suite?.array(forKey: checkInHourHistoryKey) as? [Int]) ?? []
    history.append(hour)
    if history.count > 14 { history.removeFirst(history.count - 14) }
    suite?.set(history, forKey: checkInHourHistoryKey)
}
```

### Pattern 4: Modal Hour Computation

**What:** Find the most frequently occurring value in a `[Int]`. Ties broken by the value that appears first (earliest occurrence in history).
**When to use:** In `SettingsView.onAppear` to compute the suggested nudge hour.

```swift
// Source: [ASSUMED] — pure Swift, no library needed
static func modalHour(from history: [Int]) -> Int? {
    guard !history.isEmpty else { return nil }
    // Dictionary of hour -> first index (for tie-breaking) and count
    var counts: [Int: Int] = [:]
    for hour in history { counts[hour, default: 0] += 1 }
    let maxCount = counts.values.max()!
    // Among tied hours, pick the one with the lowest first-occurrence index
    let tiedHours = counts.filter { $0.value == maxCount }.map { $0.key }
    return tiedHours.min { lhs, rhs in
        (history.firstIndex(of: lhs) ?? Int.max) < (history.firstIndex(of: rhs) ?? Int.max)
    }
}
```

### Pattern 5: Conditional Banner Row in SettingsView

**What:** `@State var showNudgeSuggestion: Bool` drives a conditional `if showNudgeSuggestion { ... }` block inserted as a row above the `DatePicker` in the "Daily Reminder" section.
**When to use:** Set in `.onAppear` after modal analysis. Never auto-applies.

```swift
// Source: [ASSUMED] — SwiftUI conditional state pattern
// In SettingsView.body, inside Section("Daily Reminder"):
if showNudgeSuggestion, let suggestedHour = computedSuggestedHour {
    NudgeSuggestionBannerRow(
        suggestedHour: suggestedHour,
        onApply: { applyNudgeSuggestion(hour: suggestedHour, minute: 0) },
        onDismiss: { dismissNudgeSuggestion() }
    )
}
DatePicker(...)
```

Extracting the banner as a private `@ViewBuilder` or small subview keeps SettingsView's body readable and makes the banner independently testable.

### Anti-Patterns to Avoid

- **Calling `StreakEngine.currentStreak` in the View layer** — streak computation belongs in the scheduler or ViewModel, not in a View's body or `.onAppear`. SettingsView already uses `@Query private var allEvents: [CompletionEvent]` + `var globalStreak: Int { StreakEngine.currentStreak(from: allEvents) }` — follow this existing pattern for passing the streak into `reschedule()`.
- **Writing `nudgeSuggestionDismissed` to `UserDefaults.standard` only** — must write to the App Group suite to match the pattern for all other `NotificationPreferences` keys.
- **Repeating `repeats: true` for the 7 PM one-shot** — the Phase 23 nudge used `repeats: true`; Phase 25 must use `repeats: false`. A subtle copy-paste mistake will create a permanent daily 7 PM alert that never self-cancels.
- **Scheduling the one-shot outside the `schedule()` method** — D-07 is explicit: both notifications are scheduled in one call. Don't split them across separate entry points.
- **Setting `showNudgeSuggestion` in a `.task {}` instead of `.onAppear {}`** — D-10 specifies `.onAppear`, not every foreground. The `.task` modifier re-runs on task cancellation (navigation push/pop), while `.onAppear` runs only on actual view appearance.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Day-of-year rotation within copy bank | Custom date math | `Calendar.current.ordinality(of: .day, in: .year, for: Date())` | Already used in the existing `makeContent(activeGoals:)` — proven pattern |
| 64-slot notification cap guard | Global notification counter | Existing `pending.count < 60` guard in `scheduleGlobalStreakAtRiskNudge(pendingCount:)` | Pattern already tested in Phase23NotificationTests; inject `pendingCount` for testability |
| One-shot immediate-then-cancel pattern | BGAppRefreshTask | `UNCalendarNotificationTrigger(repeats: false)` + `removePendingNotificationRequests` | STATE.md explicitly decided schedule-and-cancel over BGAppRefreshTask |
| App-wide UserDefaults key management | Scattered string literals | `NotificationPreferences` enum | Already the project pattern; all new keys go here |
| Streak computation | Duplicate streak logic | `StreakEngine.currentStreak(from:frozenDates:)` | Static method already used by WidgetDataProvider; pass nil tier for global streak |
| Modal time display string | Custom time formatter | `Calendar.current.date(from: DateComponents(hour: h, minute: 0))` + `DateFormatter` with `.short` time style | Standard Foundation approach — no custom formatting |

---

## Common Pitfalls

### Pitfall 1: Signature Cascade — All `schedule()`/`reschedule()` Callers Must Be Updated

**What goes wrong:** The new `schedule(hour:minute:activeGoals:completionEvents:)` signature is added, but existing callers (`VitaminGApp.swift`, `SettingsView`, `GoalViewModel.rescheduleNotification`) still call the old `schedule(hour:minute:activeGoals:)`. Swift won't error if both overloads exist — the old overload silently stays and new features never activate.
**Why it happens:** Adding a new overload is invisible to existing callers.
**How to avoid:** Remove the old `schedule(hour:minute:activeGoals:)` signature entirely after adding the new one. This forces a compiler error at all call sites, making every caller explicit.
**Warning signs:** Old `inspirationalMessages` array still appears in notification bodies during testing.

### Pitfall 2: `rescheduleNotification(context:)` Only Fetches Goals — Not CompletionEvents

**What goes wrong:** `GoalViewModel.rescheduleNotification(context:)` currently fetches only `[Goal]`. The new `schedule()` needs `[CompletionEvent]` too. If only `activeGoals` is fetched, the scheduler always receives an empty events array, streak is always 0, and tone is always "encouraging".
**Why it happens:** `rescheduleNotification` was written before streak-awareness was a requirement.
**How to avoid:** Add a second `FetchDescriptor<CompletionEvent>()` fetch in `rescheduleNotification(context:)` alongside the existing goal fetch. Pass both to `schedule()`.
**Warning signs:** All notifications show encouraging copy regardless of actual streak.

### Pitfall 3: `repeats: false` One-Shot Fires the Next Day When Called After 7 PM

**What goes wrong:** If `schedule()` is called at 8 PM (e.g., on app launch after a late check-in), the 7 PM one-shot is scheduled for the next day at 19:00 — technically correct per D-07, but the user may receive a "streak at risk" alert the morning after they already checked in.
**Why it happens:** `UNCalendarNotificationTrigger` with `repeats: false` always fires at the NEXT matching time, which can be up to 24 hours away.
**How to avoid:** Per Claude's Discretion (D-07 note), decide at implementation time whether to skip the one-shot if current time is past 19:00. Recommended: skip it — if the user is launching the app at 8 PM, they have clearly used the app and a streak-at-risk alert the next morning before they've had a chance to check in is noise.
**Warning signs:** Users reporting "at-risk" notifications firing when they have already checked in.

### Pitfall 4: Suggestion Banner Appearing Every Time SettingsView Appears (After Dismiss)

**What goes wrong:** `nudgeSuggestionDismissed` is checked in `.onAppear` but the dismissed state was written to `UserDefaults.standard` instead of the App Group suite — or the key was defined inconsistently.
**Why it happens:** Two different suite references (standard vs. App Group) yield different values for the same key.
**How to avoid:** All `NotificationPreferences` keys (including `nudgeSuggestionDismissedKey`) are defined in the `NotificationPreferences` enum. Read and write through the App Group suite exclusively — same pattern as `checkInHourHistoryKey`.
**Warning signs:** Banner reappears on Settings re-entry even after the user tapped Apply or X.

### Pitfall 5: Existing NotificationSchedulerTests Fail After makeContent Signature Change

**What goes wrong:** `NotificationSchedulerTests.swift` tests call `scheduler.makeContent(activeGoals:)` without `currentStreak:`. Removing the old signature breaks compilation of the test file.
**Why it happens:** Tests must be updated alongside production code.
**How to avoid:** Update all `makeContent(activeGoals:)` call sites in the test file to `makeContent(activeGoals:currentStreak:)` as part of the same task that changes the production signature. Also update `test_makeContent_allCompletedGoals_fallbackMessage` and related tests to use `currentStreak: 0` so they still exercise the "encouraging" branch correctly.
**Warning signs:** Build errors in the test target immediately after the signature change task.

### Pitfall 6: `checkInHourHistory` Written to Both `standard` and App Group — Reading from Wrong Suite

**What goes wrong:** `appendCheckInHour` writes to the App Group suite (correct, per D-08). But `SettingsView.onAppear` reads from `UserDefaults.standard` — finds an empty array — and never shows the banner.
**Why it happens:** Mixed UserDefaults suite reads are a common source of silent nil/empty results in iOS apps with App Group extensions.
**How to avoid:** Implement `modalCheckInHour()` as a static helper on `NotificationPreferences` that reads from the App Group suite explicitly. SettingsView calls this helper rather than reading `UserDefaults.standard` directly.
**Warning signs:** Banner never appears despite 14+ check-ins.

---

## Code Examples

### Existing: One-Shot Pattern (from scheduleMilestoneNotification)

```swift
// Source: [VERIFIED: codebase] NotificationScheduler.swift line 347
let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
```

The 7 PM one-shot uses `UNCalendarNotificationTrigger` instead of `UNTimeIntervalNotificationTrigger`, but the `repeats: false` principle is identical.

### Existing: Cap Guard Pattern

```swift
// Source: [VERIFIED: codebase] NotificationScheduler.swift line 280-287
let pending = await center.pendingNotificationRequests()
guard pending.count < 60 else {
    #if DEBUG
    print("[NotificationScheduler] Skipping streakAtRisk — approaching 64-cap (\(pending.count) pending)")
    #endif
    return
}
```

Apply this same guard before adding the 7 PM one-shot inside `schedule()`.

### Existing: App Group UserDefaults Write

```swift
// Source: [VERIFIED: codebase] NotificationPreferences.swift line 36-39
let shared = UserDefaults(suiteName: suiteName)
shared?.set(hour, forKey: hourKey)
shared?.set(minute, forKey: minuteKey)
```

Mirror exactly for `appendCheckInHour(_:)` and writing `nudgeSuggestionDismissed`.

### Existing: StreakEngine.currentStreak Call Pattern

```swift
// Source: [VERIFIED: codebase] SettingsView.swift line 32-34
@Query private var allEvents: [CompletionEvent]

private var globalStreak: Int {
    StreakEngine.currentStreak(from: allEvents)
}
```

`GoalViewModel.rescheduleNotification(context:)` needs a fetch-based equivalent since it doesn't use `@Query`.

### Existing: Task-Wrapped Async Call in addCheckIn

```swift
// Source: [VERIFIED: codebase] GoalViewModel.swift line 219
Task { await NotificationScheduler.shared.cancelGlobalStreakAtRiskNudge() }
```

The new `appendCheckInHour` call is synchronous (UserDefaults write) — no Task wrapper needed. It happens on the preceding line.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (existing, no new setup needed) |
| Config file | Xcode scheme — no separate config file |
| Quick run command | `xcodebuild test -scheme VitaminG -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests` |
| Full suite command | `xcodebuild test -scheme VitaminG -destination "platform=iOS Simulator,name=iPhone 16"` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NOTIF-01 | streak >= 7 selects celebratory bank | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_makeContent_celebratoryCopy_whenStreakGe7` | No — Wave 0 |
| NOTIF-01 | streak 1-6 selects neutral-building bank | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_makeContent_neutralBuildingCopy_whenStreak1To6` | No — Wave 0 |
| NOTIF-01 | streak 0 selects encouraging bank | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_makeContent_encouragingCopy_whenStreak0` | No — Wave 0 |
| NOTIF-02 | body contains up to 2 goal titles newline-separated | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_makeContent_twoGoalTitles` | No — Wave 0 |
| NOTIF-02 | single active goal produces single-title body | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_makeContent_singleGoal` | No — Wave 0 |
| NOTIF-03 | appendCheckInHour maintains max 14 entries FIFO | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_appendCheckInHour_fifo14` | No — Wave 0 |
| NOTIF-03 | modalHour returns correct mode | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_modalHour_returnsMode` | No — Wave 0 |
| NOTIF-03 | modalHour tie-breaks by earliest occurrence | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_modalHour_tieBreakByFirstOccurrence` | No — Wave 0 |
| NOTIF-04 | one-shot uses repeats: false | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_schedule_oneShotStreakAtRisk_repeats_false` | No — Wave 0 |
| NOTIF-04 | cap guard blocks one-shot at 60 pending | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerPhase25Tests/test_schedule_oneShotSkipped_atCapBoundary` | No — Wave 0 |
| Regression | existing makeContent tests pass with new signature | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerTests` | Yes — update signature only |

### Wave 0 Gaps

- [ ] `VitaminGTests/NotificationSchedulerPhase25Tests.swift` — all new tests listed above (covers NOTIF-01 through NOTIF-04)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes — goal titles injected into notification body | Existing `filter { !$0.isCompleted }` + `compactMap { $0.title }` + `filter { !$0.isEmpty }` chain; titles already validated at creation by `GoalViewModel.maxTitleLength = 100` |
| V6 Cryptography | no | — |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Oversized goal title in notification body | Tampering | Title length already capped at 100 chars by GoalViewModel validation; notification body has no separate limit |
| checkInHourHistory corrupted with out-of-range values | Tampering | Read-time clamp: `filter { $0 >= 0 && $0 <= 23 }` before modal computation |
| nudgeSuggestionDismissed key set to unexpected type in UserDefaults | Tampering | Read as `UserDefaults.bool(forKey:)` which safely returns false for absent/invalid values |

---

## Open Questions

1. **Should `schedule()` skip the 7 PM one-shot entirely when called after 19:00?**
   - What we know: Per D-07, the current natural behavior is the one-shot fires the following day. Per Claude's Discretion, this is an open decision.
   - What's unclear: Whether firing a "streak at risk" alert the next morning before any check-in has happened is confusing user experience.
   - Recommendation: Skip the one-shot when `Calendar.current.component(.hour, from: Date()) >= 19`. This is a 2-line guard and avoids the cross-day false alarm.

2. **Does `rescheduleNotification(context:)` need to also pass `frozenDates` to `StreakEngine.currentStreak`?**
   - What we know: `StreakFreezeService.frozenDates` is used in `addCheckIn()` for per-goal streak computation. The global streak in `SettingsView` uses `StreakEngine.currentStreak(from: allEvents)` without frozen dates.
   - What's unclear: Whether streak freeze dates should influence tone selection (i.e., should a freeze-day count as a streak day for tone purposes?).
   - Recommendation: Include `frozenDates: freezeService.frozenDates` for consistency with the existing `addCheckIn()` pattern. Defer to planner if this adds unwanted complexity.

---

## Environment Availability

Step 2.6: SKIPPED — Phase 25 is code/config changes only within the existing iOS app target. No new external tools, services, runtimes, or CLI utilities are required.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `SettingsView.onAppear` runs exactly once per view appearance (not on task cancellation cycles) | Architecture Patterns | Banner might appear/disappear unexpectedly; mitigated by `nudgeSuggestionDismissed` permanent gate |
| A2 | Exact copy text for all three tone banks is at Claude's discretion (D-01) | Standard Stack / Code Examples | Low — user accepted this as Claude's Discretion during discuss-phase |
| A3 | Mode tie-breaking by earliest occurrence is the right UX choice | Code Examples (Pattern 4) | Low — user accepted this as Claude's Discretion during discuss-phase |

---

## Sources

### Primary (HIGH confidence)
- [VERIFIED: codebase] `NotificationScheduler.swift` — all existing methods, identifiers, and patterns
- [VERIFIED: codebase] `NotificationPreferences.swift` — App Group suite name, existing key pattern
- [VERIFIED: codebase] `GoalViewModel.swift` — `addCheckIn()`, `rescheduleNotification()` implementation
- [VERIFIED: codebase] `SettingsView.swift` — `.onAppear` structure, `@State`, `@Query` usage
- [VERIFIED: codebase] `StreakEngine.swift` — `currentStreak(from:tier:frozenDates:calendar:)` signature
- [VERIFIED: codebase] `Phase23NotificationTests.swift` — testable overload pattern (`pendingCount: Int?`)
- [VERIFIED: codebase] `NotificationSchedulerTests.swift` — existing test structure to follow
- [CITED: 25-CONTEXT.md] — All D-01 through D-13 locked implementation decisions
- [CITED: Apple Developer Documentation] `UNCalendarNotificationTrigger` — `repeats: false` fires at next matching time

### Secondary (MEDIUM confidence)
- [ASSUMED] Exact copy text for tone banks — not externally sourced; provided by researcher as Claude's Discretion

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; all frameworks are first-party and already in use
- Architecture: HIGH — implementation decisions are locked in CONTEXT.md; codebase read directly
- Pitfalls: HIGH — all pitfalls derived from direct codebase inspection + known iOS notification API behavior
- Validation: HIGH — existing test structure is well-established; new test file follows exact same pattern

**Research date:** 2026-05-29
**Valid until:** 2026-06-28 (stable Apple APIs; 30-day horizon)
