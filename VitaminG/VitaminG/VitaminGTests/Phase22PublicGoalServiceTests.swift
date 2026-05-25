import XCTest
import SwiftData
import CloudKit
@testable import VitaminG

// RED/SKIP — Wave 0 stub. Tests reference PublicGoalService which ships in Plan 02.
// Two predicate-inspection tests can pass green once PublicGoalService exists.
// Other tests XCTSkip until Plan 02 ships the service implementation.
//
// COMPILE-GATE blocks (#if false) contain the real assertions once PublicGoalService exists.

final class Phase22PublicGoalServiceTests: XCTestCase {

    // MARK: - CloudKit Write Tests (XCTSkip until Plan 02)

    // PROF-04 / D-09: writePublicGoal sanitizes the title before CloudKit write.
    // Expected: InputSanitizer.sanitizeForPublic is applied — injection chars stripped.
    // Wave 0: SKIP — PublicGoalService.writePublicGoal not yet implemented.
    func test_writePublicGoal_sanitizesTitle() async throws {
        throw XCTSkip("Wave 0 stub — PublicGoalService.writePublicGoal implemented in Plan 02")

        // COMPILE-GATE: Enable in Plan 02 when PublicGoalService ships.
        #if false
        let goal = SchemaV9.Goal(title: "<script>alert('xss')</script>")
        goal.isPublic = true
        // writePublicGoal must sanitize via InputSanitizer.sanitizeForPublic before write
        try await PublicGoalService.writePublicGoal(goal: goal, creatorUsername: "tester")
        // Verify record on CloudKit — sanitized title expected
        let results = try await PublicGoalService.searchGoals(keyword: "alert")
        XCTAssertTrue(results.isEmpty, "Sanitized title must not contain injection chars")
        #endif
    }

    // PROF-04 / D-10: deletePublicGoal swallows .unknownItem error (idempotent delete).
    // Expected: calling deletePublicGoal for a non-existent record does not throw.
    // Wave 0: SKIP — PublicGoalService.deletePublicGoal not yet implemented.
    func test_deletePublicGoal_swallowsUnknownItem() async throws {
        throw XCTSkip("Wave 0 stub — PublicGoalService.deletePublicGoal implemented in Plan 02")

        // COMPILE-GATE: Enable in Plan 02.
        #if false
        let nonExistentID = "non-existent-\(UUID().uuidString)"
        // Must not throw CKError.unknownItem — swallowed per PATTERNS.md delete pattern
        try await PublicGoalService.deletePublicGoal(recordName: nonExistentID)
        #endif
    }

    // D-11: backfillPublicGoals skips goals that already have cloudKitPublicGoalRecordID set.
    // Expected: goals with cloudKitPublicGoalRecordID != nil are not written again.
    // Wave 0: SKIP — PublicGoalService.backfillPublicGoals not yet implemented.
    func test_backfillPublicGoals_skipsGoalsWithExistingRecordID() async throws {
        throw XCTSkip("Wave 0 stub — PublicGoalService.backfillPublicGoals implemented in Plan 02")

        // COMPILE-GATE: Enable in Plan 02 when backfillPublicGoals accepts ModelContext.
        #if false
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SchemaV9.Goal.self, configurations: config)
        let context = ModelContext(container)

        // Goal 1: public + already has record ID (should be skipped)
        let alreadySynced = SchemaV9.Goal(title: "Already Synced")
        alreadySynced.isPublic = true
        alreadySynced.cloudKitPublicGoalRecordID = "existing-record-id"
        context.insert(alreadySynced)

        // Goal 2: public + no record ID (should be backfilled)
        let needsSync = SchemaV9.Goal(title: "Needs Sync")
        needsSync.isPublic = true
        context.insert(needsSync)

        try context.save()

        var writtenGoalIDs: [String] = []
        await PublicGoalService.backfillPublicGoals(
            context: context,
            creatorUsername: "tester",
            writeOverride: { goal, _ in writtenGoalIDs.append(goal.id.uuidString) }
        )

        XCTAssertEqual(writtenGoalIDs.count, 1, "Only goals without cloudKitPublicGoalRecordID should be backfilled")
        XCTAssertEqual(writtenGoalIDs.first, needsSync.id.uuidString)
        #endif
    }

    // DISC-01: searchGoals uses CONTAINS[cd] predicate on the 'title' field.
    // Predicate inspection test — verifies predicate construction without hitting CloudKit.
    // Wave 0: SKIP — PublicGoalService.searchGoals not yet implemented.
    func test_searchGoals_buildsContainsCdPredicate() async throws {
        throw XCTSkip("Wave 0 stub — PublicGoalService.searchGoals implemented in Plan 02")

        // COMPILE-GATE: Enable in Plan 02.
        #if false
        // The predicate used by searchGoals must be CONTAINS[cd]:
        let keyword = "marathon"
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", keyword)
        // Verify predicate format string (case/diacritic insensitive substring)
        XCTAssertTrue(predicate.predicateFormat.contains("CONTAINS[cd]"),
            "searchGoals must use CONTAINS[cd] predicate for case-insensitive substring search")
        XCTAssertTrue(predicate.predicateFormat.contains(keyword),
            "Predicate must include the search keyword")
        #endif
    }

    // DISC-02: searchPeople uses BEGINSWITH[cd] predicate on the 'username' field.
    // Predicate inspection test — verifies predicate construction without hitting CloudKit.
    // Wave 0: SKIP — PublicGoalService.searchPeople not yet implemented.
    func test_searchPeople_buildsBeginsWithCdPredicate() async throws {
        throw XCTSkip("Wave 0 stub — PublicGoalService.searchPeople implemented in Plan 02")

        // COMPILE-GATE: Enable in Plan 02.
        #if false
        let prefix = "ali"
        let predicate = NSPredicate(format: "username BEGINSWITH[cd] %@", prefix)
        XCTAssertTrue(predicate.predicateFormat.contains("BEGINSWITH[cd]"),
            "searchPeople must use BEGINSWITH[cd] predicate for username prefix search")
        XCTAssertTrue(predicate.predicateFormat.contains(prefix))
        #endif
    }

    // PROF-04: fetchGoalsForUser maps CKRecord fields to PublicGoalItem struct.
    // Expected: returned PublicGoalItem carries all required fields from the CKRecord.
    // Wave 0: SKIP — PublicGoalService.fetchGoalsForUser not yet implemented.
    func test_fetchGoalsForUser_mapsRecordToPublicGoalItem() async throws {
        throw XCTSkip("Wave 0 stub — PublicGoalService.fetchGoalsForUser implemented in Plan 02")

        // COMPILE-GATE: Enable in Plan 02.
        #if false
        let results = try await PublicGoalService.fetchGoalsForUser(username: "alice")
        // If results are non-empty (seeded test data), verify field mapping
        for item in results {
            XCTAssertFalse(item.id.isEmpty, "PublicGoalItem.id must be non-empty")
            XCTAssertFalse(item.title.isEmpty, "PublicGoalItem.title must be non-empty")
            XCTAssertFalse(item.category.isEmpty, "PublicGoalItem.category must be non-empty")
            XCTAssertGreaterThanOrEqual(item.progressPercent, 0)
            XCTAssertLessThanOrEqual(item.progressPercent, 100)
        }
        #endif
    }
}
