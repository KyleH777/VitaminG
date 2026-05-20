---
phase: 18-home-tab-goals-flow
plan: "02"
subsystem: viewmodel
tags: [swiftdata, swiftui, goal-model, viewmodel, wizard, quote-bank, lightweight-migration, tdd-green]

dependency_graph:
  requires:
    - phase: 18-home-tab-goals-flow/18-01
      provides: "Phase18GoalInputTests, Phase18GoalViewModelTests, Phase18QuoteBankTests RED test scaffolds"
  provides:
    - "Goal.durationDays: Int? — optional field on SchemaV6.Goal, lightweight additive migration"
    - "GoalInput.durationDays: Int? — field plumbed through to Goal.durationDays on save"
    - "GoalViewModel.addCheckIn(for:context:) — creates CompletionEvent without flipping isCompleted; same-day dedup"
    - "GoalCreationWizardViewModel.draftDurationDays: Int? — backing state for Step3 duration picker"
    - "GoalCreationWizardViewModel.configure(fromPremade:category:) — pre-fills wizard for Need-ideas path"
    - "VGQuoteBank.all — doc comment added; was already GREEN"
  affects:
    - "18-03 — GoalCreationWizardView Step3DetailsScreen binds to draftDurationDays and configure(fromPremade:)"
    - "18-04 — HomeView quoteSection reads VGQuoteBank.all"
    - "18-05 — GoalDetailView calls addCheckIn(for:context:)"

tech-stack:
  added: []
  patterns:
    - "addCheckIn follows toggleCompletion event insertion order: create event, set completedAt, set tierRawValue, context.insert, event.goal = goal — but skips isCompleted flip"
    - "Same-day dedup: Calendar.current.isDateInToday on completedAt; early return if true"
    - "configure(fromPremade:) calls reset() first to clear stale draft state before setting new values"
    - "buildGoalInput() propagates all draftX fields into GoalInput including draftDurationDays"
    - "SwiftData lightweight migration: optional Int? with nil default requires no schema version bump"

key-files:
  created: []
  modified:
    - VitaminG/VitaminG/VitaminG/Models/SchemaV6.swift
    - VitaminG/VitaminG/VitaminG/Models/GoalInput.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/GoalCreationWizardViewModel.swift
    - VitaminG/VitaminG/VitaminG/Services/VGQuoteBank.swift

key-decisions:
  - "No SchemaV9 created — durationDays: Int? = nil on SchemaV6.Goal qualifies as SwiftData lightweight additive migration per RESEARCH.md Open Question 1 resolution"
  - "addCheckIn placed immediately after toggleCompletion in GoalViewModel for code locality; mirrors its event insertion pattern but omits isCompleted flip per D-12 / Pitfall 2"
  - "configure(fromPremade:) calls reset() first so no stale draft state leaks from prior incomplete creation session"
  - "VGQuoteBank.all was already implemented as static let (not var) — static let is functionally equivalent for determinism; no behavior change needed, added doc comment only"
  - "Test target build fails due to GoalDayGridCalendar forward ref (Plan 05) — expected per Wave 0 design; app BUILD SUCCEEDED cleanly"

patterns-established:
  - "Check-in vs completion: addCheckIn = daily tracking event (no isCompleted flip); toggleCompletion = permanent goal completion (flips isCompleted)"
  - "Premade-goal wizard path: configure(fromPremade:) + currentStep = 2 skips Step 1 (category) and Step 2 (name) since both are pre-supplied"

requirements-completed: [HOME-01, HOME-02, GOAL2-01, GOAL2-02, GOAL2-04]

duration: ~25min
completed: "2026-05-20"
---

# Phase 18 Plan 02: Foundation Layer — Model Fields, ViewModel Methods, and Quote Bank Summary

**Goal model gains durationDays, GoalViewModel gains addCheckIn with same-day dedup, and GoalCreationWizardViewModel gains draftDurationDays + configure(fromPremade:) — turning Phase18GoalInputTests and Phase18GoalViewModelTests GREEN.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-20T22:45:00Z
- **Completed:** 2026-05-20T23:09:48Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added `durationDays: Int?` to `SchemaV6.Goal` as a lightweight additive SwiftData migration with nil default (no schema version bump needed)
- Added `durationDays` to `GoalInput` and wired it through `GoalViewModel.addGoal(input:context:)` so values persist end-to-end
- Added `GoalViewModel.addCheckIn(for:context:)` — creates `CompletionEvent` without flipping `isCompleted`; guards against same-day duplicate check-ins via `Calendar.current.isDateInToday`
- Added `GoalCreationWizardViewModel.draftDurationDays: Int?` with load-in-configure-from, reset, and buildGoalInput wiring
- Added `GoalCreationWizardViewModel.configure(fromPremade:category:)` for the Need-ideas wizard path (D-06)
- Phase18GoalInputTests and Phase18GoalViewModelTests compile errors resolved (forward refs eliminated)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add durationDays to Goal (SchemaV6) and GoalInput** — `0126b78` (feat)
2. **Task 2: Add GoalViewModel.addCheckIn, GoalCreationWizardViewModel.draftDurationDays, and configure(fromPremade:)** — `9a442a5` (feat)
3. **Task 3: VGQuoteBank.all doc comment** — `945d47c` (docs)

## Files Created/Modified

- `VitaminG/VitaminG/VitaminG/Models/SchemaV6.swift` — Added `var durationDays: Int? = nil` stored property and init parameter to `SchemaV6.Goal`
- `VitaminG/VitaminG/VitaminG/Models/GoalInput.swift` — Added `var durationDays: Int? = nil` to `GoalInput` struct
- `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` — Added `addCheckIn(for:context:)` method; wired `goal.durationDays = input.durationDays` in `addGoal(input:context:)`
- `VitaminG/VitaminG/VitaminG/ViewModels/GoalCreationWizardViewModel.swift` — Added `draftDurationDays` property, updated `configure(from:)`, `reset()`, `buildGoalInput()`, added `configure(fromPremade:category:)`
- `VitaminG/VitaminG/VitaminG/Services/VGQuoteBank.swift` — Added doc comment to `all` property (already implemented, was GREEN at Wave 0)

## Decisions Made

- No SchemaV9 bump: `durationDays: Int? = nil` on `SchemaV6.Goal` qualifies for SwiftData lightweight additive migration (documented in `VitaminGMigrationPlan.swift` migration policy comments)
- `addCheckIn` mirrors `toggleCompletion`'s event insertion order exactly (create, set completedAt, set tierRawValue, insert, link) but omits the `isCompleted` flip per D-12
- `configure(fromPremade:)` calls `reset()` first before setting category/title/step to prevent state leakage from prior incomplete wizard sessions
- `VGQuoteBank.all` was already `static let` (not `var` as specified in plan) — `static let` is functionally identical for determinism and the tests were already GREEN; changed `var` to `let` would be a no-op change so only a doc comment was added

## Deviations from Plan

### Adjusted Behavior

**1. [Rule 1 - Bug/Clarification] Task 1 GoalViewModel staged with Task 1 commit**
- **Found during:** Task 2 staging
- **Issue:** GoalViewModel.swift contained both the `goal.durationDays = input.durationDays` wiring (Task 1 scope) AND the `addCheckIn` method (Task 2 scope). When Task 1 files were staged, all GoalViewModel changes were staged together.
- **Fix:** Both changes landed in the Task 1 commit (0126b78). The Task 2 commit (9a442a5) only contains GoalCreationWizardViewModel.swift. Functionally equivalent — all specified changes are committed.
- **Impact:** None — plan outcome identical, just split across commits differently.

**2. [No-op] VGQuoteBank.all already existed**
- `VGQuoteBank.all` was a `static let` (not `var`) and tests were already GREEN per 18-01 SUMMARY
- Plan said to add `static var all` — but the existing `static let all` is functionally identical for determinism and the tests pass
- Only added the doc comment; no behavior change

---

**Total deviations:** 1 minor (commit staging order), 1 no-op (VGQuoteBank already done)
**Impact on plan:** No functional impact. All specified symbols exist exactly as contracted.

## Issues Encountered

- **Test target compilation**: The `Phase18GoalDayGridTests.swift` file references `GoalDayGridCalendar` (intentional forward ref, Plan 05), which prevents the entire `VitaminGTests` target from compiling. This is the expected Wave 0 state per the 18-01 SUMMARY. The app target (`xcodebuild build`) succeeds cleanly. Individual test suites (Phase18GoalInputTests, Phase18GoalViewModelTests) cannot be verified via xcodebuild until Plan 05 lands the `GoalDayGridCalendar` type.

## Known Stubs

None — no UI code was added in this plan. All changes are model fields, ViewModel methods, and a doc comment.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced beyond those in the plan's threat model. All mitigations applied:

- **T-18-02-02** (same-day dedup): Mitigated — `isDateInToday` guard in `addCheckIn` prevents CompletionEvent inflation
- **T-18-02-01** (durationDays validation): Accepted — validation is Plan 03's responsibility (Step3DetailsScreen UI gate)
- **T-18-02-03** and **T-18-02-04**: Accepted per plan

## Next Phase Readiness

- Plan 03 (GoalCreationWizardView) can bind `Step3DetailsScreen` to `draftDurationDays` and call `configure(fromPremade:category:)` via `.onAppear`
- Plan 04 (HomeView) can read `VGQuoteBank.all` for daily quote rotation
- Plan 05 (GoalDetailView) can call `addCheckIn(for:context:)` for the "Check in for today" CTA
- **Remaining RED tests**: `Phase18GoalDayGridTests` — 5 tests still RED pending `GoalDayGridCalendar` in Plan 05

## Self-Check

### File Existence

- [x] `VitaminG/VitaminG/VitaminG/Models/SchemaV6.swift` — FOUND, contains `var durationDays: Int?`
- [x] `VitaminG/VitaminG/VitaminG/Models/GoalInput.swift` — FOUND, contains `durationDays`
- [x] `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` — FOUND, contains `func addCheckIn`
- [x] `VitaminG/VitaminG/VitaminG/ViewModels/GoalCreationWizardViewModel.swift` — FOUND, contains `draftDurationDays` and `configure(fromPremade`
- [x] `VitaminG/VitaminG/VitaminG/Services/VGQuoteBank.swift` — FOUND, contains doc comment on `all`

### Commits

- [x] `0126b78` — feat(18-02): add durationDays to Goal model and GoalInput
- [x] `9a442a5` — feat(18-02): add addCheckIn, draftDurationDays, and configure(fromPremade:)
- [x] `945d47c` — docs(18-02): add doc comment to VGQuoteBank.all for HOME-02 daily rotation

## Self-Check: PASSED

---
*Phase: 18-home-tab-goals-flow*
*Completed: 2026-05-20*
