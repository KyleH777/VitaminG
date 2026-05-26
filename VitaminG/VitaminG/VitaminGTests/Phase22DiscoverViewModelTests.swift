import XCTest
import SwiftData
@testable import VitaminG

// Phase 22 Plan 03 — DiscoverViewModel tests.
// All tests are now LIVE — DiscoverViewModel ships in Plan 03.

@MainActor
final class Phase22DiscoverViewModelTests: XCTestCase {

    var sut: DiscoverViewModel!

    override func setUp() async throws {
        sut = DiscoverViewModel()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // DISC-01: onSearchTextChanged("") clears results immediately (no debounce on empty text).
    func test_onSearchTextChanged_emptyText_clearsResults_immediately() async throws {
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
    }

    // DISC-01: onSearchTextChanged with non-empty text debounces by 500ms.
    func test_onSearchTextChanged_nonEmpty_debouncesBy500ms() async throws {
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
    }

    // DISC-01/DISC-02: selectedSegment defaults to .goals.
    func test_selectedSegment_defaultsToGoals() async throws {
        let sut = DiscoverViewModel()
        XCTAssertEqual(sut.selectedSegment, SearchSegment.goals,
            "selectedSegment must default to .goals (Goals segment shown first)")
    }

    // DISC-04 / Pitfall 5: isJoined returns false initially for any goalID.
    func test_isJoined_returnsFalseInitially() async throws {
        let sut = DiscoverViewModel()
        XCTAssertFalse(sut.isJoined(goalID: "uuid-1"),
            "isJoined must return false before any joinGoal call")
    }

    // DISC-04: joinGoal creates a local SwiftData Goal with isPublic = false and marks joined.
    func test_joinGoal_insertsLocalGoalAndMarksJoined() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SchemaV10.Goal.self, configurations: config)
        let context = ModelContext(container)

        let sut = DiscoverViewModel()
        // Override participant count increment to avoid real CloudKit call
        sut.incrementParticipantCountOverride = { _ in }

        let result = DiscoverGoalResult(
            id: "uuid-1", title: "Run 5K", category: "Health",
            creatorUsername: "alice", participantCount: 10, progressPercent: 0
        )
        sut.joinGoal(result, tier: .immediate, context: context)

        // Verify joined state
        XCTAssertTrue(sut.isJoined(goalID: "uuid-1"), "joinGoal must mark goalID as joined")

        // Verify local Goal was created with isPublic = false (D-15)
        let descriptor = FetchDescriptor<SchemaV10.Goal>()
        let goals = try context.fetch(descriptor)
        XCTAssertEqual(goals.count, 1, "joinGoal must insert exactly one Goal into context")
        XCTAssertEqual(goals.first?.title, "Run 5K")
        XCTAssertFalse(goals.first?.isPublic ?? true, "Joined goal must have isPublic = false (D-15)")
    }

    // DISC-04 / Pitfall 5: joinGoal is idempotent — repeat tap inserts only one Goal.
    func test_joinGoal_isIdempotentOnRepeatTap() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SchemaV10.Goal.self, configurations: config)
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
        let descriptor = FetchDescriptor<SchemaV10.Goal>()
        let goals = try context.fetch(descriptor)
        XCTAssertEqual(goals.count, 1, "joinGoal must be idempotent — repeat tap must not create duplicate Goals (Pitfall 5)")
    }

    // PROF-02 / MVVM: onFollowPerson calls writeFollowOverride exactly once with correct usernames.
    func test_onFollowPerson_callsWriteFollowOverride() async throws {
        let sut = DiscoverViewModel()
        var callCount = 0
        var capturedFollower: String = ""
        var capturedFollowee: String = ""

        sut.writeFollowOverride = { follower, followee in
            callCount += 1
            capturedFollower = follower
            capturedFollowee = followee
        }

        sut.onFollowPerson(followerUsername: "alice", followeeUsername: "bob")

        // Allow the fire-and-forget Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(callCount, 1, "writeFollowOverride must be called exactly once")
        XCTAssertEqual(capturedFollower, "alice", "Follower username must be passed correctly")
        XCTAssertEqual(capturedFollowee, "bob", "Followee username must be passed correctly")
    }
}
