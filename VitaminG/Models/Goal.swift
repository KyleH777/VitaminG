import SwiftUI
import Foundation

// MARK: - GoalTier

/// The four tiers of goal urgency/aspiration.
/// Stored as raw String values in SwiftData for CloudKit compatibility.
enum GoalTier: String, Codable, CaseIterable, Identifiable {
    case immediate  = "Immediate"
    case shortTerm  = "Short-Term"
    case longTerm   = "Long-Term"
    case lifeGoal   = "Life Goal"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .immediate: return "bolt.fill"
        case .shortTerm: return "calendar"
        case .longTerm:  return "map.fill"
        case .lifeGoal:  return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .immediate: return Color(red: 0.98, green: 0.55, blue: 0.27) // warm orange
        case .shortTerm: return Color(red: 0.36, green: 0.78, blue: 0.64) // fresh teal
        case .longTerm:  return Color(red: 0.40, green: 0.61, blue: 0.95) // calm blue
        case .lifeGoal:  return Color(red: 0.78, green: 0.48, blue: 0.95) // deep violet
        }
    }

    var typographicWeight: Font.Weight {
        switch self {
        case .immediate: return .semibold
        case .shortTerm: return .medium
        case .longTerm:  return .regular
        case .lifeGoal:  return .bold
        }
    }

    /// Ordered from most immediate to most aspirational.
    static var ordered: [GoalTier] { [.immediate, .shortTerm, .longTerm, .lifeGoal] }
}

// NOTE: Goal and CompletionEvent model classes have been moved to SchemaV1.swift
// to satisfy VersionedSchema requirements (D-11). Import SchemaV1.swift for model types.
