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
