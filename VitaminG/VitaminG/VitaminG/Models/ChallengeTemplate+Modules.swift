import Foundation

// MARK: - ChallengeTemplate + Modules (Phase 14 — CHAL-23)

/// Typed module identifier enum, JSON decode/encode helpers, and privacy convenience
/// properties for ChallengeTemplate.
///
/// JSON decode always uses `try?` with empty-array fallback — never crashes on
/// malformed or missing data (RESEARCH.md Pattern 10 / T-14-35 threat mitigation).
extension ChallengeTemplate {

    // MARK: - Module Identifiers

    /// Strongly typed identifiers for the five Phase 14 optional modules.
    /// Raw values are the persistence contract — stored as JSON strings in
    /// `enabledModulesJSON`. Do NOT change raw values without a migration.
    enum ModuleIdentifier: String, CaseIterable {
        case spendingFreeze       = "spendingFreeze"
        case cravingTools         = "cravingTools"
        case transformationPhotos = "transformationPhotos"
        case nutritionLog         = "nutritionLog"
        case buddyAccountability  = "buddyAccountability"

        /// User-facing display name — used in ChallengeDetailView module rows (Plan 14-10).
        var displayName: String {
            switch self {
            case .spendingFreeze:       return "Spending Freeze"
            case .cravingTools:         return "Craving Tools"
            case .transformationPhotos: return "Transformation Photos"
            case .nutritionLog:         return "Nutrition Log"
            case .buddyAccountability:  return "Buddy Accountability"
            }
        }

        /// SF Symbol for module list rows.
        var systemImage: String {
            switch self {
            case .spendingFreeze:       return "snowflake"
            case .cravingTools:         return "wind"
            case .transformationPhotos: return "photo.stack.fill"
            case .nutritionLog:         return "fork.knife"
            case .buddyAccountability:  return "person.2.fill"
            }
        }
    }

    // MARK: - Enabled Modules Accessor

    /// Decoded list of enabled module identifiers.
    /// Returns an empty array if `enabledModulesJSON` is nil or contains malformed data.
    /// Uses `try?` — never throws, never crashes (T-14-35 mitigation).
    var enabledModules: [ModuleIdentifier] {
        guard let json = enabledModulesJSON,
              let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return decoded.compactMap { ModuleIdentifier(rawValue: $0) }
    }

    /// Returns `true` if the given module identifier is in `enabledModulesJSON`.
    func isModuleEnabled(_ module: ModuleIdentifier) -> Bool {
        enabledModules.contains(module)
    }

    // MARK: - Encode Helper

    /// Encodes an array of `ModuleIdentifier` values to the JSON string format
    /// stored in `enabledModulesJSON`. Returns `nil` if encoding fails.
    /// Uses `try?` — never throws (T-14-35 mitigation).
    static func encodeModules(_ modules: [ModuleIdentifier]) -> String? {
        let raws = modules.map { $0.rawValue }
        guard let data = try? JSONEncoder().encode(raws),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return json
    }

    // MARK: - Privacy Convenience (T-14-36 mitigation)

    /// `true` when `privacy` is `nil` or `"private"` — defaults to private if unset.
    var isPrivate: Bool { privacy == nil || privacy == "private" }

    /// `true` when `privacy == "community"`.
    var isCommunity: Bool { privacy == "community" }
}
