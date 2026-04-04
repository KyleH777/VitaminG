import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class GoalSortTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    // MARK: - Helper

    private func makeGoal(tier: GoalTier, completed: Bool = false, date: Date = Date()) -> Goal {
        let g = Goal(title: "Goal \(tier.rawValue)", tier: tier)
        g.isCompleted = completed
        g.creationDate = date
        context.insert(g)
        return g
    }

    // MARK: - byTier Tests

    func test_sort_byTier_ordersImmediateFirst() throws {
        let g1 = makeGoal(tier: .lifeGoal)
        let g2 = makeGoal(tier: .immediate)
        let g3 = makeGoal(tier: .shortTerm)
        let result = GoalSorter.sort([g1, g2, g3], by: .byTier)
        XCTAssertEqual(result[0].tier, .immediate)
        XCTAssertEqual(result[1].tier, .shortTerm)
        XCTAssertEqual(result[2].tier, .lifeGoal)
    }

    func test_sort_byTier_activeBeforeCompletedWithinTier() throws {
        let completed = makeGoal(tier: .immediate, completed: true)
        let active    = makeGoal(tier: .immediate, completed: false)
        let result = GoalSorter.sort([completed, active], by: .byTier)
        XCTAssertFalse(result[0].completed)
        XCTAssertTrue(result[1].completed)
    }

    // MARK: - byCreationDate Tests

    func test_sort_byCreationDate_ascendingOrder() throws {
        let base = Date()
        let g1 = makeGoal(tier: .immediate, date: base.addingTimeInterval(-200))
        let g2 = makeGoal(tier: .immediate, date: base.addingTimeInterval(-100))
        let g3 = makeGoal(tier: .immediate, date: base)
        let result = GoalSorter.sort([g3, g1, g2], by: .byCreationDate)
        XCTAssertEqual(result[0].creationDate, g1.creationDate)
        XCTAssertEqual(result[2].creationDate, g3.creationDate)
    }

    // MARK: - byCompletionStatus Tests

    func test_sort_byCompletionStatus_activeSectionFirst() throws {
        let c1 = makeGoal(tier: .immediate, completed: true)
        let c2 = makeGoal(tier: .shortTerm, completed: true)
        let a1 = makeGoal(tier: .longTerm,  completed: false)
        let a2 = makeGoal(tier: .lifeGoal,  completed: false)
        let result = GoalSorter.sort([c1, c2, a1, a2], by: .byCompletionStatus)
        // First two should be active
        XCTAssertFalse(result[0].completed)
        XCTAssertFalse(result[1].completed)
        XCTAssertTrue(result[2].completed)
        XCTAssertTrue(result[3].completed)
    }

    func test_sort_byCompletionStatus_activeGoalsSortedByTier() throws {
        let a1 = makeGoal(tier: .lifeGoal, completed: false)
        let a2 = makeGoal(tier: .immediate, completed: false)
        let result = GoalSorter.sort([a1, a2], by: .byCompletionStatus)
        XCTAssertEqual(result[0].tier, .immediate)
        XCTAssertEqual(result[1].tier, .lifeGoal)
    }
}
