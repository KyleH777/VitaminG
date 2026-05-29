import Foundation

// MARK: - NotificationPreferences

/// Single source of truth for notification time UserDefaults keys and App Group suite name.
/// Eliminates duplicated string literals across SettingsView, NotificationScheduler, and widget providers.
enum NotificationPreferences {
    static let suiteName = "group.com.kyleharrington.VitaminG"

    static let hourKey   = "notificationHour"
    static let minuteKey = "notificationMinute"

    static let defaultHour   = 8
    static let defaultMinute = 0

    /// Reads the stored notification hour, falling back to default (8 AM).
    static var hour: Int {
        if UserDefaults.standard.object(forKey: hourKey) != nil {
            return UserDefaults.standard.integer(forKey: hourKey)
        }
        return defaultHour
    }

    /// Reads the stored notification minute, falling back to default (:00).
    static var minute: Int {
        if UserDefaults.standard.object(forKey: minuteKey) != nil {
            return UserDefaults.standard.integer(forKey: minuteKey)
        }
        return defaultMinute
    }

    /// Persists notification time to both standard and App Group UserDefaults.
    static func save(hour: Int, minute: Int) {
        UserDefaults.standard.set(hour, forKey: hourKey)
        UserDefaults.standard.set(minute, forKey: minuteKey)

        let shared = UserDefaults(suiteName: suiteName)
        shared?.set(hour, forKey: hourKey)
        shared?.set(minute, forKey: minuteKey)
    }

    /// Reads notification time from the App Group suite (for widget use).
    static func sharedHour() -> Int {
        let shared = UserDefaults(suiteName: suiteName)
        return shared?.object(forKey: hourKey) as? Int ?? defaultHour
    }

    static func sharedMinute() -> Int {
        let shared = UserDefaults(suiteName: suiteName)
        return shared?.object(forKey: minuteKey) as? Int ?? defaultMinute
    }

    // MARK: - Win Reminder (Phase 11, D-12)

    static let winHourKey   = "winNotificationHour"
    static let winMinuteKey = "winNotificationMinute"

    /// Default win reminder at 8:00 PM (D-12) — distinct from 8:00 AM goal reminder.
    static let defaultWinHour   = 20
    static let defaultWinMinute = 0

    /// Reads the stored win reminder hour, falling back to default (8 PM).
    static var winHour: Int {
        if UserDefaults.standard.object(forKey: winHourKey) != nil {
            return UserDefaults.standard.integer(forKey: winHourKey)
        }
        return defaultWinHour
    }

    /// Reads the stored win reminder minute, falling back to default (:00).
    static var winMinute: Int {
        if UserDefaults.standard.object(forKey: winMinuteKey) != nil {
            return UserDefaults.standard.integer(forKey: winMinuteKey)
        }
        return defaultWinMinute
    }

    /// Persists win reminder time to both standard and App Group UserDefaults.
    static func saveWinTime(hour: Int, minute: Int) {
        UserDefaults.standard.set(hour, forKey: winHourKey)
        UserDefaults.standard.set(minute, forKey: winMinuteKey)
        let shared = UserDefaults(suiteName: suiteName)
        shared?.set(hour, forKey: winHourKey)
        shared?.set(minute, forKey: winMinuteKey)
    }

    // MARK: - App Group Accessors (Win Reminder)

    /// Reads the win reminder hour from the App Group suite (for widget use).
    /// IN-02: Mirrors `sharedHour()` so a future widget reading win-reminder time
    /// has a symmetric API and avoids copy-paste errors against the wrong key.
    static func sharedWinHour() -> Int {
        let shared = UserDefaults(suiteName: suiteName)
        return shared?.object(forKey: winHourKey) as? Int ?? defaultWinHour
    }

    /// Reads the win reminder minute from the App Group suite (for widget use).
    /// IN-02: Mirrors `sharedMinute()` for symmetry.
    static func sharedWinMinute() -> Int {
        let shared = UserDefaults(suiteName: suiteName)
        return shared?.object(forKey: winMinuteKey) as? Int ?? defaultWinMinute
    }

    // MARK: - Check-In Hour History (Phase 25, NOTIF-03, D-08)

    /// UserDefaults key for the rolling check-in hour history array.
    /// Written to the App Group suite only — widgets and Watch may read it.
    static let checkInHourHistoryKey = "checkInHourHistory"

    /// UserDefaults key for the permanent nudge-suggestion-dismissed flag (D-13).
    static let nudgeSuggestionDismissedKey = "nudgeSuggestionDismissed"

    /// Appends `hour` to the rolling check-in hour history in the App Group suite.
    /// Maintains a maximum of 14 entries via FIFO eviction (D-08).
    /// Written to the App Group suite only — do NOT mirror to UserDefaults.standard (Pitfall 6).
    static func appendCheckInHour(_ hour: Int) {
        let shared = UserDefaults(suiteName: suiteName)
        var history = (shared?.array(forKey: checkInHourHistoryKey) as? [Int]) ?? []
        history.append(hour)
        if history.count > 14 {
            history.removeFirst(history.count - 14)
        }
        shared?.set(history, forKey: checkInHourHistoryKey)
    }

    /// Returns the stored check-in hour history from the App Group suite.
    /// Returns an empty array when the key is absent or the value is not `[Int]`.
    static func checkInHourHistory() -> [Int] {
        let shared = UserDefaults(suiteName: suiteName)
        return (shared?.array(forKey: checkInHourHistoryKey) as? [Int]) ?? []
    }

    /// Computes the modal (most frequently occurring) hour from check-in history.
    ///
    /// Security mitigation (T-25-01-01): out-of-range values (< 0 or > 23) are filtered
    /// before mode computation so tampered UserDefaults values cannot influence the result.
    ///
    /// Tie-breaking: when two hours appear equally often, the one with the earliest
    /// first-occurrence index in the filtered history wins (D-10, Claude's Discretion).
    ///
    /// - Returns: the modal hour (0–23), or `nil` if history is empty after filtering.
    static func modalCheckInHour() -> Int? {
        let history = checkInHourHistory().filter { $0 >= 0 && $0 <= 23 }
        guard !history.isEmpty else { return nil }

        var counts: [Int: Int] = [:]
        for hour in history {
            counts[hour, default: 0] += 1
        }

        guard let maxCount = counts.values.max() else { return nil }

        // Among all hours tied at maxCount, pick the one whose first occurrence is earliest.
        let tiedHours = counts.filter { $0.value == maxCount }.map { $0.key }
        return tiedHours.min { lhs, rhs in
            (history.firstIndex(of: lhs) ?? Int.max) < (history.firstIndex(of: rhs) ?? Int.max)
        }
    }

    // MARK: - Nudge Suggestion Dismissed Flag (Phase 25, NOTIF-03, D-13)

    /// Whether the nudge-time suggestion banner has been permanently dismissed.
    /// Read via `.bool(forKey:)` so absent or type-mismatched values safely return `false`
    /// (T-25-01-02 Tampering mitigation).
    static var nudgeSuggestionDismissed: Bool {
        UserDefaults(suiteName: suiteName)?.bool(forKey: nudgeSuggestionDismissedKey) ?? false
    }

    /// Permanently marks the nudge suggestion as dismissed via the App Group suite.
    /// After this call, `nudgeSuggestionDismissed` returns `true` and the banner
    /// never reappears (D-13).
    static func markNudgeSuggestionDismissed() {
        UserDefaults(suiteName: suiteName)?.set(true, forKey: nudgeSuggestionDismissedKey)
    }
}
