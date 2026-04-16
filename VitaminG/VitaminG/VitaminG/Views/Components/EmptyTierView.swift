import SwiftUI

// MARK: - EmptyTierView

/// Per-tier empty state shown inside TierSectionView when a tier has no active goals.
/// Displays the tier icon in tier color, warm D-07 copy, and an actionable "Add" button.
struct EmptyTierView: View {
    let tier: GoalTier
    let onAdd: () -> Void

    // MARK: Warm copy per D-07 (ONBOARD-04)

    private var promptCopy: String {
        switch tier {
        case .immediate:  return "What's one small win you can chase today?"
        case .shortTerm:  return "What are you working toward this week or month?"
        case .longTerm:   return "What would make this year meaningful?"
        case .lifeGoal:   return "What do you want your life to stand for?"
        }
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: tier.icon)
                .font(.title2)
                .foregroundStyle(tier.color)

            Text(promptCopy)
                .font(.footnote)
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add your first \(tier.displayName.lowercased()) goal") {
                onAdd()
            }
            .font(.caption.weight(.semibold))
            .fontDesign(.rounded)
            .foregroundStyle(tier.color)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
    }
}
