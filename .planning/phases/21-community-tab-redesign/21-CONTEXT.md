# Phase 21: Community Tab Redesign - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Rebuild CommunityTabView from the v1.0 challenge-based feed into a live social hub. The new tab contains five sections in order: (1) Community goal landing card (COMM-01), (2) Today's Glimpses carousel (COMM-02, COMM-03), (3) Active Today section (COMM-04), (4) Glowing This Week spotlight with applause (COMM-05, SOC-01–03), (5) global community feed with reactions/replies/photos (COMM-06, COMM-07). The challenge discovery (ChallengeDiscoveryView + IdeaBoardView) moves to the Explore tab — it is no longer part of the Community tab. This phase also writes applause records to CloudKit public DB and introduces a new GoalGlimpse CKRecord type for Today's Glimpses content.

</domain>

<decisions>
## Implementation Decisions

### Today's Glimpses (COMM-02, COMM-03)
- **D-01:** Today's Glimpses carousel is populated by a new `GoalGlimpse` CKRecord type written to CloudKit public DB at goal check-in time. Each check-in writes (or upserts) a snapshot for that user's goal.
- **D-02:** COMM-03 tap action — tapping a Glimpse card navigates to the existing `PublicProfileView` stub (built in Phase 17 for report/block). Phase 22 will flesh it out. No dead-end or placeholder tap.

### Applause System (SOC-01, SOC-02, SOC-03)
- **D-03:** Applause (👏) can be given from two surfaces: the Glowing This Week spotlight card (COMM-05) and individual Today's Glimpses cards (COMM-02). Applause is NOT shown in the community feed posts.
- **D-04:** The 1-per-day-per-recipient limit (SOC-01) is tracked via UserDefaults — a date-keyed dictionary `[recipientUsername: lastApplauseDate]`. Consistent with the Explore tab's daily gate pattern (gifter, stuck-day gifts).
- **D-05:** The floating 👏 animation (SOC-01) floats upward from the tapped button itself — a 👏 emoji with the giver's username label rises and fades out, localized to the card. Not a full-screen burst.

### Challenge Feed Migration
- **D-06:** The existing `ChallengeDiscoveryView` and `IdeaBoardView` (currently shown in `CommunityTabView` via a "Feed | Ideas" Picker) move to the Explore tab. The Community tab no longer shows challenges.
- **D-07:** The new global community feed (COMM-06) shows all community posts from all users. Sorted per COMM-06: active users at top, then most liked today, then most recent, then a random community goal comment. The follow system (Phase 22) will not affect feed scoping in Phase 21.
- **D-08:** Reply depth for COMM-06 is flat replies only — replies sit at the same level as the post. No reply-to-reply threading. Consistent with the existing `commentPostID` infrastructure in `CommunityFeedView`.

### Community Goal Landing (COMM-01)
- **D-09:** The COMM-01 community goal landing card (progress circle with % in center, participant count, days remaining) sits at the top of the Community tab scroll. Tapping it navigates to the existing `CommunityGoalsLandingView` (built in Phase 15). Shows the active/featured community challenge goal.

### Photo Compose Flow (COMM-07)
- **D-10:** Photo attachment is added to the existing compose sheet (the current `.sheet` presentation). An inline camera/photo icon button is added to the sheet. Tapping shows a `confirmationDialog` (Library / Camera options). Photo thumbnail previews inline before submit. No separate full-screen compose view.
- **D-11:** Photo attachment is optional. Text-only posts remain supported. The existing `CommunityService.createPost(imageData: nil)` nil path is unchanged.

### Claude's Discretion
- `GoalGlimpse` CKRecord field set: minimal — `username`, `goalTitle`, `progressPercent`, optional `photoAsset` (CKAsset), `authorColorHex` for AvatarView. Rendered using the existing `AvatarView` component with colorHex. Large avatar photos are excluded to keep CKRecord size and fetch cost low.
- `GoalGlimpse` upsert strategy at check-in: one record per user per day (keyed on username + calendar date). Overwrites if the user checks in multiple times in a day.
- Reply CKRecord design for COMM-06: flat `CommunityReply` record type with `parentPostID`, `text`, `authorDisplayName`, `authorColorHex`, `creationDate` fields. Same CloudKit public DB.
- SOC-02 ambient applause stream on profile owner's view: rendered as a GeometryReader overlay in `ProfileView.swift` (self-view). Loads recent applause received records on appear, animates them floating upward with staggered delays.
- Glowing This Week eligibility: users who have written at least one `GoalGlimpse` in the past 7 days (i.e., actively checking in). Consistent `weekOfYear % eligibleCount` selection per COMM-05 spec.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Requirements
- `.planning/ROADMAP.md` §Phase 21 — goal, success criteria, requirements list (COMM-01–COMM-07, SOC-01–SOC-03)
- `.planning/REQUIREMENTS.md` §COMM-01–COMM-07, §SOC-01–SOC-03 — full requirement definitions

### Community Views to Rebuild / Modify
- `VitaminG/VitaminG/VitaminG/Views/CommunityTabView.swift` — rebuilt entirely: remove challenge Feed/Ideas picker, add 5-section social hub layout (COMM-01 card → Glimpses → Active Today → Glowing → global feed)
- `VitaminG/VitaminG/VitaminG/Views/CommunityFeedView.swift` — repurpose or replace for global (non-challenge-scoped) feed
- `VitaminG/VitaminG/VitaminG/Views/Components/CommunityPostCard.swift` — extend to support 🔥 reaction type (currently only ❤️ and 👍), inline reply button
- `VitaminG/VitaminG/VitaminG/Views/CommunityGoalsLandingView.swift` — already built (Phase 15); wire as the COMM-01 tap destination
- `VitaminG/VitaminG/VitaminG/Services/CommunityService.swift` — add GoalGlimpse fetch/write, applause write, reply fetch/write, Active Today query (lastActive), Glowing This Week query

### Profile Views (Phase 17 output — Phase 21 navigates here)
- `VitaminG/VitaminG/VitaminG/Views/PublicProfileView.swift` — COMM-03 tap destination; Phase 22 expands it

### Challenge Views to Move (not delete — move to Explore tab)
- `VitaminG/VitaminG/VitaminG/Views/ChallengeDiscoveryView.swift` — move from Community to Explore tab
- Search for IdeaBoardView location and move to Explore tab alongside ChallengeDiscoveryView

### Prior Phase Context
- `.planning/phases/20-explore-tab/20-CONTEXT.md` — Explore tab architecture; ChallengeDiscovery must slot into it without disrupting Phase 20 work
- `.planning/phases/17-onboarding-overhaul/17-CONTEXT.md` — PublicProfileView established as COMM-03 destination

### Design and Theme
- `VitaminG/VitaminG/VitaminG/VGTheme.swift` — color system, typography; all new views follow clay/sand palette + Cormorant Garamond headings

### State Management Pattern
- `.planning/STATE.md` — `Active Today` decision (lastActive write at app open, show users within 2 hours); `CKAsset fileURL must be copied immediately` constraint

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CommunityPostCard` (existing): supports CKRecord posts with ❤️/👍 reactions, photo display, report button, relative timestamp. Extend to add 🔥 reaction and a reply button.
- `AvatarView` (existing): accepts `displayName`, `avatarColorHex`, `photoData`, `size`. Use for GoalGlimpse carousel cards — renders initials + color with no network dependency.
- `CommunityService.createPost()`: already handles `imageData` as optional CKAsset; `photoAsset` field + compression to 500KB already implemented. Reuse for COMM-07 photo posts.
- `CommunityFeedViewModel`: `@MainActor @Observable` pattern with test overrides. Replicate this pattern for the new global feed.
- `InputSanitizer.sanitizeForPublic()`: already called in `createPost()`; use for GoalGlimpse text and reply text.
- `ProfanityFilter.containsProfanity()`: existing gate; apply to reply text.

### Established Patterns
- CloudKit public DB write: `CKContainer.default().publicCloudDatabase.save(record)` — see `CommunityService.createPost()` for the established pattern.
- CKAsset copy to Application Support: required before display (OS reclaims temp paths under storage pressure) — see STATE.md decision. Apply to GoalGlimpse photo fetches.
- Daily gate via UserDefaults: `EXPLORE-02` gifter and `EXPLORE-06` stuck-day gifts use `UserDefaults` with date keys. Applause daily limit (D-04) follows this exact pattern.
- `.fullScreenCover` celebration: `GoalListView` milestone celebrations use this pattern. Existing precedent for full-screen animated states.
- `@Observable` ViewModel with `async` CloudKit fetching: standard pattern across all v2.0 ViewModels; follow for `CommunityHubViewModel` (new).

### Integration Points
- `AppTab.community` route: the rebuilt `CommunityTabView` plugs into the existing 5-tab `Tab` enum and `ContentView` (Phase 16 output). No routing changes needed.
- `GoalViewModel.addCheckIn()` (Phase 18): when a check-in is recorded, also write/upsert a `GoalGlimpse` CKRecord. This is the injection point for Today's Glimpses data.
- `ProfileView.swift` (self-view): SOC-02 ambient applause stream is overlaid here. Add a `GeometryReader` overlay that loads and animates recent received applause.
- `ExploreTabView` (Phase 20 output): `ChallengeDiscoveryView` and `IdeaBoardView` must be added as a new section here. Read Phase 20 CONTEXT.md before modifying.

</code_context>

<specifics>
## Specific Ideas

- The Glowing This Week spotlight is the hero card on the Community tab — it should feel elevated and celebratory, using VGTheme's warm clay/terra palette.
- Today's Glimpses carousel auto-advances every 5 seconds; pauses on manual swipe. The `TabView` with `tabViewStyle(.page)` + a `Timer` is the SwiftUI-native approach.
- The floating 👏 animation (D-05) should use `withAnimation(.easeOut(duration: 1.0))` and offset + opacity together — same feel as the existing confetti patterns in the codebase.

</specifics>

<deferred>
## Deferred Ideas

- Follow-based feed filtering: the follow system (PROF-02) comes in Phase 22. Community feed stays global in Phase 21.
- Applause on community feed posts (user raised this possibility): deferred — keeping applause to Spotlight + Glimpses keeps the gesture special.
- Nested reply threading: flat replies only in Phase 21 per D-08. Nesting deferred to a potential future phase.

</deferred>

---

*Phase: 21-community-tab-redesign*
*Context gathered: 2026-05-23*
