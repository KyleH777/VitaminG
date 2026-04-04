import Foundation

// MARK: - SortOption

enum SortOption: Hashable, CaseIterable {
    case byTier
    case byCreationDate
    case byCompletionStatus

    var displayName: String {
        switch self {
        case .byTier:             return "By Tier"
        case .byCreationDate:     return "By Date Added"
        case .byCompletionStatus: return "Completion Status"
        }
    }

    var systemImage: String {
        switch self {
        case .byTier:             return "square.3.stack.3d"
        case .byCreationDate:     return "calendar"
        case .byCompletionStatus: return "checkmark.circle"
        }
    }
}

// MARK: - GoalSorter

struct GoalSorter {
    static func sort(_ goals: [Goal], by option: SortOption) -> [Goal] {
        switch option {
        case .byTier:
            return goals.sorted { a, b in
                let ai = GoalTier.ordered.firstIndex(of: a.tier) ?? 0
                let bi = GoalTier.ordered.firstIndex(of: b.tier) ?? 0
                if ai != bi { return ai < bi }
                // Within same tier: active before completed (D-09)
                return !a.completed && b.completed
            }
        case .byCreationDate:
            return goals.sorted {
                ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast)
            }
        case .byCompletionStatus:
            // D-08: active first (sorted by tier within active group), completed below
            let active = goals.filter { !$0.completed }.sorted { a, b in
                let ai = GoalTier.ordered.firstIndex(of: a.tier) ?? 0
                let bi = GoalTier.ordered.firstIndex(of: b.tier) ?? 0
                return ai < bi
            }
            let completed = goals.filter { $0.completed }
            return active + completed
        }
    }
}
