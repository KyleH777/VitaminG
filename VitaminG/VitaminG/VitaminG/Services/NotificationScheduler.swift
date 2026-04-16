import UserNotifications
import Foundation

// MARK: - NotificationScheduler

/// Schedules a single repeating daily notification with personalized goal titles.
///
/// Design constraints (NOTIF-02 through NOTIF-07):
/// - Single identifier pattern — remove before re-add — stays within iOS 64-request cap (NOTIF-05)
/// - UNCalendarNotificationTrigger with repeats: true fires daily at user-selected time (NOTIF-02, NOTIF-04)
/// - Notification body contains up to 3 active (non-completed) goal titles (NOTIF-03)
/// - deepLink userInfo key enables deep-link routing on notification tap (NOTIF-07)
/// - UserDefaults keys "notificationHour"/"notificationMinute" store user's chosen time (NOTIF-06)
/// - Hour clamped to 0-23, minute clamped to 0-59 (T-03-08: tamper mitigation)
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    static let identifier = "com.kyleharrington.VitaminG.dailyReminder"

    private init() {}

    // MARK: - Content

    /// Builds notification content with up to 3 active goal titles (NOTIF-03).
    /// Completed goals are excluded. Nil/empty titles are skipped.
    /// Falls back to a generic message when no active goals have valid titles.
    func makeContent(activeGoals: [Goal]) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Your Vitamin G for today"

        let titles = activeGoals
            .filter { !$0.isCompleted }
            .prefix(3)
            .compactMap { $0.title }
            .filter { !$0.isEmpty }

        if titles.isEmpty {
            content.body = "Check in on your goals today."
        } else {
            content.body = titles.joined(separator: " \u{00B7} ")
        }

        content.sound = .default
        // T-03-09: userInfo deepLink value — only "goalList" is acted upon by NotificationDelegate
        content.userInfo = ["deepLink": "goalList"]
        return content
    }

    // MARK: - Scheduling

    /// Schedules a single repeating daily notification at the specified time (NOTIF-02, NOTIF-04).
    /// Removes any existing notification first to stay within the 64-request cap (NOTIF-05).
    /// Hour is clamped to 0–23 and minute to 0–59 (T-03-08: tamper mitigation).
    func schedule(hour: Int, minute: Int, activeGoals: [Goal]) async {
        let center = UNUserNotificationCenter.current()
        // Remove-before-add pattern — ensures single notification stays within iOS 64-cap
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])

        // T-03-08: Clamp hour and minute to prevent invalid DateComponents
        let validHour = max(0, min(23, hour))
        let validMinute = max(0, min(59, minute))

        var components = DateComponents()
        components.hour = validHour
        components.minute = validMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.identifier,
            content: makeContent(activeGoals: activeGoals),
            trigger: trigger
        )
        try? await center.add(request)
    }

    /// Reschedules with the user's stored time preference (NOTIF-06).
    /// Reads hour and minute from NotificationPreferences; defaults to 8:00 AM when no preference is stored.
    func reschedule(activeGoals: [Goal]) async {
        await schedule(
            hour: NotificationPreferences.hour,
            minute: NotificationPreferences.minute,
            activeGoals: activeGoals
        )
    }

    // MARK: - Authorization

    /// Checks whether the user has authorized notifications.
    func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    /// Returns the raw UNAuthorizationStatus so callers can distinguish
    /// .notDetermined / .denied / .authorized without a separate request.
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Requests notification authorization (alert, sound, badge).
    /// The system permission dialog is shown only the first time — subsequent calls
    /// when already determined return the stored value silently.
    /// - Returns: `true` if the user granted permission, `false` otherwise.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
}
