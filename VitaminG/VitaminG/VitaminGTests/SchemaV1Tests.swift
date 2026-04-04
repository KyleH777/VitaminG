import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class SchemaV1Tests: XCTestCase {

    // MARK: - VersionedSchema Structure

    func test_schemaV1_versionIdentifier() {
        XCTAssertEqual(SchemaV1.versionIdentifier, Schema.Version(1, 0, 0))
    }

    func test_schemaV1_modelsCount() {
        XCTAssertEqual(SchemaV1.models.count, 2)
    }

    func test_schemaV1_modelsContainsGoal() {
        XCTAssertTrue(
            SchemaV1.models.contains(where: { $0 == Goal.self }),
            "SchemaV1.models must include Goal.self"
        )
    }

    func test_schemaV1_modelsContainsCompletionEvent() {
        XCTAssertTrue(
            SchemaV1.models.contains(where: { $0 == CompletionEvent.self }),
            "SchemaV1.models must include CompletionEvent.self"
        )
    }

    // MARK: - Goal Default Properties

    func test_goal_defaultIsCompleted() throws {
        let container = try ModelContainerFactory.makeContainer(inMemory: true)
        let context = container.mainContext

        let goal = Goal(title: "Test Goal", goalDescription: "", tier: .immediate, associatedInspiration: "")
        context.insert(goal)

        XCTAssertFalse(goal.completed, "Goal.completed should default to false")
        XCTAssertNotNil(goal.id, "Goal.id should be non-nil after creation")
        XCTAssertNotNil(goal.creationDate, "Goal.creationDate should be set on init")
    }

    // MARK: - CompletionEvent Default Properties

    func test_completionEvent_setsCompletedAt() throws {
        let container = try ModelContainerFactory.makeContainer(inMemory: true)
        let context = container.mainContext

        let goal = Goal(title: "Test Goal", goalDescription: "", tier: .immediate, associatedInspiration: "")
        context.insert(goal)

        let event = CompletionEvent(goal: goal)
        context.insert(event)

        XCTAssertNotNil(event.completedAt, "CompletionEvent.completedAt should be set on init")
        XCTAssertEqual(
            event.tierRawValue,
            goal.tierRawValue,
            "CompletionEvent.tierRawValue should be denormalized from the goal's tier"
        )
    }
}
