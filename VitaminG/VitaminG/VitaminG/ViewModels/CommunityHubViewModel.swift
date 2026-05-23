import Foundation
import Observation
import CloudKit

// MARK: - ApplauseGate
// Encapsulates the daily-per-recipient applause gate (SOC-01 / D-04).
// Stored as a [String: Date] dict in UserDefaults under "vg_community_applauseGiven".
// Key is recipientUsername; value is the Date of the last applause given to that recipient.
// Security note (T-21-03-01): UserDefaults can be cleared by the OS or user — no
// cryptographic enforcement. Acceptable for v2.0 social trust model.

enum ApplauseGate {
    private static let applauseKey = "vg_community_applauseGiven"

    /// Returns true when the current user has NOT yet applauded `recipientUsername` today.
    static func canApplaud(
        recipientUsername: String,
        defaults: UserDefaults = .standard
    ) -> Bool {
        guard let data = defaults.data(forKey: applauseKey),
              let dict = try? JSONDecoder().decode([String: Date].self, from: data),
              let last = dict[recipientUsername]
        else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    /// Records that the current user has applauded `recipientUsername` today.
    static func markApplauseGiven(
        to recipientUsername: String,
        defaults: UserDefaults = .standard
    ) {
        var dict: [String: Date] = [:]
        if let data = defaults.data(forKey: applauseKey),
           let existing = try? JSONDecoder().decode([String: Date].self, from: data) {
            dict = existing
        }
        dict[recipientUsername] = Date()
        if let encoded = try? JSONEncoder().encode(dict) {
            defaults.set(encoded, forKey: applauseKey)
        }
    }
}

// MARK: - GlowingSelector
// Deterministic Glowing This Week selection using ISO 8601 weekOfYear (COMM-05).
// Uses Calendar(identifier: .iso8601) — NOT Calendar.current — to ensure
// consistent week boundaries regardless of locale.

enum GlowingSelector {
    /// Selects the Glowing This Week user from an eligible pool.
    /// Returns nil for an empty array. Returns the same user for the entire ISO 8601 week.
    static func selectGlowingUser(from eligible: [GoalGlimpseItem]) -> GoalGlimpseItem? {
        guard !eligible.isEmpty else { return nil }
        let week = Calendar(identifier: .iso8601).component(.weekOfYear, from: Date())
        return eligible[week % eligible.count]
    }
}

// MARK: - CommunityHubViewModel
// Central @Observable coordinator for all 5 Community tab sections (COMM-06 / Plan 03).
//
// loadAll() fans out to 5 parallel CloudKit fetches via async let.
// Each section has a test override closure (nil in production) following the
// CommunityFeedViewModel pattern. Error handling: on failure, each section
// independently falls back to empty array — UI is never blocked (T-21-03-04).
//
// Security (T-21-03-02): giverUsername sourced from UserProfile SwiftData (device-local).
// Same trust model as all other username sourcing in v2.0.

@MainActor
@Observable
final class CommunityHubViewModel {

    // MARK: - Published state

    /// Today's goal glimpses (GoalGlimpse CKRecords for today's dayKey).
    var glimpses: [GoalGlimpseItem] = []
    /// Users active within the last 2 hours.
    var activeUsers: [UserPresenceItem] = []
    /// The Glowing This Week user (deterministic per ISO 8601 week).
    var glowingUser: GoalGlimpseItem? = nil
    /// Global community feed posts.
    var feedPosts: [CKRecord] = []
    /// Applause received by the current user.
    var receivedApplause: [ApplauseItem] = []
    /// True while loadAll() is in flight.
    var isLoading: Bool = false
    /// Non-nil if a critical error occurred during loadAll() (display-safe string only).
    var loadError: String? = nil

    // MARK: - Test overrides (nil in production)
    // Pattern mirrors CommunityFeedViewModel.fetchOverride exactly.

    var fetchGlimpsesOverride: ((String) async throws -> [GoalGlimpseItem])? = nil
    var fetchActiveUsersOverride: (() async throws -> [UserPresenceItem])? = nil
    var fetchGlowingUserOverride: ((String) async throws -> [GoalGlimpseItem]?)? = nil
    var fetchPostsOverride: ((Int) async throws -> [CKRecord])? = nil
    var fetchAppreciationsOverride: ((String) async throws -> [ApplauseItem])? = nil

    // MARK: - Error constants (never expose raw localizedDescription to UI)
    static let loadFailureMessage = "Couldn't load community data. Pull to refresh."
    static let applauseWriteFailureMessage = "Couldn't send applause. Please try again."

    // MARK: - Load all 5 sections in parallel

    /// Fans out to all 5 CloudKit sections using async let for true parallelism.
    /// Each section fails independently — a single slow or failed section never
    /// blocks the others (T-21-03-04 mitigation).
    func loadAll(username: String) async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        let todayKey = formatter.string(from: Date())

        // Capture override closures on MainActor before spawning async let tasks.
        // async let closures cannot directly access @MainActor-isolated properties.
        let glimpsesOverride = fetchGlimpsesOverride
        let activeUsersOverride = fetchActiveUsersOverride
        let glowingUserOverride = fetchGlowingUserOverride
        let postsOverride = fetchPostsOverride
        let appreciationsOverride = fetchAppreciationsOverride

        // Parallel fetch — all 5 in flight simultaneously.
        async let glimpseResult: [GoalGlimpseItem] = {
            if let override = glimpsesOverride {
                return (try? await override(todayKey)) ?? []
            }
            return (try? await CommunityService.fetchGlimpses(dayKey: todayKey)) ?? []
        }()

        async let activeUsersResult: [UserPresenceItem] = {
            if let override = activeUsersOverride {
                return (try? await override()) ?? []
            }
            return (try? await CommunityService.fetchActiveUsers()) ?? []
        }()

        async let glowingResult: [GoalGlimpseItem] = {
            if let override = glowingUserOverride {
                return (try? await override(todayKey)) ?? []
            }
            return (try? await CommunityService.fetchGlowingUser(dayKey: todayKey)) ?? []
        }()

        async let feedResult: [CKRecord] = {
            if let override = postsOverride {
                return (try? await override(50)) ?? []
            }
            return (try? await CommunityService.fetchGlobalPosts(limit: 50)) ?? []
        }()

        async let applauseResult: [ApplauseItem] = {
            if let override = appreciationsOverride {
                return (try? await override(username)) ?? []
            }
            return (try? await CommunityService.fetchReceivedApplause(recipientUsername: username)) ?? []
        }()

        // Await all 5 results — order doesn't matter since they're independent.
        let (g, a, glow, feed, appl) = await (
            glimpseResult,
            activeUsersResult,
            glowingResult,
            feedResult,
            applauseResult
        )

        glimpses = g
        // Filter to only users active within the last 2 hours (mirrors CommunityService.fetchActiveUsers predicate).
        // Necessary when an override injects mixed-staleness data in tests (COMM-04).
        let twoHoursAgo = Date().addingTimeInterval(-7200)
        activeUsers = a.filter { $0.lastActiveDate > twoHoursAgo }
        glowingUser = GlowingSelector.selectGlowingUser(from: glow)
        feedPosts = feed
        receivedApplause = appl
    }

    // MARK: - Glowing user selection

    /// Selects the Glowing This Week user from an eligible pool.
    /// Delegates to GlowingSelector for testability.
    func selectGlowingUser(from eligible: [GoalGlimpseItem]) -> GoalGlimpseItem? {
        GlowingSelector.selectGlowingUser(from: eligible)
    }

    // MARK: - Applause gate (instance wrappers over ApplauseGate)

    /// Returns true when the current user has NOT yet applauded `recipientUsername` today.
    func canApplaud(recipientUsername: String, defaults: UserDefaults = .standard) -> Bool {
        ApplauseGate.canApplaud(recipientUsername: recipientUsername, defaults: defaults)
    }

    /// Records that the current user has applauded `recipientUsername` today.
    func markApplauseGiven(to recipientUsername: String, defaults: UserDefaults = .standard) {
        ApplauseGate.markApplauseGiven(to: recipientUsername, defaults: defaults)
    }

    // MARK: - Write applause

    /// Writes an applause record to CloudKit and marks the daily gate, only when
    /// canApplaud returns true. Applause failure is caught silently — a failed write
    /// should not surface an error to the user (SOC-03 / D-04).
    /// Security (T-21-03-02): giverUsername is device-local from UserProfile SwiftData.
    func writeApplauseForUser(
        recipientUsername: String,
        giverUsername: String,
        defaults: UserDefaults = .standard
    ) async {
        guard canApplaud(recipientUsername: recipientUsername, defaults: defaults) else { return }
        do {
            try await CommunityService.writeApplause(
                giverUsername: giverUsername,
                recipientUsername: recipientUsername
            )
            markApplauseGiven(to: recipientUsername, defaults: defaults)
        } catch {
            // Silently discard — applause failure must not surface to UI (SOC-03)
        }
    }
}
