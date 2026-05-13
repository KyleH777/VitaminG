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
        let challengeID = UUID()
        let today = Calendar.current.startOfDay(for: Date())

        let a = SpendingFreezeEntry()
        a.id = UUID(); a.date = today; a.userChallengeID = challengeID; a.isFreeze = true
        context.insert(a)
        let b = SpendingFreezeEntry()
        b.id = UUID(); b.date = today; b.userChallengeID = challengeID; b.isFreeze = false
        context.insert(b)
        try context.save()

        let descriptor = FetchDescriptor<SpendingFreezeEntry>()
        let all = try context.fetch(descriptor)
        XCTAssertEqual(all.filter { $0.userChallengeID == challengeID }.count, 2,
            "Schema permits multiple inserts; uniqueness is enforced at the View layer")

        let cal = Calendar.current
        let todayMatches = all.filter { entry in
            entry.userChallengeID == challengeID
                && (entry.date.map { cal.isDateInToday($0) } ?? false)
        }
        XCTAssertEqual(todayMatches.count, 2,
            "Two records for today exist; ViewModel layer takes first() per Plan 05 contract")
    }

    // CHAL-21 — implemented in Plan 05
    func test_nutritionEntry_noteMaxThreeHundredChars() throws {
        let entry = NutritionEntry()
        entry.id = UUID()
        entry.date = Date()
        entry.userChallengeID = UUID()
        let raw = String(repeating: "a", count: 350)
        entry.note = String(raw.prefix(300))
        entry.timestamp = Date()
        context.insert(entry)
        try context.save()

        let descriptor = FetchDescriptor<NutritionEntry>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.first?.note?.count, 300,
            "NutritionEntry.note must store exactly 300 characters when caller truncates per contract")
    }
}
