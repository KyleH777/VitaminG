import XCTest
import SwiftData
@testable import VitaminG

// Phase 23 Plan 02 — StatsViewModel heatmap sentinel tests.
// Tests verify that buildHeatmapData (called via refresh) correctly writes
// sentinel value -1 for frozen dates with no check-in, and does NOT overwrite
// a real check-in on the same day as a frozen date.

@MainActor
final class Phase23StatsViewModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var sut: StatsViewModel!

    override func setUpWithError() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = container.mainContext
        sut = StatsViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        context = nil
        container = nil
    }

    // MARK: - Sentinel for frozen day with no check-in

    /// A frozen date with no CompletionEvent on that day should produce heatmapData[day] == -1.
    func test_buildHeatmapData_writesSentinelForFrozenDayWithNoCheckIn() throws {
        // Arrange: a day in the past with no events, to be frozen
        let calendar = Calendar.current
        let frozenDay = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: -5, to: Date())!
        )

        // Act: refresh with empty events and one frozenDate
        sut.refresh(events: [], goals: [], frozenDates: [frozenDay])

        // Assert: sentinel -1 must be present for the frozen day
        XCTAssertEqual(
            sut.heatmapData[frozenDay],
            -1,
            "Expected heatmapData[\(frozenDay)] to be -1 (frozen sentinel) when no check-in exists for that day"
        )
    }

    // MARK: - Real check-in not overwritten by frozen sentinel

    /// When a CompletionEvent exists on the same day as a frozenDate, the real
    /// check-in count must be preserved (>= 1) and NOT replaced with -1.
    func test_buildHeatmapData_doesNotOverwriteRealCheckIn() throws {
        // Arrange: create a Goal and a CompletionEvent on a specific day
        let goal = Goal(title: "Test Goal", tier: .immediate)
        context.insert(goal)

        let calendar = Calendar.current
        let checkInDay = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: -3, to: Date())!
        )

        let event = CompletionEvent()
        event.completedAt = checkInDay  // event on the same day as the frozen date
        event.tierRawValue = GoalTier.immediate.rawValue
        context.insert(event)
        event.goal = goal

        // Act: refresh with the event AND a frozenDate on the same day
        sut.refresh(events: [event], goals: [goal], frozenDates: [checkInDay])

        // Assert: real check-in count >= 1; sentinel -1 must NOT be present
        let count = sut.heatmapData[checkInDay] ?? 0
        XCTAssertGreaterThanOrEqual(
            count,
            1,
            "Expected heatmapData[\(checkInDay)] to be >= 1 (real check-in count) — sentinel -1 must NOT overwrite a real event"
        )
        XCTAssertNotEqual(
            sut.heatmapData[checkInDay],
            -1,
            "Sentinel -1 must NOT replace a real check-in on the same day as a frozen date"
        )
    }
}
