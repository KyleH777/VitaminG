import Observation
import CloudKit

@MainActor
@Observable
final class PublicProfileViewModel {

    enum ViewState: Equatable {
        case loading
        case loaded(profile: PublicProfileData)
        case error(message: String)
    }

    var state: ViewState = .loading

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    /// Closure override for unit testing. When non-nil, used instead of ProfileSharingService.
    /// Returns PublicProfileData — updated in Phase 22 to carry the full profile struct.
    /// Follows the fake-injection pattern from NotificationSchedulerTests.
    var fetchOverride: ((String) async throws -> PublicProfileData)? = nil

    func fetchProfile(recordID: String) {
        state = .loading
        Task {
            do {
                let profile: PublicProfileData
                if let override = fetchOverride {
                    profile = try await override(recordID)
                } else {
                    profile = try await ProfileSharingService.fetchProfile(recordID: recordID)
                }
                state = .loaded(profile: profile)
            } catch let error as CKError {
                switch error.code {
                case .unknownItem:
                    state = .error(message: "This profile is no longer available.")
                case .networkFailure, .networkUnavailable:
                    state = .error(message: "Couldn't load profile. Check your internet connection and try again.")
                default:
                    state = .error(message: "Couldn't load profile. Check your internet connection and try again.")
                }
            } catch {
                state = .error(message: "Couldn't load profile. Check your internet connection and try again.")
            }
        }
    }
}
