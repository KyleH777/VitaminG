# Phase 12: Goal Progress Visualization — Pattern Map

**Mapped:** 2026-05-03
**Files analyzed:** 6 (3 create, 3 modify)
**Analogs found:** 6 / 6

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Views/Components/ProgressRingView.swift` | component | request-response | `Views/Components/EmptyTierView.swift` | role-match (same component layer, struct View with `GoalTier` param) |
| `Services/ProgressViewModel.swift` | service | transform | `Services/StreakEngine.swift` | exact (pure struct, `[CompletionEvent]` in → computed value out, no SwiftData import) |
| `VitaminGTests/ProgressViewModelTests.swift` | test | batch | `VitaminGTests/StreakEngineTests.swift` | exact (same XCTest class shape, `ModelContainerFactory.makeContainer(inMemory:)`, `makeEvent(dayOffset:)` helper) |
| `Views/GoalListView.swift` | component + view | request-response | self (read directly — this is the file being modified) | self |
| `Views/GoalDetailView.swift` | component + view | request-response | self (read directly — this is the file being modified) | self |
| `ViewModels/GoalViewModel.swift` | viewmodel | request-response | self (read directly — this is the file being modified) + `ViewModels/StatsViewModel.swift` for `@MainActor @Observable` pattern | exact |

---

## Pattern Assignments

### `Services/ProgressViewModel.swift` (service, transform)

**Analog:** `Services/StreakEngine.swift`

**Imports pattern** (StreakEngine.swift lines 1):
```swift
import Foundation
// NO import SwiftData — pure struct receives plain Swift arrays
// NO import SwiftUI — no UI dependency
```

**Struct declaration pattern** (StreakEngine.swift lines 13):
```swift
struct StreakEngine {
    // static func — no instance state required
    static func currentStreak(
        from events: [CompletionEvent],
        tier: GoalTier? = nil,
        calendar: Calendar = .current    // Injectable for testability
    ) -> Int { ... }
```
For `ProgressViewModel`, use instance methods (not static) to match D-15, but keep the same parameter convention: accept `[CompletionEvent]` and `Goal` as plain arrays/values — never reference SwiftData internals.

**Calendar arithmetic pattern** (StreakEngine.swift lines 39-45):
```swift
let days: Set<Date> = Set(
    filtered.compactMap { $0.completedAt }.map { calendar.startOfDay(for: $0) }
)
let today = calendar.startOfDay(for: Date())
```
`ProgressViewModel` must use `Calendar.current.startOfDay(for:)` identically — D-05 explicitly requires this match.

**Guard-nil-completedAt pattern** (StreakEngine.swift lines 39, StatsViewModel.swift lines 56-57):
```swift
// StreakEngine: .compactMap { $0.completedAt }
// StatsViewModel.buildHeatmapData:
guard let date = event.completedAt else { continue }
let day = Calendar.current.startOfDay(for: date)
dict[day, default: 0] += 1
```
Both patterns are present in the codebase. `ProgressViewModel.chartData` must use the `guard let` + `dict[day, default: 0] += 1` form from `StatsViewModel.buildHeatmapData` (lines 55-59) — it is the direct template for the 30-day `[DayCount]` builder.

**StatsViewModel refresh pattern** (StatsViewModel.swift lines 31-47):
```swift
func refresh(events: [CompletionEvent], goals: [Goal]) {
    globalStreak = StreakEngine.currentStreak(from: events)
    for tier in GoalTier.ordered {
        tierStreaks[tier] = StreakEngine.currentStreak(from: events, tier: tier)
        let tierGoals = goals.filter { $0.tier == tier }
        tierCompletionRates[tier] = StreakEngine.completionRate(
            events: events, totalGoals: tierGoals.count, tier: tier
        )
        tierGoalCounts[tier] = tierGoals.count
    }
    heatmapData = buildHeatmapData(from: events)
}
```
`ProgressViewModel` does NOT need a `refresh()` method (it is called inline per-goal, not once for all goals). But D-15 requires `@MainActor @Observable` on the class declaration — copy this from `StatsViewModel.swift` lines 13-15:
```swift
@MainActor
@Observable
final class StatsViewModel {
```

**Heatmap builder as exact template** (StatsViewModel.swift lines 53-61):
```swift
private func buildHeatmapData(from events: [CompletionEvent]) -> [Date: Int] {
    var dict: [Date: Int] = [:]
    for event in events {
        guard let date = event.completedAt else { continue }
        let day = Calendar.current.startOfDay(for: date)
        dict[day, default: 0] += 1
    }
    return dict
}
```
`ProgressViewModel.chartData(for:events:)` copies this body exactly, then maps the dict to `[DayCount]` for the 30-day range.

**Static milestone thresholds pattern** — no codebase analog; use the value from RESEARCH.md Pattern 1:
```swift
static let milestoneThresholds: [Int] = [5, 10, 25, 50]
```

---

### `Views/Components/ProgressRingView.swift` (component, request-response)

**Analog:** `Views/Components/EmptyTierView.swift`

**Struct declaration pattern** (EmptyTierView.swift lines 7-10):
```swift
struct EmptyTierView: View {
    let tier: GoalTier
    let onAdd: () -> Void
```
`ProgressRingView` follows the same pure-value-properties struct shape:
```swift
struct ProgressRingView: View {
    let progress: Double      // 0.0–1.0
    let tier: GoalTier
    let isCompleted: Bool
```

**Tier color usage pattern** (EmptyTierView.swift lines 26-29):
```swift
Image(systemName: tier.icon)
    .font(.title2)
    .foregroundStyle(tier.color)
```
`ProgressRingView` uses `tier.color` for the ring stroke (active goal) and a local `completionGreen` constant for a fully-completed goal ring.

**completionGreen constant** — sourced from `GoalListView.swift` line 188:
```swift
private let completionGreen = Color(red: 0.063, green: 0.725, blue: 0.506)
```
Declare this same constant identically inside `ProgressRingView`.

**@Environment reduced motion pattern** (GoalListView.swift lines 185-186):
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
@State private var bounceScale: CGFloat = 1.0
```
`ProgressRingView` uses:
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```
Then gates `.animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: progress)`.

**Circle().trim() core draw pattern** (RESEARCH.md Pattern 2 — no codebase analog; use as specified):
```swift
ZStack {
    Circle()
        .stroke(tier.color.opacity(0.15), lineWidth: 3)
    Circle()
        .trim(from: 0, to: progress)
        .stroke(strokeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: progress)
}
.frame(width: 28, height: 28)
```
Note: `.rotationEffect(.degrees(-90))` is mandatory (Pitfall 2 from RESEARCH.md — default 0° is 3 o'clock, not 12 o'clock).

**Accessibility pattern** (GoalListView.swift lines 202-204):
```swift
.accessibilityLabel(goal.completed
    ? "Mark \(goal.title ?? "goal") as active"
    : "Mark \(goal.title ?? "goal") as complete")
```
`ProgressRingView` mirrors this pattern:
```swift
.accessibilityLabel(isCompleted ? "Goal complete" : "\(Int(progress * 100))% momentum this week")
.accessibilityAddTraits(.isStaticText)
```

---

### `VitaminGTests/ProgressViewModelTests.swift` (test, batch)

**Analog:** `VitaminGTests/StreakEngineTests.swift`

**Test class boilerplate** (StreakEngineTests.swift lines 1-17):
```swift
import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class StreakEngineTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }
```
`ProgressViewModelTests` copies this header exactly — same `@MainActor`, same `ModelContainerFactory.makeContainer(inMemory: true)`, same `setUp/tearDown`.

**makeEvent helper** (StreakEngineTests.swift lines 22-33):
```swift
private func makeEvent(dayOffset: Int, tier: GoalTier = .immediate) -> CompletionEvent {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    let date = cal.date(byAdding: .day, value: dayOffset, to: today)!
    let goal = Goal(title: "Test Goal", tier: tier)
    context.insert(goal)
    let event = CompletionEvent(goal: goal)
    event.completedAt = date
    event.tierRawValue = tier.rawValue
    context.insert(event)
    return event
}
```
`ProgressViewModelTests` extends this helper to also accept a `goalID` or return the `Goal` object so tests can call `ProgressViewModel.ringProgress(for: goal, events: events)`.

**Test naming convention** (StreakEngineTests.swift throughout):
```swift
func test_emptyEvents_returnsZeroStreak()
func test_singleEventToday_returnsOneStreak()
func test_consecutiveDays_returnsCorrectStreak()
```
Follow the same `test_<scenario>_<expectedOutcome>()` naming pattern for all `ProgressViewModelTests` methods.

**XCTAssertEqual with accuracy** (StreakEngineTests.swift lines 178):
```swift
XCTAssertEqual(rate, 2.0 / 3.0, accuracy: 0.001, "Completion rate should be 2/3")
```
Use `accuracy:` for all `Double` comparisons in `ProgressViewModelTests`.

---

### `Views/GoalListView.swift` — MODIFY (component, request-response)

**The existing file is the primary reference.** Key patterns to extend:

**@Query declaration pattern** (GoalListView.swift lines 7-8):
```swift
@Environment(\.modelContext) private var modelContext
@Query private var goals: [Goal]   // no sort descriptor — dynamic sort via computed property
```
Add immediately after line 8:
```swift
@Query private var events: [CompletionEvent]
```
And add `@State` for milestone:
```swift
@State private var pendingMilestone: (goalID: UUID, threshold: Int)? = nil
```

**goalRow helper pattern** (GoalListView.swift lines 134-154):
```swift
@ViewBuilder
private func goalRow(for goal: Goal) -> some View {
    NavigationLink(value: AppRoute.goalDetail(goal)) {
        GoalRowView(goal: goal) {
            viewModel.toggleCompletion(goal: goal, context: modelContext)
        }
    }
    .listRowBackground(
        goal.completed
            ? Color(red: 0.063, green: 0.725, blue: 0.506).opacity(0.08)
            : Color(.secondarySystemGroupedBackground)
    )
    .swipeActions(edge: .trailing, allowsFullSwipe: false) { ... }
}
```
Add `events:` and `milestoneThreshold:` parameters to `GoalRowView(...)` call; keep all other modifiers unchanged. Add `.onChange(of: viewModel.pendingMilestone?.goalID)` inside or on the NavigationLink to consume the milestone event from `GoalViewModel`.

**Task { @MainActor } async delay pattern** (GoalListView.swift lines 241-246):
```swift
Task { @MainActor in
    try? await Task.sleep(for: .milliseconds(150))
    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
        bounceScale = 1.0
    }
}
```
The milestone badge animation in `GoalRowView` copies this exact pattern — `Task { @MainActor in try? await Task.sleep(for:) }` — which is the established project pattern for async delays in views.

**Tier pip to replace** (GoalListView.swift lines 224-229 — the exact code being replaced):
```swift
// Tier accent pip — completionGreen when complete
RoundedRectangle(cornerRadius: 3)
    .fill(goal.completed
        ? completionGreen.opacity(0.8)
        : goal.tier.color.opacity(0.8))
    .frame(width: 4, height: 36)
```
Replace entirely with:
```swift
ProgressRingView(
    progress: ProgressViewModel().ringProgress(for: goal, events: events),
    tier: goal.tier,
    isCompleted: goal.completed
)
```

**GoalRowView private struct signature** (GoalListView.swift lines 181-183):
```swift
private struct GoalRowView: View {
    let goal: Goal
    let onToggle: () -> Void
```
Add new parameters:
```swift
private struct GoalRowView: View {
    let goal: Goal
    let events: [CompletionEvent]
    let milestoneThreshold: Int?
    let onToggle: () -> Void
```
Add new `@State` vars for milestone badge:
```swift
@State private var showMilestoneBadge = false
@State private var badgeOpacity: Double = 0
@State private var badgeScale: CGFloat = 0.5
```

**reduceMotion pattern** (GoalListView.swift line 185):
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```
Already declared in `GoalRowView`. Milestone badge animation must also gate on `reduceMotion` (same line, same property).

---

### `Views/GoalDetailView.swift` — MODIFY (component, request-response)

**The existing file is the primary reference.** Key patterns to extend:

**Import block** (GoalDetailView.swift lines 1-2):
```swift
import SwiftUI
import SwiftData
```
Add:
```swift
import Charts
```

**VStack section ordering** (GoalDetailView.swift lines 21-28):
```swift
VStack(spacing: 16) {
    headerSection
    publicToggleSection
    quoteCardSection
    notesSection
    actionsSection
}
```
Insert `progressSection` between `quoteCardSection` and `notesSection`:
```swift
VStack(spacing: 16) {
    headerSection
    publicToggleSection
    quoteCardSection
    progressSection      // NEW
    notesSection
    actionsSection
}
```

**Section card pattern** (GoalDetailView.swift lines 62-86 — `publicToggleSection`):
```swift
private var publicToggleSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        // ... content
    }
    .padding(16)
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, 16)
}
```
`progressSection` uses the same `.padding(16) / .background(Color(.systemBackground)) / .clipShape(RoundedRectangle(cornerRadius: 12)) / .padding(.horizontal)` stack.

**Section header typography** (GoalDetailView.swift lines 168-170 — `notesSection`):
```swift
Text("Notes")
    .font(.footnote.weight(.semibold)).fontDesign(.rounded)
    .foregroundStyle(.secondary)
```
`progressSection` header: `Text("Progress History")` with identical `.font(.footnote.weight(.semibold)).fontDesign(.rounded).foregroundStyle(.secondary)`.

**Summary HStack row pattern** (GoalDetailView.swift lines 65-67 — `publicToggleSection`):
```swift
HStack {
    Text("Share this goal")
        .font(.body).fontDesign(.rounded)
    Spacer()
    Toggle(...)
```
`progressSection` summary rows mirror the HStack pattern:
```swift
HStack {
    Text("Total completions").font(.body).fontDesign(.rounded)
    Spacer()
    Text("\(totalCompletions)").font(.body.weight(.semibold)).fontDesign(.rounded)
}
```

**completionEvents relationship access** (GoalDetailView.swift lines 115-121 — already in headerSection):
```swift
if goal.completed,
   let lastEvent = goal.completionEvents?
       .sorted(by: { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) })
       .first,
   let completedAt = lastEvent.completedAt {
    Text("Completed \(completedAt.formatted(date: .abbreviated, time: .omitted))")
```
This confirms `goal.completionEvents` is already accessed in `GoalDetailView` via the SwiftData relationship — no extra `@Query` needed. `progressSection` uses `goal.completionEvents ?? []` in the same pattern.

**Date formatting pattern** (GoalDetailView.swift line 120):
```swift
completedAt.formatted(date: .abbreviated, time: .omitted)
```
"Last completed" row in `progressSection` uses the identical format call.

---

### `ViewModels/GoalViewModel.swift` — MODIFY (viewmodel, request-response)

**The existing file is the primary reference.** Key patterns to extend:

**@MainActor @Observable class pattern** (GoalViewModel.swift lines 30-32):
```swift
@MainActor
@Observable
final class GoalViewModel {
```
Unchanged. New properties are added inside this class.

**toggleCompletion method** (GoalViewModel.swift lines 99-107 — exact code being modified):
```swift
func toggleCompletion(goal: Goal, context: ModelContext) {
    goal.completed.toggle()
    if goal.completed {
        let event = CompletionEvent(goal: goal)
        context.insert(event)
    }
    rescheduleNotification(context: context)
    reloadWidgetTimelines()
}
```
After `context.insert(event)`, add the milestone check block before the existing `rescheduleNotification` call. No change to the method signature — only new logic inserted mid-body.

**reloadWidgetTimelines / rescheduleNotification pattern** (GoalViewModel.swift lines 141-155):
```swift
private func reloadWidgetTimelines() {
    WidgetCenter.shared.reloadAllTimelines()
}

func rescheduleNotification(context: ModelContext) {
    let descriptor = FetchDescriptor<Goal>(predicate: #Predicate { !$0.isCompleted })
    let activeGoals = (try? context.fetch(descriptor)) ?? []
    Task {
        await NotificationScheduler.shared.reschedule(activeGoals: activeGoals)
    }
}
```
Both are called at the end of `toggleCompletion` — new milestone code inserts between `context.insert(event)` and these trailing calls.

**New properties to add** (after existing `showingValidationAlert` at GoalViewModel.swift line 48):
```swift
// MARK: - Milestone Tracking (PROG-03)
private(set) var pendingMilestone: (goalID: UUID, threshold: Int)? = nil
private var firedMilestones: Set<String> = []
private let progressVM = ProgressViewModel()
```

---

## Shared Patterns

### @Environment(\.accessibilityReduceMotion) gate
**Source:** `Views/GoalListView.swift` line 185
**Apply to:** `ProgressRingView`, `GoalRowView` milestone badge animation
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```
All animation blocks must check `reduceMotion`:
- `ProgressRingView`: `.animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: progress)`
- Milestone badge: skip animation sequence, show static badge for 0.5s then fade

### completionGreen constant
**Source:** `Views/GoalListView.swift` line 188
**Apply to:** `ProgressRingView`, any new code in `GoalListView.swift` referencing the completion color
```swift
private let completionGreen = Color(red: 0.063, green: 0.725, blue: 0.506)
```

### Task { @MainActor } async delay
**Source:** `Views/GoalListView.swift` lines 241-246
**Apply to:** `GoalRowView` milestone badge animation sequence, any timed overlay in `GoalRowView`
```swift
Task { @MainActor in
    try? await Task.sleep(for: .milliseconds(150))
    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
        bounceScale = 1.0
    }
}
```

### fontDesign(.rounded) — project-wide convention
**Source:** Every existing view file (GoalListView.swift line 209, GoalDetailView.swift lines 95, 102, etc.)
**Apply to:** All new `Text` views in `progressSection`, `ProgressRingView` (accessibility labels use strings, not Text), and any labels
```swift
.font(.body).fontDesign(.rounded)
.font(.caption).fontDesign(.rounded)
.font(.footnote.weight(.semibold)).fontDesign(.rounded)
```

### Card background pattern
**Source:** `Views/GoalDetailView.swift` lines 79-83, lines 126-128
**Apply to:** `progressSection` in `GoalDetailView`
```swift
.padding(16)
.background(Color(.systemBackground))
.clipShape(RoundedRectangle(cornerRadius: 12))
.padding(.horizontal)
```

### @Observable ViewModel (no @StateObject)
**Source:** `Views/GoalDetailView.swift` line 14, `Views/GoalListView.swift` line 10
**Apply to:** Any `ProgressViewModel` instance in a view
```swift
@State private var viewModel = GoalViewModel()   // pattern to follow
// NOT @StateObject — that is the deprecated ObservableObject pattern
```

### UIAccessibility VoiceOver announcement
**Source:** RESEARCH.md (no codebase analog — project doesn't yet use this)
**Apply to:** `GoalRowView.fireMilestoneBadge()`
```swift
UIAccessibility.post(notification: .announcement,
                     argument: "Milestone reached: \(threshold) completions!")
```
Import `UIKit` is not needed in SwiftUI files — `UIAccessibility` is available in SwiftUI targets automatically.

---

## No Analog Found

All files have analogs. No entries.

---

## Metadata

**Analog search scope:** `VitaminG/VitaminG/VitaminG/Services/`, `VitaminG/VitaminG/VitaminG/Views/`, `VitaminG/VitaminG/VitaminG/Views/Components/`, `VitaminG/VitaminG/VitaminG/ViewModels/`, `VitaminG/VitaminG/VitaminGTests/`
**Files scanned:** 6 analogs + 1 component directory listing
**Pattern extraction date:** 2026-05-03

### Critical Path Notes for Planner

1. **ProgressViewModel must be a `class` (not `struct`)** to satisfy `@MainActor @Observable` — D-15 says `@Observable`, and `@Observable` on a struct doesn't support `@MainActor`. However, D-16 says "standalone struct/class with no SwiftData dependency" — the planner should implement as `final class` (matching `StatsViewModel`) and confirm unit testability is preserved (it is, since no SwiftData imports are required).

2. **GoalRowView `private struct` scope** — milestone state must thread through `GoalListView.goalRow(for:)` helper, not set directly on `GoalRowView` from outside. The `pendingMilestone` on `GoalViewModel` is observed via `.onChange` in `GoalListView`, which then passes `milestoneThreshold: Int?` down to `GoalRowView` as a plain parameter.

3. **`goal.completionEvents` in `GoalDetailView`** — already used in `headerSection` (line 115), confirming the relationship is accessible without an extra `@Query`. `progressSection` can use `goal.completionEvents ?? []` directly.

4. **Tier pip replacement** — the exact four lines at GoalListView.swift lines 224-229 (`RoundedRectangle...frame(width: 4, height: 36)`) are the only lines to remove. Everything else in the HStack stays.

5. **`ProgressViewModel()` instance cost** — `ringProgress(for:events:)` is called once per visible `GoalRowView`. Instantiating `ProgressViewModel()` inline is zero-cost (no stored state, no SwiftData fetch). Prefer `let vm = ProgressViewModel()` at the call site rather than a stored `@State` property on `GoalRowView` to keep the struct stateless.
