# Phase 16: Tab Restructuring + AppRoute Updates — Pattern Map

**Mapped:** 2026-05-16
**Files analyzed:** 4 files to modify (ContentView, VGTabBar, CommunityTabView, HomeView)
**Analogs found:** 4 / 4 (all files are their own primary target; analogs drawn from within the same codebase)

---

## File Classification

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|---------------|
| `Views/ContentView.swift` | view / tab coordinator | request-response (tab switching) | itself (primary target) | exact |
| `Views/Components/VGTabBar.swift` | component | event-driven (button tap → selection change) | itself (primary target) | exact |
| `Views/CommunityTabView.swift` | view | request-response (tab jump) | itself (primary target) | exact |
| `Views/HomeView.swift` | view | request-response (NavigationLink destinations) | itself (primary target) | exact |

---

## Pattern Assignments

### `Views/ContentView.swift` (view / tab coordinator, request-response)

**What changes:**
- `@State private var selectedTab: Int` → `@State private var selectedTab: Tab`
- All `.tag(N)` integer literals → `.tag(Tab.xxx)` enum cases
- Community and Explore NavigationStack blocks swap positions (new indices: Explore = 2, Community = 3)
- `goalsTab.navigationDestination` removes `.stats` and `.wins` cases
- Home tab `NavigationStack` gains `.stats` and `.wins` navigationDestination cases

**Current state — full file** (lines 1–93):

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppRouter.self) private var router
    @Query private var allUserChallenges: [UserChallenge]
    @State private var selectedTab: Int = 0          // <-- CHANGE to Tab = .home
    @State private var challengesNavPath: NavigationPath = NavigationPath()

    var body: some View {
        @Bindable var router = router
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
                // ADD: .navigationDestination(for: AppRoute.self) { route in
                //          case .stats: StatsView()
                //          case .wins: DailyWinsView()
                //      }
            }
            .tag(0)               // <-- CHANGE to .tag(Tab.home)

            goalsTab
                .tag(1)           // <-- CHANGE to .tag(Tab.goals)

            NavigationStack {     // <-- THIS BLOCK moves to index 3 (community)
                CommunityTabView(selectedTab: $selectedTab)
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .communityFeed(let c): CommunityFeedView(userChallenge: c)
                        case .communityGoals(let c): CommunityGoalsLandingView(userChallenge: c)
                        default: EmptyView()
                        }
                    }
            }
            .tag(2)               // <-- CHANGE to .tag(Tab.community) and move after Explore

            NavigationStack(path: $challengesNavPath) {   // <-- THIS BLOCK moves to index 2 (explore)
                ChallengeDiscoveryView(navigationPath: $challengesNavPath)
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .goalDetail(let goal): GoalDetailView(goal: goal)
                        case .challengeDetail(let c): ChallengeDetailView(userChallenge: c)
                        case .communityGoals(let c): CommunityGoalsLandingView(userChallenge: c)
                        default: EmptyView()
                        }
                    }
            }
            .tag(3)               // <-- CHANGE to .tag(Tab.explore) and move before Community

            NavigationStack {
                ProfileView()
            }
            .tag(4)               // <-- CHANGE to .tag(Tab.profile)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VGTabBar(selection: $selectedTab)
        }
        // ... sheets unchanged
    }

    private var goalsTab: some View {
        @Bindable var router = router
        return NavigationStack(path: $router.path) {
            GoalListView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .goalDetail(let goal): GoalDetailView(goal: goal)
                    case .stats: StatsView()          // <-- REMOVE
                    case .settings: SettingsView()
                    case .profile: ProfileView()
                    case .publicProfile: EmptyView()
                    case .wins: DailyWinsView()       // <-- REMOVE
                    case .challengeDetail(let c): ChallengeDetailView(userChallenge: c)
                    case .challengeCheckIn(let c): ChallengeCheckInView(userChallenge: c, viewModel: ChallengeViewModel())
                    case .communityFeed(let c): CommunityFeedView(userChallenge: c)
                    case .communityGoals(let c): CommunityGoalsLandingView(userChallenge: c)
                    }
                }
        }
    }
}
```

**NavigationStack + navigationDestination pattern** used consistently across all tabs (lines 13–43):
- Each tab wraps its root view in `NavigationStack`
- `navigationDestination(for: AppRoute.self)` with a switch on route cases
- `default: EmptyView()` catch-all used in non-goals tabs
- Goals tab uses `NavigationStack(path: $router.path)` (router-driven path) — home tab will use bare `NavigationStack` (no path binding needed since `.stats` and `.wins` navigate via AppRoute values pushed elsewhere)

**`@Bindable` pattern for router** (lines 11, 74):
```swift
@Bindable var router = router   // unwrap @Observable for Binding usage
```

**Sheet binding pattern** (lines 56–70) — unchanged, shown for context only:
```swift
.sheet(item: Binding(
    get: { router.pendingPublicProfileRecordID.map { ProfileDeepLinkItem(id: $0) } },
    set: { _ in router.pendingPublicProfileRecordID = nil }
)) { item in ... }
```

---

### `Views/Components/VGTabBar.swift` (component, event-driven)

**What changes:**
- `@Binding var selection: Int` → `@Binding var selection: Tab`
- `private let tabs` array reordered: Community and Explore swapped; "Me" renamed to "Profile"
- `ForEach` comparison `selection == index` → `selection == Tab(rawValue:...)` or direct enum case comparison
- `withAnimation { selection = index }` → `withAnimation { selection = tabCaseAtIndex }`

**Current state — full file** (lines 1–63):

```swift
import SwiftUI

struct VGTabBar: View {
    @Binding var selection: Int          // <-- CHANGE to Tab

    private let tabs: [(label: String, icon: String)] = [
        ("Home",      "house"),
        ("Goals",     "circle.circle"),
        ("Community", "person.2"),       // <-- SWAP: Community goes to index 3
        ("Explore",   "magnifyingglass"),// <-- SWAP: Explore goes to index 2
        ("Me",        "person"),         // <-- RENAME to "Profile"
    ]
    // Corrected order after changes:
    // ("Home",      "house"),
    // ("Goals",     "circle.circle"),
    // ("Explore",   "magnifyingglass"),
    // ("Community", "person.2"),
    // ("Profile",   "person"),

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                tabItem(index: index, label: tab.label, icon: tab.icon)
            }
        }
        // ... styling unchanged
    }

    private func tabItem(index: Int, label: String, icon: String) -> some View {
        let isActive = selection == index     // <-- CHANGE: compare Tab enum to tabs-array-derived Tab case
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selection = index }   // <-- CHANGE to Tab case
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            // ... visual rendering unchanged
        }
        .buttonStyle(.plain)
    }
}
```

**Key design note:** The `tabs` array is currently indexed by integer. After migration, `ForEach` should enumerate `Tab.allCases` (if `Tab: CaseIterable`) or keep the tuple array but map each index to its corresponding `Tab` case. The `isActive` check and button action must use `Tab` values, not `Int` offsets.

**Active indicator pattern** (lines 42–55) — unchanged:
```swift
let isActive = selection == index
// ...
Rectangle().frame(height: 2).foregroundStyle(isActive ? VGTheme.accentTerra : .clear)
Image(systemName: isActive ? icon + ".fill" : icon)
Text(label).font(.system(size: 10, weight: isActive ? .semibold : .regular))
```

---

### `Views/CommunityTabView.swift` (view, request-response)

**What changes:**
- `@Binding var selectedTab: Int` → `@Binding var selectedTab: Tab`
- Line 73: `selectedTab = 3` → `selectedTab = .explore`

**Current state — binding declaration and usage** (lines 10, 72–74):

```swift
struct CommunityTabView: View {
    @Binding var selectedTab: Int       // <-- CHANGE to Tab

    // ...

    Button("Explore Challenges") {
        selectedTab = 3                  // <-- CHANGE to selectedTab = .explore
    }
```

**Full context of the hard-coded integer** (lines 63–85):
```swift
private var emptyState: some View {
    VStack(spacing: 16) {
        Text("No challenges yet")
            .font(VGTheme.serif(20))
            .foregroundStyle(VGTheme.textPrimary)
        Text("Join a challenge to connect with others.")
            .font(.system(size: 14))
            .foregroundStyle(VGTheme.textMuted)
            .multilineTextAlignment(.center)
        Button("Explore Challenges") {
            selectedTab = 3              // <-- CHANGE to selectedTab = .explore
        }
        .font(.body.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(VGTheme.terra)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 60)
    .padding(.horizontal, 32)
}
```

**Existing cross-view binding pattern:** `selectedTab` is passed from ContentView as `$selectedTab`. This is the established pattern for cross-tab navigation from child views — retain it, just change the type.

---

### `Views/HomeView.swift` (view, request-response)

**What changes:**
- `quickStatsRow` made tappable via `NavigationLink` to `.stats` AppRoute
- Daily Wins entry point added near `checkInCTA` area
- Home tab's `NavigationStack` in ContentView wired with `.stats` and `.wins` destinations
- HomeView itself gets no new `@State` or `@Query` — new elements use existing data

**Current state — key sections:**

**`quickStatsRow` computed property** (lines 264–281) — this entire block becomes a `NavigationLink`:
```swift
private var quickStatsRow: some View {
    HStack(spacing: 8) {
        statCell(
            value: "\(goals.filter { !($0.isCompleted) }.count)",
            label: "Active Goals"
        )
        statCell(
            value: "\(completionEvents.count)",
            label: "Check-ins"
        )
        statCell(
            value: "\(goalVM.earnedBadgeCount(from: userChallenges))",
            label: "Badges"
        )
    }
    .padding(.horizontal, 24)
    .padding(.top, 16)
}
```

**`checkInCTA` function** (lines 227–244) — Daily Wins entry goes near or below this:
```swift
private func checkInCTA(_ goal: Goal) -> some View {
    NavigationLink(destination: GoalDetailView(goal: goal)) {
        Text("Log today's check-in →")
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [VGTheme.accentTerra, VGTheme.terra],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)
    }
}
```

**`statCell` helper** (lines 246–260) — used for the Quick Stats row chips; keep unchanged:
```swift
private func statCell(value: String, label: String) -> some View {
    VStack(spacing: 2) {
        Text(value)
            .font(VGTheme.serif(18))
            .foregroundStyle(VGTheme.sand)
        Text(label)
            .font(.system(size: 10))
            .kerning(0.5)
            .foregroundStyle(VGTheme.muted)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background(Color.white.opacity(0.06))
    .clipShape(RoundedRectangle(cornerRadius: 10))
}
```

**`body` layout order** (lines 52–67) — shows where new elements slot in:
```swift
ScrollView {
    VStack(spacing: 0) {
        headerSection
        quoteSection
        if let goal = primaryGoal {
            primaryGoalCard(goal)
        }
        if let goal = primaryGoal, !todayCheckedIn {
            checkInCTA(goal)            // <-- Daily Wins entry goes near here (below or adjacent)
                .padding(.top, 12)
        }
        quickStatsRow                   // <-- Wrap entire row in NavigationLink(value: AppRoute.stats)
        stayCloseSection
        secondaryGoalsSection
        Spacer(minLength: 32)
    }
}
```

**`NavigationLink` pattern used in HomeView** (lines 300–304, 314–320, 322–329) — use this same `.plain` buttonStyle pattern for new links:
```swift
NavigationLink(destination: AboutUsView()) {
    stayCloseCard(icon: "heart.fill", title: "About Us", subtitle: "Our story")
}
.buttonStyle(.plain)
```

**AppRoute-value NavigationLink pattern** (from `CommunityTabView` line 54) — preferred for programmatic navigation:
```swift
NavigationLink(value: AppRoute.communityGoals(challenge)) {
    CommunityChallengeCellView(challenge: challenge)
}
.buttonStyle(.plain)
```
Use `NavigationLink(value: AppRoute.stats)` for the Quick Stats row and `NavigationLink(value: AppRoute.wins)` for the Daily Wins entry. These require the Home tab's `NavigationStack` to have a `navigationDestination(for: AppRoute.self)` handler.

---

## Shared Patterns

### Tab Enum — New Type to Define

**Source:** Decision D-05, D-06, D-07 (no existing analog; new type)
**Apply to:** ContentView, VGTabBar, CommunityTabView

```swift
// Suggested definition (place in Navigation/Tab.swift or top of ContentView)
enum Tab: String, CaseIterable, Hashable {
    case home      = "home"
    case goals     = "goals"
    case explore   = "explore"
    case community = "community"
    case profile   = "profile"
}
// Tab order in allCases matches new display order: home(0) · goals(1) · explore(2) · community(3) · profile(4)
```

`String` raw values + `CaseIterable` + `Hashable` satisfy:
- `TabView(selection:)` requires `Hashable` — satisfied by `String` raw value enum automatically
- `ForEach(Tab.allCases)` in VGTabBar — requires `CaseIterable`
- `Binding<Tab>` across ContentView → VGTabBar and CommunityTabView — requires same type throughout

### NavigationStack + navigationDestination Pattern

**Source:** `ContentView.swift` lines 13–43, `goalsTab` lines 73–92
**Apply to:** Home tab NavigationStack in ContentView; do NOT change Goals tab structure

```swift
NavigationStack {
    HomeView()
        .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .stats: StatsView()
            case .wins: DailyWinsView()
            default: EmptyView()
            }
        }
}
.tag(Tab.home)
```

### AppRoute Enum

**Source:** `Navigation/AppRoute.swift` lines 8–19
**Apply to:** ContentView (rewire destinations), HomeView (NavigationLink values)

No changes to `AppRoute` itself. `.stats` and `.wins` already exist. They are simply moved from the Goals tab handler to the Home tab handler.

```swift
enum AppRoute: Hashable {
    // ...
    case stats      // used in Phase 3; now Home-only
    case wins       // used in Phase 11; now Home-only
    // ...
}
```

### AppRouter State

**Source:** `Navigation/AppRouter.swift` lines 1–27
**Apply to:** ContentView only; no changes to AppRouter itself

`AppRouter.path` drives the Goals tab `NavigationStack`. The Home tab uses a bare `NavigationStack` with no path binding — consistent with how Community and Profile tabs are structured currently. Do not add a second `router.path` or a new path property to AppRouter for this phase.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `Navigation/Tab.swift` (new) | model / enum | N/A | No typed tab enum exists yet; planner defines per D-06 |

---

## Metadata

**Analog search scope:** `VitaminG/VitaminG/VitaminG/Views/`, `VitaminG/VitaminG/VitaminG/Navigation/`
**Files read:** 6 (ContentView, VGTabBar, CommunityTabView, HomeView, AppRoute, AppRouter)
**Pattern extraction date:** 2026-05-16
