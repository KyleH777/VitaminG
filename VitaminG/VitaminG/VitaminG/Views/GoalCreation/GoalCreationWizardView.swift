import SwiftUI
import SwiftData

struct GoalCreationWizardView: View {
    let isOnboarding: Bool
    let editingGoal: Goal?
    let onComplete: (() -> Void)?

    @State private var wizardVM = GoalCreationWizardViewModel()
    @State private var goalVM = GoalViewModel()
    @State private var validationError: GoalValidationError?
    @State private var showingValidationAlert = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(isOnboarding: Bool = false, editingGoal: Goal? = nil, onComplete: (() -> Void)? = nil) {
        self.isOnboarding = isOnboarding
        self.editingGoal = editingGoal
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            stepView
                .toolbar {
                    if !isOnboarding {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { wizardVM.reset(); dismiss() }
                        }
                    }
                }
        }
        .onAppear {
            if let goal = editingGoal { wizardVM.configure(from: goal) }
        }
        .alert("Validation Error", isPresented: $showingValidationAlert, presenting: validationError) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
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
