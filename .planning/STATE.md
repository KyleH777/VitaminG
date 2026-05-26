---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Social Growth Engine
status: executing
last_updated: "2026-05-26T17:41:24.216Z"
last_activity: 2026-05-26
progress:
  total_phases: 9
  completed_phases: 8
  total_plans: 37
  completed_plans: 37
  percent: 89
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-15)

**Core value:** Every morning, the user is reminded of their goals — making progress feel inevitable, not accidental.
**Current focus:** Phase null — milestone-features-streak-freeze

## Current Position

Phase: 24
Plan: Not started
Status: Executing Phase null
Last activity: 2026-05-26

```
v2.0 Progress: [██████████] 100% (6/9 phases, 28/28 plans)
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

### Blockers

None.

### Pending Todos

- App Store Connect: configure 3 consumable IAP products (Small Coffee ~$0.99, Large Coffee ~$2.99, Supporter ~$4.99) before Phase 19 real-device testing
- CloudKit Console: promote new public DB record types (UserPresence, Applause, Follow, extended PublicProfile) to Production before Phase 21
- CloudKit Console: add Queryable index on "username" field in PublicProfile record type (iCloud.com.kyleharrington.VitaminG) before 17-03 real-device testing — required for username availability check (isUsernameTaken/countRecordsWithUsername)
- CloudKit Console: create TrendingGoal record type (title/String, category/String, participantCount/Int64, completedCount/Int64, createdAt/DateTime) + Queryable index on participantCount + deploy to Production + seed records before real-device Explore tab testing

## Deferred Items (from v1.0)

Items deferred at v1.0 close — carry forward context:

| Category | Item | Status |
|----------|------|--------|
| testing | Nyquist compliance (0/15 phases nyquist_compliant=true) | deferred |
| human_verification | SYNC-01: cross-device iCloud sync test (requires two physical devices) | deferred |
| human_verification | WIDGET-01/02/05: physical device widget rendering | deferred |
| tech_debt | AppRouter.navigate()/pop() dead API surface (no call sites) | deferred |
| tech_debt | SchemaV1.models typealias semantic smell (V2 types aliased in V1) | deferred |
