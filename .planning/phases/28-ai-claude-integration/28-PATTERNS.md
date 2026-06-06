# Phase 28: AI (Claude) Integration - Pattern Map

**Mapped:** 2026-06-06
**Files analyzed:** 8 (6 new, 2 modified)
**Analogs found:** 7 / 8 (worker/index.js has no Swift analog; JS patterns from RESEARCH.md)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Services/AIProxyService.swift` | service | request-response | `Services/WatchSessionManager.swift` | role-match (singleton pattern, init, shared) |
| `ViewModels/AIViewModel.swift` | viewmodel | request-response | `ViewModels/ExploreViewModel.swift` | exact (@Observable, @MainActor, UserDefaults gate) |
| `Views/Home/AIMotivationSection.swift` | component | request-response | `Views/HomeView.swift` `quoteSection` (lines 173–196) | exact (same card shell) |
| `Views/Explore/GoalSuggestionsCard.swift` | component | CRUD | `Views/Explore/GoalGifterCard.swift` | exact (card layout, goal insertion, GoalInput pattern) |
| `Views/HomeView.swift` (modify) | view | request-response | self | modify-in-place |
| `Views/Explore/ExploreView.swift` (modify) | view | request-response | self | modify-in-place |
| `VitaminGTests/AIProxyServiceTests.swift` | test | — | `VitaminGTests/ExploreViewModelTests.swift` | exact (UserDefaults teardown, @MainActor, setUp/tearDown) |
| `VitaminGTests/AIViewModelTests.swift` | test | — | `VitaminGTests/WatchSessionManagerTests.swift` | role-match (singleton, @MainActor, stub injection) |
| `worker/index.js` | service | request-response | — | no analog (JS, not Swift) |

---

## Pattern Assignments

### `Services/AIProxyService.swift` (service, request-response)

**Analog:** `Services/WatchSessionManager.swift`

**Imports pattern** (lines 1–5):
```swift
import Foundation
import WatchConnectivity
import SwiftData
import WidgetKit
```
For AIProxyService, import only what is needed:
```swift
import Foundation
import Observation
```

**Singleton pattern** (WatchSessionManager.swift lines 24–29):
```swift
final class WatchSessionManager: NSObject, WCSessionDelegate {

    // MARK: - Singleton
    static let shared = WatchSessionManager()
    private override init() { super.init() }
```
AIProxyService uses the same pattern without NSObject (no delegate protocol):
```swift
@Observable
final class AIProxyService {
    static let shared = AIProxyService()
    private init() {}
```

**Configuration constants pattern** — store Worker URL and shared token as private static lets (per D-11, Claude's Discretion):
```swift
private static let workerToken = "REPLACE-WITH-UUID-AT-IMPL-TIME"
private static let workerURL   = "https://vitaming-ai-proxy.YOUR_SUBDOMAIN.workers.dev/ai"
```

**Async network call + error-trigger fallback pattern** (no URLSession analog in codebase; use RESEARCH.md Pattern 2 lines 458–474):
```swift
private func post(_ payload: AIRequest) async throws -> Data {
    guard let url = URL(string: Self.workerURL) else { throw URLError(.badURL) }
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
```

**UserDefaults date-string cache key pattern** — ExploreViewModel.swift uses `Date` objects with `isDateInToday`; AIProxyService uses string keys per D-03/D-06 (different format to avoid ambiguity):
```swift
// ISO8601DateFormatter with .withFullDate → "YYYY-MM-DD"
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
```

**Cache hit check + network fetch + fallback pattern** (RESEARCH.md Pattern 2 lines 396–448):
```swift
func fetchMotivation(goals: [GoalPayload], streak: Int) async -> MotivationResult {
    let key = Self.motivationKey(for: Calendar.current.startOfDay(for: Date()))
    if let cached = UserDefaults.standard.string(forKey: key) { return .claude(cached) }
    do {
        let data = try await post(AIRequest(type: "motivation", goals: goals, streak: streak, token: Self.workerToken))
        let response = try JSONDecoder().decode(MotivationResponse.self, from: data)
        let text = response.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return fallbackMotivation() }
        UserDefaults.standard.set(text, forKey: key)
        return .claude(text)
    } catch {
        return fallbackMotivation()
    }
}
```

**Array cache as Data (not stringArray) — anti-pitfall** (RESEARCH.md Pitfall 1):
```swift
// Store [String] as JSON Data — NOT UserDefaults.standard.set([String], forKey:)
let cacheData = try JSONEncoder().encode(Array(suggestions))
UserDefaults.standard.set(cacheData, forKey: key)
// Read back:
if let cachedData = UserDefaults.standard.data(forKey: key),
   let cached = try? JSONDecoder().decode([String].self, from: cachedData) { return cached }
```

**Fallback source** — `VGQuoteBank.all` with day-of-year rotation (HomeView.swift lines 37–45):
```swift
private var todaysQuote: VGQuote {
    let all = VGQuoteBank.all
    guard !all.isEmpty else {
        return VGQuote(text: "Small steps, taken daily, build the life you've been dreaming of.", attribution: "Vitamin G")
    }
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    let index = (dayOfYear - 1) % all.count
    return all[index]
}
```
AIProxyService's `fallbackMotivation()` calls this same logic via `VGQuoteBank.todaysQuote()` or inline.

**Supporting Codable types** (no analog in codebase — define adjacent to AIProxyService):
```swift
struct GoalPayload: Codable { let title: String; let category: String }
struct AIRequest: Codable { let type: String; let goals: [GoalPayload]; let streak: Int; let token: String }
struct MotivationResponse: Codable { let text: String }
struct SuggestionsResponse: Codable { let suggestions: [String] }
enum MotivationResult {
    case claude(String)
    case fallback(String)
    var text: String { switch self { case .claude(let t), .fallback(let t): return t } }
    var isClaude: Bool { if case .claude = self { return true }; return false }
}
```

**Testability protocol** (RESEARCH.md Validation Architecture):
```swift
protocol AIProxyServiceProtocol {
    func fetchMotivation(goals: [GoalPayload], streak: Int) async -> MotivationResult
    func fetchSuggestions(goals: [GoalPayload]) async -> [String]
}
// AIProxyService: AIProxyServiceProtocol
```

---

### `ViewModels/AIViewModel.swift` (viewmodel, request-response)

**Analog:** `ViewModels/ExploreViewModel.swift`

**Class declaration pattern** (ExploreViewModel.swift lines 5–7):
```swift
@MainActor
@Observable
final class ExploreViewModel {
```
AIViewModel follows the same pattern:
```swift
@MainActor
@Observable
final class AIViewModel {
```

**State properties pattern** (ExploreViewModel.swift lines 22–38):
```swift
var isDispensing: Bool = false
var dispensedGoal: GifterGoal? = nil
private var lastActivationDate: Date? = nil
var hasGiftedToday: Bool {
    guard let stored = UserDefaults.standard.object(forKey: Keys.gifterDate) as? Date else { return false }
    return Calendar.current.isDateInToday(stored)
}
```
AIViewModel stores motivation result, loading booleans, suggestions, and added-state index set:
```swift
var motivationResult: MotivationResult = .fallback(VGQuoteBank.todaysQuote().text)
var isLoadingMotivation: Bool = false
var suggestions: [String] = AIProxyService.staticSuggestions
var addedSuggestionIndices: Set<Int> = []
var isLoadingSuggestions: Bool = false
```

**Async fetch action pattern** (ExploreViewModel.swift lines 99–103):
```swift
func fetchTrending() async {
    isFetchingTrending = true
    let live = await ExploreService.fetchTrendingGoals()
    trendingGoals = live.isEmpty ? ExploreContent.staticTrendingGoals : live
    isFetchingTrending = false
}
```
AIViewModel mirrors this exactly for both refresh methods, with `guard !isLoading` guard added.

**Computed label property** (no codebase analog — new for AI):
```swift
var motivationLabel: String {
    motivationResult.isClaude ? "YOUR DOSE" : "TODAY'S DOSE"
}
```

**WidgetDataProvider as data source** (WidgetDataProvider.swift lines 62–82):
```swift
static func build(goals: [Goal], events: [CompletionEvent], calendar: Calendar = .current) -> WidgetDisplayData {
    let globalStreak = StreakEngine.currentStreak(from: events, calendar: calendar)
    let tierRows: [WidgetDisplayData.TierRow] = GoalTier.ordered.map { tier in
        let topTitle = goals
            .filter { $0.tier == tier && !$0.isCompleted }
            .sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
            .first?.title
        return WidgetDisplayData.TierRow(tier: tier, topGoalTitle: topTitle)
    }
```
AIViewModel constructs `[GoalPayload]` from `WidgetDataProvider.build(goals:events:).tierRows`:
```swift
let data = WidgetDataProvider.build(goals: goals, events: events)
let payload = data.tierRows.compactMap { row -> GoalPayload? in
    guard let title = row.topGoalTitle else { return nil }
    return GoalPayload(title: title, category: row.tier.rawValue)
}
let streak = data.globalStreak
```

---

### `Views/Home/AIMotivationSection.swift` (component, request-response)

**Analog:** `Views/HomeView.swift` `quoteSection` (lines 173–196)

**Complete card shell to copy from** (HomeView.swift lines 173–196):
```swift
private var quoteSection: some View {
    VStack(alignment: .leading, spacing: 6) {          // spacing: 6 → CHANGE TO 8 (UI-SPEC)
        Text("TODAY'S DOSE")                           // label → aiViewModel.motivationLabel
            .font(.system(size: 9, weight: .semibold))
            .kerning(1.4)
            .textCase(.uppercase)
            .foregroundStyle(VGTheme.textMuted)
        Text(todaysQuote.text)                         // text → aiViewModel.motivationResult.text
            .font(VGTheme.serifItalic(16))
            .foregroundStyle(VGTheme.textSecondary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, 18)                          // PRESERVE — do not change to 16
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

**What changes from the analog:**
- `spacing: 6` → `spacing: 8` (UI-SPEC 4-point grid compliance)
- `"TODAY'S DOSE"` → `aiViewModel.motivationLabel` (computed: "YOUR DOSE" or "TODAY'S DOSE")
- `todaysQuote.text` → conditional: loading placeholder or `aiViewModel.motivationResult.text`
- Add `.redacted(reason: .placeholder)` branch when `aiViewModel.isLoadingMotivation`
- Add `.accessibilityLabel(...)` on the text view

**Loading state pattern** (matches `.redacted` SwiftUI pattern, no direct codebase analog):
```swift
if aiViewModel.isLoadingMotivation {
    Text("   ")
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
```

**HomeView.swift insertion point** (line 74 in body — replace `quoteSection`):
```swift
// Before (line 74):
quoteSection
// After:
AIMotivationSection(aiViewModel: aiViewModel)
```

HomeView must declare: `@State private var aiViewModel = AIViewModel()` and trigger refresh via `.task` on the ScrollView or body.

---

### `Views/Explore/GoalSuggestionsCard.swift` (component, CRUD)

**Analog:** `Views/Explore/GoalGifterCard.swift`

**Struct declaration + environment pattern** (GoalGifterCard.swift lines 1–9):
```swift
import SwiftUI
import SwiftData

struct GoalGifterCard: View {
    @Bindable var viewModel: ExploreViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var goalVM = GoalViewModel()
    @State private var showingConfetti = false
```
GoalSuggestionsCard mirrors this structure:
```swift
import SwiftUI
import SwiftData

struct GoalSuggestionsCard: View {
    @Bindable var aiViewModel: AIViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var goalVM = GoalViewModel()
```

**Card container style** (GoalGifterCard.swift lines 80–91):
```swift
.padding(18)
.background(
    LinearGradient(
        colors: [VGTheme.accentTerra.opacity(0.12), VGTheme.accentTerra.opacity(0.04)],
        startPoint: .top, endPoint: .bottom
    )
)
.clipShape(RoundedRectangle(cornerRadius: 20))
.overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(VGTheme.accentTerra.opacity(0.2), lineWidth: 1))
.padding(.horizontal, 16)
```
GoalSuggestionsCard copies this exact container style.

**Goal insertion pattern — exact template to copy** (GoalGifterCard.swift lines 105–121):
```swift
private func addGiftedGoal(_ gift: GifterGoal) {
    let input = GoalInput(
        title: gift.title,
        tier: .immediate,          // QuickWin = .immediate (Goal.swift GoalTier enum)
        category: gift.category,
        frequency: .daily,
        reminderTime: nil,
        isPrivate: true,
        startDate: Date()
    )
    if let inserted = try? goalVM.addGoal(input: input, context: modelContext) {
        inserted.associatedInspiration = "vg_gifter"
        viewModel.markGiftedToday()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation { showingConfetti = true }
    }
}
```
GoalSuggestionsCard adapts this for AI suggestions:
```swift
private func addSuggestion(title: String, at index: Int) {
    let input = GoalInput(
        title: title,
        tier: .immediate,          // QuickWin = .immediate per D-05
        category: .other,          // AI suggestions have no explicit category (A2)
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
Key difference: no `associatedInspiration` set on AI suggestions (no gifter gate to close), and `addedSuggestionIndices` tracks which suggestions are added (dimmed/checkmark state).

**Card body — suggestion row structure** (adapted from GoalGifterCard's dispensed-goal state, lines 43–61):
```swift
// Each suggestion row in a ForEach(suggestions.indices):
let isAdded = aiViewModel.addedSuggestionIndices.contains(index)
HStack {
    Text(suggestion)
        .font(.system(size: 15))
        .foregroundStyle(isAdded ? VGTheme.textMuted : VGTheme.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
    Spacer()
    if isAdded {
        Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(VGTheme.accentSage)
    } else {
        Button { addSuggestion(title: suggestion, at: index) } label: {
            Image(systemName: "plus.circle")
                .foregroundStyle(VGTheme.accentTerra)
        }
        .buttonStyle(.plain)
    }
}
```

---

### `Views/HomeView.swift` (modify — replace quoteSection)

**Target:** Lines 173–196. Replace the entire `quoteSection` computed var with a call to `AIMotivationSection`.

**Before (lines 173–196):**
```swift
private var quoteSection: some View {
    VStack(alignment: .leading, spacing: 6) {
        Text("TODAY'S DOSE")
        ...
    }
    ...
}
```

**After:**
1. Remove `quoteSection` computed var entirely (lines 173–196).
2. Remove `todaysQuote` computed var (lines 37–45) — no longer needed at the view layer; VGQuoteBank fallback moves into AIProxyService.
3. Add `@State private var aiViewModel = AIViewModel()` to the property list (after line 13).
4. In `body`, replace `quoteSection` (line 74) with `AIMotivationSection(aiViewModel: aiViewModel)`.
5. Add `.task` modifier to trigger refresh:
```swift
.task {
    await aiViewModel.refreshMotivationIfNeeded(goals: goals, events: completionEvents)
}
```

---

### `Views/Explore/ExploreView.swift` (modify — insert GoalSuggestionsCard)

**Target:** `existingScrollContent` computed var (lines 52–108). Insert after GoalGifterCard (line 57), before MoodPromptCard (lines 60–61).

**ExploreView must gain:** `@State private var aiViewModel = AIViewModel()` property.

**Before (lines 55–61):**
```swift
// Section 1: Daily Goal Gifter (EXPLORE-01, EXPLORE-02)
sectionLabel("Today's Gift")
GoalGifterCard(viewModel: viewModel)

// Section 2: Mood Prompt (EXPLORE-03) — inserted by Plan 20-02
sectionLabel("Daily Mood")
MoodPromptCard(viewModel: viewModel)
```

**After:**
```swift
// Section 1: Daily Goal Gifter (EXPLORE-01, EXPLORE-02)
sectionLabel("Today's Gift")
GoalGifterCard(viewModel: viewModel)

// Section 28-AI: Goals Suggested for You (AI-01) — inserted by Plan 28
sectionLabel("GOALS FOR YOU")
GoalSuggestionsCard(aiViewModel: aiViewModel)

// Section 2: Mood Prompt (EXPLORE-03) — inserted by Plan 20-02
sectionLabel("Daily Mood")
MoodPromptCard(viewModel: viewModel)
```

**sectionLabel behavior** (ExploreView.swift lines 120–126):
```swift
private func sectionLabel(_ text: String) -> some View {
    Text(text.uppercased())        // Already uppercases — "GOALS FOR YOU" stays "GOALS FOR YOU"
        .font(.system(size: 13, weight: .semibold))
        .kerning(0.4)
        .foregroundStyle(VGTheme.textMuted)
        .padding(.horizontal, 16)
}
```
Passing `"GOALS FOR YOU"` is already uppercase — `.uppercased()` is idempotent.

**Note:** GoalSuggestionsCard must NOT appear in the search branch (`isSearching && searchText.isEmpty` and `isSearching` branches at lines 25–45). Only `existingScrollContent` is modified.

Add `.task` modifier on `existingScrollContent`'s ScrollView or via `onAppear` to trigger:
```swift
.task {
    await aiViewModel.refreshSuggestionsIfNeeded(goals: allGoals, events: [])
}
```

---

### `VitaminGTests/AIProxyServiceTests.swift` (test)

**Analog:** `VitaminGTests/ExploreViewModelTests.swift`

**File structure pattern** (ExploreViewModelTests.swift lines 1–20):
```swift
import XCTest
@testable import VitaminG

@MainActor
final class ExploreViewModelTests: XCTestCase {

    private let gifterKey = "vg_explore_gifterDate"
    private let moodKey   = "vg_explore_moodDate"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: gifterKey)
        UserDefaults.standard.removeObject(forKey: moodKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: gifterKey)
        UserDefaults.standard.removeObject(forKey: moodKey)
        super.tearDown()
    }
```
AIProxyServiceTests mirrors this — clean UserDefaults keys in setUp/tearDown. Use the date string key format: `"vg_motivation_\(todayDateString)"` and `"vg_suggestions_\(todayDateString)"`.

**Mock injection pattern for network layer** — AIProxyService uses a protocol seam (`AIProxyServiceProtocol`) to allow mock injection without real network. Tests inject a mock that returns fixed data. Pattern per RESEARCH.md Validation Architecture:
```swift
// MockAIProxyService: AIProxyServiceProtocol
// Returns fixed MotivationResult / [String] without network call
```

**Cache hit test pattern** (after ExploreViewModelTests gifter gate pattern, lines 23–36):
```swift
// Test: fetchMotivation cache hit returns without network call
func test_fetchMotivation_cacheHit_returnsWithoutNetwork() async {
    let key = "vg_motivation_\(todayKey)"
    UserDefaults.standard.set("Cached text", forKey: key)
    let result = await AIProxyService.shared.fetchMotivation(goals: [], streak: 0)
    XCTAssertEqual(result.text, "Cached text")
    XCTAssertTrue(result.isClaude)
    UserDefaults.standard.removeObject(forKey: key)
}
```

**Fallback test pattern:**
```swift
// Test: fetchMotivation returns VGQuoteBank text when network fails
func test_fetchMotivation_networkError_returnsFallback() async {
    // No cached value, mock service returns error
    let mockService = MockAIProxyService(shouldFail: true)
    let result = await mockService.fetchMotivation(goals: [], streak: 0)
    XCTAssertFalse(result.isClaude)
    XCTAssertFalse(result.text.isEmpty)
}
```

---

### `VitaminGTests/AIViewModelTests.swift` (test)

**Analog:** `VitaminGTests/WatchSessionManagerTests.swift`

**Singleton + stub injection pattern** (WatchSessionManagerTests.swift lines 9–26):
```swift
@MainActor
final class WatchSessionManagerTests: XCTestCase {
    private var manager: WatchSessionManager!

    override func setUpWithError() throws {
        manager = WatchSessionManager.shared
    }

    override func tearDownWithError() throws {
        manager.onCheckIn = nil
        manager.cancelStreakAtRiskNudge = nil
        manager.reloadWidgetTimelines = nil
        manager = nil
    }
```
AIViewModelTests uses `@State`-style local instances (AIViewModel is not a singleton) per RESEARCH.md A3:
```swift
@MainActor
final class AIViewModelTests: XCTestCase {
    private var viewModel: AIViewModel!

    override func setUp() {
        super.setUp()
        viewModel = AIViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
```

**Label test pattern** (mirrors WatchSessionManagerTests dispatch-validation pattern):
```swift
// motivationLabel is "YOUR DOSE" for .claude result
func test_motivationLabel_cloudResult_returnsYourDose() {
    viewModel.motivationResult = .claude("Some message")
    XCTAssertEqual(viewModel.motivationLabel, "YOUR DOSE")
}

// motivationLabel is "TODAY'S DOSE" for .fallback result
func test_motivationLabel_fallbackResult_returnsTodaysDose() {
    viewModel.motivationResult = .fallback("Fallback quote")
    XCTAssertEqual(viewModel.motivationLabel, "TODAY'S DOSE")
}
```

**addedSuggestionIndices test:**
```swift
func test_addedSuggestionIndices_updatesOnInsert() {
    XCTAssertTrue(viewModel.addedSuggestionIndices.isEmpty)
    viewModel.addedSuggestionIndices.insert(0)
    XCTAssertTrue(viewModel.addedSuggestionIndices.contains(0))
    XCTAssertFalse(viewModel.addedSuggestionIndices.contains(1))
}
```

---

### `worker/index.js` (service, request-response)

**No codebase analog** — JavaScript, not Swift. Use RESEARCH.md Pattern 1 (lines 231–331) in full. Key structural elements:

- Export default with `async fetch(request, env, ctx)` signature
- OPTIONS preflight handler returning 204 with CORS headers
- Token validation against `SHARED_TOKEN` constant before any Claude call
- Prompt construction server-side, branched on `body.type`
- `fetch("https://api.anthropic.com/v1/messages", ...)` with `X-Api-Key: env.ANTHROPIC_API_KEY`
- Extract `claude.content?.[0]?.text` from Anthropic response
- Strip markdown fences before `JSON.parse` for suggestions (RESEARCH.md Pitfall 5):
  ```javascript
  const cleaned = text.replace(/```json?/g, '').replace(/```/g, '').trim();
  const parsed = JSON.parse(cleaned);
  ```
- Return thin JSON envelope per D-09
- All responses include `"Access-Control-Allow-Origin": "*"`

**wrangler.toml** (no codebase analog — standard Cloudflare config):
```toml
name = "vitaming-ai-proxy"
main = "src/index.js"
compatibility_date = "2026-06-06"
```

---

## Shared Patterns

### @Observable + @MainActor ViewModel Declaration
**Source:** `ViewModels/ExploreViewModel.swift` lines 5–7
**Apply to:** `AIViewModel.swift`
```swift
@MainActor
@Observable
final class ExploreViewModel {
```

### UserDefaults Gate Pattern (date-based, isDateInToday)
**Source:** `ViewModels/ExploreViewModel.swift` lines 33–38
**Apply to:** `AIViewModel.swift`, `Services/AIProxyService.swift`
```swift
var hasGiftedToday: Bool {
    guard let stored = UserDefaults.standard.object(forKey: Keys.gifterDate) as? Date else { return false }
    return Calendar.current.isDateInToday(stored)
}
```
Note: AIProxyService uses string keys (not Date objects) per D-03/D-06. Pattern structure is the same; key format differs.

### GoalInput Insertion via GoalViewModel.addGoal
**Source:** `Views/Explore/GoalGifterCard.swift` lines 105–121
**Apply to:** `Views/Explore/GoalSuggestionsCard.swift`
```swift
let input = GoalInput(
    title: gift.title,
    tier: .immediate,
    category: gift.category,
    frequency: .daily,
    reminderTime: nil,
    isPrivate: true,
    startDate: Date()
)
if let inserted = try? goalVM.addGoal(input: input, context: modelContext) {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
}
```

### Card Container Styling
**Source:** `Views/Explore/GoalGifterCard.swift` lines 80–91
**Apply to:** `Views/Explore/GoalSuggestionsCard.swift`
```swift
.padding(18)
.background(LinearGradient(colors: [VGTheme.accentTerra.opacity(0.12), VGTheme.accentTerra.opacity(0.04)], startPoint: .top, endPoint: .bottom))
.clipShape(RoundedRectangle(cornerRadius: 20))
.overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(VGTheme.accentTerra.opacity(0.2), lineWidth: 1))
.padding(.horizontal, 16)
```

### Singleton Pattern
**Source:** `Services/WatchSessionManager.swift` lines 27–29
**Apply to:** `Services/AIProxyService.swift`
```swift
static let shared = WatchSessionManager()
private override init() { super.init() }
```

### Section Label (ExploreView)
**Source:** `Views/Explore/ExploreView.swift` lines 120–126
**Apply to:** `Views/Explore/ExploreView.swift` (insertion of "GOALS FOR YOU" label)
```swift
private func sectionLabel(_ text: String) -> some View {
    Text(text.uppercased())
        .font(.system(size: 13, weight: .semibold))
        .kerning(0.4)
        .foregroundStyle(VGTheme.textMuted)
        .padding(.horizontal, 16)
}
```

### XCTest setUp/tearDown with UserDefaults Cleanup
**Source:** `VitaminGTests/ExploreViewModelTests.swift` lines 5–20
**Apply to:** `VitaminGTests/AIProxyServiceTests.swift`, `VitaminGTests/AIViewModelTests.swift`
```swift
@MainActor
final class ExploreViewModelTests: XCTestCase {
    override func setUp() { super.setUp(); UserDefaults.standard.removeObject(forKey: gifterKey) }
    override func tearDown() { UserDefaults.standard.removeObject(forKey: gifterKey); super.tearDown() }
}
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `worker/index.js` | service | request-response | No JavaScript files in Swift project; Worker is a separate non-Xcode artifact. Use RESEARCH.md Pattern 1 directly. |

---

## Key Anti-Patterns (Do Not Repeat)

Per RESEARCH.md — apply at planning time to avoid downstream implementation errors:

1. **Do NOT store suggestion `[String]` with `UserDefaults.standard.set([String], forKey:)`** — encode to `Data` via `JSONEncoder` first (Pitfall 1).
2. **Do NOT activate AIProxyService at `VitaminGApp.init()`** — trigger fetch from `.task` in view lifecycle, not app init (Pitfall 6).
3. **Do NOT share a single `AIViewModel` @State instance across HomeView and ExploreView** — use separate instances; `AIProxyService` singleton's UserDefaults cache is the per-day gate (Pitfall 3, A3).
4. **Do NOT cache VGQuoteBank fallback text in the motivation UserDefaults key** — only cache successful Claude responses.
5. **Do NOT change `.padding(.horizontal, 18)` in the motivation card shell** — only change `spacing: 6` → `spacing: 8`.
6. **Do NOT set `GoalTier.immediate` as a new case** — `.immediate` already exists and IS QuickWin (Goal.swift line 9).

---

## Metadata

**Analog search scope:** `VitaminG/VitaminG/VitaminG/` (Services, ViewModels, Views, Views/Explore, VitaminGTests)
**Files read:** WatchSessionManager.swift, GoalGifterCard.swift, HomeView.swift (lines 1–220), ExploreView.swift, ExploreViewModel.swift, WidgetDataProvider.swift, VGQuoteBank.swift (lines 1–40), Goal.swift (lines 1–80), ExploreViewModelTests.swift, WatchSessionManagerTests.swift (lines 1–60)
**Pattern extraction date:** 2026-06-06
