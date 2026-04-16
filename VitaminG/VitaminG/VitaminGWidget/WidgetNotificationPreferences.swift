import Foundation

// MARK: - NotificationPreferences (Widget Target)

/// Read-only copy of notification time preferences for the widget extension.
/// The widget target cannot import the main app module, so shared constants
/// are duplicated here. Only the App Group read path is needed — widgets never write.
///
/// IMPORTANT: If you change key names or defaults in the main app's
/// NotificationPreferences.swift, update this file to match.
enum NotificationPreferences {
    static let suiteName = "group.com.kyleharrington.VitaminG"

    static let hourKey   = "notificationHour"
    static let minuteKey = "notificationMinute"

    static let defaultHour   = 8
    static let defaultMinute = 0

    /// Reads notification hour from the App Group suite (widget-safe).
    static func sharedHour() -> Int {
        let shared = UserDefaults(suiteName: suiteName)
        return shared?.object(forKey: hourKey) as? Int ?? defaultHour
    }

    /// Reads notification minute from the App Group suite (widget-safe).
    static func sharedMinute() -> Int {
        let shared = UserDefaults(suiteName: suiteName)
        return shared?.object(forKey: minuteKey) as? Int ?? defaultMinute
    }
}
