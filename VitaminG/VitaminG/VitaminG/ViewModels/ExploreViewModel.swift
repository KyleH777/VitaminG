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
    }

    // MARK: - Daily Gifter State

    /// Whether the shake/tap animation is playing (for rotation effect on the gifter card).
    var isDispensing: Bool = false

    /// The goal shown after activation. nil = not yet activated today OR already gifted.
    var dispensedGoal: GifterGoal? = nil

    /// True if the gifter was activated today (one-per-day gate).
    var hasGiftedToday: Bool {
        guard let stored = UserDefaults.standard.object(forKey: Keys.gifterDate) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(stored)
    }

    // MARK: - Actions

    /// Called by ShakeDetectorView and by the "Surprise me" button. Enforces one-per-day gate.
    /// Returns the GifterGoal to add, or nil if already used today.
    @discardableResult
    func onGifterActivated() -> GifterGoal? {
        guard !hasGiftedToday else { return nil }
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
}
