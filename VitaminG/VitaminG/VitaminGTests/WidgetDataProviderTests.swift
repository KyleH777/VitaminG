import XCTest
import SwiftData
@testable import VitaminG

final class WidgetDataProviderTests: XCTestCase {

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

    // WIDGET-01: Home screen widget shows top active goals across tiers
    func test_build_returnsOneTierRowPerTier() throws {
        let goal = Goal(title: "Test", tier: .immediate)
        context.insert(goal)
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let result = WidgetDataProvider.build(goals: goals, events: [])

        XCTAssertEqual(result.tierRows.count, 4, "Must have exactly 4 tier rows (one per GoalTier.ordered)")
        XCTAssertEqual(result.tierRows[0].tier, .immediate)
        XCTAssertEqual(result.tierRows[1].tier, .shortTerm)
        XCTAssertEqual(result.tierRows[2].tier, .longTerm)
        XCTAssertEqual(result.tierRows[3].tier, .lifeGoal)
    }

    func test_build_topGoalPerTier_isFirstActiveByCreationDate() throws {
        // Create two immediate goals — older one should be the "top" goal
        let older = Goal(title: "Older Goal", tier: .immediate)
        older.creationDate = Date(timeIntervalSince1970: 1000)
        let newer = Goal(title: "Newer Goal", tier: .immediate)
        newer.creationDate = Date(timeIntervalSince1970: 2000)
        context.insert(older)
        context.insert(newer)
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let result = WidgetDataProvider.build(goals: goals, events: [])

        XCTAssertEqual(result.tierRows[0].topGoalTitle, "Older Goal",
                       "Top goal should be the earliest-created active goal in the tier")
    }

    func test_build_emptyTier_returnsNilTitle() throws {
        // Only add a goal in .immediate — other tiers should be nil
        let goal = Goal(title: "Only Immediate", tier: .immediate)
        context.insert(goal)
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let result = WidgetDataProvider.build(goals: goals, events: [])

        XCTAssertNotNil(result.tierRows[0].topGoalTitle)
        XCTAssertNil(result.tierRows[1].topGoalTitle, "Short-term tier should be nil (no goals)")
        XCTAssertNil(result.tierRows[2].topGoalTitle, "Long-term tier should be nil (no goals)")
        XCTAssertNil(result.tierRows[3].topGoalTitle, "Life goal tier should be nil (no goals)")
    }

    // WIDGET-02: Lock screen widget uses globalStreak from WidgetDisplayData
    func test_build_globalStreak_computedFromEvents() throws {
        let goal = Goal(title: "Streak Test", tier: .immediate)
        context.insert(goal)

        // Create a completion event for today
        let event = CompletionEvent(goal: goal)
        event.completedAt = Date()
        context.insert(event)
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let events = try context.fetch(FetchDescriptor<CompletionEvent>())
        let result = WidgetDataProvider.build(goals: goals, events: events)

        XCTAssertEqual(result.globalStreak, StreakEngine.currentStreak(from: events),
                       "globalStreak must match StreakEngine.currentStreak(from:)")
        XCTAssertGreaterThan(result.globalStreak, 0)
    }

    func test_build_noGoals_allTierRowsNil() throws {
        let result = WidgetDataProvider.build(goals: [], events: [])

        XCTAssertEqual(result.tierRows.count, 4)
        for row in result.tierRows {
            XCTAssertNil(row.topGoalTitle, "Tier \(row.tier.displayName) should have nil title with no goals")
        }
        XCTAssertEqual(result.globalStreak, 0)
    }

    func test_build_completedGoals_excluded() throws {
        let goal = Goal(title: "Done Goal", tier: .immediate)
        goal.isCompleted = true
        context.insert(goal)
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let result = WidgetDataProvider.build(goals: goals, events: [])

        XCTAssertNil(result.tierRows[0].topGoalTitle,
                     "Completed goals must not appear as top goal in tier row")
    }

    func test_placeholder_hasFourTierRows() {
        let placeholder = WidgetDisplayData.placeholder
        XCTAssertEqual(placeholder.tierRows.count, 4)
        for row in placeholder.tierRows {
            XCTAssertNotNil(row.topGoalTitle, "Placeholder tier rows should all have sample titles")
        }
        XCTAssertGreaterThan(placeholder.globalStreak, 0, "Placeholder should show a non-zero streak")
    }

    func test_empty_hasFourNilTierRows() {
        let empty = WidgetDisplayData.empty
        XCTAssertEqual(empty.tierRows.count, 4)
        for row in empty.tierRows {
            XCTAssertNil(row.topGoalTitle)
        }
        XCTAssertEqual(empty.globalStreak, 0)
    }
}
