import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class ExploreViewModel {

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let gifterDate = "vg_explore_gifterDate"
        static let moodDate   = "vg_explore_moodDate"

        // Per stuck-day card: key is "vg_explore_stuckHidden_\(gift.id)"
        static func stuckHiddenKey(for giftID: String) -> String {
            "vg_explore_stuckHidden_\(giftID)"
        }
    }

    // MARK: - Daily Gifter State

    /// Whether the shake/tap animation is playing (for rotation effect on the gifter card).
    var isDispensing: Bool = false

    /// The goal shown after activation. nil = not yet activated today OR already gifted.
    var dispensedGoal: GifterGoal? = nil

    /// Tracks last activation time for debounce guard — not persisted.
    private var lastActivationDate: Date? = nil

    /// True if the gifter was activated today (one-per-day gate).
    var hasGiftedToday: Bool {
        guard let stored = UserDefaults.standard.object(forKey: Keys.gifterDate) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(stored)
    }

    // MARK: - Actions

    /// Called by ShakeDetectorView and by the "Surprise me" button. Enforces one-per-day gate.
    /// Returns the GifterGoal to add, or nil if already used today or within debounce window.
    @discardableResult
    func onGifterActivated() -> GifterGoal? {
        guard !hasGiftedToday else { return nil }
        // Debounce: ignore activations within 500 ms of each other (shake + drag overlap)
        if let last = lastActivationDate, Date().timeIntervalSince(last) < 0.5 { return nil }
        lastActivationDate = Date()
        let goal = ExploreContent.todaysGifterGoal
        dispensedGoal = goal
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
            isDispensing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.isDispensing = false
        }
        return goal
    }

    /// Call after successfully inserting the gifted goal into SwiftData.
    func markGiftedToday() {
        UserDefaults.standard.set(Date(), forKey: Keys.gifterDate)
    }

    // MARK: - Mood Prompt State

    /// Whether the user has selected a mood today (card is collapsed).
    var hasMoodSelectedToday: Bool {
        guard let stored = UserDefaults.standard.object(forKey: Keys.moodDate) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(stored)
    }

    /// Call when user taps any mood chip. Collapses the card for today.
    func selectMood(_ mood: MoodOption) {
        UserDefaults.standard.set(Date(), forKey: Keys.moodDate)
        // hasMoodSelectedToday is computed; no stored property to update.
    }

    // MARK: - Trending Now State (EXPLORE-05)

    /// Loaded async from CloudKit. Empty until fetch completes.
    var trendingGoals: [TrendingGoalItem] = []
    /// True while CloudKit fetch is in-flight.
    var isFetchingTrending: Bool = false

    /// Called from TrendingNowSection.task. Falls back to static data on CloudKit error.
    func fetchTrending() async {
        isFetchingTrending = true
        let live = await ExploreService.fetchTrendingGoals()
        trendingGoals = live.isEmpty ? ExploreContent.staticTrendingGoals : live
        isFetchingTrending = false
    }

    // MARK: - Stuck Day Gifts State (EXPLORE-06)

    /// Returns true if this gift's card should be hidden today.
    func isStuckGiftHidden(for gift: StuckDayGift) -> Bool {
        let key = Keys.stuckHiddenKey(for: gift.id)
        guard let stored = UserDefaults.standard.object(forKey: key) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(stored)
    }

    /// Call after successfully adding a stuck-day gift goal. Hides the card for today.
    func markStuckGiftHidden(_ gift: StuckDayGift) {
        let key = Keys.stuckHiddenKey(for: gift.id)
        UserDefaults.standard.set(Date(), forKey: key)
    }
}
