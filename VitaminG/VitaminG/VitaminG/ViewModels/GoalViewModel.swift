import SwiftData
import SwiftUI
import Observation

// MARK: - Validation

enum GoalValidationError: LocalizedError, Equatable {
    case titleEmpty
    case titleTooLong(Int)
    case descriptionTooLong(Int)
    case inspirationTooLong(Int)

    var errorDescription: String? {
        switch self {
        case .titleEmpty:
            return "Title cannot be empty."
        case .titleTooLong(let max):
            return "Title must be \(max) characters or fewer."
        case .descriptionTooLong(let max):
            return "Description must be \(max) characters or fewer."
        case .inspirationTooLong(let max):
            return "Inspiration must be \(max) characters or fewer."
        }
    }
}

// MARK: - GoalViewModel

@Observable
final class GoalViewModel {

    // MARK: Constants

    static let maxTitleLength       = 100
    static let maxDescriptionLength = 500
    static let maxInspirationLength = 300

    // MARK: Add-goal form state

    var draftTitle          = ""
    var draftDescription    = ""
    var draftTier: GoalTier = .immediate
    var draftInspiration    = ""

    var validationError: GoalValidationError?
    var showingValidationAlert = false

    // MARK: - Input Sanitization

    /// Strips control characters, normalises whitespace, and trims leading/trailing whitespace.
    func sanitize(_ raw: String) -> String {
        let blocked = CharacterSet.controlCharacters.union(.illegalCharacters).subtracting(.newlines)
        let stripped = raw.unicodeScalars
            .filter { !blocked.contains($0) }
            .reduce(into: "") { $0.unicodeScalars.append($1) }

        // Collapse internal runs of whitespace (spaces + tabs) to a single space,
        // but preserve intentional newlines in multi-line fields.
        let lines = stripped.components(separatedBy: .newlines)
        let cleaned = lines
            .map { line in
                line.components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
            }
            .joined(separator: "\n")

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Validation

    func validate(
        title: String,
        description: String,
        inspiration: String
    ) throws {
        let cleanTitle = sanitize(title)
        guard !cleanTitle.isEmpty else { throw GoalValidationError.titleEmpty }
        guard cleanTitle.count <= Self.maxTitleLength
            else { throw GoalValidationError.titleTooLong(Self.maxTitleLength) }

        let cleanDesc = sanitize(description)
        guard cleanDesc.count <= Self.maxDescriptionLength
            else { throw GoalValidationError.descriptionTooLong(Self.maxDescriptionLength) }

        let cleanInspiration = sanitize(inspiration)
        guard cleanInspiration.count <= Self.maxInspirationLength
            else { throw GoalValidationError.inspirationTooLong(Self.maxInspirationLength) }
    }

    // MARK: - CRUD

    func addGoal(context: ModelContext) throws {
        let cleanTitle       = sanitize(draftTitle)
        let cleanDescription = sanitize(draftDescription)
        let cleanInspiration = sanitize(draftInspiration)

        try validate(title: cleanTitle, description: cleanDescription, inspiration: cleanInspiration)

        let goal = Goal(
            title: cleanTitle,
            goalDescription: cleanDescription,
            tier: draftTier,
            associatedInspiration: cleanInspiration
        )
        context.insert(goal)
        resetDraft()
        rescheduleNotification(context: context)
    }

    func toggleCompletion(goal: Goal, context: ModelContext) {
        goal.completed.toggle()
        if goal.completed {
            let event = CompletionEvent(goal: goal)
            context.insert(event)
        }
        rescheduleNotification(context: context)
    }

    func updateGoal(_ goal: Goal, context: ModelContext) throws {
        let cleanTitle       = sanitize(draftTitle)
        let cleanDescription = sanitize(draftDescription)
        let cleanInspiration = sanitize(draftInspiration)
        try validate(title: cleanTitle, description: cleanDescription, inspiration: cleanInspiration)
        goal.title                 = cleanTitle
        goal.goalDescription       = cleanDescription.isEmpty ? nil : cleanDescription
        goal.tierRawValue          = draftTier.rawValue
        goal.associatedInspiration = cleanInspiration.isEmpty ? nil : cleanInspiration
        resetDraft()
        rescheduleNotification(context: context)
    }

    func delete(goal: Goal, context: ModelContext) {
        context.delete(goal)
        rescheduleNotification(context: context)
    }

    // MARK: - Notification Rescheduling

    /// Reschedules the daily notification with current active goals (NOTIF-03).
    /// Called after every goal mutation to keep the notification body current (T-03-10).
    func rescheduleNotification(context: ModelContext) {
        let descriptor = FetchDescriptor<Goal>(predicate: #Predicate { !$0.isCompleted })
        let activeGoals = (try? context.fetch(descriptor)) ?? []
        Task {
            await NotificationScheduler.shared.reschedule(activeGoals: activeGoals)
        }
    }

    // MARK: - Helpers

    func resetDraft() {
        draftTitle       = ""
        draftDescription = ""
        draftTier        = .immediate
        draftInspiration = ""
        validationError  = nil
    }

    var isDraftValid: Bool {
        !sanitize(draftTitle).isEmpty &&
        sanitize(draftTitle).count <= Self.maxTitleLength &&
        sanitize(draftDescription).count <= Self.maxDescriptionLength &&
        sanitize(draftInspiration).count <= Self.maxInspirationLength
    }
}
