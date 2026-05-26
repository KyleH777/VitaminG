# Requirements: Vitamin G v2.0 Social Growth Engine

**Defined:** 2026-05-16
**Core Value:** Every morning, the user is reminded of their goals — making progress feel inevitable, not accidental.
**Milestone goal:** Transform Vitamin G from a personal goal tracker into a social growth platform.

---

## v2.0 Requirements

### Tab Restructuring (TAB)

- [ ] **TAB-01**: Tab bar restructured to 5 tabs: Home · Goals · Explore · Community · Profile (replaces Goals · Stats · Wins · Challenges · Profile)
- [ ] **TAB-02**: Stats view accessible from Home tab as a NavigationLink destination (not removed — demoted from tab)
- [ ] **TAB-03**: Daily Wins (Gratitude) view accessible from Home tab as a NavigationLink destination (not removed — demoted from tab)
- [ ] **TAB-04**: `Tab` enum with stable string raw values replaces raw integer tab selection throughout app, deep links, and widget intents — prevents routing breakage when indices shift

### Authentication & Onboarding Overhaul (AUTH)

- [ ] **AUTH-01**: Sign-in flow supports Apple Sign-In only — Google Sign-In removed entirely
- [x] **AUTH-02**: Terms & Conditions PDF (Vitamin_G_Terms_and_Conditions.pdf) is linked and readable inline during onboarding; user must acknowledge before completing sign-up
- [x] **AUTH-03**: User claims a unique username during onboarding — uniqueness enforced via async CKQuery before write; race condition handled with first-write-wins and post-save verification prompt if displaced
- [ ] **AUTH-04**: User can upload a profile picture during onboarding (PHPickerViewController for library, UIImagePickerController for camera); step is skippable; image compressed to ≤512px / JPEG 0.75 before upload
- [ ] **AUTH-05**: Notification permission priming slide shown before system alert — headline "Stay on track every day", body explains single daily reminder, primary "Turn on notifications" button, "Maybe later" secondary link
- [ ] **AUTH-06**: Camera access permission priming slide shown in onboarding — headline "Share your journey", body explains profile picture and goal photos use
- [ ] **AUTH-07**: "Welcome Back" screen shown to returning users who are not signed in — "Good to see you" message and Sign in with Apple button

### Home Tab (HOME)

- [ ] **HOME-01**: Home tab shows user's display name and current streak count prominently at top of screen
- [ ] **HOME-02**: Quote of the day displayed on Home tab — rotates daily from the existing Vitamin G quote bank
- [ ] **HOME-03**: Primary community-set goal displayed on Home tab with title and a progress bar showing completion percentage
- [ ] **HOME-04**: "My Goals" section on Home with "+add" inline; shows each goal's progress ring and days remaining
- [ ] **HOME-05**: Stats view accessible from Home tab (tappable element — replaces Stats tab from v1.0)
- [ ] **HOME-06**: Daily Wins (Gratitude) view accessible from Home tab (tappable element — replaces Wins tab from v1.0)

### Goals Flow Enhancements (GOAL2)

- [ ] **GOAL2-01**: Create goal wizard follows three steps: "What kind of goal?" → "Say it out loud" (write the goal) → "How often?" (duration, start date, reminder time, public/private toggle, "Start your journey" submit)
- [ ] **GOAL2-02**: "Need ideas" path within goal creation navigates to pre-made goals list screen ("My goals, your journey starts here…") where user can select and add a pre-made goal
- [ ] **GOAL2-03**: "Already have a goal" path opens a blank goal landing page where user fills in their existing goal
- [ ] **GOAL2-04**: Checking off a goal shows a checkmark celebration page with the user's streak count and a "Back to Goals" navigation action
- [ ] **GOAL2-05**: Goal detail page shows a grid of daily checkmarks (completed days) and blank slots (remaining days), a "Check in for today" action with streak count, and a flame icon displayed on goals where the user has checked in on 3+ consecutive days

### Explore Tab (EXPLORE)

- [ ] **EXPLORE-01**: Explore tab has a "Shake out some growth" affordance — device shake OR visible "Surprise me" tap button gifts a single random daily goal; confetti animation plays on activation (tap fallback is mandatory for accessibility)
- [ ] **EXPLORE-02**: Daily goal gifter is gated to one activation per calendar day; an accomplished counter is shown in the top-right of the Explore tab incrementing as the user completes gifted goals
- [ ] **EXPLORE-03**: "How are you feeling?" prompt appears on Explore tab once per calendar day; selecting a mood option collapses the card with a checkmark; does not re-appear until the next day
- [ ] **EXPLORE-04**: Vitamin Shelf shows 6 category cards (Body, Mind, Wellness, Money, Connection, Creative) as a tappable grid; tapping a category navigates to a filtered list of goals in that category
- [ ] **EXPLORE-05**: "Trending Now" section shows 3–5 most active community goals and the newest community goal; each card shows a progress circle with community completion % toward 100%
- [ ] **EXPLORE-06**: "3 Gifts for Stuck Days" shows 3 curated easy-win goals seeded by day-of-year (same 3 gifts for all users on a given day); tapping "Add" adds the goal to the user's goal list and hides that card from Explore for the rest of the day

### Community Tab Redesign (COMM)

- [x] **COMM-01**: Community goal landing page shows a large progress circle with completion % in the center, count of people participating, days remaining, and percentage remaining to complete
- [x] **COMM-02**: "Today's Glimpses" carousel shows cycling community member goal cards (auto-advance every 5 seconds); each card shows avatar, username, goal title, progress %, and optional photo; pauses auto-advance on manual swipe
- [x] **COMM-03**: Tapping a Today's Glimpses card opens that user's public goal page — shows their goal details, comments, and photos
- [x] **COMM-04**: "Active Today" section shows users who were active in the last 2 hours (single `lastActive` write at app open — not a live heartbeat); tapping a user opens their profile
- [x] **COMM-05**: "Glowing This Week" spotlight shows one featured user per week (deterministic weekly selection; consistent across all clients via `weekOfYear % eligibleCount`); viewer can applaud them
- [x] **COMM-06**: Community feed shows active users at top, then most liked today, then most recent, then a random community goal comment; user can scroll, react (❤️🔥👍), or reply
- [x] **COMM-07**: Community posts support photo attachment — user can add a photo from library or camera when creating a post; photos stored as CKAsset in CloudKit public DB

### Applause System (SOC)

- [x] **SOC-01**: User can give 👏 applause to another user — limited to once per day per recipient; applause emoji animates floating upward with the giver's username label beneath it in SwiftUI
- [x] **SOC-02**: Profile owner sees an ambient stream of floating username+👏 pairs on their own profile view for recent received applause; applause giver's username also appears on the goal they applauded
- [x] **SOC-03**: "Cheers given" counter displayed on the user's public profile card (how many applause they have sent)

### Public Profile (PROF)

- [x] **PROF-01**: Public profile view ("Jordan Kim" style) shows avatar, motto/bio, streak length, goal count, and cheers given count
- [x] **PROF-02**: User can follow another user's public profile (one-time action; stored as a `Follow` record in CloudKit public DB; community feed remains global in v2.0)
- [x] **PROF-03**: "Cheer them on today" button on public profile sends applause (SOC-01); button is disabled after daily limit is reached with appropriate visual feedback
- [x] **PROF-04**: Public profile shows the user's public goals with progress rings displaying progress toward 100%
- [ ] **PROF-05**: Every public profile shows a Report and Block action (content moderation required by App Store Guideline 1.2 to ship alongside profile photos); in-app support contact accessible from profile

### Milestone Features (MILE)

- [ ] **MILE-01**: "Life happened." streak freeze page shown with snowflake ❄️ — available once per week (ISO8601 Monday reset); activating it nullifies the missed day so the streak count is preserved
- [ ] **MILE-02**: "Streak at risk" notification and/or in-app nudge surfaces at 7 PM local time if user has not checked in today and has a freeze available that week
- [ ] **MILE-03**: Frozen days are displayed as ❄️ glyphs in the streak calendar/heatmap view (existing heatmap from v1.0 Phase 3)
- [ ] **MILE-04**: Achievement unlocked full-screen appears at streak milestones: 7, 14, 30, 60, 90, 365 days — fire emoji, confetti burst, milestone label, "Share to Community" CTA, and "Continue" button returning to Home; each milestone shown only once (persisted to prevent re-showing)
- [ ] **MILE-05**: Shared achievements scroll in the Community main page feed alongside regular posts
- [ ] **MILE-06**: "You did it" goal completed page shown when a goal reaches full completion — animated checkmark, goal title, goal-specific streak count, confetti, "Share" (ShareLink) and "Back to Goals" CTAs

### Discover Page (DISC)

- [x] **DISC-01**: Discover page has a search bar that queries public goals by keyword (case-insensitive substring match, debounced 500ms); results show goal card with creator username, category, participant count, and progress circle
- [x] **DISC-02**: Discover search supports a "People" segment that queries user profiles by username (case-insensitive prefix match); results show profile cards with Follow button
- [x] **DISC-03**: Trending Challenges section displayed on Discover when search is empty — reuses existing ChallengeDiscoveryView components from v1.0 Phase 15
- [x] **DISC-04**: User can join a public goal from Discover results — "Join" adds the goal to the user's local goal list and increments the public goal's participant count

### Notification Enhancements (NOTIF)

- [ ] **NOTIF-01**: "Pick your daily nudge time" landing page shown in onboarding (after notification permission slide) with 5 quick-select time chips (6 AM, 7 AM, 8 AM, 9 AM, 10 AM) and a "Custom time" DatePicker option; "Skip for now" secondary link
- [ ] **NOTIF-02**: Notification time picker accessible from Settings page to change the daily nudge time at any point

### Monetization — Tip Jar (MON)

- [ ] **MON-01**: About page shows "Vitamin G" app name, current app version, and the founder's bio (cancer recovery and goal-setting story — exact text preserved as provided); content is scrollable
- [ ] **MON-02**: Tip jar accessible from About page via a prominent button; displays 3 consumable IAP tiers: Small Coffee (~$0.99), Large Coffee (~$2.99), Supporter (~$4.99) with StoreKit 2 `product.displayPrice`
- [ ] **MON-03**: Tip jar uses StoreKit 2 consumable IAPs exclusively — no external payment links anywhere in the app (App Store Guideline 3.1.1 compliance)
- [ ] **MON-04**: Post-purchase animated thank-you confirmation displayed ("Thank you! You're the best.") with no feature gates behind tips

### Settings Page (SET)

- [ ] **SET-01**: Settings page accessible from Profile tab
- [ ] **SET-02**: Settings shows and allows editing of the daily nudge notification time (calls existing v1.0 notification scheduling logic)
- [ ] **SET-03**: Settings shows a public/private profile toggle (existing SchemaV8 privacy field)
- [ ] **SET-04**: Settings shows a dark mode selector: System / Light / Dark (stored in `@AppStorage`, applied at `WindowGroup` root via `.preferredColorScheme()`)
- [ ] **SET-05**: Settings includes a "Contact Support" link (email or in-app form)

### Widget Enhancements (WID)

- [ ] **WID-01**: Existing home screen widget (systemMedium) and lock screen widget (accessoryRectangular) updated to reflect v2.0 Home tab data (streak count, active goal with progress)
- [ ] **WID-02**: `WidgetCenter.shared.reloadAllTimelines()` called on all new v2.0 goal state changes (daily check-in, freeze used, goal completed)

---

## Future Requirements (v3.0+)

- Follow-based community feed filtering (deferred — N+1 CloudKit query problem; global feed in v2.0)
- Apple Watch app with accessory complications
- Full analytics dashboard with historical charts and CSV export
- AI-powered goal suggestions based on existing goals
- Smart notification content personalization
- Photo posts with filters or markup

---

## Out of Scope (v2.0)

| Feature | Reason |
|---------|--------|
| Android / cross-platform | iOS-native only — SwiftData/CloudKit ecosystem |
| Web dashboard | Native iOS is the experience |
| Real-time "live users" heartbeat (30s interval) | CloudKit write quota exhaustion at scale; battery drain; privacy disclosure complexity — scoped to "Active Today" instead |
| Follow-filtered community feed | N+1 CloudKit query problem; empty state for new users; deferred to v3.0 |
| External payment / "Buy Me a Coffee" links | App Store Guideline 3.1.1 rejection; all tips through StoreKit IAP only |
| RevenueCat or other IAP SDKs | Third-party dependency; StoreKit 2 covers all requirements natively |
| Server-side presence backend | Out of scope; adds infra cost; CloudKit heartbeat pattern is sufficient |
| Full-text search in Discover | Requires external service (Algolia etc.); substring matching sufficient for MVP |
| Recurring / habit goals | Different product primitive |
| Markdown / rich text in goals | Increases validation complexity |

---

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| TAB-01 | Phase 16 | Pending |
| TAB-02 | Phase 16 | Pending |
| TAB-03 | Phase 16 | Pending |
| TAB-04 | Phase 16 | Pending |
| AUTH-01 | Phase 17 | Pending |
| AUTH-02 | Phase 17 | Complete — 17-02 |
| AUTH-03 | Phase 17 | Pending |
| AUTH-04 | Phase 17 | Pending |
| AUTH-05 | Phase 17 | Pending |
| AUTH-06 | Phase 17 | Pending |
| AUTH-07 | Phase 17 | Pending |
| PROF-05 | Phase 17 | Pending |
| HOME-01 | Phase 18 | Pending |
| HOME-02 | Phase 18 | Pending |
| HOME-03 | Phase 18 | Pending |
| HOME-04 | Phase 18 | Pending |
| HOME-05 | Phase 18 | Pending |
| HOME-06 | Phase 18 | Pending |
| GOAL2-01 | Phase 18 | Pending |
| GOAL2-02 | Phase 18 | Pending |
| GOAL2-03 | Phase 18 | Pending |
| GOAL2-04 | Phase 18 | Pending |
| GOAL2-05 | Phase 18 | Pending |
| MON-01 | Phase 19 | Pending |
| MON-02 | Phase 19 | Pending |
| MON-03 | Phase 19 | Pending |
| MON-04 | Phase 19 | Pending |
| SET-01 | Phase 19 | Pending |
| SET-02 | Phase 19 | Pending |
| SET-03 | Phase 19 | Pending |
| SET-04 | Phase 19 | Pending |
| SET-05 | Phase 19 | Pending |
| NOTIF-01 | Phase 19 | Pending |
| NOTIF-02 | Phase 19 | Pending |
| EXPLORE-01 | Phase 20 | Pending |
| EXPLORE-02 | Phase 20 | Pending |
| EXPLORE-03 | Phase 20 | Pending |
| EXPLORE-04 | Phase 20 | Pending |
| EXPLORE-05 | Phase 20 | Pending |
| EXPLORE-06 | Phase 20 | Pending |
| COMM-01 | Phase 21 | Complete |
| COMM-02 | Phase 21 | Complete |
| COMM-03 | Phase 21 | Complete |
| COMM-04 | Phase 21 | Complete |
| COMM-05 | Phase 21 | Complete |
| COMM-06 | Phase 21 | Complete |
| COMM-07 | Phase 21 | Complete |
| SOC-01 | Phase 21 | Complete |
| SOC-02 | Phase 21 | Complete |
| SOC-03 | Phase 21 | Complete |
| PROF-01 | Phase 22 | Complete |
| PROF-02 | Phase 22 | Complete |
| PROF-03 | Phase 22 | Complete |
| PROF-04 | Phase 22 | Complete |
| DISC-01 | Phase 22 | Complete |
| DISC-02 | Phase 22 | Complete |
| DISC-03 | Phase 22 | Complete |
| DISC-04 | Phase 22 | Complete |
| MILE-01 | Phase 23 | Pending |
| MILE-02 | Phase 23 | Pending |
| MILE-03 | Phase 23 | Pending |
| MILE-04 | Phase 23 | Pending |
| MILE-05 | Phase 23 | Pending |
| MILE-06 | Phase 23 | Pending |
| WID-01 | Phase 24 | Pending |
| WID-02 | Phase 24 | Pending |
