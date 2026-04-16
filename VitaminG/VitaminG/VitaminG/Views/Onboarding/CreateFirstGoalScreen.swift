import SwiftUI
import SwiftData

// MARK: - CreateFirstGoalScreen

/// Onboarding Screen 3: Create First Goal.
/// Reuses GoalViewModel for validated goal creation.
/// Reuses TierPickerView and CharacterCountView from AddGoalView.
/// Per RESEARCH.md Open Question 2: uses Form directly (no inner NavigationStack)
/// — this view is already inside OnboardingView's NavigationStack.
struct CreateFirstGoalScreen: View {

    @Bindable var onboardingVM: OnboardingViewModel
    let onComplete: () -> Void
    let onSkipGoal: () -> Void

    @State private var viewModel = GoalViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
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

                    HStack {
                        Spacer()
                        Text("\(viewModel.draftTitle.count)/\(GoalViewModel.maxTitleLength)")
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(
                                viewModel.draftTitle.count >= GoalViewModel.maxTitleLength ? Color.red :
                                viewModel.draftTitle.count >= Int(Double(GoalViewModel.maxTitleLength) * 0.85) ? Color.orange :
                                Color.secondary.opacity(0.5)
                            )
                    }
                }
            } header: {
                Text("Goal Title")
            } footer: {
                Text("Required. Be specific — vague goals are hard to act on.")
                    .foregroundStyle(.secondary)
            }

            // MARK: Tier
            Section {
                TierPickerView(selectedTier: $viewModel.draftTier)
            } header: {
                Text("Tier")
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
                    HStack {
                        Spacer()
                        Text("\(viewModel.draftDescription.count)/\(GoalViewModel.maxDescriptionLength)")
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(
                                viewModel.draftDescription.count >= GoalViewModel.maxDescriptionLength ? Color.red :
                                viewModel.draftDescription.count >= Int(Double(GoalViewModel.maxDescriptionLength) * 0.85) ? Color.orange :
                                Color.secondary.opacity(0.5)
                            )
                    }
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
                    HStack {
                        Spacer()
                        Text("\(viewModel.draftInspiration.count)/\(GoalViewModel.maxInspirationLength)")
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(
                                viewModel.draftInspiration.count >= GoalViewModel.maxInspirationLength ? Color.red :
                                viewModel.draftInspiration.count >= Int(Double(GoalViewModel.maxInspirationLength) * 0.85) ? Color.orange :
                                Color.secondary.opacity(0.5)
                            )
                    }
                }
            } header: {
                Text("Inspiration (Optional)")
            } footer: {
                Text("A quote, mantra, or reason that fuels this goal.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Your First Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveAndComplete()
                }
                .fontWeight(.semibold)
                .disabled(!viewModel.isDraftValid)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button("Maybe later") {
                onSkipGoal()
            }
            .font(.callout)
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
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

    // MARK: - Save

    /// Saves goal via GoalViewModel, then calls onComplete to trigger finish() in OnboardingView.
    /// onComplete sets hasCompletedOnboarding = true synchronously (Pitfall 2).
    private func saveAndComplete() {
        do {
            try viewModel.addGoal(context: modelContext)
            onComplete()
        } catch let error as GoalValidationError {
            viewModel.validationError = error
            viewModel.showingValidationAlert = true
        } catch {
            // Unexpected error — surface generically
            viewModel.showingValidationAlert = true
        }
    }
}
