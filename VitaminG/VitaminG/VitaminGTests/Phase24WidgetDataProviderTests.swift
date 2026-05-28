import XCTest
import SwiftData
@testable import VitaminG

final class Phase24WidgetDataProviderTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // Test 1: Tier priority — Immediate wins over ShortTerm regardless of creationDate
    func test_activeGoal_immediateWinsOverShortTerm() throws {
        let immediateGoal = Goal(title: "Immediate Goal", tier: .immediate)
        immediateGoal.creationDate = Date(timeIntervalSince1970: 1000)
        let shortTermGoal = Goal(title: "ShortTerm Goal", tier: .shortTerm)
        shortTermGoal.creationDate = Date(timeIntervalSince1970: 500)
        context.insert(immediateGoal)
        context.insert(shortTermGoal)
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let result = WidgetDataProvider.build(goals: goals, events: [])

        XCTAssertEqual(result.activeGoalTitle, "Immediate Goal",
                       "Tier priority must beat creationDate: Immediate tier wins over ShortTerm")
    }

    // Test 2: Within-tier tiebreak — earliest creationDate wins
    func test_activeGoal_earliestCreationDate() throws {
        let olderGoal = Goal(title: "Older Goal", tier: .immediate)
        olderGoal.creationDate = Date(timeIntervalSince1970: 1000)
        let newerGoal = Goal(title: "Newer Goal", tier: .immediate)
        newerGoal.creationDate = Date(timeIntervalSince1970: 2000)
        context.insert(olderGoal)
        context.insert(newerGoal)
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let result = WidgetDataProvider.build(goals: goals, events: [])

        XCTAssertEqual(result.activeGoalTitle, "Older Goal",
                       "Within-tier tiebreak: earliest creationDate must win")
    }

    // Test 3: Progress clamped to 1.0 when completionEvents.count exceeds durationDays
    func test_activeGoalProgress_clampedToUnit() throws {
        let goal = Goal(title: "Clamped Goal", tier: .immediate, durationDays: 2)
        context.insert(goal)

        // Insert 5 completion events (exceeds durationDays=2 — should clamp to 1.0)
        for _ in 0..<5 {
            let event = CompletionEvent(goal: goal)
            context.insert(event)
        }
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let events = try context.fetch(FetchDescriptor<CompletionEvent>())
        let result = WidgetDataProvider.build(goals: goals, events: events)

        XCTAssertEqual(result.activeGoalProgress, 1.0,
                       "Progress must be clamped to 1.0 when completionEvents.count > durationDays")
    }

    // Test 4: Progress is nil (not 0.0) when durationDays is nil
    func test_activeGoalProgress_nilWhenNoDuration() throws {
        let goal = Goal(title: "No Duration Goal", tier: .immediate, durationDays: nil)
        context.insert(goal)
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let result = WidgetDataProvider.build(goals: goals, events: [])

        XCTAssertNil(result.activeGoalProgress,
                     "activeGoalProgress must be nil (not 0.0) when goal.durationDays is nil")
    }

    // Test 5: Both fields nil when all goals are completed
    func test_activeGoal_nilWhenAllCompleted() throws {
        let goal = Goal(title: "Completed Goal", tier: .immediate)
        goal.isCompleted = true
        context.insert(goal)
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let result = WidgetDataProvider.build(goals: goals, events: [])

        XCTAssertNil(result.activeGoalTitle,
                     "activeGoalTitle must be nil when all goals are completed")
        XCTAssertNil(result.activeGoalProgress,
                     "activeGoalProgress must be nil when all goals are completed")
    }

    // Test 6: placeholder carries sample activeGoalTitle and activeGoalProgress
    func test_placeholder_hasActiveGoalFields() {
        let placeholder = WidgetDisplayData.placeholder

        XCTAssertEqual(placeholder.activeGoalTitle, "Meditate for 10 minutes",
                       "placeholder.activeGoalTitle must be 'Meditate for 10 minutes'")
        XCTAssertEqual(placeholder.activeGoalProgress, 0.43,
                       "placeholder.activeGoalProgress must be 0.43")
    }

    // Test 7: empty carries nil for both new fields
    func test_empty_hasNilActiveGoalFields() {
        let empty = WidgetDisplayData.empty

        XCTAssertNil(empty.activeGoalTitle,
                     "empty.activeGoalTitle must be nil")
        XCTAssertNil(empty.activeGoalProgress,
                     "empty.activeGoalProgress must be nil")
    }
}
