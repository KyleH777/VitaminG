// SchemaV8: adds UserProfile.username (String?, nil default) — lightweight migration from V7. UIADD-07.
import SwiftData
import Foundation

enum SchemaV8: VersionedSchema {
    static var versionIdentifier = Schema.Version(8, 0, 0)
    static var models: [any PersistentModel.Type] = [
        SchemaV6.Goal.self,
        SchemaV2.CompletionEvent.self,
        SchemaV8.UserProfile.self,
        SchemaV3.DailyWin.self,
        SchemaV4.ChallengeTemplate.self,
        SchemaV4.UserChallenge.self,
        SchemaV4.CheckIn.self,
        SchemaV5.TransformationPhoto.self,
        SchemaV5.SpendingFreezeEntry.self,
        SchemaV5.NutritionEntry.self,
        SchemaV7.GoalIdea.self,
        SchemaV7.MoodEntry.self
    ]

    @Model final class UserProfile {
        var id: UUID = UUID()
        var displayName: String?
        var avatarColorHex: String?
        var isPublic: Bool = false
        var cloudKitPublicRecordID: String?
        var photoData: Data?
        // Added V8 — UIADD-07
        var username: String?
        init() { self.id = UUID(); self.isPublic = false }
    }
}
