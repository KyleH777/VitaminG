import SwiftData
import SwiftUI
import Observation
import WidgetKit

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

@MainActor
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

    // MARK: - Milestone Tracking (PROG-03, D-11, D-13)

    /// Set when a completion event causes the cumulative count to hit a milestone
    /// threshold (5, 10, 25, 50) for the first time this session. Consumed by
    /// GoalListView via `.onChange(of: viewModel.pendingMilestone?.goalID)`.
    /// View layer is responsible for clearing this after consumption.
    var pendingMilestone: (goalID: UUID, threshold: Int)? = nil

    /// In-memory dedup set keyed `"\(goalID.uuidString)-\(threshold)"` (D-13).
    /// Does not persist across launches — re-fire on next launch is acceptable.
    private var firedMilestones: Set<String> = []

    /// Pure-Swift progress arithmetic delegate. Stateless; no allocation cost.
    private let progressVM = ProgressViewModel()

    /// Streak freeze service used to obtain frozen dates for per-goal streak computation.
    private let freezeService = StreakFreezeService()

    // MARK: - Per-Goal Milestone Detection (MILE-04)

    /// Set when addCheckIn detects the per-goal streak just crossed a milestone threshold.
    /// Threshold values: [7, 14, 30, 60, 90, 365] (StreakMilestoneGate.goalStreakThresholds).
    /// Consumed by GoalListView/GoalDetailView via .onChange. View clears after consumption.
    var pendingGoalMilestone: (goalID: UUID, threshold: Int)? = nil

    /// Set when addCheckIn detects completionEvents.count >= durationDays on a non-completed goal.
    /// Consumed by GoalDetailView to present GoalCompletionCelebrationView (MILE-06).
    var pendingGoalCompletion: UUID? = nil

    // MARK: - Input Sanitization

    /// Delegates to the shared InputSanitizer utility.
    func sanitize(_ raw: String) -> String {
        InputSanitizer.sanitize(raw)
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
        reloadWidgetTimelines()
    }

    func toggleCompletion(goal: Goal, context: ModelContext) {
        goal.completed.toggle()
        if goal.completed {
            let event = CompletionEvent()
            event.completedAt = Date()
            event.tierRawValue = goal.tierRawValue
            context.insert(event)
            event.goal = goal

            // PROG-03 — milestone threshold check after the new event is in the
            // graph. SwiftData updates `goal.completionEvents` synchronously on
            // @MainActor, so reading the count here reflects the inserted event.
            let count = goal.completionEvents?.count ?? 0
            if let threshold = progressVM.milestoneJustCrossed(
                count: count,
                firedSet: firedMilestones,
                goalID: goal.id
            ) {
                let key = "\(goal.id.uuidString)-\(threshold)"
                firedMilestones.insert(key)
                pendingMilestone = (goalID: goal.id, threshold: threshold)
            }
        }
        rescheduleNotification(context: context)
        reloadWidgetTimelines()
    }

    /// Adds a daily check-in event for a goal without marking the goal as permanently completed.
    /// - Parameters:
    ///   - goal: The goal to check in for.
    ///   - context: The SwiftData model context.
    ///   - username: The current user's display name (for GoalGlimpse write). Defaults to "".
    ///   - colorHex: The current user's avatar color hex (for GoalGlimpse write). Defaults to "".
    ///
    /// This is the daily tracking path: "I did this today" vs. `toggleCompletion` which is
    /// "I've achieved this goal permanently". Per GOAL2-04 / D-12.
    ///
    /// Same-day dedup: if a CompletionEvent already exists for today, this is a no-op (Pitfall 3).
    /// Does NOT set `goal.isCompleted` (Pitfall 2).
    ///
    /// Injects a fire-and-forget GoalGlimpse upsert to CloudKit when username is non-empty (D-01).
    func addCheckIn(for goal: Goal, context: ModelContext, username: String = "", colorHex: String = "") {
        // Same-day dedup guard (T-18-02-02, Pitfall 3)
        let alreadyCheckedInToday = goal.completionEvents?.contains { event in
            Calendar.current.isDateInToday(event.completedAt ?? .distantPast)
        } ?? false
        guard !alreadyCheckedInToday else { return }

        let event = CompletionEvent()
        event.completedAt = Date()
        event.tierRawValue = goal.tierRawValue
        context.insert(event)
        event.goal = goal

        // MILE-04: Per-goal streak milestone detection.
        // currentStreak reads goal.completionEvents which now includes the just-inserted event
        // (SwiftData updates the relationship graph synchronously on @MainActor).
        let goalStreak = StreakEngine.currentStreak(
            from: goal.completionEvents ?? [],
            frozenDates: freezeService.frozenDates
        )
        for threshold in StreakMilestoneGate.goalStreakThresholds {
            if goalStreak >= threshold
                && goalStreak - 1 < threshold
                && !StreakMilestoneGate.hasShown(goalID: goal.id, threshold: threshold) {
                pendingGoalMilestone = (goalID: goal.id, threshold: threshold)
                break
            }
        }

        // MILE-06: Auto-completion detection.
        // Fires when cumulative check-ins reach the goal's durationDays and the goal is not
        // yet marked permanently complete. View layer sets goal.isCompleted after showing UI.
        if let duration = goal.durationDays,
           duration > 0,
           (goal.completionEvents?.count ?? 0) >= duration,
           goal.isCompleted == false {
            pendingGoalCompletion = goal.id
        }

        // Keep notifications and widgets fresh after the check-in
        rescheduleNotification(context: context)
        reloadWidgetTimelines()

        // MILE-02: Cancel the global 7 PM streak-at-risk nudge after a successful check-in.
        // Fire-and-forget — cancellation is best-effort (T-23-04-04 mitigation).
        Task { await NotificationScheduler.shared.cancelGlobalStreakAtRiskNudge() }

        // Fire-and-forget GoalGlimpse upsert (D-01 / COMM-01).
        // Progress percent = completionEvents count / durationDays (clamped 0–100).
        // If durationDays is nil or zero, progressPercent defaults to 0.
        if !username.isEmpty {
            let completionCount = (goal.completionEvents?.count ?? 0) + 1  // +1 for the just-inserted event
            let durationDays = goal.durationDays ?? 0
            let progressPercent: Int = durationDays > 0
                ? min(100, (completionCount * 100) / durationDays)
                : 0
            Task {
                await CommunityService.writeGlimpse(
                    username: username,
                    goalTitle: goal.title ?? "",
                    progressPercent: progressPercent,
                    authorColorHex: colorHex
                )
            }
        }

        // Phase 22 (D-08, D-12): fire-and-forget profile republish and public goal sync
        // after each check-in so viewers see refreshed streak and goal progress.
        // Both Tasks are independent and do NOT await each other (Pitfall 7).

        // Task A: republish profile with refreshed streakLength (D-08).
        Task {
            var profileDesc = FetchDescriptor<UserProfile>()
            profileDesc.fetchLimit = 1
            guard let userProfile = (try? context.fetch(profileDesc))?.first else { return }
            // Respect the isPublic consent toggle (T-22-04-05).
            guard userProfile.isPublic == true else { return }
            let profileUsername = userProfile.username ?? ""
            guard !profileUsername.isEmpty else { return }

            let existingRecordID: String? = userProfile.cloudKitPublicRecordID
                ?? UserDefaults.standard.string(forKey: "vg_appleUserID")

            let allGoals = (try? context.fetch(FetchDescriptor<Goal>())) ?? []
            let allEvents = allGoals.compactMap { $0.completionEvents }.flatMap { $0 }
            let streakLength = StreakEngine.currentStreak(from: allEvents)
            let goalCount = allGoals.filter { $0.isPublic == true }.count

            // motto: nil — check-in republish updates streak/count only; motto updated at save.
            try? await ProfileSharingService.publishProfile(
                displayName: nil,
                avatarColorHex: nil,
                username: profileUsername,
                existingRecordID: existingRecordID,
                streakLength: streakLength,
                goalCount: goalCount,
                motto: nil
            )
        }

        // Task B: sync progressPercent on all owned public goals (D-12).
        Task {
            let allGoals = (try? context.fetch(FetchDescriptor<Goal>())) ?? []
            await PublicGoalService.syncOwnedPublicGoals(goals: allGoals)
        }
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
        reloadWidgetTimelines()
    }

    // MARK: - Input-based CRUD (wizard path)

    @discardableResult
    func addGoal(input: GoalInput, context: ModelContext) throws -> Goal {
        let cleanTitle = sanitize(input.title)
        try validate(title: cleanTitle, description: "", inspiration: "")

        let goal = Goal(title: cleanTitle, tier: input.tier)
        goal.category     = input.category.rawValue
        goal.frequency    = input.frequency.rawValue
        goal.reminderTime = input.reminderTime
        goal.isPublic     = !input.isPrivate
        goal.startDate    = input.startDate
        goal.durationDays = input.durationDays

        context.insert(goal)
        rescheduleNotification(context: context)
        reloadWidgetTimelines()

        if input.reminderTime != nil {
            Task { await NotificationScheduler.shared.schedulePerGoal(goal) }
        }
        return goal
    }

    func updateGoal(_ goal: Goal, input: GoalInput, context: ModelContext) throws {
        let cleanTitle = sanitize(input.title)
        try validate(title: cleanTitle, description: "", inspiration: "")

        goal.title     = cleanTitle
        goal.tier      = input.tier
        goal.category  = input.category.rawValue
        goal.frequency = input.frequency.rawValue
        goal.isPublic  = !input.isPrivate
        goal.startDate = input.startDate

        NotificationScheduler.shared.cancelPerGoalNotification(for: goal.id)
        goal.reminderTime = input.reminderTime
        if input.reminderTime != nil {
            Task { await NotificationScheduler.shared.schedulePerGoal(goal) }
        }

        rescheduleNotification(context: context)
        reloadWidgetTimelines()
    }

    func delete(goal: Goal, context: ModelContext) {
        context.delete(goal)
        rescheduleNotification(context: context)
        reloadWidgetTimelines()
    }

    /// Updates the per-goal public/private flag and persists (D-08, D-09, PROF-10).
    /// Reloads widget timelines so the public goals count reflects on home screen widgets.
    func updateGoalPublicStatus(goal: Goal, isPublic: Bool, context: ModelContext) {
        goal.isPublic = isPublic
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Widget Reload

    /// Signals WidgetKit to refresh all widget timelines (D-06, WIDGET-05).
    /// Called after every goal mutation so widgets reflect current data.
    private func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Notification Rescheduling

    /// Reschedules the daily notification with current active goals (NOTIF-03).
    /// Called after every goal mutation to keep the notification body current (T-03-10).
    func rescheduleNotification(context: ModelContext) {
        // #Predicate requires stored-property key paths — use isCompleted, NOT the computed wrapper `completed`.
        let descriptor = FetchDescriptor<Goal>(predicate: #Predicate { !$0.isCompleted })
        let activeGoals = (try? context.fetch(descriptor)) ?? []
        Task {
            await NotificationScheduler.shared.reschedule(activeGoals: activeGoals)
        }
    }

    // MARK: - Stats (Phase 15 — UIADD-02)

    func earnedBadgeCount(from challenges: [UserChallenge]) -> Int {
        challenges.reduce(0) { total, challenge in
            guard let json = challenge.earnedBadgeSymbolsJSON,
                  let data = json.data(using: .utf8),
                  let symbols = try? JSONDecoder().decode([String].self, from: data)
            else { return total }
            return total + symbols.count
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
