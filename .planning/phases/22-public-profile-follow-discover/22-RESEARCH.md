# Phase 22: Public Profile + Follow + Discover - Research

**Researched:** 2026-05-24
**Domain:** SwiftUI / CloudKit public DB social features — profile expansion, follow graph, goal indexing, search
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Discover UI Placement (DISC-01–04)**
- D-01: Discover lives inside `ExploreView` via the `.searchable` modifier — search bar appears at the top of the Explore tab. No new tab is added; the 5-tab structure (TAB-01) is preserved.
- D-02: When search is active and `searchText` is empty: collapse ExploreView's 6 normal sections entirely and show `TrendingChallengesSection` (DISC-03) in their place.
- D-03: When search is active and `searchText` is non-empty: show a segment control (`Picker` in `.segmented` style: "Goals" / "People") above a `LazyVStack` of result cards. Collapse all ExploreView sections.
- D-04: When search is inactive: show ExploreView normally with its 6 existing sections.

**PublicProfile Data Expansion (PROF-01)**
- D-05: Expand the existing `PublicProfile` CKRecord with three new fields: `streakLength` (Int64), `goalCount` (Int64), `motto` (String). No new CKRecord type — same record, same `recordName = appleUserID` keying.
- D-06: Profile photos remain excluded from `PublicProfile` per T-07-08 security decision. `AvatarView` uses initials + `avatarColorHex` only.
- D-07: Motto/bio is editable from `ProfileView`. A "Motto" text field (≤100 chars) added to profile editing. Saving triggers `ProfileSharingService.publishProfile()` republish.
- D-08: `PublicProfile` republish cadence: on app launch (after successful auth) AND after every successful goal check-in.

**Public Goal Indexing (DISC-01, DISC-04)**
- D-09: New `PublicGoal` CKRecord type in CloudKit public DB. Fields: `title` (String), `category` (String), `creatorUsername` (String), `participantCount` (Int64), `progressPercent` (Int64), `durationDays` (Int64), `creationEpoch` (Int64). Record name: `goal.id.uuidString`.
- D-10: `PublicGoal` written when goal created with `isPublic == true`. Deleted on public→private toggle or completion. New field `cloudKitPublicGoalRecordID: String?` on SwiftData `Goal` model.
- D-11: Backfill on first Phase 22 launch: all local goals where `isPublic == true && cloudKitPublicGoalRecordID == nil` get `PublicGoal` records written.
- D-12: Progress sync cadence: same as PublicProfile republish — on app launch + after check-in.

**Follow System (PROF-02)**
- D-13: New `Follow` CKRecord type in CloudKit public DB. Fields: `followerUsername` (String), `followeeUsername` (String), `createdAt` (Int64 epoch). Record name: `"\(followerUsername)_\(followeeUsername)"` for deterministic deduplication.
- D-14: Follow state on `PublicProfileView` load: query CloudKit for matching `Follow` record. No local cache. No unfollow UI.

**Join Goal (DISC-04)**
- D-15: Tapping Join presents a mini tier-picker sheet. User selection creates a SwiftData `Goal` with `isPublic = false` and `creationDate = now`.
- D-16: Participant count increment: atomic fetch + `+1` + save on `PublicGoal` record. On failure: log silently, do not roll back local goal.

**Cheer + Applause (PROF-03)**
- D-17: CheerButton reuses `CommunityService` applause write path. Daily limit tracked via UserDefaults `[recipientUsername: lastCheerDate]` dictionary — same `ApplauseGate` pattern already implemented.

### Claude's Discretion
- `DiscoverViewModel` implements 500ms search debounce using `Task.sleep(for: .milliseconds(500))` inside an `async` search function with task cancellation on each keystroke.
- `PublicGoalCard` on `PublicProfileView` uses a local `Circle().trim()` implementation rather than `ProgressRingView` (which requires `GoalTier`).
- `PublicProfileViewModel` state enum expands to `loaded(profile: PublicProfileData)` where `PublicProfileData` is a lightweight struct.
- `ProfileSharingService.fetchProfile()` expands to return a `PublicProfileData` struct instead of the current `(displayName, avatarColorHex)` tuple.
- The `motto` field on SwiftData `UserProfile` model: add as `var motto: String? = nil` in SchemaV9 (new schema version for Phase 22, lightweight migration).

### Deferred Ideas (OUT OF SCOPE)
- Profile photos on public profiles (CKAsset in PublicProfile): excluded per T-07-08 security decision.
- Unfollow / follow management: follow is one-way and terminal in v2.0.
- Follow-based community feed filtering: community feed stays global in v2.0.
- Full-text goal search (Algolia etc.): CloudKit substring predicate is sufficient for MVP.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROF-01 | Public profile view shows avatar, motto/bio, streak length, goal count, and cheers given count | PublicProfileData struct + expanded PublicProfile CKRecord + expanded ProfileSharingService |
| PROF-02 | User can follow another user (one-time action; stored as Follow CKRecord in public DB) | New Follow CKRecord type + FollowButton state machine |
| PROF-03 | "Cheer them on today" button on public profile (reuses SOC-01 applause; daily limit) | Existing ApplauseGate + CommunityService.writeApplause — reused directly |
| PROF-04 | Public profile shows user's public goals with progress rings | PublicGoalService.fetchGoalsForUser + PublicGoalCard component |
| DISC-01 | Discover search bar queries public goals by keyword (case-insensitive substring, debounced 500ms) | NSPredicate CONTAINS[cd] on PublicGoal records + DiscoverViewModel |
| DISC-02 | "People" segment queries user profiles by username prefix | NSPredicate BEGINSWITH[cd] on PublicProfile records + PeopleSearchResultCard |
| DISC-03 | Trending Challenges section displayed when search is empty | Reuse existing ChallengeDiscoveryView component |
| DISC-04 | User can join a public goal from Discover; adds to local SwiftData + increments participant count | PublicGoalService.incrementParticipantCount + Goal creation from GoalInput pattern |
</phase_requirements>

---

## Summary

Phase 22 extends Vitamin G's social layer across three interconnected domains: a redesigned public profile card (PROF-01–04), a follow relationship system (PROF-02), and a searchable Discover surface inside ExploreView (DISC-01–04). All social data writes target the CloudKit public database — no SwiftData schema changes are needed for the CloudKit side. The only SwiftData changes are two lightweight additive fields: `UserProfile.motto: String?` and `Goal.cloudKitPublicGoalRecordID: String?`.

The codebase is well-prepared. Phase 21 established the `ApplauseGate` enum, `CommunityService.writeApplause()`, `AvatarView`, `ApplauseButtonView`, and the `@MainActor @Observable` ViewModel pattern that Phase 22 reuses almost directly. `PublicProfileViewModel` and `ProfileSharingService` both need surgical expansion — not replacement. The primary new work is: (1) the `PublicGoalService` (new file), (2) `DiscoverViewModel` (new file), (3) the Discover UI overlay on `ExploreView`, and (4) the PublicProfileView redesign.

The most complex technical problem is coordinating four async CloudKit operations at app launch without blocking the UI: profile republish, PublicGoal sync, glimpse write, and presence write. These must all be fire-and-forget `Task` calls chained from `VitaminGApp`'s `.task` modifier. The second hardest problem is the `.searchable` / `@Environment(\.isSearching)` integration with ExploreView's existing section layout — the two states (search active vs. inactive) must be mutually exclusive with no residual animation flash.

**Primary recommendation:** Build in four sequential plan groups — (1) data layer (SchemaV9, models, PublicGoalService extension), (2) service expansions (ProfileSharingService, launch hooks in VitaminGApp/GoalViewModel), (3) ViewModels (PublicProfileViewModel expansion, DiscoverViewModel), (4) UI (PublicProfileView redesign, ExploreView .searchable overlay, new card components).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public profile data (streak, motto, goal count) | CloudKit public DB | SwiftData (local read-only) | Stats are computed from local SwiftData; published to CloudKit for others to read |
| Follow relationship storage | CloudKit public DB | — | Social graph is inherently cross-user; no local persistence needed |
| Cheer (applause) write | CloudKit public DB | UserDefaults (daily gate) | Same pattern as Phase 21 ApplauseGate |
| Public goal indexing | CloudKit public DB | SwiftData (cloudKitPublicGoalRecordID) | Searchable index lives in public DB; SwiftData tracks the record ID for sync/delete |
| Discover search queries | CloudKit public DB | DiscoverViewModel (results cache) | NSPredicate queries against PublicGoal/PublicProfile record types |
| Join goal persistence | SwiftData (local) | CloudKit public DB (participant count) | Local goal is created first; CK participant count is a best-effort side effect |
| Daily cheer gate | UserDefaults | — | Lightweight date-keyed persistence; same as ApplauseGate |
| Search debounce | DiscoverViewModel | — | Task.sleep + cancellation in async ViewModel; no Combine needed |
| Profile motto editing | SwiftData (UserProfile.motto) | CloudKit public DB (PublicProfile.motto) | Edited locally, published on save |

---

## Standard Stack

### Core (no new packages — pure Apple frameworks)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All UI including `.searchable`, `Picker(.segmented)`, `.confirmationDialog` | Project minimum; required by CLAUDE.md |
| SwiftData | iOS 17+ | SchemaV9 lightweight migration for motto + cloudKitPublicGoalRecordID | Existing persistence layer |
| CloudKit | iOS 17+ | PublicGoal, Follow record types; NSPredicate substring/prefix search | Existing sync backend |
| Observation (`@Observable`) | iOS 17+ | DiscoverViewModel, PublicProfileViewModel expansion | Project standard per CLAUDE.md |

### No New Third-Party Packages
This phase introduces zero new external dependencies. All capabilities are implemented using Apple frameworks already in the project.

### Installation
```bash
# No new packages — nothing to install
```

---

## Package Legitimacy Audit

No external packages are introduced in Phase 22. This section is not applicable.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
[User action]
     │
     ├─► [PublicProfileView]
     │      │  fetchProfile(recordID)
     │      ▼
     │   [PublicProfileViewModel]
     │      │  fetches: PublicProfileData (displayName, avatarColorHex, motto, streakLength, goalCount)
     │      │  fetches: cheersGivenCount (CommunityService.fetchApplauseGivenCount)
     │      │  fetches: followState (ProfileSharingService.fetchFollowState)
     │      │  fetches: publicGoals (PublicGoalService.fetchGoalsForUser)
     │      ▼
     │   [CloudKit Public DB]
     │      PublicProfile record (expandd: streakLength, goalCount, motto)
     │      PublicGoal records (filtered by creatorUsername)
     │      Follow record (followerUsername_followeeUsername)
     │      Applause records (giverUsername)
     │
     ├─► [ExploreView + .searchable]
     │      │  isSearching + searchText environment
     │      ▼
     │   [DiscoverViewModel]
     │      │  debounced 500ms via Task.sleep + task cancellation
     │      │  searchGoals(keyword:) → NSPredicate "title CONTAINS[cd] %@" on PublicGoal
     │      │  searchPeople(prefix:) → NSPredicate "username BEGINSWITH[cd] %@" on PublicProfile
     │      ▼
     │   [CloudKit Public DB]
     │      PublicGoal records (keyword search)
     │      PublicProfile records (username prefix search)
     │
     └─► [App launch / check-in hooks]
            │  VitaminGApp.task → fire-and-forget Tasks:
            │    ProfileSharingService.publishProfile() (expanded fields)
            │    PublicGoalService.backfillPublicGoals()
            │    PublicGoalService.syncOwnedPublicGoals()
            │  GoalViewModel.addCheckIn() → fire-and-forget Tasks:
            │    ProfileSharingService.publishProfile()
            │    PublicGoalService.syncOwnedPublicGoals()
            ▼
         [CloudKit Public DB]
```

### Recommended Project Structure

```
VitaminG/
├── Models/
│   ├── SchemaV9.swift           # NEW — motto on UserProfile, cloudKitPublicGoalRecordID on Goal
│   ├── VitaminGMigrationPlan.swift  # EDIT — add migrateV8toV9 stage
│   └── CommunityHubModels.swift     # EDIT — add PublicProfileData, PublicGoalItem, DiscoverGoalResult, DiscoverPersonResult
│
├── Services/
│   ├── ProfileSharingService.swift  # EDIT — expand publishProfile, fetchProfile → PublicProfileData, add fetchFollowState, writeFollow
│   ├── PublicGoalService.swift      # NEW — writePublicGoal, deletePublicGoal, backfillPublicGoals, syncOwnedPublicGoals, searchGoals, searchPeople, incrementParticipantCount, fetchGoalsForUser
│   └── CommunityService.swift       # READ-ONLY (CheerButton reuses existing writeApplause)
│
├── ViewModels/
│   ├── PublicProfileViewModel.swift # EDIT — expand ViewState.loaded → loaded(profile:PublicProfileData), add followState, canCheerToday
│   └── DiscoverViewModel.swift      # NEW — debounced search, Goals/People segment, join action
│
└── Views/
    ├── PublicProfileView.swift              # EDIT — full redesign per UI-SPEC
    ├── Explore/
    │   ├── ExploreView.swift               # EDIT — add .searchable + @Environment(\.isSearching) + Discover overlay
    │   └── Discover/
    │       ├── DiscoverOverlayView.swift   # NEW — segment control + result lists (or inline in ExploreView)
    │       ├── GoalSearchResultCard.swift  # NEW — UI-SPEC §4
    │       └── PeopleSearchResultCard.swift # NEW — UI-SPEC §5
    └── Components/
        └── PublicGoalCard.swift             # NEW — Circle().trim() ring, UI-SPEC §1
```

### Pattern 1: CloudKit Public DB Query with NSPredicate
**What:** All Discover searches use `NSPredicate` with `CONTAINS[cd]` (case/diacritic insensitive substring) for goal keyword search and `BEGINSWITH[cd]` for username prefix search.
**When to use:** Any CloudKit query against a String field where exact match is too strict.
**Example:**
```swift
// Source: CONTEXT.md D-11; matches CommunityService.fetchPosts pattern
// Goal keyword search (DISC-01)
let predicate = NSPredicate(format: "title CONTAINS[cd] %@", keyword)
let query = CKQuery(recordType: "PublicGoal", predicate: predicate)
let (results, _) = try await db.records(matching: query, resultsLimit: 25)

// People prefix search (DISC-02)
let predicate = NSPredicate(format: "username BEGINSWITH[cd] %@", prefix)
let query = CKQuery(recordType: "PublicProfile", predicate: predicate)
```

### Pattern 2: Task Debounce with Cancellation
**What:** DiscoverViewModel debounces search with 500ms delay using `Task` cancellation. Each new keystroke cancels the pending task and starts a new one.
**When to use:** Whenever a user text input drives an async operation that should not fire on every keystroke.
**Example:**
```swift
// Source: CONTEXT.md Claude's Discretion — chosen over Combine.debounce
@Observable final class DiscoverViewModel {
    private var searchTask: Task<Void, Never>?

    func onSearchTextChanged(_ newText: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await performSearch(newText)
        }
    }
}
```

### Pattern 3: Deterministic Follow Record Name
**What:** `Follow` records use `"\(followerUsername)_\(followeeUsername)"` as the recordName, making the record both idempotent (safe to write twice) and queryable by ID.
**When to use:** Any relationship record where uniqueness must be enforced without a server-side uniqueness constraint (CloudKit doesn't support `@Attribute(.unique)`).
**Example:**
```swift
// Source: CONTEXT.md D-13; mirrors UsernameLookupService.writeUsername pattern
let recordName = "\(followerUsername)_\(followeeUsername)"
let recordID = CKRecord.ID(recordName: recordName)
// Try fetch first; if unknownItem, create new
```

### Pattern 4: Atomic Participant Count Increment
**What:** Fetch-increment-save pattern for updating `PublicGoal.participantCount`. One retry on `.serverRecordChanged` to handle concurrent writes.
**When to use:** Any CloudKit counter field that multiple users may update simultaneously.
**Example:**
```swift
// Source: CONTEXT.md D-16; mirrors CommunityService.toggleReaction() exactly
do {
    let record = try await db.record(for: recordID)
    let current = (record["participantCount"] as? Int64) ?? 0
    record["participantCount"] = current + 1 as CKRecordValue
    _ = try await db.save(record)
} catch let error as CKError where error.code == .serverRecordChanged {
    // one retry
    let record = try await db.record(for: recordID)
    let current = (record["participantCount"] as? Int64) ?? 0
    record["participantCount"] = current + 1 as CKRecordValue
    _ = try await db.save(record)
}
```

### Pattern 5: .searchable + isSearching Environment
**What:** `.searchable(text:placement:)` modifier on ExploreView's `NavigationStack`. `@Environment(\.isSearching)` read in the view body to switch between normal Explore sections and Discover overlay.
**When to use:** Search-as-overlay pattern where existing content is replaced, not pushed.
**Example:**
```swift
// Source: CONTEXT.md D-01; Apple HIG .searchable placement
// CRITICAL: .searchable must be on the NavigationStack, not the ScrollView
NavigationStack {
    ExploreView()
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search goals or people…"
        )
}

// Inside ExploreView:
@Environment(\.isSearching) private var isSearching
var body: some View {
    if isSearching && searchText.isEmpty {
        TrendingChallengesSection()
    } else if isSearching {
        DiscoverResultsOverlay(searchText: searchText)
    } else {
        // Normal 6-section ExploreView content
    }
}
```

### Anti-Patterns to Avoid
- **Publishing `searchText` binding across View boundary:** The `$searchText` Binding from `.searchable` must stay in the same view or be propagated carefully. Do not pass it raw to a child ViewModel — copy the string value instead.
- **Creating SwiftData Goal before participant count write:** The Join action creates the local Goal first, then attempts the CK count increment. Do NOT reverse this order — a failed CK write must not prevent goal creation (D-16).
- **Using `ProgressRingView` for `PublicGoalCard`:** `ProgressRingView` requires `GoalTier`; `PublicGoalCard` has no tier context. Use `Circle().trim()` with terra color directly (CONTEXT.md Claude's Discretion).
- **Placing `.searchable` on ScrollView or inner VStack:** The `isSearching` environment value is only reliable when `.searchable` is applied to a `NavigationStack`. Misplacement causes `isSearching` to never become `true`. [VERIFIED: Apple Developer Documentation]
- **Follow record upsert without checking existing record first:** The deterministic record name (`followerUsername_followeeUsername`) makes it safe to use `CKRecord.ID(recordName:)` for fetch-or-create. Calling `db.save()` on a new `CKRecord` with a known name creates it only if absent — but a fetch first provides the follow state reading (D-14) simultaneously.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Daily cheer gate persistence | Custom [username:Date] dict + UserDefaults logic | `ApplauseGate.canApplaud()` + `ApplauseGate.markApplauseGiven()` (already implemented) | Phase 21 built this; same semantics; isolated UserDefaults suite in tests |
| Applause floating animation | Custom float animation | `ApplauseButtonView` mechanics (reuse directly) | Phase 21 implemented reduced-motion handling, timing, ZStack overlay |
| CloudKit counter increment | Custom non-retrying write | Fetch + increment + save + one retry on `.serverRecordChanged` | Concurrent writes cause `.serverRecordChanged`; already proven in `CommunityService.toggleReaction()` |
| Username uniqueness at follow write | Complex dedup logic | Deterministic record name `"\(follower)_\(followee)"` | CloudKit prevents duplicate record names; one-write dedup for free |
| Input sanitization for motto/goal title | Custom sanitizer | `InputSanitizer.sanitizeForPublic()` | Already strips control chars + injection chars; applied before every CloudKit write |
| Search input debounce | Combine pipeline | `Task.sleep` + `.cancel()` pattern | Already chosen in CONTEXT.md; consistent with codebase's async/await style |

**Key insight:** Every "new" social primitive in Phase 22 (gate, animation, counter, sanitization) maps directly to an existing Phase 17–21 implementation. The planner should treat this as wiring and expansion work, not greenfield work.

---

## Common Pitfalls

### Pitfall 1: `.searchable` placed on wrong view node
**What goes wrong:** `@Environment(\.isSearching)` reads `false` even while the user is typing. The Discover overlay never appears.
**Why it happens:** The `isSearching` environment value is only injected by a `NavigationStack` ancestor when `.searchable` is on that stack. If `.searchable` is added to the inner `ScrollView` or `VStack`, the injection chain is broken.
**How to avoid:** Apply `.searchable` to `ExploreView`'s parent `NavigationStack` in `ContentView` (or wherever the `NavigationStack` lives for the Explore tab). Read `@Environment(\.isSearching)` inside `ExploreView`'s body.
**Warning signs:** `isSearching` always `false`; search bar appears but Discover overlay never shows; normal Explore sections always visible during search.

### Pitfall 2: SchemaV9 migration missing from VitaminGMigrationPlan
**What goes wrong:** App crashes on launch with `ModelContainer` error about unrecognized schema version. Users with existing installs lose data.
**Why it happens:** SwiftData requires every schema hop to be declared in `VitaminGMigrationPlan.schemas` and `stages` arrays. Adding `SchemaV9.self` models without adding the migration stage breaks the chain.
**How to avoid:** In `VitaminGMigrationPlan.swift`, add `SchemaV9.self` to `schemas` array AND add `migrateV8toV9 = MigrationStage.lightweight(fromVersion: SchemaV8.self, toVersion: SchemaV9.self)` to `stages` array. The typealias `UserProfile = SchemaV9.UserProfile` must also be updated in `Schema8pV2.swift`.
**Warning signs:** App crashes at launch with `ModelContainerError`; simulator works but device doesn't (because device has existing data).

### Pitfall 3: PublicProfile CKRecord update overwrites existing fields with nil
**What goes wrong:** Expanding `ProfileSharingService.publishProfile()` to write `streakLength`, `goalCount`, `motto` using the fetch-then-update path accidentally writes nil or empty string for fields the caller didn't provide.
**Why it happens:** The current `publishProfile` signature only takes `displayName`, `avatarColorHex`, and optional `username`. If the caller doesn't pass the new fields, they're written as `"" as CKRecordValue` (empty string), overwriting any existing value.
**How to avoid:** The expanded `publishProfile` must take the full `PublicProfileData` struct (or explicit parameters) covering all fields. Never write a field with an empty fallback unless that's the intended value. Or: only write fields when they are non-nil.
**Warning signs:** Fetching a profile immediately after publish shows empty motto even though it was set; `streakLength` resets to 0 after a non-streak-changing republish.

### Pitfall 4: CloudKit PublicGoal record type not in Production schema
**What goes wrong:** `PublicGoalService.writePublicGoal()` throws `CKError.serverRejectedRequest` or `CKError.unknownItem` for the record type. Backfill fails silently; no goals appear in Discover search.
**Why it happens:** CloudKit record types must be deployed to Production via CloudKit Console before the app can write to them in production. The `PublicGoal` and `Follow` record types are new and don't exist yet.
**How to avoid:** Add a human-verification checkpoint in the first wave: "Confirm CloudKit Console has PublicGoal and Follow record types deployed to Production, with Queryable indexes on: PublicGoal.title, PublicGoal.creatorUsername, PublicGoal.category; PublicProfile.username (already done for Plan 17-03 — verify)."
**Warning signs:** Simulator/sandbox works but TestFlight builds can't write public goals or follows; no results in Discover search on device.

### Pitfall 5: Join action creates duplicate goals on retry
**What goes wrong:** User taps Join, sees a failure state, taps again — two copies of the goal appear in their list.
**Why it happens:** The optimistic update (button → "Joined" + disabled) may not persist across view reload. If the button reverts to "Join" on error (D-15/D-16 requires this), the user can tap again, creating a second local goal.
**How to avoid:** `DiscoverViewModel` must track joined goal IDs in a `Set<String>` keyed by `PublicGoal` recordName. On Join tap: check set first. The `GoalViewModel.addGoal(input:context:)` path already deduplicates by title at the UI level (user sees existing goal with same title in their list), but the set-based check is more robust.
**Warning signs:** User's goal list shows duplicates after retrying a Join; participant count incremented twice.

### Pitfall 6: `fetchProfile` return type change breaks PublicProfileViewModelTests
**What goes wrong:** Expanding `ProfileSharingService.fetchProfile()` to return `PublicProfileData` instead of `(displayName: String?, avatarColorHex: String?)` breaks the existing `fetchOverride` closure type in `PublicProfileViewModel`.
**Why it happens:** The test file `PublicProfileViewModelTests.swift` uses `fetchOverride: ((String) async throws -> (String?, String?))`. Changing the return type to `PublicProfileData` requires updating both the ViewModel property type and all test closures.
**How to avoid:** The planner must include a task to update `PublicProfileViewModelTests.swift` when the return type changes. Keep `fetchOverride` in the ViewModel as a test seam — just update its closure signature to return `PublicProfileData` instead of the tuple.
**Warning signs:** Build fails in test target after ProfileSharingService change; test compiler errors on `fetchOverride` closure body.

### Pitfall 7: Fire-and-forget Tasks in VitaminGApp launch sequence block UI
**What goes wrong:** If the Phase 22 launch hooks (backfill + sync + republish) are awaited instead of fire-and-forget, the app hangs at launch for users with many goals.
**Why it happens:** CloudKit operations are network-bound and can take seconds. The existing pattern (see `GoalViewModel.addCheckIn()` line 181) wraps them in `Task { await ... }` — fire-and-forget.
**How to avoid:** All Phase 22 launch operations in `VitaminGApp.task` must use `Task { await ... }` not `await` directly. Chain them without mutual dependency:
```swift
.task {
    Task { await ProfileSharingService.publishProfile(...) }
    Task { await PublicGoalService.backfillPublicGoals(...) }
    Task { await PublicGoalService.syncOwnedPublicGoals(...) }
}
```
**Warning signs:** App freezes at launch on slow networks; tests that await `VitaminGApp.task` time out.

---

## Code Examples

### Verified Pattern: ApplauseGate reuse for CheerButton

The `ApplauseGate` (in `CommunityHubViewModel.swift`) is already implemented with an injectable `UserDefaults` for testing. CheerButton can use it directly:

```swift
// Source: CommunityHubViewModel.swift lines 12-42 (ApplauseGate enum — verified in codebase)
// In PublicProfileViewModel:
var canCheerToday: Bool {
    ApplauseGate.canApplaud(recipientUsername: targetUsername)
}

func onCheer() {
    guard canCheerToday else { return }
    ApplauseGate.markApplauseGiven(to: targetUsername)
    Task {
        try? await CommunityService.writeApplause(
            giverUsername: myUsername,
            recipientUsername: targetUsername
        )
    }
}
```

### Verified Pattern: Expanded ViewState with associated data

Following the existing `CommunityHubViewModel` pattern:

```swift
// Source: PublicProfileViewModel.swift (current implementation — verified in codebase)
// Expanded version:
enum ViewState: Equatable {
    case loading
    case loaded(profile: PublicProfileData)
    case error(message: String)
}

struct PublicProfileData: Equatable {
    let displayName: String?
    let avatarColorHex: String?
    let username: String?
    let motto: String?
    let streakLength: Int
    let goalCount: Int
    let cheersGivenCount: Int
}
```

### Verified Pattern: Follow record write with deterministic name

```swift
// Source: CONTEXT.md D-13; pattern mirrors UsernameLookupService.writeUsername (verified in codebase)
// In ProfileSharingService:
static func writeFollow(followerUsername: String, followeeUsername: String) async throws {
    let db = CKContainer(identifier: containerID).publicCloudDatabase
    let recordName = "\(followerUsername)_\(followeeUsername)"
    let recordID = CKRecord.ID(recordName: recordName)
    // Check if already exists
    do {
        _ = try await db.record(for: recordID)
        return  // Already following — idempotent
    } catch let e as CKError where e.code == .unknownItem {
        let record = CKRecord(recordType: "Follow", recordID: recordID)
        record["followerUsername"] = InputSanitizer.sanitizeForPublic(followerUsername) as CKRecordValue
        record["followeeUsername"] = InputSanitizer.sanitizeForPublic(followeeUsername) as CKRecordValue
        record["createdAt"] = Int64(Date().timeIntervalSince1970) as CKRecordValue
        _ = try await db.save(record)
    }
}

static func fetchFollowState(followerUsername: String, followeeUsername: String) async throws -> Bool {
    let db = CKContainer(identifier: containerID).publicCloudDatabase
    let recordName = "\(followerUsername)_\(followeeUsername)"
    let recordID = CKRecord.ID(recordName: recordName)
    do {
        _ = try await db.record(for: recordID)
        return true
    } catch let e as CKError where e.code == .unknownItem {
        return false
    }
}
```

### Verified Pattern: PublicGoalCard progress ring (Circle().trim())

```swift
// Source: UI-SPEC §1; ProgressRingView.swift lines 37-45 (verified in codebase — adapted for no GoalTier)
struct PublicGoalCard: View {
    let goal: PublicGoalItem  // title, category, progressPercent, durationDays
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(VGTheme.accentTerra.opacity(0.15), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: Double(goal.progressPercent) / 100.0)
                    .stroke(VGTheme.accentTerra,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.4),
                        value: goal.progressPercent
                    )
                Text("\(goal.progressPercent)%")
                    .font(.system(size: 44 * 0.22, weight: .semibold, design: .rounded))
                    .foregroundStyle(VGTheme.accentTerra)
            }
            .frame(width: 44, height: 44)
            // ... text content
        }
    }
}
```

### Verified Pattern: SwiftData lightweight migration addition

```swift
// Source: VitaminGMigrationPlan.swift + SchemaV8.swift (verified in codebase)
// SchemaV9 adds two optional fields — purely additive, qualifies for lightweight migration

enum SchemaV9: VersionedSchema {
    static var versionIdentifier = Schema.Version(9, 0, 0)
    static var models: [any PersistentModel.Type] = [
        SchemaV9.Goal.self,
        SchemaV2.CompletionEvent.self,
        SchemaV9.UserProfile.self,
        SchemaV3.DailyWin.self,
        SchemaV4.ChallengeTemplate.self,
        SchemaV4.UserChallenge.self,
        SchemaV4.CheckIn.self,
        SchemaV5.TransformationPhoto.self,
        SchemaV5.SpendingFreezeEntry.self,
        SchemaV5.NutritionEntry.self,
        SchemaV7.GoalIdea.self,
        SchemaV7.MoodEntry.self
    ]

    @Model final class UserProfile {
        // ... all SchemaV8 fields ...
        var motto: String? = nil   // NEW in V9 (D-07)
        // ...
    }

    @Model final class Goal {
        // ... all SchemaV6 Goal fields ...
        var cloudKitPublicGoalRecordID: String? = nil  // NEW in V9 (D-10)
    }
}
// In VitaminGMigrationPlan: add SchemaV9.self to schemas[] and migrateV8toV9 to stages[]
// In Schema8pV2.swift: update typealias UserProfile = SchemaV9.UserProfile, Goal = SchemaV9.Goal
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ProgressRingView(tier:)` | `Circle().trim()` with explicit color | Phase 22 (new context) | PublicGoalCard has no `GoalTier`; local ring avoids forced coupling |
| `PublicProfileViewModel.loaded(displayName:avatarColorHex:)` | `loaded(profile: PublicProfileData)` | Phase 22 | Carries all PROF-01 fields in one associated value |
| `ProfileSharingService.fetchProfile()` returning tuple | Returns `PublicProfileData` struct | Phase 22 | Additive: same call site, richer return |
| Hard-coded `CKContainer.default()` in CommunityService | `CKContainer(identifier: containerID)` in ProfileSharingService | Established in Phase 17 | ProfileSharingService already uses explicit identifier — PublicGoalService must match |

**Deprecated/outdated in Phase 22 context:**
- `PublicProfileViewModel.ViewState.loaded(displayName: String?, avatarColorHex: String?)`: replaced by `loaded(profile: PublicProfileData)`. The old associated values are removed.
- `ProfileSharingService.fetchProfile(recordID:) -> (displayName:avatarColorHex:)`: return type changes to `PublicProfileData`. Old call sites in `PublicProfileViewModel` must be updated.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | CloudKit `CONTAINS[cd]` predicate works on String fields in the public database for PublicGoal.title | Architecture Patterns §1 | Search returns no results; planner must add CloudKit Console queryable index requirement |
| A2 | `@Environment(\.isSearching)` is available to a child view of the NavigationStack that hosts `.searchable` | Common Pitfalls §1 | Discover overlay never activates; requires restructuring search placement |
| A3 | SchemaV9 with two optional fields qualifies as a lightweight migration from V8 | Code Examples | Migration fails at launch for existing users; requires custom migration stage |

**A1 note:** CloudKit substring predicates require a Queryable index on the field in CloudKit Console. The planner MUST include a human checkpoint for: "Add Queryable index on PublicGoal.title and PublicGoal.creatorUsername in CloudKit Console before real-device testing."

---

## Open Questions (RESOLVED)

1. **ExploreView NavigationStack ownership**
   - What we know: ExploreView renders inside the Explore tab of `ContentView`; `.searchable` must be on a `NavigationStack` ancestor.
   - What's unclear: Whether the Explore tab already wraps `ExploreView` in its own `NavigationStack` in `ContentView.swift` (not read during research), or whether `.searchable` must be added at the tab level.
   - Recommendation: Planner reads `ContentView.swift` to locate the Explore tab's `NavigationStack`. If present, add `.searchable` there. If not, add a `NavigationStack` wrapper for the Explore tab first.
   - **RESOLVED:** ContentView already wraps ExploreView in a NavigationStack (per `<interfaces>` block in Plan 22-05 — lines 27–33 of ContentView.swift). Plan 22-05 Task 2 adds `.searchable(text:placement:prompt:)` to that existing NavigationStack with `@State private var exploreSearchText` on ContentView, forwarded to ExploreView. ExploreView reads `@Environment(\.isSearching)` to branch its body.

2. **`ProfileView` motto text field placement**
   - What we know: D-07 requires motto editing in `ProfileView`. The current `ProfileView` has `ProfileEditSheet` for name/username editing.
   - What's unclear: Whether motto should go into `ProfileEditSheet` (existing sheet) or directly inline in `ProfileView`.
   - Recommendation: Add motto to `ProfileEditSheet` alongside existing display name / username fields. Consistent with existing edit-then-save pattern. Planner should confirm by reading `ProfileEditSheet.swift`.
   - **RESOLVED:** Motto is added to `ProfileEditSheet` as a sibling Section after the existing username Section (Plan 22-04 Task 3). It mirrors the existing username TextField pattern verbatim with a 100-char cap (`ProfileViewModel.maxMottoLength = 100`) and `.onChange` clamp. Footer copy: "A short bio shown on your public profile." On save, `ProfileViewModel` persists `userProfile.motto` and calls `ProfileSharingService.publishProfile(... motto: draftMotto ...)`.

3. **AppStorage key for current user's Apple ID in CheerButton context**
   - What we know: `PublicProfileView` already reads `@AppStorage("vg_appleUserID")` for report email context. `PublicProfileViewModel` needs the current user's username to write applause.
   - What's unclear: Whether `PublicProfileViewModel` should accept username as init parameter or read it from `@AppStorage` directly.
   - Recommendation: Accept `myUsername: String` as an init/method parameter on `PublicProfileViewModel` (injected from the view), same as `ApplauseButtonView` accepts `giverUsername`. Keeps ViewModel testable without `@AppStorage` coupling.
   - **RESOLVED:** `PublicProfileViewModel.onCheer(recipientUsername:giverUsername:defaults:)` accepts `giverUsername` as a method parameter (not from @AppStorage). The View (PublicProfileView in Plan 22-05) reads `@AppStorage("vg_username") private var myUsername` and passes it into each call: `viewModel.onCheer(recipientUsername: profile.username ?? "", giverUsername: myUsername)`. Same pattern applies to `onFollow(followerUsername:followeeUsername:)`. ViewModel remains testable without @AppStorage coupling.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| CloudKit public DB | All social features | ✓ | Existing (in use since Phase 17) | — |
| SwiftData ModelContainer | SchemaV9 migration | ✓ | Existing (in use since Phase 1) | — |
| XCTest | Phase 22 tests | ✓ | Existing test target | — |
| CloudKit Console (human action) | PublicGoal + Follow record types | Requires human action | — | Tests use mocks; real-device blocked until done |

**Missing dependencies with no fallback:**
- CloudKit Console: `PublicGoal` record type (with fields: title/String, category/String, creatorUsername/String, participantCount/Int64, progressPercent/Int64, durationDays/Int64, creationEpoch/Int64) + Queryable indexes on title and creatorUsername — required before real-device Discover search testing
- CloudKit Console: `Follow` record type (with fields: followerUsername/String, followeeUsername/String, createdAt/Int64) — required before real-device follow testing

**Missing dependencies with fallback:**
- None — all code paths have mock/fallback equivalents in the test layer.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (existing VitaminGTests target) |
| Config file | Xcode scheme — no separate config file |
| Quick run command | `xcodebuild test -scheme VitaminG -only-testing:VitaminGTests/Phase22*` |
| Full suite command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROF-01 | `PublicProfileData` struct carries all 5 fields | unit | `xcodebuild test -only-testing:VitaminGTests/Phase22PublicProfileViewModelTests` | ❌ Wave 0 |
| PROF-01 | `ProfileSharingService.fetchProfile` returns `PublicProfileData` | unit (mock) | same file | ❌ Wave 0 |
| PROF-02 | `writeFollow` creates deterministic record name | unit (mock save) | `xcodebuild test -only-testing:VitaminGTests/Phase22FollowServiceTests` | ❌ Wave 0 |
| PROF-02 | `fetchFollowState` returns true for existing record | unit (mock) | same file | ❌ Wave 0 |
| PROF-02 | FollowButton state machine: idle → loading → followed | unit | same file | ❌ Wave 0 |
| PROF-03 | `canCheerToday` false after cheer (reuses `ApplauseGate`) | unit | `Phase21ApplauseDailyGateTests` | ✅ exists |
| PROF-03 | `canCheerToday` true for fresh date | unit | same | ✅ exists |
| PROF-04 | `PublicGoalService.fetchGoalsForUser` maps CKRecord to `PublicGoalItem` | unit (mock) | `xcodebuild test -only-testing:VitaminGTests/Phase22PublicGoalServiceTests` | ❌ Wave 0 |
| DISC-01 | `DiscoverViewModel.onSearchTextChanged` debounces 500ms | unit (mock clock) | `xcodebuild test -only-testing:VitaminGTests/Phase22DiscoverViewModelTests` | ❌ Wave 0 |
| DISC-01 | `DiscoverViewModel` segment switches to Goals by default | unit | same file | ❌ Wave 0 |
| DISC-02 | `searchPeople` query uses BEGINSWITH[cd] predicate | unit (predicate inspection) | same file | ❌ Wave 0 |
| DISC-04 | `joinGoal` creates SwiftData Goal with `isPublic = false` | unit (in-memory context) | same file | ❌ Wave 0 |
| DISC-04 | `joinGoal` increments participantCount (mock increment) | unit | same file | ❌ Wave 0 |
| n/a | `PublicGoalService.backfillPublicGoals` skips goals with `cloudKitPublicGoalRecordID` set | unit | `xcodebuild test -only-testing:VitaminGTests/Phase22PublicGoalServiceTests` | ❌ Wave 0 |
| n/a | `SchemaV9.UserProfile.motto` optional with nil default | unit (in-memory SwiftData) | `xcodebuild test -only-testing:VitaminGTests/Phase22SchemaV9Tests` | ❌ Wave 0 |
| n/a | `SchemaV9.Goal.cloudKitPublicGoalRecordID` optional with nil default | unit | same file | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme VitaminG -only-testing:VitaminGTests/Phase22*`
- **Per wave merge:** `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` (full suite)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `VitaminGTests/Phase22PublicProfileViewModelTests.swift` — covers PROF-01, PROF-02 (ViewModel state machine); replaces/extends existing `PublicProfileViewModelTests.swift`
- [ ] `VitaminGTests/Phase22FollowServiceTests.swift` — covers PROF-02 (deterministic record name, fetchFollowState)
- [ ] `VitaminGTests/Phase22PublicGoalServiceTests.swift` — covers PROF-04, DISC-04, backfill logic
- [ ] `VitaminGTests/Phase22DiscoverViewModelTests.swift` — covers DISC-01, DISC-02, DISC-04 (join action)
- [ ] `VitaminGTests/Phase22SchemaV9Tests.swift` — covers SchemaV9 model field defaults

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | CloudKit user identity handled by system |
| V3 Session Management | no | Stateless CloudKit; ApplauseGate in UserDefaults (acceptable per T-21-03-01) |
| V4 Access Control | yes | CloudKit public DB is append-only from client; no user-to-user record deletion |
| V5 Input Validation | yes | `InputSanitizer.sanitizeForPublic()` on all fields before CloudKit write |
| V6 Cryptography | no | No custom crypto; CloudKit handles transport |

### Known Threat Patterns for CloudKit public DB + SwiftUI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XSS injection via motto/goal title | Tampering | `InputSanitizer.sanitizeForPublic()` strips `<>"'` + control chars before write |
| Participant count inflation (bot Join) | Tampering | Accepted risk for v2.0 (no server-side rate limit); local goal creation is required before count increment; cosmetic only |
| Follow spam (follow all users) | Denial of Service | Deterministic record name deduplicates; CloudKit rate limits apply |
| UserDefaults cheer gate bypass | Tampering | Acknowledged in T-21-03-01: no cryptographic enforcement; acceptable for v2.0 social trust model |
| Stale `PublicProfile` with old streak/motto | Information Disclosure | Republish cadence (launch + check-in) keeps data fresh within one session; acceptable for MVP |

---

## Project Constraints (from CLAUDE.md)

| Constraint | Impact on Phase 22 |
|------------|-------------------|
| No third-party dependencies unless necessary | Zero new packages — all native Apple frameworks |
| All String inputs must have strict character limits and validation | `InputSanitizer.sanitizeForPublic()` required on every CloudKit write; motto field ≤100 chars enforced at ViewModel layer |
| iOS 17+ minimum | `.searchable(placement: .navigationBarDrawer)` available iOS 15+; `@Observable` iOS 17+ — no compatibility concern |
| MVVM strictly enforced — no business logic in Views | All search debounce, CloudKit queries, follow state, cheer gate logic in ViewModels/Services; Views are display-only |
| `@Observable` macro, not `ObservableObject` | `DiscoverViewModel` and expanded `PublicProfileViewModel` must use `@MainActor @Observable final class` |
| All SwiftData properties optional or with defaults | SchemaV9 fields `motto: String? = nil` and `cloudKitPublicGoalRecordID: String? = nil` comply |
| Do not use `@Attribute(.unique)` | Follow deduplication uses deterministic record name, not SwiftData unique constraint |
| `CKAsset fileURL must be copied immediately` | No new CKAsset in Phase 22 (profile photos excluded per D-06); existing copyItem pattern in `CommunityService.mapRecordToGlimpseItem` unchanged |

---

## Sources

### Primary (HIGH confidence)
- Codebase direct read: `CommunityHubViewModel.swift` — `ApplauseGate` enum, UserDefaults `[String: Date]` pattern
- Codebase direct read: `CommunityService.swift` — CloudKit public DB write pattern, `.serverRecordChanged` retry, `writeApplause()`, `fetchApplauseGivenCount()`
- Codebase direct read: `ProfileSharingService.swift` — existing `publishProfile()` and `fetchProfile()` signatures, security field allowlist
- Codebase direct read: `PublicProfileViewModel.swift` — `ViewState` enum, `fetchOverride` test seam pattern
- Codebase direct read: `VitaminGMigrationPlan.swift` — schema chain V1→V8, lightweight migration stages
- Codebase direct read: `SchemaV8.swift` — current `UserProfile` model fields
- Codebase direct read: `SchemaV6.swift` — current `Goal` model fields including `isPublic`, `durationDays`
- Codebase direct read: `ProgressRingView.swift` — `Circle().trim()` pattern, reduced motion handling
- Codebase direct read: `ApplauseButtonView.swift` — float animation, disabled state opacity
- Codebase direct read: `ExploreView.swift` — current 6-section structure, `sectionLabel` pattern
- Codebase direct read: `VGTheme.swift` — confirmed token names `accentTerra`, `accentSage`, `accentGold`, `surface`, `textMuted`, `separator`
- Codebase direct read: `VitaminGApp.swift` — `.task` launch hook pattern, fire-and-forget Task usage
- Codebase direct read: `InputSanitizer.swift` — `sanitizeForPublic()` strips `<>"'`
- Codebase direct read: `GoalViewModel.swift` — `addCheckIn()` structure, fire-and-forget Task at line 181
- Codebase direct read: `PublicProfileViewModelTests.swift` — `fetchOverride` closure type that must be updated
- Codebase direct read: `Phase21ApplauseDailyGateTests.swift` — injectable `UserDefaults` test pattern
- `22-CONTEXT.md` — all locked decisions D-01 through D-17
- `22-UI-SPEC.md` — component dimensions, colors, typography, interaction specs

### Secondary (MEDIUM confidence)
- Apple Developer Documentation (`[VERIFIED: Apple Developer Documentation]`): `.searchable` modifier must be on NavigationStack ancestor for `isSearching` to propagate correctly

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all Apple frameworks; no new packages; verified in codebase
- Architecture patterns: HIGH — all patterns traced directly to existing codebase implementations
- Pitfalls: HIGH — migration pitfall and .searchable placement verified from prior phase patterns; CloudKit index requirement is a known constraint (explicitly noted in STATE.md pending todos)
- Test map: MEDIUM — test file names are prescribed, not yet created; XCTest runner command assumed correct for existing scheme

**Research date:** 2026-05-24
**Valid until:** 2026-06-24 (Apple framework APIs stable; CloudKit public DB API stable)
