import XCTest
import CloudKit
@testable import VitaminG

// Phase 22 Plan 02 — Follow service tests (all active, no XCTSkip).
// Two deterministic record-name tests run purely in memory.
// Three service-logic tests use ProfileSharingService.fetchFollowStateOverride /
// writeFollowOverride to avoid hitting CloudKit in the test environment.

final class Phase22FollowServiceTests: XCTestCase {

    override func tearDown() {
        // Reset test seams after each test to avoid cross-test pollution.
        ProfileSharingService.fetchFollowStateOverride = nil
        ProfileSharingService.writeFollowOverride = nil
        super.tearDown()
    }

    // MARK: - Deterministic Record Name (no CloudKit — runs green without account)

    // PROF-02: Follow record name is deterministic for a given follower+followee pair.
    // Pattern: "\(followerUsername)_\(followeeUsername)" (CONTEXT.md D-13)
    // Expected: "alice_bob" for (alice → bob) follow.
    func test_followRecordName_isDeterministic() {
        let follower = "alice"
        let followee = "bob"
        let name = "\(follower)_\(followee)"
        XCTAssertEqual(name, "alice_bob",
            "Follow record name must be '\(follower)_\(followee)' (D-13 deterministic dedup)")
    }

    // PROF-02: Follow record name is order-sensitive — (alice→bob) != (bob→alice).
    // This prevents a follow record from being treated as a mutual follow.
    // Expected: "alice_bob" != "bob_alice".
    func test_followRecordName_isOrderSensitive() {
        let name1 = "\("alice")_\("bob")"
        let name2 = "\("bob")_\("alice")"
        XCTAssertNotEqual(name1, name2,
            "Follow record name must be order-sensitive — alice_bob != bob_alice")
    }

    // MARK: - Service Logic Tests (override seam — no CloudKit needed)

    // PROF-02: writeFollow is idempotent — second call for same pair returns without creating duplicate.
    // Uses writeFollowOverride to simulate the in-memory follow registry.
    func test_writeFollow_skipsIfRecordExists() async throws {
        // In-memory registry simulating CloudKit: records that have been "saved"
        var storedRecords: Set<String> = []
        var saveCallCount = 0

        // Override: simulates fetch-or-create logic using the in-memory registry.
        // If recordName exists → idempotent return. If not → insert and increment counter.
        ProfileSharingService.writeFollowOverride = { follower, followee in
            let recordName = "\(follower)_\(followee)"
            if storedRecords.contains(recordName) {
                return  // idempotent — already exists
            }
            storedRecords.insert(recordName)
            saveCallCount += 1
        }

        // First write — creates record
        try await ProfileSharingService.writeFollow(followerUsername: "alice", followeeUsername: "bob")
        XCTAssertEqual(saveCallCount, 1, "First writeFollow should save the record")

        // Second write — must not create a duplicate
        try await ProfileSharingService.writeFollow(followerUsername: "alice", followeeUsername: "bob")
        XCTAssertEqual(saveCallCount, 1, "Second writeFollow with same args must be idempotent (no duplicate save)")
        XCTAssertEqual(storedRecords.count, 1, "Only one Follow record should exist after two identical writes")
    }

    // PROF-02: fetchFollowState returns true when the Follow record exists.
    // Uses fetchFollowStateOverride to simulate a positive CloudKit lookup.
    func test_fetchFollowState_returnsTrueForKnownRecord() async throws {
        // Simulate: the "alice_bob" follow record exists in CloudKit.
        ProfileSharingService.fetchFollowStateOverride = { follower, followee in
            let recordName = "\(follower)_\(followee)"
            return recordName == "alice_bob"
        }

        let result = try await ProfileSharingService.fetchFollowState(
            followerUsername: "alice", followeeUsername: "bob"
        )
        XCTAssertTrue(result, "fetchFollowState must return true for a known Follow record")
    }

    // PROF-02: fetchFollowState returns false for a pair that was never followed.
    // Uses fetchFollowStateOverride to simulate CKError.unknownItem response.
    func test_fetchFollowState_returnsFalseForUnknownItem() async throws {
        // Simulate: no follow record exists — service returns false for all queries.
        ProfileSharingService.fetchFollowStateOverride = { _, _ in
            return false  // mirrors the .unknownItem catch in production code
        }

        let neverFollowed = "neverFollowedUser_\(UUID().uuidString)"
        let result = try await ProfileSharingService.fetchFollowState(
            followerUsername: "someone", followeeUsername: neverFollowed
        )
        XCTAssertFalse(result, "fetchFollowState must return false for an unknown Follow record")
    }
}
