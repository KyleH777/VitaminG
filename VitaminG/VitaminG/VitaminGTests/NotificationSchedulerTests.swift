import XCTest
import SwiftData
@testable import VitaminG

// MARK: - NotificationSchedulerTests

/// Tests for NotificationScheduler.makeContent — the only purely testable part
/// without mocking UNUserNotificationCenter.
final class NotificationSchedulerTests: XCTestCase {

    private var container: ModelContainer!
    private let scheduler = NotificationScheduler.shared

    override func setUp() async throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
    }

    override func tearDown() async throws {
        container = nil
    }

    // MARK: - makeContent tests

    func test_makeContent_withActiveGoals_containsTitles() throws {
        let context = ModelContext(container)
        let g1 = Goal(title: "Run 5k", tier: .immediate)
        let g2 = Goal(title: "Read daily", tier: .shortTerm)
        let g3 = Goal(title: "Learn Swift", tier: .longTerm)
        context.insert(g1)
        context.insert(g2)
        context.insert(g3)

        let content = scheduler.makeContent(activeGoals: [g1, g2, g3])
        XCTAssertEqual(content.title, "Your Vitamin G for today")
        XCTAssertTrue(content.body.contains("Run 5k"), "Body should contain first goal title")
        XCTAssertTrue(content.body.contains("Read daily"), "Body should contain second goal title")
        XCTAssertTrue(content.body.contains("Learn Swift"), "Body should contain third goal title")
    }

    func test_makeContent_limitsToThreeGoals() throws {
        let context = ModelContext(container)
        let goals = (1...5).map { Goal(title: "Goal \($0)", tier: .immediate) }
        goals.forEach { context.insert($0) }

        let content = scheduler.makeContent(activeGoals: goals)
        // Body should contain exactly 2 separators (middle dot · between 3 titles)
        let separatorCount = content.body.components(separatedBy: "\u{00B7}").count - 1
        XCTAssertEqual(separatorCount, 2, "Body should have exactly 2 separators for 3 titles")
    }

    func test_makeContent_noActiveGoals_fallbackMessage() {
        let content = scheduler.makeContent(activeGoals: [])
        XCTAssertEqual(content.body, "Check in on your goals today.",
                       "Empty goal list should produce fallback message")
    }

    func test_makeContent_completedGoalsExcluded() throws {
        let context = ModelContext(container)
        let g1 = Goal(title: "Active", tier: .immediate)
        let g2 = Goal(title: "Done", tier: .immediate)
        g2.isCompleted = true
        context.insert(g1)
        context.insert(g2)

        let content = scheduler.makeContent(activeGoals: [g1, g2])
        XCTAssertTrue(content.body.contains("Active"), "Active goal title should appear")
        XCTAssertFalse(content.body.contains("Done"), "Completed goal title should be excluded")
    }

    func test_makeContent_userInfo_containsDeepLink() {
        let content = scheduler.makeContent(activeGoals: [])
        XCTAssertEqual(content.userInfo["deepLink"] as? String, "goalList",
                       "userInfo should carry deepLink = goalList for navigation on tap")
    }

    func test_makeContent_nilTitle_skipped() throws {
        let context = ModelContext(container)
        let g1 = Goal(title: "Valid", tier: .immediate)
        let g2 = Goal(title: "WillBeNilledOut", tier: .immediate)
        g2.title = nil
        context.insert(g1)
        context.insert(g2)

        let content = scheduler.makeContent(activeGoals: [g1, g2])
        XCTAssertEqual(content.body, "Valid", "Nil title should be skipped, body should only contain valid title")
    }

    func test_makeContent_emptyTitle_skipped() throws {
        let context = ModelContext(container)
        let g1 = Goal(title: "Real Goal", tier: .immediate)
        let g2 = Goal(title: "", tier: .immediate)
        context.insert(g1)
        context.insert(g2)

        let content = scheduler.makeContent(activeGoals: [g1, g2])
        XCTAssertTrue(content.body.contains("Real Goal"), "Real goal title should appear")
        XCTAssertFalse(content.body.contains("\u{00B7}"), "No separator should appear — empty title was skipped")
    }

    func test_makeContent_allCompletedGoals_fallbackMessage() throws {
        let context = ModelContext(container)
        let g1 = Goal(title: "Done 1", tier: .immediate)
        let g2 = Goal(title: "Done 2", tier: .immediate)
        g1.isCompleted = true
        g2.isCompleted = true
        context.insert(g1)
        context.insert(g2)

        let content = scheduler.makeContent(activeGoals: [g1, g2])
        XCTAssertEqual(content.body, "Check in on your goals today.",
                       "All-completed goals should produce fallback message")
    }

    func test_makeContent_sound_isDefault() {
        let content = scheduler.makeContent(activeGoals: [])
        XCTAssertEqual(content.sound, .default, "Notification sound should be default")
    }
}
