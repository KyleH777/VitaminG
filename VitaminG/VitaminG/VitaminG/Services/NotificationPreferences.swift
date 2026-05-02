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
}
