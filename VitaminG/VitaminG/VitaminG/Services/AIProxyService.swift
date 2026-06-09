import Foundation
import Observation

// MARK: - Supporting Codable Types

struct GoalPayload: Codable {
    let title: String
    let category: String
}

struct AIRequest: Codable {
    let type: String
    let goals: [GoalPayload]
    let streak: Int
    let token: String
}

struct MotivationResponse: Codable {
    let text: String
}

struct SuggestionsResponse: Codable {
    let suggestions: [String]
}

// MARK: - MotivationResult

enum MotivationResult {
    case claude(String)
    case fallback(String)

    var text: String {
        switch self {
        case .claude(let t), .fallback(let t): return t
        }
    }

    var isClaude: Bool {
        if case .claude = self { return true }
        return false
    }
}

// MARK: - AIProxyServiceProtocol

protocol AIProxyServiceProtocol {
    func fetchMotivation(goals: [GoalPayload], streak: Int) async -> MotivationResult
    func fetchSuggestions(goals: [GoalPayload]) async -> [String]
}

// MARK: - AIProxyService

/// Singleton @Observable network service conforming to AIProxyServiceProtocol.
/// Posts to the Cloudflare Worker proxy at workerURL, caches Claude responses under
/// date-key UserDefaults entries (D-03/D-06), and silently falls back to VGQuoteBank
/// or staticSuggestions on any network error (T-28-08).
///
/// Security: workerToken matches SHARED_TOKEN set in Plan 01 (T-28-02).
/// No Anthropic API key appears in this file; only the Cloudflare Worker URL is referenced (T-28-01).
@Observable
final class AIProxyService: AIProxyServiceProtocol {

    // MARK: - Singleton

    static let shared = AIProxyService()
    private init() {}

    // MARK: - Configuration

    private static let workerToken = "020A3129-9FDB-4817-8C8F-EA1A27F59A38"
    private static let workerURL = "https://vg-ai-proxy.kileharrington.workers.dev/ai"

    // MARK: - Static Fallback Suggestions (D-07)

    /// Canonical 3-item static fallback list. Must match Worker's fallback array.
    static let staticSuggestions: [String] = [
        "Read for 15 minutes daily",
        "Drink 8 glasses of water",
        "Meditate for 5 minutes"
    ]

    // MARK: - Cache Key Generators (D-03, D-06)

    /// Returns the UserDefaults key for today's motivation copy.
    /// Format: "vg_motivation_YYYY-MM-DD" using ISO8601 full-date encoding.
    private static func motivationKey(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return "vg_motivation_\(formatter.string(from: date))"
    }

    /// Returns the UserDefaults key for today's suggestions array.
    /// Format: "vg_suggestions_YYYY-MM-DD" using ISO8601 full-date encoding.
    private static func suggestionsKey(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return "vg_suggestions_\(formatter.string(from: date))"
    }

    // MARK: - fetchMotivation (AI-02)

    /// Returns today's Claude motivation copy, reading from UserDefaults cache first.
    /// On cache miss, POSTs to the Worker. On any error, falls back to VGQuoteBank.
    /// Only successful Claude responses are written to the cache (not fallback text).
    func fetchMotivation(goals: [GoalPayload], streak: Int) async -> MotivationResult {
        let key = Self.motivationKey(for: Calendar.current.startOfDay(for: Date()))

        // Cache hit: return stored copy as .claude without network call (Test 1)
        if let cached = UserDefaults.standard.string(forKey: key) {
            return .claude(cached)
        }

        // Network path
        let payload = AIRequest(type: "motivation", goals: goals, streak: streak, token: Self.workerToken)
        do {
            let data = try await post(payload)
            let response = try JSONDecoder().decode(MotivationResponse.self, from: data)
            let text = response.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                return fallbackMotivation()
            }
            // Write only successful Claude text to cache — never fallback (PATTERNS.md anti-pattern)
            UserDefaults.standard.set(text, forKey: key)
            return .claude(text)
        } catch {
            return fallbackMotivation()
        }
    }

    // MARK: - fetchSuggestions (AI-01)

    /// Returns today's AI goal suggestions, reading from JSON Data cache first.
    /// On cache miss, POSTs to the Worker. On any error, returns staticSuggestions.
    /// Suggestions are stored as JSON-encoded Data (not [String]) per Pitfall 1 / T-28-05.
    func fetchSuggestions(goals: [GoalPayload]) async -> [String] {
        let key = Self.suggestionsKey(for: Calendar.current.startOfDay(for: Date()))

        // Cache hit: decode [String] from JSON Data (Pitfall 1: not UserDefaults set([String]) — only Data)
        if let cachedData = UserDefaults.standard.data(forKey: key),
           let cached = try? JSONDecoder().decode([String].self, from: cachedData) {
            return cached
        }

        // Network path
        let payload = AIRequest(type: "suggestions", goals: goals, streak: 0, token: Self.workerToken)
        do {
            let data = try await post(payload)
            let response = try JSONDecoder().decode(SuggestionsResponse.self, from: data)
            let suggestions = Array(response.suggestions.prefix(3))
            guard suggestions.count == 3 else {
                return Self.staticSuggestions
            }
            // Encode [String] to Data before writing (T-28-05 mitigation, Pitfall 1)
            let cacheData = try JSONEncoder().encode(suggestions)
            UserDefaults.standard.set(cacheData, forKey: key)
            return suggestions
        } catch {
            return Self.staticSuggestions
        }
    }

    // MARK: - Private Network Layer

    /// Posts an AIRequest payload to the Worker and returns the raw response Data.
    /// Throws URLError on bad URL, non-2xx HTTP status, or network failure.
    /// timeoutInterval = 10 caps wait time (T-28-08 DoS mitigation).
    private func post(_ payload: AIRequest) async throws -> Data {
        guard let url = URL(string: Self.workerURL) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        request.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    // MARK: - Fallback

    /// Returns the VGQuoteBank day-of-year quote as a .fallback result.
    /// This result is NEVER written to the UserDefaults motivation cache key.
    private func fallbackMotivation() -> MotivationResult {
        return .fallback(VGQuoteBank.todaysQuote().text)
    }
}
