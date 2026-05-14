# Visual Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current system-styled tab bar and list views with a warm, card-based UI matching the VGTheme design spec — new tab structure, GoalListView card redesign, ProfileView hero+tabs, ChallengeDiscoveryView polish, CommunityTabView, and widget redesigns.

**Architecture:** ScrollView + LazyVStack card layouts replace List throughout. VGTheme semantic colors already defined (sandLight, clay, terra, etc.) and CormorantGaramond fonts already bundled. ViewModels stay unchanged except ProfileViewModel additions.

**Tech Stack:** SwiftUI, SwiftData, WidgetKit, iOS 17+, VGTheme, CormorantGaramond

---

## File Map

| File | Action |
|------|--------|
| `VitaminG/Views/ContentView.swift` | Remove Wins tab, add Community tab, add selectedTab state |
| `VitaminG/Views/CommunityTabView.swift` | Create new |
| `VitaminG/Views/GoalListView.swift` | Full redesign |
| `VitaminG/Views/ProfileView.swift` | Full redesign |
| `VitaminG/ViewModels/ProfileViewModel.swift` | Add quotes array, reactionCount, bestStreak wiring |
| `VitaminG/Services/StreakEngine.swift` | Add `bestStreak(events:)` static method |
| `VitaminG/Views/ChallengeDiscoveryView.swift` | Visual polish |
| `VitaminGWidget/GoalSummaryWidget.swift` | Redesign view + add StreakHomeWidget |
| `VitaminGWidget/QuoteWidget.swift` | Create new |
| `VitaminGWidget/VitaminGWidgetBundle.swift` | Register new widgets |
| `VitaminGTests/StreakEngineTests.swift` | Add bestStreak tests |

Base path for all files: `VitaminG/VitaminG/` (relative to repo root `Desktop/AI/WaterRingToss` — for VitaminG use `Desktop/AI/Vitamin G/VitaminG/VitaminG/`)

---

### Task 1: Add `bestStreak` to StreakEngine

**Files:**
- Modify: `VitaminG/Services/StreakEngine.swift`
- Test: `VitaminGTests/StreakEngineTests.swift`

- [ ] **Step 1: Write the failing test**

Open `VitaminGTests/StreakEngineTests.swift` and add:

```swift
func test_bestStreak_returnsLongestConsecutiveRun() {
    // Arrange: events on Jan 1-3, then gap, then Jan 7-10
    let cal = Calendar.current
    var events: [CompletionEvent] = []
    for day in [1, 2, 3, 7, 8, 9, 10] {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 1; comps.day = day
        let e = CompletionEvent()
        e.completedAt = cal.date(from: comps)
        events.append(e)
    }
    // Act
    let best = StreakEngine.bestStreak(events: events)
    // Assert
    XCTAssertEqual(best, 4)
}

func test_bestStreak_emptyEvents_returnsZero() {
    XCTAssertEqual(StreakEngine.bestStreak(events: []), 0)
}
```

- [ ] **Step 2: Run tests to verify they fail**

In Xcode: Cmd+U, filter to `StreakEngineTests`. Expected: compile error — `bestStreak` not found.

- [ ] **Step 3: Implement `bestStreak` in StreakEngine**

At the end of `StreakEngine.swift`, inside the `struct StreakEngine` body, add:

```swift
// MARK: - bestStreak

/// Returns the longest consecutive-day streak in the entire event history.
static func bestStreak(events: [CompletionEvent]) -> Int {
    let cal = Calendar.current
    let days = Set(
        events.compactMap { $0.completedAt }
              .map { cal.startOfDay(for: $0) }
    )
    guard !days.isEmpty else { return 0 }
    var best = 0
    for day in days {
        // Only start counting from days that don't have a predecessor
        let prev = cal.date(byAdding: .day, value: -1, to: day)!
        guard !days.contains(prev) else { continue }
        var run = 1
        var next = cal.date(byAdding: .day, value: 1, to: day)!
        while days.contains(next) {
            run += 1
            next = cal.date(byAdding: .day, value: 1, to: next)!
        }
        best = max(best, run)
    }
    return best
}
```

- [ ] **Step 4: Run tests to verify they pass**

Cmd+U, confirm both `test_bestStreak_*` tests pass.

- [ ] **Step 5: Commit**

```bash
git add "VitaminG/VitaminG/VitaminG/Services/StreakEngine.swift" \
        "VitaminG/VitaminG/VitaminGTests/StreakEngineTests.swift"
git commit -m "feat: add StreakEngine.bestStreak for all-time best run"
```

---

### Task 2: Update ContentView — remove Wins tab, add Community tab

**Files:**
- Modify: `VitaminG/Views/ContentView.swift`
- Create: `VitaminG/Views/CommunityTabView.swift`

- [ ] **Step 1: Create CommunityTabView stub**

Create `VitaminG/VitaminG/VitaminG/Views/CommunityTabView.swift`:

```swift
import SwiftUI
import SwiftData

struct CommunityTabView: View {
    @Binding var selectedTab: Int
    @Query private var userChallenges: [UserChallenge]
    @Environment(\.modelContext) private var modelContext

    var activeChallenges: [UserChallenge] {
        userChallenges.filter { !($0.isCompleted ?? false) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("Community")
                    .font(VGTheme.serif(28))
                    .foregroundStyle(VGTheme.clay)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                if activeChallenges.isEmpty {
                    emptyState
                } else {
                    challengeList
                }
            }
        }
        .background(VGTheme.sandLight)
    }

    private var challengeList: some View {
        LazyVStack(spacing: 10) {
            ForEach(activeChallenges) { challenge in
                NavigationLink(value: AppRoute.communityFeed(challenge)) {
                    CommunityChallengeCellView(challenge: challenge)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No challenges yet")
                .font(VGTheme.serif(20))
                .foregroundStyle(VGTheme.clay)
            Text("Join a challenge to connect with others.")
                .font(.system(size: 14))
                .foregroundStyle(VGTheme.muted)
                .multilineTextAlignment(.center)
            Button("Explore Challenges") {
                selectedTab = 3
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
}

// MARK: - CommunityChallengeCellView

private struct CommunityChallengeCellView: View {
    let challenge: UserChallenge

    private var accentColor: Color {
        Color(hex: challenge.template?.accentColorHex ?? "#C4673A")
    }
    private var challengeName: String { challenge.template?.name ?? "Challenge" }
    private var categoryLabel: String { challenge.template?.category ?? "" }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: 4, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(challengeName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(VGTheme.clay)
                Text(categoryLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(VGTheme.muted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(VGTheme.muted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(VGTheme.warmWhite)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: VGTheme.clay.opacity(0.07), radius: 8, y: 1)
    }
}
```

- [ ] **Step 2: Update ContentView**

Replace the entire `ContentView.swift` body with:

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppRouter.self) private var router
    @Query private var allUserChallenges: [UserChallenge]
    @State private var selectedTab: Int = 0

    var body: some View {
        @Bindable var router = router
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            goalsTab
                .tabItem { Label("Goals", systemImage: "target") }
                .tag(1)

            NavigationStack {
                CommunityTabView(selectedTab: $selectedTab)
            }
            .tabItem { Label("Community", systemImage: "person.2.fill") }
            .tag(2)

            NavigationStack {
                ChallengeDiscoveryView()
            }
            .tabItem { Label("Challenges", systemImage: "flame.fill") }
            .tag(3)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
            .tag(4)
        }
        .tint(VGTheme.terra)
        .sheet(item: Binding(
            get: { router.pendingPublicProfileRecordID.map { ProfileDeepLinkItem(id: $0) } },
            set: { _ in router.pendingPublicProfileRecordID = nil }
        )) { item in
            PublicProfileView(recordID: item.id)
        }
        .sheet(item: Binding(
            get: { router.pendingChallengeCheckInID.map { ChallengeCheckInDeepLinkItem(id: $0) } },
            set: { _ in router.pendingChallengeCheckInID = nil }
        )) { item in
            if let uuid = UUID(uuidString: item.id),
               let challenge = allUserChallenges.first(where: { $0.id == uuid }) {
                NotifCheckInSheetContent(challenge: challenge)
            }
        }
    }

    private var goalsTab: some View {
        @Bindable var router = router
        return NavigationStack(path: $router.path) {
            GoalListView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .goalDetail(let goal): GoalDetailView(goal: goal)
                    case .stats: StatsView()
                    case .settings: SettingsView()
                    case .profile: ProfileView()
                    case .publicProfile: EmptyView()
                    case .wins: DailyWinsView()
                    case .challengeDetail(let c): ChallengeDetailView(userChallenge: c)
                    case .challengeCheckIn(let c): ChallengeCheckInView(userChallenge: c, viewModel: ChallengeViewModel())
                    case .communityFeed(let c): CommunityFeedView(userChallenge: c)
                    }
                }
        }
    }
}
```

- [ ] **Step 3: Build and verify**

Cmd+B. Confirm no compile errors. Check that 5 tabs appear and Wins tab is gone.

- [ ] **Step 4: Commit**

```bash
git add "VitaminG/VitaminG/VitaminG/Views/ContentView.swift" \
        "VitaminG/VitaminG/VitaminG/Views/CommunityTabView.swift"
git commit -m "feat: replace Wins tab with Community tab, add CommunityTabView"
```

---

### Task 3: GoalListView — header, challenge hero card, card rows

**Files:**
- Modify: `VitaminG/Views/GoalListView.swift`

- [ ] **Step 1: Replace GoalListView body**

Replace the entire `GoalListView.swift` with:

```swift
import SwiftUI
import SwiftData

struct GoalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]
    @Query private var events: [CompletionEvent]
    @Query private var userChallenges: [UserChallenge]

    @State private var viewModel = GoalViewModel()
    @State private var showingAddGoal = false
    @State private var goalToDelete: Goal?
    @State private var showingDeleteConfirmation = false
    @State private var sortOption: SortOption = .byTier
    @State private var pendingMilestone: (goalID: UUID, threshold: Int)? = nil

    private var hasAnyGoals: Bool { !goals.isEmpty }
    private var sortedGoals: [Goal] { GoalSorter.sort(goals, by: sortOption) }
    private func goals(for tier: GoalTier) -> [Goal] { sortedGoals.filter { $0.tier == tier } }
    private var primaryChallenge: UserChallenge? {
        userChallenges.first(where: { !($0.isCompleted ?? false) })
    }

    var body: some View {
        Group {
            if hasAnyGoals {
                goalScrollView
            } else {
                EmptyStateView { showingAddGoal = true }
            }
        }
        .background(VGTheme.sandLight)
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Label(option.displayName, systemImage: option.systemImage).tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Sort goals")
            }
        }
        .sheet(isPresented: $showingAddGoal) { AddGoalView(viewModel: viewModel) }
        .confirmationDialog("Delete this goal?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let goal = goalToDelete { viewModel.delete(goal: goal, context: modelContext) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This action cannot be undone.") }
        .onChange(of: viewModel.pendingMilestone?.goalID) { _, _ in
            if let milestone = viewModel.pendingMilestone {
                pendingMilestone = milestone
                viewModel.pendingMilestone = nil
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(3))
                    pendingMilestone = nil
                }
            }
        }
    }

    private var goalScrollView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                // Inline header
                HStack {
                    Text("My Goals")
                        .font(VGTheme.serif(28))
                        .foregroundStyle(VGTheme.clay)
                    Spacer()
                    Button {
                        showingAddGoal = true
                    } label: {
                        Text("+ New Goal")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(VGTheme.terra)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 4)

                // Primary challenge hero card
                if let challenge = primaryChallenge {
                    ChallengeHeroCard(challenge: challenge, events: events)
                        .padding(.horizontal, 16)
                }

                // Goal sections
                if sortOption == .byCompletionStatus {
                    let active    = sortedGoals.filter { !$0.completed }
                    let completed = sortedGoals.filter { $0.completed }
                    if !active.isEmpty {
                        sectionHeader("Active")
                        ForEach(active) { goal in goalCard(for: goal) }
                    }
                    if !completed.isEmpty {
                        sectionHeader("Completed")
                        ForEach(completed) { goal in goalCard(for: goal) }
                    }
                } else {
                    ForEach(GoalTier.ordered, id: \.self) { tier in
                        let tieredGoals = goals(for: tier)
                        if !tieredGoals.isEmpty {
                            sectionHeader(tier.displayName.uppercased())
                            ForEach(tieredGoals) { goal in goalCard(for: goal) }
                        } else {
                            sectionHeader(tier.displayName.uppercased())
                            EmptyTierView(tier: tier) {
                                viewModel.draftTier = tier
                                showingAddGoal = true
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }

                Spacer(minLength: 32)
            }
        }
        .animation(.easeOut(duration: 0.25), value: sortOption)
        .animation(.easeOut(duration: 0.15), value: goals.count)
    }

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(VGTheme.muted)
            .kerning(1.0)
            .padding(.horizontal, 24)
            .padding(.top, 8)
    }

    @ViewBuilder
    private func goalCard(for goal: Goal) -> some View {
        let milestoneThreshold: Int? = (pendingMilestone?.goalID == goal.id)
            ? pendingMilestone?.threshold : nil
        NavigationLink(value: AppRoute.goalDetail(goal)) {
            GoalCardView(
                goal: goal,
                events: events,
                milestoneThreshold: milestoneThreshold,
                onToggle: { viewModel.toggleCompletion(goal: goal, context: modelContext) }
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .contextMenu {
            Button(role: .destructive) {
                goalToDelete = goal
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - ChallengeHeroCard

private struct ChallengeHeroCard: View {
    let challenge: UserChallenge
    let events: [CompletionEvent]

    private var challengeName: String { challenge.template?.name ?? "Challenge" }
    private var category: String { challenge.template?.category ?? "" }
    private var dayNumber: Int { challenge.currentDayNumber }
    private var daysRemaining: Int { max(0, (challenge.template?.durationDays ?? 90) - dayNumber) }
    private var progress: Double {
        let total = Double(challenge.template?.durationDays ?? 90)
        return min(1.0, Double(dayNumber) / max(1, total))
    }
    private let weekDays = ["M","T","W","T","F","S","S"]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(VGTheme.terra.opacity(0.15))
                .frame(width: 120, height: 120)
                .offset(x: 30, y: -30)

            VStack(alignment: .leading, spacing: 0) {
                Text(category.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(VGTheme.muted)
                    .kerning(1.2)
                    .padding(.bottom, 12)

                HStack(alignment: .center, spacing: 18) {
                    ProgressRingView(
                        progress: progress,
                        tier: .immediate,
                        isCompleted: false
                    )
                    .frame(width: 80, height: 80)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(challengeName)
                            .font(VGTheme.serif(18))
                            .foregroundStyle(VGTheme.sand)
                            .lineLimit(2)
                        Text("\(daysRemaining) days remaining")
                            .font(.system(size: 12))
                            .foregroundStyle(VGTheme.muted)
                        HStack(spacing: 5) {
                            Circle().fill(VGTheme.sage).frame(width: 8, height: 8)
                            Text("On track")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(VGTheme.sage)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.bottom, 16)

                // 7-day bar chart
                HStack(spacing: 6) {
                    ForEach(Array(weekDays.enumerated()), id: \.offset) { i, day in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(i < 5 ? VGTheme.terraSoft.opacity(0.7) : Color.white.opacity(0.1))
                                .frame(height: 28)
                            Text(day)
                                .font(.system(size: 10))
                                .foregroundStyle(VGTheme.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [VGTheme.clay, VGTheme.clayMid],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: VGTheme.clay.opacity(0.3), radius: 12, y: 4)
    }
}

// MARK: - GoalCardView

private struct GoalCardView: View {
    let goal: Goal
    let events: [CompletionEvent]
    let milestoneThreshold: Int?
    let onToggle: () -> Void

    @State private var showMilestoneBadge = false
    @State private var badgeOpacity: Double = 0
    @State private var badgeScale: CGFloat = 0.5
    @State private var bounceScale: CGFloat = 1.0
    @State private var bounceTask: Task<Void, Never>?
    @State private var badgeTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let progressVM = ProgressViewModel()

    private var tagLine: String {
        "\(goal.tier.displayName) · Streak: \(streakCount)"
    }
    private var streakCount: Int { 0 } // StreakEngine computed externally if needed

    var body: some View {
        HStack(spacing: 14) {
            ProgressRingView(
                progress: progressVM.ringProgress(for: goal, events: events),
                tier: goal.tier,
                isCompleted: goal.completed
            )
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(goal.title ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(goal.completed ? VGTheme.muted : VGTheme.clay)
                    .strikethrough(goal.completed, color: VGTheme.muted.opacity(0.6))
                    .lineLimit(2)
                if let desc = goal.goalDescription, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundStyle(VGTheme.muted)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(VGTheme.muted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(VGTheme.warmWhite)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: VGTheme.clay.opacity(0.07), radius: 8, y: 1)
        .scaleEffect(bounceScale)
        .overlay(alignment: .center) {
            if showMilestoneBadge, let threshold = milestoneThreshold {
                Image(systemName: threshold == 50 ? "trophy.fill" : "star.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(goal.tier.color)
                    .scaleEffect(badgeScale)
                    .opacity(badgeOpacity)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .onChange(of: goal.completed) { _, _ in
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { bounceScale = 1.02 }
            bounceTask?.cancel()
            bounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { bounceScale = 1.0 }
            }
        }
        .onChange(of: milestoneThreshold) { _, newValue in
            guard newValue != nil else { return }
            fireMilestoneBadge(threshold: newValue ?? 0)
        }
        .onDisappear { bounceTask?.cancel(); badgeTask?.cancel() }
    }

    private func fireMilestoneBadge(threshold: Int) {
        showMilestoneBadge = true
        UIAccessibility.post(notification: .announcement, argument: "Milestone reached: \(threshold) completions!")
        badgeTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { badgeOpacity = 1.0; badgeScale = 1.2 }
        badgeTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { badgeScale = 1.0 }
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.3)) { badgeOpacity = 0 }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            showMilestoneBadge = false; badgeScale = 0.5
        }
    }
}
```

- [ ] **Step 2: Build and verify**

Cmd+B. Confirm Goals tab renders with warm card layout and no List chrome.

- [ ] **Step 3: Commit**

```bash
git add "VitaminG/VitaminG/VitaminG/Views/GoalListView.swift"
git commit -m "feat: redesign GoalListView with card layout and challenge hero"
```

---

### Task 4: ProfileViewModel — quotes, reactionCount, ProfileTab enum

**Files:**
- Modify: `VitaminG/ViewModels/ProfileViewModel.swift`

- [ ] **Step 1: Add to ProfileViewModel**

Open `ProfileViewModel.swift` and add these members to the `@Observable class ProfileViewModel`:

```swift
// MARK: - Profile redesign additions

enum ProfileTab { case goals, badges, activity }

let quotes: [String] = [
    "The secret of getting ahead is getting started.",
    "Small daily improvements lead to stunning results.",
    "You don't have to be great to start, but you have to start to be great.",
    "Every day is a chance to be better than yesterday.",
    "Progress, not perfection.",
    "The only bad workout is the one that didn't happen.",
    "Discipline is choosing between what you want now and what you want most.",
    "It always seems impossible until it's done.",
    "Don't count the days, make the days count.",
    "You are one decision away from a totally different life.",
]

var todayQuote: String {
    let day = Calendar.current.component(.day, from: Date())
    return quotes[day % quotes.count]
}

var reactionCount: Int = 0

func loadReactionCount() async {
    // CloudKit fetch — safe default 0 on any error
    // Replace with actual CKQuery when CloudKit reactions schema is defined
    reactionCount = 0
}
```

- [ ] **Step 2: Build and verify**

Cmd+B. No errors expected.

- [ ] **Step 3: Commit**

```bash
git add "VitaminG/VitaminG/VitaminG/ViewModels/ProfileViewModel.swift"
git commit -m "feat: add ProfileViewModel quote rotation and reactionCount"
```

---

### Task 5: ProfileView redesign

**Files:**
- Modify: `VitaminG/Views/ProfileView.swift`

- [ ] **Step 1: Replace ProfileView**

Replace the entire `ProfileView.swift` with:

```swift
import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var activeTab: ProfileViewModel.ProfileTab = .goals
    @State private var selectedMood: Int? = nil

    @Query private var goals: [Goal]
    @Query private var completionEvents: [CompletionEvent]
    @Query private var userChallenges: [UserChallenge]

    private var currentStreak: Int {
        StreakEngine.currentStreak(events: completionEvents, tier: nil)
    }
    private var bestStreak: Int {
        StreakEngine.bestStreak(events: completionEvents)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroBanner
                profileTabBar
                tabContent
                    .padding(.bottom, 32)
                shareAndSettings
            }
        }
        .background(VGTheme.sandLight)
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadOrCreateProfile(context: modelContext)
            Task { await viewModel.loadReactionCount() }
        }
        .sheet(isPresented: $viewModel.showingEditSheet) {
            ProfileEditSheet(viewModel: viewModel)
        }
        .alert("Couldn't share your profile.", isPresented: $viewModel.showingCloudKitError) {
            Button("Got It", role: .cancel) {}
        } message: {
            Text("Check your internet connection and try again.")
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [VGTheme.clay, Color(hex: "#5A3A22")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 0) {
                // Quote strip
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY'S DOSE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(VGTheme.muted)
                        .kerning(1.0)
                    Text(""\(viewModel.todayQuote)"")
                        .font(VGTheme.serifItalic(14))
                        .foregroundStyle(VGTheme.sand.opacity(0.85))
                        .lineLimit(3)
                }
                .padding(12)
                .background(Color.white.opacity(0.07))
                .overlay(
                    Rectangle()
                        .fill(VGTheme.terra)
                        .frame(width: 3),
                    alignment: .leading
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 16)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Avatar row
                HStack(alignment: .bottom, spacing: 14) {
                    ZStack(alignment: .bottomTrailing) {
                        AvatarView(
                            displayName: viewModel.profile?.displayName,
                            avatarColorHex: viewModel.profile?.avatarColorHex,
                            photoData: viewModel.profile?.photoData,
                            size: 72
                        )
                        .overlay(Circle().stroke(VGTheme.clay, lineWidth: 3))

                        Circle()
                            .fill(VGTheme.terra)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white)
                            )
                            .overlay(Circle().stroke(VGTheme.clay, lineWidth: 2))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if let name = viewModel.profile?.displayName, !name.isEmpty {
                            Text(name)
                                .font(VGTheme.serif(22))
                                .foregroundStyle(VGTheme.sand)
                        }
                        Text("Vitamin G Member")
                            .font(.system(size: 12))
                            .foregroundStyle(VGTheme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        viewModel.draftDisplayName = viewModel.profile?.displayName ?? ""
                        viewModel.showingEditSheet = true
                    } label: {
                        Text("Edit")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(VGTheme.sand)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.bottom, 4)
                }
                .padding(.horizontal, 20)

                // Stats row
                HStack(spacing: 0) {
                    ForEach(Array([
                        (String(currentStreak), "Streak"),
                        (String(goals.count),   "Goals"),
                        (String(completionEvents.count), "Check-ins"),
                        (String(viewModel.reactionCount), "Reactions"),
                    ].enumerated()), id: \.offset) { i, stat in
                        VStack(spacing: 2) {
                            Text(stat.0)
                                .font(VGTheme.serif(20))
                                .foregroundStyle(VGTheme.sand)
                            Text(stat.1.uppercased())
                                .font(.system(size: 9))
                                .foregroundStyle(VGTheme.muted)
                                .kerning(0.5)
                        }
                        .frame(maxWidth: .infinity)
                        if i < 3 {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .frame(height: 32)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Mood check-in
                VStack(alignment: .leading, spacing: 8) {
                    Text("HOW ARE YOU FEELING TODAY?")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(VGTheme.muted)
                        .kerning(0.8)

                    HStack(spacing: 8) {
                        ForEach(Array([("🌟","Amazing"),("😊","Good"),("😐","Okay"),("😔","Low"),("💪","Push")].enumerated()), id: \.offset) { i, mood in
                            Button {
                                selectedMood = i
                            } label: {
                                VStack(spacing: 3) {
                                    Text(mood.0).font(.system(size: 18))
                                    Text(mood.1)
                                        .font(.system(size: 9))
                                        .foregroundStyle(selectedMood == i ? VGTheme.terraSoft : VGTheme.muted)
                                        .kerning(0.4)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedMood == i ? VGTheme.terra.opacity(0.25) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedMood == i ? VGTheme.terra.opacity(0.4) : Color.clear, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Curved bottom scallop
                Color(VGTheme.sandLight)
                    .frame(height: 24)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 20, bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0, topTrailingRadius: 20
                        )
                    )
                    .padding(.top, 20)
            }
        }
    }

    // MARK: - Tab Bar

    private var profileTabBar: some View {
        HStack(spacing: 0) {
            ForEach([("Goals", ProfileViewModel.ProfileTab.goals),
                     ("Badges", .badges),
                     ("Activity", .activity)], id: \.0) { label, tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { activeTab = tab }
                } label: {
                    VStack(spacing: 0) {
                        Text(label)
                            .font(.system(size: 13, weight: activeTab == tab ? .semibold : .regular))
                            .foregroundStyle(activeTab == tab ? VGTheme.terra : VGTheme.muted)
                            .padding(.vertical, 10)
                        Rectangle()
                            .fill(activeTab == tab ? VGTheme.terra : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.plain)
            }
        }
        .background(VGTheme.sandLight)
        .overlay(Divider().foregroundStyle(VGTheme.sandMid), alignment: .bottom)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .goals:    goalsTab
        case .badges:   badgesTab
        case .activity: activityTab
        }
    }

    private var goalsTab: some View {
        LazyVStack(spacing: 10) {
            ForEach(GoalSorter.sort(goals, by: .byTier)) { goal in
                NavigationLink(value: AppRoute.goalDetail(goal)) {
                    HStack(spacing: 14) {
                        ProgressRingView(progress: 0, tier: goal.tier, isCompleted: goal.completed)
                            .frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(goal.title ?? "")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(goal.completed ? VGTheme.muted : VGTheme.clay)
                                .strikethrough(goal.completed, color: VGTheme.muted.opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12)).foregroundStyle(VGTheme.muted)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(VGTheme.warmWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: VGTheme.clay.opacity(0.07), radius: 8, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var badgesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            let earnedBadges = allEarnedBadges()
            let allBadges    = allKnownBadges()

            if allBadges.isEmpty {
                Text("Complete challenges to earn badges.")
                    .font(.system(size: 14))
                    .foregroundStyle(VGTheme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(allBadges, id: \.label) { badge in
                        let earned = earnedBadges.contains(badge.sfSymbol)
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 8) {
                                Text(badge.emoji).font(.system(size: 28))
                                Text(badge.label)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(earned ? VGTheme.clay : VGTheme.muted)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(earned ? VGTheme.warmWhite : VGTheme.sandMid)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: earned ? VGTheme.clay.opacity(0.1) : .clear, radius: 8, y: 2)
                            .opacity(earned ? 1 : 0.5)

                            if earned {
                                Circle().fill(VGTheme.sage).frame(width: 8, height: 8)
                                    .padding(8)
                            }
                        }
                    }
                }

                // Next badge progress
                if let next = nextUnearned(earned: earnedBadges, all: allBadges) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NEXT BADGE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(VGTheme.muted).kerning(0.8)
                        HStack(spacing: 12) {
                            Text(next.emoji).font(.system(size: 28)).opacity(0.4)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(next.label)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(VGTheme.clay)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 99).fill(VGTheme.sandMid).frame(height: 4)
                                        RoundedRectangle(cornerRadius: 99).fill(VGTheme.terra)
                                            .frame(width: geo.size.width * 0.5, height: 4)
                                    }
                                }.frame(height: 4)
                            }
                        }
                        .padding(14)
                        .background(VGTheme.warmWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: VGTheme.clay.opacity(0.07), radius: 8, y: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var activityTab: some View {
        VStack(spacing: 20) {
            HeatmapCard(events: completionEvents)
            summaryCard
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            let completionRate = goals.isEmpty ? 0 : Int((Double(completionEvents.count) / Double(max(1, goals.count * 30))) * 100)
            ForEach(Array([
                ("\(min(100, completionRate))%", "Completion rate"),
                (String(currentStreak), "Current streak"),
                (String(bestStreak), "Best streak"),
            ].enumerated()), id: \.offset) { i, stat in
                VStack(spacing: 4) {
                    Text(stat.0).font(VGTheme.serif(22)).foregroundStyle(VGTheme.terra)
                    Text(stat.1).font(.system(size: 10)).foregroundStyle(VGTheme.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                if i < 2 { Divider().frame(height: 32) }
            }
        }
        .padding(16)
        .background(VGTheme.warmWhite)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: VGTheme.clay.opacity(0.07), radius: 8, y: 1)
    }

    // MARK: - Share + Settings

    private var shareAndSettings: some View {
        VStack(spacing: 12) {
            if let url = viewModel.shareURL {
                ShareLink(item: url, subject: Text("Vitamin G Profile"),
                          message: Text("Check out my goals on Vitamin G!")) {
                    Label("Share Profile", systemImage: "square.and.arrow.up")
                        .font(.body.weight(.semibold)).fontDesign(.rounded)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(VGTheme.terra)
            }
            NavigationLink(destination: SettingsView()) {
                HStack(spacing: 12) {
                    Image(systemName: "gear").foregroundStyle(VGTheme.terra).frame(width: 28, height: 28)
                    Text("Settings").font(.body).fontDesign(.rounded).foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("Open Settings")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Badge helpers

    struct BadgeDefinition {
        let sfSymbol: String; let emoji: String; let label: String
    }
    private let knownBadges: [BadgeDefinition] = [
        BadgeDefinition(sfSymbol: "flame.fill",  emoji: "🔥", label: "7-Day Streak"),
        BadgeDefinition(sfSymbol: "trophy.fill", emoji: "🏆", label: "30-Day Champ"),
        BadgeDefinition(sfSymbol: "medal.fill",  emoji: "🥇", label: "60-Day Grind"),
        BadgeDefinition(sfSymbol: "star.fill",   emoji: "⭐", label: "90-Day Legend"),
    ]

    private func allKnownBadges() -> [BadgeDefinition] { knownBadges }

    private func allEarnedBadges() -> Set<String> {
        var earned = Set<String>()
        for c in userChallenges {
            guard let data = c.earnedBadgeSymbolsJSON?.data(using: .utf8),
                  let symbols = try? JSONDecoder().decode([String].self, from: data) else { continue }
            symbols.forEach { earned.insert($0) }
        }
        return earned
    }

    private func nextUnearned(earned: Set<String>, all: [BadgeDefinition]) -> BadgeDefinition? {
        all.first { !earned.contains($0.sfSymbol) }
    }
}

// MARK: - HeatmapCard

private struct HeatmapCard: View {
    let events: [CompletionEvent]
    private let days = ["M","T","W","T","F","S","S"]
    private let weeks = 10

    private var activeDays: Set<Date> {
        let cal = Calendar.current
        return Set(events.compactMap { $0.completedAt }.map { cal.startOfDay(for: $0) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Check-in activity")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(VGTheme.clay)
                Spacer()
                Text("Last \(weeks) weeks")
                    .font(.system(size: 12)).foregroundStyle(VGTheme.muted)
            }

            HStack(spacing: 3) {
                ForEach(days, id: \.self) { d in
                    Text(d).font(.system(size: 9)).foregroundStyle(VGTheme.muted)
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: 3) {
                ForEach(0..<weeks, id: \.self) { week in
                    HStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { dow in
                            let date = dateFor(week: week, dow: dow)
                            let count = activeDays.contains(date) ? 2 : 0
                            RoundedRectangle(cornerRadius: 4)
                                .fill(cellColor(count: count))
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(VGTheme.warmWhite)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: VGTheme.clay.opacity(0.07), radius: 8, y: 1)
    }

    private func dateFor(week: Int, dow: Int) -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let mondayOffset = -(((weekday + 5) % 7))
        let startOfThisWeek = cal.date(byAdding: .day, value: mondayOffset, to: today)!
        let weekStart = cal.date(byAdding: .day, value: -(weeks - 1 - week) * 7, to: startOfThisWeek)!
        return cal.date(byAdding: .day, value: dow, to: weekStart)!
    }

    private func cellColor(count: Int) -> Color {
        count == 0 ? VGTheme.sandMid : count == 1 ? VGTheme.terra.opacity(0.35) : VGTheme.terra
    }
}
```

- [ ] **Step 2: Build and verify**

Cmd+B. Open Profile tab, confirm hero banner renders, tabs switch correctly.

- [ ] **Step 3: Commit**

```bash
git add "VitaminG/VitaminG/VitaminG/Views/ProfileView.swift" \
        "VitaminG/VitaminG/VitaminG/ViewModels/ProfileViewModel.swift"
git commit -m "feat: redesign ProfileView with hero banner, stats row, and tabs"
```

---

### Task 6: ChallengeDiscoveryView visual polish

**Files:**
- Modify: `VitaminG/Views/ChallengeDiscoveryView.swift`

- [ ] **Step 1: Update header and scroll background**

In `ChallengeDiscoveryView.body`, replace:
```swift
.navigationTitle("Challenges")
```
with an inline header at the top of the `ScrollView` content:
```swift
// At top of VStack inside ScrollView:
HStack {
    Text("Challenges")
        .font(VGTheme.serif(28))
        .foregroundStyle(VGTheme.clay)
    Spacer()
}
.padding(.horizontal, 16)
.padding(.top, 20)
.padding(.bottom, 4)
```
Remove `.navigationTitle("Challenges")` modifier.

- [ ] **Step 2: Update section labels**

Find all section header `Text` views in `featuredSection` and `categorySection`. Replace `.font(.title2.weight(.semibold).fontDesign(.rounded))` with:
```swift
.font(.system(size: 10, weight: .bold))
.foregroundStyle(VGTheme.muted)
.kerning(1.2)
```

- [ ] **Step 3: Update "Build Your Own" button**

Find `buildYourOwnButton`. Replace the button label style with:
```swift
.font(.body.weight(.semibold)).fontDesign(.rounded)
.frame(maxWidth: .infinity)
.padding(.vertical, 14)
.background(VGTheme.terra)
.foregroundStyle(.white)
.clipShape(RoundedRectangle(cornerRadius: 14))
```

- [ ] **Step 4: Build and verify**

Cmd+B. Open Challenges tab, confirm serif header and updated section labels.

- [ ] **Step 5: Commit**

```bash
git add "VitaminG/VitaminG/VitaminG/Views/ChallengeDiscoveryView.swift"
git commit -m "feat: visual polish on ChallengeDiscoveryView headers and CTA"
```

---

### Task 7: GoalSummaryWidget redesign + StreakHomeWidget

**Files:**
- Modify: `VitaminGWidget/GoalSummaryWidget.swift`
- Modify: `VitaminGWidget/VitaminGWidgetBundle.swift`

- [ ] **Step 1: Replace GoalSummaryWidgetView and add StreakHomeWidget**

Replace the view and widget sections in `GoalSummaryWidget.swift`:

```swift
// MARK: - GoalSummaryWidgetView

struct GoalSummaryWidgetView: View {
    let entry: GoalEntry

    private var doneCount: Int { entry.displayData.tierRows.filter { $0.topGoalTitle != nil }.count }
    private var totalCount: Int { entry.displayData.tierRows.count }
    private var topGoals: [(String, Bool)] {
        entry.displayData.tierRows.prefix(3).compactMap { row in
            guard let title = row.topGoalTitle else { return nil }
            return (title, false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(red: 0.769, green: 0.404, blue: 0.227))
                        .frame(width: 22, height: 22)
                    Text("TODAY · VITAMIN G")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(red: 0.604, green: 0.541, blue: 0.471))
                        .kerning(0.8)
                }
                Spacer()
                Text("\(doneCount) of \(totalCount)")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color(red: 0.961, green: 0.867, blue: 0.816))
                    .foregroundStyle(Color(red: 0.769, green: 0.404, blue: 0.227))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.bottom, 12)

            HStack(alignment: .center, spacing: 14) {
                // Progress ring (local implementation — no app target import)
                let pct = totalCount > 0 ? Double(doneCount) / Double(totalCount) : 0
                WidgetProgressRing(progress: pct)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(topGoals.enumerated()), id: \.offset) { _, goal in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(goal.1 ? Color(red: 0.478, green: 0.620, blue: 0.494) : Color.clear)
                                .overlay(Circle().stroke(Color(red: 0.478, green: 0.620, blue: 0.494), lineWidth: 1.5))
                                .frame(width: 13, height: 13)
                            Text(goal.0)
                                .font(.system(size: 12, weight: goal.1 ? .regular : .medium))
                                .foregroundStyle(goal.1 ? Color(red: 0.604, green: 0.541, blue: 0.471) : Color(red: 0.239, green: 0.184, blue: 0.118))
                                .strikethrough(goal.1)
                                .lineLimit(1)
                        }
                    }
                }
            }

            if entry.displayData.globalStreak > 0 {
                HStack(spacing: 4) {
                    Text("🔥")
                    Text("\(entry.displayData.globalStreak) day streak")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(red: 0.769, green: 0.404, blue: 0.227))
                }
                .padding(.top, 10)
            }
        }
        .padding(16)
        .containerBackground(Color(red: 0.992, green: 0.980, blue: 0.965), for: .widget)
    }
}

// MARK: - WidgetProgressRing (local — no app target dependency)

struct WidgetProgressRing: View {
    let progress: Double
    var size: CGFloat = 64
    var strokeWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(red: 0.910, green: 0.851, blue: 0.769), lineWidth: strokeWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(Color(red: 0.769, green: 0.404, blue: 0.227),
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.18, weight: .semibold))
                .foregroundStyle(Color(red: 0.239, green: 0.184, blue: 0.118))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - GoalSummaryWidget

struct GoalSummaryWidget: Widget {
    let kind = "GoalSummaryWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GoalSummaryProvider()) { entry in
            GoalSummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Goals")
        .description("See your daily goal progress at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - StreakHomeWidgetView

struct StreakHomeWidgetView: View {
    let entry: GoalEntry

    private var tagline: String {
        entry.displayData.globalStreak > 0 ? "🔥 Keep it going" : "Start your streak today"
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.18))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(20))
                .offset(x: 8, y: -8)

            VStack(alignment: .leading, spacing: 0) {
                Text("STREAK")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .kerning(1.0)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(entry.displayData.globalStreak)")
                        .font(.custom("CormorantGaramond-SemiBold", size: 38))
                        .foregroundStyle(Color.white)
                    Text("days")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                .padding(.top, 10)
                Text(tagline)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .padding(.top, 6)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .containerBackground(
            LinearGradient(
                colors: [Color(red: 0.769, green: 0.404, blue: 0.227),
                         Color(hex: "#A0522D")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            for: .widget
        )
    }
}

// MARK: - StreakHomeWidget

struct StreakHomeWidget: Widget {
    let kind = "StreakHomeWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakHomeWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Your current daily streak.")
        .supportedFamilies([.systemSmall])
    }
}
```

- [ ] **Step 2: Register in VitaminGWidgetBundle**

Open `VitaminGWidgetBundle.swift`. Add `StreakHomeWidget()` to the bundle body:

```swift
@main
struct VitaminGWidgetBundle: WidgetBundle {
    var body: some Widget {
        GoalSummaryWidget()
        StreakWidget()
        StreakHomeWidget()
        QuoteWidget()   // will be added in next task
    }
}
```

(Leave `QuoteWidget()` commented out until Task 8 is done if it causes a compile error.)

- [ ] **Step 3: Build and verify**

Cmd+B. Confirm widget target builds. Add widget to simulator home screen to verify layout.

- [ ] **Step 4: Commit**

```bash
git add "VitaminG/VitaminG/VitaminGWidget/GoalSummaryWidget.swift" \
        "VitaminG/VitaminG/VitaminGWidget/VitaminGWidgetBundle.swift"
git commit -m "feat: redesign GoalSummaryWidget and add StreakHomeWidget (.systemSmall)"
```

---

### Task 8: QuoteWidget

**Files:**
- Create: `VitaminGWidget/QuoteWidget.swift`
- Modify: `VitaminGWidget/VitaminGWidgetBundle.swift`

- [ ] **Step 1: Create QuoteWidget.swift**

Create `VitaminG/VitaminG/VitaminGWidget/QuoteWidget.swift`:

```swift
import WidgetKit
import SwiftUI

// MARK: - QuoteEntry

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quoteText: String
}

// MARK: - QuoteProvider

struct QuoteProvider: TimelineProvider {
    private let quotes: [String] = [
        "The secret of getting ahead is getting started.",
        "Small daily improvements lead to stunning results.",
        "You don't have to be great to start, but you have to start to be great.",
        "Every day is a chance to be better than yesterday.",
        "Progress, not perfection.",
        "The only bad workout is the one that didn't happen.",
        "Discipline is choosing between what you want now and what you want most.",
        "It always seems impossible until it's done.",
        "Don't count the days, make the days count.",
        "You are one decision away from a totally different life.",
        "What you do today can improve all your tomorrows.",
        "The harder you work for something, the greater you'll feel when you achieve it.",
        "Dream it. Wish it. Do it.",
        "Success doesn't just find you. You have to go out and get it.",
        "The key to success is to focus on goals, not obstacles.",
    ]

    private var todayQuote: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return quotes[(dayOfYear - 1) % quotes.count]
    }

    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: .now, quoteText: "Small daily improvements lead to stunning results.")
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        completion(QuoteEntry(date: .now, quoteText: todayQuote))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let entry = QuoteEntry(date: .now, quoteText: todayQuote)
        // Refresh at midnight
        let nextMidnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }
}

// MARK: - QuoteWidgetView

struct QuoteWidgetView: View {
    let entry: QuoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DAILY DOSE")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(red: 0.604, green: 0.541, blue: 0.471))
                .kerning(1.0)
            Spacer()
            Text(""\(entry.quoteText)"")
                .font(.custom("CormorantGaramond-Italic", size: 13))
                .foregroundStyle(Color(red: 0.239, green: 0.184, blue: 0.118))
                .lineLimit(5)
                .fixedSize(horizontal: false, vertical: false)
            Spacer()
            HStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.910, green: 0.584, blue: 0.427),
                                     Color(red: 0.769, green: 0.404, blue: 0.227)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 14, height: 14)
                Spacer()
                Text("TAP TO REFLECT")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color(red: 0.604, green: 0.541, blue: 0.471))
                    .kerning(0.5)
            }
        }
        .padding(14)
        .containerBackground(Color(red: 0.992, green: 0.980, blue: 0.965), for: .widget)
        .widgetURL(URL(string: "vitaming://wins"))
    }
}

// MARK: - QuoteWidget

struct QuoteWidget: Widget {
    let kind = "QuoteWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Dose")
        .description("A fresh motivational quote every day.")
        .supportedFamilies([.systemSmall])
    }
}
```

- [ ] **Step 2: Uncomment QuoteWidget() in bundle**

In `VitaminGWidgetBundle.swift`, ensure `QuoteWidget()` is uncommented in the bundle body (from Task 7 Step 2).

- [ ] **Step 3: Build and verify**

Cmd+B. Confirm widget target builds clean. Add to simulator, verify quote text appears.

- [ ] **Step 4: Commit**

```bash
git add "VitaminG/VitaminG/VitaminGWidget/QuoteWidget.swift" \
        "VitaminG/VitaminG/VitaminGWidget/VitaminGWidgetBundle.swift"
git commit -m "feat: add QuoteWidget (.systemSmall) with daily rotating quote"
```

---

### Final verification checklist

- [ ] All 5 tabs present: Home / Goals / Community / Challenges / Profile
- [ ] Wins tab gone — no `DailyWinsView` in tab bar
- [ ] GoalListView renders card layout on sandLight background
- [ ] Primary challenge card appears when a UserChallenge exists
- [ ] ProfileView: hero banner visible, tabs switch (Goals/Badges/Activity)
- [ ] Community tab: shows challenge list or empty state with "Explore" CTA
- [ ] Widget gallery shows GoalSummaryWidget, StreakWidget (lock screen), StreakHomeWidget, QuoteWidget
- [ ] All tests pass: `Cmd+U`

```bash
git tag visual-redesign-complete
```
