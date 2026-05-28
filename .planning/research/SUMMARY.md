# Project Research Summary

**Project:** Vitamin G v3.0 — Personal Intelligence + Apple Watch
**Domain:** iOS goal tracking / gratitude app with Apple Watch companion and AI features
**Researched:** 2026-05-28
**Confidence:** HIGH (stack and architecture), MEDIUM (AI integration, BGAppRefreshTask reliability)

---

## Executive Summary

Vitamin G v3.0 adds four interconnected capability areas to an already-mature SwiftData + CloudKit app (SchemaV10, 24+ phases complete): an Apple Watch companion, an analytics dashboard, Claude AI integration, and smarter notifications. The existing architecture is a strong foundation — MVVM, @Observable, App Groups for widget data sharing, and a versioned schema migration plan are all in place. The v3.0 work is additive: no schema migrations are strictly required (SchemaV11 is optional and deferred), no new third-party dependencies are mandated (direct URLSession to the Anthropic API is preferred over SwiftAnthropic given the project's no-dependency policy), and no new CloudKit record types are needed.

The recommended build order is: Smart Notifications first (lowest-risk, highest retention ROI, pure logic on top of existing infrastructure), then Analytics (self-contained, derives everything from existing CompletionEvent records), then Watch (new Xcode target with a carefully structured WatchConnectivity data pipeline), and finally AI (new infrastructure dependency requiring a backend proxy or user-supplied Keychain key). This order maximizes delivered value at each step while deferring the highest-risk surface (AI key management and Watch data sync) until the simpler features are shipped and stable.

The biggest risks in v3.0 are (1) the WatchConnectivity architecture — App Groups do not cross device boundaries and CloudKit-to-watchOS sync is documented as unreliable, so WCSession is the only reliable data bridge; (2) the Anthropic API key security requirement — the key must never be embedded in the binary, requiring either a backend proxy or a user-supplied Keychain approach; and (3) complication refresh budget exhaustion, which causes silent stale data with no error thrown. All three risks have clear, documented prevention strategies. Get the architecture right on day one of each feature area and these are manageable.

---

## Key Findings

### Recommended Stack

The existing stack (Swift, SwiftUI, SwiftData, CloudKit, WidgetKit, App Intents, UserNotifications, @Observable, App Groups, XCTest, StoreKit 2, CoreMotion, PhotosUI, CAEmitterLayer, Swift Charts) is complete. v3.0 adds one new external-facing framework group and one optional SPM package.

**New frameworks for v3.0:**

- **WatchKit + SwiftUI lifecycle (watchOS 10.0 target):** Single-target Watch app using the "Watch App for iOS App" Xcode template. Do NOT use the old two-target WatchKit Extension architecture.
- **WatchConnectivity (WCSession):** The only reliable iOS-to-Watch data bridge. `updateApplicationContext()` for phone-to-watch pushes; `transferUserInfo()` for watch-to-phone writes (guaranteed delivery). Never use `sendMessage` as the sole delivery mechanism from iOS.
- **WidgetKit (watchOS complication families):** Extend the existing VitaminGWidget target to serve `accessoryCircular` (streak count), `accessoryRectangular` (goal title + progress ring). Same TimelineProvider pattern as iOS widgets.
- **BackgroundTasks (BGAppRefreshTask):** For AI motivation copy pre-generation only. Do NOT use for streak-at-risk notification — use schedule-and-cancel instead.
- **Security framework (Keychain):** Store user-supplied Anthropic API key via raw `SecItemAdd`/`SecItemCopyMatching`. No third-party Keychain wrapper needed for a single key.
- **SwiftAnthropic v2.2.2 (optional SPM):** `https://github.com/jamesrochabrun/SwiftAnthropic`. Community package — not official. Given the project's no-dependency policy, direct URLSession is preferred. Either works; URLSession is more maintainable and eliminates SDK lag risk.

**AI key strategy (decide before writing any AI code):**

Two valid approaches, in preference order:
1. **Backend proxy (strongest):** Cloudflare Worker or Vercel function holds the Anthropic key in an environment variable. iOS calls the proxy. Eliminates key-in-binary risk entirely. Free up to 100K req/day on Cloudflare.
2. **User-supplied key in Keychain:** User enters their own Anthropic key in Settings. Stored via KeychainService. No backend required. Appropriate for a portfolio app.

Do not embed a developer-owned API key in the binary. It is extractable from any .ipa with `strings`.

**Deployment targets for v3.0:**
- iOS: 17.0 (unchanged)
- watchOS: 10.0 (set this immediately — existing scaffold targets 7.0, which is too low for WidgetKit complications)
- watchOS 11.0: required for `Button(intent:)` interactive complications — guard with `@available(watchOS 11.0, *)` and degrade to tap-to-open on watchOS 10

**What NOT to add:**
- ClockKit (fully deprecated watchOS 9+)
- Old two-target WatchKit Extension architecture
- SwiftClaude (requires iOS 18 minimum)
- App Group container as cross-device data bridge (same-device feature only)
- A separate watchOS notification schedule (iOS notifications mirror automatically)

---

### Expected Features

#### Area A: Apple Watch

**Table stakes:**
- Streak count complication (accessoryCircular — large number + flame SF Symbol)
- Active goal + progress ring complication (accessoryRectangular)
- Morning push notification delivered to wrist (zero Watch-specific code; automatic when Watch app is installed and phone is locked)

**Differentiators:**
- Check-in from wrist: Pattern 1 (tap complication opens Watch app, tap Done button) targets watchOS 10+. Pattern 2 (interactive Button(intent:) in complication) targets watchOS 11+. Build Pattern 1 first.

**Defer:**
- All 4 complication families on day one — start with accessoryCircular only
- Pattern 2 interactive complications — add after Watch app is validated on device

**Anti-features:**
- Full SwiftData stack on Watch (use WatchConnectivity snapshot instead)
- Polling-based complication refresh (exhausts ~50/day budget by midday)
- WCSession sendMessage as primary phone-to-watch data path (doesn't wake Watch when suspended)

#### Area B: Analytics Dashboard

**Table stakes:**
- Streak history chart (BarMark per streak run, Swift Charts)
- Completion rate trends (weekly/monthly LineMark, Swift Charts)
- CSV export via ShareLink

**Differentiators:**
- All-time GitHub-style heatmap (horizontally scrolling LazyHStack of RectangleMark cells; extends existing v1.0 heatmap)

**Implementation note:** All data derives from existing CompletionEvent and Goal records. No new SwiftData models. No SchemaV11 required.

**Anti-features:**
- Passing raw CompletionEvent arrays directly to Swift Charts (aggregate first — target <500 data points per chart series)
- Analytics computation on the main thread (use background ModelActor + value-type structs across actor boundaries)
- Fetching all CompletionEvents at once for CSV export (page with fetchLimit: 500)

#### Area C: AI (Claude) Integration

**Table stakes (from competitive landscape):** Loading state with progress indicator; per-suggestion dismiss; static fallback copy when offline or API unavailable.

**Differentiators:**
- Goal suggestions seeded by existing goals (3 AI-generated complementary goals with title, tier, and 1-sentence rationale)
- Personalized daily motivation copy (streak + goal-specific; generated once per day; cached in UserDefaults; used in notification body and Home tab card)

**Defer:**
- Streaming responses (non-streaming adequate for short outputs; streaming adds complexity for minimal UX gain)
- Large model (claude-opus) — use claude-3-haiku-20240307 for both use cases

**Anti-features:**
- Embedded API key in binary (CRITICAL)
- Regenerating motivation on every app open (once per calendar day maximum)
- AI network calls from Views or Watch target

#### Area D: Smart Notifications

**Table stakes:**
- Goal title in notification body (hero goal selected by highest streak count)
- Streak-at-risk evening alert (schedule each morning, cancel on check-in; fire only for streak >= 3 days)

**Differentiators:**
- Tone adaptation by streak state (6-state matrix: fresh / building / building-strong / on-fire / recovering / at-risk-evening)
- Send time adaptation (compute modal check-in hour from last 30 CompletionEvents; suggest, never auto-change)

**Anti-features:**
- More than 2 notifications per day (morning + evening streak-at-risk only)
- BGAppRefreshTask for streak-at-risk delivery (use schedule-and-cancel instead)
- Automatically changing notification time without user consent

---

### Architecture Approach

The existing MVVM architecture (static engine structs for pure computation, @Observable ViewModels, SwiftData as source of truth) extends cleanly to v3.0. Each feature area adds a small set of new components without touching the core data layer.

**New components by area:**

Watch:
- `WatchSessionManager` (iOS @Observable service) — sends WatchSnapshot via WCSession; receives check-in confirmations
- `WatchSessionDelegate` (watchOS NSObject+WCSessionDelegate) — receives snapshot; writes to Watch App Group UserDefaults; relays check-in back to iOS
- `WatchAppState` (watchOS @Observable) — in-memory display state for Watch UI
- `WatchSnapshot` (Codable struct, ~6 fields) — the DTO crossing the WCSession boundary
- `VGWatchComplicationBundle` (watchOS WidgetKit extension) — StreakComplication + GoalProgressComplication
- `WatchCheckInIntent` (watchOS AppIntent, @available watchOS 11.0)

Analytics:
- `AnalyticsEngine` (static struct) — streakHistory(events:), completionRateTrend(events:goals:period:), generateCSV(goals:events:) — pure functions, fully testable
- `AnalyticsDashboardViewModel` (@Observable) — owns chart data arrays; calls AnalyticsEngine
- `AnalyticsDashboardView` — Swift Charts rendering

AI:
- `AnthropicService` (actor) — URLSession HTTP client; suggestGoals() and generateMotivation() async throws
- `KeychainService` (enum) — Security framework primitives
- `AIViewModel` (@Observable) — owns suggestions, motivationText, isLoading, error
- `GoalSuggestion` (Codable struct)

Smart Notifications:
- `NotificationPatternAnalyzer` (static struct) — modal check-in hour from last 30 CompletionEvents
- `ToneBank` (enum) — 6-state tone matrix to String
- `SmartNotificationScheduler` (extension on NotificationScheduler) — orchestrates tone selection + adaptive time

**Architectural constraints that must not be violated:**
1. Watch target must NOT open SwiftData. All data arrives via WCSession snapshot.
2. AnthropicService must NOT be called from a View or from the Watch target.
3. Motivation copy regenerates at most once per calendar day (UserDefaults cache key by date string).
4. All analytics computation runs async and passes only value types across actor boundaries — never @Model objects.
5. Streak-at-risk notification uses schedule-and-cancel, not BGAppRefreshTask.

**SwiftData schema:** SchemaV11 is NOT required. All v3.0 state that is ephemeral or device-specific (motivation copy, check-in hour history, Watch snapshot) lives in UserDefaults. IF AI-sourced goals need tagging, add `isAISuggested: Bool? = nil` as a lightweight migration — but defer until there is a product requirement.

---

### Critical Pitfalls

**CRITICAL — will ship a broken feature if ignored:**

1. **App Group does not cross device boundaries (V3-WA-1)** — The iOS widget uses App Groups to share SwiftData. The Watch app CANNOT use this mechanism. App Groups are same-device only. Use WCSession exclusively for iPhone-to-Watch data. Warning sign: Watch @Query returns 0 results despite iOS data being present.

2. **API key embedded in binary (V3-AI-1)** — Any string constant or bundled config containing `sk-ant-...` is extractable from the .ipa. Consequences: unexpected billing, account suspension. Prevention: backend proxy OR user-supplied Keychain key. Verify before every release: `strings YourApp.app/YourApp | grep "sk-ant"`.

3. **Custom StagedMigrationPlan crashes with CloudKit (V3-SD-2)** — Any `.custom(...)` migration stage in a CloudKit-synced container causes a crash on update install. All SchemaV11 changes must be lightweight (additive, optional fields with defaults). This is the primary reason to avoid SchemaV11 unless there is a compelling product requirement.

4. **CloudKit schema not deployed to Production before TestFlight (V3-SD-5)** — New record types work in the Development CloudKit environment automatically. They do NOT exist in Production until explicitly deployed via CloudKit Console > Schema > Deploy. Add to the release checklist as a gating step.

**HIGH — will produce bad UX or silent failure:**

5. **sendMessage does not wake the Watch (V3-WA-2)** — WCSession.sendMessage from iOS silently drops when Watch app is suspended. Use updateApplicationContext() for phone-to-watch data; transferUserInfo() for watch-to-phone writes. Never gate operations on isReachable.

6. **WatchConnectivity transfer APIs do not work in Simulator (V3-WA-4)** — transferUserInfo and transferCurrentComplicationUserInfo are silently no-ops in Simulator. Establish physical device testing before merging any WatchConnectivity code.

7. **Complication refresh budget exhaustion (V3-WA-5, V3-WA-6)** — ~50 reloads/day total; transferCurrentComplicationUserInfo has an even tighter separate budget. Call it only on user check-in. Provide a full 24-hour forward timeline in getTimelineEntries so the system can display correct data without reloads.

8. **Analytics @Model objects not Sendable across actors (V3-SD-4)** — Passing SwiftData model instances from a background ModelActor to a @MainActor ViewModel crashes. Always map to plain value-type structs before crossing actor boundaries.

9. **BGAppRefreshTask unreliable for streak-at-risk (V3-NT-2)** — Infrequent users (the ones most at risk of losing a streak) are exactly the users for whom iOS throttles BGAppRefreshTask. Use schedule-and-cancel: schedule the evening alert every morning; cancel it on check-in via removePendingNotificationRequests(withIdentifiers:).

10. **API rate limit retry without backoff exhausts budget (V3-AI-4)** — A tight retry on 429 can exhaust Tier 1 limits (50 RPM, 40K ITPM) in minutes. Implement exponential backoff, serve cached copy on failure, max 3 retries.

---

## Implications for Roadmap

### Suggested Phase Structure

Research supports a 4-group build order based on dependencies, risk profile, and delivered value per unit of effort.

---

### Group 1: Smart Notifications Enhancement

**Rationale:** Highest retention ROI per effort unit. Pure logic on top of existing Phase 3 infrastructure. No new Xcode targets, no new external dependencies, no schema changes. Ships value immediately. Establishes the cancel-on-check-in pattern that D.4 (streak-at-risk) requires — Watch check-in (Group 3) must also trigger this cancel path.

**Delivers:** Tone-adaptive morning notifications, goal-title-personalized copy, streak-at-risk evening alerts, send-time suggestion based on check-in history.

**Features:** D.1 (tone adaptation), D.2 (goal title in notification), D.3 (send time adaptation), D.4 (streak-at-risk evening alert)

**Key pitfall:** V3-NT-2 — do not implement streak-at-risk via BGAppRefreshTask; use schedule-and-cancel.

**Suggested sub-phases:**
- D.2 + D.1: goal title hero selection + tone matrix (pure logic, ~1-2 days)
- D.4: streak-at-risk schedule-and-cancel pattern
- D.3: send time adaptation (requires simulated check-in history in dev; 7+ real days needed to validate the suggestion trigger in production)

**Research flag:** Standard patterns — skip research phase.

---

### Group 2: Analytics Dashboard

**Rationale:** Fully self-contained. All data exists in SwiftData. No new Xcode targets. No schema migrations. High user value (data ownership + progress visibility).

**Delivers:** Streak history bar chart, completion rate trend line chart, all-time heatmap, CSV export.

**Features:** B.1 (streak history), B.2 (completion rate trends), B.3 (all-time heatmap), B.4 (CSV export)

**Key pitfalls:** V3-SD-4 (never pass @Model across actors); V3-AN-1 (paginate CSV); V3-AN-2 (aggregate before Swift Charts).

**New components:** AnalyticsEngine (static struct, fully unit-testable), AnalyticsDashboardViewModel, AnalyticsDashboardView.

**Suggested sub-phases:**
- AnalyticsEngine unit tests + data derivation structs (foundation, no UI)
- Chart views (streak history + completion rate)
- All-time heatmap (LazyHStack virtualized rendering)
- CSV export (ShareLink + paginated FetchDescriptor)

**Research flag:** Standard patterns for Swift Charts and ShareLink — skip research phase. If heatmap scroll performance is a concern, a quick targeted research pass on LazyHStack virtualization is warranted before that sub-phase.

---

### Group 3: Apple Watch App

**Rationale:** New Xcode target, new WatchConnectivity pipeline, physical device testing required. This is the highest setup overhead of any v3.0 group. Build after Groups 1 and 2 so the cancel-on-check-in notification pattern from D.4 is established and tested — Watch check-in must also cancel the evening alert via the same path.

**Delivers:** Streak count complication, active goal + progress ring complication, check-in from wrist (watchOS 10 pattern), morning notification delivered to wrist.

**Features:** A.1 (streak complication), A.2 (progress ring), A.3 (check-in from wrist), A.4 (morning nudge)

**Key pitfalls:** V3-WA-1 (App Groups cross-device myth), V3-WA-2 (sendMessage asymmetry), V3-WA-4 (Simulator blocking transfer APIs), V3-WA-5/6 (complication refresh budget).

**Existing scaffold:** VGWatchApp target exists with hardcoded mock data in TodayGlanceView, WatchGoalListView, WatchFaceView. Wire to WatchAppState — do not rewrite the UI.

**Suggested sub-phases:**
- WCSession foundation: WatchSessionManager + WatchSessionDelegate + WatchAppState + WatchSnapshot. Wire existing Watch views to live data. Device test gate before proceeding to complications.
- Complications: VGWatchComplicationBundle, StreakComplication (accessoryCircular), GoalProgressComplication (accessoryRectangular). Complication refresh budget discipline from first commit.
- Check-in from wrist (watchOS 10 pattern): tap complication → open app → Done button. Ensure Watch check-in fires the same notification cancel path as iOS/widget check-in.
- Interactive complication (watchOS 11, optional): WatchCheckInIntent with @available guard. Add after watchOS 10 path is stable and validated on device.

**Research flag:** Needs research phase before the WCSession foundation sub-phase. WCSession has known platform-specific bugs (isReachable stuck, Simulator blocking). A focused pre-phase check on current watchOS 10/11 WCSession behavior before writing production code is warranted.

---

### Group 4: AI (Claude) Integration

**Rationale:** New infrastructure dependency (backend proxy or Keychain key management). Builds last because: it is the highest-risk group; motivation copy enhances notifications already improved in Group 1; goal suggestions are independent but depend on a working AnthropicService foundation. The backend proxy setup is a prerequisite for both C.1 and C.2.

**Delivers:** AI goal suggestions (3 complementary suggestions), personalized daily motivation copy in notifications and Home tab card, Keychain API key storage, Settings UI for API key entry.

**Features:** C.1 (goal suggestions), C.2 (daily motivation copy)

**Key pitfalls:** V3-AI-1 (API key in binary — CRITICAL), V3-AI-3 (latency — loading indicator with timeout), V3-AI-4 (retry without backoff), V3-AI-6 (no network guard — use NWPathMonitor + static fallback).

**New components:** AnthropicService (actor), KeychainService (enum), AIViewModel (@Observable), GoalSuggestion (Codable struct). Modify: SettingsView (API key entry field), NotificationScheduler (motivation copy override), GoalCreationWizardViewModel (AI suggestion fetch).

**Suggested sub-phases:**
- Infrastructure: KeychainService + AnthropicService (URLSession HTTP, non-streaming). Settings UI for API key. Test with real API calls before building any UI on top.
- Goal suggestions: AIViewModel + GoalSuggestion UI in creation wizard. Rate limiting, error handling, per-suggestion dismiss.
- Daily motivation: UserDefaults date-keyed cache, BGAppRefreshTask trigger (with graceful degradation to app-open generation), NotificationScheduler integration.

**Research flag:** Needs research phase before the infrastructure sub-phase. Confirm: current Anthropic rate limits for Tier 1 accounts, direct URLSession vs SwiftAnthropic decision, Cloudflare Worker vs Vercel choice for backend proxy. The proxy is new infrastructure that hasn't been built for this project.

---

### Phase Ordering Rationale

- Notifications before Watch: Watch check-in (Group 3) must trigger the same cancel-on-check-in path established in Group 1. Building notifications first means that path exists and is tested before Watch adds a new entry point to it.
- Analytics before Watch: Analytics is self-contained and ships user value without any coordination. Watch has higher setup friction.
- Watch before AI: AI has the highest infrastructure risk (new backend). Watch issues are more deterministic. Sequencing Watch first means AI is built with momentum and with the simpler features stable.
- AI last: If the backend proxy proves harder than expected, AI features can slip without blocking anything else.
- Smart Notifications first: Near-zero risk, immediate retention value, validates the check-in pipeline before Watch adds a new path through it.

---

### Research Flags

**Needs research phase before starting:**
- Group 3 / WCSession foundation sub-phase: WCSession has documented platform-specific bugs. A focused pre-phase check on current watchOS 10/11 WCSession behavior is warranted before writing production Watch code.
- Group 4 / AI infrastructure sub-phase: Backend proxy architecture (Cloudflare Worker vs Vercel), current Anthropic rate limits, and URLSession vs SwiftAnthropic decision. The proxy is new infrastructure.

**Standard patterns — skip research phase:**
- Group 1 (Smart Notifications): Extending existing NotificationScheduler. Pure Swift logic.
- Group 2 (Analytics): Swift Charts + SwiftData @Query. Well-documented with official samples.
- Group 3 / Complications sub-phase: WidgetKit accessory families are well-documented post-WWDC22.
- Group 3 / Check-in from wrist sub-phase: WCSession transferUserInfo pattern is established once the foundation is working.
- Group 4 / Goal suggestions + motivation UI sub-phases: Standard async/await pattern once AnthropicService is validated.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All framework choices verified against Apple official docs, WWDC sessions, and Apple Developer Forums. SwiftAnthropic is MEDIUM (community package); direct URLSession is HIGH. |
| Features | HIGH (Watch, Analytics, Notifications), MEDIUM (AI) | Watch and notification patterns verified against shipping apps. AI patterns verified against Anthropic docs and competitor analysis. |
| Architecture | HIGH | WatchConnectivity data flow pattern is verified against official docs and forum consensus. Analytics computation approach is standard MVVM. AI service/ViewModel split is established pattern. |
| Pitfalls | HIGH | All critical pitfalls sourced from Apple Developer Forums with direct links. WCSession asymmetries and complication budget limits are documented in Apple official docs. |

**Overall confidence:** HIGH for the recommended approach. MEDIUM for AI delivery timing reliability (BGAppRefreshTask is explicitly non-deterministic by design).

### Gaps to Address

- **BGAppRefreshTask execution frequency:** Non-deterministic for infrequent users. Mitigation: also generate motivation copy on app foreground (with date cache check). If BGAppRefreshTask never fires, copy is generated on next app open rather than overnight. Accept this graceful degradation.
- **SwiftAnthropic vs direct URLSession:** Architecture doc recommends direct URLSession; Stack doc notes SwiftAnthropic is the most mature community SDK. Make this decision at the start of Group 4 based on whether Anthropic's API surface has remained stable.
- **watchOS 11 adoption rate:** Interactive complications (Pattern 2 for A.3) require watchOS 11. Build Pattern 1 (watchOS 10+) first; treat Pattern 2 as an enhancement phase gated on observed Watch app usage.
- **Backend proxy vs user-supplied key:** Product decision, not a technical one. Make it explicit before Group 4 begins. For a portfolio app with low traffic, user-supplied Keychain key eliminates backend operational overhead entirely.

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation: WatchConnectivity, WidgetKit accessory families, Swift Charts, App Intents, BackgroundTasks, Security framework (Keychain)
- Apple WWDC22: Complications and widgets: Reloaded; Go further with Complications in WidgetKit
- Apple TechNote TN3157: Updating your watchOS project for SwiftUI and WidgetKit
- Apple Developer Forums: SwiftData CloudKit sync on watchOS (thread/733397); WCSession sendMessage reliability (thread/20311); WatchConnectivity not working on device (thread/662935)
- Anthropic API Documentation: Messages API, rate limits documentation
- fatbobman.com: Designing Models for CloudKit Sync; initializeCloudKitSchema; custom migration crash analysis
- Cocoa Switch: Building interactive Apple Watch widget (confirms watchOS 11 requirement for Button(intent:))

### Secondary (MEDIUM confidence)
- Smashing Magazine: Designing A Streak System: The UX And Psychology Of Streaks
- Doist Engineering: Implementing a local notification scheduler in Todoist iOS (64-slot limit, schedule-and-cancel pattern)
- Mert Bulan: Don't rely on BGAppRefreshTask for business logic
- GitHub — jamesrochabrun/SwiftAnthropic: version history, API surface review
- Atomic Object: An Unauthorized Guide to SwiftData Migrations
- Leo Kwan: Deploy your CloudKit-backed SwiftData entities to production

### Tertiary (LOW confidence — needs validation during implementation)
- BGAppRefreshTask execution reliability for infrequent users (system behavior; non-deterministic by design; documented pattern only)
- watchOS 11 adoption rate (not researched; assumption that watchOS 10 fallback covers most Watch users)
- Anthropic rate limit tier structure (may change; verify at implementation time against current Anthropic documentation)

---
*Research completed: 2026-05-28*
*Ready for roadmap: yes*
