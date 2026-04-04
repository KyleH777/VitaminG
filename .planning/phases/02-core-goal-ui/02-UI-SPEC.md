# Phase 2: Core Goal UI — UI Design Contract

**Generated:** 2026-04-04
**Updated:** 2026-04-04
**Stack:** SwiftUI (iOS 17+)
**Style:** Warm & Vibrant — multi-tier color identity, rounded type, celebratory completion
**Status:** draft

---

## Design System

### Tool

No external design system (shadcn is a web concept — not applicable). All tokens derived from existing `GoalTier.color` values and Apple system colors. Zero third-party dependencies.

---

### Color Palette

The tier color system is the visual identity of this app. These are locked in `GoalTier.color` — do not redefine or override.

| Token | Value | Use |
|-------|-------|-----|
| Immediate tier | `Color(red: 0.98, green: 0.55, blue: 0.27)` — warm orange | Immediate goal accents, tier badge, quote card tint |
| Short-Term tier | `Color(red: 0.36, green: 0.78, blue: 0.64)` — fresh teal | Short-Term accents |
| Long-Term tier | `Color(red: 0.40, green: 0.61, blue: 0.95)` — calm blue | Long-Term accents |
| Life Goal tier | `Color(red: 0.78, green: 0.48, blue: 0.95)` — deep violet | Life Goal accents |
| `textPrimary` | `Color.primary` (system adaptive) | All primary text |
| `textMuted` | `Color.secondary` (system adaptive) | Descriptions, captions, secondary labels |
| `listBackground` | `Color(.systemGroupedBackground)` | Screen backgrounds |
| `rowBackground` | `Color(.secondarySystemGroupedBackground)` | List rows, card backgrounds |
| `destructiveColor` | `Color.red` (system) | Destructive action buttons only |

**60/30/10 split:**
- 60% dominant: `listBackground` / `rowBackground` system colors — adapts to Light and Dark Mode automatically
- 30% secondary: tier color at 8–12% opacity for tinted row/card backgrounds
- 10% accent: tier colors at full opacity — reserved for tier badges, completion toggle fill, quote card border, tier picker selected state, and action buttons

**Completion state color:** Use `goal.tier.color` (not a global green) — the completion reward is tied to the tier's identity. The goal stays "owned" by its tier even when complete.

---

### Typography

Apply `.fontDesign(.rounded)` globally via `.environment(\.fontDesign, .rounded)` on the root view — warm and approachable, consistent with app tone.

**Font sizes (4 total):** `.caption` (12pt), `.body`/`.headline` (17pt), `.title3` (20pt), `.title2` (22pt)

**Font weights (2 total):** `.regular` (400) and `.semibold` (600)

| Role | SwiftUI Font | Weight | Notes |
|------|-------------|--------|-------|
| Navigation title (large) | `.title2` | `.semibold` | Used by `"My Goals"` large title |
| Navigation title (inline) | `.headline` | — (system default) | Sheet navigation titles |
| Goal title — row | `.body` | `goal.tier.typographicWeight` | Already in GoalRowView |
| Goal title — detail | `.title2` | `.semibold` | 22pt system equivalent |
| Description preview | `.caption` | `.regular` | Row second line, 2-line max |
| Description — detail | `.body` | `.regular` | Full text in detail view |
| Tier label / section header | `.caption` | `.semibold` | Use `.caption.weight(.semibold)` — replaces `.subheadline` |
| Quote card text | `.title3.italic()` | `.regular` | `associatedInspiration` display |
| Quote card label | `.caption.weight(.semibold)` | — | "Inspiration" label above quote |
| Character count | `.caption` | `.regular` | Monospaced digits — already CharacterCountView; replaces `.caption2` |
| Button / CTA | `.headline` | `.semibold` | Primary action buttons |
| Destructive button | `.body` | `.regular` | Delete actions |

`GoalTier.typographicWeight` must return only `.semibold` (for Immediate and Life Goal tiers) or `.regular` (for Short-Term and Long-Term tiers) — no `.bold` values.

**Line heights:** SwiftUI's default line height per `.fontDesign(.rounded)` is acceptable. Do not override unless a specific element needs it.

---

### Spacing Scale

All spacing uses 4pt base units. No exceptions.

| Value | Use |
|-------|-----|
| 4pt | Intra-component micro gaps (e.g., title + description in row) |
| 8pt | Icon-to-label spacing in headers and pills |
| 16pt | Row horizontal padding (HStack spacing in GoalRowView); card padding (quote card, tier picker card internal); grid spacing in tier picker |
| 24pt | Section spacing, form section gaps |
| 32pt | Empty state internal spacing |
| 44pt | Minimum touch target — all interactive elements without exception |

---

### Animation Contract

All animations must check `UIAccessibility.isReduceMotionEnabled` before executing spring/scale effects. The check is required — not optional.

```swift
// Required pattern for all decorative animations
if !UIAccessibility.isReduceMotionEnabled {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
        // celebration or scale effect
    }
} else {
    // instant state change — no animation modifier
}
```

| Interaction | Duration | Curve | Reduced Motion Fallback |
|-------------|----------|-------|------------------------|
| Toggle / button tap (micro) | 150ms | `.easeOut` | Instant state swap |
| Sheet present / dismiss | System default | System default | No override needed |
| List reorder / insertion | `.easeInOut` | `.easeInOut` | Instant (SwiftUI handles) |
| Completion celebration — symbol bounce | iOS 17 `symbolEffect(.bounce)` | Spring (system) | `.contentTransition(.symbolEffect(.replace))` only |
| Completion celebration — row flash | 300ms spring, `response: 0.4, dampingFraction: 0.6` | Spring | Instant opacity/color change |
| Tier card selection | 150ms `.easeOut` | `.easeOut` | Instant border/background swap |

---

### Haptic Feedback

Use `UIImpactFeedbackGenerator` for completion toggle — fired on every completion state change (both complete and reactivate).

```swift
// In GoalViewModel.toggleCompletion or in GoalRowView's onToggle closure
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred()
```

- Completion toggle → `.medium` impact
- Delete confirmation trigger → no haptic (system `.confirmationDialog` provides feedback)
- Save (valid form) → no haptic (system keyboard dismiss is sufficient)
- Validation error alert → no haptic (`.alert` provides system feedback)

---

## Navigation Architecture

**Pattern:** `NavigationStack` (already in `ContentView`) + `NavigationLink(value:)` + `navigationDestination(for: AppRoute.self)`.

**Never use:** `NavigationLink(destination:)` (deprecated pattern), `NavigationView`, `@Environment(\.presentationMode)`.

**Always use:** `@Environment(\.dismiss)` for sheet/push dismissal — already established in `AddGoalView`.

```swift
// ContentView.swift — navigationDestination registration (Phase 2 update)
NavigationStack(path: $router.path) {
    GoalListView()
        .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .goalDetail(let goal):
                GoalDetailView(goal: goal)
            }
        }
}

// GoalListView — row wrapping
NavigationLink(value: AppRoute.goalDetail(goal)) {
    GoalRowView(goal: goal, onToggle: { ... })
}
```

**Touch target note:** `NavigationLink` rows in a `List` satisfy 44pt height automatically when `GoalRowView` content has `.padding(.vertical, 4)` + label content height ≥ 36pt. The existing `.contentShape(Rectangle())` in `GoalRowView` ensures consistent hit testing. No changes needed.

---

## Screen Designs

### 1. GoalListView (modifications to Phase 1)

**Navigation title:** `"My Goals"` — `.large` display mode. Source: already set in Phase 1.

**Toolbar:**
- Trailing slot 1: Sort menu — `Label("Sort", systemImage: "line.3.horizontal.decrease.circle")`, `.menu` button style
- Trailing slot 2: Add button — `Label("Add Goal", systemImage: "plus")`, existing behavior

**Sort menu (D-06/D-07/D-08):**
```swift
Menu {
    Picker("Sort", selection: $sortOption) {
        Label("By Tier", systemImage: "square.3.stack.3d").tag(SortOption.byTier)
        Label("By Date Added", systemImage: "calendar").tag(SortOption.byCreationDate)
        Label("By Status", systemImage: "checkmark.circle").tag(SortOption.byCompletionStatus)
    }
} label: {
    Label("Sort", systemImage: "line.3.horizontal.decrease.circle")
}
```

**Sort behavior:**
- `.byTier` (default): Existing `TierSectionView` sections, Immediate → Short-Term → Long-Term → Life Goal. Within each tier: active goals first, completed goals below. Uses existing `goals(for tier:)` helper with active-before-completed sub-sort.
- `.byCreationDate`: Single flat section, oldest first. No tier section headers.
- `.byCompletionStatus`: Two sections — "Active" (tier-ordered within) and "Completed". Plain section headers, not `TierSectionView`.

**List style:** `.insetGrouped` — unchanged from Phase 1.

**`@Query` change:** Remove sort descriptor from `@Query(sort: \Goal.createdAt)` → `@Query private var goals: [Goal]`. All ordering handled by `sortedGoals` computed property to avoid divergence.

---

### 2. GoalRowView (modifications to Phase 1)

Wrap in `NavigationLink(value: AppRoute.goalDetail(goal))`. Inner `Button` (completion toggle) uses `.buttonStyle(.plain)` — SwiftUI hit-testing gives it priority over the surrounding link. Existing `.contentShape(Rectangle())` stays.

**Row layout (unchanged from Phase 1 except completion treatment):**
```
[ ✓ toggle ]  Goal Title (body, tier.typographicWeight)    [ tier pip ]
              Description preview (caption, .secondary, 2 lines)
```

**Active state:** Unchanged from Phase 1.

**Completed state visual treatment (D-10 — celebratory, not punishing):**
- Row background: `goal.tier.color.opacity(0.08)` — subtle glow of the tier color
- Title: `Color.secondary` foreground + `.strikethrough(true, color: goal.tier.color.opacity(0.6))` — tier-colored strikethrough, not a grey slash
- Description: `Color.secondary` (already reduced via existing code)
- Tier pip: `goal.tier.color.opacity(0.3)` — already implemented in Phase 1
- Completion toggle: `"checkmark.circle.fill"` in `goal.tier.color` — already implemented in Phase 1
- Symbol animation: `.symbolEffect(.bounce, value: goal.completed)` + `.contentTransition(.symbolEffect(.replace))` — upgrade from Phase 1's replace-only
- Row background flash: spring scale 1.0 → 1.02 → 1.0, 300ms, `response: 0.4, dampingFraction: 0.6`
- Reduced motion: instant icon swap + instant background tint, no spring

```swift
// listRowBackground for completion state
.listRowBackground(
    goal.completed
        ? goal.tier.color.opacity(0.08)
        : Color(.secondarySystemGroupedBackground)
)
// Animate the background change
.animation(.easeOut(duration: 0.15), value: goal.completed)
```

**Completion toggle — final spec:**
```swift
Button(action: {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
    onToggle()
}) {
    Image(systemName: goal.completed ? "checkmark.circle.fill" : "circle")
        .font(.title3)
        .foregroundStyle(goal.completed ? goal.tier.color : Color.secondary)
        .symbolEffect(.bounce, value: goal.completed)
        .contentTransition(.symbolEffect(.replace))
}
.buttonStyle(.plain)
.frame(minWidth: 44, minHeight: 44)  // guaranteed touch target
.accessibilityLabel(goal.completed
    ? "Mark \(goal.title ?? "goal") as active"
    : "Mark \(goal.title ?? "goal") as complete")
```

---

### 3. GoalDetailView (new view)

**Navigation:** Pushed via `NavigationStack` path. `navigationTitle(goal.title ?? "")`, `.inline` display mode.

**Toolbar:**
- Trailing: `Button("Edit") { showingEdit = true }` — presents `EditGoalView` as `.sheet` (D-04)
- `@Environment(\.dismiss)` for back navigation (system back button handles this automatically)

**Layout:** `List` with `.insetGrouped` style. Four potential sections.

**Section 1 — Tier + Title header**
- Tier badge pill: `HStack(spacing: 8)` containing `Image(systemName: tier.icon).foregroundStyle(tier.color)` + `Text(tier.displayName).font(.caption.weight(.semibold)).foregroundStyle(tier.color)` — matches `TierSectionView` style, displayed inline in section, not as header
- Goal title: `.title2.weight(.semibold)`, `.fontDesign(.rounded)`
- Created date: `.caption`, `Color.secondary`, formatted as "Added Apr 4, 2026" using `DateFormatter` with `.medium` date style

**Section 2 — Inspiration Quote Card (D-02, only when `associatedInspiration` is non-nil and non-empty)**

```swift
VStack(alignment: .leading, spacing: 8) {
    Label("Inspiration", systemImage: "quote.opening")
        .font(.caption.weight(.semibold))
        .foregroundStyle(goal.tier.color)
    Text(""\(inspiration)"")
        .font(.title3.italic())
        .foregroundStyle(Color.primary)
        .multilineTextAlignment(.leading)
}
.padding(16)
.frame(maxWidth: .infinity, alignment: .leading)
.background(
    RoundedRectangle(cornerRadius: 12)
        .fill(goal.tier.color.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(goal.tier.color.opacity(0.25), lineWidth: 1)
        )
)
.accessibilityElement(children: .combine)
.accessibilityLabel("Inspiration: \(inspiration)")
```

**Section 3 — Notes (only when `goalDescription` is non-nil and non-empty)**
- Section header: `"Notes"`
- Body: `.body`, `Color.primary`, full text (no truncation)

**Section 4 — Actions**
- Completion toggle button — full width, `.borderedProminent` style:
  - Active → `"Mark Complete"`, tint `goal.tier.color`
  - Completed → `"Reactivate Goal"`, tint `Color.secondary`
  - Both: `Label` with appropriate SF Symbol (`"checkmark.circle"` / `"arrow.counterclockwise"`)
  - Haptic: `UIImpactFeedbackGenerator(style: .medium).impactOccurred()` before calling `viewModel.toggleCompletion`
- Delete button — `.destructive` role, `"Delete Goal"`, triggers `.confirmationDialog` (same confirmation dialog pattern as GoalListView swipe-delete)

**Confirmation dialog copy (delete from detail):**
- Title: `"Delete this goal?"`
- Message: `"This cannot be undone."`
- Buttons: `Button("Delete", role: .destructive)` + `Button("Cancel", role: .cancel)`

---

### 4. AddGoalView / EditGoalView (D-04/D-05)

**Mode detection:** `AddGoalView` accepts `editingGoal: Goal? = nil`. When non-nil → Edit mode. Sheet navigation title: `"New Goal"` (create) vs `"Edit Goal"` (edit). Save button calls `viewModel.addGoal` (create) or `viewModel.updateGoal(goal:context:)` (edit).

**Draft pre-population on edit (`.onAppear`):**
```swift
.onAppear {
    if let goal = editingGoal {
        viewModel.draftTitle       = goal.title ?? ""
        viewModel.draftDescription = goal.goalDescription ?? ""
        viewModel.draftTier        = goal.tier
        viewModel.draftInspiration = goal.associatedInspiration ?? ""
    }
}
```

**Cancel always calls `viewModel.resetDraft()`** before `dismiss()` — prevents draft state pollution.

**Replace Picker with Custom Tier Picker (D-11):**

Replace the `.pickerStyle(.navigationLink)` Picker section entirely with `TierPickerView`.

```
Section header: "Tier"

┌──────────────────┐ ┌──────────────────┐
│   bolt.fill      │ │   calendar       │
│   Immediate      │ │   Short-Term     │
│  "Quick wins     │ │  "Goals for the  │
│   this week"     │ │   next few       │
│                  │ │   months"        │
└──────────────────┘ └──────────────────┘
┌──────────────────┐ ┌──────────────────┐
│   map.fill       │ │   star.fill      │
│   Long-Term      │ │   Life Goal      │
│  "Multi-year     │ │  "The things     │
│   milestones"    │ │   you want to    │
│                  │ │   have done"     │
└──────────────────┘ └──────────────────┘
```

**`TierPickerView` spec:**

| Property | Value |
|----------|-------|
| Grid | `LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16)` |
| Card corner radius | 12pt |
| Card padding | 16pt |
| Icon size | `.title2` (22pt) |
| Tier name font | `.caption.weight(.semibold)` |
| Description font | `.caption`, `Color.secondary`, 2-line max |
| Selected card border | 2pt stroke, `tier.color`, corner radius 12 |
| Selected card background | `tier.color.opacity(0.12)` |
| Unselected card background | `Color(.secondarySystemGroupedBackground)` |
| Selection animation | `.animation(.easeOut(duration: 0.15), value: selectedTier)` |
| Touch target | Full card is tappable; card height satisfies 44pt minimum |
| Accessibility | `.accessibilityLabel("\(tier.displayName): \(tier.description)")` + `.accessibilityAddTraits(.isButton)` + `.accessibilityValue(isSelected ? "selected" : "")` |

**Tier card descriptions (aligned with existing `TierFooterView.description`):**
- Immediate: `"Quick wins this week — build momentum."`
- Short-Term: `"Goals for the next few weeks to months."`
- Long-Term: `"Multi-year milestones that shape your direction."`
- Life Goal: `"The things you want to have done with your life."`

**Form footer** (below tier picker, replaces `TierFooterView`): remove — the cards are self-documenting. `TierFooterView` can be deleted in Phase 2 or kept for future use outside the form.

---

## Copywriting Contract

| Surface | Copy |
|---------|------|
| Navigation title | `"My Goals"` |
| Add button accessibility | `"Add Goal"` |
| Sort button accessibility | `"Sort goals"` |
| Empty state headline | `"Time to take your Vitamin G!"` *(existing — keep)* |
| Empty state body | `"Start making goals to get your daily dose of gratitude and inspiration."` *(existing — keep)* |
| Empty state CTA | `"Add Your First Goal"` *(existing — keep)* |
| Add sheet title | `"New Goal"` |
| Edit sheet title | `"Edit Goal"` |
| Title field placeholder | `"What do you want to achieve?"` *(existing — keep)* |
| Title section header | `"Goal Title"` |
| Title section footer | `"Required. Be specific — vague goals are hard to act on."` *(existing — keep)* |
| Tier section header | `"Tier"` |
| Description section header | `"Description (Optional)"` |
| Inspiration section header | `"Inspiration (Optional)"` |
| Inspiration section footer | `"A quote, mantra, or reason that fuels this goal. Shown on the detail screen as a daily reminder."` *(existing — keep)* |
| Detail quote card label | `"Inspiration"` |
| Detail created date | `"Added [date]"` |
| Detail complete action | `"Mark Complete"` |
| Detail reactivate action | `"Reactivate Goal"` |
| Detail delete action | `"Delete Goal"` |
| Delete confirmation title | `"Delete this goal?"` |
| Delete confirmation message | `"This cannot be undone."` |
| Delete confirmation button | `"Delete"` (destructive) |
| Validation error alert title | `"Title Required"` |
| Validation error alert message | `"Please enter a goal title before saving."` |
| Validation error alert button | `"OK"` |
| Sort: by tier | `"By Tier"` |
| Sort: by date | `"By Date Added"` |
| Sort: by status | `"By Status"` |
| Completion-sort active section | `"Active"` |
| Completion-sort completed section | `"Completed"` |

**Tone rule:** No productivity-aggressive copy. Avoid: "Track", "Crush", "Hit", "Smash". Prefer: "achieve", "complete", "work toward", "take your Vitamin G". Copy should feel like a warm daily companion, not a task manager.

---

## Accessibility Contract

| Element | Requirement |
|---------|------------|
| All interactive elements | Minimum 44×44pt touch target — enforced via `.frame(minWidth: 44, minHeight: 44)` or SwiftUI automatic sizing |
| Completion toggle | `.accessibilityLabel("Mark [goal title] as complete")` / `"Mark [goal title] as active"` |
| Tier picker cards | `.accessibilityLabel("[tier name]: [tier description]")` + `.accessibilityAddTraits(.isButton)` + `.accessibilityValue("selected")` when selected |
| Quote card | `.accessibilityElement(children: .combine)` + `.accessibilityLabel("Inspiration: [quote text]")` — not focusable as interactive |
| Tier section headers | `.accessibilityLabel("[tier name] goals")` — informational |
| Sort menu | `.accessibilityLabel("Sort goals")` |
| Delete swipe action | `.accessibilityLabel("Delete [goal title]")` |
| Color-only indicators | Never sole indicator — all colored elements have an accompanying icon or label |
| Reduce motion | `UIAccessibility.isReduceMotionEnabled` checked before all spring/scale animations |
| Dynamic Type | All fonts use SwiftUI system font APIs — Dynamic Type scales automatically |
| VoiceOver row | Row content combines as: `"[goal title], [tier name], [complete/active], [description if present]"` — use `.accessibilityElement(children: .combine)` on `GoalRowView` |

---

## Component Specs

### TierPickerView (new component)

**File:** `Views/TierPickerView.swift`

**Input:** `@Binding var selectedTier: GoalTier`

**Layout:** `LazyVGrid` 2-column, 16pt spacing. Each `TierCardView` shows icon (`.title2`) + name (`.caption.weight(.semibold)`) + description (`.caption`, 2-line max) in a `VStack(alignment: .leading, spacing: 4)`, padded 16pt, on a `RoundedRectangle(cornerRadius: 12)` background.

**Selection state:** `.overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(tier.color, lineWidth: 2))` on selected card. Animated with `.animation(.easeOut(duration: 0.15), value: selectedTier)`.

### GoalDetailView (new view)

**File:** `Views/GoalDetailView.swift`

**Input:** `let goal: Goal`

**Dependencies:** `@Environment(\.modelContext)`, `@Environment(\.dismiss)`, `@State var viewModel: GoalViewModel` (injected from list or created fresh — see pitfall note below)

**Pitfall:** Do not create a new `GoalViewModel()` in `GoalDetailView` if the edit path needs to share draft state. `GoalDetailView` should receive the `GoalViewModel` as a parameter or access it via the environment, same instance as `GoalListView` uses.

**Sheet presentation for edit:**
```swift
@State private var showingEdit = false

// In toolbar:
Button("Edit") { showingEdit = true }

// Sheet:
.sheet(isPresented: $showingEdit) {
    AddGoalView(viewModel: viewModel, editingGoal: goal)
}
```

### EmptyStateView (no changes in Phase 2)

Keep existing implementation — Phase 5 scope for per-tier empty states.

---

## Registry

No third-party registries. All components are SwiftUI native + SF Symbols. No shadcn, no npm, no external component registry. Not applicable.

---

## Anti-Patterns

| Pattern | Reason | Use Instead |
|---------|--------|-------------|
| `NavigationLink(destination:)` with a view | Deprecated API — breaks programmatic navigation | `NavigationLink(value:)` + `navigationDestination(for:)` |
| `@Environment(\.presentationMode)` | Deprecated — use `@Environment(\.dismiss)` | `@Environment(\.dismiss)` |
| `NavigationView` | Deprecated iOS 16+ | `NavigationStack` (already in place) |
| Global `completionGreen` color for toggle | Loses tier identity on completion | `goal.tier.color` — completion is a tier reward |
| Strikethrough in `.secondary` grey only | Feels punishing, not celebratory | Tier-colored strikethrough at 60% opacity |
| `.linear` animation timing | Feels mechanical | `.easeOut` for micro-interactions, spring for celebrations |
| `UIAccessibility.isReduceMotionEnabled` unchecked | Fails WCAG 2.1 SC 2.3.3 | Always gate decorative spring/scale animations |
| Hardcoded `UIColor` / hex strings | Breaks Dark Mode + Dynamic Colors | `Color(.systemGroupedBackground)` and `GoalTier.color` |
| Creating `GoalViewModel()` twice | Causes draft state pollution | Single instance passed as parameter |
| Using `.bold` font weight | Violates 2-weight constraint | Use `.semibold` — the only heavy weight in this spec |
| Using `.caption2` font size | Violates 4-size constraint | Use `.caption` — minimum size in this spec |
| Using `.subheadline` font size | Violates 4-size constraint | Use `.caption.weight(.semibold)` for tier labels |
| Spacing values not divisible by 4 (e.g., 14pt) | Breaks 4pt grid | Use 16pt for row horizontal padding |

---

## Pre-Population Sources

| Field | Source |
|-------|--------|
| Navigation API (`NavigationStack`, `navigationDestination`) | CONTEXT.md D-01/D-03, RESEARCH.md Pattern 1 |
| Tier color values | `Goal.swift` — read directly, locked in `GoalTier.color` |
| Completion toggle icon / color | `GoalListView.swift` — read directly from existing `GoalRowView` |
| `TierFooterView` descriptions | `AddGoalView.swift` — read directly, carried into tier card spec |
| Sort menu options | CONTEXT.md D-06/D-07/D-08 |
| Quote card design | CONTEXT.md D-02, RESEARCH.md Pattern 5 |
| Edit UX (sheet, pre-populate) | CONTEXT.md D-04/D-05, RESEARCH.md Pattern 3 |
| Custom tier picker | CONTEXT.md D-11, RESEARCH.md Pattern 4 |
| Animation durations | Update context — UI/UX Pro Max SwiftUI guidelines |
| Haptic feedback | Update context — `UIImpactFeedbackGenerator(.medium)` on completion |
| Reduce motion gate | Update context — `UIAccessibility.isReduceMotionEnabled` check |
| `@Environment(\.dismiss)` | Already in `AddGoalView.swift` — confirmed pattern |
| Empty state copy | `GoalListView.swift` — read directly |
| Deletion copy | `GoalListView.swift` — `"Delete this goal?"` / `"This action cannot be undone."` (spec uses shorter `"This cannot be undone."` — keep the existing `"This action cannot be undone."` for consistency) |

---

*Phase: 02-core-goal-ui*
*UI-SPEC generated: 2026-04-04 via ui-ux-pro-max design system*
*Updated: 2026-04-04 — corrected tier colors from actual GoalTier.color, added haptic spec, precise navigation API contract, aligned tier descriptions with TierFooterView, fixed completion color to tier.color, added reduce-motion implementation pattern, added accessibility VoiceOver row spec*
*Revised: 2026-04-04 — fixed checker blocks: reduced font sizes to 4 (dropped .caption2, .subheadline), consolidated weights to 2 (dropped .bold, all usages now .semibold), replaced 14pt spacing with 16pt; applied non-blocking: "Reactivate Goal" CTA, destructiveColor row, validation error alert copy*
