# Phase 13: Challenge Platform — Core Engine - Context

**Gathered:** 2026-05-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 13 delivers a configurable challenge engine built on SchemaV4 (3 new SwiftData models: `ChallengeTemplate`, `UserChallenge`, `CheckIn`). Three featured challenges (90-Day Summer Body, Save $5,000, Dry Summer) are seeded from Swift constants at first launch. A new 5th Challenges tab (Goals · Stats · Wins · Challenges · Profile) hosts the discovery screen. Type-adaptive check-in flows (boolean/numeric/multi-step) are driven entirely by template config — no per-type branching in the engine. A `StreakChainView` (horizontal day-dot component) tracks progress in challenge detail. Evening reminder notifications route directly to the check-in modal, per-challenge at user-set time.

Phase 13 does NOT add: community feed, reactions, profanity filter, optional modules (Spending Freeze, Craving Tools, etc.), custom challenge builder, or the full notification suite — those are Phase 14.

</domain>

<decisions>
## Implementation Decisions

### Featured Template Storage (CHAL-01, CHAL-06, CHAL-07)
- **D-01:** The 3 featured `ChallengeTemplate` instances are defined as Swift static constants (not JSON, not hardcoded per-type logic). No JSON decoding, no file I/O — type-safe, zero new dependency patterns.
- **D-02:** Seeding logic lives in `ChallengeViewModel.seedFeaturedTemplates()`, called on ViewModel init. Checks if featured templates already exist in SwiftData before inserting — idempotent. Follows the existing `GoalViewModel` pattern for proximity between seeding and model ownership.
- **D-03:** User's `UserChallenge` and `CheckIn` records sync via CloudKit (private DB) normally. Template definitions are local constants only — no need to sync the template catalog.

### Tab / Navigation Structure
- **D-04:** Add a **5th "Challenges" tab** to `ContentView`'s `TabView`. Tab order: Goals · Stats · Wins · Challenges · Profile. Tab icon: `flame.fill`. Challenge discovery is the tab root (no push route needed for discovery).
- **D-05:** Two new `AppRoute` cases: `challengeDetail(UserChallenge)` for the challenge detail/progress view; `challengeCheckIn(UserChallenge)` for the daily check-in modal. Both pushed from the Challenges tab's `NavigationStack`.
- **D-06:** `AppRoute.challengeCheckIn` is also the notification deep-link destination — evening reminder carries `UserChallenge.id` in payload, resolved to the check-in modal on tap.

### Check-in Notification Routing (CHAL-12)
- **D-07:** Evening reminder notification → user taps → opens directly to check-in modal (`challengeCheckIn` route) for that challenge. Fastest path. Uses existing `DeepLinkParser/Builder` infrastructure extended with challenge-specific URL scheme.
- **D-08:** Per-challenge reminder time picker lives in challenge detail view (not global SettingsView). Each `UserChallenge` stores its own `reminderHour: Int?` / `reminderMinute: Int?`. Notification identifier: `com.kyleharrington.VitaminG.challengeReminder.\(userChallengeID)` — one identifier per active challenge. Remove-before-add pattern preserves the existing iOS 64-request cap approach.

### Streak Chain View (CHAL-11)
- **D-09:** New `StreakChainView` component — horizontal scrollable row of day circles (past 30 days). Filled circle = checked in; outlined circle = missed; today's circle highlighted. Accent color from the challenge template. NOT the existing `HeatmapView` (that's a grid for goal completion density, semantically different).
- **D-10:** `StreakChainView` appears in the challenge detail view, below the active check-in CTA. User sees streak context after landing from discovery or notification.

### Claude's Discretion
- Exact size of day-dot circles in `StreakChainView` (recommended: 20pt diameter, 2pt stroke for outlined, solid for filled)
- Whether the progress bar toward goal value (CHAL-11) sits above or below the streak chain view in detail layout
- SF Symbol for the milestone celebration badge at different thresholds (e.g., `flame.fill` at 7-day, `trophy.fill` at 30-day)
- Animation curve for the confetti full-screen celebration (CHAL-10) — `withAnimation(.spring)` recommended

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Schema migration (CHAL-04)
- `VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift` — Existing V1→V2→V3 migration plan. SchemaV4 adds `ChallengeTemplate`, `UserChallenge`, `CheckIn` via a new lightweight `migrateV3toV4` stage. Update `schemas` and `stages` arrays here.
- `VitaminG/VitaminG/VitaminG/Models/SchemaV3.swift` — Pattern to follow for SchemaV4: `enum SchemaV4: VersionedSchema`, `models: [any PersistentModel.Type]` includes all V3 models unchanged + 3 new models. All new properties must be optional or have defaults (CloudKit compatibility).
- `VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift` — Update to include new V4 models in container configuration after migration plan update.

### Navigation (D-04, D-05, D-06)
- `VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift` — Add `challengeDetail(UserChallenge)` and `challengeCheckIn(UserChallenge)` cases. Follow existing `Hashable` conformance pattern.
- `VitaminG/VitaminG/VitaminG/Navigation/AppRouter.swift` — May need challenge-specific state (e.g., `pendingChallengeCheckInID`) for notification deep-link routing, parallel to `pendingPublicProfileRecordID`.
- `VitaminG/VitaminG/VitaminG/Views/ContentView.swift` — Add 5th Challenges tab. Update `navigationDestination` handler for new challenge routes.

### Notification infrastructure (CHAL-12, D-07, D-08)
- `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` — Extend with challenge reminder scheduling. Per-challenge identifier scheme.
- `VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift` — Pattern for storing per-challenge reminder time (hour/minute keys keyed by `UserChallenge.id`).
- `VitaminG/VitaminG/VitaminG/Services/DeepLinkBuilder.swift` — Extend with challenge check-in deep-link format.
- `VitaminG/VitaminG/VitaminG/Services/DeepLinkParser.swift` — Parse incoming challenge check-in deep links from notification tap.

### Existing computation patterns
- `VitaminG/VitaminG/VitaminG/Services/StreakEngine.swift` — `Calendar.current.startOfDay` pattern for day comparison. Challenge streak engine must use identical calendar arithmetic for DST-safe midnight handling (CHAL-05).
- `VitaminG/VitaminG/VitaminG/ViewModels/StatsViewModel.swift` — `refresh(events:goals:)` signature pattern. `ChallengeViewModel` should mirror this structure: pure computations accept arrays, no direct SwiftData queries inside the VM.
- `VitaminG/VitaminG/VitaminG/Services/ProgressViewModel.swift` — `@MainActor @Observable`, no SwiftData/SwiftUI dependency, all data passed in as arrays. `ChallengeViewModel` follows the same testability pattern.

### Architecture constraints
- `.planning/PROJECT.md` — No third-party dependencies. MVVM strictly enforced.
- `VitaminG/CLAUDE.md` — `@Observable` ViewModel, iOS 17+ minimum, all SwiftData model properties optional or defaulted, no `@Attribute(.unique)`, `UNCalendarNotificationTrigger` for local notifications.
- `.planning/REQUIREMENTS.md` — CHAL-01 through CHAL-12 are the requirements being closed by this phase.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `StreakEngine.startOfDay` calendar arithmetic — copy-compatible for challenge streak computation (DST-safe)
- `NotificationScheduler` + `UNCalendarNotificationTrigger` — extend, don't replace, for per-challenge reminders
- `DeepLinkBuilder` / `DeepLinkParser` — extend with challenge check-in URL scheme for notification routing
- `GoalTier.color` / accent color system — challenge template `accentColor` uses same color encoding convention
- `VGTheme` — shared design tokens for celebration UI (confetti, milestone badge colors)

### Established Patterns
- `@Observable` ViewModel with `@State private var viewModel = ChallengeViewModel()` in Views — no `@StateObject`, no `@EnvironmentObject`
- Pure VM methods: arrays passed in, no `@Query` inside ViewModels — ensures unit testability (GoalSorter / StreakEngine / ProgressViewModel pattern)
- `SchemaVN` enum pattern: all new models live inside the enum, prior-version models referenced not redeclared
- Lightweight migration for pure additions — V3→V4 is additive only (3 new models), no custom stage needed
- Remove-before-add notification scheduling — preserves iOS 64-request cap; per-challenge identifier keeps challenge reminders independent from goal/win reminders

### Integration Points
- `ContentView.TabView` → add Challenges tab (slot 4, before Profile), `NavigationStack` with `navigationDestination` for challenge routes
- `AppRouter` → may need `pendingChallengeCheckInID: String?` for notification-triggered deep link, parallel to existing `pendingPublicProfileRecordID`
- `ChallengeViewModel.seedFeaturedTemplates()` → called on init, checks SwiftData for existing featured templates before inserting
- `UserChallenge` → stores `reminderHour: Int?`, `reminderMinute: Int?`; `NotificationScheduler` reads these to schedule per-challenge reminder

</code_context>

<specifics>
## Specific Ideas

- Day-dot preview confirmed by user: `● ○ ● ● ● ● ● ○ ● ● ●` — filled = checked in, outlined = missed, accent color for current streak chain
- Tab order confirmed: Goals · Stats · Wins · Challenges · Profile with `flame.fill` icon
- Seeding lives in `ChallengeViewModel`, not `ModelContainerFactory` or app entry point
- Notification routes directly to check-in modal — no intermediate detail view on notification tap

</specifics>

<deferred>
## Deferred Ideas

- $2 subscription tier with profile photo frames (cosmetic rewards / monetization) — future phase post Phase 14
- Community feed, reactions, profanity filter — Phase 14
- Optional modules (Spending Freeze, Craving Tools, Transformation Photos, Nutrition Log, Buddy Accountability) — Phase 14
- Custom challenge builder — Phase 14
- Full notification suite (streak-at-risk, milestone reached, reaction received, buddy ping) — Phase 14

</deferred>

---

*Phase: 13-challenge-platform-core-engine*
*Context gathered: 2026-05-04*
