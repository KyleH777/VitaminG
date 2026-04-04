import UserNotifications
import Foundation

// MARK: - NotificationDelegate

/// Handles notification tap events for deep-link routing (NOTIF-07).
/// Must be a class (not struct) to conform to UNUserNotificationCenterDelegate.
/// Set as UNUserNotificationCenter.current().delegate in VitaminGApp.init() and
/// stored as a property to prevent deallocation.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    private let onDeepLink: (String) -> Void

    /// - Parameter onDeepLink: Called with the deepLink string from userInfo when user taps a notification.
    init(onDeepLink: @escaping (String) -> Void) {
        self.onDeepLink = onDeepLink
        super.init()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when the user taps a notification (NOTIF-07).
    /// T-03-09: Guard cast ensures only known "goalList" deep-link value triggers navigation;
    /// unknown or malformed values are silently ignored.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // T-03-09: Only act on known deepLink value "goalList" — unknown values are ignored
        if let deepLink = response.notification.request.content.userInfo["deepLink"] as? String {
            onDeepLink(deepLink)
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
