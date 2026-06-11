import Foundation

/// Blocks comments containing discouraging, hostile, or negative language.
/// Applied in CommentSheetView alongside ProfanityFilter to enforce the
/// architecture-level positivity guarantee: the app structurally cannot
/// receive a discouraging comment, not just a profane one.
enum PositivityFilter {

    /// Single-word and multi-word patterns that signal negativity or hostility.
    private static let negativePatterns: Set<String> = [
        // Discouragement
        "give up", "quit trying", "stop trying", "don't bother", "waste of time",
        "no point", "won't work", "will never work", "pointless", "hopeless",
        "not worth it", "you'll fail", "you'll never", "give up already",
        // Put-downs
        "loser", "failure", "pathetic", "worthless", "disgrace", "embarrassing",
        "terrible", "awful", "horrible", "disgusting", "ridiculous",
        "stupid", "dumb", "idiot", "useless",
        // Hostile
        "hate you", "hate this", "hate that", "you suck", "this sucks",
        "worst", "i hate"
    ]

    /// Returns true if the text contains discouraging or hostile language.
    static func isNegative(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        let lower = text.lowercased()
        for phrase in negativePatterns where phrase.contains(" ") {
            if lower.contains(phrase) { return true }
        }
        let words = lower
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return words.contains { negativePatterns.contains($0) }
    }

    /// Returns true if the comment passes both positivity and profanity checks.
    static func isAllowed(_ text: String) -> Bool {
        !isNegative(text) && !ProfanityFilter.containsProfanity(text)
    }
}
