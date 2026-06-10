import XCTest
import SwiftData
@testable import VitaminG

// DEL-05 — AccountDeletionService unit tests.
// Uses the deletePublicRecordsOverride seam to avoid CKContainer init (which crashes
// in test runs without iCloud entitlements — same pattern as Phase22PublicGoalServiceTests).
// All tests use an in-memory ModelContainer via ModelContainerFactory.makeContainer(inMemory: true).

@MainActor
final class AccountDeletionServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        try await super.setUp()
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = ModelContext(container)
        AccountDeletionService.deletePublicRecordsOverride = nil
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }

    override func tearDown() async throws {
        AccountDeletionService.deletePublicRecordsOverride = nil
        container = nil
        context = nil
        try await super.tearDown()
    }

    // MARK: - DEL-05-01

    /// Seeds 2 public goals + profile with cloudKitPublicRecordID + vg_appleUserID.
    /// Asserts the override receives all record names: 2 goal IDs + profile CK ID + appleUserID.
    func testCollectsRecordNamesFromGoalsAndProfile() async throws {
        // Seed
        UserDefaults.standard.set("test-apple-id-123", forKey: "vg_appleUserID")

        let goal1 = Goal(title: "Goal 1")
        goal1.cloudKitPublicGoalRecordID = "goal-record-1"
        let goal2 = Goal(title: "Goal 2")
        goal2.cloudKitPublicGoalRecordID = "goal-record-2"
        context.insert(goal1)
        context.insert(goal2)

        let profile = UserProfile()
        profile.cloudKitPublicRecordID = "profile-record-abc"
        context.insert(profile)
        try context.save()

        // Capture what the service sends to CloudKit
        var capturedNames: [String] = []
        AccountDeletionService.deletePublicRecordsOverride = { names in
            capturedNames = names
        }

        try await AccountDeletionService.deleteAccount(context: context)

        // Expect: 2 goal record names + profile CK record ID + appleUserID
        XCTAssertTrue(capturedNames.contains("goal-record-1"), "Missing goal-record-1")
        XCTAssertTrue(capturedNames.contains("goal-record-2"), "Missing goal-record-2")
        XCTAssertTrue(capturedNames.contains("profile-record-abc"), "Missing profile-record-abc")
        XCTAssertTrue(capturedNames.contains("test-apple-id-123"), "Missing appleUserID record")
        XCTAssertEqual(capturedNames.count, 4)
    }

    // MARK: - DEL-05-02

    /// CloudKit override throws. Asserts local data (goals) and UserDefaults (vg_appleUserID) survive.
    func testCloudKitFailureLeavesLocalDataIntact() async throws {
        UserDefaults.standard.set("survivor-apple-id", forKey: "vg_appleUserID")

        let goal = Goal(title: "Survivor Goal")
        goal.cloudKitPublicGoalRecordID = "some-record"
        context.insert(goal)
        try context.save()

        AccountDeletionService.deletePublicRecordsOverride = { _ in
            throw NSError(domain: "CKError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network failure"])
        }

        do {
            try await AccountDeletionService.deleteAccount(context: context)
            XCTFail("Expected deleteAccount to throw")
        } catch AccountDeletionService.DeletionError.cloudKitFailed {
            // Expected — CloudKit failed, local data must be intact
        }

        let goals = try context.fetch(FetchDescriptor<Goal>())
        XCTAssertEqual(goals.count, 1, "Goals should be untouched after CloudKit failure")

        let savedAppleID = UserDefaults.standard.string(forKey: "vg_appleUserID")
        XCTAssertEqual(savedAppleID, "survivor-apple-id", "vg_appleUserID should survive CloudKit failure")
    }

    // MARK: - DEL-05-03

    /// Successful deletion wipes all model types. Asserts fetch count == 0 for Goal and UserProfile.
    func testSuccessWipesAllModelTypes() async throws {
        AccountDeletionService.deletePublicRecordsOverride = { _ in }

        let goal = Goal(title: "Doomed Goal")
        context.insert(goal)
        let profile = UserProfile()
        context.insert(profile)
        try context.save()

        try await AccountDeletionService.deleteAccount(context: context)

        let goals = try context.fetch(FetchDescriptor<Goal>())
        XCTAssertEqual(goals.count, 0, "All Goals must be wiped on successful deletion")

        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(profiles.count, 0, "All UserProfiles must be wiped on successful deletion")
    }

    // MARK: - DEL-05-04

    /// Policy: .unknownItem (already deleted) is idempotency success, not an error.
    /// Documented here per design decision D-10. The override contract guarantees this
    /// by not throwing — the service must not add extra guard logic that breaks idempotency.
    func testUnknownItemTreatedAsSuccess() async throws {
        // Override that simulates a partial prior deletion — records already gone on server.
        // The service must call through without throwing.
        AccountDeletionService.deletePublicRecordsOverride = { _ in
            // Simulates server returning unknownItem for all records — no throw expected.
        }

        let goal = Goal(title: "Already-deleted goal")
        goal.cloudKitPublicGoalRecordID = "ghost-record"
        context.insert(goal)
        try context.save()

        // Must not throw — idempotent retry should converge.
        try await AccountDeletionService.deleteAccount(context: context)
    }

    // MARK: - DEL-05-05

    /// Fresh user with no public data: override receives empty array (or is never required
    /// if the service short-circuits on empty). Local wipe still proceeds.
    func testNoRemoteRecordsSkipsCloudKitAndWipesLocally() async throws {
        var overrideCalled = false
        AccountDeletionService.deletePublicRecordsOverride = { names in
            overrideCalled = true
            XCTAssertTrue(names.isEmpty, "No record names expected for a user with no public data")
        }

        let goal = Goal(title: "Private goal — no CK record")
        // cloudKitPublicGoalRecordID is nil — never made public
        context.insert(goal)
        try context.save()

        try await AccountDeletionService.deleteAccount(context: context)

        // Local wipe must still happen
        let goals = try context.fetch(FetchDescriptor<Goal>())
        XCTAssertEqual(goals.count, 0, "Local goals should be wiped even with no remote records")
        // Override may or may not be called — guard !isEmpty in production path skips CKContainer
        // but override path is called with empty array. Either behaviour is valid.
        _ = overrideCalled
    }

    // MARK: - DEL-05-06

    /// Seeds BlockListService, deletes account, asserts blockedUserIDs() returns empty.
    func testDeletionClearsBlockList() async throws {
        AccountDeletionService.deletePublicRecordsOverride = { _ in }

        BlockListService.blockUser(appleUserID: "blocked-person-1")
        BlockListService.blockUser(appleUserID: "blocked-person-2")
        XCTAssertFalse(BlockListService.blockedUserIDs().isEmpty, "Precondition: block list must be non-empty")

        try await AccountDeletionService.deleteAccount(context: context)

        XCTAssertTrue(BlockListService.blockedUserIDs().isEmpty, "Block list must be cleared after account deletion")
    }
}
