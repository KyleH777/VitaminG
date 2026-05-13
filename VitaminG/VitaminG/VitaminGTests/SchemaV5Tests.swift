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
        let payload = Data(repeating: 0xAB, count: 1024)
        let photo = TransformationPhoto()
        photo.id = UUID()
        photo.date = Date()
        photo.userChallengeID = UUID()
        photo.imageData = payload
        photo.timestamp = Date()
        context.insert(photo)
        try context.save()

        let descriptor = FetchDescriptor<TransformationPhoto>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.imageData, payload, "imageData must roundtrip byte-equal via @Attribute(.externalStorage)")
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
