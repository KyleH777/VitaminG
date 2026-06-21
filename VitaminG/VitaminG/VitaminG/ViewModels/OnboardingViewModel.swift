// VitaminG/ViewModels/OnboardingViewModel.swift
import SwiftUI
import UserNotifications
import Observation
import CloudKit

// MARK: - UsernameCheckState

/// State machine for the async username availability check in UsernameScreen.
/// Transitions:
///   onUsernameChanged("") or short input     → .idle
///   onUsernameChanged("bad!char")             → .invalid(msg)
///   onUsernameChanged("valid") after debounce → .checking → .available | .taken
///   CloudKit error during check               → .idle (silent fallback)
enum UsernameCheckState: Equatable {
    case idle
    case checking
    case available
    case taken
    case invalid(String)
}

// MARK: - OnboardingViewModel

@MainActor
@Observable
final class OnboardingViewModel {

    var hasCreatedFirstGoal: Bool = false

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Returning-user detection

    var savedName: String {
        (defaults.string(forKey: "vg_onboardingName") ?? "")
            .trimmingCharacters(in: .whitespaces)
    }

    var isReturningUser: Bool { !savedName.isEmpty }

    // MARK: - Apple Sign-In credential passthrough (ephemeral — not persisted)

    /// Pre-fill value from Apple Sign-In fullName credential.
    /// Passed to NameScreen so the user sees a pre-filled display name.
    var appleFullName: PersonNameComponents? = nil

    // MARK: - Profile photo (ephemeral session state)

    /// Compressed JPEG data for the profile photo selected during onboarding.
    /// Written to the SwiftData UserProfile record at onboarding completion.
    var profilePhotoData: Data? = nil

    // MARK: - Username check state (AUTH-03, D-07)

    var usernameCheckState: UsernameCheckState = .idle

    /// Cancellable debounce task — cancelled on each new keystroke.
    private var debounceTask: Task<Void, Never>? = nil

    // MARK: - Username validation

    /// Called from UsernameScreen .onChange. Validates character set synchronously,
    /// then fires async CloudKit check after 500ms of inactivity (D-17 debounce).
    ///
    /// Synchronous guard paths (tested without CloudKit):
    ///   - Empty or < 3 chars → .idle (no check)
    ///   - Invalid chars → .invalid(message) (no check)
    ///   - Valid ≥ 3 chars → debounce 500ms → checkUsernameAvailability
    func onUsernameChanged(_ newValue: String) {
        // Cancel any in-flight debounce task
        debounceTask?.cancel()
        debounceTask = nil

        // Guard: empty or too short — reset to idle, no check
        guard !newValue.isEmpty else {
            usernameCheckState = .idle
            return
        }

        guard newValue.count >= 3 else {
            usernameCheckState = .idle
            return
        }

        // Guard: character set validation (T-17-03-02)
        // Only lowercase letters, digits, and underscores are allowed.
        // Note: uppercase is rejected here; UsernameScreen uses .textInputAutocapitalization(.never)
        let allowed = CharacterSet.letters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: "_"))
        if newValue.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            usernameCheckState = .invalid("Only letters, numbers, and underscores")
            return
        }

        // Valid input — fire debounced CloudKit check
        let lowercased = newValue.lowercased()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await checkUsernameAvailability(lowercased)
        }
    }

    /// Performs the async CloudKit availability check.
    /// Called from the debounce task — never directly from onUsernameChanged.
    private func checkUsernameAvailability(_ username: String) async {
        usernameCheckState = .checking
        do {
            let taken = try await UsernameLookupService.isUsernameTaken(username)
            usernameCheckState = taken ? .taken : .available
        } catch {
            // CloudKit unavailable (new container, no index yet, or network error).
            // Assume available — the post-save count check in claimUsername catches real duplicates.
            usernameCheckState = .available
        }
    }

    // MARK: - Username Claim (D-17 race condition mitigation)

    /// Claims the username in CloudKit.
    /// After writing, performs a post-save count re-check to detect race conditions
    /// (two devices claiming the same username within the debounce window).
    ///
    /// - Parameters:
    ///   - username: The username to claim (must already be .available state).
    ///   - appleUserID: Apple-issued UID; used as the CloudKit record name.
    /// - Returns: true if claim succeeded and this device is the sole owner; false on race condition or error.
    func claimUsername(_ username: String, appleUserID: String) async -> Bool {
        do {
            // Write the username claim to CloudKit
            let recordID = try await UsernameLookupService.writeUsername(username, appleUserID: appleUserID)

            // Post-save race condition check (D-17, T-17-03-04)
            let count = try await UsernameLookupService.countRecordsWithUsername(username)
            if count > 1 {
                // Race condition: another device claimed the same username.
                // Delete this device's write to avoid duplicate claims.
                let container = CKContainer(identifier: "iCloud.com.kyleharrington.VitaminG")
                _ = try? await container.publicCloudDatabase.deleteRecord(withID: recordID)
                return false
            }
            return true
        } catch {
            return false
        }
    }

    // MARK: - Actions

    func completeOnboarding() async {
        hasCreatedFirstGoal = true

        // Coordinate username write path: read the claimed username from AppStorage,
        // then call publishProfile with it so the full PublicProfile record includes username.
        // Both claimUsername (called earlier) and publishProfile target the same
        // CKRecord.ID(recordName: appleUserID) record — writing the same lowercased value is safe.
        let storedUsername = defaults.string(forKey: "vg_onboardingUsername") ?? ""
        let appleUserID = defaults.string(forKey: "vg_appleUserID") ?? ""
        let existingRecordID = defaults.string(forKey: "vg_cloudKitPublicRecordID")

        if !storedUsername.isEmpty && !appleUserID.isEmpty {
            // publishProfile with the claimed username — non-nil so it's written to the record
            _ = try? await ProfileSharingService.publishProfile(
                displayName: defaults.string(forKey: "vg_onboardingName"),
                avatarColorHex: nil,
                username: storedUsername,
                existingRecordID: existingRecordID ?? appleUserID
            )
        }

        // Notification permission is handled inline by NotificationOnboardingScreen.
    }

    /// Clears persisted profile and onboarding completion flag.
    /// Call from OnboardingView when the user chooses "Start fresh".
    func restartOnboarding() {
        defaults.removeObject(forKey: "vg_onboardingName")
        defaults.set(false, forKey: "hasCompletedOnboarding")
    }
}
