import XCTest
@testable import VitaminG

// Wave 0 RED test stubs for AIProxyService.
//
// These tests REFERENCE types that Plan 02 (Wave 1) will introduce:
//   AIProxyService, AIProxyServiceProtocol, MotivationResult, GoalPayload,
//   AIProxyService.staticSuggestions, AIProxyService.shared
//
// The VitaminGTests target build WILL FAIL until Plan 02 adds AIProxyService.swift —
// this is the expected Wave 0 RED state. Plan 02 turns these GREEN.
//
// Analog: ExploreViewModelTests.swift (UserDefaults teardown pattern, @MainActor + XCTestCase)
// Ref: 28-VALIDATION.md Wave 0 Requirements, 28-RESEARCH.md Validation Architecture (lines 902–964)

@MainActor
final class AIProxyServiceTests: XCTestCase {

    // MARK: - Today's cache key (used in setUp/tearDown)

    private var todayKey: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let today = Calendar.current.startOfDay(for: Date())
        return formatter.string(from: today)
    }

    private var motivationKey: String { "vg_motivation_\(todayKey)" }
    private var suggestionsKey: String { "vg_suggestions_\(todayKey)" }

    // MARK: - setUp / tearDown

    override func setUp() {
        super.setUp()
        // Remove both today's cache keys to prevent test cross-contamination (Pitfall 1)
        UserDefaults.standard.removeObject(forKey: motivationKey)
        UserDefaults.standard.removeObject(forKey: suggestionsKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: motivationKey)
        UserDefaults.standard.removeObject(forKey: suggestionsKey)
        super.tearDown()
    }

    // MARK: - Cache hit / miss tests (AI-02)

    /// Cache hit: seeds UserDefaults motivation key and expects AIProxyService to return it
    /// without a network call. Validates .claude result and correct text.
    func test_fetchMotivation_cacheHit_returnsWithoutNetwork() async {
        // Seed the cache with a known motivation string
        UserDefaults.standard.set("Cached motivation text", forKey: motivationKey)

        let result = await AIProxyService.shared.fetchMotivation(goals: [], streak: 0)

        XCTAssertEqual(result.text, "Cached motivation text",
                       "Cache hit must return the stored motivation text")
        XCTAssertTrue(result.isClaude,
                      "Cache hit must return MotivationResult.claude — cached copy is treated as Claude content")
    }

    /// Network error path: uses MockAIProxyService returning .fallback to verify
    /// the fallback mechanism produces a non-empty, non-Claude result.
    func test_fetchMotivation_networkError_returnsFallback() async {
        let mock = MockAIProxyService(shouldFailMotivation: true)
        let result = await mock.fetchMotivation(goals: [], streak: 0)

        XCTAssertFalse(result.isClaude,
                       "Network error must return MotivationResult.fallback, not .claude")
        XCTAssertFalse(result.text.isEmpty,
                       "Fallback motivation text must not be empty")
    }

    // MARK: - Suggestions cache hit / miss tests (AI-01)

    /// Cache hit: seeds UserDefaults suggestions key (as JSON Data per Pitfall 1) and
    /// expects AIProxyService to return the cached array without a network call.
    func test_fetchSuggestions_cacheHit_returnsCachedArray() async {
        // Encode [String] to Data — MUST use JSONEncoder (Pitfall 1: not set([String], forKey:))
        let expected = ["A", "B", "C"]
        let cacheData = try! JSONEncoder().encode(expected)
        UserDefaults.standard.set(cacheData, forKey: suggestionsKey)

        let result = await AIProxyService.shared.fetchSuggestions(goals: [])

        XCTAssertEqual(result, expected,
                       "Cache hit must return the JSON-encoded [String] stored in UserDefaults")
    }

    /// Network error path: uses MockAIProxyService returning staticSuggestions to verify
    /// the static fallback is the canonical 3-item list.
    func test_fetchSuggestions_networkError_returnsStaticFallback() async {
        let mock = MockAIProxyService(shouldFailSuggestions: true)
        let result = await mock.fetchSuggestions(goals: [])

        XCTAssertEqual(result, AIProxyService.staticSuggestions,
                       "Network error must return AIProxyService.staticSuggestions verbatim")
        XCTAssertEqual(result, ["Read for 15 minutes daily", "Drink 8 glasses of water", "Meditate for 5 minutes"],
                       "Static fallback must match the canonical 3 suggestions (D-07)")
    }

    // MARK: - Date key format tests (AI-01, AI-02)

    /// Validates the motivation UserDefaults key matches the expected "vg_motivation_YYYY-MM-DD" format.
    func test_motivationKey_matchesYYYYMMDDFormat() {
        let key = motivationKey  // "vg_motivation_YYYY-MM-DD" per D-03

        XCTAssertTrue(key.hasPrefix("vg_motivation_"),
                      "Motivation key must start with 'vg_motivation_' prefix")

        let pattern = "^vg_motivation_\\d{4}-\\d{2}-\\d{2}$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(key.startIndex..., in: key)
        let matches = regex.numberOfMatches(in: key, range: range)
        XCTAssertEqual(matches, 1,
                       "Motivation key must match YYYY-MM-DD date format: got '\(key)'")
    }

    /// Validates the suggestions UserDefaults key matches the expected "vg_suggestions_YYYY-MM-DD" format.
    func test_suggestionsKey_matchesYYYYMMDDFormat() {
        let key = suggestionsKey  // "vg_suggestions_YYYY-MM-DD" per D-06

        XCTAssertTrue(key.hasPrefix("vg_suggestions_"),
                      "Suggestions key must start with 'vg_suggestions_' prefix")

        let pattern = "^vg_suggestions_\\d{4}-\\d{2}-\\d{2}$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(key.startIndex..., in: key)
        let matches = regex.numberOfMatches(in: key, range: range)
        XCTAssertEqual(matches, 1,
                       "Suggestions key must match YYYY-MM-DD date format: got '\(key)'")
    }
}

// MARK: - MockAIProxyService

/// Inline mock conforming to AIProxyServiceProtocol for dependency injection in tests.
/// Returns configurable MotivationResult and [String] without any network call.
/// Defined here (not in a separate file) so Wave 0 test file is self-contained.
private struct MockAIProxyService: AIProxyServiceProtocol {

    var shouldFailMotivation: Bool = false
    var shouldFailSuggestions: Bool = false
    var mockMotivationResult: MotivationResult = .fallback("fallback text")
    var mockSuggestions: [String] = AIProxyService.staticSuggestions

    func fetchMotivation(goals: [GoalPayload], streak: Int) async -> MotivationResult {
        if shouldFailMotivation {
            return .fallback("fallback text")
        }
        return mockMotivationResult
    }

    func fetchSuggestions(goals: [GoalPayload]) async -> [String] {
        if shouldFailSuggestions {
            return AIProxyService.staticSuggestions
        }
        return mockSuggestions
    }
}
