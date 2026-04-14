import SwiftData
import Foundation

// MARK: - SchemaV1

/// Version 1 of the Vitamin G data schema.
/// All model types MUST be declared inside this enum and referenced via typealiases.
/// This cannot be safely retrofitted once user data exists — declared from day one per D-11.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Goal.self, CompletionEvent.self]
    }

    // MARK: - Goal

    /// CloudKit-compatible SwiftData model for a user goal.
    /// All properties are optional or have defaults to satisfy CloudKit sync requirements (D-10).
    /// No @Attribute(.unique) — CloudKit cannot enforce atomic uniqueness across devices (D-12).
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

    // MARK: - CompletionEvent

    /// Records a single completion of a goal on a given day.
    /// Used for streak computation and the heatmap in Phase 3.
    /// Tier is denormalized so stats remain correct if a goal's tier changes later.
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
}

// MARK: - Typealiases
// NOTE: Typealiases for Goal and CompletionEvent are declared in SchemaV2.swift,
// pointing to the V2 types. SchemaV1 is frozen and must not be modified (D-15).
