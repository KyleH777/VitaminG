import XCTest
@testable import VitaminG

// GREEN — Plan 03 implemented CommunityHubViewModel.
// Tests verify the 5-section coordinator pattern (COMM-06 / 21-03-01).

@MainActor
final class Phase21CommunityHubViewModelTests: XCTestCase {

    // COMM-06 / 21-xx-05
    // loadAll() must fan out to all 5 CloudKit fetch overrides:
    //   fetchGlimpsesOverride, fetchActiveUsersOverride,
    //   fetchGlowingUserOverride, fetchPostsOverride, fetchAppreciationsOverride.
    // Expected assertion: all 5 flag vars become true after one loadAll() call.
    func test_loadAll_callsAllFiveFetchOverrides() async throws {
        var glimpsesCalled = false
        var activeCalled = false
        var glowingCalled = false
        var postsCalled = false
        var appreciationsCalled = false

        let vm = CommunityHubViewModel()
        vm.fetchGlimpsesOverride = { _ in glimpsesCalled = true; return [] }
        vm.fetchActiveUsersOverride = { activeCalled = true; return [] }
        vm.fetchGlowingUserOverride = { _ in glowingCalled = true; return nil }
        vm.fetchPostsOverride = { _ in postsCalled = true; return [] }
        vm.fetchAppreciationsOverride = { _ in appreciationsCalled = true; return [] }

        await vm.loadAll(username: "testuser")

        XCTAssertTrue(glimpsesCalled, "fetchGlimpsesOverride must be called by loadAll()")
        XCTAssertTrue(activeCalled, "fetchActiveUsersOverride must be called by loadAll()")
        XCTAssertTrue(glowingCalled, "fetchGlowingUserOverride must be called by loadAll()")
        XCTAssertTrue(postsCalled, "fetchPostsOverride must be called by loadAll()")
        XCTAssertTrue(appreciationsCalled, "fetchAppreciationsOverride must be called by loadAll()")
    }

    // COMM-04 / 21-xx-02
    // Active Today filter: users whose lastActiveDate is more than 2 hours ago
    // must be excluded from the activeUsers array.
    // Expected assertion: stale items (> 2 hours old) are absent; fresh items remain.
    func test_activeToday_excludesUsersOlderThan2Hours() async throws {
        let freshDate = Date()
        let staleDate = Date().addingTimeInterval(-3 * 60 * 60) // 3 hours ago

        let fresh = UserPresenceItem(id: "1", username: "alice",
            authorColorHex: "#FF0000", lastActiveDate: freshDate)
        let stale = UserPresenceItem(id: "2", username: "bob",
            authorColorHex: "#00FF00", lastActiveDate: staleDate)

        let vm = CommunityHubViewModel()
        // Set all 5 overrides to prevent real CloudKit calls in test environment.
        vm.fetchGlimpsesOverride = { _ in [] }
        vm.fetchActiveUsersOverride = { return [fresh, stale] }
        vm.fetchGlowingUserOverride = { _ in [] }
        vm.fetchPostsOverride = { _ in [] }
        vm.fetchAppreciationsOverride = { _ in [] }

        await vm.loadAll(username: "testuser")

        XCTAssertTrue(vm.activeUsers.contains(where: { $0.id == "1" }),
            "Fresh user within 2 hours must be included")
        XCTAssertFalse(vm.activeUsers.contains(where: { $0.id == "2" }),
            "Stale user older than 2 hours must be excluded")
    }

    // COMM-06 / 21-xx-04
    // The fire reaction case must exist on ReactionType with fieldKey == "fireCount".
    // Expected assertion: ReactionType.fire.fieldKey == "fireCount"
    func test_fireReactionFieldKey_isFireCount() throws {
        XCTAssertEqual(ReactionType.fire.fieldKey, "fireCount",
            "fire reaction fieldKey must be \"fireCount\" to match CKRecord field")
    }
}
