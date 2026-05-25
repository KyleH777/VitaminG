import Foundation

enum AuditEventType: String, Codable {
    case appLaunch
    case biometricUnlock
    case biometricFailed
    case profileEdited
    case userBlocked
    case userUnblocked
    case followWritten
    case followRateLimitHit
    case searchRateLimitHit
}

struct AuditEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let eventType: AuditEventType
    let actorUserID: String
    let targetUserID: String?
    let metadata: [String: String]

    init(
        eventType: AuditEventType,
        targetUserID: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.eventType = eventType
        self.actorUserID = UserDefaults.standard.string(forKey: "vg_appleUserID") ?? "unknown"
        self.targetUserID = targetUserID
        self.metadata = metadata
    }
}

final class SecurityAuditLog {
    static let shared = SecurityAuditLog()

    private let maxEntries = 500
    let defaultsKey = "vg_audit_log"
    private let queue = DispatchQueue(label: "com.vg.audit", qos: .utility)

    private init() {}

    func log(_ event: AuditEvent) {
        queue.async { [self] in
            var events = loadEvents()
            events.append(event)
            if events.count > maxEntries {
                events = Array(events.suffix(maxEntries))
            }
            saveEvents(events)
        }
    }

    func recentEvents(limit: Int = 50) -> [AuditEvent] {
        queue.sync {
            Array(loadEvents().suffix(limit))
        }
    }

    func export() -> String {
        queue.sync {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            guard let data = try? encoder.encode(loadEvents()),
                  let json = String(data: data, encoding: .utf8) else { return "[]" }
            return json
        }
    }

    #if DEBUG
    func clearForTesting() {
        queue.sync {
            UserDefaults.standard.removeObject(forKey: defaultsKey)
        }
    }
    #endif

    private func loadEvents() -> [AuditEvent] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([AuditEvent].self, from: data)) ?? []
    }

    private func saveEvents(_ events: [AuditEvent]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(events) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
