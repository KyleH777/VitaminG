import SwiftUI
import SwiftData
import UserNotifications
import StoreKit
import os

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

        // Step 3: Guard CloudKit calls in test environments.
        // CKContainer(identifier:) crashes when the app lacks iCloud entitlements (test/simulator
        // environments without a paid team). Set no-op overrides so app bootstrap doesn't crash
        // during XCTest runs. (Rule 1 auto-fix — pre-existing crash blocking test execution.)
        if ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil {
            PublicGoalService.syncOwnedPublicGoalsOverride = { _ in }
            PublicGoalService.writePublicGoalOverride = { _, _ in return "" }
        }

        // Step 4: Initialize SwiftData container.
        do {
            container = try ModelContainerFactory.makeContainer()

            // initializeCloudKitSchema disabled — CloudKit schema already promoted to Production.
            // Re-enable only when testing schema changes with a paid developer team in Xcode.
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        // Step 4b: Wire WatchSessionManager check-in relay (WATCH-03).
        // Assign onCheckIn BEFORE activate() so any queued userInfo is routed on delivery.
        // The closure captures `container` (not WatchSessionManager) to avoid circular dependency.
        // Closure runs on @MainActor (handleCheckIn is @MainActor); no additional dispatch needed.
        let watchContainer = container
        WatchSessionManager.shared.onCheckIn = { goalId in
            let context = watchContainer.mainContext
            // Predicate fetch — filters at the store level instead of loading all goals.
            let id = goalId
            var descriptor = FetchDescriptor<Goal>(
                predicate: #Predicate { $0.id == id }
            )
            descriptor.fetchLimit = 1
            guard let goal = ((try? context.fetch(descriptor)) ?? []).first else {
                VGLog.watch.debug("WCSession check-in: goal \(goalId.uuidString, privacy: .public) not found")
                return
            }
            // Call the same addCheckIn path used by iOS-side and widget check-ins (STATE.md locked decision).
            // Empty username/colorHex — Watch check-in does not write GoalGlimpse (per addCheckIn line 227).
            let goalVM = GoalViewModel()
            goalVM.addCheckIn(for: goal, context: context)
        }
        // Activate WCSession after closure is wired so delivery of any pending userInfo is handled.
        WatchSessionManager.shared.activate()

        // Step 5: Install a lifetime-scoped StoreKit Transaction.updates listener (D-08, MON-03).
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
                    await NotificationScheduler.shared.reschedule(activeGoals: [], completionEvents: [])
                    // NOTIF-04 (D-05): the 7 PM streak-at-risk one-shot is now scheduled inside reschedule()/schedule() — no separate launch call needed.
                }

                // Phase 22 (D-08, D-11, D-12): fire-and-forget refresh tasks at launch.
                // All three Tasks are wrapped in Task { } so they do NOT block the outer
                // .task body (Pitfall 7 — never await Phase 22 launch hooks directly).
                // The container.mainContext is used to read local data; access is safe on
                // @MainActor since VitaminGApp.body runs on the main actor.
                let launchContext = container.mainContext

                // Phase 22 Task A: republish profile with refreshed streakLength + goalCount (D-08).
                // T-22-04-05 privacy guard: skip entirely when user has not opted into public profile.
                Task {
                    // Fetch UserProfile to check consent and read identity fields.
                    var profileDescriptor = FetchDescriptor<UserProfile>()
                    profileDescriptor.fetchLimit = 1
                    guard let userProfile = (try? launchContext.fetch(profileDescriptor))?.first else { return }

                    // T-22-04-05: Private users must NOT republish streak/goalCount to PublicProfile.
                    guard userProfile.isPublic == true else { return }

                    // Read username from UserProfile (set during onboarding username claim).
                    let username = userProfile.username ?? ""
                    guard !username.isEmpty else { return }

                    // existingRecordID: use cloudKitPublicRecordID stored on UserProfile,
                    // falling back to vg_appleUserID (UserDefaults) as the record name key
                    // when the explicit record ID is not yet stored locally (Phase 17 pattern).
                    let existingRecordID: String? = userProfile.cloudKitPublicRecordID
                        ?? UserDefaults.standard.string(forKey: "vg_appleUserID")

                    // Fetch all goals to compute streakLength and goalCount.
                    let allGoals = (try? launchContext.fetch(FetchDescriptor<Goal>())) ?? []
                    let allEvents = allGoals.compactMap { $0.completionEvents }.flatMap { $0 }
                    let streakLength = StreakEngine.currentStreak(from: allEvents)
                    let goalCount = allGoals.filter { $0.isPublic == true }.count

                    // T-22-04-06: pass motto: nil so the launch refresh does NOT overwrite
                    // an existing motto — motto is updated only on ProfileEditSheet save.
                    _ = try? await ProfileSharingService.publishProfile(
                        displayName: nil,
                        avatarColorHex: nil,
                        username: username,
                        existingRecordID: existingRecordID,
                        streakLength: streakLength,
                        goalCount: goalCount,
                        motto: nil
                    )
                }

                // Phase 22 Task B: backfill PublicGoal records for any public goal that
                // was made public before Phase 22 shipped (D-11 — best-effort, per-goal resilient).
                Task {
                    let allGoals = (try? launchContext.fetch(FetchDescriptor<Goal>())) ?? []
                    var profileDescriptor = FetchDescriptor<UserProfile>()
                    profileDescriptor.fetchLimit = 1
                    let creatorUsername = (try? launchContext.fetch(profileDescriptor))?.first?.username ?? ""
                    guard !creatorUsername.isEmpty else { return }
                    await PublicGoalService.backfillPublicGoals(
                        goals: allGoals,
                        context: launchContext,
                        creatorUsername: creatorUsername
                    )
                }

                // Phase 22 Task C: sync progressPercent on all already-published public goals (D-12).
                Task {
                    let allGoals = (try? launchContext.fetch(FetchDescriptor<Goal>())) ?? []
                    await PublicGoalService.syncOwnedPublicGoals(goals: allGoals)
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
