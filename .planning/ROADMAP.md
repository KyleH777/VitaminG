# Roadmap: Vitamin G

## Overview

Vitamin G ships in six phases that follow a strict dependency order. Phase 1 locks in the data model, App Group, and CloudKit configuration before any user data exists — the one-time infrastructure cost that makes every subsequent phase safe. Phase 2 delivers the full goal management UI so the app is usable. Phase 3 adds streak computation, statistics, and personalized daily notifications — the core daily-use value loop. Phase 4 extends that data into home screen and lock screen widgets via the shared App Group store. Phase 5 wraps the experience in onboarding, polish, and accessibility. Phase 6 executes the App Store submission checklist and ships.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - App Group, SwiftData models with VersionedSchema, CloudKit-ready ModelContainer, MVVM scaffold, and input validation
- [ ] **Phase 2: Core Goal UI** - Four-tier goal CRUD views, visual tier identity, goal detail with associatedInspiration, completion toggle
- [ ] **Phase 3: Streaks, Stats & Notifications** - CompletionEvent-based streak computation, stats heatmap screen, personalized daily push notifications
- [ ] **Phase 4: iCloud Sync & Widgets** - CloudKit transparent sync, systemMedium home screen widget, accessoryRectangular lock screen widget
- [ ] **Phase 5: Onboarding & Polish** - First-launch onboarding, empty states, Light/Dark Mode, Dynamic Type, VoiceOver, App Store-quality UI
- [ ] **Phase 6: Distribution** - App Store assets, CloudKit schema promotion to Production, TestFlight, App Store submission

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
**Plans:** 3 plans
Plans:
- [ ] 01-01-PLAN.md — VersionedSchema models, ModelContainerFactory, app entry point, entitlements, widget stub
- [ ] 01-02-PLAN.md — AppRouter navigation scaffold, GoalViewModel refinement, ContentView stub
- [ ] 01-03-PLAN.md — Unit tests (GoalViewModel + SchemaV1) and Xcode build verification

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
**Plans**: TBD
**UI hint**: yes

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
**Plans**: TBD

### Phase 4: iCloud Sync & Widgets
**Goal**: Goal data syncs transparently across the user's devices and appears on the home screen and lock screen via read-only widgets that share the same App Group store
**Depends on**: Phase 3
**Requirements**: SYNC-01, SYNC-02, WIDGET-01, WIDGET-02, WIDGET-03, WIDGET-04, WIDGET-05
**Success Criteria** (what must be TRUE):
  1. A goal created on one device appears on a second device signed into the same iCloud account without any manual sync action
  2. The home screen `systemMedium` widget displays the user's top active goals across tiers and updates at least once per day
  3. The lock screen `accessoryRectangular` widget displays the current global streak or top active goal title
  4. Both widgets read from the shared App Group SwiftData store and perform no write operations — all data is read-only from the widget process
**Plans**: TBD
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
**Plans**: TBD
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

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 0/3 | Planning complete | - |
| 2. Core Goal UI | 0/TBD | Not started | - |
| 3. Streaks, Stats & Notifications | 0/TBD | Not started | - |
| 4. iCloud Sync & Widgets | 0/TBD | Not started | - |
| 5. Onboarding & Polish | 0/TBD | Not started | - |
| 6. Distribution | 0/TBD | Not started | - |
