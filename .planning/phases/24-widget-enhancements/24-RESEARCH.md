# Phase 24: Widget Enhancements - Research

**Researched:** 2026-05-27
**Domain:** WidgetKit / SwiftUI / SwiftData — widget view redesign + mutation-site reload audit
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**GoalSummaryWidget Layout (WID-01)**
- D-01: Full visual redesign of `GoalSummaryWidgetView` — drop the 4-tier row layout entirely. New layout is an equal split: top row = flame icon + streak count + "day streak" label; bottom row = active goal title (1 line, truncated) + thin linear progress bar (Capsule trim, visible only when `durationDays != nil`).
- D-02: `StreakWidget` (accessoryRectangular) is unchanged — it already shows streak count with goal title fallback, which is correct for v2.0.

**Active Goal Selection**
- D-03: Active goal = highest-priority non-completed goal from local SwiftData only (no CloudKit access from widgets). Tier priority: Immediate first, then Short Term, Long Term, Life Goal. Within a tier, earliest `creationDate` wins.
- D-04: Progress = `completionEvents.count / durationDays` (clamped 0.0–1.0). If `goal.durationDays` is nil, show goal title only — no progress bar rendered.
- D-05: `WidgetDisplayData` extended with `activeGoalTitle: String?` and `activeGoalProgress: Double?` (nil = no duration, no bar). `WidgetDataProvider.build()` computes these. Existing `tierRows` field retained for backward compat but no longer rendered.

**Progress Representation**
- D-06: Progress bar: thin `Capsule()` filled with `VGTheme.accentTerra`. Background track: `accentTerra.opacity(0.20)`. Width = full available horizontal space. Height: ~4pt. `.widgetAccentable()` NOT applied.
- D-07: No progress bar on `StreakWidget` (accessoryRectangular) — space too constrained.

**WID-02 — Widget Reload Wiring**
- D-08: Add `WidgetCenter.shared.reloadAllTimelines()` in `StatsView` immediately after `freezeService.freeze()` in the confirmation dialog handler. Surgical one-line fix — `StreakFreezeService` remains pure Foundation.
- D-09: Audit all v2.0 goal state mutation sites (GoalDetailViewModel, AchievementView check-in path, ExploreView gifter add-goal path, StuckDayGift add-goal path, StreakFreezeView if separate from StatsView) to confirm each calls `WidgetCenter.shared.reloadAllTimelines()` or `reloadWidgetTimelines()`. Fix any gaps found.

### Claude's Discretion

- Tier priority for active goal selection (D-03): Immediate first rather than Life Goal first.
- `activeGoalProgress: Double?` uses `nil` as sentinel for "no duration" rather than `0.0`, preventing rendering an empty bar for goals without a timeline.

### Deferred Ideas (OUT OF SCOPE)

- Interactive widget tap-to-check-in: App Intents + `AppIntentConfiguration` — no AppIntent scaffold exists yet; v3.0 candidate.
- Additional widget families (systemSmall, systemLarge): out of scope for Phase 24.
- accessoryCircular lock screen variant: defer to future widget phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WID-01 | Existing home screen widget (systemMedium) and lock screen widget (accessoryRectangular) updated to reflect v2.0 Home tab data (streak count, active goal with progress) | `WidgetDisplayData` struct extension (D-05) + `GoalSummaryWidgetView` body redesign (D-01) + `WidgetDataProvider.build()` active-goal logic (D-03/D-04) — all three components fully verified in codebase |
| WID-02 | `WidgetCenter.shared.reloadAllTimelines()` called on all new v2.0 goal state changes (daily check-in, freeze used, goal completed) | `GoalViewModel.reloadWidgetTimelines()` already covers 7 mutation sites; `StatsView` freeze handler is the confirmed missing site; `GoalGifterCard` and `StuckDayGiftsSection` both call `goalVM.addGoal()` which already routes through `GoalViewModel.reloadWidgetTimelines()` — covered transitively |
</phase_requirements>

---

## Summary

Phase 24 is a focused, surgical widget update — the last phase of the v2.0 milestone. It has two components: (1) a visual redesign of `GoalSummaryWidgetView` from a 4-tier row layout to a 2-row equal-split layout showing streak + active goal with a linear progress bar, and (2) a widget timeline reload audit that closes a single confirmed gap in `StatsView`.

The codebase is in excellent shape for this work. `WidgetDataProvider` is already a pure struct with a clean `build()` function, `WidgetContainerCache` is shared across both providers, and `GoalViewModel.reloadWidgetTimelines()` already covers the critical mutation sites. The WID-02 audit is simpler than it looked from the outside: `GoalGifterCard.addGiftedGoal()` and `StuckDayGiftsSection.addStuckDayGift()` both call `goalVM.addGoal(input:context:)` which internally calls `reloadWidgetTimelines()` — these paths are covered transitively through `GoalViewModel`. The one confirmed missing site is `StatsView.confirmationDialog` freeze handler at line 106.

The design contract is fully specified in 24-UI-SPEC.md (approved 2026-05-27). `WidgetDisplayData.placeholder` needs updating to carry sample `activeGoalTitle` and `activeGoalProgress`. The existing `WidgetDataProviderTests.swift` file exists and will need new test cases for the extended `WidgetDisplayData` fields.

**Primary recommendation:** Implement in one wave — three targeted file edits: `WidgetDataProvider.swift` (struct extension), `GoalSummaryWidget.swift` (view redesign), `StatsView.swift` (one-line fix). Add a `Phase24WidgetDataProviderTests.swift` for the new active-goal logic. No schema migration, no new imports, no new dependencies.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Widget display data computation | Widget Extension (pure Swift) | — | `WidgetDataProvider.build()` is a pure value function in `VitaminG/Services/` — no framework imports, shared by both providers |
| Widget view layout | Widget Extension (SwiftUI/WidgetKit) | — | `GoalSummaryWidgetView` lives in `VitaminGWidget/` — only WidgetKit/SwiftUI rendering |
| SwiftData fetch for widget | Widget Extension (background thread) | — | `GoalSummaryProvider.getTimeline()` fetches via `WidgetContainerCache.shared` ModelContext; runs on background thread (not MainActor) |
| Widget timeline invalidation | App (MainActor) | — | `WidgetCenter.shared.reloadAllTimelines()` must be called from app-side mutation sites; widgets cannot self-invalidate in push-only mode |
| Streak freeze mutation | App — View layer (StatsView) | — | `StreakFreezeService.freeze()` is called in `StatsView.confirmationDialog` handler — same location where reload call is missing |

---

## Standard Stack

### Core (system frameworks only — no third-party dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| WidgetKit | iOS 17+ | Widget timeline provider, widget configuration | System framework — project minimum iOS 17 |
| SwiftUI | iOS 17+ | Widget view rendering | System framework — all widget views use SwiftUI |
| SwiftData | iOS 17+ | Reading goals and events in widget getTimeline | System framework — `ModelContext(container)` fetch pattern already in place |
| Foundation | iOS 17+ | `StreakFreezeService` (pure Foundation), `WidgetDataProvider` (pure Foundation) | System framework |

[VERIFIED: CLAUDE.md project stack declaration]

### Supporting (in-project, no installs)

| Component | Location | Purpose | When Used |
|-----------|----------|---------|-----------|
| `WidgetDataProvider` | `Services/WidgetDataProvider.swift` | Pure `build()` function — extend with `activeGoalTitle`/`activeGoalProgress` | This phase extends it |
| `WidgetDisplayData` | `Services/WidgetDataProvider.swift` | Struct carrying widget display state — add two new fields | This phase extends it |
| `WidgetContainerCache` | `VitaminGWidget/GoalSummaryWidget.swift` | Shared `ModelContainer` for widget extension | No change needed |
| `StreakEngine` | (existing) | `currentStreak(from:frozenDates:)` | Already called in `build()` — no change |
| `GoalTier.ordered` | `Models/Goal.swift` | `[.immediate, .shortTerm, .longTerm, .lifeGoal]` | Used in active goal tier-priority sort (D-03) |
| `VGTheme.accentTerra` | `VGTheme.swift` | Adaptive color token — `#C4673A` light / `#FF8A5C` dark | Progress bar fill + flame icon |

[VERIFIED: codebase read]

### Package Legitimacy Audit

> Not applicable — this phase installs zero external packages. All dependencies are system frameworks (WidgetKit, SwiftUI, SwiftData, Foundation) and in-project files.

---

## Architecture Patterns

### System Architecture Diagram

```
App Process (MainActor)                Widget Extension Process (background)
─────────────────────────────────      ─────────────────────────────────────
User action                            WidgetKit calls getTimeline()
    │                                       │
    ▼                                       ▼
GoalViewModel mutation                 WidgetContainerCache.shared
(addGoal/addCheckIn/toggleCompletion/       │ ModelContainer (App Group)
 delete/updatePublicStatus/freeze)          │
    │                                       ▼
    ▼                               ModelContext.fetch(Goal, CompletionEvent)
WidgetCenter.shared                         │
  .reloadAllTimelines()                     ▼
    │                               WidgetDataProvider.build(goals:events:)
    └──────────► WidgetKit re-calls         │ — tierRows (existing)
                  getTimeline()             │ — globalStreak (existing)
                                            │ — activeGoalTitle (NEW Phase 24)
                                            │ — activeGoalProgress (NEW Phase 24)
                                            │
                                            ▼
                                      GoalEntry(displayData:)
                                            │
                                            ▼
                                    GoalSummaryWidgetView (NEW layout)
                                    ┌─── Top row: flame + streak count
                                    └─── Bottom row: goal title + progress bar
```

### Recommended File Touch List

```
VitaminGWidget/
├── GoalSummaryWidget.swift    # GoalSummaryWidgetView: replace body; drop TierRowView
│                              # GoalSummaryWidget.description update
VitaminG/
├── Services/
│   └── WidgetDataProvider.swift   # WidgetDisplayData: 2 new fields + placeholder/empty update
│                                   # WidgetDataProvider.build(): active goal logic
└── Views/
    └── StatsView.swift             # One-line fix: reloadAllTimelines() after freeze()
VitaminGTests/
└── Phase24WidgetDataProviderTests.swift  # New — test active goal selection + progress
```

### Pattern 1: WidgetDisplayData Extension

**What:** Add two optional fields to the value type; update `placeholder` and `empty` static instances; update `build()` to compute them.
**When to use:** Pure struct extension — additive, no breaking changes to existing `tierRows`/`globalStreak` consumers.

```swift
// Source: existing WidgetDataProvider.swift — extend struct
struct WidgetDisplayData {
    // ... existing fields ...
    let activeGoalTitle: String?     // nil → no active non-completed goal
    let activeGoalProgress: Double?  // nil → goal.durationDays is nil; 0.0–1.0 clamped
}
```

**Active goal selection in `build()` (D-03, D-04):**
```swift
// After existing tierRows computation — add to WidgetDataProvider.build()
// Source: CONTEXT.md D-03/D-04 + GoalTier.ordered = [.immediate, .shortTerm, .longTerm, .lifeGoal]
let activeGoal = GoalTier.ordered.compactMap { tier in
    goals
        .filter { $0.tier == tier && !$0.isCompleted }
        .sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
        .first
}.first

let activeGoalTitle = activeGoal?.title
let activeGoalProgress: Double? = {
    guard let goal = activeGoal,
          let duration = goal.durationDays,
          duration > 0 else { return nil }
    let count = Double(goal.completionEvents?.count ?? 0)
    return min(1.0, count / Double(duration))
}()
```

[VERIFIED: codebase read — GoalTier.ordered confirmed as `[.immediate, .shortTerm, .longTerm, .lifeGoal]`]

### Pattern 2: GoalSummaryWidgetView Equal-Split Layout

**What:** Replace `TierRowView` ForEach loop + footer HStack with a `VStack(spacing: 8)` containing a streak row (top) and a goal row with optional progress bar (bottom).
**When to use:** This is the only layout for the redesigned widget.

```swift
// Source: 24-UI-SPEC.md Layout Contract
struct GoalSummaryWidgetView: View {
    let entry: GoalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // TOP ROW: Streak
            streakRow

            // BOTTOM ROW: Active Goal + optional progress bar
            if let title = entry.displayData.activeGoalTitle {
                activeGoalRow(title: title, progress: entry.displayData.activeGoalProgress)
            } else {
                Text("Add your first goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Add your first goal")
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var streakRow: some View {
        HStack(spacing: 4) {
            if entry.displayData.globalStreak > 0 {
                Image(systemName: "flame.fill")
                    .foregroundStyle(VGTheme.accentTerra)
                    .font(.caption)
                Text("\(entry.displayData.globalStreak)")
                    .font(.title2.bold().monospacedDigit())
                Text("day streak")
                    .font(.caption)
                    .fontWeight(.semibold)
            } else {
                Text("Start your streak")
                    .font(.caption)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            entry.displayData.globalStreak > 0
                ? "\(entry.displayData.globalStreak) day streak"
                : "Start your streak"
        )
    }

    private func activeGoalRow(title: String, progress: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .truncationMode(.tail)

            if let p = progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(VGTheme.accentTerra.opacity(0.20))
                            .frame(height: 4)
                        Capsule()
                            .fill(VGTheme.accentTerra)
                            .frame(width: geo.size.width * p, height: 4)
                    }
                }
                .frame(height: 4)
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            progress != nil
                ? "\(title), \(Int((progress ?? 0) * 100))% complete"
                : title
        )
    }
}
```

[VERIFIED: codebase read of existing `GoalSummaryWidgetView` + 24-UI-SPEC.md + CLAUDE.md WidgetKit section]

### Pattern 3: Widget Reload One-Line Fix

**What:** Insert `WidgetCenter.shared.reloadAllTimelines()` immediately after `freezeService.freeze()` in `StatsView`.
**When to use:** Only this one site — all other mutation sites route through `GoalViewModel.reloadWidgetTimelines()` which already calls it.

```swift
// Source: StatsView.swift line 106 — confirmed gap
Button("Freeze Streak") {
    freezeService.freeze()
    WidgetCenter.shared.reloadAllTimelines()  // ADD THIS LINE (D-08)
    viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
}
```

[VERIFIED: codebase read of StatsView.swift lines 104-108]

### Anti-Patterns to Avoid

- **Changing timeline policy:** Do NOT change `policy: .never` to `.atEnd` or `.after`. The push-only pattern is a deliberate project decision (STATE.md). Changing it would cause widget ghost-polling.
- **Adding SwiftUI/WidgetKit/SwiftData imports to `WidgetDataProvider`:** The struct is intentionally pure Foundation. Any new logic stays within the existing parameters — no new imports.
- **Using `VGTheme.serif()` / CormorantGaramond in widget views:** Custom fonts in widget extensions require explicit bundle configuration. Use SF system fonts only. The UI-SPEC explicitly forbids this.
- **Applying `.widgetAccentable()` to the progress bar:** D-06 explicitly states to keep `accentTerra` expressive on home screen. `.widgetAccentable()` would neutralize the color on lock screen tinting. Do not add it to progress bar fills.
- **Fetching SwiftData in `placeholder()` or `getSnapshot()`:** These must use `WidgetDisplayData.placeholder` (static data only). SwiftData fetches belong exclusively in `getTimeline()`.
- **Removing `tierRows` from `WidgetDisplayData`:** The field is retained for backward compatibility per D-05. `StreakWidget` uses `tierRows` via `entry.displayData.tierRows.first(where: { $0.tier == .immediate })?.topGoalTitle` — removing it would break `StreakWidgetView`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Linear progress bar | Custom `Path`-based drawing | `GeometryReader` + `ZStack` with two `Capsule()` shapes | `Path` is overkill; Capsule + GeometryReader is the SwiftUI idiomatic approach and is already in 24-UI-SPEC.md |
| Widget timeline refresh throttling | Custom debounce/timer logic | `WidgetCenter.shared.reloadAllTimelines()` directly | WidgetKit handles budget internally; app should call unreservedly after mutations |
| Tier-priority sort at widget render time | Sort in `GoalSummaryWidgetView.body` | Compute in `WidgetDataProvider.build()` | Widget views run on background threads with tight budget; pre-compute all data in `build()` |
| Active goal "cache" between refreshes | `UserDefaults` or keychain caching | Direct SwiftData fetch in `getTimeline()` via `WidgetContainerCache.shared` | The App Group container read is the canonical source; caching would introduce staleness |

**Key insight:** Widget views are stateless renderers — all non-trivial computation belongs in `WidgetDataProvider.build()`, which is already the project's established pattern.

---

## WID-02 Mutation Site Audit (Completed)

This audit was performed by reading all relevant source files. Results are definitive.

| Site | File | Mutation | Reload Path | Gap? |
|------|------|----------|-------------|------|
| `GoalViewModel.addGoal()` | `GoalViewModel.swift:125` | Add new goal | `reloadWidgetTimelines()` (private method → `WidgetCenter.shared.reloadAllTimelines()`) | None |
| `GoalViewModel.addGoal(input:)` | `GoalViewModel.swift:314` | Wizard add goal | `reloadWidgetTimelines()` | None |
| `GoalViewModel.addCheckIn()` | `GoalViewModel.swift:215` | Daily check-in | `reloadWidgetTimelines()` | None |
| `GoalViewModel.toggleCompletion()` | `GoalViewModel.swift:152` | Toggle goal complete | `reloadWidgetTimelines()` | None |
| `GoalViewModel.updateGoal()` | `GoalViewModel.swift:294` | Edit goal | `reloadWidgetTimelines()` | None |
| `GoalViewModel.updateGoal(input:)` | `GoalViewModel.swift:340` | Wizard edit goal | `reloadWidgetTimelines()` | None |
| `GoalViewModel.delete()` | `GoalViewModel.swift:346` | Delete goal | `reloadWidgetTimelines()` | None |
| `GoalViewModel.updateGoalPublicStatus()` | `GoalViewModel.swift:354` | Toggle public/private | `WidgetCenter.shared.reloadAllTimelines()` direct | None |
| **`StatsView` freeze handler** | **`StatsView.swift:106`** | **Streak freeze** | **MISSING** | **YES — fix required (D-08)** |
| `GoalGifterCard.addGiftedGoal()` | `GoalGifterCard.swift:115` | Gifter add goal | Calls `goalVM.addGoal(input:context:)` → `GoalViewModel.reloadWidgetTimelines()` | None (transitive) |
| `StuckDayGiftsSection.addStuckDayGift()` | `StuckDayGiftsSection.swift:87` | Stuck day gift add | Calls `goalVM.addGoal(input:context:)` → `GoalViewModel.reloadWidgetTimelines()` | None (transitive) |
| `GoalDetailView` check-in | `GoalDetailView.swift:352` | Goal check-in | Calls `viewModel.addCheckIn()` → `GoalViewModel.reloadWidgetTimelines()` | None (transitive) |
| `GoalListView` toggle completion | `GoalListView.swift:222` | Toggle complete | Calls `viewModel.toggleCompletion()` → `GoalViewModel.reloadWidgetTimelines()` | None (transitive) |
| `GoalDetailView` toggle completion | `GoalDetailView.swift:506` | Toggle complete | Calls `viewModel.toggleCompletion()` → `GoalViewModel.reloadWidgetTimelines()` | None (transitive) |

**Summary:** One gap confirmed. All other v2.0 mutation sites are covered, either directly in `GoalViewModel` or transitively through `goalVM.addGoal()/addCheckIn()/toggleCompletion()` calls in View files. No separate `StreakFreezeView` exists — freeze is inline in `StatsView`.

[VERIFIED: codebase grep across all `.swift` files for `reloadAllTimelines` and `reloadWidgetTimelines`; read of `StatsView.swift`, `GoalGifterCard.swift`, `StuckDayGiftsSection.swift`, `GoalDetailView.swift`, `GoalListView.swift`]

---

## Common Pitfalls

### Pitfall 1: Breaking `WidgetDisplayData` struct initialization
**What goes wrong:** Adding new required (non-optional, no-default) fields to `WidgetDisplayData` causes compile errors at all existing call sites, including `WidgetDisplayData.placeholder` and `WidgetDisplayData.empty`.
**Why it happens:** Swift structs with memberwise initializers require all fields at construction.
**How to avoid:** New fields must have defaults OR both `placeholder` and `empty` static instances must be updated simultaneously with the struct definition. The new fields (`activeGoalTitle: String?` and `activeGoalProgress: Double?`) are optional, so they default to `nil` if a default is added — but the static instances must be updated explicitly per 24-UI-SPEC.md.
**Warning signs:** Compiler error "missing argument for parameter 'activeGoalTitle' in call".

### Pitfall 2: SwiftData fetch in `placeholder()` or `getSnapshot()`
**What goes wrong:** Attempting `WidgetContainerCache.shared` in `placeholder()` causes a crash or hang because widget gallery rendering does not have a valid model container context.
**Why it happens:** Widget gallery calls `placeholder()` outside the normal app process lifecycle.
**How to avoid:** Both `placeholder()` and `getSnapshot()` return `GoalEntry(date: .now, displayData: .placeholder)` — static data only. Only `getTimeline()` fetches from SwiftData.
**Warning signs:** Widget crashes in the gallery or on first add; `GoalSummaryProvider.placeholder` returns real data.

### Pitfall 3: `WidgetDataProvider` import contamination
**What goes wrong:** Adding `import SwiftUI` or `import SwiftData` to `WidgetDataProvider.swift` makes it impossible to unit-test the struct independently and violates the established pure-struct pattern.
**Why it happens:** The active goal computation uses `Goal` model properties — temptation to add SwiftData import.
**How to avoid:** `Goal` is already accessible without `import SwiftData` in the widget extension because the model is in the `VitaminG` module. Keep `import Foundation` only. The existing file has no framework imports beyond Foundation.
**Warning signs:** File gains any import beyond `Foundation`.

### Pitfall 4: `GoalSummaryWidgetView` retains `TierRowView` loop
**What goes wrong:** Leaving the `TierRowView` ForEach + Divider + footer streak HStack creates a layout that is both the old and new design — double-renders, overflow, incorrect final layout.
**Why it happens:** Partial edit of `body` without removing the old `TierRowView` struct.
**How to avoid:** Delete the entire `TierRowView` private struct from `GoalSummaryWidget.swift`. The new `GoalSummaryWidgetView.body` does not reference it.
**Warning signs:** Widget preview shows more than two rows; `TierRowView` still compiles.

### Pitfall 5: `WidgetDisplayData.tierRows` still used by `StreakWidgetView`
**What goes wrong:** If `tierRows` is removed from `WidgetDisplayData` to "clean up", `StreakWidgetView` State B (`entry.displayData.tierRows.first(where: { $0.tier == .immediate })?.topGoalTitle`) breaks.
**Why it happens:** `StreakWidget` is read-only (no changes this phase) but still depends on `tierRows`.
**How to avoid:** D-05 explicitly says "Existing `tierRows` field is retained if needed for backward compat". Keep `tierRows` in the struct. The new `GoalSummaryWidgetView` simply ignores it at render time.
**Warning signs:** `StreakWidgetView` shows `nil`/empty for the Immediate goal fallback.

### Pitfall 6: GeometryReader height not fixed
**What goes wrong:** `GeometryReader` in SwiftUI expands to fill available space by default. Without `.frame(height: 4)` after it, the progress bar row consumes all vertical space in the widget, pushing the goal title out.
**Why it happens:** `GeometryReader` does not constrain its own height.
**How to avoid:** Always follow `GeometryReader { ... }` with `.frame(height: 4)` to constrain the row height to match the Capsule height.
**Warning signs:** Widget preview shows only streak row with a large empty area below it.

---

## Code Examples

### GoalSummaryWidget.description update
```swift
// Source: 24-UI-SPEC.md Copywriting Contract
.description("Your active goal and current streak at a glance.")
// Replaces: "See your top goal for each tier at a glance."
```

### WidgetDisplayData.placeholder update
```swift
// Source: 24-UI-SPEC.md WidgetDisplayData Extension Contract
static let placeholder = WidgetDisplayData(
    tierRows: [
        TierRow(tier: .immediate, topGoalTitle: "Meditate for 10 minutes"),
        TierRow(tier: .shortTerm, topGoalTitle: "Read 12 books this quarter"),
        TierRow(tier: .longTerm, topGoalTitle: "Run a half marathon"),
        TierRow(tier: .lifeGoal, topGoalTitle: "Write a novel"),
    ],
    globalStreak: 7,
    activeGoalTitle: "Meditate for 10 minutes",
    activeGoalProgress: 0.43
)
```

### WidgetDisplayData.empty update
```swift
// Source: 24-UI-SPEC.md WidgetDisplayData Extension Contract
static let empty = WidgetDisplayData(
    tierRows: GoalTier.ordered.map { TierRow(tier: $0, topGoalTitle: nil) },
    globalStreak: 0,
    activeGoalTitle: nil,
    activeGoalProgress: nil
)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 4-tier row layout (TierRowView) | 2-row equal-split (streak + active goal) | Phase 24 (this phase) | Widget communicates one actionable goal instead of four tiers of context |
| No progress visualization | Thin 4pt Capsule progress bar | Phase 24 (this phase) | Visual feedback on goal completion pacing |
| Streak count only in footer | Streak count promoted to primary row | Phase 24 (this phase) | Streak is the primary motivating metric for daily users |

**No deprecated APIs in scope.** `StaticConfiguration` with `TimelineProvider` is current WidgetKit API. `AppIntentConfiguration` (interactive widgets) is deferred to v3.0.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (existing `VitaminGTests` target) |
| Config file | Xcode target `VitaminGTests` |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -testClass Phase24WidgetDataProviderTests 2>&1 | tail -20` |
| Full suite command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WID-01 | Active goal selection: Immediate tier wins over Short Term | unit | `xcodebuild test ... -testClass Phase24WidgetDataProviderTests -only-testing:.../test_activeGoal_immediateWinsOverShortTerm` | ❌ Wave 0 |
| WID-01 | Active goal selection: earliest creationDate within tier | unit | `-only-testing:.../test_activeGoal_earliestCreationDate` | ❌ Wave 0 |
| WID-01 | Progress computation: clamped to 0.0–1.0 | unit | `-only-testing:.../test_activeGoalProgress_clampedToUnit` | ❌ Wave 0 |
| WID-01 | nil progress when durationDays is nil | unit | `-only-testing:.../test_activeGoalProgress_nilWhenNoDuration` | ❌ Wave 0 |
| WID-01 | Empty state: no active goals → activeGoalTitle nil | unit | `-only-testing:.../test_activeGoal_nilWhenAllCompleted` | ❌ Wave 0 |
| WID-01 | placeholder carries new fields with sample values | unit | `-only-testing:.../test_placeholder_hasActiveGoalFields` | ❌ Wave 0 |
| WID-01 | empty carries nil for new fields | unit | `-only-testing:.../test_empty_hasNilActiveGoalFields` | ❌ Wave 0 |
| WID-02 | Existing WidgetDataProviderTests still pass | unit | `-testClass WidgetDataProviderTests` | ✅ `WidgetDataProviderTests.swift` |

### Sampling Rate
- **Per task commit:** Run `WidgetDataProviderTests` + `Phase24WidgetDataProviderTests`
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `VitaminGTests/Phase24WidgetDataProviderTests.swift` — covers WID-01 new `activeGoalTitle`/`activeGoalProgress` logic in `WidgetDataProvider.build()`

*(Existing `WidgetDataProviderTests.swift` covers the pre-Phase-24 behavior — no changes needed to that file, but new test cases for the new fields belong in a dedicated Phase24 file per project convention.)*

---

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Widget is read-only, no auth actions |
| V3 Session Management | No | Widgets have no session |
| V4 Access Control | No | Widget reads local SwiftData only — no remote access |
| V5 Input Validation | No | `activeGoalTitle` is `goal.title` already validated at insertion time by `GoalViewModel.validate()`; widget only reads it |
| V6 Cryptography | No | No secrets in widget scope |

**Threat patterns for WidgetKit/SwiftData:**

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Widget reads unvalidated goal titles from SwiftData | Information Disclosure | Not a concern — SwiftData is private app container; titles are already sanitized at input by `InputSanitizer.sanitize()` |
| App Group container accessible to other app extensions | Information Disclosure | App Group is scoped to `group.com.kyleharrington.VitaminG` — no third-party extensions in project |

No security changes required in this phase.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode | Build/test | ✓ | (existing — project already compiling) | — |
| iOS Simulator | Unit tests | ✓ | (existing — prior phases tested) | — |
| App Groups entitlement | `WidgetContainerCache.shared` | ✓ | Already configured — Phase 4 | — |
| WidgetKit framework | Widget extension | ✓ | iOS 17+ — already in use | — |

No new environment setup required.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `GoalDetailView` check-in path calls `viewModel.addCheckIn()` (GoalViewModel) which already routes through `reloadWidgetTimelines()` | WID-02 Audit | Low — confirmed by reading GoalDetailView.swift line 352 calling `viewModel.addCheckIn()` and GoalViewModel.addCheckIn() line 215 calling `reloadWidgetTimelines()` |
| A2 | No separate `StreakFreezeView` file exists — freeze is entirely in `StatsView` | WID-02 Audit | Low — confirmed by filesystem search returning no results |
| A3 | `WidgetDataProvider` is in the app module (not widget extension) and accessible to both | Architecture | Low — confirmed by file path `VitaminG/Services/WidgetDataProvider.swift` |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed.

All items above are LOW risk and were verified by direct codebase read.

---

## Open Questions

None. All research questions resolved by codebase inspection. The UI-SPEC (24-UI-SPEC.md) is approved and provides a complete visual contract. No ambiguities remain.

---

## Sources

### Primary (HIGH confidence)
- `VitaminGWidget/GoalSummaryWidget.swift` — current widget layout verified
- `VitaminGWidget/StreakWidget.swift` — confirmed no-change; `tierRows` dependency verified
- `VitaminGWidget/WidgetTimelineEntry.swift` — `GoalEntry` struct confirmed
- `VitaminG/Services/WidgetDataProvider.swift` — struct shape, `build()` signature, static instances verified
- `VitaminG/Views/StatsView.swift` — missing `reloadAllTimelines()` after `freezeService.freeze()` confirmed at line 106
- `VitaminG/ViewModels/GoalViewModel.swift` — `reloadWidgetTimelines()` call sites at lines 125, 152, 215, 294, 314, 340, 346, 354 verified
- `VitaminG/Views/Explore/GoalGifterCard.swift` — transitive coverage via `goalVM.addGoal()` confirmed
- `VitaminG/Views/Explore/StuckDayGiftsSection.swift` — transitive coverage via `goalVM.addGoal()` confirmed at line 87
- `VitaminG/Models/Goal.swift` — `GoalTier.ordered = [.immediate, .shortTerm, .longTerm, .lifeGoal]` confirmed
- `VitaminG/VGTheme.swift` — `accentTerra` adaptive token confirmed
- `.planning/phases/24-widget-enhancements/24-UI-SPEC.md` — approved layout contract verified
- `.planning/phases/24-widget-enhancements/24-CONTEXT.md` — all decisions D-01 through D-09 verified
- `VitaminGTests/WidgetDataProviderTests.swift` — existing test coverage baseline verified
- `CLAUDE.md` (project) — no third-party dependencies, iOS 17+, Swift/SwiftUI/SwiftData only

### Secondary (MEDIUM confidence)
- `.planning/STATE.md` — push-only widget policy and App Group pattern confirmed as deliberate architecture decisions

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all system frameworks, no new packages
- Architecture: HIGH — existing patterns are clear and confirmed by reading all target files
- Pitfalls: HIGH — derived from direct code reading, not training knowledge
- WID-02 audit: HIGH — exhaustive grep across all Swift files for reload calls

**Research date:** 2026-05-27
**Valid until:** 2026-06-27 (30 days — stable iOS SDK; no fast-moving dependencies)
