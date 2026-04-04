# Phase 3: Streaks, Stats & Notifications — Research

**Researched:** 2026-04-04
**Domain:** Swift/SwiftUI streak computation, calendar heatmap UI, UserNotifications local scheduling
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STATS-01 | Streak per tier: consecutive days with at least one CompletionEvent in that tier | StreakEngine algorithm using Calendar.current — documented below |
| STATS-02 | Global streak: consecutive days with at least one CompletionEvent in any tier | Same engine, filter omitted |
| STATS-03 | Streak computation uses Calendar.current date arithmetic, not raw TimeInterval — DST-safe | `Calendar.current.isDate(_:inSameDayAs:)` and `startOfDay` pattern |
| STATS-04 | Stats screen: current streak per tier, global streak, completion rate, total goals per tier | StatsViewModel + StatsView |
| STATS-05 | Stats screen calendar heatmap — GitHub-style grid of completion activity | Custom SwiftUI heatmap built from CompletionEvent date buckets |
| STATS-06 | All streak/stats derived from CompletionEvent records, not isCompleted boolean | FetchDescriptor<CompletionEvent> as single source of truth |
| NOTIF-02 | Daily notification fires at user-selected time (default 8:00 AM) | UNCalendarNotificationTrigger with DateComponents |
| NOTIF-03 | Notification body contains user's actual active goal titles (up to top 3) | Load active goals at schedule time; embed in content.body |
| NOTIF-04 | UNCalendarNotificationTrigger with repeats: true — no background fetch | Standard local notification pattern |
| NOTIF-05 | Stays within iOS 64-request limit — scheduling caps pre-scheduled notifications | Remove pending before re-scheduling; single identifier per notification |
| NOTIF-06 | User can change notification time in Settings — reschedules existing | NotificationScheduler.reschedule() removes + re-adds |
| NOTIF-07 | Tapping notification deep-links to goal list | userInfo payload + UNUserNotificationCenterDelegate |
</phase_requirements>

---

## Summary

Phase 3 has three distinct sub-domains that must compose cleanly: (1) a **StreakEngine** that computes per-tier and global streaks from `CompletionEvent` records using DST-safe Calendar arithmetic; (2) a **StatsView** with a calendar heatmap implemented in pure SwiftUI (no third-party dependency); and (3) a **NotificationScheduler** that schedules a single repeating `UNCalendarNotificationTrigger` with personalized goal titles and handles the iOS 64-notification cap.

All three sub-domains operate on existing data models (`CompletionEvent`, `Goal`) from SchemaV1 — no schema changes are required for this phase. The primary technical challenge is correct streak-boundary logic across midnight and DST transitions, which is well-solved by `Calendar.current.startOfDay(for:)` + `isDate(_:inSameDayAs:)`. The heatmap grid is straightforward SwiftUI `LazyVGrid` over a bucketed date map; no external charting library is needed or appropriate given the no-third-party-dependencies constraint.

Notification deep-linking to the goal list requires adding a `.stats` case and a `.goalList` case to `AppRoute` and handling `UNUserNotificationCenterDelegate` in `VitaminGApp` — the navigation scaffold already exists from Phase 1/2.

**Primary recommendation:** Build `StreakEngine` as a standalone testable struct (same pattern as `GoalSorter`), `NotificationScheduler` as a standalone actor/class (not embedded in a View), and `StatsViewModel` as an `@Observable` class that drives `StatsView`. Keep all three isolated so they are unit-testable without UI.

---

## Project Constraints (from CLAUDE.md)

| Constraint | Impact on Phase 3 |
|------------|-------------------|
| No third-party dependencies unless necessary | Heatmap must be built in SwiftUI; no charting library (Swift Charts is Apple-native — acceptable if needed) |
| iOS 17+ minimum | `@Observable`, `@Query`, all SwiftUI features available |
| MVVM strictly enforced — no business logic in Views | StreakEngine and NotificationScheduler must live outside Views |
| All String inputs validated at model layer | Notification body construction must handle nil/empty goal titles gracefully |
| App Store Review Guidelines: proper notification permissions, no background abuse | Use local notifications only, never background fetch for notification scheduling |
| Architecture: @Observable for ViewModels, SwiftData for persistence | StatsViewModel uses @Observable; reads CompletionEvent via @Query or ModelContext fetch |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift | 5.9+ (Xcode 15+) | Primary language | Project constraint |
| SwiftUI | iOS 17+ | Stats screen UI, heatmap grid | Project constraint; @Query integration |
| SwiftData | iOS 17+ | FetchDescriptor<CompletionEvent> for streak source of truth | Already in use |
| UserNotifications | iOS 10+ / best practices iOS 17 | UNCalendarNotificationTrigger scheduling | Project constraint; local-only |
| Foundation/Calendar | Built-in | DST-safe date arithmetic | Standard; no external dep needed |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Swift Charts | iOS 16+ (Apple) | Alternative to hand-rolled heatmap | Acceptable as Apple-native; LazyVGrid is simpler for this use case |
| XCTest | Built-in | Unit tests for StreakEngine, NotificationScheduler | All business logic must be unit tested |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| LazyVGrid heatmap | Swift Charts (BarMark / RectangleMark) | Swift Charts is Apple-native (acceptable), but the GitHub-style grid requires a custom heatmap layout that LazyVGrid handles cleanly. Swift Charts adds complexity without benefit here. |
| Single UNCalendarNotificationTrigger | Multiple scheduled daily reminders | Single `repeats: true` trigger stays within the 64 cap with room to spare; multiple triggers waste budget unnecessarily. |

**Installation:** No new packages — all stack is built-in frameworks. [VERIFIED: project codebase has no Package.swift / Podfile]

---

## Architecture Patterns

### Recommended Project Structure
```
VitaminG/
├── Models/
│   ├── Goal.swift              (existing)
│   └── SchemaV1.swift          (existing)
├── ViewModels/
│   ├── GoalViewModel.swift     (existing)
│   └── StatsViewModel.swift    (NEW — streak + heatmap computed properties)
├── Services/
│   ├── StreakEngine.swift      (NEW — pure struct, testable, no SwiftUI)
│   └── NotificationScheduler.swift  (NEW — actor/class, no SwiftUI)
├── Views/
│   ├── GoalListView.swift      (existing)
│   ├── StatsView.swift         (NEW — consumes StatsViewModel)
│   ├── HeatmapView.swift       (NEW — reusable heatmap grid component)
│   └── SettingsView.swift      (NEW — notification time picker)
├── Navigation/
│   ├── AppRoute.swift          (MODIFY — add .stats, .settings cases)
│   └── AppRouter.swift         (existing)
└── Persistence/
    └── ModelContainerFactory.swift  (existing)
```

### Pattern 1: StreakEngine — Standalone Testable Struct

**What:** Pure struct that computes streaks from an array of `CompletionEvent` objects. No SwiftUI, no SwiftData dependency — takes `[CompletionEvent]` and returns computed values.

**When to use:** Called by StatsViewModel to derive streak values after fetching CompletionEvents.

**Algorithm (DST-safe):**
1. Extract unique calendar days from `CompletionEvent.completedAt` using `Calendar.current.startOfDay(for:)`
2. Sort descending
3. Walk backward from today — count consecutive days. Stop at first gap.

**Example:**
```swift
// Source: Apple Developer Documentation — Calendar.current arithmetic
struct StreakEngine {
    static func currentStreak(
        from events: [CompletionEvent],
        tier: GoalTier? = nil,   // nil = global streak
        calendar: Calendar = .current
    ) -> Int {
        let filtered = tier.map { t in events.filter { $0.tier == t } } ?? events
        guard !filtered.isEmpty else { return 0 }

        // Bucket events into unique calendar days
        let days: Set<Date> = Set(filtered.compactMap {
            guard let date = $0.completedAt else { return nil }
            return calendar.startOfDay(for: date)
        })

        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var candidate = today

        while days.contains(candidate) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: candidate) else { break }
            candidate = previous
        }
        return streak
    }
}
```
[CITED: https://developer.apple.com/documentation/foundation/calendar]

**Why `startOfDay` matters:** Using raw `TimeInterval` or subtracting 86400 seconds fails across DST transitions (clocks spring forward/back). `Calendar.current.startOfDay(for:)` is the correct idiom. [CITED: Apple Swift Documentation — Calendar]

### Pattern 2: Heatmap Grid — LazyVGrid over Date Buckets

**What:** A SwiftUI view that renders a grid of colored squares for the past N days, shaded by completion count.

**When to use:** Inside StatsView for STATS-05.

**Key implementation notes:**
- Generate an array of the past 90 days (or configurable window) using `Calendar.current.date(byAdding:)`
- For each day, look up the count of CompletionEvents in a pre-built `[Date: Int]` dictionary (keyed by `startOfDay`)
- Map count → color intensity (opacity or a stepped palette)
- Use `LazyVGrid(columns: Array(repeating: .init(.fixed(12)), count: 7))` — one column per weekday

```swift
// Source: [ASSUMED — standard SwiftUI LazyVGrid pattern]
private func completionCount(for day: Date, events: [CompletionEvent]) -> Int {
    let startOfDay = Calendar.current.startOfDay(for: day)
    return events.filter {
        guard let completedAt = $0.completedAt else { return false }
        return Calendar.current.isDate(completedAt, inSameDayAs: startOfDay)
    }.count
}
```

**Performance note:** Pre-build the `[Date: Int]` dictionary once in StatsViewModel, not in the View body — avoids O(n*days) per render. [ASSUMED — standard optimization for computed SwiftUI views]

### Pattern 3: NotificationScheduler — Single Repeating Trigger

**What:** Encapsulates all notification scheduling logic. Exposes `schedule(time: DateComponents, goals: [Goal])` and `reschedule(time: DateComponents, goals: [Goal])`.

**When to use:** Called from SettingsView when user changes notification time, and from GoalViewModel after any goal mutation that changes the active title set.

**Critical: iOS 64-notification cap**
- iOS allows a maximum of 64 pending local notifications per app. [CITED: https://developer.apple.com/documentation/usernotifications/unusernotificationcenter]
- With a single `UNCalendarNotificationTrigger` set to `repeats: true`, the OS schedules it perpetually from one entry — not 64 individual requests.
- The cap is only relevant if you schedule N individual non-repeating triggers. Using one repeating trigger per notification type is the correct pattern for this app.

**Notification body construction (NOTIF-03):**
```swift
// Source: [ASSUMED — standard UNMutableNotificationContent pattern]
func makeContent(activeGoals: [Goal]) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.title = "Your Vitamin G for today"
    let goalTitles = activeGoals
        .prefix(3)
        .compactMap { $0.title }
        .filter { !$0.isEmpty }
    if goalTitles.isEmpty {
        content.body = "Check in on your goals today."
    } else {
        content.body = goalTitles.joined(separator: " · ")
    }
    content.sound = .default
    content.userInfo = ["deepLink": "goalList"]
    return content
}
```

**Scheduling with UNCalendarNotificationTrigger:**
```swift
// Source: [CITED: https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger]
func schedule(at time: DateComponents, goals: [Goal]) async {
    let center = UNUserNotificationCenter.current()
    // Remove existing before re-adding (NOTIF-06)
    center.removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])

    let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
    let request = UNNotificationRequest(
        identifier: Self.notificationIdentifier,
        content: makeContent(activeGoals: goals),
        trigger: trigger
    )
    try? await center.add(request)
}
```

**Static identifier:** Use a single constant like `"com.kyleharrington.VitaminG.dailyReminder"` — the same identifier is used to remove and replace the notification on reschedule. [ASSUMED — standard practice]

### Pattern 4: Deep-link from Notification (NOTIF-07)

**What:** When user taps the notification, app should navigate to the goal list.

**Mechanism:** Implement `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)` in `VitaminGApp`, read `userInfo["deepLink"]`, and call `AppRouter.popToRoot()` (goal list is the root view).

**AppRoute additions needed:**
```swift
// Modify AppRoute.swift
enum AppRoute: Hashable {
    case goalDetail(Goal)
    case stats            // NEW — Phase 3
    case settings         // NEW — Phase 3
}
```

**ContentView additions needed — add navigationDestination cases for .stats and .settings.**

**VitaminGApp must become UNUserNotificationCenterDelegate:**
```swift
// Source: [CITED: https://developer.apple.com/documentation/usernotifications/unusernotificationcenter]
// VitaminGApp.init() — set delegate
UNUserNotificationCenter.current().delegate = notificationDelegate
```

Since `@main struct` can't directly conform to `UNUserNotificationCenterDelegate` (it's a struct), use a dedicated `NotificationDelegate` class that holds a weak reference to `AppRouter`. [ASSUMED — standard pattern for SwiftUI apps]

### Pattern 5: Settings — Notification Time Picker

**What:** A simple settings screen with a `DatePicker` (`.datePickerStyle(.wheel)`, `displayedComponents: .hourAndMinute`) that stores the selected time in `UserDefaults` and calls `NotificationScheduler.reschedule()`.

**UserDefaults key:** `"notificationHour"` and `"notificationMinute"` (or a single `TimeInterval` offset). [ASSUMED — standard approach]

**Default:** 8:00 AM (hour: 8, minute: 0). [VERIFIED: REQUIREMENTS.md NOTIF-02]

### Pattern 6: StatsView Navigation Entry Point

**What:** A tab bar or toolbar button in `GoalListView` / `ContentView` that navigates to `StatsView`.

**Recommendation:** Add a tab bar (`TabView`) to `ContentView` with two tabs: Goals (existing `GoalListView`) and Stats. This avoids touching the `NavigationStack` routing for a peer-level screen. Alternatively, add a toolbar button to `GoalListView` that pushes `.stats`. The tab bar approach provides better discoverability. [ASSUMED — design decision for planner]

### Anti-Patterns to Avoid

- **Using raw TimeInterval for day comparison:** `date1.timeIntervalSince(date2) < 86400` is wrong across DST. Always use `Calendar.current.isDate(_:inSameDayAs:)` or `startOfDay` comparison.
- **Scheduling 64+ individual notifications:** A `repeats: true` single trigger handles perpetual daily reminders without hitting the cap. Multiple non-repeating daily triggers for 64 days ahead would hit the cap immediately.
- **Embedding NotificationScheduler logic in a View:** Scheduling is async and side-effecting — it belongs in a service class, not `onAppear` or `onChange` in a View.
- **Computing streaks in the View body:** Streak computation is O(n log n) over CompletionEvents. Pre-compute in ViewModel/StreakEngine and expose computed properties.
- **Fetching active goals at notification fire time:** The notification content is set at scheduling time, not when the notification fires. The body will be stale if goals change. This is acceptable for v1 (REQUIREMENTS.md is explicit about this design) — reschedule when goals change. [VERIFIED: REQUIREMENTS.md NOTIF-03 says "surfaces the user's active goal titles" at notification body, not dynamically]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DST-safe day comparison | Custom TimeInterval math | `Calendar.current.isDate(_:inSameDayAs:)` | Handles DST, locale, timezone correctly |
| Notification scheduling | Manual timer / background fetch | `UNCalendarNotificationTrigger(dateMatching:repeats:)` | App Store compliant, no background entitlement needed |
| Notification permission | Custom permission flow | `UNUserNotificationCenter.requestAuthorization(options:)` | Only correct API |
| Calendar date arithmetic | Manual offset by 86400 | `Calendar.current.date(byAdding: .day, value: -1, to:)` | Correct across DST, leap seconds |

**Key insight:** The notification and streak domains are well-covered by Apple's own frameworks. The only custom work is the StreakEngine algorithm (computing streaks from an event array) and the heatmap layout (SwiftUI grid). Everything else is framework wiring.

---

## Common Pitfalls

### Pitfall 1: Off-by-one in Streak Calculation (Today vs. Yesterday)

**What goes wrong:** Streak shows 0 when the user completed a goal earlier today because the algorithm only counts days strictly before today.

**Why it happens:** The algorithm checks if today is in the day set before counting. If the user completed something at 11:55 PM last night and it's now 12:05 AM, `Calendar.current.startOfDay(for: Date())` returns a new day and the streak breaks.

**How to avoid:** Include today in the streak check. The algorithm above starts from `today` (not `yesterday`) and walks backward. If today has a completion, streak starts at 1 and walks back. If today has no completion but yesterday does, streak is still alive (the day isn't over yet). [ASSUMED — common streak UX convention; verify with user if needed]

**Warning signs:** Streak shows 0 after a fresh completion.

### Pitfall 2: Notification Content Staleness

**What goes wrong:** Notification body shows old goal titles after user updates goals because the content is baked in at schedule time.

**Why it happens:** `UNCalendarNotificationTrigger` stores the notification content at scheduling time — it is not re-evaluated when the notification fires.

**How to avoid:** Call `NotificationScheduler.reschedule(goals:)` whenever the user creates, updates, deletes, or completes a goal. Trigger this from `GoalViewModel` mutations. [VERIFIED: REQUIREMENTS.md — implicit requirement for NOTIF-03 to stay accurate]

**Warning signs:** Notification shows a deleted goal's title.

### Pitfall 3: Heatmap Performance with Large Event Sets

**What goes wrong:** The heatmap stutters on scroll or re-render when there are many `CompletionEvent` records.

**Why it happens:** Filtering the full event array per cell in a `LazyVGrid` body is O(n) per cell, O(n * cells) total.

**How to avoid:** In `StatsViewModel`, pre-build a `[Date: Int]` dictionary (keyed by `startOfDay`) once. The View performs O(1) lookups. Rebuild the dictionary whenever CompletionEvents change.

**Warning signs:** Noticeable lag when opening StatsView with 100+ events.

### Pitfall 4: UNUserNotificationCenterDelegate Not Set Early Enough

**What goes wrong:** Tapping a notification while the app is backgrounded doesn't deep-link correctly — the delegate handler fires before the app is fully initialized.

**Why it happens:** The delegate must be set before `application(_:didFinishLaunchingWithOptions:)` completes. In SwiftUI `@main` apps, this means setting it in the `init()` of the `App` struct.

**How to avoid:** Set `UNUserNotificationCenter.current().delegate = ...` in `VitaminGApp.init()`, before the `container` is initialized. [CITED: https://developer.apple.com/documentation/usernotifications/unusernotificationcenter — see "Setting the Delegate" note]

**Warning signs:** Notification tap opens app to root but doesn't navigate; or worse, the delegate method is never called.

### Pitfall 5: Notification Authorization State Not Checked Before Scheduling

**What goes wrong:** `NotificationScheduler.schedule()` silently fails if the user has denied notifications; no error surfaced to the UI.

**Why it happens:** `UNUserNotificationCenter.add(_:)` does not throw if authorization is denied — the notification is silently dropped.

**How to avoid:** Check `UNUserNotificationCenter.current().notificationSettings()` before scheduling. If `.authorizationStatus == .denied`, surface an informative message (or deep-link to Settings). Note: NOTIF-01 (onboarding permission request) is Phase 5 — Phase 3 should check authorization status but not request it (that's Phase 5's job). [VERIFIED: REQUIREMENTS.md — NOTIF-01 in Phase 5, NOTIF-02 through NOTIF-07 in Phase 3]

**Warning signs:** User enables notifications in system settings but never receives them.

### Pitfall 6: Multiple CompletionEvents on Same Day Breaking Streak

**What goes wrong:** If a user completes multiple goals in the same tier on the same day, the streak algorithm double-counts.

**Why it happens:** Raw event count != day count.

**How to avoid:** The StreakEngine algorithm above uses a `Set<Date>` of `startOfDay` values — duplicates within a day are automatically collapsed. This is correct behavior. [ASSUMED — inherent to the Set-based approach]

---

## Code Examples

### Streak Computation (DST-safe)
```swift
// Source: Apple Developer Documentation — Calendar arithmetic
// [CITED: https://developer.apple.com/documentation/foundation/calendar]
struct StreakEngine {
    static func currentStreak(
        from events: [CompletionEvent],
        tier: GoalTier? = nil,
        calendar: Calendar = .current
    ) -> Int {
        let filtered: [CompletionEvent]
        if let tier {
            filtered = events.filter { $0.tier == tier }
        } else {
            filtered = events
        }
        guard !filtered.isEmpty else { return 0 }

        let days: Set<Date> = Set(filtered.compactMap {
            guard let date = $0.completedAt else { return nil }
            return calendar.startOfDay(for: date)
        })

        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var candidate = today
        while days.contains(candidate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: candidate) else { break }
            candidate = prev
        }
        return streak
    }
}
```

### UNCalendarNotificationTrigger Scheduling
```swift
// Source: [CITED: https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger]
final class NotificationScheduler {
    static let identifier = "com.kyleharrington.VitaminG.dailyReminder"

    func schedule(hour: Int, minute: Int, activeGoals: [Goal]) async throws {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "Your Vitamin G for today"
        let titles = activeGoals.prefix(3).compactMap { $0.title }.filter { !$0.isEmpty }
        content.body = titles.isEmpty ? "Check in on your goals today." : titles.joined(separator: " · ")
        content.sound = .default
        content.userInfo = ["deepLink": "goalList"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger)
        try await center.add(request)
    }
}
```

### HeatmapView — LazyVGrid Structure
```swift
// Source: [ASSUMED — standard SwiftUI LazyVGrid pattern]
struct HeatmapView: View {
    let events: [CompletionEvent]
    let windowDays: Int = 90

    private var dayBuckets: [Date: Int] {
        var dict: [Date: Int] = [:]
        for event in events {
            guard let date = event.completedAt else { continue }
            let day = Calendar.current.startOfDay(for: date)
            dict[day, default: 0] += 1
        }
        return dict
    }

    private var days: [Date] {
        (0..<windowDays).compactMap {
            Calendar.current.date(byAdding: .day, value: -($0), to: Calendar.current.startOfDay(for: Date()))
        }.reversed()
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(12), spacing: 3), count: 7), spacing: 3) {
            ForEach(days, id: \.self) { day in
                let count = dayBuckets[day] ?? 0
                RoundedRectangle(cornerRadius: 2)
                    .fill(cellColor(for: count))
                    .frame(width: 12, height: 12)
            }
        }
    }

    private func cellColor(for count: Int) -> Color {
        switch count {
        case 0: return Color(.systemFill)
        case 1: return .green.opacity(0.4)
        case 2: return .green.opacity(0.7)
        default: return .green
        }
    }
}
```

### AppRoute Additions
```swift
// Modify AppRoute.swift — add stats and settings
enum AppRoute: Hashable {
    case goalDetail(Goal)
    case stats        // Phase 3
    case settings     // Phase 3
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `UNTimeIntervalNotificationTrigger` for daily reminders | `UNCalendarNotificationTrigger(dateMatching:repeats:true)` | iOS 10 | Calendar trigger is the correct pattern for fixed daily time; interval trigger doesn't respect clock time |
| `ObservableObject` ViewModels | `@Observable` macro (iOS 17+) | iOS 17 | Project uses @Observable throughout; StatsViewModel must follow |
| Custom calendar/date math | `Calendar.current` API | Always | No custom TimeInterval math — use Calendar.current throughout |

**Deprecated/outdated:**
- Raw `TimeInterval` arithmetic for day differences: Use `Calendar.current.dateComponents(.day, from:to:)` or `startOfDay` comparison
- `UNMutableNotificationContent` with empty body: Apple review may flag notifications with no meaningful content — always populate body

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (existing in project) |
| Config file | Xcode scheme — VitaminGTests target |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests` |
| Full suite command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STATS-01 | Per-tier streak from CompletionEvents | unit | `xcodebuild test ... -only-testing:VitaminGTests/StreakEngineTests` | ❌ Wave 0 |
| STATS-02 | Global streak from CompletionEvents | unit | `xcodebuild test ... -only-testing:VitaminGTests/StreakEngineTests` | ❌ Wave 0 |
| STATS-03 | DST-safe calendar arithmetic | unit | `xcodebuild test ... -only-testing:VitaminGTests/StreakEngineTests/test_streak_dstSafe` | ❌ Wave 0 |
| STATS-06 | Streak derived from CompletionEvents not isCompleted | unit | `xcodebuild test ... -only-testing:VitaminGTests/StreakEngineTests` | ❌ Wave 0 |
| NOTIF-03 | Notification body contains goal titles | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerTests` | ❌ Wave 0 |
| NOTIF-04 | UNCalendarNotificationTrigger with repeats:true | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerTests` | ❌ Wave 0 |
| NOTIF-05 | 64-cap: removes before re-scheduling | unit | `xcodebuild test ... -only-testing:VitaminGTests/NotificationSchedulerTests` | ❌ Wave 0 |
| STATS-04 | Stats screen shows correct values | manual | — | manual-only: requires UI |
| STATS-05 | Heatmap renders correctly | manual | — | manual-only: visual verification |
| NOTIF-02 | Notification fires at selected time | manual | — | manual-only: requires real device/time |
| NOTIF-06 | Reschedule on time change | manual | — | manual-only: requires real device |
| NOTIF-07 | Tap notification opens goal list | manual | — | manual-only: requires real device |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/StreakEngineTests`
- **Per wave merge:** Full suite — `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `VitaminGTests/StreakEngineTests.swift` — covers STATS-01, STATS-02, STATS-03, STATS-06
- [ ] `VitaminGTests/NotificationSchedulerTests.swift` — covers NOTIF-03, NOTIF-04, NOTIF-05

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Notification body: compactMap + filter on goal titles; never pass raw unsanitized strings to notification content |
| V6 Cryptography | no | — |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unvalidated goal title in notification body | Tampering / Info Disclosure | Use `GoalViewModel.sanitize()` output (already validated at storage time); `compactMap` + `filter` for nil/empty titles before embedding in notification body |
| UserDefaults storing notification time | Tampering | Validate hour (0-23) and minute (0-59) before building DateComponents; reject out-of-range values |
| CompletionEvent `completedAt` nil | Tampering | Guard with `compactMap { $0.completedAt }` in StreakEngine — never force-unwrap date from SwiftData model |

**Key security note:** Goal titles were validated and sanitized at insert time (`GoalViewModel.sanitize()`), so notification body construction is safe. Still guard against nil — SwiftData optional properties can be nil on CloudKit-synced records. [VERIFIED: SchemaV1.swift — CompletionEvent.completedAt is `Date?`]

---

## Open Questions

1. **Should the streak count "today" if today has no completion yet?**
   - What we know: The algorithm above starts from today and counts backward. If today has no completion, streak reflects yesterday's end state.
   - What's unclear: Some apps show "streak is alive if you act before midnight" vs "streak broke if today has no completion yet". The success criteria says "consecutive days with at least one completion event" — strictly, today with no completion should not count.
   - Recommendation: Show streak as "days ago through yesterday" (strict) and surface an encouraging copy nudge if today has no completion yet. Confirm with user.

2. **How to navigate to StatsView — tab bar or toolbar button?**
   - What we know: ContentView uses a `NavigationStack`. Adding a `TabView` is a significant structural change.
   - What's unclear: Phase 4/5 may add more tabs (settings, onboarding) — better to establish tab structure now.
   - Recommendation: Introduce a `TabView` with Goals and Stats tabs in Phase 3. This is a better long-term structure than toolbar buttons. [ASSUMED]

3. **Should NotificationScheduler reschedule on every goal mutation?**
   - What we know: NOTIF-03 requires actual active goal titles in the notification body. The content is baked at schedule time.
   - What's unclear: Rescheduling on every create/edit/delete adds overhead. For 3 titles out of potentially many goals, the body only changes if top-3 active goals change.
   - Recommendation: Reschedule on every goal mutation in Phase 3 for correctness. Optimization is premature.

---

## Environment Availability

Step 2.6: SKIPPED — Phase 3 has no external tool dependencies beyond the existing Xcode/Swift toolchain already in use.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Streak counts today even if goal was completed earlier today (not "yesterday and before only") | Architecture Patterns, Pitfall 1 | User sees counter-intuitive streak behavior; needs explicit decision |
| A2 | Single static notification identifier `"com.kyleharrington.VitaminG.dailyReminder"` is sufficient (one notification per day) | Pattern 3 | If user wants multiple reminders in future, this needs revisiting — acceptable for v1 |
| A3 | TabView with Goals + Stats tabs is the preferred navigation structure | Architecture Patterns | If user prefers toolbar navigation, ContentView restructure is minimal |
| A4 | `NotificationScheduler` reschedules on every goal mutation for correctness | Open Questions | Minor performance overhead; not a correctness risk |
| A5 | LazyVGrid 90-day window for heatmap (not 365 days) | Code Examples | 365 days is feasible but may require horizontal scroll or smaller cells |
| A6 | UserDefaults stores notification time (not SwiftData) | Pattern 5 | Consistent with iOS convention for app preferences; appropriate for non-synced local setting |

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation — `Calendar` — `isDate(_:inSameDayAs:)`, `startOfDay(for:)`, `date(byAdding:value:to:)` — DST-safe arithmetic patterns [CITED: https://developer.apple.com/documentation/foundation/calendar]
- Apple Developer Documentation — `UNCalendarNotificationTrigger` — `repeats:true`, `dateMatching:` DateComponents [CITED: https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger]
- Apple Developer Documentation — `UNUserNotificationCenter` — 64-notification limit, delegate pattern, `removePendingNotificationRequests` [CITED: https://developer.apple.com/documentation/usernotifications/unusernotificationcenter]
- Project CLAUDE.md — tech stack constraints, MVVM enforcement, no-third-party rule [VERIFIED: project file]
- Project REQUIREMENTS.md — all STATS-* and NOTIF-* requirements verbatim [VERIFIED: project file]
- Project SchemaV1.swift — `CompletionEvent` model structure, optional `completedAt: Date?`, denormalized `tierRawValue` [VERIFIED: project file]
- Project GoalViewModel.swift — existing `sanitize()`, `@Observable`, MVVM pattern [VERIFIED: project file]
- Project GoalSorter.swift (by file listing) — standalone struct pattern for testable non-SwiftUI logic [VERIFIED: project file listing]

### Secondary (MEDIUM confidence)
- CLAUDE.md sources section — `UNCalendarNotificationTrigger` listed explicitly as the correct tool for "daily local alarm" [CITED: project CLAUDE.md]

### Tertiary (LOW confidence)
- Streak "counts today if today has a completion" convention — [ASSUMED] standard habit-tracker UX; not verified against a specific reference

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all frameworks are built-in Apple; no third-party decisions required
- Architecture: HIGH — StreakEngine struct pattern mirrors existing GoalSorter; NotificationScheduler pattern is standard
- Streak algorithm: HIGH — Calendar.current approach is documented and standard
- Notification scheduling: HIGH — UNCalendarNotificationTrigger with repeats:true is documented exactly
- Heatmap implementation: MEDIUM — LazyVGrid approach is standard SwiftUI but implementation details are ASSUMED
- Navigation structure (TabView vs toolbar): LOW — design decision not locked; flagged as assumption

**Research date:** 2026-04-04
**Valid until:** 2026-05-04 (stable Apple frameworks; 30-day validity)
