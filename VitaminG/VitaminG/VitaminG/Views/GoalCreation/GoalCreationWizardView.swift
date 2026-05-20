import SwiftUI
import SwiftData

struct GoalCreationWizardView: View {
    let isOnboarding: Bool
    let editingGoal: Goal?
    let startAtStep: Int
    let premadeGoal: (title: String, category: GoalCategory)?
    let onComplete: (() -> Void)?

    @State private var wizardVM = GoalCreationWizardViewModel()
    @State private var goalVM = GoalViewModel()
    @State private var validationError: GoalValidationError?
    @State private var showingValidationAlert = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(isOnboarding: Bool = false,
         editingGoal: Goal? = nil,
         startAtStep: Int = 0,
         premadeGoal: (title: String, category: GoalCategory)? = nil,
         onComplete: (() -> Void)? = nil) {
        self.isOnboarding = isOnboarding
        self.editingGoal = editingGoal
        self.startAtStep = startAtStep
        self.premadeGoal = premadeGoal
        self.onComplete = onComplete
    }

    var body: some View {
        wizardContent
            .onAppear {
                if let goal = editingGoal {
                    wizardVM.configure(from: goal)
                } else if let pg = premadeGoal {
                    wizardVM.configure(fromPremade: pg.title, category: pg.category)
                } else if startAtStep > 0 {
                    wizardVM.currentStep = startAtStep
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert, presenting: validationError) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
    }

    // Wraps in NavigationStack only when used as a standalone sheet (not inside OnboardingView's stack).
    // In onboarding mode we're already inside OnboardingView's NavigationStack, so a second
    // NavigationStack would produce nested stacks — causing swipe-back to pop the outer stack
    // (returning to WelcomeScreen) instead of navigating within the wizard.
    @ViewBuilder
    private var wizardContent: some View {
        if isOnboarding {
            stepView
                .navigationBarBackButtonHidden(true)
        } else {
            NavigationStack {
                stepView
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { wizardVM.reset(); dismiss() }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var stepView: some View {
        switch wizardVM.currentStep {
        case 0:
            Step1CategoryScreen(wizardVM: wizardVM, isOnboarding: isOnboarding)
        case 1:
            Step2NameScreen(wizardVM: wizardVM)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { wizardVM.currentStep = 0 } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
        default:
            Step3DetailsScreen(wizardVM: wizardVM, onSave: saveGoal)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { wizardVM.currentStep = 1 } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
        }
    }

    private func saveGoal() {
        let input = wizardVM.buildGoalInput()
        do {
            if let goal = editingGoal {
                try goalVM.updateGoal(goal, input: input, context: modelContext)
            } else {
                try goalVM.addGoal(input: input, context: modelContext)
            }
            wizardVM.reset()
            if isOnboarding { onComplete?() } else { dismiss() }
        } catch let error as GoalValidationError {
            validationError = error
            showingValidationAlert = true
        } catch {
            showingValidationAlert = true
        }
    }
}
