# Phase 2: Core Goal UI - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Full goal CRUD — create, view, edit, complete, reactivate, delete — across all four tiers, with a visually distinct UI per tier. Phase 2 makes the app fully usable as a daily goal-tracking tool. Statistics, notifications, widgets, and onboarding are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Goal detail + navigation
- **D-01:** Tapping a goal row navigates to `GoalDetailView` via `NavigationLink`. The row shows title + tier pip; the detail shows all fields.
- **D-02:** `associatedInspiration` is displayed as a **quote card** — large italic text on a subtle tier-color tinted background — on the detail view. This is the primary "prominent display" treatment required by UI-03.
- **D-03:** `AppRoute` gains `.goalDetail(Goal)` case (and any other cases needed) in Phase 2 to enable programmatic navigation.

### Edit UX
- **D-04:** Editing reuses `AddGoalView` as `EditGoalView` — same sheet form, pre-populated with the goal's current values. Launched from a toolbar **Edit** button on `GoalDetailView` (trailing position, standard iOS pattern).
- **D-05:** No in-place editing on the detail view — save action is explicit via the form's Save button, consistent with validation pattern already in place.

### Sort / filter
- **D-06:** Sort UI lives in a **toolbar menu** (sort icon, `.menu` button style) on `GoalListView`. Three options: Sort by Tier, Sort by Creation Date, Sort by Completion Status.
- **D-07:** Default sort is **by tier** — Immediate → Short-Term → Long-Term → Life Goal, matching the Phase 1 `GoalTier.ordered` array already used.
- **D-08:** When sorted by completion status: active goals first (grouped by tier within that group), completed goals below.

### Completed goals visual treatment
- **D-09:** Completed goals remain inline within their tier section, positioned below active goals in that section.
- **D-10:** The completion visual treatment should feel **celebratory and motivating** — completed goals should make the user feel good about their progress, not just show a strikethrough. The exact treatment (subtle background, animation, badge, etc.) is Claude's discretion via the UI-SPEC, but the principle is: completion = reward, not just a state change.

### Tier picker in Add/Edit form
- **D-11:** Replace the `.navigationLink` Picker in `AddGoalView` with a **custom 4-option visual picker** — a 2×2 card grid, each card showing the tier's color, icon, and display name. No navigation needed — instant inline selection. More visual, reinforces the tier identity system.

### Claude's Discretion
- Navigation title copy for `GoalListView` (e.g., "My Goals", greeting, app name — pick what best fits the warm tone)
- Goal row information density beyond title + description preview + tier pip (keep minimal or add date)
- Exact completion celebration animation/visual treatment (principle: celebratory, see D-10)
- Loading skeleton, error states
- Transition animations between list and detail

</decisions>

<specifics>
## Specific Ideas

- Completion should make the user feel good and motivate them to complete more goals — it's a positive reinforcement loop, not just a status update. The UI phase should design this with that emotional goal in mind.
- The app tone is warm and reflective, not productivity-aggressive (PROJECT.md constraint) — this applies to copy, empty states, and completion states throughout.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 1 source of truth (what's already built)
- `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` — ViewModel API: addGoal, updateGoal (to be added), delete, toggleCompletion, draft state, isDraftValid, sanitize, validate
- `VitaminG/VitaminG/VitaminG/Models/Goal.swift` — GoalTier enum with colors, icons, typographic weights, `ordered` array
- `VitaminG/VitaminG/VitaminG/Models/SchemaV1.swift` — Goal and CompletionEvent @Model definitions, typealiases
- `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift` — Existing list view, GoalRowView, TierSectionView, EmptyStateView (all Phase 1 code)
- `VitaminG/VitaminG/VitaminG/Views/AddGoalView.swift` — Form pattern to reuse for EditGoalView; CharacterCountView, TierFooterView helpers
- `VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift` — Stub enum awaiting Phase 2 cases
- `VitaminG/VitaminG/VitaminG/Navigation/AppRouter.swift` — @Observable navigation controller

### Requirements
- `.planning/REQUIREMENTS.md` §Goal Management — GOAL-01 through GOAL-07
- `.planning/REQUIREMENTS.md` §UI & Design — UI-01 through UI-03

### Phase summaries (decisions from Phase 1)
- `.planning/phases/01-foundation/01-01-SUMMARY.md` — Data layer decisions (SchemaV1, App Group, CloudKit)
- `.planning/phases/01-foundation/01-02-SUMMARY.md` — MVVM scaffold decisions (AppRouter injection, AppRoute stub)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `GoalListView` — Already built with tier sections, swipe-to-delete, add-sheet, empty state, toggle. Phase 2 adds: NavigationLink on rows, sort toolbar, completed visual treatment.
- `AddGoalView` — Full form with all fields, CharacterCountView, TierFooterView, validation error alert, Save/Cancel. Reuse as EditGoalView by accepting an optional `Goal` parameter and pre-filling draft state.
- `TierSectionView` — Reusable header component showing tier color + icon + name. Use in detail view for tier badge.
- `GoalRowView` — Has completion toggle, title, description preview, tier pip already. Phase 2 wraps in NavigationLink.
- `GoalTier.color`, `.icon`, `.typographicWeight` — All tier visual identity properties are locked in and reusable.

### Established Patterns
- `@Observable` ViewModels (no `@Published`, no `ObservableObject`)
- `@Environment(\.modelContext)` for SwiftData operations — no direct model injection
- Sheet presentation for create/edit flows
- `.confirmationDialog` for destructive actions (delete already uses this)
- `.insetGrouped` List style for all list screens
- `CharacterCountView` for live char limit feedback

### Integration Points
- `AppRoute` enum must gain new cases for navigation (`.goalDetail(Goal)` at minimum)
- `AppRouter.navigate(_ route:)` is the entry point for programmatic navigation
- `ContentView` has `NavigationStack` with `AppRouter` path binding — new views register as `.navigationDestination(for: AppRoute.self)`
- `GoalViewModel.addGoal()` is the add path — need to add `updateGoal(goal:context:)` for editing

</code_context>

<deferred>
## Deferred Ideas

- Per-tier empty state placeholder rows with add prompts (ONBOARD-04 scope — Phase 5)
- Long-press context menu on rows as secondary edit entry point — not needed since toolbar Edit button covers GOAL-03

</deferred>

---

*Phase: 02-core-goal-ui*
*Context gathered: 2026-04-04*
