# Phase 2: Core Goal UI - Research

**Researched:** 2026-04-04
**Domain:** SwiftUI navigation, SwiftData CRUD, iOS goal management UI patterns
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Tapping a goal row navigates to `GoalDetailView` via `NavigationLink`. The row shows title + tier pip; the detail shows all fields.
- **D-02:** `associatedInspiration` is displayed as a **quote card** — large italic text on a subtle tier-color tinted background — on the detail view. This is the primary "prominent display" treatment required by UI-03.
- **D-03:** `AppRoute` gains `.goalDetail(Goal)` case (and any other cases needed) in Phase 2 to enable programmatic navigation.
- **D-04:** Editing reuses `AddGoalView` as `EditGoalView` — same sheet form, pre-populated with the goal's current values. Launched from a toolbar **Edit** button on `GoalDetailView` (trailing position, standard iOS pattern).
- **D-05:** No in-place editing on the detail view — save action is explicit via the form's Save button, consistent with validation pattern already in place.
- **D-06:** Sort UI lives in a **toolbar menu** (sort icon, `.menu` button style) on `GoalListView`. Three options: Sort by Tier, Sort by Creation Date, Sort by Completion Status.
- **D-07:** Default sort is **by tier** — Immediate → Short-Term → Long-Term → Life Goal, matching the Phase 1 `GoalTier.ordered` array already used.
- **D-08:** When sorted by completion status: active goals first (grouped by tier within that group), completed goals below.
- **D-09:** Completed goals remain inline within their tier section, positioned below active goals in that section.
- **D-10:** Completion visual treatment should feel **celebratory and motivating** — exact treatment is Claude's discretion, but the principle is: completion = reward, not just a state change.
- **D-11:** Replace the `.navigationLink` Picker in `AddGoalView` with a **custom 4-option visual picker** — a 2×2 card grid, each card showing the tier's color, icon, and display name.

### Claude's Discretion

- Navigation title copy for `GoalListView` (e.g., "My Goals", greeting, app name — pick what best fits the warm tone)
- Goal row information density beyond title + description preview + tier pip (keep minimal or add date)
- Exact completion celebration animation/visual treatment (principle: celebratory, see D-10)
- Loading skeleton, error states
- Transition animations between list and detail

### Deferred Ideas (OUT OF SCOPE)

- Per-tier empty state placeholder rows with add prompts (ONBOARD-04 scope — Phase 5)
- Long-press context menu on rows as secondary edit entry point — not needed since toolbar Edit button covers GOAL-03
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GOAL-01 | User can create a goal with title, description (optional), tier selection, and associatedInspiration (optional) | `addGoal()` + draft state fully implemented in GoalViewModel; D-11 custom tier picker replaces navigationLink Picker |
| GOAL-02 | User can view all goals grouped and visually distinguished by tier | `GoalListView` + `TierSectionView` already built; Phase 2 adds sort and NavigationLink wrapping |
| GOAL-03 | User can edit any goal field after creation | `updateGoal()` method to add to GoalViewModel; EditGoalView reuses AddGoalView form pre-populated via optional `Goal` param |
| GOAL-04 | User can delete a goal (with confirmation) | `delete()` + `.confirmationDialog` already in GoalListView; detail view needs swipe-delete or delete button |
| GOAL-05 | User can mark goal complete — creates CompletionEvent with timestamp and tier | `toggleCompletion()` already implemented; Phase 2 adds celebratory visual treatment |
| GOAL-06 | Completed goals remain visible (with visual distinction) and can be re-activated | Toggle already re-activates; D-09 positions completed inline below active within tier |
| GOAL-07 | Goal list is sortable by tier, creation date, and completion status | New sort state enum + computed sort logic needed in GoalListView; D-06 toolbar menu |
| UI-01 | Each tier has distinct visual identity (color, icon, weight) | Already fully implemented in `GoalTier`; D-11 custom picker reinforces this |
| UI-02 | App tone is warm and reflective — copy and design enforce this | Applies to empty states, completion copy, navigation title, tier descriptions |
| UI-03 | `associatedInspiration` prominently displayed on goal detail view | D-02 quote card: large italic on tier-color tinted background |
</phase_requirements>

---

## Summary

Phase 2 is a pure SwiftUI/SwiftData phase with zero new external dependencies. The data model (`SchemaV1`), validation logic (`GoalViewModel`), and navigation scaffold (`AppRouter`, `AppRoute`) are all built. The primary work is: (1) adding `GoalDetailView` and wiring it into `NavigationLink` via `AppRoute.goalDetail`; (2) creating `EditGoalView` (AddGoalView reused with pre-population); (3) adding `updateGoal()` to `GoalViewModel`; (4) implementing the sort toolbar and sort logic in `GoalListView`; (5) replacing the navigationLink Picker with a custom 2×2 tier card picker; and (6) designing the completion celebration state.

The most technically non-trivial aspect is the sort state management in `GoalListView`. Currently the view uses a `@Query(sort: \Goal.createdAt)` that cannot be conditionally re-sorted at runtime — the pattern for dynamic sort in SwiftData is to either re-declare the `@Query` with a different sort descriptor (not directly possible in SwiftUI) or maintain a separate `@State` sort key and sort the fetched array in a computed property. The computed-property approach is correct and aligns with the existing `goals(for tier:)` pattern already in use.

`AppRoute` must gain `Hashable` conformance for `Goal` — `Goal` is a SwiftData `@Model` class and is already `PersistentModel`, which provides an identity-based `==` and `hash`. Passing a `Goal` in a route enum case requires that `Goal` is `Hashable`, which `PersistentModel` satisfies via `ModelIdentifier`. This is a confirmed, safe pattern.

**Primary recommendation:** Build in four sequential waves: (1) GoalDetailView + AppRoute + NavigationLink wiring; (2) EditGoalView + updateGoal() ViewModel method; (3) Sort toolbar + sort logic; (4) Custom tier picker + completion visual treatment. Each wave is independently testable.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All UI: NavigationStack, List, Sheet, Form, Toolbar | Project constraint — no UIKit |
| SwiftData | iOS 17+ | `@Query` for live data, `ModelContext` for writes | Already in use — SchemaV1 locked |
| Observation (`@Observable`) | iOS 17+ | GoalViewModel state, AppRouter | Already established pattern |
| SF Symbols | 5+ (iOS 17+) | All icons — tier icons, sort icon, completion toggle | Zero dependency, built in |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SwiftUI `.animation()` | iOS 17+ | Completion celebration, list reorder | On all state-driven visual transitions |
| SwiftUI `symbolEffect` | iOS 17+ | Checkmark bounce on completion | `.bounce` for celebratory toggle |
| SwiftUI `.matchedGeometryEffect` | iOS 17+ | Optional: smooth transitions | Only if list-to-detail transition needs it |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Computed-property sort | Re-declared `@Query` with `SortDescriptor` | `@Query` cannot be dynamic at runtime in SwiftUI — computed property on fetched results is the correct pattern |
| Sheet for EditGoalView | Full navigation push | Sheet is consistent with create flow (AddGoalView); D-04 locks this |
| `.confirmationDialog` for delete | `.alert` | `.confirmationDialog` already in use in GoalListView; maintain consistency |

**Installation:** No new packages. All frameworks are already linked.

---

## Architecture Patterns

### Recommended Project Structure (Phase 2 additions)

```
VitaminG/
├── Models/
│   ├── SchemaV1.swift       # EXISTING — Goal, CompletionEvent
│   └── Goal.swift           # EXISTING — GoalTier enum
├── ViewModels/
│   └── GoalViewModel.swift  # MODIFY — add updateGoal(), add SortOption enum
├── Views/
│   ├── GoalListView.swift   # MODIFY — add NavigationLink, sort toolbar, completed state
│   ├── GoalDetailView.swift # CREATE — detail, quote card, edit/delete toolbar
│   ├── AddGoalView.swift    # MODIFY — optional Goal param for edit pre-population, custom tier picker
│   └── TierPickerView.swift # CREATE — 2×2 card grid for tier selection (D-11)
└── Navigation/
    ├── AppRoute.swift       # MODIFY — add .goalDetail(Goal) case
    └── AppRouter.swift      # EXISTING — no changes needed
```

### Pattern 1: AppRoute with SwiftData Model as Associated Value

**What:** `AppRoute` gains `.goalDetail(Goal)`. `Goal` is a SwiftData `@Model` class. `NavigationStack` requires route types to be `Hashable`. `PersistentModel` protocol (which `@Model` classes conform to) provides identity-based `Hashable` through `ModelIdentifier`, so `Goal` satisfies `Hashable` automatically.

**When to use:** Whenever navigating to a view bound to a specific persisted model instance.

**Example:**
```swift
// AppRoute.swift
enum AppRoute: Hashable {
    case goalDetail(Goal)
}

// ContentView.swift — navigationDestination
.navigationDestination(for: AppRoute.self) { route in
    switch route {
    case .goalDetail(let goal):
        GoalDetailView(goal: goal)
    }
}

// GoalListView.swift — NavigationLink in row
NavigationLink(value: AppRoute.goalDetail(goal)) {
    GoalRowView(goal: goal, onToggle: { ... })
}
```

**Confidence:** HIGH — `@Model` conforms to `PersistentModel` which bridges to `Hashable` via `ModelIdentifier`. This is a documented SwiftData + NavigationStack pattern.

### Pattern 2: Dynamic Sort Without Re-Declaring @Query

**What:** `@Query` sort descriptors are fixed at declaration time in SwiftUI. For user-driven sort changes, maintain a `@State var sortOption: SortOption` and sort the `goals` array in a computed property.

**When to use:** Any time the user controls sort order at runtime.

**Example:**
```swift
// GoalViewModel additions (or inline in GoalListView)
enum SortOption {
    case byTier, byCreationDate, byCompletionStatus
}

// GoalListView
@Query private var goals: [Goal]          // base fetch — no sort descriptor needed
@State private var sortOption: SortOption = .byTier

private var sortedGoals: [Goal] {
    switch sortOption {
    case .byTier:
        return goals.sorted { GoalTier.ordered.firstIndex(of: $0.tier)! < GoalTier.ordered.firstIndex(of: $1.tier)! }
    case .byCreationDate:
        return goals.sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
    case .byCompletionStatus:
        return goals.sorted { !$0.completed && $1.completed }
    }
}
```

**Note on D-08 (completion sort):** When sorted by completion status, active goals first grouped by tier within that group. The `byCompletionStatus` case should sort primarily by `!isCompleted` then secondarily by tier order.

**Note on D-09 (inline completed per tier section):** When sorted by tier (the default), each tier section shows active goals first, then completed goals below within the same section. The `goals(for tier:)` helper should be extended to sort active before completed within a tier.

### Pattern 3: EditGoalView via AddGoalView Re-Use

**What:** `AddGoalView` accepts an optional `Goal?` parameter. When non-nil, the view pre-populates the ViewModel's draft state from the goal's current values. The Save button calls `updateGoal()` instead of `addGoal()`.

**When to use:** D-04 locks this pattern.

**Example:**
```swift
// AddGoalView.swift — modified signature
struct AddGoalView: View {
    @Bindable var viewModel: GoalViewModel
    let editingGoal: Goal?   // nil = create, non-nil = edit
    
    // onAppear pre-populates:
    // viewModel.draftTitle = editingGoal?.title ?? ""
    // viewModel.draftTier  = editingGoal?.tier ?? .immediate
    // etc.
}

// GoalViewModel — new method
func updateGoal(_ goal: Goal, context: ModelContext) throws {
    let cleanTitle       = sanitize(draftTitle)
    let cleanDescription = sanitize(draftDescription)
    let cleanInspiration = sanitize(draftInspiration)
    try validate(title: cleanTitle, description: cleanDescription, inspiration: cleanInspiration)
    goal.title                 = cleanTitle
    goal.goalDescription       = cleanDescription.isEmpty ? nil : cleanDescription
    goal.tierRawValue          = draftTier.rawValue
    goal.associatedInspiration = cleanInspiration.isEmpty ? nil : cleanInspiration
    // SwiftData auto-saves on context change
}
```

### Pattern 4: Custom 2×2 Tier Picker (D-11)

**What:** Replace `.pickerStyle(.navigationLink)` with an inline card grid. Each of the 4 `GoalTier` cases renders as a tappable card with its color, SF Symbol icon, and display name. Selected tier gets a colored border/background. No navigation needed.

**When to use:** D-11 locks this.

**Example:**
```swift
struct TierPickerView: View {
    @Binding var selectedTier: GoalTier

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(GoalTier.ordered) { tier in
                TierCardView(tier: tier, isSelected: selectedTier == tier)
                    .onTapGesture { selectedTier = tier }
            }
        }
    }
}
```

### Pattern 5: Quote Card for associatedInspiration (D-02)

**What:** On `GoalDetailView`, display `associatedInspiration` as a styled card: italic text at body+/title3 size, on a `tier.color.opacity(0.12)` rounded-rectangle background. Shows only when `associatedInspiration` is non-nil and non-empty.

**Example:**
```swift
if let inspiration = goal.associatedInspiration, !inspiration.isEmpty {
    VStack(alignment: .leading, spacing: 8) {
        Text("Inspiration")
            .font(.caption.weight(.semibold))
            .foregroundStyle(goal.tier.color)
        Text(""\(inspiration)"")
            .font(.title3.italic())
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(goal.tier.color.opacity(0.12))
    )
}
```

### Pattern 6: Completion Celebration

**What:** When a goal is toggled to completed, the checkmark icon should animate with `.symbolEffect(.bounce)` (already using `.contentTransition(.symbolEffect(.replace))` in GoalRowView — upgrade to bounce). Optionally add a brief scale/opacity transition on the row background. The completed state visual: soft tier-color background tint on the row (e.g., `tier.color.opacity(0.06)`), strikethrough on title (already implemented), slightly reduced opacity on description.

The principle from D-10: completion = reward. A `.bounce` symbol effect plus a brief colored flash on the row background is celebratory without being aggressive.

**Example:**
```swift
// GoalRowView completion toggle
Button(action: onToggle) {
    Image(systemName: goal.completed ? "checkmark.circle.fill" : "circle")
        .font(.title3)
        .foregroundStyle(goal.completed ? goal.tier.color : .secondary)
        .symbolEffect(.bounce, value: goal.completed)  // bounce on completion
}
.buttonStyle(.plain)

// Row background for completed state
.listRowBackground(
    goal.completed 
        ? goal.tier.color.opacity(0.06)
        : Color(.secondarySystemGroupedBackground)
)
```

### Anti-Patterns to Avoid

- **Putting `SortOption` state in GoalViewModel as a shared property:** `GoalViewModel` is a `@State` instance owned by `GoalListView`. If the sort state lives there, it couples the ViewModel to list-specific UI state. Prefer `@State private var sortOption: SortOption` directly in `GoalListView`, or a lightweight `GoalListViewModel` if complexity warrants.
- **Using `@Query` sort descriptors for dynamic sort:** `@Query(sort:)` cannot be changed at runtime in a SwiftUI view. Attempting this leads to compile errors or inconsistent behavior.
- **Passing `modelContext` to AddGoalView for edit:** The existing `AddGoalView` already uses `@Environment(\.modelContext)` — do not add a constructor parameter for context. The edit path calls `viewModel.updateGoal(goal:context:)` where context comes from the environment, same as `addGoal`.
- **Adding `.goalDetail(Goal)` to route without verifying Goal is Hashable:** Goal is a `@Model` class which conforms to `PersistentModel`. This provides Hashable via `ModelIdentifier`. Do not manually add `Hashable` conformance to Goal — it's already satisfied.
- **Using `.alert` for delete confirmation in detail view:** Use `.confirmationDialog` to be consistent with GoalListView swipe-delete pattern already established.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Symbol animation on completion | Custom animation layer | `.symbolEffect(.bounce)` on SF Symbols | iOS 17 built-in, hardware-accelerated, single line |
| Tier color grid picker | Full custom drag/touch tracking | `LazyVGrid` + `onTapGesture` | SwiftUI grid handles layout; no gesture recognizer needed |
| Navigation push with type safety | String-keyed navigation or UIKit push | `NavigationLink(value:)` + `AppRoute` enum | Already scaffolded; type-safe, stack-managed |
| Edit form from scratch | New form with same fields | `AddGoalView` with optional `Goal?` param | D-04 locks reuse; avoids divergence |
| Sort logic in SwiftData query | Custom `NSFetchRequest` predicates | Swift `sorted(by:)` on `@Query` array | Simple array sort is correct pattern; no predicate complexity |
| Quote card rounded rect | `UIView` subclass or `CALayer` | SwiftUI `RoundedRectangle` + `fill()` | Declarative, animatable, no bridging |

**Key insight:** Every visual and navigation pattern required by this phase is natively available in SwiftUI + SF Symbols. There is no custom drawing, no gesture recognizer complexity, and no need for third-party libraries.

---

## Common Pitfalls

### Pitfall 1: AppRoute.goalDetail(Goal) Hashable Requirement

**What goes wrong:** Adding `case goalDetail(Goal)` to `AppRoute: Hashable` may surface a compiler warning or error if `Goal` is not recognized as `Hashable` at the call site.
**Why it happens:** `Goal` is a `@Model` class. `PersistentModel` satisfies `Hashable` by object identity (via `ModelIdentifier`). Xcode may not always infer this without an explicit import or if the model is in a different module.
**How to avoid:** If the compiler complains, add `@testable import VitaminG` or verify the `SchemaV1.Goal` typealias is in scope. Do not manually add `Hashable` conformance to `Goal` — it would conflict with the SwiftData-synthesized version.
**Warning signs:** "Type 'Goal' does not conform to protocol 'Hashable'" at the `AppRoute` enum declaration.

### Pitfall 2: @Query Sort vs. Computed Sort Divergence

**What goes wrong:** `GoalListView` has `@Query(sort: \Goal.createdAt)` as the base fetch. When implementing dynamic sort, the team adds `sortedGoals` computed property but forgets that the base `@Query` already imposes a `createdAt` sort. The computed sort then redundantly re-sorts an already-sorted array — harmless but wasteful.
**Why it happens:** The base `@Query` sort descriptor was added in Phase 1 for initial display order. Phase 2 introduces dynamic sort that supersedes it.
**How to avoid:** When adding dynamic sort, change the `@Query` to `@Query private var goals: [Goal]` (no sort descriptor) and let the computed sort handle all ordering. This avoids confusion about which sort is "authoritative."
**Warning signs:** Goals appearing in unexpected order when switching sort options.

### Pitfall 3: GoalViewModel Draft State Pollution Between Create and Edit

**What goes wrong:** `GoalViewModel` owns `draftTitle`, `draftDescription`, `draftTier`, `draftInspiration` as shared mutable state. If `EditGoalView` pre-populates these on appear, and the user dismisses without saving, the state is dirty. When the user then opens `AddGoalView` (new goal), the draft fields contain the previous edit's data.
**Why it happens:** `resetDraft()` is called on Cancel. If the dismiss callback doesn't call `resetDraft()`, state persists.
**How to avoid:** Always call `viewModel.resetDraft()` in the `EditGoalView` Cancel button action, matching `AddGoalView`'s existing Cancel behavior. Also call it in `.onDisappear` as a safety net.
**Warning signs:** Add-goal form showing data from a previously-cancelled edit session.

### Pitfall 4: NavigationLink vs. Button Tap Area Conflict in GoalRowView

**What goes wrong:** `GoalRowView` has a completion toggle `Button` inside the row. If the row is wrapped in `NavigationLink(value:)`, tapping the toggle also triggers navigation — both `Button` action and `NavigationLink` fire.
**Why it happens:** `NavigationLink` in a List makes the entire row tappable. An inner `Button` with `.buttonStyle(.plain)` competes for taps.
**How to avoid:** Use `NavigationLink(value:) { GoalRowView(...) }` and ensure the toggle button uses `.buttonStyle(.plain)` — SwiftUI's hit-testing gives `.plain` buttons priority over the surrounding NavigationLink. This is the standard pattern. Also set `.contentShape(Rectangle())` on the row for consistent hit testing.
**Warning signs:** Tapping the circle toggle navigates to the detail view instead of toggling completion.

### Pitfall 5: SwiftData Auto-Save Timing with updateGoal

**What goes wrong:** `updateGoal()` mutates properties on a `Goal` @Model instance. SwiftData automatically persists changes when the `ModelContext` saves (which happens automatically on app background or explicit `try context.save()`). If the test suite runs in-memory and doesn't trigger a save cycle, tests may see stale data.
**Why it happens:** SwiftData's auto-save is triggered by the run loop, not synchronously.
**How to avoid:** In `updateGoal()`, do not call `context.save()` explicitly — the existing `addGoal()` doesn't either, and the Phase 1 test suite is already designed around in-memory containers that save synchronously on `context.save()`. For Phase 2 tests of `updateGoal`, call `try context.save()` explicitly after the update before asserting.
**Warning signs:** XCTest assertions reading goal fields that still show pre-update values.

### Pitfall 6: Tier Section Ordering When Sorted by Completion Status

**What goes wrong:** D-08 says: when sorted by completion status, active goals first (grouped by tier within that group), completed goals below. Implementing this as a simple `isCompleted` sort produces a flat active list followed by a flat completed list — but no tier grouping within the active group.
**Why it happens:** `List { Section }` structure in `GoalListView` is currently driven by `GoalTier.ordered` sections. A "sort by completion status" mode may need to restructure the section grouping.
**How to avoid:** For completion-status sort mode, use two sections: "Active" (containing tier-ordered active goals) and "Completed" (containing all completed goals). The existing `TierSectionView` is not needed for the completed section — a plain "Completed" section header suffices. For the default tier-sort mode, restore the per-tier `TierSectionView` structure.

---

## Code Examples

### Verified Pattern: NavigationLink with AppRoute Value

```swift
// Source: Apple Documentation — NavigationStack, NavigationLink(value:)
// ContentView.swift
NavigationStack(path: $router.path) {
    GoalListView()
        .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .goalDetail(let goal):
                GoalDetailView(goal: goal)
            }
        }
}

// GoalListView.swift — inside ForEach
NavigationLink(value: AppRoute.goalDetail(goal)) {
    GoalRowView(goal: goal, onToggle: { viewModel.toggleCompletion(goal: goal, context: modelContext) })
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { ... } label: { Label("Delete", systemImage: "trash") }
        }
}
```

### Verified Pattern: Toolbar Sort Menu

```swift
// Source: Apple Documentation — toolbarMenu
// GoalListView.swift toolbar
ToolbarItem(placement: .primaryAction) {
    Menu {
        Picker("Sort", selection: $sortOption) {
            Label("By Tier", systemImage: "square.3.stack.3d").tag(SortOption.byTier)
            Label("By Date", systemImage: "calendar").tag(SortOption.byCreationDate)
            Label("By Status", systemImage: "checkmark.circle").tag(SortOption.byCompletionStatus)
        }
    } label: {
        Label("Sort", systemImage: "arrow.up.arrow.down")
    }
}
```

### Verified Pattern: symbolEffect Bounce (iOS 17+)

```swift
// Source: Apple Documentation — symbolEffect(_:options:isActive:)
Image(systemName: goal.completed ? "checkmark.circle.fill" : "circle")
    .symbolEffect(.bounce, value: goal.completed)
    .contentTransition(.symbolEffect(.replace))
```

Note: `.bounce` triggers on value change. `.replace` handles the symbol name transition. Both can be applied together on iOS 17+.

### Verified Pattern: updateGoal in GoalViewModel

```swift
// GoalViewModel.swift — new method
func updateGoal(_ goal: Goal, context: ModelContext) throws {
    let cleanTitle       = sanitize(draftTitle)
    let cleanDescription = sanitize(draftDescription)
    let cleanInspiration = sanitize(draftInspiration)
    try validate(title: cleanTitle, description: cleanDescription, inspiration: cleanInspiration)
    goal.title                 = cleanTitle
    goal.goalDescription       = cleanDescription.isEmpty ? nil : cleanDescription
    goal.tierRawValue          = draftTier.rawValue
    goal.associatedInspiration = cleanInspiration.isEmpty ? nil : cleanInspiration
    resetDraft()
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17 / Swift 5.9 | Property-level invalidation; cleaner `@Bindable` syntax; no `@StateObject` needed |
| `NavigationView` | `NavigationStack` | iOS 16 | Type-safe programmatic navigation via path; `navigationDestination(for:)` |
| `Picker(.navigationLink)` | Custom grid picker (D-11) | Phase 2 decision | More visual, reinforces tier identity |
| `@Query(sort:)` fixed sort | `@Query` + computed sort property | Phase 2 pattern | Runtime sort changes without re-declaring query |
| `.contentTransition(.symbolEffect(.replace))` | Add `.symbolEffect(.bounce)` | iOS 17 feature | Celebratory animation on completion |

**Deprecated/outdated:**
- `NavigationView`: deprecated iOS 16+ — `NavigationStack` is the correct API
- `@Published` / `ObservableObject`: superseded by `@Observable` macro for iOS 17+ — project CLAUDE.md forbids use

---

## Open Questions

1. **Goal model Hashable in AppRoute**
   - What we know: `@Model` classes conform to `PersistentModel`, which synthesizes `Hashable` via object identity / `ModelIdentifier`
   - What's unclear: Whether the compiler infers this without an explicit conformance declaration at the `AppRoute` enum site — needs compilation verification
   - Recommendation: Build the AppRoute case, compile, and verify. If the compiler complains, add `extension Goal: Hashable {}` which simply confirms the already-synthesized conformance without overriding it.

2. **Sort section structure for completion-status sort (D-08)**
   - What we know: D-08 says active goals first grouped by tier, then completed goals below
   - What's unclear: Whether this means (a) two top-level sections ("Active" / "Completed") or (b) tier sections that sort active-first within each tier
   - Recommendation: Interpret D-08 as two top-level sections when in completion-status sort mode: an "Active" section (with goals in tier order within it) and a "Completed" section. This gives the clearest visual separation. Planner should note this as a minor decision to confirm.

---

## Environment Availability

Step 2.6: SKIPPED — Phase 2 is a pure SwiftUI/SwiftData code phase. All frameworks are Apple system frameworks present on iOS 17+. No external tools, CLIs, databases, or services are required beyond what Phase 1 already validated.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode built-in) |
| Config file | Xcode scheme — no external config file |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests` |
| Full suite command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GOAL-01 | Create goal with all fields validated | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalViewModelTests` | ✅ GoalViewModelTests.swift |
| GOAL-03 | Edit goal — updateGoal() validates and persists | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalViewModelTests/test_updateGoal_*` | ❌ Wave 0 — tests don't exist yet |
| GOAL-04 | Delete goal — model removed from context | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalViewModelTests/test_deleteGoal_*` | ❌ Wave 0 |
| GOAL-05 | Toggle completion — CompletionEvent created | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalViewModelTests/test_toggleCompletion_*` | ❌ Wave 0 — verify existing coverage |
| GOAL-06 | Re-activate goal — isCompleted flips to false | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalViewModelTests/test_toggleCompletion_reactivates` | ❌ Wave 0 |
| GOAL-07 | Sort by tier, date, completion status | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalViewModelTests/test_sort_*` | ❌ Wave 0 |
| UI-01 | GoalTier color/icon/weight properties are defined | unit | `xcodebuild test ... -only-testing:VitaminGTests/SchemaV1Tests` | ✅ SchemaV1Tests.swift |
| UI-02 | Warm tone copy in empty states | manual | N/A — visual/copy review | manual only |
| UI-03 | associatedInspiration shows as quote card | manual | N/A — requires visual inspection | manual only |

### Sampling Rate

- **Per task commit:** `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests`
- **Per wave merge:** Full suite (`VitaminGTests` + `VitaminGUITests`)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `VitaminGTests/GoalViewModelTests.swift` — add `test_updateGoal_validInput_persistsChanges`
- [ ] `VitaminGTests/GoalViewModelTests.swift` — add `test_updateGoal_emptyTitle_throwsValidationError`
- [ ] `VitaminGTests/GoalViewModelTests.swift` — add `test_deleteGoal_removesFromContext`
- [ ] `VitaminGTests/GoalViewModelTests.swift` — add `test_toggleCompletion_createsCompletionEvent`
- [ ] `VitaminGTests/GoalViewModelTests.swift` — add `test_toggleCompletion_reactivates_removesCompletedState`
- [ ] `VitaminGTests/GoalSortTests.swift` (new file) — sort logic unit tests covering all three SortOption cases

---

## Project Constraints (from CLAUDE.md)

| Directive | Applies To Phase 2 |
|-----------|-------------------|
| Swift, SwiftUI, SwiftData only — no third-party dependencies | All views and ViewModel work |
| iOS 17+ minimum — use modern APIs freely | `@Observable`, `NavigationStack`, `symbolEffect` all available |
| MVVM strictly enforced — no business logic in Views | `updateGoal()`, `SortOption` logic, draft management in ViewModel |
| `@Observable` macro only — no `ObservableObject` / `@Published` | GoalViewModel, any new ViewModels |
| `NavigationStack` only — no `NavigationView` | AppRoute + ContentView navigation destination |
| All String inputs validated at model layer | `updateGoal()` must call `validate()` before persisting |
| `.confirmationDialog` for destructive actions — established pattern | Delete on GoalDetailView |
| `@Environment(\.modelContext)` for SwiftData operations — no direct model injection | AddGoalView/EditGoalView, GoalDetailView |
| `@insetGrouped` List style for all list screens | GoalListView sort modes |
| App tone is warm and reflective — not productivity-aggressive | Navigation title, empty states, completion copy |

---

## Sources

### Primary (HIGH confidence)

- Apple Developer Documentation — NavigationStack, NavigationLink(value:), navigationDestination(for:): confirmed navigation pattern for SwiftData model values
- Apple Developer Documentation — symbolEffect(_:), contentTransition: confirms `.bounce` + `.replace` combination on iOS 17+
- `VitaminG/Models/SchemaV1.swift` (read directly) — Goal model structure, field names, optional properties
- `VitaminG/ViewModels/GoalViewModel.swift` (read directly) — existing CRUD API, draft state, validation pattern
- `VitaminG/Views/GoalListView.swift` (read directly) — existing list structure, established patterns
- `VitaminG/Views/AddGoalView.swift` (read directly) — form pattern for edit re-use
- `VitaminG/Navigation/AppRoute.swift` + `AppRouter.swift` (read directly) — navigation scaffold
- `.planning/phases/02-core-goal-ui/02-CONTEXT.md` (read directly) — all locked decisions

### Secondary (MEDIUM confidence)

- Phase 1 summaries (`01-01-SUMMARY.md`, `01-02-SUMMARY.md`) — established patterns and decisions
- `VitaminG/CLAUDE.md` — technology constraints and forbidden patterns

### Tertiary (LOW confidence)

- None — all claims are sourced from code read directly or Apple's documented APIs.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all frameworks read directly from existing code; no new dependencies
- Architecture patterns: HIGH — patterns derived from existing codebase + locked decisions in CONTEXT.md
- Pitfalls: HIGH — sourced from reading actual existing code and documented SwiftData/SwiftUI behaviors

**Research date:** 2026-04-04
**Valid until:** 2026-05-04 (stable APIs; SwiftData/SwiftUI on iOS 17 not changing rapidly)
