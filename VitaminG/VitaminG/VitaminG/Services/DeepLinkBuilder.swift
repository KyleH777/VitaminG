import Foundation

/// Builds deep link URLs for profile sharing.
/// Phase 7 only generates links — incoming deep link parsing is deferred to a future phase.
/// Per D-07: URL scheme is vitaming://profile/<recordID>.
enum DeepLinkBuilder {
    static let scheme = "vitaming"

    /// Returns a vitaming://profile/<recordID> URL, or nil if recordID is nil/empty.
    static func profileURL(recordID: String?) -> URL? {
        guard let recordID, !recordID.isEmpty else { return nil }
        return URL(string: "\(scheme)://profile/\(recordID)")
    }
}
