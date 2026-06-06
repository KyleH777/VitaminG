import Foundation
import WatchConnectivity
import SwiftData
import WidgetKit

// MARK: - WatchSessionManager

/// iOS-side WCSession singleton that pushes WatchSnapshot payloads to the paired Watch
/// via `WCSession.updateApplicationContext` (last-writer-wins snapshot delivery, per RESEARCH.md Pattern 1),
/// and receives Watch→iPhone check-in relays via `transferUserInfo` (WATCH-03).
///
/// Design constraints (WATCH-02 / WATCH-03):
/// - Must inherit from NSObject because WCSessionDelegate extends NSObjectProtocol
/// - `session.delegate` must be set BEFORE `activate()` is called
/// - iOS-only methods `sessionDidBecomeInactive` / `sessionDidDeactivate` wrapped in `#if os(iOS)`
/// - `pushSnapshot` guards on `activationState == .activated` before calling updateApplicationContext
/// - Error logging via `#if DEBUG print("[WatchSessionManager] ...")` pattern
/// - Wave 4 (Plan 27-05): `didReceiveUserInfo` delegates to `handleCheckIn` via DispatchQueue.main.async
///
/// Threat mitigation:
/// - T-27-02-03: updateApplicationContext call wrapped in do/catch; WCSession unavailability never crashes app
/// - T-27-05-02: UUID(uuidString:) guard returns nil on malformed goalId — handleCheckIn returns early
/// - T-27-05-04: session(_:didReceiveUserInfo:) dispatches to MainActor via DispatchQueue.main.async (Pitfall 4)
final class WatchSessionManager: NSObject, WCSessionDelegate {

    // MARK: - Singleton

    static let shared = WatchSessionManager()
    private override init() { super.init() }

    // MARK: - Closure Injection Seams (WATCH-03)

    /// Injected by VitaminGApp.init() after ModelContainer creation.
    /// Called on @MainActor by handleCheckIn with the parsed UUID.
    /// Tests replace this with a recording stub.
    var onCheckIn: ((UUID) -> Void)?

    /// Side-effect seam: cancels the global streak-at-risk nudge after a check-in.
    /// Default: calls the production NotificationScheduler path (same as GoalViewModel.addCheckIn).
    /// Idempotent — addCheckIn also calls this internally.
    /// Tests replace this with a recording stub to avoid scheduling real notifications.
    var cancelStreakAtRiskNudge: (() -> Void)? = {
        Task { await NotificationScheduler.shared.cancelGlobalStreakAtRiskNudge() }
    }

    /// Side-effect seam: reloads all WidgetKit timelines after a check-in.
    /// Default: calls the production WidgetCenter path (same as GoalViewModel.addCheckIn).
    /// Idempotent — addCheckIn also calls this internally.
    /// Tests replace this with a recording stub to avoid real WidgetCenter calls.
    var reloadWidgetTimelines: (() -> Void)? = {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Activation

    /// Activates the WCSession on the iOS side. Safe to call multiple times — idempotent.
    /// Delegates `session.delegate = self` before `activate()` per WCSession contract.
    /// Guards on `WCSession.isSupported()` so this is a no-op on unsupported devices.
    func activate() {
        guard WCSession.isSupported() else {
            #if DEBUG
            print("[WatchSessionManager] WCSession not supported on this device — skipping activation")
            #endif
            return
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Snapshot Push

    /// Encodes a WatchSnapshot and pushes it to the paired Watch via `updateApplicationContext`.
    ///
    /// Only pushes when `activationState == .activated` — silently skips if WCSession is not
    /// yet activated (e.g., activation in progress at app launch). Callers retry naturally on
    /// subsequent mutations.
    ///
    /// - Parameters:
    ///   - goals: All Goal records (used to build the snapshot via WatchSnapshot.build)
    ///   - events: All CompletionEvent records (for streak computation)
    ///   - context: ModelContext — used by WatchSnapshot.build for active-goal selection
    func pushSnapshot(goals: [Goal], events: [CompletionEvent], context: ModelContext) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else {
            #if DEBUG
            print("[WatchSessionManager] Skipping pushSnapshot — WCSession not activated")
            #endif
            return
        }

        let snapshot = WatchSnapshot.build(goals: goals, events: events)

        do {
            let data = try JSONEncoder().encode(snapshot)
            // T-27-02-03: wrap updateApplicationContext in do/catch; never crash on WCSession error
            do {
                try WCSession.default.updateApplicationContext(["snapshot": data])
                #if DEBUG
                print("[WatchSessionManager] Pushed snapshot: streak=\(snapshot.globalStreak), hasCheckedIn=\(snapshot.hasCheckedInToday)")
                #endif
            } catch {
                #if DEBUG
                print("[WatchSessionManager] updateApplicationContext failed: \(error)")
                #endif
            }
        } catch {
            #if DEBUG
            print("[WatchSessionManager] JSONEncoder failed to encode WatchSnapshot: \(error)")
            #endif
        }
    }

    // MARK: - WCSessionDelegate

    /// Called when the WCSession activation completes (both iOS and watchOS).
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        #if DEBUG
        if let error = error {
            print("[WatchSessionManager] Activation failed: \(error)")
        } else {
            print("[WatchSessionManager] Activation completed: \(activationState.rawValue)")
        }
        #endif
    }

    /// Receive check-in relay from Watch (WATCH-03).
    /// The WCSession delegate fires on a NON-MAIN background serial queue (RESEARCH.md Pitfall 4).
    /// GoalViewModel is @MainActor — MUST dispatch to main actor before any SwiftData access.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.handleCheckIn(userInfo: userInfo)
        }
    }

    // MARK: - Check-In Handler (WATCH-03)

    /// Validates a transferUserInfo payload and invokes the injected check-in closure.
    ///
    /// Must be called on @MainActor (either via DispatchQueue.main.async from the delegate,
    /// or directly from @MainActor test code).
    ///
    /// Validation (T-27-05-02 mitigation):
    /// - Payload must have `action == "checkIn"`
    /// - Payload must have a parseable UUID string for `goalId`
    /// - Any validation failure: DEBUG log + early return; no side effects
    ///
    /// Side effects on valid payload (both are idempotent):
    /// - `onCheckIn?(goalId)` — wired to GoalViewModel.addCheckIn in VitaminGApp
    /// - `cancelStreakAtRiskNudge?()` — idempotent; addCheckIn also calls this internally
    /// - `reloadWidgetTimelines?()` — idempotent; addCheckIn also calls this internally
    @MainActor func handleCheckIn(userInfo: [String: Any]) {
        // Validate action field (T-27-05-02)
        guard let action = userInfo["action"] as? String, action == "checkIn" else {
            #if DEBUG
            print("[WatchSessionManager] handleCheckIn: ignoring — missing or wrong action: \(userInfo["action"] as? String ?? "(nil)")")
            #endif
            return
        }

        // Validate goalId as parseable UUID (T-27-05-02)
        guard let idString = userInfo["goalId"] as? String,
              let goalId = UUID(uuidString: idString) else {
            #if DEBUG
            print("[WatchSessionManager] handleCheckIn: ignoring — missing or invalid goalId: \(userInfo["goalId"] as? String ?? "(nil)")")
            #endif
            return
        }

        // Invoke injected check-in closure (wired to GoalViewModel.addCheckIn in VitaminGApp).
        onCheckIn?(goalId)

        // Defensive side effects — idempotent; addCheckIn also calls these internally.
        // If onCheckIn fails silently (e.g., goal not found), cancel/reload still happen.
        // Comment: Idempotent — addCheckIn also calls these internally.
        cancelStreakAtRiskNudge?()
        reloadWidgetTimelines?()
    }

    // MARK: - iOS-Only Lifecycle (watchOS does NOT have these methods)

    #if os(iOS)
    /// Called when the iOS-side session becomes inactive (e.g., user switches paired Watch).
    func sessionDidBecomeInactive(_ session: WCSession) {
        // No action required — watchOS handles re-pairing
    }

    /// Called when the iOS-side session fully deactivates after becoming inactive.
    /// Re-activate immediately so the new Watch pair is ready.
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
