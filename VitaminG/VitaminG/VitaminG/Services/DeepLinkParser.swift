import Foundation

/// Parses incoming vitaming:// deep link URLs.
/// Extracted as a pure static function so URL parsing is unit-testable
/// without launching the full app or SwiftUI scene.
enum DeepLinkParser {
    /// Extracts the recordID from a vitaming://profile/<recordID> URL.
    /// Returns nil for malformed, unknown, or empty URLs — caller silently ignores nil (D-09).
    /// Security (T-10-01): guards scheme, host, and non-empty path before returning any value.
    /// The recordID is never passed to file system or SQL — it is only used to construct a CKRecord.ID.
    static func recordID(from url: URL) -> String? {
        guard url.scheme == DeepLinkBuilder.scheme,
              url.host == "profile",
              let recordID = url.pathComponents.dropFirst().first,
              !recordID.isEmpty else { return nil }
        return recordID
    }
}
