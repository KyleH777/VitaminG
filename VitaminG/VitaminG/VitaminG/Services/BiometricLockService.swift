import Foundation
import LocalAuthentication
import Observation

@MainActor
@Observable
final class BiometricLockService {
    static let shared = BiometricLockService()

    private let enabledKey = "vg_biometric_lock_enabled"

    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: enabledKey) }
    }

    private(set) var isLocked: Bool = false

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
    }

    func lockIfEnabled() {
        if isEnabled {
            isLocked = true
        }
    }

    #if DEBUG
    func resetForTesting() {
        isLocked = false
        isEnabled = false
        UserDefaults.standard.removeObject(forKey: enabledKey)
    }
    #endif

    func authenticate() async {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isLocked = false
            return
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock Vitamin G"
            )
            if success {
                isLocked = false
                SecurityAuditLog.shared.log(AuditEvent(eventType: .biometricUnlock))
            }
        } catch {
            SecurityAuditLog.shared.log(
                AuditEvent(eventType: .biometricFailed,
                           metadata: ["error": error.localizedDescription])
            )
        }
    }
}
