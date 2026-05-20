---
phase: 18-home-tab-goals-flow
plan: "03"
subsystem: views
tags: [swiftui, goal-creation, wizard, premade-goals, callback-pattern, sheet-routing, duration-picker]

dependency_graph:
  requires:
    - phase: 18-home-tab-goals-flow/18-02
      provides: "GoalCreationWizardViewModel.configure(fromPremade:category:), draftDurationDays, Goal.durationDays"
  provides:
    - "GoalEntryChoiceView: 3-path choice sheet with NavigationStack, onSelectWizard(Int) + onSelectPremade(String,GoalCategory) callbacks"
    - "PremadeGoalsListView: grouped premade goals from GoalCategory.suggestions, onSelect(String,GoalCategory) callback"
    - "GoalCreationWizardView(startAtStep:premadeGoal:): extended init for direct-entry paths; .onAppear writes to wizard's own VM"
    - "Step3DetailsScreen: segmented duration picker (1wk/1mo/3mo/Custom) bound to wizardVM.draftDurationDays"
    - "GoalListView +add: opens GoalEntryChoiceView; routes to wizard with pendingPremadeGoal or wizardStartStep"
  affects:
    - "18-04 — HomeView +add uses identical sheet wiring pattern (GoalEntryChoiceView API established here)"
    - "18-05 — GoalDetailView round-trips through Goal.durationDays (set via Step3 duration picker)"

tech-stack:
  added: []
  patterns:
    - "Two-sheet pattern: GoalEntryChoiceView (choice) + GoalCreationWizardView (wizard) with DispatchQueue.main.asyncAfter(0.35) delay"
    - "Callback routing (Pattern 5): PremadeGoalsListView.onSelect -> GoalEntryChoiceView.onSelectPremade -> parent state -> wizard init param"
    - "Pitfall 8 prevention: PremadeGoalsListView and GoalEntryChoiceView hold NO @State GoalCreationWizardViewModel; wizard's .onAppear writes to its OWN VM"
    - "Segmented picker + custom TextField with 1-365 range validation; save button disabled on invalid custom input"

key-files:
  created:
    - VitaminG/VitaminG/VitaminG/Views/GoalCreation/GoalEntryChoiceView.swift
    - VitaminG/VitaminG/VitaminG/Views/GoalCreation/PremadeGoalsListView.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/GoalCreation/GoalCreationWizardView.swift
    - VitaminG/VitaminG/VitaminG/Views/GoalCreation/Step3DetailsScreen.swift
    - VitaminG/VitaminG/VitaminG/Views/GoalListView.swift

key-decisions:
  - "GoalEntryChoiceView wraps PremadeGoalsListView via NavigationLink inside its own NavigationStack — per RESEARCH.md Pitfall 4 (no nesting of NavigationStack inside a sheet that will present wizard)"
  - "Duration picker defaults to .month (30 days) on first appear if draftDurationDays is nil"
  - "CormorantGaramond-Medium usages in Step3DetailsScreen replaced with SemiBold per UI-SPEC typography constraint"
  - "DispatchQueue.main.asyncAfter(0.35) delay between sheet dismiss and wizard present — prevents SwiftUI double-sheet presentation race"
  - "GoalListView removes showingAddGoal entirely — all add-goal entry points now go through showingGoalEntryChoice"

requirements-completed: [GOAL2-01, GOAL2-02, GOAL2-03]

duration: ~20min
completed: "2026-05-20"
---

# Phase 18 Plan 03: Goal-Creation Entry Flow (GoalEntryChoiceView, PremadeGoalsListView, Wizard Plumbing, Duration Field) Summary

**3-path choice sheet + premade goals list + wizard routing with startAtStep/premadeGoal + duration picker in Step 3 — completing the Goal creation entry flow for GoalListView.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-05-20T23:00:00Z
- **Completed:** 2026-05-20T23:18:25Z
- **Tasks:** 3
- **Files created:** 2
- **Files modified:** 3

## Accomplishments

- Created `GoalEntryChoiceView.swift` — 3-path choice sheet with NavigationStack hosting PremadeGoalsListView push; no orphan VM; uses `onSelectWizard` + `onSelectPremade` callbacks per Pattern 5
- Created `PremadeGoalsListView.swift` — groups all `GoalCategory.suggestions` by category; emits selection via `onSelect` callback; no VM, no sheet, no NavigationStack
- Extended `GoalCreationWizardView` with `startAtStep: Int = 0` and `premadeGoal: (title: String, category: GoalCategory)? = nil` init parameters; `.onAppear` applies pre-fill to wizard's own internal VM (Pitfall 8 fix)
- Added segmented duration picker to `Step3DetailsScreen` (1 week / 1 month / 3 months / Custom), with custom TextField validated to 1–365 days and save button disabled on invalid input; writes to `wizardVM.draftDurationDays` (added in Plan 02)
- Wired `GoalListView` +add button and EmptyStateView/EmptyTierView to `GoalEntryChoiceView` via `showingGoalEntryChoice` state; removed `showingAddGoal` entirely

## Task Commits

Each task was committed atomically:

1. **Task 1: Create GoalEntryChoiceView + PremadeGoalsListView** — `3edfbb1` (feat)
2. **Task 2: Extend GoalCreationWizardView + Step3DetailsScreen duration** — `d93d45d` (feat)
3. **Task 3: Wire GoalListView +add to GoalEntryChoiceView** — `05cc88f` (feat)

## Key APIs

### GoalEntryChoiceView.init

```swift
struct GoalEntryChoiceView: View {
    let onSelectWizard: (Int) -> Void           // 0 = "Build my own goal", 1 = "Already have a goal"
    let onSelectPremade: (String, GoalCategory) -> Void
}
```

### PremadeGoalsListView.init

```swift
struct PremadeGoalsListView: View {
    let onSelect: (String, GoalCategory) -> Void
}
```

### GoalCreationWizardView.init (extended)

```swift
init(isOnboarding: Bool = false,
     editingGoal: Goal? = nil,
     startAtStep: Int = 0,
     premadeGoal: (title: String, category: GoalCategory)? = nil,
     onComplete: (() -> Void)? = nil)
```

## Files Created/Modified

- `VitaminG/VitaminG/VitaminG/Views/GoalCreation/GoalEntryChoiceView.swift` — New: 3-path choice sheet
- `VitaminG/VitaminG/VitaminG/Views/GoalCreation/PremadeGoalsListView.swift` — New: premade goals list
- `VitaminG/VitaminG/VitaminG/Views/GoalCreation/GoalCreationWizardView.swift` — Extended init; .onAppear Pitfall 8 fix
- `VitaminG/VitaminG/VitaminG/Views/GoalCreation/Step3DetailsScreen.swift` — Duration picker added; Medium font fixed
- `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift` — Two-sheet routing; +add now opens GoalEntryChoiceView

## Pitfall 8 Confirmation

Neither `GoalEntryChoiceView` nor `PremadeGoalsListView` holds a `@State GoalCreationWizardViewModel`. Selection flows:

```
PremadeGoalsListView row tap
  → onSelect(title, category) callback
    → GoalEntryChoiceView.onSelectPremade(title, category)
      → dismiss() GoalEntryChoiceView
        → parent sets pendingPremadeGoal + wizardStartStep
          → DispatchQueue.main.asyncAfter(0.35) { showingWizard = true }
            → GoalCreationWizardView(startAtStep: 2, premadeGoal: (title, category))
              → .onAppear { wizardVM.configure(fromPremade: title, category: category) }
                // writes to wizard's OWN internal VM
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Typography Constraint] CormorantGaramond-Medium → SemiBold in Step3DetailsScreen**
- **Found during:** Task 2 implementation
- **Issue:** Step3DetailsScreen had 3 existing `CormorantGaramond-Medium` usages in `TierOptionCard`, `FrequencyCard`, and the encouragement card. The acceptance criterion requires `grep -c "CormorantGaramond-Medium" ... == 0` per UI-SPEC which states "Medium weight is not used in Phase 18; any prior 'Medium' usage maps to SemiBold."
- **Fix:** Replaced all 3 occurrences with `CormorantGaramond-SemiBold`
- **Files modified:** `Step3DetailsScreen.swift`
- **Commit:** `d93d45d`

## Issues Encountered

- **Test target compilation**: `Phase18GoalDayGridTests.swift` references `GoalDayGridCalendar` (forward ref for Plan 05), which prevents the entire `VitaminGTests` target from compiling. This is the expected Wave 0 state documented in 18-02 SUMMARY. The app target (`xcodebuild build`) succeeds cleanly.

## Known Stubs

None — all three paths in GoalEntryChoiceView are wired: Need-ideas pushes PremadeGoalsListView, Already-have-a-goal presents wizard at step 1, Build-my-own presents wizard at step 0. Duration picker has real preset values (7/30/90) and real custom validation.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced beyond those in the plan's threat model. All mitigations applied:

- **T-18-03-01** (custom duration TextField): Mitigated — validates Int conversion + range (1..365); disables save on invalid input; shows inline error text
- **T-18-03-04** (startAtStep skipping required steps): Mitigated — configure(fromPremade:) sets category before currentStep = 2; existing wizard step validation gates preserved
- **T-18-03-05** (stale orphan VM): Mitigated — no @State VM in picker views; confirmed by acceptance criteria grep checks (all == 0)

## Self-Check

### File Existence

- [x] `VitaminG/VitaminG/VitaminG/Views/GoalCreation/GoalEntryChoiceView.swift` — FOUND
- [x] `VitaminG/VitaminG/VitaminG/Views/GoalCreation/PremadeGoalsListView.swift` — FOUND
- [x] `VitaminG/VitaminG/VitaminG/Views/GoalCreation/GoalCreationWizardView.swift` — FOUND, contains `startAtStep`, `premadeGoal`, `wizardVM.configure(fromPremade:`
- [x] `VitaminG/VitaminG/VitaminG/Views/GoalCreation/Step3DetailsScreen.swift` — FOUND, contains `draftDurationDays`, `HOW LONG?`
- [x] `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift` — FOUND, contains `GoalEntryChoiceView`, `pendingPremadeGoal`, `showingGoalEntryChoice`

### Commits

- [x] `3edfbb1` — feat(18-03): add GoalEntryChoiceView and PremadeGoalsListView
- [x] `d93d45d` — feat(18-03): extend GoalCreationWizardView with startAtStep+premadeGoal; add duration to Step3
- [x] `05cc88f` — feat(18-03): wire GoalListView +add to GoalEntryChoiceView with premadeGoal routing

## Self-Check: PASSED

---
*Phase: 18-home-tab-goals-flow*
*Completed: 2026-05-20*
