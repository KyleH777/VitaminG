import SwiftUI
import SwiftData

// MARK: - GoalListView

struct GoalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createdAt) private var goals: [Goal]

    @State private var viewModel = GoalViewModel()
    @State private var showingAddGoal = false
    @State private var goalToDelete: Goal?
    @State private var showingDeleteConfirmation = false

    // MARK: Derived

    private var hasAnyGoals: Bool { !goals.isEmpty }

    private func goals(for tier: GoalTier) -> [Goal] {
        goals.filter { $0.tier == tier }
    }

    // MARK: Body

    var body: some View {
        Group {
            if hasAnyGoals {
                goalList
            } else {
                EmptyStateView {
                    showingAddGoal = true
                }
            }
        }
        .navigationTitle("My Goals")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddGoal = true
                } label: {
                    Label("Add Goal", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView(viewModel: viewModel)
        }
        .confirmationDialog(
            "Delete this goal?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let goal = goalToDelete {
                    viewModel.delete(goal: goal, context: modelContext)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: Goal List

    private var goalList: some View {
        List {
            ForEach(GoalTier.ordered, id: \.self) { tier in
                let tieredGoals = goals(for: tier)
                if !tieredGoals.isEmpty {
                    TierSectionView(tier: tier) {
                        ForEach(tieredGoals) { goal in
                            GoalRowView(goal: goal) {
                                viewModel.toggleCompletion(goal: goal, context: modelContext)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    goalToDelete = goal
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeInOut, value: goals.count)
    }
}

// MARK: - TierSectionView

private struct TierSectionView<Content: View>: View {
    let tier: GoalTier
    @ViewBuilder let content: () -> Content

    var body: some View {
        Section {
            content()
        } header: {
            HStack(spacing: 8) {
                Image(systemName: tier.icon)
                    .foregroundStyle(tier.color)
                Text(tier.displayName)
                    .font(.subheadline.weight(tier.typographicWeight))
                    .foregroundStyle(tier.color)
            }
            .textCase(nil)
        }
    }
}

// MARK: - GoalRowView

private struct GoalRowView: View {
    let goal: Goal
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Completion toggle
            Button(action: onToggle) {
                Image(systemName: goal.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(goal.completed ? goal.tier.color : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(goal.completed ? "Mark incomplete" : "Mark complete")

            VStack(alignment: .leading, spacing: 3) {
                Text(goal.title ?? "")
                    .font(.body.weight(goal.tier.typographicWeight))
                    .foregroundStyle(goal.completed ? .secondary : .primary)
                    .strikethrough(goal.completed, color: .secondary)

                if let desc = goal.goalDescription, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Tier accent pip
            RoundedRectangle(cornerRadius: 3)
                .fill(goal.tier.color.opacity(goal.completed ? 0.3 : 0.8))
                .frame(width: 4, height: 36)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - EmptyStateView

struct EmptyStateView: View {
    let onAddTapped: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.55, blue: 0.27).opacity(0.15),
                                Color(red: 0.78, green: 0.48, blue: 0.95).opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "star.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.55, blue: 0.27),
                                Color(red: 0.78, green: 0.48, blue: 0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse)
            }

            // Copy
            VStack(spacing: 12) {
                Text("Time to take your Vitamin G!")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Start making goals to get your daily dose\nof gratitude and inspiration.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            // CTA
            Button(action: onAddTapped) {
                Label("Add Your First Goal", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.55, blue: 0.27),
                                Color(red: 0.78, green: 0.48, blue: 0.95)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
