import SwiftData
import Foundation

// MARK: - SchemaV5
//
// Version 5 of the Vitamin G data schema.
// Adds (Phase 14 — Challenge Platform Community Modules):
//   - TransformationPhoto — photo proof for visual transformation challenge module (CHAL-20)
//   - SpendingFreezeEntry — daily freeze log for spending freeze module (CHAL-18)
//   - NutritionEntry — nutrition note log for nutrition module (CHAL-21)
//
// CRITICAL: All properties optional or defaulted — CloudKit sync compatibility (CLAUDE.md).
// Do not add uniqueness attributes — CloudKit does not support atomic uniqueness.
// @Attribute(.externalStorage) only on imageData: Data? (binary blob).
// userChallengeID: UUID? used for denormalized association (no @Relationship to avoid inverse complexity).

enum SchemaV5: VersionedSchema {
    static var versionIdentifier = Schema.Version(5, 0, 0)

    static var models: [any PersistentModel.Type] {
        [SchemaV2.Goal.self,
         SchemaV2.CompletionEvent.self,
         SchemaV2.UserProfile.self,
         SchemaV3.DailyWin.self,
         SchemaV4.ChallengeTemplate.self,
         SchemaV4.UserChallenge.self,
         SchemaV4.CheckIn.self,
         SchemaV5.TransformationPhoto.self,
         SchemaV5.SpendingFreezeEntry.self,
         SchemaV5.NutritionEntry.self]
    }

    // MARK: - TransformationPhoto (NEW in V5 — CHAL-20)
    @Model
    final class TransformationPhoto {
        var id: UUID = UUID()
        var date: Date?
        var userChallengeID: UUID?
        @Attribute(.externalStorage) var imageData: Data?
        var timestamp: Date?
        init() {}
    }

    // MARK: - SpendingFreezeEntry (NEW in V5 — CHAL-18)
    @Model
    final class SpendingFreezeEntry {
        var id: UUID = UUID()
        var date: Date?
        var userChallengeID: UUID?
        var isFreeze: Bool = false
        var timestamp: Date?
        init() {}
    }

    // MARK: - NutritionEntry (NEW in V5 — CHAL-21)
    @Model
    final class NutritionEntry {
        var id: UUID = UUID()
        var date: Date?
        var userChallengeID: UUID?
        var note: String?
        var timestamp: Date?
        init() {}
    }
}

// MARK: - Typealiases (V5)
typealias TransformationPhoto = SchemaV5.TransformationPhoto
typealias SpendingFreezeEntry = SchemaV5.SpendingFreezeEntry
typealias NutritionEntry = SchemaV5.NutritionEntry
