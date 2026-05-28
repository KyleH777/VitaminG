# Feature Landscape — Vitamin G v2.0 Social Growth Engine

**Domain:** iOS social goal/habit tracking app
**Researched:** 2026-05-15 (v2.0 update — appended below v1.0 research)
**Confidence:** MEDIUM-HIGH (competitive landscape well-documented; social feature patterns verified against Duolingo, Strava, Habitica, BeReal, and Apple HIG)

---

## v1.0 Feature Landscape (Reference — Do Not Re-Research)

*(Original v1.0 research retained below for roadmap continuity)*

### Table Stakes (v1.0 — Already Built)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Goal creation with title + description | Core function; no goal tracking without it | Low | Built — Phase 2 |
| Tiered / categorized goals | Users need to separate urgent tasks from life vision | Low-Med | Built — 4-tier hierarchy, Phase 2 |
| Goal completion (check-off) | Basic task completion feedback | Low | Built — Phase 2 |
| Streak tracking | Industry standard; every major competitor has it | Med | Built — CompletionEvent, Phase 3 |
| Progress statistics / completion rate | Charts, success rate, days active | Med | Built — Stats screen, Phase 3 |
| Push notifications — daily morning reminder | Core value proposition | Med | Built — UNCalendarNotificationTrigger, Phase 3 |
| iCloud sync across devices | Cross-device sync is a baseline expectation | Med | Built — CloudKit, Phase 4 |
| Home screen widget | Goal summary visible without opening app | Med | Built — Phase 4 |
| Lock screen widget | Quick glance at today's primary goal / streak | Med | Built — Phase 4 |
| Edit and delete goals | Without CRUD, app is a dead end after first use | Low | Built — Phase 2 |
| Onboarding / empty states | 25% of users abandon after one use | Low-Med | Built — Phase 5 |
| Input validation on all text fields | Required for App Store security bar | Low-Med | Built — Phase 1 |

### Differentiators (v1.0 — Already Built)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| 4-tier goal hierarchy | No mainstream iOS app maps goals to realistic planning horizons this way | Med | Built — core differentiator |
| associatedInspiration per goal | Linking quote/why to a goal creates emotional resonance | Med | Built |
| Morning notification with goal summary content | Personalized notification with actual goal titles | Med | Built |
| Tier-aware streak tracking | Streaks per tier, not just global | Med | Built |
| Community feed with reactions + profanity filter | Social layer without a backend | Med-High | Built — Phase 14 |
| Challenge Platform (3 featured + custom builder) | Template-driven, zero core logic per type | High | Built — Phase 13 |
| User profiles with public goals + deep links | Social profile with privacy toggle | Med | Built — Phase 7 |

---

## v2.0 Feature Landscape (NEW Research — 2026-05-15)

**Scope:** Features being added in v2.0 Social Growth Engine milestone.
**Classification:**
- TABLE STAKES — Expected in any social goal app; missing = product feels incomplete
- DIFFERENTIATOR — Sets Vitamin G apart; not expected, but valued
- ANTI-FEATURE — Complexity without proportional value, or architectural risk

---

## Feature Area 1: Explore Tab

### 1.1 "Shake Out Some Growth" — Random Goal Gifter

**Classification:** DIFFERENTIATOR

**UX behavior in the wild:** Shake-to-discover is rare as a primary mechanic in goal apps. It exists in dictionary apps (shake for random word), music apps (shake to shuffle — removed by Apple from iPod shuffle), and trivia apps. The playfulness is the point. Tapping "Surprise me" is the more common pattern in goal template browsers.

**Expected UX for this feature:** Device shake (or "Surprise me" tap) → confetti burst → single goal card appears with title, category emoji, and short description → "Add this goal" and "Try another" CTAs → once-per-day gate enforced with a top-right counter showing community adoption count.

**Complexity:** Low SwiftUI. `CMMotionManager` is not the right API — override `motionEnded(_:with:)` in a `UIResponder` subclass exposed to SwiftUI via `UIViewControllerRepresentable`. The once-per-day gate is a `UserDefaults` date comparison. Confetti is a `CAEmitterLayer` particle system (no third-party needed on iOS 17+).

**Critical accessibility requirement:** The shake gesture alone fails users with motor disabilities (tremors, paralysis). Apple's own "Shake to Undo" feature has received sustained criticism for this reason. A visible tap fallback ("Surprise me" button) is mandatory, not optional — without it, this fails App Store accessibility expectations and VoiceOver users cannot access the feature at all.

**Dependencies on v1.0:** GoalViewModel.addGoal(). Existing GoalTemplate/ChallengeTemplate pool for the suggestion content.

---

### 1.2 "How Are You Feeling?" Collapsible Mood Prompt

**Classification:** TABLE STAKES

**UX behavior in the wild:** Mood check-ins appear in Reflectly, Daylio, and Apple Health's Mood & Emotions log. The pattern is a horizontal row of emoji faces or colored circles, one tap selects, the card collapses with a checkmark. Best apps show the prompt once per day — not on every open.

**Expected UX:** Collapsible card at top of Explore → 5–7 emoji options in a row → tap selects → card animates closed with a small checkmark → "You're doing great" acknowledgment appears briefly. One disclosure per calendar day.

**Complexity:** Simple SwiftUI `DisclosureGroup` or custom animated `if/else` transition. Ephemeral storage (UserDefaults date + selected mood) is sufficient for v2.0 — no SwiftData schema change required unless mood data feeds into analytics.

**Dependencies on v1.0:** None — self-contained. DailyWin model could be extended to capture mood if analytics are desired (deferred to v3.0).

---

### 1.3 Vitamin Shelf — 6 Category Browsing

**Classification:** TABLE STAKES

**UX behavior in the wild:** Category-based goal/habit browsing exists in Strides ("library" of habit templates by category), Productive (habit categories), and Apple Health (health categories). The pattern is always a grid or horizontal scroll of category chips/cards — tapping filters a list.

**Expected UX:** A 2x3 grid or horizontal scroll of category cards (Body, Mind, Wellness, Money, Connection, Creative), each with a representative emoji or icon and a warm background color per category. Tapping shows a filtered list of pre-made goals or challenges in that category.

**Complexity:** Low. Static category data. Filtered NavigationStack push to a goal list view. No CloudKit. No schema change if categories are string tags on existing ChallengeTemplate records.

**Implementation note:** If goal templates are separate from challenge templates, a lightweight static `GoalTemplate` struct (not a `@Model` — just a `Codable` struct loaded from a bundled JSON or hardcoded array) avoids a schema migration entirely.

**Dependencies on v1.0:** ChallengeTemplate engine (Phase 13). Existing goal creation flow (Phase 2).

---

### 1.4 "3 Gifts for Stuck Days" — Easy Daily Goals

**Classification:** DIFFERENTIATOR

**UX behavior in the wild:** No direct comparables found in mainstream habit apps. The closest is Headspace's "Everyday" quick sessions and Calm's "Daily Calm" — a curated, low-commitment daily item that removes decision friction. The "stuck day" framing is emotionally resonant and uncommon.

**Expected UX:** Three cards shown as "gifts" (gift box emoji or wrapped card visual) with ultra-easy goal titles ("Drink a glass of water," "Take a 10-minute walk," "Write one thing you're grateful for"). Tapping "Add" adds the goal to today's list with a small unwrapping animation. Once added, the card disappears from Explore for the rest of the day. Cards reset at midnight.

**Complexity:** Low. Curated static list of 20–30 rotating options, seeded by `dayOfYear` so all users see the same 3 gifts on a given day (no per-user randomization needed, no CloudKit). `UserDefaults` tracks which of today's 3 were accepted. No schema change needed if gifts are ephemeral (not persisted as goals after the day ends — or they ARE persisted via the normal GoalViewModel path).

**Dependencies on v1.0:** GoalViewModel.addGoal(). Existing goal creation flow.

---

### 1.5 "Trending Now" — Most Active Community Goals

**Classification:** TABLE STAKES

**UX behavior in the wild:** Trending/popular content exists in Strava (popular segments), Habitica (popular challenges), and every major social app. A horizontal scroll of top content with social proof numbers is the universal pattern.

**Expected UX:** A horizontal scroll of 3–5 goal cards showing: goal title, category icon, progress circle with community completion percentage in the center, "X people working on this." Newest community goal is pinned as a separate "New" card.

**Complexity:** Medium. CloudKit public DB query sorted by `participantCount` (descending). CloudKit does not support SQL-style aggregate queries, so `participantCount` must be a denormalized integer field on the public goal record, incremented when users join. Progress circles are existing v1.0 UI. This requires a new CloudKit public record type or a field addition to an existing one.

**CloudKit design note:** Use a `CKModifyRecordsOperation` with `savePolicy: .ifServerRecordUnchanged` and atomic increment via server-side field math — or accept eventual consistency by doing a read-modify-write on the client. The latter is simpler but risks count drift with concurrent joiners. For MVP, accept drift.

**Dependencies on v1.0:** CloudKit public DB (Phase 14). Existing progress ring component (Phase 12). ChallengeTemplate engine (Phase 13).

---

## Feature Area 2: Social Applause System

### 2.1 Clapping Hands Reactions with Floating Username Attribution

**Classification:** DIFFERENTIATOR

**UX behavior in the wild:** Floating reaction animations exist in Facebook Live (floating hearts/emojis), Hinge (floating heart on match), and Zoom ("Epic Reactions" background mode). Username attribution on top of a floating emoji is Vitamin G's specific design signature — not found in mainstream habit apps.

**Expected UX:** From a public profile, viewer taps "Cheer them on today" → a clapping hands emoji floats upward from the button → the viewer's username appears beneath the emoji in a small label → the emoji fades out at top of screen. The profile owner's "Cheers received" counter increments. A once-per-day limit per sender-recipient pair. On the profile owner's own profile view, recent cheers appear as a fading ambient stream of floating username+emoji pairs.

**Complexity:** Medium-High (animation: Low; data layer: High).
- The SwiftUI animation is straightforward: `offset` + `opacity` modifiers with `withAnimation`. Each cheer is an independently animated view.
- The data layer requires a net-new CloudKit public record type: `ApplauseEvent` with fields `giverUserId`, `giverUsername`, `recipientUserId`, `goalId` (optional), `timestamp`. This is NOT a SwiftData model — it lives in CloudKit public DB.
- The once-per-day enforcement: check for an existing `ApplauseEvent` record for today's date from giverUserId to recipientUserId before writing. CloudKit does not have transactions, so this is a read-then-write with a race condition risk; for a social feature, eventual consistency (rare duplicate cheers) is acceptable.
- Real-time receipt by the profile owner: `CKQuerySubscription` on `ApplauseEvent` where `recipientUserId = currentUser` fires a silent push notification, which triggers a local data refresh.

**Dependencies on v1.0:** Username (SchemaV8). ProfileView (Phase 7). CloudKit public DB (Phase 14).

---

### 2.2 "Cheers Given" Counter on Public Profile

**Classification:** TABLE STAKES

**UX behavior in the wild:** "Kudos given" on Strava, "Hugs sent" on wellness apps, "Hearts sent" in messaging apps. Users expect a social engagement counter that shows their positive contribution, not just what they've received (which can feel punishing for low-follower accounts).

**Expected UX:** A metric displayed on the public profile card — "Jordan has given 42 cheers." Shown alongside streak count and goal count. Updated each time the user sends a cheer.

**Complexity:** Low. Increment a `cheersGiven` counter on the user's own private CloudKit record each time an ApplauseEvent is written. Read and display on profile.

**Dependencies on v1.0:** CloudKit user record. ProfileView (Phase 7).

---

## Feature Area 3: Live Users Indicator

### 3.1 "Who's On Right Now" Presence Section

**Classification:** ANTI-FEATURE (as specified) / TABLE STAKES (if scoped down — see recommendation)

**UX behavior in the wild:** Real-time presence exists in Slack (green dot), iMessage (typing indicators), Discord (online/idle/DND status). In habit apps, it's rare — Habitica shows party member activity but not real-time presence. BeReal shows "posted today" which is a presence-lite pattern.

**Why full real-time presence is an ANTI-FEATURE for this stack:**
1. **CloudKit write volume**: A 30-second heartbeat from 100 concurrent users = 200 writes/minute to CloudKit public DB. CloudKit has per-request rate limits and quotas; sustained write loads from heartbeats will exhaust them and degrade other CloudKit operations.
2. **Battery impact**: Continuous network writes while foregrounded drain battery. Background heartbeats require Background App Refresh, which Apple's App Store Review Guidelines flag as potential abuse of background execution.
3. **Privacy concern**: Sharing real-time location-in-app is presence data that requires explicit consent disclosure. This needs a clear privacy disclosure in onboarding and privacy policy update.
4. **Staleness without cleanup**: If the app is backgrounded or killed, the "live" record goes stale for up to the heartbeat interval. Users will see "live" indicators for users who left 30 seconds ago.

**Recommended scope — "Active Today" instead of "Live Now":**
Write `lastActive = Date()` once at app open (one write per session, not per heartbeat). Show users on Community tab who were `lastActive` within the last 2 hours as "recently active." This is:
- 1 write per session vs 120+ writes per hour
- Honest and privacy-safe ("active today" is a much weaker presence signal)
- Stable (no staleness problem — the "2 hours ago" threshold is forgiving)
- Pattern used by LinkedIn ("Active 1 hour ago") and Strava ("Active today")

**Complexity (scoped version):** Low-Medium. Single CloudKit write at app open updates `lastActive` on the user's public record. Community tab query filters by `lastActive > Date() - 7200`.

**Dependencies on v1.0:** CloudKit public user record. Username (SchemaV8). Community tab (Phase 14).

---

## Feature Area 4: Today's Glimpses Carousel

### 4.1 Cycling Card Carousel of Community Goal Posts

**Classification:** TABLE STAKES

**UX behavior in the wild:** BeReal's "Today" feed (daily reset, auto-advancing card carousel), Strava's activity feed (full-width cards with social proof), Instagram Stories (auto-advance on tap). The "today only" constraint is a key design choice that creates urgency and authenticity — users know posts are fresh.

**Expected UX:** A horizontally scrollable (or auto-advancing) carousel at the top of the Community tab. Each card shows: avatar, username, goal title, progress percentage, optional photo. Cards auto-advance every 5 seconds. Tapping opens the goal's landing page with comments. Carousel shows posts from the current calendar day only (resets at midnight UTC). A "X glimpses today" label shows community activity level.

**Auto-advance implementation:** A `Timer` publisher (`Timer.publish(every: 5, on: .main, in: .common)`) drives a `@State var currentPage: Int` that controls a `TabView` with `.tabViewStyle(.page)`. Pause auto-advance when user manually swipes.

**Complexity:** Medium. The `TabView` page carousel is standard SwiftUI. The complexity is photos: `CKAsset` download is async and must be cached locally using `URLCache` or a simple `[CKAsset.fileURL: UIImage]` dictionary. Without caching, each card reload hits CloudKit, which is slow.

**Optimization note:** Pre-fetch the next 2 cards' images while the current card is displayed.

**Dependencies on v1.0:** CloudKit public DB community posts (Phase 14). Existing post/reaction model. Existing community feed view.

---

## Feature Area 5: Glowing This Week Spotlight

### 5.1 Random Weekly User Highlight for Accomplishments

**Classification:** DIFFERENTIATOR

**UX behavior in the wild:** "User of the week" spotlights appear in Habitica (champion of the month), Duolingo's leaderboards (weekly top learner), and fitness apps (weekly podium). The mechanism is usually algorithmically determined by a backend. A serverless equivalent is clever but requires careful design.

**Expected UX:** A featured card on Community tab showing a single highlighted user: large avatar, username, "Glowing this week" badge, their top accomplishment (streak milestone or goal completed this week), and an "Applaud them" button. Updated once per week (Sunday midnight reset). All users see the same spotlight user within a given week.

**Serverless weekly seed pattern (HIGH confidence this works):** On the client, query CloudKit for users with a streak >= 7 active in the last 7 days. Take the sorted list (by userId, deterministic) and select index `weekNumber % count` using `Calendar.iso8601.component(.weekOfYear, from: Date())` as the seed. All clients independently compute the same selection without a backend coordinator. This is an established pattern in distributed systems (consistent hashing).

**Edge case:** If the eligible user list changes during the week (a user falls below 7-day streak), different clients may see different users briefly. For a social spotlight feature, this inconsistency is acceptable.

**Complexity:** Low-Medium. The CloudKit query + selection logic is ~30 LOC. The UI is a styled card. The weekly reset is handled by the seed computation — no cron job or server needed.

**Dependencies on v1.0:** CloudKit public DB user records. Streak data (CompletionEvent model, Phase 3). Username (SchemaV8). Applause system (feature 2.1) for the "Applaud them" button.

---

## Feature Area 6: Streak Freeze Mechanic

### 6.1 "Life Happened." Grace Day — Once Per Week

**Classification:** TABLE STAKES

**UX behavior in the wild:** Duolingo's streak freeze is the gold standard. Key mechanics:
- Acquired separately (Duolingo uses in-app currency; Vitamin G gives them freely, once per week)
- Snowflake icon appears on streak calendar for frozen days instead of a checkmark or empty slot
- The screen frames it as "protecting" the streak, not "cheating" — language matters enormously
- Duolingo's freeze reduced churn by 21% for at-risk users
- Research shows apps with streak freeze functionality average 48% longer streaks (30.63 days vs 18.87 days for users past 14 days)

**Expected UX:** Accessible when streak is at risk (user has not checked in today). A full-screen or sheet view with:
- Snowflake emoji (❄️), large and centered
- Headline: "Life happened."
- Subheadline: "Protect your streak — just this once this week."
- Streak count displayed prominently so user feels the stakes
- "Freeze my streak" button (primary, clear action)
- "Skip — reset my streak" secondary link (honest alternative)
- After use: calendar heatmap shows ❄️ on the frozen day; the streak number remains unchanged
- "Next freeze available: [Monday's date]" shown after use

**Complexity:** Medium.
- `StreakFreeze` SwiftData model: `usedDate: Date?`, `weekNumber: Int`, `yearForWeekOfYear: Int` (using ISO8601 calendar to avoid Monday/Sunday ambiguity). This requires SchemaV9 migration.
- The "streak at risk" detection: no check-in for today + current time > a threshold (e.g., 7 PM). Surface a "your streak is at risk" notification in the evening if freeze is available.
- Calendar heatmap update: the existing heatmap view (Phase 3) needs a data source change to render a snowflake glyph for dates with a freeze record.
- CloudKit sync requirement: `StreakFreeze` model must follow all CloudKit rules (all fields optional or defaulted, no `.unique` attribute).

**iOS-specific calendar note:** Use `Calendar(identifier: .iso8601)` not `.gregorian` for `weekOfYear`. Gregorian weeks start on Sunday in the US; ISO8601 weeks start on Monday. Using ISO8601 ensures a consistent Monday reset regardless of user locale.

**Dependencies on v1.0:** CompletionEvent-based streak computation (Phase 3). Stats heatmap view (Phase 3). SwiftData schema versioning (SchemaV1–V8 already established; SchemaV9 is the next version).

---

## Feature Area 7: Achievement Unlocked Screen

### 7.1 Milestone Celebrations at 7d, 30d (and 14d, 60d, 90d, 365d) Streaks

**Classification:** TABLE STAKES

**UX behavior in the wild:** Full-screen achievement celebrations exist in Duolingo (fireworks on lesson completion), Apple Fitness (award unlock screen with animation), Habitify (confetti on completing all daily habits). The pattern is: full-screen overlay, large visual, celebration animation, clear CTA to continue. They appear once per milestone (not every check-in). Sharing to community is a common secondary CTA.

**Expected UX:**
1. User checks in → streak crosses milestone threshold (7, 14, 30, 60, 90, 365 days)
2. Full-screen overlay appears (over a dimmed background)
3. Animated fire/flame SF Symbol (`flame.fill` with `symbolEffect(.variableColor.iterative)`)
4. "Achievement Unlocked" header, milestone name ("7-Day Streak!"), brief description
5. Confetti burst using `CAEmitterLayer` (no third-party dependency)
6. Two CTAs: "Share to Community" (CloudKit public DB write) and "Continue" (dismiss + return to Home)
7. The achievement is marked as claimed in a `claimedAchievements: Set<String>` persisted to SwiftData — prevents re-showing on next app open

**SF Symbols approach:** `symbolEffect(.variableColor.iterative)` on `flame.fill` (iOS 17+) produces a pulsing color animation. This is zero-dependency and fully native.

**Community share:** The "Share to Community" button creates a post in the CloudKit public DB community feed with the achievement type and streak count. Other users see it in the community feed with an applause reaction option.

**Complexity:** Medium. The CAEmitterLayer confetti animation is reusable across this screen and the Goal Completed screen (feature 8.1). Build it as a standalone `ConfettiView` struct once. The `claimedAchievements` set needs a SwiftData field on the User model (SchemaV9).

**Dependencies on v1.0:** Streak computation (Phase 3). CloudKit public DB (Phase 14). Existing micro-milestone celebration pattern (Phase 12) — v2.0 extends Phase 12 celebrations to full-screen with community share.

---

## Feature Area 8: Goal Completed Celebration

### 8.1 "You Did It" Screen After Full Goal Completion

**Classification:** TABLE STAKES

**UX behavior in the wild:** Every quality goal/habit app shows a dedicated celebration moment when a long-form goal is fully completed. Apple Fitness (ring closing on New Year's Day), Streaks (completion confetti), Productive (check animation). Without this moment, completing a goal feels as anticlimactic as deleting a task.

**Expected UX:**
- Triggered when a goal is marked fully complete (not a daily check-in, but the goal's end condition is met)
- Full-screen sheet (not modal — this is a moment, not a warning)
- Large animated checkmark circle: drawn on appear using `trim(from: 0, to: 1)` path animation on a `Circle` + checkmark `Shape`
- Goal title, displayed prominently
- Streak count for that specific goal (days maintained)
- Subtle confetti burst (smaller scale than achievement screen — goal completion is personal, not broadcast)
- Two CTAs: "Share" (using `ShareLink` with a generated image/text) and "Back to Goals"

**SwiftUI implementation note:** The animated checkmark path is a `Shape` conformance drawing via `path(in:)`, animated with `withAnimation(.easeInOut(duration: 0.6))` toggling a `@State var drawProgress: CGFloat` from 0 to 1 used in a `trim` modifier.

**Complexity:** Low-Medium. The animation is the primary work. The `ShareLink` CTA is 3 lines of code (iOS 16+ ShareLink API, already in the stack). Reuse the confetti emitter from feature 7.1.

**Dependencies on v1.0:** GoalViewModel.completeGoal(). Completion toggle (Phase 2). Progress rings (Phase 12). Confetti view from feature 7.1.

---

## Feature Area 9: Discover Page

### 9.1 Search Public Goals to Join

**Classification:** TABLE STAKES

**UX behavior in the wild:** Strava's "Explore" tab, Habitica's challenge browser, and every social app have a search-to-join pattern. Users type a keyword, see filtered results, tap to join/follow. This is the primary discovery mechanism for building community participation.

**Expected UX:** Search bar at top of Discover tab. As user types (debounced), a CloudKit query filters public goal records by title keyword. Results show: goal card (title, creator username, category emoji, participant count, progress circle). Tapping "Join" calls GoalViewModel.addGoal() with the public goal's template data. A "You're in!" confirmation appears inline.

**CloudKit search limitation:** CloudKit predicates support `CONTAINS[c]` (case-insensitive substring match) but not full-text search (no relevance ranking, no stemming, no typo tolerance). For MVP, substring matching is sufficient. Full-text search would require an external search service (Algolia, etc.) — out of scope given the no-backend constraint.

**Debounce requirement:** Fire the CKQuery 500ms after the last keystroke (`Task.sleep` in an async context, or a `Combine` publisher debounce). Firing on every character change will exhaust CloudKit rate limits and produce a poor UX with rapidly changing results.

**Complexity:** Medium. CKQuery setup, debounce logic, result rendering. The "join" action writes a participation record to CloudKit public DB and adds the goal to the user's local SwiftData store.

**Dependencies on v1.0:** CloudKit public DB (Phase 14). GoalViewModel (Phase 2). Existing public goal records.

---

### 9.2 Search Profiles to Follow

**Classification:** TABLE STAKES

**UX behavior in the wild:** User search by username is universal in social apps. The minimum viable pattern: segmented control (Goals / People) on the Discover search bar, same search UX, results show profile cards with Follow button.

**Follow relationship design decision:** Two options:
1. **Simple**: Store a `Set<String>` of followed userIds on the user's own private CloudKit record. Community feed remains global (no filtering by follow). Follow data only powers the Discover results list and "following" profile state.
2. **Complex**: A `Follow` CloudKit public record (followerId, followedId). Community feed can be filtered to "people I follow." Requires feed query to join across Follow records — CloudKit does not support SQL JOINs, so this requires fetching Follow records then performing a second query per followed user. N+1 query problem.

**Recommendation:** Option 1 for v2.0. Follow data is collected but feed filtering is deferred to v3.0. This avoids the N+1 CloudKit query problem and keeps the community feed global (which benefits new users with no follows yet — they still see content).

**Complexity:** Medium. Username-based CKQuery (`username BEGINSWITH[c] %@` for prefix matching). New "following" state on ProfileView. Writing the followed userId to the user's private record.

**Dependencies on v1.0:** CloudKit user records. Username (SchemaV8). ProfileView (Phase 7).

---

### 9.3 Trending Challenges Section

**Classification:** TABLE STAKES

**UX behavior in the wild:** "Featured" or "Trending" sections at the bottom of discovery pages exist in every app with a content library. They provide a fallback for users who don't know what to search for.

**Expected UX:** Non-searchable section below the search results on the Discover tab (or shown when search bar is empty). Shows 3 trending challenge cards using the existing ChallengeTemplate engine. Same card UI as ChallengeDiscoveryView from v1.0.

**Complexity:** Low. Direct reuse of ChallengeDiscoveryView components (Phase 15). No new data model or CloudKit work.

**Dependencies on v1.0:** ChallengeDiscoveryView (Phase 15). ChallengeTemplate engine (Phase 13).

---

## Feature Area 10: Tip Jar

### 10.1 Tiered Consumable In-App Purchases

**Classification:** TABLE STAKES for a free portfolio/indie app

**UX behavior in the wild:** The tip jar pattern is established in the iOS indie developer ecosystem. Key findings:
- Consumable IAPs (not subscriptions, not non-consumables) are the correct product type — they can be purchased multiple times and have no persistent entitlement to restore
- Multiple tiers (typically 3) outperform a single tier — users anchored on "small" select "medium" more often when all 3 are visible (middle anchoring effect)
- Common indie tier structure: ~$0.99 / $2.99 / $4.99 (exact amounts vary; $0.99 is the minimum meaningful App Store IAP)
- Naming conventions vary widely by app personality. Common patterns: "Small Coffee / Large Coffee / Supporter," "Small Tip / Medium Tip / Large Tip," or thematic names (e.g., fountain pen nibs, emoji-based)

**App Store compliance (CRITICAL):** External tip links ("Buy Me a Coffee" external URLs) have been rejected under App Store Review Guideline 3.1.1. All tips must go through StoreKit IAP. The purchase flow must use Apple's native payment sheet — no custom payment UI. Products must be configured in App Store Connect as Consumable IAPs before TestFlight/submission.

**StoreKit 2 implementation:** Use `Product.products(for: ["tip.small", "tip.medium", "tip.large"])` to fetch products. Show them using `ProductView` (iOS 17+ low-code API) or custom UI with `product.displayPrice`. Call `product.purchase()` and handle the `.paymentSheet` result. Require a `StoreKitConfiguration` file for local sandbox testing (Xcode 13+ feature, configured in scheme settings).

**Expected UX:** Accessible via a prominent button on the About page. A sheet slides up showing 3 product cards arranged vertically: emoji + tier name + price + a short description ("Help keep Vitamin G growing"). After purchase, an animated thank-you moment (e.g., sparkle emoji burst + "Thank you! You're the best."). No feature gates behind tips — tips are pure gratitude.

**Complexity:** Medium. StoreKit 2 is well-documented and the API surface is clean. The primary complexity is App Store Connect configuration and sandbox testing — not the code. Estimated 2–3 days including sandbox validation.

**Dependencies on v1.0:** None — fully independent. About page is new in v2.0.

---

## Feature Area 11: Notification Time Picker

### 11.1 "Pick Your Daily Nudge Time" Landing Page

**Classification:** TABLE STAKES

**UX behavior in the wild:** Every habit/reminder app with daily notifications must provide time configuration. Research finding: apps that show quick-select preset times (e.g., 6 AM, 7 AM, 8 AM, 9 AM as tappable chips) see higher completion rates than apps that show only a time picker wheel. The preset covers 80% of use cases; the custom picker handles edge cases.

**Expected UX:**
- Full-screen landing page shown during onboarding (after notification permission slide) and accessible from Settings
- Headline: "Pick your daily nudge time"
- 4–6 quick-select time buttons styled as chips: "6:00 AM," "7:00 AM," "8:00 AM," "9:00 AM," "10:00 AM"
- A "Custom time" option that presents a native `DatePicker(selection:displayedComponents: .hourAndMinute)` inline
- "Skip for now" link at bottom (stores nil; notification scheduling skipped until user sets a time)
- On selection: confirmation animation, notification rescheduled immediately

**Reschedule logic:** When the user changes time, call `UNUserNotificationCenter.current().removeAllPendingNotificationRequests()` then reschedule with the new `UNCalendarNotificationTrigger`. This already exists in v1.0 — this feature is purely a new UI surface calling the existing scheduling logic.

**Complexity:** Low. The notification scheduling is already built (Phase 3). This is 1 new SwiftUI view with chip buttons + DatePicker.

**Dependencies on v1.0:** UNCalendarNotificationTrigger scheduling (Phase 3). UserDefaults key for notification time (existing).

---

## Feature Area 12: In-Onboarding Permission Slides

### 12.1 Permission Priming Slides for Notifications and Camera

**Classification:** TABLE STAKES

**UX behavior in the wild:** Permission priming (showing a custom screen explaining why before triggering the system alert) is recommended in Apple's HIG and standard practice in quality iOS apps. Research data:
- Apps using permission priming see 2x higher opt-in rates than apps that request at launch without context
- Apps that defer permission requests (not at launch, but in context) see 28% higher grant rates
- 78% of users who understand why a permission is needed exhibit 2x higher opt-in rates

**Apple HIG requirement:** The system permission alert's purpose string (NSCameraUsageDescription, NSUserNotificationsUsageDescription in Info.plist) must be set and should closely match the priming screen's explanation. Mismatch between the priming copy and the system alert text creates distrust.

**Expected UX — Notification Permission Slide:**
- Full-screen onboarding slide (appears in the onboarding TabView sequence)
- Bell icon (SF Symbols: `bell.fill`)
- Headline: "Stay on track every day"
- Body: "We'll send you a gentle morning reminder with your top goals — nothing else, ever."
- Primary button: "Turn on notifications" → triggers `UNUserNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge])`
- Secondary link: "Maybe later" → skips without requesting

**Expected UX — Camera Permission Slide:**
- Camera icon (SF Symbols: `camera.fill`)
- Headline: "Share your journey"
- Body: "Camera access lets you add photos to your goals and set your profile picture."
- Primary button: "Allow camera" → triggers `AVCaptureDevice.requestAccess(for: .video)`
- Secondary link: "Skip for now"

**State machine requirement:** Track permission outcomes in an onboarding state enum. If notification permission was already granted/denied (e.g., user re-runs onboarding), skip the notification slide. `UNUserNotificationCenter.current().getNotificationSettings()` returns the current authorization status synchronously-ish (callback-based).

**Complexity:** Low. Two SwiftUI views. The permission requests are one-liners. The complexity is the state machine: handle already-granted, granted-now, denied, and not-determined states gracefully.

**New entitlement required:** Camera access (`NSCameraUsageDescription`) requires `Privacy - Camera Usage Description` in Info.plist and the `Camera` capability in the target settings. If v1.0 has no camera usage, this must be added before submission.

**Dependencies on v1.0:** Existing onboarding flow (Phase 5). Existing notification permission request (Phase 3).

---

## v2.0 Feature Classification Summary

| Feature | Classification | Complexity | New Schema? |
|---------|---------------|------------|-------------|
| 1.1 Shake goal gifter | DIFFERENTIATOR | Low | No |
| 1.2 Mood check-in prompt | TABLE STAKES | Low | No |
| 1.3 Vitamin Shelf categories | TABLE STAKES | Low | No |
| 1.4 3 Gifts for stuck days | DIFFERENTIATOR | Low | No |
| 1.5 Trending Now goals | TABLE STAKES | Medium | CloudKit field add |
| 2.1 Applause floating reactions | DIFFERENTIATOR | Medium-High | New CK record type |
| 2.2 Cheers given counter | TABLE STAKES | Low | CK field add |
| 3.1 Live users indicator | ANTI-FEATURE (full) / TABLE STAKES (scoped to "active today") | Low-Medium (scoped) | CK field add |
| 4.1 Today's Glimpses carousel | TABLE STAKES | Medium | No (reuses existing posts) |
| 5.1 Glowing spotlight | DIFFERENTIATOR | Low-Medium | No |
| 6.1 Streak freeze | TABLE STAKES | Medium | SwiftData SchemaV9 |
| 7.1 Achievement unlock screen | TABLE STAKES | Medium | SwiftData field add |
| 8.1 Goal completed "You did it" | TABLE STAKES | Low-Medium | No |
| 9.1 Search public goals | TABLE STAKES | Medium | No |
| 9.2 Search profiles to follow | TABLE STAKES | Medium | CK field add (following set) |
| 9.3 Trending challenges | TABLE STAKES | Low | No |
| 10.1 Tip jar | TABLE STAKES | Medium | No (StoreKit only) |
| 11.1 Nudge time picker | TABLE STAKES | Low | No |
| 12.1 Permission priming slides | TABLE STAKES | Low | No (Info.plist only) |

---

## Anti-Feature Summary

| Feature | Why It's an Anti-Feature | Recommended Scope Instead |
|---------|--------------------------|--------------------------|
| True real-time "live users" presence | CloudKit write volume + battery drain + privacy consent complexity | "Active today/recently" (single write at app open) |
| Shake-only gesture with no tap fallback | Inaccessible to users with motor disabilities; invisible/undiscoverable | Always pair with "Surprise me" tap button |
| Follow-filtered community feed (v2.0) | N+1 CloudKit query problem; empty state for new users | Keep global feed; defer follow-based filtering to v3.0 |

---

## v2.0 Schema Changes Required

| Change | Scope | Migration Path |
|--------|-------|---------------|
| `StreakFreeze` model (usedDate, weekNumber, yearForWeekOfYear) | SwiftData private DB | SchemaV9 via VitaminGMigrationPlan |
| `claimedAchievements: [String]` on User model | SwiftData private DB | SchemaV9 |
| `ApplauseEvent` record type (giverUserId, giverUsername, recipientUserId, goalId?, timestamp) | CloudKit public DB | New CK record type (promoted via CloudKit console) |
| `lastActive: Date` on user public record | CloudKit public DB | New CK field on existing record type |
| `participantCount: Int` on community goal records | CloudKit public DB | New CK field on existing record type |
| `followingUserIds: [String]` on user private record | CloudKit private DB | New CK field (or SwiftData User model field, SchemaV9) |
| `NSCameraUsageDescription` in Info.plist | App target Info.plist | Manual addition; requires App Store Review re-approval if first time |

---

## v2.0 MVP Priority Ordering

**Build first — highest retention lift, lowest risk:**
1. Streak Freeze (proven 48% retention lift, medium complexity, no external dependencies)
2. Achievement Unlocked Screen (extends v1.0, builds on existing confetti infrastructure)
3. Goal Completed "You Did It" (low complexity, high emotional impact, reuses confetti)
4. "3 Gifts for Stuck Days" (no CloudKit, no schema change, differentiating framing)
5. Notification Time Picker (fixes v1.0 UX gap, low complexity)
6. Permission Priming Slides (improves notification opt-in rate, low complexity)

**Build second — social layer (medium complexity, CloudKit work required):**
7. Today's Glimpses Carousel (extends existing community feed data)
8. Applause System (brand-defining, new CloudKit record type)
9. Vitamin Shelf + Trending Now (Explore tab structure)
10. Discover Page — goal search (CKQuery, debounce logic)

**Build third — differentiating polish (validate assumptions first):**
11. Tip Jar (App Store Connect configuration dependency; validate before building)
12. Glowing Spotlight (validate community size assumption — needs eligible users with 7+ day streaks)
13. Live Users / "Active Today" scoped version (lowest priority — users need to exist first)

---

## Feature Dependency Map (v2.0)

```
Explore Tab
  1.1 Shake Goal Gifter ─────────────────────────── GoalViewModel.addGoal() [v1.0]
  1.3 Vitamin Shelf ──────────────────────────────── ChallengeTemplate engine [v1.0]
  1.4 3 Gifts ─────────────────────────────────────── GoalViewModel.addGoal() [v1.0]
  1.5 Trending Now ────────────────────────────────── CloudKit public DB + progress rings [v1.0]

Community Tab
  2.1 Applause reactions ──────────────────────────── Username (SchemaV8) + CloudKit public DB [v1.0]
    └── 5.1 Glowing Spotlight ──────────────────────── 2.1 (applaud button) + streak data [v1.0]
  3.1 Live Users / Active Today ───────────────────── CloudKit user records [v1.0]
  4.1 Today's Glimpses Carousel ───────────────────── Community posts [v1.0 Phase 14]

Milestone Features
  6.1 Streak Freeze ───────────────────────────────── Streak engine [v1.0] → SchemaV9 (new)
  7.1 Achievement Screen ──────────────────────────── Streak engine [v1.0] + CloudKit share [v1.0]
    └── 8.1 Goal Completed Screen ───────────────────── GoalViewModel [v1.0] + confetti from 7.1

Discover Tab
  9.1 Search Goals ────────────────────────────────── CloudKit CKQuery + GoalViewModel [v1.0]
  9.2 Search Profiles ─────────────────────────────── CloudKit user records + SchemaV9 (following set)
  9.3 Trending Challenges ─────────────────────────── ChallengeDiscoveryView [v1.0 Phase 15]

Supporting Features
  10.1 Tip Jar ─────────────────────────────────────── StoreKit 2 (independent, no v1.0 deps)
  11.1 Nudge Picker ───────────────────────────────── UNCalendarNotificationTrigger [v1.0]
  12.1 Permission Slides ──────────────────────────── Notification request [v1.0] + camera (new)
```

---

## Sources

- [Designing A Streak System: The UX And Psychology Of Streaks — Smashing Magazine](https://www.smashingmagazine.com/2026/02/designing-streak-system-ux-psychology/)
- [Apps That Use Streaks: 10 Real Examples Analysed — Trophy](https://trophy.so/blog/streaks-feature-gamification-examples)
- [Designing Streaks for Long-Term User Growth — Trophy](https://trophy.so/blog/designing-streaks-for-long-term-user-growth)
- [Duolingo Streak System Detailed Breakdown — Medium](https://medium.com/@salamprem49/duolingo-streak-system-detailed-breakdown-design-flow-886f591c953f)
- [Implementing a Tip Jar with Swift and SwiftUI — Ben Cardy](https://bencardy.co.uk/2023/02/17/implementing-a-tip-jar-with-swift-and-swiftui/)
- [Building a tip jar feature with RevenueCat](https://www.revenuecat.com/blog/engineering/building-a-tip-jar-feature-with-revenuecat/)
- [Implementing Consumable In-App Purchases with StoreKit 2 — Create with Swift](https://www.createwithswift.com/implementing-consumable-in-app-purchases-with-storekit-2/)
- [My Ongoing Battle with Apple Over a "Buy Me a Coffee" Link — Medium](https://medium.com/@robert-baer/my-ongoing-battle-with-apple-over-a-buy-me-a-coffee-link-is-over-9c158df81c05)
- [Mastering StoreKit 2 in SwiftUI — Medium](https://medium.com/@dhruvinbhalodiya752/mastering-storekit-2-in-swiftui-a-complete-guide-to-in-app-purchases-2025-ef9241fced46)
- [Onboarding UX Patterns — Permission Priming — UserOnboard](https://www.useronboard.com/onboarding-ux-patterns/permission-priming/)
- [Apple Human Interface Guidelines — Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding)
- [Apple Human Interface Guidelines — Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications)
- [Mobile Permission Requests: Timing, Strategy & Compliance — Dogtown Media](https://www.dogtownmedia.com/the-ask-when-and-how-to-request-mobile-app-permissions-camera-location-contacts/)
- [Testing Motion-Based Features — Real iOS Devices Shake Gesture Accessibility — DEV Community](https://dev.to/bhawana127/testing-motion-based-features-on-real-ios-devices-why-your-shake-gesture-is-leaving-users-behind-1fek)
- [Creating Fun SwiftUI Animations: Emoji Reactions for Chat and Video — Medium/Stream](https://medium.com/@amosgyamfi/creating-fun-swiftui-animations-emoji-reactions-for-chat-video-streaming-52db30c2f029)
- [Real-Time Heartbeats for Online Status in Chat Apps — Medium](https://medium.com/@onakoyak/real-time-reliability-using-client-server-heartbeats-to-ensure-consistent-online-status-in-a-chat-429ae3c2d94a)
- [Strava: The Social Layer of Fitness — Blake Crosley](https://blakecrosley.com/guides/design/strava)
- [Master Search UX in 2026: Best Practices — Design Monks](https://www.designmonks.co/blog/search-ux-best-practices)
- [CloudKit — Apple Developer Documentation](https://developer.apple.com/documentation/cloudkit)

---

---

## v3.0 Feature Landscape (NEW Research — 2026-05-28)

**Scope:** Features being added in v3.0 Personal Intelligence + Apple Watch milestone.
**Confidence:** MEDIUM-HIGH (Apple Watch patterns verified against WidgetKit docs and competitive apps; AI integration patterns verified against Anthropic API docs and competitive landscape; analytics patterns verified against Swift Charts docs and competitor apps)

**Classification:**
- TABLE STAKES — Expected for this feature category; missing = implementation feels incomplete
- DIFFERENTIATOR — Sets Vitamin G apart from comparable implementations
- ANTI-FEATURE — High complexity-to-value ratio, UX harm, or architectural risk

---

## Feature Area A: Apple Watch App

### A.1 Streak Count Complication

**Classification:** TABLE STAKES

**UX behavior in the wild:** Every iOS streaks app with a Watch extension surfaces the streak number as a complication. Duolingo's Watch complication shows the streak count in a circular badge. Streaks (the app) shows active habit count with a ring. Users who go to the trouble of adding a complication expect a persistent, always-visible glance — not a number they have to dig for.

**Expected UX:** A `accessoryCircular` complication showing the current global streak count as a large number with a flame SF Symbol below. Tapping the complication opens the Watch app. The number stays current — stale complications erode trust faster than no complication at all.

**Complication families to support:** `accessoryCircular` (primary — fits most watch faces), `accessoryRectangular` (secondary — shows label + number), `accessoryCorner` (optional). Do not attempt to support all 4 families from day one; accessoryCircular is the highest-value target.

**Data flow (CRITICAL — App Groups do not work across phone/watch):** The app group container used for iOS widgets cannot be shared between the iPhone app and the Watch app — they are separate devices. Use CloudKit private DB as the source of truth; the Watch app reads streak data via its own SwiftData container synced through CloudKit. Alternatively, use WatchConnectivity `transferCurrentComplicationUserInfo` to push a lightweight payload (just the streak integer) from the iPhone app to the Watch complication timeline. WatchConnectivity is the faster, lighter approach for a single integer.

**Refresh budget:** watchOS gives each complication a budget of approximately 50 timeline entries per day and approximately 40-50 background refreshes. The streak number changes at most once per day (at check-in time). Refresh on check-in (via WatchConnectivity push) rather than polling. Do not set up a repeating background refresh — the complication content changes at most once per day.

**Complexity:** Medium. New WatchKit target in Xcode. WidgetKit extension inside the Watch app. WatchConnectivity session setup on both the phone and watch sides. Timeline provider with a single entry (streak count). One-time Xcode target/entitlement setup is the primary friction, not the Swift code.

**Dependencies:** CompletionEvent-based streak computation (v1.0 Phase 3). App Group entitlement already exists (repurpose for WatchConnectivity session ID coordination if needed). WatchConnectivity requires the iPhone app to be the WCSession delegate.

---

### A.2 Active Goal + Progress Ring Complication

**Classification:** TABLE STAKES

**UX behavior in the wild:** Progress ring complications are the visual language of Apple Watch. Apple Fitness rings, Streaks (the app), and Habitify all show ring-based progress. Users expect a ring that fills as they complete their daily goal activity.

**Expected UX:** A `accessoryCircular` complication with a progress ring (filled 0–100% based on today's completion rate across active goals) and a short goal title truncated to ~12 characters in the center or below the ring. Tapping opens the Watch app's goal list.

**Progress value source:** The existing `activeGoalTitle` and `activeGoalProgress` fields already on `WidgetDisplayData` (added in Phase 24) can be forwarded to the Watch via WatchConnectivity. The Watch complication reads from this forwarded data, not from SwiftData directly — this avoids a full SwiftData stack on the Watch for this use case.

**Complexity:** Medium. Same WatchKit target as A.1. The `accessoryCircular` complication with a Gauge or ProgressView inside a timeline entry is well-documented. The primary work is the WatchConnectivity data forwarding bridge.

**Dependencies:** Phase 24 WidgetDisplayData extension (activeGoalTitle/activeGoalProgress). WatchConnectivity session from A.1.

---

### A.3 Check-In from Wrist

**Classification:** DIFFERENTIATOR

**UX behavior in the wild:** Streaks (the app) allows marking a habit complete from the Watch complication with a single tap. This is the highest-value Watch interaction — the whole reason someone wants an app on their wrist. Without it, the Watch app is read-only and feels like a missed opportunity.

**Expected UX — two valid interaction patterns:**

**Pattern 1 (Tap complication → open Watch app → tap "Done"):** The complication tap opens the Watch app. The Watch app shows the top active goal and a large "Check in" button. User taps. A haptic confirmation fires (`WKInterfaceDevice.current().play(.success)`). The complication updates on next timeline refresh.

**Pattern 2 (Interactive complication — watchOS 11+ only):** A `Button(intent: CheckInGoalIntent())` inside the complication view triggers an App Intent directly from the watch face without opening the app. This is the highest-friction-reduction pattern but requires: watchOS 11 minimum (confirmed available since WWDC 2024), an App Intent that runs on the Watch (intent must be registered for watchOS target), and the intent writes to a shared store (WatchConnectivity transfer to phone, which then persists to SwiftData and CloudKit).

**Recommendation:** Build Pattern 1 first (opens Watch app). It works on watchOS 10+ and has no App Intent complexity. Add Pattern 2 as an enhancement in a later phase if the Watch app proves popular.

**Watch app data persistence:** Check-ins from the Watch must eventually reach the iPhone's SwiftData store (the authoritative store). Use `WCSession.transferUserInfo` (guaranteed delivery, not real-time) to send a `[String: Any]` dictionary containing the goal ID and completion timestamp from Watch to iPhone. The iPhone app receives this in `session(_:didReceiveUserInfo:)` and writes it to SwiftData.

**Complexity:** High. The Watch-to-iPhone data sync via WatchConnectivity is the hardest part: handling the delegate callbacks, the offline queue (Watch may check in when iPhone is not reachable), and the deduplication logic on receipt. Plan for 2–3 days of WatchConnectivity debugging beyond the UI work.

**Dependencies:** WatchConnectivity session from A.1. GoalViewModel.checkIn() on iPhone side. App Intents framework (if Pattern 2 added).

---

### A.4 Morning Nudge Delivered to Apple Watch

**Classification:** TABLE STAKES

**UX behavior in the wild:** Any iOS app that sends a morning push notification automatically delivers it to the paired Apple Watch if the phone is locked and the Watch is worn and unlocked. This is default iOS/watchOS behavior — it requires zero Watch-specific code to enable.

**Expected UX:** The existing morning push notification (personalized with goal titles) appears on the Watch face as a notification card. The user can dismiss it from the Watch or tap to open the Watch app (if installed).

**What "Watch-specific" means here:** The only Watch-specific enhancement is providing a Watch notification interface in the WatchKit target: a custom `WKUserNotificationHostingController` that shows a styled notification view instead of the default system card. This is optional polish — the notification delivers without it.

**Complication tap as alternative nudge:** The complication itself serves as a persistent visual nudge after the notification is dismissed. The morning push notification ensures the first wrist raise of the day shows a goal reminder even if the user has not tapped the complication.

**Complexity:** Low. Default notification delivery to Watch requires no code. Custom Watch notification UI is Low-Medium (optional WKUserNotificationHostingController subclass). This is the lowest-effort Watch feature with the highest daily visibility.

**Dependencies:** Existing UNCalendarNotificationTrigger morning notification (v1.0 Phase 3). WatchKit target from A.1 (needed only for custom notification UI — not for basic delivery).

---

### A.5 Watch App Anti-Features

**Classification:** ANTI-FEATURE

| Anti-Feature | Why to Avoid | Better Approach |
|---|---|---|
| Full SwiftData stack on Watch for all goal data | Watch has limited RAM and storage; a full goal model graph is overkill for glanceable complications | Forward only what the complication needs via WatchConnectivity (integer + string) |
| WCSession live messaging for real-time sync | `sendMessage` requires both devices reachable; breaks when iPhone is in airplane mode or out of Bluetooth range | Use `transferUserInfo` (guaranteed delivery queue) for check-in data |
| Polling-based complication refresh | Exhausts the 50-refresh budget quickly | Push via `transferCurrentComplicationUserInfo` only when data actually changes (check-in event) |
| Supporting all 4 complication families in v1 | 4x design and test surface for complications users may never use | Start with `accessoryCircular` only; add others based on user feedback |

---

## Feature Area B: Analytics Dashboard

### B.1 Streak History Chart

**Classification:** TABLE STAKES

**UX behavior in the wild:** Strides, HabitNow, and Streaks (the app) all show a streak history chart — a bar or line chart where each bar represents a streak run (length on Y axis, end date on X axis). Users who are streak-motivated want to see their personal best and improvement over time. The GitHub contribution graph is the cultural reference point for this kind of longitudinal data display.

**Expected UX:** A bar chart (preferred over line for discrete streak runs) showing each completed streak run as a vertical bar. X axis: time (week or month granularity selectable). Y axis: streak length in days. Tapping a bar reveals a tooltip with start date, end date, and length. A "Personal Best" annotation on the tallest bar. Segmented control for "Per goal" vs "Global" view.

**Swift Charts implementation:** `BarMark` with `x: .value("Period", endDate)` and `y: .value("Days", streakLength)`. Swift Charts is already in the stack (iOS 16+, stronger on iOS 17+ with `chartXSelection` for tap-to-annotate). No new dependency required.

**Data derivation:** The streak history requires computing all historical streak runs from `CompletionEvent` records — not just the current streak. The existing streak engine computes the current streak; this feature needs the full run history. A `StreakRun` struct (startDate, endDate, length) derived from sorted CompletionEvents is the data model. This computation is local and does not require new SwiftData schema changes — it reads existing CompletionEvent records.

**Complexity:** Medium. The Swift Charts bar chart is low complexity. The `StreakRun` computation from CompletionEvent history is medium complexity (requires a date-gap detection algorithm over sorted events). Implement in a ViewModel method, not in the View.

**Dependencies:** CompletionEvent records (v1.0 Phase 3). Swift Charts (already in the tech stack).

---

### B.2 Completion Rate Trends Chart

**Classification:** TABLE STAKES

**UX behavior in the wild:** HabitDaily, Done, and Productive all show a weekly/monthly completion percentage over time. This is the "are you getting better?" chart — the core analytics question for goal trackers. Users expect to see improvement trending upward over weeks.

**Expected UX:** A line chart showing completion rate (0–100%) on Y axis, time period (weeks or months) on X axis. Segmented control: "Weekly" / "Monthly." The line uses `.interpolationMethod(.catmullRom)` for smooth curves. A horizontal reference line at 80% ("your target") if the user has set a goal. The most recent data point is annotated with its value.

**Data derivation:** Weekly completion rate = (check-ins that week / total possible check-ins that week) × 100. "Total possible" = number of active goals × 7 days. This requires aggregating CompletionEvents by ISO calendar week, joining against the goal creation dates (a goal only contributes to "possible" starting from its creation date). This join logic is non-trivial but runs locally on-device from existing SwiftData data.

**Complexity:** Medium. Swift Charts line chart is straightforward. The aggregation query over CompletionEvents with goal-aware "possible" calculation is the main complexity. Cache the result (recompute on check-in, not on every view render).

**Dependencies:** CompletionEvent records (v1.0 Phase 3). Goal creation dates from the Goal model. Swift Charts.

---

### B.3 Full All-Time Goal Heatmap (GitHub-style)

**Classification:** DIFFERENTIATOR

**UX behavior in the wild:** GitHub's contribution graph is the universally recognized cultural reference. Streaks (the app) has a yearly heatmap. Loop Habit Tracker has a full-history heatmap. The all-time GitHub-style heatmap is rare in mainstream iOS goal apps — most show only the past 30–90 days. Showing the full history since app install is emotionally powerful ("look how far I've come").

**Expected UX:** A horizontally scrollable grid of colored squares, one per day, from the goal's creation date to today. Color intensity maps to check-in count that day (0 = empty/gray, 1 = light green, 2+ = darker green, using a 4-level palette matching GitHub's aesthetic). Week columns run top-to-bottom (Mon–Sun). Month labels appear above each month's first column. A year selector if the history spans multiple years. Pinch-to-zoom to switch between "year view" (small squares) and "month view" (larger squares with day numbers).

**Existing heatmap:** v1.0 already has a weekly heatmap (Phase 3). This feature extends it to all-time, requiring a horizontally scrolling implementation rather than the fixed-week view. The existing heatmap color logic can be reused.

**Implementation note:** A full all-time heatmap with 365+ squares per year must use `LazyHStack` with virtualized rendering — not a `ForEach` over all days in a non-lazy container. Building with `LazyHStack` inside a `ScrollView(.horizontal)` is the correct pattern. Rendering 1000+ squares in a non-lazy stack will cause scroll stutter.

**Complexity:** Medium-High. The lazy grid rendering with virtualization is the primary complexity. The color mapping and date grid generation are straightforward but require careful handling of week boundaries and partial months.

**Dependencies:** CompletionEvent records (v1.0 Phase 3). Existing heatmap color logic (Phase 3). LazyHStack (SwiftUI).

---

### B.4 CSV Export via Share Sheet

**Classification:** TABLE STAKES

**UX behavior in the wild:** Loop Habit Tracker, HabitDaily, and Productive all support data export. Users who use analytics features invariably want to own their data. CSV export is the lowest-friction export format (opens in Numbers, Excel, Google Sheets). Users who don't use it don't notice its absence; users who want it strongly resent its absence.

**Expected UX:** An "Export" button in the Analytics view or Settings. Tapping generates a CSV file (in-memory, no disk write needed) and presents the native `ShareLink` (iOS 16+ API) / `UIActivityViewController` for sharing to Files, Mail, AirDrop, etc. The CSV schema: one row per day, columns: date, goalTitle, goalTier, completed (boolean), streakDay. A header row. UTF-8 encoding.

**Implementation:** Generate the CSV as a `String` by iterating over CompletionEvent records grouped by goal. Write to a `Data` object. Use `ShareLink(item: csvData, preview: SharePreview("Vitamin G Export"))` for the share sheet — zero UIKit bridge required on iOS 16+.

**Complexity:** Low. CSV generation is string interpolation over a sorted array of structs. `ShareLink` is 3 lines of SwiftUI. The data query (fetching all CompletionEvents) may be slow for large histories — run it in a background Task, show a progress indicator, then present the share sheet when ready.

**Dependencies:** CompletionEvent records (v1.0 Phase 3). Goal model. SwiftUI `ShareLink` (iOS 16+, in the stack).

---

### B.5 Analytics Anti-Features

| Anti-Feature | Why to Avoid | Better Approach |
|---|---|---|
| Showing completion rate as a simple percentage without time context | "70% completion rate" is meaningless without knowing the period | Always show rate in a time-windowed chart with period labels |
| Computing streak history and completion trends on the main thread | Large CompletionEvent histories (1000+ records) will block the UI | Always compute in a `Task { }` on a background thread, publish results via `@MainActor` |
| Exporting via a custom file picker or saving to app Documents | Complex, fragile, requires user to understand iOS Files app | Use `ShareLink` / `UIActivityViewController` — system handles destination choice |
| Offering JSON export instead of (or in addition to) CSV for v1 | Developers want JSON; users want CSV (opens in spreadsheets) | CSV only for v1; JSON export can be added later if requested |

---

## Feature Area C: AI (Claude) Integration

### C.1 Goal Suggestions — Claude Analyzes Existing Goals

**Classification:** DIFFERENTIATOR

**UX behavior in the wild:** Pattrn, HabitForge, and AIHabitPro all offer AI goal suggestions. The dominant pattern: show 3 AI-generated goal suggestions with brief rationale, allow one-tap adoption, allow regeneration. The key differentiator for Vitamin G is that suggestions are seeded by the user's *existing goals* — not generic lifestyle templates. "You're working on fitness and mindfulness — consider adding a reading goal to round out your growth."

**Expected UX:** A "Suggest goals" card on the Goals tab or a dedicated "AI Suggestions" sheet. Tapping triggers an API call with the user's current goals (titles and tiers) as context. Three suggestions appear with title, tier recommendation, and 1-sentence rationale. Each suggestion has an "Add this goal" button (calls GoalViewModel.addGoal()) and a "Not for me" dismiss. A "Refresh suggestions" button generates 3 new ones (rate-limited to prevent runaway API costs). A loading state with animated dots while the API responds.

**Prompt structure (HIGH confidence this works):** Send a system prompt establishing the role, then a user message listing the goals. Request structured output (JSON array of 3 objects: title, tier, rationale). Parse the JSON response. Do not stream for this use case — wait for the full response, then render all 3 suggestions at once.

**API key security (CRITICAL):** The Anthropic API key must not be embedded in the iOS app binary. Anyone with the `.ipa` file can extract strings from the binary. The correct architecture is: iOS app → your backend proxy → Anthropic API. The proxy receives the goal list, forwards to Claude, returns suggestions. This requires a minimal backend (a single Cloudflare Worker, Vercel serverless function, or AWS Lambda is sufficient). This is not optional — Anthropic's terms of service and security best practices explicitly prohibit embedding API keys in client apps.

**Backend proxy minimum viable:** A single HTTP POST endpoint that: (1) validates the request (e.g., a per-device token or app-specific secret header — not the user's Anthropic key), (2) appends the Anthropic API key from an environment variable, (3) forwards to `https://api.anthropic.com/v1/messages`, (4) returns the response. A Cloudflare Worker can do this in ~30 lines of JavaScript with no infrastructure cost up to 100K requests/day.

**Rate limiting / cost control:** Each suggestion request costs approximately $0.001–0.003 USD (claude-haiku-3, short prompt, short response). Without rate limiting, a user who taps "Refresh" 100 times could cost $0.30/day. Enforce a per-device rate limit at the proxy level: max 10 suggestion requests per user per day. Store the request count in a KV store (Cloudflare KV is free) keyed by a device fingerprint hash.

**Complexity:** High. The AI feature itself is low-complexity (URLSession POST, JSON parsing). The required backend proxy and rate limiting add Medium complexity. The overall feature is High because it introduces a new infrastructure dependency (backend proxy) that did not exist in v1.0/v2.0. Plan for 1–2 days of backend work in addition to the iOS work.

**Dependencies:** GoalViewModel with goal list access. Network layer (URLSession, already in use for CloudKit indirect patterns). New: backend proxy (Cloudflare Worker or equivalent). Anthropic API account.

---

### C.2 Personalized Daily Motivation Copy

**Classification:** DIFFERENTIATOR

**UX behavior in the wild:** "Habits - AI Daily Tracker" and "Habit AI" both offer AI-generated daily motivation. The pattern: one piece of motivational copy, generated fresh each morning, personalized with the user's name, streak, and goal context. The key UX finding from competitors is that generic motivation ("You can do it!") is perceived as worse than no motivation — personalization is the entire value. If the copy does not reference something specific to the user, users stop reading it.

**Expected UX — two surfaces:**

**Surface 1: Morning push notification body.** Instead of the static "Here are your goals for today: [list]", the notification body is Claude-generated copy: "Day 14, Jordan. Your writing goal is 14 days strong — keep the momentum." This is generated by the proxy the night before (e.g., 2 AM local time) and cached. The notification scheduler reads from the cache when scheduling the 8 AM notification.

**Surface 2: Home tab card.** A card at the top of the Home tab shows today's motivation copy (same content as the notification, or a fresh generation on app open). Appears only once per calendar day (collapses/hides after the user's first check-in of the day).

**Generation timing:** Generating on-demand at notification schedule time (daily at a fixed background task time) is cleaner than generating at app open. Use `BGAppRefreshTask` to schedule a background generation the night before. The generated copy is stored in UserDefaults (ephemeral — no SwiftData schema change needed).

**Offline / failure handling:** If the API call fails or the device has no connectivity, fall back to the existing static notification copy (the goal list format from v1.0). The motivation copy is a nice-to-have enhancement — a missing response should never block the notification from firing.

**Privacy consideration:** The prompt sent to the Claude API includes the user's goal titles and streak data. This is personal information. Include a clear disclosure in the privacy policy and, on first use, show an in-app prompt: "To generate personalized motivation, we send your goal titles and streak count to Claude (Anthropic). No other data is shared." Give the user an opt-out toggle in Settings.

**Complexity:** High. The `BGAppRefreshTask` background execution is notoriously unreliable on iOS (the OS decides when to run it, not the developer). The notification scheduling pipeline (generate copy → store → schedule notification with copy) has multiple failure points. Plan for 3–4 days including testing on-device background behavior.

**Dependencies:** Existing UNCalendarNotificationTrigger notification pipeline (v1.0 Phase 3). Backend proxy from C.1. BGAppRefreshTask (requires "Background fetch" capability in Xcode target). UserDefaults for motivation copy cache.

---

### C.3 AI Anti-Features

| Anti-Feature | Why to Avoid | Better Approach |
|---|---|---|
| Embedding the Anthropic API key in the iOS binary | Extractable from the .ipa; violates Anthropic ToS; enables API cost abuse | Always route through a backend proxy |
| Streaming responses for goal suggestions | Partial JSON is not parseable; streaming adds complexity for a 3-item list | Request full response, render all at once |
| Generating motivation copy on main thread / in View body | Blocks UI; API calls take 1–5 seconds | Always in an async Task, show loading state |
| Showing AI suggestions without a "Not for me" option | Users who don't want a suggestion feel trapped; one-tap dismiss is required | Always offer dismiss per suggestion |
| Using a large model (claude-opus) for simple structured outputs | 10–20x cost vs haiku for the same task | Use claude-haiku-3 for goal suggestions and motivation copy; reserve larger models for complex reasoning if ever needed |
| Regenerating motivation copy on every app open | API cost accumulates; users don't want new copy every time they open the app | Generate once per day (background task), cache in UserDefaults, display cached copy |

---

## Feature Area D: Smart Notifications

### D.1 Tone Adaptation Based on Streak Level

**Classification:** DIFFERENTIATOR

**UX behavior in the wild:** Duolingo's notifications are the gold standard for tone adaptation — the app is famous for its escalating "sad owl" notifications when streaks are at risk. Headspace uses warm, non-urgent copy. Most goal apps use static copy. Tone-adaptive notifications are rare and memorable when done well.

**Expected UX — tone matrix:**

| Streak State | Tone | Example Copy |
|---|---|---|
| 0 (no streak) | Inviting, low pressure | "A fresh start. What's one thing you're working toward today?" |
| 1–6 days | Encouraging, momentum-building | "Day [N] building. Keep showing up — it adds up." |
| 7–29 days | Celebratory, proud | "One week strong, [name]. Your [goal title] streak is real." |
| 30+ days | Reverent, community | "30 days. You're in rare company. Don't stop now." |
| Streak just broken | Compassionate, not punishing | "Yesterday didn't happen. Today is a new streak. Ready?" |
| Streak at risk (evening) | Urgent but warm | "Your [N]-day streak ends at midnight. 5 minutes is enough." |

**Implementation:** The notification scheduler reads the current streak count from UserDefaults (written by the app at each check-in via the existing WidgetDisplayData path). A `NotificationCopyGenerator` struct maps streak state to a copy variant. No API call required for tone selection — it is a local switch statement over streak ranges. This feature is pure logic, no network dependency.

**Complexity:** Low. This is a local switch statement and string interpolation. The existing notification scheduling code (Phase 3) already references goal titles. Extend it to also read the streak count and select a copy variant. The tone matrix copy needs to be written (UX copywriting work, not code complexity).

**Dependencies:** Streak count in UserDefaults (written by streak engine at check-in). Existing UNCalendarNotificationTrigger scheduling (v1.0 Phase 3). Goal titles in UserDefaults/WidgetDisplayData (existing).

---

### D.2 Content References Actual Goal Titles

**Classification:** TABLE STAKES

**UX behavior in the wild:** The v1.0 notification already includes goal titles ("Here are your goals for today: [list]"). This feature extends that pattern to make the title feel less like a list and more like a personal message. The research finding is clear: notifications that contain the user's actual data (name, specific goal name, specific number) have 2–3x higher open rates than generic copy.

**Expected UX:** Instead of listing all goals, pick the single highest-priority active goal (top-tier, longest streak, or most recently checked in — configurable heuristic). The notification body references it by name: "Your 'Write every morning' goal is calling." or "Day 7: Keep showing up for 'Run 3 miles a week'."

**Heuristic for goal selection:** Use the goal with the highest streak count as the "hero goal" for the notification. If tied, use the goal at the highest tier. This heuristic is simple, local, and does not require AI.

**Complexity:** Low. The goal selection heuristic is a sort + first() operation over the goals array. The notification body template is a String interpolation. This is a refinement of the existing Phase 3 notification code, not a new feature.

**Dependencies:** Goal model with streak data. Existing notification scheduling (v1.0 Phase 3). UserDefaults/WidgetDisplayData for quick access at notification schedule time.

---

### D.3 Send Time Adaptation Based on Check-In Patterns

**Classification:** DIFFERENTIATOR

**UX behavior in the wild:** This is genuinely rare in iOS apps because it requires storing historical check-in times and computing an optimal send window — most apps offer a manual time picker (which Vitamin G already has from v2.0). Apps like Finch (self-care app) adaptively suggest new nudge times based on when the user is most active. The pattern is: observe when the user actually opens the app and checks in, then suggest moving the notification time to match.

**Expected UX:** After 7+ days of check-in history, the app computes the most common hour of check-in. If the user's check-ins cluster at 7 AM but their nudge time is set to 8 AM, show a banner: "We noticed you usually check in around 7 AM. Move your nudge to 7 AM?" with "Update" and "Keep 8 AM" buttons. This is a suggestion, not an automatic change — the user remains in control.

**Implementation:** At each check-in, record the hour (`Calendar.current.component(.hour, from: Date())`) in a small array stored in UserDefaults (rolling 14-day window, store as `[Int]`). After 7 data points, compute the mode (most frequent hour). If the mode differs from the current nudge time by 2+ hours, surface the suggestion banner.

**Complexity:** Low-Medium. The hour tracking is a UserDefaults array append. The mode computation is a `Dictionary(grouping:)` + `max(by:)` — ~5 lines. The UI banner is a conditional SwiftUI view on the Home tab. The only subtlety is the trigger logic: only suggest once, don't re-suggest if dismissed, don't suggest if the user has already manually set their time recently.

**Dependencies:** Check-in timestamps (CompletionEvent records from Phase 3, or a lighter UserDefaults rolling array for just the hours). Existing notification scheduling (v1.0 Phase 3). Notification time setting UI (v2.0 feature 11.1).

---

### D.4 Streak-at-Risk Evening Alert

**Classification:** TABLE STAKES

**UX behavior in the wild:** Duolingo's evening "Don't lose your streak" notification is its most impactful retention tool. Habitica sends evening reminders for incomplete quests. The pattern: fire at 7–8 PM if the user has an active streak and has not checked in today. This is the single highest-ROI notification a streaks-based app can send.

**Expected UX:** An additional notification (separate from the morning nudge) scheduled dynamically each morning: "if the user has not checked in by 7 PM, fire a streak-at-risk alert." The alert: title "Your [N]-day streak ends at midnight." body "[Goal name] is waiting. Just tap once." action button (if the app is in foreground when the notification fires, the action dismisses and opens the check-in flow).

**Implementation challenge:** Local notifications cannot be conditionally fired ("only if X has not happened"). The workaround: schedule the evening alert every morning. When the user checks in, cancel the pending evening notification via `UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streak-at-risk"])`. This cancel-on-check-in pattern is well-established in iOS apps with streak protection mechanics.

**Notification identifier:** Use a fixed identifier `"streak.at-risk.evening"` so the same notification slot can be cancelled and rescheduled each day without accumulating pending notifications.

**Streak threshold for firing:** Only fire the evening alert if the current streak is >= 3 days. A 1–2 day streak is not emotionally significant enough to justify an extra notification. A 3+ day streak has enough sunk cost to motivate action.

**User experience:** The user should not receive two notifications on days they have already checked in. The cancel-on-check-in logic is mandatory, not optional.

**Complexity:** Low-Medium. The scheduling and cancellation logic is ~20 lines. The notification content is a string interpolation over streak count and goal title. The main complexity is testing: need to verify the cancel-on-check-in works correctly when the app is backgrounded, when the user checks in via the widget, and when the user checks in via the Watch (Watch check-in must also trigger the phone-side cancel).

**Dependencies:** Streak count at check-in time. CompletionEvent records (to know if user has checked in today). Existing notification scheduling (v1.0 Phase 3). Watch check-in (A.3) — Watch check-in must send a cancel signal to the phone.

---

### D.5 Smart Notification Anti-Features

| Anti-Feature | Why to Avoid | Better Approach |
|---|---|---|
| More than 2 notifications per day | App Store Review Guideline 4.5.4; iOS 15+ notification summary groups can hide even 2; more = churn risk | Maximum 2: morning nudge + evening streak-at-risk (only if not checked in) |
| Sending streak-at-risk for streaks of 0–2 days | Not emotionally compelling; feels nagging rather than protective | Only fire for streaks >= 3 days |
| Automatically changing the user's nudge time without consent | Users feel violated when apps change their settings | Always ask first; never auto-change |
| Using `.timeSensitive` interruption level for morning nudge | Time-sensitive breaks Focus mode; morning nudge is not an emergency | Use `.active` (default) for morning nudge; `.timeSensitive` is appropriate only for the streak-at-risk alert if streak >= 30 days |
| Scheduling evening alert without cancelling on check-in | User who checks in at noon still gets a "your streak is at risk" at 7 PM — confusing and trust-eroding | Cancel-on-check-in is mandatory |

---

## v3.0 Feature Classification Summary

| Feature | Classification | Complexity | New Infrastructure? |
|---------|---------------|------------|---------------------|
| A.1 Streak complication | TABLE STAKES | Medium | WatchKit target (new) |
| A.2 Active goal + progress ring complication | TABLE STAKES | Medium | WatchKit target (shared from A.1) |
| A.3 Check-in from wrist | DIFFERENTIATOR | High | WatchConnectivity bridge |
| A.4 Morning nudge to Watch | TABLE STAKES | Low | None (automatic delivery) |
| B.1 Streak history chart | TABLE STAKES | Medium | None |
| B.2 Completion rate trends chart | TABLE STAKES | Medium | None |
| B.3 All-time goal heatmap | DIFFERENTIATOR | Medium-High | None |
| B.4 CSV export | TABLE STAKES | Low | None |
| C.1 Goal suggestions (AI) | DIFFERENTIATOR | High | Backend proxy (new) |
| C.2 Daily motivation copy (AI) | DIFFERENTIATOR | High | Backend proxy (shared from C.1) |
| D.1 Tone adaptation | DIFFERENTIATOR | Low | None |
| D.2 Goal title in notifications | TABLE STAKES | Low | None |
| D.3 Send time adaptation | DIFFERENTIATOR | Low-Medium | None |
| D.4 Streak-at-risk evening alert | TABLE STAKES | Low-Medium | None |

---

## v3.0 Feature Dependency Map

```
Apple Watch
  A.1 Streak complication ──────────────────── WatchKit target (NEW) + WatchConnectivity
  A.2 Progress ring complication ───────────── A.1 (same target) + Phase 24 WidgetDisplayData
  A.3 Check-in from wrist ──────────────────── A.1 + WatchConnectivity bridge + GoalViewModel
    └── D.4 Streak-at-risk ───────────────────── A.3 must cancel evening notification on Watch check-in
  A.4 Morning nudge to Watch ───────────────── Existing UNCalendarNotificationTrigger (v1.0 Phase 3)
    └── Optional: WatchKit notification UI ───── A.1 WatchKit target

Analytics
  B.1 Streak history chart ─────────────────── CompletionEvent records (v1.0 Phase 3) + Swift Charts
  B.2 Completion rate trends ───────────────── CompletionEvent + Goal creation dates + Swift Charts
  B.3 All-time heatmap ─────────────────────── CompletionEvent records + existing heatmap color logic
  B.4 CSV export ───────────────────────────── CompletionEvent + Goal model + ShareLink

AI (Claude)
  C.1 Goal suggestions ─────────────────────── Backend proxy (NEW) + GoalViewModel
  C.2 Daily motivation copy ────────────────── Backend proxy (shared) + BGAppRefreshTask + notification pipeline
    └── C.2 depends on D.2 ───────────────────── Goal title in notification (D.2) is the fallback when AI fails

Smart Notifications
  D.1 Tone adaptation ──────────────────────── Streak count in UserDefaults + existing scheduling (Phase 3)
  D.2 Goal title in notification ───────────── Goal model + existing scheduling (Phase 3)
  D.3 Send time adaptation ─────────────────── Check-in hour history + notification time setter (v2.0 11.1)
  D.4 Streak-at-risk evening alert ─────────── Streak count + existing scheduling + cancel-on-check-in
    └── D.4 cancel must be triggered by ─────── A.3 Watch check-in AND widget check-in AND app check-in
```

---

## v3.0 New Infrastructure Required

| Infrastructure | Purpose | Options | Recommendation |
|---|---|---|---|
| WatchKit app target | Apple Watch app, complications, check-in | Built into Xcode (File > New Target > Watch App) | Required for A.1–A.4 |
| Backend proxy | Route AI requests securely | Cloudflare Worker (free tier), Vercel serverless, AWS Lambda | Cloudflare Worker — zero cold start, free up to 100K req/day, JavaScript |
| BGAppRefreshTask | Generate motivation copy nightly | BGTaskScheduler (built into iOS) | Required for C.2 |

---

## v3.0 Schema Changes Required

| Change | Scope | Migration Path |
|---|---|---|
| No new SwiftData models required for v3.0 | All analytics features read from existing CompletionEvent + Goal models | No schema migration needed |
| `motivationCopyCache: String` + `motivationCopyDate: Date` | UserDefaults (not SwiftData) | No migration — UserDefaults key addition |
| `checkinHourHistory: [Int]` (rolling 14-day) | UserDefaults | No migration — UserDefaults key addition |
| Watch complication data payload | WatchConnectivity `userInfo` dictionary | No SwiftData change — lightweight dictionary |

---

## v3.0 Build Priority Ordering

**Build first — highest value, lowest new infrastructure risk:**
1. D.2 Goal title in notifications (refinement of existing v1.0 code, near-zero effort)
2. D.1 Tone adaptation (local logic only, no new infra, high perceived intelligence)
3. D.4 Streak-at-risk evening alert (proven retention tool, Low-Medium complexity)
4. B.4 CSV export (user data ownership, table stakes, Low complexity)
5. B.1 Streak history chart (Swift Charts, local data, Medium complexity)
6. B.2 Completion rate trends (Swift Charts, local data, Medium complexity)

**Build second — watch app (new Xcode target, dedicated sprint):**
7. A.1 Streak complication (foundation of Watch target — must be built before A.2, A.3, A.4)
8. A.4 Morning nudge to Watch (zero code after A.1 target exists; add optional notification UI)
9. A.2 Active goal + progress ring complication (depends on A.1)
10. A.3 Check-in from wrist (highest Watch complexity; build after A.1 and A.2 are stable)

**Build third — AI features (new backend dependency):**
11. Backend proxy (prerequisite for C.1 and C.2 — set up first)
12. C.1 Goal suggestions (backend proxy + structured JSON parsing)
13. C.2 Daily motivation copy (backend proxy + BGAppRefreshTask + notification pipeline)

**Build last — adaptive send time (requires data accumulation):**
14. D.3 Send time adaptation (requires 7+ days of real usage data to validate the suggestion trigger — test with simulated data in development)

---

## Sources

- [Apple Developer Documentation — Creating Accessory Widgets and Watch Complications](https://developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications)
- [Apple Developer Documentation — Transferring Data with Watch Connectivity](https://developer.apple.com/documentation/WatchConnectivity/transferring-data-with-watch-connectivity)
- [Apple Developer Documentation — Go Further with Complications in WidgetKit (WWDC22)](https://developer.apple.com/videos/play/wwdc2022/10051/)
- [Building Interactive Apple Watch Widget — Cocoa Switch](https://www.cocoaswitch.com/2024/12/16/building-interactive-apple.html)
- [SwiftData CloudKit sync on watchOS 10 — Apple Developer Forums](https://developer.apple.com/forums/thread/733397)
- [Data Synchronization Between iOS and watchOS Using WatchConnectivity — Medium](https://medium.com/@sheik25bareeth/data-synchronization-between-ios-and-watchos-using-watchconnectivity-009a3064e12a)
- [Apple Developer Documentation — Swift Charts](https://developer.apple.com/documentation/charts)
- [Mastering Charts Framework in SwiftUI & iOS 18 — Devtechie](https://www.devtechie.com/mastering-charts-framework-in-swiftui-ios-18)
- [API Key Best Practices — Anthropic Help Center](https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure)
- [Anthropic Swift Client Library Examples — AIProxy](https://www.aiproxy.com/docs/swift-examples/anthropic.html)
- [SwiftAnthropic — GitHub (jamesrochabrun)](https://github.com/jamesrochabrun/SwiftAnthropic)
- [25 Best Apple Watch Complications — iPhone Life](https://www.iphonelife.com/content/25-best-apple-watch-complications)
- [Designing Apple Watch Complications — MoldStud](https://moldstud.com/articles/p-the-ultimate-guide-to-designing-complications-for-apple-watch-dos-and-donts)
- [iOS Notifications Complete Developer Guide 2026 — Medium](https://medium.com/@thakurneeshu280/the-complete-guide-to-ios-notifications-from-basics-to-advanced-2026-edition-48cdcba8c18c)
- [Send Communication and Time Sensitive Notifications — WWDC21](https://developer.apple.com/videos/play/wwdc2021/10091/)
- [HabitDaily App Store — CSV Export Feature Reference](https://apps.apple.com/us/app/habit-tracker-habitdaily/id6754026468)
- [Best Habit Tracker Apps 2026 — Reclaim](https://reclaim.ai/blog/habit-tracker-apps)
