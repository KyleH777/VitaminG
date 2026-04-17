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

- [ ] **GOAL-01**: User can create a goal by entering title, description (optional), tier selection, and associatedInspiration (optional)
- [ ] **GOAL-02**: User can view all goals grouped and visually distinguished by tier
- [ ] **GOAL-03**: User can edit any goal field after creation
- [ ] **GOAL-04**: User can delete a goal (with confirmation)
- [ ] **GOAL-05**: User can mark a goal as complete — creates a `CompletionEvent` record with timestamp and tier
- [ ] **GOAL-06**: Completed goals remain visible (with visual distinction) and can be re-activated
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
- [ ] **SYNC-03**: CloudKit schema promoted to Production before App Store submission (deployment task)

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

- [ ] **UI-01**: Each tier has a distinct visual identity (color, icon, weight) — not just a label
- [x] **UI-02**: App tone is warm and reflective, not productivity-aggressive — copy and design enforce this
- [ ] **UI-03**: `associatedInspiration` field is prominently displayed on goal detail view
- [ ] **UI-04**: App Store-quality polish: no placeholder UI, no debug elements, smooth transitions
- [ ] **UI-05**: Supports both Light and Dark Mode
- [ ] **UI-06**: Accessibility: Dynamic Type support, VoiceOver labels on all interactive elements

### User Profiles

- [ ] **PROF-01**: SchemaV2 migration adds `UserProfile` model and `Goal.isPublic` field without data loss on existing records
- [ ] **PROF-02**: Profile tab (4th tab) shows avatar, display name, privacy toggle, public goals preview, and share button
- [ ] **PROF-03**: Toggling profile to Public saves a `PublicProfile` record to CloudKit public database
- [ ] **PROF-04**: Toggling profile to Private deletes the `PublicProfile` record from CloudKit public database
- [ ] **PROF-05**: Share Profile button generates a `vitaming://profile/<recordID>` deep link and presents system share sheet
- [ ] **PROF-06**: App handles incoming `vitaming://profile/<recordID>` deep links via `.onOpenURL` handler in `VitaminGApp`
- [ ] **PROF-07**: Programmatic navigation to a specific profile via deep link resolves and navigates correctly
- [ ] **PROF-08**: GoalDetailView has a "Share this goal" toggle that persists `isPublic` on the `Goal` model
- [ ] **PROF-09**: `AvatarView` renders warm-colored initials avatar; supports photo fallback when `photoData` is available
- [ ] **PROF-10**: CloudKit public database stores and retrieves `PublicProfile` records correctly

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
| GOAL-01 | Phase 2 | Pending |
| GOAL-02 | Phase 2 | Pending |
| GOAL-03 | Phase 2 | Pending |
| GOAL-04 | Phase 2 | Pending |
| GOAL-05 | Phase 2 | Pending |
| GOAL-06 | Phase 2 | Pending |
| GOAL-07 | Phase 2 | Complete |
| UI-01 | Phase 2 | Pending |
| UI-02 | Phase 2 | Complete |
| UI-03 | Phase 2 | Pending |
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
| UI-05 | Phase 5 | Pending |
| UI-06 | Phase 5 | Pending |
| SYNC-03 | Phase 6 | Pending |
| PROF-01 | Phase 7 | Pending |
| PROF-02 | Phase 7 | Pending |
| PROF-03 | Phase 7 | Pending |
| PROF-04 | Phase 7 | Pending |
| PROF-05 | Phase 7 | Pending |
| PROF-06 | Phase 10 | Pending |
| PROF-07 | Phase 10 | Pending |
| PROF-08 | Phase 7 | Pending |
| PROF-09 | Phase 7 | Pending |
| PROF-10 | Phase 7 | Pending |

**Coverage:**
- v1 requirements: 55 total (45 original + 10 user profile requirements added 2026-04-17)
- Mapped to phases: 55
- Unmapped: 0

---
*Requirements defined: 2026-04-03*
*Last updated: 2026-04-03 — traceability updated after roadmap creation (6 phases)*
