import SwiftUI

struct PremadeGoalsListView: View {
    /// Called when the user taps a premade goal row. Arguments: (title, category).
    let onSelect: (String, GoalCategory) -> Void

    // MARK: - Private data model

    private struct PremadeGoal: Identifiable {
        let id = UUID()
        let title: String
        let category: GoalCategory
    }

    private var groupedGoals: [(category: GoalCategory, goals: [PremadeGoal])] {
        GoalCategory.allCases
            .filter { !$0.suggestions.isEmpty }
            .map { cat in
                (category: cat,
                 goals: cat.suggestions.map { suggestion in
                     PremadeGoal(title: suggestion, category: cat)
                 })
            }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Page heading
                Text("My goals, your journey starts here…")
                    .font(VGTheme.serif(34))
                    .foregroundStyle(VGTheme.clay)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 4)

                // Category sections
                ForEach(groupedGoals, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader(group.category.rawValue.uppercased())

                        VStack(spacing: 8) {
                            ForEach(group.goals) { goal in
                                premadeGoalRow(goal)
                            }
                        }
                    }
                }

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(VGTheme.sandLight.ignoresSafeArea())
        .navigationTitle("Pre-made goals")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Section header

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(VGTheme.textMuted)
            .kerning(1.0)
    }

    // MARK: - Goal row

    @ViewBuilder
    private func premadeGoalRow(_ goal: PremadeGoal) -> some View {
        Button {
            onSelect(goal.title, goal.category)
        } label: {
            HStack(spacing: 14) {
                Text(goal.category.emoji)
                    .font(.title2)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title)
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundStyle(VGTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Text(goal.category.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(VGTheme.textMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(VGTheme.textMuted)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(VGTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(VGTheme.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(goal.title), \(goal.category.rawValue) goal")
        .accessibilityHint("Tap to use this goal")
    }
}
