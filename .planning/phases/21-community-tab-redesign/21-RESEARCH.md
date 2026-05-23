# Phase 21: Community Tab Redesign - Research

**Researched:** 2026-05-23
**Domain:** SwiftUI social hub — CloudKit public DB, carousel UI, applause animation, feed ranking, photo compose
**Confidence:** HIGH

---

## Summary

Phase 21 replaces the `CommunityPlaceholderView` stub (currently wired at `AppTab.community` in `ContentView.swift`) with a full 5-section social hub. All infrastructure needed to execute this phase already exists in the codebase: `CommunityService`, `CommunityFeedViewModel`, `CommunityPostCard`, `AvatarView`, `PostComposeSheet`, `ReactionPill`, and `InputSanitizer` / `ProfanityFilter` are all production-ready and well-tested. The task is assembly, extension, and new CloudKit record types — not greenfield engineering.

The two new CloudKit record types (`GoalGlimpse` and `CommunityReply`) follow the existing `CommunityPost` pattern exactly: write to the public database using `CKContainer.default().publicCloudDatabase.save(record)`. The `UserPresence` record type (for Active Today) also follows this pattern. The applause daily gate follows the `vg_explore_gifterDate` UserDefaults pattern already in `ExploreViewModel`. The floating 👏 animation follows the confetti-overlay pattern used in `CheckInCelebrationView`, `MilestoneCelebrationView`, and `ExploreConfettiOverlay` (SwiftUI Canvas with `TimelineView`, or a simpler `withAnimation(.easeOut)` + offset/opacity state).

The main complexity is in the CommunityHubViewModel (new): it must orchestrate five async CloudKit fetches (community goal card data, GoalGlimpse records, UserPresence records, Glowing This Week query, global feed posts) without blocking the UI, and must expose test overrides consistent with the existing `fetchOverride`/`createOverride` pattern.

**Primary recommendation:** Build `CommunityHubViewModel` as the single `@MainActor @Observable` coordinator for the new hub. Decompose the five sections into sub-view structs (GlimpsesCarouselSection, ActiveTodaySection, GlowingSpotlightSection, GlobalFeedSection) each receiving the view model. Wire everything into `CommunityTabView` (rebuilt from scratch), plug into `ContentView` by replacing `CommunityPlaceholderView`.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Today's Glimpses carousel is populated by a new `GoalGlimpse` CKRecord type written to CloudKit public DB at goal check-in time. Each check-in writes (or upserts) a snapshot for that user's goal.

**D-02:** COMM-03 tap action — tapping a Glimpse card navigates to the existing `PublicProfileView` stub (built in Phase 17 for report/block). Phase 22 will flesh it out. No dead-end or placeholder tap.

**D-03:** Applause (👏) can be given from two surfaces: the Glowing This Week spotlight card (COMM-05) and individual Today's Glimpses cards (COMM-02). Applause is NOT shown in the community feed posts.

**D-04:** The 1-per-day-per-recipient limit (SOC-01) is tracked via UserDefaults — a date-keyed dictionary `[recipientUsername: lastApplauseDate]`. Consistent with the Explore tab's daily gate pattern (gifter, stuck-day gifts).

**D-05:** The floating 👏 animation (SOC-01) floats upward from the tapped button itself — a 👏 emoji with the giver's username label rises and fades out, localized to the card. Not a full-screen burst.

**D-06:** The existing `ChallengeDiscoveryView` and `IdeaBoardView` (currently shown in `CommunityTabView` via a "Feed | Ideas" Picker) move to the Explore tab. The Community tab no longer shows challenges.

**D-07:** The new global community feed (COMM-06) shows all community posts from all users. Sorted per COMM-06: active users at top, then most liked today, then most recent, then a random community goal comment. The follow system (Phase 22) will not affect feed scoping in Phase 21.

**D-08:** Reply depth for COMM-06 is flat replies only — replies sit at the same level as the post. No reply-to-reply threading. Consistent with the existing `commentPostID` infrastructure in `CommunityFeedView`.

**D-09:** The COMM-01 community goal landing card (progress circle with % in center, participant count, days remaining) sits at the top of the Community tab scroll. Tapping it navigates to the existing `CommunityGoalsLandingView` (built in Phase 15). Shows the active/featured community challenge goal.

**D-10:** Photo attachment is added to the existing compose sheet (the current `.sheet` presentation). An inline camera/photo icon button is added to the sheet. Tapping shows a `confirmationDialog` (Library / Camera options). Photo thumbnail previews inline before submit. No separate full-screen compose view.

**D-11:** Photo attachment is optional. Text-only posts remain supported. The existing `CommunityService.createPost(imageData: nil)` nil path is unchanged.

### Claude's Discretion

- `GoalGlimpse` CKRecord field set: minimal — `username`, `goalTitle`, `progressPercent`, optional `photoAsset` (CKAsset), `authorColorHex` for AvatarView.
- `GoalGlimpse` upsert strategy at check-in: one record per user per day (keyed on username + calendar date). Overwrites if user checks in multiple times in a day.
- Reply CKRecord design for COMM-06: flat `CommunityReply` record type with `parentPostID`, `text`, `authorDisplayName`, `authorColorHex`, `creationDate` fields.
- SOC-02 ambient applause stream on profile owner's view: rendered as a GeometryReader overlay in `ProfileView.swift` (self-view). Loads recent applause received records on appear, animates floating upward with staggered delays.
- Glowing This Week eligibility: users who have written at least one `GoalGlimpse` in the past 7 days. `weekOfYear % eligibleCount` selection per COMM-05 spec.

### Deferred Ideas (OUT OF SCOPE)

- Follow-based feed filtering: the follow system (PROF-02) comes in Phase 22. Community feed stays global in Phase 21.
- Applause on community feed posts: deferred — keeping applause to Spotlight + Glimpses.
- Nested reply threading: flat replies only in Phase 21 per D-08.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COMM-01 | Community goal landing card at top of tab; tapping navigates to `CommunityGoalsLandingView` | `CommunityGoalsLandingView` already built (Phase 15). Wire as NavigationLink or `.sheet`. Need to resolve how to pass the featured `UserChallenge` without requiring active membership — ASSUMED: use first active `UserChallenge` from `@Query` or a CloudKit `FeaturedGoal` record. |
| COMM-02 | Today's Glimpses carousel — auto-advances 5s, shows avatar/username/goal/progress, optional photo | `TabView(.page)` + `Timer.scheduledTimer` or `onReceive(timer)` pattern; `GoalGlimpse` CKRecord fetch from CommunityHubViewModel |
| COMM-03 | Tapping a Glimpse card opens `PublicProfileView` stub | `PublicProfileView` exists; presentation as `.sheet` via router pattern already used in `ContentView` |
| COMM-04 | Active Today section — users active within 2 hours; tapping opens profile | `UserPresence` CKRecord query on `lastActiveDate` field; needs `> Date() - 7200` predicate |
| COMM-05 | Glowing This Week spotlight with applause button | Deterministic `weekOfYear % eligibleCount` selection; applause write to CloudKit `Applause` record type |
| COMM-06 | Global community feed with reactions + replies | Extend `CommunityService.fetchPosts` to accept `nil` category for global query; add `fireCount` field; `CommunityReply` record type |
| COMM-07 | Community post photo attachment — library or camera via `confirmationDialog` | `PostComposeSheet` already handles `PhotosPicker`; add camera option via `UIImagePickerController` representable (existing pattern in `ProfileView.swift`) |
| SOC-01 | 👏 applause — 1/day/recipient; floating emoji animation | UserDefaults dictionary gate (D-04 pattern); SwiftUI `withAnimation(.easeOut)` + `.offset` + `.opacity` |
| SOC-02 | Profile owner sees ambient applause stream | GeometryReader overlay on `ProfileView.swift`; CloudKit query for recent received `Applause` records |
| SOC-03 | "Cheers given" counter on public profile card | Count of `Applause` records where `giverUsername == currentUsername`; displayed in `PublicProfileView` |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| GoalGlimpse record write at check-in | API / Backend (CloudKit) | iOS App (GoalViewModel injection point) | CloudKit public DB is the data tier; GoalViewModel.addCheckIn() is the injection point |
| Today's Glimpses carousel UI | iOS App (SwiftUI View) | — | Pure presentation, reads from CommunityHubViewModel |
| Applause daily gate | iOS App (UserDefaults) | CloudKit (Applause record write) | UserDefaults for gate enforcement; CloudKit for persistence of the applause record |
| Active Today query | API / Backend (CloudKit) | iOS App (CommunityHubViewModel) | CloudKit predicate query on `lastActiveDate` field; ViewModel wraps fetch |
| Glowing This Week selection | iOS App (deterministic algorithm) | CloudKit (GoalGlimpse eligibility source) | Algorithm runs client-side using weekOfYear; CloudKit provides the eligible user pool |
| Global community feed + reactions | API / Backend (CloudKit) | iOS App (CommunityHubViewModel) | Extends existing CommunityService; ViewModel drives optimistic UI |
| Reply write / fetch | API / Backend (CloudKit) | iOS App (CommunityHubViewModel) | New `CommunityReply` record type in CloudKit public DB |
| Photo attachment in compose | iOS App (SwiftUI View) | CloudKit (CKAsset) | `PostComposeSheet` + `UIImagePickerController`; `CommunityService.createPost` already handles compression |
| Ambient applause stream on profile | iOS App (SwiftUI View) | CloudKit (Applause query) | GeometryReader overlay in ProfileView; loads on `.task` |
| Challenge migration to Explore tab | iOS App (ExploreView) | — | DOM rearrangement: remove from CommunityTabView, slot into ExploreView |

---

## Standard Stack

No new third-party dependencies. All libraries are Apple-native, already present in the project.

### Core (already in project)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All UI | Project minimum; all views use it |
| CloudKit | iOS 17+ | Public DB for all social data (GoalGlimpse, Applause, CommunityPost, CommunityReply, UserPresence) | Established pattern across all social features |
| Observation (`@Observable`) | iOS 17+ | CommunityHubViewModel | Project standard — replaces ObservableObject throughout |
| PhotosUI (`PhotosPicker`) | iOS 16+ | Library photo selection in PostComposeSheet | Already used in PostComposeSheet, ProfileView, CommunityGoalsLandingView |
| XCTest | N/A | Unit tests for CommunityHubViewModel | Established test framework — 35+ test files in VitaminGTests |

### Supporting (already in project)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `UserDefaults` | iOS 2+ | Applause daily gate (D-04) | Lightweight ephemeral state, consistent with gifter/mood/stuck-day gate pattern |
| `InputSanitizer` | project | Sanitize reply text and GoalGlimpse title before CloudKit write | Must be called on all user-generated text before persistence |
| `ProfanityFilter` | project | Gate reply text | Same pattern as PostComposeSheet |

**Installation:** None required.

---

## Package Legitimacy Audit

No new packages are installed in this phase. All APIs are Apple-native or from the existing project.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
User Interaction
       |
       v
CommunityTabView (rebuilt)
       |
       +---> Section 1: CommunityGoalCard -------> NavigationLink --> CommunityGoalsLandingView (Phase 15)
       |
       +---> Section 2: GlimpsesCarouselSection
       |       |  TabView(.page) + Timer
       |       |  reads: CommunityHubViewModel.glimpses [GoalGlimpse]
       |       +---> tap card --> .sheet(PublicProfileView)
       |       +---> tap 👏 button --> ApplauseService.writeApplause() + UserDefaults gate
       |
       +---> Section 3: ActiveTodaySection
       |       |  reads: CommunityHubViewModel.activeUsers [UserPresenceItem]
       |       +---> tap user --> .sheet(PublicProfileView)
       |
       +---> Section 4: GlowingSpotlightSection (hero card)
       |       |  reads: CommunityHubViewModel.glowingUser [GoalGlimpse?]
       |       +---> tap 👏 button --> ApplauseService.writeApplause() + UserDefaults gate
       |       +---> floating 👏 animation overlay
       |
       +---> Section 5: GlobalFeedSection
               |  reads: CommunityHubViewModel.feedPosts [CKRecord]
               |  CommunityPostCard (extended: 🔥 reaction, inline reply)
               +---> tap reply --> .sheet(CommunityReplySheetView) [new]
               +---> tap compose --> .sheet(PostComposeSheet) [existing, extended for camera]

CommunityHubViewModel (@MainActor @Observable)
       |
       +---> CommunityService.fetchGlimpses()        [new method]
       +---> CommunityService.writeGlimpse()         [new method, called from GoalViewModel.addCheckIn]
       +---> CommunityService.fetchActiveUsers()     [new method]
       +---> CommunityService.writeUserPresence()    [new method, called at app open]
       +---> CommunityService.fetchGlowingUser()     [new method]
       +---> CommunityService.writeApplause()        [new method]
       +---> CommunityService.fetchGlobalFeed()      [new method — nil-category variant of fetchPosts]
       +---> CommunityService.fetchReplies()         [new method]
       +---> CommunityService.writeReply()           [new method]
               |
               v
       CloudKit Public Database
       - CommunityPost (existing)
       - GoalGlimpse (new: username, goalTitle, progressPercent, authorColorHex, photoAsset?, dayKey)
       - UserPresence (new: username, authorColorHex, lastActiveDate)
       - Applause (new: giverUsername, recipientUsername, creationDate)
       - CommunityReply (new: parentPostID, text, authorDisplayName, authorColorHex, creationDate)

ProfileView (self-view) — SOC-02
       +---> ApplauseStreamOverlay (new: GeometryReader overlay)
               +---> CommunityService.fetchReceivedApplause(username:) [new]
```

### Recommended Project Structure

```
VitaminG/Views/
├── CommunityTabView.swift          # Rebuilt — 5-section hub (was challenge feed)
├── Community/
│   ├── GlimpsesCarouselSection.swift    # COMM-02/03
│   ├── ActiveTodaySection.swift         # COMM-04
│   ├── GlowingSpotlightSection.swift    # COMM-05/SOC-01
│   ├── GlobalFeedSection.swift          # COMM-06
│   ├── CommunityReplySheetView.swift    # COMM-06 replies (replaces local-only CommentSheetView for new posts)
│   ├── ApplauseButtonView.swift         # SOC-01 reusable button + animation
│   ├── ApplauseStreamOverlay.swift      # SOC-02 ambient stream
│   ├── IdeaBoardView.swift              # stays — just moves to ExploreView
│   ├── CommentSheetView.swift           # stays for legacy challenge posts
│   └── ProposeIdeaSheet.swift           # stays
VitaminG/ViewModels/
├── CommunityHubViewModel.swift     # New: orchestrates all 5 sections
VitaminGTests/
├── Phase21CommunityHubViewModelTests.swift   # new
├── Phase21ApplauseDailyGateTests.swift       # new
├── Phase21GlowingSelectionTests.swift        # new
├── Phase21ReplyTests.swift                   # new
```

### Pattern 1: CommunityHubViewModel — @MainActor @Observable with test overrides

Follows the established `CommunityFeedViewModel` pattern exactly. Every CloudKit call has an override closure for testability.

```swift
// Source: VitaminGTests/CommunityFeedViewModelTests.swift + ViewModels/CommunityFeedViewModel.swift [VERIFIED: codebase]
@MainActor
@Observable
final class CommunityHubViewModel {
    var glimpses: [GoalGlimpseItem] = []
    var activeUsers: [UserPresenceItem] = []
    var glowingUser: GoalGlimpseItem? = nil
    var feedPosts: [CKRecord] = []
    var isLoading: Bool = false

    // Test overrides — nil in production
    var fetchGlimpsesOverride: (() async throws -> [GoalGlimpseItem])? = nil
    var fetchActiveUsersOverride: (() async throws -> [UserPresenceItem])? = nil
    // ... one override per CloudKit call

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        async let g = loadGlimpses()
        async let a = loadActiveUsers()
        async let glow = loadGlowingUser()
        async let feed = loadFeedPosts()
        _ = await (g, a, glow, feed)
    }
}
```

### Pattern 2: Today's Glimpses Carousel — TabView(.page) + Timer

```swift
// Source: Apple SwiftUI Documentation — TabView page style [ASSUMED: training knowledge, pattern is standard]
struct GlimpsesCarouselSection: View {
    let glimpses: [GoalGlimpseItem]
    @State private var currentIndex = 0
    @State private var isDragging = false

    // 5-second auto-advance per COMM-02
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(glimpses.enumerated()), id: \.offset) { index, glimpse in
                GlimpseCard(glimpse: glimpse)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .onReceive(timer) { _ in
            guard !isDragging, !glimpses.isEmpty else { return }
            withAnimation(.easeInOut(duration: 0.4)) {
                currentIndex = (currentIndex + 1) % glimpses.count
            }
        }
        // Detect manual swipe: pause timer on drag gesture
        .simultaneousGesture(DragGesture().onChanged { _ in isDragging = true }
                                          .onEnded { _ in isDragging = false })
    }
}
```

### Pattern 3: Applause Daily Gate — UserDefaults dictionary (D-04)

```swift
// Source: ExploreViewModel.swift — identical pattern for gifter and mood gates [VERIFIED: codebase]
// Key: "vg_community_applauseGiven"
// Value: [recipientUsername: Date] stored as Data (JSONEncoder)
func canApplaud(recipientUsername: String) -> Bool {
    guard let data = UserDefaults.standard.data(forKey: applauseGivenKey),
          let dict = try? JSONDecoder().decode([String: Date].self, from: data),
          let last = dict[recipientUsername]
    else { return true }
    return !Calendar.current.isDateInToday(last)
}

func markApplauseGiven(to recipientUsername: String) {
    var dict: [String: Date] = [:]
    if let data = UserDefaults.standard.data(forKey: applauseGivenKey),
       let existing = try? JSONDecoder().decode([String: Date].self, from: data) {
        dict = existing
    }
    dict[recipientUsername] = Date()
    if let data = try? JSONEncoder().encode(dict) {
        UserDefaults.standard.set(data, forKey: applauseGivenKey)
    }
}
```

### Pattern 4: Floating 👏 Animation (SOC-01, D-05)

```swift
// Source: CheckInCelebrationView.swift pattern (withAnimation + State) [VERIFIED: codebase]
// Localized to the card — not full screen. A simple state-driven approach:
struct ApplauseButtonView: View {
    let recipientUsername: String
    let giverUsername: String
    let canApplaud: Bool
    let onApplaud: () -> Void

    @State private var showFloat = false
    @State private var floatOffset: CGFloat = 0
    @State private var floatOpacity: Double = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Button { triggerApplause() } label: {
                Text("👏")
                    .font(.title2)
                    .opacity(canApplaud ? 1.0 : 0.4)
            }
            .disabled(!canApplaud)
            .accessibilityLabel(canApplaud ? "Applaud \(recipientUsername)" : "Already applauded today")

            if showFloat {
                VStack(spacing: 2) {
                    Text("👏")
                    Text(giverUsername).font(.caption2).fontDesign(.rounded)
                }
                .foregroundStyle(VGTheme.accentGold)
                .offset(y: floatOffset)
                .opacity(floatOpacity)
            }
        }
    }

    private func triggerApplause() {
        guard canApplaud else { return }
        onApplaud()
        showFloat = true
        floatOffset = 0
        floatOpacity = 1.0
        withAnimation(.easeOut(duration: 1.0)) {
            floatOffset = -80
            floatOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            showFloat = false
        }
    }
}
```

### Pattern 5: GoalGlimpse write at check-in (D-01)

```swift
// Source: GoalViewModel.addCheckIn() — injection point [VERIFIED: codebase]
// GoalViewModel.addCheckIn() currently does NOT write a GoalGlimpse.
// Phase 21 adds this call at the end of addCheckIn():
func addCheckIn(for goal: Goal, context: ModelContext) {
    // ... existing check-in logic unchanged ...
    // NEW: fire-and-forget GoalGlimpse upsert
    Task {
        await CommunityService.writeGlimpse(
            username: currentUsername,
            goalTitle: goal.title,
            progressPercent: computedProgress,
            authorColorHex: currentUserColorHex
        )
    }
}
```

### Pattern 6: CommunityReply CloudKit record

```swift
// Source: CommunityService.createPost() pattern — exact copy for replies [VERIFIED: codebase]
static func writeReply(
    parentPostID: String,
    text: String,
    authorDisplayName: String?,
    authorColorHex: String?
) async throws -> CKRecord {
    let record = CKRecord(recordType: "CommunityReply")
    record["parentPostID"] = parentPostID as CKRecordValue
    record["text"] = InputSanitizer.sanitizeForPublic(text) as CKRecordValue
    record["authorDisplayName"] = InputSanitizer.sanitizeForPublic(authorDisplayName ?? "Anonymous") as CKRecordValue
    record["authorColorHex"] = (authorColorHex ?? "") as CKRecordValue
    // creationDate is auto-set by CloudKit
    return try await CKContainer.default().publicCloudDatabase.save(record)
}
```

### Pattern 7: Glowing This Week deterministic selection

```swift
// Source: COMM-05 spec + CONTEXT.md Claude's Discretion [ASSUMED: algorithm design]
// weekOfYear % eligibleCount — same index for all clients on a given week
func selectGlowingUser(from eligible: [GoalGlimpseItem]) -> GoalGlimpseItem? {
    guard !eligible.isEmpty else { return nil }
    let week = Calendar(identifier: .iso8601).component(.weekOfYear, from: Date())
    return eligible[week % eligible.count]
}
```

### Pattern 8: Camera / library `confirmationDialog` in PostComposeSheet (D-10)

```swift
// Source: PostComposeSheet.swift (existing PhotosPicker) + ProfileView.swift (existing camera) [VERIFIED: codebase]
// Current PostComposeSheet uses PhotosPicker inline. D-10 requires a confirmationDialog choice.
// Replace PhotosPicker button with a camera icon button that shows a confirmationDialog:
Button { showPhotoSourceDialog = true } label: {
    Image(systemName: "camera.fill")
}
.confirmationDialog("Add Photo", isPresented: $showPhotoSourceDialog) {
    Button("Photo Library") { showLibraryPicker = true }
    Button("Camera") { showCamera = true }
    Button("Cancel", role: .cancel) {}
}
// Library: existing PhotosPicker(selection:matching:) pattern
// Camera: UIImagePickerController representable (exists in ProfileView.swift via AVFoundation)
```

### Anti-Patterns to Avoid

- **CKAsset fileURL used after temp cleanup:** `CKAsset.fileURL` points to a temp path. Copy to `Application Support` immediately on fetch before storing. STATE.md decision: "CKAsset fileURL must be copied immediately." Apply to GoalGlimpse `photoAsset` fetches.
- **Blocking UI on parallel CloudKit fetches:** Use `async let` to parallelize the 5 section fetches in `CommunityHubViewModel.loadAll()`. Sequential `await` calls would stall on slow networks.
- **Force-unwrapping CKRecord fields:** Every `record["field"]` cast can return nil. All CKRecord accessors must use optional binding.
- **CommunityFeedView reuse for global feed:** Do not reuse `CommunityFeedView` directly — it requires a `UserChallenge` parameter that global feed does not have. Build `GlobalFeedSection` as a new component inside `CommunityTabView`.
- **CommentSheetView for new replies:** The existing `CommentSheetView` persists comments to UserDefaults (local-only). New replies (COMM-06) must go to CloudKit via `CommunityReply`. Build `CommunityReplySheetView` as the CloudKit-backed replacement for global feed posts.
- **Timer leaks on carousel:** The `Timer.publish().autoconnect()` approach auto-cancels on view disappear. Do not use `Timer.scheduledTimer` with `RunLoop` — it requires manual invalidation.
- **weekOfYear with `.gregorian` calendar:** StreakFreeze learned this already. Use `Calendar(identifier: .iso8601)` for Monday-anchored `weekOfYear` consistency. `Calendar.current` may be `.gregorian` for some locales.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Photo compression before CKAsset | Custom JPEG compressor | `CommunityService.compressToJPEG(_:maxBytes:)` (exists) | Already handles quality step-down loop; max 500KB established |
| Profanity gate on reply text | Custom word filter | `ProfanityFilter.containsProfanity()` (exists) | Shared blocklist; already tested |
| Input sanitization for reply/glimpse text | Custom trimmer/normalizer | `InputSanitizer.sanitizeForPublic()` (exists) | Strips zero-width chars, trims whitespace, limits length |
| CKRecord server-conflict retry | Manual optimistic-lock | Existing `catch CKError.serverRecordChanged` retry in `CommunityService.toggleReaction` | One-retry pattern already proven; replicate for reply writes |
| Public profile navigation | Custom sheet/nav logic | Existing `AppRouter.pendingPublicProfileRecordID` + `ContentView` sheet binding | Phase 17 built the router pattern; COMM-03 just sets that property |
| Avatar rendering | Custom initials + color circle | `AvatarView(displayName:avatarColorHex:photoData:size:)` (exists) | Handles photo vs initials, shadow, accessibility label |
| Reaction pill UI | Custom button + count | `ReactionPill(emoji:count:isActive:accentColor:action:)` (exists) | Capsule style, active border, accessibility label |

---

## Common Pitfalls

### Pitfall 1: CKAsset temporary path reclaim
**What goes wrong:** GoalGlimpse photoAsset fetched from CloudKit, stored as `CKAsset`, `fileURL` displayed in `AsyncImage`. Under storage pressure, iOS reclaims the temp path silently — image shows blank.
**Why it happens:** CloudKit returns assets at temporary paths under `/tmp` or `/var/folders`. The OS reclaims them under low-storage conditions.
**How to avoid:** On receipt of any CKAsset (GoalGlimpse.photoAsset), copy the file to `Application Support` immediately: `try FileManager.default.copyItem(at: asset.fileURL, to: permanentURL)`. This is already the established STATE.md constraint.
**Warning signs:** Blank image thumbnails on real device under low storage; works fine in Simulator.

### Pitfall 2: COMM-01 featured goal data source
**What goes wrong:** COMM-01 card at the top of the Community tab needs a "featured community challenge goal" — but the user may not be a member of any challenge, and `UserChallenge` is a SwiftData model requiring membership.
**Why it happens:** The existing `CommunityGoalsLandingView` takes a `UserChallenge` parameter (requires active membership). The Community tab should show this card regardless of membership.
**How to avoid:** The COMM-01 card should use the first active `UserChallenge` from `@Query`. If no active challenge exists, show a "Join a community goal" prompt that navigates to `ExploreView`. Do not force-unwrap or assume a challenge always exists. [ASSUMED: no explicit decision in CONTEXT.md about the zero-membership state]

### Pitfall 3: CommunityTabView currently wired to `CommunityPlaceholderView`
**What goes wrong:** `ContentView.swift` wires `.tag(AppTab.community)` to a `NavigationStack { CommunityPlaceholderView() }`. Swapping it requires editing `ContentView.swift` to replace `CommunityPlaceholderView` with `CommunityTabView`.
**Why it happens:** Phase 16 built a placeholder stub by design.
**How to avoid:** Plan must include a task to update `ContentView.swift`'s community tab slot. Also: `CommunityTabView.swift` already exists as the old challenge-feed view — it must be rebuilt in place (or deleted and replaced).

### Pitfall 4: Existing CommunityTabView vs. new CommunityTabView name conflict
**What goes wrong:** `VitaminG/Views/CommunityTabView.swift` already exists and defines `struct CommunityTabView`. The Phase 21 rebuild replaces this file. If only partially updated, compilation errors.
**Why it happens:** File has the right name but wrong content.
**How to avoid:** Fully replace `CommunityTabView.swift` contents — do not try to extend the old struct. Remove `CommunitySegment` enum and `CommunityChallengeCellView` from this file.

### Pitfall 5: ChallengeDiscoveryView and IdeaBoardView migration
**What goes wrong:** `ChallengeDiscoveryView` is imported and rendered inside `CommunityTabView` via the `CommunitySegment.ideas` branch. Simply deleting it without adding it to `ExploreView` will remove discovery entirely from the app.
**Why it happens:** D-06 says move, not delete.
**How to avoid:** Add `ChallengeDiscoveryView` (and `IdeaBoardView`) as a new section in `ExploreView.swift` before removing them from `CommunityTabView`. The move must be atomic across both files in the same plan/task.

### Pitfall 6: GoalGlimpse write at check-in requires GoalViewModel context
**What goes wrong:** `GoalViewModel.addCheckIn()` runs in a `@MainActor` context but doesn't have direct access to the current user's `username` or `avatarColorHex`. Those live in `UserProfile` (SwiftData), which the ViewModel doesn't hold.
**Why it happens:** GoalViewModel focuses on `Goal` data, not user identity.
**How to avoid:** Pass `username` and `avatarColorHex` as parameters to `addCheckIn(for:context:username:colorHex:)` — callers (GoalDetailView, CheckInCelebrationView) already have `@Query private var profiles: [UserProfile]` and can pass these values. Alternatively, read from `@AppStorage("vg_onboardingName")` as a fallback.

### Pitfall 7: Global feed sort order — server-side vs client-side
**What goes wrong:** COMM-06 requires "active users at top, then most liked today, then most recent, then random comment." CloudKit does not support multi-key sorts or server-side "active users" joins.
**Why it happens:** CloudKit sort is limited to a single NSSortDescriptor on a Queryable-indexed field.
**How to avoid:** Fetch posts sorted by `creationDate` descending (most recent). Apply client-side re-ranking in `CommunityHubViewModel`: posts whose `authorDisplayName` matches any Active Today user float to the top; ties broken by `heartCount + thumbsUpCount + fireCount` as a single score; then chronological. The "random community goal comment" slot is a hardcoded `ExploreContent`-style item appended at the end. [ASSUMED: no explicit server-side ranking infrastructure in scope]

### Pitfall 8: ReplySheetView — do not reuse CommentSheetView for CloudKit replies
**What goes wrong:** `CommentSheetView` stores comments in `UserDefaults` (local-only, not CloudKit). Using it for COMM-06 replies would make replies invisible to other users.
**Why it happens:** The old system was local-only for in-challenge comments.
**How to avoid:** Build `CommunityReplySheetView` as the CloudKit-backed reply sheet. Keep `CommentSheetView` for legacy challenge-scoped use only (or deprecate it — it is only called from `CommunityFeedView` which is itself being superseded).

---

## Runtime State Inventory

> Included because this phase rebuilds existing views and moves components.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `UserDefaults` keys for legacy challenge community features (`com.kyleharrington.VitaminG.reporterID`) — still valid. No GoalGlimpse/Applause/UserPresence records exist yet (new types). | Code edit only — no migration |
| Live service config | CloudKit public DB record types UserPresence, Applause, GoalGlimpse, CommunityReply must be created in CloudKit Console before real-device testing | Manual CloudKit Console step (already noted in STATE.md Pending Todos) |
| OS-registered state | None — no task scheduler or daemon state involved | None |
| Secrets/env vars | `vg_community_applauseGiven` (new UserDefaults key) — code defines it; no conflict | Code edit only |
| Build artifacts | `CommunityTabView.swift` file rebuilt in place — stale content replaced entirely | Full file replacement |

**Nothing found in category — verified:**
- OS-registered state: None — verified by grep for `launchd`, `Task Scheduler`, `pm2` (not in project)
- Build artifacts beyond noted CommunityTabView.swift: None — no egg-info, no compiled binaries needing rename

---

## Code Examples

### GoalGlimpse CKRecord schema
```swift
// Source: CommunityService.createPost() pattern — applied to new GoalGlimpse type [VERIFIED: codebase]
// Fields:
// "username"         String   — sanitized, Queryable index required in CloudKit Console
// "goalTitle"        String   — sanitized
// "progressPercent"  Int64    — 0-100
// "authorColorHex"   String   — "#RRGGBB"
// "photoAsset"       CKAsset? — optional, compressed per CommunityService.compressToJPEG
// "dayKey"           String   — "YYYY-MM-DD" for upsert keying (fetch-or-create pattern)
// creationDate       auto     — set by CloudKit
```

### UserPresence CKRecord schema
```swift
// Fields:
// "username"          String   — Queryable index required
// "authorColorHex"    String
// "lastActiveDate"    DateTime — set at app open; predicate: lastActiveDate > (now - 7200)
```

### Applause CKRecord schema
```swift
// Fields:
// "giverUsername"     String   — Queryable index for SOC-03 count query
// "recipientUsername" String   — Queryable index for SOC-02 fetch
// creationDate        auto
```

### ContentView.swift community tab swap
```swift
// Source: ContentView.swift line 33-35 [VERIFIED: codebase]
// BEFORE:
NavigationStack {
    CommunityPlaceholderView()
}
.tag(AppTab.community)

// AFTER:
NavigationStack {
    CommunityTabView(selectedTab: $selectedTab)
}
.tag(AppTab.community)
```

### CommunityService.fetchPosts extended for global (nil-category) fetch
```swift
// Source: CommunityService.fetchPosts() [VERIFIED: codebase]
// Existing fetchPosts requires a category string. Global feed passes nil:
static func fetchGlobalPosts(limit: Int = 50) async throws -> [CKRecord] {
    let db = CKContainer.default().publicCloudDatabase
    let predicate = NSPredicate(format: "reportCount < 3")
    let query = CKQuery(recordType: postRecordType, predicate: predicate)
    query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    let (results, _) = try await db.records(matching: query, resultsLimit: limit)
    return results.compactMap { try? $0.1.get() }
}
```

### Adding 🔥 reaction to ReactionType enum and CommunityService
```swift
// Source: CommunityService.swift ReactionType enum [VERIFIED: codebase]
// Add to existing enum:
enum ReactionType: String {
    case thumbsUp
    case heart
    case fire      // NEW for Phase 21 COMM-06

    var fieldKey: String {
        switch self {
        case .thumbsUp: return "thumbsUpCount"
        case .heart:    return "heartCount"
        case .fire:     return "fireCount"    // NEW — requires new field on CommunityPost in CloudKit
        }
    }
}
// CommunityPost records need "fireCount" Int64 field in CloudKit Console
// Existing records without this field return nil — default to 0 in accessor
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `CommunityTabView` with challenge Feed/Ideas picker | 5-section social hub without challenges | Phase 21 | Full rebuild; old file content discarded |
| `CommunityFeedView` scoped to a `UserChallenge` | Global feed (no challenge scope) in `GlobalFeedSection` | Phase 21 | `CommunityFeedView` remains for challenge-scoped use; new `GlobalFeedSection` for global |
| `CommentSheetView` — UserDefaults-only local comments | `CommunityReplySheetView` — CloudKit-backed replies | Phase 21 | New CloudKit `CommunityReply` record type |
| Challenge discovery in Community tab | Challenge discovery in Explore tab | Phase 21 | `ChallengeDiscoveryView` + `IdeaBoardView` moved, not deleted |

**Deprecated/outdated:**
- `CommunitySegment` enum (Feed/Ideas picker): removed in Phase 21 — Community tab no longer has a segment picker
- `CommunityPlaceholderView`: replaced by rebuilt `CommunityTabView` — file can be deleted after Phase 21

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | COMM-01 card when user has no active UserChallenge: show "Join a community goal" fallback navigating to Explore | Common Pitfalls #2, Code Examples | Blank first section or crash; needs explicit decision if wrong |
| A2 | GoalGlimpse upsert strategy uses fetch-first then save (no CloudKit `.unique` constraint) | Architecture Patterns / GoalGlimpse schema | Duplicate records per day if upsert not enforced correctly; CloudKit has no atomic unique constraint |
| A3 | Global feed client-side re-ranking is sufficient for MVP (no server-side sort infrastructure) | Common Pitfalls #7 | Sort order may differ from COMM-06 spec literal reading if ranking is more complex |
| A4 | `TabView(.page)` + `Timer.publish().autoconnect()` is the correct carousel approach | Architecture Patterns — Pattern 2 | Minor if wrong — alternative is `withAnimation` + manual index; functional either way |
| A5 | Camera support in PostComposeSheet uses `UIImagePickerController` representable (same as ProfileView) | Pattern 8 | `UIImagePickerController` is deprecated in iOS 14+ in favor of `PHPickerViewController`. ProfileView uses `PhotosPicker` (SwiftUI). For camera-only access, `UIImagePickerController.sourceType = .camera` remains the iOS 17 standard. [LOW risk — functional in iOS 17] |
| A6 | `CommunityReplySheetView` (new CloudKit replies) is the target for COMM-06 reply button; old `CommentSheetView` is retired for new feed posts | Anti-Patterns, Pitfall 8 | If wrong, replies are local-only and invisible to other users |
| A7 | SOC-03 "cheers given" counter is fetched from CloudKit public DB by counting Applause records where `giverUsername == currentUsername` | Phase Requirements | If wrong, count won't reflect cross-device reality |

**If this table is empty:** Not empty — A1 through A7 require planner/implementor awareness.

---

## Open Questions

1. **COMM-01 card data source when user has no active UserChallenge**
   - What we know: `CommunityGoalsLandingView` requires a `UserChallenge` parameter
   - What's unclear: Does the COMM-01 card always show the "featured" community challenge regardless of membership, or only when the user is enrolled?
   - Recommendation: Show the card for any user; if no `UserChallenge` exists, show a simplified progress card using a `TrendingGoal` from CloudKit or a static featured goal. This matches the spirit of COMM-01 ("participant count, days remaining, % remaining").

2. **`fireCount` field on existing CommunityPost records in CloudKit**
   - What we know: `ReactionType.fire` is new; existing CKRecord posts don't have this field
   - What's unclear: Will `record["fireCount"] as? Int` return nil or 0 for old records?
   - Recommendation: Default to 0 when nil — `let fireCount = (record["fireCount"] as? Int) ?? 0`. CloudKit returns nil for missing fields, so this is safe.

3. **GoalGlimpse upsert concurrency**
   - What we know: D-01 says "upsert" (one per user per day, overwrites)
   - What's unclear: CloudKit has no native upsert. The implementation must fetch-or-create.
   - Recommendation: Fetch by `NSPredicate(format: "username == %@ AND dayKey == %@", username, todayKey)`. If found, fetch the record ID and save an updated version. If not found, create new. Wrap in a `do/catch CKError.serverRecordChanged` retry per existing pattern.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| CloudKit public DB (new record types) | GoalGlimpse, Applause, UserPresence, CommunityReply | Partially — container exists; new types not yet deployed | iCloud.com.kyleharrington.VitaminG | Silent fallback (empty array) per ExploreService pattern |
| Xcode / Swift compiler | All | ✓ | iOS 17+ target | — |
| `PhotosUI` (camera option) | COMM-07 D-10 | ✓ | iOS 17+ | Library-only if camera denied |

**Missing dependencies with no fallback:**
- CloudKit new record types (GoalGlimpse, Applause, UserPresence, CommunityReply) must be promoted to Production in CloudKit Console before real-device testing. STATE.md already tracks this in Pending Todos.

**Missing dependencies with fallback:**
- Camera access denied → fall back to library picker only (PhotosPicker), same as current PostComposeSheet behavior.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest |
| Config file | `VitaminG.xcodeproj` (VitaminGTests target) |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -testPlan VitaminGTests 2>&1 \| xcpretty` |
| Full suite command | Same — no separate full-suite target |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| COMM-02 | Carousel auto-advance timer fires after 5 seconds | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21CommunityHubViewModelTests` | ❌ Wave 0 |
| COMM-05 | Glowing This Week selection is deterministic for same weekOfYear | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21GlowingSelectionTests` | ❌ Wave 0 |
| COMM-06 | 🔥 reaction field key is "fireCount" | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21CommunityHubViewModelTests` | ❌ Wave 0 |
| COMM-07 | PostComposeSheet submits with imageData non-nil when photo attached | unit | `xcodebuild test ... -only-testing:VitaminGTests/CommunityFeedViewModelTests` (extend existing) | ✅ (extend) |
| SOC-01 | Applause daily gate: second call same day blocked; resets on new day | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21ApplauseDailyGateTests` | ❌ Wave 0 |
| SOC-01 | Applause gate is per-recipient: can applaud B after applauding A | unit | Same as SOC-01 above | ❌ Wave 0 |
| COMM-06 | CommunityHubViewModel.loadAll() calls all 5 CloudKit fetches via overrides | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21CommunityHubViewModelTests` | ❌ Wave 0 |
| COMM-06 | Reply write sanitizes profanity before CloudKit | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21ReplyTests` | ❌ Wave 0 |
| COMM-04 | Active Today filter excludes users with lastActiveDate > 2 hours ago | unit | `xcodebuild test ... -only-testing:VitaminGTests/Phase21CommunityHubViewModelTests` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/Phase21...`
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `VitaminGTests/Phase21CommunityHubViewModelTests.swift` — covers COMM-02, COMM-06, COMM-04
- [ ] `VitaminGTests/Phase21ApplauseDailyGateTests.swift` — covers SOC-01
- [ ] `VitaminGTests/Phase21GlowingSelectionTests.swift` — covers COMM-05
- [ ] `VitaminGTests/Phase21ReplyTests.swift` — covers COMM-06 reply write + profanity gate

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | CloudKit identity managed by Apple; no app-level auth in this phase |
| V3 Session Management | no | No session tokens introduced |
| V4 Access Control | yes | Applause daily gate (UserDefaults); 1-per-day-per-recipient enforcement |
| V5 Input Validation | yes | `InputSanitizer.sanitizeForPublic()` + `ProfanityFilter.containsProfanity()` on all user-generated text (GoalGlimpse title, CommunityReply text, CommunityPost text) |
| V6 Cryptography | no | No cryptographic operations in this phase |

### Known Threat Patterns for CloudKit public DB + SwiftUI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsanitized text injected into CloudKit records | Tampering | `InputSanitizer.sanitizeForPublic()` before every CKRecord string write — established pattern |
| Profane/abusive content in replies and glimpses | Information Disclosure | `ProfanityFilter.containsProfanity()` gate before submission |
| Report spam / inflated reportCount | Spoofing | `reporterIDsJSON` de-duplication already in `CommunityService.reportPost()` — apply same pattern to CommunityReply if reply reporting is in scope (not in Phase 21 requirements) |
| Applause farming (multiple applause per day) | Elevation of Privilege | UserDefaults `[recipientUsername: Date]` dictionary gate (D-04); bypassed only by clearing UserDefaults — acceptable for v2.0 social trust model |
| CKAsset path traversal | Tampering | `CommunityService.compressToJPEG` processes only `Data` + `UIImage`; no file path from user input |

---

## Project Constraints (from CLAUDE.md)

These directives from `CLAUDE.md` constrain all implementation in this phase:

| Directive | Impact on Phase 21 |
|-----------|-------------------|
| No third-party dependencies unless necessary | All APIs are Apple-native. No new SPM packages. |
| MVVM strictly enforced — no business logic in Views | `CommunityHubViewModel` owns all CloudKit fetch/write logic. Views only render and forward user actions. |
| All String inputs must have strict character limits and validation | Reply text: 300 char limit (consistent with `CommentSheetView`). GoalGlimpse title: sanitized via `InputSanitizer`. |
| iOS 17+ minimum | `@Observable`, `TabView(.page)`, `PhotosPicker` — all iOS 17+. |
| SwiftUI throughout; `@Observable` macro replaces `ObservableObject` | `CommunityHubViewModel` uses `@MainActor @Observable` pattern. |
| `NavigationStack` (not `NavigationView`) | Already established in `ContentView.swift`. |

---

## Sources

### Primary (HIGH confidence)
- Codebase: `VitaminG/Services/CommunityService.swift` — CloudKit public DB write pattern, photo compression, reaction toggle, report post
- Codebase: `VitaminG/ViewModels/CommunityFeedViewModel.swift` — `@Observable` ViewModel pattern, test override closures
- Codebase: `VitaminG/ViewModels/ExploreViewModel.swift` — UserDefaults date gate pattern for applause (D-04)
- Codebase: `VitaminG/Views/PostComposeSheet.swift` — existing photo compose flow (D-10/D-11)
- Codebase: `VitaminG/Views/Components/CommunityPostCard.swift` — reaction display, report button
- Codebase: `VitaminG/Views/Components/ReactionPill.swift` — reaction pill component
- Codebase: `VitaminG/Views/AvatarView.swift` — avatar rendering
- Codebase: `VitaminG/Views/CheckInCelebrationView.swift` — animation pattern for applause float
- Codebase: `VitaminG/Views/CommunityTabView.swift` — current structure being replaced
- Codebase: `VitaminG/Views/CommunityGoalsLandingView.swift` — COMM-01 tap destination
- Codebase: `VitaminG/Views/PublicProfileView.swift` — COMM-03 tap destination
- Codebase: `VitaminG/Views/ContentView.swift` — community tab slot (CommunityPlaceholderView)
- Codebase: `.planning/phases/21-community-tab-redesign/21-CONTEXT.md` — all locked decisions
- Codebase: `.planning/STATE.md` — CKAsset fileURL constraint, Active Today decision

### Secondary (MEDIUM confidence)
- Apple SwiftUI Documentation [ASSUMED]: `TabView(.page)` + `Timer.publish().autoconnect()` carousel pattern — standard SwiftUI page carousel approach, widely documented
- Apple CloudKit Documentation [ASSUMED]: CKRecord field nil-on-missing behavior — standard CloudKit behavior

### Tertiary (LOW confidence)
- None.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries are already in the project and verified via codebase inspection
- Architecture: HIGH — patterns are direct extensions of working code in the same codebase
- Pitfalls: HIGH — derived from existing STATE.md decisions and code inspection, not training data

**Research date:** 2026-05-23
**Valid until:** 2026-06-23 (30 days — stable iOS/CloudKit APIs)
