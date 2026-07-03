# Phase B — Goal Creation UX Design

**Date:** 2026-05-14
**Scope:** Replace `AddGoalView` with a 3-step goal creation wizard. Add category, privacy, frequency, per-goal reminders, and legacy start-date support via SchemaV2 migration.

---

## Overview

The current `AddGoalView` is a flat form (title → tier → description → inspiration). Phase B replaces it with a warm, card-based 3-step wizard matching the handoff design:

- **Step 1:** Pick a category/vibe (Body, Mind, Wellness, Money, Connection, Creative, Habit, Other)
- **Step 2:** Name the goal — large text input with category-specific suggestion chips and a SMART tip
- **Step 3:** Tier + frequency + per-goal reminder time + privacy toggle + legacy start-date toggle

The wizard is used for both creating and editing goals, and replaces `CreateFirstGoalScreen` in onboarding (back/cancel hidden in onboarding mode).

Description and Inspiration fields (from the old form) move to `GoalDetailView` — editable after creation, not during the wizard.

---

## Data Model — SchemaV2

`SchemaV1` is frozen. `SchemaV2` adds five optional fields to `Goal` via a lightweight migration:

```swift
// SchemaV2.Goal additions
var category: String?       // GoalCategory raw value ("Body", "Mind", etc.)
var isPrivate: Bool = false
var frequency: String?      // GoalFrequency raw value ("Daily", "Weekly", "Monthly", "One-time")
var reminderTime: Date?     // Time-of-day component used; date component ignored
var startDate: Date?        // nil = use creationDate; set for legacy/backdated goals
```

`creationDate` is unchanged — it records when the goal was added to the app. `startDate` records when the user actually began working toward the goal (used for streak/progress calculation on legacy goals).

**Migration:** `MigrationPlan` with a single `V1toV2` stage using `.lightweight`. All new fields are optional or have defaults, so no custom migration logic is needed.

---

## New Enums

### `GoalCategory`

```swift
enum GoalCategory: String, CaseIterable, Identifiable {
    case body       = "Body"
    case mind       = "Mind"
    case wellness   = "Wellness"
    case money      = "Money"
    case connection = "Connection"
    case creative   = "Creative"
    case habit      = "Habit"
    case other      = "Other"
}
```

Each case holds: `emoji: String`, `subtitle: String`, `suggestions: [String]` (3–6 template chips shown in Step 2).

Example suggestions:
- `.body` → ["Walk 10,000 steps", "Work out 3×/week", "Run a 5K", "Stretch daily", "No junk food"]
- `.mind` → ["Read 20 pages daily", "Learn one new thing", "Meditate 10 min", "No phone first hour", "Journal every night"]
- `.wellness` → ["Sleep by 11pm", "Drink 8 glasses of water", "No alcohol this month", "Morning walk", "Breathe before reacting"]
- `.money` → ["Save $500 this month", "No impulse buys", "Track every expense", "Build 3-month emergency fund"]
- `.connection` → ["Call a friend weekly", "Family dinner every Sunday", "Send a thank-you note", "No phones at dinner"]
- `.creative` → ["Write 500 words daily", "Finish one project", "Learn an instrument", "Sketch every day"]
- `.habit` → ["Quit social media scrolling", "No snooze button", "Replace coffee with tea", "10 min cleanup daily"]
- `.other` → ["Something uniquely yours"] (placeholder only — user must type their own)

### `GoalFrequency`

```swift
enum GoalFrequency: String, CaseIterable, Identifiable {
    case daily    = "Daily"
    case weekly   = "Weekly"
    case monthly  = "Monthly"
    case onetime  = "One-time"
}
```

`One-time` disables the per-goal reminder (a one-time goal has no repeating nudge). Falls back to global notification time when `reminderTime` is nil.

---

## Architecture

### New: `GoalCreationWizardViewModel`

`@MainActor @Observable` class. Owns all wizard draft state:

```swift
var currentStep: Int = 0          // 0, 1, 2
var selectedCategory: GoalCategory = .other
var draftTitle: String = ""
var draftTier: GoalTier = .immediate
var selectedFrequency: GoalFrequency = .daily
var reminderEnabled: Bool = true
var draftReminderTime: Date = defaultReminderTime   // 7:30 AM today (hour/minute only used)
var isPrivate: Bool = false
var isLegacy: Bool = false
var draftStartDate: Date = .now
var isEditMode: Bool = false       // true when editing existing goal
```

Navigation rules:
- `canAdvanceStep1`: `selectedCategory` chosen (always true — has default)
- `canAdvanceStep2`: `draftTitle.trimmingCharacters(in: .whitespaces).count > 0`
- `canSave`: always true when on Step 3 (title validated on Step 2)

Pre-fill method for edit mode:
```swift
func configure(from goal: Goal)   // populates all draft fields from existing Goal
```

Save handoff:
```swift
func buildGoalInput() -> GoalInput   // value type carrying all wizard fields to GoalViewModel
```

### New: `GoalInput` (value type)

Carries wizard output to `GoalViewModel.addGoal(input:context:)` and `updateGoal(_:input:context:)`:

```swift
struct GoalInput {
    var title: String
    var tier: GoalTier
    var category: GoalCategory
    var frequency: GoalFrequency
    var reminderTime: Date?
    var isPrivate: Bool
    var startDate: Date?
}
```

### New: `GoalCreationWizardView`

Sheet-based container view. Reads `currentStep` to show the correct step screen:
- `Step1CategoryScreen` — 2×4 category grid, tap to select
- `Step2NameScreen` — large text input, category-specific suggestion chips, SMART tip card
- `Step3DetailsScreen` — tier picker (2×2), frequency picker (2×2), reminder time row (hidden for One-time), privacy toggle row, legacy toggle row (reveals `DatePicker` inline)

Step indicator: 3 pill-dots at top of each screen (active dot widens, filled dots = completed steps).

Onboarding mode: `isOnboarding: Bool` parameter. When true, back arrow on Step 1 is hidden/disabled and the cancel button is removed from the toolbar.

### Modified: `GoalViewModel`

`addGoal(input:context:)` and `updateGoal(_:input:context:)` accept `GoalInput`. Internal validation unchanged (title empty/too-long checks still apply). After save, calls `NotificationScheduler.schedulePerGoal(goal)` if `reminderTime != nil`.

Existing draft state properties (`draftTitle`, `draftTier`, etc.) remain for any callers still using them, but are no longer used by the wizard path.

### Modified: `NotificationScheduler`

New method:
```swift
func schedulePerGoal(_ goal: Goal) async
```

- Reads `goal.reminderTime` for hour/minute; reads `goal.frequency` for repeat interval
- `Daily` → `UNCalendarNotificationTrigger` with `dateComponents: [.hour, .minute]`, `repeats: true`
- `Weekly` → same components plus `.weekday` (defaults to same weekday as `startDate ?? creationDate`)
- `Monthly` → components plus `.day` (same day of month)
- `One-time` → no notification scheduled
- Notification identifier: `"goal-\(goal.id.uuidString)"` — used for cancellation on goal delete/edit
- Falls back to global notification time when `reminderTime` is nil and frequency is not One-time

Existing `scheduleGlobalMorningNotification()` is unchanged.

### Modified: `GoalDetailView`

New "Edit start date" row in the goal info section. Tapping opens a `DatePicker` in a `.sheet` limited to dates in the past (`in: ...Date.now`). Sets `goal.startDate`. This is the "legacy import from existing goals" path.

### Modified: `GoalListView`

`+` toolbar button presents `GoalCreationWizardView(isOnboarding: false)`.
Edit tap (long-press or swipe action) presents `GoalCreationWizardView` pre-filled via `wizardVM.configure(from: goal)`.

### Modified: Onboarding

`CreateFirstGoalScreen` is replaced by `GoalCreationWizardView(isOnboarding: true)` embedded inside `OnboardingView`'s `NavigationStack`. The `onComplete` closure is called after the wizard's final save.

### Deleted: `AddGoalView.swift`

Fully replaced by `GoalCreationWizardView`.

---

## Testing

### `GoalCreationWizardViewModelTests` (new)

- Step advancement blocked when title empty on Step 2
- Step advancement allowed when category selected and title non-empty
- Suggestion chips return correct set per category
- Legacy toggle: `startDate` set on toggle-on, cleared on toggle-off
- `buildGoalInput()` returns correct fields after wizard filled
- `configure(from:)` pre-fills all fields from existing Goal
- Edit mode: `isEditMode` set correctly

### `NotificationSchedulerTests` (extend)

- `schedulePerGoal` produces correct trigger for daily/weekly/monthly
- One-time frequency produces no notification
- `reminderTime == nil` falls back to global time
- Notification identifier matches `"goal-{uuid}"`

### `SchemaV2MigrationTests` (new)

- V1 goals survive migration with new fields nil/defaulted
- `isPrivate` defaults to `false` post-migration
- No existing fields modified by migration

---

## Files

| Action | File |
|--------|------|
| Create | `VitaminG/Models/SchemaV2.swift` |
| Create | `VitaminG/Models/GoalCategory.swift` |
| Create | `VitaminG/Models/GoalFrequency.swift` |
| Create | `VitaminG/Models/GoalInput.swift` |
| Create | `VitaminG/ViewModels/GoalCreationWizardViewModel.swift` |
| Create | `VitaminG/Views/GoalCreation/GoalCreationWizardView.swift` |
| Create | `VitaminG/Views/GoalCreation/Step1CategoryScreen.swift` |
| Create | `VitaminG/Views/GoalCreation/Step2NameScreen.swift` |
| Create | `VitaminG/Views/GoalCreation/Step3DetailsScreen.swift` |
| Modify | `VitaminG/ViewModels/GoalViewModel.swift` |
| Modify | `VitaminG/Services/NotificationScheduler.swift` |
| Modify | `VitaminG/Views/GoalListView.swift` |
| Modify | `VitaminG/Views/GoalDetailView.swift` |
| Modify | `VitaminG/Views/Onboarding/OnboardingView.swift` |
| Modify | `VitaminG/Persistence/ModelContainerFactory.swift` |
| Delete | `VitaminG/Views/AddGoalView.swift` |
| Create | `VitaminGTests/GoalCreationWizardViewModelTests.swift` |
| Create | `VitaminGTests/SchemaV2MigrationTests.swift` |
| Modify | `VitaminGTests/NotificationSchedulerTests.swift` (extend) |

All paths relative to `Desktop/AI/Vitamin G/VitaminG/VitaminG/`.

---

## Constraints & Decisions

- All new `Goal` fields are optional or have defaults — CloudKit compatibility maintained
- `SchemaV1` is frozen (per D-15) — all new fields declared in `SchemaV2` only
- Per-goal notification identifier uses `goal.id` UUID — enables clean cancellation on delete
- `One-time` goals never get a repeating notification trigger
- Description and Inspiration remain on `GoalDetailView` (not in wizard) to keep wizard focused
- `AddGoalView` deleted — no backwards-compatibility shim needed
- Onboarding mode hides cancel/back on Step 1 — wizard is not dismissable mid-onboarding
