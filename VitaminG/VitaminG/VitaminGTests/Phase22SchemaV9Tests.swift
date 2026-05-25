import XCTest
import SwiftData
@testable import VitaminG

// GREEN — Plan 01 implemented SchemaV9 (motto on UserProfile, cloudKitPublicGoalRecordID on Goal).
// Tests verify lightweight migration field defaults and typealias resolution.
// All 6 tests must pass green (no XCTSkip — SchemaV9 ships in Plan 01).

final class Phase22SchemaV9Tests: XCTestCase {

    // In-memory ModelContainer for isolated SwiftData tests
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: SchemaV9.UserProfile.self, SchemaV9.Goal.self,
            configurations: config
        )
        context = ModelContext(container)
    }

    override func tearDown() async throws {
        context = nil
        container = nil
    }

    // MARK: - SchemaV9 Field Default Tests

    // Test 1 — D-07: UserProfile.motto defaults to nil after insert.
    // Expected: freshly inserted UserProfile has motto == nil.
    func test_motto_defaultsToNil() throws {
        let profile = SchemaV9.UserProfile()
        context.insert(profile)
        try context.save()

        let descriptor = FetchDescriptor<SchemaV9.UserProfile>()
        let results = try context.fetch(descriptor)
        XCTAssertFalse(results.isEmpty, "Expected at least one UserProfile in context")
        XCTAssertNil(results.first?.motto, "UserProfile.motto must default to nil (D-07 lightweight migration)")
    }

    // Test 2 — D-10: Goal.cloudKitPublicGoalRecordID defaults to nil after insert.
    // Expected: freshly inserted Goal has cloudKitPublicGoalRecordID == nil.
    func test_cloudKitPublicGoalRecordID_defaultsToNil() throws {
        let goal = SchemaV9.Goal(title: "Test Goal")
        context.insert(goal)
        try context.save()

        let descriptor = FetchDescriptor<SchemaV9.Goal>()
        let results = try context.fetch(descriptor)
        XCTAssertFalse(results.isEmpty, "Expected at least one Goal in context")
        XCTAssertNil(results.first?.cloudKitPublicGoalRecordID,
            "Goal.cloudKitPublicGoalRecordID must default to nil (D-10 lightweight migration)")
    }

    // Test 3 — D-07: UserProfile.motto accepts and persists a String value.
    // Expected: setting motto = "Keep going" persists and reads back equal.
    func test_motto_acceptsString() throws {
        let profile = SchemaV9.UserProfile()
        profile.motto = "Keep going"
        context.insert(profile)
        try context.save()

        let descriptor = FetchDescriptor<SchemaV9.UserProfile>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.first?.motto, "Keep going",
            "UserProfile.motto must persist and read back the assigned String value")
    }

    // Test 4 — D-10: Goal.cloudKitPublicGoalRecordID accepts and persists a String value.
    // Expected: setting cloudKitPublicGoalRecordID = "uuid-123" persists and reads back equal.
    func test_cloudKitPublicGoalRecordID_acceptsString() throws {
        let goal = SchemaV9.Goal(title: "Test Goal")
        goal.cloudKitPublicGoalRecordID = "uuid-123"
        context.insert(goal)
        try context.save()

        let descriptor = FetchDescriptor<SchemaV9.Goal>()
        let results = try context.fetch(descriptor)
        XCTAssertEqual(results.first?.cloudKitPublicGoalRecordID, "uuid-123",
            "Goal.cloudKitPublicGoalRecordID must persist and read back the assigned String value")
    }

    // Test 5 — typealias compile-time check: UserProfile resolves to SchemaV9.UserProfile.
    // Expected: a SchemaV9.UserProfile can be assigned to a variable typed UserProfile (Schema8pV2 typealias).
    // This is a compile-time check — if it compiles, the typealias is correct.
    func test_typealias_userProfile_isV9() {
        let v9Profile = SchemaV9.UserProfile()
        // Compile-time assignment — will fail to compile if typealias doesn't resolve to SchemaV9.UserProfile
        let aliased: UserProfile = v9Profile
        XCTAssertNotNil(aliased, "UserProfile typealias must resolve to SchemaV9.UserProfile")
    }

    // Test 6 — typealias compile-time check: Goal resolves to SchemaV9.Goal.
    // Expected: a SchemaV9.Goal can be assigned to a variable typed Goal (Schema8pV2 typealias).
    // This is a compile-time check — if it compiles, the typealias is correct.
    func test_typealias_goal_isV9() {
        let v9Goal = SchemaV9.Goal(title: "Typealias Test")
        // Compile-time assignment — will fail to compile if typealias doesn't resolve to SchemaV9.Goal
        let aliased: Goal = v9Goal
        XCTAssertNotNil(aliased, "Goal typealias must resolve to SchemaV9.Goal")
    }
}
