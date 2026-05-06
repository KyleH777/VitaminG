import SwiftData
import Foundation

// MARK: - SchemaV4
//
// Version 4 of the Vitamin G data schema.
// Adds:
//   - ChallengeTemplate model — configurable challenge definitions (CHAL-01)
//   - UserChallenge model — user's instance of a challenge (CHAL-02)
//   - CheckIn model — daily check-in entry per UserChallenge (CHAL-03)
//
// CRITICAL: All V4 model types MUST live inside this enum.
// Goal, CompletionEvent, UserProfile, DailyWin are unchanged — referenced from V2/V3.
// All properties optional or defaulted — CloudKit sync compatibility (CLAUDE.md).
// No @Attribute(.unique) — CloudKit does not support atomic uniqueness.
// Both sides of every @Relationship declare `inverse:`.

enum SchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        // V3 models unchanged + 3 new V4 types
        [SchemaV2.Goal.self,
         SchemaV2.CompletionEvent.self,
         SchemaV2.UserProfile.self,
         SchemaV3.DailyWin.self,
         SchemaV4.ChallengeTemplate.self,
         SchemaV4.UserChallenge.self,
         SchemaV4.CheckIn.self]
    }

    // MARK: - ChallengeTemplate (NEW in V4 — CHAL-01)
    @Model
    final class ChallengeTemplate {
        var id: UUID = UUID()
        var title: String?
        var challengeDescription: String?
        var category: String?               // "fitness" | "finance" | "sobriety"
        var challengeType: String?          // "featured" | "custom"
        var checkInType: String?            // "boolean" | "numeric" | "multiStep"
        var goalType: String?               // "streak" | "target" | "dateBound"
        var durationDays: Int?
        var milestonesJSON: String?         // JSON-encoded [MilestoneConfig]
        var accentColorHex: String?
        var iconName: String?
        var isFeatured: Bool = false
        var activeFrom: Date?
        var activeUntil: Date?
        var communitySize: Int = 0          // seeded value, not live count in Phase 13

        @Relationship(deleteRule: .nullify, inverse: \UserChallenge.template)
        var userChallenges: [UserChallenge]?

        init() {}
    }

    // MARK: - UserChallenge (NEW in V4 — CHAL-02)
    @Model
    final class UserChallenge {
        var id: UUID = UUID()
        var startDate: Date?
        var targetEndDate: Date?
        var currentStreak: Int = 0
        var longestStreak: Int = 0
        var totalCheckIns: Int = 0
        var statusRaw: String?              // "active" | "completed" | "abandoned"
        var milestoneHistoryJSON: String?   // JSON-encoded [Int] thresholds awarded
        var reminderHour: Int?
        var reminderMinute: Int?

        var template: ChallengeTemplate?

        @Relationship(deleteRule: .cascade, inverse: \CheckIn.userChallenge)
        var checkIns: [CheckIn]?

        init() {}
    }

    // MARK: - CheckIn (NEW in V4 — CHAL-03)
    @Model
    final class CheckIn {
        var id: UUID = UUID()
        var date: Date?
        var payloadBool: Bool?
        var payloadNumber: Double?
        var payloadNote: String?
        var timestamp: Date?

        var userChallenge: UserChallenge?

        init() {}
    }
}

// MARK: - Typealiases (V4)
typealias ChallengeTemplate = SchemaV4.ChallengeTemplate
typealias UserChallenge = SchemaV4.UserChallenge
typealias CheckIn = SchemaV4.CheckIn
