# Roadmap: Vitamin G

## Milestones

- ✅ **v1.0 MVP** — Phases 1–15 (shipped 2026-05-15)
- 🔄 **v2.0 Social Growth Engine** — Phases 16–24 (in progress)
- 📋 **v3.0 Personal Intelligence + Apple Watch** — Phases 25–28 (planned)

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
- [x] **Phase 17: Onboarding Overhaul** - Apple Sign-In only, unique username, profile picture upload, permission priming slides, Welcome Back screen, report/block moderation
- [x] **Phase 18: Home Tab + Goals Flow Enhancements** - New Home dashboard + enhanced goal creation wizard + goal detail page (completed 2026-05-20)
- [x] **Phase 19: Tip Jar + About Page + Settings** - StoreKit 2 consumable tip jar, About page with founder bio, Settings page, notification picker (completed 2026-05-22)
- [x] **Phase 20: Explore Tab** - Shake/tap daily goal gifter, mood prompt, Vitamin Shelf, Trending Now, 3 Gifts for Stuck Days (completed 2026-05-24)
- [x] **Phase 21: Community Tab Redesign** - Today's Glimpses carousel, Active Today, Glowing This Week, community feed with reactions/replies/photos, applause system (completed 2026-05-24)
- [x] **Phase 22: Public Profile + Follow + Discover** - Public profile redesign, follow/cheer system, Discover page with goal search and people search (completed 2026-05-26)
- [x] **Phase 23: Milestone Features + Streak Freeze** - Streak freeze, achievement unlocked screens, achievement sharing, goal completed celebration (completed 2026-05-26)
- [x] **Phase 24: Widget Enhancements** - Update widgets for v2.0 data, wire WidgetCenter.reloadAllTimelines() to all new state changes (completed 2026-05-28)

### v3.0 Personal Intelligence + Apple Watch

- [x] **Phase 25: Smart Notifications Enhancement** - Tone-adaptive notifications, goal-title personalization, streak-at-risk evening alert, send-time suggestion banner
- [x] **Phase 26: Analytics Dashboard** - Completion rate trends chart (Swift Charts), all-time goal heatmap, CSV export via ShareLink (completed 2026-06-02)
- [x] **Phase 27: Apple Watch App** - accessoryRectangular complication with goal + progress ring, check-in from wrist via WCSession.transferUserInfo (completed 2026-06-05)
- [ ] **Phase 28: AI (Claude) Integration** - Cloudflare Worker proxy, goal suggestions card on Explore tab, personalized daily motivation on Home tab

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

**Plans**: 5 plans
Plans:

- [x] 17-01-PLAN.md — Auth gate: WelcomeScreen Apple-only + OnboardingStep enum expansion + LoginScreen re-auth (AUTH-01, AUTH-07)
- [x] 17-02-PLAN.md — T&C screen: TermsAndConditionsScreen + PDFPreviewView + PDF bundle (AUTH-02)
- [x] 17-03-PLAN.md — Username: UsernameLookupService + OnboardingViewModel debounce + UsernameScreen (AUTH-03)
- [x] 17-04-PLAN.md — Name pre-fill + ProfilePictureScreen + CameraPermissionScreen (AUTH-04, AUTH-05, AUTH-06)
- [x] 17-05-PLAN.md — Report/Block: BlockListService + PublicProfileView contextMenu + MFMailCompose/mailto report + UserDefaults block list (PROF-05)

**Wave 1** *(17-02 and 17-03 blocked on 17-01 completion)*
**Wave 2 *(blocked on Wave 1 completion)***
**Cross-cutting constraints:** OnboardingStep enum (17-01) is prerequisite for all downstream navigation; CloudKit Console username index must be confirmed before 17-03 runs (human checkpoint); T&C PDF must be in Xcode target before 17-02 runs (human checkpoint)
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

**Plans**: 5 plans
Plans:
**Wave 1**

- [x] 18-01-PLAN.md — Wave 0 test scaffolding (6 XCTest files; RED stubs for HOME-01/02, GOAL2-01/02/04/05)
- [x] 18-02-PLAN.md — Foundation: Goal.durationDays + GoalInput + GoalViewModel.addCheckIn + GoalCreationWizardViewModel.configure(fromPremade:) + VGQuoteBank.all (HOME-01, HOME-02, GOAL2-01, GOAL2-02, GOAL2-04)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 18-03-PLAN.md — Goal creation flow: GoalEntryChoiceView + PremadeGoalsListView + Wizard startAtStep + Step3 duration field + GoalListView +add wiring (GOAL2-01, GOAL2-02, GOAL2-03)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 18-04-PLAN.md — Home dashboard restructure: streak fix, quote bank, community goal card, Stats nav, +add hookup, flame icons, drop Daily Wins (HOME-01..06)
- [x] 18-05-PLAN.md — Goal Detail + Day Grid + Check-in Celebration: GoalDayGridView, CheckInCelebrationView, addCheckIn wiring, flame in header (GOAL2-04, GOAL2-05)

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

**Plans**: 6 plans
Plans:
**Wave 1**

- [x] 19-01-PLAN.md — Wave 0 scaffolding: ColorSchemePreference enum, 6 test files, VitaminGTips.storekit config (SET-04)

**Wave 2** *(blocked on Wave 1; 02/03/05/06 run in parallel)*

- [x] 19-02-PLAN.md — VitaminGApp foundation: .preferredColorScheme on WindowGroup, Transaction.updates listener, launch reschedule (SET-04, MON-03)
- [x] 19-03-PLAN.md — Tip jar: TipStore StoreKit 2 ViewModel + TipJarView + TipThankYouView (MON-02, MON-03, MON-04)
- [x] 19-05-PLAN.md — Rotating notification copy: NotificationScheduler.makeContent overhaul + test update (NOTIF-02)
- [x] 19-06-PLAN.md — Onboarding nudge-time step: NudgeTimePickerScreen + conditional OnboardingStep routing (NOTIF-01)

**Wave 3** *(blocked on 19-02 + 19-03)*

- [x] 19-04-PLAN.md — AboutView + SettingsView expansion: founder bio, Appearance/Privacy/Support sections (MON-01, SET-01..SET-05, NOTIF-02)

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

**Plans**: 6 plans

Plans:
**Wave 1**

- [x] 21-01-PLAN.md — Wave 0 scaffolding: CommunityHubModels value types + 4 RED test stub files (COMM-02, COMM-04, COMM-05, COMM-06, SOC-01)
- [x] 21-02-PLAN.md — CommunityService 9 new CloudKit methods + ReactionType.fire + GoalViewModel.addCheckIn injection (COMM-01–07, SOC-01–03)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 21-03-PLAN.md — CommunityHubViewModel + ApplauseButtonView + ApplauseStreamOverlay; 3 test files GREEN (COMM-02, COMM-04, COMM-05, SOC-01, SOC-02, SOC-03)
- [x] 21-04-PLAN.md — PostComposeSheet camera/confirmationDialog extension + CommunityReplySheetView; Phase21ReplyTests GREEN (COMM-06, COMM-07, SOC-01)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 21-05-PLAN.md — GlimpsesCarouselSection, ActiveTodaySection, GlowingSpotlightSection, GlobalFeedSection (COMM-02–07, SOC-01–03)
- [x] 21-06-PLAN.md — CommunityTabView rebuild + ContentView swap + CommunityPostCard 🔥 + ExploreView challenge migration + ProfileView SOC-02; human verify (COMM-01–07, SOC-01–03)

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

**Plans**: 5 plans
Plans:

- [x] 22-01-PLAN.md — Wave 0: SchemaV9 (motto + cloudKitPublicGoalRecordID), CommunityHubModels Phase 22 structs, 5 RED test files, CloudKit Console deployment (PROF-01, PROF-02, PROF-04, DISC-01, DISC-02, DISC-04)
- [x] 22-02-PLAN.md — Services: ProfileSharingService expansion (publish/fetch/follow) + new PublicGoalService (CRUD + search + increment + backfill + sync) (PROF-01, PROF-02, PROF-04, DISC-01, DISC-02, DISC-04)
- [x] 22-03-PLAN.md — ViewModels + 5 Components: PublicProfileViewModel + DiscoverViewModel + PublicGoalCard/FollowButton/CheerButton/GoalSearchResultCard/PeopleSearchResultCard (PROF-01, PROF-02, PROF-03, PROF-04, DISC-01, DISC-02, DISC-04)
- [x] 22-04-PLAN.md — Launch + check-in hooks + ProfileEditSheet motto field (D-07, D-08, D-11, D-12) (PROF-01)
- [x] 22-05-PLAN.md — Screen integration: PublicProfileView redesign + ExploreView .searchable + DiscoverOverlayView + human verify (PROF-01, PROF-02, PROF-03, PROF-04, DISC-01, DISC-02, DISC-03, DISC-04)

**Wave 1**: 22-01 (test scaffolding + SchemaV9 + CloudKit Console human checkpoint)
**Wave 2**: 22-02 (services — depends on 22-01)
**Wave 3**: 22-03 and 22-04 run in parallel (no overlapping files; both depend on 22-02)
**Wave 4**: 22-05 (UI integration + human verify — depends on 22-03 and 22-04)

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

**Plans**: 4 plans

Plans:

- [x] 23-01-PLAN.md — SchemaV10 migration + StreakFreezeService weekly ISO8601 reset + StreakMilestoneGate service (MILE-01, MILE-03, MILE-04)
- [x] 23-02-PLAN.md — StatsViewModel frozen sentinel + HeatmapView ❄️ glyph + GoalViewModel per-goal milestone detection (MILE-01, MILE-03, MILE-04)
- [x] 23-03-PLAN.md — GoalStreakMilestoneView + GoalCompletionCelebrationView + GoalDetailView/GoalListView wiring (MILE-04, MILE-06)
- [x] 23-04-PLAN.md — Global streak-at-risk notification + CommunityService achievement post + feed integration + human verify (MILE-02, MILE-05)

**UI hint**: yes

### Phase 24: Widget Enhancements

**Goal**: The home screen and lock screen widgets reflect v2.0 data (current streak and active goal progress) and stay fresh after every goal state change in the app
**Depends on**: Phase 23
**Requirements**: WID-01, WID-02
**Success Criteria** (what must be TRUE):

  1. User adds the Vitamin G home screen widget and it shows their current streak count and their active goal with a progress indicator that reflects the latest data
  2. After the user checks in on a goal, freezes a streak, or completes a goal inside the app, the widget updates to reflect the change without requiring an app relaunch

**Plans**: 3 plans
Plans:
**Wave 1**

- [x] 24-01-PLAN.md — WidgetDisplayData extension + WidgetDataProvider.build() active goal/progress + Phase24WidgetDataProviderTests.swift (WID-01)

**Wave 2** *(blocked on Wave 1 completion; 24-02 and 24-03 run in parallel)*

- [x] 24-02-PLAN.md — GoalSummaryWidgetView equal-split layout redesign + TierRowView removal + .description copy update + human visual verify (WID-01)
- [x] 24-03-PLAN.md — StatsView freeze handler reload fix + WID-02 audit grep evidence + human verify widget refresh without app relaunch (WID-02)

**UI hint**: yes

### Phase 25: Smart Notifications Enhancement

**Goal**: Users receive daily notifications that know who they are — referencing their actual goal titles, adapting tone to their streak health, alerting them in the evening only when a streak is genuinely at risk, and surfacing a nudge-time suggestion when the app detects a systematic mismatch between their check-in patterns and their current notification schedule
**Depends on**: Phase 24
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04
**Success Criteria** (what must be TRUE):

  1. User with a 10-day streak opens a morning notification and reads celebratory copy referencing one of their actual active goal titles; a user with a broken streak reads encouraging copy instead of the same generic message
  2. User who has not checked in by 7 PM and has a streak of 3 or more days receives a second notification that evening; the moment they check in via the iOS app, a widget, or the Apple Watch, that evening alert is silently cancelled and never fires
  3. User visits Settings after 14 days of consistent check-ins at a time 2+ hours earlier than their current nudge setting and sees a non-intrusive banner suggesting they shift their nudge time; tapping the banner applies the change immediately; the banner never auto-applies without a tap
  4. User with a broken or missing streak reads encouraging phrasing; user with 1–6 day streak reads neutral-building phrasing; user with 7+ day streak reads celebratory-momentum phrasing — all determined locally with no network call

**Plans**: 3 plans

Plans:
**Wave 1**

- [x] 25-01-PLAN.md — Wave 0 scaffolding: NotificationPreferences keys (checkInHourHistory, nudgeSuggestionDismissed) + helpers (appendCheckInHour, modalCheckInHour, markNudgeSuggestionDismissed) + RED test file NotificationSchedulerPhase25Tests (NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 25-02-PLAN.md — NotificationScheduler signature migration: three tone copy banks + makeContent(activeGoals:currentStreak:) + schedule/reschedule (activeGoals:completionEvents:) + scheduleOneShotStreakAtRisk with cap guard + evening-skip guard (NOTIF-01, NOTIF-02, NOTIF-04)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 25-03-PLAN.md — Cascade + UI: GoalViewModel addCheckIn hour append + dual fetch in rescheduleNotification + VitaminGApp launch reschedule update + SettingsView nudge suggestion banner + human verify (NOTIF-03, NOTIF-04)

### Phase 26: Analytics Dashboard

**Goal**: Users can explore their full goal history through a completion rate trends chart, a scrollable all-time heatmap per goal, and export everything as a CSV file — all computed from existing CompletionEvent data with no schema migration
**Depends on**: Phase 25
**Requirements**: ANLT-02, ANLT-03, ANLT-04
**Success Criteria** (what must be TRUE):

  1. User opens the Analytics view and sees a bar or line chart (Swift Charts) displaying their weekly and monthly goal completion rate across all active and completed goals; the chart renders without lag even for users with 2+ years of data
  2. User taps any goal and sees a full all-time GitHub-style heatmap from that goal's creation date to today; the heatmap scrolls horizontally without stutter for 1000+ days because it uses LazyHStack virtualization
  3. User taps Export on the Analytics view, selects a destination (Files, Mail, or any share-sheet recipient), and receives a well-formed CSV file containing every CompletionEvent — goal name, date, tier — with no truncation even for large histories

**Plans**: 3 plans

Plans:
**Wave 1**

- [x] 26-01-PLAN.md — Wave 0 test scaffolding + CSVExportService + AppRoute.analytics case (ANLT-04, ANLT-02, ANLT-03)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 26-02-PLAN.md — AnalyticsViewModel: completionRateBuckets, heatmapDataByGoal, allGoals; turns Phase26AnalyticsViewModelTests RED stubs GREEN (ANLT-02, ANLT-03)

**Wave 3** *(blocked on Waves 1+2 completion)*

- [x] 26-03-PLAN.md — Views + navigation wiring: AllTimeHeatmapView, GoalAllTimeHeatmapView, AnalyticsView, StatsView nav row, ContentView destination; human verify (ANLT-02, ANLT-03, ANLT-04)

**UI hint**: yes

### Phase 27: Apple Watch App

**Goal**: Users can glance at their active goal title and progress ring on their watch face via an accessoryRectangular complication, and check in for the day directly from their wrist with the same effect as checking in on iPhone
**Depends on**: Phase 25
**Requirements**: WATCH-02, WATCH-03
**Success Criteria** (what must be TRUE):

  1. User adds the Vitamin G accessoryRectangular complication to their watch face and sees their active goal title and a progress ring showing today's completion status; data reflects the most recent iPhone state within the WatchConnectivity session
  2. User taps the complication to open the Watch app, sees a prominent Check In button, taps it, and the check-in is relayed to the iPhone via WCSession.transferUserInfo; the iPhone's streak count updates, the home screen widget reloads, and any pending streak-at-risk evening notification is cancelled — identical to checking in from the iOS app
  3. User who has not checked in by evening does not receive a duplicate streak-at-risk alert on their Watch — the single alert scheduled on iPhone mirrors to the wrist automatically, and is cancelled by the Watch check-in through the same cancel path used by the iOS and widget check-in surfaces

**Plans**: 6 plans

- [x] 27-01-PLAN.md — Watch target scaffold: watchOS 10 target, WatchKit App Group, VGRingView, TodayGlanceView stub, complication entry point (WATCH-02)
- [x] 27-02-PLAN.md — WatchSnapshot model + WidgetDataProvider delegation + WatchSnapshotTests (WATCH-02)
- [x] 27-03-PLAN.md — WatchReceiver: processApplicationContext + @AppStorage reactive read + TodayGlanceView live data + Phase27WatchReceiverTests (WATCH-02)
- [x] 27-04-PLAN.md — iPhone pushSnapshot path: GoalViewModel.pushSnapshot + VitaminGApp foreground trigger + Phase27PushSnapshotTests (WATCH-02)
- [x] 27-05-PLAN.md — Watch check-in: WatchSessionManager.handleCheckIn + transferUserInfo + onCheckIn closure + VitaminGApp wiring + WatchSessionManagerTests (WATCH-03)
- [x] 27-06-PLAN.md — Physical device UAT: 27-UAT.md human verification (WATCH-02, WATCH-03)

### Phase 28: AI (Claude) Integration

**Goal**: Users see Claude-generated goal suggestions on the Explore tab and a personalized daily motivation message on the Home tab, both powered by a Cloudflare Worker proxy that keeps the Anthropic API key off the device and both degrade gracefully to static fallbacks when the proxy is unreachable
**Depends on**: Phase 27
**Requirements**: AI-03, AI-01, AI-02
**Success Criteria** (what must be TRUE):

  1. A Cloudflare Worker is deployed at a stable HTTPS URL; iOS can POST a request and receive a Claude response; the Anthropic API key exists only in the Worker's environment variables and is never present in the iOS binary (verified by `strings` scan of the .ipa)
  2. User opens the Explore tab and sees a "Goals suggested for you" card with 3 Claude-generated goal suggestions based on their existing goal titles and categories; tapping one adds the goal with a single tap; suggestions do not re-fetch more than once per calendar day (UserDefaults cache key by date string)
  3. User sees a personalized daily motivation message above the My Goals list on the Home tab; the message references their actual streak count and active goal titles; it was generated by Claude at most once today and falls back to a VGQuoteBank entry if the Cloudflare Worker is unreachable — the Home tab never shows an error state or empty card in place of the motivation message

**Plans**: 4 plans

Plans:
**Wave 0**

- [x] 28-01-PLAN.md — Cloudflare Worker proxy (POST /ai, token gate, prompt builder, Anthropic call, thin envelope) + Wave 0 RED test stubs + human deployment checkpoint (AI-03)

**Wave 1** *(blocked on Wave 0 completion)*

- [x] 28-02-PLAN.md — AIProxyService (singleton, @Observable, AIProxyServiceProtocol, date-key UserDefaults cache, VGQuoteBank/static fallback) + AIViewModel (@MainActor @Observable, motivationLabel, refresh methods using WidgetDataProvider.build) — turns Wave 0 tests GREEN (AI-01, AI-02)

**Wave 2** *(blocked on Wave 1)*

- [x] 28-03-PLAN.md — Home tab integration: AIMotivationSection.swift + HomeView.swift quoteSection replacement + .task fetch trigger + human verify (AI-02)

**Wave 3** *(blocked on Wave 2; sequential after 28-03 — both plans edit project.pbxproj)*

- [x] 28-04-PLAN.md — Explore tab integration: GoalSuggestionsCard.swift + ExploreView.swift insertion between Today's Gift and Daily Mood + .task fetch trigger + human verify (AI-01)

**UI hint**: yes

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
| 16. Tab Restructuring + AppRoute Updates | v2.0 | 2/2 | Complete | 2026-05-17 |
| 17. Onboarding Overhaul | v2.0 | 2/5 | In progress | - |
| 18. Home Tab + Goals Flow Enhancements | v2.0 | 5/5 | Complete   | 2026-05-20 |
| 19. Tip Jar + About Page + Settings | v2.0 | 6/6 | Complete   | 2026-05-22 |
| 20. Explore Tab | v2.0 | 0/? | Not started | - |
| 21. Community Tab Redesign | v2.0 | 6/6 | Complete   | 2026-05-24 |
| 22. Public Profile + Follow + Discover | v2.0 | 5/5 | Complete   | 2026-05-26 |
| 23. Milestone Features + Streak Freeze | v2.0 | 4/4 | Complete    | 2026-05-26 |
| 24. Widget Enhancements | v2.0 | 3/3 | Complete    | 2026-05-28 |
| 25. Smart Notifications Enhancement | v3.0 | 0/3 | Not started | - |
| 26. Analytics Dashboard | v3.0 | 3/3 | Complete   | 2026-06-02 |
| 27. Apple Watch App | v3.0 | 6/6 | Complete    | 2026-06-06 |
| 28. AI (Claude) Integration | v3.0 | 4/4 | Human verify pending | - |
