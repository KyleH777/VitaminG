import Foundation
import Observation
import SwiftUI
import SwiftData

// MARK: - SearchSegment
// Declared at file scope (importable elsewhere — DiscoverOverlayView.swift Picker binding).

enum SearchSegment: Hashable, Sendable {
    case goals
    case people
}

// MARK: - DiscoverViewModel

@MainActor
@Observable
final class DiscoverViewModel {

    // MARK: - State

    var goalResults: [DiscoverGoalResult] = []
    var peopleResults: [DiscoverPersonResult] = []
    var isSearching: Bool = false
    var searchError: String? = nil
    var selectedSegment: SearchSegment = .goals

    // MARK: - Dedup (Pitfall 5)
    // Set<String> rather than [String: Date] because join is terminal in v2.0.
    // joinedGoalIDs is marked BEFORE local goal insert so rapid re-taps during
    // the brief insert window are no-ops (T-22-03-01 mitigation).

    private var joinedGoalIDs: Set<String> = []

    // MARK: - Debounce Task

    private var searchTask: Task<Void, Never>?

    // MARK: - Client-Side Rate Limiter
    // Caps search calls to 20 per 60 seconds in-session (T-22-03-05 secondary defense).
    // Does not touch UserDefaults — in-memory only.

    private var recentSearchTimes: [Date] = []

    // MARK: - Test Override Seams
    // nil in production — set in unit tests to avoid hitting CloudKit.

    /// Override for PublicGoalService.searchGoals. nil = use real service.
    var searchGoalsOverride: ((String) async throws -> [DiscoverGoalResult])? = nil

    /// Override for PublicGoalService.searchPeople. nil = use real service.
    var searchPeopleOverride: ((String) async throws -> [DiscoverPersonResult])? = nil

    /// Override for PublicGoalService.incrementParticipantCount. nil = use real service.
    var incrementParticipantCountOverride: ((String) async -> Void)? = nil

    /// Override for ProfileSharingService.writeFollow used by onFollowPerson. nil = use real service.
    /// CLAUDE.md MVVM rule: Views must not call services directly — onFollowPerson is the MVVM seam.
    var writeFollowOverride: ((String, String) async throws -> Void)? = nil

    // MARK: - Query Methods

    /// Returns true if the given goalID has already been joined in this session.
    func isJoined(goalID: String) -> Bool { joinedGoalIDs.contains(goalID) }

    // MARK: - Debounced Search

    /// Called by DiscoverOverlayView's .onChange(of: searchText).
    /// T-22-03-05 mitigation: cancels prior task + 500ms Task.sleep debounce.
    /// Empty text: clears results immediately (no debounce on clear — UX expectation).
    func onSearchTextChanged(_ newText: String) {
        searchTask?.cancel()
        guard !newText.isEmpty else {
            goalResults = []
            peopleResults = []
            isSearching = false
            searchError = nil
            return
        }

        // Client-side rate limit (20 searches per 60 seconds in-session)
        recentSearchTimes = recentSearchTimes.filter { Date().timeIntervalSince($0) < 60 }
        guard recentSearchTimes.count < 20 else {
            searchError = "Too many searches. Please slow down."
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await performSearch(newText)
        }
    }

    // MARK: - Segment Switching

    /// Switches the search segment and re-runs search with current text (no debounce on segment swap).
    func setSegment(_ segment: SearchSegment, searchText: String) {
        selectedSegment = segment
        guard !searchText.isEmpty else { return }
        Task {
            await performSearch(searchText)
        }
    }

    // MARK: - Private Search

    private func performSearch(_ text: String) async {
        do {
            switch selectedSegment {
            case .goals:
                let results: [DiscoverGoalResult]
                if let override = searchGoalsOverride {
                    results = try await override(text)
                } else {
                    results = try await PublicGoalService.searchGoals(keyword: text)
                }
                goalResults = results
            case .people:
                let results: [DiscoverPersonResult]
                if let override = searchPeopleOverride {
                    results = try await override(text)
                } else {
                    results = try await PublicGoalService.searchPeople(usernamePrefix: text)
                }
                peopleResults = results
            }
            isSearching = false
            recentSearchTimes.append(Date())
        } catch {
            // Cancellation must NOT set searchError — only real errors.
            if Task.isCancelled { return }
            searchError = "Search failed. Check your connection and try again."
            isSearching = false
        }
    }

    // MARK: - Join Goal

    /// Creates a local SwiftData Goal from a Discover result, marks joined, and fires participant count.
    /// T-22-03-01 mitigation: joinedGoalIDs.insert happens BEFORE local goal insert — rapid re-taps are no-ops.
    /// D-15: joined copies are private by default (isPublic = false).
    /// D-16: count failure must not roll back local goal (fire-and-forget).
    func joinGoal(_ result: DiscoverGoalResult, tier: GoalTier, context: ModelContext) {
        guard !isJoined(goalID: result.id) else { return }
        // Mark joined BEFORE insert so rapid re-taps are idempotent (Pitfall 5)
        joinedGoalIDs.insert(result.id)

        // Create local SwiftData Goal — D-16: always insert locally first
        let goal = Goal(title: result.title, tier: tier)
        goal.isPublic = false        // D-15: joined copies private by default
        goal.category = result.category
        goal.creationDate = Date()
        context.insert(goal)
        try? context.save()

        // Fire-and-forget participant count increment (D-16: failure must not roll back goal)
        Task {
            if let override = incrementParticipantCountOverride {
                await override(result.id)
            } else {
                await PublicGoalService.incrementParticipantCount(recordName: result.id)
            }
        }
    }

    // MARK: - Follow Person

    /// MVVM seam: called by DiscoverOverlayView when the user taps Follow on a PeopleSearchResultCard.
    /// CLAUDE.md MVVM rule: Views must not call services directly — this is the single call site.
    /// Fire-and-forget: failures are swallowed (T-22-03-07 accept — authoritative follow state
    /// surfaces when user navigates into PublicProfileView).
    func onFollowPerson(followerUsername: String, followeeUsername: String) {
        Task {
            if let override = writeFollowOverride {
                try? await override(followerUsername, followeeUsername)
            } else {
                try? await ProfileSharingService.writeFollow(
                    followerUsername: followerUsername,
                    followeeUsername: followeeUsername
                )
            }
        }
    }
}
