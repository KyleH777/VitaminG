import SwiftData
import Foundation

// MARK: - SchemaV7
// Adds GoalIdea and MoodEntry — new models, purely additive, lightweight migration from V6.
// All properties optional-or-defaulted for CloudKit compatibility.

enum SchemaV7: VersionedSchema {
    static var versionIdentifier = Schema.Version(7, 0, 0)

    static var models: [any PersistentModel.Type] {
        [SchemaV6.Goal.self,
         SchemaV2.CompletionEvent.self,
         SchemaV2.UserProfile.self,
         SchemaV3.DailyWin.self,
         SchemaV4.ChallengeTemplate.self,
         SchemaV4.UserChallenge.self,
         SchemaV4.CheckIn.self,
         SchemaV5.TransformationPhoto.self,
         SchemaV5.SpendingFreezeEntry.self,
         SchemaV5.NutritionEntry.self,
         SchemaV7.GoalIdea.self,
         SchemaV7.MoodEntry.self]
    }

    @Model final class GoalIdea {
        var id: UUID = UUID()
        var title: String = ""
        var ideaDescription: String = ""
        var category: String = ""
        var authorName: String = ""
        var createdAt: Date = Date()
        var upvoteCount: Int = 0
        var copyCount: Int = 0
        var isPromoted: Bool = false
        var promotedChallengeID: UUID? = nil
        init() {}
    }

    @Model final class MoodEntry {
        var id: UUID = UUID()
        var mood: Int = 0       // 0=Amazing 1=Good 2=Okay 3=Low 4=Push
        var recordedAt: Date = Date()
        var note: String? = nil
        init() {}
    }
}
