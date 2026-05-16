# Phase 4: iCloud Sync & Widgets - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Goal data syncs transparently across the user's devices and appears on the home screen and lock screen via read-only widgets that share the same App Group store. No manual sync button. Onboarding and polish are Phase 5 scope.

</domain>

<decisions>
## Implementation Decisions

### iCloud Sync UX
- **D-01:** Sync is truly invisible — no sync status indicator, no spinner, no "last synced" row in Settings. CloudKit sync is an expectation, not a feature to surface.
- **D-02:** Settings shows the current global streak count (e.g., 🔥 12 days) as a motivational element. This is the dopamine hit — a reason to open the app daily. Not related to sync; it's a persistent motivational anchor.

### Home Screen Widget (systemMedium)
- **D-03:** The widget displays 4 tier rows (Immediate → Short-Term → Long-Term → Life Goal). Each row shows the top active goal for that tier with its tier color and icon. Empty tiers show a gentle prompt (e.g., "No Immediate goals yet").
- **D-04:** A footer row at the bottom of the widget shows the global streak count (e.g., 🔥 12 days). If streak is 0, the footer is omitted or shows a neutral encouragement.

### Lock Screen Widget (accessoryRectangular)
- **D-05:** Smart display logic: show global streak count (e.g., "🔥 12 days") if streak > 0; fall back to the top active Immediate goal title when streak is 0. The widget always has something meaningful to show.

### Widget Refresh Strategy
- **D-06:** Timeline refreshes once daily (morning, aligned with the notification time set by the user). The main app calls `WidgetCenter.shared.reloadAllTimelines()` after any goal add, edit, delete, or completion toggle. Best balance of data freshness and battery.

### Widget Data Pipeline
- **D-07:** Widgets read directly from the shared App Group SwiftData store using the same `ModelContainerFactory.makeContainer()` pattern already established. Widget process creates its own `ModelContainer` with the group container identifier. No separate JSON/plist snapshot needed — the infrastructure is already in place.

### Claude's Discretion
- Exact widget visual design (spacing, typography, line truncation for long goal titles)
- Empty tier prompt copy in the home screen widget
- Widget display name and description strings in Xcode
- Exact footer layout when streak is 0 (omit vs. neutral copy)
- Unit test coverage pattern for widget timeline provider (follow StreakEngine/GoalSorter standalone struct pattern)

</decisions>

<specifics>
## Specific Ideas

- The streak in Settings is a dopamine hit — it should be visually prominent, not a small subtitle. Design it to celebrate the number, not just list it.
- Lock screen widget: streak-first when earned, goal title as fallback. This makes users feel rewarded when they've built a streak, and reminded of purpose when they haven't.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Widget target (existing stub)
- `VitaminG/VitaminG/VitaminGWidget/VitaminGWidgetBundle.swift` — Placeholder widget to replace in Phase 4; App Group entitlement already configured

### Shared data infrastructure
- `VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift` — Production ModelContainer with `groupContainer: .identifier("group.com.kyleharrington.VitaminG")` + `cloudKitDatabase: .automatic`; simulator guard already in place
- `VitaminG/VitaminG/VitaminG/Models/SchemaV1.swift` — Goal and CompletionEvent @Model definitions; widget must use same schema types
- `VitaminG/VitaminG/VitaminG/Models/Goal.swift` — GoalTier enum with colors, icons, `ordered` array; widget uses these for tier row rendering

### Streak computation
- `VitaminG/VitaminG/VitaminG/Services/StreakEngine.swift` — `currentStreak(from:tier:calendar:)` — widget uses this to compute global streak for footer and lock screen display

### Settings (for streak display addition)
- `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift` — Add streak motivational row to this view in Phase 4

### Requirements
- `SYNC-01`, `SYNC-02` — iCloud sync requirements (transparent, no manual action)
- `WIDGET-01` through `WIDGET-05` — Widget requirements including read-only, App Group store, daily refresh

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ModelContainerFactory.makeContainer()` — Same call works in widget process; simulator guard handles non-provisioned App Group in tests
- `StreakEngine.currentStreak(from:)` — Pure struct, no SwiftUI/SwiftData dependency; can be imported into widget target or duplicated (widget bundles cannot import app module code)
- `GoalTier.ordered`, `GoalTier.color`, `GoalTier.icon` — Widget tier rows use these directly for visual consistency

### Established Patterns
- Standalone testable structs (no SwiftUI/SwiftData dependency) — StreakEngine and GoalSorter set this pattern; widget timeline provider logic should follow the same pattern
- `@Observable` ViewModels are app-target only — widgets use TimelineProvider (no ViewModel layer)
- `#if targetEnvironment(simulator)` guard in ModelContainerFactory — widget target needs this same guard (widgets run in simulator during development)

### Integration Points
- `GoalViewModel` calls needed in main app after goal mutations: `WidgetCenter.shared.reloadAllTimelines()` — add to `addGoal`, `updateGoal`, `deleteGoal`, `toggleCompletion`
- `VitaminGWidgetBundle` — replace `VitaminGWidgetPlaceholder` with real `GoalSummaryWidget` (systemMedium) and `StreakWidget` (accessoryRectangular)
- `SettingsView` — add streak count row (D-02) reading from SwiftData via injected CompletionEvent data

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 04-icloud-sync-widgets*
*Context gathered: 2026-04-06*
