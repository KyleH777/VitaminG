# Phase 20: Explore Tab - Pattern Map

**Mapped:** 2026-05-22
**Files analyzed:** 9 new/modified files
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `Views/ExploreView.swift` | view (tab root) | request-response | `Views/ChallengeDiscoveryView.swift` | exact |
| `ViewModels/ExploreViewModel.swift` | viewmodel | CRUD + event-driven | `ViewModels/ChallengeViewModel.swift` | exact |
| `Views/Explore/DailyGoalGifterCard.swift` | component | event-driven | `Views/ChallengeDiscoveryView.swift` → `VitaminDispenserView` | exact |
| `Views/Explore/MoodPromptCard.swift` | component | event-driven + CRUD | `Views/DailyWinsView.swift` | role-match |
| `Views/Explore/VitaminShelfSection.swift` | component | CRUD + filter | `Views/ChallengeDiscoveryView.swift` → `VitaminShelfGrid` | exact |
| `Views/Explore/TrendingNowSection.swift` | component | request-response | `Views/ChallengeDiscoveryView.swift` → `TrendingChallengesRow` | exact |
| `Views/Explore/GiftsForStuckDaysSection.swift` | component | CRUD | `Views/ChallengeDiscoveryView.swift` → `VitaminShelfGrid` inline add | role-match |
| `Views/Explore/ExploreConfettiOverlay.swift` | component | event-driven | `Views/CheckInCelebrationView.swift` | exact |
| `Models/ExploreModels.swift` (or inline enums) | model | — | `Models/GoalCategory.swift` + `Models/ChallengeLibrary.swift` | exact |

---

## Pattern Assignments

### `Views/ExploreView.swift` (view, tab root, request-response)

**Analog:** `Views/ChallengeDiscoveryView.swift` (lines 1–55)
**Also reference:** `Views/HomeView.swift` (lines 1–108) for heroBackground + NavigationBarHidden

**Imports pattern** (ChallengeDiscoveryView lines 1–3):
```swift
import SwiftUI
import SwiftData
```

**Struct declaration + environment pattern** (ChallengeDiscoveryView lines 10–19):
```swift
struct ChallengeDiscoveryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ChallengeViewModel()
    @State private var goalVM = GoalViewModel()
    @Query private var templates: [ChallengeTemplate]
    @Query private var userChallenges: [UserChallenge]
    @State private var showBuildYourOwn = false
    @State private var selectedMood: String = "All"
    @State private var localNavigationPath: NavigationPath = NavigationPath()
    @Binding var navigationPath: NavigationPath
```

**Background + NavigationTitle pattern** (ChallengeDiscoveryView lines 27–55):
```swift
var body: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            // sections stacked vertically
        }
        .padding(.top, 8)
    }
    .background(VGTheme.background)
    .navigationTitle("Explore")
    .onAppear {
        // seed / load data
    }
}
```

**Note:** ExploreView should match the Challenges tab background (`VGTheme.background`) NOT HomeView's `VGTheme.heroBackground`, since this is a discovery tab, not a dark hero screen. Use `VGTheme.background.ignoresSafeArea()`.

**Replace `ExplorePlaceholderView` in ContentView** (ContentView.swift lines 27–30):
```swift
// Before (Phase 16 placeholder):
NavigationStack {
    ExplorePlaceholderView()
}
.tag(AppTab.explore)

// After (Phase 20):
NavigationStack {
    ExploreView()
}
.tag(AppTab.explore)
```

---

### `ViewModels/ExploreViewModel.swift` (viewmodel, CRUD + event-driven)

**Analog:** `ViewModels/ChallengeViewModel.swift` (lines 54–80) + `ViewModels/GoalViewModel.swift` (lines 32–50)

**ViewModel declaration pattern** (GoalViewModel.swift lines 31–50):
```swift
@MainActor
@Observable
final class ExploreViewModel {
    // MARK: - Once-per-day state keys (see Shared Patterns below)
    private static let gifterDateKey = "vg_explore_gifterDate"
    private static let moodPromptDateKey = "vg_explore_moodPromptDate"

    // MARK: - Published UI state
    var dispensedGoal: GoalTemplate? = nil
    var isShaking: Bool = false
    var moodPromptDismissed: Bool = false
    var selectedMood: Int? = nil   // index into mood options array
}
```

**Once-per-day guard pattern** (modeled on DailyWinsViewModel.swift lines 52–65):
```swift
// Use Calendar.current.startOfDay for DST-safe boundaries — established StreakEngine pattern
var hasGiftedToday: Bool {
    guard let stored = UserDefaults.standard.object(forKey: Self.gifterDateKey) as? Date else {
        return false
    }
    return Calendar.current.isDateInToday(stored)
}

func markGiftedToday() {
    UserDefaults.standard.set(Date(), forKey: Self.gifterDateKey)
}
```

**Add-goal (dispense) pattern** (ChallengeDiscoveryView.swift lines 364–369):
```swift
// Copy from VitaminDispenserView — addGoal via GoalInput, then navigate
let input = GoalInput(
    title: goal.title,
    tier: .shortTerm,
    category: .habit,
    frequency: .daily,
    reminderTime: nil,
    isPrivate: false,
    startDate: nil
)
if let newGoal = try? goalVM.addGoal(input: input, context: modelContext) {
    navigationPath.append(AppRoute.goalDetail(newGoal))
}
UIImpactFeedbackGenerator(style: .medium).impactOccurred()
```

---

### `Views/Explore/DailyGoalGifterCard.swift` (component, event-driven + once-per-day)

**Analog:** `Views/ChallengeDiscoveryView.swift` → `VitaminDispenserView` (lines 393–505)

**Shake animation pattern** (VitaminDispenserView lines 410–417):
```swift
private func dispense() {
    guard !moodFiltered.isEmpty else { return }
    dispensedGoal = moodFiltered.randomElement()
    withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
        isShaking = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        isShaking = false
    }
}
```

**Rotation effect for shake visual** (VitaminDispenserView lines 434–436):
```swift
VGCapsule(size: 48, color1: VGTheme.terraSoft, color2: VGTheme.terra)
    .rotationEffect(.degrees(isShaking ? 15 : 0))
```

**DragGesture to trigger shake** (VitaminDispenserView lines 445–448):
```swift
.gesture(
    DragGesture(minimumDistance: 10).onEnded { _ in dispense() }
)
```

**Card container style** (VitaminDispenserView lines 421–432):
```swift
ZStack {
    RoundedRectangle(cornerRadius: 30)
        .fill(LinearGradient(
            colors: [VGTheme.accentTerra.opacity(0.15), VGTheme.accentTerra.opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        ))
        .frame(height: 160)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .strokeBorder(VGTheme.accentTerra.opacity(0.2), lineWidth: 1)
        )
```

**Once-per-day lockout:** After the user adds a gifted goal, call `viewModel.markGiftedToday()`. On next app open, check `viewModel.hasGiftedToday` and show a "Come back tomorrow" state instead of the shake UI. See Shared Patterns: Once-Per-Day Gate.

**Confetti on add:** Trigger confetti overlay (see `ExploreConfettiOverlay`) after `modelContext.insert` succeeds, identical to `CheckInCelebrationView` pattern.

---

### `Views/Explore/MoodPromptCard.swift` (component, event-driven + CRUD)

**Analog:** `Views/DailyWinsView.swift` (lines 36–121) for once-per-day + dismiss with checkmark; `Views/ChallengeDiscoveryView.swift` → `MoodScannerView` (lines 212–238) for mood chip row.

**Collapsible card with checkmark dismiss pattern** — copy from DailyWinsView section header + save flow:
```swift
// Outer card — shown until dismissed for today
if !viewModel.isMoodPromptDismissedToday {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Text("How are you feeling?")
                .font(VGTheme.serif(18))
                .foregroundStyle(VGTheme.textPrimary)
            Spacer()
            // Checkmark dismiss button
            Button {
                viewModel.dismissMoodPrompt()  // writes today's date to UserDefaults
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(VGTheme.accentSage)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Dismiss mood prompt")
        }
        // Mood chip row (copy MoodScannerView pattern)
        moodChipRow
    }
    .padding(18)
    .background(VGTheme.surface)
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(VGTheme.separator, lineWidth: 1))
    .padding(.horizontal, 16)
    .transition(.opacity.combined(with: .move(edge: .top)))
}
```

**Mood chip row pattern** (MoodScannerView lines 217–237):
```swift
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 8) {
        ForEach(moods, id: \.self) { mood in
            let isActive = selectedMood == mood
            Button { selectedMood = mood } label: {
                Text(mood)
                    .font(.system(size: 14, weight: isActive ? .semibold : .regular))
                    .fontDesign(.rounded)
                    .foregroundStyle(isActive ? Color.white : VGTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isActive ? VGTheme.accentTerra : VGTheme.surface)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(isActive ? Color.clear : VGTheme.separator, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
    .padding(.horizontal, 16)
}
```

**MoodEntry insert pattern** (SchemaV7.swift lines 40–46 + GoalViewModel addGoal pattern):
```swift
// When user selects a mood and taps "Save"
let entry = MoodEntry()
entry.mood = selectedMoodIndex   // 0=Amazing 1=Good 2=Okay 3=Low 4=Push
entry.recordedAt = Date()
modelContext.insert(entry)
viewModel.dismissMoodPrompt()
```

---

### `Views/Explore/VitaminShelfSection.swift` (component, CRUD + filter)

**Analog:** `Views/ChallengeDiscoveryView.swift` → `VitaminShelfGrid` (lines 298–389)

**This component already exists as `VitaminShelfGrid` in ChallengeDiscoveryView.** For Phase 20, extract it as a standalone reusable component `VitaminShelfSection` that accepts a `Binding<NavigationPath>` and `GoalViewModel`. Copy the private struct verbatim and make it internal.

**2×2 LazyVGrid pattern** (VitaminShelfGrid lines 311–315):
```swift
LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
    ForEach(catalogue) { section in
        // category card — expands to full-width on tap
    }
}
.padding(.horizontal, 16)
```

**Expand-to-full-width grid cell** (VitaminShelfGrid lines 344–345):
```swift
.gridCellColumns(expandedCategory == section.name ? 2 : 1)
```

**Inline "+ ADD" button pattern** (VitaminShelfGrid lines 355–370):
```swift
Button("+ ADD") {
    let input = GoalInput(
        title: goal.title,
        tier: .shortTerm,
        category: .habit,
        frequency: .daily,
        reminderTime: nil,
        isPrivate: false,
        startDate: nil
    )
    if let newGoal = try? goalVM.addGoal(input: input, context: modelContext) {
        navigationPath.append(AppRoute.goalDetail(newGoal))
    }
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
}
.font(.system(size: 12, weight: .semibold))
.foregroundStyle(VGTheme.accentTerra)
.padding(.horizontal, 12)
.padding(.vertical, 7)
.background(VGTheme.accentTerra.opacity(0.12))
.clipShape(Capsule())
```

**Section label pattern** (VitaminShelfGrid lines 307–312):
```swift
Text("Vitamin Shelf")
    .font(.system(size: 13, weight: .semibold))
    .kerning(0.4)
    .foregroundStyle(VGTheme.textMuted)
    .padding(.horizontal, 16)
```

**Phase 20 addition:** The 6 category cards should map to `GoalCategory` cases (Body, Mind, Wellness, Money, Connection, Creative — drop Habit and Other per the 6-card spec). Use `GoalCategory.emoji` and `GoalCategory.subtitle` for card content instead of `ChallengeLibrary.categories`. Filter `@Query private var goals: [Goal]` by `goal.category == category.rawValue` on tap.

---

### `Views/Explore/TrendingNowSection.swift` (component, request-response)

**Analog:** `Views/ChallengeDiscoveryView.swift` → `TrendingChallengesRow` (lines 242–294)

**Horizontal scroll card row pattern** (TrendingChallengesRow lines 248–294):
```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Trending Now")
        .font(.system(size: 13, weight: .semibold))
        .kerning(0.4)
        .foregroundStyle(VGTheme.textMuted)
        .padding(.horizontal, 16)
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
            ForEach(trendingGoals, id: \.id) { item in
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 180, height: 120)
                    // Content overlaid at bottomLeading
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
```

**Progress circle in trending card:** Use `ProgressRingView` (already exists):
```swift
ProgressRingView(
    progress: item.communityProgress,   // Double 0.0–1.0
    tier: .immediate,                    // use a neutral tier or map category → tier color
    isCompleted: false,
    size: 44,
    strokeWidth: 4,
    glow: false
)
```

**Participant count label** (TrendingChallengesRow lines 274–277):
```swift
if item.participantCount > 0 {
    Text("\(item.participantCount.formatted()) joined")
        .font(.system(size: 11))
        .foregroundStyle(.white.opacity(0.8))
}
```

**Data source note:** For Phase 20, use a static `TrendingGoalItem` struct in `ChallengeLibrary` or `ExploreModels.swift` — no CloudKit fetch required unless spec calls for live data. CloudKit fetch pattern if needed: copy `CommunityService.fetchPosts` (CommunityService.swift lines 24–30) as the query template, adapting `recordType` and `predicate`.

---

### `Views/Explore/GiftsForStuckDaysSection.swift` (component, CRUD)

**Analog:** `Views/ChallengeDiscoveryView.swift` → `VitaminShelfGrid` expanded goal list rows (lines 346–383)

**Curated static list of 3 goals** — use `ChallengeLibrary.categories` as the data source, selecting one goal per mood tier (easy/medium/hard), or define a static `GiftsForStuckDays.goals: [GoalTemplate]` array in `ExploreModels.swift` following the `GoalTemplate` struct pattern (ChallengeLibrary.swift lines 6–11):
```swift
struct GoalTemplate: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
    let level: String   // "Easy" | "Medium" | "Hard"
}
```

**Goal row with "+ Add to my list" button** (VitaminShelfGrid lines 347–383):
```swift
HStack {
    Text(goal.title)
        .font(.system(size: 13))
        .fontDesign(.rounded)
        .foregroundStyle(VGTheme.textPrimary)
        .lineLimit(2)
    Spacer()
    Button("+ Add to my list") {
        let input = GoalInput(title: goal.title, tier: .shortTerm, category: .habit,
                              frequency: .daily, reminderTime: nil,
                              isPrivate: false, startDate: nil)
        try? goalVM.addGoal(input: input, context: modelContext)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    .font(.system(size: 12, weight: .semibold))
    .foregroundStyle(VGTheme.accentTerra)
    .padding(.horizontal, 12)
    .padding(.vertical, 7)
    .background(VGTheme.accentTerra.opacity(0.12))
    .clipShape(Capsule())
}
.padding(.horizontal, 14)
.padding(.vertical, 10)
.background(VGTheme.surface)
.clipShape(RoundedRectangle(cornerRadius: 12))
```

---

### `Views/Explore/ExploreConfettiOverlay.swift` (component, event-driven)

**Analog:** `Views/CheckInCelebrationView.swift` (lines 107–125) — the `confettiView` computed property is the canonical confetti implementation.

**Confetti canvas — copy verbatim** (CheckInCelebrationView lines 107–125):
```swift
// SwiftUI Canvas + TimelineView — no SpriteKit, no third-party
// 60 particles, golden-angle scatter, hue-varied.
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
```

**Reduce Motion gate — always required** (CheckInCelebrationView lines 37–42):
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

// In body:
if !reduceMotion {
    confettiView
        .ignoresSafeArea()
        .accessibilityHidden(true)
}
```

**Badge scale-in animation on appear** (CheckInCelebrationView lines 92–99):
```swift
if reduceMotion {
    badgeScale = 1.0
    badgeOpacity = 1.0
} else {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
        badgeScale = 1.0
        badgeOpacity = 1.0
    }
}
```

**Overlay usage in ExploreView** — present as a ZStack overlay (not fullScreenCover) so the tab bar remains visible:
```swift
ZStack {
    // main scroll content
    if showingConfetti {
        ExploreConfettiOverlay(onDismiss: { showingConfetti = false })
            .transition(.opacity)
    }
}
```

---

### `Models/ExploreModels.swift` (model, enums + static data)

**Analog:** `Models/GoalCategory.swift` (lines 1–76) for enum + emoji/subtitle pattern; `Models/ChallengeLibrary.swift` (lines 1–60) for static catalogue struct pattern.

**Enum pattern** (GoalCategory.swift lines 3–13):
```swift
import Foundation

enum MoodOption: String, CaseIterable, Identifiable {
    // 5 moods for the prompt card
    case amazing  = "Amazing"
    case good     = "Good"
    case okay     = "Okay"
    case low      = "Low"
    case push     = "Push"

    var id: String { rawValue }

    var emoji: String { /* switch */ }
    var subtitle: String { /* switch */ }
}
```

**Static catalogue struct pattern** (ChallengeLibrary.swift lines 6–19):
```swift
struct TrendingGoalItem: Identifiable {
    let id = UUID()
    let title: String
    let categoryName: String
    let participantCount: Int
    let communityProgress: Double   // 0.0–1.0
}

enum ExploreContent {
    static let trendingGoals: [TrendingGoalItem] = [...]
    static let giftsForStuckDays: [GoalTemplate] = [...]
}
```

**GoalCategory filtering** — the Vitamin Shelf cards filter the user's live goals by category. Use `@Query` + in-memory filter (GoalListView pattern, lines 23):
```swift
@Query private var goals: [Goal]

private func goals(for category: GoalCategory) -> [Goal] {
    goals.filter { $0.category == category.rawValue && !$0.isCompleted }
}
```

---

## Shared Patterns

### Background and Navigation Bar
**Source:** `Views/ChallengeDiscoveryView.swift` lines 47–48
**Apply to:** `ExploreView`
```swift
.background(VGTheme.background)
.navigationTitle("Explore")
```

### Section Label Style
**Source:** `Views/ChallengeDiscoveryView.swift` lines 307–311 (VitaminShelfGrid)
**Apply to:** All section headers in ExploreView
```swift
Text("SECTION TITLE")
    .font(.system(size: 13, weight: .semibold))
    .kerning(0.4)
    .foregroundStyle(VGTheme.textMuted)
    .padding(.horizontal, 16)
```

### Card Surface Style
**Source:** `Views/HomeView.swift` lines 187–195
**Apply to:** All card containers (MoodPromptCard, GifterCard, GiftsForStuckDays)
```swift
.padding(18)
.background(VGTheme.surface)
.clipShape(RoundedRectangle(cornerRadius: 18))
.overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(VGTheme.separator, lineWidth: 1))
.padding(.horizontal, 16)
```

### Once-Per-Day Gate (UserDefaults date key)
**Source:** `ViewModels/DailyWinsViewModel.swift` lines 52–65 (Calendar.startOfDay pattern)
**Apply to:** `ExploreViewModel` — gifter lock, mood prompt dismiss
```swift
// Key naming convention: "vg_explore_{featureName}Date"
// Example: "vg_explore_gifterDate", "vg_explore_moodPromptDate"
private static let gifterDateKey = "vg_explore_gifterDate"

var hasGiftedToday: Bool {
    guard let stored = UserDefaults.standard.object(forKey: Self.gifterDateKey) as? Date else {
        return false
    }
    // Calendar.current.startOfDay for DST-safe day boundaries
    return Calendar.current.isDateInToday(stored)
}

func markGiftedToday() {
    UserDefaults.standard.set(Date(), forKey: Self.gifterDateKey)
}
```

**Key naming:** All Explore UserDefaults keys must use the `vg_explore_` prefix (consistent with `vg_` namespace established across the project — see `vg_onboardingName`, `vg_colorScheme`, etc.).

### Add-Goal via GoalInput (modelContext.insert)
**Source:** `Views/ChallengeDiscoveryView.swift` lines 362–370 (VitaminShelfGrid) + `ViewModels/GoalViewModel.swift` lines 186–206
**Apply to:** DailyGoalGifterCard, VitaminShelfSection, GiftsForStuckDaysSection
```swift
let input = GoalInput(
    title: goal.title,
    tier: .shortTerm,
    category: .habit,        // or map from GoalCategory
    frequency: .daily,
    reminderTime: nil,
    isPrivate: false,
    startDate: nil
)
if let newGoal = try? goalVM.addGoal(input: input, context: modelContext) {
    navigationPath.append(AppRoute.goalDetail(newGoal))
}
UIImpactFeedbackGenerator(style: .medium).impactOccurred()
```
Note: `goalVM.addGoal(input:context:)` calls `context.insert()` internally and triggers `WidgetCenter.shared.reloadAllTimelines()` — do not call `context.insert` directly.

### ViewModel Declaration
**Source:** `ViewModels/GoalViewModel.swift` lines 31–32; `ViewModels/ChallengeViewModel.swift` lines 54–56
**Apply to:** `ExploreViewModel`
```swift
@MainActor
@Observable
final class ExploreViewModel {
```

### Haptic Feedback on Action
**Source:** `Views/ChallengeDiscoveryView.swift` line 368; `Views/GoalListView.swift` line 181
**Apply to:** Every add-goal, shake, and dismiss action
```swift
UIImpactFeedbackGenerator(style: .medium).impactOccurred()
```

### Animation with Reduce Motion
**Source:** `Views/CheckInCelebrationView.swift` lines 38, 92–99; `Views/GoalListView.swift` lines 309, 358–366
**Apply to:** Confetti overlay, shake animation, card collapse animation
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

// Always gate animation on reduceMotion:
if !reduceMotion {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { ... }
} else {
    // set state directly, no animation
}
```

### AppRoute Navigation (goal detail push)
**Source:** `Navigation/AppRoute.swift` line 9; `Views/ChallengeDiscoveryView.swift` line 367
**Apply to:** Any card "+ Add" that navigates to goal detail
```swift
navigationPath.append(AppRoute.goalDetail(newGoal))
```

### GoalCategory Enum (6 Vitamin Shelf cards)
**Source:** `Models/GoalCategory.swift` lines 3–10
**Apply to:** VitaminShelfSection — use exactly these 6 cases for the shelf:
```swift
// The 6 shelf categories (omit .habit and .other per Phase 20 spec):
let shelfCategories: [GoalCategory] = [.body, .mind, .wellness, .money, .connection, .creative]
```
Each card uses `category.emoji` + `category.rawValue` + `category.subtitle`.

---

## No Analog Found

No files in this phase are without an analog. All patterns have direct precedent in the codebase.

| File | Closest Gap | Resolution |
|---|---|---|
| `ExploreConfettiOverlay.swift` (standalone overlay vs. fullScreenCover) | Existing confetti always used inside `fullScreenCover` | Use ZStack overlay in ExploreView body instead; canvas code is identical |
| `TrendingNowSection` with live CloudKit data | CommunityService fetches posts, not goals | Start with static data; use `CommunityService.fetchPosts` pattern (CommunityService.swift lines 24–30) if live data is needed in a later phase |

---

## Metadata

**Analog search scope:**
- `VitaminG/VitaminG/VitaminG/Views/` (all Swift files)
- `VitaminG/VitaminG/VitaminG/ViewModels/` (all Swift files)
- `VitaminG/VitaminG/VitaminG/Models/` (all Swift files)
- `VitaminG/VitaminG/VitaminG/Services/` (CommunityService.swift)
- `VitaminG/VitaminG/VitaminG/Navigation/` (AppRoute, Tab)

**Files scanned:** 24 source files read in full
**Pattern extraction date:** 2026-05-22
