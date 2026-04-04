import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class GoalViewModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var sut: GoalViewModel!

    override func setUpWithError() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = container.mainContext
        sut = GoalViewModel()
    }

    override func tearDownWithError() throws {
        sut = nil
        context = nil
        container = nil
    }

    // MARK: - Validation: Title Empty

    func test_createGoal_emptyTitle_throwsTitleEmpty() throws {
        sut.draftTitle = "   "  // whitespace-only — sanitize strips to empty
        sut.draftDescription = ""
        sut.draftInspiration = ""

        XCTAssertThrowsError(try sut.addGoal(context: context)) { error in
            XCTAssertEqual(error as? GoalValidationError, .titleEmpty)
        }
    }

    // MARK: - Validation: Title Too Long

    func test_createGoal_titleTooLong_throwsTitleTooLong() throws {
        sut.draftTitle = String(repeating: "a", count: 101)
        sut.draftDescription = ""
        sut.draftInspiration = ""

        XCTAssertThrowsError(try sut.addGoal(context: context)) { error in
            XCTAssertEqual(error as? GoalValidationError, .titleTooLong(GoalViewModel.maxTitleLength))
        }
    }

    // MARK: - Validation: Description Too Long

    func test_createGoal_descriptionTooLong_throwsDescriptionTooLong() throws {
        sut.draftTitle = "Valid Title"
        sut.draftDescription = String(repeating: "b", count: 501)
        sut.draftInspiration = ""

        XCTAssertThrowsError(try sut.addGoal(context: context)) { error in
            XCTAssertEqual(
                error as? GoalValidationError,
                .descriptionTooLong(GoalViewModel.maxDescriptionLength)
            )
        }
    }

    // MARK: - Validation: Inspiration Too Long

    func test_createGoal_inspirationTooLong_throwsInspirationTooLong() throws {
        sut.draftTitle = "Valid Title"
        sut.draftDescription = ""
        sut.draftInspiration = String(repeating: "c", count: 301)

        XCTAssertThrowsError(try sut.addGoal(context: context)) { error in
            XCTAssertEqual(
                error as? GoalValidationError,
                .inspirationTooLong(GoalViewModel.maxInspirationLength)
            )
        }
    }

    // MARK: - CRUD: Valid Goal Persists

    func test_createGoal_validInputs_persistsGoal() throws {
        sut.draftTitle = "Run a marathon"
        sut.draftDescription = "Complete my first 26.2 miles"
        sut.draftTier = .shortTerm
        sut.draftInspiration = ""

        try sut.addGoal(context: context)

        let goals = try context.fetch(FetchDescriptor<Goal>())
        XCTAssertEqual(goals.count, 1)
        XCTAssertEqual(goals.first?.title, "Run a marathon")
    }

    // MARK: - CRUD: Creation Date Set

    func test_createGoal_validInputs_setsCreationDate() throws {
        sut.draftTitle = "Learn Swift"
        sut.draftDescription = ""
        sut.draftInspiration = ""

        try sut.addGoal(context: context)

        let goals = try context.fetch(FetchDescriptor<Goal>())
        XCTAssertNotNil(goals.first?.creationDate)
    }

    // MARK: - CRUD: Correct Tier Stored

    func test_createGoal_validInputs_setsCorrectTier() throws {
        sut.draftTitle = "Launch an app"
        sut.draftDescription = ""
        sut.draftTier = .shortTerm
        sut.draftInspiration = ""

        try sut.addGoal(context: context)

        let goals = try context.fetch(FetchDescriptor<Goal>())
        XCTAssertEqual(goals.first?.tierRawValue, GoalTier.shortTerm.rawValue)
    }

    // MARK: - Completion Toggle: Creates CompletionEvent

    func test_toggleCompletion_createsCompletionEvent() throws {
        sut.draftTitle = "Read 12 books"
        sut.draftDescription = ""
        sut.draftInspiration = ""
        try sut.addGoal(context: context)

        let goals = try context.fetch(FetchDescriptor<Goal>())
        guard let goal = goals.first else {
            XCTFail("Expected a goal to exist")
            return
        }

        sut.toggleCompletion(goal: goal, context: context)

        let events = try context.fetch(FetchDescriptor<CompletionEvent>())
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.goal?.id, goal.id)
    }

    // MARK: - Completion Toggle: Sets isCompleted

    func test_toggleCompletion_setsIsCompletedTrue() throws {
        sut.draftTitle = "Meditate daily"
        sut.draftDescription = ""
        sut.draftInspiration = ""
        try sut.addGoal(context: context)

        let goals = try context.fetch(FetchDescriptor<Goal>())
        guard let goal = goals.first else {
            XCTFail("Expected a goal to exist")
            return
        }

        XCTAssertFalse(goal.completed)
        sut.toggleCompletion(goal: goal, context: context)
        XCTAssertTrue(goal.completed)
    }

    // MARK: - Sanitization: Control Characters Stripped

    func test_sanitize_stripsControlCharacters() {
        // \u{00} is NULL, \u{07} is BEL — both are control characters
        let result = sut.sanitize("\u{00}Hello\u{07}World")
        XCTAssertEqual(result, "HelloWorld")
    }

    // MARK: - Sanitization: Whitespace Normalised

    func test_sanitize_normalizesWhitespace() {
        let result = sut.sanitize("  hello   world  ")
        XCTAssertEqual(result, "hello world")
    }

    // MARK: - Sanitization: Newlines Preserved

    func test_sanitize_preservesNewlines() {
        let result = sut.sanitize("line1\nline2")
        XCTAssertTrue(result.contains("\n"), "Expected newline to be preserved, got: \(result)")
    }

    // MARK: - Delete

    func test_deleteGoal_removesFromContext() throws {
        sut.draftTitle = "Goal to delete"
        sut.draftDescription = ""
        sut.draftInspiration = ""
        try sut.addGoal(context: context)

        var goals = try context.fetch(FetchDescriptor<Goal>())
        XCTAssertEqual(goals.count, 1)

        guard let goal = goals.first else {
            XCTFail("Expected a goal to exist before deletion")
            return
        }

        sut.delete(goal: goal, context: context)

        goals = try context.fetch(FetchDescriptor<Goal>())
        XCTAssertEqual(goals.count, 0)
    }
}
