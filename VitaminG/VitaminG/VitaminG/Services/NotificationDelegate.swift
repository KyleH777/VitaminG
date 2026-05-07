import UserNotifications
import Foundation

// MARK: - NotificationDelegate

/// Handles notification tap events for deep-link routing (NOTIF-07, CHAL-12).
/// Must be a class (not struct) to conform to UNUserNotificationCenterDelegate.
/// Set as UNUserNotificationCenter.current().delegate in VitaminGApp.init() and
/// stored as a property to prevent deallocation.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    private let onDeepLink: (String, [AnyHashable: Any]) -> Void

    /// - Parameter onDeepLink: Called with `(deepLink, userInfo)` when the user taps a notification.
    ///   The full `userInfo` is forwarded so callers can extract additional payload values
    ///   (e.g. `userChallengeID` for challenge reminder taps — CR-01 / CHAL-12).
    init(onDeepLink: @escaping (String, [AnyHashable: Any]) -> Void) {
        self.onDeepLink = onDeepLink
        super.init()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when the user taps a notification (NOTIF-07, CHAL-12).
    /// T-03-09: Guard cast ensures only payloads carrying a String `deepLink` value
    /// trigger the callback; unknown or malformed values are silently ignored.
    /// The full userInfo is forwarded so the caller can extract additional keys
    /// (e.g. `userChallengeID` for the challenge check-in route).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let deepLink = userInfo["deepLink"] as? String {
            onDeepLink(deepLink, userInfo)
        }
        completionHandler()
    }

    /// Shows notification banner and plays sound even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
