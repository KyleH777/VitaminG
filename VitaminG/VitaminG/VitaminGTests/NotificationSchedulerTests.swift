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
        XCTAssertEqual(content.title, "Good morning")
        XCTAssertTrue(content.body.contains("\n"), "Body should contain newline between message and top goal")
        XCTAssertTrue(content.body.contains("Run 5k"), "Body should contain the top (first) goal title")
        XCTAssertFalse(content.body.contains("Read daily"), "Body should only show the top goal, not others")
    }

    func test_makeContent_limitsToThreeGoals() throws {
        let context = ModelContext(container)
        let goals = (1...5).map { Goal(title: "Goal \($0)", tier: .immediate) }
        goals.forEach { context.insert($0) }

        let content = scheduler.makeContent(activeGoals: goals)
        // New format: one inspirational message + top goal only — exactly one newline, no separators
        let newlineCount = content.body.components(separatedBy: "\n").count - 1
        XCTAssertEqual(newlineCount, 1, "Body should have exactly one newline (message + top goal only)")
        XCTAssertFalse(content.body.contains("\u{00B7}"), "Body should not use middle-dot separators")
    }

    func test_makeContent_noActiveGoals_fallbackMessage() {
        let content = scheduler.makeContent(activeGoals: [])
        XCTAssertFalse(content.body.isEmpty, "Empty goal list should produce an inspirational message")
        XCTAssertFalse(content.body.contains("\n"), "No-goal body should be the message alone — no newline")
        XCTAssertTrue(NotificationScheduler.inspirationalMessages.contains(content.body),
                      "Body should be one of the 7 inspirational messages")
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
        XCTAssertTrue(content.body.contains("Valid"), "Nil title should be skipped; valid title should appear")
        XCTAssertFalse(content.body.contains("WillBeNilledOut"), "Nil title should not appear")
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
        XCTAssertFalse(content.body.isEmpty, "All-completed goals should still produce an inspirational message")
        XCTAssertFalse(content.body.contains("\n"), "All-completed body should be message alone — no goal title newline")
        XCTAssertTrue(NotificationScheduler.inspirationalMessages.contains(content.body),
                      "Body should be one of the 7 inspirational messages")
    }

    func test_makeContent_sound_isDefault() {
        let content = scheduler.makeContent(activeGoals: [])
        XCTAssertEqual(content.sound, .default, "Notification sound should be default")
    }

    // MARK: - perGoalIdentifier

    func test_perGoalIdentifier_containsUUID() {
        let id = UUID()
        let identifier = NotificationScheduler.perGoalIdentifier(for: id)
        XCTAssertTrue(identifier.contains(id.uuidString))
    }

    func test_perGoalIdentifier_hasBundlePrefix() {
        let identifier = NotificationScheduler.perGoalIdentifier(for: UUID())
        XCTAssertTrue(identifier.hasPrefix("com.kyleharrington.VitaminG.goal."))
    }

    // MARK: - cancelPerGoalNotification (smoke — no crash on unknown ID)

    func test_cancelPerGoalNotification_unknownID_doesNotCrash() {
        scheduler.cancelPerGoalNotification(for: UUID())
    }
}
