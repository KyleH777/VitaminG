import SwiftUI
import SwiftData

/// Destination view for a Vitamin Shelf category card. Shows the user's non-completed
/// goals for the selected GoalCategory. No new NavigationStack — uses the existing
/// NavigationStack from ContentView.
struct CategoryGoalListView: View {
    let category: GoalCategory
    @Query private var allGoals: [Goal]
    @Environment(\.modelContext) private var modelContext

    private var filteredGoals: [Goal] {
        allGoals.filter { $0.category == category.rawValue && !($0.isCompleted) }
    }

    var body: some View {
        Group {
            if filteredGoals.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredGoals) { goal in
                        goalRow(goal)
                            .listRowBackground(VGTheme.surface)
                            .listRowSeparatorTint(VGTheme.separator)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(VGTheme.background)
            }
        }
        .navigationTitle("\(category.emoji) \(category.rawValue)")
        .background(VGTheme.background.ignoresSafeArea())
    }

    private func goalRow(_ goal: Goal) -> some View {
        HStack(spacing: 12) {
            let events = goal.completionEvents ?? []
            let total = max(goal.durationDays ?? 30, 1)
            let progress = Double(events.count) / Double(total)
            ProgressRingView(
                progress: min(progress, 1.0),
                tier: goal.tier,
                isCompleted: goal.isCompleted,
                size: 36,
                strokeWidth: 3,
                glow: false
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title ?? "Untitled goal")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(VGTheme.textPrimary)
                    .lineLimit(2)
                Text(goal.frequency ?? "")
                    .font(.system(size: 12))
                    .foregroundStyle(VGTheme.textMuted)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text(category.emoji)
                .font(.system(size: 48))
            Text("No \(category.rawValue) goals yet")
                .font(VGTheme.serif(20))
                .foregroundStyle(VGTheme.textPrimary)
            Text("Add your first \(category.rawValue.lowercased()) goal to see it here.")
                .font(.system(size: 15))
                .foregroundStyle(VGTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}
