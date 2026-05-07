# Requirements: Vitamin G

**Defined:** 2026-04-03
**Core Value:** Every morning, the user is reminded of their goals — making progress feel inevitable, not accidental.

---

## v1 Requirements

### Foundation (Architecture & Data Model)

- [x] **FOUND-01**: App uses MVVM architecture — zero business logic in Views, all state in `@Observable` ViewModels
- [x] **FOUND-02**: SwiftData `Goal` model with `id` (UUID), `title` (String?), `description` (String?), `tier` (String? enum: immediate/shortTerm/longTerm/lifeGoal), `isCompleted` (Bool), `creationDate` (Date?), `associatedInspiration` (String?) — all optional for CloudKit compatibility
- [x] **FOUND-03**: `Goal` model uses `VersionedSchema` from day one — no unversioned schema ships
- [x] **FOUND-04**: `CompletionEvent` model for streak history: `id` (UUID), `goalID` (UUID), `tier` (String?), `completedAt` (Date?) — CloudKit-compatible
- [x] **FOUND-05**: App Group entitlement configured (`group.com.[BUNDLEID].vitamingapp`) so widget and main app share the same SwiftData store
- [x] **FOUND-06**: `ModelContainer` uses `groupContainer: .identifier(...)` + `cloudKitDatabase: .automatic` from Phase 1
- [x] **FOUND-07**: All String inputs validated at model layer: title max 100 chars, description max 500 chars, associatedInspiration max 300 chars — enforced before SwiftData insert

### Goal Management

- [x] **GOAL-01**: User can create a goal by entering title, description (optional), tier selection, and associatedInspiration (optional)
- [x] **GOAL-02**: User can view all goals grouped and visually distinguished by tier
- [x] **GOAL-03**: User can edit any goal field after creation
- [x] **GOAL-04**: User can delete a goal (with confirmation)
- [x] **GOAL-05**: User can mark a goal as complete — creates a `CompletionEvent` record with timestamp and tier
- [x] **GOAL-06**: Completed goals remain visible (with visual distinction) and can be re-activated
- [x] **GOAL-07**: Goal list is sortable by tier, by creation date, and by completion status

### Streaks & Statistics

- [x] **STATS-01**: App tracks a streak per tier — consecutive days with at least one completion event in that tier
- [x] **STATS-02**: App tracks a global streak — consecutive days with at least one completion event in any tier (motivational fallback)
- [x] **STATS-03**: Streak computation uses `Calendar.current` date arithmetic, not raw `TimeInterval` — DST-safe
- [x] **STATS-04**: Stats screen shows: current streak per tier, global streak, completion rate per tier, total goals per tier
- [x] **STATS-05**: Stats screen shows a calendar/heatmap view — GitHub-style grid of completion activity
- [x] **STATS-06**: All streak and stats computations are derived from `CompletionEvent` records, not `isCompleted` boolean

### Notifications

- [ ] **NOTIF-01**: App requests notification permission during onboarding (not on cold launch without context)
- [x] **NOTIF-02**: Daily morning notification fires at user-selected time (default: 8:00 AM)
- [x] **NOTIF-03**: Notification body surfaces the user's active goal titles (up to top 3) — not a generic message
- [x] **NOTIF-04**: Notification scheduling uses `UNCalendarNotificationTrigger` with `repeats: true` — no background fetch required
- [x] **NOTIF-05**: Notification rotation stays within iOS 64-request limit — scheduling logic caps pre-scheduled notifications
- [x] **NOTIF-06**: User can change notification time in Settings — reschedules existing notifications
- [x] **NOTIF-07**: Tapping notification deep-links to the goal list

### iCloud Sync

- [ ] **SYNC-01**: All `Goal` and `CompletionEvent` data syncs across user's devices via CloudKit private database
- [ ] **SYNC-02**: Sync works transparently — no manual sync button in v1
- [x] **SYNC-03**: CloudKit schema promoted to Production before App Store submission (deployment task)

### Widgets

- [ ] **WIDGET-01**: Home screen widget (`systemMedium`) shows top active goals across tiers
- [ ] **WIDGET-02**: Lock screen widget (`accessoryRectangular`) shows current global streak or top active goal title
- [ ] **WIDGET-03**: Widget reads from shared App Group SwiftData store — same data as main app
- [ ] **WIDGET-04**: Widgets are read-only in v1 — no write operations from widget context
- [ ] **WIDGET-05**: Widget timeline refreshes at least once daily (aligns with morning notification)

### Onboarding

- [ ] **ONBOARD-01**: First-launch onboarding explains the 4 tiers with warm, gratitude-framing copy
- [ ] **ONBOARD-02**: Onboarding guides user to create their first goal before reaching the main view
- [ ] **ONBOARD-03**: Notification permission request occurs during onboarding with clear value framing
- [ ] **ONBOARD-04**: Empty states for each tier include actionable prompts to add a first goal

### UI & Design

- [x] **UI-01**: Each tier has a distinct visual identity (color, icon, weight) — not just a label
- [x] **UI-02**: App tone is warm and reflective, not productivity-aggressive — copy and design enforce this
- [x] **UI-03**: `associatedInspiration` field is prominently displayed on goal detail view
- [ ] **UI-04**: App Store-quality polish: no placeholder UI, no debug elements, smooth transitions
- [x] **UI-05**: Supports both Light and Dark Mode
- [x] **UI-06**: Accessibility: Dynamic Type support, VoiceOver labels on all interactive elements

### User Profiles

- [x] **PROF-01**: SchemaV2 migration adds `UserProfile` model and `Goal.isPublic` field without data loss on existing records
- [x] **PROF-02**: Profile tab (4th tab) shows avatar, display name, privacy toggle, public goals preview, and share button
- [x] **PROF-03**: Toggling profile to Public saves a `PublicProfile` record to CloudKit public database
- [x] **PROF-04**: Toggling profile to Private deletes the `PublicProfile` record from CloudKit public database
- [x] **PROF-05**: Share Profile button generates a `vitaming://profile/<recordID>` deep link and presents system share sheet
- [ ] **PROF-06**: App handles incoming `vitaming://profile/<recordID>` deep links via `.onOpenURL` handler in `VitaminGApp`
- [ ] **PROF-07**: Programmatic navigation to a specific profile via deep link resolves and navigates correctly
- [x] **PROF-08**: GoalDetailView has a "Share this goal" toggle that persists `isPublic` on the `Goal` model
- [x] **PROF-09**: `AvatarView` renders warm-colored initials avatar; supports photo fallback when `photoData` is available
- [x] **PROF-10**: CloudKit public database stores and retrieves `PublicProfile` records correctly

### Challenge Platform — Core Engine

- [x] **CHAL-01**: `ChallengeTemplate` SwiftData model (SchemaV3) defines all challenge behavior via config: id, title, description, category, type (featured/custom), check_in_type (boolean/numeric/photo/multi-step), goal_type (streak/target/date-bound), duration, milestones array, accent color, icon, featured flag + active date range
- [x] **CHAL-02**: `UserChallenge` model links a user to a template with start date, target end date, current streak, longest streak, total check-ins, status (active/completed/abandoned), and milestone history
- [x] **CHAL-03**: `CheckIn` model stores challenge instance ID, date, type-specific payload (boolean/number/note/photo), and timestamp — one check-in per day per challenge enforced
- [x] **CHAL-04**: SchemaV3 migration adds ChallengeTemplate, UserChallenge, CheckIn without data loss on existing SchemaV2 records
- [x] **CHAL-05**: Challenge engine computes streak correctly across midnight and DST transitions; missed check-in breaks streak; longest streak tracked
- [x] **CHAL-06**: Three featured challenges seeded via template system: 90-Day Summer Body (fitness/multi-step), Save $5,000 (finance/numeric), Dry Summer (sobriety/boolean) — no hardcoded type-specific logic
- [x] **CHAL-07**: Adding a new challenge type requires zero new core engine logic — all behavior driven by template config
- [x] **CHAL-08**: Discovery screen shows Featured Challenges (curated cards with category, community size), category browse, and "Build Your Own" CTA
- [x] **CHAL-09**: Daily check-in flow adapts to check_in_type from template (boolean/numeric/multi-step) with no type-specific branching in engine layer
- [x] **CHAL-10**: Milestone array from template triggers full-screen celebration (confetti + personalized message + milestone badge saved to profile) at each configured trigger point
- [x] **CHAL-11**: Progress tracking: streak calendar chain view, progress bar toward goal value, prominent day counter for sobriety-type challenges
- [x] **CHAL-12**: Evening check-in reminder notification fires per-challenge at user-set time if no check-in logged that day

### Challenge Platform — Community & Modules

- [ ] **CHAL-13**: Community feed scoped per challenge category — posts (text + optional photo) visible only within the same category
- [ ] **CHAL-14**: Post reactions: 👍 and ❤️ only — no comments, no other reaction types; reaction counts visible on post
- [ ] **CHAL-15**: Report button present on every post; report count never shown publicly
- [ ] **CHAL-16**: Profanity filter runs on post submission — rejects and prompts user to edit; never silently drops content
- [ ] **CHAL-17**: Community posts and reactions persist in CloudKit public database
- [ ] **CHAL-18**: Spending Freeze module — daily self-reported toggle, freeze badge on dashboard, daily reminder while active
- [ ] **CHAL-19**: Craving Tools module — box breathing exercise (4-4-4-4 pattern), random motivational distraction prompt, buddy ping button
- [ ] **CHAL-20**: Transformation Photos module — private dated photo log visible only to the user
- [ ] **CHAL-21**: Nutrition Log module — simple daily meal note field per challenge
- [ ] **CHAL-22**: Buddy Accountability module — user opts in a contact; buddy receives push ping on request
- [ ] **CHAL-23**: Custom Challenge builder lets users configure name, category, check-in type, goal type/value, duration, and privacy — produces a ChallengeTemplate using identical infrastructure as featured challenges
- [ ] **CHAL-24**: Notification suite: streak-at-risk (no check-in by 8pm), milestone reached, reaction received on post, buddy accountability ping
- [ ] **CHAL-25**: Warm, encouraging empty state on community feed when sparse ("Be the first to share your progress"); no red failure states throughout challenge UI

### Gratitude / Daily Wins

- [ ] **GRAT-01**: User can create a daily win or gratitude entry — free-text, date-keyed, one entry per calendar day
- [ ] **GRAT-02**: `DailyWin` SwiftData model persists entries with `id` (UUID), `date` (Date?), `text` (String?) — CloudKit-compatible (all optional)
- [ ] **GRAT-03**: A dedicated Daily Wins surface shows today's entry editor and a scrollable history of past entries with their dates
- [ ] **GRAT-04**: If today's entry already exists, opening the Daily Wins view pre-fills the editor — no duplicate entries per day
- [ ] **GRAT-05**: A "What's your win today?" notification variant fires at a user-configurable time, distinct from the goal-reminder notification
- [ ] **GRAT-06**: Daily Wins is accessible from a prominent surface (dedicated tab or home screen shortcut) within the app

### Goal Progress Visualization

- [ ] **PROG-01**: Each goal card displays a progress ring or activity bar derived from `CompletionEvent` records — fills proportionally to recent completion frequency
- [ ] **PROG-02**: GoalDetailView shows per-goal history: total completion count, last completed date, and a mini activity indicator
- [ ] **PROG-03**: Micro-milestone celebrations (confetti or animated badge) fire when a goal's cumulative completion count reaches thresholds: 5, 10, 25, 50
- [ ] **PROG-04**: A momentum score (completions in last 7 days ÷ 7, clamped 0–1) is computed per goal and shown in GoalDetailView with a color indicator
- [ ] **PROG-05**: All progress and momentum computations derive from existing `CompletionEvent` records — no new model required

---

## v2 Requirements

### Widgets (Enhanced)
- Interactive widget buttons (App Intents) to mark goals complete from home screen
- Apple Watch app (accessory complications)

### Stats (Enhanced)
- Full analytics dashboard with historical charts
- CSV/PDF export of goal history

### Content
- `associatedInspiration` supports image/photo attachment
- Goal template library (pre-built goals by tier)

### Social
- Optional goal sharing (requires backend + privacy policy)
- Friend accountability features

### AI
- AI-powered goal suggestions based on existing goals
- Smart notification content personalization

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Social / sharing | Requires backend, auth, moderation — single-user app for v1 |
| AI-generated insights | Third-party API dependency — out per PROJECT.md constraints |
| Vision board / image collage | Complex media pipeline, CloudKit size limits |
| Goal templates library | Content project, not engineering |
| Apple Watch app | High effort; lock screen widget covers glanceable use case |
| Recurring / habit goals | Different product primitive from aspirational goal tracking |
| Web dashboard | iOS-native only |
| Markdown / rich text | Increases validation complexity; plain text is safer |
| Gamification | Not aligned with reflective tone |
| In-app calendar integration | Morning push notification covers reminder use case |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | Phase 1 | Complete |
| FOUND-02 | Phase 1 | Complete |
| FOUND-03 | Phase 1 | Complete |
| FOUND-04 | Phase 1 | Complete |
| FOUND-05 | Phase 1 | Complete |
| FOUND-06 | Phase 1 | Complete |
| FOUND-07 | Phase 1 | Complete |
| GOAL-01 | Phase 2 | Complete |
| GOAL-02 | Phase 2 | Complete |
| GOAL-03 | Phase 2 | Complete |
| GOAL-04 | Phase 2 | Complete |
| GOAL-05 | Phase 2 | Complete |
| GOAL-06 | Phase 2 | Complete |
| GOAL-07 | Phase 2 | Complete |
| UI-01 | Phase 2 | Complete |
| UI-02 | Phase 2 | Complete |
| UI-03 | Phase 2 | Complete |
| STATS-01 | Phase 3 | Complete |
| STATS-02 | Phase 3 | Complete |
| STATS-03 | Phase 3 | Complete |
| STATS-04 | Phase 3 | Complete |
| STATS-05 | Phase 3 | Complete |
| STATS-06 | Phase 3 | Complete |
| NOTIF-02 | Phase 3 | Complete |
| NOTIF-03 | Phase 3 | Complete |
| NOTIF-04 | Phase 3 | Complete |
| NOTIF-05 | Phase 3 | Complete |
| NOTIF-06 | Phase 3 | Complete |
| NOTIF-07 | Phase 3 | Complete |
| SYNC-01 | Phase 4 | Pending |
| SYNC-02 | Phase 4 | Pending |
| WIDGET-01 | Phase 4 | Pending |
| WIDGET-02 | Phase 4 | Pending |
| WIDGET-03 | Phase 4 | Pending |
| WIDGET-04 | Phase 4 | Pending |
| WIDGET-05 | Phase 4 | Pending |
| NOTIF-01 | Phase 5 | Pending |
| ONBOARD-01 | Phase 5 | Pending |
| ONBOARD-02 | Phase 5 | Pending |
| ONBOARD-03 | Phase 5 | Pending |
| ONBOARD-04 | Phase 5 | Pending |
| UI-04 | Phase 5 | Pending |
| UI-05 | Phase 9 | Complete |
| UI-06 | Phase 9 | Complete |
| SYNC-03 | Phase 6 | Complete |
| PROF-01 | Phase 7 | Complete |
| PROF-02 | Phase 7 | Complete |
| PROF-03 | Phase 7 | Complete |
| PROF-04 | Phase 7 | Complete |
| PROF-05 | Phase 7 | Complete |
| PROF-06 | Phase 10 | Pending |
| PROF-07 | Phase 10 | Pending |
| PROF-08 | Phase 7 | Complete |
| PROF-09 | Phase 7 | Complete |
| PROF-10 | Phase 7 | Complete |
| CHAL-01 | Phase 13 | Complete |
| CHAL-02 | Phase 13 | Complete |
| CHAL-03 | Phase 13 | Complete |
| CHAL-04 | Phase 13 | Complete |
| CHAL-05 | Phase 13 | Complete |
| CHAL-06 | Phase 13 | Complete |
| CHAL-07 | Phase 13 | Complete |
| CHAL-08 | Phase 13 | Complete |
| CHAL-09 | Phase 13 | Complete |
| CHAL-10 | Phase 13 | Complete |
| CHAL-11 | Phase 13 | Complete |
| CHAL-12 | Phase 13 | Complete |
| CHAL-13 | Phase 14 | Pending |
| CHAL-14 | Phase 14 | Pending |
| CHAL-15 | Phase 14 | Pending |
| CHAL-16 | Phase 14 | Pending |
| CHAL-17 | Phase 14 | Pending |
| CHAL-18 | Phase 14 | Pending |
| CHAL-19 | Phase 14 | Pending |
| CHAL-20 | Phase 14 | Pending |
| CHAL-21 | Phase 14 | Pending |
| CHAL-22 | Phase 14 | Pending |
| CHAL-23 | Phase 14 | Pending |
| CHAL-24 | Phase 14 | Pending |
| CHAL-25 | Phase 14 | Pending |
| GRAT-01 | Phase 11 | Pending |
| GRAT-02 | Phase 11 | Pending |
| GRAT-03 | Phase 11 | Pending |
| GRAT-04 | Phase 11 | Pending |
| GRAT-05 | Phase 11 | Pending |
| GRAT-06 | Phase 11 | Pending |
| PROG-01 | Phase 12 | Pending |
| PROG-02 | Phase 12 | Pending |
| PROG-03 | Phase 12 | Pending |
| PROG-04 | Phase 12 | Pending |
| PROG-05 | Phase 12 | Pending |

**Coverage:**
- v1 requirements: 91 total (66 previous + 25 challenge platform requirements added 2026-05-01)
- Mapped to phases: 66
- Unmapped: 0

---
*Requirements defined: 2026-04-03*
*Last updated: 2026-05-01 — GRAT-01–06 (Phase 11) and PROG-01–05 (Phase 12) added for new feature phases*
