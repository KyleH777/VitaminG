# Phase 28: AI (Claude) Integration - Research

**Researched:** 2026-06-06
**Domain:** Cloudflare Workers (Node.js/JS), iOS URLSession async/await, SwiftUI @Observable, UserDefaults caching, SwiftData goal insertion
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** The existing `quoteSection` at `HomeView.swift:173` is REPLACED by the AI motivation section. Same card position, same visual shell. When Claude copy is available, section label is "YOUR DOSE"; when falling back to VGQuoteBank, label is "TODAY'S DOSE". No separate card is added — one slot, two copy sources.

**D-02:** Copy format: 2–3 sentences, warm and personal (≤40 words). The prompt to Claude must constrain length. References the user's streak count and active goal titles per AI-02. The existing card shell uses `fixedSize(horizontal: false, vertical: true)` so it accommodates paragraph copy without layout changes.

**D-03:** Caching: UserDefaults key is the calendar date string (e.g., `"vg_motivation_2026-06-06"`). At most one Claude call per calendar day. On fallback, VGQuoteBank fills the same slot — the user never sees an empty card or error state.

**D-04:** The "Goals suggested for you" card appears in the **second position** in the Explore scroll — between "Today's Gift" (GoalGifterCard) and "Daily Mood" (MoodPromptCard). Section label: "GOALS FOR YOU" (all-caps, matching existing section label style).

**D-05:** Tapping a suggestion adds the goal as **QuickWin tier** immediately (single-tap). The tapped suggestion is marked as added (checkmark or dimmed appearance) — the card stays visible with all 3 suggestions; added ones are visually distinguished.

**D-06:** Caching: UserDefaults key is the calendar date string (e.g., `"vg_suggestions_2026-06-06"`). Suggestions do not re-fetch more than once per day.

**D-07:** Fallback when Worker is unreachable: Show 3 static pre-written suggestions ("Read for 15 minutes daily", "Drink 8 glasses of water", "Meditate for 5 minutes"). Card is always present — no error state, no hidden card.

**D-08:** Single endpoint: `POST /ai`. Request body:
```json
{
  "type": "motivation" | "suggestions",
  "goals": [{ "title": "string", "category": "string" }],
  "streak": 14,
  "token": "<shared-secret>"
}
```
The `token` field is a UUID-format shared secret compiled into iOS as a constant (not the Anthropic key — acceptable to embed). Worker validates the token before forwarding to Claude.

**D-09:** Response format (thin JSON wrapper, not raw Claude API response):
- Motivation: `{ "text": "Your personalized message here." }`
- Suggestions: `{ "suggestions": ["Suggestion 1", "Suggestion 2", "Suggestion 3"] }`
The Worker extracts `content[0].text` from Claude's response, wraps it, returns the thin envelope. iOS never parses Claude's API schema directly.

**D-10:** Worker builds Claude prompts server-side from the structured payload. iOS sends structured data only — prompts can be iterated without app updates.

**D-11:** Worker auth: simple shared secret (UUID-format) sent as a field in the request body. Deters casual abuse. The Anthropic API key exists ONLY in the Worker's Cloudflare environment variables.

### Claude's Discretion

- **Motivation copy format** — 2–3 sentences, ≤40 words, warm and personal. The card's `fixedSize` layout accommodates variable paragraph length.
- **Worker token storage on iOS** — Store the shared-secret UUID as a `private static let` constant in the `AIProxyService`. It is a rate-limiting token, not a credential that grants data access — embedding as a constant is acceptable.
- **Claude model and max_tokens** — Use `claude-haiku-4-5-20251001` for both endpoints. `max_tokens: 150` for motivation, `max_tokens: 200` for suggestions. Worker sets these.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AI-03 | A Cloudflare Worker proxy is deployed at a stable URL and forwards POST requests from the iOS app to the Anthropic Messages API; the Worker holds the Anthropic API key server-side (never in the iOS binary); the Worker returns Claude's response to the app | Wrangler CLI setup, Worker code structure, `wrangler secret put ANTHROPIC_API_KEY`, CORS headers, response extraction from `content[0].text` |
| AI-01 | User opens the Explore tab and sees a "Goals suggested for you" card with 3 Claude-generated goal suggestions based on their existing goal titles and categories; tapping one adds it to their goal list with a single tap; suggestions refresh at most once per day (cached in UserDefaults) | GoalGifterCard pattern, GoalViewModel.addGoal(input:context:), AIProxyService fetchSuggestions(), date-key UserDefaults cache, GoalSuggestionsCard SwiftUI view |
| AI-02 | User sees a personalized daily motivation message on the Home tab above the My Goals list; the message is generated by Claude using the user's current streak count and active goal titles; it is cached per calendar day (one API call maximum per day) and falls back to the existing VGQuoteBank copy if the API is unavailable | quoteSection replacement, AIProxyService fetchMotivation(), date-key UserDefaults cache, VGQuoteBank fallback, WidgetDataProvider.build() as data source |
</phase_requirements>

---

## Summary

Phase 28 wires Claude-generated content into two existing screens through a Cloudflare Worker proxy. There are three distinct implementation concerns that must be sequenced carefully:

**1. Cloudflare Worker (backend):** A JavaScript Worker deployed via the Wrangler CLI holds the Anthropic API key as a Cloudflare secret (`wrangler secret put ANTHROPIC_API_KEY`). It receives POST /ai requests with a structured payload, validates a shared-secret token, builds Claude prompts server-side, calls the Anthropic Messages API (`POST https://api.anthropic.com/v1/messages` with `anthropic-version: 2023-06-01` and `X-Api-Key` header), extracts `content[0].text` from the response, and returns a thin JSON envelope. CORS headers (`Access-Control-Allow-Origin: *`, `Access-Control-Allow-Methods: POST, OPTIONS`) must be included so iOS URLSession does not reject the response.

**2. iOS AIProxyService:** An `@Observable` singleton (following `WatchSessionManager.shared` pattern) wraps all network calls. Two async methods — `fetchMotivation(goals:streak:)` and `fetchSuggestions(goals:)` — post to the Worker and return Swift values, falling back silently to VGQuoteBank / static strings on any error. All AI state (cached motivation copy, cached suggestions, cache date key) lives in UserDefaults — zero SwiftData schema changes.

**3. SwiftUI integration:** `quoteSection` in `HomeView.swift` is replaced in-place with an AI motivation section sourced from `AIProxyService`. `GoalSuggestionsCard.swift` is a new card inserted in `ExploreView.existingScrollContent` between `GoalGifterCard` and `MoodPromptCard`. Goal add-on-tap follows the `GoalGifterCard` → `GoalViewModel.addGoal(input:context:)` pattern exactly, inserting a `GoalInput` with `.immediate` tier (QuickWin = immediate in this codebase).

**Primary recommendation:** Build the Worker first (Wave 0), wire AIProxyService in isolation (Wave 1), then implement the SwiftUI cards against the live service (Waves 2-3). This keeps backend and iOS code independently testable.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Anthropic API key storage | Cloudflare Worker (env secret) | — | Key must never appear in iOS binary (REQUIREMENTS.md security decision) |
| Claude prompt construction | Cloudflare Worker | — | D-10 locked: prompts are iterated server-side without app updates |
| iOS → Worker network call | API / Service (AIProxyService) | — | MVVM: no network calls in Views |
| UserDefaults date-key cache read/write | API / Service (AIProxyService) | — | Cache gate belongs in service, not ViewModel or View |
| Motivation copy state | ViewModel (AIViewModel or extended ExploreViewModel) | — | @Observable state bound to HomeView |
| Suggestions state + added-state tracking | ViewModel (AIViewModel) | — | @Observable state bound to GoalSuggestionsCard |
| Goal insertion on suggestion tap | GoalViewModel (via addGoal(input:context:)) | — | Existing CRUD path; suggestions card calls this, does not replicate it |
| UI fallback selection (YOUR DOSE vs TODAY'S DOSE) | View (HomeView) | — | Label is a view-layer concern driven by ViewModel state |
| Skeleton / loading state | View | ViewModel boolean | isLoading bool in ViewModel, .redacted in View |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Cloudflare Workers runtime (JS) | Workers runtime (latest) | Serverless proxy for Anthropic API | Cloudflare free tier: 100K req/day; Anthropic key stored as encrypted secret; no server to maintain [VERIFIED: developers.cloudflare.com] |
| `wrangler` (npm) | 4.98.0 | CLI for deploying/configuring Workers | Official Cloudflare CLI, part of workers-sdk monorepo [VERIFIED: npm registry + github.com/cloudflare/workers-sdk] |
| Anthropic Messages API | v1 (`anthropic-version: 2023-06-01`) | LLM generation endpoint | `POST https://api.anthropic.com/v1/messages`; response at `content[0].text` [VERIFIED: platform.claude.com/docs/en/api/messages] |
| Swift URLSession (async/await) | Built-in (iOS 15+) | iOS network calls to Worker | No third-party dependency; `URLSession.shared.data(for:)` with `async throws` [ASSUMED — Apple docs, confirmed pattern in project is no third-party networking] |
| UserDefaults | Built-in | Daily cache for motivation copy and suggestions | Already used in this codebase for gifter gate, mood gate, stuck-day gate [VERIFIED: codebase grep — ExploreViewModel.swift uses this pattern] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `VGQuoteBank` (in-project) | — | Fallback motivation copy | Always available; used when Worker is unreachable or response times out |
| `WidgetDataProvider.build()` (in-project) | — | Goal data source for Claude prompt payload | Single source of truth for active goal title and streak count; use instead of re-deriving |
| `GoalViewModel.addGoal(input:context:)` (in-project) | — | Goal insertion path for suggestion tap | Existing validated CRUD path; suggestion tap must call this, not replicate it |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Cloudflare Worker | AWS Lambda / Vercel Edge | Worker free tier is 100K req/day vs Lambda's 1M/month free — Worker is lower ops overhead for a solo iOS dev; both are valid |
| URLSession directly | Alamofire | No third-party dependency aligns with project constraint in CLAUDE.md |
| UserDefaults for cache | SwiftData AI entity | STATE.md locked decision: "No SchemaV11 required for v3.0 — all v3.0 state lives in UserDefaults" |

**Installation (Worker):**
```bash
npm install -g wrangler
# or use npx wrangler for one-off commands
```

**Version verification:**
```bash
npm view wrangler version   # 4.98.0 confirmed 2026-06-06
```

---

## Package Legitimacy Audit

> Phase 28 installs one external package: `wrangler` (npm, for the Cloudflare Worker — not installed in the iOS Xcode project).

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| wrangler | npm | ~5 yrs (Cloudflare Workers SDK) | Very high (official Cloudflare CLI) | github.com/cloudflare/workers-sdk | slopcheck ran on PyPI registry (wrong ecosystem) — see note | Approved via authoritative source verification |

**Note on slopcheck:** slopcheck checked the PyPI registry (Python) and returned [OK] for a `wrangler` PyPI package, which is NOT the package being installed. The correct `wrangler` is an **npm package** verified via:
- `npm view wrangler repository` → `git+https://github.com/cloudflare/workers-sdk.git` [VERIFIED: npm registry]
- `npm view wrangler homepage` → `https://github.com/cloudflare/workers-sdk#readme` [VERIFIED: npm registry]
- Official Cloudflare Workers docs explicitly reference `npx wrangler` throughout [VERIFIED: developers.cloudflare.com]
- `npm view wrangler scripts.postinstall` → no postinstall script found (safe)

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

No npm packages are installed in the iOS Xcode project. All iOS code uses system frameworks only.

---

## Architecture Patterns

### System Architecture Diagram

```
iOS App (HomeView / ExploreView)
        │
        ▼ app foreground + date-cache miss
[AIViewModel / AIProxyService]
        │ UserDefaults.string(forKey: "vg_motivation_YYYY-MM-DD") → cache hit → return cached
        │ cache miss →
        ▼
URLSession.shared.data(for: workerRequest)  [POST /ai]
        │
        ▼
Cloudflare Worker  [POST /ai endpoint]
        │ token validation (UUID match)
        │ prompt construction (server-side)
        ▼
Anthropic Messages API  [POST https://api.anthropic.com/v1/messages]
  X-Api-Key: env.ANTHROPIC_API_KEY (secret, never in iOS binary)
  model: claude-haiku-4-5-20251001
        │
        ▼ { content: [{ type: "text", text: "..." }] }
Worker extracts content[0].text
        │
        ▼ { "text": "..." } or { "suggestions": ["...", "...", "..."] }
iOS URLSession receives thin JSON
        │
        ▼
AIProxyService decodes → writes UserDefaults cache → returns Swift value
        │
        ▼
AIViewModel publishes @Observable state → View renders
        │
        └─ on error (any URLError, HTTP non-200, decode failure)
           ▼ fallback
           VGQuoteBank.todaysQuote().text   (motivation)
           static 3 suggestions            (Explore card)
```

### Recommended Project Structure

```
VitaminG/
├── Services/
│   └── AIProxyService.swift          # new — singleton, @Observable, URLSession + UserDefaults cache
├── ViewModels/
│   └── AIViewModel.swift             # new — @Observable, @MainActor, bridges service to Views
├── Views/
│   ├── HomeView.swift                # modify — replace quoteSection with AIMotivationSection
│   └── Explore/
│       └── GoalSuggestionsCard.swift # new — SwiftUI View, mirrors GoalGifterCard layout
worker/                               # new directory at project root (outside Xcode project)
├── src/
│   └── index.js                      # Cloudflare Worker code
└── wrangler.toml                     # Worker configuration
```

### Pattern 1: Cloudflare Worker — POST /ai Handler

**What:** A JavaScript Worker that validates the shared secret, builds a Claude prompt from the structured payload, calls the Anthropic API, and returns a thin JSON envelope.

**When to use:** This is the only pattern for the Worker — all prompt construction is server-side per D-10.

```javascript
// Source: developers.cloudflare.com/workers + platform.claude.com/docs/en/api/messages
// worker/src/index.js

const SHARED_TOKEN = "replace-with-uuid-constant"; // matches iOS AIProxyService.workerToken

export default {
  async fetch(request, env, ctx) {
    // CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type",
          "Access-Control-Max-Age": "86400",
        },
      });
    }

    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    const body = await request.json();

    // Validate shared secret token (D-11)
    if (body.token !== SHARED_TOKEN) {
      return new Response("Unauthorized", { status: 401 });
    }

    const type = body.type; // "motivation" | "suggestions"
    const goals = body.goals ?? [];
    const streak = body.streak ?? 0;

    // Build prompt server-side (D-10)
    let prompt;
    let maxTokens;
    if (type === "motivation") {
      const goalTitles = goals.map(g => g.title).join(", ");
      prompt = `You are a warm, personal wellness coach. The user has a ${streak}-day streak and is working on: ${goalTitles}. Write a motivational message in 2-3 sentences, under 40 words. Be warm, personal, and specific to their goals. Do not use generic platitudes.`;
      maxTokens = 150;
    } else {
      const goalTitles = goals.map(g => `${g.title} (${g.category})`).join(", ");
      prompt = `The user is already working on these goals: ${goalTitles}. Suggest exactly 3 new, specific, actionable goals that complement their existing ones. Return ONLY a JSON array of 3 strings, nothing else. Example: ["Goal 1", "Goal 2", "Goal 3"]`;
      maxTokens = 200;
    }

    // Call Anthropic Messages API
    const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "anthropic-version": "2023-06-01",
        "X-Api-Key": env.ANTHROPIC_API_KEY,  // secret — never exposed to iOS
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: maxTokens,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!anthropicResponse.ok) {
      return new Response("Claude API error", {
        status: 502,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }

    const claude = await anthropicResponse.json();
    const text = claude.content?.[0]?.text ?? "";

    // Wrap in thin envelope (D-09)
    let responseBody;
    if (type === "motivation") {
      responseBody = { text };
    } else {
      // Parse the JSON array Claude returns for suggestions
      let suggestions = ["Read for 15 minutes daily", "Drink 8 glasses of water", "Meditate for 5 minutes"];
      try {
        const parsed = JSON.parse(text);
        if (Array.isArray(parsed) && parsed.length >= 3) {
          suggestions = parsed.slice(0, 3);
        }
      } catch (_) {
        // fallback to static if Claude returns malformed JSON
      }
      responseBody = { suggestions };
    }

    return new Response(JSON.stringify(responseBody), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  },
};
```

**wrangler.toml:**
```toml
# Source: developers.cloudflare.com/workers/wrangler/configuration/
name = "vitaming-ai-proxy"
main = "src/index.js"
compatibility_date = "2026-06-06"
```

**Deployment commands:**
```bash
# From worker/ directory
npx wrangler login
npx wrangler secret put ANTHROPIC_API_KEY   # prompts for the key value — never stored in files
npx wrangler deploy
```

---

### Pattern 2: AIProxyService — iOS Singleton

**What:** `@Observable` singleton that wraps URLSession calls with date-key UserDefaults caching. Returns Swift values; callers never see HTTP/JSON details.

**When to use:** Both HomeView (motivation) and ExploreView/GoalSuggestionsCard (suggestions) consume this service.

```swift
// Source: WatchSessionManager.swift pattern (VERIFIED: codebase) +
//         URLSession async/await (ASSUMED: Apple docs, consistent with project patterns)

import Foundation
import Observation

@Observable
final class AIProxyService {

    // MARK: - Singleton
    static let shared = AIProxyService()
    private init() {}

    // MARK: - Configuration
    // Worker token — rate-limiting shared secret, NOT the Anthropic key.
    // Acceptable to embed as a constant (D-11, CONTEXT.md Claude's Discretion).
    private static let workerToken = "REPLACE-WITH-UUID-AT-IMPL-TIME"
    private static let workerURL = "https://vitaming-ai-proxy.YOUR_SUBDOMAIN.workers.dev/ai"

    // MARK: - UserDefaults Cache Keys
    private static func motivationKey(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return "vg_motivation_\(formatter.string(from: date))"
    }

    private static func suggestionsKey(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return "vg_suggestions_\(formatter.string(from: date))"
    }

    // MARK: - Motivation (AI-02)

    /// Returns Claude motivation copy or VGQuoteBank fallback. Never throws.
    /// Cache hit: synchronous UserDefaults read, no network call.
    /// Cache miss: POST /ai, write result to UserDefaults.
    func fetchMotivation(goals: [GoalPayload], streak: Int) async -> MotivationResult {
        let today = Calendar.current.startOfDay(for: Date())
        let key = Self.motivationKey(for: today)

        // Cache hit
        if let cached = UserDefaults.standard.string(forKey: key) {
            return .claude(cached)
        }

        // Network fetch
        do {
            let payload = AIRequest(type: "motivation", goals: goals, streak: streak, token: Self.workerToken)
            let data = try await post(payload)
            let response = try JSONDecoder().decode(MotivationResponse.self, from: data)
            let text = response.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return fallbackMotivation() }
            UserDefaults.standard.set(text, forKey: key)
            return .claude(text)
        } catch {
            return fallbackMotivation()
        }
    }

    private func fallbackMotivation() -> MotivationResult {
        return .fallback(VGQuoteBank.todaysQuote().text)
    }

    // MARK: - Suggestions (AI-01)

    /// Returns 3 Claude-generated suggestions or 3 static fallbacks. Never throws.
    func fetchSuggestions(goals: [GoalPayload]) async -> [String] {
        let today = Calendar.current.startOfDay(for: Date())
        let key = Self.suggestionsKey(for: today)

        // Cache hit — stored as JSON-encoded [String]
        if let cachedData = UserDefaults.standard.data(forKey: key),
           let cached = try? JSONDecoder().decode([String].self, from: cachedData) {
            return cached
        }

        // Network fetch
        do {
            let payload = AIRequest(type: "suggestions", goals: goals, streak: 0, token: Self.workerToken)
            let data = try await post(payload)
            let response = try JSONDecoder().decode(SuggestionsResponse.self, from: data)
            let suggestions = response.suggestions.prefix(3).map { $0 }
            guard suggestions.count == 3 else { return Self.staticSuggestions }
            let cacheData = try JSONEncoder().encode(Array(suggestions))
            UserDefaults.standard.set(cacheData, forKey: key)
            return Array(suggestions)
        } catch {
            return Self.staticSuggestions
        }
    }

    static let staticSuggestions = [
        "Read for 15 minutes daily",
        "Drink 8 glasses of water",
        "Meditate for 5 minutes"
    ]

    // MARK: - Private Network Layer

    private func post(_ payload: AIRequest) async throws -> Data {
        guard let url = URL(string: Self.workerURL) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10  // Haiku is fast; 10s is generous
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

// MARK: - Supporting Types

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

enum MotivationResult {
    case claude(String)
    case fallback(String)

    var text: String {
        switch self { case .claude(let t), .fallback(let t): return t }
    }
    var isClaude: Bool {
        if case .claude = self { return true }
        return false
    }
}
```

---

### Pattern 3: AIViewModel — @Observable ViewModel

**What:** A dedicated `@MainActor @Observable` class bridging `AIProxyService` to Views. Holds loading state, motivation result, and suggestions + added-state array.

**When to use:** New — separate from ExploreViewModel to keep AI concerns isolated. Both HomeView and ExploreView/GoalSuggestionsCard reference the same `aiViewModel` instance passed as a parameter or held as a `@State`.

```swift
// Source: ExploreViewModel.swift @Observable pattern (VERIFIED: codebase)

@MainActor
@Observable
final class AIViewModel {
    var motivationResult: MotivationResult = .fallback(VGQuoteBank.todaysQuote().text)
    var isLoadingMotivation: Bool = false

    var suggestions: [String] = AIProxyService.staticSuggestions
    var addedSuggestionIndices: Set<Int> = []
    var isLoadingSuggestions: Bool = false

    // MARK: - Trigger on view appear (date-cache miss)

    func refreshMotivationIfNeeded(goals: [Goal], events: [CompletionEvent]) async {
        // Cache hit check happens inside AIProxyService — no need to check here.
        // If already loaded today, service returns instantly from UserDefaults.
        guard !isLoadingMotivation else { return }
        isLoadingMotivation = true
        let data = WidgetDataProvider.build(goals: goals, events: events)
        let payload = data.tierRows.compactMap { row -> GoalPayload? in
            guard let title = row.topGoalTitle else { return nil }
            return GoalPayload(title: title, category: row.tier.rawValue)
        }
        let streak = data.globalStreak
        motivationResult = await AIProxyService.shared.fetchMotivation(goals: payload, streak: streak)
        isLoadingMotivation = false
    }

    func refreshSuggestionsIfNeeded(goals: [Goal], events: [CompletionEvent]) async {
        guard !isLoadingSuggestions else { return }
        isLoadingSuggestions = true
        let data = WidgetDataProvider.build(goals: goals, events: events)
        let payload = data.tierRows.compactMap { row -> GoalPayload? in
            guard let title = row.topGoalTitle else { return nil }
            return GoalPayload(title: title, category: row.tier.rawValue)
        }
        suggestions = await AIProxyService.shared.fetchSuggestions(goals: payload)
        addedSuggestionIndices = []  // reset on new day's suggestions
        isLoadingSuggestions = false
    }

    var motivationLabel: String {
        motivationResult.isClaude ? "YOUR DOSE" : "TODAY'S DOSE"
    }
}
```

---

### Pattern 4: quoteSection Replacement in HomeView

**What:** Replace the `quoteSection` computed var in-place. The card shell is unchanged; only the copy source and label change.

**Key insight from codebase:** The existing `quoteSection` uses `spacing: 6` (VStack) and `.padding(.horizontal, 18)` — per 28-UI-SPEC.md, the spacing changes from 6 to 8 for grid compliance, but the `.padding(.horizontal, 18)` must NOT be changed (spec note: "do not modify the existing shell padding").

```swift
// Replaces `quoteSection` at HomeView.swift:173
// Source: HomeView.swift (VERIFIED: codebase) + 28-UI-SPEC.md (VERIFIED: phase spec)
private var aiMotivationSection: some View {
    VStack(alignment: .leading, spacing: 8) {  // spacing 6→8 per UI-SPEC
        Text(aiViewModel.motivationLabel)
            .font(.system(size: 9, weight: .semibold))
            .kerning(1.4)
            .textCase(.uppercase)
            .foregroundStyle(VGTheme.textMuted)
        if aiViewModel.isLoadingMotivation {
            Text("   ")  // two redacted lines
                .redacted(reason: .placeholder)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(aiViewModel.motivationResult.text)
                .font(VGTheme.serifItalic(16))
                .foregroundStyle(VGTheme.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Daily motivation: \(aiViewModel.motivationResult.text)")
        }
    }
    .padding(.horizontal, 18)  // PRESERVE 18pt — do not change to 16pt (UI-SPEC note)
    .padding(.vertical, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(VGTheme.surface)
    .overlay(alignment: .leading) {
        Rectangle().frame(width: 2).foregroundStyle(VGTheme.accentTerra)
    }
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .padding(.horizontal, 24)
    .padding(.top, 20)
}
```

HomeView must hold an `@State private var aiViewModel = AIViewModel()` and trigger the refresh in a `.task` modifier.

---

### Pattern 5: GoalSuggestionsCard — New SwiftUI View

**What:** New card inserted in `ExploreView.existingScrollContent` between GoalGifterCard and MoodPromptCard. Takes `AIViewModel` as a `@Bindable` parameter (or `viewModel` let).

**Key add-goal pattern from GoalGifterCard:**
```swift
// Source: GoalGifterCard.swift (VERIFIED: codebase)
// GoalGifterCard uses GoalInput + goalVM.addGoal(input:context:)
// For AI suggestions, the QuickWin tier = .immediate (Goal.swift GoalTier enum)
private func addSuggestion(title: String, at index: Int, context: ModelContext) {
    let input = GoalInput(
        title: title,
        tier: .immediate,         // QuickWin = .immediate in GoalTier enum
        category: .other,         // Suggestions have no explicit category
        frequency: .daily,
        reminderTime: nil,
        isPrivate: true,
        startDate: Date()
    )
    if (try? goalVM.addGoal(input: input, context: modelContext)) != nil {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeInOut(duration: 0.2)) {
            aiViewModel.addedSuggestionIndices.insert(index)
        }
    }
}
```

**ExploreView.existingScrollContent insertion (two lines, between Section 1 and Section 2):**
```swift
// Source: ExploreView.swift (VERIFIED: codebase)
// Section 1: Daily Goal Gifter
sectionLabel("Today's Gift")
GoalGifterCard(viewModel: viewModel)

// PHASE 28 INSERT — between Section 1 and Section 2
sectionLabel("GOALS FOR YOU")
GoalSuggestionsCard(aiViewModel: aiViewModel)

// Section 2: Mood Prompt
sectionLabel("Daily Mood")
MoodPromptCard(viewModel: viewModel)
```

Note: `sectionLabel(_:)` already uppercases via `text.uppercased()` — passing "GOALS FOR YOU" results in "GOALS FOR YOU". [VERIFIED: ExploreView.swift:121]

---

### Anti-Patterns to Avoid

- **Do NOT create a new GoalTier for QuickWin.** The `GoalTier.immediate` case IS QuickWin. GoalGifterCard confirms `.immediate` tier. No new enum case needed.
- **Do NOT put the shared-secret token or Worker URL in the Worker's git history as cleartext.** Use `wrangler secret put` for the Anthropic API key. The shared token in the Worker is a hardcoded constant (rate-limiting, not a security secret) — but keep it out of public repos.
- **Do NOT write the Worker URL as a hardcoded string across multiple iOS files.** Put it in one place: `AIProxyService.workerURL` static let.
- **Do NOT set `Access-Control-Allow-Origin` to a specific domain** — URLSession on iOS does not enforce CORS origin matching the way a browser does, but the Worker should return `*` for simplicity.
- **Do NOT await AIProxyService calls from VitaminGApp.init()**. AI fetches must trigger from view lifecycle (`.task` modifier on HomeView body) because the ModelContainer must be ready first.
- **Do NOT store suggestions as a `[String]` in a UserDefaults key using `set(_:forKey:)`.** Arrays of strings require `JSONEncoder` encoding to `Data` first — the existing gifter gate uses `Date` objects, not arrays. Use `JSONEncoder().encode([String].self)` and store the resulting `Data`.
- **Do NOT cache VGQuoteBank fallback results in the UserDefaults motivation key.** Only cache successful Claude responses. If the key is absent tomorrow, the service correctly re-fetches or re-falls-back.
- **Do NOT use `spacing: 6` in the replacement motivation VStack** — the UI-SPEC changes it to `spacing: 8` for 4-point grid compliance.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Secure Anthropic API key delivery to iOS | Custom server, embedded key in binary | Cloudflare Worker + `wrangler secret put` | Key in binary is ToS violation; Worker free tier is 100K req/day [VERIFIED: REQUIREMENTS.md security decision] |
| Per-day cache invalidation | Custom TTL or expiry logic | Date-string key per calendar day (`"vg_motivation_YYYY-MM-DD"`) | New key each day = natural cache expiry; same pattern as other Explore gates in codebase [VERIFIED: ExploreViewModel.swift] |
| Goal insertion from suggestion tap | Custom SwiftData insert | `GoalViewModel.addGoal(input:context:)` with `GoalInput` | Existing validated path; handles `rescheduleNotification`, `reloadWidgetTimelines`, sanitization [VERIFIED: GoalViewModel.swift:308] |
| Motivation fallback | Custom quote struct | `VGQuoteBank.todaysQuote()` | Already returns day-of-year rotation; same logic already in `todaysQuote` computed var in HomeView [VERIFIED: VGQuoteBank.swift + HomeView.swift:37] |
| CORS handling | Custom headers middleware | Worker OPTIONS handler pattern | Cloudflare Worker handles preflight; iOS URLSession does not enforce CORS the way browsers do but the header prevents unexpected rejections [VERIFIED: developers.cloudflare.com/workers/examples/cors-header-proxy/] |

---

## Runtime State Inventory

> Phase 28 is NOT a rename/refactor/migration phase. This section is omitted.

---

## Environment Availability Audit

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | `npx wrangler` CLI for Worker deploy | Yes | v24.14.0 | — |
| npm | `npx wrangler` | Yes | 11.9.0 | — |
| Xcode | iOS build | Yes | 26.5 (17F42) | — |
| `wrangler` CLI | Worker deploy/secrets | Not globally installed — use `npx wrangler` | 4.98.0 (npm latest) | `npx wrangler` works without global install |
| Cloudflare account | Worker deployment | Not verified — requires human | — | Human checkpoint required before AI testing |
| Anthropic API key | Worker secret | Not verified — requires human | — | Human checkpoint required before Worker deploy |

**Missing dependencies with no fallback:**
- Cloudflare account + deployed Worker URL: must exist before any AI-01/AI-02 real-device testing. Plan must include a human verification checkpoint before the first integration test.
- Anthropic API key: must be added via `wrangler secret put ANTHROPIC_API_KEY` before Worker can call Claude. Human checkpoint.

**Missing dependencies with fallback:**
- `wrangler` global install: `npx wrangler` works; no global install needed.

---

## Common Pitfalls

### Pitfall 1: Suggestions Cached as [String] Using Wrong UserDefaults Method

**What goes wrong:** `UserDefaults.standard.set(["a", "b", "c"], forKey: key)` succeeds but silently stores an `NSArray`, not the expected `[String]`. Reading back with `UserDefaults.standard.stringArray(forKey:)` works, but reading with custom decoder fails.

**Why it happens:** `UserDefaults` supports `Array` of property-list types natively, but mixing Codable `[String]` decode with direct NSArray storage is inconsistent.

**How to avoid:** Encode to `Data` with `JSONEncoder` and store as `Data`. Decode with `JSONDecoder`. This is consistent with how complex types (e.g., `Date`) are handled in tests (ExploreViewModelTests uses `Date` objects directly — the same approach works for arrays when stored as `Data`).

**Warning signs:** Cache reads return nil even though the key was written yesterday.

---

### Pitfall 2: Worker Returns 401 When iOS Sends Incorrect Token

**What goes wrong:** The shared-secret UUID in `AIProxyService.workerToken` doesn't match what's hardcoded in the Worker's `SHARED_TOKEN` constant. Every request gets a 401, triggering fallback immediately.

**Why it happens:** Two separate files must contain the same UUID string. Easy to mismatch.

**How to avoid:** Generate the UUID once (`uuidgen` in terminal), paste it into BOTH the Worker JS and the iOS `AIProxyService.workerToken` at the same time. Document it in a comment with a "generated once, never rotate" note.

**Warning signs:** All AI content shows fallback (VGQuoteBank or static suggestions) even when the Worker is deployed and the Anthropic key is valid.

---

### Pitfall 3: `.task` Fires Twice (HomeView + ExploreView) on Same Date

**What goes wrong:** Both HomeView and ExploreView might trigger refresh concurrently if the user navigates between tabs rapidly on a fresh day. Two concurrent calls to `fetchMotivation` could write the same key twice or hit the Anthropic API twice.

**Why it happens:** The `isLoadingMotivation` guard inside `AIViewModel` prevents redundant concurrent fetches but only if the same `AIViewModel` instance is shared. If HomeView and ExploreView each create their own `@State var aiViewModel = AIViewModel()`, they are separate instances.

**How to avoid:** The `AIProxyService` singleton's UserDefaults cache is the definitive gate. Even if two concurrent calls happen (rare), the second one writes the same value and the cost is one extra API call. The simpler fix: wire `AIViewModel` as a shared instance passed into both views from a parent (ContentView or equivalent), not as independent `@State` per view. Since HomeView uses motivation and ExploreView uses suggestions, they are different fetches anyway — the `isLoading` guards in `AIViewModel` are per-fetch-type.

**Warning signs:** Debug logs showing two simultaneous network calls to the Worker on app cold launch.

---

### Pitfall 4: quoteSection spacing: 6 Preserved Instead of Changed to spacing: 8

**What goes wrong:** The executor copies the existing `quoteSection` shell verbatim, including `spacing: 6`. The UI-SPEC mandates `spacing: 8`.

**Why it happens:** The UI-SPEC note about preserving `.padding(.horizontal, 18)` may cause the executor to over-preserve and leave `spacing: 6` too.

**How to avoid:** Only preserve `.padding(.horizontal, 18)`. Change `spacing: 6` → `spacing: 8`. These are independent changes.

**Warning signs:** UI audit flags `spacing: 6` as a 4-point grid violation.

---

### Pitfall 5: Worker Suggestions Prompt Returns JSON Embedded in Text

**What goes wrong:** Claude sometimes wraps JSON in markdown code fences (```json ... ```) when prompted for a JSON array. The Worker's `JSON.parse(text)` call fails, triggering the fallback to static suggestions even when the Worker is functioning.

**Why it happens:** Claude models may add markdown formatting even when instructed not to. `claude-haiku-4-5-20251001` is more compliant than larger models but still may wrap.

**How to avoid:** In the Worker's suggestions prompt, include: "Return ONLY a raw JSON array of 3 strings. No markdown, no code fences, no explanation. Example: [\"Goal 1\",\"Goal 2\",\"Goal 3\"]". Also strip markdown code fences in the Worker before parsing: `text.replace(/```json?/g, '').replace(/```/g, '').trim()`.

**Warning signs:** Suggestions always show the 3 static fallbacks even on a fresh Worker response.

---

### Pitfall 6: AIProxyService Activated Before ModelContainer Is Ready

**What goes wrong:** If `AIProxyService.shared` is activated at `VitaminGApp.init()` (like `WatchSessionManager.shared.activate()`), it cannot access `WidgetDataProvider.build()` yet because `ModelContainer` doesn't exist. The fetch would use an empty goal list.

**Why it happens:** WatchSessionManager follows the `activate()` pattern at init time — AI service should NOT follow this pattern for the data fetch (activation is fine; data fetch is not).

**How to avoid:** `AIProxyService` needs NO `activate()` call. The fetch triggers from `.task` modifier in HomeView and ExploreView (view lifecycle), at which point `@Query` goals and completion events are available. The service is stateless between fetches.

**Warning signs:** All AI responses use empty goal context ("You" + 0 streak) even when goals exist.

---

## Code Examples

### Worker Deploy Sequence

```bash
# Source: developers.cloudflare.com/workers/get-started/guide/ [VERIFIED]
# From worker/ directory at project root

npx wrangler login                           # authenticate with Cloudflare
npx wrangler secret put ANTHROPIC_API_KEY    # enter key when prompted — never stored in files
npx wrangler deploy                          # deploys to *.workers.dev URL
```

### iOS Date String Key Generation

```swift
// Source: CONTEXT.md D-03/D-06 key format + Swift ISO8601DateFormatter (ASSUMED: Apple docs)
// Key format: "vg_motivation_2026-06-06" / "vg_suggestions_2026-06-06"
let formatter = ISO8601DateFormatter()
formatter.formatOptions = [.withFullDate]  // "YYYY-MM-DD" only, no time
let today = Calendar.current.startOfDay(for: Date())
let key = "vg_motivation_\(formatter.string(from: today))"

// Cache hit check:
if let cached = UserDefaults.standard.string(forKey: key) {
    // return cached — no network call
}
```

### Goal Payload Construction from WidgetDataProvider

```swift
// Source: WidgetDataProvider.swift (VERIFIED: codebase)
// Use WidgetDataProvider.build() as the single source of truth for goal data
let data = WidgetDataProvider.build(goals: goals, events: events)
let payload = data.tierRows.compactMap { row -> GoalPayload? in
    guard let title = row.topGoalTitle else { return nil }
    return GoalPayload(title: title, category: row.tier.rawValue)
}
let streak = data.globalStreak
```

### URLSession POST with Error-Trigger Fallback

```swift
// Source: URLSession async/await pattern (ASSUMED: Apple docs, matches project conventions)
private func post(_ payload: AIRequest) async throws -> Data {
    guard let url = URL(string: Self.workerURL) else { throw URLError(.badURL) }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 10
    request.httpBody = try JSONEncoder().encode(payload)
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
        throw URLError(.badServerResponse)
    }
    return data
}
// Callers wrap in do/catch, return fallback on any error — never propagates to View
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Embedded API keys in mobile apps | Server-side proxy (Cloudflare Worker) | Anthropic ToS enforced continuously | Mandatory for App Store compliance (REQUIREMENTS.md Out of Scope table) |
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17 (2023) | Property-level invalidation; project already uses this exclusively |
| `wrangler.toml` only | `wrangler.jsonc` supported | Wrangler v3.91.0 | jsonc is recommended for new projects; toml still works |
| `curl` + shell for Anthropic API | Official SDKs available | 2024 | Worker uses `fetch()` directly (no SDK needed in Cloudflare Workers JS environment) |

**Deprecated/outdated:**
- `ObservableObject`/`@Published`: not used in this project (CLAUDE.md explicit prohibition)
- `anthropic-version` header older than `2023-06-01`: always pin to `2023-06-01` minimum

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `URLSession.shared.data(for: URLRequest)` async/await is the correct iOS pattern (no Alamofire) | Standard Stack, Pattern 2 | Low: `data(for:)` async was added in iOS 15; project targets iOS 17 minimum — confirmed available |
| A2 | `GoalCategory.other` is the right category for AI-suggested goals that have no explicit category | Pattern 5, add-goal code | Low: category is a display property only; `.other` has rawValue "Other" which is a valid GoalCategory case |
| A3 | Shared `AIViewModel` instance should be created in a parent view (ContentView or tab root) and passed to HomeView and ExploreView | Pattern 3, Pitfall 3 | Medium: if HomeView and ExploreView are not in the same parent hierarchy with easy environment access, separate instances with UserDefaults-level deduplication is an alternative |
| A4 | `claude-haiku-4-5-20251001` is a valid model ID accepted by the Anthropic Messages API as of 2026-06-06 | Standard Stack | Medium: model IDs can be retired; verify before deploying Worker; Anthropic API will return 400 with an invalid model |
| A5 | The Worker's `SHARED_TOKEN` constant can be a hardcoded UUID string (not a Cloudflare secret) without security risk | Pattern 1, Worker code | Low per CONTEXT.md D-11: "deters casual abuse"; it is not a credential that grants data access |
| A6 | `ISO8601DateFormatter` with `.withFullDate` produces "YYYY-MM-DD" matching the key format in CONTEXT.md | Code Examples | Very low: this is standard Swift behavior |

---

## Open Questions

1. **Worker subdomain URL**
   - What we know: Worker deploys to `<name>.<subdomain>.workers.dev` where subdomain is the Cloudflare account subdomain.
   - What's unclear: The exact deployed URL is unknown until `wrangler deploy` runs on the developer's Cloudflare account.
   - Recommendation: Wave 0 plan must include a human checkpoint: deploy Worker, capture URL, add it as `AIProxyService.workerURL`. All subsequent waves depend on this URL being set.

2. **claude-haiku-4-5-20251001 model ID availability**
   - What we know: This model ID is specified in CONTEXT.md Claude's Discretion section.
   - What's unclear: Model may be retired or renamed between now and execution. Anthropic does retire model versions.
   - Recommendation: Plan includes a task to verify the model ID against `GET https://api.anthropic.com/v1/models` (or Anthropic model documentation) before deploying.

3. **AIViewModel ownership: shared instance vs. per-view @State**
   - What we know: HomeView needs motivation; ExploreView needs suggestions. Both call the same `AIProxyService` singleton.
   - What's unclear: Whether ContentView already has an @Observable environment propagation pattern that can carry AIViewModel to both tabs.
   - Recommendation: The simplest approach is two separate `@State var aiViewModel = AIViewModel()` in HomeView and ExploreView respectively. Since motivation and suggestions are separate cache keys and separate async methods, concurrency issues are minimal. The UserDefaults cache acts as the definitive per-day gate regardless.

---

## Validation Architecture

> `workflow.nyquist_validation: true` in config.json — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (existing in VitaminGTests target) |
| Config file | No explicit pytest.ini — Xcode scheme handles test execution |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Full suite command | Same — all tests run in VitaminGTests target |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AI-03 | Worker token validation rejects bad token → 401 | unit (Worker JS logic, not iOS) | Manual Worker curl test | N/A — JS not in Xcode |
| AI-03 | Worker returns `{ "text": "..." }` for motivation type | integration (real Worker) | curl POST to deployed URL | N/A — human verify |
| AI-01 | fetchSuggestions returns 3 items on mock success | unit | `xcodebuild test ... -only-testing:VitaminGTests/AIProxyServiceTests` | ❌ Wave 0 |
| AI-01 | fetchSuggestions returns staticSuggestions on network error | unit | same | ❌ Wave 0 |
| AI-01 | UserDefaults suggestions cache hit returns immediately without network call | unit | same | ❌ Wave 0 |
| AI-01 | addSuggestion inserts Goal with tier .immediate | unit | `xcodebuild test ... -only-testing:VitaminGTests/AIViewModelTests` | ❌ Wave 0 |
| AI-01 | addedSuggestionIndices updated after successful insert | unit | same | ❌ Wave 0 |
| AI-02 | fetchMotivation returns VGQuoteBank text on network error | unit | `xcodebuild test ... -only-testing:VitaminGTests/AIProxyServiceTests` | ❌ Wave 0 |
| AI-02 | fetchMotivation cache hit reads UserDefaults key without network call | unit | same | ❌ Wave 0 |
| AI-02 | motivationLabel is "YOUR DOSE" for .claude result, "TODAY'S DOSE" for .fallback | unit | `xcodebuild test ... -only-testing:VitaminGTests/AIViewModelTests` | ❌ Wave 0 |
| AI-01/AI-02 | Date string key format matches "vg_motivation_YYYY-MM-DD" / "vg_suggestions_YYYY-MM-DD" | unit | same | ❌ Wave 0 |

**Tests that CANNOT be automated (require deployed Worker or real device):**
- AI-03: Anthropic API key is server-side only — verifiable by `strings` scan on .ipa (manual, per success criterion)
- AI-01/AI-02: End-to-end Claude response quality — human review on device
- AI-02: Fallback-to-Claude transition on app re-launch after Worker downtime — manual simulation

### Testing AIProxyService Without a Real Worker

The `AIProxyService` should be protocol-backed for testability:

```swift
// Wave 0: define protocol for dependency injection in tests
protocol AIProxyServiceProtocol {
    func fetchMotivation(goals: [GoalPayload], streak: Int) async -> MotivationResult
    func fetchSuggestions(goals: [GoalPayload]) async -> [String]
}
// AIProxyService conforms to this protocol
// Tests inject a mock that returns fixed data without network
```

This enables all unit tests to run without a deployed Worker.

### Sampling Rate

- **Per task commit:** `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/AIProxyServiceTests -only-testing:VitaminGTests/AIViewModelTests`
- **Per wave merge:** Full `VitaminGTests` suite
- **Phase gate:** Full suite green + human real-device verification before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `VitaminGTests/AIProxyServiceTests.swift` — covers AI-01, AI-02 cache hit/miss, fallback paths
- [ ] `VitaminGTests/AIViewModelTests.swift` — covers motivationLabel, addedSuggestionIndices, goal insert tier
- [ ] Worker test: `worker/test-worker.sh` — curl script for manual smoke test of deployed Worker endpoints

*(No new test fixtures needed — tests use `UserDefaults(suiteName: UUID().uuidString)` for isolation, matching existing ExploreViewModelTests pattern)*

---

## Security Domain

> `security_enforcement` not set to false in config — this section is required.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Partial | Shared-secret token in request body (D-11); not full auth but deters casual abuse |
| V3 Session Management | No | No session state; stateless per-request |
| V4 Access Control | No | Worker is public endpoint with token gate only |
| V5 Input Validation | Yes | Worker must validate `type` field is exactly "motivation" or "suggestions"; iOS must validate decoded suggestion strings are non-empty and within reasonable length |
| V6 Cryptography | No | Anthropic API key stored as Cloudflare encrypted secret (not custom crypto) |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Anthropic API key extraction from iOS binary | Information Disclosure | Cloudflare Worker holds key server-side (D-11, mandatory) |
| Worker endpoint abuse / cost amplification | Elevation of Privilege | Shared-secret token gate (D-11); Cloudflare rate limiting (free tier limits apply) |
| Prompt injection via goal titles | Tampering | Worker prompt construction uses goal titles as data within a fixed template, not as executable instructions; max_tokens cap limits response surface |
| Malformed Worker response crashing iOS | Denial of Service | `try?` decode with fallback to static data; never force-unwrap Claude response |
| Stored XSS via Claude-generated suggestion text shown in SwiftUI | Tampering | SwiftUI Text() renders as plain text — no HTML/JS execution risk |
| iOS goal title exfiltration to Cloudflare logs | Information Disclosure | Goal titles are sent to Worker in payload; worker.dev logs are scoped to developer's Cloudflare account only |

### Security Implementation Notes

1. The Anthropic API key MUST be set via `wrangler secret put ANTHROPIC_API_KEY` — never committed to git, never in wrangler.toml, never in iOS code. [VERIFIED: REQUIREMENTS.md "Out of Scope" table — "Embedded Anthropic API key: ToS violation + security risk"]

2. The shared-secret UUID token in iOS (`AIProxyService.workerToken`) and the Worker JS (`SHARED_TOKEN`) is intentionally NOT a security credential — it is a lightweight abuse deterrent. Do not treat it as a password. [VERIFIED: CONTEXT.md D-11]

3. Input validation in Worker: check that `body.type` is exactly `"motivation"` or `"suggestions"` before building prompts. Reject unknown types with 400.

---

## Sources

### Primary (HIGH confidence)
- [developers.cloudflare.com/workers/examples/cors-header-proxy/](https://developers.cloudflare.com/workers/examples/cors-header-proxy/) — CORS header pattern for Worker
- [developers.cloudflare.com/workers/configuration/secrets/](https://developers.cloudflare.com/workers/configuration/secrets/) — `wrangler secret put` and `env.ANTHROPIC_API_KEY` access
- [platform.claude.com/docs/en/api/messages](https://platform.claude.com/docs/en/api/messages) — Anthropic Messages API: endpoint, headers, request/response schema, `content[0].text`
- [npm registry: wrangler v4.98.0](https://www.npmjs.com/package/wrangler) — verified as official Cloudflare CLI from `github.com/cloudflare/workers-sdk`
- Codebase: `ExploreViewModel.swift`, `GoalGifterCard.swift`, `WatchSessionManager.swift`, `WidgetDataProvider.swift`, `VGQuoteBank.swift`, `GoalViewModel.swift`, `HomeView.swift`, `ExploreView.swift`, `SchemaV9.swift` — all VERIFIED by file read

### Secondary (MEDIUM confidence)
- [developers.cloudflare.com/workers/get-started/guide/](https://developers.cloudflare.com/workers/get-started/guide/) — Wrangler quickstart, wrangler.toml structure
- [developers.cloudflare.com/workers/wrangler/configuration/](https://developers.cloudflare.com/workers/wrangler/configuration/) — `name`, `main`, `compatibility_date` fields

### Tertiary (LOW confidence / ASSUMED)
- URLSession `data(for:)` async/await pattern — consistent with Apple docs and multiple 2024-2026 blog sources; project uses no networking yet so no codebase reference
- ISO8601DateFormatter `.withFullDate` producing "YYYY-MM-DD" — standard Swift behavior, not verified against Apple docs in this session

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — Worker/Anthropic API verified against official docs; iOS stack verified against codebase
- Architecture: HIGH — all integration points traced from actual source files
- Pitfalls: HIGH — most derived from codebase patterns and API documentation, not speculation
- Cloudflare Worker code example: MEDIUM — pattern correct, exact Worker URL and model ID require human verification at deploy time

**Research date:** 2026-06-06
**Valid until:** 2026-07-06 (model IDs may be retired; re-verify `claude-haiku-4-5-20251001` before deploying)
