// Phase 18 Wave 0 — RED tests. Will go GREEN as Plan 02 lands implementation.
// Tests GOAL2-01: durationDays field round-trips through GoalInput -> Goal.
// NOTE: GoalInput.durationDays and Goal.durationDays are intentionally forward-referenced.
// Plan 02 adds these fields. This file will FAIL TO COMPILE until Plan 02 lands.

import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class Phase18GoalInputTests: XCTestCase {

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

    // MARK: - GOAL2-01a: GoalInput carries durationDays

    /// GOAL2-01: GoalInput must carry a durationDays property that round-trips correctly.
    /// RED: GoalInput.durationDays is not yet defined — Plan 02 adds it.
    func test_goalInput_carriesDurationDays() {
        // RED: GoalInput(durationDays:) initializer parameter is not yet defined — Plan 02 adds it
        let input = GoalInput(
            title: "30 Day Challenge",
            tier: .shortTerm,
            category: .habit,
            frequency: .daily,
            reminderTime: nil,
            isPrivate: true,
            startDate: nil,
            durationDays: 30  // forward reference — Plan 02 adds this parameter
        )

        XCTAssertEqual(input.durationDays, 30,
            "GOAL2-01: GoalInput.durationDays must round-trip to 30")
    }

    // MARK: - GOAL2-01b: durationDays is optional, defaults to nil

    /// GOAL2-01: durationDays must be optional so existing call sites using GoalInput
    /// without durationDays continue to compile. Default is nil.
    /// RED: GoalInput.durationDays is not yet defined — Plan 02 adds it.
    func test_goalInput_durationDaysIsOptional_defaultsToNil() {
        // Without specifying durationDays — must default to nil
        let input = GoalInput(
            title: "Open-Ended Goal",
            tier: .lifeGoal,
            category: .mind,
            frequency: .daily,
            reminderTime: nil,
            isPrivate: false,
            startDate: nil
        )

        // RED: GoalInput.durationDays is not yet defined — Plan 02 adds it
        XCTAssertNil(input.durationDays,
            "GOAL2-01: GoalInput.durationDays must default to nil when not provided")
    }

    // MARK: - GOAL2-01c: durationDays persists from GoalInput through to Goal model

    /// GOAL2-01: When GoalInput with durationDays: 60 is passed to GoalViewModel.addGoal(input:context:),
    /// the resulting Goal model must have durationDays == 60.
    /// RED: Both GoalInput.durationDays and Goal.durationDays are not yet defined — Plan 02 adds them.
    func test_goalInput_durationDays_persistsToGoalModel() throws {
        // RED: GoalInput(durationDays:) and Goal.durationDays are not yet defined — Plan 02 adds them
        let input = GoalInput(
            title: "60 Day Sprint",
            tier: .shortTerm,
            category: .wellness,
            frequency: .daily,
            reminderTime: nil,
            isPrivate: false,
            startDate: nil,
            durationDays: 60  // forward reference — Plan 02 adds this parameter
        )

        try viewModel.addGoal(input: input, context: context)

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let goal = try XCTUnwrap(goals.first, "Expected goal to be persisted")

        // RED: Goal.durationDays is not yet defined — Plan 02 adds it
        XCTAssertEqual(goal.durationDays, 60,
            "GOAL2-01: durationDays must persist from GoalInput through to the Goal model (60 days)")
    }
}
