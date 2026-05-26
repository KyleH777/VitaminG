import Observation
import CloudKit
import SwiftUI

// MARK: - FollowState
// State machine for the FollowButton on PublicProfileView.
// Declared at file scope so FollowButton.swift can consume it without importing the VM module.
// State machine:
//   .idle ──tap──> .loading ──success──> .followed
//                            ──failure──> .idle (followError auto-clears after 3s)
// Note: Follow is a one-time terminal action in v2.0 (no unfollow).

enum FollowState: Equatable {
    case idle
    case loading
    case followed
}

// MARK: - PublicProfileViewModel

@MainActor
@Observable
final class PublicProfileViewModel {

    // MARK: - ViewState

    enum ViewState: Equatable {
        case loading
        case loaded(profile: PublicProfileData)
        case error(message: String)
    }

    // MARK: - State

    var state: ViewState = .loading

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    // MARK: - Follow State

    /// Current follow state (T-22-03-02: guard in onFollow prevents double-fire during .loading).
    var followState: FollowState = .idle

    /// Auto-clearing error shown below the FollowButton on failure (UI-SPEC §2 error banner).
    /// Cleared after 3 seconds via Task.sleep.
    var followError: String? = nil

    // MARK: - Public Goals

    /// Public goals fetched for the viewed profile. Populated after fetchProfile succeeds.
    var publicGoals: [PublicGoalItem] = []

    /// Silent error string when publicGoals fetch fails — shown as empty state, not toast.
    var publicGoalsError: String? = nil

    // MARK: - Test Override Seams
    // nil in production — set in unit tests to avoid CloudKit calls.

    /// Override for fetchProfile (updated in Phase 22 to return PublicProfileData struct).
    /// Follows the fake-injection pattern from NotificationSchedulerTests.
    var fetchOverride: ((String) async throws -> PublicProfileData)? = nil

    /// Override for PublicGoalService.fetchGoalsForUser. nil = use real service.
    var fetchGoalsForUserOverride: ((String) async throws -> [PublicGoalItem])? = nil

    /// Override for ProfileSharingService.fetchFollowState. nil = use real service.
    var fetchFollowStateOverride: ((String, String) async throws -> Bool)? = nil

    /// Override for ProfileSharingService.writeFollow. nil = use real service.
    var writeFollowOverride: ((String, String) async throws -> Void)? = nil

    /// Override for CommunityService.writeApplause. nil = use real service.
    var writeApplauseOverride: ((String, String) async throws -> Void)? = nil

    // MARK: - Fetch Profile

    /// Loads the public profile from CloudKit (or fetchOverride in tests).
    /// Sets state = .loading immediately, then transitions to .loaded or .error.
    /// On success, also kicks off a public goals fetch (silent — shows empty state on failure).
    func fetchProfile(recordID: String) {
        state = .loading
        publicGoals = []
        publicGoalsError = nil
        Task {
            do {
                let profile: PublicProfileData
                if let override = fetchOverride {
                    profile = try await override(recordID)
                } else {
                    profile = try await ProfileSharingService.fetchProfile(recordID: recordID)
                }
                state = .loaded(profile: profile)

                // Kick off public goals fetch after profile resolves username (silent on failure)
                let username = profile.username ?? ""
                if !username.isEmpty {
                    do {
                        if let override = fetchGoalsForUserOverride {
                            publicGoals = try await override(username)
                        } else {
                            publicGoals = try await PublicGoalService.fetchGoalsForUser(username: username)
                        }
                    } catch {
                        publicGoalsError = "Couldn't load this user's goals."
                        // publicGoals remains [] — view shows empty state
                    }
                }
            } catch let error as CKError {
                switch error.code {
                case .unknownItem:
                    state = .error(message: "This profile is no longer available.")
                case .networkFailure, .networkUnavailable:
                    state = .error(message: "Couldn't load this profile. Check your connection and try again.")
                default:
                    state = .error(message: "Couldn't load this profile. Check your connection and try again.")
                }
            } catch {
                state = .error(message: "Couldn't load this profile. Check your connection and try again.")
            }
        }
    }

    // MARK: - Follow State Resolution

    /// Resolves the current follow state from CloudKit (or fetchFollowStateOverride in tests).
    /// Called after fetchProfile when both usernames are known.
    /// Sets followState = .followed if a Follow record exists, .idle otherwise.
    func resolveFollowState(followerUsername: String, followeeUsername: String) {
        Task {
            do {
                let isFollowing: Bool
                if let override = fetchFollowStateOverride {
                    isFollowing = try await override(followerUsername, followeeUsername)
                } else {
                    isFollowing = try await ProfileSharingService.fetchFollowState(
                        followerUsername: followerUsername,
                        followeeUsername: followeeUsername
                    )
                }
                followState = isFollowing ? .followed : .idle
            } catch {
                // Silently swallow — followState stays .idle on error.
                // User can still attempt follow; idempotency check is server-side.
            }
        }
    }

    // MARK: - Follow Action

    /// Initiates the follow action from followerUsername → followeeUsername.
    /// T-22-03-02 mitigation: guard on followState == .idle prevents double-fire during .loading.
    /// On success: followState → .followed with spring animation.
    /// On failure: followState → .idle with followError auto-cleared after 3s.
    func onFollow(followerUsername: String, followeeUsername: String) {
        guard followState == .idle else { return }
        followState = .loading
        Task {
            do {
                if let override = writeFollowOverride {
                    try await override(followerUsername, followeeUsername)
                } else {
                    try await ProfileSharingService.writeFollow(
                        followerUsername: followerUsername,
                        followeeUsername: followeeUsername
                    )
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    followState = .followed
                }
            } catch {
                followState = .idle
                followError = "Couldn't follow right now. Tap to retry."
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    followError = nil
                }
            }
        }
    }

    // MARK: - Cheer Gate

    /// Returns true when the current user has NOT yet cheered recipientUsername today.
    /// Delegates to ApplauseGate so the gate logic is defined in one place (SOC-01).
    func canCheerToday(recipientUsername: String, defaults: UserDefaults = .standard) -> Bool {
        ApplauseGate.canApplaud(recipientUsername: recipientUsername, defaults: defaults)
    }

    // MARK: - Cheer Action

    /// Fires the cheer (applause) action for recipientUsername.
    /// Guards on canCheerToday — no-op if daily gate already consumed (T-22-03-03 accept).
    /// Marks the gate via ApplauseGate.markApplauseGiven then fires CommunityService.writeApplause
    /// as a fire-and-forget Task (T-22-03-06 accept: failures are best-effort per Phase 21 behavior).
    func onCheer(recipientUsername: String, giverUsername: String, defaults: UserDefaults = .standard) {
        guard canCheerToday(recipientUsername: recipientUsername, defaults: defaults) else { return }
        ApplauseGate.markApplauseGiven(to: recipientUsername, defaults: defaults)
        Task {
            if let override = writeApplauseOverride {
                try? await override(giverUsername, recipientUsername)
            } else {
                try? await CommunityService.writeApplause(giverUsername: giverUsername, recipientUsername: recipientUsername)
            }
        }
    }
}
