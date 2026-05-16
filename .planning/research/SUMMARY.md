# Research Summary — Vitamin G v2.0 Social Growth Engine

**Project:** Vitamin G
**Domain:** iOS social goal/habit tracking app (SwiftUI + SwiftData + CloudKit, iOS 17+)
**Researched:** 2026-05-15
**Milestone:** v2.0 Social Growth Engine
**Confidence:** HIGH

---

## Executive Summary

Vitamin G v2.0 adds a social layer — Explore, Community, Discover tabs, applause reactions, profile photos, tip jar, streak milestones, and content moderation — on top of the existing SwiftData (SchemaV8) + CloudKit private DB architecture. The critical architectural insight from research is that no SwiftData schema migration (SchemaV9) is required for v2.0 if follows, presence, and applause live entirely in the CloudKit public database. SchemaV8 already contains `UserProfile.username` and `UserProfile.photoData`, meaning all new social data fits the existing private schema plus new CK public record types (`UserPresence`, `Applause`, `Follow`, extended `PublicProfile`). This avoids the severe migration risk associated with custom `SchemaMigrationStage` and CloudKit on iOS 17 (pitfalls V2-SD-1 through V2-SD-5).

The recommended build order follows a clear dependency chain: tab restructuring unlocks all other placement decisions; onboarding gates username and photo data being correctly populated before social features expect them; profile photo in the public DB enables correct avatars everywhere; then the social tabs (Explore, Community, Discover) can be built with correct data already flowing. Two features that appear simple are actually regulatory-compliance requirements that must ship together with their infrastructure: profile picture upload requires a report/block/moderation system (App Store Guideline 1.2), and tip jar requires App Store Connect consumable IAP products configured before a single line of purchase UI is written (Guideline 3.1.1). Both have caused real-world App Store rejections.

The single highest-risk assumption in v2.0 is the "live users" feature as originally scoped. Real-time presence via CloudKit heartbeats exceeds CloudKit write quotas at any meaningful user count, drains battery, and requires explicit privacy consent disclosure. Research across all four files unanimously recommends scoping this as "Active Today": one `lastActive` write at app open, display users active within 2 hours. This is the LinkedIn/Strava pattern and is architecturally sound on CloudKit.

---

## Key Findings

### Stack Additions (v2.0 — What Is New)

The existing v1.0 stack (Swift 5.9+, SwiftUI, SwiftData, CloudKit private DB, WidgetKit, App Intents, UserNotifications, `@Observable`, App Groups, XCTest) is unchanged. All v2.0 additions are Apple-first — no third-party dependencies.

**Core new frameworks:**

- **StoreKit 2** (`Product`, `Transaction`, iOS 15+) — Consumable tip jar IAPs. Use `product.purchase()` directly; not `ProductView` if custom tier UI is needed. Requires "In-App Purchase" capability in Xcode and products configured in App Store Connect as Consumable type. Use a `.storekit` configuration file for simulator testing; real-device testing requires sandbox accounts.
- **CloudKit direct API** (`CKDatabase`, `CKRecord`, `CKAsset`, already active) — Profile photo in public DB, username uniqueness checks, `lastActive` timestamp writes, applause records, presence records. SwiftData CloudKit sync only targets the private DB; public DB operations must use the direct `CKDatabase` API.
- **CoreMotion** (`CMMotionManager`, iOS 4+) — Shake detection for the daily goal gifter. One instance per app (singleton service, injected via environment). Requires `NSMotionUsageDescription` in Info.plist. Stop accelerometer updates in `onDisappear` to prevent battery drain.
- **PhotosUI** (`PHPickerViewController`, iOS 14+) — Photo library picker for profile photo. No `NSPhotoLibraryUsageDescription` needed. Must use `loadFileRepresentation` + `CGImageSourceCreateThumbnailAtIndex` to avoid 200 MB+ memory spike from decoding full-resolution HEIC directly.
- **QuartzCore** (`CAEmitterLayer`, iOS 5+) — Confetti animation for achievement celebrations. GPU-accelerated, zero dependencies. Set `birthRate = 0` after 1 second for a burst. Apply `.allowsHitTesting(false)` on the overlay so it does not block the feed.
- **SwiftUI `.preferredColorScheme()`** + `@AppStorage` — In-app dark mode toggle. Store as `"light"` / `"dark"` / `"system"` string. Apply at `WindowGroup` root. Must be read at cold launch to avoid a white flash.

**New Info.plist keys required:**

| Key | Required For |
|-----|-------------|
| `NSMotionUsageDescription` | CoreMotion shake gesture (iOS 17+ crashes without this) |
| `NSCameraUsageDescription` | Camera capture path for profile photo |

`NSPhotoLibraryUsageDescription` is NOT needed for `PHPickerViewController`-only access (iOS 14+).

**New Xcode capability required:**

| Capability | Notes |
|------------|-------|
| In-App Purchase | Must be added before writing any StoreKit code; required for sandbox testing |

---

### Feature Classification — v2.0

**Table stakes (must ship to feel complete):**
- Mood check-in collapsible prompt (Explore, once per day, ephemeral `@AppStorage`)
- Vitamin Shelf 6-category browsing (static data, no CloudKit required)
- Trending Now community goals (CloudKit `participantCount` query)
- Today's Glimpses carousel (Community tab, `TabView` pager, `CKAsset` caching required)
- "Cheers given" counter on public profile
- Active Today indicator (scoped from "live users" — single `lastActive` write at app open, show users active within 2 hours)
- Streak Freeze ("Life happened." — once per week, ISO8601 calendar for Monday reset, `❄️` in heatmap)
- Achievement Unlock screen (7d, 14d, 30d, 60d, 90d, 365d milestones with confetti + community share CTA)
- Goal Completed "You Did It" screen (animated checkmark path, personal confetti, `ShareLink`)
- Search public goals to join (Discover tab, debounced CKQuery, 500ms `Task.sleep` debounce)
- Search profiles to follow (username CKQuery, follow stored in CK public DB as `Follow` record)
- Trending Challenges section (reuses `ChallengeDiscoveryView` from v1.0 Phase 15)
- Tip Jar — tiered consumable IAPs (StoreKit 2, App Store Connect configuration is the hard dependency)
- Notification time picker (quick-select chips + custom `DatePicker`, calls existing v1.0 scheduling logic)
- Permission priming slides for notifications and camera

**Differentiators (set Vitamin G apart):**
- "Shake Out Some Growth" random goal gifter — shake OR "Surprise me" tap (tap fallback is mandatory, not optional — accessibility requirement)
- "3 Gifts for Stuck Days" — curated daily goals seeded by `dayOfYear` so all users see same 3 gifts
- Applause floating reactions — `👏` floats upward with giver's username, SwiftUI `offset`/`opacity` animation, `Applause` CloudKit public record type
- "Glowing This Week" spotlight — deterministic weekly selection via `weekOfYear % eligibleUserCount` (no backend coordinator)

**Confirmed anti-features (do not build as originally scoped):**

| Anti-Feature | Why | Correct Scope |
|---|---|---|
| Real-time "live users" (heartbeat every 30s) | CloudKit write quota exhaustion, battery drain, privacy consent requirement | Single `lastActive` write at app open; show users active within 2 hours ("Active Today") |
| Shake gesture with no tap fallback | Motor disability inaccessibility; VoiceOver users cannot access feature | Always pair shake with visible "Surprise me" button |
| Follow-filtered community feed | N+1 CloudKit query problem; empty state for new users | Keep global feed in v2.0; defer follow filtering to v3.0 |

---

### Architecture Integration Points

**No SchemaV9 required** — SchemaV8 already has `UserProfile.photoData` and `UserProfile.username`. All new social data goes to CloudKit public DB record types. This is the single most important architecture decision in v2.0 — it eliminates the migration risk entirely.

**Tab wiring fix (first code change in v2.0):** `VGTabBar` already has v2.0 labels but `ContentView` tab indices do not match. Index 3 currently points to `ChallengeDiscoveryView`; v2.0 swaps Explore and Community to indices 2/3. The fix is a `Tab` enum with stable string raw values replacing raw `Int` indices.

**Profile photo dual-database pattern:**
1. `UserProfile.photoData` (SchemaV8) already stores photo in private DB via SwiftData sync — already works
2. `ProfileSharingService.publishProfile()` must be extended to write photo as `CKAsset` to `PublicProfile` public DB record
3. `PublicProfileViewModel` must download the `CKAsset` and return `photoData: Data?`
4. `AvatarView` already accepts `photoData: Data?` — only the data flow changes

**New CloudKit public DB record types (must be promoted to Production before shipping):**

| Record Type | Key Fields | Required Queryable Indexes |
|---|---|---|
| `UserPresence` (new) | `username`, `lastSeenAt`, `currentGoalTitle` | `lastSeenAt` |
| `Applause` (new) | `fromUsername`, `toProfileRecordID`, `toUsername`, `createdAt` | `toProfileRecordID`, `createdAt` |
| `Follow` (new) | `fromUserRecordID`, `toProfileRecordID`, `followedAt` | `fromUserRecordID`, `toProfileRecordID` |
| `PublicProfile` (extend) | Add `username (String)`, `photoAsset (CKAsset)` | Add index on `username` |

**New components:** `ExploreTabView`, `ExploreViewModel`, `MotionService` (singleton), `PresenceService`, `LiveUsersViewModel`, `ApplauseService`, `ApplauseViewModel`, `TipJarViewModel`, `TipJarView`, `AboutView`, `UsernameAvailabilityService`, `DiscoverViewModel`, `DiscoverView`

**Modified components:** `ContentView`, `VGTabBar`, `AppRoute`, `ProfileSharingService`, `PublicProfileViewModel`, `ProfileViewModel`, `CommunityTabView`, `OnboardingViewModel`, `VitaminGApp`, `SettingsView`

**Architectural violations to avoid:**
- Do not create `CMMotionManager` per View or ViewModel — one instance in `VitaminGApp`, injected via `.environment`
- Do not put `product.purchase()` in a View — all StoreKit calls go in `TipJarViewModel`
- Do not store applause/presence/follow in SwiftData — these are community-scale records for CloudKit public DB
- Do not use `@Attribute(.unique)` on any property — breaks CloudKit sync silently (project-wide constraint)
- Do not use Combine for debounce in `DiscoverViewModel` — use `Task + Task.sleep` consistent with codebase

---

### Top 5 Pitfalls

**1. Profile photo upload requires content moderation — must ship together (V2-ASR-1, HIGH)**
App Store Guideline 1.2 requires a Report mechanism, Block option, and support contact on any app with user-uploaded photos. Apple's review team actively tests UGC by uploading inappropriate images. For a zero-backend app: implement client-side reporting that writes to a `Reports` CloudKit container monitored manually. Terms and Conditions must state prohibited content. This is not a v2.1 follow-up — it ships with profile pictures or the update is rejected.

**2. PHPhotoPicker memory spike — use `loadFileRepresentation` + `CGImageSourceCreateThumbnailAtIndex` (V2-PP-2, HIGH)**
Calling `loadObject(ofClass: UIImage.self)` on a 48 MP HEIC decodes ~192 MB. With concurrent operations this peaks above 2 GB and the OS kills the app. Fix: `loadFileRepresentation(forTypeIdentifier:)` to get a temp URL, then `CGImageSourceCreateThumbnailAtIndex` with `kCGImageSourceThumbnailMaxPixelSize: 512`. Memory drops from ~200 MB to ~3 MB.

**3. StoreKit 2 — external payment links cause immediate rejection; ASC products must exist before device testing (V2-SK-1, V2-SK-3, HIGH)**
No "Buy Me a Coffee" links anywhere in the app — Guideline 3.1.1 rejections are real and documented. All tips through `Product.purchase()` only. `Product.products(for:)` returns empty on a real device until IAP products are in App Store Connect in "Ready to Submit" state. Configure ASC before writing the tip jar UI. `Transaction.updates` listener must be started at app launch in the `App` struct, not inside the tip jar View.

**4. CKAsset fileURL is a temporary path the OS silently reclaims (V2-CK-IMG-1, HIGH)**
After fetching a record with a `CKAsset`, the asset's `fileURL` points to `~/Library/Caches/CloudKit/Assets/`. The OS deletes this under storage pressure with no notification. Fix: copy asset data immediately on fetch with `Data(contentsOf: asset.fileURL!)` and persist to `Application Support`. Never store the raw `fileURL` for later use.

**5. Tab restructuring — raw Int indices break deep links and widget intents (V2-TAB-1, HIGH)**
v2.0 swaps Explore and Community (indices 2/3). Any `selectedTab = 3` now routes to the wrong tab. Any stored integer in `UserDefaults`, any widget `AppIntent` encoding a tab index, any deep link handler is now wrong. Fix: switch to a `Tab` enum with stable string raw values before building any new tab content. Default to Home if a stored integer does not map to a valid v2.0 tab.

---

## Implications for Roadmap

### Recommended Build Order

Based on architecture research, with cross-cutting pitfall avoidance integrated:

**Phase 1: Tab Restructuring + AppRoute Updates**
Rationale: Prerequisite for every other feature — establishes where each new feature lives. `VGTabBar` labels are already correct; only `ContentView` wiring and `Tab` enum need fixing. Low risk, highest dependency value of any v2.0 change.
Delivers: Correct 5-tab navigation (Home, Goals, Explore, Community, Me), `Tab` enum with stable string raw values, `AppRoute` updated with `explore`/`discover`/`tipJar`/`about` cases, Stats and Wins demoted to NavigationLink destinations.
Avoids: V2-TAB-1 (integer deep link breakage), V2-TAB-2 (existing users losing Stats/Wins without surfaced alternatives).
Research flag: Standard patterns — skip phase research.

**Phase 2: Onboarding Overhaul**
Rationale: Gates username and photo data being populated before any social feature renders. Building Community before onboarding means building against placeholder data.
Delivers: Apple Sign-In only flow, T&C, unique username claim (`UsernameAvailabilityService` CKQuery with `recordName: "username:\(normalizedName)"` as atomic lock), profile photo step (skippable), notification + camera permission priming slides.
Avoids: V2-UN-1 (username race condition), V2-UN-2 (normalize before uniqueness check), V2-ASR-2 (camera permission must not gate onboarding completion).
Research flag: Standard patterns — skip phase research.

**Phase 3: Public Profile Photo Pipeline**
Rationale: Correct avatars must exist before Community tab social features are built. All social UI displays initials-circle placeholders until this ships, making end-to-end QA impossible.
Delivers: `ProfileSharingService.publishProfile()` extended with `CKAsset` write; `PublicProfileViewModel` returns `photoData: Data?`; CloudKit Console `PublicProfile` record type extended; content moderation infrastructure (Report + Block on every public profile view).
Avoids: V2-CK-IMG-1 (copy asset data immediately, never store fileURL), V2-CK-IMG-2 (resize to 512px max, JPEG 0.75 before CKAsset), V2-CK-IMG-3 (deploy CK schema to Production before TestFlight), V2-PP-2 (`loadFileRepresentation` + `CGImageSourceCreateThumbnailAtIndex`), V2-ASR-1 (moderation ships with photos — not a follow-up).
Research flag: Needs attention — CloudKit public DB quota architecture (photo in private DB referenced by `recordName` vs `CKAsset` in public DB) must be decided before record type is defined.

**Phase 4: Home Tab Completion**
Rationale: Completes the primary daily driver. Stats and Wins accessible from Home as NavigationLink destinations — no functionality removed for existing users.
Delivers: Full dashboard with streak, quote of day, primary goal card, daily check-in, Stats and Wins as destinations. `WidgetCenter.shared.reloadAllTimelines()` wired to all goal state changes.
Research flag: Standard patterns — skip phase research.

**Phase 5: Goals Flow Enhancements**
Rationale: Enriches goal creation and management. Builds on existing `GoalCreationWizardViewModel`.
Delivers: "Need ideas" integration, goal detail with per-goal streak and flame, goal completion trigger for "You Did It" screen.
Research flag: Standard patterns — skip phase research.

**Phase 6: StoreKit 2 Tip Jar**
Rationale: Placed early because App Store Connect IAP configuration has a lead time. Consumable products must be in "Ready to Submit" state before any real-device testing.
Delivers: `TipJarViewModel` (all purchase logic), `TipJarView` (3 tier cards), `AboutView` (entry point), `Transaction.updates` listener started at app launch in `VitaminGApp`, `.storekit` configuration file for simulator, sandbox test accounts established.
Avoids: V2-SK-1 (no external payment links), V2-SK-2 (consumable type = no Restore button required), V2-SK-3 (ASC config before any device test), V2-SK-4 (`Transaction.updates` at app launch, not in View).
Research flag: Standard patterns — skip phase research. Risk is in ASC configuration, not code.

**Phase 7: Dark Mode Toggle**
Rationale: Two-line change to `VitaminGApp` + SettingsView picker. Zero risk, no dependencies on other v2.0 phases.
Delivers: `@AppStorage("vg_colorSchemeOverride")` read at cold launch, `.preferredColorScheme()` on `WindowGroup` root, Settings picker with System/Light/Dark.
Avoids: V2-DM-1 (no deprecated `UIApplication.shared.windows`), V2-DM-2 (preference applied at cold launch, not only on toggle).
Research flag: Standard patterns — skip phase research.

**Phase 8: Explore Tab**
Rationale: Tab index correct from Phase 1. All content is static/local or CloudKit read-only. No write infrastructure required from prior phases.
Delivers: `ExploreTabView` + `ExploreViewModel`, `MotionService` singleton (injected at `VitaminGApp` init), shake goal gifter with mandatory "Surprise me" tap fallback, feelings mood prompt (once per day), Vitamin Shelf 6-category grid, "3 Gifts for Stuck Days" (seeded by `dayOfYear`), Trending Now goals.
Avoids: V2-CM-1 (stop accelerometer in `onDisappear`), V2-CM-2 (CMMotionManager in ViewModel, not UIKit responder chain).
Research flag: Standard patterns — skip phase research.

**Phase 9: Community Tab Redesign**
Rationale: Depends on correct avatars from Phase 3 and Applause CK record type being deployed. Highest data-complexity phase in v2.0.
Delivers: Today's Glimpses carousel (`TabView` pager, `Timer.publish(every: 5)`, `CKAsset` caching), Active Today section (`PresenceService` writes `lastActive` at app open, `LiveUsersViewModel` queries active-within-2-hours users), `ApplauseService` + `ApplauseViewModel` + floating label SwiftUI animation (max 3 concurrent emitters), "Glowing This Week" spotlight (deterministic `weekOfYear % eligibleCount`), Discover entry point.
Avoids: V2-LP-1 (public DB = direct `CKDatabase` API, not SwiftData `@Query`), V2-LP-2 (polling when view visible, not push subscriptions as primary), V2-ANIM-1 (max 3 emitters, remove after 2s), V2-ANIM-2 (`.allowsHitTesting(false)` on all overlays).
Research flag: Needs attention — CKAsset caching strategy and `lastSeenAt` threshold should be validated against CloudKit quota estimates.

**Phase 10: Public Profile + Follow/Cheer**
Rationale: Depends on Applause system from Phase 9 (the cheer button uses `ApplauseService`) and correct avatars from Phase 3.
Delivers: `PublicProfileView` redesign with avatar, username, streak, "Cheers given" counter, `👏 Cheer them on today` button (once-per-day via pre-write CKQuery), Follow button (writes `Follow` record to CK public DB, simple Option 1 — no feed filtering in v2.0).
Research flag: Standard patterns — skip phase research.

**Phase 11: Discover Page**
Rationale: Depends on CloudKit queryable indexes on `username` and goal title fields added during Community phase. Querying unindexed fields returns unpredictable results.
Delivers: `DiscoverView` + `DiscoverViewModel`, debounced CKQuery (500ms `Task.sleep`), `CONTAINS[cd]` substring matching for Goals and People, "Join" action via `GoalViewModel.addGoal()`, Trending Challenges section (reuses `ChallengeDiscoveryView`).
Research flag: Standard patterns — skip phase research.

**Phase 12: Streak Freeze, Achievement Celebrations, Notification Picker**
Rationale: Polish layer — no new architecture. Extends existing streak engine and `MilestoneCelebrationView`. Grouped because all three are low-risk feature completions with no new dependencies.
Delivers: Streak Freeze sheet (ISO8601 `weekOfYear` for Monday reset, `❄️` glyph in heatmap), Achievement Unlock screen (full-screen `CAEmitterLayer` confetti, community share CTA), Goal Completed "You Did It" screen (animated `trim` checkmark, `ShareLink`), Notification time picker (quick-select chips + `DatePicker`).
Avoids: Using `.gregorian` calendar — must use `Calendar(identifier: .iso8601)` for Monday-start week reset.
Research flag: Standard patterns — skip phase research.

**Phase 13: Widget Enhancements**
Rationale: Last because widgets are read-only consumers of SwiftData, and schema is now stable. `WidgetDataProvider` extended for v2.0 data surfaces.
Delivers: Widget extensions for new data surfaces, `WidgetCenter.shared.reloadAllTimelines()` wired to all new v2.0 goal state changes.
Avoids: V2-SD-3 (widget's `ModelContainer` must reference same schema via shared helper file included in both targets).
Research flag: Standard patterns — skip phase research.

---

### Phase Ordering Rationale

- Tab restructuring is Phase 1 because every feature's UI placement depends on correct tab routing; the `Tab` enum also eliminates the deep link regression risk for all subsequent phases.
- Onboarding precedes social features because username and photo data flows into every social surface.
- Profile photo precedes Community because correct avatars are load-bearing for end-to-end QA.
- Tip jar is Phase 6 specifically for App Store Connect lead time — IAP products cannot be tested on real devices until they exist in ASC.
- Discover follows Community because CloudKit queryable indexes on `username` and goal title fields are created during Community setup.
- Widgets are last because they are read-only consumers; placing them last ensures the schema they read is fully stable.

---

### Research Flags

**Needs phase-level research:**
- Phase 3 (Profile Photo): CloudKit public DB quota architecture — private DB photo referenced by `recordName` vs full `CKAsset` in public DB. Quota impact at scale matters; this decision must be made before the `PublicProfile` record type is finalized (CloudKit schema is add-only in Production, so getting the field type wrong requires a new field name).
- Phase 9 (Community Tab): CKAsset image caching strategy (`URLCache` vs simple `[fileURL: UIImage]` dictionary vs `Application Support` persistence) and `lastSeenAt` threshold window validation against CloudKit write quota estimates.

**Standard patterns (skip phase research):**
All other phases — Phase 1, 2, 4, 5, 6, 7, 8, 10, 11, 12, 13. Well-documented Apple frameworks, established patterns, or direct extensions of v1.0 work with no new architectural unknowns.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All v2.0 additions from Apple official docs and WWDC sessions. No third-party dependencies means no version uncertainty. |
| Features | MEDIUM-HIGH | Patterns sourced from Duolingo, Strava, Habitica, BeReal, Apple HIG. Anti-feature verdict on "live users" is well-supported by CloudKit quota documentation. |
| Architecture | HIGH | Analysis is specific to the existing codebase (SchemaV8, `ProfileSharingService`, `AvatarView`). No-SchemaV9 verdict is a concrete decision with documented rationale across all four research files. |
| Pitfalls | HIGH | Sourced from Apple Developer Forums (with Apple engineer responses), official App Store Review Guidelines, and documented real-world rejections. All HIGH-severity pitfalls have specific prevention steps. |

**Overall confidence:** HIGH

### Gaps to Address During Execution

- **CloudKit public DB quota for profile photos:** Research flags both "CKAsset in public DB" and "private DB photo referenced by `recordName`" as valid. Decision must be made in Phase 3 before defining the `PublicProfile` record type — changing storage location after Production deployment requires a new field name.
- **Content moderation implementation scope:** Guideline 1.2 requires Report/Block but does not prescribe the mechanism. CloudKit `Reports` record type vs email mailto link vs in-app form — implementation approach must be decided in Phase 3 before profile photo ships.
- **Username race condition UX cost:** The post-save verification query (re-fetch `recordName`, verify `creatorUserRecordID` matches current user) mitigates the TOCTOU race but adds a network round-trip to the username claim flow. Validate UX impact during Phase 2.
- **CoreMotion vs UIKit shake on-device tuning:** `CMMotionManager` threshold (2.5g) was documented in research but not device-tested. If false-positive rate is too high (bumpy surfaces, phone set down sharply), UIKit `motionEnded` should be evaluated as a fallback — it includes OS-level debouncing.

---

## Sources

### Primary (HIGH confidence — Apple official)
- [StoreKit 2 — Apple Developer Documentation](https://developer.apple.com/storekit/)
- [App Store Review Guidelines — Apple Developer](https://developer.apple.com/app-store/review/guidelines/)
- [CKAsset — Apple Developer Documentation](https://developer.apple.com/documentation/cloudkit/ckasset)
- [PHPickerViewController — Apple Developer Documentation](https://developer.apple.com/documentation/PhotosUI/PHPickerViewController)
- [CMMotionManager — Apple Developer Documentation](https://developer.apple.com/documentation/coremotion/cmmotionmanager)
- [CAEmitterLayer — Apple Developer Documentation](https://developer.apple.com/documentation/quartzcore/caemitterlayer)
- [preferredColorScheme — Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/view/preferredcolorscheme(_:))
- [NSCameraUsageDescription — Apple Developer Documentation](https://developer.apple.com/documentation/BundleResources/Information-Property-List/NSCameraUsageDescription)
- [Explore enhancements to App Intents — WWDC23](https://developer.apple.com/videos/play/wwdc2023/10103/)

### Secondary (HIGH confidence — verified community)
- [Using PHPickerViewController Images in a Memory-Efficient Way — Christian Selig](https://christianselig.com/2020/09/phpickerviewcontroller-efficiently/)
- [Working with Images in CloudKit — Frozen Fire Studios](https://medium.com/frozen-fire-studios/working-with-images-in-cloudkit-1e3579c67558)
- [Implementing a Tip Jar with Swift and SwiftUI — Ben Cardy](https://bencardy.co.uk/2023/02/17/implementing-a-tip-jar-with-swift-and-swiftui/)
- [My Ongoing Battle with Apple Over a Buy Me a Coffee Link — Robert Baer](https://medium.com/@robert-baer/my-ongoing-battle-with-apple-over-a-buy-me-a-coffee-link-is-over-9c158df81c05)
- [Best way to handle unique values with SwiftData and CloudKit — Hacking with Swift Forums](https://www.hackingwithswift.com/forums/swiftui/best-way-to-handle-unique-values-with-swiftdata-and-cloudkit/30145)
- [SwiftData custom migration crash — Apple Developer Forums](https://developer.apple.com/forums/thread/758874)
- [Five Reasons CloudKit Notifications Are Not Arriving — Cocoacasts](https://cocoacasts.com/five-reasons-cloudkit-notifications-are-not-arriving)
- [Designing Streaks for Long-Term User Growth — Trophy](https://trophy.so/blog/designing-streaks-for-long-term-user-growth)
- [Mastering StoreKit 2 — Swift with Majid](https://swiftwithmajid.com/2023/08/01/mastering-storekit2/)
- [Deploy CloudKit-backed SwiftData entities to production — Leo Kwan](https://www.leojkwan.com/swiftdata-cloudkit-deploy-schema-changes/)
- [Designing Streak System: UX and Psychology — Smashing Magazine](https://www.smashingmagazine.com/2026/02/designing-streak-system-ux-psychology/)

---

*Research completed: 2026-05-15*
*Milestone: v2.0 Social Growth Engine*
*Ready for roadmap: yes*
