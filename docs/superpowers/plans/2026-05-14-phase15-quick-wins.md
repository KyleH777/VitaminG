# Phase 15: Quick Wins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix dark mode token consistency, add haptic feedback on goal completion, build a weighted Consistency Score card on the Stats screen, add a one-per-month Streak Freeze safety valve, and switch widgets to push-only refresh.

**Architecture:** All changes are local — no new frameworks, no network calls, no new SwiftData models. `ConsistencyEngine` and `StreakFreezeService` follow the existing `StreakEngine` pattern (pure structs / UserDefaults, zero SwiftUI dependency, injectable for testing). UI additions slot into existing `StatsView` below the global streak card.

**Tech Stack:** SwiftUI, SwiftData, WidgetKit, XCTest, UserDefaults (App Group suite)

---

## File Map

| Action | File | Change |
|--------|------|--------|
| Modify | `VitaminG/Views/StatsView.swift` | Replace hardcoded gradient colors; add ConsistencyScoreCard + Freeze button |
| Modify | `VitaminG/Views/SettingsView.swift` | Replace hardcoded gradient colors |
| Modify | `VitaminG/Views/DailyWinsView.swift` | Replace hardcoded gradient colors |
| Modify | `VitaminG/Views/Sheets/NotificationPermissionSheet.swift` | Replace hardcoded gradient colors |
| Modify | `VitaminG/Views/Onboarding/TiersScreen.swift` | Replace hardcoded gradient colors |
| Modify | `VitaminG/Views/PublicProfileView.swift` | Replace hardcoded terra color |
| Modify | `VitaminG/Views/GoalListView.swift` | Replace one `Color.white.opacity(0.1)` spark bar; add `.sensoryFeedback` |
| Modify | `VitaminG/Views/GoalDetailView.swift` | Add `.sensoryFeedback` on completion button |
| Modify | `VitaminG/Views/ChallengeCheckInView.swift` | Add `.sensoryFeedback` on save |
| Create | `VitaminG/Services/ConsistencyEngine.swift` | Pure struct, exponential-decay score |
| Modify | `VitaminG/ViewModels/StatsViewModel.swift` | Add `consistencyScore` + `recentDaysActivity` |
| Create | `VitaminG/Views/Components/ConsistencyScoreCard.swift` | Stats card view |
| Create | `VitaminG/Services/StreakFreezeService.swift` | UserDefaults-backed monthly freeze |
| Modify | `VitaminG/Services/StreakEngine.swift` | Add `frozenDates` parameter |
| Modify | `VitaminGWidget/GoalSummaryWidget.swift` | Change timeline policy to `.never`; fix hardcoded flame color |
| Modify | `VitaminGWidget/StreakWidget.swift` | Change timeline policy to `.never` |
| Create | `VitaminGTests/ConsistencyEngineTests.swift` | Unit tests |
| Create | `VitaminGTests/StreakFreezeTests.swift` | Unit tests |
| Modify | `VitaminGTests/StreakEngineTests.swift` | Add frozen-dates tests |

---

### Task 1: Dark Mode Token Replacement

**Files:**
- Modify: `VitaminG/Views/StatsView.swift`
- Modify: `VitaminG/Views/SettingsView.swift`
- Modify: `VitaminG/Views/DailyWinsView.swift`
- Modify: `VitaminG/Views/Sheets/NotificationPermissionSheet.swift`
- Modify: `VitaminG/Views/Onboarding/TiersScreen.swift`
- Modify: `VitaminG/Views/PublicProfileView.swift`
- Modify: `VitaminG/Views/GoalListView.swift`
- Modify: `VitaminGWidget/GoalSummaryWidget.swift`

- [ ] **Step 1: Replace hardcoded colors in StatsView**

In `StatsView.swift`, find the `globalStreakCard` gradient and replace both hardcoded colors:

```swift
// Before
colors: [
    Color(red: 0.98, green: 0.55, blue: 0.27),
    Color(red: 0.78, green: 0.48, blue: 0.95)
],

// After
colors: [
    VGTheme.accentTerra,
    VGTheme.accentPurple
],
```

- [ ] **Step 2: Replace hardcoded colors in SettingsView**

In `SettingsView.swift`, find the gradient using `Color(red: 0.98, green: 0.55, blue: 0.27)` and `Color(red: 0.78, green: 0.48, blue: 0.95)` and apply the same substitution:

```swift
colors: [VGTheme.accentTerra, VGTheme.accentPurple],
```

- [ ] **Step 3: Replace hardcoded colors in DailyWinsView**

In `DailyWinsView.swift` at lines 103–104, same substitution:

```swift
colors: [VGTheme.accentTerra, VGTheme.accentPurple],
```

- [ ] **Step 4: Replace hardcoded colors in NotificationPermissionSheet**

In `NotificationPermissionSheet.swift` at lines 17–18:

```swift
colors: [VGTheme.accentTerra, VGTheme.accentPurple],
```

- [ ] **Step 5: Replace hardcoded colors in TiersScreen**

In `TiersScreen.swift` at lines 24–25:

```swift
colors: [VGTheme.accentTerra, VGTheme.accentPurple],
```

- [ ] **Step 6: Replace hardcoded colors in PublicProfileView**

In `PublicProfileView.swift`:
- Line 23: `.foregroundStyle(Color(red: 0.98, green: 0.55, blue: 0.27))` → `.foregroundStyle(VGTheme.accentTerra)`
- Line 40: `.tint(Color(red: 0.98, green: 0.55, blue: 0.27))` → `.tint(VGTheme.accentTerra)`

- [ ] **Step 7: Replace spark bar color in GoalListView**

In `GoalListView.swift` at line 229:

```swift
// Before
.fill(i < 5 ? VGTheme.terraSoft.opacity(0.7) : Color.white.opacity(0.1))

// After
.fill(i < 5 ? VGTheme.terraSoft.opacity(0.7) : VGTheme.separator)
```

- [ ] **Step 8: Fix flame icon color in GoalSummaryWidget**

In `GoalSummaryWidget.swift`, find the footer flame icon:

```swift
// Before
.foregroundStyle(Color(red: 0.98, green: 0.55, blue: 0.27))

// After
.foregroundStyle(VGTheme.accentTerra)
```

Note: `VGTheme` is defined in the main app target. Import it or inline the adaptive color in the widget target. If VGTheme is not accessible in the widget extension, replace with:
```swift
.foregroundStyle(Color(uiColor: UIColor { t in
    t.userInterfaceStyle == .dark
        ? UIColor(red: 1.0, green: 0.541, blue: 0.361, alpha: 1)
        : UIColor(red: 0.769, green: 0.404, blue: 0.227, alpha: 1)
}))
```

- [ ] **Step 9: Build and verify**

Open Xcode, build the main target (`Cmd+B`). Resolve any compile errors. Switch simulator to Dark Mode (Settings → Developer → Dark Appearance) and visually confirm the five views render correctly without white or light-only elements in gradient cards.

- [ ] **Step 10: Commit**

```bash
git add -p
git commit -m "fix: replace hardcoded colors with VGTheme adaptive tokens for dark mode"
```

---

### Task 2: Haptic Feedback on Completion

**Files:**
- Modify: `VitaminG/Views/GoalDetailView.swift`
- Modify: `VitaminG/Views/ChallengeCheckInView.swift`

- [ ] **Step 1: Add sensoryFeedback to GoalDetailView**

In `GoalDetailView.swift`, find `actionsSection`. Add `.sensoryFeedback` to the outer `VStack` in that section. The modifier fires only when `goal.completed` transitions to `true`:

```swift
private var actionsSection: some View {
    VStack(spacing: 12) {
        // ... existing button code unchanged ...
    }
    .sensoryFeedback(.success, trigger: goal.completed) { _, new in new }
}
```

The `{ _, new in new }` condition means the haptic fires only on completion, not on reactivation.

- [ ] **Step 2: Add sensoryFeedback to ChallengeCheckInView**

In `ChallengeCheckInView.swift`, add a `@State private var checkInSaved = false` property. In the `saveButton` helper's action closure, set `checkInSaved = true` after the save. Then attach to the body or the save button container:

```swift
// At the top of ChallengeCheckInView:
@State private var checkInSaved = false

// In saveButton action, after the existing save call:
checkInSaved = true

// On the body's outermost view:
.sensoryFeedback(.success, trigger: checkInSaved)
```

- [ ] **Step 3: Build and manual test**

Build (`Cmd+B`). On a physical device (haptics don't fire in Simulator), complete a goal and confirm you feel a success tap. Check-in a challenge and confirm a success tap.

- [ ] **Step 4: Commit**

```bash
git add VitaminG/Views/GoalDetailView.swift VitaminG/Views/ChallengeCheckInView.swift
git commit -m "feat: add haptic feedback on goal completion and challenge check-in"
```

---

### Task 3: ConsistencyEngine — TDD

**Files:**
- Create: `VitaminG/Services/ConsistencyEngine.swift`
- Create: `VitaminGTests/ConsistencyEngineTests.swift`

- [ ] **Step 1: Write failing tests**

Create `VitaminGTests/ConsistencyEngineTests.swift`:

```swift
import XCTest
@testable import VitaminG

final class ConsistencyEngineTests: XCTestCase {

    // Helper: build fake CompletionEvent dates relative to a fixed reference
    private func events(daysAgo offsets: [Int], reference: Date = .now) -> [CompletionEvent] {
        let cal = Calendar.current
        return offsets.compactMap { offset -> CompletionEvent? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: reference) else { return nil }
            let e = CompletionEvent()
            e.completedAt = date
            return e
        }
    }

    func test_perfectMonth_scores100() {
        // All 30 days completed → score should be 100
        let evts = events(daysAgo: Array(0...29))
        let score = ConsistencyEngine.score(events: evts)
        XCTAssertEqual(score, 100)
    }

    func test_noEvents_scores0() {
        let score = ConsistencyEngine.score(events: [])
        XCTAssertEqual(score, 0)
    }

    func test_onlyToday_scoredHighlyDueToWeight() {
        // Only today completed — should be well above 50 because day 0 is max weight
        let evts = events(daysAgo: [0])
        let score = ConsistencyEngine.score(events: evts)
        XCTAssertGreaterThan(score, 50)
    }

    func test_onlyOldestDay_scoredLow() {
        // Only day 29 completed — low weight, should be below 30
        let evts = events(daysAgo: [29])
        let score = ConsistencyEngine.score(events: evts)
        XCTAssertLessThan(score, 30)
    }

    func test_recentDays_returnsCorrectBoolArray() {
        // Completed on day 0 and day 2 — recentDays[0] and [2] should be true
        let evts = events(daysAgo: [0, 2])
        let days = ConsistencyEngine.recentDays(events: evts)
        XCTAssertEqual(days.count, 7)
        XCTAssertTrue(days[0])   // today
        XCTAssertFalse(days[1])  // yesterday
        XCTAssertTrue(days[2])   // 2 days ago
        XCTAssertFalse(days[3])
    }

    func test_eventsOlderThan30Days_ignored() {
        // Day 31 is outside window — should not increase score vs empty
        let evts = events(daysAgo: [31])
        let score = ConsistencyEngine.score(events: evts)
        XCTAssertEqual(score, 0)
    }
}
```

- [ ] **Step 2: Run tests — confirm they fail**

```bash
xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/ConsistencyEngineTests 2>&1 | tail -20
```

Expected: compile error — `ConsistencyEngine` not yet defined.

- [ ] **Step 3: Create ConsistencyEngine**

Create `VitaminG/Services/ConsistencyEngine.swift`:

```swift
import Foundation

// MARK: - ConsistencyEngine

/// Computes a weighted consistency score over the past 30 days.
/// Recent days are weighted exponentially more than older days (decay = 0.05).
/// Pattern: pure struct, injectable asOf date, zero SwiftUI/SwiftData dependency — same as StreakEngine.
struct ConsistencyEngine {

    private static let windowDays = 30
    private static let decay: Double = 0.05

    // MARK: - score

    /// Returns an integer 0–100 representing weighted completion rate over the past 30 days.
    /// - Parameters:
    ///   - events: All CompletionEvent records. nil completedAt values are skipped.
    ///   - asOf: Reference date for computing daysAgo. Defaults to now; injectable for tests.
    static func score(events: [CompletionEvent], asOf: Date = .now) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: asOf)

        // Build a Set<Date> of unique days that had ≥1 completion in the window
        let completedDays: Set<Date> = Set(
            events.compactMap { $0.completedAt }
                .map { cal.startOfDay(for: $0) }
                .filter { day in
                    guard let diff = cal.dateComponents([.day], from: day, to: today).day else { return false }
                    return diff >= 0 && diff < windowDays
                }
        )

        var weightedSum: Double = 0
        var totalWeight: Double = 0

        for daysAgo in 0..<windowDays {
            let weight = exp(-decay * Double(daysAgo))
            totalWeight += weight
            guard let day = cal.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            if completedDays.contains(day) {
                weightedSum += weight
            }
        }

        guard totalWeight > 0 else { return 0 }
        return Int((weightedSum / totalWeight * 100).rounded())
    }

    // MARK: - recentDays

    /// Returns a 7-element Bool array: index 0 = today, index 6 = 6 days ago.
    /// true = at least one CompletionEvent on that day.
    static func recentDays(events: [CompletionEvent], asOf: Date = .now) -> [Bool] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: asOf)
        let completedDays: Set<Date> = Set(
            events.compactMap { $0.completedAt }.map { cal.startOfDay(for: $0) }
        )
        return (0..<7).map { daysAgo in
            guard let day = cal.date(byAdding: .day, value: -daysAgo, to: today) else { return false }
            return completedDays.contains(day)
        }
    }
}
```

- [ ] **Step 4: Run tests — confirm they pass**

```bash
xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/ConsistencyEngineTests 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add VitaminG/Services/ConsistencyEngine.swift VitaminGTests/ConsistencyEngineTests.swift
git commit -m "feat: add ConsistencyEngine with exponential-decay weighted score (TDD)"
```

---

### Task 4: ConsistencyScoreCard + StatsViewModel

**Files:**
- Modify: `VitaminG/ViewModels/StatsViewModel.swift`
- Create: `VitaminG/Views/Components/ConsistencyScoreCard.swift`
- Modify: `VitaminG/Views/StatsView.swift`

- [ ] **Step 1: Update StatsViewModel**

In `StatsViewModel.swift`, add two new published properties and compute them in `refresh`:

```swift
// Add after existing published properties:
var consistencyScore: Int = 0
var recentDaysActivity: [Bool] = Array(repeating: false, count: 7)

// In refresh(events:goals:), add after globalStreak line:
consistencyScore = ConsistencyEngine.score(events: events)
recentDaysActivity = ConsistencyEngine.recentDays(events: events)
```

- [ ] **Step 2: Create ConsistencyScoreCard**

Create `VitaminG/Views/Components/ConsistencyScoreCard.swift`:

```swift
import SwiftUI

// MARK: - ConsistencyScoreCard

/// Displays the user's 30-day weighted consistency score.
/// Sits below globalStreakCard in StatsView (Layout A from design).
struct ConsistencyScoreCard: View {
    let score: Int
    let recentDays: [Bool]   // 7 elements: index 0 = today

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Consistency Score")
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.textSecondary)
                    Text("Last 30 days · recent days weighted")
                        .font(.caption)
                        .foregroundStyle(VGTheme.textMuted)
                }
                Spacer()
                // Mini 7-bar chart
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(Array(recentDays.reversed().enumerated()), id: \.offset) { _, active in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(active ? VGTheme.accentSage : VGTheme.separator)
                            .frame(width: 5, height: active ? 28 : 12)
                    }
                }
            }

            // Score numeral
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(VGTheme.accentSage)
                Text("%")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(VGTheme.textMuted)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(VGTheme.separator)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(VGTheme.accentSage)
                        .frame(width: geo.size.width * CGFloat(score) / 100, height: 6)
                        .animation(.easeOut(duration: 0.6), value: score)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(VGTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(VGTheme.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Consistency Score: \(score) percent over the last 30 days")
    }
}
```

- [ ] **Step 3: Add ConsistencyScoreCard to StatsView**

In `StatsView.swift`, in the main `VStack` of the `ScrollView` body, add `ConsistencyScoreCard` directly after `globalStreakCard`:

```swift
VStack(spacing: 20) {
    globalStreakCard
    ConsistencyScoreCard(
        score: viewModel.consistencyScore,
        recentDays: viewModel.recentDaysActivity
    )
    tierStreakGrid
    heatmapSection
}
```

- [ ] **Step 4: Build and visually verify**

Build (`Cmd+B`). Run in Simulator. Navigate to the Stats tab. Confirm the card appears below the streak card with a score, 7-bar chart, and progress bar. Toggle to Dark Mode and confirm colors adapt correctly.

- [ ] **Step 5: Commit**

```bash
git add VitaminG/ViewModels/StatsViewModel.swift VitaminG/Views/Components/ConsistencyScoreCard.swift VitaminG/Views/StatsView.swift
git commit -m "feat: add Consistency Score card to Stats screen with 30-day weighted metric"
```

---

### Task 5: StreakFreezeService — TDD

**Files:**
- Create: `VitaminG/Services/StreakFreezeService.swift`
- Create: `VitaminGTests/StreakFreezeTests.swift`

- [ ] **Step 1: Write failing tests**

Create `VitaminGTests/StreakFreezeTests.swift`:

```swift
import XCTest
@testable import VitaminG

final class StreakFreezeTests: XCTestCase {

    var service: StreakFreezeService!

    override func setUp() {
        super.setUp()
        // Use a test-isolated UserDefaults suite
        let defaults = UserDefaults(suiteName: "test.streakfreeze")!
        defaults.removePersistentDomain(forName: "test.streakfreeze")
        service = StreakFreezeService(defaults: defaults)
    }

    func test_canFreeze_trueOnFreshInstall() {
        XCTAssertTrue(service.canFreeze)
    }

    func test_afterFreeze_canFreezeIsFalse() {
        service.freeze()
        XCTAssertFalse(service.canFreeze)
    }

    func test_frozenDates_containsTodayAfterFreeze() {
        let today = Calendar.current.startOfDay(for: .now)
        service.freeze()
        XCTAssertTrue(service.frozenDates.contains(today))
    }

    func test_freezeOnDifferentMonth_resetsAvailability() {
        // Simulate a freeze in the previous month
        let cal = Calendar.current
        let lastMonth = cal.date(byAdding: .month, value: -1, to: .now)!
        service.freeze(on: lastMonth)
        // Now canFreeze should be true because last freeze was last month
        XCTAssertTrue(service.canFreeze)
    }

    func test_twoFreezesInSameMonth_secondIsIgnored() {
        service.freeze()
        let countBefore = service.frozenDates.count
        service.freeze()
        XCTAssertEqual(service.frozenDates.count, countBefore)
    }
}
```

- [ ] **Step 2: Run tests — confirm they fail**

```bash
xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/StreakFreezeTests 2>&1 | tail -10
```

Expected: compile error — `StreakFreezeService` not defined.

- [ ] **Step 3: Create StreakFreezeService**

Create `VitaminG/Services/StreakFreezeService.swift`:

```swift
import Foundation

// MARK: - StreakFreezeService

/// Manages the one-per-month streak freeze safety valve.
/// Backed by UserDefaults so state persists across app launches and is
/// accessible from the App Group suite shared with widgets.
final class StreakFreezeService {

    private let defaults: UserDefaults
    private let keyLastFreezeDate = "vg.streakFreeze.lastFreezeDate"
    private let keyFrozenDates = "vg.streakFreeze.frozenDates"

    // MARK: - Init

    /// - Parameter defaults: Injectable UserDefaults suite. Production uses the App Group suite.
    init(defaults: UserDefaults = UserDefaults(suiteName: "group.com.kyleharrington.VitaminG") ?? .standard) {
        self.defaults = defaults
    }

    // MARK: - Public API

    /// True when the user has not used their freeze this calendar month.
    var canFreeze: Bool {
        guard let lastDate = lastFreezeDate else { return true }
        let cal = Calendar.current
        return !cal.isDate(lastDate, equalTo: .now, toGranularity: .month)
    }

    /// Sorted array of dates on which the user has activated a freeze.
    var frozenDates: [Date] {
        let intervals = defaults.array(forKey: keyFrozenDates) as? [Double] ?? []
        return intervals.map { Date(timeIntervalSince1970: $0) }
    }

    /// Activates a freeze for the given date. No-op if freeze already used this month.
    /// - Parameter date: The date to freeze. Defaults to now; injectable for testing.
    func freeze(on date: Date = .now) {
        guard canFreeze else { return }
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        var intervals = defaults.array(forKey: keyFrozenDates) as? [Double] ?? []
        intervals.append(day.timeIntervalSince1970)
        defaults.set(intervals, forKey: keyFrozenDates)
        defaults.set(date.timeIntervalSince1970, forKey: keyLastFreezeDate)
    }

    // MARK: - Private

    private var lastFreezeDate: Date? {
        let interval = defaults.double(forKey: keyLastFreezeDate)
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }
}
```

- [ ] **Step 4: Run tests — confirm they pass**

```bash
xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/StreakFreezeTests 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add VitaminG/Services/StreakFreezeService.swift VitaminGTests/StreakFreezeTests.swift
git commit -m "feat: add StreakFreezeService with one-per-month safety valve (TDD)"
```

---

### Task 6: StreakEngine — Frozen Dates Support

**Files:**
- Modify: `VitaminG/Services/StreakEngine.swift`
- Modify: `VitaminGTests/StreakEngineTests.swift`

- [ ] **Step 1: Write failing frozen-dates tests**

In `VitaminGTests/StreakEngineTests.swift`, add at the end of the class:

```swift
func test_frozenDate_countsAsCompletedDay() {
    // No real events, but today is frozen — streak should be 1
    let cal = Calendar.current
    let today = cal.startOfDay(for: .now)
    let result = StreakEngine.currentStreak(from: [], frozenDates: [today])
    XCTAssertEqual(result, 1)
}

func test_frozenDatePlusPriorDay_givesStreak2() {
    let cal = Calendar.current
    let today = cal.startOfDay(for: .now)
    let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

    // Yesterday: real event. Today: freeze.
    let e = CompletionEvent()
    e.completedAt = yesterday

    let result = StreakEngine.currentStreak(from: [e], frozenDates: [today])
    XCTAssertEqual(result, 2)
}

func test_existingCallersUnaffected_defaultFrozenDatesEmpty() {
    // Existing callers omit frozenDates — default [] must not break anything
    let e = CompletionEvent()
    e.completedAt = Calendar.current.startOfDay(for: .now)
    let result = StreakEngine.currentStreak(from: [e])
    XCTAssertEqual(result, 1)
}
```

- [ ] **Step 2: Run new tests — confirm they fail**

```bash
xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/StreakEngineTests/test_frozenDate 2>&1 | tail -10
```

Expected: compile error on `frozenDates` parameter.

- [ ] **Step 3: Update StreakEngine.currentStreak**

In `StreakEngine.swift`, update `currentStreak` signature and implementation:

```swift
static func currentStreak(
    from events: [CompletionEvent],
    tier: GoalTier? = nil,
    frozenDates: [Date] = [],
    calendar: Calendar = .current
) -> Int {
    let filtered = filteredEvents(events, tier: tier)

    var days: Set<Date> = Set(
        filtered.compactMap { $0.completedAt }.map { calendar.startOfDay(for: $0) }
    )
    // Add frozen dates only where there is no real event (freeze doesn't consume if user completed)
    for frozen in frozenDates {
        days.insert(calendar.startOfDay(for: frozen))
    }

    guard !days.isEmpty else { return 0 }

    let today = calendar.startOfDay(for: Date())
    var candidate: Date
    if days.contains(today) {
        candidate = today
    } else {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
        candidate = yesterday
    }

    var streak = 0
    while days.contains(candidate) {
        streak += 1
        guard let previous = calendar.date(byAdding: .day, value: -1, to: candidate) else { break }
        candidate = previous
    }
    return streak
}
```

- [ ] **Step 4: Run all StreakEngine tests — confirm they pass**

```bash
xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/StreakEngineTests 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add VitaminG/Services/StreakEngine.swift VitaminGTests/StreakEngineTests.swift
git commit -m "feat: StreakEngine supports frozenDates — freeze counts as completed day"
```

---

### Task 7: Streak Freeze UI in StatsView

**Files:**
- Modify: `VitaminG/Views/StatsView.swift`

- [ ] **Step 1: Add StreakFreezeService to StatsView**

In `StatsView.swift`, add state for the freeze service and confirmation alert:

```swift
// Add alongside existing @State properties:
@State private var freezeService = StreakFreezeService()
@State private var showFreezeConfirmation = false
```

- [ ] **Step 2: Add freeze button to globalStreakCard**

In `globalStreakCard`, add the freeze button below the days label inside the `VStack`. The full updated `globalStreakCard`:

```swift
private var globalStreakCard: some View {
    ZStack {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: [VGTheme.accentTerra, VGTheme.accentPurple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
                Text("Global Streak")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
            }

            Text("\(viewModel.globalStreak)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(viewModel.globalStreak == 1 ? "Day" : "Days")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))

            // Streak Freeze button — only visible when freeze is available
            if freezeService.canFreeze {
                Button {
                    showFreezeConfirmation = true
                } label: {
                    Label("Freeze Streak", systemImage: "snowflake")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.15))
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            } else {
                Label("Streak protected this month", systemImage: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 24)
    }
    .confirmationDialog(
        "Use your monthly streak freeze?",
        isPresented: $showFreezeConfirmation,
        titleVisibility: .visible
    ) {
        Button("Freeze Streak") {
            freezeService.freeze()
            viewModel.refresh(events: events, goals: goals)
        }
        Button("Cancel", role: .cancel) {}
    } message: {
        Text("You get one freeze per month. This will protect today's streak even if you miss a day.")
    }
}
```

- [ ] **Step 3: Wire frozen dates into StatsViewModel streak computation**

In `StatsView.swift`, update the `.onAppear` and `.onChange` calls to pass frozen dates. First, update `StatsViewModel.refresh` to accept frozen dates:

In `StatsViewModel.swift`, update `refresh`:

```swift
func refresh(events: [CompletionEvent], goals: [Goal], frozenDates: [Date] = []) {
    globalStreak = StreakEngine.currentStreak(from: events, frozenDates: frozenDates)

    for tier in GoalTier.ordered {
        tierStreaks[tier] = StreakEngine.currentStreak(from: events, tier: tier, frozenDates: frozenDates)
        // ... rest unchanged
    }
    // ... rest unchanged
}
```

In `StatsView.swift`, update the refresh calls:

```swift
.onAppear {
    viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
}
.onChange(of: events.count) {
    viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
}
.onChange(of: goals.count) {
    viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
}
```

- [ ] **Step 4: Build and visually verify**

Build (`Cmd+B`). Open the Stats tab. Confirm the "Freeze Streak" button appears in the streak card. Tap it, confirm the dialog, and confirm it changes to the "Streak protected" label. Relaunch the app and confirm the protected state persists.

- [ ] **Step 5: Commit**

```bash
git add VitaminG/Views/StatsView.swift VitaminG/ViewModels/StatsViewModel.swift
git commit -m "feat: add Streak Freeze UI — one-per-month safety valve in global streak card"
```

---

### Task 8: Widget Push-to-Refresh

**Files:**
- Modify: `VitaminGWidget/GoalSummaryWidget.swift`
- Modify: `VitaminGWidget/StreakWidget.swift`

- [ ] **Step 1: Change GoalSummaryWidget timeline policy to .never**

In `GoalSummaryWidget.swift`, in `GoalSummaryProvider.getTimeline`, replace the `nextRefresh` calculation and timeline construction:

```swift
// Before
let nextRefresh = WidgetDataProvider.nextMorningRefreshDate(...)
let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
completion(timeline)
// ...
let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))

// After (both branches)
let timeline = Timeline(entries: [entry], policy: .never)
completion(timeline)
```

Remove the `nextRefresh` constant — it is no longer used.

- [ ] **Step 2: Change StreakWidget timeline policy to .never**

In `StreakWidget.swift`, same change in `StreakProvider.getTimeline`:

```swift
// Both branches: .after(...) → .never
let timeline = Timeline(entries: [entry], policy: .never)
completion(timeline)
```

Remove the `nextRefresh` constant.

- [ ] **Step 3: Verify GoalViewModel already calls reloadAllTimelines**

Check `GoalViewModel.swift` — confirm `reloadWidgetTimelines()` is called from `toggleCompletion`, `createGoal`, `updateGoal`, and `deleteGoal`. No changes needed; this is already in place.

- [ ] **Step 4: Build widget target and verify**

Build the widget target (`VitaminGWidget`). Add the widget to the home screen in Simulator. Complete a goal in the app — confirm the widget updates immediately. Confirm the widget does NOT update on its own after sitting idle.

- [ ] **Step 5: Commit**

```bash
git add VitaminGWidget/GoalSummaryWidget.swift VitaminGWidget/StreakWidget.swift
git commit -m "perf: switch widgets to push-only refresh (.never policy) to reduce battery drain"
```

---

### Task 9: Final Build Verification

- [ ] **Step 1: Run the full test suite**

```bash
xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "PASSED|FAILED|error:"
```

Expected: all tests pass, no errors.

- [ ] **Step 2: Visual dark mode check**

In Simulator, switch to Dark Mode. Navigate through: Goal List → Goal Detail → Stats (streak card, Consistency Score card, Freeze button) → Settings → Daily Wins → Notifications permission sheet. Confirm no harsh white or light-only elements.

- [ ] **Step 3: Tag Phase 15 complete**

```bash
git tag phase-15-complete
```
