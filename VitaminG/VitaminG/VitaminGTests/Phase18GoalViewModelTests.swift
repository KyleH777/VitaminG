// Phase 18 Wave 0 — RED tests. Will go GREEN as Plan 02 lands implementation.
// Tests GOAL2-04: addCheckIn creates CompletionEvent without flipping isCompleted; same-day dedup.
// NOTE: addCheckIn(for:context:) is intentionally forward-referenced — Plan 02 adds it.
// This file will FAIL TO COMPILE or FAIL AT RUNTIME until Plan 02 lands.

import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class Phase18GoalViewModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var viewModel: GoalViewModel!

    override func setUpWithError() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = container.mainContext
        viewModel = GoalViewModel()
    }

    override func tearDown() async throws {
        await Task.yield()
        viewModel = nil
        context = nil
        container = nil
    }

    // MARK: - Helpers

    private func makeTestGoal(title: String = "Test Goal") throws -> Goal {
        viewModel.draftTitle = title
        viewModel.draftDescription = ""
        viewModel.draftInspiration = ""
        try viewModel.addGoal(context: context)
        let goals = try context.fetch(FetchDescriptor<Goal>())
        return try XCTUnwrap(goals.first, "Expected goal to be created")
    }

    // MARK: - GOAL2-04a: addCheckIn creates CompletionEvent

    /// GOAL2-04: Calling addCheckIn(for:context:) must create exactly one CompletionEvent
    /// for the goal, with a completedAt date within 1 second of now.
    /// RED: addCheckIn is not yet defined — Plan 02 adds it.
    func test_addCheckIn_createsCompletionEventForGoal() throws {
        let goal = try makeTestGoal(title: "Check-In Goal")
        let before = Date()

        // RED: addCheckIn(for:context:) is not yet defined — Plan 02 adds this method
        viewModel.addCheckIn(for: goal, context: context)

        let events = goal.completionEvents ?? []
        XCTAssertEqual(events.count, 1, "GOAL2-04: addCheckIn must create exactly one CompletionEvent")

        let event = try XCTUnwrap(events.first)
        let completedAt = try XCTUnwrap(event.completedAt, "CompletionEvent must have a completedAt date")
        XCTAssertLessThanOrEqual(
            abs(completedAt.timeIntervalSince(before)),
            1.0,
            "GOAL2-04: completedAt must be within 1 second of the call time"
        )
    }

    // MARK: - GOAL2-04b: addCheckIn must NOT set isCompleted

    /// GOAL2-04: Pitfall 2 — check-in (daily tracking) must NOT permanently mark the goal
    /// as complete. isCompleted is for "I've achieved this goal", not "I did this today".
    /// RED: addCheckIn is not yet defined — Plan 02 adds it.
    func test_addCheckIn_doesNotSetIsCompletedFlag() throws {
        let goal = try makeTestGoal(title: "Non-Completing Goal")

        // RED: addCheckIn(for:context:) is not yet defined — Plan 02 adds this method
        viewModel.addCheckIn(for: goal, context: context)

        XCTAssertFalse(
            goal.isCompleted,
            "GOAL2-04 Pitfall 2: addCheckIn must NOT set isCompleted — use isCompleted only for permanent goal completion"
        )
    }

    // MARK: - GOAL2-04c: Same-day dedup — second call in same day is no-op

    /// GOAL2-04: Pitfall 3 — calling addCheckIn twice on the same calendar day must result in
    /// only 1 CompletionEvent (the second call is idempotent within the same day).
    /// RED: addCheckIn is not yet defined — Plan 02 adds it.
    func test_addCheckIn_isIdempotentWithinSameCalendarDay() throws {
        let goal = try makeTestGoal(title: "Idempotent Goal")

        // RED: addCheckIn(for:context:) is not yet defined — Plan 02 adds this method
        viewModel.addCheckIn(for: goal, context: context)
        viewModel.addCheckIn(for: goal, context: context) // second call — must be no-op

        let events = goal.completionEvents ?? []
        XCTAssertEqual(
            events.count,
            1,
            "GOAL2-04 Pitfall 3: Calling addCheckIn twice in the same day must produce only 1 CompletionEvent"
        )
    }

    // MARK: - GOAL2-04d: Second check-in on a different day IS allowed

    /// GOAL2-04: The same-day dedup guard must be calendar-day scoped, not session scoped.
    /// If there's an existing CompletionEvent from yesterday, calling addCheckIn today must
    /// create a new event (total = 2).
    /// RED: addCheckIn is not yet defined — Plan 02 adds it.
    func test_addCheckIn_allowsSecondCheckInOnNextDay() throws {
        let goal = try makeTestGoal(title: "Multi-Day Goal")

        // Insert a CompletionEvent dated yesterday directly
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
        let priorEvent = CompletionEvent(goal: goal)
        priorEvent.completedAt = yesterday
        priorEvent.tierRawValue = GoalTier.immediate.rawValue
        context.insert(priorEvent)

        // Now call addCheckIn for today
        // RED: addCheckIn(for:context:) is not yet defined — Plan 02 adds this method
        viewModel.addCheckIn(for: goal, context: context)

        let events = goal.completionEvents ?? []
        XCTAssertEqual(
            events.count,
            2,
            "GOAL2-04: addCheckIn on a different calendar day must create a new event (total 2 events)"
        )
    }
}
