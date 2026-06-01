# Phase 26: Analytics Dashboard - Pattern Map

**Mapped:** 2026-06-01
**Files analyzed:** 10 (7 new, 3 modified)
**Analogs found:** 10 / 10

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `ViewModels/AnalyticsViewModel.swift` | viewmodel | CRUD / transform | `ViewModels/StatsViewModel.swift` | exact |
| `Views/AnalyticsView.swift` | view (screen) | request-response | `Views/StatsView.swift` | exact |
| `Views/AllTimeHeatmapView.swift` | view (component) | transform | `Views/HeatmapView.swift` | exact |
| `Views/GoalAllTimeHeatmapView.swift` | view (screen) | request-response | `Views/StatsView.swift` + `Views/HeatmapView.swift` | role-match |
| `Services/CSVExportService.swift` | service | transform | `Services/ConsistencyEngine.swift` | exact |
| `VitaminGTests/Phase26AnalyticsViewModelTests.swift` | test | — | `VitaminGTests/NotificationSchedulerPhase25Tests.swift` | exact |
| `VitaminGTests/Phase26CSVExportServiceTests.swift` | test | — | `VitaminGTests/NotificationSchedulerPhase25Tests.swift` | exact |
| `Navigation/AppRoute.swift` (modify) | route | — | self | exact |
| `Views/ContentView.swift` (modify) | navigation | — | self | exact |
| `Views/StatsView.swift` (modify) | view (screen) | — | self | exact |

---

## Pattern Assignments

### `ViewModels/AnalyticsViewModel.swift` (viewmodel, CRUD / transform)

**Analog:** `VitaminG/VitaminG/VitaminG/ViewModels/StatsViewModel.swift` (lines 1–79)

**Imports pattern** (lines 1–3):
```swift
import SwiftData
import Observation
import Foundation
```

**Class declaration pattern** (lines 13–15):
```swift
@MainActor
@Observable
final class StatsViewModel {
```
Copy verbatim; rename to `AnalyticsViewModel`.

**Published state pattern** (lines 19–30):
```swift
// Each computed output is a plain var with a default — no @Published needed
var globalStreak: Int = 0
var tierStreaks: [GoalTier: Int] = [:]
var heatmapData: [Date: Int] = [:]
```
For AnalyticsViewModel, declare:
```swift
var weeklyBuckets: [BucketItem] = []
var monthlyBuckets: [BucketItem] = []
var heatmapDataByGoal: [UUID: [Date: Int]] = [:]
var allGoals: [Goal] = []
```

**Refresh method signature pattern** (lines 36–54):
```swift
func refresh(events: [CompletionEvent], goals: [Goal], frozenDates: [Date] = []) {
    globalStreak = StreakEngine.currentStreak(from: events, frozenDates: frozenDates)
    // ...
    heatmapData = buildHeatmapData(from: events, frozenDates: frozenDates)
}
```
`AnalyticsViewModel.refresh()` follows the same signature — called from `AnalyticsView.onAppear` and `.onChange(of: events.count)`.

**Heatmap data builder pattern** (lines 62–78):
```swift
private func buildHeatmapData(from events: [CompletionEvent], frozenDates: [Date] = []) -> [Date: Int] {
    var dict: [Date: Int] = [:]
    for event in events {
        guard let date = event.completedAt else { continue }
        let day = Calendar.current.startOfDay(for: date)
        dict[day, default: 0] += 1
    }
    // Sentinel -1 for frozen dates with no real check-in
    for frozen in frozenDates {
        let day = Calendar.current.startOfDay(for: frozen)
        if dict[day] == nil {
            dict[day] = -1
        }
    }
    return dict
}
```
For per-goal heatmap, call this same logic filtered to a single goal's events:
```swift
private func buildGoalHeatmapData(goal: Goal, events: [CompletionEvent], frozenDates: [Date]) -> [Date: Int] {
    let goalEvents = events.filter { $0.goal?.persistentModelID == goal.persistentModelID }
    // then identical dict-building loop as above
}
```

**D-05 bucket builder pattern** (adapted from `ConsistencyEngine.score`, lines 37–68):
Bucket completion rate = `(unique calendar days with any event in period) / (total calendar days in period)`. Use `Calendar.current.dateInterval(of: .weekOfYear, for:)` for week boundaries. Both `weeklyBuckets` and `monthlyBuckets` are computed in `refresh()` so that the view can switch granularity without triggering recomputation (avoids Pitfall 2 from RESEARCH.md).

**BucketItem supporting type** — declare as a private or internal struct in the same file:
```swift
struct BucketItem: Identifiable {
    let id = UUID()
    let periodStart: Date
    let completionRate: Double  // 0.0–1.0
}
```

**Heatmap start date guard pattern** (RESEARCH.md Pitfall 1):
```swift
let start = goal.creationDate
    ?? goal.completionEvents?.compactMap(\.completedAt).min()
    ?? Calendar.current.date(byAdding: .day, value: -90, to: Date())!
```
Use this in `buildGoalHeatmapData` to guard against nil `creationDate`.

---

### `Views/AnalyticsView.swift` (view / screen, request-response)

**Analog:** `VitaminG/VitaminG/VitaminG/Views/StatsView.swift` (lines 1–167)

**Imports pattern** (lines 1–4):
```swift
import SwiftUI
import SwiftData
import Charts
```
Add `Charts` (already present in the project, imported in `GoalDetailView.swift` line 3).

**@Query + @State ViewModel pattern** (lines 13–18):
```swift
@Query private var events: [CompletionEvent]
@Query private var goals: [Goal]

@State private var viewModel = StatsViewModel()
@State private var freezeService = StreakFreezeService()
```
For AnalyticsView:
```swift
@Query private var events: [CompletionEvent]
@Query private var goals: [Goal]

@State private var viewModel = AnalyticsViewModel()
@State private var freezeService = StreakFreezeService()
```
Do NOT pass events/goals from StatsView — give AnalyticsView its own `@Query` declarations per established convention.

**Navigation title pattern** (lines 35–36):
```swift
.navigationTitle("Stats")
.navigationBarTitleDisplayMode(.large)
```
Use `.navigationTitle("Analytics")` with `.navigationBarTitleDisplayMode(.large)` per D-02.

**onAppear / onChange refresh pattern** (lines 37–45):
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
Copy this pattern verbatim; replace `StatsViewModel` with `AnalyticsViewModel`.

**ScrollView VStack layout pattern** (lines 21–33):
```swift
ScrollView {
    VStack(spacing: 20) {
        // ...sections...
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 20)
}
.background(Color(UIColor.systemGroupedBackground))
```
AnalyticsView replicates this exact outer structure.

**Section card pattern** (lines 146–166 — heatmapSection):
```swift
VStack(alignment: .leading, spacing: 12) {
    Text("Activity")
        .font(.title3.weight(.semibold))
        .padding(.horizontal, 4)

    ZStack {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(UIColor.secondarySystemGroupedBackground))

        VStack(alignment: .leading, spacing: 10) {
            // ...content...
        }
        .padding(16)
    }
}
```
Use this same ZStack + RoundedRectangle card wrapping pattern for the chart section and the goal list section in AnalyticsView.

**BarMark chart pattern** (`GoalDetailView.swift` lines 452–468):
```swift
Chart(chartItems) { item in
    BarMark(
        x: .value("Day", item.date, unit: .day),
        y: .value("Count", item.count)
    )
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
```
For AnalyticsView, adapt as follows:
```swift
// granularity is @State private var granularity: ChartGranularity = .weekly
Chart(granularity == .weekly ? viewModel.weeklyBuckets : viewModel.monthlyBuckets) { item in
    BarMark(
        x: .value("Period", item.periodStart, unit: granularity == .weekly ? .weekOfYear : .month),
        y: .value("Rate", item.completionRate)
    )
    .foregroundStyle(VGTheme.accentTerra)
}
.chartYAxis {
    AxisMarks(format: .percent)
}
.frame(height: 180)
.accessibilityLabel("Completion rate trends bar chart")
```

**Segmented Picker pattern** (standard iOS; no codebase analog needed):
```swift
Picker("Granularity", selection: $granularity) {
    Text("Weekly").tag(ChartGranularity.weekly)
    Text("Monthly").tag(ChartGranularity.monthly)
}
.pickerStyle(.segmented)
```

**ShareLink pattern** (`ProfileView.swift` lines 471–478):
```swift
if let url = viewModel.shareURL {
    ShareLink(item: url, subject: Text("Vitamin G Profile"),
              message: Text("Check out my goals on Vitamin G!")) {
        Label("Share Profile", systemImage: "square.and.arrow.up")
            .font(.body.weight(.semibold)).fontDesign(.rounded)
            .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .tint(VGTheme.terra)
}
```
For AnalyticsView CSV export:
```swift
let csvString = CSVExportService.buildGlobalCSV(
    events: events,
    goals: goals,
    frozenDates: freezeService.frozenDates
)
let dateStamp = Date().formatted(.iso8601.year().month().day())
ShareLink(
    item: csvString,
    preview: SharePreview("vitamin-g-history-\(dateStamp).csv",
                          image: Image(systemName: "doc.text"))
) {
    Label("Export CSV", systemImage: "square.and.arrow.up")
        .font(.body.weight(.semibold)).fontDesign(.rounded)
        .frame(maxWidth: .infinity)
}
.buttonStyle(.borderedProminent)
.tint(VGTheme.accentTerra)
```

---

### `Views/AllTimeHeatmapView.swift` (view / component, transform)

**Analog:** `VitaminG/VitaminG/VitaminG/Views/HeatmapView.swift` (lines 1–60)

**Struct declaration and parameters** (lines 11–17):
```swift
struct HeatmapView: View {
    let data: [Date: Int]
    var windowDays: Int = 90
```
AllTimeHeatmapView mirrors this pure-component shape:
```swift
struct AllTimeHeatmapView: View {
    let data: [Date: Int]      // pre-built by AnalyticsViewModel
    let startDate: Date        // goal.creationDate (with nil-fallback applied before passing)
```
No `@Query`, no ViewModel — receives pre-computed data only.

**Cell rendering pattern — verbatim copy** (lines 31–44):
```swift
ZStack {
    RoundedRectangle(cornerRadius: 2)
        .fill(cellColor(for: data[day] ?? 0))
        .frame(width: 12, height: 12)
    if data[day] == -1 {
        Image(systemName: "snowflake")
            .font(.system(size: 7))
            .foregroundStyle(Color.blue)
            .accessibilityLabel("Streak freeze")
    }
}
```
Copy this ZStack cell structure exactly. The only axis change is the outer container.

**cellColor function — verbatim copy** (lines 51–59):
```swift
private func cellColor(for count: Int) -> Color {
    switch count {
    case -1:      return Color.blue.opacity(0.25)
    case 0:       return Color(.systemFill)
    case 1:       return .green.opacity(0.3)
    case 2:       return .green.opacity(0.6)
    default:      return .green
    }
}
```
Copy this function character-for-character into `AllTimeHeatmapView`. Do NOT extract to a shared helper — the views are intentionally separate (RESEARCH.md anti-pattern note).

**Axis change: LazyVGrid → LazyHStack**
The existing `HeatmapView` body (lines 27–45) uses `LazyVGrid(columns: Array(repeating: GridItem(.fixed(12), spacing: 3), count: 7), spacing: 3)`. AllTimeHeatmapView replaces this with:
```swift
ScrollViewReader { proxy in
    ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top, spacing: 3) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                VStack(spacing: 3) {
                    ForEach(week, id: \.self) { day in
                        // ... same ZStack cell as above ...
                    }
                }
                .id(index)
            }
        }
        .padding(.horizontal, 8)
    }
    .onAppear {
        proxy.scrollTo(weeks.count - 1, anchor: .trailing)
    }
}
```
Each outer `VStack` column = one ISO week (7 day cells). Each column is tagged with `index` for `ScrollViewReader`.

**weeks computed property** (no analog — new logic):
```swift
private var weeks: [[Date]] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    var result: [[Date]] = []
    var weekStart = calendar.dateInterval(of: .weekOfYear, for: startDate)?.start ?? startDate
    while weekStart <= today {
        let days = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)
        }
        result.append(days)
        weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? today
    }
    return result
}
```
Cap each day cell at `<= today` during render to avoid showing future grey cells in the current partial week (RESEARCH.md Pitfall 4).

---

### `Views/GoalAllTimeHeatmapView.swift` (view / screen, request-response)

**Analog:** `Views/StatsView.swift` (overall screen structure) + `Views/AllTimeHeatmapView.swift` (hosts the component)

This is the push-navigation destination when a user taps a goal in AnalyticsView. It wraps `AllTimeHeatmapView` with a standard navigation screen scaffold.

**Screen scaffold pattern** (from `StatsView.swift` lines 20–46):
```swift
struct GoalAllTimeHeatmapView: View {
    let goal: Goal
    // Receives pre-computed heatmap data from AnalyticsView/ViewModel
    let heatmapData: [Date: Int]
    let frozenDates: [Date]

    private var startDate: Date {
        goal.creationDate
            ?? goal.completionEvents?.compactMap(\.completedAt).min()
            ?? Calendar.current.date(byAdding: .day, value: -90, to: Date())!
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AllTimeHeatmapView(data: heatmapData, startDate: startDate)
                // Per-goal ShareLink (CSV export)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(goal.title)
        .navigationBarTitleDisplayMode(.large)
    }
}
```

**Per-goal ShareLink** — same pattern as global export in AnalyticsView, but scoped:
```swift
let csvString = CSVExportService.buildGoalCSV(
    goal: goal,
    events: /* filter passed-in or via @Query */,
    frozenDates: frozenDates
)
ShareLink(item: csvString, preview: SharePreview("vitamin-g-\(goal.title)-\(dateStamp).csv")) {
    Label("Export CSV", systemImage: "square.and.arrow.up")
}
```

---

### `Services/CSVExportService.swift` (service, transform)

**Analog:** `VitaminG/VitaminG/VitaminG/Services/ConsistencyEngine.swift` (lines 1–93)

**Pure struct with static methods pattern** (lines 1–14):
```swift
import Foundation

// MARK: - ConsistencyEngine

/// Standalone testable struct that computes a weighted consistency score
/// from CompletionEvent records over a 30-day rolling window.
///
/// Design constraints:
/// - Pure function: no side effects, no SwiftUI/SwiftData dependency
struct ConsistencyEngine {
    // only static methods — no instance state
    static func score(events: [CompletionEvent], asOf: Date = .now) -> Int { ... }
    static func recentDays(events: [CompletionEvent], asOf: Date = .now) -> [Bool] { ... }
}
```
`CSVExportService` uses the identical pattern — `import Foundation` only, no `SwiftUI`, no `SwiftData`, pure `struct` with `static` methods:
```swift
import Foundation

// MARK: - CSVExportService

/// Pure struct service — no SwiftUI or SwiftData dependency.
/// Builds an in-memory CSV string for export via ShareLink.
/// Columns: goal_name, date, tier, is_frozen.
/// Date format: ISO 8601 YYYY-MM-DD (D-11).
struct CSVExportService {
    static func buildGlobalCSV(events: [CompletionEvent], goals: [Goal], frozenDates: [Date]) -> String { ... }
    static func buildGoalCSV(goal: Goal, events: [CompletionEvent], frozenDates: [Date]) -> String { ... }
}
```

**Static method pattern** (ConsistencyEngine lines 37–69):
```swift
static func score(events: [CompletionEvent], asOf: Date = .now) -> Int {
    let cal = Calendar.current
    let today = cal.startOfDay(for: asOf)
    let completedDays: Set<Date> = Set(
        events.compactMap { $0.completedAt }
              .map { cal.startOfDay(for: $0) }
              .filter { ... }
    )
    // ...pure computation, returns value type...
    return Int(...)
}
```
`buildGlobalCSV` follows the same shape: takes value-type inputs, returns a `String`, no side effects.

**CSV construction pattern** (RESEARCH.md Pattern 3):
```swift
static func buildGlobalCSV(events: [CompletionEvent], goals: [Goal], frozenDates: [Date]) -> String {
    var rows = ["goal_name,date,tier,is_frozen"]
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]   // YYYY-MM-DD only

    let frozenDaySet = Set(frozenDates.map { Calendar.current.startOfDay(for: $0) })

    let sorted = events.sorted {
        ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast)
    }
    for event in sorted {
        guard let date = event.completedAt else { continue }
        let goalName = (event.goal?.title ?? "Unknown").csvEscaped
        let dateStr = formatter.string(from: date)
        let tier = (event.tierRawValue ?? "unknown").csvEscaped
        let day = Calendar.current.startOfDay(for: date)
        let isFrozen = frozenDaySet.contains(day) ? "true" : "false"
        rows.append("\(goalName),\(dateStr),\(tier),\(isFrozen)")
    }
    return rows.joined(separator: "\n")
}
```

**RFC 4180 String extension** (RESEARCH.md Pitfall 3 — add in same file or a shared extension):
```swift
private extension String {
    var csvEscaped: String {
        let escaped = self.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
```
Mark `private` — only `CSVExportService` uses it. Apply to `goal_name` and `tier` fields consistently.

---

### `VitaminGTests/Phase26AnalyticsViewModelTests.swift` (test)

**Analog:** `VitaminG/VitaminG/VitaminGTests/NotificationSchedulerPhase25Tests.swift` (lines 1–80)

**Import and class declaration pattern** (lines 1–14):
```swift
import XCTest
import UserNotifications
import SwiftData
@testable import VitaminG

@MainActor
final class NotificationSchedulerPhase25Tests: XCTestCase {
    private var container: ModelContainer!
```
For Phase 26:
```swift
import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class Phase26AnalyticsViewModelTests: XCTestCase {
    private var container: ModelContainer!
    private var viewModel: AnalyticsViewModel!
```

**setUp / tearDown pattern** (lines 19–31):
```swift
override func setUp() async throws {
    try await super.setUp()
    container = try ModelContainerFactory.makeContainer(inMemory: true)
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    clearAppGroupKeys()
}

override func tearDown() async throws {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    clearAppGroupKeys()
    container = nil
    try await super.tearDown()
}
```
For Phase 26:
```swift
override func setUp() async throws {
    try await super.setUp()
    container = try ModelContainerFactory.makeContainer(inMemory: true)
    viewModel = AnalyticsViewModel()
}

override func tearDown() async throws {
    viewModel = nil
    container = nil
    try await super.tearDown()
}
```

**Test method naming pattern** (lines 43–53):
```swift
func test_makeContent_celebratoryCopy_whenStreakGe7() throws {
    let context = ModelContext(container)
    let goal = Goal(title: "Goal A", tier: .immediate)
    context.insert(goal)

    let content = scheduler.makeContent(activeGoals: [goal], currentStreak: 7)
    XCTAssertTrue(...)
}
```
For Phase 26, use the `test_<method>_<expected>_<condition>` naming convention:
```swift
func test_weeklyBuckets_rateIsOneHalf_whenHalfDaysHaveEvent() throws { ... }
func test_monthlyBuckets_correctPeriodCount_forThreeMonths() throws { ... }
func test_completionRateFormula_zeroDays_returnsZero() throws { ... }
func test_heatmapStartDate_usesCreationDateFallback_whenCreationDateNil() throws { ... }
func test_allGoalsIncluded_completedGoalsAppearInList() throws { ... }
```

**Test data creation pattern** (lines 45–47):
```swift
let context = ModelContext(container)
let goal = Goal(title: "Goal A", tier: .immediate)
context.insert(goal)
```
Use `ModelContext(container)` from the in-memory container for all test data. Create `CompletionEvent` instances by inserting them into the same context and setting `completedAt` to specific dates for deterministic bucket assertions.

---

### `VitaminGTests/Phase26CSVExportServiceTests.swift` (test)

**Analog:** `VitaminG/VitaminG/VitaminGTests/NotificationSchedulerPhase25Tests.swift` (lines 1–160)

**Same import and class pattern** as `Phase26AnalyticsViewModelTests.swift` above:
```swift
import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class Phase26CSVExportServiceTests: XCTestCase {
    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try ModelContainerFactory.makeContainer(inMemory: true)
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }
}
```

**Test assertions pattern** (lines 43–53 — XCTAssertTrue with descriptive failure message):
```swift
XCTAssertTrue(
    NotificationScheduler.celebratoryCopy.contains { content.body.hasPrefix($0) },
    "streak >= 7 should select from celebratoryCopy bank"
)
```
For CSV tests:
```swift
func test_csvHeader_isCorrect() throws {
    let result = CSVExportService.buildGlobalCSV(events: [], goals: [], frozenDates: [])
    XCTAssertTrue(result.hasPrefix("goal_name,date,tier,is_frozen"), "Header row must be first line")
}

func test_csvEscaping_commaInGoalName() throws {
    // Create goal titled "My, Goal" — comma must be escaped
    ...
    XCTAssertTrue(output.contains("\"My, Goal\""), "Goal name with comma must be quoted (RFC 4180)")
}

func test_isFrozenColumn_trueForFrozenDay() throws {
    // event.completedAt = frozenDate → is_frozen = true
    ...
    XCTAssertTrue(row.hasSuffix(",true"), "is_frozen column must be 'true' for frozen-day event")
}

func test_sortOrder_dateAscending() throws {
    // Create events for day+2 and day+0; verify day+0 row appears first in output
    ...
}
```

---

### `Navigation/AppRoute.swift` (modify — add case)

**File to read before modifying:** `VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift` (already read, lines 1–19)

**Current last case** (line 18):
```swift
case communityGoals(UserChallenge)     // Phase 15 — UIADD-04, C4
```

**Add after line 18:**
```swift
case analytics   // Phase 26 — ANLT-02/03/04
```

Keep the inline comment convention (phase number and requirement IDs). No other changes to this file.

---

### `Views/ContentView.swift` (modify — add destination case)

**File to read before modifying:** `VitaminG/VitaminG/VitaminG/Views/ContentView.swift` (already read, lines 1–122)

**Home tab NavigationStack destination switch** (lines 14–21):
```swift
NavigationStack {
    HomeView()
        .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .stats: StatsView()
            case .wins: DailyWinsView()
            default: EmptyView()
            }
        }
}
```

**Add one case before `default`:**
```swift
case .analytics: AnalyticsView()
```

Result:
```swift
switch route {
case .stats: StatsView()
case .wins: DailyWinsView()
case .analytics: AnalyticsView()   // Phase 26
default: EmptyView()
}
```

`AnalyticsView` lives in the Home tab's `NavigationStack` — the same stack that owns `.stats`. This is correct because `StatsView` (`.stats`) is on the Home tab, and AnalyticsView is navigated from inside StatsView. Do NOT add `.analytics` to the Goals tab's `NavigationStack(path: $router.path)` (lines 74–90).

---

### `Views/StatsView.swift` (modify — add NavigationLink)

**File to read before modifying:** `VitaminG/VitaminG/VitaminG/Views/StatsView.swift` (already read, lines 1–229)

**Current VStack structure** (lines 22–33):
```swift
VStack(spacing: 20) {
    globalStreakCard
    ConsistencyScoreCard(...)
    tierStreakGrid
    heatmapSection
}
```

**Add one item after `heatmapSection`:**
```swift
VStack(spacing: 20) {
    globalStreakCard
    ConsistencyScoreCard(...)
    tierStreakGrid
    heatmapSection
    analyticsNavigationRow   // Phase 26 — D-01
}
```

**analyticsNavigationRow private var pattern** — copy the chevron-row style from `ProfileView.swift` lines 481–491:
```swift
private var analyticsNavigationRow: some View {
    NavigationLink(value: AppRoute.analytics) {
        HStack {
            Label("Analytics", systemImage: "chart.bar.doc.horizontal")
                .font(.body).fontDesign(.rounded)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
}
```

Do not modify `globalStreakCard`, `tierStreakGrid`, `heatmapSection`, or any other existing properties in `StatsView`.

---

## Shared Patterns

### @MainActor @Observable ViewModel
**Source:** `ViewModels/StatsViewModel.swift` lines 13–15
**Apply to:** `AnalyticsViewModel.swift`
```swift
@MainActor
@Observable
final class StatsViewModel {
```

### refresh(events:goals:frozenDates:) Pattern
**Source:** `ViewModels/StatsViewModel.swift` lines 36–54
**Apply to:** `AnalyticsViewModel.refresh()` — same signature, same call sites (`.onAppear` + `.onChange(of: events.count)` + `.onChange(of: goals.count)`)

### @Query in View (not passed from parent)
**Source:** `Views/StatsView.swift` lines 13–14
**Apply to:** `AnalyticsView.swift`
```swift
@Query private var events: [CompletionEvent]
@Query private var goals: [Goal]
```
Never pass `[CompletionEvent]` or `[Goal]` arrays as init parameters across view boundaries — each screen owns its own `@Query`.

### HeatmapData Sentinel (-1 for frozen days)
**Source:** `ViewModels/StatsViewModel.swift` lines 62–78
**Apply to:** `AnalyticsViewModel.buildGoalHeatmapData()` and `CSVExportService.buildGlobalCSV()`
The -1 sentinel is written by `buildHeatmapData` for frozen dates with no real check-in. `CSVExportService` must reconstruct the frozen-day set from `frozenDates` independently (it receives raw `[Date]`, not the pre-built dict).

### Pure Service Struct Pattern
**Source:** `Services/ConsistencyEngine.swift` lines 1–14
**Apply to:** `Services/CSVExportService.swift`
`import Foundation` only. No `SwiftUI`, no `SwiftData`, no stored instance properties. All methods are `static`. Return value types (`String`, `Int`, `Bool`).

### Card / Section Layout Pattern
**Source:** `Views/StatsView.swift` lines 146–166 (heatmapSection)
**Apply to:** All card sections in `AnalyticsView.swift`
```swift
VStack(alignment: .leading, spacing: 12) {
    Text("Section Title")
        .font(.title3.weight(.semibold))
        .padding(.horizontal, 4)

    ZStack {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(UIColor.secondarySystemGroupedBackground))
        VStack(...) { ... }.padding(16)
    }
}
```

### XCTest Scaffold Pattern
**Source:** `VitaminGTests/NotificationSchedulerPhase25Tests.swift` lines 1–40
**Apply to:** Both Phase 26 test files
```swift
@MainActor
final class Phase26XxxTests: XCTestCase {
    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try ModelContainerFactory.makeContainer(inMemory: true)
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }
}
```

### VGTheme Color Usage
**Source:** `Views/StatsView.swift` lines 54–57 + `Views/ProfileView.swift` line 479
**Apply to:** `AnalyticsView.swift` (chart foreground, button tint)
Use `VGTheme.accentTerra` as primary accent for the bar chart and Export button. Use `VGTheme.accentPurple` only as gradient secondary if desired. Do not introduce new color names.

---

## No Analog Found

All files in scope have close analogs in the codebase. No gaps.

| File | Role | Data Flow | Reason |
|---|---|---|---|
| (none) | — | — | — |

---

## Metadata

**Analog search scope:** `VitaminG/VitaminG/VitaminG/` (ViewModels, Views, Services, Navigation) + `VitaminG/VitaminG/VitaminGTests/`
**Files scanned:** 10 source files read; 4 additional via Bash grep
**Pattern extraction date:** 2026-06-01
