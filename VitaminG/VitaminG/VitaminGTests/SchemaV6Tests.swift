import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class SchemaV6Tests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = container.mainContext
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    func test_schemaV6_versionIdentifier_is6_0_0() {
        XCTAssertEqual(SchemaV6.versionIdentifier, Schema.Version(6, 0, 0))
    }

    func test_schemaV6_modelsArray_containsTenModels() {
        XCTAssertEqual(SchemaV6.models.count, 10)
    }

    func test_goal_category_defaultsToNil() throws {
        let goal = Goal(title: "Test")
        context.insert(goal)
        try context.save()
        XCTAssertNil(goal.category)
    }

    func test_goal_frequency_defaultsToNil() throws {
        let goal = Goal(title: "Test")
        context.insert(goal)
        try context.save()
        XCTAssertNil(goal.frequency)
    }

    func test_goal_reminderTime_defaultsToNil() throws {
        let goal = Goal(title: "Test")
        context.insert(goal)
        try context.save()
        XCTAssertNil(goal.reminderTime)
    }

    func test_goal_startDate_defaultsToNil() throws {
        let goal = Goal(title: "Test")
        context.insert(goal)
        try context.save()
        XCTAssertNil(goal.startDate)
    }

    func test_goal_category_roundtrips() throws {
        let goal = Goal(title: "Run")
        goal.category = "Body"
        goal.frequency = "Daily"
        context.insert(goal)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<Goal>()).first
        XCTAssertEqual(fetched?.category, "Body")
        XCTAssertEqual(fetched?.frequency, "Daily")
    }

    func test_goal_reminderTime_roundtrips() throws {
        let goal = Goal(title: "Meditate")
        let reminder = Date(timeIntervalSince1970: 1_700_000_000)
        goal.reminderTime = reminder
        context.insert(goal)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<Goal>()).first
        XCTAssertEqual(fetched?.reminderTime, reminder)
    }

    func test_goal_startDate_roundtrips() throws {
        let goal = Goal(title: "Exercise")
        let start = Date(timeIntervalSince1970: 1_710_000_000)
        goal.startDate = start
        context.insert(goal)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<Goal>()).first
        XCTAssertEqual(fetched?.startDate, start)
    }
}
