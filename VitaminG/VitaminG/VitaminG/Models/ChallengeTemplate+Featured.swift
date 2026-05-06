import Foundation

// MARK: - MilestoneConfig

/// Codable milestone definition stored as JSON inside ChallengeTemplate.milestonesJSON.
///
/// CloudKit-safe encoding: the array is stored as a JSON string on the model,
/// avoiding any CloudKit-incompatible transformable attribute (RESEARCH.md Pattern 4).
/// Decoding uses `try? JSONDecoder()` throughout so malformed data never crashes
/// (T-13-06 threat mitigation).
struct MilestoneConfig: Codable, Equatable {
    /// Day threshold (check-in count) at which this milestone fires.
    let dayThreshold: Int
    /// User-facing celebration message displayed in the milestone sheet.
    let message: String
    /// SF Symbol name for the milestone badge icon.
    let badgeSymbol: String
}

// MARK: - ChallengeTemplate + Featured (D-01, D-03, CHAL-01, CHAL-06)

/// Static factory methods and milestone JSON helpers for ChallengeTemplate.
///
/// D-01: Featured templates are Swift static constants — no JSON file, no file I/O.
/// D-03: These constants are inserted into the LOCAL SwiftData context only at seed time
///       (in ChallengeViewModel.seedFeaturedTemplates). No CloudKit catalog sync.
extension ChallengeTemplate {

    // MARK: - Featured Template Catalog

    /// All three featured challenge templates. Consumed by seedFeaturedTemplates().
    static var featuredTemplates: [ChallengeTemplate] {
        [summerBodyTemplate, save5000Template, drySummerTemplate]
    }

    // MARK: - Summer Body (fitness / multiStep / streak)

    /// 90-Day Summer Body — fitness, multiStep check-ins, streak goal.
    /// Accent: #FF6B4A (coral). Icon: figure.run. Community: 1,240.
    static var summerBodyTemplate: ChallengeTemplate {
        let t = ChallengeTemplate()
        t.title = "90-Day Summer Body"
        t.challengeDescription = "Transform your fitness over 90 days with daily movement check-ins."
        t.category = "fitness"
        t.challengeType = "featured"
        t.checkInType = "multiStep"
        t.goalType = "streak"
        t.durationDays = 90
        t.accentColorHex = "#FF6B4A"
        t.iconName = "figure.run"
        t.communitySize = 1240
        t.isFeatured = true
        t.milestonesJSON = encodedMilestones([
            MilestoneConfig(dayThreshold: 7,  message: "One week strong!",                           badgeSymbol: "flame.fill"),
            MilestoneConfig(dayThreshold: 30, message: "A whole month! Keep going.",                 badgeSymbol: "trophy.fill"),
            MilestoneConfig(dayThreshold: 60, message: "Two months in — momentum is yours.",         badgeSymbol: "medal.fill"),
            MilestoneConfig(dayThreshold: 90, message: "You did it! 90 days!",                       badgeSymbol: "star.fill")
        ])
        return t
    }

    // MARK: - Save $5,000 (finance / numeric / target)

    /// Save $5,000 — finance, numeric check-ins, target goal.
    /// Accent: #4A90E2 (blue). Icon: dollarsign.circle.fill. Community: 860.
    static var save5000Template: ChallengeTemplate {
        let t = ChallengeTemplate()
        t.title = "Save $5,000"
        t.challengeDescription = "Log a daily savings amount and watch the total grow toward $5,000."
        t.category = "finance"
        t.challengeType = "featured"
        t.checkInType = "numeric"
        t.goalType = "target"
        t.durationDays = 90
        t.accentColorHex = "#4A90E2"
        t.iconName = "dollarsign.circle.fill"
        t.communitySize = 860
        t.isFeatured = true
        t.milestonesJSON = encodedMilestones([
            MilestoneConfig(dayThreshold: 7,  message: "First week of saving — keep going!",         badgeSymbol: "flame.fill"),
            MilestoneConfig(dayThreshold: 30, message: "A month of savings logged.",                 badgeSymbol: "trophy.fill"),
            MilestoneConfig(dayThreshold: 60, message: "Sixty days of discipline.",                  badgeSymbol: "medal.fill"),
            MilestoneConfig(dayThreshold: 90, message: "Goal completed! $5,000 mindset achieved.",   badgeSymbol: "star.fill")
        ])
        return t
    }

    // MARK: - Dry Summer (sobriety / boolean / streak)

    /// Dry Summer — sobriety, boolean check-ins, streak goal.
    /// Accent: #7A9E7E (sage green). Icon: leaf.fill. Community: 2,105.
    static var drySummerTemplate: ChallengeTemplate {
        let t = ChallengeTemplate()
        t.title = "Dry Summer"
        t.challengeDescription = "Stay alcohol-free for 90 days. One check-in per day."
        t.category = "sobriety"
        t.challengeType = "featured"
        t.checkInType = "boolean"
        t.goalType = "streak"
        t.durationDays = 90
        t.accentColorHex = "#7A9E7E"
        t.iconName = "leaf.fill"
        t.communitySize = 2105
        t.isFeatured = true
        t.milestonesJSON = encodedMilestones([
            MilestoneConfig(dayThreshold: 7,  message: "One week clear.",                            badgeSymbol: "flame.fill"),
            MilestoneConfig(dayThreshold: 30, message: "Thirty days of clarity.",                    badgeSymbol: "trophy.fill"),
            MilestoneConfig(dayThreshold: 60, message: "Sixty days — you're building real strength.", badgeSymbol: "medal.fill"),
            MilestoneConfig(dayThreshold: 90, message: "Ninety days. A new chapter.",                badgeSymbol: "star.fill")
        ])
        return t
    }

    // MARK: - Milestones Accessor (T-13-06: safe try? decode; never crash on tampered JSON)

    /// Decodes the JSON milestone array stored in milestonesJSON.
    /// Returns an empty array if milestonesJSON is nil or contains malformed data.
    var milestones: [MilestoneConfig] {
        guard let json = milestonesJSON,
              let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([MilestoneConfig].self, from: data) else {
            return []
        }
        return decoded
    }

    // MARK: - JSON Encoder Helper

    /// Encodes a [MilestoneConfig] array to a JSON string suitable for storage in milestonesJSON.
    /// Returns nil if encoding fails (uses try? — never crashes).
    static func encodedMilestones(_ configs: [MilestoneConfig]) -> String? {
        guard let data = try? JSONEncoder().encode(configs),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }
}
