import Foundation
import WatchConnectivity
import SwiftData

// MARK: - WatchSessionManager

/// iOS-side WCSession singleton that pushes WatchSnapshot payloads to the paired Watch
/// via `WCSession.updateApplicationContext` (last-writer-wins snapshot delivery, per RESEARCH.md Pattern 1).
///
/// Design constraints (WATCH-02):
/// - Must inherit from NSObject because WCSessionDelegate extends NSObjectProtocol
/// - `session.delegate` must be set BEFORE `activate()` is called
/// - iOS-only methods `sessionDidBecomeInactive` / `sessionDidDeactivate` wrapped in `#if os(iOS)`
/// - `pushSnapshot` guards on `activationState == .activated` before calling updateApplicationContext
/// - Error logging via `#if DEBUG print("[WatchSessionManager] ...")` pattern
/// - Wave 4 (Plan 27-05) wires the `didReceiveUserInfo` handler; body is empty here
///
/// Threat mitigation:
/// - T-27-02-03: updateApplicationContext call wrapped in do/catch; WCSession unavailability never crashes app
final class WatchSessionManager: NSObject, WCSessionDelegate {

    // MARK: - Singleton

    static let shared = WatchSessionManager()
    private override init() { super.init() }

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
    ///   - context: ModelContext — retained for future Wave 4 receive handler (not used in push path)
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

    /// Receive check-in relay from Watch (Wave 4 — Plan 27-05 fills in the body).
    /// The WCSession delegate fires on a non-main serial background queue.
    /// GoalViewModel is @MainActor — DispatchQueue.main.async is required before any SwiftData access.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        // TODO(Plan 27-05): Dispatch to main actor, parse payload, call GoalViewModel.addCheckIn,
        // reload widget timelines, cancel streak-at-risk notification, push updated snapshot.
        // DispatchQueue.main.async { [weak self] in self?.handleCheckIn(userInfo: userInfo) }
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
