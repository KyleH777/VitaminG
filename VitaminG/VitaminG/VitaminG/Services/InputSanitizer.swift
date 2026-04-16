import Foundation

// MARK: - InputSanitizer

/// Centralised input sanitization shared by GoalViewModel and ProfileViewModel.
/// Ensures consistent cleaning of user text across the app.
enum InputSanitizer {

    /// Strips control characters, normalises whitespace, and trims leading/trailing whitespace.
    /// Preserves intentional newlines in multi-line fields.
    static func sanitize(_ raw: String) -> String {
        let blocked = CharacterSet.controlCharacters
            .union(.illegalCharacters)
            .subtracting(.newlines)
        let stripped = raw.unicodeScalars
            .filter { !blocked.contains($0) }
            .reduce(into: "") { $0.unicodeScalars.append($1) }

        // Collapse internal runs of whitespace (spaces + tabs) to a single space,
        // but preserve intentional newlines in multi-line fields.
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

    /// Sanitizes with additional HTML/script-injection character stripping.
    /// Used for fields that may be exposed publicly (e.g., profile display names).
    static func sanitizeForPublic(_ raw: String) -> String {
        var blocked = CharacterSet.controlCharacters
            .union(.illegalCharacters)
            .subtracting(.newlines)
        blocked.insert(charactersIn: "<>\"'")
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
