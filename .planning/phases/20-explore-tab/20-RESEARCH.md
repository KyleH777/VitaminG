# Phase 20: Explore Tab - Research

**Researched:** 2026-05-22
**Domain:** SwiftUI / SwiftData / CloudKit public DB / UIKit motion detection
**Confidence:** HIGH

---

## Summary

Phase 20 replaces `ExplorePlaceholderView` — a static "Coming soon" screen created in Phase 16 — with a full-featured Explore tab. The tab contains five distinct sections, each with its own daily-reset gate: a shake/tap goal gifter (EXPLORE-01/02), a mood prompt (EXPLORE-03), a six-category Vitamin Shelf grid (EXPLORE-04), a Trending Now community feed (EXPLORE-05), and three curated Gifts for Stuck Days (EXPLORE-06).

All daily-reset gates use the established project pattern: a `UserDefaults.standard` key that stores a date string (`yyyy-MM-dd` formatted with the current calendar), compared against today's string on view appear. This is the same mechanism used elsewhere in the project (see `StreakFreezeService` storing frozen dates as `timeIntervalSince1970`). No new persistence layer is required.

The confetti animation already exists in two views (`MilestoneCelebrationView`, `CheckInCelebrationView`) as a pure SwiftUI `Canvas + TimelineView` implementation — no SpriteKit, no third-party package. Phase 20 reuses or copies that pattern verbatim. Shake detection does not exist anywhere in the codebase yet; the standard iOS approach is a UIKit `motionEnded(_:with:)` override surfaced into SwiftUI via a `UIViewControllerRepresentable` or `UIWindow` override. The Trending Now section is the only component requiring CloudKit public DB reads; the pattern already exists in `CommunityService` (NSPredicate + CKQuery + `db.records(matching:resultsLimit:)`).

**Primary recommendation:** Build `ExploreView` as a top-level `ScrollView` with five `VStack` sections wired to an `@Observable ExploreViewModel`. All five daily-gate booleans live in the ViewModel, backed by `UserDefaults.standard`. Confetti is copied from `CheckInCelebrationView`. Shake detection uses a `ShakeDetectorViewController` (UIViewControllerRepresentable). Trending Now queries CloudKit public DB on `task` attach with a simple `CKQuery` on an existing or new `TrendingGoal` record type.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Daily gate enforcement (once per day) | ViewModel (local) | UserDefaults | Simple date-string compare; no server needed |
| Shake detection | UIKit (UIWindow/UIVC) | SwiftUI wrapper | `motionEnded` is UIKit-only |
| Confetti animation | SwiftUI Canvas | — | Already proven pattern in project |
| Goal gifter randomness | ViewModel (local) | — | Seeded by `Calendar.current.ordinality(of:.day)` |
| Mood selection persistence | UserDefaults | — | Mood is ephemeral per-day; not a SwiftData model |
| Vitamin Shelf browsing | SwiftUI View + `@Query` | SwiftData | Filters existing local Goal records by `category` |
| Trending Now data | CloudKit public DB | ViewModel async | Requires CKQuery; async fetch on appear |
| Stuck-Day Gifts seeding | ViewModel (local) | — | Deterministic `dayOfYear % giftsPool.count` |
| Add gifted goal to user list | SwiftData modelContext | GoalViewModel | Same `context.insert` pattern used everywhere |
| Counter display (EXPLORE-02) | SwiftData `@Query` | — | Count of goals added via gifter today |

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EXPLORE-01 | Shake OR "Surprise me" button gifts one random daily goal with confetti | Shake via `motionEnded` UIKit bridge; confetti from existing Canvas pattern; goal from pre-seeded pool |
| EXPLORE-02 | One-per-day gate on gifter; accomplished counter top-right shows gifted goals completed today | UserDefaults date-string gate; counter computed from `@Query` on gifted goals |
| EXPLORE-03 | "How are you feeling?" prompt once per day; selecting a mood collapses with checkmark | UserDefaults date-string gate; mood selection is local-only, no model required |
| EXPLORE-04 | Vitamin Shelf — 6 category cards navigate to filtered goal list | `GoalCategory` enum already defines all 6 Vitamin Shelf categories (Body, Mind, Wellness, Money, Connection, Creative); NavigationLink to filtered view |
| EXPLORE-05 | Trending Now — 3-5 active community goals with progress circles | CKQuery on CloudKit public DB `TrendingGoal` record type (new) or via existing community goal data; `ProgressRingView` reused |
| EXPLORE-06 | 3 Gifts for Stuck Days seeded by day-of-year; tapping "Add" inserts goal and hides card | Same `dayOfYear % pool.count` pattern as `VGQuoteBank.todaysQuote()`; `context.insert` via `GoalViewModel.addGoal(input:context:)` |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | All UI — ScrollView, LazyVGrid, Canvas, TimelineView | Project minimum; `@Observable` ViewModel binding |
| SwiftData | iOS 17+ | Insert gifted goals, query user goals by category | Established project persistence; `modelContext.insert` pattern |
| CloudKit | iOS 17+ | Fetch Trending Now community goal records | Already used in `CommunityService`; public DB reads are anonymous |
| UIKit (bridge only) | iOS 17+ | `motionEnded(_:with:)` shake detection | `UIViewControllerRepresentable` wraps UIKit; no SwiftUI-native shake API |
| UserDefaults | — | Daily-gate date strings; mood selection state | Established pattern for ephemeral per-day state (see `BlockListService`, `NotificationPreferences`) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ProgressRingView | (internal) | Progress circles on Trending Now cards | Already in project at `Views/Components/ProgressRingView.swift` |
| VGTheme | (internal) | Colors, Cormorant Garamond fonts, surface tokens | All new views must use VGTheme exclusively |
| StreakEngine | (internal) | Computing per-goal consecutive day streaks | If Vitamin Shelf goal cards show flame icons |
| GoalViewModel | (internal) | `addGoal(input:context:)` to insert gifted/stuck-day goals | Handles validation, notification reschedule, widget reload |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| UIKit shake bridge | CoreMotion CMMotionManager accelerometer | CoreMotion is more complex, requires background permission risk; UIKit `motionEnded` is simpler and purpose-built for shake |
| UserDefaults date-string | SwiftData model (GiftedGoalLog) | SwiftData model is heavier and risks migration; UserDefaults is sufficient for ephemeral daily flags |
| CloudKit public DB for Trending | Local mock/seeded data | Mock data satisfies the UI but violates EXPLORE-05 ("community completion %"); CloudKit is the right source |

**No new external packages required.** This phase uses only Apple frameworks and existing internal components.

---

## Package Legitimacy Audit

No external packages are installed in this phase. All capabilities use Apple frameworks and existing internal components.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
User Action (shake / tap / mood select / category tap / add gift)
        |
        v
ExploreView (SwiftUI ScrollView)
  |-- ExploreViewModel (@Observable, @MainActor)
  |     |-- UserDefaults daily gates (gifter, mood)
  |     |-- gifterGoalPool: [GifterGoal] (static, seeded by dayOfYear)
  |     |-- stuckDayGifts: [StuckDayGift] (static, seeded by dayOfYear)
  |     |-- trendingGoals: [TrendingGoalEntry] (async from CloudKit)
  |     |-- Task { await fetchTrending() } on .task modifier
  |
  |-- ShakeDetectorView (UIViewControllerRepresentable)
  |     `-- UIViewController.motionEnded -> viewModel.onShake()
  |
  |-- Section 1: GoalGifterCard
  |     `-- confetti: Canvas + TimelineView (copied from CheckInCelebrationView)
  |
  |-- Section 2: MoodPromptCard (collapsed/expanded daily gate)
  |
  |-- Section 3: VitaminShelfGrid (LazyVGrid 2-col)
  |     `-- NavigationLink -> CategoryGoalListView(category:)
  |
  |-- Section 4: TrendingNowSection
  |     `-- ProgressRingView per card
  |
  `-- Section 5: StuckDayGiftsSection
        `-- "Add" Button -> GoalViewModel.addGoal(input:context:)
                          -> UserDefaults hide-card gate (per gift, per day)

CloudKit public DB (async, on .task)
  `-- CKQuery(recordType: "TrendingGoal") -> ExploreViewModel.trendingGoals
```

### Recommended Project Structure

```
VitaminG/Views/
├── Explore/
│   ├── ExploreView.swift           # Root ScrollView; wires all sections
│   ├── GoalGifterCard.swift        # Shake/tap gifter + confetti section
│   ├── MoodPromptCard.swift        # "How are you feeling?" collapsible card
│   ├── VitaminShelfGrid.swift      # 6-category LazyVGrid
│   ├── CategoryGoalListView.swift  # Filtered goal list (NavigationLink destination)
│   ├── TrendingNowSection.swift    # CloudKit-backed trending list
│   └── StuckDayGiftsSection.swift  # 3 curated easy-win goals
VitaminG/ViewModels/
└── ExploreViewModel.swift          # @Observable ViewModel; owns all daily gates + async fetch
VitaminG/Services/
└── ExploreService.swift            # CloudKit fetch for Trending Now (mirrors CommunityService style)
VitaminG/Utilities/
└── ShakeDetectorView.swift         # UIViewControllerRepresentable shake bridge
```

### Pattern 1: Daily Gate with UserDefaults Date String

**What:** Enforce "only once per calendar day" by storing today's ISO date string and comparing on view appear.

**When to use:** Every once-per-day action in the Explore tab (gifter, mood prompt, stuck-day gift cards).

**Example:**
```swift
// Source: established project pattern; mirrors BlockListService key approach
private static let gifterUsedKey = "vg_explore_gifterUsedDate"

var hasUsedGifterToday: Bool {
    let stored = UserDefaults.standard.string(forKey: gifterUsedKey)
    let today = todayDateString()
    return stored == today
}

func markGifterUsed() {
    UserDefaults.standard.set(todayDateString(), forKey: gifterUsedKey)
    hasUsedGifterToday = true
}

private func todayDateString() -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    fmt.calendar = Calendar.current
    return fmt.string(from: Date())
}
```

### Pattern 2: Shake Detection via UIViewControllerRepresentable

**What:** Detect `motionEnded(_:with:)` events (UIKit shake) and forward them to the ViewModel via a closure.

**When to use:** EXPLORE-01 shake gesture. This is the only correct approach — SwiftUI has no built-in shake API on iOS 17. [ASSUMED based on training knowledge; iOS 17 release notes do not add a native SwiftUI shake modifier]

**Example:**
```swift
// Source: [ASSUMED] — standard UIKit bridge pattern; no SwiftUI native API
struct ShakeDetectorView: UIViewControllerRepresentable {
    let onShake: () -> Void

    func makeUIViewController(context: Context) -> ShakeVC {
        let vc = ShakeVC()
        vc.onShake = onShake
        return vc
    }
    func updateUIViewController(_ uiViewController: ShakeVC, context: Context) {}
}

final class ShakeVC: UIViewController {
    var onShake: (() -> Void)?
    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake { onShake?() }
    }
}
```

Placement: Add as a `Color.clear.frame(width: 0, height: 0)` overlay or `.background` modifier in ExploreView so it always holds first-responder focus.

**Accessibility mandate (EXPLORE-01):** The visible "Surprise me" tap button is NOT optional — it is a mandatory accessibility fallback for users with physical disabilities who cannot shake a device. Both the shake and tap path must call the same `viewModel.onGifterActivated()` function.

### Pattern 3: Day-of-Year Seeded Deterministic Selection

**What:** Produce the same N items for all users on a given calendar day, without a network call.

**When to use:** Goal gifter daily selection (EXPLORE-01), Stuck Day Gifts pool (EXPLORE-06).

**Example:**
```swift
// Source: [VERIFIED: codebase] — VGQuoteBank.todaysQuote() uses this exact pattern
static func todaysGift(from pool: [StuckDayGift]) -> [StuckDayGift] {
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    // For 3 gifts, step through pool using dayOfYear as seed offset
    let startIndex = (dayOfYear - 1) % pool.count
    return (0..<3).map { pool[(startIndex + $0) % pool.count] }
}
```

### Pattern 4: CloudKit Public DB Async Fetch

**What:** Query the public CloudKit database for Trending Now records, returning a sorted array.

**When to use:** EXPLORE-05 Trending Now section on `ExploreView.task`.

**Example:**
```swift
// Source: [VERIFIED: codebase] — mirrors CommunityService.fetchPosts pattern
static func fetchTrendingGoals(limit: Int = 5) async throws -> [CKRecord] {
    let db = CKContainer.default().publicCloudDatabase
    // "participantCount" is a sortable field on TrendingGoal record type
    let query = CKQuery(recordType: "TrendingGoal", predicate: NSPredicate(value: true))
    query.sortDescriptors = [NSSortDescriptor(key: "participantCount", ascending: false)]
    let (results, _) = try await db.records(matching: query, resultsLimit: limit)
    return results.compactMap { try? $0.1.get() }
}
```

### Pattern 5: Insert Goal from Explore (context.insert)

**What:** When user taps "Add" on a gifted or stuck-day goal, insert a new Goal into SwiftData.

**When to use:** EXPLORE-01 (goal gifter), EXPLORE-06 (stuck day gifts).

**Example:**
```swift
// Source: [VERIFIED: codebase] — GoalViewModel.addGoal(input:context:) existing path
let input = GoalInput(
    title: gift.title,
    tier: .immediate,
    category: gift.category,
    frequency: .daily,
    reminderTime: nil,
    isPrivate: true,
    startDate: Date()
)
try? viewModel.addGoal(input: input, context: modelContext)
```

GoalViewModel handles notification reschedule and `WidgetCenter.shared.reloadAllTimelines()` automatically — callers do not need to call these separately.

### Pattern 6: Confetti Animation (SwiftUI Canvas)

**What:** 60-particle Canvas + TimelineView confetti. No SpriteKit, no third-party.

**When to use:** Goal gifter activation (EXPLORE-01). Copy verbatim from `CheckInCelebrationView.confettiView`.

**Anti-Patterns to Avoid**
- **SpriteKit for confetti:** Not used anywhere in the codebase; the Canvas pattern is established and simpler. Do not add an SKScene.
- **CoreMotion for shake:** `CMMotionManager` accelerometer polling is heavier than `motionEnded`; requires continuous polling loop; significantly more complex. Use `motionEnded`.
- **SwiftData model for mood:** MoodEntry exists in SchemaV7 but was added for a different purpose (idea board mood logging). Do not reuse SchemaV7.MoodEntry for the daily mood prompt — UserDefaults is sufficient for a per-day "did user pick a mood today?" flag. Avoid a new SwiftData schema version for ephemeral daily UI state.
- **New schema version for gifter state:** Do not create SchemaV9 for Explore daily state. All Explore daily state (gifter used, mood selected, stuck-day cards hidden) fits cleanly in UserDefaults. Only add a schema version if data must survive a reinstall (it should not for daily ephemeral state).
- **Storing mood value in UserDefaults beyond the date:** The requirement (EXPLORE-03) only says the prompt collapses "with a checkmark." The mood value itself does not need to be stored beyond dismissal. Store only the date string gate, not the selected mood integer.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Confetti animation | SKScene or third-party library | `Canvas + TimelineView` (copy from `CheckInCelebrationView.confettiView`) | Already proven in codebase; no new dependency |
| Progress circles on Trending cards | Custom arc drawing | `ProgressRingView(progress:tier:isCompleted:size:)` | Existing component at `Views/Components/ProgressRingView.swift`; supports sublabel for % display |
| Goal insertion with side effects | `context.insert(Goal(...))` inline in View | `GoalViewModel.addGoal(input:context:)` | Handles notification reschedule + widget reload — skipping this causes widget/notification staleness |
| CloudKit fetch error handling | Custom retry loops | Mirror `CommunityService` pattern (one `serverRecordChanged` retry) | Established pattern; prevents duplicate work |
| Vitamin Shelf category filtering | Manual string comparison | `#Predicate { $0.category == selectedCategory.rawValue }` with `@Query` | SwiftData predicate is type-safe and efficient |

**Key insight:** The Explore tab has no net-new complexity that requires custom solutions. Every sub-problem maps to an existing project pattern.

---

## Runtime State Inventory

This is a greenfield feature phase (new view replacing a placeholder). No rename/refactor involved.

**Nothing found in any category** — verified by codebase search. No stored data, live service config, OS-registered state, secrets/env vars, or build artifacts require updating.

---

## Common Pitfalls

### Pitfall 1: Vitamin Shelf Categories vs. GoalCategory Enum

**What goes wrong:** Developer creates a new enum or hardcodes string literals for the 6 Vitamin Shelf categories, then hits a type mismatch when filtering SwiftData Goals.

**Why it happens:** The spec says "Body, Mind, Wellness, Money, Connection, Creative." The `GoalCategory` enum already has all 6 as cases (`.body`, `.mind`, `.wellness`, `.money`, `.connection`, `.creative`) plus `.habit` and `.other`.

**How to avoid:** Use `GoalCategory` directly. The Vitamin Shelf grid shows a subset: `[.body, .mind, .wellness, .money, .connection, .creative]`. Filter SwiftData Goals using `goal.category == selectedCategory.rawValue`. Do not introduce a separate `VitaminShelfCategory` type.

**Warning signs:** Any file that imports a new type for categories; any `#Predicate` comparing to a string literal instead of `GoalCategory.rawValue`.

### Pitfall 2: Shake Detector Losing First Responder

**What goes wrong:** `ShakeVC` becomes first responder on `viewDidAppear`, but SwiftUI lifecycle causes the VC to disappear/reappear when navigating to `CategoryGoalListView`, losing first responder on return. Shake stops working after first navigation.

**Why it happens:** `UIViewControllerRepresentable` view controllers follow SwiftUI's view lifecycle. A `NavigationLink` push causes the Explore view to be backgrounded; `viewDidDisappear` fires and first-responder status is lost. `viewDidAppear` must call `becomeFirstResponder()` every time it fires — not just once.

**How to avoid:** Override `viewDidAppear` (not `viewDidLoad`) to call `becomeFirstResponder()`. This ensures first responder is re-acquired on every return from a NavigationLink push.

**Warning signs:** Shake works on first app launch but stops working after tapping a Vitamin Shelf category and returning.

### Pitfall 3: CloudKit TrendingGoal Record Type Must Be Promoted to Production

**What goes wrong:** `TrendingGoal` is a new CloudKit public DB record type. It works in development (simulator/TestFlight) but fails in production because the record type was never promoted in CloudKit Console.

**Why it happens:** CloudKit development and production schemas are separate. New record types created in development are not automatically promoted.

**How to avoid:** Add a human checkpoint plan before any production release that requires a developer to open CloudKit Console → Schema → Record Types → Deploy Schema Changes to Production. The same note appears in STATE.md for UserPresence, Applause, Follow — follow the same process.

**Warning signs:** CKError with `.unknownItem` or `.serverRejectedRequest` on production builds only.

### Pitfall 4: Mood Entry Confusion with SchemaV7.MoodEntry

**What goes wrong:** Developer discovers `SchemaV7.MoodEntry` in the codebase and tries to use it for the daily mood prompt, creating a SwiftData insert on every mood selection and requiring a SchemaV9 migration.

**Why it happens:** `SchemaV7.MoodEntry` exists (mood: Int 0–4, recordedAt: Date, note: String?) and looks like the right type. But it was added for the Idea Board feature and has different semantics.

**How to avoid:** The Explore tab mood prompt only needs to know (a) did the user pick a mood today? and (b) what checkmark to show. Use two UserDefaults keys: `vg_explore_moodDate` (string) and `vg_explore_moodValue` (Int). Do NOT insert into SwiftData for this.

**Warning signs:** Any code path that calls `context.insert(MoodEntry(...))` from ExploreViewModel.

### Pitfall 5: Daily Gate Reset Timing (Midnight vs. Wake)

**What goes wrong:** The daily gate checks `"yyyy-MM-dd"` formatted with `Calendar.current`. If the user stays on the Explore tab past midnight, the gate resets but the view state (e.g., `hasUsedGifterToday`) still shows the old day's result because the ViewModel was initialized before midnight.

**Why it happens:** The ViewModel reads UserDefaults once on `init()` and caches the boolean. The gate's UserDefaults key updates at midnight but the cached boolean does not.

**How to avoid:** Compute the gate check as a computed property (not a stored property) in the ViewModel — always compare `UserDefaults.standard.string(forKey: key)` to `todayDateString()` at the call site. Or use `onForeground` scene phase observation to refresh gate state when the app returns from background.

**Warning signs:** Gate appears to stay "used" on the next calendar day if the app was not backgrounded.

### Pitfall 6: Accessibility for Reduce Motion (Confetti)

**What goes wrong:** Confetti `Canvas + TimelineView` plays on celebration even when the user has "Reduce Motion" enabled in iOS Accessibility settings.

**Why it happens:** `CheckInCelebrationView` already handles this correctly (`if !reduceMotion { confettiView }`), but a new developer copying the confetti code may forget the reduce motion guard.

**How to avoid:** Always wrap the confetti canvas in `if !reduceMotion { ... }` using `@Environment(\.accessibilityReduceMotion)`. Copy the full pattern from `CheckInCelebrationView`, not just the canvas body.

---

## Code Examples

### Existing Confetti Pattern (Reuse Verbatim)

```swift
// Source: [VERIFIED: codebase] VitaminG/Views/CheckInCelebrationView.swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

private var confettiView: some View {
    TimelineView(.animation) { timeline in
        Canvas { context, size in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let count = 60
            for i in 0..<count {
                let seed = Double(i) * 137.5  // golden angle scatter
                let x = (sin(seed + now * 0.8 + Double(i)) * 0.5 + 0.5) * size.width
                let rawY = (now * 80.0 + seed * 3.7).truncatingRemainder(dividingBy: size.height)
                let y = rawY < 0 ? rawY + size.height : rawY
                let hue = (seed / 360.0).truncatingRemainder(dividingBy: 1.0)
                let color = Color(hue: hue, saturation: 0.8, brightness: 0.9)
                let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                context.fill(Path(rect), with: .color(color))
            }
        }
    }
}

// Guard:
if !reduceMotion { confettiView.ignoresSafeArea().accessibilityHidden(true) }
```

### UserDefaults Date Key Pattern (Established in Project)

```swift
// Source: [VERIFIED: codebase] BlockListService uses UserDefaults.standard.data(forKey:)
// NotificationPreferences uses UserDefaults.standard.integer(forKey:)
// This date-string pattern is the correct extension for per-day gates.

private enum ExploreKeys {
    static let gifterUsedDate   = "vg_explore_gifterDate"
    static let moodSelectedDate = "vg_explore_moodDate"
    static let moodValue        = "vg_explore_moodValue"
    // Per stuck-day card: "vg_explore_stuckHidden_\(gift.id)"
}

private func todayDateString() -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    return fmt.string(from: Date())
}
```

### GoalCategory Vitamin Shelf Filter

```swift
// Source: [VERIFIED: codebase] GoalCategory.swift — enum cases match spec exactly
static let vitaminShelfCategories: [GoalCategory] = [
    .body, .mind, .wellness, .money, .connection, .creative
]

// In CategoryGoalListView:
@Query private var allGoals: [Goal]
let category: GoalCategory

private var filteredGoals: [Goal] {
    allGoals.filter { $0.category == category.rawValue && !$0.isCompleted }
}
```

### CKQuery Pattern for Trending Now

```swift
// Source: [VERIFIED: codebase] mirrors CommunityService.fetchPosts exactly
// containerID = "iCloud.com.kyleharrington.VitaminG" (from CommunityService)
static func fetchTrendingGoals(limit: Int = 5) async throws -> [CKRecord] {
    let db = CKContainer.default().publicCloudDatabase
    let query = CKQuery(
        recordType: "TrendingGoal",
        predicate: NSPredicate(value: true)  // fetch all; sort by participantCount
    )
    query.sortDescriptors = [NSSortDescriptor(key: "participantCount", ascending: false)]
    let (results, _) = try await db.records(matching: query, resultsLimit: limit)
    return results.compactMap { try? $0.1.get() }
}
```

### GoalViewModel.addGoal(input:context:) Call Site

```swift
// Source: [VERIFIED: codebase] GoalViewModel.swift — addGoal(input:context:) handles
// validation, notification reschedule, and widget reload automatically.
@Environment(\.modelContext) private var modelContext
@State private var goalVM = GoalViewModel()

func addGiftedGoal(_ gift: GifterGoal) {
    let input = GoalInput(
        title: gift.title,
        tier: .immediate,
        category: gift.category,
        frequency: .daily,
        reminderTime: nil,
        isPrivate: true,
        startDate: Date()
    )
    try? goalVM.addGoal(input: input, context: modelContext)
    // No need to call WidgetCenter or rescheduleNotification — GoalViewModel does it.
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SpriteKit particle emitter for confetti | SwiftUI `Canvas + TimelineView` | Phase 13 (MilestoneCelebrationView) | No SpriteKit import needed; works in previews |
| `ObservableObject + @Published` ViewModel | `@Observable` macro | Phase 1 (D-07) | Property-level invalidation; simpler boilerplate |
| `NavigationView` | `NavigationStack` | Phase 1 | Programmatic navigation via `AppRoute` |

**Deprecated/outdated:**
- `ObservableObject / @Published`: CLAUDE.md explicitly bans for this project; use `@Observable` macro exclusively.
- SpriteKit for UI animations: Not used anywhere in codebase; `Canvas + TimelineView` covers all animation needs.

---

## Existing Infrastructure Map (Key Discovery Results)

### What Phase 16 Left for Phase 20

`ExplorePlaceholderView` at `VitaminG/VitaminG/VitaminG/Views/Placeholders/ExplorePlaceholderView.swift`:
```swift
// [VERIFIED: codebase] — Phase 16 placeholder, ready to replace
struct ExplorePlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Coming soon").font(VGTheme.serif(28))...
            Text("Something exciting is brewing.")...
        }
        .background(VGTheme.heroBackground.ignoresSafeArea())
    }
}
```

`ContentView.swift` wires it at line 27-30:
```swift
NavigationStack {
    ExplorePlaceholderView()
}
.tag(AppTab.explore)
```

**Migration:** Replace `ExplorePlaceholderView()` with `ExploreView()` in `ContentView.swift`. The `NavigationStack` wrapper stays — `ExploreView` should NOT create its own `NavigationStack`. Category list views pushed via `NavigationLink` will use the existing `NavigationStack` from `ContentView`.

### GoalCategory — Vitamin Shelf Is a Subset [VERIFIED: codebase]

GoalCategory enum has 8 cases: `.body`, `.mind`, `.wellness`, `.money`, `.connection`, `.creative`, `.habit`, `.other`. The Vitamin Shelf uses the first 6 exactly. No new type is needed.

### Goal Model Fields [VERIFIED: codebase — SchemaV6.Goal]

The current `Goal` model (defined in `SchemaV6.Goal`, referenced as `Goal` via typealiases):
- `id: UUID`
- `title: String?`
- `goalDescription: String?`
- `tierRawValue: String?` (computed accessor: `var tier: GoalTier`)
- `isCompleted: Bool = false`
- `creationDate: Date?`
- `associatedInspiration: String?`
- `isPublic: Bool = false`
- `category: String?` (matches `GoalCategory.rawValue`)
- `frequency: String?` (matches `GoalFrequency.rawValue`)
- `reminderTime: Date?`
- `startDate: Date?`
- `durationDays: Int?`
- `completionEvents: [CompletionEvent]?` (relationship)

**No schema migration needed for Phase 20.** All fields required by Explore are already present. Gifted goals use `category`, `title`, `tier`, `frequency`, `isPublic` — all in SchemaV6.

### MoodEntry (SchemaV7) — Do NOT Use for Explore Mood Prompt [VERIFIED: codebase]

`SchemaV7.MoodEntry` fields: `id: UUID`, `mood: Int` (0=Amazing 1=Good 2=Okay 3=Low 4=Push), `recordedAt: Date`, `note: String?`. This was added for the Idea Board module. Using it for the Explore mood prompt would require inserting SwiftData records for ephemeral per-day state and entangles two unrelated features. Use UserDefaults only.

### CommunityService Container ID [VERIFIED: codebase]

CloudKit container identifier: `"iCloud.com.kyleharrington.VitaminG"`. `ExploreService` (new) must use `CKContainer.default()` (which resolves to the container in the app's entitlements) or `CKContainer(identifier: "iCloud.com.kyleharrington.VitaminG")` for consistency.

### Confetti — No SpriteKit in Project [VERIFIED: codebase]

Grep for `SpriteKit`, `SKScene`, `SKEmitter`, `MilestoneCelebration` — confetti is 100% SwiftUI Canvas. The `confettiView` computed property in `CheckInCelebrationView` and `MilestoneCelebrationView` are identical (lines 104-126). Copy verbatim for `GoalGifterCard`.

### Shake Detection — No Existing Implementation [VERIFIED: codebase]

Grep for `motionEnded`, `motionShake`, `CoreMotion`, `CMMotionManager`, `beginGeneratingDeviceOrientationNotifications` — zero results. This is net-new for Phase 20.

---

## CloudKit Schema: TrendingGoal Record Type (New)

Phase 20 is the first feature to query "trending goals" from CloudKit. A new `TrendingGoal` public DB record type is needed. Recommended fields:

| Field | Type | Notes |
|-------|------|-------|
| title | String | Goal title (sanitized) |
| category | String | GoalCategory rawValue |
| participantCount | Int | For sort + progress circle denominator |
| completedCount | Int | For community completion % |
| createdAt | Date | For "newest" community goal criterion |

**CloudKit Console action required (human checkpoint):** Before Phase 20 real-device testing:
1. Create `TrendingGoal` record type in CloudKit Console (development schema)
2. Add Queryable index on `participantCount`
3. Deploy schema to production

**Seeding strategy:** For the planner — the simplest approach that satisfies EXPLORE-05 without requiring a server-side job is: seed 3-5 `TrendingGoal` records manually via CloudKit Console Dashboard for the initial release, and update them periodically. Phase 21's community infrastructure can later automate this. [ASSUMED — no seeding mechanism exists yet]

**Alternative for MVP:** If CloudKit records cannot be seeded before release, EXPLORE-05 can fall back to a hardcoded in-memory `[TrendingGoalEntry]` for the initial build, with a `fetchTrending()` that overlays live CloudKit data when available. This keeps the UI functional even if the CloudKit schema is not yet promoted.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | SwiftUI iOS 17 has no native shake gesture modifier; UIKit `motionEnded` bridge is required | Standard Stack, Pattern 2 | Low — iOS 17 release notes and Apple docs do not mention a shake modifier; if Apple added one, the UIKit bridge still works |
| A2 | `TrendingGoal` CloudKit record type does not yet exist; must be created in CloudKit Console | CloudKit Schema section | Medium — if a prior phase created it under a different name, use that name instead |
| A3 | Seeding TrendingGoal records requires manual CloudKit Console action or a future automated job | CloudKit Schema section | Medium — if the planner decides to seed via a one-time migration plan, architecture is unchanged |
| A4 | The mood value (0-4 integer) does not need to be persisted beyond the day; only the gate date is stored | Pattern 1, Common Pitfalls | Low — requirement says card collapses with checkmark; no spec for mood history |
| A5 | No SchemaV9 is needed for Phase 20 | Standard Stack | HIGH confidence — verified all Explore daily state fits in UserDefaults and Goal model has all required fields |

---

## Open Questions

1. **TrendingGoal data source — seeded or live-computed?**
   - What we know: EXPLORE-05 says "3-5 most active community goals + newest community goal" with "community completion % toward 100%." This implies CloudKit public DB reads with participantCount.
   - What's unclear: Who writes `TrendingGoal` records? Is this a manual seed, a CloudKit Function, or computed on-device from existing community data?
   - Recommendation: For Phase 20, the planner should add a human checkpoint task — "Seed TrendingGoal records in CloudKit Console (dev + prod)." Automated seeding can be a Phase 21 follow-up. The view should handle an empty array gracefully (hide the section or show a "check back soon" state).

2. **Accomplished counter (EXPLORE-02) — count gifted goals that were completed today vs. total gifted?**
   - What we know: EXPLORE-02 says "an accomplished counter is shown in the top-right of the Explore tab incrementing as the user completes gifted goals."
   - What's unclear: "Completes" could mean (a) completed via check-in today, or (b) marked as isCompleted permanently.
   - Recommendation: Use (a) — count of `CompletionEvent` records today for goals that were added via the gifter. This requires a tag on goals added via the gifter (e.g., `associatedInspiration = "vg_gifter"` flag) or a UserDefaults array of gifted goal IDs for today. Simplest: tag with `associatedInspiration` on insert, then `@Query` + filter by today's date.

3. **Vitamin Shelf — show all goals or only user's active goals?**
   - What we know: EXPLORE-04 says "filtered list of goals in that category." Ambiguous whether this means community goals (CloudKit) or the user's own goals (SwiftData).
   - What's unclear: If community goals, a CKQuery is needed. If personal goals, `@Query` with category filter is sufficient.
   - Recommendation: Phase 20 should show the user's own goals by category (SwiftData `@Query`) since the Vitamin Shelf is framed as "discover what others are working on" but Phase 22 (Discover) explicitly adds public goal search. Use local SwiftData for Phase 20; add community browsing in Phase 22.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| CloudKit public DB | EXPLORE-05 Trending Now | ✓ | Already provisioned | Hardcoded in-memory TrendingGoal entries |
| UIKit (UIViewController) | Shake detection | ✓ | iOS 17+ | None needed — UIKit is always available |
| Xcode 15+ | Build | ✓ | Assumed from project | — |
| CloudKit Console access | TrendingGoal schema creation | Human action required | — | Manual checkpoint task in plan |

**Missing dependencies with no fallback:** CloudKit Console schema deployment (TrendingGoal record type) — requires a human checkpoint before real-device testing.

**Missing dependencies with fallback:** TrendingGoal records (CloudKit data seed) — fall back to empty section with "Check back soon" empty state.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (VitaminGTests target) |
| Config file | Xcode project target — no separate config file |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/ExploreViewModelTests` |
| Full suite command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EXPLORE-01 | `onGifterActivated()` adds goal and sets `hasUsedGifterToday = true` | unit | `...-only-testing:VitaminGTests/ExploreViewModelTests/testGifterActivation` | ❌ Wave 0 |
| EXPLORE-02 | Second call to `onGifterActivated()` on same day is a no-op | unit | `...-only-testing:VitaminGTests/ExploreViewModelTests/testGifterGate` | ❌ Wave 0 |
| EXPLORE-02 | Daily gate resets when `todayDateString()` returns a new date | unit | `...-only-testing:VitaminGTests/ExploreViewModelTests/testGifterGateReset` | ❌ Wave 0 |
| EXPLORE-03 | `selectMood(_:)` sets `hasMoodSelectedToday = true` | unit | `...-only-testing:VitaminGTests/ExploreViewModelTests/testMoodGate` | ❌ Wave 0 |
| EXPLORE-04 | `GoalCategory.vitaminShelfCategories` returns exactly 6 cases | unit | `...-only-testing:VitaminGTests/ExploreViewModelTests/testVitaminShelfCategories` | ❌ Wave 0 |
| EXPLORE-05 | `ExploreService.fetchTrendingGoals` returns `[CKRecord]` (mock or offline) | manual | Manual device test with seeded CK data | — |
| EXPLORE-06 | `todaysStuckDayGifts()` returns 3 items deterministically for same dayOfYear | unit | `...-only-testing:VitaminGTests/ExploreViewModelTests/testStuckDayGiftDeterminism` | ❌ Wave 0 |
| EXPLORE-06 | Tapping "Add" hides card for rest of day (UserDefaults gate per gift ID) | unit | `...-only-testing:VitaminGTests/ExploreViewModelTests/testStuckDayHideGate` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/ExploreViewModelTests`
- **Per wave merge:** Full suite (`VitaminGTests` target, all tests)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `VitaminGTests/ExploreViewModelTests.swift` — covers EXPLORE-01, EXPLORE-02, EXPLORE-03, EXPLORE-04, EXPLORE-06 unit tests
- [ ] `ExploreViewModel.swift` stub with testable interface (UserDefaults-injectable init for testing daily gate isolation)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Goal title for gifted/stuck-day goals goes through `GoalViewModel.addGoal(input:context:)` which calls `InputSanitizer.sanitize(_:)` and validates char limits |
| V6 Cryptography | no | — |

### Known Threat Patterns for CloudKit public DB reads

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| CKRecord field injection via `TrendingGoal.title` | Tampering | Read-only query; data displayed, not executed; InputSanitizer on any user-visible string before display |
| Mood selection value overflow | Tampering | Mood is an enum (0-4); validate before storing with `guard (0...4).contains(mood)` |
| Gifted goal title XSS/injection | Tampering | Title comes from a hardcoded Swift array (not user input); no sanitization needed for seeded data |

---

## Sources

### Primary (HIGH confidence)
- `[VERIFIED: codebase]` — All patterns cited are directly read from existing Swift source files in `VitaminG/VitaminG/VitaminG/`
- `[VERIFIED: codebase]` — `CheckInCelebrationView.swift` — confetti pattern (Canvas + TimelineView, 60 particles, golden-angle scatter)
- `[VERIFIED: codebase]` — `MilestoneCelebrationView.swift` — confetti pattern (identical to CheckInCelebrationView)
- `[VERIFIED: codebase]` — `CommunityService.swift` — CloudKit public DB query pattern (CKQuery, NSPredicate, resultsLimit)
- `[VERIFIED: codebase]` — `GoalViewModel.swift` — `addGoal(input:context:)` insert pattern
- `[VERIFIED: codebase]` — `GoalCategory.swift` — 8 enum cases; 6 map to Vitamin Shelf
- `[VERIFIED: codebase]` — `SchemaV6.Goal` — complete field list; no migration required
- `[VERIFIED: codebase]` — `VGQuoteBank.todaysQuote()` — day-of-year deterministic selection pattern
- `[VERIFIED: codebase]` — `ExplorePlaceholderView.swift` — Phase 16 placeholder struct to replace
- `[VERIFIED: codebase]` — `ContentView.swift` — NavigationStack wraps Explore tab; ExploreView must not create its own

### Secondary (MEDIUM confidence)
- `[ASSUMED]` — UIKit `motionEnded` is the standard iOS shake detection approach for SwiftUI apps (training knowledge; iOS 17 docs do not document a native SwiftUI shake modifier)

### Tertiary (LOW confidence)
- `[ASSUMED]` — TrendingGoal CloudKit record type does not yet exist; needs creation in CloudKit Console

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries are Apple-native and already used in the project
- Architecture: HIGH — all patterns are directly verified from existing codebase
- Pitfalls: HIGH — discovered via code reading (schema confusion, shake responder lifecycle, confetti reduce-motion guard)
- CloudKit schema (TrendingGoal): MEDIUM — record type is new; seeding strategy is ASSUMED

**Research date:** 2026-05-22
**Valid until:** 2026-06-22 (30 days — stable Apple framework; CloudKit record type may be created sooner)
