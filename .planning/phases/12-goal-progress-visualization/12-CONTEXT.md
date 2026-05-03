# Phase 12: Goal Progress Visualization - Context

**Gathered:** 2026-05-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 12 adds visual progress feedback to every goal card and the GoalDetailView. Each `GoalRowView` gains a circular progress ring (replacing the tier pip) that fills based on completions in the last 7 days. `GoalDetailView` gains a Swift Charts bar chart of daily completions over the last 30 days, total count, last completed date, and a momentum score with color indicator. Micro-milestone celebrations (animated SF Symbol badge overlay) fire at 5, 10, 25, and 50 cumulative completions.

**No new SwiftData model is needed.** All computations derive from existing `CompletionEvent` records (PROG-05).

Phase 12 does NOT add: global progress dashboards, cross-goal leaderboards, completion streaks on the progress ring, or any new data model properties.

</domain>

<decisions>
## Implementation Decisions

### Progress Ring on Goal Cards (PROG-01)
- **D-01:** Replace the existing tier pip (`RoundedRectangle`, 4×36pt, tier color) in `GoalRowView` with a circular progress ring — 28pt diameter, 3pt stroke width, tier color. Zero layout change: same HStack slot, same color encoding, progress fill replaces solid pip.
- **D-02:** Ring fill formula: `min(completionsLast7Days / 7.0, 1.0)` — clockwise arc from top. A completed goal (isCompleted == true) shows the ring fully filled (1.0) regardless of the 7-day window.
- **D-03:** Ring is drawn with `Circle().trim(from: 0, to: progress).stroke(...)` layered over a faint background circle (`opacity: 0.15`). Reduced motion: skip trim animation, show static fill instantly.

### Time Window (PROG-01, PROG-04)
- **D-04:** 7-day window used for both the ring fill and the momentum score. Consistent formula: `completions in last 7 calendar days ÷ 7`, clamped 0–1. Same window = same story told by ring and by GoalDetailView momentum color.
- **D-05:** "Last 7 calendar days" = today + 6 prior days using `Calendar.current.startOfDay`. No time-zone gymnastics — consistent with StreakEngine's existing `startOfDay` pattern.

### Momentum Score in GoalDetailView (PROG-04)
- **D-06:** Momentum score displayed as a labeled row in GoalDetailView: score value (e.g., "0.57") alongside a color dot — green (≥ 0.5), amber (0.1–0.5), gray (< 0.1).
- **D-07:** Label: "Momentum" with subtitle "completions in the last 7 days." Color dot uses existing tier color palette conventions (green = goal complete color `#10B981`, amber = `.orange`, gray = `.secondary`).

### Per-Goal History in GoalDetailView (PROG-02)
- **D-08:** Use Swift Charts (`import Charts`, Apple framework, iOS 16+, no third-party dep) for a per-goal bar chart: one `BarMark` per calendar day, last 30 days, Y = completion count for that goal on that day. Days with 0 completions show an empty bar placeholder.
- **D-09:** Above the chart: two summary rows — "Total completions: N" and "Last completed: [date or 'Never']". Below the chart: the momentum score row (D-06).
- **D-10:** Chart height: 80pt. Bar color: tier color. X-axis shows abbreviated day labels for the last 7 days; older bars unlabeled (chart scrolls or compresses). Keep it compact — GoalDetailView already has several sections.

### Micro-Milestone Celebrations (PROG-03)
- **D-11:** Thresholds: 5, 10, 25, 50 cumulative completions per goal. Check total `completionEvents?.count` after each `toggleCompletion` call.
- **D-12:** Celebration: an SF Symbol badge (`.star.fill`, tier color) animates onto the goal card — scales from 0.5 → 1.2 → 1.0, fades in, holds for 1.5s, fades out. Non-blocking: appears as an overlay on the card without modals or interruption.
- **D-13:** Track fired milestones in-memory via a `Set<Int>` on `GoalViewModel` keyed by goal ID + threshold (e.g., `"\(goalID)-5"`). Prevents re-firing within a session. Does not persist across launches — re-firing on next launch after a threshold is acceptable (the celebration is brief and reinforcing).
- **D-14:** Reduced motion: skip animation, show a brief static badge for 0.5s then fade.

### ProgressViewModel (new ViewModel)
- **D-15:** Add `ProgressViewModel` — `@MainActor @Observable` — following the `StatsViewModel.refresh(events:goals:)` pattern. It exposes:
  - `func ringProgress(for goal: Goal, events: [CompletionEvent]) -> Double`
  - `func momentumScore(for goal: Goal, events: [CompletionEvent]) -> Double`
  - `func chartData(for goal: Goal, events: [CompletionEvent]) -> [DayCount]` (last 30 days)
  - `func milestoneJustCrossed(for goal: Goal) -> Int?` (returns threshold if newly crossed)
- **D-16:** `ProgressViewModel` is a standalone struct/class with no SwiftData/SwiftUI dependency — unit-testable in isolation (same GoalSorter / StreakEngine pattern).

### Claude's Discretion
- Exact SF Symbol for the milestone badge (`.star.fill` recommended; tier could use `.trophy.fill` for 50-completion milestone)
- Whether the progress ring animates on appear (`.animation(.easeInOut, value: progress)` — recommended unless reduced motion)
- Chart X-axis label density and scroll behavior (compact / non-scrolling preferred to avoid layout complexity)
- Exact padding and card layout of the progress section in GoalDetailView

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing progress data source
- `VitaminG/VitaminG/VitaminG/Models/SchemaV2.swift` — `CompletionEvent` model: `completedAt: Date?`, `tierRawValue: String?`, `goal: Goal?`. Ring and momentum computations pull from this.
- `VitaminG/VitaminG/VitaminG/Models/SchemaV3.swift` — Current schema version; any new models would need SchemaV4, but PROG-05 prohibits new models.

### Existing computation patterns to follow
- `VitaminG/VitaminG/VitaminG/Services/StreakEngine.swift` — `Calendar.current.startOfDay` pattern for day comparison. `ProgressViewModel` must use identical calendar arithmetic.
- `VitaminG/VitaminG/VitaminG/ViewModels/StatsViewModel.swift` — `refresh(events:goals:)` signature pattern; `buildHeatmapData` shows how to transform `[CompletionEvent]` into day-keyed counts. `ProgressViewModel` should mirror this structure.

### Views to modify
- `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift` — `GoalRowView` (line 181+): replace tier pip `RoundedRectangle` with circular progress ring. `GoalListView` must pass `CompletionEvent` data to `GoalRowView` — plan how events flow down.
- `VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift` — Add history section (chart + summary rows + momentum score) below existing sections.

### Architecture constraints
- `.planning/PROJECT.md` — No third-party dependencies. Swift Charts is an Apple framework (OK). MVVM enforced.
- `VitaminG/CLAUDE.md` — `@Observable` ViewModel pattern, iOS 17+ minimum, Dynamic Type + reduced motion requirements, CloudKit-compatible model rules (no new model needed here per PROG-05).
- `.planning/REQUIREMENTS.md` — PROG-01 through PROG-05 are the requirements being closed by this phase.

### Navigation / widget refresh
- `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` — `toggleCompletion` is where milestone check should hook in (D-11). Already calls `WidgetCenter.shared.reloadAllTimelines()`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `StreakEngine.startOfDay` calendar arithmetic — copy-compatible pattern for 7-day window in `ProgressViewModel`
- `StatsViewModel.buildHeatmapData` — exact pattern for `[DayCount]` chart data builder
- Tier color system (`GoalTier.color`) — drives ring stroke color and momentum dot color at no extra work
- Existing `completionGreen` constant in `GoalRowView` — reuse for fully-filled ring on completed goals

### Established Patterns
- `GoalSorter` / `StreakEngine` pattern: pure struct, no SwiftData dependency, `static` or instance methods, all SwiftData types passed in as arrays. `ProgressViewModel` must follow this exactly to stay unit-testable.
- `@Observable` ViewModel with `@State private var viewModel = ProgressViewModel()` in the View — no `@StateObject`, no `@EnvironmentObject`.
- `@Environment(\.accessibilityReduceMotion)` gate in `GoalRowView` — progress ring animation and milestone badge animation must also check this.
- `@Query` provides `[Goal]` and `[CompletionEvent]` arrays in Views — pass arrays down to ViewModel methods (no direct SwiftData inside ViewModel).

### Integration Points
- `GoalRowView` → needs `completionEvents` for the goal filtered from the parent `@Query`. Either filter in `GoalListView` and pass `[CompletionEvent]` to `GoalRowView`, or pass all events and filter inside `GoalRowView`. Passing filtered per-goal events is cleaner.
- `GoalDetailView` → already holds `let goal: Goal` — add `@Query` for `completionEvents` filtered to this goal, or pass events from the calling view.
- `GoalViewModel.toggleCompletion` → milestone check fires here after insert; `ProgressViewModel.milestoneJustCrossed` called with updated count.

</code_context>

<specifics>
## Specific Ideas

- Progress ring replaces the tier pip visually exactly — same slot, same color, adds ring arc fill (confirmed by user)
- 7-day window for both ring and momentum — consistent formula, no dual-definition (confirmed by user)
- SF Symbol badge overlay on card, non-blocking, ~2s duration (confirmed by user)
- Swift Charts bar chart in GoalDetailView, last 30 days (confirmed by user)
- Completed goal (isCompleted == true) shows ring as fully filled (1.0) — natural UX

</specifics>

<deferred>
## Deferred Ideas

- Cross-goal progress dashboard / leaderboard — future phase
- Persistent milestone history (to avoid re-firing across launches) — acceptable to leave in-memory for now; could persist to UserDefaults in a later polish phase
- Streak counter on the progress ring (e.g., streak arc layer) — StatsView already covers streaks; keep ring focused on 7-day momentum
- Widget showing individual goal progress ring — would need WidgetKit + App Group pass-through of CompletionEvent counts; Phase 4 extension

</deferred>

---

*Phase: 12-goal-progress-visualization*
*Context gathered: 2026-05-03*
