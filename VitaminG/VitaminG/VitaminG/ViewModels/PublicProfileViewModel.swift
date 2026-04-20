import Observation
import CloudKit

@MainActor
@Observable
final class PublicProfileViewModel {

    enum ViewState: Equatable {
        case loading
        case loaded(displayName: String?, avatarColorHex: String?)
        case error(message: String)
    }

    var state: ViewState = .loading

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    /// Closure override for unit testing. When non-nil, used instead of ProfileSharingService.
    /// Follows the fake-injection pattern from NotificationSchedulerTests.
    var fetchOverride: ((String) async throws -> (String?, String?))? = nil

    func fetchProfile(recordID: String) {
        state = .loading
        Task {
            do {
                let result: (displayName: String?, avatarColorHex: String?)
                if let override = fetchOverride {
                    let (d, a) = try await override(recordID)
                    result = (displayName: d, avatarColorHex: a)
                } else {
                    result = try await ProfileSharingService.fetchProfile(recordID: recordID)
                }
                state = .loaded(displayName: result.displayName, avatarColorHex: result.avatarColorHex)
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
