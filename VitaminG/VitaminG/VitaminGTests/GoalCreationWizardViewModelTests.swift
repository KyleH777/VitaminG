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
        sut.draftTier = .lifeGoal
        sut.selectedFrequency = .weekly
        sut.reminderEnabled = false
        sut.isPrivate = true
        sut.isLegacy = true
        sut.isEditMode = true
        sut.editingGoalID = UUID()

        sut.reset()

        XCTAssertEqual(sut.currentStep, 0)
        XCTAssertEqual(sut.draftTitle, "")
        XCTAssertEqual(sut.selectedCategory, .other)
        XCTAssertEqual(sut.draftTier, .immediate)
        XCTAssertEqual(sut.selectedFrequency, .daily)
        XCTAssertTrue(sut.reminderEnabled)
        XCTAssertFalse(sut.isPrivate)
        XCTAssertFalse(sut.isLegacy)
        XCTAssertFalse(sut.isEditMode)
        XCTAssertNil(sut.editingGoalID)
    }
}
