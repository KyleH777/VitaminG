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

        // Step 2: Wire NotificationDelegate with deep-link handler (NOTIF-07).
        // Set as delegate BEFORE container creation — ensures taps during launch are handled.
        let delegate = NotificationDelegate { deepLink in
            if deepLink == "goalList" {
                // T-03-09: Only act on known "goalList" value; unknown values are ignored by NotificationDelegate
                appRouter.popToRoot()
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
                await NotificationScheduler.shared.rescheduleWinReminder()
            }
            .onOpenURL { url in
                // D-08, D-09: Parse vitaming://profile/<recordID>
                if let recordID = DeepLinkParser.recordID(from: url) {
                    router.pendingPublicProfileRecordID = recordID
                }
            }
        }
    }
}
