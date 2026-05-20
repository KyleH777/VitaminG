# Phase 18: Home Tab + Goals Flow Enhancements - Research

**Researched:** 2026-05-17
**Domain:** SwiftUI / SwiftData — iOS dashboard layout, goal creation wizard redesign, celebration flows, calendar grid UI
**Confidence:** HIGH — all findings sourced from the codebase directly

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Community goal (HOME-03) gets its own card section between the quote section and "My Goals" — distinct from the user's personal top goal. Two clear sections: community goal card (with title + progress bar showing community completion %), then "My Goals" below.
- **D-02:** Stats view (HOME-05) surfaces as a tappable row card in the Home scroll that pushes to the full StatsView via NavigationStack. The existing `quickStatsRow` section is promoted to a proper navigation entry point. No separate tab needed.
- **D-03:** Streak count lives in the header alongside the greeting: `"Good morning, Kyle ☀️  🔥 14"` — streak count + flame emoji on the same line as the greeting. Prominent and glanceable.
- **D-04:** HOME-06 (Daily Wins / Gratitude) is dropped. Remove the existing `dailyWinsEntry` section from HomeView. No gratitude log in Phase 18.
- **D-05:** When the user taps "+add" on the Home screen, a choice screen appears (sheet) with 3 paths: "Need ideas" (pre-made goals list), "Already have a goal" (blank goal form — GOAL2-03), and the 3-step wizard ("Build my own goal"). User picks their path.
- **D-06:** "Need ideas" pre-made goals list (GOAL2-02) is a hardcoded Swift array — no network call, works offline. Goals are organized by GoalCategory. Tapping a pre-made goal pre-fills Step 2 (name) and Step 1 (category) of the wizard, then lands on Step 3 for final details.
- **D-07:** Tier (life goal / long-term / short-term / challenge) stays in Step 3 alongside duration, start date, reminder time, and public/private toggle. The redesigned Step 3 replaces the existing Step3DetailsScreen content but retains tier as a required field.
- **D-08:** "Already have a goal" path (GOAL2-03) opens a blank goal landing page — effectively drops the user into Step 2 (goal name text field) with Step 1 category defaulted or choosable inline.
- **D-09:** Day grid (GOAL2-05) uses calendar-month rows — days arranged Mon–Sun in week rows. Filled circles for completed days, empty circles for future/missed days. Current month shown by default.
- **D-10:** Only the current calendar month is shown at a time. No scrolling through full goal duration — keeps the view fast and focused. (Swipe navigation to adjacent months is Claude's discretion.)
- **D-11:** Flame icon on goals with 3+ consecutive days (GOAL2-05) appears on the goal row/card in the My Goals section (not just in the detail grid). Sourced from per-goal streak calculated against CompletionEvent records.
- **D-12:** The celebration screen (GOAL2-04) shows the user's **overall app streak** (same number displayed in the Home header), not a per-goal streak.
- **D-13:** Celebration appears as a full-screen cover. It auto-dismisses after ~2 seconds. A manual "Back to Goals" button is also present. Matches the existing milestone achievement pattern (`pendingMilestone`) in GoalListView.

### Claude's Discretion

- Exact confetti animation style on the check-in celebration screen.
- Whether the community goal card shows the community-wide completion percentage or the user's personal contribution — use whatever data is available from CloudKit or the local model.
- Layout of the goal creation choice screen (sheet title, icon treatment for the 3 paths).
- Swipe navigation between months in the day grid (if adding, keep it simple — chevron buttons are sufficient).
- Whether "Already have a goal" shows all 3 steps or skips Step 1 if category is not critical.

### Deferred Ideas (OUT OF SCOPE)

- Daily Wins / Gratitude (HOME-06): Explicitly removed from Phase 18.
- Per-goal streak on celebration screen: User chose overall app streak.
- Full goal duration in day grid: Current month view only.
- Full month-browsing UI in day grid: Chevrons are sufficient if added.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HOME-01 | Home tab shows user's display name and current streak count prominently at top of screen | Header section exists; `currentStreak` computed property needs fix (currently uses `completionEvents?.count`, not `StreakEngine`) |
| HOME-02 | Quote of the day displayed on Home tab — rotates daily from existing quote bank | `VGQuoteBank` exists with 6+ categories; `quoteSection` in HomeView uses a hardcoded 4-quote array — needs to source from `VGQuoteBank` |
| HOME-03 | Primary community-set goal displayed on Home tab with title and progress bar | No community goal model on Home tab yet; `CommunityGoalsLandingView` exists for reference; `primaryGoalCard` currently shows user's personal goal — new community section needed |
| HOME-04 | "My Goals" section on Home with "+add" inline; shows each goal's progress ring and days remaining | `secondaryGoalsSection` exists; needs "+add" wired to `GoalEntryChoiceView` and "days remaining" added to goal rows |
| HOME-05 | Stats view accessible from Home tab (tappable element) | `quickStatsRow` already has `NavigationLink(value: AppRoute.stats)` — promote to single-card layout per D-02 |
| HOME-06 | DROPPED per D-04 — do not implement | `dailyWinsEntry` is removed from HomeView |
| GOAL2-01 | Goal creation wizard follows three steps: category → name → duration/start/reminder/privacy | `GoalCreationWizardView` has 3-step structure; Step 3 (`Step3DetailsScreen`) needs duration field added alongside existing tier/reminder/privacy |
| GOAL2-02 | "Need ideas" path — pre-made goals list screen | New file `PremadeGoalsListView.swift`; `GoalCategory.suggestions` array is the data source — already structured by category |
| GOAL2-03 | "Already have a goal" path — blank goal landing page | New routing: `GoalCreationWizardView` initialized at step 1 (skipping or defaulting Step 1 category) |
| GOAL2-04 | Checking off a goal shows a checkmark celebration page with streak count | New `CheckInCelebrationView.swift`; auto-dismiss after 2s; `StreakEngine.currentStreak(from:)` for overall streak |
| GOAL2-05 | Goal detail page shows grid of daily checkmarks, "Check in for today" action with streak, flame icon | New `GoalDayGridView.swift`; `LazyVGrid` 7 columns; `CompletionEvent.completedAt` is source of truth; `StreakEngine.currentStreak(from:goalEvents)` for per-goal streak |
</phase_requirements>

---

## Summary

Phase 18 is a SwiftUI-native codebase enhancement phase with no new dependencies. The project uses Swift 6.3.2 / Xcode 26.5 on iOS 17+ with SwiftUI + SwiftData. All required infrastructure (navigation, theme, streak calculation, confetti pattern) already exists and needs to be wired together rather than built from scratch.

The primary work involves: (1) rebuilding HomeView's content sections — removing `dailyWinsEntry`, fixing the streak source, adding a community goal card, and promoting the stats row to a navigation card; (2) adding a `GoalEntryChoiceView` sheet that routes to three goal creation paths; (3) building `PremadeGoalsListView` backed by the existing `GoalCategory.suggestions` arrays; (4) building `CheckInCelebrationView` using the established `MilestoneCelebrationView` confetti pattern; and (5) building `GoalDayGridView` as a `LazyVGrid` calendar-month component for `GoalDetailView`.

The most complex integration point is the **check-in trigger** in `GoalDetailView` — the existing "Mark as Complete" button uses `toggleCompletion()` which sets `goal.isCompleted` permanently. The check-in action (GOAL2-04/GOAL2-05) should create a `CompletionEvent` without permanently marking the goal complete. This requires either a new `GoalViewModel` method or direct `CompletionEvent` insertion. The planner must choose one approach and be consistent across `GoalDetailView` and `GoalListView`.

**Primary recommendation:** Reuse all existing patterns precisely — confetti from `MilestoneCelebrationView`, `StreakEngine.currentStreak(from:)` for app streak, `GoalCategory.suggestions` for pre-made goals, and `FullScreenCover` + `DispatchQueue.main.asyncAfter` for the celebration screen. Build `GoalDayGridView` as a standalone component. No new dependencies.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Home header with streak count | Frontend (View) | Service (StreakEngine) | View reads from StreakEngine; streak is derived from SwiftData CompletionEvent records |
| Quote of the day display | Frontend (View) | Service (VGQuoteBank) | Day-of-year deterministic selection; already computed at render time |
| Community goal card | Frontend (View) | — | Phase 18 displays a static/placeholder card; live community data is Phase 21 scope |
| My Goals section with "+add" | Frontend (View) | ViewModel (GoalViewModel) | GoalEntryChoiceView is a sheet; GoalViewModel owns CRUD |
| Stats row navigation | Frontend (View) | — | Existing AppRoute.stats NavigationLink — just reshape the card UI |
| Goal entry choice routing | Frontend (View) | ViewModel (GoalCreationWizardViewModel) | Choice sheet; downstream wizard uses existing ViewModel |
| Pre-made goals list | Frontend (View) | Model (GoalCategory) | Hardcoded via GoalCategory.suggestions; no network layer needed |
| GoalCreationWizardViewModel pre-fill | ViewModel | — | Add `configure(from premadeGoal:)` method mirroring existing `configure(from goal:)` |
| Check-in celebration | Frontend (View) | Service (StreakEngine) | fullScreenCover; streak count sourced from StreakEngine overall |
| Day grid calendar layout | Component (View) | Model (CompletionEvent) | LazyVGrid 7-column; reads CompletionEvent records for filled/empty state |
| Flame icon per-goal streak | Frontend (View) | Service (StreakEngine) | StreakEngine.currentStreak with per-goal events; displayed in goal row |
| "Check in for today" action | ViewModel (GoalViewModel) | Model (CompletionEvent) | Needs new method: addCheckIn(for goal:) distinct from toggleCompletion |

---

## Standard Stack

### Core (no new dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All UI — LazyVGrid, fullScreenCover, sheet, NavigationLink | Project standard; CLAUDE.md prohibits UIKit for feature views |
| SwiftData | iOS 17+ | `@Query`, `ModelContext`, CompletionEvent persistence | Project persistence layer |
| Foundation | Swift 6.3.2 | Calendar arithmetic for day grid | Calendar.current.startOfDay(for:), dateComponents |

### Supporting (already in project)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| StreakEngine | project | Overall app streak + per-goal consecutive streak | Home header, celebration screen, flame icon, day grid check-in count |
| VGQuoteBank | project | Quote-of-the-day data | HOME-02 quote rotation |
| GoalCategory | project | Pre-made goals data source | GoalCategory.suggestions — 7 categories with 4-5 goals each |
| MilestoneCelebrationView | project | Confetti canvas pattern | CheckInCelebrationView replicates this exactly |
| VGTheme | project | All colors, typography, spacing | Design system — no raw hex values in Phase 18 code |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Calendar arithmetic for day grid | Third-party date library | No third-party deps per CLAUDE.md; Calendar.current is sufficient for single-month display |
| SwiftUI Canvas confetti (existing) | SpriteKit | CLAUDE.md prohibits unnecessary deps; existing Canvas pattern proven |
| GoalCategory.suggestions for pre-made goals | CloudKit data | D-06 locked: offline-only, hardcoded. CloudKit data not available until Phase 21 |

**Installation:** No new packages. Phase 18 is zero-dependency.

---

## Package Legitimacy Audit

No external packages are installed in this phase. All components are native SwiftUI + project code.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
User Action ("+add" tap or goal row tap)
       |
       v
GoalEntryChoiceView (.sheet)
       |
  ┌────┴──────────────────┐
  |                       |
  v                       v
PremadeGoalsListView    GoalCreationWizardView
  |                      (step 0, 1, or 2 depending on path)
  |                       |
  └────────────┬──────────┘
               |
               v
         GoalViewModel.addGoal(input:)
               |
               v
         SwiftData ModelContext (CompletionEvent / Goal)
               |
               v
         WidgetCenter.reloadAllTimelines()

Check-in Flow:
GoalDetailView "Check in for today"
       |
       v
GoalViewModel.addCheckIn(for goal:)  [NEW METHOD]
       |
       v
CompletionEvent inserted → SwiftData
       |
       v
CheckInCelebrationView (.fullScreenCover)
  - StreakEngine.currentStreak(from: allEvents) for badge
  - Auto-dismiss after 2s OR manual "Back to Goals"

Home Dashboard (read path):
HomeView (@Query goals, @Query completionEvents)
  |
  ├── headerSection: StreakEngine.currentStreak(from: completionEvents)
  ├── quoteSection: VGQuoteBank day-of-year selection
  ├── communityGoalSection: placeholder/ChallengeTemplate data
  ├── quickStatsRow (NavigationLink → AppRoute.stats)
  └── secondaryGoalsSection (GoalEntryChoiceView trigger, flame icons)
```

### Recommended Project Structure

```
Views/
├── HomeView.swift                          (modify — restructure sections)
├── GoalDetailView.swift                    (modify — add GoalDayGridView + check-in CTA)
├── GoalListView.swift                      (modify — "+add" → GoalEntryChoiceView sheet)
├── GoalCreation/
│   ├── GoalCreationWizardView.swift        (modify — add startAtStep + premadeGoal init params)
│   ├── GoalEntryChoiceView.swift           (NEW)
│   ├── PremadeGoalsListView.swift          (NEW)
│   └── Step3DetailsScreen.swift           (modify — add duration field)
├── CheckInCelebrationView.swift           (NEW)
└── Components/
    └── GoalDayGridView.swift              (NEW)
ViewModels/
└── GoalCreationWizardViewModel.swift      (modify — add draftDurationDays + configure(from premadeGoal:))
ViewModels/GoalViewModel.swift             (modify — add addCheckIn(for:context:))
```

### Pattern 1: Overall App Streak Computation

**What:** Use `StreakEngine.currentStreak(from:)` with nil tier and ALL CompletionEvent records to get the overall app streak.
**When to use:** Home header badge, CheckInCelebrationView.

```swift
// Source: VitaminG/Services/StreakEngine.swift (project codebase)
// In HomeView or CheckInCelebrationView:
private var appStreak: Int {
    StreakEngine.currentStreak(from: completionEvents)
    // tier: nil (default) → counts all goals across all tiers
}
```

**Current bug in HomeView:** `currentStreak` is computed as `goals.compactMap { $0.completionEvents?.count }.max() ?? 0` — this returns the max check-in count of any single goal, NOT a streak. It must be replaced with `StreakEngine.currentStreak(from: completionEvents)`.

### Pattern 2: Per-Goal Streak for Flame Icon

**What:** Filter CompletionEvent records by goal ID, then call `StreakEngine.currentStreak(from:)` with the filtered set.
**When to use:** Flame icon on goal rows (D-11), check-in count display in GoalDetailView (GOAL2-05).

```swift
// Source: VitaminG/Services/StreakEngine.swift + existing goalEvents pattern in GoalDetailView
private func goalStreak(_ goal: Goal, allEvents: [CompletionEvent]) -> Int {
    let goalEvents = allEvents.filter { $0.goal?.id == goal.id }
    return StreakEngine.currentStreak(from: goalEvents)
}

// Flame icon display condition (D-11):
if goalStreak(goal, allEvents: events) >= 3 {
    Image(systemName: "flame.fill")
        .foregroundStyle(VGTheme.accentGold)
        .accessibilityLabel("\(goalStreak(goal, allEvents: events)) day streak — on fire!")
}
```

### Pattern 3: Check-In Action (New GoalViewModel Method)

**What:** A dedicated check-in that creates a `CompletionEvent` for today WITHOUT toggling `goal.isCompleted`. This is distinct from the existing `toggleCompletion()` which marks a goal permanently complete.
**When to use:** GoalDetailView "Check in for today" CTA (GOAL2-04, GOAL2-05).

```swift
// Source: GoalViewModel.swift pattern — mirrors CompletionEvent insertion in toggleCompletion
// New method to add to GoalViewModel:
func addCheckIn(for goal: Goal, context: ModelContext) {
    let event = CompletionEvent()
    event.completedAt = Date()
    event.tierRawValue = goal.tierRawValue
    context.insert(event)
    event.goal = goal
    rescheduleNotification(context: context)
    reloadWidgetTimelines()
}
```

**Guard:** Prevent duplicate check-ins on the same calendar day. Check `goal.completionEvents?.contains(where: { Calendar.current.isDateInToday($0.completedAt ?? .distantPast) })` before inserting.

### Pattern 4: GoalDayGridView — Calendar Month Grid

**What:** `LazyVGrid` with 7 `GridItem(.fixed(36))` columns. Populate cells for each day of the displayed month. Pad leading cells for the weekday offset of the 1st.
**When to use:** GoalDetailView embedded component (GOAL2-05).

```swift
// Source: UI-SPEC.md §GoalDayGridView + Calendar API (ASSUMED — standard Swift Calendar pattern)
@State private var displayedMonth: Date = Date()  // local state

private var daysInMonth: [Date?] {
    var calendar = Calendar.current
    calendar.firstWeekday = 2  // Monday start
    guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
          let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
    else { return [] }
    let weekdayOffset = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
    var days: [Date?] = Array(repeating: nil, count: weekdayOffset)
    for day in range {
        if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
            days.append(date)
        }
    }
    return days
}

// Column header: ["M", "T", "W", "T", "F", "S", "S"]
// Each cell: 32pt circle — filled accentSage if completedDays.contains(startOfDay(cell))
```

**Month navigation bounds:**
- Cannot navigate past current month into the future: `displayedMonth <= Calendar.current.startOfDay(for: Date())`
- Cannot navigate before `goal.startDate ?? goal.creationDate`

### Pattern 5: GoalEntryChoiceView Sheet Routing (Callback Pattern)

**What:** Medium-detent sheet with 3 path cards. Each path card emits a typed selection back to the parent via callback. The parent view owns all sheet presentation state for the downstream wizard, so child views never own orphaned ViewModels whose state is later thrown away.
**When to use:** "+add" trigger from HomeView.secondaryGoalsSection and GoalListView.

```swift
// Source: CONTEXT.md D-05/D-06/D-08, UI-SPEC §GoalEntryChoiceView
// Parent view (HomeView / GoalListView) state:
@State private var showingGoalEntryChoice = false
@State private var showingWizard = false
@State private var wizardStartStep: Int = 0
@State private var pendingPremadeGoal: (title: String, category: GoalCategory)? = nil

// GoalEntryChoiceView signature:
struct GoalEntryChoiceView: View {
    let onSelectWizard: (Int) -> Void
    let onSelectPremade: (String, GoalCategory) -> Void
    // Path 1 ("Need ideas"): NavigationLink inside the sheet pushes
    //   PremadeGoalsListView(onSelect: { title, category in
    //     onSelectPremade(title, category); dismiss()
    //   })
    // Path 2 ("Already have a goal"): Button → onSelectWizard(1); dismiss()
    // Path 3 ("Build my own goal"): Button → onSelectWizard(0); dismiss()
}

// PremadeGoalsListView signature (no orphan VM):
struct PremadeGoalsListView: View {
    let onSelect: (String, GoalCategory) -> Void
    // Row tap: onSelect(premadeGoal.title, premadeGoal.category)
}

// Parent sheet wiring:
// .sheet(isPresented: $showingGoalEntryChoice) {
//   GoalEntryChoiceView(
//     onSelectWizard: { step in
//       wizardStartStep = step
//       pendingPremadeGoal = nil
//       showingGoalEntryChoice = false
//       DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showingWizard = true }
//     },
//     onSelectPremade: { title, category in
//       wizardStartStep = 2
//       pendingPremadeGoal = (title, category)
//       showingGoalEntryChoice = false
//       DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showingWizard = true }
//     })
// }
// .sheet(isPresented: $showingWizard) {
//   GoalCreationWizardView(startAtStep: wizardStartStep, premadeGoal: pendingPremadeGoal)
// }
```

**Why callbacks (not local VMs):** A `@State` ViewModel inside `PremadeGoalsListView` would be a *different instance* from the one inside the wizard sheet that the parent later presents. Pre-fill writes to the orphan VM are discarded. The callback pattern lets the parent inject the selection into the wizard's own VM via the wizard init.

**Sheet navigation strategy:** `GoalEntryChoiceView` wraps a `NavigationStack` so `PremadeGoalsListView` can be pushed inline. Paths 2/3/Premade all dismiss the sheet first; the parent then presents `GoalCreationWizardView` as its own sheet (preventing nested NavigationStacks per Pitfall 4).

### Pattern 6: CheckInCelebrationView — Replicate MilestoneCelebrationView

**What:** Identical dark-overlay + Canvas confetti + badge card pattern. Auto-dismiss with `DispatchQueue.main.asyncAfter`. Manual dismiss button always visible.

```swift
// Source: VitaminG/Views/MilestoneCelebrationView.swift (project codebase)
// Auto-dismiss:
.onAppear {
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        dismiss()
    }
    UIAccessibility.post(notification: .announcement,
        argument: "Check-in complete! \(streakCount) day streak")
}

// Reduce motion: skip confetti canvas (accessibilityReduceMotion)
// Badge scales statically: badgeScale = 1.0 without spring animation
```

**Key difference from MilestoneCelebrationView:** No badge save logic needed (celebration is per check-in, not a one-time milestone). The confetti canvas code is copy-identical to MilestoneCelebrationView.

### Pattern 7: PremadeGoalsListView — Using GoalCategory.suggestions

**What:** Hardcoded pre-made goals sourced from `GoalCategory.suggestions`. Each category provides 4–5 goal strings. Tapping a goal emits the selection upward via callback (the parent handles wizard pre-fill — see Pattern 5).

```swift
// Source: VitaminG/Models/GoalCategory.swift — GoalCategory.suggestions property
// Available categories with suggestions: .body (5), .mind (5), .wellness (5),
// .money (5), .connection (4), .creative (4), .habit (5)
// .other has 0 suggestions — omit from PremadeGoalsListView sections.

struct PremadeGoal: Identifiable {
    let id = UUID()
    let title: String
    let category: GoalCategory
}

// Build list by flattening GoalCategory.allCases (excluding .other) .suggestions:
let premadeGoals: [PremadeGoal] = GoalCategory.allCases
    .filter { !$0.suggestions.isEmpty }
    .flatMap { cat in cat.suggestions.map { PremadeGoal(title: $0, category: cat) } }
```

**GoalCreationWizardViewModel extension:** Add `configure(fromPremade title: String, category: GoalCategory)` that sets `selectedCategory = category`, `draftTitle = title`, and `currentStep = 2` (jumping to Step 3). The **wizard view itself** (not a child of the picker) owns the VM and invokes this in `.onAppear` when its new `premadeGoal:` init parameter is non-nil.

### Pattern 8: GoalCreationWizardView — startAtStep + premadeGoal Parameters

**What:** Add optional `startAtStep: Int = 0` AND optional `premadeGoal: (title: String, category: GoalCategory)? = nil` init params so "Already have a goal" path can open at step 1 (name) and pre-made goal path jumps to step 2 (details) with pre-fill applied to the wizard's OWN internal VM.

```swift
// Source: GoalCreationWizardView.swift (project codebase) — existing init pattern
init(isOnboarding: Bool = false,
     editingGoal: Goal? = nil,
     startAtStep: Int = 0,                                            // NEW
     premadeGoal: (title: String, category: GoalCategory)? = nil,     // NEW
     onComplete: (() -> Void)? = nil) {
    self.isOnboarding = isOnboarding
    self.editingGoal = editingGoal
    self.startAtStep = startAtStep
    self.premadeGoal = premadeGoal
    self.onComplete = onComplete
}

// In .onAppear (priority: editingGoal > premadeGoal > startAtStep):
.onAppear {
    if let goal = editingGoal {
        wizardVM.configure(from: goal)
    } else if let pg = premadeGoal {
        wizardVM.configure(fromPremade: pg.title, category: pg.category)
    } else if startAtStep > 0 {
        wizardVM.currentStep = startAtStep
    }
}
```

**Why both params:** `premadeGoal` carries the pre-fill payload because the wizard's `wizardVM` is created fresh when the wizard sheet opens — there is no upstream VM to share. `startAtStep` covers the "Already have a goal" path (no pre-fill, just step jump).

### Pattern 9: Community Goal Card — Placeholder Using ChallengeTemplate

**What:** The community goal for Phase 18 is sourced from `UserChallenge` (existing model). Phase 21 adds the full CloudKit community goal infrastructure. For Phase 18, display the active `UserChallenge` (if any) as the community goal card, or show a placeholder if none.

**Data source decision (Claude's discretion):** Use `@Query` for `[UserChallenge]` filtered to `statusRaw == "active"`. The progress bar shows `userChallenge.totalCheckIns / template?.durationDays` as the community completion. If no active challenge exists, hide the community goal section or show a minimal placeholder card.

```swift
// Source: CommunityGoalsLandingView.swift (existing pattern)
private var communityProgress: Double {
    guard let challenge = primaryChallenge,
          let template = challenge.template else { return 0.0 }
    return min(1.0, Double(challenge.totalCheckIns ?? 0) / Double(max(1, template.durationDays ?? 90)))
}
```

### Anti-Patterns to Avoid

- **Using `toggleCompletion()` for the "Check in for today" CTA:** `toggleCompletion` sets `goal.isCompleted = true` permanently. A daily check-in must only insert a `CompletionEvent`, not flip the isCompleted flag. Needs a new `addCheckIn(for:context:)` method.
- **Using `goals.compactMap { $0.completionEvents?.count }.max()` for streak:** This gives the max completion count of any single goal, not a streak of consecutive days. Always use `StreakEngine.currentStreak(from: allEvents)`.
- **Nested NavigationStack inside GoalCreationWizardView sheet:** The wizard already conditionally wraps itself in a NavigationStack when not in onboarding mode. Do not add another NavigationStack in the GoalEntryChoiceView that presents the wizard — dismiss the sheet first, then present the wizard as a new sheet from the parent view.
- **Orphaned `@State` ViewModels in picker/list views:** Never create a `@State private var wizardVM = GoalCreationWizardViewModel()` inside `PremadeGoalsListView` or similar picker views. The wizard sheet, when presented later by the parent, creates its OWN VM — writes to the picker's local VM are discarded. Use callbacks (Pattern 5) to emit the selection upward and let the parent inject the pre-fill via the wizard's `premadeGoal:` init param (Pattern 8).
- **Adding `@Attribute(.unique)` to new model fields:** CloudKit does not support atomic uniqueness. Per CLAUDE.md, never use this attribute.
- **Force-unwrapping `goal.completionEvents`:** The relationship is optional in SwiftData/CloudKit. Always use `goal.completionEvents ?? []`.
- **Hard-coding VGTheme hex values:** All color references must use `VGTheme.*` tokens (not raw `Color(red:green:blue:)` values). VGTheme handles light/dark mode adaptation.
- **Using `CormorantGaramond-Medium` weight:** The UI-SPEC restricts Cormorant Garamond to Regular and SemiBold only in Phase 18. Step3DetailsScreen uses `CormorantGaramond-Medium` in the `encouragementCard` — do not introduce this weight in new Phase 18 code.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Consecutive-day streak | Custom loop over CompletionEvent sorted array | `StreakEngine.currentStreak(from:tier:calendar:)` | Already DST-safe, handles nil completedAt, tested |
| Confetti animation | SpriteKit scene, third-party confetti lib | Canvas + TimelineView (MilestoneCelebrationView pattern) | Already exists; zero new dependencies |
| Quote rotation | Custom date-to-index mapping | `VGQuoteBank.all[Calendar.component(.day, from:) % count]` | Quote bank exists with 6 categories and 50+ quotes |
| Calendar month cells | Custom day-of-month array builder | `Calendar.range(of: .day, in: .month, for:)` + `dateComponents` | Standard Foundation Calendar API — no math-based workarounds |
| Pre-made goals data | CloudKit fetch, JSON file, plist | `GoalCategory.suggestions` property | Already defined with 33 goals across 7 categories; works offline |
| Wizard pre-fill | Re-implementing configure() | `GoalCreationWizardViewModel.configure(from:)` pattern | Existing edit-mode pre-fill; add a new overload for pre-made goals |

**Key insight:** This phase is almost entirely integration and composition of existing building blocks. The main value-add is routing and new view files — not new algorithmic logic.

---

## Common Pitfalls

### Pitfall 1: Streak Computed Wrong on HomeView
**What goes wrong:** `currentStreak` in HomeView currently returns `goals.compactMap { $0.completionEvents?.count }.max() ?? 0` — the highest completion count across goals, not a streak of consecutive days. The Home header will show "47" when the user has 47 total completions on one goal but only a 3-day streak.
**Why it happens:** HomeView predates StreakEngine — it was written before the streak service existed.
**How to avoid:** Replace `currentStreak` computed property with `StreakEngine.currentStreak(from: completionEvents)` using the `@Query private var completionEvents: [CompletionEvent]` that already exists in HomeView.
**Warning signs:** Streak number on Home header matches total check-in count rather than a streak of consecutive days.

### Pitfall 2: Check-in vs. Complete Conflation
**What goes wrong:** Using `GoalViewModel.toggleCompletion(goal:context:)` for the daily "Check in for today" action permanently marks the goal as completed (`goal.isCompleted = true`). The goal disappears from active goals list and the user cannot check in again.
**Why it happens:** The existing CTA in GoalDetailView.actionsSection is labeled "Mark as Complete" and uses toggleCompletion — functionally different from a daily check-in.
**How to avoid:** Implement `GoalViewModel.addCheckIn(for goal:context:)` that only inserts a CompletionEvent. Never call toggleCompletion from the day grid check-in CTA.
**Warning signs:** After tapping "Check in for today", the goal vanishes from the My Goals list.

### Pitfall 3: Same-Day Duplicate Check-Ins
**What goes wrong:** User taps "Check in for today" multiple times, creating multiple CompletionEvents for the same calendar day. `StreakEngine.currentStreak` deduplicates by `Set<Date>` of start-of-day values, so streaks won't overcount — but total check-in counts will inflate and the day grid will show duplicate records.
**Why it happens:** No guard in addCheckIn prevents same-day re-entry.
**How to avoid:** Before inserting a CompletionEvent, check `goal.completionEvents?.contains(where: { Calendar.current.isDateInToday($0.completedAt ?? .distantPast) }) == true`. If already checked in today, show a "Already checked in today" state on the CTA (disabled button or checkmark indicator).
**Warning signs:** User can tap "Check in for today" multiple times in a session; day grid shows multiple filled circles for the same date.

### Pitfall 4: GoalEntryChoiceView Nested NavigationStack
**What goes wrong:** Wrapping `GoalEntryChoiceView` in a NavigationStack inside the sheet, then presenting `GoalCreationWizardView` as a NavigationLink destination within the same stack. `GoalCreationWizardView` also wraps itself in a NavigationStack (non-onboarding mode), causing nested NavigationStacks — swipe-back goes to wrong screen.
**Why it happens:** `GoalCreationWizardView.wizardContent` wraps in a NavigationStack unless `isOnboarding: true`.
**How to avoid:** `GoalEntryChoiceView` should use its own inner `NavigationStack` for `PremadeGoalsListView` push. For paths 2 and 3 (wizard), dismiss the sheet and present `GoalCreationWizardView` as a separate sheet from the parent via `@State var showingWizard = false` on HomeView/GoalListView.
**Warning signs:** Tapping "Build my own goal" pushes wizard into the choice sheet's stack instead of presenting it full-screen.

### Pitfall 5: Day Grid Leading Offset Calculation
**What goes wrong:** The day grid pads cells for the weekday offset of the 1st of the month but uses `Calendar.current.firstWeekday` (Sunday = 1 in Gregorian) instead of Monday. This produces a one-day offset error where Monday appears in Sunday's column.
**Why it happens:** `Calendar.current` uses Sunday as firstWeekday by default in most locales.
**How to avoid:** Create a local `var calendar = Calendar.current; calendar.firstWeekday = 2` (Monday = 2). Calculate offset as `(calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7`.
**Warning signs:** Day grid shows dates shifted one column right — e.g., a Monday appears in the T column.

### Pitfall 6: Community Goal Section When No Challenge Exists
**What goes wrong:** HomeView crashes or shows an empty broken section when `userChallenges.first(where: { $0.statusRaw == "active" })` returns nil.
**Why it happens:** The community goal section (HOME-03) depends on `UserChallenge` data which may not exist for all users.
**How to avoid:** Wrap the community goal card in `if let primaryChallenge = primaryChallenge { communityGoalCard(primaryChallenge) }`. Do not show the section header ("COMMUNITY GOAL") when there is no challenge.
**Warning signs:** HomeView shows "COMMUNITY GOAL" overline with nothing below it.

### Pitfall 7: Step3DetailsScreen Duration Field — GoalInput Has No Duration Property
**What goes wrong:** Adding a duration field to `Step3DetailsScreen` requires `GoalInput` to carry the value, but `GoalInput` currently has no `durationDays` property. If the executor adds UI without wiring the model, the value is collected but never saved.
**Why it happens:** GOAL2-01 requires duration in step 3, but the existing `GoalInput` struct and `Goal` model don't have a duration field.
**How to avoid:** The planner must include a task to extend `Goal` (SchemaV9 or additive nil-default field on SchemaV8-compatible approach) with `durationDays: Int?` and extend `GoalInput` and `GoalCreationWizardViewModel` accordingly. Check if a lightweight migration (nil-default optional) is acceptable vs. requiring a new schema version.
**Warning signs:** Duration picker appears in UI but saved goals have no duration recorded.

### Pitfall 8: Orphan ViewModel in PremadeGoalsListView
**What goes wrong:** `PremadeGoalsListView` declares `@State private var wizardVM = GoalCreationWizardViewModel()` and calls `wizardVM.configure(fromPremade:)` on row tap. The user dismisses to the wizard sheet — but the wizard creates its OWN fresh `GoalCreationWizardViewModel` internally. Pre-fill writes (selectedCategory, draftTitle) on the picker's VM are silently discarded. The wizard opens blank on Step 3.
**Why it happens:** SwiftUI `@State` ownership: each view that holds `@State var vm = ...` instantiates a new copy. `PremadeGoalsListView` and `GoalCreationWizardView` are sibling sheets — they cannot share a `@State` VM.
**How to avoid:** Use Pattern 5 callbacks. `PremadeGoalsListView` takes `onSelect: (String, GoalCategory) -> Void` and emits the selection upward. The parent dismisses the picker, then presents the wizard with a new `premadeGoal:` init parameter (Pattern 8). The wizard's `.onAppear` calls `wizardVM.configure(fromPremade:)` on its own internal VM.
**Warning signs:** User taps a pre-made goal → wizard appears but Step 3 shows no category and an empty title field.

---

## Code Examples

### App Streak Source (replacing the buggy HomeView.currentStreak)

```swift
// Source: VitaminG/Services/StreakEngine.swift (project codebase)
// Replace existing HomeView.currentStreak:
@Query private var completionEvents: [CompletionEvent]  // already in HomeView

private var appStreak: Int {
    StreakEngine.currentStreak(from: completionEvents)
}
```

### Confetti Canvas (direct copy from MilestoneCelebrationView)

```swift
// Source: VitaminG/Views/MilestoneCelebrationView.swift (project codebase)
private var confettiView: some View {
    TimelineView(.animation) { timeline in
        Canvas { context, size in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let count = 60
            for i in 0..<count {
                let seed = Double(i) * 137.5  // golden angle scatter
                let x = (sin(seed + now * 0.8 + Double(i)) * 0.5 + 0.5) * size.width
                let rawY = (now * 80.0 + seed * 3.7).truncatingRemainder(dividingBy: size.height)
                let y = rawY < 0 ? rawY + size.height : rawY
                let hue = (seed / 360.0).truncatingRemainder(dividingBy: 1.0)
                let color = Color(hue: hue, saturation: 0.8, brightness: 0.9)
                let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                context.fill(Path(rect), with: .color(color))
            }
        }
    }
}
```

### GoalDayGridView Skeleton

```swift
// Source: UI-SPEC.md §GoalDayGridView + CONTEXT.md D-09/D-10/D-11 (ASSUMED for Calendar details)
struct GoalDayGridView: View {
    let goal: Goal
    let completionEvents: [CompletionEvent]
    @State private var displayedMonth: Date = Date()

    private let columns = Array(repeating: GridItem(.fixed(36), spacing: 8), count: 7)
    private let dayHeaders = ["M", "T", "W", "T", "F", "S", "S"]

    private var completedDays: Set<Date> {
        Set(completionEvents
            .filter { $0.goal?.id == goal.id }
            .compactMap { $0.completedAt }
            .map { Calendar.current.startOfDay(for: $0) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month header + navigation
            HStack {
                Button { navigateMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(VGTheme.accentTerra)
                }
                .accessibilityLabel("Previous month")
                .frame(minWidth: 28, minHeight: 28)

                Spacer()
                Text(monthTitle(for: displayedMonth))
                    .font(VGTheme.serif(20, weight: .semibold))
                    .foregroundStyle(VGTheme.textPrimary)
                Spacer()

                Button { navigateMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(canNavigateForward ? VGTheme.accentTerra : VGTheme.textMuted)
                }
                .disabled(!canNavigateForward)
                .accessibilityLabel("Next month")
                .frame(minWidth: 28, minHeight: 28)
            }

            // Column headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(dayHeaders, id: \.self) { header in
                    Text(header)
                        .font(.system(size: 13, weight: .semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(VGTheme.textMuted)
                        .frame(width: 36, height: 20)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    DayCell(date: date, isCompleted: date.map { completedDays.contains($0) } ?? false)
                }
            }
        }
        .padding(16)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var canNavigateForward: Bool {
        let today = Calendar.current.startOfMonth(for: Date())
        let displayed = Calendar.current.startOfMonth(for: displayedMonth)
        return displayed < today
    }

    // ... helper methods: daysInMonth, navigateMonth, monthTitle
}
```

### GoalCreationWizardViewModel Pre-Fill Extension

```swift
// Source: GoalCreationWizardViewModel.swift configure(from:) pattern (project codebase)
// Add to GoalCreationWizardViewModel:
func configure(fromPremade title: String, category: GoalCategory) {
    reset()
    selectedCategory = category
    draftTitle = title
    currentStep = 2  // jump to Step 3 (details)
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `goals.completionEvents?.count` for streak | `StreakEngine.currentStreak(from:)` | Phase 3 (StreakEngine added) | HomeView has not yet been updated; Phase 18 must fix this |
| No goal creation choice screen | 3-path GoalEntryChoiceView sheet | Phase 18 | Adds "Need ideas" path backed by GoalCategory.suggestions |
| No check-in celebration | fullScreenCover MilestoneCelebrationView pattern | Phase 13 (established) | CheckInCelebrationView replicates this; no new pattern needed |
| List-based GoalDetailView progress | Calendar-month day grid | Phase 18 | LazyVGrid 7-column replacing Charts-only progress section |

**Deprecated/outdated:**
- `primaryGoalCard` on Home: Phase 18 repurposes this section as the community goal card; the user's goals move to the "My Goals" section below.
- `dailyWinsEntry` in HomeView: Removed per D-04.
- `stayCloseSection` in HomeView: Review whether this section is kept, moved, or removed. CONTEXT.md does not mention it — the planner should decide its fate (likely keep below My Goals as non-blocking scroll content).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Goal` model does not have a `durationDays` field — must be added for GOAL2-01 duration storage | Common Pitfalls #7, Standard Stack | If a `durationDays` field already exists in a schema not read, an unnecessary schema version is added |
| A2 | `VGQuoteBank.all` (or equivalent flattened property) can be computed by combining all category arrays for day-of-year rotation (HOME-02) | Pattern 7 | VGQuoteBank only exposes per-category statics; a flattened `all` property may need to be added |
| A3 | The `stayCloseSection` in HomeView is kept as-is below the My Goals section | Architecture diagram | If the planner decides to remove it, task scope changes |
| A4 | Calendar.firstWeekday = 2 is the correct ISO Monday-first approach for the day grid | Pattern 4 | Some locales may differ; Monday start is specified by UI-SPEC so override is intentional |
| A5 | Community goal card in Phase 18 uses the active `UserChallenge` as its data source | Pattern 9, HOME-03 | Phase 21 introduces proper community goal models; this approach is a Phase 18 bridge |

---

## Open Questions (RESOLVED)

1. **Does `durationDays` require a new schema version (SchemaV9)?**
   - What we know: Goal model is at SchemaV6.Goal (aliased); adding an optional field with nil default qualifies for lightweight migration.
   - What's unclear: Whether the planner wants to bump to SchemaV9 or treat the field as purely UI state (stored in GoalCreationWizardViewModel but not persisted on Goal yet).
   - Recommendation: Add `durationDays: Int?` to SchemaV6.Goal as a lightweight additive migration. This avoids a full schema version bump while keeping data persistent.
   - **RESOLVED:** Plan 02 Task 1 adds `var durationDays: Int? = nil` to `SchemaV6.Goal` as an additive nil-default field (lightweight migration). No SchemaV9 bump. Confirmed by `acceptance_criteria` "No new Schema file created (! ls VitaminG/VitaminG/VitaminG/Models/SchemaV9.swift is true)".

2. **What happens to `stayCloseSection` (About Us / Contact Us / FAQ) in HomeView?**
   - What we know: HomeView currently has this horizontal scroll section. CONTEXT.md and UI-SPEC are silent on it.
   - What's unclear: Whether it stays, moves, or is removed in the Phase 18 restructure.
   - Recommendation: Keep it below the My Goals section as a non-blocking scroll element — it doesn't conflict with any Phase 18 requirement.
   - **RESOLVED:** Plan 04 leaves `stayCloseSection` intact per the recommendation. Section order in Plan 04 `<interfaces>`: header → quote → community → quickStatsRow → secondaryGoalsSection → stayCloseSection. Documented in Plan 04 Task 1 instruction "Do NOT modify in this task: ... stayCloseSection."

3. **Does the "Check in for today" button in GoalDetailView replace or coexist with "Mark as Complete"?**
   - What we know: GOAL2-05 specifies a "Check in for today" action. GoalDetailView currently has a "Mark as Complete" button (permanent completion).
   - What's unclear: Whether both CTAs exist side-by-side or "Check in for today" replaces "Mark as Complete".
   - Recommendation: Both coexist. "Check in for today" (new, creates CompletionEvent) lives in the day grid section. "Mark as Complete" (existing, permanent) stays in `actionsSection`. They are semantically different actions.
   - **RESOLVED:** Plan 05 Task 3 implements coexistence. Acceptance criterion: `grep -c "Mark as Complete" >= 1` (existing CTA preserved). New "Check in for today" CTA lives in the day grid section and calls `addCheckIn` (not `toggleCompletion`).

4. **How does the VGQuoteBank get used for daily rotation (HOME-02)?**
   - What we know: `VGQuoteBank` has 6 static category arrays. HomeView currently uses a 4-item hardcoded array rotating by day-of-month.
   - What's unclear: Whether to flatten all VGQuoteBank arrays into one pool or keep per-category.
   - Recommendation: Add a computed static `var all: [VGQuote]` to `VGQuoteBank` that concatenates all category arrays. Use `Calendar.current.component(.dayOfYear, from: Date()) % all.count` for daily rotation. This ensures the same quote is shown all day.
   - **RESOLVED:** Plan 02 Task 3 adds `static var all: [VGQuote]` as a deterministic concatenation. Plan 04 Task 1 wires HomeView's `quoteSection` to use `Calendar.current.ordinality(of: .day, in: .year, for: Date())` modulo `VGQuoteBank.all.count`. Plan 01 Task 2 covers determinism with `Phase18QuoteBankTests.test_VGQuoteBank_all_isDeterministic` and `test_dailyQuoteSelection_isStableWithinSameDay`.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Swift | All Swift files | Yes | 6.3.2 | — |
| Xcode | Build + simulator testing | Yes | 26.5 | — |
| iOS Simulator | UI verification | Yes (inferred from Xcode 26.5) | — | — |

No external tools, services, or package managers required. Phase 18 is a pure Swift/SwiftUI codebase phase.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (existing project) |
| Config file | none detected — inline test targets |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests` |
| Full suite command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HOME-01 | appStreak uses StreakEngine, not completionEvents.count | unit | `xcodebuild test ... -only-testing:VitaminGTests/StreakEngineTests` | ❌ Wave 0 |
| HOME-02 | Quote rotates daily from VGQuoteBank | unit | `xcodebuild test ... -only-testing:VitaminGTests/QuoteBankTests` | ❌ Wave 0 |
| HOME-03 | Community goal card hidden when no active challenge | manual-only | visual on simulator | ✅ (manual) |
| HOME-04 | "+add" triggers GoalEntryChoiceView sheet | manual-only | visual on simulator | ✅ (manual) |
| HOME-05 | Stats row navigates to StatsView | manual-only | visual on simulator | ✅ (manual) |
| GOAL2-01 | Step 3 includes duration field; GoalInput carries durationDays | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalInputTests` | ❌ Wave 0 |
| GOAL2-02 | Pre-made goals list has all GoalCategory suggestions (33 goals) | unit | `xcodebuild test ... -only-testing:VitaminGTests/PremadeGoalsTests` | ❌ Wave 0 |
| GOAL2-03 | "Already have a goal" opens wizard at step 1 | manual-only | visual on simulator | ✅ (manual) |
| GOAL2-04 | Check-in creates CompletionEvent, does not set isCompleted | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalViewModelTests` | ❌ Wave 0 |
| GOAL2-04 | Same-day duplicate check-in is blocked | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalViewModelTests` | ❌ Wave 0 |
| GOAL2-05 | Day grid shows correct filled/empty cells for given CompletionEvents | unit | `xcodebuild test ... -only-testing:VitaminGTests/GoalDayGridTests` | ❌ Wave 0 |
| GOAL2-05 | Flame icon appears when consecutive streak >= 3 | unit | `xcodebuild test ... -only-testing:VitaminGTests/StreakEngineTests` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `xcodebuild build -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Per wave merge:** Full test suite above
- **Phase gate:** Build green + manual walkthrough of all 5 success criteria before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `VitaminGTests/StreakEngineTests.swift` — covers HOME-01 streak source fix + GOAL2-05 flame threshold
- [ ] `VitaminGTests/GoalViewModelTests.swift` — covers GOAL2-04 addCheckIn, same-day dedup, isCompleted unchanged
- [ ] `VitaminGTests/GoalDayGridTests.swift` — covers GOAL2-05 grid cell filled/empty logic, month bounds
- [ ] `VitaminGTests/PremadeGoalsTests.swift` — covers GOAL2-02 category.suggestions count and no-empty-title guard
- [ ] `VitaminGTests/GoalInputTests.swift` — covers GOAL2-01 durationDays field persistence

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 18 is local UI only |
| V3 Session Management | no | No session state in this phase |
| V4 Access Control | no | No access-gated features |
| V5 Input Validation | yes | GoalInput.title via GoalViewModel.sanitize() and validate() — already enforced |
| V6 Cryptography | no | No new cryptographic operations |

### Known Threat Patterns for Swift/SwiftUI/SwiftData stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Goal title injection via pre-made goals | Tampering | Pre-made goals are hardcoded Swift literals — no user-supplied strings in PremadeGoalsListView items. Title is passed to GoalCreationWizardViewModel.draftTitle and validated by GoalViewModel.sanitize() + validate() before persistence. |
| Duplicate CompletionEvent insertion | Tampering | addCheckIn guard: `Calendar.current.isDateInToday` check before insert prevents same-day inflation |
| CompletionEvent with nil completedAt | Tampering | StreakEngine.currentStreak already uses `compactMap` to skip nil completedAt — safe |

---

## Sources

### Primary (HIGH confidence)
- Project codebase — `HomeView.swift`, `StreakEngine.swift`, `GoalCreationWizardView.swift`, `Step3DetailsScreen.swift`, `GoalCreationWizardViewModel.swift`, `GoalViewModel.swift`, `MilestoneCelebrationView.swift`, `GoalListView.swift`, `GoalDetailView.swift`, `VGTheme.swift`, `GoalCategory.swift`, `SchemaV6.swift`, `AppRoute.swift` — all read directly this session
- `18-CONTEXT.md` — locked decisions D-01 through D-13
- `18-UI-SPEC.md` — approved UI design contract (spacing, typography, color, component specs)
- `REQUIREMENTS.md` — HOME-01–HOME-06, GOAL2-01–GOAL2-05 definitions
- `CLAUDE.md` — tech stack constraints (Swift/SwiftUI/SwiftData, no third-party deps)

### Secondary (MEDIUM confidence)
- `CommunityGoalsLandingView.swift` — referenced for community goal display pattern; adapted for Phase 18 Home card

### Tertiary (LOW confidence)
- None — all claims verified against codebase or CONTEXT.md

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all stack verified from project files
- Architecture: HIGH — patterns sourced from existing codebase implementations
- Pitfalls: HIGH — pitfalls 1–4 confirmed by reading actual code; 5–8 by API-level knowledge
- Community goal source: MEDIUM — A5 assumption that UserChallenge is the Phase 18 bridge

**Research date:** 2026-05-17
**Last revised:** 2026-05-18 (Pattern 5 / Pattern 8 reshaped to callback + premadeGoal init param; Pitfall 8 added; Open Questions marked RESOLVED)
**Valid until:** 2026-06-17 (stable codebase; no external dependencies to drift)
