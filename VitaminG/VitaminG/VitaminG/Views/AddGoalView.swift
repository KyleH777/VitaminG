import SwiftUI
import SwiftData

// MARK: - AddGoalView

struct AddGoalView: View {
    @Bindable var viewModel: GoalViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

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

                // MARK: Tier
                Section {
                    Picker("Tier", selection: $viewModel.draftTier) {
                        ForEach(GoalTier.ordered) { tier in
                            Label(tier.displayName, systemImage: tier.icon)
                                .tag(tier)
                        }
                    }
                    .pickerStyle(.navigationLink)
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
            .navigationTitle("New Goal")
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
        }
    }

    // MARK: - Save

    private func saveGoal() {
        do {
            try viewModel.addGoal(context: modelContext)
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
                    isAtLimit   ? .red :
                    isNearLimit ? .orange :
                                  .tertiary
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
