import SwiftData
import Foundation

// MARK: - SchemaV3

/// Version 3 of the Vitamin G data schema.
/// Adds:
///   - DailyWin model — date-keyed free-text gratitude / daily win entries (GRAT-02)
///
/// CRITICAL: All V3 model types MUST live inside this enum.
/// Goal, CompletionEvent, and UserProfile are unchanged — referenced from SchemaV2.
/// The typealias at the bottom of this file resolves DailyWin call-sites to SchemaV3.DailyWin.
enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        // V2 models (via typealiases) + new DailyWin
        [Goal.self, CompletionEvent.self, UserProfile.self, DailyWin.self]
    }

    // MARK: - DailyWin (NEW in V3)

    /// Date-keyed gratitude / daily win entry (GRAT-02).
    /// One entry per calendar day enforced at ViewModel layer.
    /// All properties optional or defaulted — CloudKit sync compatibility (CLAUDE.md constraint).
    /// No @Attribute(.unique) — CloudKit does not support atomic uniqueness checks.
    @Model
    final class DailyWin {
        var id: UUID = UUID()
        var date: Date?
        var text: String?

        init(date: Date = Date(), text: String) {
            self.id = UUID()
            self.date = date
            self.text = text
        }
    }
}

// MARK: - Typealias (V3)

/// Resolves DailyWin call-sites to SchemaV3.DailyWin transparently.
typealias DailyWin = SchemaV3.DailyWin
