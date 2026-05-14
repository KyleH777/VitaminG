import Foundation

enum GoalFrequency: String, CaseIterable, Identifiable {
    case daily   = "Daily"
    case weekly  = "Weekly"
    case monthly = "Monthly"
    case onetime = "One-time"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .daily:   return "Every day"
        case .weekly:  return "Pick days"
        case .monthly: return "Few times a month"
        case .onetime: return "A milestone"
        }
    }
}
