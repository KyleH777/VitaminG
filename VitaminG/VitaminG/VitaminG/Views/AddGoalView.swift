import SwiftUI
import SwiftData

// MARK: - AddGoalView

struct AddGoalView: View {
    @Bindable var viewModel: GoalViewModel
    let editingGoal: Goal?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(viewModel: GoalViewModel, editingGoal: Goal? = nil) {
        self.viewModel = viewModel
        self.editingGoal = editingGoal
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Title
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("What do you want to achieve?", text: $viewModel.draftTitle, axis: .vertical)
                            .lineLimit(1...3)
                            .onChange(of: viewModel.draftTitle) { _, new in
                                if new.count > GoalViewModel.maxTitleLength {
                                    viewModel.draftTitle = String(new.prefix(GoalViewModel.maxTitleLength))
                                }
                            }

                        CharacterCountView(
                            current: viewModel.draftTitle.count,
                            max: GoalViewModel.maxTitleLength
                        )
                    }
                } header: {
                    Text("Goal Title")
                } footer: {
                    Text("Required. Be specific — vague goals are hard to act on.")
                        .foregroundStyle(.secondary)
                }

                // MARK: Tier (2x2 card grid per D-11)
                Section {
                    TierPickerView(selectedTier: $viewModel.draftTier)
                } header: {
                    Text("Tier")
                } footer: {
                    TierFooterView(tier: viewModel.draftTier)
                }

                // MARK: Description
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        TextEditor(text: $viewModel.draftDescription)
                            .frame(minHeight: 80)
                            .onChange(of: viewModel.draftDescription) { _, new in
                                if new.count > GoalViewModel.maxDescriptionLength {
                                    viewModel.draftDescription = String(new.prefix(GoalViewModel.maxDescriptionLength))
                                }
                            }
                        CharacterCountView(
                            current: viewModel.draftDescription.count,
                            max: GoalViewModel.maxDescriptionLength
                        )
                    }
                } header: {
                    Text("Description (Optional)")
                }

                // MARK: Inspiration
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        TextEditor(text: $viewModel.draftInspiration)
                            .frame(minHeight: 60)
                            .onChange(of: viewModel.draftInspiration) { _, new in
                                if new.count > GoalViewModel.maxInspirationLength {
                                    viewModel.draftInspiration = String(new.prefix(GoalViewModel.maxInspirationLength))
                                }
                            }
                        CharacterCountView(
                            current: viewModel.draftInspiration.count,
                            max: GoalViewModel.maxInspirationLength
                        )
                    }
                } header: {
                    Text("Inspiration (Optional)")
                } footer: {
                    Text("A quote, mantra, or reason that fuels this goal. Shown on the detail screen as a daily reminder.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(editingGoal == nil ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetDraft()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoal()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isDraftValid)
                }
            }
            .alert(
                "Validation Error",
                isPresented: $viewModel.showingValidationAlert,
                presenting: viewModel.validationError
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
            .onAppear {
                if let goal = editingGoal {
                    viewModel.draftTitle       = goal.title ?? ""
                    viewModel.draftDescription = goal.goalDescription ?? ""
                    viewModel.draftTier        = goal.tier
                    viewModel.draftInspiration = goal.associatedInspiration ?? ""
                }
            }
            .onDisappear {
                // Safety net: reset draft on dismiss to prevent pollution across create/edit flows
                // (T-02-05 mitigation, Pitfall 3 from RESEARCH.md)
                viewModel.resetDraft()
            }
        }
    }

    // MARK: - Save

    private func saveGoal() {
        do {
            if let goal = editingGoal {
                try viewModel.updateGoal(goal, context: modelContext)
            } else {
                try viewModel.addGoal(context: modelContext)
            }
            dismiss()
        } catch let error as GoalValidationError {
            viewModel.validationError = error
            viewModel.showingValidationAlert = true
        } catch {
            // Unexpected error — surface generically
            viewModel.validationError = nil
            viewModel.showingValidationAlert = true
        }
    }
}

// MARK: - CharacterCountView

private struct CharacterCountView: View {
    let current: Int
    let max: Int

    private var isNearLimit: Bool { current >= Int(Double(max) * 0.85) }
    private var isAtLimit: Bool   { current >= max }

    var body: some View {
        HStack {
            Spacer()
            Text("\(current)/\(max)")
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(
                    isAtLimit   ? Color.red :
                    isNearLimit ? Color.orange :
                                  Color.secondary.opacity(0.5)
                )
                .animation(.easeInOut, value: current)
        }
    }
}

// MARK: - TierFooterView

private struct TierFooterView: View {
    let tier: GoalTier

    var description: String {
        switch tier {
        case .immediate: return "Quick wins this week — build momentum."
        case .shortTerm: return "Goals for the next few weeks to months."
        case .longTerm:  return "Multi-year milestones that shape your direction."
        case .lifeGoal:  return "The things you want to have done with your life."
        }
    }

    var body: some View {
        Label(description, systemImage: tier.icon)
            .foregroundStyle(tier.color)
            .font(.footnote)
    }
}
