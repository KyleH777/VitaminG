# Phase 22: Public Profile + Follow + Discover - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Redesign `PublicProfileView` from the minimal Phase 17 avatar+name stub into a full social profile card (PROF-01–04): stats row (streak, goal count, cheers given), Follow button with CloudKit persistence, Cheer button reusing Phase 21 applause mechanics, and a list of the user's public goals with progress rings. Expand the `PublicProfile` CKRecord to carry the new stat fields. Add a `Follow` CKRecord type for the follow relationship. Introduce a new `PublicGoal` CKRecord type to back goal indexing. Implement Discover search (DISC-01–04) as a `.searchable` overlay on `ExploreView`: keyword goal search, username-prefix people search, Trending Challenges when search is empty, and a Join action that creates a local SwiftData goal with user-selected tier.

</domain>

<decisions>
## Implementation Decisions

### Discover UI Placement (DISC-01–04)
- **D-01:** Discover lives inside `ExploreView` via the `.searchable` modifier — search bar appears at the top of the Explore tab. No new tab is added; the 5-tab structure (TAB-01) is preserved.
- **D-02:** When search is active and `searchText` is empty (`isSearching == true`, `searchText == ""`): collapse ExploreView's 6 normal sections entirely and show `TrendingChallengesSection` (DISC-03) in their place.
- **D-03:** When search is active and `searchText` is non-empty: show a segment control (`Picker` in `.segmented` style: "Goals" / "People") above a `LazyVStack` of result cards (`GoalSearchResultCard` / `PeopleSearchResultCard`). Collapse all ExploreView sections.
- **D-04:** When search is inactive (`isSearching == false`): show ExploreView normally with its 6 existing sections (including the ChallengeDiscovery section already at the bottom). Trending Challenges visible in both idle and active-empty states — mutually exclusive rendering, not a duplicate.

### PublicProfile Data Expansion (PROF-01)
- **D-05:** Expand the existing `PublicProfile` CKRecord (type already in use by `ProfileSharingService`) with three new fields: `streakLength` (Int64), `goalCount` (Int64), `motto` (String). No new CKRecord type — same record, same `recordName = appleUserID` keying strategy.
- **D-06:** Profile photos (`photoData`) remain excluded from `PublicProfile` per the T-07-08 security decision from Phase 17. `AvatarView` on `PublicProfileView` continues to use initials + `avatarColorHex` only (`photoData: nil`). No CKAsset added in this phase.
- **D-07:** Motto/bio is editable from the existing `ProfileView` (self-view). A "Motto" text field (≤100 chars, same sanitization as `displayName`) is added to the profile editing surface. Saving triggers `ProfileSharingService.publishProfile()` republish.
- **D-08:** `PublicProfile` republish cadence: on app launch (after successful auth) AND after every successful goal check-in. Check-in is the primary event that changes streak (the most visible profile stat). Goal create/complete changes are picked up on the next launch. This balances freshness with write quota.

### Public Goal Indexing (DISC-01, DISC-04)
- **D-09:** New `PublicGoal` CKRecord type written to CloudKit public DB. Fields: `title` (String), `category` (String), `creatorUsername` (String), `participantCount` (Int64), `progressPercent` (Int64), `durationDays` (Int64), `creationEpoch` (Int64). Record name: `goal.id.uuidString` for stable identity.
- **D-10:** A `PublicGoal` record is written when a goal is created with `isPublic == true` (GOAL2-01 toggle). When a goal is toggled from public→private or completed: the `PublicGoal` record is deleted. Store the CloudKit recordID in a new `cloudKitPublicGoalRecordID: String?` field on the SwiftData `Goal` model (lightweight migration — optional with nil default).
- **D-11:** Backfill on first Phase 22 launch: at app open, iterate all local `Goal` records where `isPublic == true && cloudKitPublicGoalRecordID == nil` and write `PublicGoal` records for them. This is a one-time operation (once `cloudKitPublicGoalRecordID` is set, the goal is already indexed). Run concurrently with the profile republish at launch.
- **D-12:** Progress sync cadence: same as PublicProfile republish — on app launch + after check-in. Updates `progressPercent` and `participantCount` on owned public goals.

### Follow System (PROF-02)
- **D-13:** New `Follow` CKRecord type in CloudKit public DB. Fields: `followerUsername` (String), `followeeUsername` (String), `createdAt` (Int64 epoch). Record name: `"\(followerUsername)_\(followeeUsername)"` for deterministic deduplication (follow is one-time, no unfollow in v2.0).
- **D-14:** Follow state on `PublicProfileView` load: query CloudKit public DB for a `Follow` record matching the current user's username as `followerUsername` and the viewed user's username as `followeeUsername`. Result drives `FollowButton` initial state (`.idle` or `.followed`). One query per profile open — authoritative, no local cache needed. No unfollow UI exists; `.followed` state is terminal.

### Join Goal (DISC-04)
- **D-15:** Tapping Join on a `GoalSearchResultCard` presents a mini tier-picker sheet: "Which type of goal is this for you?" with the four tiers (Immediate · Daily · Monthly · Life Goal). User selection creates a new SwiftData `Goal` with the public goal's `title`, `category` mapped to matching `GoalCategory`, the selected `tierRawValue`, `isPublic = false` (joined copies are private by default), and `creationDate = now`.
- **D-16:** Participant count increment: after local `Goal` creation, update the source `PublicGoal` CKRecord's `participantCount` field using CloudKit atomic increment (fetch + `+1` + save, same pattern as `CommunityService.reactToPost()`). On failure: log silently; the local goal is kept (don't roll back a successfully created goal over a count write failure).

### Cheer + Applause (PROF-03)
- **D-17:** CheerButton on `PublicProfileView` reuses `CommunityService`'s existing applause write path (Phase 21). Daily limit tracked via `UserDefaults` date-keyed dictionary `[recipientUsername: lastCheerDate]` — same pattern as `vg_explore_gifterDate` and Phase 21 D-04. `canCheerToday` computed in `PublicProfileViewModel`.

### Claude's Discretion
- `DiscoverViewModel` implements 500ms search debounce using `Task.sleep(for: .milliseconds(500))` inside an `async` search function, resetting on each keystroke via cancellation of the previous task. Simpler than Combine `debounce` for this codebase's async/await style.
- `PublicGoalCard` on `PublicProfileView`: uses a local `Circle().trim()` implementation (per UI-SPEC §1) rather than the existing `ProgressRingView` which requires `GoalTier`.
- `PublicProfileViewModel` state enum expands from `loaded(displayName, avatarColorHex)` to `loaded(profile: PublicProfileData)` where `PublicProfileData` is a lightweight struct carrying all PROF-01 fields.
- `ProfileSharingService.fetchProfile()` expands to return a `PublicProfileData` struct instead of the current `(displayName, avatarColorHex)` tuple — same call site, additive return type.
- The `motto` field on the SwiftData `UserProfile` model: add as `var motto: String? = nil` with `@Attribute` on SchemaV3 (new schema version for Phase 22, lightweight migration).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Requirements
- `.planning/ROADMAP.md` §Phase 22 — goal, success criteria, requirements list (PROF-01–04, DISC-01–04)
- `.planning/REQUIREMENTS.md` §PROF-01–PROF-05, §DISC-01–DISC-04 — full requirement definitions
- `.planning/phases/22-public-profile-follow-discover/22-UI-SPEC.md` — visual and interaction contract; component specs (PublicGoalCard, FollowButton, CheerButton, GoalSearchResultCard, PeopleSearchResultCard, TrendingChallengesSection), layout specs for PublicProfileView and DiscoverView, copywriting, colors, accessibility — **source of truth for all UI decisions**

### Views to Redesign / Create
- `VitaminG/VitaminG/VitaminG/Views/PublicProfileView.swift` — full redesign per UI-SPEC §PublicProfileView; current implementation is Phase 17 minimal stub
- `VitaminG/VitaminG/VitaminG/Views/Explore/ExploreView.swift` — add `.searchable` + Discover overlay; existing 6 sections stay intact in non-search state
- Create `VitaminG/VitaminG/VitaminG/Views/Discover/DiscoverView.swift` (or inline in ExploreView) — segment control, GoalSearchResultCard list, PeopleSearchResultCard list, empty/error states

### ViewModels to Expand / Create
- `VitaminG/VitaminG/VitaminG/ViewModels/PublicProfileViewModel.swift` — expand `ViewState.loaded` to carry full `PublicProfileData`; add follow state query, cheer daily limit logic
- Create `VitaminG/VitaminG/VitaminG/ViewModels/DiscoverViewModel.swift` — debounced search, Goals/People segment, CloudKit queries, Join action

### Services to Extend
- `VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift` — expand `publishProfile()` to write `streakLength`, `goalCount`, `motto`; expand `fetchProfile()` to return full `PublicProfileData`; add `fetchFollowState()` and `writeFollow()` methods
- `VitaminG/VitaminG/VitaminG/Services/CommunityService.swift` — add `fetchApplauseGivenCount()` already exists; reuse applause write path for CheerButton (D-17)
- Create `VitaminG/VitaminG/VitaminG/Services/PublicGoalService.swift` — write/delete/search `PublicGoal` records; `writePublicGoal()`, `deletePublicGoal()`, `backfillPublicGoals()`, `searchGoals(keyword:)`, `searchPeople(usernamePrefix:)`, `incrementParticipantCount(recordName:)`

### Data Models
- `VitaminG/VitaminG/VitaminG/Models/Schema8pV2.swift` — `Goal.isPublic` already present; add `Goal.cloudKitPublicGoalRecordID: String? = nil` in new schema version
- `VitaminG/VitaminG/VitaminG/Models/SchemaV8.swift` — `UserProfile.photoData`, `.isPublic`, `.username` present; add `UserProfile.motto: String? = nil` in new schema version

### Prior Phase Context
- `.planning/phases/21-community-tab-redesign/21-CONTEXT.md` — D-02: Today's Glimpses tap navigates to `PublicProfileView` (Phase 22 expands it); D-04: applause daily gate via UserDefaults pattern to reuse; D-05: floating 👏 animation pattern; CommunityService applause write path
- `.planning/phases/20-explore-tab/20-CONTEXT.md` — ExploreView architecture; `.searchable` must layer on top without disrupting Phase 20 sections
- `.planning/phases/17-onboarding-overhaul/17-CONTEXT.md` — T-07-08 security decision (photoData excluded from PublicProfile); report/block pattern on PublicProfileView; `ProfileSharingService.publishProfile()` write path

### Design and Theme
- `VitaminG/VitaminG/VitaminG/VGTheme.swift` — color system (accentTerra for Follow/Join, accentSage for "Following" state, accentGold for CheerButton), typography, spacing

### State Decisions
- `.planning/STATE.md` — `CKAsset fileURL must be copied immediately` constraint; `No SchemaV9 required` decision (still applies — new fields use lightweight migration); daily gate UserDefaults pattern

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AvatarView` (existing): `displayName`, `avatarColorHex`, `photoData`, `size` — use with `photoData: nil` and `size: 80` on PublicProfileView, `size: 40` on PeopleSearchResultCard
- `ApplauseButtonView` (Phase 21): floating 👏 animation, reduced motion handling, daily gate pattern — CheerButton reuses this mechanic directly
- `CommunityService.fetchApplauseGivenCount()` (Phase 21): already implemented; used for PROF-01 cheers given stat
- `CommunityService` applause write path (Phase 21): reused by CheerButton for PROF-03
- `CommunityService.reactToPost()` (fetch + increment + save): pattern to reuse for participant count increment in D-16
- `BlockListService.blockUser()` + `MailComposeView` (Phase 17): already in `PublicProfileView`; carry forward, do not remove
- `InputSanitizer.sanitizeForPublic()`: apply to `motto` field before write, and to goal title/category in PublicGoal records
- `ProgressRingView` (existing): NOT used for PublicGoalCard (requires `GoalTier`); use local `Circle().trim()` instead

### Established Patterns
- CloudKit public DB write: `CKContainer.default().publicCloudDatabase.save(record)` — see `CommunityService.createPost()` for established pattern
- Daily gate via UserDefaults: `EXPLORE-02` gifter, `EXPLORE-06` stuck-day gifts, Phase 21 D-04 applause limit — `[username: Date]` dictionary keyed in UserDefaults. CheerButton follows this exact pattern.
- `@MainActor @Observable` ViewModel with `async` CloudKit fetching: standard pattern; `DiscoverViewModel` and expanded `PublicProfileViewModel` follow this
- CloudKit predicate substring search: `NSPredicate(format: "title CONTAINS[cd] %@", keyword)` for DISC-01 goal search; `NSPredicate(format: "username BEGINSWITH[cd] %@", prefix)` for DISC-02 people search
- Record name as stable identity: `ProfileSharingService` uses `recordName = appleUserID`; `PublicGoal` uses `recordName = goal.id.uuidString` — consistent approach

### Integration Points
- `ExploreView`: add `.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))` and `@Environment(\.isSearching)` to drive section collapse
- `GoalViewModel.addCheckIn()` (Phase 18): hook `ProfileSharingService.publishProfile()` + `PublicGoalService.syncOwnedPublicGoals()` call here for the post-check-in republish (D-08, D-12)
- `VitaminGApp.swift` (app entry point): add `PublicGoalService.backfillPublicGoals()` + `ProfileSharingService.publishProfile()` to the `onAppear` / post-auth launch sequence
- `ContentView.swift`: `PublicProfileView` already presented as `.sheet` from multiple surfaces (Community tab Phase 21, deep links Phase 10) — Phase 22 redesign maintains `.sheet` presentation
- `ProfileView.swift` (self-view): add motto text field (editable) and trigger `publishProfile()` on save

</code_context>

<specifics>
## Specific Ideas

- The FollowButton state machine matches the UI-SPEC exactly: `.idle` → `.loading` (disabled, inline ProgressView) → `.followed` (accentSage background, "Following" label). Spring animation `.spring(response: 0.35, dampingFraction: 0.75)` on transition. Follow is terminal — no unfollow.
- CheerButton uses `VGTheme.accentGold` (not terra) to distinguish from navigation CTAs. Disabled state is `.opacity(0.35)` only — no color swap.
- Discover search debounce: 500ms via `Task.sleep` + task cancellation pattern (cancel previous search Task on each keystroke). Consistent with codebase's async/await style over Combine.
- Join tier-picker: presented as a `.confirmationDialog` or a compact `.sheet` with four tier buttons. Dismisses after selection, goal creation begins immediately.
- Error banner on FollowButton failure: inline `Text(...)` below button, fades in, auto-hides after 3 seconds. Consistent with Phase 21 applause error handling.

</specifics>

<deferred>
## Deferred Ideas

- Profile photos on public profiles (CKAsset in PublicProfile): excluded per T-07-08 security decision. Defer to a dedicated "profile media" phase.
- Unfollow / follow management: Phase 22 follow is one-way and terminal (PROF-02 requirement). Unfollow deferred to future phase.
- Follow-based community feed filtering: community feed stays global in v2.0 (Phase 21 D-07). Follow relationship affects profile display only in Phase 22.
- Full-text goal search (Algolia etc.): CloudKit substring predicate is sufficient for MVP (see REQUIREMENTS.md §143 note).

</deferred>

---

*Phase: 22-public-profile-follow-discover*
*Context gathered: 2026-05-24*
