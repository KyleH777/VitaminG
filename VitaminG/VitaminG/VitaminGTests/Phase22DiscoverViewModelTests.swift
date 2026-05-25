import XCTest
import SwiftData
@testable import VitaminG

// RED/SKIP — Wave 0 stub. Tests reference DiscoverViewModel which ships in Plan 04.
// All tests XCTSkip until Plan 04 ships the DiscoverViewModel implementation.
//
// COMPILE-GATE blocks (#if false) contain the real assertions once DiscoverViewModel exists.

@MainActor
final class Phase22DiscoverViewModelTests: XCTestCase {

    // MARK: - DiscoverViewModel Tests (XCTSkip until Plan 04)

    // DISC-01: onSearchTextChanged("") clears results immediately (no debounce on empty text).
    // Expected: goalResults and peopleResults are empty immediately after clearing.
    // Wave 0: SKIP — DiscoverViewModel not yet implemented.
    func test_onSearchTextChanged_emptyText_clearsResults_immediately() async throws {
        throw XCTSkip("Wave 0 stub — DiscoverViewModel implemented in Plan 04")

        // COMPILE-GATE: Enable in Plan 04 when DiscoverViewModel ships.
        #if false
        let sut = DiscoverViewModel()
        // Seed some results to verify clearing
        sut.goalResults = [
            DiscoverGoalResult(id: "1", title: "Run 5K", category: "Health",
                               creatorUsername: "alice", participantCount: 5, progressPercent: 50)
        ]
        sut.onSearchTextChanged("")
        // Empty text must clear results immediately without debounce
        XCTAssertTrue(sut.goalResults.isEmpty, "Empty text must clear goalResults immediately")
        XCTAssertTrue(sut.peopleResults.isEmpty, "Empty text must clear peopleResults immediately")
        #endif
    }

    // DISC-01: onSearchTextChanged with non-empty text debounces by 500ms.
    // Expected: results are not populated until after 500ms delay.
    // Wave 0: SKIP — DiscoverViewModel not yet implemented.
    func test_onSearchTextChanged_nonEmpty_debouncesBy500ms() async throws {
        throw XCTSkip("Wave 0 stub — DiscoverViewModel implemented in Plan 04")

        // COMPILE-GATE: Enable in Plan 04.
        #if false
        let sut = DiscoverViewModel()
        var searchCalled = false
        sut.searchGoalsOverride = { _ in
            searchCalled = true
            return []
        }
        sut.searchPeopleOverride = { _ in [] }

        sut.onSearchTextChanged("marathon")
        // Immediately after call: search must NOT have fired yet (debounce pending)
        XCTAssertFalse(searchCalled, "Search must not fire before 500ms debounce")

        // After 600ms: search must have fired
        try await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertTrue(searchCalled, "Search must fire after 500ms debounce elapses")
        #endif
    }

    // DISC-01/DISC-02: selectedSegment defaults to .goals.
    // Expected: freshly created DiscoverViewModel has selectedSegment == .goals.
    // Wave 0: SKIP — DiscoverViewModel not yet implemented.
    func test_selectedSegment_defaultsToGoals() async throws {
        throw XCTSkip("Wave 0 stub — DiscoverViewModel implemented in Plan 04")

        // COMPILE-GATE: Enable in Plan 04.
        #if false
        let sut = DiscoverViewModel()
        XCTAssertEqual(sut.selectedSegment, SearchSegment.goals,
            "selectedSegment must default to .goals (Goals segment shown first)")
        #endif
    }

    // DISC-04 / Pitfall 5: isJoined returns false initially for any goalID.
    // Expected: isJoined("uuid-1") == false before any joinGoal call.
    // Wave 0: SKIP — DiscoverViewModel not yet implemented.
    func test_isJoined_returnsFalseInitially() async throws {
        throw XCTSkip("Wave 0 stub — DiscoverViewModel implemented in Plan 04")

        // COMPILE-GATE: Enable in Plan 04.
        #if false
        let sut = DiscoverViewModel()
        XCTAssertFalse(sut.isJoined(goalID: "uuid-1"),
            "isJoined must return false before any joinGoal call")
        #endif
    }

    // DISC-04: joinGoal creates a local SwiftData Goal with isPublic = false and marks joined.
    // Expected: after joinGoal, a Goal exists in context and isJoined returns true.
    // Wave 0: SKIP — DiscoverViewModel.joinGoal not yet implemented.
    func test_joinGoal_insertsLocalGoalAndMarksJoined() async throws {
        throw XCTSkip("Wave 0 stub — DiscoverViewModel.joinGoal implemented in Plan 04")

        // COMPILE-GATE: Enable in Plan 04.
        #if false
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SchemaV9.Goal.self, configurations: config)
        let context = ModelContext(container)

        let sut = DiscoverViewModel()
        // Override participant count increment to avoid real CloudKit call
        sut.incrementParticipantCountOverride = { _ in }

        let result = DiscoverGoalResult(
            id: "uuid-1", title: "Run 5K", category: "Health",
            creatorUsername: "alice", participantCount: 10, progressPercent: 0
        )
        sut.joinGoal(result, tier: .daily, context: context)

        // Verify joined state
        XCTAssertTrue(sut.isJoined(goalID: "uuid-1"), "joinGoal must mark goalID as joined")

        // Verify local Goal was created with isPublic = false (D-15)
        let descriptor = FetchDescriptor<SchemaV9.Goal>()
        let goals = try context.fetch(descriptor)
        XCTAssertEqual(goals.count, 1, "joinGoal must insert exactly one Goal into context")
        XCTAssertEqual(goals.first?.title, "Run 5K")
        XCTAssertFalse(goals.first?.isPublic ?? true, "Joined goal must have isPublic = false (D-15)")
        #endif
    }

    // DISC-04 / Pitfall 5: joinGoal is idempotent — repeat tap inserts only one Goal.
    // Expected: calling joinGoal twice for the same goalID inserts only one local Goal.
    // Wave 0: SKIP — DiscoverViewModel.joinGoal not yet implemented.
    func test_joinGoal_isIdempotentOnRepeatTap() async throws {
        throw XCTSkip("Wave 0 stub — DiscoverViewModel.joinGoal implemented in Plan 04")

        // COMPILE-GATE: Enable in Plan 04 (Pitfall 5 dedup via Set<String>).
        #if false
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SchemaV9.Goal.self, configurations: config)
        let context = ModelContext(container)

        let sut = DiscoverViewModel()
        sut.incrementParticipantCountOverride = { _ in }

        let result = DiscoverGoalResult(
            id: "uuid-2", title: "Drink water daily", category: "Health",
            creatorUsername: "bob", participantCount: 3, progressPercent: 0
        )

        // Tap Join twice
        sut.joinGoal(result, tier: .immediate, context: context)
        sut.joinGoal(result, tier: .immediate, context: context)

        // Only one Goal should be in context (Set<String> dedup per Pitfall 5)
        let descriptor = FetchDescriptor<SchemaV9.Goal>()
        let goals = try context.fetch(descriptor)
        XCTAssertEqual(goals.count, 1, "joinGoal must be idempotent — repeat tap must not create duplicate Goals (Pitfall 5)")
        #endif
    }
}
