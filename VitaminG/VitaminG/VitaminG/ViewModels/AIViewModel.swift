import Foundation
import Observation
import SwiftData

// MARK: - AIViewModel

/// @MainActor @Observable ViewModel bridging AIProxyService to HomeView and ExploreView.
/// Owns AI state (motivation result, suggestions, loading flags, added suggestion indices).
///
/// Design constraints:
/// - NOT a singleton: separate @State instances per view are acceptable; AIProxyService
///   UserDefaults cache deduplicates responses per day (Pitfall 3, A3).
/// - Does NOT trigger fetches from init(): callers use .task modifier (Pitfall 6).
/// - Uses AIProxyServiceProtocol injection so tests can mock without network.
/// - No @Published / ObservableObject — uses @Observable macro per CLAUDE.md.
@MainActor
@Observable
final class AIViewModel {

    // MARK: - AI State Properties

    /// The current motivation result. Defaults to .fallback so the card always shows
    /// VGQuoteBank copy before any Claude response arrives (D-03, Test 6).
    var motivationResult: MotivationResult = .fallback(VGQuoteBank.todaysQuote().text)

    /// True while a motivation fetch is in flight.
    var isLoadingMotivation: Bool = false

    /// The current list of AI goal suggestions. Defaults to staticSuggestions so the
    /// card is never empty before the first fetch (D-07, Test 5).
    var suggestions: [String] = AIProxyService.staticSuggestions

    /// Index set of suggestion rows the user has already added as goals.
    /// Reset to empty whenever a fresh suggestions fetch completes.
    var addedSuggestionIndices: Set<Int> = []

    /// True while a suggestions fetch is in flight.
    var isLoadingSuggestions: Bool = false

    // MARK: - Service

    private let service: AIProxyServiceProtocol

    // MARK: - Initializer

    /// Default: injects AIProxyService.shared (production singleton).
    /// Tests inject a mock conforming to AIProxyServiceProtocol.
    init(service: AIProxyServiceProtocol = AIProxyService.shared) {
        self.service = service
    }

    // MARK: - Computed Properties

    /// The motivation card header label per D-01.
    /// "YOUR DOSE" for live Claude copy; "TODAY'S DOSE" for VGQuoteBank fallback.
    var motivationLabel: String {
        motivationResult.isClaude ? "YOUR DOSE" : "TODAY'S DOSE"
    }

    // MARK: - Refresh Methods

    /// Fetches today's motivation if not already loading. Constructs the goal payload
    /// from WidgetDataProvider.build() — single source of truth (RESEARCH.md Architecture Map).
    ///
    /// Guard against concurrent reentry (Pitfall 3).
    func refreshMotivationIfNeeded(goals: [Goal], events: [CompletionEvent]) async {
        guard !isLoadingMotivation else { return }
        isLoadingMotivation = true
        let data = WidgetDataProvider.build(goals: goals, events: events)
        let payload: [GoalPayload] = data.tierRows.compactMap { row -> GoalPayload? in
            guard let title = row.topGoalTitle else { return nil }
            return GoalPayload(title: title, category: row.tier.rawValue)
        }
        let streak = data.globalStreak
        motivationResult = await service.fetchMotivation(goals: payload, streak: streak)
        isLoadingMotivation = false
    }

    /// Fetches today's AI suggestions if not already loading. Constructs the goal payload
    /// from WidgetDataProvider.build() — single source of truth.
    ///
    /// Resets addedSuggestionIndices on completion (new day's suggestions slate is fresh).
    func refreshSuggestionsIfNeeded(goals: [Goal], events: [CompletionEvent]) async {
        guard !isLoadingSuggestions else { return }
        isLoadingSuggestions = true
        let data = WidgetDataProvider.build(goals: goals, events: events)
        let payload: [GoalPayload] = data.tierRows.compactMap { row -> GoalPayload? in
            guard let title = row.topGoalTitle else { return nil }
            return GoalPayload(title: title, category: row.tier.rawValue)
        }
        suggestions = await service.fetchSuggestions(goals: payload)
        addedSuggestionIndices = []
        isLoadingSuggestions = false
    }
}
