import XCTest
import SwiftData
@testable import VitaminG

// GREEN — Plan 27-02 makes these tests pass.
// WatchSnapshot delegates active goal / progress / streak to WidgetDataProvider.
final class WatchSnapshotTests: XCTestCase {

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

    // WATCH-02: WatchSnapshot.build() returns the active goal title from the highest-priority tier
    func test_build_returnsActiveGoalTitle_fromHighestPriorityTier() throws {
        // Immediate tier goal created later in time still wins over ShortTerm
        let immediateGoal = Goal(title: "Run 5K", tier: .immediate)
        immediateGoal.creationDate = Date(timeIntervalSince1970: 2000)
        let shortTermGoal = Goal(title: "Read 12 books", tier: .shortTerm)
        shortTermGoal.creationDate = Date(timeIntervalSince1970: 1000)
        context.insert(immediateGoal)
        context.insert(shortTermGoal)
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let snapshot = WatchSnapshot.build(goals: goals, events: [])

        XCTAssertEqual(snapshot.activeGoalTitle, "Run 5K",
                       "Immediate tier must win over ShortTerm regardless of creationDate")
    }

    // WATCH-02: WatchSnapshot.build() returns activeGoalProgress in range 0.0–1.0
    func test_build_returnsActiveGoalProgress_zeroToOne() throws {
        // Goal with durationDays = 10 and 3 completion events → progress = 0.3
        let goal = Goal(title: "Write novel", tier: .immediate, durationDays: 10)
        context.insert(goal)
        for _ in 0..<3 {
            let event = CompletionEvent(goal: goal)
            context.insert(event)
        }
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let events = try context.fetch(FetchDescriptor<CompletionEvent>())
        let snapshot = WatchSnapshot.build(goals: goals, events: events)

        XCTAssertGreaterThanOrEqual(snapshot.activeGoalProgress, 0.0,
                                    "activeGoalProgress must be >= 0.0")
        XCTAssertLessThanOrEqual(snapshot.activeGoalProgress, 1.0,
                                 "activeGoalProgress must be <= 1.0")
        XCTAssertEqual(snapshot.activeGoalProgress, 0.3, accuracy: 0.001,
                       "3 events / 10 days = 0.3 progress")
    }

    // WATCH-02: WatchSnapshot.build() returns the global streak from StreakEngine
    func test_build_returnsGlobalStreak_fromStreakEngine() throws {
        // Insert 3 consecutive daily completion events ending today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for dayOffset in 0..<3 {
            let event = CompletionEvent()
            event.completedAt = calendar.date(byAdding: .day, value: -dayOffset, to: today)
            context.insert(event)
        }
        try context.save()

        let events = try context.fetch(FetchDescriptor<CompletionEvent>())
        let snapshot = WatchSnapshot.build(goals: [], events: events, calendar: calendar)

        // StreakEngine counts consecutive days ending today
        let expected = StreakEngine.currentStreak(from: events, calendar: calendar)
        XCTAssertEqual(snapshot.globalStreak, expected,
                       "globalStreak must equal StreakEngine.currentStreak output")
        XCTAssertGreaterThanOrEqual(snapshot.globalStreak, 1,
                                    "Streak must be at least 1 with a today event")
    }

    // WATCH-02: WatchSnapshot.build() returns hasCheckedInToday == true when a today event exists
    func test_build_returnsHasCheckedInToday_trueWhenTodayEventExists() throws {
        let goal = Goal(title: "Meditate", tier: .immediate)
        context.insert(goal)

        // Add a completion event for the active goal with completedAt = now
        let todayEvent = CompletionEvent(goal: goal)
        todayEvent.completedAt = Date()
        context.insert(todayEvent)
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let events = try context.fetch(FetchDescriptor<CompletionEvent>())
        let snapshot = WatchSnapshot.build(goals: goals, events: events)

        XCTAssertTrue(snapshot.hasCheckedInToday,
                      "hasCheckedInToday must be true when active goal has a today completion event")
    }

    // WATCH-02: WatchSnapshot.build() returns activeGoalId as UUID string
    func test_build_returnsActiveGoalId_uuidString() throws {
        let goal = Goal(title: "Launch app", tier: .immediate)
        context.insert(goal)
        try context.save()

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let snapshot = WatchSnapshot.build(goals: goals, events: [])

        XCTAssertNotNil(snapshot.activeGoalId,
                        "activeGoalId must not be nil when an active goal exists")
        // Must be a valid UUID string
        XCTAssertNotNil(UUID(uuidString: snapshot.activeGoalId ?? ""),
                        "activeGoalId must be a valid UUID string (goal.id.uuidString)")
        XCTAssertEqual(snapshot.activeGoalId, goals.first?.id.uuidString,
                       "activeGoalId must equal the active goal's id.uuidString")
    }

    // WATCH-02: WatchSnapshot round-trips through JSONEncoder/JSONDecoder without data loss
    func test_codable_roundTripsThroughJSONEncoderDecoder() throws {
        let original = WatchSnapshot(
            activeGoalTitle: "Run a marathon",
            activeGoalProgress: 0.65,
            globalStreak: 14,
            hasCheckedInToday: true,
            activeGoalId: UUID().uuidString
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WatchSnapshot.self, from: data)

        XCTAssertEqual(decoded, original,
                       "WatchSnapshot must round-trip through JSONEncoder/JSONDecoder without loss")
        XCTAssertEqual(decoded.activeGoalTitle, original.activeGoalTitle)
        XCTAssertEqual(decoded.activeGoalProgress, original.activeGoalProgress, accuracy: 0.0001)
        XCTAssertEqual(decoded.globalStreak, original.globalStreak)
        XCTAssertEqual(decoded.hasCheckedInToday, original.hasCheckedInToday)
        XCTAssertEqual(decoded.activeGoalId, original.activeGoalId)
    }
}
