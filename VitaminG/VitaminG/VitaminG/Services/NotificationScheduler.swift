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
        // WR-01: Surface center.add errors instead of swallowing with try?.
        do {
            try await center.add(request)
        } catch {
            #if DEBUG
            print("[NotificationScheduler] Failed to add daily reminder request: \(error)")
            #endif
        }
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

    // MARK: - Win Reminder (Phase 11, D-11, D-13)

    /// Separate identifier for the "What's your win today?" notification (D-11).
    /// Must differ from Self.identifier to allow both notifications to coexist.
    static let winIdentifier = "com.kyleharrington.VitaminG.winReminder"

    /// Builds static win notification content (D-13).
    /// Title: "Vitamin G", Body: "What's your win today?", userInfo deepLink "wins".
    func makeWinContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Vitamin G"
        content.body = "What's your win today?"
        content.sound = .default
        content.userInfo = ["deepLink": "wins"]
        return content
    }

    /// Schedules the win reminder at the specified time.
    /// Remove-before-add pattern ensures single notification within iOS 64-request cap.
    /// Hour clamped to 0–23, minute to 0–59 (T-03-08 tamper mitigation).
    func scheduleWinReminder(hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.winIdentifier])

        let validHour   = max(0, min(23, hour))
        let validMinute = max(0, min(59, minute))

        var components = DateComponents()
        components.hour   = validHour
        components.minute = validMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.winIdentifier,
            content: makeWinContent(),
            trigger: trigger
        )
        // WR-01: Surface center.add errors instead of swallowing with try?.
        do {
            try await center.add(request)
        } catch {
            #if DEBUG
            print("[NotificationScheduler] Failed to add win reminder request: \(error)")
            #endif
        }
    }

    /// Reschedules with the user's stored win reminder time preference (D-12).
    func rescheduleWinReminder() async {
        await scheduleWinReminder(
            hour: NotificationPreferences.winHour,
            minute: NotificationPreferences.winMinute
        )
    }
}

// MARK: - Phase 13 challenge reminders (CHAL-12, D-08)

extension NotificationScheduler {

    /// Per-challenge identifier scheme: one identifier per active UserChallenge.
    /// Remove-before-add pattern preserves the iOS 64-request cap.
    static func challengeReminderIdentifier(for challengeID: UUID) -> String {
        "com.kyleharrington.VitaminG.challengeReminder.\(challengeID.uuidString)"
    }

    /// Schedule (or replace) the evening reminder for a UserChallenge at the given hour/minute.
    /// Notification userInfo carries deepLink + userChallengeID for routing on tap (D-06, D-07).
    func scheduleChallengeReminder(
        for challenge: UserChallenge,
        hour: Int,
        minute: Int
    ) async {
        let challengeID = challenge.id
        let identifier = Self.challengeReminderIdentifier(for: challengeID)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let validHour   = max(0, min(23, hour))
        let validMinute = max(0, min(59, minute))

        let content = UNMutableNotificationContent()
        content.title = "Check in on your challenge"
        content.body = challenge.template?.title ?? "Daily check-in reminder"
        content.sound = .default
        content.userInfo = [
            "deepLink": "challengeCheckIn",
            "userChallengeID": challengeID.uuidString
        ]

        var components = DateComponents()
        components.hour   = validHour
        components.minute = validMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        do {
            try await center.add(request)
        } catch {
            #if DEBUG
            print("[NotificationScheduler] Failed to add challenge reminder: \(error)")
            #endif
        }
    }

    /// Remove the pending evening reminder for a given challenge.
    /// Called when a UserChallenge is abandoned, completed, or has its reminder turned off.
    func removeChallengeReminder(for challengeID: UUID) {
        let identifier = Self.challengeReminderIdentifier(for: challengeID)
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

// MARK: - Phase 14 Notification Suite (CHAL-22, CHAL-24)

extension NotificationScheduler {

    // MARK: - Identifiers

    static func streakAtRiskIdentifier(for challengeID: UUID) -> String {
        "com.kyleharrington.VitaminG.streakAtRisk.\(challengeID.uuidString)"
    }

    static func milestoneIdentifier(for challengeID: UUID, threshold: Int) -> String {
        "com.kyleharrington.VitaminG.milestone.\(challengeID.uuidString).\(threshold)"
    }

    static func buddyPingIdentifier(for challengeID: UUID) -> String {
        "com.kyleharrington.VitaminG.buddyPing.\(challengeID.uuidString)"
    }

    // MARK: - Streak at risk (CHAL-24) — fires nightly at 20:00 if scheduled

    /// Schedules a repeating nightly reminder at 20:00 when the user hasn't checked in.
    /// Remove-before-add pattern prevents duplicate scheduling (T-14-06 tamper mitigation).
    /// Identifier embeds challenge UUID — one notification per active challenge.
    func scheduleStreakAtRiskReminder(challengeID: UUID, challengeTitle: String) async {
        let identifier = Self.streakAtRiskIdentifier(for: challengeID)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Don't lose your streak!"
        content.body = "You haven't checked in on \(challengeTitle) today. Tap to log your check-in."
        content.sound = .default
        content.userInfo = [
            "deepLink": "challengeCheckIn",
            "userChallengeID": challengeID.uuidString,
            "source": "streakAtRisk"
        ]

        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            #if DEBUG
            print("[NotificationScheduler] Failed to add streak-at-risk: \(error)")
            #endif
        }
    }

    /// Removes the streak-at-risk reminder for a given challenge.
    /// Called when the user checks in or abandons the challenge.
    func cancelStreakAtRiskReminder(challengeID: UUID) {
        let identifier = Self.streakAtRiskIdentifier(for: challengeID)
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Milestone reached (CHAL-24) — fires once, immediately

    /// Fires a one-time notification immediately (timeInterval: 1) when a milestone is reached.
    /// Identifier embeds UUID + threshold to distinguish multiple milestones on same challenge (T-14-14).
    func scheduleMilestoneNotification(
        challengeID: UUID,
        threshold: Int,
        message: String
    ) async {
        let identifier = Self.milestoneIdentifier(for: challengeID, threshold: threshold)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Milestone reached!"
        content.body = message
        content.sound = .default
        content.userInfo = [
            "deepLink": "challengeDetail",
            "userChallengeID": challengeID.uuidString,
            "source": "milestone",
            "threshold": threshold
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            #if DEBUG
            print("[NotificationScheduler] Failed to add milestone: \(error)")
            #endif
        }
    }

    // MARK: - Buddy ping (CHAL-22) — local UNUserNotification to self, fire-once

    /// Fires a one-time local notification when a buddy sends an accountability ping.
    /// Cooldown enforcement (24h) is handled by the caller (UserChallenge.canSendBuddyPing — Plan 08).
    func scheduleBuddyPing(
        challengeID: UUID,
        buddyDisplayName: String,
        challengeTitle: String
    ) async {
        let identifier = Self.buddyPingIdentifier(for: challengeID)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Your buddy is cheering for you!"
        content.body = "\(buddyDisplayName) sent you an accountability ping on \(challengeTitle)."
        content.sound = .default
        content.userInfo = [
            "deepLink": "challengeDetail",
            "userChallengeID": challengeID.uuidString,
            "source": "buddyPing"
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            #if DEBUG
            print("[NotificationScheduler] Failed to add buddy ping: \(error)")
            #endif
        }
    }
}
