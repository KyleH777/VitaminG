import Foundation
import Observation

@MainActor
@Observable
final class GoalCreationWizardViewModel {

    // MARK: - Step state

    var currentStep: Int = 0   // 0 = category, 1 = name, 2 = details

    // MARK: - Step 1

    var selectedCategory: GoalCategory = .other

    // MARK: - Step 2

    var draftTitle: String = ""

    var canAdvanceStep2: Bool {
        !draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Step 3

    var draftTier: GoalTier = .immediate
    var selectedFrequency: GoalFrequency = .daily
    var reminderEnabled: Bool = true
    var draftReminderTime: Date = GoalCreationWizardViewModel.defaultReminderTime
    var isPrivate: Bool = false
    var isLegacy: Bool = false
    var draftStartDate: Date = .now

    // MARK: - Edit mode

    var isEditMode: Bool = false
    var editingGoalID: UUID? = nil

    // MARK: - Default reminder (7:30 AM)

    static var defaultReminderTime: Date {
        Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
    }

    // MARK: - Build output

    func buildGoalInput() -> GoalInput {
        let trimmedTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let reminder: Date? = (reminderEnabled && selectedFrequency != .onetime)
            ? draftReminderTime : nil
        return GoalInput(
            title: trimmedTitle,
            tier: draftTier,
            category: selectedCategory,
            frequency: selectedFrequency,
            reminderTime: reminder,
            isPrivate: isPrivate,
            startDate: isLegacy ? draftStartDate : nil
        )
    }

    // MARK: - Edit pre-fill

    func configure(from goal: Goal) {
        currentStep = 0
        isEditMode = true
        editingGoalID = goal.id
        draftTitle = goal.title ?? ""
        draftTier = goal.tier
        selectedCategory = GoalCategory(rawValue: goal.category ?? "") ?? .other
        selectedFrequency = GoalFrequency(rawValue: goal.frequency ?? "") ?? .daily
        if let rt = goal.reminderTime {
            reminderEnabled = true
            draftReminderTime = rt
        } else {
            reminderEnabled = false
            draftReminderTime = GoalCreationWizardViewModel.defaultReminderTime
        }
        isPrivate = !goal.isPublic
        isLegacy = goal.startDate != nil
        draftStartDate = goal.startDate ?? .now
    }

    // MARK: - Reset

    func reset() {
        currentStep = 0
        selectedCategory = .other
        draftTitle = ""
        draftTier = .immediate
        selectedFrequency = .daily
        reminderEnabled = true
        draftReminderTime = GoalCreationWizardViewModel.defaultReminderTime
        isPrivate = false
        isLegacy = false
        draftStartDate = .now
        isEditMode = false
        editingGoalID = nil
    }
}
