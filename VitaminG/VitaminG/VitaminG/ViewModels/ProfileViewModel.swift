import Observation
import SwiftData
import SwiftUI

// MARK: - ProfileViewModel

/// Manages the single UserProfile per device/iCloud account.
/// Follows the GoalViewModel pattern: @Observable, business logic only, no SwiftUI view code.
/// Plan 07-02: Profile CRUD, avatar color assignment, display name validation, privacy toggle.
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

    /// Set when a CloudKit public database write fails (Plan 03 wires the actual write).
    var cloudKitError: String?
    var showingCloudKitError: Bool = false

    // MARK: - Profile Load/Create

    /// Fetches the singleton UserProfile or creates one on first visit (D-14).
    /// Assigns a random avatar color from the palette and persists it (D-02).
    /// Thread: must be called on the main actor (ModelContext is main-actor-bound).
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

    /// Share URL for this profile. Returns nil until Plan 03 populates cloudKitPublicRecordID.
    var shareURL: URL? {
        guard let recordID = profile?.cloudKitPublicRecordID else { return nil }
        return URL(string: "vitaming://profile/\(recordID)")
    }

    // MARK: - Display Name Validation

    /// Sanitizes and validates draftDisplayName, then saves to SwiftData.
    /// Returns true on success; sets showingValidationAlert on failure.
    /// Follows GoalViewModel.sanitize() pattern exactly (T-07-04).
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
        return true
    }

    // MARK: - Privacy Toggle

    /// Toggles profile-level isPublic and persists.
    /// CloudKit public DB write is handled in Plan 03. For now, local persistence only (D-04 — D-06).
    func toggleProfilePublic(context: ModelContext) {
        profile?.isPublic.toggle()
        try? context.save()
    }

    // MARK: - Input Sanitization (mirrors GoalViewModel.sanitize — T-07-04, T-07-07)

    /// Strips control characters and HTML/script-injection characters,
    /// normalises whitespace, and trims leading/trailing whitespace.
    func sanitize(_ raw: String) -> String {
        let blocked = CharacterSet.controlCharacters.union(.illegalCharacters).subtracting(.newlines)
        let stripped = raw.unicodeScalars
            .filter { !blocked.contains($0) }
            .reduce(into: "") { $0.unicodeScalars.append($1) }

        let lines = stripped.components(separatedBy: .newlines)
        let cleaned = lines
            .map { line in
                line.components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
            }
            .joined(separator: "\n")

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
