# Phase 25: Smart Notifications Enhancement - Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 5 (4 modified + 1 new)
**Analogs found:** 5 / 5

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` | service | request-response + event-driven | `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` (self — extension pattern) | exact |
| `VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift` | service / config | CRUD (UserDefaults) | `VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift` (self — extend existing keys) | exact |
| `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` | viewmodel | CRUD + event-driven | `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` (self — addCheckIn / rescheduleNotification) | exact |
| `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift` | view | request-response | `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift` (self — onAppear + @State banner pattern) | exact |
| `VitaminG/VitaminG/VitaminGTests/NotificationSchedulerPhase25Tests.swift` | test | — | `VitaminG/VitaminG/VitaminGTests/Phase23NotificationTests.swift` + `NotificationSchedulerTests.swift` | exact |

---

## Pattern Assignments

### `NotificationScheduler.swift` — MODIFY (makeContent, schedule, reschedule, one-shot)

**Analog:** Self — existing Phase 23 extension block starting at line 453.

**Imports pattern** (lines 1–3):
```swift
import UserNotifications
import Foundation
```
No new imports required. `StreakEngine` and `CompletionEvent` are already in the same module.

**Existing `inspirationalMessages` array to replace** (lines 25–33):
```swift
internal static let inspirationalMessages: [String] = [
    "You got this! 💪",
    "Take your daily Vitamin G 💊",
    // ... 7 entries total
]
```
Replace with three named static arrays: `celebratoryCopy`, `neutralBuildingCopy`, `encouragingCopy`. Keep the `internal` access so existing tests can reference them by name (same as `inspirationalMessages` is referenced in `NotificationSchedulerTests` at line 57 and 117).

**Existing `makeContent` signature to update** (lines 38–61):
```swift
func makeContent(activeGoals: [Goal]) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.title = "Good morning"

    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    let message = Self.inspirationalMessages[(dayOfYear - 1) % Self.inspirationalMessages.count]

    let topGoalTitle = activeGoals
        .filter { !$0.isCompleted }
        .compactMap { $0.title }
        .filter { !$0.isEmpty }
        .first

    if let topGoalTitle {
        content.body = "\(message)\n\(topGoalTitle)"
    } else {
        content.body = message
    }

    content.sound = .default
    content.userInfo = ["deepLink": "goalList"]
    return content
}
```
New signature: `makeContent(activeGoals: [Goal], currentStreak: Int) -> UNMutableNotificationContent`.
- Add a private `copyBank(for streak: Int) -> [String]` helper above `makeContent`.
- Change the single `topGoalTitle` extraction to pick up to 2 active, non-empty titles.
- Preserve day-of-year rotation: `bank[(dayOfYear - 1) % bank.count]`.
- Preserve `content.sound = .default` and `content.userInfo = ["deepLink": "goalList"]`.

**Existing `schedule` signature to update** (lines 68–95):
```swift
func schedule(hour: Int, minute: Int, activeGoals: [Goal]) async {
    let center = UNUserNotificationCenter.current()
    // Remove-before-add pattern
    center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])

    let validHour = max(0, min(23, hour))
    let validMinute = max(0, min(59, minute))
    // ...
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    let request = UNNotificationRequest(
        identifier: Self.identifier,
        content: makeContent(activeGoals: activeGoals),
        trigger: trigger
    )
    do {
        try await center.add(request)
    } catch {
        #if DEBUG
        print("[NotificationScheduler] Failed to add daily reminder request: \(error)")
        #endif
    }
}
```
New signature: `schedule(hour: Int, minute: Int, activeGoals: [Goal], completionEvents: [CompletionEvent]) async`.
- Call `StreakEngine.currentStreak(from: completionEvents)` before `makeContent`.
- After `center.add(request)` succeeds, call a new private `scheduleOneShotStreakAtRisk(activeGoals:streak:center:)` method.
- Remove the old no-`completionEvents` overload entirely to force compiler errors at all stale call sites.

**Cap guard pattern for one-shot** (lines 280–287 of existing Phase 14 extension):
```swift
let pending = await center.pendingNotificationRequests()
guard pending.count < 60 else {
    #if DEBUG
    print("[NotificationScheduler] Skipping streakAtRisk — approaching 64-cap (\(pending.count) pending)")
    #endif
    return
}
```
Apply this same guard inside the new `scheduleOneShotStreakAtRisk` method before adding the 7 PM one-shot. Use the testable-overload pattern from `scheduleGlobalStreakAtRiskNudge(pendingCount:)` (lines 472–508): accept `pendingCount: Int? = nil` so tests can inject a count.

**One-shot trigger pattern** (lines 493–500 of existing Phase 23 extension, to be replaced):
```swift
// OLD: repeats: true — Phase 23 pattern to be replaced
var components = DateComponents()
components.hour = 19
components.minute = 0
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
let request = UNNotificationRequest(
    identifier: Self.globalStreakAtRiskIdentifier,
    content: content,
    trigger: trigger
)
```
New Phase 25 version — same identifier, same DateComponents, but `repeats: false`:
```swift
let trigger = UNCalendarNotificationTrigger(
    dateMatching: DateComponents(hour: 19, minute: 0),
    repeats: false   // D-05: one-shot, not repeating
)
```
The `removeBeforeAdd` call on `globalStreakAtRiskIdentifier` stays — ensures at most one pending instance.

**Existing `reschedule` signature to update** (lines 99–105):
```swift
func reschedule(activeGoals: [Goal]) async {
    await schedule(
        hour: NotificationPreferences.hour,
        minute: NotificationPreferences.minute,
        activeGoals: activeGoals
    )
}
```
New signature: `reschedule(activeGoals: [Goal], completionEvents: [CompletionEvent]) async` — forwards both arrays to `schedule()`.

**Error handling pattern** (lines 87–94, repeated across all `center.add` calls):
```swift
do {
    try await center.add(request)
} catch {
    #if DEBUG
    print("[NotificationScheduler] Failed to add <notification type>: \(error)")
    #endif
}
```
Apply identical pattern to the new one-shot `center.add` call. Errors are best-effort/silent in production.

---

### `NotificationPreferences.swift` — MODIFY (add checkInHourHistory + nudgeSuggestionDismissed keys)

**Analog:** Self — existing `winHourKey`/`winMinuteKey` block (lines 55–103) and `save(hour:minute:)` (lines 33–40).

**Existing App Group write pattern** (lines 33–40):
```swift
static func save(hour: Int, minute: Int) {
    UserDefaults.standard.set(hour, forKey: hourKey)
    UserDefaults.standard.set(minute, forKey: minuteKey)

    let shared = UserDefaults(suiteName: suiteName)
    shared?.set(hour, forKey: hourKey)
    shared?.set(minute, forKey: minuteKey)
}
```
New `appendCheckInHour(_:)` static method mirrors this pattern but writes **only to the App Group suite** (D-08 — widgets and Watch may read it). Standard `UserDefaults.standard` is NOT written for this key.

**Existing App Group read pattern** (lines 43–51):
```swift
static func sharedHour() -> Int {
    let shared = UserDefaults(suiteName: suiteName)
    return shared?.object(forKey: hourKey) as? Int ?? defaultHour
}
```
New `checkInHourHistory() -> [Int]` and `modalCheckInHour() -> Int?` static helpers follow this App Group read pattern. `SettingsView.onAppear` calls these helpers — never reads `UserDefaults.standard` directly for this key (see Pitfall 6 in RESEARCH.md).

**Existing key naming pattern** (lines 10–11, 56–57):
```swift
static let hourKey   = "notificationHour"
static let minuteKey = "notificationMinute"
// ...
static let winHourKey   = "winNotificationHour"
static let winMinuteKey = "winNotificationMinute"
```
New keys follow same `static let` naming style:
```swift
static let checkInHourHistoryKey     = "checkInHourHistory"
static let nudgeSuggestionDismissedKey = "nudgeSuggestionDismissed"
```

**New `appendCheckInHour` implementation pattern** (mirrors RESEARCH.md Pattern 3, confirmed against lines 33–40):
```swift
static func appendCheckInHour(_ hour: Int) {
    let shared = UserDefaults(suiteName: suiteName)
    var history = (shared?.array(forKey: checkInHourHistoryKey) as? [Int]) ?? []
    history.append(hour)
    if history.count > 14 { history.removeFirst(history.count - 14) }
    shared?.set(history, forKey: checkInHourHistoryKey)
}
```

**New `nudgeSuggestionDismissed` write/read pattern** (mirrors bool flag pattern, read with `.bool(forKey:)` which safely returns false for absent/invalid values):
```swift
static var nudgeSuggestionDismissed: Bool {
    UserDefaults(suiteName: suiteName)?.bool(forKey: nudgeSuggestionDismissedKey) ?? false
}

static func markNudgeSuggestionDismissed() {
    UserDefaults(suiteName: suiteName)?.set(true, forKey: nudgeSuggestionDismissedKey)
}
```

---

### `GoalViewModel.swift` — MODIFY (addCheckIn + rescheduleNotification)

**Analog:** Self — `addCheckIn` starting at line 169 and `rescheduleNotification` at line 369.

**Existing `addCheckIn` Task wrapping pattern** (line 219):
```swift
// MILE-02: Cancel the global 7 PM streak-at-risk nudge after a successful check-in.
// Fire-and-forget — cancellation is best-effort (T-23-04-04 mitigation).
Task { await NotificationScheduler.shared.cancelGlobalStreakAtRiskNudge() }
```
New check-in hour append (D-09) is **synchronous** — no Task wrapper needed. Insert it on the line immediately before this existing Task:
```swift
// NOTIF-03: Record check-in hour for nudge suggestion analysis (D-09).
// Synchronous UserDefaults write — no Task wrapper needed.
NotificationPreferences.appendCheckInHour(Calendar.current.component(.hour, from: Date()))
Task { await NotificationScheduler.shared.cancelGlobalStreakAtRiskNudge() }
```

**Existing `rescheduleNotification` pattern** (lines 369–376):
```swift
func rescheduleNotification(context: ModelContext) {
    let descriptor = FetchDescriptor<Goal>(predicate: #Predicate { !$0.isCompleted })
    let activeGoals = (try? context.fetch(descriptor)) ?? []
    Task {
        await NotificationScheduler.shared.reschedule(activeGoals: activeGoals)
    }
}
```
Extend with a second fetch for `CompletionEvent` (Pitfall 2 in RESEARCH.md — if omitted, streak is always 0):
```swift
func rescheduleNotification(context: ModelContext) {
    let descriptor = FetchDescriptor<Goal>(predicate: #Predicate { !$0.isCompleted })
    let activeGoals = (try? context.fetch(descriptor)) ?? []
    let eventsDescriptor = FetchDescriptor<CompletionEvent>()
    let completionEvents = (try? context.fetch(eventsDescriptor)) ?? []
    Task {
        await NotificationScheduler.shared.reschedule(
            activeGoals: activeGoals,
            completionEvents: completionEvents
        )
    }
}
```

**Existing `Task { await ... }` pattern** for async calls in the synchronous `addCheckIn` method (lines 219, 232, 247, 277):
All async notification and CloudKit calls in `addCheckIn` use fire-and-forget `Task { await ... }`. The new `cancelGlobalStreakAtRiskNudge` call already uses this pattern. No deviation needed.

---

### `SettingsView.swift` — MODIFY (onAppear modal analysis + conditional banner row)

**Analog:** Self — `@State` declarations (lines 38–53), `.onAppear` block (lines 208–217), `Section("Daily Reminder")` (lines 105–125), `@ViewBuilder private var authorizationRow` (lines 227–262).

**Existing `@State` declaration pattern** (lines 38–53):
```swift
@State private var notificationTime: Date = { ... }()
@State private var winNotificationTime: Date = { ... }()
@State private var authStatus: UNAuthorizationStatus = .notDetermined
@State private var profileVM = ProfileViewModel()
```
Add alongside these:
```swift
@State private var showNudgeSuggestion: Bool = false
@State private var suggestedNudgeHour: Int? = nil
```

**Existing `.onAppear` pattern** (lines 208–217):
```swift
.onAppear {
    let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
    NotificationPreferences.save(
        hour: components.hour ?? NotificationPreferences.defaultHour,
        minute: components.minute ?? NotificationPreferences.defaultMinute
    )
    profileVM.loadOrCreateProfile(context: modelContext)
}
```
Append modal analysis to this same `.onAppear` block (D-10 specifies `.onAppear`, not `.task`):
```swift
.onAppear {
    // ... existing lines ...

    // NOTIF-03: Compute nudge suggestion (D-10).
    // Only once (dismissed flag is permanent); only after 14+ check-in entries.
    guard !NotificationPreferences.nudgeSuggestionDismissed else { return }
    if let modal = NotificationPreferences.modalCheckInHour() {
        let diff = abs(modal - NotificationPreferences.hour)
        if diff >= 2 {
            suggestedNudgeHour = modal
            showNudgeSuggestion = true
        }
    }
}
```

**Existing conditional row pattern in `Section("Daily Reminder")`** (lines 105–125):
```swift
Section("Daily Reminder") {
    DatePicker(
        "Reminder Time",
        selection: $notificationTime,
        displayedComponents: .hourAndMinute
    )
    .disabled(!isAuthorized)
    .onChange(of: notificationTime) { ... }

    authorizationRow
}
```
Insert the banner row **above** the `DatePicker` (D-11):
```swift
Section("Daily Reminder") {
    if showNudgeSuggestion, let hour = suggestedNudgeHour {
        nudgeSuggestionBanner(suggestedHour: hour)
    }
    DatePicker(...)
    // ... rest unchanged
}
```

**Existing `@ViewBuilder` helper pattern** (lines 227–262, `authorizationRow`):
```swift
@ViewBuilder
private var authorizationRow: some View {
    switch authStatus {
    case .notDetermined:
        Button("Enable Notifications") { ... }
    case .denied:
        HStack { ... }
    default:
        HStack { ... }
    }
}
```
Extract the nudge suggestion banner into a private `@ViewBuilder` function following the same style:
```swift
@ViewBuilder
private func nudgeSuggestionBanner(suggestedHour: Int) -> some View {
    // HStack with label + Apply button + X/xmark button
    // Apply: calls NotificationPreferences.save(hour:minute:) + Task { await reschedule() }
    //        then: NotificationPreferences.markNudgeSuggestionDismissed(); showNudgeSuggestion = false
    // X:     NotificationPreferences.markNudgeSuggestionDismissed(); showNudgeSuggestion = false
}
```

**Existing reschedule call pattern in SettingsView** (lines 119–121):
```swift
Task {
    await NotificationScheduler.shared.reschedule(activeGoals: Array(activeGoals))
}
```
The banner's Apply action must call the updated `reschedule(activeGoals:completionEvents:)` signature. `SettingsView` already has `@Query private var allEvents: [CompletionEvent]` (line 30) — pass `Array(allEvents)` as `completionEvents`.

**Existing `globalStreak` computed property pattern** (lines 32–34):
```swift
@Query private var allEvents: [CompletionEvent]

private var globalStreak: Int {
    StreakEngine.currentStreak(from: allEvents)
}
```
The banner's Apply action follows the same pattern: `allEvents` is already in scope for the `reschedule` call — no new `@Query` needed.

---

### `NotificationSchedulerPhase25Tests.swift` — NEW

**Analog:** `Phase23NotificationTests.swift` (cap guard + identifier stability tests) and `NotificationSchedulerTests.swift` (makeContent unit tests with in-memory ModelContainer).

**Imports and class structure** (from Phase23NotificationTests.swift lines 1–7 and NotificationSchedulerPhase14Tests.swift lines 1–8):
```swift
import XCTest
import UserNotifications
import SwiftData
@testable import VitaminG

@MainActor
final class NotificationSchedulerPhase25Tests: XCTestCase {
    private var container: ModelContainer!
    private let scheduler = NotificationScheduler.shared

    override func setUp() async throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    override func tearDown() async throws {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        container = nil
    }
}
```

**makeContent unit test pattern** (from NotificationSchedulerTests.swift lines 24–37):
```swift
func test_makeContent_celebratoryCopy_whenStreakGe7() throws {
    let context = ModelContext(container)
    let g1 = Goal(title: "Goal A", tier: .immediate)
    context.insert(g1)

    let content = scheduler.makeContent(activeGoals: [g1], currentStreak: 7)
    XCTAssertTrue(
        NotificationScheduler.celebratoryCopy.contains { content.body.hasPrefix($0) },
        "streak >= 7 should select from celebratoryCopy bank"
    )
}
```
Repeat for `neutralBuildingCopy` (streak 3) and `encouragingCopy` (streak 0).

**Cap guard test pattern** (from Phase23NotificationTests.swift lines 27–44):
```swift
func test_schedule_oneShotSkipped_atCapBoundary() async {
    // inject pendingCount = 60 via testable overload
    await scheduler.scheduleOneShotStreakAtRisk(activeGoals: [], streak: 5, pendingCount: 60)

    let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
    let nudgeAdded = pending.contains {
        $0.identifier == NotificationScheduler.globalStreakAtRiskIdentifier
    }
    XCTAssertFalse(nudgeAdded, "Cap guard should prevent one-shot when pendingCount >= 60")
}
```

**One-shot `repeats: false` verification pattern** (from NotificationSchedulerPhase14Tests.swift lines 35–51):
```swift
func test_schedule_oneShotStreakAtRisk_repeats_false() async throws {
    // schedule with pendingCount = 0 to bypass cap guard
    await scheduler.scheduleOneShotStreakAtRisk(activeGoals: [], streak: 3, pendingCount: 0)

    let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
    let request = pending.first {
        $0.identifier == NotificationScheduler.globalStreakAtRiskIdentifier
    }
    try XCTSkipIf(request == nil, "Notification permission not granted — skip trigger assertion")
    guard let trigger = request?.trigger as? UNCalendarNotificationTrigger else {
        return XCTFail("Expected UNCalendarNotificationTrigger")
    }
    XCTAssertFalse(trigger.repeats, "One-shot 7 PM alert must have repeats: false")
    XCTAssertEqual(trigger.dateComponents.hour, 19)
    XCTAssertEqual(trigger.dateComponents.minute, 0)
}
```

**Pure function tests** (from NotificationSchedulerTests.swift line 104 — `allCompletedGoals_fallbackMessage` pattern):
```swift
// Tests for NOTIF-03 helpers (no ModelContainer needed — pure [Int] arithmetic)
func test_appendCheckInHour_fifo14() {
    // write 15 entries; verify only the last 14 are stored
}

func test_modalHour_returnsMode() {
    // [8, 8, 9, 8, 9] -> modal = 8
}

func test_modalHour_tieBreakByFirstOccurrence() {
    // [9, 8, 9, 8] -> modal = 9 (9 appears at index 0 before 8 at index 1)
}
```
These tests call `NotificationPreferences` static methods directly — no scheduler needed.

---

## Shared Patterns

### Remove-Before-Add (all scheduling methods)
**Source:** `NotificationScheduler.swift` lines 70–71 (daily), 157 (win), 210–211 (challenge), 289 (streak-at-risk), 334 (milestone).
**Apply to:** All `center.add` calls in Phase 25 — both the morning notification and the one-shot 7 PM alert.
```swift
center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
// ... build content and trigger ...
try await center.add(request)
```

### Hour/Minute Input Clamping
**Source:** `NotificationScheduler.swift` lines 73–75.
**Apply to:** The existing `schedule()` method already applies clamping for hour/minute inputs. No new clamping is needed for the 7 PM one-shot (DateComponents are hardcoded, not user-supplied).
```swift
let validHour = max(0, min(23, hour))
let validMinute = max(0, min(59, minute))
```

### App Group UserDefaults Write Pattern
**Source:** `NotificationPreferences.swift` lines 37–39 (`save`), lines 80–84 (`saveWinTime`).
**Apply to:** All new `NotificationPreferences` helpers — `appendCheckInHour`, `markNudgeSuggestionDismissed`, `checkInHourHistory()`, `modalCheckInHour()`.
```swift
let shared = UserDefaults(suiteName: suiteName)
shared?.set(value, forKey: key)
```
**Never** write `checkInHourHistory` or `nudgeSuggestionDismissed` to `UserDefaults.standard` — App Group suite only (Pitfall 4 and 6 in RESEARCH.md).

### Fire-and-Forget Task Pattern
**Source:** `GoalViewModel.swift` line 219 (`cancelGlobalStreakAtRiskNudge`) and lines 232, 247, 277.
**Apply to:** `rescheduleNotification(context:)` and the banner Apply action in `SettingsView`. All async notification calls in `@MainActor` synchronous contexts use `Task { await ... }`.
```swift
Task { await NotificationScheduler.shared.reschedule(activeGoals: ..., completionEvents: ...) }
```

### DEBUG Print Error Pattern
**Source:** `NotificationScheduler.swift` lines 91–93 (repeated in every `center.add` catch block).
**Apply to:** New `center.add` call for the one-shot 7 PM alert.
```swift
} catch {
    #if DEBUG
    print("[NotificationScheduler] Failed to add <description>: \(error)")
    #endif
}
```

### Testable Overload for Cap Guard
**Source:** `NotificationScheduler.swift` lines 472–508 (`scheduleGlobalStreakAtRiskNudge(pendingCount:)`).
**Apply to:** The new one-shot scheduling helper. Accept `pendingCount: Int? = nil` — nil fetches from `UNUserNotificationCenter`, a non-nil value is used as-is for tests.
```swift
func scheduleOneShotStreakAtRisk(activeGoals: [Goal], streak: Int, pendingCount: Int? = nil) async {
    let center = UNUserNotificationCenter.current()
    let count: Int
    if let injected = pendingCount {
        count = injected
    } else {
        count = await center.pendingNotificationRequests().count
    }
    guard count < 60 else { ... return }
    // ... schedule one-shot
}
```

### XCTest Setup/Teardown with Notification Cleanup
**Source:** `Phase23NotificationTests.swift` lines 9–18, `NotificationSchedulerPhase14Tests.swift` lines 12–18.
**Apply to:** `NotificationSchedulerPhase25Tests` setUp/tearDown.
```swift
override func setUp() async throws {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
}
override func tearDown() async throws {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
}
```

### XCTSkipIf for Simulator Permission
**Source:** `NotificationSchedulerPhase14Tests.swift` lines 44–45, 66.
**Apply to:** Any Phase 25 test that inspects pending notification requests after scheduling.
```swift
try XCTSkipIf(request == nil,
    "Notification permission not granted in test environment — skip trigger assertion")
```

---

## No Analog Found

All five files have strong exact-match analogs within the existing codebase. No RESEARCH.md-only patterns are required.

---

## Cascade Call Sites (Planner Must Track)

The `schedule()`/`reschedule()` signature change cascades to call sites beyond the four primary files. These must be updated in the same plan that changes the signatures:

| Call Site | File | Current Call | Required Update |
|---|---|---|---|
| `rescheduleNotification(context:)` | `GoalViewModel.swift` line 374 | `reschedule(activeGoals:)` | `reschedule(activeGoals:completionEvents:)` |
| Time picker onChange | `SettingsView.swift` line 120 | `reschedule(activeGoals:)` | `reschedule(activeGoals:completionEvents:)` (pass `Array(allEvents)`) |
| Authorization row grant path | `SettingsView.swift` line 235 | `reschedule(activeGoals:)` | `reschedule(activeGoals:completionEvents:)` |
| App launch | `VitaminGApp.swift` (search for `reschedule`) | `reschedule(activeGoals: [])` | `reschedule(activeGoals: [], completionEvents: [])` |
| Existing `NotificationSchedulerTests` | `NotificationSchedulerTests.swift` lines 33, 45, 52, etc. | `makeContent(activeGoals:)` | `makeContent(activeGoals:currentStreak:)` — pass `currentStreak: 0` for all existing tests |

---

## Metadata

**Analog search scope:** `VitaminG/VitaminG/VitaminG/Services/`, `VitaminG/VitaminG/VitaminG/ViewModels/`, `VitaminG/VitaminG/VitaminG/Views/`, `VitaminG/VitaminG/VitaminGTests/`
**Files scanned:** 7 source files read in full
**Pattern extraction date:** 2026-05-29
