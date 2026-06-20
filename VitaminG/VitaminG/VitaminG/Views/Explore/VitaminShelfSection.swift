import SwiftUI
import SwiftData

/// The 6-category Vitamin Shelf grid. Each card shows the category emoji, name,
/// subtitle, and a badge with the count of the user's non-completed goals in that category.
/// Tapping a card pushes CategoryGoalListView via NavigationLink.
struct VitaminShelfSection: View {
    @Query private var allGoals: [Goal]

    /// The 6 Vitamin Shelf categories (GoalCategory subset — excludes .habit and .other).
    private let shelfCategories: [GoalCategory] = [
        .body, .mind, .wellness, .money, .connection, .creative
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(shelfCategories) { category in
                NavigationLink(value: category) {
                    categoryCard(category)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private func categoryCard(_ category: GoalCategory) -> some View {
        let count = goalCount(for: category)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.emoji)
                    .font(.title)
                    .accessibilityHidden(true)
                Spacer()
                if count > 0 {
                    Text("\(count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(VGTheme.accentTerra)
                        .clipShape(Capsule())
                        .accessibilityHidden(true)
                }
            }
            Text(category.rawValue)
                .font(.callout.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textPrimary)
            Text(category.subtitle)
                .font(.caption)
                .foregroundStyle(VGTheme.textMuted)
                .lineLimit(2)
        }
        .padding(16)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(VGTheme.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(count > 0
            ? "\(category.rawValue). \(category.subtitle). \(count) active goals."
            : "\(category.rawValue). \(category.subtitle).")
    }

    private func goalCount(for category: GoalCategory) -> Int {
        allGoals.filter { $0.category == category.rawValue && !($0.isCompleted) }.count
    }
}
