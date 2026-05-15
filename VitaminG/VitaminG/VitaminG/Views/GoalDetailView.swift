import SwiftUI
import SwiftData
import Charts

// MARK: - GoalDetailView

/// Full detail screen for a single goal.
/// Displays tier badge, title, dates, quote card (associatedInspiration), notes, and action buttons.
/// Edit toolbar button presents GoalCreationWizardView as a sheet. Delete triggers confirmationDialog.
struct GoalDetailView: View {
    let goal: Goal

    @State private var showingEditGoal = false
    @State private var showingDeleteConfirmation = false
    @State private var showingStartDatePicker = false
    @State private var viewModel = GoalViewModel()

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Live query so completions added during this session update the progress section immediately (CR-02).
    @Query private var allEvents: [CompletionEvent]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                publicToggleSection
                quoteCardSection
                progressSection
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
            GoalCreationWizardView(editingGoal: goal)
        }
        .sheet(isPresented: $showingStartDatePicker) {
            NavigationStack {
                VStack(spacing: 24) {
                    Text("When did you actually start this goal?")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top)

                    DatePicker(
                        "Start date",
                        selection: Binding(
                            get: { goal.startDate ?? goal.creationDate ?? Date() },
                            set: { goal.startDate = $0 }
                        ),
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()

                    Spacer()
                }
                .navigationTitle("Edit Start Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showingStartDatePicker = false }
                    }
                }
            }
            .presentationDetents([.medium])
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

    // MARK: - Public Toggle Section

    private var publicToggleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Share this goal")
                    .font(.body).fontDesign(.rounded)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { goal.isPublic },
                    set: { newValue in
                        viewModel.updateGoalPublicStatus(goal: goal, isPublic: newValue, context: modelContext)
                    }
                ))
                .labelsHidden()
            }
            Text("Public goals appear on your profile when your profile is set to public.")
                .font(.caption).fontDesign(.rounded)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Share this goal")
        .accessibilityValue(goal.isPublic ? "On" : "Off")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tier pill badge
            Label(goal.tier.displayName, systemImage: goal.tier.icon)
                .font(.caption.weight(.semibold)).fontDesign(.rounded)
                .foregroundStyle(goal.tier.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(goal.tier.color.opacity(0.12), in: Capsule())

            // Goal title
            Text(goal.title ?? "Untitled")
                .font(.title2.weight(.semibold)).fontDesign(.rounded)
                .foregroundStyle(.primary)

            // Creation date
            if let date = goal.creationDate {
                Text("Added \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }

            // Completion date if completed
            if goal.completed,
               let lastEvent = goal.completionEvents?
                   .sorted(by: { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) })
                   .first,
               let completedAt = lastEvent.completedAt {
                Text("Completed \(completedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).fontDesign(.rounded)
                    .foregroundStyle(Color.completionGreen)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
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
                    .font(.title3)
                    .foregroundStyle(goal.tier.color)

                Text(inspiration)
                    .font(.body.italic()).fontDesign(.rounded)
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
                    .font(.footnote.weight(.semibold)).fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                Text(desc)
                    .font(.body).fontDesign(.rounded)
                    .foregroundStyle(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    // MARK: - Progress Section (PROG-02, PROG-04)

    /// Live-queried events for this goal — guaranteed to reflect completions added during the session.
    private var goalEvents: [CompletionEvent] {
        allEvents.filter { $0.goal?.id == goal.id }
    }

    /// Total cumulative completion count for the goal.
    private var totalCompletions: Int {
        goalEvents.count
    }

    /// Most recent completion date, or nil if the goal has never been completed.
    private var lastCompletedDate: Date? {
        goalEvents.compactMap { $0.completedAt }.max()
    }

    /// Pure-Swift progress arithmetic delegate (no observable state required).
    private var progressVM: ProgressViewModel {
        ProgressViewModel()
    }

    @ViewBuilder
    private var progressSection: some View {
        let chartItems = progressVM.chartData(for: goal, events: goalEvents)
        let score = progressVM.momentumScore(for: goal, events: goalEvents)
        let momentumColor: Color = {
            if score >= 0.5 { return .green }
            if score >= 0.1 { return .orange }
            return .secondary
        }()
        let momentumDescription: String = {
            if score >= 0.5 { return "High" }
            if score >= 0.1 { return "Medium" }
            return "Inactive"
        }()
        let scoreString = String(format: "%.2f", score)
        let last7Dates = Array(chartItems.suffix(7).map { $0.date })

        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text("Progress History")
                .font(.footnote.weight(.semibold)).fontDesign(.rounded)
                .foregroundStyle(.secondary)

            // Summary rows
            HStack {
                Text("Total completions")
                    .font(.body).fontDesign(.rounded)
                Spacer()
                Text("\(totalCompletions)")
                    .font(.body.weight(.semibold)).fontDesign(.rounded)
            }

            HStack {
                Text("Last completed")
                    .font(.body).fontDesign(.rounded)
                Spacer()
                Text(
                    lastCompletedDate.map { $0.formatted(date: .abbreviated, time: .omitted) }
                        ?? "Never"
                )
                .font(.body.weight(.semibold)).fontDesign(.rounded)
            }

            // 30-day bar chart (PROG-02, D-08, D-10)
            Chart(chartItems) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(goal.tier.color)
            }
            .frame(height: 80)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: last7Dates) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .accessibilityLabel("30-day completion history bar chart")
            .accessibilityValue("\(totalCompletions) completions in the last 30 days")
            .padding(.top, 8)

            // Momentum row (PROG-04, D-06, D-07)
            HStack(spacing: 8) {
                Circle()
                    .fill(momentumColor)
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Momentum")
                        .font(.body).fontDesign(.rounded)
                    Text("completions in the last 7 days")
                        .font(.caption).fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(scoreString)
                    .font(.body.weight(.semibold)).fontDesign(.rounded)
            }
            .padding(.top, 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "Momentum score \(scoreString). \(momentumDescription). Based on completions in the last 7 days."
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
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
            .tint(goal.completed ? goal.tier.color : Color.completionGreen)
            .accessibilityLabel(
                goal.completed
                    ? "Reactivate goal \(goal.title ?? "")"
                    : "Mark goal \(goal.title ?? "") as complete"
            )

            // Edit start date (legacy backdating)
            Button {
                showingStartDatePicker = true
            } label: {
                Label("Edit start date", systemImage: "calendar.badge.clock")
                    .font(.system(.body, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(VGTheme.terra)

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
        .sensoryFeedback(.success, trigger: goal.completed) { _, new in new }
    }
}
