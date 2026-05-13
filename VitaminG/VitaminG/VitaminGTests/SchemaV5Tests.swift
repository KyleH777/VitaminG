import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class SchemaV5Tests: XCTestCase {
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

    // Structural smoke test — runs in Wave 0 to confirm SchemaV5 wiring
    func test_schemaV5_modelsArray_containsTenModels() {
        XCTAssertEqual(SchemaV5.models.count, 10,
            "SchemaV5.models must contain 4 V2/V3 models + 3 V4 models + 3 new V5 models = 10")
    }

    // CHAL-20 — implemented in Plan 02
    func test_transformationPhoto_savesAndRetrievesImageData() throws {
        try XCTSkipIf(true, "Implemented in Plan 02")
    }

    // CHAL-18 — implemented in Plan 05
    func test_spendingFreezeEntry_oneRecordPerChallengePerDay() throws {
        try XCTSkipIf(true, "Implemented in Plan 05")
    }

    // CHAL-21 — implemented in Plan 05
    func test_nutritionEntry_noteMaxThreeHundredChars() throws {
        try XCTSkipIf(true, "Implemented in Plan 05")
    }
}
