import SwiftData
import Foundation
import Observation

// MARK: - CheckInError

/// Errors thrown by ChallengeViewModel.recordCheckIn.
enum CheckInError: Error, Equatable {
    /// A check-in for today already exists in the store (one-per-day enforcement, CHAL-03).
    case alreadyCheckedInToday
    /// The multiStep payload note exceeded the 500-character limit after sanitization (T-13-07).
    case noteTooLong
}

// MARK: - CheckInPayload

/// Type-blind value carrier consumed by recordCheckIn (CHAL-07).
///
/// The engine NEVER inspects ChallengeTemplate.checkInType — the payload itself
/// carries the dispatch logic in `apply(to:)`. This design prevents per-type
/// branching in ChallengeViewModel (no `switch checkInType`, no `if checkInType ==`).
enum CheckInPayload {
    case boolean(Bool)
    case numeric(Double)
    case multiStep(note: String, numericValue: Double?)

    /// Applies the payload values to the given CheckIn model.
    /// This is the only place payload type is inspected — and it dispatches on its
    /// OWN cases, not on the template's checkInType string (permitted per CHAL-07).
    func apply(to checkIn: CheckIn) {
        switch self {
        case .boolean(let v):
            checkIn.payloadBool = v
        case .numeric(let v):
            checkIn.payloadNumber = v
        case .multiStep(let note, let num):
            checkIn.payloadNote = note
            checkIn.payloadNumber = num
        }
    }
}

// MARK: - ChallengeViewModel

/// @Observable ViewModel owning challenge seeding, one-per-day check-in enforcement,
/// streak updates, and milestone detection.
///
/// Architecture constraints:
/// - @MainActor: SwiftData ModelContext must be accessed on the main actor.
/// - No @Query: all fetches via context.fetch() at call-site (GoalViewModel/DailyWinsViewModel pattern).
/// - No import SwiftUI: ViewModel is presentation-free; UI lives in Wave 4 Views.
/// - No import WidgetKit: Phase 13 does not trigger widget timeline reloads (per plan CRITICAL note).
/// - Type-blind engine: no `switch checkInType` / `if checkInType ==` appears anywhere in this class.
@MainActor
@Observable
final class ChallengeViewModel {

    // MARK: - Milestone State (CHAL-10)

    /// Set when totalCheckIns crosses a milestone threshold for the first time.
    /// Consumed by the View layer (`.onChange(of: viewModel.pendingMilestone?.challengeID)`).
    /// View is responsible for clearing after consumption.
    var pendingMilestone: (challengeID: UUID, threshold: Int)? = nil

    /// In-memory dedup set keyed `"\(challengeID.uuidString)-\(threshold)"`.
    /// Prevents re-firing the same milestone within one VM lifetime.
    /// Does not persist — acceptable to re-fire on next cold launch.
    private var firedMilestones: Set<String> = []

    // MARK: - Seeding (D-02, CHAL-06; Pitfall 4 — idempotent guard)

    /// Inserts the three featured ChallengeTemplate constants into the store if not yet present.
    /// Idempotent: fetches existing featured templates first; returns immediately if any exist.
    /// Called once at app launch (or ViewModel init in a containing View).
    func seedFeaturedTemplates(context: ModelContext) {
        let descriptor = FetchDescriptor<ChallengeTemplate>(
            predicate: #Predicate<ChallengeTemplate> { $0.isFeatured == true }
        )
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        for template in ChallengeTemplate.featuredTemplates {
            context.insert(template)
        }
    }

    // MARK: - One-per-day enforcement (CHAL-03; Pitfall 5 — startOfDay range)

    /// Returns today's CheckIn for the given challenge, or nil if none exists yet.
    ///
    /// Uses a Calendar.current.startOfDay half-open range [today, tomorrow) to avoid
    /// raw Date equality comparisons that break across DST transitions (Pitfall 5).
    func todayCheckIn(for challenge: UserChallenge, context: ModelContext) -> CheckIn? {
        let today = Calendar.current.startOfDay(for: Date())
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
            return nil
        }
        let id = challenge.id
        let descriptor = FetchDescriptor<CheckIn>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.first { ci in
            guard ci.userChallenge?.id == id, let d = ci.date else { return false }
            return d >= today && d < tomorrow
        }
    }

    // MARK: - Join Challenge

    /// Creates a new UserChallenge linked to the given template and inserts it into the store.
    /// Sets startDate to now, statusRaw to "active", and computes targetEndDate from durationDays.
    @discardableResult
    func joinChallenge(template: ChallengeTemplate, context: ModelContext) -> UserChallenge {
        let challenge = UserChallenge()
        challenge.startDate = Date()
        challenge.statusRaw = "active"
        challenge.currentStreak = 0
        challenge.longestStreak = 0
        challenge.totalCheckIns = 0
        challenge.template = template
        if let days = template.durationDays {
            challenge.targetEndDate = Calendar.current.date(byAdding: .day, value: days, to: Date())
        }
        context.insert(challenge)
        return challenge
    }

    // MARK: - Abandon Challenge

    /// Marks a challenge as abandoned without deleting it or its check-in history.
    /// statusRaw = "abandoned" is the only mutation performed.
    func abandonChallenge(_ challenge: UserChallenge, context: ModelContext) {
        challenge.statusRaw = "abandoned"
    }

    // MARK: - Record Check-in (CHAL-03, CHAL-05, CHAL-07, CHAL-10)

    /// Records a new check-in for today. Throws on duplicate or invalid input.
    ///
    /// Type-blind contract (CHAL-07): this method NEVER inspects
    /// `challenge.template?.checkInType`. The payload's `apply(to:)` method handles
    /// per-type dispatch. The only `switch` in this method is on `payload`'s own cases —
    /// specifically to sanitize the `multiStep` note before applying.
    ///
    /// - Parameters:
    ///   - challenge: The active UserChallenge to check in for.
    ///   - payload: Type-blind value carrier; determines what fields are written to CheckIn.
    ///   - context: ModelContext for persistence.
    /// - Throws: `CheckInError.alreadyCheckedInToday` if a check-in already exists for today.
    ///           `CheckInError.noteTooLong` if the multiStep note exceeds 500 chars post-sanitization.
    func recordCheckIn(
        for challenge: UserChallenge,
        payload: CheckInPayload,
        context: ModelContext
    ) throws {

        // 1. One-per-day enforcement (CHAL-03).
        guard todayCheckIn(for: challenge, context: context) == nil else {
            throw CheckInError.alreadyCheckedInToday
        }

        // 2. Validate multiStep note length before any writes (T-13-07 — input sanitization).
        if case .multiStep(let rawNote, _) = payload {
            let cleaned = InputSanitizer.sanitize(rawNote)
            guard cleaned.count <= 500 else {
                throw CheckInError.noteTooLong
            }
        }

        // 3. Insert new CheckIn record.
        let checkIn = CheckIn()
        checkIn.date = Date()
        checkIn.timestamp = Date()
        checkIn.userChallenge = challenge

        // 4. Apply payload (type-blind dispatch — no `switch checkInType` in this VM).
        //    For multiStep, re-sanitize the note so the stored value is always clean.
        switch payload {
        case .multiStep(let rawNote, let num):
            let cleaned = InputSanitizer.sanitize(rawNote)
            CheckInPayload.multiStep(note: cleaned, numericValue: num).apply(to: checkIn)
        default:
            payload.apply(to: checkIn)
        }
        context.insert(checkIn)

        // 5. Update streak fields on the UserChallenge (CHAL-05).
        challenge.totalCheckIns += 1
        let existingDates = (challenge.checkIns ?? []).compactMap { $0.date }
        let allDates = existingDates + [checkIn.date].compactMap { $0 }
        challenge.currentStreak = ChallengeStreakEngine.currentStreak(from: allDates)
        challenge.longestStreak = max(challenge.longestStreak, challenge.currentStreak)

        // 6. Milestone detection (CHAL-10).
        //    Fire once per (challengeID, threshold) pair — firedMilestones guards against
        //    re-firing within the same VM lifetime.
        let milestones = challenge.template?.milestones ?? []
        let count = challenge.totalCheckIns
        if let crossed = milestones.first(where: { $0.dayThreshold == count }) {
            let key = "\(challenge.id.uuidString)-\(crossed.dayThreshold)"
            if !firedMilestones.contains(key) {
                firedMilestones.insert(key)
                pendingMilestone = (challengeID: challenge.id, threshold: crossed.dayThreshold)

                // Persist milestone history for cross-launch dedup (milestoneHistoryJSON).
                var history = decodeHistory(challenge.milestoneHistoryJSON)
                if !history.contains(crossed.dayThreshold) {
                    history.append(crossed.dayThreshold)
                    challenge.milestoneHistoryJSON = encodeHistory(history)
                }
            }
        }
    }

    // MARK: - Milestone History Persistence Helpers (T-13-06: try? only; never crash)

    /// Decodes a JSON-encoded [Int] milestone history from the model.
    private func decodeHistory(_ json: String?) -> [Int] {
        guard let json,
              let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([Int].self, from: data) else {
            return []
        }
        return decoded
    }

    /// Encodes a [Int] milestone history to a JSON string for persistence.
    private func encodeHistory(_ list: [Int]) -> String? {
        guard let data = try? JSONEncoder().encode(list),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }
}
