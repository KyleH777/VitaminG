import XCTest
import SwiftData
@testable import VitaminG

// Phase 23 Plan 02 — GoalViewModel per-goal milestone detection and auto-completion tests.
// Tests verify that addCheckIn:
//  1. Sets pendingGoalMilestone when a per-goal streak just crosses a threshold
//  2. Does NOT fire again after the gate is marked shown
//  3. Sets pendingGoalCompletion when completionEvents.count >= durationDays

@MainActor
final class Phase23GoalViewModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var sut: GoalViewModel!
    /// Isolated UserDefaults suite for StreakMilestoneGate calls in tests.
    /// Using a fresh UUID per suite prevents cross-test and cross-run contamination.
    /// Pass this to every hasShown/markShown call so tests remain isolated from the
    /// production app-group suite (changed in CR-01) and from each other.
    var testDefaults: UserDefaults!

    override func setUpWithError() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = container.mainContext
        sut = GoalViewModel()
        testDefaults = UserDefaults(suiteName: UUID().uuidString)!
    }

    override func tearDown() async throws {
        await Task.yield()
        sut = nil
        context = nil
        container = nil
        testDefaults = nil
    }

    // MARK: - Helpers

    /// Creates a Goal and inserts completionEvents on consecutive days ending yesterday.
    /// Returns the goal with the events attached.
    private func makeGoal(withStreak streakCount: Int) throws -> Goal {
        let goal = Goal(title: "Test Goal", tier: .immediate)
        goal.durationDays = 365  // large so auto-completion doesn't trigger accidentally
        context.insert(goal)

        let calendar = Calendar.current
        for i in 1...streakCount {
            // streakCount days ago → ... → yesterday
            let dayOffset = -(streakCount - i + 1)
            let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: Date()))!
            let event = CompletionEvent()
            event.completedAt = day
            event.tierRawValue = GoalTier.immediate.rawValue
            context.insert(event)
            event.goal = goal
        }

        return goal
    }

    // MARK: - Test 1: pendingGoalMilestone set when streak hits 7

    /// A goal with 6 prior check-ins on consecutive days (streak = 6) should trigger
    /// pendingGoalMilestone.threshold == 7 after addCheckIn adds the 7th consecutive day.
    func test_addCheckIn_setsPendingGoalMilestoneAt7Days() throws {
        // Arrange: goal with 6 events on days -6 through -1 (yesterday = day -1)
        let goal = try makeGoal(withStreak: 6)

        // Pre-condition: gate not yet shown for threshold 7 in isolated test suite.
        // Always pass testDefaults so the test is isolated from the production app-group
        // suite and from other tests (WR-07 fix).
        XCTAssertFalse(StreakMilestoneGate.hasShown(goalID: goal.id, threshold: 7, defaults: testDefaults))

        // Act: check in today — streak goes to 7
        sut.addCheckIn(for: goal, context: context)

        // Assert
        XCTAssertNotNil(sut.pendingGoalMilestone, "Expected pendingGoalMilestone to be set after 7-day streak")
        XCTAssertEqual(
            sut.pendingGoalMilestone?.threshold,
            7,
            "Expected pendingGoalMilestone.threshold == 7 when streak just crossed 7"
        )
        XCTAssertEqual(
            sut.pendingGoalMilestone?.goalID,
            goal.id,
            "Expected pendingGoalMilestone.goalID to match the checked-in goal"
        )
    }

    // MARK: - Test 2: No duplicate milestone after gate marked shown

    /// After StreakMilestoneGate.markShown is called for threshold 7, addCheckIn should NOT
    /// set pendingGoalMilestone (the gate prevents the duplicate notification).
    func test_addCheckIn_noDuplicateMilestoneAfterGateMarked() throws {
        // Arrange: goal with 6 consecutive check-ins
        let goal = try makeGoal(withStreak: 6)

        // Pre-mark threshold 7 as already shown in isolated test suite (WR-07 fix).
        StreakMilestoneGate.markShown(goalID: goal.id, threshold: 7, defaults: testDefaults)

        // Act: check in today — streak would be 7 but gate is already fired
        sut.addCheckIn(for: goal, context: context)

        // Assert: pendingGoalMilestone should remain nil (gate already shown)
        // It may be set to a higher threshold if streak > threshold, but threshold 7 must not fire.
        // Since streak == 7 exactly after check-in, only threshold 7 would match.
        // Because threshold 7 is gated, pendingGoalMilestone must be nil.
        if let milestone = sut.pendingGoalMilestone {
            XCTAssertNotEqual(
                milestone.threshold,
                7,
                "Expected threshold 7 NOT to fire after StreakMilestoneGate.markShown was called for it"
            )
        }
        // The most precise assertion: since no other threshold (14, 30, etc.) is reached,
        // pendingGoalMilestone should be nil entirely.
        XCTAssertNil(
            sut.pendingGoalMilestone,
            "Expected pendingGoalMilestone to be nil because threshold 7 was already marked shown"
        )
    }

    // MARK: - Test 3: pendingGoalCompletion set when durationDays reached

    /// A goal with durationDays = 3 should trigger pendingGoalCompletion on the 3rd check-in.
    func test_addCheckIn_setsPendingGoalCompletionWhenDurationReached() throws {
        // Arrange: goal with durationDays = 3 and 2 prior check-ins
        let goal = Goal(title: "Short Goal", tier: .immediate)
        goal.durationDays = 3
        context.insert(goal)

        // Add 2 prior check-ins on different days (not today)
        let calendar = Calendar.current
        for dayOffset in [-2, -1] {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: Date()))!
            let event = CompletionEvent()
            event.completedAt = day
            event.tierRawValue = GoalTier.immediate.rawValue
            context.insert(event)
            event.goal = goal
        }

        // Pre-condition: goal is not yet completed
        XCTAssertFalse(goal.isCompleted, "Goal should not be completed before the 3rd check-in")

        // Act: 3rd check-in today completes the duration
        sut.addCheckIn(for: goal, context: context)

        // Assert
        XCTAssertNotNil(
            sut.pendingGoalCompletion,
            "Expected pendingGoalCompletion to be set when completionEvents.count >= durationDays"
        )
        XCTAssertEqual(
            sut.pendingGoalCompletion,
            goal.id,
            "Expected pendingGoalCompletion to equal the completed goal's ID"
        )
    }
}
