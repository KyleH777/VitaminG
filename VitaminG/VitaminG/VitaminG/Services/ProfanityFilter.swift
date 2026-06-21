import Foundation
import os

enum ProfanityFilter {
    /// Lazy static — read once from Bundle, then O(1) lookup forever.
    /// Returns empty set if the bundled file is missing (fail-open).
    static let blockedWords: Set<String> = {
        guard let url = Bundle.main.url(forResource: "profanity_list", withExtension: "txt"),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            VGLog.general.error("profanity_list.txt missing from bundle — filter will fail-open")
            return []
        }
        return Set(
            contents
                .components(separatedBy: .newlines)
                .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
    }()

    /// Whole-word case-insensitive match. Synchronous, safe to call before CKRecord write.
    /// Splits on non-alphanumeric characters to avoid substring false positives ("classy" -> "ass").
    static func containsProfanity(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return words.contains { blockedWords.contains($0) }
    }
}
