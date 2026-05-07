import SwiftUI
import SwiftData
import UserNotifications

@main
struct VitaminGApp: App {
    let container: ModelContainer
    /// Stored as a property so AppRouter identity is stable across the app lifecycle.
    /// NotificationDelegate holds a reference to it for deep-link routing on notification tap.
    let router: AppRouter
    /// Stored to prevent deallocation — UNUserNotificationCenter holds a weak delegate reference.
    let notificationDelegate: NotificationDelegate

    init() {
        // Step 1: Create and store AppRouter before anything else.
        // NotificationDelegate captures router so deep-link navigation works even during launch.
        let appRouter = AppRouter()
        self.router = appRouter

        // Step 2: Wire NotificationDelegate with deep-link handler (NOTIF-07, CHAL-12).
        // Set as delegate BEFORE container creation — ensures taps during launch are handled.
        let delegate = NotificationDelegate { deepLink, userInfo in
            if deepLink == "goalList" {
                // T-03-09: Only act on known "goalList" value; unknown values are ignored.
                appRouter.popToRoot()
            } else if deepLink == "challengeCheckIn",
                      let idString = userInfo["userChallengeID"] as? String {
                // CHAL-12 / D-06: Notification tap routes to per-challenge check-in modal.
                // ContentView resolves the UUID string back to a UserChallenge via @Query
                // and presents ChallengeCheckInView as a sheet.
                appRouter.pendingChallengeCheckInID = idString
            }
        }
        self.notificationDelegate = delegate
        UNUserNotificationCenter.current().delegate = delegate

        // Step 3: Initialize SwiftData container.
        do {
            container = try ModelContainerFactory.makeContainer()

            #if DEBUG && !targetEnvironment(simulator)
            ModelContainerFactory.initializeCloudKitSchema(container: container)
            #endif
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .modelContainer(container)
            .environment(router)
            .task {
                // Schedule win reminder on launch (Phase 11, D-12)
                // CR-01: Guard on authorization status — mirror SettingsView pattern.
                // Calling UNUserNotificationCenter.add without permission is a no-op on the
                // notification but the remove-before-add inside scheduleWinReminder still
                // executes, which is wasted work and obscures intent.
                let isGranted = await NotificationScheduler.shared.isAuthorized()
                if isGranted {
                    await NotificationScheduler.shared.rescheduleWinReminder()
                }
            }
            .onOpenURL { url in
                // D-08, D-09: Parse vitaming://profile/<recordID>
                if let recordID = DeepLinkParser.recordID(from: url) {
                    router.pendingPublicProfileRecordID = recordID
                }
                // Phase 13 — D-06, D-07: Parse vitaming://challengeCheckIn/<userChallengeID>
                // Sets pendingChallengeCheckInID; ContentView sheet binding resolves UserChallenge from SwiftData.
                else if let challengeID = DeepLinkParser.challengeCheckInID(from: url) {
                    router.pendingChallengeCheckInID = challengeID
                }
            }
        }
    }
}
