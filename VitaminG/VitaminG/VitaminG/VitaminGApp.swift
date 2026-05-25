import SwiftUI
import SwiftData
import UserNotifications
import StoreKit

@main
struct VitaminGApp: App {
    let container: ModelContainer
    /// Stored as a property so AppRouter identity is stable across the app lifecycle.
    /// NotificationDelegate holds a reference to it for deep-link routing on notification tap.
    let router: AppRouter
    /// Stored to prevent deallocation — UNUserNotificationCenter holds a weak delegate reference.
    let notificationDelegate: NotificationDelegate
    /// Stored as a `let` property so the Task is never deallocated (D-08, T-19-02-04).
    /// A local variable would be released when `init()` returns, stopping the listener.
    private let transactionUpdatesTask: Task<Void, Never>
    private let biometricService = BiometricLockService.shared

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

            // initializeCloudKitSchema disabled — CloudKit schema already promoted to Production.
            // Re-enable only when testing schema changes with a paid developer team in Xcode.
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        // Step 4: Install a lifetime-scoped StoreKit Transaction.updates listener (D-08, MON-03).
        // Must be assigned to a stored `let` property — local vars are deallocated after init()
        // and stop processing the queue (T-19-02-04 / Anti-Pattern in 19-RESEARCH.md).
        // T-19-02-01: Switch on VerificationResult — only call finish() for .verified transactions;
        // silently discard .unverified (forged/tampered) — never deliver an unverified transaction.
        transactionUpdatesTask = Task.detached {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    // Consumable tip — no entitlement to grant; finishing clears the queue (D-08).
                    await transaction.finish()
                case .unverified:
                    // Discard — never act on an unverified (potentially tampered) transaction (T-19-02-01).
                    break
                }
            }
        }
    }

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("vg_colorScheme") private var colorSchemePref: ColorSchemePreference = .system
    @Environment(\.scenePhase) private var scenePhase

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
            // SET-04: Apply the user's appearance preference app-wide at the WindowGroup root.
            // Must be on this Group (not ContentView/OnboardingView) to recolor tab bar and
            // presented sheets (D-11, 19-RESEARCH.md Pitfall 3). nil = .system (OS decides).
            .preferredColorScheme(colorSchemePref.colorScheme)
            .task {
                SecurityAuditLog.shared.log(AuditEvent(eventType: .appLaunch))
                // Schedule win reminder on launch (Phase 11, D-12)
                // CR-01: Guard on authorization status — mirror SettingsView pattern.
                // Calling UNUserNotificationCenter.add without permission is a no-op on the
                // notification but the remove-before-add inside scheduleWinReminder still
                // executes, which is wasted work and obscures intent.
                let isGranted = await NotificationScheduler.shared.isAuthorized()
                if isGranted {
                    await NotificationScheduler.shared.rescheduleWinReminder()
                    // Reschedule daily reminder so existing users receive updated notification
                    // copy from Plan 05 (D-16) without needing to open Settings (OQ-3).
                    // Passing [] is intentional — picks up new rotating message; top-goal title
                    // refreshes next time SettingsView/GoalViewModel calls reschedule with live goals.
                    await NotificationScheduler.shared.reschedule(activeGoals: [])
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
            .fullScreenCover(isPresented: Binding(
                get: { biometricService.isLocked },
                set: { _ in }
            )) {
                LockScreen()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background || newPhase == .inactive {
                    biometricService.lockIfEnabled()
                }
            }
        }
    }
}
