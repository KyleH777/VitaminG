# Phase 21: Community Tab Redesign - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 14 new/modified files
**Analogs found:** 13 / 14

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `Views/CommunityTabView.swift` (rebuilt) | view / hub coordinator | request-response | `Views/Explore/ExploreView.swift` | exact (multi-section ScrollView hub with sub-sections and ViewModel) |
| `ViewModels/CommunityHubViewModel.swift` (new) | viewmodel | CRUD + event-driven | `ViewModels/CommunityFeedViewModel.swift` | exact (`@MainActor @Observable`, test overrides, async CloudKit) |
| `Views/Community/GlimpsesCarouselSection.swift` (new) | component / section | request-response | `Views/Explore/TrendingNowSection.swift` | role-match (section sub-view, consumes ViewModel array) |
| `Views/Community/ActiveTodaySection.swift` (new) | component / section | request-response | `Views/Explore/StuckDayGiftsSection.swift` | role-match (section sub-view, horizontal list, taps open profile) |
| `Views/Community/GlowingSpotlightSection.swift` (new) | component / section | event-driven | `Views/Explore/GoalGifterCard.swift` | role-match (hero card with interaction + UserDefaults gate) |
| `Views/Community/GlobalFeedSection.swift` (new) | component / section | CRUD | `Views/CommunityFeedView.swift` | exact (CloudKit feed, `CommunityPostCard` list, compose button) |
| `Views/Community/CommunityReplySheetView.swift` (new) | component / sheet | CRUD | `Views/PostComposeSheet.swift` | role-match (sheet with text input, profanity gate, CloudKit write) |
| `Views/Community/ApplauseButtonView.swift` (new) | component / utility | event-driven | `Views/Explore/ExploreConfettiOverlay.swift` + `Views/CheckInCelebrationView.swift` | role-match (animation overlay, `withAnimation` + state) |
| `Views/Community/ApplauseStreamOverlay.swift` (new) | component / overlay | event-driven | `Views/CheckInCelebrationView.swift` (confetti Canvas pattern) | partial-match (GeometryReader overlay, staggered animation) |
| `Views/Components/CommunityPostCard.swift` (extend) | component | request-response | self | — (extending existing file) |
| `Views/Components/ReactionPill.swift` (minor extend) | component | request-response | self | — (extending existing file) |
| `Services/CommunityService.swift` (extend) | service | CRUD + file-I/O | self | — (extending existing file; new methods follow established static func patterns) |
| `ViewModels/GoalViewModel.swift` (inject at addCheckIn) | viewmodel | event-driven | self | — (injection point; pattern from existing `addGoal`) |
| `Views/ContentView.swift` (swap placeholder) | view / router | request-response | self | — (one-line swap: `CommunityPlaceholderView` → `CommunityTabView`) |

---

## Pattern Assignments

### `ViewModels/CommunityHubViewModel.swift` (new — viewmodel, CRUD + event-driven)

**Analog:** `ViewModels/CommunityFeedViewModel.swift` (lines 1–114)

**Imports pattern** (lines 1–3):
```swift
import Foundation
import Observation
import CloudKit
```

**Core ViewModel pattern** (lines 5–18):
```swift
@MainActor
@Observable
final class CommunityFeedViewModel {
    // MARK: - Public state
    var posts: [CKRecord] = []
    var isLoading: Bool = false
    var submitError: String? = nil
    var reactionError: String? = nil

    // MARK: - Test overrides (nil in production)
    var fetchOverride: ((String, Int) async throws -> [CKRecord])? = nil
    var createOverride: ((String, Data?, String, String?, String?) async throws -> CKRecord)? = nil
    var toggleOverride: ((CKRecord.ID, ReactionType, Bool) async throws -> CKRecord)? = nil
    var reportOverride: ((CKRecord.ID, String) async throws -> Int)? = nil
```
Apply this exact structure. `CommunityHubViewModel` uses the same `@MainActor @Observable final class` declaration, one override closure per CloudKit call, and `isLoading` + error state properties. Extend with sections: `glimpses`, `activeUsers`, `glowingUser`, `feedPosts`.

**Async load pattern** (lines 27–42):
```swift
func loadPosts(category: String, limit: Int = 50) async {
    isLoading = true
    defer { isLoading = false }
    do {
        if let override = fetchOverride {
            posts = try await override(category, limit)
        } else {
            posts = try await CommunityService.fetchPosts(category: category, limit: limit)
        }
    } catch {
        if posts.isEmpty { posts = [] }
        // On refresh failure, preserve existing posts
    }
}
```
Replicate this structure for each of the five section loads. Use `async let` to parallelize all five in `loadAll()`.

**Error handling pattern** (lines 75–79):
```swift
} catch {
    submitError = Self.postSaveFailureMessage
    return false
}
```
Same try/catch with named error message constants (`static let` on the class). Never expose raw `error.localizedDescription` to UI.

---

### `Views/CommunityTabView.swift` (rebuilt — view/hub coordinator, request-response)

**Analog:** `Views/Explore/ExploreView.swift` (lines 1–77)

**Imports pattern** (lines 1–3):
```swift
import SwiftUI
import SwiftData
```

**Hub layout pattern** (lines 10–36):
```swift
struct ExploreView: View {
    @State private var viewModel = ExploreViewModel()
    @State private var goalVM = GoalViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var allGoals: [Goal]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Section 1 label + card
                sectionLabel("Today's Gift")
                GoalGifterCard(viewModel: viewModel)
                // Section 2 label + card
                sectionLabel("Daily Mood")
                MoodPromptCard(viewModel: viewModel)
                // ...
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("Explore")
        .background(VGTheme.background.ignoresSafeArea())
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 13, weight: .semibold))
            .kerning(0.4)
            .foregroundStyle(VGTheme.textMuted)
            .padding(.horizontal, 16)
    }
}
```
The new `CommunityTabView` follows this exact hub pattern: `ScrollView > VStack > sectionLabel + SubSectionView` for each of the 5 COMM sections. Remove `CommunitySegment` enum and the old `Picker` — those are gone in Phase 21.

**Theme pattern** (all views):
```swift
.background(VGTheme.background)
VGTheme.serif(28)           // Cormorant Garamond headings
VGTheme.textPrimary         // body copy
VGTheme.clay                // dark text variant
VGTheme.terra               // primary CTA accent
VGTheme.surface             // card backgrounds
```
All new community views use these tokens exclusively. No raw `Color(...)` calls for brand colors.

---

### `Views/Community/GlimpsesCarouselSection.swift` (new — component, request-response)

**Analog:** `Views/Explore/TrendingNowSection.swift` (section sub-view pattern)

**Shell pattern** (from ExploreView section composition):
```swift
// Each section is a standalone View struct that receives the ViewModel
struct GlimpsesCarouselSection: View {
    let glimpses: [GoalGlimpseItem]
    // ... onTapCard, onApplaud closures passed in
    var body: some View { ... }
}
```

**Carousel core** (from RESEARCH.md Pattern 2 — confirmed pattern, `TabView(.page)` is SwiftUI standard):
```swift
@State private var currentIndex = 0
@State private var isDragging = false
let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

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
.simultaneousGesture(DragGesture()
    .onChanged { _ in isDragging = true }
    .onEnded   { _ in isDragging = false })
```
Use `Timer.publish().autoconnect()` — not `Timer.scheduledTimer`. The `.autoconnect()` form auto-cancels on view disappear (no manual invalidation needed).

**Avatar rendering in card** (from `Views/AvatarView.swift` lines 13–72):
```swift
AvatarView(
    displayName: glimpse.username,
    avatarColorHex: glimpse.authorColorHex,
    photoData: nil,   // large photos excluded per Claude's Discretion
    size: 48
)
```

---

### `Views/Community/GlowingSpotlightSection.swift` (new — component/hero card, event-driven)

**Analog:** `Views/Explore/GoalGifterCard.swift` (hero card with UserDefaults-gated interaction)

**Hero card surface pattern** (from `Views/CommunityGoalsLandingView.swift` lines 47–80):
```swift
VStack(spacing: 16) {
    ProgressRingView(
        progress: collectiveProgress,
        tier: .longTerm,
        isCompleted: false,
        size: 200,
        strokeWidth: 12,
        glow: true
    )
    // stat pills
}
.padding(20)
.background(VGTheme.surface)
.clipShape(RoundedRectangle(cornerRadius: 20))
.padding(.horizontal, 16)
.padding(.top, 16)
```
Use a similar elevated card surface with `VGTheme.terra`/`VGTheme.gold` palette for warm celebration feel.

**Navigation to PublicProfileView** (from `Navigation/AppRouter.swift` lines 11–13 + `Views/ContentView.swift` lines 47–51):
```swift
// In CommunityTabView — same pattern ContentView uses for deep-link profiles
@Environment(AppRouter.self) private var router

// On tap:
router.pendingPublicProfileRecordID = glimpse.username  // or CloudKit recordName
// ContentView already handles .sheet(item:) binding on this property
```

---

### `Views/Community/ActiveTodaySection.swift` (new — component/section, request-response)

**Analog:** `Views/Explore/StuckDayGiftsSection.swift` (horizontal scrolling list of user cards)

**Section pattern:**
```swift
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 12) {
        ForEach(activeUsers) { user in
            Button { onTapUser(user) } label: {
                VStack(spacing: 6) {
                    AvatarView(
                        displayName: user.username,
                        avatarColorHex: user.authorColorHex,
                        photoData: nil,
                        size: 48
                    )
                    Text(user.username)
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.clay)
                        .lineLimit(1)
                }
            }
            .buttonStyle(.plain)
        }
    }
    .padding(.horizontal, 16)
}
```
Tap navigates to `PublicProfileView` via `router.pendingPublicProfileRecordID` (same AppRouter pattern as ContentView uses).

---

### `Views/Community/GlobalFeedSection.swift` (new — component/section, CRUD)

**Analog:** `Views/CommunityFeedView.swift` (lines 1–186)

**Feed list pattern** (lines 65–84):
```swift
if viewModel.isLoading && viewModel.feedPosts.isEmpty {
    ProgressView().padding(.top, 32)
        .frame(maxWidth: .infinity)
} else if viewModel.feedPosts.isEmpty {
    emptyState
} else {
    LazyVStack(spacing: 12) {
        ForEach(viewModel.feedPosts, id: \.recordID) { post in
            CommunityPostCard(
                post: post,
                currentUserReaction: localReactionByPostID[post.recordID],
                accentColor: VGTheme.terra,
                onReact: { type in handleReact(post: post, type: type) },
                onReport: { Task { await handleReport(post: post) } },
                onComment: { replyPostID = post.recordID.recordName }
            )
        }
    }
    .padding(.horizontal, 16)
}
```
Replace `commentPostID` → `replyPostID` and wire to `CommunityReplySheetView` instead of `CommentSheetView`.

**Optimistic reaction pattern** (lines 145–168):
```swift
private func handleReact(post: CKRecord, type: ReactionType) {
    let prior = localReactionByPostID[post.recordID]
    if prior == type {
        localReactionByPostID[post.recordID] = nil
    } else {
        localReactionByPostID[post.recordID] = type
    }
    Task {
        if let prior, prior != type {
            _ = await viewModel.toggleReaction(recordID: post.recordID, reactionType: prior, add: false)
        }
        _ = await viewModel.toggleReaction(
            recordID: post.recordID,
            reactionType: type,
            add: localReactionByPostID[post.recordID] == type
        )
    }
}
```
Copy this verbatim for the global feed — optimistic mutual-exclusion reaction toggle is the established pattern.

**Compose CTA pattern** (lines 51–60):
```swift
Button { showCompose = true } label: {
    Label("Share Your Progress", systemImage: "square.and.pencil")
        .font(.body.weight(.semibold)).fontDesign(.rounded)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(Color(.secondarySystemGroupedBackground))
        .foregroundStyle(VGTheme.textPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}
.buttonStyle(.plain)
.padding(.horizontal, 16)
```

---

### `Views/Community/CommunityReplySheetView.swift` (new — sheet, CRUD)

**Analog:** `Views/PostComposeSheet.swift` (lines 1–160)

**Sheet structure pattern** (lines 29–135):
```swift
NavigationStack {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            // TextEditor with placeholder overlay
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body).fontDesign(.rounded)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8).padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.body).fontDesign(.rounded)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .onChange(of: text) { _, newValue in
                        if newValue.count > Self.maxChars {
                            text = String(newValue.prefix(Self.maxChars))
                        }
                        localProfanityFlagged = ProfanityFilter.containsProfanity(text)
                    }
            }
            // Character count + profanity error + submit toolbar
        }
    }
    .navigationTitle("Reply")
    .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Post") { Task { await submit() } }
                .disabled(!isPostEnabled)
        }
    }
}
```
Max chars for replies: 300 (consistent with `CommentSheetView` line 64: `String(body.prefix(300))`).

**Profanity gate pattern** (PostComposeSheet lines 140–156):
```swift
private func submit() async {
    isSubmitting = true
    defer { isSubmitting = false }
    if ProfanityFilter.containsProfanity(text) {
        localProfanityFlagged = true
        return
    }
    let success = await viewModel.writeReply(...)
    if success { dismiss() }
    else { showAlert = true }
}
```

---

### `Views/Community/ApplauseButtonView.swift` (new — component/utility, event-driven)

**Analog:** `Views/CheckInCelebrationView.swift` animation pattern + `Views/Explore/ExploreViewModel.swift` daily gate pattern

**Animation pattern** (from CheckInCelebrationView lines 82–100):
```swift
// State-driven animation — suppress under reduceMotion
@State private var showFloat = false
@State private var floatOffset: CGFloat = 0
@State private var floatOpacity: Double = 0

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
```

**Reduce motion respect** (from CheckInCelebrationView line 38):
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
// Suppress animation when reduceMotion is true — only show static state
```

**Accessibility pattern** (from ReactionPill lines 9–17):
```swift
.accessibilityLabel(canApplaud ? "Applaud \(recipientUsername)" : "Already applauded today")
.accessibilityAddTraits(.isButton)
```

---

### `Views/Community/ApplauseStreamOverlay.swift` (new — component/overlay, event-driven)

**Analog:** `Views/CheckInCelebrationView.swift` confetti canvas (lines 107–126) + `Views/Explore/ExploreConfettiOverlay.swift` (lines 1–50)

**GeometryReader overlay pattern** (from ExploreConfettiOverlay lines 7–30):
```swift
struct ApplauseStreamOverlay: View {
    let receivedApplause: [ApplauseItem]   // loaded by caller's .task
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Staggered floating 👏 items
                ForEach(Array(receivedApplause.enumerated()), id: \.offset) { i, item in
                    if !reduceMotion {
                        FloatingApplauseItem(item: item, delay: Double(i) * 0.3, size: geo.size)
                    }
                }
            }
        }
        .allowsHitTesting(false)   // overlay doesn't block interaction
    }
}
```
Use `withAnimation(.easeOut)` + `.offset` + `.opacity` for each floating item, staggered by `Double(i) * 0.3` delay.

---

### `Views/Components/CommunityPostCard.swift` (extend — component, request-response)

**Analog:** self (extending existing file)

**Current imports** (lines 1–2):
```swift
import SwiftUI
import CloudKit
```

**New field accessor to add** (follow existing accessor pattern at lines 14–23):
```swift
private var fireCount: Int { (post["fireCount"] as? Int) ?? 0 }
// Note: default to 0 for old records — CloudKit returns nil for missing fields
```

**New ReactionPill to add** (follow reaction pill pattern at lines 81–94):
```swift
ReactionPill(
    emoji: "🔥",
    count: fireCount,
    isActive: currentUserReaction == .fire,
    accentColor: accentColor,
    action: { onReact(.fire) }
)
```

**Inline reply button** (already scaffolded at lines 95–103):
```swift
// onComment closure is already present — just wire CommunityReplySheetView as caller
if let onComment {
    Button { onComment() } label: {
        HStack(spacing: 5) {
            Image(systemName: "bubble.left").font(.system(size: 12))
            Text("Reply").font(.system(size: 12))
        }
        .foregroundStyle(VGTheme.textMuted)
    }
    .buttonStyle(.plain)
}
```

---

### `Services/CommunityService.swift` (extend — service, CRUD + file-I/O)

**Analog:** self (extending existing file)

**CloudKit public DB write pattern** (lines 35–64):
```swift
static func createPost(
    text: String,
    imageData: Data?,
    category: String,
    authorDisplayName: String?,
    authorColorHex: String?
) async throws -> CKRecord {
    let container = CKContainer.default()
    let record = CKRecord(recordType: postRecordType)
    record["text"] = InputSanitizer.sanitizeForPublic(text) as CKRecordValue
    // ... set all fields
    return try await container.publicCloudDatabase.save(record)
}
```
All new methods (`writeGlimpse`, `fetchGlimpses`, `writeApplause`, `writeReply`, `fetchReplies`, `fetchActiveUsers`, `fetchGlowingUser`, `fetchGlobalPosts`, `writeUserPresence`) follow this exact static-func pattern. Every string field goes through `InputSanitizer.sanitizeForPublic()` before assignment.

**CKAsset write pattern** (lines 53–63):
```swift
if let imageData = imageData,
   let compressed = compressToJPEG(imageData, maxBytes: 500_000) {
    let tmpURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString + ".jpg")
    try compressed.write(to: tmpURL)
    defer { try? FileManager.default.removeItem(at: tmpURL) }
    record["photoAsset"] = CKAsset(fileURL: tmpURL)
    return try await container.publicCloudDatabase.save(record)
}
```
Use for `GoalGlimpse` optional `photoAsset`. Always `defer { try? FileManager.default.removeItem(at: tmpURL) }`.

**CKAsset read / copy pattern** (STATE.md constraint — copy fileURL to Application Support immediately):
```swift
// On fetch — for any CKRecord with a photoAsset field:
if let asset = record["photoAsset"] as? CKAsset,
   let src = asset.fileURL {
    let dest = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(UUID().uuidString + ".jpg")
    try? FileManager.default.copyItem(at: src, to: dest)
    // Use dest URL for display — not the temporary src
}
```

**Server conflict retry pattern** (lines 81–89):
```swift
} catch let error as CKError where error.code == .serverRecordChanged {
    // One retry on conflict — fetch latest and re-apply
    let record = try await db.record(for: recordID)
    // ... re-apply mutation
    return try await db.save(record)
}
```
Apply to `writeGlimpse` (upsert) and `writeReply`.

**Fetch with NSPredicate pattern** (lines 24–31):
```swift
let predicate = NSPredicate(format: "category == %@ AND reportCount < 3", category)
let query = CKQuery(recordType: postRecordType, predicate: predicate)
query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
let (results, _) = try await db.records(matching: query, resultsLimit: limit)
return results.compactMap { try? $0.1.get() }
```
For `fetchActiveUsers`: predicate `"lastActiveDate > %@", Date().addingTimeInterval(-7200)`.
For `fetchGlimpses`: predicate `"dayKey == %@", todayKey`.
For `fetchGlobalPosts`: predicate `"reportCount < 3"`, no category filter.

**`ReactionType` enum extension** (lines 7–16):
```swift
enum ReactionType: String {
    case thumbsUp
    case heart
    case fire      // NEW — Phase 21 COMM-06
    var fieldKey: String {
        switch self {
        case .thumbsUp: return "thumbsUpCount"
        case .heart:    return "heartCount"
        case .fire:     return "fireCount"   // NEW — CloudKit field, default 0 for old records
        }
    }
}
```

---

### `ViewModels/GoalViewModel.swift` (inject at addCheckIn — viewmodel, event-driven)

**Analog:** self (injection point only)

**Current addCheckIn signature** (lines 151–167):
```swift
func addCheckIn(for goal: Goal, context: ModelContext) {
    // Same-day dedup guard
    let alreadyCheckedInToday = goal.completionEvents?.contains { event in
        Calendar.current.isDateInToday(event.completedAt ?? .distantPast)
    } ?? false
    guard !alreadyCheckedInToday else { return }
    // ... creates CompletionEvent, reschedules, reloads widgets
}
```

**Injection point — add at end of addCheckIn, after existing logic:**
```swift
// NEW: Phase 21 — fire-and-forget GoalGlimpse upsert (D-01)
// username and colorHex passed as parameters by callers (GoalDetailView, CheckInCelebrationView)
// which already hold @Query private var profiles: [UserProfile]
Task {
    await CommunityService.writeGlimpse(
        username: username,
        goalTitle: goal.title,
        progressPercent: computedProgress,
        authorColorHex: colorHex
    )
}
```
Extend the method signature to `addCheckIn(for:context:username:colorHex:)`. Callers pass `profiles.first?.displayName` and `profiles.first?.avatarColorHex`. Fallback: `@AppStorage("vg_onboardingName")`.

---

### `Views/ContentView.swift` (swap placeholder — view, request-response)

**Analog:** self (one-line swap)

**Current community tab block** (lines 32–35):
```swift
NavigationStack {
    CommunityPlaceholderView()
}
.tag(AppTab.community)
```

**Replace with:**
```swift
NavigationStack {
    CommunityTabView(selectedTab: $selectedTab)
}
.tag(AppTab.community)
```

---

### `Views/PostComposeSheet.swift` (extend for camera — component/sheet, file-I/O)

**Analog:** `Views/ProfileView.swift` (camera source pattern) + `Views/PostComposeSheet.swift` self

**Current photo section** (lines 77–111):
```swift
PhotosPicker(selection: $selectedItem, matching: .images) {
    Label("Add Photo", systemImage: "photo.fill")
    // ...
}
```

**Replace with confirmationDialog pattern** (D-10):
```swift
@State private var showPhotoSourceDialog = false
@State private var showCamera = false

Button { showPhotoSourceDialog = true } label: {
    Label("Add Photo", systemImage: "camera.fill")
        .font(.body).fontDesign(.rounded)
        .foregroundStyle(VGTheme.clay)
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
}
.confirmationDialog("Add Photo", isPresented: $showPhotoSourceDialog) {
    Button("Photo Library") { /* show existing PhotosPicker */ }
    Button("Camera") { showCamera = true }
    Button("Cancel", role: .cancel) {}
}
// Camera sheet: UIImagePickerController representable
// (ProfileView.swift already has AVFoundation import + camera permission pattern)
```

---

## Shared Patterns

### @MainActor @Observable ViewModel
**Source:** `ViewModels/CommunityFeedViewModel.swift` lines 5–7
**Apply to:** `CommunityHubViewModel`
```swift
@MainActor
@Observable
final class CommunityHubViewModel { ... }
```

### Test Override Closures
**Source:** `ViewModels/CommunityFeedViewModel.swift` lines 14–18
**Apply to:** `CommunityHubViewModel` — one override per CloudKit call
```swift
var fetchOverride: ((String, Int) async throws -> [CKRecord])? = nil
// Pattern: if let override = fetchXOverride { return try await override(...) }
//          else { return try await CommunityService.fetchX(...) }
```

### CloudKit Public DB Save
**Source:** `Services/CommunityService.swift` lines 24–31, 35–64
**Apply to:** All new CommunityService methods
```swift
let db = CKContainer.default().publicCloudDatabase
// ... build CKRecord, set fields with as CKRecordValue
return try await db.save(record)
```

### InputSanitizer on Every User String
**Source:** `Services/CommunityService.swift` line 44
**Apply to:** GoalGlimpse title, CommunityReply text, any new user-generated string field before CloudKit write
```swift
record["text"] = InputSanitizer.sanitizeForPublic(text) as CKRecordValue
```

### ProfanityFilter Gate
**Source:** `ViewModels/CommunityFeedViewModel.swift` lines 56–59
**Apply to:** `CommunityReplySheetView.submit()`, `CommunityHubViewModel.writeReply()`
```swift
if ProfanityFilter.containsProfanity(text) {
    submitError = Self.profanityRejectionMessage
    return false
}
```

### UserDefaults Daily Gate (Applause)
**Source:** `ViewModels/ExploreViewModel.swift` lines 30–36, 56–58
**Apply to:** `ApplauseButtonView.canApplaud` + `CommunityHubViewModel.markApplauseGiven()`
```swift
// Check gate:
guard let stored = UserDefaults.standard.object(forKey: Keys.gifterDate) as? Date else {
    return false
}
return Calendar.current.isDateInToday(stored)
// Write gate:
UserDefaults.standard.set(Date(), forKey: applauseKey)
```
For applause: use `[String: Date]` dict keyed by `recipientUsername`, encoded as JSON Data (D-04 pattern from RESEARCH.md Pattern 3). Key: `"vg_community_applauseGiven"`.

### Animation with Reduce Motion Respect
**Source:** `Views/CheckInCelebrationView.swift` lines 27–28, 93–100
**Apply to:** `ApplauseButtonView`, `ApplauseStreamOverlay`
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
// Always guard animation blocks:
if !reduceMotion {
    withAnimation(.easeOut(duration: 1.0)) { ... }
} else {
    // set final state immediately
}
```

### VGTheme Typography
**Source:** `VGTheme.swift` (entire file read), `Views/CommunityTabView.swift` lines 21–23
**Apply to:** All new view files
```swift
.font(VGTheme.serif(28))          // section headings (Cormorant Garamond)
.font(.body.weight(.semibold))    // card titles
.font(.system(size: 13, weight: .semibold))  // section labels (uppercased + kerning)
.fontDesign(.rounded)             // body/caption text
```

### NavigationLink / Router for PublicProfileView
**Source:** `Navigation/AppRouter.swift` lines 11–13, `Views/ContentView.swift` lines 47–51
**Apply to:** Glimpse card tap (COMM-03), Active Today user tap (COMM-04), Glowing spotlight tap
```swift
// Set on router, ContentView handles the sheet:
router.pendingPublicProfileRecordID = username  // or CKRecord.ID.recordName
// Never present PublicProfileView directly from a sub-section view
```

### CKRecord Field Access (nil-safe)
**Source:** `Views/Components/CommunityPostCard.swift` lines 14–23
**Apply to:** All GoalGlimpse, UserPresence, Applause CKRecord accessors
```swift
// Always use optional binding or nil coalescing — never force cast
private var fireCount: Int { (post["fireCount"] as? Int) ?? 0 }
private var colorHex: String? {
    (post["authorColorHex"] as? String).flatMap { $0.isEmpty ? nil : $0 }
}
```

### iso8601 Calendar for weekOfYear
**Source:** RESEARCH.md Anti-Patterns section (codebase-confirmed pitfall from StreakFreeze)
**Apply to:** `GlowingSpotlightSection` deterministic selection
```swift
// CORRECT — Monday-anchored weekOfYear:
let week = Calendar(identifier: .iso8601).component(.weekOfYear, from: Date())
// WRONG — may vary by locale:
// Calendar.current.component(.weekOfYear, from: Date())
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `VitaminGTests/Phase21CommunityHubViewModelTests.swift` | test | — | No existing test file for a multi-section hub ViewModel; closest is `CommunityFeedViewModelTests` — planner should use RESEARCH.md Validation Architecture section for test structure |

---

## Metadata

**Analog search scope:** `VitaminG/VitaminG/VitaminG/` (all subdirectories)
**Files scanned:** 14 key analog files read
**Pattern extraction date:** 2026-05-23
