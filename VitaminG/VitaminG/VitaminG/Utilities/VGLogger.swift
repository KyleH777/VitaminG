import Foundation
import os

/// Centralized loggers per subsystem area (POL-01).
/// Usage: VGLog.notifications.error("Failed to add request: \(error.localizedDescription, privacy: .public)")
/// Release builds keep .error and .fault; .debug is stripped unless captured.
enum VGLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.kyleharrington.VitaminG"

    static let notifications = Logger(subsystem: subsystem, category: "notifications")
    static let cloudKit      = Logger(subsystem: subsystem, category: "cloudkit")
    static let watch         = Logger(subsystem: subsystem, category: "watch")
    static let community     = Logger(subsystem: subsystem, category: "community")
    static let general       = Logger(subsystem: subsystem, category: "general")
}
