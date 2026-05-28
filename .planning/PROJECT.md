# Vitamin G

## Current Milestone: v3.0 Personal Intelligence + Apple Watch

**Goal:** Extend Vitamin G to the wrist and make it smarter — Apple Watch with full complication and check-in support, deep analytics with CSV export, AI-powered goal suggestions and personalized daily motivation via Claude, and notifications that adapt to your streak and habits.

**Target features:**
- Apple Watch — streak complication, active goal + progress complication, check-in from wrist, morning nudge delivered to watch
- Analytics dashboard — streak history chart, completion rate trends, full all-time goal heatmap, CSV export via share sheet
- AI (Claude) — suggest new goals based on existing ones + generate personalized daily motivation copy each morning
- Smart notifications — tone adapts to streak level, content references actual goal titles, send time adapts to check-in patterns, streak-at-risk evening alert
- Discover page — search public goals/profiles, trending challenges
- Notification picker — "Pick your daily nudge time" landing
- Tip Jar + About page — tiered payments, version info
- Settings page — nudge time, privacy, dark mode, contact support
- Enhanced widgets — improved home screen widget interactions

**Tab structure (v2.0):** Home · Goals · Explore · Community · Profile

## What This Is

Vitamin G is an iOS app for daily gratitude and tiered goal tracking. Users set goals across four tiers — from immediate wins to life goals — receive personalized daily morning push notifications, track streaks and progress, join community challenges, log daily wins, and share goals socially via CloudKit-backed public profiles. It's "Vitamin G for Gratitude": a daily dose of intentionality.

The app shipped v1.0 as a full-featured iOS app with a configurable Challenge Platform (3 featured challenges + custom builder + 5 optional modules), community feed with reactions and profanity filtering, goal progress rings and milestone celebrations, gratitude/daily wins module, and App Store-quality accessibility.

## Core Value

Every morning, the user is reminded of their goals — making progress feel inevitable, not accidental.

## Current State (v2.0 — in progress)

v1.0 Shipped: 2026-05-15. Phase 24 complete: 2026-05-28.
- v2.0: 24 phases complete (Phases 16–24 are v2.0 milestone work)
- Phase 24 complete: Widget enhancements — WidgetDisplayData extended with activeGoalTitle/activeGoalProgress; GoalSummaryWidget redesigned with equal-split layout; StatsView freeze handler widget-reload gap closed
- SwiftData with 10+ schema versions (SchemaV1 → SchemaV10)
- CloudKit private DB (sync) + CloudKit public DB (community features)
- 5 tabs (v2.0): Home · Goals · Explore · Community · Profile

## Requirements

### Validated

- ✓ Four-tier goal system with CRUD, completion toggle, sorting — v1.0 (Phase 2)
- ✓ VersionedSchema SwiftData models + ModelContainerFactory — v1.0 (Phase 1)
- ✓ App Group + CloudKit-ready ModelContainer shared with widget targets — v1.0 (Phase 1)
- ✓ MVVM architecture with @Observable ViewModels — v1.0 (Phase 1)
- ✓ Secure input validation (100/500/300 char limits, sanitization) — v1.0 (Phase 1)
- ✓ CompletionEvent-based streak computation (per-tier + global) — v1.0 (Phase 3)
- ✓ Stats screen with heatmap, streak cards, completion rate — v1.0 (Phase 3)
- ✓ Personalized daily push notifications (top 3 active goal titles, user time) — v1.0 (Phase 3)
- ✓ CloudKit transparent sync across devices — v1.0 (Phase 4)
- ✓ systemMedium home screen widget + accessoryRectangular lock screen widget — v1.0 (Phase 4)
- ✓ First-launch onboarding with tier explanation and first-goal creation — v1.0 (Phase 5)
- ✓ App Store-quality polish: Dark Mode, Dynamic Type, VoiceOver — v1.0 (Phases 5, 9)
- ✓ CloudKit schema promoted to Production, PrivacyInfo.xcprivacy, TestFlight — v1.0 (Phase 6)
- ✓ User Profiles with AvatarView, privacy toggle, public goals, profile sharing — v1.0 (Phase 7)
- ✓ vitaming:// deep link receive handler for incoming profile links — v1.0 (Phase 10)
- ✓ DailyWin model + DailyWinsView + "What's your win today?" notification variant — v1.0 (Phase 11)
- ✓ Progress rings on goal cards + per-goal history + micro-milestone celebrations + momentum score — v1.0 (Phase 12)
- ✓ ChallengeTemplate engine (SchemaV4) with 3 featured challenges + custom builder — v1.0 (Phase 13)
- ✓ Community feed with CloudKit public DB, reactions, profanity filter, 5 optional modules — v1.0 (Phase 14)
- ✓ ChallengeDiscoveryView redesign, Community Goals landing, ProfileView fixes, username (SchemaV8) — v1.0 (Phase 15)

### Active (v3.0 Targets)

**Apple Watch**
- [ ] Streak count complication on watch face
- [ ] Active goal + progress ring complication on watch face
- [ ] Check-in from wrist (tap complication to mark today's goal complete)
- [ ] Morning nudge notification delivered to Apple Watch

**Analytics**
- [ ] Streak history chart (line/bar showing streak length over time per goal)
- [ ] Completion rate trends (weekly/monthly % chart across all goals)
- [ ] Full all-time goal heatmap (GitHub-style, every day since goal creation)
- [ ] CSV export of all goal history via share sheet

**AI (Claude)**
- [ ] Goal suggestions — Claude analyzes existing goals and suggests complementary ones
- [ ] Personalized daily motivation — Claude generates unique morning copy based on streak + goals

**Smart Notifications**
- [ ] Tone adapts to streak level (celebratory for high streak, encouraging for low/broken)
- [ ] Content references actual goal titles (not generic copy)
- [ ] Send time adapts to user's historical check-in patterns
- [ ] Streak-at-risk evening alert when user hasn't checked in and has streak to protect

### Out of Scope

| Feature | Reason |
|---------|--------|
| Android / cross-platform | iOS-native only — SwiftData/CloudKit ecosystem |
| Web dashboard | Native iOS is the experience |
| Goal collaboration / team goals | Single-user app; social features require backend + moderation |
| Vision board / image collage | Complex media pipeline, CloudKit size limits |
| Recurring / habit goals | Different product primitive from aspirational goal tracking |
| Markdown / rich text in goals | Increases validation complexity; plain text is safer |
| In-app calendar integration | Morning push notification covers the reminder use case |

## Context

- Target platform: iOS 17+ (SwiftData, @Observable, modern SwiftUI APIs)
- Architecture: MVVM with SwiftData + WidgetKit + CloudKit (private + public DB)
- Distribution: App Store + portfolio showcase
- Schema versioned from day one (SchemaV1 → SchemaV10 via VitaminGMigrationPlan)
- Challenge Platform is template-driven — adding new challenge types requires zero core logic
- Community features use CloudKit public DB — no server backend required
- 5-tab navigation (v2.0): Home · Goals · Explore · Community · Profile
- v3.0 adds WatchKit target + Anthropic SDK for AI features

## Constraints

- **Tech Stack**: Swift, SwiftUI, SwiftData — no third-party dependencies unless necessary
- **Security**: All String inputs must have strict character limits and validation; local SwiftData storage must be treated as untrusted input boundary
- **Platform**: iOS 17+ minimum for SwiftData and modern SwiftUI APIs
- **Distribution**: Must meet App Store Review Guidelines — proper notification permissions, no background abuse
- **Architecture**: MVVM strictly enforced — no business logic in Views

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| SwiftData over CoreData | Modern Swift-native API, SwiftUI integration, CloudKit sync built-in | ✓ Good — paid upfront with VersionedSchema, paid off across 8 schema versions |
| MVVM architecture | Clean separation, testable ViewModels, industry standard for iOS | ✓ Good — ChallengeViewModel, DailyWinsViewModel etc. all clean |
| SwiftUI-first UI | Matches SwiftData, enables widgets via WidgetKit naturally | ✓ Good |
| 4-tier goal hierarchy | Maps to realistic planning horizons | ✓ Good — core differentiator |
| Input validation at model layer | Defense in depth even for local storage | ✓ Good |
| VersionedSchema from Phase 1 | One-time cost to enable safe future migrations | ✓ Good — enabled 8 schema versions without data loss |
| Template-driven Challenge Platform | ChallengeTemplate config drives all challenge types; zero core logic per type | ✓ Good — CHAL-07 validated |
| CloudKit public DB for community | Posts, reactions, public profiles — no server required | ✓ Good — no backend cost |
| On-device profanity filter | No server round-trip for content moderation | ✓ Good — fast rejection UX |
| Decimal phase numbering for insertions | Clean insertion semantics without renumbering existing phases | ✓ Good |
| App Group UserDefaults for widget sync | Widgets read from shared store; no file I/O complexity | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-28 — v3.0 milestone started*
