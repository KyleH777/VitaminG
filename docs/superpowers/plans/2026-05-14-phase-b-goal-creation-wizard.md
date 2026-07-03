# Phase B — Goal Creation Wizard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the flat `AddGoalView` form with a 3-step wizard (category → name → details) that adds category, frequency, per-goal reminders, privacy, and legacy backdating to the goal creation flow.

**Architecture:** SchemaV6 adds 4 new optional fields to `Goal` via lightweight migration from V5. A new `GoalCreationWizardViewModel` owns all wizard draft state and hands off a `GoalInput` value type to `GoalViewModel.addGoal(input:context:)` at save time. Three focused step views (`Step1CategoryScreen`, `Step2NameScreen`, `Step3DetailsScreen`) live under `Views/GoalCreation/`. The wizard replaces `AddGoalView` everywhere: `GoalListView` (+), `GoalDetailView` (edit), and `OnboardingView` (first goal).

**Tech Stack:** Swift 5.9, SwiftUI, SwiftData, XCTest, UserNotifications, `@Observable`, `ModelContainerFactory`

**Spec:** `docs/superpowers/specs/2026-05-14-phase-b-design.md`

---

## File Map

| Action | File |
|--------|------|
| Create | `VitaminG/Models/SchemaV6.swift` |
| Modify | `VitaminG/Models/VitaminGMigrationPlan.swift` |
| Modify | `VitaminG/Persistence/ModelContainerFactory.swift` |
| Modify | `VitaminG/Models/Schema8pV2.swift` (update `typealias Goal`) |
| Create | `VitaminGTests/SchemaV6Tests.swift` |
| Create | `VitaminG/Models/GoalCategory.swift` |
| Create | `VitaminG/Models/GoalFrequency.swift` |
| Create | `VitaminG/Models/GoalInput.swift` |
| Create | `VitaminGTests/GoalCreationWizardViewModelTests.swift` |
| Create | `VitaminG/ViewModels/GoalCreationWizardViewModel.swift` |
| Modify | `VitaminG/ViewModels/GoalViewModel.swift` |
| Modify | `VitaminG/Services/NotificationScheduler.swift` |
| Modify | `VitaminGTests/NotificationSchedulerTests.swift` |
| Create | `VitaminG/Views/GoalCreation/Step1CategoryScreen.swift` |
| Create | `VitaminG/Views/GoalCreation/Step2NameScreen.swift` |
| Create | `VitaminG/Views/GoalCreation/Step3DetailsScreen.swift` |
| Create | `VitaminG/Views/GoalCreation/GoalCreationWizardView.swift` |
| Modify | `VitaminG/Views/GoalListView.swift` |
| Modify | `VitaminG/Views/GoalDetailView.swift` |
| Modify | `VitaminG/Views/Onboarding/OnboardingView.swift` |
| Delete | `VitaminG/Views/AddGoalView.swift` |

All paths relative to `Desktop/AI/Vitamin G/VitaminG/VitaminG/`.

---

### Task 1: SchemaV6 — add 4 new Goal fields + migration

**Files:**
- Create: `VitaminG/Models/SchemaV6.swift`
- Modify: `VitaminG/Models/VitaminGMigrationPlan.swift`
- Modify: `VitaminG/Persistence/ModelContainerFactory.swift`
- Modify: `VitaminG/Models/Schema8pV2.swift`
- Create: `VitaminGTests/SchemaV6Tests.swift`

**Context:** The app is currently on SchemaV5 (see `ModelContainerFactory.swift` — it references `SchemaV5`). To add fields to `Goal`, we redeclare it in a new `SchemaV6` enum. All new fields are optional/defaulted so the migration is lightweight (no custom logic needed). The `Goal` typealias currently lives in `Schema8pV2.swift` pointing to `SchemaV2.Goal` — update it to `SchemaV6.Goal` so all call sites transparently use the new type.

- [ ] **Step 1.1: Write failing SchemaV6Tests**

Create `VitaminGTests/SchemaV6Tests.swift`:

```swift
import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class SchemaV6Tests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = container.mainContext
    }
    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    func test_schemaV6_versionIdentifier_is6_0_0() {
        XCTAssertEqual(SchemaV6.versionIdentifier, Schema.Version(6, 0, 0))
    }

    func test_schemaV6_modelsArray_containsTenModels() {
        XCTAssertEqual(SchemaV6.models.count, 10,
            "SchemaV6.models: 1 V6 Goal + 2 V2 models + 1 V3 + 3 V4 + 3 V5 = 10")
    }

    func test_goal_category_defaultsToNil() throws {
        let goal = Goal(title: "Test")
        context.insert(goal)
        try context.save()
        XCTAssertNil(goal.category)
    }

    func test_goal_frequency_defaultsToNil() throws {
        let goal = Goal(title: "Test")
        context.insert(goal)
        try context.save()
        XCTAssertNil(goal.frequency)
    }

    func test_goal_reminderTime_defaultsToNil() throws {
        let goal = Goal(title: "Test")
        context.insert(goal)
        try context.save()
        XCTAssertNil(goal.reminderTime)
    }

    func test_goal_startDate_defaultsToNil() throws {
        let goal = Goal(title: "Test")
        context.insert(goal)
        try context.save()
        XCTAssertNil(goal.startDate)
    }

    func test_goal_category_roundtrips() throws {
        let goal = Goal(title: "Run")
        goal.category = "Body"
        goal.frequency = "Daily"
        context.insert(goal)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<Goal>()).first
        XCTAssertEqual(fetched?.category, "Body")
        XCTAssertEqual(fetched?.frequency, "Daily")
    }
}
```

- [ ] **Step 1.2: Run tests — expect compile failure (SchemaV6 undefined)**

In Xcode: Product → Test (⌘U). SchemaV6Tests will fail to compile because `SchemaV6` does not exist yet. That is expected.

- [ ] **Step 1.3: Create SchemaV6.swift**

Create `VitaminG/Models/SchemaV6.swift`:

```swift
import SwiftData
import Foundation

// MARK: - SchemaV6
//
// Version 6 — Phase B: Goal Creation Wizard.
// Adds to Goal: category, frequency, reminderTime, startDate (all optional — CloudKit compatible).
// All other models are unchanged; referenced from their original schema versions.
// When adding SchemaV7, update BOTH `schemas` and `stages` in VitaminGMigrationPlan.swift.

enum SchemaV6: VersionedSchema {
    static var versionIdentifier = Schema.Version(6, 0, 0)

    static var models: [any PersistentModel.Type] {
        [SchemaV6.Goal.self,
         SchemaV2.CompletionEvent.self,
         SchemaV2.UserProfile.self,
         SchemaV3.DailyWin.self,
         SchemaV4.ChallengeTemplate.self,
         SchemaV4.UserChallenge.self,
         SchemaV4.CheckIn.self,
         SchemaV5.TransformationPhoto.self,
         SchemaV5.SpendingFreezeEntry.self,
         SchemaV5.NutritionEntry.self]
    }

    // MARK: - Goal (V6 — adds category, frequency, reminderTime, startDate)
    //
    // isPublic from V2 is preserved unchanged.
    // isPrivate is NOT stored — the wizard maps isPrivate → goal.isPublic = !isPrivate at save time.
    // startDate is the user's real start date for legacy goals; nil means use creationDate.
    @Model
    final class Goal {
        var id: UUID = UUID()
        var title: String?
        var goalDescription: String?
        var tierRawValue: String?
        var isCompleted: Bool = false
        var creationDate: Date?
        var associatedInspiration: String?
        var isPublic: Bool = false
        // New in V6
        var category: String?       // GoalCategory.rawValue
        var frequency: String?      // GoalFrequency.rawValue
        var reminderTime: Date?     // hour + minute used; date component ignored
        var startDate: Date?        // nil = use creationDate; non-nil = legacy backdated start

        @Relationship(deleteRule: .cascade, inverse: \SchemaV2.CompletionEvent.goal)
        var completionEvents: [SchemaV2.CompletionEvent]?

        init(
            title: String,
            goalDescription: String = "",
            tier: GoalTier = .immediate,
            associatedInspiration: String = ""
        ) {
            self.id = UUID()
            self.title = title
            self.goalDescription = goalDescription
            self.tierRawValue = tier.rawValue
            self.isCompleted = false
            self.creationDate = Date()
            self.associatedInspiration = associatedInspiration
            self.completionEvents = []
            self.isPublic = false
        }

        var tier: GoalTier {
            get { GoalTier(rawValue: tierRawValue ?? "") ?? .immediate }
            set { tierRawValue = newValue.rawValue }
        }

        var completed: Bool {
            get { isCompleted }
            set { isCompleted = newValue }
        }
    }
}

// MARK: - Typealiases (V6)
// These replace the V2 typealiases in Schema8pV2.swift.
// typealias Goal = SchemaV6.Goal  ← declared in Schema8pV2.swift (see Step 1.5)
```

- [ ] **Step 1.4: Update VitaminGMigrationPlan.swift**

Open `VitaminG/Models/VitaminGMigrationPlan.swift`. Add `SchemaV6.self` to `schemas` and a new `migrateV5toV6` stage:

```swift
enum VitaminGMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self, SchemaV5.self, SchemaV6.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4, migrateV4toV5, migrateV5toV6]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
    static let migrateV2toV3 = MigrationStage.lightweight(fromVersion: SchemaV2.self, toVersion: SchemaV3.self)
    static let migrateV3toV4 = MigrationStage.lightweight(fromVersion: SchemaV3.self, toVersion: SchemaV4.self)
    static let migrateV4toV5 = MigrationStage.lightweight(fromVersion: SchemaV4.self, toVersion: SchemaV5.self)
    static let migrateV5toV6 = MigrationStage.lightweight(fromVersion: SchemaV5.self, toVersion: SchemaV6.self)
}
```

- [ ] **Step 1.5: Update Goal typealias in Schema8pV2.swift**

In `VitaminG/Models/Schema8pV2.swift`, find line 144 and change:

```swift
// Before
typealias Goal = SchemaV2.Goal

// After
typealias Goal = SchemaV6.Goal
```

Leave `typealias CompletionEvent = SchemaV2.CompletionEvent` and `typealias UserProfile = SchemaV2.UserProfile` unchanged.

- [ ] **Step 1.6: Update ModelContainerFactory.swift**

In `VitaminG/Persistence/ModelContainerFactory.swift`, change all three references from `SchemaV5` to `SchemaV6`:

```swift
// Both makeContainer and makeWidgetContainer — change these lines:
let schema = Schema(SchemaV6.models, version: SchemaV6.versionIdentifier)
```

There are two occurrences (one in `makeContainer`, one in `makeWidgetContainer`). Update both.

- [ ] **Step 1.7: Run tests — expect pass**

Run ⌘U. SchemaV6Tests should pass. All existing tests must remain green. If `SchemaV1Tests` or `SchemaV5Tests` fail, the model count or typealias update is wrong — fix before continuing.

- [ ] **Step 1.8: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/Models/SchemaV6.swift \
        VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift \
        VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift \
        VitaminG/VitaminG/VitaminG/Models/Schema8pV2.swift \
        VitaminG/VitaminG/VitaminGTests/SchemaV6Tests.swift
git commit -m "feat: SchemaV6 — add category/frequency/reminderTime/startDate to Goal"
```

---

### Task 2: GoalCategory enum

**Files:**
- Create: `VitaminG/Models/GoalCategory.swift`

**Context:** Pure enum with no SwiftData dependency. 8 cases matching the wizard Step 1 grid. Each case carries `emoji`, `subtitle`, and `suggestions` (shown as chips in Step 2). Tested indirectly via GoalCreationWizardViewModelTests (Task 5).

- [ ] **Step 2.1: Create GoalCategory.swift**

Create `VitaminG/Models/GoalCategory.swift`:

```swift
import Foundation

enum GoalCategory: String, CaseIterable, Identifiable {
    case body       = "Body"
    case mind       = "Mind"
    case wellness   = "Wellness"
    case money      = "Money"
    case connection = "Connection"
    case creative   = "Creative"
    case habit      = "Habit"
    case other      = "Other"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .body:       return "💪"
        case .mind:       return "🧠"
        case .wellness:   return "🌿"
        case .money:      return "💸"
        case .connection: return "❤️"
        case .creative:   return "🎨"
        case .habit:      return "🌱"
        case .other:      return "✨"
        }
    }

    var subtitle: String {
        switch self {
        case .body:       return "Move, lift, stretch"
        case .mind:       return "Read, learn, focus"
        case .wellness:   return "Sleep, hydrate, breathe"
        case .money:      return "Save, invest, budget"
        case .connection: return "Family, friends, love"
        case .creative:   return "Make, write, build"
        case .habit:      return "Quit, change, replace"
        case .other:      return "Something uniquely yours"
        }
    }

    var suggestions: [String] {
        switch self {
        case .body:
            return ["Walk 10,000 steps", "Work out 3×/week", "Run a 5K", "Stretch daily", "No junk food"]
        case .mind:
            return ["Read 20 pages daily", "Learn one new thing", "Meditate 10 min", "No phone first hour", "Journal every night"]
        case .wellness:
            return ["Sleep by 11pm", "Drink 8 glasses of water", "No alcohol this month", "Morning walk", "Breathe before reacting"]
        case .money:
            return ["Save $500 this month", "No impulse buys", "Track every expense", "Build 3-month emergency fund"]
        case .connection:
            return ["Call a friend weekly", "Family dinner every Sunday", "Send a thank-you note", "No phones at dinner"]
        case .creative:
            return ["Write 500 words daily", "Finish one project", "Learn an instrument", "Sketch every day"]
        case .habit:
            return ["Quit social media scrolling", "No snooze button", "Replace coffee with tea", "10 min cleanup daily"]
        case .other:
            return ["Something uniquely yours"]
        }
    }
}
```

- [ ] **Step 2.2: Build — verify no compile errors**

⌘B. No new tests needed at this step.

- [ ] **Step 2.3: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/Models/GoalCategory.swift
git commit -m "feat: add GoalCategory enum with suggestions per category"
```

---

### Task 3: GoalFrequency enum

**Files:**
- Create: `VitaminG/Models/GoalFrequency.swift`

- [ ] **Step 3.1: Create GoalFrequency.swift**

Create `VitaminG/Models/GoalFrequency.swift`:

```swift
import Foundation

enum GoalFrequency: String, CaseIterable, Identifiable {
    case daily   = "Daily"
    case weekly  = "Weekly"
    case monthly = "Monthly"
    case onetime = "One-time"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .daily:   return "Every day"
        case .weekly:  return "Pick days"
        case .monthly: return "Few times a month"
        case .onetime: return "A milestone"
        }
    }
}
```

- [ ] **Step 3.2: Build — verify no compile errors (⌘B)**

- [ ] **Step 3.3: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/Models/GoalFrequency.swift
git commit -m "feat: add GoalFrequency enum"
```

---

### Task 4: GoalInput value type

**Files:**
- Create: `VitaminG/Models/GoalInput.swift`

**Context:** Carries wizard output to `GoalViewModel.addGoal(input:context:)` and `updateGoal(_:input:context:)`. `isPrivate` maps to `goal.isPublic = !isPrivate` at save time — no `isPrivate` field on the Goal model.

- [ ] **Step 4.1: Create GoalInput.swift**

Create `VitaminG/Models/GoalInput.swift`:

```swift
import Foundation

struct GoalInput {
    var title: String
    var tier: GoalTier
    var category: GoalCategory
    var frequency: GoalFrequency
    var reminderTime: Date?   // nil = no per-goal reminder
    var isPrivate: Bool       // stored as goal.isPublic = !isPrivate
    var startDate: Date?      // nil = use creationDate; non-nil = legacy backdated start
}
```

- [ ] **Step 4.2: Build — verify no compile errors (⌘B)**

- [ ] **Step 4.3: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/Models/GoalInput.swift
git commit -m "feat: add GoalInput value type"
```

---

### Task 5: GoalCreationWizardViewModel (TDD)

**Files:**
- Create: `VitaminGTests/GoalCreationWizardViewModelTests.swift`
- Create: `VitaminG/ViewModels/GoalCreationWizardViewModel.swift`

**Context:** This ViewModel owns all wizard draft state: current step, selected category, title, tier, frequency, reminder toggle/time, privacy, and legacy start-date. It exposes `canAdvanceStep2` (gate on non-empty title), `buildGoalInput()` (creates the `GoalInput` handed to GoalViewModel at save), and `configure(from:)` (pre-fills state for edit mode).

- [ ] **Step 5.1: Write failing tests**

Create `VitaminGTests/GoalCreationWizardViewModelTests.swift`:

```swift
import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class GoalCreationWizardViewModelTests: XCTestCase {
    var sut: GoalCreationWizardViewModel!
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        sut = GoalCreationWizardViewModel()
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = container.mainContext
    }

    override func tearDown() async throws {
        await Task.yield()
        sut = nil
        context = nil
        container = nil
    }

    // MARK: canAdvanceStep2

    func test_canAdvanceStep2_emptyTitle_returnsFalse() {
        sut.draftTitle = ""
        XCTAssertFalse(sut.canAdvanceStep2)
    }

    func test_canAdvanceStep2_whitespaceTitle_returnsFalse() {
        sut.draftTitle = "   "
        XCTAssertFalse(sut.canAdvanceStep2)
    }

    func test_canAdvanceStep2_nonEmptyTitle_returnsTrue() {
        sut.draftTitle = "Walk 10,000 steps"
        XCTAssertTrue(sut.canAdvanceStep2)
    }

    // MARK: suggestions

    func test_suggestions_bodyCategory_containsWalk() {
        XCTAssertTrue(GoalCategory.body.suggestions.contains("Walk 10,000 steps"))
    }

    func test_suggestions_mindCategory_containsRead() {
        XCTAssertTrue(GoalCategory.mind.suggestions.contains("Read 20 pages daily"))
    }

    func test_suggestions_allCategories_haveAtLeastTwo() {
        for cat in GoalCategory.allCases {
            XCTAssertGreaterThanOrEqual(cat.suggestions.count, 2,
                "\(cat.rawValue) needs ≥ 2 suggestions")
        }
    }

    // MARK: buildGoalInput

    func test_buildGoalInput_titleTrimmed() {
        sut.draftTitle = "  Run a 5K  "
        XCTAssertEqual(sut.buildGoalInput().title, "Run a 5K")
    }

    func test_buildGoalInput_categoryMatchesSelection() {
        sut.selectedCategory = .body
        XCTAssertEqual(sut.buildGoalInput().category, .body)
    }

    func test_buildGoalInput_tierMatchesSelection() {
        sut.draftTier = .lifeGoal
        XCTAssertEqual(sut.buildGoalInput().tier, .lifeGoal)
    }

    func test_buildGoalInput_onetimeFrequency_reminderNil() {
        sut.selectedFrequency = .onetime
        sut.reminderEnabled = true
        XCTAssertNil(sut.buildGoalInput().reminderTime)
    }

    func test_buildGoalInput_reminderDisabled_reminderNil() {
        sut.selectedFrequency = .daily
        sut.reminderEnabled = false
        XCTAssertNil(sut.buildGoalInput().reminderTime)
    }

    func test_buildGoalInput_reminderEnabledDaily_reminderSet() {
        sut.selectedFrequency = .daily
        sut.reminderEnabled = true
        XCTAssertNotNil(sut.buildGoalInput().reminderTime)
    }

    func test_buildGoalInput_legacyOn_startDateSet() {
        sut.isLegacy = true
        sut.draftStartDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        XCTAssertNotNil(sut.buildGoalInput().startDate)
    }

    func test_buildGoalInput_legacyOff_startDateNil() {
        sut.isLegacy = false
        XCTAssertNil(sut.buildGoalInput().startDate)
    }

    func test_buildGoalInput_private_isPrivateTrue() {
        sut.isPrivate = true
        XCTAssertTrue(sut.buildGoalInput().isPrivate)
    }

    func test_buildGoalInput_notPrivate_isPrivateFalse() {
        sut.isPrivate = false
        XCTAssertFalse(sut.buildGoalInput().isPrivate)
    }

    // MARK: configure(from:)

    func test_configure_setsEditModeAndTitle() throws {
        let goal = Goal(title: "Existing goal")
        goal.category = GoalCategory.mind.rawValue
        goal.frequency = GoalFrequency.weekly.rawValue
        goal.isPublic = false
        context.insert(goal)

        sut.configure(from: goal)

        XCTAssertTrue(sut.isEditMode)
        XCTAssertEqual(sut.draftTitle, "Existing goal")
        XCTAssertEqual(sut.selectedCategory, .mind)
        XCTAssertEqual(sut.selectedFrequency, .weekly)
        XCTAssertTrue(sut.isPrivate)  // isPublic=false → isPrivate=true
    }

    func test_configure_legacyGoal_setsIsLegacyTrue() throws {
        let goal = Goal(title: "Sober")
        goal.startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())
        context.insert(goal)

        sut.configure(from: goal)

        XCTAssertTrue(sut.isLegacy)
    }

    // MARK: reset()

    func test_reset_clearsAllState() {
        sut.currentStep = 2
        sut.draftTitle = "Something"
        sut.selectedCategory = .body
        sut.isEditMode = true

        sut.reset()

        XCTAssertEqual(sut.currentStep, 0)
        XCTAssertEqual(sut.draftTitle, "")
        XCTAssertEqual(sut.selectedCategory, .other)
        XCTAssertFalse(sut.isEditMode)
    }
}
```

- [ ] **Step 5.2: Run tests — expect compile failure (`GoalCreationWizardViewModel` undefined)**

⌘U. Expected: compile error.

- [ ] **Step 5.3: Create GoalCreationWizardViewModel.swift**

Create `VitaminG/ViewModels/GoalCreationWizardViewModel.swift`:

```swift
import Foundation
import Observation

@MainActor
@Observable
final class GoalCreationWizardViewModel {

    // MARK: - Step state

    var currentStep: Int = 0   // 0 = category, 1 = name, 2 = details

    // MARK: - Step 1

    var selectedCategory: GoalCategory = .other

    // MARK: - Step 2

    var draftTitle: String = ""

    var canAdvanceStep2: Bool {
        !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Step 3

    var draftTier: GoalTier = .immediate
    var selectedFrequency: GoalFrequency = .daily
    var reminderEnabled: Bool = true
    var draftReminderTime: Date = GoalCreationWizardViewModel.defaultReminderTime
    var isPrivate: Bool = false
    var isLegacy: Bool = false
    var draftStartDate: Date = .now

    // MARK: - Edit mode

    var isEditMode: Bool = false
    var editingGoalID: UUID? = nil

    // MARK: - Default reminder (7:30 AM)

    static var defaultReminderTime: Date {
        Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
    }

    // MARK: - Build output

    func buildGoalInput() -> GoalInput {
        let trimmedTitle = draftTitle.trimmingCharacters(in: .whitespaces)
        let reminder: Date? = (reminderEnabled && selectedFrequency != .onetime)
            ? draftReminderTime : nil
        return GoalInput(
            title: trimmedTitle,
            tier: draftTier,
            category: selectedCategory,
            frequency: selectedFrequency,
            reminderTime: reminder,
            isPrivate: isPrivate,
            startDate: isLegacy ? draftStartDate : nil
        )
    }

    // MARK: - Edit pre-fill

    func configure(from goal: Goal) {
        isEditMode = true
        editingGoalID = goal.id
        draftTitle = goal.title ?? ""
        draftTier = goal.tier
        selectedCategory = GoalCategory(rawValue: goal.category ?? "") ?? .other
        selectedFrequency = GoalFrequency(rawValue: goal.frequency ?? "") ?? .daily
        if let rt = goal.reminderTime {
            reminderEnabled = true
            draftReminderTime = rt
        } else {
            reminderEnabled = false
        }
        isPrivate = !goal.isPublic
        isLegacy = goal.startDate != nil
        draftStartDate = goal.startDate ?? .now
    }

    // MARK: - Reset

    func reset() {
        currentStep = 0
        selectedCategory = .other
        draftTitle = ""
        draftTier = .immediate
        selectedFrequency = .daily
        reminderEnabled = true
        draftReminderTime = GoalCreationWizardViewModel.defaultReminderTime
        isPrivate = false
        isLegacy = false
        draftStartDate = .now
        isEditMode = false
        editingGoalID = nil
    }
}
```

- [ ] **Step 5.4: Run tests — expect all pass (⌘U)**

- [ ] **Step 5.5: Commit**

```bash
git add VitaminG/VitaminG/VitaminGTests/GoalCreationWizardViewModelTests.swift \
        VitaminG/VitaminG/VitaminG/ViewModels/GoalCreationWizardViewModel.swift
git commit -m "feat: add GoalCreationWizardViewModel with TDD"
```

---

### Task 6: GoalViewModel — new addGoal/updateGoal input signatures

**Files:**
- Modify: `VitaminG/ViewModels/GoalViewModel.swift`

**Context:** Add `addGoal(input:context:)` and `updateGoal(_:input:context:)` alongside the existing draft-state methods. The old methods (`addGoal(context:)`, `updateGoal(_:context:)`) remain — they are deleted in Task 15 once all callers are replaced. After saving, call `NotificationScheduler.shared.schedulePerGoal(goal)` if a `reminderTime` was set; call `cancelPerGoalNotification(for:)` before rescheduling on edit.

- [ ] **Step 6.1: Add new tests to GoalViewModelTests.swift**

Open `VitaminGTests/GoalViewModelTests.swift` and add these tests after the existing ones:

```swift
// MARK: - addGoal(input:)

func test_addGoalInput_createsGoalWithCorrectFields() throws {
    let input = GoalInput(
        title: "Walk 10,000 steps",
        tier: .immediate,
        category: .body,
        frequency: .daily,
        reminderTime: nil,
        isPrivate: true,
        startDate: nil
    )
    try sut.addGoal(input: input, context: context)

    let goals = try context.fetch(FetchDescriptor<Goal>())
    XCTAssertEqual(goals.count, 1)
    let goal = try XCTUnwrap(goals.first)
    XCTAssertEqual(goal.title, "Walk 10,000 steps")
    XCTAssertEqual(goal.category, GoalCategory.body.rawValue)
    XCTAssertEqual(goal.frequency, GoalFrequency.daily.rawValue)
    XCTAssertFalse(goal.isPublic)   // isPrivate=true → isPublic=false
}

func test_addGoalInput_emptyTitle_throwsTitleEmpty() throws {
    let input = GoalInput(
        title: "   ",
        tier: .immediate,
        category: .other,
        frequency: .daily,
        reminderTime: nil,
        isPrivate: false,
        startDate: nil
    )
    XCTAssertThrowsError(try sut.addGoal(input: input, context: context)) { error in
        XCTAssertEqual(error as? GoalValidationError, .titleEmpty)
    }
}

func test_addGoalInput_legacyStartDate_stored() throws {
    let past = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    let input = GoalInput(
        title: "Sober",
        tier: .lifeGoal,
        category: .habit,
        frequency: .daily,
        reminderTime: nil,
        isPrivate: true,
        startDate: past
    )
    try sut.addGoal(input: input, context: context)

    let goals = try context.fetch(FetchDescriptor<Goal>())
    XCTAssertNotNil(goals.first?.startDate)
}

// MARK: - updateGoal(input:)

func test_updateGoalInput_updatesFields() throws {
    // Create a goal first
    sut.draftTitle = "Old title"
    try sut.addGoal(context: context)

    let goal = try XCTUnwrap(context.fetch(FetchDescriptor<Goal>()).first)

    let input = GoalInput(
        title: "New title",
        tier: .longTerm,
        category: .mind,
        frequency: .weekly,
        reminderTime: nil,
        isPrivate: false,
        startDate: nil
    )
    try sut.updateGoal(goal, input: input, context: context)

    XCTAssertEqual(goal.title, "New title")
    XCTAssertEqual(goal.tier, .longTerm)
    XCTAssertEqual(goal.category, GoalCategory.mind.rawValue)
    XCTAssertTrue(goal.isPublic)  // isPrivate=false → isPublic=true
}
```

- [ ] **Step 6.2: Run tests — expect failures on new tests (methods undefined)**

⌘U. New GoalViewModelTests fail. Existing tests remain green.

- [ ] **Step 6.3: Add new methods to GoalViewModel.swift**

Open `VitaminG/ViewModels/GoalViewModel.swift`. After the existing `updateGoal(_:context:)` method (around line 150), add:

```swift
// MARK: - Input-based CRUD (wizard path)

func addGoal(input: GoalInput, context: ModelContext) throws {
    let cleanTitle = sanitize(input.title)
    try validate(title: cleanTitle, description: "", inspiration: "")

    let goal = Goal(title: cleanTitle, tier: input.tier)
    goal.category    = input.category.rawValue
    goal.frequency   = input.frequency.rawValue
    goal.reminderTime = input.reminderTime
    goal.isPublic    = !input.isPrivate
    goal.startDate   = input.startDate

    context.insert(goal)
    rescheduleNotification(context: context)
    reloadWidgetTimelines()

    if input.reminderTime != nil {
        Task { await NotificationScheduler.shared.schedulePerGoal(goal) }
    }
}

func updateGoal(_ goal: Goal, input: GoalInput, context: ModelContext) throws {
    let cleanTitle = sanitize(input.title)
    try validate(title: cleanTitle, description: "", inspiration: "")

    goal.title     = cleanTitle
    goal.tier      = input.tier
    goal.category  = input.category.rawValue
    goal.frequency = input.frequency.rawValue
    goal.isPublic  = !input.isPrivate
    goal.startDate = input.startDate

    // Cancel old per-goal notification and reschedule with new settings
    NotificationScheduler.shared.cancelPerGoalNotification(for: goal.id)
    goal.reminderTime = input.reminderTime
    if input.reminderTime != nil {
        Task { await NotificationScheduler.shared.schedulePerGoal(goal) }
    }

    rescheduleNotification(context: context)
    reloadWidgetTimelines()
}
```

- [ ] **Step 6.4: Run tests — expect all pass (⌘U)**

- [ ] **Step 6.5: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift \
        VitaminG/VitaminG/VitaminGTests/GoalViewModelTests.swift
git commit -m "feat: add GoalViewModel.addGoal(input:) and updateGoal(_:input:)"
```

---

### Task 7: NotificationScheduler — schedulePerGoal

**Files:**
- Modify: `VitaminG/Services/NotificationScheduler.swift`
- Modify: `VitaminGTests/NotificationSchedulerTests.swift`

**Context:** Add a new extension to `NotificationScheduler` with `schedulePerGoal(_:)`, `cancelPerGoalNotification(for:)`, and the static `perGoalIdentifier(for:)` helper. The identifier is `"com.kyleharrington.VitaminG.goal.<UUID>"`. `.onetime` frequency: no notification scheduled. The reminder time's hour/minute are used; for `.weekly`/`.monthly` the start-date anchor determines weekday/day-of-month.

- [ ] **Step 7.1: Add tests to NotificationSchedulerTests.swift**

Open `VitaminGTests/NotificationSchedulerTests.swift` and add at the end of the class:

```swift
// MARK: - perGoalIdentifier

func test_perGoalIdentifier_containsUUID() {
    let id = UUID()
    let identifier = NotificationScheduler.perGoalIdentifier(for: id)
    XCTAssertTrue(identifier.contains(id.uuidString),
        "Identifier must embed the goal UUID for cancellation")
}

func test_perGoalIdentifier_hasBundlePrefix() {
    let identifier = NotificationScheduler.perGoalIdentifier(for: UUID())
    XCTAssertTrue(identifier.hasPrefix("com.kyleharrington.VitaminG.goal."))
}

// MARK: - cancelPerGoalNotification (smoke — no crash on unknown ID)

func test_cancelPerGoalNotification_unknownID_doesNotCrash() {
    NotificationScheduler.shared.cancelPerGoalNotification(for: UUID())
    // No assertion needed — test passes if no exception is thrown
}
```

- [ ] **Step 7.2: Run tests — expect failures (identifiers not defined yet)**

⌘U. New tests fail. Existing NotificationSchedulerTests remain green.

- [ ] **Step 7.3: Add schedulePerGoal extension to NotificationScheduler.swift**

Open `VitaminG/Services/NotificationScheduler.swift`. At the end of the file, after the Phase 14 extension, add:

```swift
// MARK: - Phase B: Per-goal reminders

extension NotificationScheduler {

    static func perGoalIdentifier(for goalID: UUID) -> String {
        "com.kyleharrington.VitaminG.goal.\(goalID.uuidString)"
    }

    /// Schedules a repeating notification for a single goal based on its frequency and reminder time.
    /// One-time goals are skipped — they have no repeating trigger.
    /// Remove-before-add pattern keeps us within the iOS 64-request cap.
    func schedulePerGoal(_ goal: Goal) async {
        guard let frequencyRaw = goal.frequency,
              let frequency = GoalFrequency(rawValue: frequencyRaw),
              frequency != .onetime else { return }

        let identifier = Self.perGoalIdentifier(for: goal.id)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Vitamin G"
        content.body = goal.title ?? "Time to work on your goal"
        content.sound = .default
        content.userInfo = ["deepLink": "goalList", "goalID": goal.id.uuidString]

        let anchor = goal.reminderTime ?? GoalCreationWizardViewModel.defaultReminderTime
        var components = Calendar.current.dateComponents([.hour, .minute], from: anchor)

        switch frequency {
        case .daily:
            break  // hour + minute is enough
        case .weekly:
            let startAnchor = goal.startDate ?? goal.creationDate ?? Date()
            components.weekday = Calendar.current.component(.weekday, from: startAnchor)
        case .monthly:
            let startAnchor = goal.startDate ?? goal.creationDate ?? Date()
            components.day = Calendar.current.component(.day, from: startAnchor)
        case .onetime:
            return  // guarded above, but explicit for exhaustive switch
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            #if DEBUG
            print("[NotificationScheduler] Failed to add per-goal reminder: \(error)")
            #endif
        }
    }

    /// Removes the pending per-goal notification for the given goal ID.
    /// Call on goal delete or when the reminder is turned off during edit.
    func cancelPerGoalNotification(for goalID: UUID) {
        let identifier = Self.perGoalIdentifier(for: goalID)
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
```

- [ ] **Step 7.4: Run tests — expect all pass (⌘U)**

- [ ] **Step 7.5: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift \
        VitaminG/VitaminG/VitaminGTests/NotificationSchedulerTests.swift
git commit -m "feat: NotificationScheduler.schedulePerGoal — per-goal repeating reminders"
```

---

### Task 8: Step1CategoryScreen

**Files:**
- Create: `VitaminG/Views/GoalCreation/Step1CategoryScreen.swift`

**Context:** Shows the 2×4 category grid. Tapping a card sets `wizardVM.selectedCategory`. "Next" always enabled (category has a default). In onboarding mode the back arrow is hidden. VGTheme colors are already defined in the project (`VGTheme.sandLight`, `VGTheme.clay`, `VGTheme.terra`, `VGTheme.sandMid`, `VGTheme.backgroundCard`).

- [ ] **Step 8.1: Create folder and file**

Create `VitaminG/Views/GoalCreation/Step1CategoryScreen.swift`:

```swift
import SwiftUI

struct Step1CategoryScreen: View {
    @Bindable var wizardVM: GoalCreationWizardViewModel
    var isOnboarding: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerText
                categoryGrid
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(VGTheme.sandLight.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            nextButton
        }
        .navigationBarBackButtonHidden(isOnboarding)
    }

    // MARK: - Subviews

    private var headerText: some View {
        VStack(alignment: .leading, spacing: 6) {
            stepDots
            Text("What kind of\ngoal is this?")
                .font(.custom("CormorantGaramond-Regular", size: 34))
                .foregroundStyle(VGTheme.clay)
                .lineSpacing(2)
            Text("Pick the vibe — we'll personalize from here.")
                .font(.subheadline)
                .foregroundStyle(VGTheme.muted)
        }
    }

    private var stepDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i == 0 ? VGTheme.terra : VGTheme.sandMid)
                    .frame(width: i == 0 ? 22 : 8, height: 8)
            }
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(GoalCategory.allCases) { category in
                CategoryCard(
                    category: category,
                    isSelected: wizardVM.selectedCategory == category
                ) {
                    wizardVM.selectedCategory = category
                }
            }
        }
    }

    private var nextButton: some View {
        Button {
            wizardVM.currentStep = 1
        } label: {
            Text("Next")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(VGTheme.terra)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}

// MARK: - CategoryCard

private struct CategoryCard: View {
    let category: GoalCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(category.emoji)
                    .font(.system(size: 28))
                Text(category.rawValue)
                    .font(.custom("CormorantGaramond-Medium", size: 18))
                    .foregroundStyle(isSelected ? VGTheme.terra : VGTheme.clay)
                Text(category.subtitle)
                    .font(.caption2)
                    .foregroundStyle(VGTheme.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(isSelected ? Color.white : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(isSelected ? VGTheme.terra : VGTheme.sandMid, lineWidth: 2)
            )
            .shadow(color: isSelected ? VGTheme.terra.opacity(0.2) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 8.2: Build — verify no compile errors (⌘B)**

If `VGTheme.muted` or `VGTheme.sandMid` are not defined, check `VGTheme.swift` for the exact property names and adjust accordingly.

- [ ] **Step 8.3: Commit**

```bash
git add "VitaminG/VitaminG/VitaminG/Views/GoalCreation/Step1CategoryScreen.swift"
git commit -m "feat: Step1CategoryScreen — category vibe picker"
```

---

### Task 9: Step2NameScreen

**Files:**
- Create: `VitaminG/Views/GoalCreation/Step2NameScreen.swift`

- [ ] **Step 9.1: Create Step2NameScreen.swift**

Create `VitaminG/Views/GoalCreation/Step2NameScreen.swift`:

```swift
import SwiftUI

struct Step2NameScreen: View {
    @Bindable var wizardVM: GoalCreationWizardViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerText
                goalInputCard
                suggestionsSection
                smartTip
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(VGTheme.sandLight.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            nextButton
        }
        .onAppear { isFocused = true }
    }

    // MARK: - Subviews

    private var headerText: some View {
        VStack(alignment: .leading, spacing: 6) {
            stepDots
            Text("Say it\nout loud.")
                .font(.custom("CormorantGaramond-Regular", size: 34))
                .foregroundStyle(VGTheme.clay)
            Text("Name your goal. The clearer, the more it sticks.")
                .font(.subheadline)
                .foregroundStyle(VGTheme.muted)
        }
    }

    private var stepDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i <= 1 ? VGTheme.terra : VGTheme.sandMid)
                    .frame(width: i == 1 ? 22 : 8, height: 8)
            }
        }
    }

    private var goalInputCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Walk 10,000 steps", text: $wizardVM.draftTitle, axis: .vertical)
                .font(.custom("CormorantGaramond-Regular", size: 22))
                .foregroundStyle(VGTheme.clay)
                .lineLimit(1...4)
                .focused($isFocused)
                .onChange(of: wizardVM.draftTitle) { _, new in
                    if new.count > 100 {
                        wizardVM.draftTitle = String(new.prefix(100))
                    }
                }
                .padding(.bottom, 10)

            Divider()

            HStack {
                Text("\(wizardVM.draftTitle.count)/100")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(
                        wizardVM.draftTitle.count >= 100 ? .red :
                        wizardVM.draftTitle.count >= 85 ? .orange :
                        Color.secondary.opacity(0.5)
                    )
                Spacer()
                Text("✨ Make it personal")
                    .font(.caption2)
                    .foregroundStyle(VGTheme.terra)
            }
            .padding(.top, 8)
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Need ideas?")
                .font(.caption)
                .fontWeight(.bold)
                .textCase(.uppercase)
                .foregroundStyle(VGTheme.muted)
                .tracking(1)

            FlowLayout(spacing: 6) {
                ForEach(wizardVM.selectedCategory.suggestions, id: \.self) { suggestion in
                    Button {
                        wizardVM.draftTitle = suggestion
                    } label: {
                        Text(suggestion)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                wizardVM.draftTitle == suggestion
                                    ? VGTheme.terraLight : Color.white
                            )
                            .foregroundStyle(
                                wizardVM.draftTitle == suggestion
                                    ? VGTheme.terra : VGTheme.clay
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().strokeBorder(
                                    wizardVM.draftTitle == suggestion
                                        ? VGTheme.terra : VGTheme.sandMid,
                                    lineWidth: 1.5
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var smartTip: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("💡")
            Text("**Pro tip:** Specific goals win. \"Walk 10k steps\" beats \"exercise more.\"")
                .font(.footnote)
                .foregroundStyle(VGTheme.clay)
        }
        .padding(12)
        .background(VGTheme.terraLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(VGTheme.terraSoft, lineWidth: 1))
    }

    private var nextButton: some View {
        Button {
            wizardVM.currentStep = 2
        } label: {
            Text("Next")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(wizardVM.canAdvanceStep2 ? VGTheme.terra : VGTheme.sandMid)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!wizardVM.canAdvanceStep2)
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}
```

**Note:** `FlowLayout` is a custom wrapping layout. If it doesn't exist in the codebase yet, add this minimal implementation at the bottom of `Step2NameScreen.swift`:

```swift
// MARK: - FlowLayout (wrapping chip layout)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0; var y: CGFloat = 0; var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 { y += rowHeight + spacing; x = 0; rowHeight = 0 }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowHeight: CGFloat = 0
        var row: [(subview: LayoutSubview, size: CGSize)] = []
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && !row.isEmpty {
                y += rowHeight + spacing; x = bounds.minX; rowHeight = 0; row = []
            }
            row.append((view, size))
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height); x += size.width + spacing
        }
    }
}
```

- [ ] **Step 9.2: Build — verify no compile errors (⌘B)**

Check `VGTheme.terraLight`, `VGTheme.terraSoft` are defined. If not, check `VGTheme.swift` for the closest equivalent.

- [ ] **Step 9.3: Commit**

```bash
git add "VitaminG/VitaminG/VitaminG/Views/GoalCreation/Step2NameScreen.swift"
git commit -m "feat: Step2NameScreen — goal name input with suggestion chips"
```

---

### Task 10: Step3DetailsScreen

**Files:**
- Create: `VitaminG/Views/GoalCreation/Step3DetailsScreen.swift`

- [ ] **Step 10.1: Create Step3DetailsScreen.swift**

Create `VitaminG/Views/GoalCreation/Step3DetailsScreen.swift`:

```swift
import SwiftUI

struct Step3DetailsScreen: View {
    @Bindable var wizardVM: GoalCreationWizardViewModel
    let onSave: () -> Void
    @State private var showingValidationAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerText
                tierSection
                frequencySection
                if wizardVM.selectedFrequency != .onetime {
                    reminderSection
                }
                privacySection
                legacySection
                encouragementCard
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(VGTheme.sandLight.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            saveButton
        }
    }

    // MARK: - Header

    private var headerText: some View {
        VStack(alignment: .leading, spacing: 6) {
            stepDots
            Text("When &\nhow often?")
                .font(.custom("CormorantGaramond-Regular", size: 34))
                .foregroundStyle(VGTheme.clay)
        }
    }

    private var stepDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(VGTheme.terra)
                    .frame(width: i == 2 ? 22 : 8, height: 8)
            }
        }
    }

    // MARK: - Tier

    private var tierSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Tier")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(GoalTier.ordered, id: \.self) { tier in
                    TierOptionCard(
                        tier: tier,
                        isSelected: wizardVM.draftTier == tier
                    ) { wizardVM.draftTier = tier }
                }
            }
        }
    }

    // MARK: - Frequency

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("How often")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(GoalFrequency.allCases) { freq in
                    FrequencyCard(
                        frequency: freq,
                        isSelected: wizardVM.selectedFrequency == freq
                    ) { wizardVM.selectedFrequency = freq }
                }
            }
        }
    }

    // MARK: - Reminder

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Daily nudge")
            HStack(spacing: 12) {
                Text("🔔").font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    DatePicker("", selection: $wizardVM.draftReminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    Text("A gentle reminder, not a guilt trip")
                        .font(.caption)
                        .foregroundStyle(VGTheme.muted)
                }
                Spacer()
                Toggle("", isOn: $wizardVM.reminderEnabled).labelsHidden()
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Privacy")
            HStack(spacing: 12) {
                Text(wizardVM.isPrivate ? "🔒" : "🌍").font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(wizardVM.isPrivate ? "Keep this private" : "Share with community")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(VGTheme.clay)
                    Text(wizardVM.isPrivate ? "Only you can see this goal" : "Friends can cheer you on")
                        .font(.caption)
                        .foregroundStyle(VGTheme.muted)
                }
                Spacer()
                Toggle("", isOn: $wizardVM.isPrivate).labelsHidden()
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
        }
    }

    // MARK: - Legacy

    private var legacySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Already started?")
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text("📅").font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("I've been working on this")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(VGTheme.clay)
                        Text("Set the real start date")
                            .font(.caption).foregroundStyle(VGTheme.muted)
                    }
                    Spacer()
                    Toggle("", isOn: $wizardVM.isLegacy).labelsHidden()
                }
                .padding(14)

                if wizardVM.isLegacy {
                    Divider().padding(.horizontal, 14)
                    HStack {
                        Text("Start date")
                            .font(.caption).foregroundStyle(VGTheme.muted)
                        Spacer()
                        DatePicker("", selection: $wizardVM.draftStartDate,
                                   in: ...Date.now,
                                   displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(14)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
            .animation(.easeInOut(duration: 0.2), value: wizardVM.isLegacy)
        }
    }

    // MARK: - Encouragement card

    private var encouragementCard: some View {
        HStack(spacing: 12) {
            Text("🎉").font(.largeTitle)
            VStack(alignment: .leading, spacing: 4) {
                Text("You're about to set a goal.")
                    .font(.custom("CormorantGaramond-Medium", size: 16))
                    .foregroundStyle(VGTheme.clay)
                Text("That's already further than most people get. We're rooting for you.")
                    .font(.caption)
                    .foregroundStyle(VGTheme.muted)
            }
        }
        .padding(16)
        .background(VGTheme.terraLight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(VGTheme.terraSoft, lineWidth: 1))
    }

    // MARK: - Save button

    private var saveButton: some View {
        Button(action: onSave) {
            Text(wizardVM.isEditMode ? "Save changes" : "Start this journey ✨")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(VGTheme.terra)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption).fontWeight(.bold).textCase(.uppercase)
            .foregroundStyle(VGTheme.muted)
            .tracking(1)
    }
}

// MARK: - TierOptionCard

private struct TierOptionCard: View {
    let tier: GoalTier
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Label(tier.displayName, systemImage: tier.icon)
                    .font(.custom("CormorantGaramond-Medium", size: 15))
                    .foregroundStyle(isSelected ? tier.color : VGTheme.clay)
                Text(tier.description)
                    .font(.caption2)
                    .foregroundStyle(VGTheme.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(isSelected ? Color.white : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(
                isSelected ? tier.color : VGTheme.sandMid, lineWidth: 2))
            .shadow(color: isSelected ? tier.color.opacity(0.2) : .clear, radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FrequencyCard

private struct FrequencyCard: View {
    let frequency: GoalFrequency
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(frequency.rawValue)
                    .font(.custom("CormorantGaramond-Medium", size: 16))
                    .foregroundStyle(isSelected ? VGTheme.terra : VGTheme.clay)
                Text(frequency.subtitle)
                    .font(.caption2)
                    .foregroundStyle(VGTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(isSelected ? Color.white : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(
                isSelected ? VGTheme.terra : VGTheme.sandMid, lineWidth: 2))
            .shadow(color: isSelected ? VGTheme.terra.opacity(0.18) : .clear, radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 10.2: Build — verify no compile errors (⌘B)**

- [ ] **Step 10.3: Commit**

```bash
git add "VitaminG/VitaminG/VitaminG/Views/GoalCreation/Step3DetailsScreen.swift"
git commit -m "feat: Step3DetailsScreen — tier/frequency/reminder/privacy/legacy"
```

---

### Task 11: GoalCreationWizardView container

**Files:**
- Create: `VitaminG/Views/GoalCreation/GoalCreationWizardView.swift`

**Context:** Sheet container that shows the correct step screen based on `wizardVM.currentStep`. Calls `GoalViewModel.addGoal(input:)` or `updateGoal(_:input:)` on save. Shows a validation alert if save throws. In onboarding mode, `isOnboarding: true` hides the Cancel button and calls `onComplete` after save instead of dismissing.

- [ ] **Step 11.1: Create GoalCreationWizardView.swift**

Create `VitaminG/Views/GoalCreation/GoalCreationWizardView.swift`:

```swift
import SwiftUI
import SwiftData

struct GoalCreationWizardView: View {
    let isOnboarding: Bool
    let editingGoal: Goal?
    let onComplete: (() -> Void)?

    @State private var wizardVM = GoalCreationWizardViewModel()
    @State private var goalVM = GoalViewModel()
    @State private var validationError: GoalValidationError?
    @State private var showingValidationAlert = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(
        isOnboarding: Bool = false,
        editingGoal: Goal? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        self.isOnboarding = isOnboarding
        self.editingGoal = editingGoal
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            stepView
                .toolbar {
                    if !isOnboarding {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                wizardVM.reset()
                                dismiss()
                            }
                        }
                    }
                }
        }
        .onAppear {
            if let goal = editingGoal {
                wizardVM.configure(from: goal)
            }
        }
        .alert(
            "Validation Error",
            isPresented: $showingValidationAlert,
            presenting: validationError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    @ViewBuilder
    private var stepView: some View {
        switch wizardVM.currentStep {
        case 0:
            Step1CategoryScreen(wizardVM: wizardVM, isOnboarding: isOnboarding)
        case 1:
            Step2NameScreen(wizardVM: wizardVM)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            wizardVM.currentStep = 0
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
        default:
            Step3DetailsScreen(wizardVM: wizardVM, onSave: saveGoal)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            wizardVM.currentStep = 1
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
        }
    }

    private func saveGoal() {
        let input = wizardVM.buildGoalInput()
        do {
            if let goal = editingGoal {
                try goalVM.updateGoal(goal, input: input, context: modelContext)
            } else {
                try goalVM.addGoal(input: input, context: modelContext)
            }
            wizardVM.reset()
            if isOnboarding {
                onComplete?()
            } else {
                dismiss()
            }
        } catch let error as GoalValidationError {
            validationError = error
            showingValidationAlert = true
        } catch {
            showingValidationAlert = true
        }
    }
}
```

- [ ] **Step 11.2: Build — verify no compile errors (⌘B)**

- [ ] **Step 11.3: Commit**

```bash
git add "VitaminG/VitaminG/VitaminG/Views/GoalCreation/GoalCreationWizardView.swift"
git commit -m "feat: GoalCreationWizardView container — 3-step wizard shell"
```

---

### Task 12: Wire wizard into GoalListView

**Files:**
- Modify: `VitaminG/Views/GoalListView.swift`

**Context:** `GoalListView` currently presents `AddGoalView` via `showingAddGoal` (line 49). Replace the sheet target with `GoalCreationWizardView`. The `viewModel: GoalViewModel` passed to `AddGoalView` is no longer needed for the sheet — the wizard has its own GoalViewModel.

- [ ] **Step 12.1: Update GoalListView.swift**

In `GoalListView.swift`, find line 49:
```swift
.sheet(isPresented: $showingAddGoal) { AddGoalView(viewModel: viewModel) }
```

Replace with:
```swift
.sheet(isPresented: $showingAddGoal) { GoalCreationWizardView() }
```

- [ ] **Step 12.2: Build — verify no compile errors (⌘B)**

- [ ] **Step 12.3: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/Views/GoalListView.swift
git commit -m "feat: GoalListView — present GoalCreationWizardView instead of AddGoalView"
```

---

### Task 13: GoalDetailView — edit wizard + legacy start date

**Files:**
- Modify: `VitaminG/Views/GoalDetailView.swift`

**Context:** `GoalDetailView` currently presents `AddGoalView(viewModel: viewModel, editingGoal: goal)` for editing. Replace with `GoalCreationWizardView(editingGoal: goal)`. Also add an "Edit start date" row in the goal info section for legacy backdating.

- [ ] **Step 13.1: Replace AddGoalView sheet in GoalDetailView.swift**

In `GoalDetailView.swift`, find the edit sheet (around line 47-49):
```swift
.sheet(isPresented: $showingEditGoal) {
    AddGoalView(viewModel: viewModel, editingGoal: goal)
}
```

Replace with:
```swift
.sheet(isPresented: $showingEditGoal) {
    GoalCreationWizardView(editingGoal: goal)
}
```

- [ ] **Step 13.2: Add startDate editing to GoalDetailView**

In `GoalDetailView.swift`, add a `@State private var showingStartDatePicker = false` property near the top of the struct, then find the `notesSection` or `headerSection` (whichever contains goal metadata) and add a start date row. Add the following to the struct body after the existing sheets:

```swift
.sheet(isPresented: $showingStartDatePicker) {
    NavigationStack {
        VStack(spacing: 24) {
            Text("When did you actually start this goal?")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.top)

            DatePicker(
                "Start date",
                selection: Binding(
                    get: { goal.startDate ?? goal.creationDate ?? Date() },
                    set: { goal.startDate = $0 }
                ),
                in: ...Date.now,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()

            Spacer()
        }
        .navigationTitle("Edit Start Date")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { showingStartDatePicker = false }
            }
        }
    }
    .presentationDetents([.medium])
}
```

Also add this row inside the `notesSection` or `actionsSection` (whichever is appropriate for metadata):

```swift
Button {
    showingStartDatePicker = true
} label: {
    Label("Edit start date", systemImage: "calendar.badge.clock")
        .font(.subheadline)
        .foregroundStyle(VGTheme.terra)
}
```

- [ ] **Step 13.3: Build — verify no compile errors (⌘B)**

- [ ] **Step 13.4: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift
git commit -m "feat: GoalDetailView — wizard edit + legacy start date picker"
```

---

### Task 14: OnboardingView — replace CreateFirstGoalScreen with wizard

**Files:**
- Modify: `VitaminG/Views/Onboarding/OnboardingView.swift`

**Context:** `OnboardingView.swift` has a `.createGoal` case that renders `CreateFirstGoalScreen(onboardingVM:, onComplete:, onSkipGoal:)`. Replace it with `GoalCreationWizardView(isOnboarding: true, onComplete: finish)`. The `CreateFirstGoalScreen.swift` file is deleted in Task 15.

- [ ] **Step 14.1: Update the .createGoal case in OnboardingView.swift**

In `VitaminG/Views/Onboarding/OnboardingView.swift`, find lines 42–47:
```swift
case .createGoal:
    CreateFirstGoalScreen(
        onboardingVM: onboardingVM,
        onComplete: finish,
        onSkipGoal: finish
    )
```

Replace with:
```swift
case .createGoal:
    GoalCreationWizardView(isOnboarding: true, onComplete: finish)
```

- [ ] **Step 14.2: Build — verify no compile errors (⌘B)**

`CreateFirstGoalScreen` still exists at this point, so the only change is the call site. If `onboardingVM` was only used for `CreateFirstGoalScreen`, check whether it has other usages in `OnboardingView` — if not, it can be removed now (or in Task 15 cleanup).

- [ ] **Step 14.3: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/Views/Onboarding/OnboardingView.swift
git commit -m "feat: OnboardingView — use GoalCreationWizardView for createGoal step"
```

---

### Task 15: Delete AddGoalView + CreateFirstGoalScreen + full test suite

**Files:**
- Delete: `VitaminG/Views/AddGoalView.swift`
- Delete: `VitaminG/Views/Onboarding/CreateFirstGoalScreen.swift`

**Context:** Both files are now unreferenced. Deleting them removes the old flat form. Also clean up the old draft-state `addGoal(context:)` callers if none remain, and verify the full test suite is green.

- [ ] **Step 15.1: Delete AddGoalView.swift**

In Xcode's Project Navigator: right-click `AddGoalView.swift` → Delete → Move to Trash.

Or from terminal:
```bash
rm "VitaminG/VitaminG/VitaminG/Views/AddGoalView.swift"
```

Then remove the file from the Xcode project (if using terminal deletion, open Xcode and delete the red broken reference from the navigator).

- [ ] **Step 15.2: Delete CreateFirstGoalScreen.swift**

```bash
rm "VitaminG/VitaminG/VitaminG/Views/Onboarding/CreateFirstGoalScreen.swift"
```

Remove from Xcode navigator as above.

- [ ] **Step 15.3: Build — verify no compile errors (⌘B)**

If any file still references `AddGoalView` or `CreateFirstGoalScreen`, the build will fail. Grep to find stragglers:

```bash
grep -r "AddGoalView\|CreateFirstGoalScreen" VitaminG/VitaminG/VitaminG/ --include="*.swift"
```

Fix any remaining references before continuing.

- [ ] **Step 15.4: Clean up old draft-state addGoal callers (optional)**

The old `addGoal(context:)` and `updateGoal(_:context:)` methods in `GoalViewModel` are still there but should now have no callers. Verify:

```bash
grep -r "addGoal(context:\|updateGoal.*context:" VitaminG/VitaminG/VitaminG/ --include="*.swift"
```

If the only hits are in `GoalViewModelTests.swift` (which tests the old API), leave them — they document the old contract and continue to pass. If hits exist in Views, replace those usages with the wizard flow.

- [ ] **Step 15.5: Run full test suite — expect all green (⌘U)**

All existing tests plus the new SchemaV6Tests, GoalCreationWizardViewModelTests, GoalViewModelTests (new tests), and NotificationSchedulerTests should pass.

- [ ] **Step 15.6: Final commit**

```bash
git add -A
git commit -m "feat: Phase B complete — goal creation wizard replaces AddGoalView"
```

---

## Self-Review Notes

**Spec coverage:**
- ✅ SchemaV6: category, frequency, reminderTime, startDate fields on Goal (Task 1)
- ✅ GoalCategory enum with 8 cases and per-category suggestions (Task 2)
- ✅ GoalFrequency enum with 4 cases (Task 3)
- ✅ GoalInput value type (Task 4)
- ✅ GoalCreationWizardViewModel with canAdvanceStep2, buildGoalInput, configure(from:), reset (Task 5)
- ✅ GoalViewModel.addGoal(input:) and updateGoal(_:input:) (Task 6)
- ✅ NotificationScheduler.schedulePerGoal + cancelPerGoalNotification (Task 7)
- ✅ Step1CategoryScreen (Task 8), Step2NameScreen (Task 9), Step3DetailsScreen (Task 10)
- ✅ GoalCreationWizardView container (Task 11)
- ✅ GoalListView wired (Task 12)
- ✅ GoalDetailView edit + legacy start date (Task 13)
- ✅ OnboardingView .createGoal case replaced (Task 14)
- ✅ AddGoalView + CreateFirstGoalScreen deleted (Task 15)

**Type consistency:** All tasks use `GoalInput`, `GoalCategory`, `GoalFrequency`, `GoalCreationWizardViewModel` — no name drift between tasks.

**CloudKit safety:** All new fields on SchemaV6.Goal are optional or `Bool = false` — lightweight migration safe.
