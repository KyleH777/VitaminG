# Architecture: VitaminG v3.0 Feature Integration

**Milestone:** v3.0 Personal Intelligence + Apple Watch
**Researched:** 2026-05-28
**Scope:** How the 4 new v3.0 feature areas integrate with existing MVVM + SwiftData (SchemaV10) + CloudKit + WidgetKit + MVVM architecture

---

## Existing Architecture Snapshot (v2.0 — Phase 24 complete)

- **Schema:** SchemaV10 (10 schema versions; `VitaminGMigrationPlan` with 9 lightweight stages)
- **Persistence:** `ModelContainerFactory` — App Group container (`group.com.kyleharrington.VitaminG`), `cloudKitDatabase: .none` in current build; `makeWidgetContainer()` mirrors same config, read-only from widget process
- **Core models (SchemaV10):** `Goal`, `CompletionEvent` (V2), `UserProfile`, `DailyWin` (V3), `ChallengeTemplate`/`UserChallenge`/`CheckIn` (V4), `GoalIdea`/`MoodEntry` (V7)
- **Streak computation:** `StreakEngine` — pure static struct, derives everything from `CompletionEvent` records; `StatsViewModel` owns heatmap + streak display state
- **Notifications:** `NotificationScheduler` — 3 identifiers (daily reminder, win reminder, global streak-at-risk); `UNCalendarNotificationTrigger` repeats; `NotificationPreferences` (enum) bridges UserDefaults ↔ App Group UserDefaults
- **Widget target:** `VitaminGWidget` — `makeWidgetContainer()`, `WidgetDataProvider` (pure static func building `WidgetDisplayData` from Goal/CompletionEvent arrays), `StreakWidget` + `GoalSummaryWidget`
- **Watch target:** `VGWatchApp` exists in Xcode project (`com.kyleharrington.VitaminG.watchkitapp`, SDKROOT = watchos, WATCHOS_DEPLOYMENT_TARGET = 7.0). Current state: scaffold-only — all views use hardcoded data. No SwiftData wiring, no App Intents, no complications registered.
- **Tab structure (v2.0):** Home · Goals · Explore · Community · Profile

---

## Feature 1: Apple Watch App

### Current State Assessment

The WatchOS target exists (`VGWatchApp`, `VGWatchContentView`, Screens/*, Shared/*) but is purely a design scaffold. `TodayGlanceView` has a hardcoded `@State private var checkedIn = false` with no SwiftData context. `WatchGoalListView` uses hardcoded `GoalItem` structs. No `ModelContainer` is injected in `VGWatchApp.body`.

### Data Sharing: WatchConnectivity, Not App Groups or CloudKit

App Groups work for on-device extension-to-app sharing (the widget uses this). They do NOT work across devices (iPhone to Apple Watch). CloudKit sync from iOS to watchOS has been unreliable in practice — multiple developer forum threads confirm SwiftData + CloudKit sync fails to reach Apple Watch even with matching container identifiers. The recommended, reliable approach is WatchConnectivity.

**Verdict: Use WatchConnectivity (WCSession) to push a lightweight data snapshot from the iOS app to the Watch app on demand and on foreground.** The Watch app does NOT open SwiftData directly.

**Data flow:**
```
iOS App (SwiftData source of truth)
  → WatchSessionManager (new iOS service)
    → WCSession.sendMessage() / updateApplicationContext()
      → Watch WatchSessionDelegate (new Watch service)
        → WatchAppState (new @Observable on Watch)
          → TodayGlanceView / WatchGoalListView / complications
```

The snapshot sent over WCSession is a lightweight `[String: Any]` dictionary (Codable struct encoded to JSON Data then to `[String: Any]`):
```swift
struct WatchSnapshot: Codable {
    let globalStreak: Int
    let activeGoalTitle: String?
    let activeGoalProgress: Double?  // 0.0–1.0
    let todayCheckedIn: Bool
    let topGoalTitles: [String]      // up to 4, one per tier
    let updatedAt: Date
}
```

`updateApplicationContext()` is preferred over `sendMessage()` for this use case — it delivers the latest state even when the Watch app is not in the foreground, and the Watch receives it on next launch. `sendMessage()` is used for the interactive check-in action (requires both sides reachable).

### Complications: WidgetKit on watchOS 10+

WatchOS 9 migrated complications to WidgetKit (deprecating ClockKit). Interactive complications (AppIntent-driven actions) require watchOS 11+.

**Recommendation: Target watchOS 10 for read-only complications (streak count, goal progress ring), watchOS 11 for interactive check-in complication button.**

The existing `VitaminGWidget` target uses `AppIntentConfiguration` already for iOS. The Watch complication target is a separate WidgetKit extension that must be added under the WatchOS target in Xcode. It shares the complication families `accessoryCircular` (streak count), `accessoryRectangular` (goal title + ring), and `accessoryCorner`.

The Watch complication reads data from the WatchOS App Group UserDefaults (written by the Watch app's `WatchSessionDelegate` when a WCSession message arrives). This mirrors the iOS widget pattern exactly — data in a shared container, complication reads a snapshot.

**Check-in from wrist (watchOS 11+ interactive):**
```swift
struct WatchCheckInIntent: AppIntent {
    static var title: LocalizedStringResource = "Check In Today"

    func perform() async throws -> some IntentResult {
        // 1. Write check-in confirmation to Watch App Group UserDefaults
        // 2. Send WCSession message to iOS: ["action": "checkIn", "timestamp": ISO8601 date]
        // 3. iOS WatchSessionManager receives → creates CompletionEvent in SwiftData → reschedules notifications
        return .result()
    }
}
```

The iOS side handles the actual SwiftData write. The Watch side optimistically updates local display state.

### WatchOS Deployment Target

Change from `WATCHOS_DEPLOYMENT_TARGET = 7.0` to `10.0` (required for WidgetKit complications). Use `@available(watchOS 11.0, *)` guard for interactive Button(intent:) elements — fall back to a tap on the complication that deep-links to the app on watchOS 10.

### Morning Nudge to Watch

iOS schedules a `UNCalendarNotificationTrigger` notification. When the device is paired with a Watch and the Watch app is installed, watchOS automatically mirrors eligible iOS notifications to the Watch. No separate watchOS notification scheduling is needed — the existing `NotificationScheduler.schedule()` handles this. The `WatchNotificationView` (scaffold) becomes the Watch notification interface controller.

### New Components (Watch Feature)

| Component | Target | Type | Purpose |
|-----------|--------|------|---------|
| `WatchSessionManager` | iOS | @Observable service | Sends WatchSnapshot via WCSession on goal/check-in changes; listens for check-in confirmations from Watch |
| `WatchSessionDelegate` | watchOS | NSObject + WCSessionDelegate | Receives snapshot from iOS; writes to Watch App Group UserDefaults; relays check-in action back to iOS |
| `WatchAppState` | watchOS | @Observable | In-memory state for Watch UI — globalStreak, activeGoalTitle, todayCheckedIn; populated from WatchSessionDelegate |
| `WatchSnapshot` | Shared (or duplicated) | Codable struct | Lightweight DTO crossing the WCSession boundary |
| `WatchCheckInIntent` | watchOS | AppIntent | Interactive complication action (watchOS 11+) |
| `VGWatchComplicationBundle` | watchOS extension | WidgetBundle | Registers streak + goal complications |
| `StreakComplication` | watchOS extension | Widget (accessoryCircular) | Displays global streak count |
| `GoalProgressComplication` | watchOS extension | Widget (accessoryRectangular) | Displays active goal title + progress ring |

### Modified Existing Components (Watch Feature)

| Component | Changes |
|-----------|---------|
| `VGWatchApp` | Inject `WatchAppState` via `.environment()`; activate `WCSession` on launch via `WatchSessionDelegate` |
| `TodayGlanceView` | Consume `@Environment(WatchAppState.self)` instead of hardcoded state; wire check-in button to `WatchCheckInIntent` or WCSession message |
| `WatchGoalListView` | Consume `WatchAppState.topGoalTitles` instead of hardcoded `GoalItem` array |
| `WatchFaceView` | Consume `WatchAppState` for streak count and progress values |
| `GoalViewModel` | On completion toggle → call `WatchSessionManager.sendSnapshot()` |
| `NotificationScheduler` | No change needed — iOS notifications mirror to Watch automatically |
| `ModelContainerFactory` | No change — Watch does NOT open SwiftData |

---

## Feature 2: Analytics Dashboard

### Data Source Assessment

All analytics data is already in SwiftData. No new storage is needed.

- **Streak history over time:** Requires walking `CompletionEvent` records chronologically. `StreakEngine.bestStreak()` gives the all-time best. A new computed function deriving per-period streak lengths (e.g., "streak as of week N") requires iterating grouped events. This is a new computation in `StreakEngine` or a new `AnalyticsEngine` struct.
- **Completion rate trends (weekly/monthly):** Group `CompletionEvent.completedAt` by ISO week or month, compute unique-goal completion rates per bucket. Derivable from existing `CompletionEvent` records.
- **All-time heatmap:** `StatsViewModel.heatmapData` already computes `[Date: Int]` — the dashboard heatmap is a larger rendering of this same data, not a new model.
- **CSV export:** Generate a CSV string from `Goal` + `CompletionEvent` records in memory, present via `ShareLink` with `ShareLink(item: csvString)` — no new storage needed.

**Verdict: No new SwiftData models. No SchemaV11 required for analytics.** All data derives from existing `Goal` and `CompletionEvent` records.

### Swift Charts Integration

Swift Charts (iOS 16+, enhanced in iOS 17) is the correct primitive. No third-party chart library needed.

- **Line/bar chart (streak history):** `Chart { ForEach(streakPeriods) { LineMark(...) } }` or `BarMark`
- **Completion rate trend:** `BarMark` grouped by week/month with a `chartXSelection` gesture for iOS 17 tooltip
- **Heatmap:** The existing heatmap uses a custom `LazyVGrid` + colored cells. The analytics dashboard version is the same component scaled to full-screen with a date range picker.
- **CSV export:** `ShareLink(item: csvString, preview: SharePreview("Goal History"))` — zero dependency on charts; pure data export.

### New Components (Analytics)

| Component | Type | Purpose |
|-----------|------|---------|
| `AnalyticsDashboardView` | View | Full-screen analytics screen with tab/segment for different chart types |
| `AnalyticsDashboardViewModel` | @Observable ViewModel | Owns chart data arrays; calls AnalyticsEngine; owns CSV generation |
| `AnalyticsEngine` | Static struct | Pure computation: streakHistory(events:), completionRateTrend(events:goals:period:), generateCSV(goals:events:); testable |
| `StreakPeriod` | Value type (struct) | DTO for chart: `startDate`, `endDate`, `length` |
| `CompletionRateBucket` | Value type (struct) | DTO for chart: `periodLabel`, `rate` |

### Modified Existing Components (Analytics)

| Component | Changes |
|-----------|---------|
| `StatsViewModel` | Consider whether to extend or keep separate. Recommendation: keep `StatsViewModel` for the existing Stats screen (streak cards, existing heatmap); `AnalyticsDashboardViewModel` is a new, separate ViewModel for the new dashboard view |
| `AppRoute` | Add `case analyticsDashboard` |
| `StreakEngine` | Optionally add `streakHistory(from events:, calendar:) -> [StreakPeriod]` — or put this in `AnalyticsEngine` to keep `StreakEngine` single-purpose |

---

## Feature 3: AI (Claude via Anthropic API)

### API Key Storage

The Anthropic API key must NEVER be embedded in source code or any committed file. It must be stored in the iOS Keychain at runtime.

**Recommended pattern — `KeychainService` wrapper (no third-party dependency):**
```swift
enum KeychainService {
    private static let service = "com.kyleharrington.VitaminG"

    static func save(key: String, value: String) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary)  // Remove before add
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed(status) }
    }

    static func load(key: String) throws -> String {
        // SecItemCopyMatching pattern
    }
}
```

The API key is entered by the user in Settings (one-time setup), stored in Keychain, read at network call time. It is never read at app launch, never stored in UserDefaults or AppStorage. This is the same security posture as apps like Prompt or SSH clients.

**App Store consideration:** Calling the Anthropic API directly from an iOS app with a user-supplied key is analogous to a "bring your own API key" model. Apple does not prohibit this pattern. The key risk is accidental exposure in logs — ensure the key is never logged. A future v3.1 path could proxy through a server, but for v3.0 user-supplied key in Keychain is the pragmatic choice that avoids backend infrastructure.

### Anthropic API Integration (No Third-Party SDK)

Per the project constraint ("no third-party dependencies unless necessary"), implement direct HTTP using `URLSession`:

```
POST https://api.anthropic.com/v1/messages
Headers:
  x-api-key: {keychainApiKey}
  anthropic-version: 2023-06-01
  content-type: application/json
Body:
  { "model": "claude-3-haiku-20240307",
    "max_tokens": 256,
    "messages": [{ "role": "user", "content": "{prompt}" }] }
```

`claude-3-haiku-20240307` is the right model choice for this use case: fast, cheap, sufficient capability for goal suggestions and motivation copy. Use `claude-3-5-sonnet` only if quality proves insufficient.

Non-streaming is adequate for both use cases (goal suggestions = single JSON block; daily motivation = single paragraph). Streaming adds implementation complexity for minimal UX gain at these token lengths.

### Two AI Features and Their Prompts

**Goal Suggestions:**
- Input context: up to 10 existing goal titles + tiers (passed as a compact list)
- Output: 3–5 suggested complementary goals as a JSON array `[{"title": "...", "tier": "immediate|shortTerm|longTerm|lifeGoal"}]`
- Prompt instructs Claude to: analyze the user's existing goals, identify gaps across tiers, suggest goals that are specific, achievable, and complementary
- Parse with `JSONDecoder` — validate output schema before presenting to user

**Daily Motivation:**
- Input context: current global streak, today's active goal count, top goal title
- Output: 1–2 sentence motivational message (plain text, no JSON needed)
- Prompt instructs Claude to: be specific about the streak and goal, match tone to streak length (celebratory at 7+, encouraging at 1–3, resilient after break)
- Cached in UserDefaults keyed by calendar day — regenerate only once per day, not on every app open

### New Components (AI)

| Component | Type | Purpose |
|-----------|------|---------|
| `AnthropicService` | Actor or @MainActor service | URLSession-based API client; `func suggestGoals(existingGoals: [Goal]) async throws -> [GoalSuggestion]`; `func generateMotivation(streak: Int, goalTitle: String?) async throws -> String` |
| `GoalSuggestion` | Codable struct | `title: String`, `tier: GoalTier`, `rationale: String?` |
| `KeychainService` | Enum | Generic Keychain read/write/delete using Security framework |
| `AIViewModel` | @Observable ViewModel | Owns `suggestions: [GoalSuggestion]`, `motivationText: String?`, `isLoading: Bool`, `error: String?`; drives both AI-powered UI surfaces |

### Modified Existing Components (AI)

| Component | Changes |
|-----------|---------|
| `GoalCreationWizardViewModel` | Add `func fetchAISuggestions() async` → calls `AIViewModel` or `AnthropicService` directly; expose `aiSuggestions: [GoalSuggestion]` |
| `SettingsView` (or new `APIKeySettingsView`) | Text field for API key entry → `KeychainService.save(key: "anthropicApiKey", value: ...)` |
| `NotificationScheduler.makeContent()` | After daily motivation is cached, `makeContent()` can read from UserDefaults to use AI-generated copy in the notification body instead of the hardcoded `inspirationalMessages` array |
| `AppRoute` | Add `case aiGoalSuggestions` |

### Motivation Caching Strategy

```
UserDefaults key: "vg_aiMotivation_{YYYY-MM-DD}"
Value: String (motivation text)
Write: Once per day on first app open if key is absent
Read: makeContent() checks this key before falling back to inspirationalMessages
```

This keeps the motivation fresh (new every day) without unnecessary API calls.

---

## Feature 4: Smart Notifications

### Current Notification Architecture

`NotificationScheduler` schedules at a fixed user-chosen time (`NotificationPreferences.hour/minute`). The content uses a rotating `inspirationalMessages` array — day-seeded but not adaptive. The global streak-at-risk nudge fires at 19:00 regardless of whether the user has already checked in.

### What "Smart" Means Architecturally

1. **Tone adapts to streak level** — already achievable by reading `StreakEngine.currentStreak()` at notification-schedule time and choosing different message templates
2. **Content references actual goal titles** — already done in `makeContent()` (the top active goal title is included)
3. **Send time adapts to historical check-in patterns** — requires storing check-in timestamps and computing the modal check-in hour; derives from `CompletionEvent.completedAt`
4. **Streak-at-risk evening alert if not checked in** — the `scheduleGlobalStreakAtRiskNudge()` already exists; smart version cancels it after check-in and only fires if the user has a streak ≥ 2

### User Pattern Data Storage

No new SwiftData model is needed. The smart send time can be computed from existing `CompletionEvent.completedAt` timestamps.

**Algorithm:**
```
modal_hour = mode(hour(event.completedAt) for event in last 30 completion events)
```
If fewer than 7 events, fall back to user-set time. If modal hour differs from stored time by more than 1 hour, suggest or auto-update the notification time.

This computation belongs in a new `NotificationPatternAnalyzer` (static struct, same pattern as `StreakEngine`). It runs asynchronously when the app foregrounds. Result is stored in App Group UserDefaults under a new key `vg_adaptiveNotificationHour`.

### Tone Templates

Replace the 7-element `inspirationalMessages` array with a `ToneBank` enum:

```swift
enum NotificationTone {
    case onFire(streak: Int)       // streak >= 14
    case building(streak: Int)     // streak 7–13
    case starting(streak: Int)     // streak 1–6
    case recovering               // streak == 0, had streak before
    case fresh                    // no history
}
```

`NotificationScheduler.makeContent(activeGoals:, streak:, tone:)` becomes a new overload that accepts tone. The existing overload remains for backward compatibility.

### Streak-at-Risk Smart Cancellation

The existing `scheduleGlobalStreakAtRiskNudge()` fires every night at 19:00 regardless. The smart version:
1. Re-evaluates at `BGAppRefreshTask` foreground (or at check-in time)
2. If `StreakEngine.currentStreak() == 0` AND user has no prior streak > 1, skip the alert (nothing to protect)
3. After successful check-in, `cancelGlobalStreakAtRiskNudge()` is already called (Phase 23) — this is correct

### New Components (Smart Notifications)

| Component | Type | Purpose |
|-----------|------|---------|
| `NotificationPatternAnalyzer` | Static struct | `func preferredCheckInHour(from events: [CompletionEvent]) -> Int?` — returns modal hour from last 30 events, nil if insufficient data |
| `ToneBank` | Enum | Static `func message(for tone: NotificationTone, goalTitle: String?) -> String` — replaces hardcoded `inspirationalMessages` |
| `SmartNotificationScheduler` | Extension on `NotificationScheduler` | `func rescheduleAdaptive(activeGoals: [Goal], events: [CompletionEvent]) async` — orchestrates tone selection + adaptive time |

### Modified Existing Components (Smart Notifications)

| Component | Changes |
|-----------|---------|
| `NotificationScheduler.makeContent()` | New overload: `makeContent(activeGoals:, streak:, tone:)`; original signature preserved |
| `NotificationPreferences` | Add `vg_adaptiveNotificationHour` key; `SmartNotificationScheduler` writes this, `reschedule()` reads it |
| `GoalViewModel` (or wherever check-in is triggered) | After successful check-in: call `SmartNotificationScheduler.rescheduleAdaptive()` to update tone for next day's notification |

---

## SwiftData Schema: SchemaV11

**One new schema version is needed for v3.0, but only if the AI features add per-goal metadata.**

The AI motivation text is cached in UserDefaults (not SwiftData) — no schema change.
Goal suggestions are transient (shown, then user accepts or dismisses) — no schema change.
Smart notification adaptive hour is in UserDefaults — no schema change.
Analytics data is derived from existing records — no schema change.
Watch data is exchanged via WCSession, not stored locally on Watch — no schema change.

**SchemaV11 trigger: IF the product wants to record that a Goal was created from an AI suggestion (for analytics, or to exclude it from future suggestion cycles), add:**

```swift
// SchemaV11 candidate field on Goal
var isAISuggested: Bool? = nil    // optional with nil default — lightweight migration safe
var aiSuggestionRationale: String? = nil  // optional — lightweight migration safe
```

**Verdict: SchemaV11 is optional. Ship v3.0 without it if AI-sourced goals don't need to be distinguished from user-created goals. If this distinction matters for the goal suggestion prompt (avoid re-suggesting existing AI goals), use the goal title string match instead — no schema change needed.**

---

## Data Flow Diagrams

### Watch Check-In Flow

```
User taps "Check in" on Watch (TodayGlanceView)
  → WatchCheckInIntent.perform() [watchOS 11] OR WCSession.sendMessage() [watchOS 10]
    → iOS: WatchSessionManager.session(_:didReceiveMessage:)
      → GoalViewModel.toggleCompletion(for: activeGoal)
        → CompletionEvent inserted into SwiftData
        → StreakEngine recomputes
        → WatchSessionManager.sendSnapshot() → WCSession.updateApplicationContext()
        → WidgetCenter.shared.reloadAllTimelines() [iOS widgets update]
        → NotificationScheduler.cancelGlobalStreakAtRiskNudge()
          → Watch: WatchAppState.todayCheckedIn = true [UI updates]
```

### AI Daily Motivation Flow

```
App foregrounds (morning)
  → AIViewModel.refreshMotivationIfNeeded()
    → Check UserDefaults["vg_aiMotivation_2026-05-28"]
      → [cache hit] → use cached string, skip API
      → [cache miss] → AnthropicService.generateMotivation(streak:, goalTitle:)
        → URLSession POST to api.anthropic.com/v1/messages
        → Parse response text
        → Store in UserDefaults["vg_aiMotivation_{today}"]
        → NotificationScheduler.reschedule(activeGoals:, motivationOverride: text)
```

### Smart Notification Scheduling Flow

```
App foregrounds OR check-in completes
  → SmartNotificationScheduler.rescheduleAdaptive(activeGoals:, events:)
    → NotificationPatternAnalyzer.preferredCheckInHour(from: events)
      → [has pattern] → write to UserDefaults["vg_adaptiveNotificationHour"]
      → [no pattern] → use NotificationPreferences.hour (user-set time)
    → StreakEngine.currentStreak(from: events) → determine ToneBank tone
    → [AI motivation cached today] → use AI text
    → [no AI motivation] → ToneBank.message(for: tone, goalTitle:)
    → NotificationScheduler.schedule(hour:, minute:, content:)
```

---

## Component Summary: New vs Modified

### New Components (v3.0)

| Component | Target | Type | Feature Area |
|-----------|--------|------|--------------|
| `WatchSessionManager` | iOS | @Observable service | Watch |
| `WatchSessionDelegate` | watchOS | NSObject + WCSessionDelegate | Watch |
| `WatchAppState` | watchOS | @Observable | Watch |
| `WatchSnapshot` | Shared | Codable struct | Watch |
| `WatchCheckInIntent` | watchOS | AppIntent (watchOS 11+) | Watch |
| `VGWatchComplicationBundle` | watchOS WidgetKit extension | WidgetBundle | Watch |
| `StreakComplication` | watchOS WidgetKit extension | Widget (accessoryCircular) | Watch |
| `GoalProgressComplication` | watchOS WidgetKit extension | Widget (accessoryRectangular) | Watch |
| `AnalyticsDashboardView` | iOS | View | Analytics |
| `AnalyticsDashboardViewModel` | iOS | @Observable ViewModel | Analytics |
| `AnalyticsEngine` | iOS | Static struct | Analytics |
| `StreakPeriod` | iOS | Value type | Analytics |
| `CompletionRateBucket` | iOS | Value type | Analytics |
| `AnthropicService` | iOS | Actor/service | AI |
| `GoalSuggestion` | iOS | Codable struct | AI |
| `KeychainService` | iOS | Enum | AI (security) |
| `AIViewModel` | iOS | @Observable ViewModel | AI |
| `NotificationPatternAnalyzer` | iOS | Static struct | Smart notifications |
| `ToneBank` | iOS | Enum | Smart notifications |
| `SmartNotificationScheduler` | iOS | Extension | Smart notifications |

### Modified Existing Components (v3.0)

| Component | Changes |
|-----------|---------|
| `VGWatchApp` | Inject `WatchAppState` env object; activate WCSession |
| `TodayGlanceView` | Wire to `WatchAppState`; connect check-in to intent |
| `WatchGoalListView` | Wire to `WatchAppState.topGoalTitles` |
| `WatchFaceView` | Wire to `WatchAppState` streak/progress |
| `GoalViewModel` | On completion: call `WatchSessionManager.sendSnapshot()` |
| `SettingsView` | Add API key entry field; write to `KeychainService` |
| `NotificationScheduler` | Add `makeContent(activeGoals:, streak:, tone:)` overload |
| `NotificationPreferences` | Add `vg_adaptiveNotificationHour` key |
| `StatsViewModel` | Consider exposing `heatmapData` and `globalStreak` to `AnalyticsDashboardViewModel` — or duplicate the @Query fetch |
| `AppRoute` | Add: `analyticsDashboard`, `aiGoalSuggestions` |
| `GoalCreationWizardViewModel` | Add AI suggestion fetch capability |

---

## Build Order Recommendation

The order below respects cross-feature dependencies and minimizes rework.

### Phase A: Watch Foundation (no interactions yet)
**What:** WCSession setup, WatchAppState, data sync from iOS to Watch. Wire existing Watch screens to live data. Complications (read-only).

**Why first:** The Watch scaffold exists but has zero real data wiring. All other Watch features (check-in, complications) depend on the data flow being established. Complications require a separate WidgetKit extension target — create it now so subsequent phases can extend it.

**Dependencies established:** `WatchSessionManager` + `WatchSessionDelegate` + `WatchAppState` + `WatchSnapshot`.

---

### Phase B: Watch Interactive Check-In + Complications
**What:** `WatchCheckInIntent` (guarded by `@available(watchOS 11.0, *)`), interactive complications, watchOS 10 fallback (tap-to-open app).

**Why second:** Depends on Phase A data flow. The check-in action must write back through iOS SwiftData — this is only safe once the WCSession pipeline is tested.

---

### Phase C: Analytics Dashboard
**What:** `AnalyticsEngine`, `AnalyticsDashboardViewModel`, `AnalyticsDashboardView` with Swift Charts. CSV export via `ShareLink`.

**Why third:** Fully self-contained. No dependencies on Watch or AI features. Deriving data from existing SwiftData records is safe to do at any point. Going before AI lets AI motivations potentially surface on the analytics screen ("Your consistency this month...").

---

### Phase D: Keychain + Anthropic Service Foundation
**What:** `KeychainService`, `AnthropicService`, API key Settings UI, `GoalSuggestion` model, `AIViewModel`.

**Why fourth:** Must be in place before any AI-powered UI is wired. Keychain work is security-critical — test it before building UI on top. `AnthropicService` should be tested with real API calls before the ViewModel layer is built.

---

### Phase E: AI Goal Suggestions in Creation Flow
**What:** Wire `AIViewModel.suggestions` into `GoalCreationWizardViewModel`; show AI suggestions in the wizard.

**Why fifth:** Depends on Phase D `AnthropicService` being validated.

---

### Phase F: AI Daily Motivation + Notification Integration
**What:** `AIViewModel.refreshMotivationIfNeeded()`, UserDefaults motivation cache, `NotificationScheduler` overload accepting AI copy.

**Why sixth:** Depends on Phase D `AnthropicService`. Notification integration must be done carefully — ensure the AI text is validated/truncated before use in a notification (iOS truncates notification body at ~200 chars; AI copy must respect this).

---

### Phase G: Smart Notifications
**What:** `NotificationPatternAnalyzer`, `ToneBank`, `SmartNotificationScheduler`. Wire adaptive scheduling into check-in and app-foreground paths.

**Why last:** Builds on all prior work — requires AI motivation (Phase F), existing streak data, and the notification scheduler to be stable. Smart notifications enhance rather than replace existing notification behavior.

---

## Architecture Decision Log

| Decision | Verdict | Rationale |
|----------|---------|-----------|
| Watch data sync: WatchConnectivity vs CloudKit vs App Group | **WatchConnectivity** | App Groups don't cross device boundaries; CloudKit-to-watchOS sync is unreliable in practice (multiple confirmed forum issues); WCSession is the standard, reliable approach |
| Watch complication data source | **Watch App Group UserDefaults** (written by WatchSessionDelegate) | Mirrors the iOS widget pattern; complications cannot fetch data on demand, they read a snapshot |
| Interactive complications: watchOS 10 vs 11 | **watchOS 11 for interactive, gracefully degrade on 10** | `Button(intent:)` in WidgetKit requires watchOS 11; deploy target stays at 10 for broader compatibility |
| Morning nudge to Watch | **Mirror iOS notification automatically** | No separate watchOS notification scheduling required; the paired Watch mirrors eligible iOS notifications |
| Analytics storage: new models vs derived computation | **Derived from existing CompletionEvent records** | All required data is already in SwiftData; creating parallel storage would introduce sync complexity and duplication |
| Analytics charting: Swift Charts vs third-party | **Swift Charts (first-party)** | iOS 17+ minimum already established; no third-party dependency needed; line/bar/heatmap all achievable natively |
| AI API key storage: Keychain vs UserDefaults vs hardcoded | **Keychain only** | UserDefaults is not encrypted and is included in device backups; hardcoding violates security and makes key rotation impossible |
| AI API: direct URLSession vs third-party SDK | **Direct URLSession** | Project constraint: no third-party dependencies unless necessary; the Anthropic API is simple HTTP POST with JSON; no streaming required for these use cases |
| AI model choice | **claude-3-haiku** | Fast, low cost, sufficient for goal suggestions and short-form motivation; upgrade path to claude-3-5-sonnet if quality proves insufficient |
| AI motivation caching | **UserDefaults keyed by calendar date** | Single string per day; no CloudKit sync needed (motivation is device-specific); avoids redundant API calls |
| Smart notification time adaptation: new model vs derived | **Derived from CompletionEvent timestamps** | Sufficient data already exists; a new SwiftData model would be premature optimization |
| SchemaV11: add AI-sourced goal flag | **Defer unless product requires it** | Goal title string matching is sufficient to prevent re-suggesting identical goals; adding a schema version for a single bool adds migration complexity |

---

## Architectural Violations to Avoid

1. **Do not open SwiftData from the Watch target** — `WGWatchApp` must not call `ModelContainerFactory`; all data arrives via WCSession snapshot
2. **Do not store the Anthropic API key in UserDefaults, AppStorage, or any committed file** — Keychain only; never log the key value
3. **Do not call `AnthropicService` from a View** — all API calls go through `AIViewModel`; MVVM strictly enforced
4. **Do not use App Group UserDefaults for cross-device sync** — App Groups share within one device; WCSession crosses the device boundary
5. **Do not schedule a separate watchOS notification** — iOS notifications mirror automatically when Watch is paired; duplicate scheduling causes double-delivery
6. **Do not run `NotificationPatternAnalyzer` synchronously on the main thread** — event aggregation over 30+ records is O(n); run async and publish result to the calling ViewModel
7. **Do not regenerate AI motivation on every app foreground** — check UserDefaults cache key first; one API call per calendar day maximum
8. **Do not put Claude prompt strings in Views** — all prompt construction belongs in `AnthropicService` methods; prompts are business logic
9. **Do not use CloudKit sync as the Watch data channel** — it is unreliable between iOS and watchOS; WatchConnectivity is the only reliable real-time path

---

## Sources

- SwiftData + CloudKit sync between iOS and watchOS (unreliable): [Apple Developer Forums — SwiftData CloudKit sync on WatchOS 10](https://developer.apple.com/forums/thread/733397)
- WatchConnectivity for iOS–watchOS data sharing: [Apple Developer Documentation — Transferring data with Watch Connectivity](https://developer.apple.com/documentation/WatchConnectivity/transferring-data-with-watch-connectivity)
- Interactive watchOS widgets require watchOS 11: [Cocoa Switch — Building interactive Apple Watch widget](https://www.cocoaswitch.com/2024/12/16/building-interactive-apple.html)
- WidgetKit complications on watchOS 9+: [Kodeco — watchOS With SwiftUI by Tutorials, Chapter 8: Complications](https://www.kodeco.com/books/watchos-with-swiftui-by-tutorials/v2.0/chapters/8-complications)
- Migrating ClockKit to WidgetKit: [Apple Developer Documentation](https://developer.apple.com/documentation/widgetkit/converting-a-clockkit-app)
- Swift Charts iOS 17 features (selection, scrolling): [Apple Developer Documentation — Charts](https://developer.apple.com/documentation/charts)
- Anthropic Messages API direct HTTP: [Anthropic API Documentation — Messages streaming](https://docs.anthropic.com/claude/reference/messages-streaming)
- SwiftAnthropic iOS SDK (reference, not used): [GitHub — jamesrochabrun/SwiftAnthropic](https://github.com/jamesrochabrun/SwiftAnthropic)
- SwiftClaude KeychainAuthenticator pattern: [GitHub — GeorgeLyon/SwiftClaude](https://github.com/GeorgeLyon/SwiftClaude)
- iOS Keychain with Security framework: [How to Use Keychain for Secure Storage in Swift](https://oneuptime.com/blog/post/2026-02-02-swift-keychain-secure-storage/view)
- Anthropic CORS/client-side access risks: [Simon Willison — Claude's API now supports CORS](https://simonwillison.net/2024/Aug/23/anthropic-dangerous-direct-browser-access/)
- App Groups vs WatchConnectivity for data sharing: [Apple Developer Forums — SwiftData and correct setup for App Group](https://developer.apple.com/forums/thread/732986)
