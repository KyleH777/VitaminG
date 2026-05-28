# Phase 24: Widget Enhancements - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Update the existing systemMedium home screen widget (`GoalSummaryWidget`) with a v2.0 redesign: equal-split layout showing streak count + active goal title with a linear progress bar. The accessoryRectangular lock screen widget (`StreakWidget`) stays as-is — it already reflects v2.0 data correctly. Wire `WidgetCenter.shared.reloadAllTimelines()` to the streak freeze mutation in `StatsView` (currently missing) and audit all v2.0 goal state mutation sites for any additional gaps.

No new widget families, no schema changes, no CloudKit access from widgets.

</domain>

<decisions>
## Implementation Decisions

### GoalSummaryWidget Layout (WID-01)

- **D-01:** Full visual redesign of `GoalSummaryWidgetView` — drop the 4-tier row layout entirely. New layout is an equal split:
  - **Top row:** Flame icon + streak count + "day streak" label (same visual as current footer, promoted to primary position)
  - **Bottom row:** Active goal title (1 line, truncated) + thin linear progress bar (Capsule trim, visible only when `durationDays != nil`)
- **D-02:** `StreakWidget` (accessoryRectangular) is unchanged — it already shows streak count with goal title fallback, which is correct for v2.0.

### Active Goal Selection

- **D-03:** Active goal = the highest-priority non-completed goal from local SwiftData only (no CloudKit access from widgets). Tier priority: **Immediate first**, then Short Term, Long Term, Life Goal. Within a tier, earliest `creationDate` wins.
  - *Rationale (Claude discretion):* The widget lives on the home screen for daily reference — showing the most immediately actionable goal (Immediate tier) is more motivating than surfacing a long-horizon Life Goal.
- **D-04:** Progress = `completionEvents.count / durationDays` (clamped to 0.0–1.0). If `goal.durationDays` is nil, show goal title only — no progress bar rendered.
- **D-05:** `WidgetDisplayData` is extended with two new fields: `activeGoalTitle: String?` and `activeGoalProgress: Double?` (nil = no duration, no bar). `WidgetDataProvider.build()` computes these using D-03 + D-04 logic. Existing `tierRows` field is retained if needed for backward compat but is no longer rendered.

### Progress Representation

- **D-06:** Progress bar: thin `Capsule()` filled with `VGTheme.accentTerra`. Background track: `.fill.tertiary` or `accentTerra.opacity(0.20)`. Width = full available horizontal space. Height: ~4pt. `.widgetAccentable()` not applied to the fill (keep color expressive on home screen).
- **D-07:** No progress bar is shown on the `StreakWidget` (accessoryRectangular) — space too constrained and the widget requirement is streak-first.

### WID-02 — Widget Reload Wiring

- **D-08:** Add `WidgetCenter.shared.reloadAllTimelines()` in `StatsView` immediately after `freezeService.freeze()` in the confirmation dialog handler. Surgical one-line fix — keeps `StreakFreezeService` pure Foundation.
- **D-09:** Audit all v2.0 goal state mutation sites (including GoalDetailViewModel, AchievementView check-in path, ExploreView gifter add-goal path, StuckDayGift add-goal path, StreakFreezeView if separate from StatsView) to confirm each calls `WidgetCenter.shared.reloadAllTimelines()` or `reloadWidgetTimelines()`. Fix any gaps found.

### Claude's Discretion

- Tier priority for active goal selection (D-03): Immediate first rather than Life Goal first — optimizes for daily actionability on a home screen widget.
- `activeGoalProgress: Double?` uses `nil` as sentinel for "no duration" rather than `0.0`, preventing rendering an empty bar for goals without a timeline.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Requirements
- `.planning/ROADMAP.md` §Phase 24 — goal, success criteria, requirements (WID-01, WID-02)
- `.planning/REQUIREMENTS.md` §Widget Enhancements (WID-01, WID-02) — full requirement definitions

### Existing Widget Code (read before touching)
- `VitaminG/VitaminG/VitaminGWidget/GoalSummaryWidget.swift` — `GoalSummaryWidgetView` to redesign (D-01); `GoalSummaryProvider` stays the same
- `VitaminG/VitaminG/VitaminGWidget/StreakWidget.swift` — no changes (D-02); read to understand structure
- `VitaminG/VitaminG/VitaminGWidget/WidgetTimelineEntry.swift` — `GoalEntry` shared by both providers
- `VitaminG/VitaminG/VitaminG/Services/WidgetDataProvider.swift` — `WidgetDisplayData` struct + `WidgetDataProvider.build()` to extend with `activeGoalTitle` + `activeGoalProgress` (D-05)

### Mutation Sites for WID-02 Audit
- `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` — already calls `reloadWidgetTimelines()` on all mutations (addGoal, updateGoal, addCheckIn, toggleCompletion, delete, updatePublicStatus)
- `VitaminG/VitaminG/VitaminG/Views/StatsView.swift` — `freezeService.freeze()` on line ~106 **missing** `reloadAllTimelines()` — primary gap to fix (D-08)

### Theme and Design System
- `VitaminG/VitaminG/VitaminG/VGTheme.swift` — `accentTerra` color for progress bar (D-06)

### Prior Phase Context
- `.planning/STATE.md` — key decisions: push-only widget refresh (`.never` policy), App Group UserDefaults pattern, "Widget phase is last" rationale
- `.planning/phases/22-public-profile-follow-discover/22-CONTEXT.md` — `Circle().trim()` progress ring pattern (used in PublicGoalCard); this phase uses linear bar instead but the trim pattern is available if needed

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `WidgetDataProvider.build(goals:events:calendar:)` (existing pure function): extend its return type to include `activeGoalTitle` and `activeGoalProgress` — same input arrays, same pure-function pattern
- `WidgetContainerCache.shared` (existing): shared `ModelContainer` across both widget providers — no change needed
- `GoalEntry` (existing `TimelineEntry`): no change needed — carries `WidgetDisplayData` which will gain the new fields
- `StreakEngine.currentStreak(from:frozenDates:)` (existing): already used by `WidgetDataProvider` for `globalStreak` — no change
- `GoalViewModel.reloadWidgetTimelines()` (existing private method): pattern to follow for the freeze fix in `StatsView`

### Established Patterns
- Push-only widget refresh: `Timeline(entries: [entry], policy: .never)` — both providers use this; do not change to `.atEnd` or `.after`
- Placeholder/snapshot use static data only (Pitfall 4) — `GoalSummaryProvider.placeholder` and `getSnapshot` must remain static; only `getTimeline` does SwiftData fetch
- `WidgetDataProvider` is a pure struct (no SwiftUI/WidgetKit/SwiftData imports) — keep it pure; all new logic stays in this struct, no imports added
- `.containerBackground(.fill.tertiary, for: .widget)` required on all widget root views (iOS 17+)
- `@MainActor` and WidgetKit providers are NOT on main actor — widget providers run on background threads; `WidgetDataProvider.build()` must remain thread-safe (it already is — pure value computation)

### Integration Points
- `GoalSummaryWidgetView.body`: replace `TierRowView` loop + footer with new equal-split layout (D-01). `entry.displayData.activeGoalTitle` + `entry.displayData.activeGoalProgress` drive the new bottom row.
- `WidgetDataProvider.build()`: add active goal selection logic (D-03, D-04) after existing `tierRows` computation. New fields populate `activeGoalTitle` and `activeGoalProgress`.
- `StatsView` freeze handler: add `WidgetCenter.shared.reloadAllTimelines()` after `freezeService.freeze()` (D-08).
- v2.0 audit sites: GoalDetailViewModel check-in (Phase 18), ExploreView gifter add-goal path (Phase 20), StuckDayGift add-goal path (Phase 20) — verify each calls reload.

</code_context>

<specifics>
## Specific Ideas

- The new `GoalSummaryWidgetView` layout: top half is the streak row (same `HStack` with `flame.fill` + bold count + "day streak" text already in the current footer — just promoted). Bottom half is an `HStack` with goal title (`.lineLimit(1)`, `.truncationMode(.tail)`) + a `Capsule().fill(...)` progress bar in a `GeometryReader` or using `LinearProgressViewStyle`. A `VStack(spacing: 8)` wraps both rows.
- Empty state (no active goals): show a simple "Add your first goal" prompt where the goal row would be, consistent with `StreakWidgetView`'s State C.
- The `WidgetDisplayData.placeholder` should be updated to include sample `activeGoalTitle` and `activeGoalProgress` values for a realistic widget gallery preview.

</specifics>

<deferred>
## Deferred Ideas

- Interactive widget tap-to-check-in: App Intents + `AppIntentConfiguration` would let users check in directly from the widget. Deferred — no `AppIntent` scaffold exists yet; v3.0 candidate.
- Additional widget families (systemSmall, systemLarge): out of scope for Phase 24; only systemMedium and accessoryRectangular in WID-01.
- accessoryCircular lock screen variant: not in WID-01 requirements; defer to future widget phase.

</deferred>

---

*Phase: 24-widget-enhancements*
*Context gathered: 2026-05-27*
