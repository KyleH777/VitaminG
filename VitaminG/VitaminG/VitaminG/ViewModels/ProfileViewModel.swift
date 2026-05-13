import Observation
import SwiftData
import SwiftUI

// MARK: - ProfileViewModel

/// Manages the single UserProfile per device/iCloud account.
/// Follows the GoalViewModel pattern: @Observable, business logic only, no SwiftUI view code.
/// Plan 07-02: Profile CRUD, avatar color assignment, display name validation, privacy toggle.
/// Plan 07-03: CloudKit public database write/delete wired to toggleProfilePublic; shareURL uses DeepLinkBuilder.
@MainActor
@Observable
final class ProfileViewModel {

    // MARK: - Constants

    static let maxDisplayNameLength = 50

    /// Warm, gratitude-toned avatar color palette (D-01, D-02).
    /// Six colors designed to feel personal and positive — drawn from the app's tier tone system.
    static let avatarColors: [(red: Double, green: Double, blue: Double)] = [
        (0.98, 0.55, 0.27),  // Warm orange
        (0.36, 0.78, 0.64),  // Fresh teal
        (0.40, 0.61, 0.95),  // Calm blue
        (0.78, 0.48, 0.95),  // Deep violet
        (0.95, 0.75, 0.28),  // Sunflower gold
        (0.87, 0.40, 0.55),  // Rose
    ]

    // MARK: - Published State

    /// The singleton profile (loaded or created on first Profile tab visit).
    var profile: UserProfile?

    /// Edit sheet binding — populated when user taps pencil button.
    var draftDisplayName: String = ""

    var showingEditSheet: Bool = false
    var showingValidationAlert: Bool = false
    var validationErrorMessage: String = ""

    /// Set when a CloudKit public database write fails (T-07-11).
    var cloudKitError: String?
    var showingCloudKitError: Bool = false

    // MARK: - Profile Load/Create

    /// Fetches the singleton UserProfile or creates one on first visit (D-14).
    /// Assigns a random avatar color from the palette and persists it (D-02).
    func loadOrCreateProfile(context: ModelContext) {
        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1  // T-07-06: prevent unbounded query
        let results = (try? context.fetch(descriptor)) ?? []

        if let existing = results.first {
            self.profile = existing
        } else {
            let newProfile = UserProfile()
            // Assign random avatar color — persisted, never re-randomized (D-02)
            let idx = Int.random(in: 0..<Self.avatarColors.count)
            let c = Self.avatarColors[idx]
            newProfile.avatarColorHex = String(
                format: "#%02X%02X%02X",
                Int(c.red * 255), Int(c.green * 255), Int(c.blue * 255)
            )
            // Pre-fill name from onboarding if available
            if let pendingName = UserDefaults.standard.string(forKey: "vg_onboardingName"),
               !pendingName.isEmpty {
                newProfile.displayName = String(pendingName.prefix(Self.maxDisplayNameLength))
            }
            context.insert(newProfile)
            try? context.save()
            self.profile = newProfile
        }
    }

    // MARK: - Computed Properties

    /// Initials derived from displayName. Max 2 characters, uppercase.
    /// Returns "?" when displayName is nil or empty (per UI-SPEC AvatarView).
    var initials: String {
        guard let name = profile?.displayName, !name.isEmpty else { return "?" }
        let words = name.split(separator: " ")
        let chars = words.prefix(2).compactMap { $0.first.map { String($0).uppercased() } }
        return chars.joined()
    }

    /// Color parsed from avatarColorHex. Falls back to gray if nil or unparseable.
    var avatarColor: Color {
        guard let hex = profile?.avatarColorHex else { return .gray }
        return Color(hex: hex)
    }

    /// Share URL for this profile using DeepLinkBuilder.
    /// Returns nil until profile is public AND cloudKitPublicRecordID is set (D-06, D-07).
    var shareURL: URL? {
        DeepLinkBuilder.profileURL(recordID: profile?.cloudKitPublicRecordID)
    }

    // MARK: - Display Name Validation

    /// Sanitizes and validates draftDisplayName, then saves to SwiftData.
    /// Returns true on success; sets showingValidationAlert on failure.
    @discardableResult
    func validateAndSaveDisplayName(context: ModelContext) -> Bool {
        let sanitized = sanitize(draftDisplayName)

        guard !sanitized.isEmpty else {
            validationErrorMessage = "Name cannot be empty. Add your name so others can recognize you."
            showingValidationAlert = true
            return false
        }

        // Truncate at limit (soft cap — never error, just clip)
        let capped = sanitized.count <= Self.maxDisplayNameLength
            ? sanitized
            : String(sanitized.prefix(Self.maxDisplayNameLength))

        profile?.displayName = capped
        try? context.save()

        // Sync updated display name to CloudKit public record if profile is public
        updatePublicRecordIfNeeded(context: context)

        return true
    }

    // MARK: - Privacy Toggle

    /// Toggles profile-level isPublic and triggers CloudKit public DB write or delete.
    /// Going public: saves PublicProfile record to CloudKit public DB, stores recordID locally.
    /// Going private: deletes CloudKit public record (prevents orphaned accessible data), clears recordID.
    /// Per D-04 – D-06, T-07-11: on publish failure, shows alert but keeps toggle ON (optimistic UI).
    func toggleProfilePublic(context: ModelContext) {
        guard let profile else { return }
        let newValue = !profile.isPublic
        profile.isPublic = newValue
        try? context.save()

        if newValue {
            // Going public — write to CloudKit public database
            Task { @MainActor in
                do {
                    let recordID = try await ProfileSharingService.publishProfile(
                        displayName: profile.displayName,
                        avatarColorHex: profile.avatarColorHex,
                        existingRecordID: profile.cloudKitPublicRecordID
                    )
                    profile.cloudKitPublicRecordID = recordID
                    try? context.save()
                } catch {
                    // CloudKit write failed — show alert but keep toggle ON (optimistic UI per T-07-11)
                    cloudKitError = error.localizedDescription
                    showingCloudKitError = true
                }
            }
        } else {
            // Going private — delete CloudKit public record to prevent orphaned accessible data (D-06)
            if let recordID = profile.cloudKitPublicRecordID {
                Task {
                    try? await ProfileSharingService.unpublishProfile(recordID: recordID)
                }
                // Clear recordID immediately so share link disappears (optimistic local update)
                profile.cloudKitPublicRecordID = nil
                try? context.save()
            }
        }
    }

    // MARK: - CloudKit Sync

    /// Syncs updated displayName or avatarColorHex to the CloudKit public record when profile is public.
    /// Called after validateAndSaveDisplayName succeeds. Silently ignores failures (best-effort sync).
    func updatePublicRecordIfNeeded(context: ModelContext) {
        guard let profile, profile.isPublic, profile.cloudKitPublicRecordID != nil else { return }
        Task {
            _ = try? await ProfileSharingService.publishProfile(
                displayName: profile.displayName,
                avatarColorHex: profile.avatarColorHex,
                existingRecordID: profile.cloudKitPublicRecordID
            )
        }
    }

    // MARK: - Input Sanitization

    /// Delegates to the shared InputSanitizer utility with public-safe character stripping.
    /// Profile display names may be publicly visible, so HTML/script characters are also stripped.
    func sanitize(_ raw: String) -> String {
        InputSanitizer.sanitizeForPublic(raw)
    }
}
