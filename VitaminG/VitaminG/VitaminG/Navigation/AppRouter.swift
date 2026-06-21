import Observation

/// Centralized navigation state for the app.
/// Injected into the SwiftUI environment so any view can navigate without coupling.
@Observable
final class AppRouter {
    var path: [AppRoute] = []

    /// Trigger for presenting PublicProfileView as a sheet (D-07).
    /// Set to a non-nil recordID by .onOpenURL handler in VitaminGApp.
    /// Setting nil dismisses the sheet.
    var pendingPublicProfileRecordID: String? = nil
    var pendingChallengeCheckInID: String? = nil

    func popToRoot() {
        path.removeAll()
    }
}

/// Thin Identifiable wrapper enabling .sheet(item:) binding on pendingPublicProfileRecordID.
/// Defined alongside AppRouter because it is a navigation type, not a view type.
struct ProfileDeepLinkItem: Identifiable {
    let id: String  // id == recordID
}

/// Thin Identifiable wrapper enabling .sheet(item:) binding on pendingChallengeCheckInID.
/// Parallel structure to ProfileDeepLinkItem — id is the UserChallenge UUID string.
struct ChallengeCheckInDeepLinkItem: Identifiable, Hashable {
    let id: String   // UUID string
}
