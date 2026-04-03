# Research Summary — Vitamin G

**Project:** Vitamin G — iOS Goal Tracking & Daily Intentionality App
**Domain:** iOS 17+, SwiftUI, SwiftData, CloudKit, WidgetKit, UserNotifications
**Researched:** 2026-04-03
**Confidence:** HIGH

---

## Executive Summary

Vitamin G is a personal goal-tracking and daily intentionality app for iOS 17+. Expert iOS developers in 2026 build this class of app entirely with Apple-native frameworks: SwiftUI for UI, SwiftData for persistence, CloudKit for sync, and WidgetKit for home/lock screen widgets. The recommended approach uses zero third-party dependencies — Apple's framework stack covers all v1 requirements, and the absence of third-party libraries reduces App Store risk, licensing complexity, and maintenance burden. The MVVM pattern is correct for this stack, but requires a specific seam: `@Query` lives in Views (not ViewModels), and `@Observable` replaces `ObservableObject` throughout.

The single highest-risk area is the SwiftData + CloudKit + App Groups integration. These three systems must be configured together from the very first commit — retrofitting any of them after user data exists causes data loss or silent sync failures. The App Group entitlement must be added to both targets before any data is persisted; CloudKit requires all model properties to be optional or defaulted from day one; and `VersionedSchema` must be declared before the first TestFlight build. Getting these three things wrong is catastrophic to fix; getting them right is a one-time setup cost.

The 4-tier goal hierarchy (Immediate / Short-Term / Long-Term / Life Goal) is Vitamin G's core differentiator. No mainstream competitor structures goals this way, and it is psychologically grounded in how people actually plan across time horizons. The `associatedInspiration` field — linking a personal "why" to each goal — is the gratitude angle. Together, these distinguish the app from generic habit trackers and create a focused, warm, non-subscription-gated experience that is rare in the App Store. Defer everything else (Apple Watch, AI features, social, vision board, recurring habits) to v2+.

---

## Key Findings

### Recommended Stack

The entire app should be built on Apple's modern iOS 17+ stack. SwiftData replaces Core Data with a Swift-native, SwiftUI-integrated persistence layer that has a built-in CloudKit sync path. The `@Observable` macro replaces `ObservableObject` + `@Published`, providing surgical per-property view updates instead of whole-object invalidation. SwiftUI is the only framework with first-class integration with both `@Query` and `@Observable` — do not introduce UIKit for feature views.

WidgetKit with `AppIntentConfiguration` handles both home screen and lock screen widgets. Interactive widgets (iOS 17+) allow users to mark goals complete directly from the home screen. UserNotifications with `UNCalendarNotificationTrigger` covers the daily morning reminder with a single repeating local notification — no push server required.

**Core technologies:**
- Swift 5.9+ / Xcode 15+: Primary language — no alternative
- SwiftUI (iOS 17+): All UI — required for `@Query`, `@Observable`, and WidgetKit integration
- SwiftData (iOS 17+): Local persistence with CloudKit-ready model layer — replaces Core Data
- CloudKit private DB (iOS 17+): iCloud sync via `ModelConfiguration.cloudKitDatabase` — free, private, no backend
- WidgetKit + App Intents (iOS 17+): Home screen and lock screen widgets with interactive completion
- `@Observable` macro (iOS 17+): ViewModel layer — replaces `ObservableObject`, iOS 17+ only
- App Groups entitlement: Shared SwiftData container between app and widget processes — mandatory
- UserNotifications (local): Repeating daily reminder via `UNCalendarNotificationTrigger` — no server needed

**What to avoid:** Core Data, UIKit feature views, `ObservableObject`/`@Published`, `NavigationView`, `@Attribute(.unique)` with CloudKit, third-party persistence (Realm, GRDB), Firebase, push notification server, SiriKit Intents (deprecated for new widgets), Combine.

### Expected Features

**Must have (table stakes):**
- Goal CRUD (create, read, update, delete) with title, description, tier, associatedInspiration
- 4-tier goal hierarchy (Immediate / Short-Term / Long-Term / Life Goal) with visual distinction per tier
- Goal completion toggle
- Streak tracking (per tier) — every major competitor has it; users leave without it
- Basic stats view (per-tier completion rate, streak length)
- Daily morning push notification with active goal summary in the body
- iCloud sync across devices — baseline expectation in 2026
- Home screen widget (systemMedium minimum, showing top active goals)
- Lock screen widget (accessoryRectangular showing top goal or streak)
- Edit and delete goals
- Onboarding with tier explanation + first-goal creation flow
- Input validation on all text fields (character limits, sanitization)

**Should have (differentiators):**
- `associatedInspiration` per goal — free-text "why" field displayed on goal detail and in notifications
- Tier-aware streak tracking — "30 days consistent on Life Goals" is a deeper signal than a global streak
- Morning notification that shows the user's actual goal titles (not a generic "check your goals" message)
- Intentionality framing ("Vitamin G" tone) — warm, reflective copy, not productivity-grind aesthetic
- Free or one-time purchase pricing — no subscription paywall interrupting the flow

**Defer to v2+:**
- Apple Watch app (lock screen widget covers the glanceable use case)
- Image/photo attachments for `associatedInspiration` (v1: free text only)
- AI-generated insights or journaling prompts (requires API dependency)
- Social sharing, friend accountability, shared goals (requires backend, auth, moderation)
- Vision board / photo collage
- Goal templates library
- Recurring/habit-style goals (different product primitive from aspirational goal tracking)
- Full analytics dashboard with export
- Web dashboard

### Architecture Approach

The app is structured as a single main process plus a widget extension process, communicating through a shared App Group SQLite store. The `SharedModelContainer` singleton is the central load-bearing component — it configures the one `ModelContainer` pointing at the App Group URL with CloudKit enabled, and is imported by both targets. ViewModels use `@Observable` and live as `@State` properties in their owning Views. `@Query` stays in Views; ViewModels receive `[Goal]` arrays from the View's query results for computation (stats, streaks). The `NotificationScheduler` is a stateless service called on launch and after goal mutations.

**Major components:**
1. `SharedModelContainer` — single source of truth for the SwiftData store; compiled into both targets; points at App Group URL with CloudKit enabled
2. `Goal` (@Model) + `GoalTier` (enum: String) — the persisted entity; all properties optional or defaulted for CloudKit; compiled into both targets
3. `GoalListViewModel` / `GoalFormViewModel` / `StatsViewModel` — `@Observable` classes; own validation logic, CRUD operations, streak computation; receive `ModelContext` from the environment
4. `GoalWidgetProvider` (TimelineProvider) — reads from shared App Group store; builds `GoalWidgetEntry` snapshots; never writes
5. `NotificationScheduler` — stateless service; schedules single repeating `UNCalendarNotificationTrigger`; called on launch and after goal changes
6. Onboarding flow — explains 4 tiers, creates first goal, gates notification permission request

**Build order:** App Group + CloudKit + SwiftData model (Phase 1) → CRUD + ViewModel layer (Phase 2) → Stats + Streaks + Notifications (Phase 3) → Widget extension (Phase 4) → Polish + App Store prep (Phase 5)

### Critical Pitfalls

1. **CloudKit requires all model properties to be optional or defaulted** — Design the `Goal` @Model with `var title: String? = ""` and `var tier: String? = GoalTier.immediate.rawValue` from the first commit. Non-optional properties without defaults silently break CloudKit sync. Use computed properties to wrap optionals for clean internal API. (Phase 1 — blocking)

2. **Declare `VersionedSchema` before the first TestFlight build** — Wrap `Goal` in `SchemaV1` from the beginning. Without it, the first schema change post-ship causes SwiftData to wipe the store. Start with `stages: []`; add stages when fields change. Never rename stored properties — add new ones and migrate. (Phase 1 — blocking)

3. **Add App Group entitlement to the main app before any user data exists** — When an App Group is added to an app with existing users, SwiftData changes the store lookup path and data "vanishes." Plan for App Groups in Phase 1, even before the widget is built. Explicit `url` in `ModelConfiguration` pointing to the App Group container prevents this. (Phase 1 — blocking)

4. **Streak timezone / DST correctness** — Store all timestamps as UTC `Date` values; compute streak boundaries using `Calendar.current.isDateInToday(_:)` and `Calendar.current.isDate(_:inSameDayAs:)`, never raw `TimeInterval` arithmetic. Hardcoded UTC or `86400`-second day logic breaks for non-UTC users at DST transitions. (Phase 2 — high)

5. **Never request notification permission at app launch** — iOS shows the system permission dialog exactly once. An early dismissal permanently denies notifications, killing the app's core value proposition. Request after the user has created their first goal. Show a custom pre-permission screen first. Handle `.denied` with an in-app "Enable in Settings" link. (Phase 3 — high)

**Additional high-priority pitfalls to track:**
- `@Query` cannot live in a ViewModel — keep it in Views, pass arrays to ViewModels
- Widget must create its own `ModelContainer` pointing at the shared App Group URL — it cannot use the main app's in-memory context
- Call `WidgetCenter.shared.reloadAllTimelines()` after every goal mutation — widgets do not update reactively
- Gate `initializeCloudKitSchema()` behind `#if DEBUG` — never call in production
- Use `@State var vm = ViewModel()` for `@Observable` ViewModels, not `@StateObject`

---

## Implications for Roadmap

Based on the dependency chains identified in FEATURES.md and ARCHITECTURE.md, and the phase-mapped pitfalls from PITFALLS.md, the natural phase structure is:

### Phase 1: Foundation — Data Model, App Group, CloudKit Setup

**Rationale:** Every other component depends on a working, CloudKit-compatible, App Group-shared SwiftData store. Three of the five most critical pitfalls (P0-1, P0-2, P0-4) must be avoided here. This phase has no UI — it is infrastructure. Getting it wrong requires a migration or data loss to fix.

**Delivers:** `Goal` @Model with all CloudKit-compatible properties, `GoalTier` enum, `SharedModelContainer` pointing at App Group URL with CloudKit enabled, `VersionedSchema` declared, App Group entitlement on both targets.

**Addresses:** Data model setup from FEATURES.md critical path; "SwiftData model" prerequisite block

**Avoids:** P0-1 (non-optional model properties), P0-2 (missing VersionedSchema), P0-4 (App Group store path change), P1-6 (unique constraint blocks launch), P2-5 (@StateObject vs @State), P1-1 (@Query in ViewModel)

**Research flag:** Standard Apple-documented patterns — skip phase research

---

### Phase 2: Core CRUD and Goal List UI

**Rationale:** The model is useless without create/read/update/delete. This phase proves the MVVM seam (`@Query` in View, `@Observable` ViewModel with `ModelContext`) works correctly before adding statistical complexity. Navigation structure is established here.

**Delivers:** `GoalFormViewModel` with full input validation, `GoalListViewModel` with delete/toggle, `GoalListView` with `@Query` per tier, `GoalDetailView`, `GoalFormView`, `NavigationStack`-based navigation, completion toggle with `completionDate` field.

**Addresses:** Goal CRUD, 4-tier goal list UI, associatedInspiration display, completion tracking

**Avoids:** P1-1 (@Query in ViewModel), P1-2 (models not Sendable across actors), P2-1 (validation at ViewModel layer), P1-5 (timezone-correct completionDate from day one)

**Research flag:** Standard MVVM + SwiftData patterns — skip phase research

---

### Phase 3: Streaks, Stats, Notifications, and iCloud

**Rationale:** Completion history (added in Phase 2) unlocks streak computation. Notifications require real goal data to be meaningful. iCloud sync is validated here with real data rather than added post-ship. This phase delivers the app's core daily-use value loop.

**Delivers:** `StatsViewModel` with tier-aware streak computation using `Calendar.current` day comparisons, stats view UI, `NotificationScheduler` with repeating daily morning notification, `NotificationPermissionViewModel` with post-first-goal permission request, CloudKit sync validation, `initializeCloudKitSchema()` in `#if DEBUG` build.

**Addresses:** Streak tracking, push notification with goal summary content, iCloud sync, progress stats

**Avoids:** P0-3 (CloudKit schema add-only after production — finalize names before first CloudKit beta), P1-3 (64-notification limit — use repeating trigger, not 365 individual requests), P1-4 (permission too early), P1-5 (DST/timezone streak bugs), P2-3 (accept last-write-wins for v1), P2-6 (initializeCloudKitSchema in production)

**Research flag:** CloudKit schema finalization warrants careful review before first TestFlight with iCloud enabled

---

### Phase 4: Widget Extension

**Rationale:** Requires a stable, finalized model schema. Schema changes after widget ships require careful migration. App Group infrastructure from Phase 1 is the prerequisite. Widget adds meaningfully to daily re-engagement without requiring any new model changes.

**Delivers:** `GoalWidgetBundle`, `GoalWidget` (systemSmall/systemMedium), `LockScreenGoalWidget` (accessoryRectangular), `GoalWidgetProvider` (read-only TimelineProvider using shared App Group store), `GoalWidgetEntryView`.

**Addresses:** Home screen widget, lock screen widget from FEATURES.md table stakes

**Avoids:** P0-5 (widget must create its own ModelContainer), P2-2 (call `WidgetCenter.shared.reloadAllTimelines()` on every goal mutation)

**Research flag:** Widget + SwiftData + App Group integration has known quirks — verify `SharedModelContainer` works in widget process on physical device before building widget UI

---

### Phase 5: Onboarding, Polish, and App Store Preparation

**Rationale:** Onboarding depends on stable CRUD (user must create a goal during onboarding). Polish (deep links, notification time preference settings, validation hardening) depends on all prior phases being stable. App Store prep is the final gate.

**Delivers:** Onboarding flow with tier explanation + first-goal creation + notification permission request, deep link from notification tap to relevant goal tier, notification time preference setting, validation audit across all ViewModels, settings screen, App Store metadata, screenshots, privacy manifest.

**Addresses:** Onboarding from FEATURES.md table stakes; App Store Guideline 4.5.4 compliance

**Avoids:** P1-4 (permission requested during onboarding, not on launch), P2-4 (notifications framed as enhancement, not requirement)

**Research flag:** App Store submission requirements (privacy manifest, entitlements audit) may need targeted research

---

### Phase Ordering Rationale

- **Phase 1 must be first** because CloudKit-compatible model design, App Group entitlement, and VersionedSchema are zero-cost to set up at start and catastrophically expensive to retrofit.
- **Phase 2 before Phase 3** because streak computation and notification content require completed goal records; statistics are meaningless without CRUD.
- **Phase 3 before Phase 4** because schema must be finalized before the widget extension compiles against it; CloudKit schema is add-only after first production push.
- **Phase 5 last** because onboarding depends on stable CRUD; polish and App Store prep cannot precede a working app.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3:** CloudKit schema finalization — attribute names and entity structure must be locked before first iCloud-enabled TestFlight; requires careful review of CloudKit Console workflow
- **Phase 4:** Widget + SwiftData + App Group integration on physical device — Simulator is unreliable for widget rendering and App Group filesystem access; validate early on device before building widget UI
- **Phase 5:** App Store privacy manifest requirements — Apple's privacy manifest (PrivacyInfo.xcprivacy) is now required; required reason API declarations must cover all APIs used

Phases with standard, well-documented patterns (skip `/gsd:research-phase`):
- **Phase 1:** App Group + SwiftData + CloudKit setup is thoroughly documented by Apple and the Swift community
- **Phase 2:** MVVM + SwiftData + `@Observable` is the canonical iOS 17 architecture with multiple official guides

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All recommendations backed by Apple Developer Documentation and multiple corroborating community sources; zero third-party dependencies reduces uncertainty |
| Features | MEDIUM-HIGH | Competitive landscape well-researched from App Store patterns and multiple review sources; some UX retention claims are from third-party benchmarks, not Apple data |
| Architecture | HIGH | Component boundaries and MVVM seam pattern verified against Apple Developer Documentation, Hacking with Swift SwiftData by Example, and Developer Forums |
| Pitfalls | HIGH | All critical pitfalls sourced from Apple Developer Forums threads and official documentation; CloudKit constraints are authoritative |

**Overall confidence:** HIGH

### Gaps to Address

- **`cloudKitDatabase: .automatic` + `groupContainer: .identifier()` coexistence:** Verified by community (MEDIUM confidence), but not explicitly documented by Apple as a supported combination. Validate in Phase 1 on a physical device before proceeding.
- **Streak persistence model:** Research recommends computing streaks on-read from completion history for v1. If performance is acceptable at typical goal counts (10–100), this is fine. If a persisted streak count is needed later, that is a Phase 3+ migration decision — plan `completionDate: Date?` on `Goal` from Phase 1.
- **CloudKit schema promotion workflow:** The manual step of deploying schema from Development to Production in CloudKit Console is documented but easy to miss. Confirm this step is in the Phase 3 definition of done before shipping to App Store.
- **Notification permission opt-in rate:** No data on what percentage of goal-tracking app users grant notification permission. The custom pre-permission screen and context-gated request (post-first-goal) are best-practice mitigations, but the actual impact is unknown until live.

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation — SwiftData, WidgetKit, UserNotifications, App Intents, CloudKit
- Hacking with Swift: SwiftData by Example — MVVM pattern, CloudKit sync, widget container access
- fatbobman.com — CloudKit model constraints, initializeCloudKitSchema, SwiftData relationships
- Apple Developer Forums (threads 732986, 789173, 742899, 736226, 758882) — App Groups, CloudKit migration, background actor

### Secondary (MEDIUM confidence)
- Matteo Manferdini — SwiftData + MVVM compatibility analysis
- AzamSharp — VersionedSchema migration guide, SwiftData iCloud sync status (March 2026)
- AppMakers.DEV — Configurable widget with App Intents and SwiftData
- RevenueCat State of Subscription Apps 2025 — pricing and paywall competitive context
- Reclaim, MindfulSuite, AppleInsider, DailyHabits — competitive feature landscape

### Tertiary (MEDIUM-LOW confidence)
- UXCam mobile app churn benchmarks — retention statistics
- Trophy.so — streaks feature implementation and timezone handling

---

*Research completed: 2026-04-03*
*Ready for roadmap: yes*
