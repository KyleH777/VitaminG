import SwiftData
import Foundation
import SwiftUI
import UIKit

// MARK: - SchemaV2

/// Version 2 of the Vitamin G data schema.
/// Adds:
///   - Goal.isPublic (Bool, default false) — per-goal privacy toggle (D-08, D-10)
///   - UserProfile model — personal identity layer (D-13)
///   - VitaminGMigrationPlan — lightweight V1→V2 migration
///
/// CRITICAL: All V2 model types MUST live inside this enum.
/// Typealiases at the bottom of this file update call-site resolution from V1 → V2.
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Goal.self, CompletionEvent.self, UserProfile.self]
    }

    // MARK: - Goal (V2 — adds isPublic)

    /// CloudKit-compatible SwiftData model for a user goal.
    /// All properties are optional or have defaults for CloudKit sync compatibility.
    /// isPublic added in V2 with default false — qualifies for lightweight migration.
    @Model
    final class Goal {
        var id: UUID = UUID()
        var title: String?
        /// Use goalDescription, NOT description — 'description' shadows NSObject.description.
        var goalDescription: String?
        /// Raw value of GoalTier stored as String for CloudKit compatibility.
        var tierRawValue: String?
        var isCompleted: Bool = false
        var creationDate: Date?
        var associatedInspiration: String?
        /// Per-goal privacy toggle. Default false — all goals are private by default (D-08).
        var isPublic: Bool = false

        @Relationship(deleteRule: .cascade, inverse: \CompletionEvent.goal)
        var completionEvents: [CompletionEvent]?

        init(
            title: String,
            goalDescription: String = "",
            tier: GoalTier = .immediate,
            associatedInspiration: String = ""
        ) {
            self.id = UUID()
            self.title = title
            self.goalDescription = goalDescription
            self.tierRawValue = tier.rawValue
            self.isCompleted = false
            self.creationDate = Date()
            self.associatedInspiration = associatedInspiration
            self.completionEvents = []
            self.isPublic = false
        }

        /// Computed accessor for the GoalTier enum.
        var tier: GoalTier {
            get { GoalTier(rawValue: tierRawValue ?? "") ?? .immediate }
            set { tierRawValue = newValue.rawValue }
        }

        /// Computed accessor for completion state (mirrors isCompleted).
        var completed: Bool {
            get { isCompleted }
            set { isCompleted = newValue }
        }
    }

    // MARK: - CompletionEvent (V2 — unchanged, redeclared for schema completeness)

    /// Records a single completion of a goal on a given day.
    /// Redeclared inside SchemaV2 so all V2 models reside in this enum.
    @Model
    final class CompletionEvent {
        var id: UUID = UUID()
        var completedAt: Date?
        /// Denormalized tier snapshot so stats remain correct if a goal's tier changes later.
        var tierRawValue: String?
        var goal: Goal?

        init(goal: Goal) {
            self.id = UUID()
            self.goal = goal
            self.tierRawValue = goal.tierRawValue
            self.completedAt = Date()
        }

        /// Computed accessor for the GoalTier enum.
        var tier: GoalTier {
            GoalTier(rawValue: tierRawValue ?? "") ?? .immediate
        }
    }

    // MARK: - UserProfile (NEW in V2)

    /// Personal identity model added in SchemaV2 (D-13).
    /// One record per device/iCloud account — created on first Profile tab visit (D-14).
    /// photoData is reserved nil — not surfaced in Phase 7 UI (D-03).
    @Model
    final class UserProfile {
        var id: UUID = UUID()
        /// Display name shown on the profile. Max 50 chars enforced at ViewModel layer (D-13).
        var displayName: String?
        /// Randomly assigned hex color persisted at profile creation (D-02).
        var avatarColorHex: String?
        /// Profile-level privacy toggle. Default false (Private) per D-04.
        var isPublic: Bool = false
        /// CloudKit public record ID — populated when profile is first made public (D-07).
        var cloudKitPublicRecordID: String?
        /// Reserved for future photo upload (D-03). Not surfaced in Phase 7 UI.
        var photoData: Data?

        init() {
            self.id = UUID()
            self.isPublic = false
        }
    }
}

// MARK: - Migration Plan
//
// WR-06: VitaminGMigrationPlan has moved to VitaminGMigrationPlan.swift so future
// schema authors discover it adjacent to (and not buried inside) the version files.
// When adding SchemaV4, update BOTH `schemas` and `stages` arrays in that file.

// MARK: - Typealiases (V2)

/// Convenience typealiases so call sites resolve to V2 types transparently.
/// Replaces the V1 typealiases that were removed from SchemaV1.swift.
typealias Goal = SchemaV2.Goal
typealias CompletionEvent = SchemaV2.CompletionEvent
typealias UserProfile = SchemaV2.UserProfile

// MARK: - Color+Hex

extension Color {
    /// Returns the hex string representation of this color (e.g. "#FF6B4A").
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    /// Initialises a Color from a hex string (e.g. "#FF6B4A" or "FF6B4A").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
