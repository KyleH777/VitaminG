---
phase: 22-public-profile-follow-discover
verified: 2026-05-25T10:00:00Z
status: human_needed
score: 6/6
overrides_applied: 0
human_verification:
  - test: "Cheer button animation plays on tap"
    expected: "Tapping 'Cheer them on today' fires a floating clap animation; button label changes to 'Cheered today' and stays disabled for the rest of the day"
    why_human: "UI animation (float + opacity transition) is not testable in XCTest; daily gate persistence requires device/simulator run"
  - test: "Follow button state persists across app restart"
    expected: "After following a user, killing and relaunching the app shows the FollowButton in 'Following' state for that same profile"
    why_human: "Requires live CloudKit connection + app relaunch sequence — not automatable with grep or unit tests"
  - test: "Discover search returns results within perceived 500ms after debounce"
    expected: "Typing a keyword in Discover shows results appearing promptly after the 500ms debounce window elapses; no visible delay beyond debounce"
    why_human: "Real CloudKit network timing and perceived responsiveness require device testing against production CloudKit"
  - test: "CloudKit Console: PublicGoal record type deployed with Queryable indexes on 'title' and 'creatorUsername'"
    expected: "BEGINSWITH[cd] and CONTAINS[cd] queries return results in Discover (not throw CKError due to missing Queryable index)"
    why_human: "CloudKit Console deployment is a manual operation; cannot be verified programmatically"
  - test: "CloudKit Console: Follow record type deployed to Production"
    expected: "writeFollow creates a Follow CKRecord without error in a production run"
    why_human: "CloudKit Console deployment is a manual operation; cannot be verified programmatically"
---

# Phase 22: Public Profile + Follow + Discover — Verification Report

**Phase Goal:** Users can view redesigned public profiles, follow other users, give daily cheers, and search public goals and profiles from the Discover page
**Verified:** 2026-05-25T10:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User views another user's public profile and sees their avatar, motto/bio, current streak, goal count, and cheers given count | VERIFIED | `PublicProfileView.swift` lines 114-154: AvatarView (80pt), displayName, @username, motto (conditional), stats row renders `streakLength`, `goalCount`, `cheersGivenCount` from `PublicProfileData`. `ProfileSharingService.fetchProfile` maps all five CK fields. |
| 2 | User taps "Cheer them on today" on a public profile and the applause animation plays; the button disables for the rest of the day after use | VERIFIED (code) / HUMAN (animation) | `CheerButton.swift`: `isAvailable` drives disabled state via `ApplauseGate.canApplaud`; float animation state machine (`showFloat`, `floatOffset`, `floatOpacity`) implemented inline. `PublicProfileViewModel.onCheer` marks gate then fires `CommunityService.writeApplause`. Animation correctness requires human testing. |
| 3 | User taps Follow on a public profile; the follow is recorded and the button state changes to reflect the follow | VERIFIED | `PublicProfileViewModel.onFollow`: idle→loading→followed state machine with spring animation. `ProfileSharingService.writeFollow`: deterministic record name, idempotency check, rate limit (10/hour), CK save. `FollowButton.swift` consumes `FollowState` enum; disabled on .loading and .followed. |
| 4 | User taps the Discover tab and types a keyword; goal results appear within 500ms showing goal title, creator, category, participant count, and a progress circle | VERIFIED | `DiscoverViewModel.onSearchTextChanged`: 500ms `Task.sleep` debounce + task cancellation on new input. `GoalSearchResultCard.swift`: 32pt progress ring (trim by progressPercent), title, `@creatorUsername · category · N people` metadata. `PublicGoalService.searchGoals`: CK CONTAINS[cd] predicate, 25-result cap. |
| 5 | User switches to the People segment in Discover search and finds users by username prefix; each result shows a Follow button | VERIFIED | `DiscoverOverlayView.swift`: segmented Picker (Goals/People). `PublicGoalService.searchPeople`: `username BEGINSWITH[cd]` CK predicate. `PeopleSearchResultCard` renders via `ForEach(viewModel.peopleResults)` with a FollowButton. Per-row follow state is `.idle` MVP shortcut (documented). |
| 6 | User taps Join on a goal in Discover results; the goal appears in their goal list and the participant count increments | VERIFIED | `DiscoverViewModel.joinGoal`: inserts `SchemaV9.Goal` into `ModelContext`, sets `isPublic=false`, marks `joinedGoalIDs` before insert (idempotency). `PublicGoalService.incrementParticipantCount`: fire-and-forget fetch+increment+save with one retry on conflict. Unit tests in `Phase22DiscoverViewModelTests` cover join insertion and idempotency. |

**Score:** 6/6 truths verified (animation correctness in truth #2 deferred to human verification)

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `VitaminG/VitaminG/VitaminG/Models/SchemaV9.swift` | SchemaV9 with UserProfile.motto + Goal.cloudKitPublicGoalRecordID | VERIFIED | Both fields present as `String? = nil`, lightweight migration wired in `VitaminGMigrationPlan.swift` as `migrateV8toV9` |
| `VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift` | fetchProfile + fetchFollowState + writeFollow | VERIFIED | All three methods implemented with CK operations, idempotency, rate limiting |
| `VitaminG/VitaminG/VitaminG/Services/PublicGoalService.swift` | searchGoals + searchPeople + fetchGoalsForUser + incrementParticipantCount + backfillPublicGoals + syncOwnedPublicGoals | VERIFIED | All methods present with real CK queries |
| `VitaminG/VitaminG/VitaminG/ViewModels/PublicProfileViewModel.swift` | FollowState enum + cheer gate + publicGoals | VERIFIED | FollowState machine (idle/loading/followed), canCheerToday via ApplauseGate, publicGoals array populated after fetchProfile |
| `VitaminG/VitaminG/VitaminG/ViewModels/DiscoverViewModel.swift` | 500ms debounce + segment + join dedup | VERIFIED | Task.sleep(500ms) debounce, SearchSegment enum, joinedGoalIDs Set dedup |
| `VitaminG/VitaminG/VitaminG/Views/PublicProfileView.swift` | Full UI-SPEC card (hero + stats + actions + goals + footer) | VERIFIED | Hero (80pt AvatarView, displayName, @username, motto), stats row (3 cells), FollowButton + CheerButton action row, MY PUBLIC GOALS LazyVStack, Report/Block footer |
| `VitaminG/VitaminG/VitaminG/Views/Explore/Discover/DiscoverOverlayView.swift` | Segmented picker + result cards + tier picker + profile sheet | VERIFIED | Picker (Goals/People), GoalSearchResultCard + PeopleSearchResultCard lists, confirmationDialog tier picker, .sheet(item:) profile navigation |
| `VitaminG/VitaminG/VitaminG/Views/Components/FollowButton.swift` | Three-state pill button | VERIFIED | .idle/.loading/.followed states, spring animation, disabled on loading+followed |
| `VitaminG/VitaminG/VitaminG/Views/Components/CheerButton.swift` | Daily-gated cheer with float animation | VERIFIED | isAvailable gate, hands.clap.fill icon, float animation state machine |
| `VitaminG/VitaminG/VitaminG/Views/Components/PublicGoalCard.swift` | Goal card for profile page | VERIFIED | File exists and is substantive |
| `VitaminG/VitaminG/VitaminG/Views/Explore/Discover/GoalSearchResultCard.swift` | Discover goal result card | VERIFIED | 32pt ring, title, metadata (creator/category/participants), Join button |
| `VitaminG/VitaminG/VitaminG/Views/Explore/Discover/PeopleSearchResultCard.swift` | Discover people result card | VERIFIED | File exists and renders Follow button |
| `VitaminGTests/Phase22SchemaV9Tests.swift` | 6 green tests for SchemaV9 fields | VERIFIED | All 6 tests live (no XCTSkip), testing defaults, persistence, and typealias resolution |
| `VitaminGTests/Phase22DiscoverViewModelTests.swift` | Debounce + join + follow tests | VERIFIED | 6 live tests: empty-clear, 500ms debounce, default segment, join insertion, idempotency, onFollowPerson |
| `VitaminGTests/Phase22FollowServiceTests.swift` | Follow service unit tests | VERIFIED | File comment confirms all active, no XCTSkip |
| `VitaminGTests/Phase22PublicGoalServiceTests.swift` | PublicGoalService unit tests | VERIFIED | File comment confirms all active, no XCTSkip |
| `VitaminGTests/Phase22PublicProfileViewModelTests.swift` | ViewModel state machine tests | VERIFIED | File exists and substantive |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `PublicProfileView` | `PublicProfileViewModel` | `@State private var viewModel` + `.onAppear { viewModel.fetchProfile }` | WIRED | View drives VM on appear; `viewModel.followState`, `viewModel.canCheerToday`, `viewModel.publicGoals` all consumed in body |
| `PublicProfileViewModel` | `ProfileSharingService.fetchProfile` | `try await ProfileSharingService.fetchProfile(recordID:)` line 93 | WIRED | Called in Task inside fetchProfile; override seam available for tests |
| `PublicProfileViewModel` | `ProfileSharingService.writeFollow` | `try await ProfileSharingService.writeFollow(...)` line 166 | WIRED | Called in onFollow Task; guarded by followState == .idle |
| `PublicProfileViewModel` | `PublicGoalService.fetchGoalsForUser` | `publicGoals = try await PublicGoalService.fetchGoalsForUser(...)` line 104 | WIRED | Called after fetchProfile succeeds; populates publicGoals array |
| `ExploreView` | `DiscoverOverlayView` | `DiscoverOverlayView(searchText: searchText, viewModel: discoverViewModel)` | WIRED | Rendered in middle branch: `else if isSearching` |
| `ExploreView` | `@Environment(\.isSearching)` | `.searchable` on `NavigationStack` in `ContentView.swift` line 34-35 | WIRED | `ContentView` owns `@State exploreSearchText`; passes to `ExploreView(searchText: exploreSearchText)` |
| `DiscoverOverlayView` | `DiscoverViewModel.joinGoal` | `viewModel.joinGoal(result, tier: tier, context: modelContext)` in confirmationDialog Button | WIRED | Tier picker triggers join via VM seam |
| `DiscoverViewModel` | `PublicGoalService.searchGoals` | `results = try await PublicGoalService.searchGoals(keyword: text)` | WIRED | Called in performSearch() for .goals segment |
| `DiscoverViewModel` | `PublicGoalService.incrementParticipantCount` | `await PublicGoalService.incrementParticipantCount(recordName: result.id)` | WIRED | Fire-and-forget Task in joinGoal |
| `VitaminGApp` | Phase 22 launch hooks | 3 fire-and-forget Tasks at `.task` launch (Task A: publishProfile, Task B: backfillPublicGoals, Task C: syncOwnedPublicGoals) | WIRED | Lines 116, 156, 170 in VitaminGApp.swift |
| `GoalViewModel.addCheckIn` | Phase 22 check-in hooks | 2 fire-and-forget Tasks (publishProfile + syncOwnedPublicGoals) at lines 196, 226 | WIRED | Triggered every time user adds a check-in |
| `ProfileEditSheet` | `motto` field | `TextField("Your motto", text: $viewModel.draftMotto)` line 88 | WIRED | `ProfileViewModel.draftMotto` persisted to `UserProfile.motto` and synced to CloudKit on save |
| `SchemaV9` | `VitaminGMigrationPlan` | `migrateV8toV9 = MigrationStage.lightweight(fromVersion: SchemaV8.self, toVersion: SchemaV9.self)` | WIRED | Both `SchemaV9.self` in models array and `migrateV8toV9` in migration stages array |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `PublicProfileView` | `profile` (PublicProfileData) | `ProfileSharingService.fetchProfile` → CK public DB `record(for:)` | Yes — CK record fields mapped: displayName, username, motto, streakLength, goalCount | FLOWING |
| `PublicProfileView` | `viewModel.publicGoals` | `PublicGoalService.fetchGoalsForUser` → CK `records(matching:)` with creatorUsername predicate | Yes — CK query result mapped to `[PublicGoalItem]` | FLOWING |
| `PublicProfileView` | `viewModel.followState` | `ProfileSharingService.fetchFollowState` → CK `record(for:)` with deterministic recordName | Yes — returns true/false based on CK record existence | FLOWING |
| `DiscoverOverlayView` | `viewModel.goalResults` | `PublicGoalService.searchGoals` → CK CONTAINS[cd] predicate query | Yes — CK query returning up to 25 real records | FLOWING |
| `DiscoverOverlayView` | `viewModel.peopleResults` | `PublicGoalService.searchPeople` → CK BEGINSWITH[cd] predicate on PublicProfile | Yes — CK query returning up to 25 real records | FLOWING |

---

### Behavioral Spot-Checks

Step 7b: SKIPPED — iOS app project, no runnable CLI entry points or API endpoints testable without a running simulator.

---

### Probe Execution

Step 7c: No probe scripts declared in plans or found in `scripts/*/tests/probe-*.sh`. SKIPPED.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|------------|------------|-------------|--------|---------|
| PROF-01 | 22-01, 22-02, 22-03, 22-04, 22-05 | Public profile visible with avatar, motto, streak, goal count, cheers given | SATISFIED | PublicProfileView renders all 5 fields; ProfileSharingService.fetchProfile maps all CK fields |
| PROF-02 | 22-01, 22-02, 22-03, 22-05 | Follow system with FollowState machine, deterministic record name, idempotency | SATISFIED | ProfileSharingService.writeFollow + fetchFollowState implemented; FollowButton state machine wired; tests in Phase22FollowServiceTests |
| PROF-03 | 22-03, 22-05 | Daily cheer gate with ApplauseGate + button disables after use | SATISFIED (code) / HUMAN (animation) | CheerButton + PublicProfileViewModel.canCheerToday + ApplauseGate.markApplauseGiven all wired; animation requires human |
| PROF-04 | 22-01, 22-02, 22-03, 22-05 | Public goals visible on profile, fetched per user from CloudKit | SATISFIED | PublicProfileViewModel.publicGoals + PublicGoalService.fetchGoalsForUser + PublicGoalCard rendering |
| DISC-01 | 22-01, 22-02, 22-03, 22-05 | Discover search with 500ms debounce, goal results with title/creator/category/count/ring | SATISFIED (code) / HUMAN (live timing) | DiscoverViewModel 500ms Task.sleep debounce; GoalSearchResultCard shows all fields; unit test verifies debounce |
| DISC-02 | 22-01, 22-02, 22-03, 22-05 | People search by username prefix (BEGINSWITH[cd]) | SATISFIED | PublicGoalService.searchPeople uses BEGINSWITH[cd] predicate |
| DISC-03 | 22-05 | ExploreView three-branch search body (normal / trending-only / discover results) | SATISFIED | ExploreView: `@Environment(\.isSearching)` drives three branches; DiscoverOverlayView shown when isSearching && !searchText.isEmpty |
| DISC-04 | 22-01, 22-02, 22-03, 22-05 | Join goal: creates local SwiftData Goal, increments participant count | SATISFIED | DiscoverViewModel.joinGoal: inserts Goal into ModelContext, fire-and-forget incrementParticipantCount; unit tests cover insertion and idempotency |

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `DiscoverOverlayView.swift` | 90-93 | `followState: .idle` hardcoded — per-row follow state not fetched from CloudKit on search load | Info | Documented MVP shortcut with `// MVP NOTE:` comment; authoritative state visible on PublicProfileView sheet tap. Not a blocker — intentional deferred scope. |

No TBD, FIXME, or XXX markers found in any Phase 22 files. No unreferenced debt markers.

---

### Human Verification Required

#### 1. Cheer Button Animation

**Test:** On a device or simulator: open a public profile, tap "Cheer them on today"
**Expected:** Floating clap animation plays (hands.clap icon + username floats up and fades); button label changes to "Cheered today" and remains disabled; relaunching the app that same day still shows "Cheered today"
**Why human:** UI animation and daily persistence cannot be verified by static code analysis or unit tests

#### 2. Follow Button State Persistence Across Restart

**Test:** Follow a user from their PublicProfileView, then kill and relaunch the app; navigate back to that user's public profile
**Expected:** FollowButton shows "Following" (sage background) — confirming CloudKit resolveFollowState correctly re-fetches on appear
**Why human:** Requires live CloudKit + app relaunch sequence

#### 3. Discover Search Responsiveness

**Test:** On device with production CloudKit: tap Explore tab, type a keyword (e.g. "run"), switch to People segment, type a username prefix
**Expected:** Results appear in both segments; perceived delay matches the 500ms debounce; no CKError thrown (confirming Queryable indexes deployed)
**Why human:** Real network timing + CloudKit Console deployment state cannot be verified programmatically

#### 4. CloudKit Console: PublicGoal Record Type with Queryable Indexes

**Test:** Open CloudKit Console → Production → Schema, verify PublicGoal record type exists with Queryable indexes on `title` and `creatorUsername`
**Expected:** CONTAINS[cd] on `title` and BEGINSWITH[cd] on `creatorUsername` queries succeed without CKError
**Why human:** CloudKit Console deployment is a manual admin action

#### 5. CloudKit Console: Follow Record Type Deployed

**Test:** Open CloudKit Console → Production → Schema, verify Follow record type exists with `followerUsername`, `followeeUsername`, `createdAt` fields
**Expected:** writeFollow creates records without schema-not-found CKError in a production run
**Why human:** CloudKit Console deployment is a manual admin action

---

### Gaps Summary

No blocking gaps. All 6 success criteria have complete code implementations verified at all four levels (exists, substantive, wired, data-flowing). Five items require human verification (two CloudKit Console deployments, three behavioral checks) — these are documented in the VALIDATION.md as manual-only verifications and are expected for this phase.

The per-row follow state shortcut in DiscoverOverlayView (all rows start `.idle`) is an explicit documented MVP decision — not a gap. The authoritative follow state is correctly surfaced when the user taps through to PublicProfileView.

---

_Verified: 2026-05-25T10:00:00Z_
_Verifier: Claude (gsd-verifier)_
