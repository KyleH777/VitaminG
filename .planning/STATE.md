---
gsd_state_version: 1.0
milestone: v3.0
milestone_name: Personal Intelligence + Apple Watch
status: executing
last_updated: "2026-06-08T23:45:00.000Z"
last_activity: 2026-06-08
progress:
  total_phases: 13
  completed_phases: 12
  total_plans: 57
  completed_plans: 57
  percent: 98
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-28)

**Core value:** Every morning, the user is reminded of their goals — making progress feel inevitable, not accidental.
**Current focus:** Phase 27 — apple-watch-app

## Current Position

Phase: 28
Plan: 04
Plans: 4 (waves 0–3)
Status: IN PROGRESS — Plan 28-04 code tasks COMPLETE (Tasks 1 and 2 committed); awaiting human verification checkpoint (Task 3, Checks A–F on simulator)
Last activity: 2026-06-08

```
v3.0 Progress: [##########] 98% (4/4 plans code-complete in phase 28; human verification checkpoint pending for 28-04)
```

## Accumulated Context

### Key Decisions

| Decision | Rationale |
|----------|-----------|
| v2.0 tab structure: Home · Goals · Explore · Community · Profile | Replaces Goals · Stats · Wins · Challenges · Profile — Stats/Wins consolidated into Home, Challenges replaced by Explore/Community |
| Apple Sign-In only | Remove Google Sign-In; aligns with iOS-native identity + T&C PDF requirement |
| No SchemaV9 required | SchemaV8 already has username + photoData; all new social data goes to CloudKit public DB record types — avoids migration risk |
| PROF-05 (report/block) ships in Phase 17 on PublicProfileView | App Store Guideline 1.2 requires moderation alongside profile photos — cannot defer; D-12 revised: PublicProfileView (not ProfileView) is the correct target since ProfileView is self-view |
| Phases continue from 16 (not reset to 1) | Continuous phase numbering across milestones |
| Tab enum with stable string raw values | Prevents deep link and widget intent routing breakage when tab indices shift |
| Active Today (not live heartbeat) | CloudKit write quota exhaustion risk; single lastActive write at app open; show users active within 2 hours |
| CKAsset fileURL must be copied immediately | OS silently reclaims temporary paths under storage pressure — copy to Application Support on fetch |
| StoreKit 2 consumable IAPs only | No external payment links (App Store Guideline 3.1.1); Transaction.updates listener at VitaminGApp init |
| StreakFreeze uses ISO8601 calendar | weekOfYear Monday reset requires Calendar(identifier: .iso8601), not .gregorian |
| Widget phase is last (Phase 24) | Widgets are read-only consumers; schema must be stable before wiring WidgetCenter reloads |
| NavigationDestination placeholder stubs for new OnboardingStep cases | Plans 2-5 replace Text placeholders; NavigationStack lazy-loads so stubs are safe |
| CommunityGoalOnboardingScreen.advance() calls onSkip() | .createGoal removed per D-16; community goal is final onboarding step before app entry |
| StepBarView(current:0, total:7) on T&C screen | T&C is step 0; total:7 follows PATTERNS.md over UI-SPEC §2 total:6 per plan interface section note |
| if-let guard on termsURL (no force-unwrap) | T-17-02-02 mitigation: PDFPreviewView never constructed with nil URL; DEBUG assert surfaces missing bundle resource |
| claimUsername posts writeUsername first, then countRecords post-save D-17 race check | Race condition detection at claim time; conflicting record deleted, false returned so UsernameScreen shows inline error |
| ProfileSharingService.publishProfile username param defaults to nil | Backward compatible additive extension; completeOnboarding() passes stored username for write coordination |
| UsernameCheckState falls back to .idle on CloudKit error (not .taken) | Silent fallback allows retry without false "taken" feedback on network failure |
| VerificationResult.unverified returns (false,false) — never triggers showThankYou | T-19-03-01: tampered/forged receipt yields no user-visible consequence; StoreKit 2 JWS auto-verified |
| interactiveDismissDisabled applied at TipJarView presenter, not inside TipThankYouView | Keeps TipThankYouView self-contained and dismiss-agnostic |
| SettingsView.supportMailtoURLString extracted as static let | Allows SettingsViewTests to reference authoritative URL string without instantiating the view |
| profileVM.toggleProfilePublic delegates isPublic write in SettingsView Privacy toggle | Reuses existing CloudKit-aware write/delete path — Settings adds no new write logic (T-19-04-03) |
| associatedInspiration = "vg_gifter" set post-insert on gifted goals | Enables @Query filter in ExploreView to count daily accomplishments without a schema migration |
| Daily gifter gate stored as Date in UserDefaults (vg_explore_gifterDate) | Lightweight persistence for one-per-day gate; Calendar.current.isDateInToday() check is timezone-safe |
| ShakeDetectorView becomeFirstResponder in viewDidAppear (not viewDidLoad) | Re-acquires first-responder after NavigationStack push/pop; viewDidLoad only fires once per controller lifetime |
| navigationDestination(for: GoalCategory.self) placed on ScrollView in ExploreView | Keeps navigation logic local to Explore tab; GoalCategory is a new nav value type — no conflict with ContentView destinations |
| TrendingGoal CKRecord schema uses silent fallback | TrendingGoal record type not yet deployed to CloudKit — ExploreService catches CKError and returns staticTrendingGoals |
| StuckDayGift.id is a stable String (not UUID()) | Reproducible UserDefaults hide key across sessions; changing IDs would break hide gates |
| StuckDayGift.description renamed to .subtitle | Avoids CustomStringConvertible protocol conflict with Swift's built-in description property |
| v3.0 build order: Notifications → Analytics → Watch → AI | Notifications first (no new infra, validates cancel-on-check-in path Watch needs); Analytics second (self-contained); Watch third (new target, physical device required, cancel path must pre-exist); AI last (new backend proxy is highest-risk infra) |
| WatchConnectivity (not App Groups) for iOS-Watch data bridge | App Groups are same-device only; CloudKit-to-watchOS sync is documented as unreliable; WCSession is the only reliable cross-device bridge |
| Cloudflare Worker proxy for AI features | Anthropic API key must never be embedded in iOS binary; Cloudflare Worker holds the key server-side; free up to 100K req/day |
| No SchemaV11 required for v3.0 | All v3.0 state (motivation copy, check-in hour history, Watch snapshot) lives in UserDefaults; analytics derives from existing CompletionEvent data |
| BGAppRefreshTask is fallback only for AI motivation copy | BGAppRefreshTask is non-deterministic for infrequent users; primary generation trigger is app foreground with date-key cache check |
| Streak-at-risk evening alert uses schedule-and-cancel (not BGAppRefreshTask) | BGAppRefreshTask throttled for infrequent users (exactly who needs the alert); schedule morning + cancel on any check-in surface |
| Watch check-in must cancel streak-at-risk notification via same path as iOS/widget | 64-slot cap requires reliable cancellation; all three check-in surfaces (app, widget, Watch) must call the same removePendingNotificationRequests path |
| watchOS 10.0 minimum for Watch target | Existing scaffold targets watchOS 7.0 — too low for WidgetKit complications; set to 10.0 immediately; Button(intent:) interactive complications require watchOS 11.0, guard with @available |
| Watch-scoped App Group is group.com.kyleharrington.VitaminGWatch | Distinct from iOS group.com.kyleharrington.VitaminG; iOS and watchOS App Group containers are different filesystem locations (DTS-confirmed) |
| WatchSnapshot.build() delegates to WidgetDataProvider.build() — not re-derived | Guarantees identical active goal selection on iPhone and Watch; single source of truth for tier priority + creationDate tiebreak |
| FetchDescriptor<CompletionEvent>() for events fetch in GoalViewModel.addCheckIn pushSnapshot call | compactMap{$0.completionEvents}.flatMap{$0} triggers SwiftData KeyPath crash in test context; direct fetch is correct pattern (same as rescheduleNotification) |
| onCheckIn closure assigned before WatchSessionManager.activate() in VitaminGApp.init() | RESEARCH.md Pitfall 1: queued userInfo delivered immediately on activation; closure must exist before activate() call |
| Transient GoalViewModel() constructed in onCheckIn closure | No shared singleton; addCheckIn has no view-state dependency; local instance is correct and consistent with VitaminGApp.body usage pattern |
| activeGoalProgress coerced to 0.0 in WatchSnapshot (not nil) | Watch progress ring (VGRingView) requires concrete Double; nil from WidgetDataProvider means no duration set → 0.0 is correct (D-01) |
| WatchSnapshot payload encoded as Data under key "snapshot" in applicationContext dict | Property-list safe; JSON-encoded Data survives WCSession serialization without type coercion issues |
| WatchReceiver.swift compiled into both VitaminGWatch and VitaminG iOS targets | Required for @testable import VitaminG to expose WatchReceiver to WatchReceiverTests; WatchConnectivity+WidgetKit compile on iOS |
| #if os(iOS) guards for sessionDidBecomeInactive/sessionDidDeactivate in WatchReceiver | iOS WCSessionDelegate requires these methods; watchOS omits them (Pitfall 6); cross-platform file requires guards |
| processApplicationContext(_:into:) injectable wrapper in WatchReceiver | Enables unit test isolation without WCSession instantiation; tests pass ephemeral UUID-keyed UserDefaults suites |
| TodayGlanceView uses @AppStorage backed by Watch App Group suite | Reactive on UserDefaults change; no custom ViewModel needed for WATCH-02 read path |
| SHARED_TOKEN uses REPLACE_WITH_UUID_AT_DEPLOY placeholder in worker/src/index.js | Operator generates UUID via uuidgen and replaces before wrangler deploy; same UUID pasted into AIProxyService.workerToken in Plan 02 (Pitfall 2 prevention, T-28-02) |
| worker/ created at project root alongside VitaminG/ — not inside Xcode project | Cloudflare Worker is a JavaScript artifact; must not be in the Xcode project directory to avoid confusing Xcode build system |
| Wave 0 RED test files on disk but not yet added to Xcode test target | Xcode .pbxproj requires manual addition; Plan 02 first task adds both files to VitaminGTests target before turning GREEN |
| MockAIProxyService defined inline in AIProxyServiceTests.swift | Protocol seam (AIProxyServiceProtocol) enables mock injection without network; inline definition keeps Wave 0 file self-contained |
| Worker deployed at https://vg-ai-proxy.kileharrington.workers.dev/ai; SHARED_TOKEN = 020A3129-9FDB-4817-8C8F-EA1A27F59A38 | Smoke tests 4/4 PASSED; Plan 02 embeds these as AIProxyService.workerURL and .workerToken static lets |
| macOS head -n-1 → sed '$d' in test-worker.sh | GNU head -n-1 is not available on macOS BSD head; sed '$d' achieves same result cross-platform |
| PBXFileSystemSynchronizedRootGroup auto-includes new Swift files (Plan 28-02) | Xcode 16 synchronized groups handle Services/ and ViewModels/ subdirectories automatically — no manual pbxproj edits required for AIProxyService.swift and AIViewModel.swift |
| AIViewModel is NOT a singleton (Plan 28-02) | Separate @State instances per view (HomeView, ExploreView) are acceptable; AIProxyService UserDefaults cache deduplicates per day (Pitfall 3 / A3) |
| AIProxyService.staticSuggestions = ["Read for 15 minutes daily", "Drink 8 glasses of water", "Meditate for 5 minutes"] | D-07 canonical 3-item fallback list; must match Worker's fallback array |
| AIMotivationSection uses @Bindable aiViewModel (Plan 28-03) | @Bindable enables two-way binding to @Observable AIViewModel; view components read motivationLabel and motivationResult.text exclusively — no hardcoded label strings in the view |
| .task modifier on HomeView outermost ZStack fires refreshMotivationIfNeeded (Plan 28-03) | Pitfall 6 compliant; fetch originates from view lifecycle, not VitaminGApp.init; once-per-day UserDefaults cache prevents redundant network calls |
| GoalSuggestionsCard uses @Bindable aiViewModel pattern (Plan 28-04) | mirrors AIMotivationSection; @Bindable enables addedSuggestionIndices mutation via withAnimation; card always shows 3 rows (never empty/error per D-07) |
| .task modifier on ExploreView ScrollView fires refreshSuggestionsIfNeeded with real @Query allGoals and completionEvents (Plan 28-04) | Pitfall 6 compliant; @Query completionEvents added to ExploreView for personalized Claude prompt |
| GoalSuggestionsCard uses .padding(16) not .padding(18) (Plan 28-04) | 4-point grid compliance per UI-SPEC §Spacing; GoalGifterCard uses 18pt (legacy), GoalSuggestionsCard uses 16pt as new-construction reference |

### Blockers

None.

### Pending Todos

- App Store Connect: configure 3 consumable IAP products (Small Coffee ~$0.99, Large Coffee ~$2.99, Supporter ~$4.99) before Phase 19 real-device testing
- CloudKit Console: promote new public DB record types (UserPresence, Applause, Follow, extended PublicProfile) to Production before Phase 21
- CloudKit Console: add Queryable index on "username" field in PublicProfile record type (iCloud.com.kyleharrington.VitaminG) before 17-03 real-device testing — required for username availability check (isUsernameTaken/countRecordsWithUsername)
- CloudKit Console: create TrendingGoal record type (title/String, category/String, participantCount/Int64, completedCount/Int64, createdAt/DateTime) + Queryable index on participantCount + deploy to Production + seed records before real-device Explore tab testing
- [DONE - Plan 28-01] Worker deployed at https://vg-ai-proxy.kileharrington.workers.dev/ai; SHARED_TOKEN = 020A3129-9FDB-4817-8C8F-EA1A27F59A38; Plan 02 must embed these as AIProxyService.workerURL and AIProxyService.workerToken

## Deferred Items (from v1.0)

Items deferred at v1.0 close — carry forward context:

| Category | Item | Status |
|----------|------|--------|
| testing | Nyquist compliance (0/15 phases nyquist_compliant=true) | deferred |
| human_verification | SYNC-01: cross-device iCloud sync test (requires two physical devices) | deferred |
| human_verification | WIDGET-01/02/05: physical device widget rendering | deferred |
| tech_debt | AppRouter.navigate()/pop() dead API surface (no call sites) | deferred |
| tech_debt | SchemaV1.models typealias semantic smell (V2 types aliased in V1) | deferred |
