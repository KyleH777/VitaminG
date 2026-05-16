# Architecture: VitaminG v2.0 Feature Integration

**Milestone:** v2.0 Social Growth Engine
**Researched:** 2026-05-15
**Scope:** How new v2.0 features integrate with existing MVVM + SwiftData (SchemaV1–V8) + CloudKit architecture

---

## Existing Architecture Snapshot (v1.0)

- **Navigation:** `AppRouter` (@Observable) + `AppRoute` (Hashable enum) + `VGTabBar` (custom, `.toolbar(.hidden)` pattern)
- **Tab state:** `ContentView` owns `@State private var selectedTab: Int`; VGTabBar is a `safeAreaInset`
- **Current tab wiring (ContentView, v1.0 HEAD):**
  - 0 → HomeView (NavigationStack)
  - 1 → GoalListView (NavigationStack, uses `router.path`)
  - 2 → CommunityTabView (NavigationStack)
  - 3 → ChallengeDiscoveryView (NavigationStack, owns its own `NavigationPath`)
  - 4 → ProfileView (NavigationStack)
- **VGTabBar labels (v1.0 HEAD):** Home · Goals · Community · Explore · Me
- **CloudKit:** Private DB via SwiftData `ModelConfiguration`; Public DB via direct `CKContainer.default().publicCloudDatabase` calls in `CommunityService` + `ProfileSharingService`
- **Schema:** SchemaV8; `UserProfile` is the singleton local model (1 per device); `UserProfile.username` added in V8
- **AvatarView:** Accepts `photoData: Data?`; renders `UIImage` if non-nil, initials circle otherwise
- **ProfileViewModel:** Handles photo selection via `PhotosPickerItem`, compresses to JPEG ≤200KB, stores in `UserProfile.photoData` (private SwiftData / iCloud private DB)

---

## Feature-by-Feature Integration Analysis

---

### 1. Tab Restructuring: Goals · Stats · Wins · Challenges · Profile → Home · Goals · Explore · Community · Profile

**Observation:** The v1.0 HEAD code already has the v2.0 tab *labels* in VGTabBar (Home, Goals, Community, Explore, Me), but the *content wiring* does not match v2.0 intent. Specifically, index 3 points to `ChallengeDiscoveryView` (labeled "Explore") and index 2 points to `CommunityTabView`. The v2.0 spec swaps these: Explore (new tab with shake/feelings/trending) is index 2 and Community (redesigned) is index 3. Wins and Stats are no longer top-level tabs — they become routable destinations.

**What happens to Stats, Wins, Challenges?**
- `StatsView` — demote to a routable sub-page. Natural home: reachable from `HomeView` via a "See Stats" card or from `ProfileView`. Add `AppRoute.stats` navigation to HomeView's NavigationStack.
- `DailyWinsView` — demote to a routable sub-page under `GoalListView` or reachable from the Home tab's daily check-in flow. `AppRoute.wins` already exists and is wired in the Goals tab's `NavigationDestination`.
- `ChallengeDiscoveryView` — becomes the **Discover** page (index 2 in v2.0? or a sub-tab within Community). Per the v2.0 spec, Discover is a page reachable from Community (search public goals/profiles, trending challenges). It can remain a `NavigationLink` destination within the Community tab rather than a top-level tab.

**Concrete changes required:**
- **Modified:** `ContentView` — rewire tabs 2, 3; update `NavigationDestination` blocks
- **Modified:** `VGTabBar` — relabel: index 2 = "Explore" (sparkles icon), index 3 = "Community" (person.2); adjust SF Symbol names
- **Modified:** `AppRoute` — add `case explore`, `case discover`, `case home`; verify `case stats` is still routable
- **Modified:** `AppRouter` — no structural change; `pendingPublicProfileRecordID` and `pendingChallengeCheckInID` remain
- **New:** `ExploreTabView` — root of the new Explore tab (index 2)
- **Modified:** `CommunityTabView` — redesign (new "Today's glimpses", live users, applause sections)
- **No schema change required** for tab restructuring alone

**Build order dependency:** Tab restructuring is a prerequisite for all other feature work — it establishes where each new feature lives.

---

### 2. Profile Picture Upload: CloudKit Storage Location + AvatarView Integration

**Storage decision: CloudKit private DB (via SwiftData iCloud sync), NOT the public DB.**

Rationale: `UserProfile.photoData` (type `Data?`) already exists in SchemaV8 and syncs automatically through the SwiftData CloudKit private container. `ProfileViewModel.handlePhotoSelection()` already compresses to JPEG ≤200KB and writes to `profile?.photoData`. The photo is already stored in the private iCloud DB through the SwiftData sync path.

**What is NOT done yet:**
- The onboarding flow does not include a photo selection step
- The public `PublicProfile` CloudKit record (in the public DB) currently stores only `displayName` and `avatarColorHex` — it does NOT include the photo
- For the Community and public profile views where *other users* see someone's photo, the photo must be readable by others — which means the **public DB** must store the photo as a `CKAsset`

**Full picture for v2.0 profile photo:**
1. User selects photo → `ProfileViewModel.handlePhotoSelection()` (existing) → stored in `UserProfile.photoData` (private DB, local + iCloud private sync) — ALREADY WORKS
2. When user makes profile public → `ProfileSharingService.publishProfile()` must be extended to upload the photo as a `CKAsset` to the `PublicProfile` public DB record
3. When other users view a public profile → `PublicProfileViewModel.fetchProfile()` must be extended to download the `CKAsset` and decode to `Data`
4. `AvatarView` already accepts `photoData: Data?` — no API change required, only data flow

**Modified components:**
- `ProfileSharingService.publishProfile()` — add `photoData: Data?` parameter; write as `CKAsset` to temp file, attach to record; existing field allowlist pattern must explicitly include this field
- `ProfileSharingService.fetchProfile()` — return `photoData: Data?` in addition to existing fields; download asset synchronously
- `PublicProfileViewModel` — update `ViewState.loaded` to include `photoData: Data?`
- `ProfileViewModel.toggleProfilePublic()` — pass `profile.photoData` to updated `publishProfile()`
- Onboarding flow — add `PhotosPicker` step (new `OnboardingPhotoScreen`); call existing `handlePhotoSelection()` from onboarding

**No schema change needed.** `UserProfile.photoData` already exists in SchemaV8.

**Security note:** CloudKit `CKAsset` files in the public DB are publicly readable by any CloudKit-authenticated user — this is correct behavior for a public profile photo. The existing `InputSanitizer` field allowlist in `ProfileSharingService` must be explicitly documented to allow `photoAsset`.

---

### 3. Unique Username Enforcement

**Constraint confirmed:** `@Attribute(.unique)` is explicitly banned for CloudKit sync (per CLAUDE.md and PROJECT.md). This is not a v2.0 constraint — it was established in v1.0.

**Correct pattern — application-level duplicate detection:**

Username uniqueness requires a two-step check against the CloudKit public DB before the user can claim a username:

1. **Local validation** (already exists in `ProfileViewModel.usernameValidationError`): format check (lowercase, digits, underscores, ≤30 chars)
2. **Remote availability check** (new): query CloudKit public DB `PublicProfile` records for `username == draftUsername`; if any record found, reject with "Username already taken"
3. **Write with conflict detection** (race condition mitigation): after confirming availability, write the username to the `PublicProfile` record and attempt to save. If another user claims it between check and write (TOCTOU), handle `CKError.serverRecordChanged` by re-running the availability check and returning the conflict error.

**CloudKit query for username check:**
```swift
let predicate = NSPredicate(format: "username == %@", candidate)
let query = CKQuery(recordType: "PublicProfile", predicate: predicate)
let results = try await db.records(matching: query, resultsLimit: 1)
```
This requires adding a `username` field to the `PublicProfile` CK record type and adding a queryable index on `username` in CloudKit Dashboard.

**Schema change:** `PublicProfile` CloudKit record type (not SwiftData schema) needs a new `username` field. `UserProfile.username` (SwiftData) already exists from SchemaV8. No new SwiftData migration required.

**New components:**
- `UsernameAvailabilityService` (new enum, mirrors `ProfileSharingService` pattern) — `checkAvailability(username:) async throws -> Bool`; `reserveUsername(username:, recordID:) async throws`

**Modified components:**
- `ProfileViewModel` — add `checkAndSaveUsername(context:) async` that calls local validation then remote check; expose `isCheckingUsername: Bool` and `usernameIsAvailable: Bool` state
- `ProfileSharingService.publishProfile()` — include `username` field in the public record write
- Onboarding — add username step; call `ProfileViewModel.checkAndSaveUsername()` before allowing "Continue"

**Build order dependency:** Username must be stored in the public DB before unique enforcement is meaningful. Enforce that onboarding writes the public record at username claim time.

---

### 4. StoreKit 2 Tip Jar: Architecture Placement

**Purchase logic location:** A new `TipJarViewModel` (@Observable, @MainActor) — consistent with all existing ViewModels. Business logic in ViewModel, zero purchase code in Views.

**No SwiftData model needed.** Consumable tip purchases do not need local persistence. StoreKit 2 provides `Transaction.currentEntitlements` and `Transaction.updates` for receipt validation; consumable transactions are finished immediately after acknowledgment. There is nothing to store.

**UserDefaults (optional):** For a "thank you" flag (did the user ever tip?), a single `@AppStorage("vg_hasTipped") var hasTipped = false` in the ViewModel or the View is sufficient. This is purely cosmetic (to show a "thank you" message instead of the tip buttons) and does not affect entitlement logic.

**New components:**
- `TipJarViewModel` — `@Observable @MainActor final class`
  - `var products: [Product] = []` — loaded via `Product.products(for: tipProductIDs)`
  - `var isPurchasing: Bool = false`
  - `var purchaseError: String? = nil`
  - `func loadProducts() async` — calls `Product.products(for:)`
  - `func purchase(_ product: Product) async` — calls `product.purchase()`, switches on `.verified` result, calls `transaction.finish()`
  - `var tipProductIDs: [String]` — hardcoded array of App Store Connect product IDs (e.g. `["vg_tip_small", "vg_tip_medium", "vg_tip_large"]`)
- `TipJarView` — new View (navigated to from About page)
- `AboutView` — new View (in Profile tab Settings section or accessible from Profile)

**Modified components:**
- `AppRoute` — add `case tipJar`, `case about`
- Settings section in `ProfileView` or new `SettingsView` extension

**StoreKit configuration:** Requires `.storekit` configuration file for development/preview testing. No backend. No RevenueCat or similar — raw StoreKit 2 is sufficient for a tip jar.

**App Store Review note:** Apple requires a "Restore Purchases" button for non-consumable products. Tip jars are consumable — restore is not required, but Apple may ask for one anyway. Add a `Transaction.currentEntitlements` check as a courtesy restore path.

---

### 5. "Live Users" Presence: CloudKit Public DB Approach

**Constraint:** No background push server. CloudKit subscriptions require APNs registration but no custom server.

**Honest assessment:** True real-time presence (sub-5-second staleness) is not achievable with CloudKit alone on iOS without a persistent connection (WebSocket) or silent push with high delivery reliability. CloudKit silent push notifications are "best-effort" — Apple explicitly does not guarantee delivery timing.

**Achievable approach — heartbeat polling with short TTL records:**

1. On app foreground, write/update a `UserPresence` record in the CloudKit public DB:
   - `recordType: "UserPresence"`
   - `fields: userDisplayName (String), username (String), currentGoalTitle (String?), lastSeenAt (Date), deviceToken (String — optional, for dedup)`
   - `recordName: derived from userID or device token (stable per device)`
2. On app background/terminate, write a `lastSeenAt` timestamp that is clearly in the past — no explicit "offline" record needed; records older than N minutes are considered offline
3. On Community tab appear, fetch `UserPresence` records where `lastSeenAt > now - 5 minutes`, limit 20
4. Poll on a timer (`Timer.publish(every: 60)`) while the Community tab is visible — this is acceptable because the user is actively on screen
5. Write own heartbeat every 30 seconds while on-screen

**Freshness:** With 60-second polling and 5-minute TTL window, "live users" will be 0–60 seconds stale. Acceptable for a social feature with this product's scale.

**New components:**
- `PresenceService` (new enum, mirrors `CommunityService`) — `func heartbeat(profile: UserProfile) async throws`, `func fetchLiveUsers(limit: Int) async throws -> [CKRecord]`
- `LiveUsersViewModel` (@Observable, @MainActor) — `var liveUsers: [CKRecord] = []`, `var isLoading: Bool`, polling timer logic in `startPolling()` / `stopPolling()`

**Modified components:**
- `CommunityTabView` — add LiveUsers section, inject `LiveUsersViewModel`

**CloudKit schema (not SwiftData):** New `UserPresence` record type in public DB with queryable index on `lastSeenAt`.

**No SwiftData model.** Presence is ephemeral — never persisted locally.

**No new SwiftData schema version required.**

---

### 6. Shake Gesture for Daily Goal: CoreMotion MVVM Pattern

**CoreMotion rule:** One `CMMotionManager` instance per app. Do not create one per View. The existing app has no CoreMotion usage, so this is a net-new singleton service.

**Correct placement: shared @Observable service, injected via environment.**

```swift
@Observable
final class MotionService {
    private let manager = CMMotionManager()
    var didShake: Bool = false  // toggled on shake detection
    // ...
}
```

Instantiated once in `VitaminGApp` or `ContentView`, injected via `.environment(motionService)`.

**Shake detection approach:**
- Option A — `CMMotionManager.startDeviceMotionUpdates(to:)` with threshold on `userAcceleration` magnitude (≥2.5g) — clean, no UIKit bridge needed; runs on background queue, publishes via `@MainActor` dispatch
- Option B — Override `UIWindow.motionEnded(_:with:)` — simpler but requires UIKit bridge and a UIViewControllerRepresentable wrapper; not idiomatic in this codebase

Option A is correct for this codebase's pure SwiftUI + @Observable pattern.

**Architecture:**
- `MotionService` detects shake → sets `didShake = true`
- `ExploreTabView` observes `motionService.didShake` → triggers daily goal gifter animation → resets `didShake = false`
- Daily goal gifter logic lives in `ExploreViewModel`, not in `MotionService` (single responsibility)

**New components:**
- `MotionService` (@Observable, singleton, starts/stops CoreMotion updates)
- `ExploreViewModel` (@Observable, @MainActor) — owns daily goal gifter state, "3 gifts" list, feelings prompt state, trending data

**Modified components:**
- `VitaminGApp.init()` — instantiate `MotionService`, inject via `.environment(motionService)`
- `ExploreTabView` (new) — consumes `@Environment(MotionService.self)`

**No SwiftData change.** The daily goal gifter is stateless except for a "already shown today" flag, handled via `@AppStorage("vg_dailyGoalDate") var lastShakeDate: String = ""` in `ExploreViewModel`.

---

### 7. Applause System: CloudKit Record + SwiftUI Animation

**CloudKit record design for applause:**

```
RecordType: "Applause"
Fields:
  - fromUsername: String (sanitized, profanity-filtered)
  - fromDisplayName: String
  - fromAvatarColorHex: String
  - toProfileRecordID: String (references PublicProfile.recordID)
  - toUsername: String (denormalized for query without join)
  - goalTitle: String? (optional — applause on a specific goal)
  - createdAt: Date (set by CloudKit on creation)
```

Queryable index needed on `toProfileRecordID` for per-profile applause feed.

**Applause uniqueness (once/day per giver):** Cannot use CloudKit unique constraints. Enforce at application level: before creating an `Applause` record, query for existing `Applause` where `fromUsername == currentUser AND toProfileRecordID == target AND createdAt > startOfToday`. If found, reject silently or show "Already cheered today."

**Floating username animation in SwiftUI:**

The floating animation is a pure SwiftUI effect — no CloudKit involvement at render time. Pattern:

```swift
// In CommunityViewModel or ApplauseViewModel
struct FloatingLabel: Identifiable {
    let id = UUID()
    let username: String
    var opacity: Double = 1.0
    var offset: CGFloat = 0
}

var floatingLabels: [FloatingLabel] = []
```

When a new applause event arrives (via polling or after user taps 👏):
1. Append a `FloatingLabel` to `floatingLabels`
2. Animate `.offset(y: -80)` + `.opacity(0)` over 1.5 seconds using `withAnimation(.easeOut(duration: 1.5))`
3. Remove from array after animation completes (`Task { try await Task.sleep(for: .seconds(1.5)) }`)

The View renders `ZStack` of `FloatingLabel` items positioned over the profile/goal card.

**New components:**
- `ApplauseService` (new enum) — `func sendApplause(from:, to:, goalTitle:) async throws -> CKRecord`, `func fetchApplause(forProfileRecordID:, since:) async throws -> [CKRecord]`, `func hasAlreadyApplaudedToday(from:, to:) async throws -> Bool`
- `ApplauseViewModel` (@Observable, @MainActor) — manages `floatingLabels`, applause send/poll, `cheersGiven: Int`

**Modified components:**
- `PublicProfileView` + `PublicProfileViewModel` — add 👏 button, `cheersGiven` count display, integrate `ApplauseViewModel`
- `CommunityTabView` — add "Glowing this week" spotlight section, consume `ApplauseViewModel` for feed

**No SwiftData change.** Applause records live entirely in CloudKit public DB. No local persistence.

---

### 8. In-App Dark Mode Toggle

**State storage: `@AppStorage` (UserDefaults), NOT SwiftData.**

Rationale: Dark mode preference is a device-local setting. It does not need CloudKit sync, migration versioning, or SwiftData's relationship model. `@AppStorage` is the correct primitive.

**Implementation pattern (HIGH confidence — matches Apple's own pattern):**

```swift
// In VitaminGApp body or a root wrapper view
@AppStorage("vg_colorSchemeOverride") var colorSchemeRaw: String = "system"

var preferredColorScheme: ColorScheme? {
    switch colorSchemeRaw {
    case "light": return .light
    case "dark":  return .dark
    default:      return nil   // nil = follow system
    }
}
```

Apply at the root `.preferredColorScheme(preferredColorScheme)` on the `WindowGroup`'s root view. Changing `colorSchemeRaw` from Settings causes SwiftUI to re-render the entire view tree with the new scheme.

**Where the toggle lives:** `SettingsView` (accessible from Profile tab). The toggle writes to `@AppStorage("vg_colorSchemeOverride")`.

**Architecture note:** This does NOT belong in a ViewModel. A ViewModel should not own UI appearance state. `@AppStorage` in a View or accessed directly from `WindowGroup` is the right pattern for this cross-cutting concern. No ViewModel needed.

**No SwiftData change. No new schema version.**

**Modified components:**
- `VitaminGApp.body` — add `.preferredColorScheme(preferredColorScheme)` to the root `Group`
- `SettingsView` — add dark mode picker (System / Light / Dark)

---

### 9. SchemaV9: What New Models Are Required

**SwiftData schema migrations are required only when the local SwiftData model changes.** CloudKit public DB record types (CommunityPost, PublicProfile, UserPresence, Applause) are not SwiftData models and do not trigger schema migrations.

**Analysis of each v2.0 feature:**

| Feature | SwiftData Change? | Migration Needed? |
|---------|-------------------|-------------------|
| Tab restructuring | None | No |
| Profile picture in onboarding | None — `UserProfile.photoData` exists (SchemaV8) | No |
| Username uniqueness enforcement | None — `UserProfile.username` exists (SchemaV8) | No |
| Tip Jar | None | No |
| Live users presence | None — ephemeral CK public records | No |
| Shake gesture / daily goal gifter | None — `@AppStorage` flag | No |
| Applause system | None — CK public records | No |
| Dark mode toggle | None — `@AppStorage` | No |
| Follow / cheer system | New? — `FollowRelationship` local record? | Possibly yes (see below) |
| Achievement milestones | `UserChallenge` + threshold already tracked | No |
| Home tab quote of day | None — `VGQuoteBank` exists | No |

**The one potential SchemaV9 trigger:**

The **follow system** ("follow + cheer them on today") implies the local app knows which profiles the current user follows. If this list is stored locally (for offline-capable following lists), a new SwiftData model is needed:

```swift
// SchemaV9 candidate
@Model final class FollowedProfile {
    var id: UUID = UUID()
    var publicRecordID: String?      // CK public record ID
    var username: String?
    var displayName: String?
    var avatarColorHex: String?
    var followedAt: Date?
}
```

**Recommendation:** Store follows in CloudKit public DB only (in a `Follow` record type), keeping the local SwiftData schema at V8. This avoids a schema migration and aligns with the existing pattern (community features = CK public DB, not SwiftData). A `Follow` CK record: `fromUserRecordID`, `toProfileRecordID`, `followedAt`.

**Verdict: No SchemaV9 required for v2.0 if follows are CK-public-only.**

If product later requires offline follow lists, SchemaV9 adds `FollowedProfile` as a lightweight migration (additive model, nil defaults).

---

### 10. Discover Page Search: CloudKit Public DB vs Local Filtering

**CloudKit public DB search approach:**

CloudKit `CKQuery` with `NSPredicate` supports:
- `CONTAINS` (case-insensitive with `[cd]` modifier) for substring matching on indexed String fields
- `BEGINSWITH` for prefix matching

For goal/profile search by keyword:
```swift
let predicate = NSPredicate(format: "username CONTAINS[cd] %@", searchText)
let query = CKQuery(recordType: "PublicProfile", predicate: predicate)
```

**Limitation:** CloudKit does not support full-text search or fuzzy matching. `CONTAINS[cd]` is substring-only and requires a queryable index on the field. Index creation is done in CloudKit Dashboard — not automatically inferred.

**Architecture decision: remote-only search, no local cache.**

Local filtering only works if all public records are downloaded first — infeasible at any scale. Search must query CloudKit public DB. Results are displayed directly; no local caching needed for MVP.

**Debounce pattern:** `DiscoverViewModel` holds `var searchText: String` and debounces via `Task` with `try await Task.sleep(for: .milliseconds(400))` before calling the service — consistent with the codebase's async/await pattern (no Combine).

**New components:**
- `DiscoverViewModel` (@Observable, @MainActor) — `var searchText: String`, `var goalResults: [CKRecord]`, `var profileResults: [CKRecord]`, `var isSearching: Bool`, debounced search
- `DiscoverView` — accessible from Community tab or as a NavigationLink destination

**Modified components:**
- `AppRoute` — add `case discover`
- `CommunityTabView` — add "Search" button/entry point to `DiscoverView`

**CloudKit requirements:**
- `PublicProfile` record type: queryable index on `username`, `displayName`
- Goal record type in public DB: queryable index on title field

---

## Component Summary: New vs Modified

### New Components

| Component | Type | Tab | Notes |
|-----------|------|-----|-------|
| `ExploreTabView` | View | Explore (2) | Root of Explore tab |
| `ExploreViewModel` | ViewModel | Explore | Shake gifter, feelings, trending |
| `MotionService` | Service | App-wide | Singleton, one `CMMotionManager` |
| `LiveUsersViewModel` | ViewModel | Community | Polling, presence display |
| `PresenceService` | Service | Community | CK public DB heartbeat/fetch |
| `ApplauseService` | Service | Community/Profile | CK public DB applause CRUD |
| `ApplauseViewModel` | ViewModel | Community/Profile | Floating label animation state |
| `TipJarViewModel` | ViewModel | Profile/About | StoreKit 2 product fetch + purchase |
| `TipJarView` | View | Profile | Tiered tip display |
| `AboutView` | View | Profile | App version, tip jar entry |
| `UsernameAvailabilityService` | Service | Onboarding | CK public DB username check |
| `DiscoverViewModel` | ViewModel | Community | Debounced CK search |
| `DiscoverView` | View | Community | Search UI |

### Modified Components

| Component | Changes |
|-----------|---------|
| `ContentView` | Rewire tab indices 2/3; update NavigationDestination blocks |
| `VGTabBar` | Relabel tab 2→Explore (sparkles/wand icon), 3→Community; adjust SF Symbol names |
| `AppRoute` | Add: `explore`, `discover`, `tipJar`, `about`; verify `stats` still wired |
| `ProfileSharingService` | `publishProfile()` — add `photoData: Data?` param, write as CKAsset; `fetchProfile()` — return `photoData: Data?` |
| `PublicProfileViewModel` | `ViewState.loaded` — add `photoData: Data?`; add applause count, cheer button state |
| `ProfileViewModel` | Add `checkAndSaveUsername(context:) async` (remote check); `toggleProfilePublic()` — pass photo to publishProfile |
| `CommunityTabView` | Add: live users section, "Today's glimpses", "Glowing this week", Discover entry |
| `OnboardingViewModel` | Add photo step, Apple Sign-In-only flow, username claim step with async check |
| `VitaminGApp` | Instantiate `MotionService`, inject via environment; add `.preferredColorScheme()` modifier |
| `SettingsView` | Add dark mode picker; daily nudge time setting already exists |

---

## CloudKit Schema Changes (Public DB Record Types)

These are additions to the CloudKit **public database** schema — not SwiftData. New record types must be defined and promoted in CloudKit Dashboard.

| Record Type | Fields | Queryable Indexes Needed |
|-------------|--------|--------------------------|
| `UserPresence` (new) | `username (String)`, `displayName (String)`, `avatarColorHex (String)`, `currentGoalTitle (String)`, `lastSeenAt (Date)` | `lastSeenAt` |
| `Applause` (new) | `fromUsername (String)`, `fromDisplayName (String)`, `fromAvatarColorHex (String)`, `toProfileRecordID (String)`, `toUsername (String)`, `goalTitle (String)`, `createdAt (Date)` | `toProfileRecordID`, `createdAt` |
| `Follow` (new) | `fromUserRecordID (String)`, `toProfileRecordID (String)`, `followedAt (Date)` | `fromUserRecordID`, `toProfileRecordID` |
| `PublicProfile` (existing — extend) | Add: `username (String)`, `photoAsset (CKAsset)` | Add: `username` |

---

## SwiftData Schema Version Assessment

**No SchemaV9 is required for v2.0** if follows, presence, and applause remain in CloudKit public DB only (no local SwiftData persistence). All v2.0 features either:
- Use existing SwiftData fields (`UserProfile.photoData`, `UserProfile.username` — both in SchemaV8)
- Use `@AppStorage` for device-local preferences (dark mode, daily shake date)
- Use CloudKit public DB records (presence, applause, follow, public profile photo)

**If SchemaV9 is needed later:** The trigger would be persisting follow relationships locally for offline access. Migration would be lightweight (additive `FollowedProfile` model, all optional fields).

---

## Suggested Build Order

This order respects feature dependencies and avoids rework:

1. **Tab restructuring + AppRoute updates** — prerequisite for everything; establishes where each feature lives (ContentView, VGTabBar, AppRoute)
2. **Onboarding overhaul** — Apple Sign-In only, T&C, unique username (with `UsernameAvailabilityService`), profile picture step, notification permission slide; gates SchemaV8 username + photo data being populated at onboarding time
3. **Public profile photo** — extend `ProfileSharingService` to write/read CKAsset; update `PublicProfileViewModel`; all subsequent social features show correct avatars
4. **Home tab** (new dashboard) — `HomeView` already partially exists; complete streak display, quote, primary goal, "My Goals" list; Stats/Wins as NavigationLink destinations
5. **Goals flow enhancements** — wizard, "Need ideas", goal detail with streak/flame; builds on existing `GoalCreationWizardViewModel`
6. **StoreKit 2 Tip Jar** — self-contained, no dependencies on other v2.0 features; early = good because App Store review requires IAP review lead time
7. **Dark mode toggle** — two-line change to `VitaminGApp` + `SettingsView` picker; zero risk
8. **Explore tab** — `ExploreTabView` + `ExploreViewModel` + `MotionService` (shake gifter, feelings prompt, Vitamin Shelf, trending); requires CloudKit trending query
9. **Community tab redesign** — "Today's glimpses", live users (`PresenceService` + `LiveUsersViewModel`), applause system (`ApplauseService` + `ApplauseViewModel` + floating animation)
10. **Public profile + follow/cheer** — `PublicProfileView` redesign, follow button, cheer/applause on profile; depends on Applause system (step 9)
11. **Discover page** — `DiscoverView` + `DiscoverViewModel`; depends on CloudKit indexes from Community work
12. **Streak freeze, achievement celebrations, notification picker** — polishing layer; no new architecture, extend existing `StreakFreezeService` and `MilestoneCelebrationView`
13. **Widget enhancements** — last, because widgets read from SwiftData and the schema is stable; `WidgetDataProvider` extension

---

## Architecture Decision Flags

| Decision | Verdict | Rationale |
|----------|---------|-----------|
| Profile photo in private vs public DB | **Both** — private DB for storage (existing), public DB for sharing (CKAsset in PublicProfile record) | Privacy: user controls when photo is visible (via isPublic toggle) |
| Follows in CK public DB vs SwiftData | **CK public DB only** | Avoids SchemaV9; consistent with existing community pattern; acceptable for MVP |
| Dark mode state in UserDefaults vs SwiftData | **UserDefaults (@AppStorage)** | Device-local preference; no sync needed; SwiftData overkill |
| Tip jar in StoreKit 2 vs SwiftData | **StoreKit 2 only, no SwiftData** | Consumables don't need local persistence; `transaction.finish()` is the end state |
| Shake detection via CMMotionManager vs UIWindow override | **CMMotionManager** | Pure SwiftUI + @Observable; no UIKit bridge; consistent with codebase style |
| Live users via subscriptions vs polling | **Polling with short TTL records** | CloudKit push is best-effort; polling is predictable and controllable |
| Username uniqueness via @Attribute(.unique) | **BANNED** (project constraint) | CloudKit incompatible; app-level query check is the only valid pattern |

---

## Architectural Violations to Avoid

1. **Do not put `CMMotionManager` in a View** — exactly one instance per app, created in a service class, injected via environment
2. **Do not put StoreKit purchase calls in a View** — all `product.purchase()` calls go in `TipJarViewModel`
3. **Do not store applause/presence/follow counts in SwiftData** — these are community-scale counters that live in CloudKit public DB; SwiftData is for the user's own private data
4. **Do not add `@Attribute(.unique)` to `UserProfile.username`** — this will silently break CloudKit sync
5. **Do not use Combine for debounce in `DiscoverViewModel`** — use `Task + Task.sleep` pattern consistent with the rest of the codebase (no Combine)
6. **Do not write business logic for the floating applause animation in a View** — `ApplauseViewModel` owns `floatingLabels: [FloatingLabel]` and drives animations; View only reads state
7. **Do not create a `CMMotionManager` per View or per ViewModel** — this is a per-app singleton; instantiate once in `VitaminGApp`

---

## Sources

- CloudKit unique constraints limitation: [Hacking with Swift Forums](https://www.hackingwithswift.com/forums/swiftui/best-way-to-handle-unique-values-with-swiftdata-and-cloudkit/30145)
- CKQuerySubscription for public DB (not CKDatabaseSubscription): [Apple Developer Documentation](https://developer.apple.com/documentation/cloudkit/ckquerysubscription)
- CloudKit notifications best-effort delivery: [Cocoacasts](https://cocoacasts.com/five-reasons-cloudkit-notifications-are-not-arriving)
- StoreKit 2 consumable purchase result: [Apple Developer Documentation — Product.PurchaseResult](https://developer.apple.com/documentation/storekit/product/purchaseresult)
- StoreKit 2 Transaction.latest(for:): [Apple Developer Documentation](https://developer.apple.com/documentation/storekit/transaction/latest%28for%3A%29)
- .preferredColorScheme override pattern: [Apple Developer Forums](https://developer.apple.com/forums/thread/658818)
- CoreMotion SwiftUI integration: [CreateWithSwift](https://www.createwithswift.com/using-core-motion-within-a-swiftui-application/)
- Tip jar implementation reference: [Ben Cardy](https://bencardy.co.uk/2023/02/17/implementing-a-tip-jar-with-swift-and-swiftui/)
