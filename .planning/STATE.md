---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Social Growth Engine
status: ready_to_execute
last_updated: "2026-05-17T16:15:00.000Z"
last_activity: 2026-05-17 -- Phase 17 Plan 02 complete (TermsAndConditionsScreen + PDFPreviewView)
progress:
  total_phases: 9
  completed_phases: 1
  total_plans: 7
  completed_plans: 4
  percent: 19
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-15)

**Core value:** Every morning, the user is reminded of their goals — making progress feel inevitable, not accidental.
**Current focus:** Milestone v2.0 — Social Growth Engine

## Current Position

Phase: 17 — Onboarding Overhaul
Plan: 02 complete — next: 17-03-PLAN.md
Status: In progress — 2/5 plans complete
Last activity: 2026-05-17 -- Plan 17-02 complete (TermsAndConditionsScreen + PDFPreviewView + OnboardingView wired)

```
v2.0 Progress: [===                 ] 19% (1/9 phases, 4/7 plans)
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

### Blockers

None.

### Pending Todos

- App Store Connect: configure 3 consumable IAP products (Small Coffee ~$0.99, Large Coffee ~$2.99, Supporter ~$4.99) before Phase 19 real-device testing
- CloudKit Console: promote new public DB record types (UserPresence, Applause, Follow, extended PublicProfile) to Production before Phase 21

## Deferred Items (from v1.0)

Items deferred at v1.0 close — carry forward context:

| Category | Item | Status |
|----------|------|--------|
| testing | Nyquist compliance (0/15 phases nyquist_compliant=true) | deferred |
| human_verification | SYNC-01: cross-device iCloud sync test (requires two physical devices) | deferred |
| human_verification | WIDGET-01/02/05: physical device widget rendering | deferred |
| tech_debt | AppRouter.navigate()/pop() dead API surface (no call sites) | deferred |
| tech_debt | SchemaV1.models typealias semantic smell (V2 types aliased in V1) | deferred |
