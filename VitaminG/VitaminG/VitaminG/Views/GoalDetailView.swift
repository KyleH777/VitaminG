import SwiftUI
import SwiftData

// MARK: - GoalDetailView

/// Full detail screen for a single goal.
/// Displays tier badge, title, dates, quote card (associatedInspiration), notes, and action buttons.
/// Edit toolbar button presents AddGoalView as a sheet. Delete triggers confirmationDialog.
struct GoalDetailView: View {
    let goal: Goal

    @State private var showingEditGoal = false
    @State private var showingDeleteConfirmation = false
    @State private var viewModel = GoalViewModel()

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                quoteCardSection
                notesSection
                actionsSection
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(goal.title ?? "Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditGoal = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEditGoal) {
            AddGoalView(viewModel: viewModel, editingGoal: goal)
        }
        .confirmationDialog(
            "Delete this goal?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.delete(goal: goal, context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tier pill badge
            Label(goal.tier.displayName, systemImage: goal.tier.icon)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(goal.tier.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(goal.tier.color.opacity(0.12), in: Capsule())

            // Goal title
            Text(goal.title ?? "Untitled")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            // Creation date
            if let date = goal.creationDate {
                Text("Added \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            // Completion date if completed
            if goal.completed,
               let lastEvent = goal.completionEvents?
                   .sorted(by: { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) })
                   .first,
               let completedAt = lastEvent.completedAt {
                Text("Completed \(completedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(red: 0.063, green: 0.725, blue: 0.506))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.top, 16)
    }

    // MARK: - Quote Card Section

    @ViewBuilder
    private var quoteCardSection: some View {
        if let inspiration = goal.associatedInspiration, !inspiration.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 20))
                    .foregroundStyle(goal.tier.color)

                Text(inspiration)
                    .font(.system(size: 18, weight: .regular, design: .rounded).italic())
                    .foregroundStyle(goal.tier.color.opacity(0.85))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(goal.tier.color.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(goal.tier.color.opacity(0.25), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
            .accessibilityLabel("Inspiration: \(inspiration)")
            .accessibilityAddTraits(.isStaticText)
        }
    }

    // MARK: - Notes Section

    @ViewBuilder
    private var notesSection: some View {
        if let desc = goal.goalDescription, !desc.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Notes")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(desc)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Complete / Reactivate button
            Button {
                viewModel.toggleCompletion(goal: goal, context: modelContext)
            } label: {
                Label(
                    goal.completed ? "Reactivate Goal" : "Mark as Complete",
                    systemImage: goal.completed ? "arrow.counterclockwise" : "checkmark.circle.fill"
                )
                .font(.system(.body, design: .rounded).weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(goal.completed ? goal.tier.color : Color(red: 0.063, green: 0.725, blue: 0.506))
            .accessibilityLabel(
                goal.completed
                    ? "Reactivate goal \(goal.title ?? "")"
                    : "Mark goal \(goal.title ?? "") as complete"
            )

            // Delete button
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete Goal", systemImage: "trash")
                    .font(.system(.body, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(.horizontal)
    }
}
