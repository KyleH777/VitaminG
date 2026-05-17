# Roadmap: Vitamin G

## Milestones

- ✅ **v1.0 MVP** — Phases 1–15 (shipped 2026-05-15)
- 🔄 **v2.0 Social Growth Engine** — Phases 16–24 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1–15) — SHIPPED 2026-05-15</summary>

- [x] Phase 1: Foundation (3/3 plans) — completed 2026-04-04
- [x] Phase 2: Core Goal UI (3/3 plans) — completed 2026-04-04
- [x] Phase 3: Streaks, Stats & Notifications (4/4 plans) — completed 2026-05-04
- [x] Phase 4: iCloud Sync & Widgets (2/2 plans) — completed 2026-05-04
- [x] Phase 5: Onboarding & Polish (5/5 plans) — completed 2026-04-27
- [x] Phase 6: Distribution (1/1 plan) — completed 2026-05-01
- [x] Phase 7: User Profiles (4/4 plans) — completed 2026-04-23
- [x] Phase 8: Verification Sprint (4/4 plans) — completed 2026-04-27
- [x] Phase 9: TierPickerView Accessibility Fix (1/1 plan) — completed 2026-04-27
- [x] Phase 10: Profile Deep Link Handler (2/2 plans) — completed 2026-04-23
- [x] Phase 11: Gratitude / Daily Wins Module (4/4 plans) — completed 2026-05-01
- [x] Phase 12: Goal Progress Visualization (6/6 plans) — completed 2026-05-04
- [x] Phase 13: Challenge Platform — Core Engine (9/9 plans) — completed 2026-05-07
- [x] Phase 14: Challenge Platform — Community & Modules (10/10 plans) — completed 2026-05-13
- [x] Phase 15: UI Additions & Fixes (9/9 plans) — completed 2026-05-15

See [.planning/milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md) for full phase details.

</details>

### v2.0 Social Growth Engine

- [x] **Phase 16: Tab Restructuring + AppRoute Updates** - Correct 5-tab navigation with stable Tab enum; Stats/Wins demoted to NavigationLink destinations
- [ ] **Phase 17: Onboarding Overhaul** - Apple Sign-In only, unique username, profile picture upload, permission priming slides, Welcome Back screen, report/block moderation
- [ ] **Phase 18: Home Tab + Goals Flow Enhancements** - New Home dashboard + enhanced goal creation wizard + goal detail page
- [ ] **Phase 19: Tip Jar + About Page + Settings** - StoreKit 2 consumable tip jar, About page with founder bio, Settings page, notification picker
- [ ] **Phase 20: Explore Tab** - Shake/tap daily goal gifter, mood prompt, Vitamin Shelf, Trending Now, 3 Gifts for Stuck Days
- [ ] **Phase 21: Community Tab Redesign** - Today's Glimpses carousel, Active Today, Glowing This Week, community feed with reactions/replies/photos, applause system
- [ ] **Phase 22: Public Profile + Follow + Discover** - Public profile redesign, follow/cheer system, Discover page with goal search and people search
- [ ] **Phase 23: Milestone Features + Streak Freeze** - Streak freeze, achievement unlocked screens, achievement sharing, goal completed celebration
- [ ] **Phase 24: Widget Enhancements** - Update widgets for v2.0 data, wire WidgetCenter.reloadAllTimelines() to all new state changes

---

## Phase Details

### Phase 16: Tab Restructuring + AppRoute Updates
**Goal**: Users navigate a correct 5-tab app (Home, Goals, Explore, Community, Profile) with no routing regressions
**Depends on**: Phase 15 (v1.0 complete)
**Requirements**: TAB-01, TAB-02, TAB-03, TAB-04
**Success Criteria** (what must be TRUE):
  1. User taps each of the 5 tabs and lands on the correct screen — Home, Goals, Explore, Community, Profile
  2. User navigates from the Home tab to Stats and from Home tab to Daily Wins via tappable elements (not top-level tabs)
  3. A deep link or widget intent encoded with a tab name routes to the correct screen after the index swap (no routing regression)
  4. The Explore and Community tabs exist in the bar as empty placeholder screens (no crashes on tap)
**Plans**: 2 plans
- [x] 16-01-PLAN.md — Tab enum + 5-tab restructure + Community/Explore swap + placeholder views (TAB-01, TAB-04)
- [x] 16-02-PLAN.md — HomeView Stats and Daily Wins entry points + Home-tab navigationDestination (TAB-02, TAB-03)

### Phase 17: Onboarding Overhaul
**Goal**: New users complete onboarding with Apple Sign-In, a unique username, optional profile picture, and permission priming; returning signed-out users see a Welcome Back screen; every public profile has a report/block action
**Depends on**: Phase 16
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06, AUTH-07, PROF-05
**Success Criteria** (what must be TRUE):
  1. New user completes sign-up using Sign in with Apple (no Google option visible); must acknowledge the T&C PDF before proceeding
  2. New user claims a username; if the username is already taken the system rejects it immediately with an explanatory message
  3. New user can upload a profile picture from their photo library or camera during onboarding, or skip the step entirely
  4. Onboarding shows a notification permission priming slide and a camera permission priming slide before any system permission dialog appears
  5. Returning user who is not signed in sees a "Welcome Back" screen with a Sign in with Apple button
  6. Every public profile view shows a Report and Block action accessible to the viewer
**Plans**: TBD
**UI hint**: yes

### Phase 18: Home Tab + Goals Flow Enhancements
**Goal**: Users see a complete Home dashboard on every launch and can create goals through a structured wizard with detailed check-in and celebration flows
**Depends on**: Phase 17
**Requirements**: HOME-01, HOME-02, HOME-03, HOME-04, HOME-05, HOME-06, GOAL2-01, GOAL2-02, GOAL2-03, GOAL2-04, GOAL2-05
**Success Criteria** (what must be TRUE):
  1. User opens the app and sees their display name, current streak count, quote of the day, and their primary community goal with a progress bar all on the Home screen
  2. User taps "+add" in the My Goals section on Home and is guided through a 3-step wizard: goal type, writing the goal, and setting duration/schedule/privacy
  3. User taps "Need ideas" during goal creation and sees a list of pre-made goals they can select
  4. User checks off a goal and sees a checkmark celebration screen showing their streak count before returning to Goals
  5. User taps a goal to open its detail page, sees a grid of completed and remaining days, and can check in for today with a streak count display
**Plans**: TBD
**UI hint**: yes

### Phase 19: Tip Jar + About Page + Settings
**Goal**: Users can tip the developer via StoreKit 2 IAP, read the founder's story on the About page, and configure notification time and display preferences from Settings
**Depends on**: Phase 16
**Requirements**: MON-01, MON-02, MON-03, MON-04, SET-01, SET-02, SET-03, SET-04, SET-05, NOTIF-01, NOTIF-02
**Success Criteria** (what must be TRUE):
  1. User opens the About page and reads the founder's bio (cancer recovery and goal-setting story) with the current app version displayed
  2. User taps the tip jar button on About, sees three tip tiers with real prices from StoreKit, and completes a purchase (sandbox); an animated thank-you confirmation appears after purchase
  3. User navigates to Settings from their Profile tab and sees options for notification time, profile privacy, dark mode, and contact support
  4. User changes dark mode preference in Settings and the app immediately applies the chosen appearance (System/Light/Dark) without a restart
  5. User selects a daily nudge time in Settings and the app reschedules the existing notification to that time
**Plans**: TBD
**UI hint**: yes

### Phase 20: Explore Tab
**Goal**: Users discover new goals each day through the Explore tab via shake or tap, mood check-in, category browsing, trending goals, and curated stuck-day gifts
**Depends on**: Phase 16
**Requirements**: EXPLORE-01, EXPLORE-02, EXPLORE-03, EXPLORE-04, EXPLORE-05, EXPLORE-06
**Success Criteria** (what must be TRUE):
  1. User shakes their device or taps "Surprise me" on the Explore tab and receives a random daily goal with a confetti animation; the action is available only once per calendar day
  2. User sees a "How are you feeling?" mood prompt on Explore; selecting a mood collapses the card with a checkmark and the prompt does not return until the next day
  3. User taps a category card in the Vitamin Shelf (Body, Mind, Wellness, Money, Connection, Creative) and sees a filtered list of goals for that category
  4. User sees a Trending Now section showing active community goals with progress circles indicating community completion percentage
  5. User sees 3 Gifts for Stuck Days and taps "Add" on one — the goal appears in their goal list and that card disappears from Explore for the rest of the day
**Plans**: TBD
**UI hint**: yes

### Phase 21: Community Tab Redesign
**Goal**: Users experience a live-feeling community feed with a photo carousel of peers' goals, an applause system, and the ability to post with photos and react to others' posts
**Depends on**: Phase 17
**Requirements**: COMM-01, COMM-02, COMM-03, COMM-04, COMM-05, COMM-06, COMM-07, SOC-01, SOC-02, SOC-03
**Success Criteria** (what must be TRUE):
  1. User opens the Community tab and sees Today's Glimpses — a carousel of community members' goal cards that auto-advances every 5 seconds; tapping a card opens that user's public goal page
  2. User sees an Active Today section showing users who were active in the last 2 hours; tapping a user opens their profile
  3. User sees a Glowing This Week spotlight and can tap the applause button to send a 👏 emoji that floats upward with their username on screen
  4. User can give applause to another user once per day; the button disables after the daily limit is reached with clear visual feedback
  5. User creates a community post with a photo from their library or camera; the post appears in the community feed with the photo visible
  6. User reacts to a post with ❤️, 🔥, or 👍 and the reaction count updates; user can reply to a post
**Plans**: TBD
**UI hint**: yes

### Phase 22: Public Profile + Follow + Discover
**Goal**: Users can view redesigned public profiles, follow other users, give daily cheers, and search public goals and profiles from the Discover page
**Depends on**: Phase 21
**Requirements**: PROF-01, PROF-02, PROF-03, PROF-04, DISC-01, DISC-02, DISC-03, DISC-04
**Success Criteria** (what must be TRUE):
  1. User views another user's public profile and sees their avatar, motto/bio, current streak, goal count, and cheers given count
  2. User taps "Cheer them on today" on a public profile and the applause animation plays; the button disables for the rest of the day after use
  3. User taps Follow on a public profile; the follow is recorded and the button state changes to reflect the follow
  4. User taps the Discover tab and types a keyword; goal results appear within 500ms showing goal title, creator, category, participant count, and a progress circle
  5. User switches to the People segment in Discover search and finds users by username prefix; each result shows a Follow button
  6. User taps Join on a goal in Discover results; the goal appears in their goal list and the participant count increments
**Plans**: TBD
**UI hint**: yes

### Phase 23: Milestone Features + Streak Freeze
**Goal**: Users are protected from accidental streak loss via a weekly freeze, celebrated at streak milestones with shareable achievement screens, and shown a completion celebration when finishing a goal
**Depends on**: Phase 18
**Requirements**: MILE-01, MILE-02, MILE-03, MILE-04, MILE-05, MILE-06
**Success Criteria** (what must be TRUE):
  1. User who missed a day can activate "Life happened." streak freeze once per week; their streak count is preserved and the missed day shows a ❄️ glyph in the heatmap
  2. User who has not checked in by 7 PM and has a weekly freeze available receives a streak-at-risk nudge
  3. User reaches a streak milestone (7, 14, 30, 60, 90, or 365 days) and sees a full-screen achievement unlocked celebration with confetti, milestone label, and a "Share to Community" button; each milestone screen only appears once
  4. Shared achievements appear in the Community main page feed alongside regular posts
  5. User who completes all days of a goal sees a "You did it" page with an animated checkmark, their goal streak count, confetti, and share/back-to-goals actions
**Plans**: TBD
**UI hint**: yes

### Phase 24: Widget Enhancements
**Goal**: The home screen and lock screen widgets reflect v2.0 data (current streak and active goal progress) and stay fresh after every goal state change in the app
**Depends on**: Phase 23
**Requirements**: WID-01, WID-02
**Success Criteria** (what must be TRUE):
  1. User adds the Vitamin G home screen widget and it shows their current streak count and their active goal with a progress indicator that reflects the latest data
  2. After the user checks in on a goal, freezes a streak, or completes a goal inside the app, the widget updates to reflect the change without requiring an app relaunch
**Plans**: TBD

---

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 3/3 | Complete | 2026-04-04 |
| 2. Core Goal UI | v1.0 | 3/3 | Complete | 2026-04-04 |
| 3. Streaks, Stats & Notifications | v1.0 | 4/4 | Complete | 2026-05-04 |
| 4. iCloud Sync & Widgets | v1.0 | 2/2 | Complete | 2026-05-04 |
| 5. Onboarding & Polish | v1.0 | 5/5 | Complete | 2026-04-27 |
| 6. Distribution | v1.0 | 1/1 | Complete | 2026-05-01 |
| 7. User Profiles | v1.0 | 4/4 | Complete | 2026-04-23 |
| 8. Verification Sprint | v1.0 | 4/4 | Complete | 2026-04-27 |
| 9. TierPickerView Accessibility Fix | v1.0 | 1/1 | Complete | 2026-04-27 |
| 10. Profile Deep Link Handler | v1.0 | 2/2 | Complete | 2026-04-23 |
| 11. Gratitude / Daily Wins Module | v1.0 | 4/4 | Complete | 2026-05-01 |
| 12. Goal Progress Visualization | v1.0 | 6/6 | Complete | 2026-05-04 |
| 13. Challenge Platform — Core Engine | v1.0 | 9/9 | Complete | 2026-05-07 |
| 14. Challenge Platform — Community & Modules | v1.0 | 10/10 | Complete | 2026-05-13 |
| 15. UI Additions & Fixes | v1.0 | 9/9 | Complete | 2026-05-15 |
| 16. Tab Restructuring + AppRoute Updates | v2.0 | 0/2 | Not started | - |
| 17. Onboarding Overhaul | v2.0 | 0/? | Not started | - |
| 18. Home Tab + Goals Flow Enhancements | v2.0 | 0/? | Not started | - |
| 19. Tip Jar + About Page + Settings | v2.0 | 0/? | Not started | - |
| 20. Explore Tab | v2.0 | 0/? | Not started | - |
| 21. Community Tab Redesign | v2.0 | 0/? | Not started | - |
| 22. Public Profile + Follow + Discover | v2.0 | 0/? | Not started | - |
| 23. Milestone Features + Streak Freeze | v2.0 | 0/? | Not started | - |
| 24. Widget Enhancements | v2.0 | 0/? | Not started | - |
