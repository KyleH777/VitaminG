import Foundation
import WatchConnectivity
import WidgetKit

/// Watch-side WCSession singleton.
///
/// Activated in `VGWatchApp.init()` so the session is ready before any view renders.
/// Decodes incoming `applicationContext` snapshots into Watch App Group UserDefaults and
/// triggers a WidgetKit timeline reload so the Watch complication stays current.
///
/// CRITICAL: watchOS does NOT have `sessionDidBecomeInactive` or `sessionDidDeactivate`
/// — those methods are iOS-only (see RESEARCH.md Pitfall 6). Do not add them here.
final class WatchReceiver: NSObject, WCSessionDelegate {

    // MARK: - Singleton

    static let shared = WatchReceiver()
    private override init() { super.init() }

    // MARK: - Private

    private let suiteName = "group.com.kyleharrington.VitaminGWatch"

    // MARK: - Activation

    /// Activates the WCSession. Idempotent — safe to call multiple times.
    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        #if DEBUG
        if let error = error {
            print("[WatchReceiver] activation error: \(error)")
        } else {
            print("[WatchReceiver] activated with state: \(activationState.rawValue)")
        }
        #endif
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        processApplicationContext(applicationContext, into: UserDefaults(suiteName: suiteName))
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Testable Wrapper

    /// Decodes a WatchSnapshot from an applicationContext dictionary and writes the five
    /// `watchSnapshot_` keys to the provided UserDefaults instance.
    ///
    /// Extracted for unit testability — tests pass an ephemeral UserDefaults suite and call
    /// this method directly, bypassing WCSession entirely.
    ///
    /// - Parameters:
    ///   - applicationContext: The dictionary received from WCSession (or a test dictionary).
    ///   - defaults: The UserDefaults instance to write into. Pass `nil` to skip writing.
    func processApplicationContext(
        _ applicationContext: [String: Any],
        into defaults: UserDefaults?
    ) {
        guard let data = applicationContext["snapshot"] as? Data else { return }
        do {
            let snapshot = try JSONDecoder().decode(WatchSnapshot.self, from: data)
            writeToUserDefaults(snapshot, into: defaults)
        } catch {
            #if DEBUG
            print("[WatchReceiver] decode error: \(error)")
            #endif
        }
    }

    // MARK: - Private Helpers

    private func writeToUserDefaults(_ snapshot: WatchSnapshot, into defaults: UserDefaults?) {
        defaults?.set(snapshot.activeGoalTitle, forKey: "watchSnapshot_activeGoalTitle")
        defaults?.set(snapshot.activeGoalProgress, forKey: "watchSnapshot_activeGoalProgress")
        defaults?.set(snapshot.globalStreak, forKey: "watchSnapshot_globalStreak")
        defaults?.set(snapshot.hasCheckedInToday, forKey: "watchSnapshot_hasCheckedInToday")
        defaults?.set(snapshot.activeGoalId, forKey: "watchSnapshot_activeGoalId")
    }
}
