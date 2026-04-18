# Roadmap: Vitamin G

## Overview

Vitamin G ships in six phases that follow a strict dependency order. Phase 1 locks in the data model, App Group, and CloudKit configuration before any user data exists — the one-time infrastructure cost that makes every subsequent phase safe. Phase 2 delivers the full goal management UI so the app is usable. Phase 3 adds streak computation, statistics, and personalized daily notifications — the core daily-use value loop. Phase 4 extends that data into home screen and lock screen widgets via the shared App Group store. Phase 5 wraps the experience in onboarding, polish, and accessibility. Phase 6 executes the App Store submission checklist and ships.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - App Group, SwiftData models with VersionedSchema, CloudKit-ready ModelContainer, MVVM scaffold, and input validation
- [x] **Phase 2: Core Goal UI** - Four-tier goal CRUD views, visual tier identity, goal detail with associatedInspiration, completion toggle (completed 2026-04-04)
- [x] **Phase 3: Streaks, Stats & Notifications** - CompletionEvent-based streak computation, stats heatmap screen, personalized daily push notifications (completed 2026-04-06)
- [ ] **Phase 4: iCloud Sync & Widgets** - CloudKit transparent sync, systemMedium home screen widget, accessoryRectangular lock screen widget
- [ ] **Phase 5: Onboarding & Polish** - First-launch onboarding, empty states, Light/Dark Mode, Dynamic Type, VoiceOver, App Store-quality UI
- [ ] **Phase 6: Distribution** - App Store assets, CloudKit schema promotion to Production, TestFlight, App Store submission
- [ ] **Phase 8: Verification Sprint** - Generate VERIFICATION.md for phases 2, 3, and 7; register PROF-01–10 in REQUIREMENTS.md; update stale checkboxes
- [ ] **Phase 9: TierPickerView Accessibility Fix** - Fix Color.white Dark Mode failure (UI-05) and hardcoded Dynamic Type font sizes (UI-06) in TierCardView
- [ ] **Phase 10: Profile Deep Link Handler** - Add vitaming:// onOpenURL handler to VitaminGApp; wire AppRouter profile navigation for PROF-06 and PROF-07

## Phase Details

### Phase 1: Foundation
**Goal**: The data layer is correct, CloudKit-compatible, and App Group-shared before any user data exists — making every future phase safe to build on
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05, FOUND-06, FOUND-07
**Success Criteria** (what must be TRUE):
  1. A `Goal` record can be created, persisted, and read back from the shared App Group SwiftData store without data loss on app relaunch
  2. The `ModelContainer` is configured with both `groupContainer: .identifier(...)` and `cloudKitDatabase: .automatic` and the app launches without errors on a physical device
  3. `Goal` and `CompletionEvent` models use `VersionedSchema` (SchemaV1) and all properties are optional or defaulted — confirmed by passing CloudKit schema initialization in `#if DEBUG`
  4. A ViewModel can perform a validated create operation and be rejected when title exceeds 100 characters, description exceeds 500 characters, or associatedInspiration exceeds 300 characters
**Plans:** 2/3 plans executed
Plans:
- [x] 01-01-PLAN.md — VersionedSchema models, ModelContainerFactory, app entry point, entitlements, widget stub
- [x] 01-02-PLAN.md — AppRouter navigation scaffold, GoalViewModel refinement, ContentView stub
- [x] 01-03-PLAN.md — Unit tests (GoalViewModel + SchemaV1) and Xcode build verification

### Phase 2: Core Goal UI
**Goal**: Users can fully manage their goals across all four tiers — creating, editing, completing, re-activating, deleting, and viewing inspiration — with a visually distinct UI per tier
**Depends on**: Phase 1
**Requirements**: GOAL-01, GOAL-02, GOAL-03, GOAL-04, GOAL-05, GOAL-06, GOAL-07, UI-01, UI-02, UI-03
**Success Criteria** (what must be TRUE):
  1. User can create a goal with title, optional description, tier selection, and optional associatedInspiration — all fields validated before save
  2. User can view all goals grouped by tier, where each tier has a distinct color, icon, and typographic weight that makes tiers immediately distinguishable at a glance
  3. User can edit any goal field, delete a goal after a confirmation prompt, and sort the list by tier, creation date, or completion status
  4. User can tap a completion toggle on any goal — a `CompletionEvent` record is created with timestamp and tier — and the goal shows a distinct visual state for completed vs. active
  5. Completed goals remain visible and can be re-activated; the goal detail view prominently displays the `associatedInspiration` field
**Plans:** 3/3 plans complete
Plans:
- [x] 02-01-PLAN.md — AppRoute.goalDetail, ContentView wiring, GoalDetailView with quote card and delete action
- [x] 02-02-PLAN.md — updateGoal(), TierPickerView 2x2 grid, AddGoalView edit mode, celebratory completion visual
- [x] 02-03-PLAN.md — Sort toolbar, SortOption enum, GoalSorter, two-section completion-status layout, human verify

### Phase 3: Streaks, Stats & Notifications
**Goal**: Users see their completion history as meaningful streaks and statistics, and receive a personalized daily notification containing their actual active goal titles
**Depends on**: Phase 2
**Requirements**: STATS-01, STATS-02, STATS-03, STATS-04, STATS-05, STATS-06, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05, NOTIF-06, NOTIF-07
**Success Criteria** (what must be TRUE):
  1. The stats screen shows a current streak per tier (consecutive days with at least one completion event in that tier) and a global streak (any tier) — both computed from `CompletionEvent` records using `Calendar.current` day comparisons, not raw `TimeInterval`
  2. The stats screen includes a calendar heatmap view showing completion activity across past days, per tier and globally
  3. A daily notification fires at the user's selected time (default 8:00 AM) and its body contains the user's actual active goal titles (up to top 3) — not a generic message
  4. Notification scheduling uses `UNCalendarNotificationTrigger` with `repeats: true` and stays within the iOS 64-request limit
  5. Tapping a notification opens the app directly to the goal list; the user can change notification time in Settings and existing notifications are rescheduled immediately
**Plans:** 3/4 plans executed
Plans:
- [x] 03-01-PLAN.md — StreakEngine TDD (per-tier + global streaks), AppRoute expansion, TabView restructure
- [x] 03-02-PLAN.md — StatsViewModel, StatsView with streak cards, HeatmapView, ContentView Stats tab wiring
- [x] 03-03-PLAN.md — NotificationScheduler, NotificationDelegate, SettingsView, VitaminGApp + GoalViewModel wiring
- [ ] 03-04-PLAN.md — Full test suite run and human visual verification of all Phase 3 features

### Phase 4: iCloud Sync & Widgets
**Goal**: Goal data syncs transparently across the user's devices and appears on the home screen and lock screen via read-only widgets that share the same App Group store
**Depends on**: Phase 3
**Requirements**: SYNC-01, SYNC-02, WIDGET-01, WIDGET-02, WIDGET-03, WIDGET-04, WIDGET-05
**Success Criteria** (what must be TRUE):
  1. A goal created on one device appears on a second device signed into the same iCloud account without any manual sync action
  2. The home screen `systemMedium` widget displays the user's top active goals across tiers and updates at least once per day
  3. The lock screen `accessoryRectangular` widget displays the current global streak or top active goal title
  4. Both widgets read from the shared App Group SwiftData store and perform no write operations — all data is read-only from the widget process
**Plans:** 2 plans
Plans:
- [ ] 04-01-PLAN.md — Main app widget wiring (WidgetCenter reload, Settings streak row, App Group UserDefaults, makeWidgetContainer, Wave 0 test stubs)
- [ ] 04-02-PLAN.md — Widget data layer + full widget implementation (WidgetDataProvider, GoalSummaryWidget, StreakWidget, test upgrades)
**UI hint**: yes

### Phase 5: Onboarding & Polish
**Goal**: First-time users are guided into the app with tier explanation and first-goal creation; returning users experience App Store-quality UI with full accessibility and Light/Dark Mode support
**Depends on**: Phase 4
**Requirements**: ONBOARD-01, ONBOARD-02, ONBOARD-03, ONBOARD-04, NOTIF-01, UI-04, UI-05, UI-06
**Success Criteria** (what must be TRUE):
  1. A first-launch user is walked through the four tiers with warm, gratitude-framing copy and guided to create their first goal before reaching the main goal list
  2. Notification permission is requested during onboarding (after first goal is created) with a value-framing screen — not on cold app launch
  3. Every tier's empty state displays an actionable prompt to add a first goal — no blank or placeholder screens exist in the shipping build
  4. The app renders correctly in both Light and Dark Mode, all text scales properly with Dynamic Type at all size categories, and every interactive element has a VoiceOver label
**Plans:** 5 plans
Plans:
- [ ] 05-01-PLAN.md — Onboarding flow: OnboardingViewModel, 3-screen NavigationStack, NotificationPermissionSheet, VitaminGApp gate
- [ ] 05-02-PLAN.md — Per-tier empty states: EmptyTierView component, GoalListView wiring
- [ ] 05-03-PLAN.md — Light/Dark Mode + Dynamic Type: semantic colors, font migration across 5 views
- [ ] 05-04-PLAN.md — VoiceOver labels, touch targets, app icon wiring, placeholder audit, test stubs
- [ ] 05-05-PLAN.md — Gap closure: TierCardView Dynamic Type font migration and Dark Mode color fix
**UI hint**: yes

### Phase 6: Distribution
**Goal**: The app passes App Store Review and ships to the public with CloudKit schema promoted to Production and TestFlight validated
**Depends on**: Phase 5
**Requirements**: SYNC-03
**Success Criteria** (what must be TRUE):
  1. CloudKit schema is promoted from Development to Production in CloudKit Console before App Store submission — confirmed by a test device in production mode syncing correctly
  2. The app passes a TestFlight beta with no crash reports on core flows (create goal, complete goal, view stats, receive notification)
  3. App Store listing has complete metadata: screenshots for all required device sizes, description, keywords, and privacy manifest (PrivacyInfo.xcprivacy) covering all required-reason APIs used
**Plans**: TBD

### Phase 7: Add user profiles with privacy toggle, profile picture upload, and AI-generated character avatar
**Goal:** Users have a personal profile with display name, warm-colored initials avatar, privacy toggle (public/private), per-goal public/private controls, and a shareable deep link for public profiles via CloudKit public database
**Depends on:** Phase 6
**Requirements**: PROF-01, PROF-02, PROF-03, PROF-04, PROF-05, PROF-06, PROF-07, PROF-08, PROF-09, PROF-10
**Success Criteria** (what must be TRUE):
  1. SchemaV2 migration adds UserProfile model and Goal.isPublic without data loss on existing records
  2. Profile tab (4th tab) shows avatar, display name, privacy toggle, public goals preview, and share button
  3. Toggling profile to Public saves a PublicProfile record to CloudKit public database; toggling Private deletes it
  4. Share Profile button generates a vitaming://profile/<recordID> deep link and presents system share sheet
  5. GoalDetailView has a working "Share this goal" toggle that persists isPublic on the Goal
  6. AvatarView renders initials + warm color (or photo when photoData is available in future)
**Plans:** 4 plans

Plans:
- [x] 07-01-PLAN.md — SchemaV2 migration: UserProfile model, Goal.isPublic, VitaminGMigrationPlan, ModelContainerFactory update
- [x] 07-02-PLAN.md — Profile UI: ProfileViewModel, ProfileView (4th tab), ProfileEditSheet, GoalDetailView public toggle
- [x] 07-03-PLAN.md — CloudKit public sharing: ProfileSharingService, DeepLinkBuilder, Info.plist URL scheme, ShareLink wiring
- [x] 07-04-PLAN.md — AvatarView component: reusable initials+color avatar with photo fallback, integrated into ProfileView and ProfileEditSheet

### Phase 8: Verification Sprint
**Goal:** Formally verify completed phases 2, 3, and 7 so their requirements count as satisfied; register PROF-01–10 in REQUIREMENTS.md; update all stale checkboxes
**Depends on:** Phase 7
**Requirements:** GOAL-01, GOAL-02, GOAL-03, GOAL-04, GOAL-05, GOAL-06, UI-01, UI-03, STATS-01, STATS-02, STATS-03, STATS-04, STATS-05, STATS-06, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05, NOTIF-06, NOTIF-07, PROF-01, PROF-02, PROF-03, PROF-04, PROF-05, PROF-08, PROF-09, PROF-10
**Gap Closure:** Closes gaps from v1.0 audit — missing VERIFICATION.md for phases 2, 3, 7; orphaned PROF-01–10; stale REQUIREMENTS.md checkboxes
**Success Criteria** (what must be TRUE):
  1. VERIFICATION.md exists for Phase 2 and all GOAL-01–06, UI-01, UI-03 show Satisfied
  2. VERIFICATION.md exists for Phase 3 and all STATS-01–06, NOTIF-02–07 show Satisfied
  3. VERIFICATION.md exists for Phase 7 and PROF-01–05, PROF-08–10 show Satisfied
  4. PROF-01–10 are listed in REQUIREMENTS.md v1 section and traceability table
  5. All stale REQUIREMENTS.md checkboxes (Phase 4 SYNC/WIDGET, Phase 5 NOTIF/ONBOARD) updated to reflect current state
**Plans:** 4 plans
Plans:
- [x] 08-01-PLAN.md — Phase 2 VERIFICATION.md (GOAL-01–06, UI-01, UI-03)
- [x] 08-02-PLAN.md — Phase 3 VERIFICATION.md (STATS-01–06, NOTIF-02–07)
- [x] 08-03-PLAN.md — Phase 7 VERIFICATION.md (PROF-01–05, PROF-08–10; gaps: PROF-06, PROF-07)
- [x] 08-04-PLAN.md — REQUIREMENTS.md checkbox and traceability table updates

### Phase 9: TierPickerView Accessibility Fix
**Goal:** Fix the two confirmed accessibility failures in TierCardView — Dark Mode (Color.white) and Dynamic Type (hardcoded font sizes) — so UI-05 and UI-06 pass verification
**Depends on:** Phase 8
**Requirements:** UI-05, UI-06
**Gap Closure:** Closes UI-05 (confirmed FAILED in Phase 5 VERIFICATION.md) and UI-06 (PARTIAL — hardcoded font sizes)
**Success Criteria** (what must be TRUE):
  1. TierCardView unselected fill uses `.systemBackground` or semantic adaptive color — no `Color.white` hardcode
  2. TierCardView displayName label uses `.subheadline` text style (Dynamic Type-scaled)
  3. TierCardView description label uses `.caption` text style (Dynamic Type-scaled)
  4. Dark Mode visual check: TierPickerView renders without harsh white rectangles in dark system appearance
**Plans:** TBD

### Phase 10: Profile Deep Link Handler
**Goal:** Implement the missing vitaming:// deep link receive path so incoming profile links resolve to the correct profile view instead of being silently dropped
**Depends on:** Phase 8
**Requirements:** PROF-06, PROF-07
**Gap Closure:** Closes PROF-06 and PROF-07 integration gaps and the "Incoming profile deep link" broken flow from the v1.0 audit
**Success Criteria** (what must be TRUE):
  1. VitaminGApp.body has `.onOpenURL { url in ... }` handler that parses `vitaming://profile/<recordID>`
  2. Handler resolves the recordID and calls `AppRouter.navigate(to: .profile)` with the correct profile
  3. Tapping a shared vitaming:// profile link opens the app directly to that user's profile
**Plans:** TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 3/3 | Complete |  |
| 2. Core Goal UI | 3/3 | Complete   | 2026-04-04 |
| 3. Streaks, Stats & Notifications | 3/4 | In Progress|  |
| 4. iCloud Sync & Widgets | 0/2 | Not started | - |
| 5. Onboarding & Polish | 0/5 | Not started | - |
| 6. Distribution | 0/TBD | Not started | - |
| 7. User Profiles | 0/4 | Not started | - |
| 8. Verification Sprint | 0/4 | Not started | - |
| 9. TierPickerView Accessibility Fix | 0/TBD | Not started | - |
| 10. Profile Deep Link Handler | 0/TBD | Not started | - |
