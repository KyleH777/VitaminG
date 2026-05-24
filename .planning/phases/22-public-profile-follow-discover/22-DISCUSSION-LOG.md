# Phase 22: Public Profile + Follow + Discover - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-24
**Phase:** 22-public-profile-follow-discover
**Areas discussed:** Discover UI placement, PublicProfile data expansion, Public goal indexing + Join, Profile photo, Follow state persistence, Goal backfill

---

## Discover UI Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Search bar at top of Explore tab (.searchable) | Add `.searchable` to ExploreView. When field empty, show existing sections. When active, collapse them and show DiscoverView content. Minimal routing change. | ✓ |
| Toolbar magnifier → standalone DiscoverView | Add magnifying glass button in ExploreView that navigates to a new DiscoverView (pushed via NavigationStack). Extra navigation step. | |
| Separate Discover tab | 6th tab "Discover" — breaks the fixed 5-tab TAB-01 structure. | |

**User's choice:** Search bar at top of Explore tab (.searchable)
**Notes:** ExploreView sections collapse when search is active + non-empty. When active + empty: show TrendingChallengesSection (DISC-03). When inactive: normal ExploreView with all 6 sections.

---

## Search Active State — Section Collapse

| Option | Description | Selected |
|--------|-------------|----------|
| Collapse completely — show only search results | Standard iOS search behavior. Existing sections disappear when search active. | ✓ |
| Scroll below results | Existing sections stay below result cards. Creates confusing mixed-content scroll. | |

**User's choice:** Collapse completely
**Notes:** Consistent with system Mail, App Store search behavior.

---

## Search Empty State

| Option | Description | Selected |
|--------|-------------|----------|
| Normal Explore sections (no Discover content visible) | 6 Explore sections render normally when search not typed. | |
| Trending Challenges section pre-loaded below Explore sections | DISC-03 TrendingChallengesSection shown when search is active but empty. | ✓ |

**User's choice:** Trending Challenges section pre-loaded below Explore sections
**Notes:** Clarified: TrendingChallengesSection shows in the `isSearching && searchText.isEmpty` state (search bar focused but nothing typed). When search is inactive (`isSearching == false`), normal ExploreView renders including the existing ChallengeDiscovery Section 6. Mutually exclusive — not a duplicate.

---

## PublicProfile Data Expansion

| Option | Description | Selected |
|--------|-------------|----------|
| Expand PublicProfile CKRecord + republish at app launch | Add streakLength, goalCount, motto fields. Single record, no new CKRecord type. | ✓ |
| Compute from existing CloudKit data at fetch time | Derive streak+count from GoalGlimpse records. Multi-query, motto still needs a home. | |
| You decide | Claude picks simplest approach. | |

**User's choice:** Expand PublicProfile CKRecord + republish at app launch

---

## Motto/Bio Editing Surface

| Option | Description | Selected |
|--------|-------------|----------|
| Add to existing ProfileView or Settings | Motto text field in existing ProfileView (self-view). Triggers publishProfile() on save. | ✓ |
| First-time prompt on PublicProfileView when empty | Inline "Add a motto…" prompt when user views own profile. | |
| Skip motto — stats only | Defer motto entirely. | |

**User's choice:** Add to existing profile/settings flow — ProfileView or Settings

---

## Profile Republish Cadence

| Option | Description | Selected |
|--------|-------------|----------|
| App launch only | Republish once at app open. Streak/count may be up to 24h stale. Simple. | |
| App launch + after every check-in / goal create / complete | Always-fresh stats but adds CloudKit writes to hot-path. | |
| You decide | Balance freshness vs. write quota. | ✓ |

**User's choice:** You decide
**Notes (Claude's choice):** App launch + after check-in only. Check-in changes streak (most visible stat). Goal create/complete picked up on next launch.

---

## Public Goal Indexing CKRecord

| Option | Description | Selected |
|--------|-------------|----------|
| New PublicGoal CKRecord type (written when isPublic toggle is ON) | Separate searchable index. Matches GOAL2-01 public/private intent. | |
| Reuse existing ChallengeTemplate records | No new type. Conflates challenges with personal public goals. | |
| You decide | Pick based on GOAL2-01 intent. | ✓ |

**User's choice:** You decide
**Notes (Claude's choice):** New `PublicGoal` CKRecord type. Personal public goals and community challenges are distinct entities — conflating them breaks the GOAL2-01 public/private toggle semantics.

---

## Join Goal Mechanics

| Option | Description | Selected |
|--------|-------------|----------|
| Create local SwiftData Goal + user picks tier at join | Mini tier-picker sheet before creation. Respects Vitamin G's core tier concept. | ✓ |
| Default to Daily tier — no picker | Simpler, no extra UI. But tier is core to the app. | |
| Create Goal with no tier — user edits later | Requires schema change and nil tier handling. Over-engineered. | |

**User's choice:** Create a local SwiftData Goal copying title + category — user picks tier at join

---

## Public Goal Progress Sync Cadence

| Option | Description | Selected |
|--------|-------------|----------|
| Sync at app launch alongside PublicProfile republish | Consistent cadence, simple. | |
| Sync after every check-in on a public goal | Always-fresh progress rings, adds hot-path writes. | |
| You decide | Match PublicProfile republish cadence. | ✓ |

**User's choice:** You decide
**Notes (Claude's choice):** App launch + after check-in, matching PublicProfile cadence for simplicity.

---

## Profile Photo on PublicProfileView

| Option | Description | Selected |
|--------|-------------|----------|
| No — keep photoData excluded, show initials + color only | Maintains T-07-08 security decision. No CKAsset infra needed. | ✓ |
| Yes — publish profile photo as CKAsset in Phase 22 | New CKAsset field, privacy implications, not specced in PROF-01. | |

**User's choice:** No — keep photoData excluded, show initials + color only

---

## Follow State Persistence

| Option | Description | Selected |
|--------|-------------|----------|
| Query CloudKit public DB on profile load | Authoritative. One query per profile open. | ✓ |
| Cache followed usernames in UserDefaults | Faster. Risks stale state if Follow record removed by moderation. | |

**User's choice:** Query CloudKit public DB on profile load

---

## Retroactive Public Goal Backfill

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — backfill on first Phase 22 launch | Write PublicGoal records for existing isPublic goals. One-time operation. | ✓ |
| No — only newly created public goals indexed going forward | No backfill logic. Pre-Phase-22 public goals not discoverable until next creation. | |

**User's choice:** Yes — backfill on first Phase 22 launch

---

## Claude's Discretion

- **PublicProfile republish cadence:** App launch + after check-in only (not after every goal create/complete)
- **Public goal CKRecord:** New `PublicGoal` record type (not reusing ChallengeTemplate)
- **Public goal progress sync cadence:** App launch + after check-in (matching PublicProfile cadence)
- **Search debounce:** `Task.sleep(500ms)` + task cancellation (async/await style, not Combine)
- **PublicGoalCard progress ring:** Local `Circle().trim()` implementation (not ProgressRingView which requires GoalTier)
- **PublicProfileViewModel state:** Expand `loaded` to carry `PublicProfileData` struct
- **Schema version:** New lightweight migration for `Goal.cloudKitPublicGoalRecordID` and `UserProfile.motto` fields

## Deferred Ideas

- Profile photos on public profiles — CKAsset infra, privacy implications; deferred to future phase
- Unfollow functionality — PROF-02 is one-way follow only in v2.0; unfollow deferred
- Follow-based feed filtering — community feed stays global in v2.0 per Phase 21 D-07
- Full-text goal search (Algolia etc.) — CloudKit substring predicate sufficient for MVP
