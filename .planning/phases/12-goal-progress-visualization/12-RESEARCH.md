# Phase 12: Goal Progress Visualization — Research

**Researched:** 2026-05-03
**Domain:** SwiftUI progress visualization, Swift Charts, SF Symbol animation, MVVM service extraction
**Confidence:** HIGH (all primary claims verified against live codebase; Swift Charts patterns verified against Apple documentation)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Replace tier pip (`RoundedRectangle` 4×36pt) in `GoalRowView` with circular progress ring — 28pt diameter, 3pt stroke, tier color. Same HStack trailing slot.
- **D-02:** Ring fill formula: `min(completionsLast7Days / 7.0, 1.0)`. Fully-completed goal (`isCompleted == true`) always shows 1.0.
- **D-03:** Ring: `Circle().trim(from: 0, to: progress).stroke(...)` over faint background circle (`opacity: 0.15`). Reduced motion: static fill, no animation.
- **D-04:** 7-day window for both ring fill and momentum score. Consistent formula: `completions in last 7 calendar days ÷ 7`, clamped 0–1.
- **D-05:** "Last 7 calendar days" = today + 6 prior days via `Calendar.current.startOfDay`. Matches StreakEngine pattern.
- **D-06:** Momentum score shown as labeled row in GoalDetailView: numeric value + color dot (green ≥ 0.5, amber 0.1–0.5, gray < 0.1).
- **D-07:** Label: "Momentum" with subtitle "completions in the last 7 days." Colors: `#10B981` green, `.orange`, `.secondary`.
- **D-08:** Swift Charts (`import Charts`, Apple framework, iOS 16+, no third-party) for per-goal bar chart: one `BarMark` per calendar day, last 30 days.
- **D-09:** Above chart: "Total completions: N" and "Last completed: [date or 'Never']". Below chart: momentum score row.
- **D-10:** Chart height 80pt. Bar color: tier color. X-axis labels only last 7 days; older unlabeled.
- **D-11:** Milestone thresholds: 5, 10, 25, 50 cumulative completions per goal. Check `completionEvents?.count` after each `toggleCompletion`.
- **D-12:** Celebration: SF Symbol badge (`.star.fill`, tier color) scales 0.5 → 1.2 → 1.0, fades in, holds 1.5s, fades out. Non-blocking overlay.
- **D-13:** In-memory `Set<String>` on `GoalViewModel`, keyed `"\(goalID.uuidString)-\(threshold)"`. Does not persist across launches.
- **D-14:** Reduced motion: skip animation, show static badge 0.5s then fade.
- **D-15:** `ProgressViewModel` — `@MainActor @Observable`. Exposes: `ringProgress(for:events:)`, `momentumScore(for:events:)`, `chartData(for:events:)`, `milestoneJustCrossed(for:)`.
- **D-16:** `ProgressViewModel` is a standalone struct/class with no SwiftData/SwiftUI dependency — unit-testable in isolation.

### Claude's Discretion

- Exact SF Symbol for milestone badge (`.star.fill` recommended; `.trophy.fill` for 50-completion milestone)
- Whether progress ring animates on appear (`.animation(.easeInOut(duration: 0.4), value: progress)` — recommended unless reduced motion)
- Chart X-axis label density and scroll behavior (compact / non-scrolling preferred)
- Exact padding and card layout of the progress section in GoalDetailView

### Deferred Ideas (OUT OF SCOPE)

- Cross-goal progress dashboard / leaderboard
- Persistent milestone history (UserDefaults or SwiftData)
- Streak counter on the progress ring
- Widget showing individual goal progress ring
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROG-01 | Each goal card displays a progress ring derived from `CompletionEvent` records — fills proportionally to recent completion frequency | ProgressRingView component (D-01/02/03), data flow from `@Query` via GoalListView |
| PROG-02 | GoalDetailView shows per-goal history: total completion count, last completed date, and a mini activity indicator | Swift Charts BarMark pattern, `progressSection` card insertion below `quoteCardSection` |
| PROG-03 | Micro-milestone celebrations fire at 5, 10, 25, 50 cumulative completions | Badge overlay animation on GoalRowView, `GoalViewModel` milestone hook in `toggleCompletion` |
| PROG-04 | Momentum score (completions in last 7 days ÷ 7, clamped 0–1) shown in GoalDetailView with color indicator | `ProgressViewModel.momentumScore()`, momentum row component |
| PROG-05 | All progress and momentum computations derive from existing `CompletionEvent` records — no new model required | Confirmed: no SchemaV4 needed; GoalRowView receives filtered `[CompletionEvent]` from parent |
</phase_requirements>

---

## Summary

Phase 12 adds visual progress feedback to the VitaminG goal list and goal detail views by surfacing `CompletionEvent` data that has been accumulated since Phase 3. All five requirements are achievable without any new SwiftData model — only new Swift files (one ViewModel, one component View, one test file) plus targeted modifications to two existing views and one ViewModel.

The central architectural challenge is **data flow**: `@Query` for `CompletionEvent` lives in parent views, but `GoalRowView` needs per-goal event counts. The cleanest pattern (verified against the existing `GoalListView` code) is to pass `[CompletionEvent]` downward to `GoalRowView` as a parameter, letting `ProgressViewModel` filter to the goal in question. `GoalDetailView` already has `let goal: Goal` and can access `goal.completionEvents` directly (the relationship is eager-loaded by SwiftData from the existing `@Relationship` on `Goal`).

The milestone celebration is the most coordination-heavy piece: it hooks into `GoalViewModel.toggleCompletion`, requires in-memory session state on `GoalViewModel`, and must animate a badge overlay inside `GoalRowView`. Because `GoalRowView` is a `private struct` inside `GoalListView.swift`, the milestone trigger state must bubble up from `GoalViewModel` back to the list in a way both views can observe — a `@State var firingMilestoneForGoalID: UUID?` on `GoalListView` threaded down to `GoalRowView`, set by `GoalViewModel` after the toggle, is the pattern consistent with existing code.

**Primary recommendation:** Implement `ProgressViewModel` as a pure `struct` (following `StreakEngine`/`GoalSorter`) with static or instance methods, add `ProgressRingView` as a new component file, add a `progressSection` card to `GoalDetailView`, and hook the milestone trigger into `GoalViewModel.toggleCompletion` — no new SwiftData model, no third-party dependencies.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Progress ring value computation | Service layer (`ProgressViewModel`) | — | Pure arithmetic on `[CompletionEvent]`; must be unit-testable without UI |
| Progress ring rendering | View layer (`ProgressRingView`) | — | Pure SwiftUI drawing; no business logic |
| Momentum score computation | Service layer (`ProgressViewModel`) | — | Same arithmetic as ring; reuse method |
| Chart data preparation | Service layer (`ProgressViewModel`) | — | Transforms `[CompletionEvent]` into `[DayCount]`; mirrors `buildHeatmapData` |
| Chart rendering | View layer (`GoalDetailView` / `progressSection`) | — | Native Swift Charts `Chart` view |
| Milestone threshold check | ViewModel (`GoalViewModel`) | — | Already owns `toggleCompletion`; milestone check is post-insert side effect |
| Milestone animation state | View state (`GoalRowView` via `GoalListView`) | — | `@State` in list, passed down — no global state needed |
| `CompletionEvent` data supply | View tier (`@Query` in `GoalListView` and `GoalDetailView`) | — | SwiftData `@Query` belongs in Views per MVVM constraint |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift Charts | iOS 16+ (Apple, bundled) | `BarMark` per-day completion chart in GoalDetailView | First-party, no SPM dep, already on the iOS version floor via project minimum iOS 17 |
| SwiftUI | iOS 17+ | `Circle().trim()` progress ring, badge overlay, `@Environment(\.accessibilityReduceMotion)` | Project-required; no alternative |
| Observation (`@Observable`) | iOS 17+ | `ProgressViewModel` observable pattern | Project standard; matches `StatsViewModel`, `GoalViewModel` |

[VERIFIED: codebase — SchemaV3.swift confirms iOS 17+ minimum; Swift Charts is available iOS 16+ so is a safe import; project already uses `import Charts` convention is confirmed by CONTEXT.md D-08]

### No New Dependencies

No SPM packages, CocoaPods, or Carthage entries are needed. [VERIFIED: CONTEXT.md + CLAUDE.md "no third-party dependencies" constraint]

---

## Architecture Patterns

### System Architecture Diagram

```
GoalListView
  @Query [CompletionEvent]  ─────────────────────────────────┐
  @Query [Goal]                                               │
  @State GoalViewModel                                        │
        │                                                     │
        ├─ GoalViewModel.toggleCompletion()                   │
        │        │                                            │
        │        ├─ insert CompletionEvent                    │
        │        ├─ check milestoneJustCrossed(for:)          │
        │        └─ set firingMilestoneForGoalID / threshold  │
        │                                                     ▼
        └─ GoalRowView(goal:, events: [CompletionEvent])  ◄───┘
                 │
                 ├─ ProgressViewModel.ringProgress(for:events:) ──► Double
                 ├─ ProgressRingView(progress:, tier:, isCompleted:)
                 └─ MilestoneBadge overlay (when milestone fires)

GoalDetailView
  let goal: Goal
  @State ProgressViewModel
        │
        ├─ goal.completionEvents (SwiftData relationship — no extra @Query needed)
        ├─ progressSection:
        │    ├─ Summary rows (totalCount, lastCompletedDate)
        │    ├─ Chart([DayCount]) — 30 days
        │    └─ Momentum row (score + color dot)
        └─ ProgressViewModel.chartData(for:events:) ──► [DayCount]
           ProgressViewModel.momentumScore(for:events:) ──► Double
```

### Recommended Project Structure

New files to create:

```
VitaminG/
├── Services/
│   └── ProgressViewModel.swift      # Pure struct — ring, momentum, chart data, milestone
├── Views/
│   └── Components/
│       └── ProgressRingView.swift   # 28pt circle trim view
└── VitaminGTests/
    └── ProgressViewModelTests.swift # Unit tests matching StreakEngineTests pattern
```

Modified files:

```
VitaminG/
├── Views/
│   ├── GoalListView.swift           # Pass [CompletionEvent] to GoalRowView; add @Query events; milestone state
│   └── GoalDetailView.swift         # Add progressSection between quoteCardSection and notesSection
└── ViewModels/
    └── GoalViewModel.swift          # Add milestone tracking Set<String> + milestoneJustCrossed()
```

### Pattern 1: ProgressViewModel — Pure Struct Following StreakEngine

**What:** Stateless struct with static or instance methods. All SwiftData types passed in as arrays. No `import SwiftData`, no `import SwiftUI` needed.

**When to use:** All progress/momentum computations; invoked from View's `.onAppear` or `.onChange` — same pattern as `StatsViewModel.refresh(events:goals:)`.

```swift
// Source: StreakEngine.swift (codebase) — mirror this pattern exactly
struct ProgressViewModel {

    struct DayCount: Identifiable {
        let id = UUID()
        let date: Date            // Calendar.current.startOfDay value
        let count: Int
    }

    // PROG-01, D-02: ring fill = completions in last 7 days / 7.0, clamped 0–1
    // Completed goals (isCompleted == true) return 1.0 immediately (D-02)
    func ringProgress(for goal: Goal, events: [CompletionEvent]) -> Double {
        guard !goal.isCompleted else { return 1.0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let windowStart = calendar.date(byAdding: .day, value: -6, to: today)!
        let goalEvents = events.filter { $0.goal?.id == goal.id }
        let count = goalEvents.compactMap { $0.completedAt }
            .filter { calendar.startOfDay(for: $0) >= windowStart }
            .count
        return min(Double(count) / 7.0, 1.0)
    }

    // PROG-04, D-04: momentum = completions in last 7 days / 7, clamped 0–1
    func momentumScore(for goal: Goal, events: [CompletionEvent]) -> Double {
        // Same arithmetic as ringProgress — DRY: delegate to ringProgress
        // (For completed goals, momentum reflects actual activity, not forced 1.0)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let windowStart = calendar.date(byAdding: .day, value: -6, to: today)!
        let goalEvents = events.filter { $0.goal?.id == goal.id }
        let count = goalEvents.compactMap { $0.completedAt }
            .filter { calendar.startOfDay(for: $0) >= windowStart }
            .count
        return min(Double(count) / 7.0, 1.0)
    }

    // PROG-02, D-08: last 30 calendar days, one DayCount per day
    // Days with 0 completions are included (empty bars preserve x-axis span)
    func chartData(for goal: Goal, events: [CompletionEvent]) -> [DayCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let goalEvents = events.filter { $0.goal?.id == goal.id }
        var dict: [Date: Int] = [:]
        for event in goalEvents {
            guard let date = event.completedAt else { continue }
            let day = calendar.startOfDay(for: date)
            dict[day, default: 0] += 1
        }
        return (0..<30).compactMap { offset -> DayCount? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayCount(date: day, count: dict[day] ?? 0)
        }.reversed()
    }

    // PROG-03, D-11: returns milestone threshold if just crossed (for GoalViewModel to call)
    static let milestoneThresholds: [Int] = [5, 10, 25, 50]

    func milestoneJustCrossed(count: Int, firedSet: Set<String>, goalID: UUID) -> Int? {
        for threshold in Self.milestoneThresholds {
            let key = "\(goalID.uuidString)-\(threshold)"
            if count == threshold && !firedSet.contains(key) {
                return threshold
            }
        }
        return nil
    }
}
```

[ASSUMED: The `momentumScore` for completed goals uses actual 7-day activity (not forced to 1.0 like ringProgress), because the momentum score should truthfully reflect recent activity independent of `isCompleted` state. This is consistent with CONTEXT.md D-06 which says "completions in the last 7 days" without the completed-goal override. The planner should confirm this interpretation.]

### Pattern 2: ProgressRingView — Circle().trim()

**What:** 28pt SwiftUI view using `Circle().trim(from:to:)` drawn clockwise from 12 o'clock via `-90°` rotation.

**When to use:** Drop-in replacement for tier pip in `GoalRowView`'s HStack trailing slot.

```swift
// Source: SwiftUI documentation + CONTEXT.md D-03
// [CITED: developer.apple.com/documentation/swiftui/circle]
import SwiftUI

struct ProgressRingView: View {
    let progress: Double     // 0.0 to 1.0
    let tier: GoalTier
    let isCompleted: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let completionGreen = Color(red: 0.063, green: 0.725, blue: 0.506)

    private var strokeColor: Color {
        isCompleted ? completionGreen : tier.color
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(tier.color.opacity(0.15), lineWidth: 3)
            // Progress arc — rotated so 0% starts at 12 o'clock
            Circle()
                .trim(from: 0, to: progress)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 0.4),
                    value: progress
                )
        }
        .frame(width: 28, height: 28)
        .accessibilityLabel(
            isCompleted
                ? "Goal complete"
                : "\(Int(progress * 100))% momentum this week"
        )
        .accessibilityAddTraits(.isStaticText)
    }
}
```

[VERIFIED: `Circle().trim(from:to:)` is a standard SwiftUI modifier available iOS 13+ — confirmed in Apple docs. The `-90°` rotation convention for "start at top" is standard in every SwiftUI circular progress implementation.]

### Pattern 3: Swift Charts BarMark — Per-Goal 30-Day History

**What:** `Chart` view consuming `[DayCount]` with one `BarMark` per day. Y-axis hidden; X-axis shows only last 7 days labeled.

**When to use:** Inside `progressSection` in `GoalDetailView`, 80pt fixed height.

```swift
// Source: Apple Swift Charts documentation
// [CITED: developer.apple.com/documentation/charts]
import Charts
import SwiftUI

// Inside progressSection:
Chart(chartDataItems) { item in
    BarMark(
        x: .value("Day", item.date, unit: .day),
        y: .value("Count", item.count)
    )
    .foregroundStyle(goal.tier.color)
}
.frame(height: 80)
.chartYAxis(.hidden)
.chartXAxis {
    AxisMarks(values: last7DayValues) { value in
        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
    }
}
.accessibilityLabel("30-day completion history bar chart")
.accessibilityValue("\(totalCompletions) completions in the last 30 days")
```

Key API notes:
- `BarMark(x: .value("Day", date, unit: .day), y: .value("Count", count))` — the `unit: .day` argument groups entries by calendar day and ensures the x-axis spans all 30 days even when some have zero counts. [VERIFIED: Apple Swift Charts documentation — `PlottableValue` with `unit:` parameter]
- `.chartYAxis(.hidden)` hides the y-axis completely. [VERIFIED: Apple Swift Charts documentation]
- `AxisMarks(values:)` takes an explicit array of `Date` values to label — pass the 7 most-recent dates from `chartData`. [VERIFIED: Apple Swift Charts documentation]

### Pattern 4: Milestone Badge Overlay in GoalRowView

**What:** A conditional SF Symbol overlay that animates into view, holds, then fades out. Pure overlay — no sheet, modal, or navigation interrupt.

**When to use:** After `GoalViewModel.toggleCompletion` sets a `firingMilestone` state on the parent view.

```swift
// Source: CONTEXT.md D-12, UI-SPEC §6
// @State var showMilestoneBadge = false (on GoalRowView)
// @State var badgeOpacity: Double = 0
// @State var badgeScale: CGFloat = 0.5

// Overlay added to GoalRowView's body:
.overlay(alignment: .center) {
    if showMilestoneBadge {
        Image(systemName: threshold == 50 ? "trophy.fill" : "star.fill")
            .font(.system(size: 48))
            .foregroundStyle(goal.tier.color)
            .scaleEffect(badgeScale)
            .opacity(badgeOpacity)
    }
}
.onChange(of: shouldFireMilestone) { _, fires in
    guard fires else { return }
    fireMilestoneBadge()
}

// Animation sequence (D-12):
private func fireMilestoneBadge() {
    showMilestoneBadge = true
    if reduceMotion {
        badgeOpacity = 1.0; badgeScale = 1.0
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.easeIn(duration: 0.2)) { badgeOpacity = 0 }
            try? await Task.sleep(for: .milliseconds(200))
            showMilestoneBadge = false
        }
    } else {
        withAnimation(.easeOut(duration: 0.2)) { badgeOpacity = 1; badgeScale = 1.2 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { badgeScale = 1.0 }
            try? await Task.sleep(for: .milliseconds(1500))
            withAnimation(.easeIn(duration: 0.3)) { badgeOpacity = 0 }
            try? await Task.sleep(for: .milliseconds(300))
            showMilestoneBadge = false; badgeScale = 0.5
        }
    }
    UIAccessibility.post(notification: .announcement,
                         argument: "Milestone reached: \(threshold) completions!")
}
```

[VERIFIED: `Task { @MainActor in try? await Task.sleep(for:) }` pattern is already used in `GoalRowView` (line 241–246 of GoalListView.swift) for the bounce animation — this is the established project pattern for async delays in views.]

### Pattern 5: GoalListView @Query Events — Data Flow to GoalRowView

**What:** `GoalListView` already has `@Query private var goals: [Goal]`. It needs a second `@Query private var events: [CompletionEvent]` (no predicate needed — all events; filtering by goal happens in `ProgressViewModel`).

**Data flow:**
- `GoalListView` passes `events` down to `GoalRowView` as `let events: [CompletionEvent]`
- `GoalRowView` calls `ProgressViewModel().ringProgress(for: goal, events: events)`
- Ring progress value computed inline; no ViewModel instance needed (pure function call)

**Alternative considered:** Add `@Query` inside `GoalRowView` filtered by goal ID — rejected because SwiftData `@Query` with predicates involving relationships can be slow when many rows are rendered. Passing the full array and filtering in the pure function is O(n) once per list render, not O(n) queries. [ASSUMED: this is the idiomatic approach; Apple's WWDC sessions recommend passing arrays down rather than adding @Query in list row views]

**GoalDetailView** approach: use `goal.completionEvents` directly (the SwiftData `@Relationship(deleteRule: .cascade, inverse:)` on `Goal` means the relationship array is available as `goal.completionEvents ?? []`). No additional `@Query` needed in `GoalDetailView`. [VERIFIED: SchemaV2.swift line 42–43 confirms the relationship is declared and will be available on the `Goal` object passed to `GoalDetailView`.]

### Pattern 6: Milestone State on GoalViewModel

**What:** `GoalViewModel` gains two new members:
1. `private var firedMilestones: Set<String> = []` — in-memory deduplication
2. `var pendingMilestone: (goalID: UUID, threshold: Int)? = nil` — observed by GoalListView

**When milestone fires:**
- `toggleCompletion` inserts `CompletionEvent`, then checks `completionEvents?.count`
- Calls `ProgressViewModel().milestoneJustCrossed(count:firedSet:goalID:)`
- If non-nil: adds key to `firedMilestones`, sets `pendingMilestone`
- `GoalListView` observes `viewModel.pendingMilestone` via `.onChange`

**Critical detail:** `GoalViewModel` is `@MainActor @Observable`. Reading `goal.completionEvents?.count` immediately after `context.insert(event)` will reflect the new count because SwiftData's `ModelContext` updates the in-memory object graph synchronously on the main actor before returning. No async operation is needed here. [ASSUMED: SwiftData in-memory count update is synchronous — consistent with observed behavior in Phase 3 tests, but not explicitly documented in Apple's API]

### Anti-Patterns to Avoid

- **@Query inside GoalRowView:** Adds one SwiftData fetch per visible row — creates scroll performance issues in lists. Pass events from the parent `GoalListView` instead.
- **Storing ProgressViewModel as `@StateObject`:** `@Observable` (Observation framework) uses `@State private var viewModel = ProgressViewModel()` — `@StateObject` is the old `ObservableObject` pattern. [VERIFIED: CLAUDE.md project constraint]
- **`import SwiftData` in ProgressViewModel:** Breaking the isolation pattern removes unit testability. ProgressViewModel must accept plain Swift arrays.
- **Animating Chart bars on appear:** Swift Charts applies entry animations by default in some configurations. For reduced motion compliance, do not add `.chartAnimation` or custom appear transitions to the bar chart.
- **Checking `goal.completionEvents?.count` before the context insert:** The count won't include the new event. Check after `context.insert(event)`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Circular progress arc | Custom `CAShapeLayer` / `UIBezierPath` | `Circle().trim(from:to:)` | SwiftUI-native, animates with `withAnimation`, zero bridging code |
| Bar chart | Custom `LazyHGrid` with scaled rectangles | `import Charts` + `BarMark` | Handles axis labels, accessibility, dynamic bar sizing, and date grouping automatically |
| Day-of-week axis labels | Manual date formatting in a ForEach | `AxisMarks(values:) { AxisValueLabel(format: .dateTime.weekday(.abbreviated)) }` | Swift Charts built-in date formatting respects locale |
| Milestone animation timer | `DispatchQueue.main.asyncAfter` | `Task { @MainActor in try? await Task.sleep(for:) }` | Established project pattern (GoalListView.swift line 241); modern concurrency |
| Accessibility announcement | Custom notification | `UIAccessibility.post(notification: .announcement, argument:)` | UIKit API; no SwiftUI equivalent needed |

**Key insight:** Swift Charts handles the zero-count bar problem automatically when using `unit: .day` on the x-axis PlottableValue — the framework reserves x-axis space for all 30 days even when `count == 0`. Custom solutions would need to explicitly handle this edge case.

---

## Common Pitfalls

### Pitfall 1: GoalRowView is `private struct` — milestone state can't be set from outside

**What goes wrong:** `GoalViewModel.pendingMilestone` is set, but `GoalRowView` is `private` — it cannot be directly observed or injected.

**Why it happens:** GoalRowView is declared `private struct GoalRowView` inside GoalListView.swift.

**How to avoid:** `GoalListView` observes `viewModel.pendingMilestone` via `.onChange`. When it fires, `GoalListView` passes a `Bool` or threshold down to the matching `GoalRowView` as a parameter. The `goalRow(for:)` helper already constructs `GoalRowView` inline — add a parameter `milestoneThreshold: Int?` and thread it through.

**Warning signs:** If you try to access `GoalRowView` from outside `GoalListView.swift` the compiler will reject it.

### Pitfall 2: Circle().trim() draws clockwise from 3 o'clock by default

**What goes wrong:** Without rotation, the arc starts at the 3 o'clock position, not 12 o'clock.

**Why it happens:** SwiftUI's coordinate system places 0° at the right (3 o'clock position) for trim.

**How to avoid:** Apply `.rotationEffect(.degrees(-90))` after `.stroke(...)`. [VERIFIED: standard SwiftUI pattern — rotation is always needed for 12 o'clock start]

**Warning signs:** Ring appears to start filling from the right side of the circle.

### Pitfall 3: Swift Charts requires iOS 16+ but AxisMarks API varies

**What goes wrong:** Some `AxisMarks` initializers added in iOS 17 may not compile on an iOS 16 deployment target.

**Why it happens:** The project minimum is iOS 17, so this is not an actual risk here. [VERIFIED: CLAUDE.md + SchemaV3.swift confirm iOS 17 minimum]

**How to avoid:** No action needed — iOS 17 minimum is safe for all Swift Charts APIs including `AxisMarks(values:)`.

### Pitfall 4: SwiftData relationship access on non-main actor

**What goes wrong:** Accessing `goal.completionEvents` on a background thread causes a SwiftData assertion failure or crash.

**Why it happens:** SwiftData model objects are not `Sendable` and must be accessed on the same actor as the `ModelContext`.

**How to avoid:** All `ProgressViewModel` methods are called from `@MainActor` views. `GoalViewModel` is `@MainActor`. No background access is introduced in this phase. [VERIFIED: CLAUDE.md + existing GoalViewModel pattern — all SwiftData access is on main actor]

### Pitfall 5: Momentum vs. Ring formula for completed goals

**What goes wrong:** Applying the `isCompleted == true → 1.0` override to momentum score (like the ring) means a goal completed once long ago shows "high" momentum even with no recent activity.

**Why it happens:** The ring shows a "completion" visual, so 1.0 is natural. Momentum should reflect actual recent activity.

**How to avoid:** `ringProgress` returns 1.0 for completed goals (D-02). `momentumScore` always uses raw 7-day arithmetic — even for completed goals. This distinction is subtle but important for the correctness of the momentum color dot. [ASSUMED: see Assumptions Log A1]

### Pitfall 6: Badge overlay renders behind List cell separator

**What goes wrong:** A `.overlay` on `GoalRowView` inside a `List` may be clipped by the list row's bounds or obscured by separators.

**Why it happens:** `List` rows clip their content to the row bounds by default.

**How to avoid:** The existing `GoalRowView` already uses `.scaleEffect(bounceScale)` and `.contentShape(Rectangle())` — the cell frame is the expected badge boundary. The badge at 48pt system font (`Image(systemName:).font(.system(size: 48))`) will likely extend beyond the 44+pt row height, which means it needs `.clipped(false)` or `.allowsHitTesting(false)` to prevent clipping. Add `.clipped(false)` or use `.zIndex(1)` on the overlay to ensure it renders above adjacent rows. [ASSUMED: list row clipping behavior — needs runtime verification]

### Pitfall 7: `unit: .day` grouping in Swift Charts with Date values

**What goes wrong:** Passing a raw `Date` (not start-of-day) to `BarMark(x: .value("Day", date, unit: .day))` may result in chart grouping different events onto the same or different bars unexpectedly.

**Why it happens:** Swift Charts groups by calendar day when `unit: .day` is specified, but the grouping uses the Charts framework's internal calendar (usually `.current`). Pre-converting to `startOfDay` in `ProgressViewModel.chartData` avoids ambiguity.

**How to avoid:** `chartData` returns `DayCount` structs where `date` is already `calendar.startOfDay(for:)`. Pass pre-normalized dates to the Chart. [VERIFIED: StreakEngine and StatsViewModel both use `startOfDay` normalization for the same reason]

---

## Code Examples

### GoalListView — Adding @Query events and threading to GoalRowView

```swift
// Source: GoalListView.swift (existing) — minimal addition
// [VERIFIED: codebase GoalListView.swift]

// ADD to GoalListView:
@Query private var events: [CompletionEvent]          // line after @Query private var goals
@State private var pendingMilestone: (goalID: UUID, threshold: Int)? = nil

// MODIFY goalRow(for:) helper — add milestone parameter:
private func goalRow(for goal: Goal) -> some View {
    let milestoneThreshold: Int? = pendingMilestone?.goalID == goal.id
        ? pendingMilestone?.threshold : nil
    return NavigationLink(value: AppRoute.goalDetail(goal)) {
        GoalRowView(
            goal: goal,
            events: events,          // pass full events array
            milestoneThreshold: milestoneThreshold,
            onToggle: {
                viewModel.toggleCompletion(goal: goal, context: modelContext)
            }
        )
    }
    // ... existing listRowBackground, swipeActions unchanged
    .onChange(of: viewModel.pendingMilestone?.goalID) { _, _ in
        pendingMilestone = viewModel.pendingMilestone
        viewModel.pendingMilestone = nil   // consume the event
    }
}
```

### GoalDetailView — Adding progressSection

```swift
// Source: GoalDetailView.swift (existing sections pattern)
// [VERIFIED: codebase GoalDetailView.swift]

// ADD import Charts at top of file

// ADD computed properties:
private var goalEvents: [CompletionEvent] {
    goal.completionEvents ?? []
}
private var vm: ProgressViewModel { ProgressViewModel() }
private var totalCompletions: Int { goalEvents.count }
private var lastCompletedDate: Date? {
    goalEvents.compactMap { $0.completedAt }.max()
}

// ADD progressSection between quoteCardSection and notesSection in body VStack:
// VStack { headerSection; publicToggleSection; quoteCardSection; progressSection; notesSection; actionsSection }

@ViewBuilder
private var progressSection: some View {
    let chartItems = vm.chartData(for: goal, events: goalEvents)
    let score = vm.momentumScore(for: goal, events: goalEvents)
    let momentumColor: Color = score >= 0.5 ? .green : score >= 0.1 ? .orange : .secondary
    let last7Dates: [Date] = chartItems.suffix(7).map { $0.date }

    VStack(alignment: .leading, spacing: 8) {
        Text("Progress History")
            .font(.footnote.weight(.semibold)).fontDesign(.rounded)
            .foregroundStyle(.secondary)

        HStack {
            Text("Total completions").font(.body).fontDesign(.rounded)
            Spacer()
            Text("\(totalCompletions)").font(.body.weight(.semibold)).fontDesign(.rounded)
        }
        HStack {
            Text("Last completed").font(.body).fontDesign(.rounded)
            Spacer()
            Text(lastCompletedDate.map {
                $0.formatted(date: .abbreviated, time: .omitted)
            } ?? "Never")
            .font(.body.weight(.semibold)).fontDesign(.rounded)
        }

        Chart(chartItems) { item in
            BarMark(x: .value("Day", item.date, unit: .day),
                    y: .value("Count", item.count))
                .foregroundStyle(goal.tier.color)
        }
        .frame(height: 80)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: last7Dates) { _ in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .accessibilityLabel("30-day completion history bar chart")
        .accessibilityValue("\(totalCompletions) completions in the last 30 days")

        HStack(spacing: 8) {
            Circle().fill(momentumColor).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 4) {
                Text("Momentum").font(.body).fontDesign(.rounded)
                Text("completions in the last 7 days")
                    .font(.caption).fontDesign(.rounded).foregroundStyle(.secondary)
            }
            Spacer()
            Text(String(format: "%.2f", score))
                .font(.body.weight(.semibold)).fontDesign(.rounded)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Momentum score \(String(format: "%.2f", score)). \(score >= 0.5 ? "High" : score >= 0.1 ? "Medium" : "Inactive"). Based on completions in the last 7 days.")
    }
    .padding(16)
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal)
}
```

### GoalViewModel — Milestone Tracking Addition

```swift
// Source: GoalViewModel.swift (existing toggleCompletion)
// [VERIFIED: codebase GoalViewModel.swift lines 99–107]

// ADD to GoalViewModel:
private(set) var pendingMilestone: (goalID: UUID, threshold: Int)? = nil
private var firedMilestones: Set<String> = []
private let progressVM = ProgressViewModel()

// MODIFY toggleCompletion:
func toggleCompletion(goal: Goal, context: ModelContext) {
    goal.completed.toggle()
    if goal.completed {
        let event = CompletionEvent(goal: goal)
        context.insert(event)
        // Milestone check — count after insert
        let count = goal.completionEvents?.count ?? 0
        if let threshold = progressVM.milestoneJustCrossed(
            count: count, firedSet: firedMilestones, goalID: goal.id) {
            let key = "\(goal.id.uuidString)-\(threshold)"
            firedMilestones.insert(key)
            pendingMilestone = (goalID: goal.id, threshold: threshold)
        }
    }
    rescheduleNotification(context: context)
    reloadWidgetTimelines()
}
```

---

## Exact File Modification List

| File | Action | Change Summary |
|------|--------|----------------|
| `Views/Components/ProgressRingView.swift` | CREATE | New component; `Circle().trim()` ring view, 28pt, reduced-motion gate |
| `Services/ProgressViewModel.swift` | CREATE | Pure struct; `ringProgress`, `momentumScore`, `chartData`, `milestoneJustCrossed` |
| `VitaminGTests/ProgressViewModelTests.swift` | CREATE | Unit tests matching StreakEngineTests pattern |
| `Views/GoalListView.swift` | MODIFY | Add `@Query events`, pass to `GoalRowView`; add milestone state; replace tier pip with `ProgressRingView`; wire badge overlay |
| `Views/GoalDetailView.swift` | MODIFY | Add `import Charts`; add `progressSection` between `quoteCardSection` and `notesSection` |
| `ViewModels/GoalViewModel.swift` | MODIFY | Add `pendingMilestone`, `firedMilestones`, `progressVM`; update `toggleCompletion` |

**No other files need modification.** SchemaV2, SchemaV3, migration plan, ModelContainerFactory — all unchanged (PROG-05 confirmed: no new model).

---

## Risk Assessment

### Risk 1: CloudKit constraint violations — NONE

No new SwiftData model properties or relationships are added. No `@Attribute(.unique)` is used. Existing `Goal.completionEvents` relationship is unchanged. CloudKit schema is not affected. [VERIFIED: CONTEXT.md D-15 "No new SwiftData model is needed"; SchemaV3.swift shows the current schema ceiling]

### Risk 2: Build breakage from GoalRowView signature change — LOW-MEDIUM

`GoalRowView` is `private struct` — only used inside `GoalListView.swift`. Adding parameters (`events:`, `milestoneThreshold:`) only affects the one `goalRow(for:)` helper. No other file references `GoalRowView` directly. Risk is isolated to one file.

**Mitigation:** Update the `GoalRowView` initializer and `goalRow(for:)` helper atomically in one edit. The compiler will catch any missed call site immediately.

### Risk 3: Performance — filtering events per row — LOW

`GoalListView` fetches all `CompletionEvent` records via `@Query`. Typical user has tens to hundreds of completion events (not millions). Filtering by `goal.id` in `ProgressViewModel.ringProgress()` is O(n) where n = total events. For normal usage (< 500 events) this is not a performance concern. [ASSUMED: based on typical user data volumes for a personal goal tracker; no benchmark performed]

### Risk 4: Badge overlay clipping by List row bounds — MEDIUM

The 48pt SF Symbol badge may extend beyond the `GoalRowView` frame inside a `List`. Requires runtime testing.

**Mitigation:** Apply `.zIndex(1)` to the overlay and verify on device. The existing `bounceScale` animation already confirms the view's layer participates in list rendering correctly, but a 48pt overlay is larger than any existing element.

### Risk 5: Swift Charts x-axis label rendering with 30-day data — LOW

Charts with 30 bars and only 7 labeled may display oddly on very narrow iPhone screens (iPhone SE). The compact 80pt height also constrains readability.

**Mitigation:** The 80pt height is a locked decision (D-10). The x-axis showing only 7 labels (one per day in the last week) is Claude's Discretion. If labels overlap, use `AxisMarks(preset: .automatic, values: .stride(by: .day, count: 7))` which lets Charts auto-select label density.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17 / Swift 5.9 | Project already uses `@Observable`; `ProgressViewModel` follows this |
| `CALayer` circular progress | `Circle().trim()` + SwiftUI animation | iOS 14+ | SwiftUI-native; animates with `value:` binding automatically |
| `UIKit` chart libraries (Charts, etc.) | Swift Charts (Apple first-party) | iOS 16 | No SPM dep; matches project constraint |
| `DispatchQueue.main.asyncAfter` | `Task { @MainActor in try? await Task.sleep(for:) }` | Swift 5.7+ | Project already uses this pattern (GoalListView.swift line 241) |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `momentumScore` returns raw 7-day arithmetic even for `isCompleted == true` goals (not forced to 1.0 like `ringProgress`) | Pattern 1, Pitfall 5 | If wrong: completed goals with no recent activity show falsely high momentum (green dot) |
| A2 | SwiftData `context.insert(event)` synchronously updates `goal.completionEvents?.count` on the main actor before the next line of `toggleCompletion` executes | Pitfall 4, GoalViewModel pattern | If wrong: milestone check reads stale count (off by one) — milestone badge fires one toggle late |
| A3 | Passing `[CompletionEvent]` (full unfiltered array) down to `GoalRowView` is performant for typical user data volumes | Pattern 5, Risk 3 | If wrong for users with thousands of events: ring computation causes scroll jank |
| A4 | `GoalRowView`'s badge overlay at `.font(.system(size: 48))` will not be clipped by `List` row bounds without explicit `.zIndex` | Pitfall 6, Risk 4 | If wrong: badge is invisible; needs runtime fix with `clipped(false)` or `zIndex` |
| A5 | `.chartXAxis` with `AxisMarks(values: last7Dates)` compiles and renders correctly with iOS 17 deployment target | Pattern 3 | If wrong: use `AxisMarks(preset: .automatic, values: .stride(by: .day, count: 7))` as fallback |

---

## Open Questions

1. **Momentum score for completed goals**
   - What we know: `ringProgress` is explicitly forced to 1.0 for completed goals (D-02). Momentum is described as "completions in last 7 days / 7" (D-04) without a completed-goal override.
   - What's unclear: Should a goal completed long ago (but marked `isCompleted`) show green momentum even with zero recent completions?
   - Recommendation: Use raw 7-day arithmetic for momentum (Assumption A1). This is more honest and avoids a misleading green dot on stale goals. Planner should note this distinction in the task.

2. **GoalRowView badge clipping**
   - What we know: SwiftUI `List` rows clip content by default to the row bounds.
   - What's unclear: Whether `zIndex` or `clipped(false)` is required — needs runtime test.
   - Recommendation: Add `.zIndex(1)` to the overlay as a precaution; verify in Wave 1.

3. **GoalDetailView completionEvents access pattern**
   - What we know: `goal.completionEvents` is available via the `@Relationship` declared in SchemaV2. `GoalDetailView` receives `let goal: Goal`.
   - What's unclear: Whether SwiftData lazy-loads the relationship or requires an explicit fetch when the Goal is passed across NavigationLink.
   - Recommendation: Use `goal.completionEvents ?? []` directly. If empty unexpectedly, add a `@Query` with a predicate on `goal.id` as a fallback. [ASSUMED: SwiftData eager-loads relationships for in-memory objects — behavior may differ for objects loaded across navigation boundaries]

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (Apple, bundled with Xcode) |
| Config file | Xcode scheme (no pytest.ini equivalent) |
| Quick run command | `xcodebuild test -scheme VitaminG -destination "platform=iOS Simulator,name=iPhone 15"` |
| Full suite command | Same (all tests in one target) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | File |
|--------|----------|-----------|------|
| PROG-01 | `ringProgress` returns 0 for 0 events, clamped values for partial, 1.0 for full | unit | `ProgressViewModelTests.swift` (Wave 0 create) |
| PROG-01 | `ringProgress` returns 1.0 when `isCompleted == true` regardless of events | unit | `ProgressViewModelTests.swift` |
| PROG-02 | `chartData` returns 30 `DayCount` items, days with 0 events have count 0 | unit | `ProgressViewModelTests.swift` |
| PROG-02 | `chartData` filters to the goal's events only (not other goals' events) | unit | `ProgressViewModelTests.swift` |
| PROG-03 | `milestoneJustCrossed` returns correct threshold at 5, 10, 25, 50 | unit | `ProgressViewModelTests.swift` |
| PROG-03 | `milestoneJustCrossed` returns `nil` when threshold already in firedSet | unit | `ProgressViewModelTests.swift` |
| PROG-03 | `milestoneJustCrossed` returns `nil` for counts that don't match any threshold | unit | `ProgressViewModelTests.swift` |
| PROG-04 | `momentumScore` returns 0 for 0 events in 7 days | unit | `ProgressViewModelTests.swift` |
| PROG-04 | `momentumScore` returns correct value for N events (N/7, clamped to 1.0) | unit | `ProgressViewModelTests.swift` |
| PROG-04 | `momentumScore` excludes events older than 7 days | unit | `ProgressViewModelTests.swift` |
| PROG-05 | No new SwiftData model types in schema | unit | `SchemaV1Tests.swift` (existing model count assertion) |

### Sampling Rate

- **Per task commit:** Build (Xcode build succeeds)
- **Per wave merge:** `xcodebuild test -scheme VitaminG` — all tests green
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `VitaminGTests/ProgressViewModelTests.swift` — must be created; covers PROG-01 through PROG-04
- [ ] Verify `SchemaV1Tests` model count assertion still passes (no accidental model addition)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | No | No user-input fields added; `Int` count and `Double` score are computed from trusted local SwiftData records |
| V6 Cryptography | No | — |

**No security-relevant surface area introduced.** All data flows from local SwiftData `CompletionEvent` records. No network calls, no user text input, no new persistence layer. [VERIFIED: CONTEXT.md confirms no new model; CLAUDE.md security constraint is "all String inputs validated" — no new String inputs added]

---

## Sources

### Primary (HIGH confidence)
- `VitaminG/VitaminG/VitaminG/Services/StreakEngine.swift` — Calendar arithmetic pattern; `startOfDay` normalization; pure struct design
- `VitaminG/VitaminG/VitaminG/ViewModels/StatsViewModel.swift` — `refresh(events:goals:)` signature pattern; `buildHeatmapData` exact template
- `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift` — `GoalRowView` structure; existing `Task { @MainActor }` delay pattern; `@Query` usage
- `VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift` — section card pattern; `systemBackground` + `RoundedRectangle(cornerRadius: 12)` template
- `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` — `toggleCompletion` hook point; `@MainActor @Observable` pattern
- `VitaminG/VitaminG/VitaminG/Models/SchemaV2.swift` — `CompletionEvent.completedAt`, `Goal.completionEvents` relationship confirmed
- `VitaminG/VitaminG/VitaminG/Models/SchemaV3.swift` — Current schema version (V3); confirmed no SchemaV4 needed
- `VitaminG/VitaminG/VitaminGTests/StreakEngineTests.swift` — Test file structure; `ModelContainerFactory.makeContainer(inMemory: true)` pattern; `makeEvent(dayOffset:)` helper pattern
- `.planning/phases/12-goal-progress-visualization/12-CONTEXT.md` — All locked decisions D-01 through D-16
- `.planning/phases/12-goal-progress-visualization/12-UI-SPEC.md` — Component inventory, animation sequences, VoiceOver labels, copywriting

### Secondary (MEDIUM confidence)
- `[CITED: developer.apple.com/documentation/charts]` — Swift Charts `BarMark`, `AxisMarks`, `chartYAxis(.hidden)` API
- `[CITED: developer.apple.com/documentation/swiftui/circle]` — `Circle().trim(from:to:)` SwiftUI API

### Tertiary (LOW confidence)
- [ASSUMED] SwiftData lazy vs. eager relationship loading behavior for objects passed via NavigationLink (Open Question 3)
- [ASSUMED] `context.insert()` synchronous count update (Assumption A2)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Swift Charts and SwiftUI are Apple first-party; project already targets iOS 17
- Architecture: HIGH — all patterns verified against live codebase files
- Pitfalls: HIGH/MEDIUM — 4 verified against code; 2 assumed (badge clipping, list row behavior)
- Test strategy: HIGH — mirrors StreakEngineTests exactly

**Research date:** 2026-05-03
**Valid until:** 2026-06-03 (stable Apple frameworks; valid indefinitely for codebase patterns)
