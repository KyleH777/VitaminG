# VitaminG Handoff UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild every VitaminG screen to match the Claude Design handoff bundles, adding community engagement, idea board with challenge promotion, mood logging, satisfying goal interactions, and a custom tab bar with glow effects.

**Architecture:** Screen-by-screen replacement across 4 phases — Onboarding → Home/Goals → Community/Explore/Profile → Custom tab bar + dark mode sweep. New SwiftData models (GoalIdea, MoodEntry) land in SchemaV7, following the existing lightweight migration pattern. All existing navigation routes and SwiftData bindings are preserved.

**Tech Stack:** Swift 5.9, SwiftUI (iOS 17+), SwiftData, @Observable MVVM, UIKit haptics (UIImpactFeedbackGenerator), VGTheme adaptive color tokens

**Spec:** `docs/superpowers/specs/2026-05-14-handoff-ui-implementation-design.md`

**Base path** (all file paths relative to): `Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/`

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `Models/SchemaV7.swift` | GoalIdea + MoodEntry SwiftData models |
| Modify | `Models/VitaminGMigrationPlan.swift` | Add V6→V7 lightweight stage |
| Modify | `Persistence/ModelContainerFactory.swift` | Register SchemaV7 |
| Create | `Models/ChallengeLibrary.swift` | Static goal catalogue (12 categories, 4–6 goals each) |
| Create | `Views/Components/VGCapsule.swift` | Extracted VitaminTablet shape |
| Modify | `Views/Components/ProgressRingView.swift` | Add glow + sublabel parameters |
| Create | `Views/Components/VGTabBar.swift` | Custom tab bar with active-line + glow |
| Modify | `Views/ContentView.swift` | Attach VGTabBar via safeAreaInset, suppress system tab bar |
| Modify | `Views/Onboarding/WelcomeScreen.swift` | Button label copy |
| Modify | `Views/Onboarding/MotivationCategoryScreen.swift` | 2-col icon grid |
| Modify | `Views/Onboarding/NotificationOnboardingScreen.swift` | Frosted notification preview card |
| Modify | `Views/Onboarding/CommunityGoalOnboardingScreen.swift` | Gradient challenge card |
| Modify | `Views/HomeView.swift` | Greeting with name, ◉ streak badge, "Today's dose" quote, mini rings |
| Modify | `Views/GoalListView.swift` | Inline header, adaptive bg, hero card, ProgressRing rows, haptics |
| Modify | `Views/GoalCreation/Step2NameScreen.swift` | Curated suggestion pool, "pick for me" cycling |
| Create | `ViewModels/IdeaBoardViewModel.swift` | Upvote + promotion pipeline |
| Create | `Views/Community/IdeaBoardView.swift` | Idea board card list + FAB |
| Create | `Views/Community/ProposeIdeaSheet.swift` | Idea submission form |
| Create | `Views/Community/CommentSheetView.swift` | Per-post comment sheet |
| Modify | `Views/CommunityTabView.swift` | Feed/Ideas segmented picker |
| Modify | `Views/CommunityFeedView.swift` | Tappable reactions + comment sheet trigger |
| Modify | `Views/ChallengeDiscoveryView.swift` | 12-category catalogue from ChallengeLibrary |
| Modify | `Views/ProfileView.swift` | Mood logging, hero section, activity heatmap |
| Modify | `Views/GoalDetailView.swift` | Adaptive colors, haptics on check-in |
| Modify | `Views/SettingsView.swift` | Adaptive colors |

---

## Phase 1 — Foundation & Onboarding

---

### Task 1: SchemaV7 — GoalIdea + MoodEntry models

**Files:**
- Create: `Models/SchemaV7.swift`
- Modify: `Models/VitaminGMigrationPlan.swift`
- Modify: `Persistence/ModelContainerFactory.swift`

- [ ] **Step 1: Create `Models/SchemaV7.swift`**

```swift
import SwiftData
import Foundation

// MARK: - SchemaV7
// Adds GoalIdea and MoodEntry — new models, purely additive, lightweight migration from V6.
// All properties optional-or-defaulted for CloudKit compatibility.

enum SchemaV7: VersionedSchema {
    static var versionIdentifier = Schema.Version(7, 0, 0)

    static var models: [any PersistentModel.Type] {
        [SchemaV6.Goal.self,
         SchemaV2.CompletionEvent.self,
         SchemaV2.UserProfile.self,
         SchemaV3.DailyWin.self,
         SchemaV4.ChallengeTemplate.self,
         SchemaV4.UserChallenge.self,
         SchemaV4.CheckIn.self,
         SchemaV5.TransformationPhoto.self,
         SchemaV5.SpendingFreezeEntry.self,
         SchemaV5.NutritionEntry.self,
         SchemaV7.GoalIdea.self,
         SchemaV7.MoodEntry.self]
    }

    @Model final class GoalIdea {
        var id: UUID = UUID()
        var title: String = ""
        var ideaDescription: String = ""
        var category: String = ""
        var authorName: String = ""
        var createdAt: Date = Date()
        var upvoteCount: Int = 0
        var copyCount: Int = 0
        var isPromoted: Bool = false
        var promotedChallengeID: UUID? = nil
        init() {}
    }

    @Model final class MoodEntry {
        var id: UUID = UUID()
        var mood: Int = 0       // 0=Amazing 1=Good 2=Okay 3=Low 4=Push
        var recordedAt: Date = Date()
        var note: String? = nil
        init() {}
    }
}
```

- [ ] **Step 2: Add V6→V7 stage to `Models/VitaminGMigrationPlan.swift`**

Add `SchemaV7.self` to `schemas` and append `migrateV6toV7` to `stages`:

```swift
static var schemas: [any VersionedSchema.Type] {
    [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self,
     SchemaV5.self, SchemaV6.self, SchemaV7.self]
}

static var stages: [MigrationStage] {
    [migrateV1toV2, migrateV2toV3, migrateV3toV4,
     migrateV4toV5, migrateV5toV6, migrateV6toV7]
}

static let migrateV6toV7 = MigrationStage.lightweight(
    fromVersion: SchemaV6.self,
    toVersion: SchemaV7.self
)
```

- [ ] **Step 3: Update `Persistence/ModelContainerFactory.swift`**

Replace every `SchemaV6` reference with `SchemaV7`:

```swift
// Line ~9 — change both occurrences:
let schema = Schema(SchemaV7.models, version: SchemaV7.versionIdentifier)
```

- [ ] **Step 4: Build — confirm zero compile errors**

In Xcode: Product → Build (⌘B). Expected: Build Succeeded. If the app was previously installed on device/simulator, delete it first to avoid migration conflicts during testing.

- [ ] **Step 5: Commit**

```bash
git add VitaminG/Models/SchemaV7.swift VitaminG/Models/VitaminGMigrationPlan.swift VitaminG/Persistence/ModelContainerFactory.swift
git commit -m "feat: add SchemaV7 with GoalIdea and MoodEntry models"
```

---

### Task 2: ChallengeLibrary — static goal catalogue

**Files:**
- Create: `Models/ChallengeLibrary.swift`

- [ ] **Step 1: Create `Models/ChallengeLibrary.swift`**

```swift
import Foundation

// MARK: - ChallengeLibrary
// Static catalogue — no network, no SwiftData. Read-only at runtime.

struct GoalTemplate: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
    let level: String          // "Easy" | "Medium" | "Hard"
}

struct GoalCategorySection: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let colorToken: String     // matches VGTheme accent name
    let goals: [GoalTemplate]
}

enum ChallengeLibrary {
    static let categories: [GoalCategorySection] = [
        .init(name: "Morning Habits", icon: "◐", colorToken: "terra", goals: [
            .init(title: "No phone for the first 30 minutes", duration: "Daily habit", level: "Medium"),
            .init(title: "Make your bed before leaving your room", duration: "Daily habit", level: "Easy"),
            .init(title: "Drink a full glass of water before coffee", duration: "Daily habit", level: "Easy"),
            .init(title: "5-minute morning journal", duration: "Daily habit", level: "Easy"),
            .init(title: "Cold shower every morning", duration: "Daily habit", level: "Hard"),
        ]),
        .init(name: "Movement", icon: "◎", colorToken: "sage", goals: [
            .init(title: "10-minute walk after every meal", duration: "Daily habit", level: "Easy"),
            .init(title: "3 full workouts per week", duration: "Weekly", level: "Medium"),
            .init(title: "Stretch for 5 minutes before bed", duration: "Daily habit", level: "Easy"),
            .init(title: "Take the stairs every time", duration: "Daily habit", level: "Easy"),
            .init(title: "Stand up every hour at work", duration: "Daily habit", level: "Easy"),
        ]),
        .init(name: "Mindfulness", icon: "◇", colorToken: "purple", goals: [
            .init(title: "Meditate for 10 minutes daily", duration: "Daily habit", level: "Easy"),
            .init(title: "3 deep breaths before any hard conversation", duration: "Daily habit", level: "Easy"),
            .init(title: "One hour of phone-free time per day", duration: "Daily habit", level: "Medium"),
            .init(title: "Gratitude — write 3 things every night", duration: "Daily habit", level: "Easy"),
        ]),
        .init(name: "Nutrition", icon: "◑", colorToken: "gold", goals: [
            .init(title: "Drink 8 glasses of water daily", duration: "Daily habit", level: "Easy"),
            .init(title: "No added sugar for 30 days", duration: "30 days", level: "Hard"),
            .init(title: "Cook at home at least 5 nights a week", duration: "Weekly", level: "Medium"),
            .init(title: "Eat a vegetable with every meal", duration: "Daily habit", level: "Easy"),
        ]),
        .init(name: "Sleep", icon: "☽", colorToken: "purple", goals: [
            .init(title: "In bed by 10:30 pm every night", duration: "Daily habit", level: "Medium"),
            .init(title: "No screens 30 minutes before sleep", duration: "Daily habit", level: "Medium"),
            .init(title: "Same wake time every day including weekends", duration: "Daily habit", level: "Hard"),
        ]),
        .init(name: "Career & Learning", icon: "△", colorToken: "gold", goals: [
            .init(title: "Read 20 pages every night before sleep", duration: "Daily habit", level: "Easy"),
            .init(title: "Finish one book this month", duration: "Monthly", level: "Medium"),
            .init(title: "Learn one new word daily", duration: "Daily habit", level: "Easy"),
            .init(title: "No social media before noon", duration: "Daily habit", level: "Medium"),
        ]),
        .init(name: "Relationships", icon: "◈", colorToken: "terra", goals: [
            .init(title: "Call a friend or family member once a week", duration: "Weekly", level: "Easy"),
            .init(title: "Put the phone away at dinner every night", duration: "Daily habit", level: "Easy"),
            .init(title: "Send a genuine compliment once a day", duration: "Daily habit", level: "Easy"),
            .init(title: "Plan one meaningful outing this month", duration: "Monthly", level: "Medium"),
        ]),
        .init(name: "Creativity", icon: "◐", colorToken: "sage", goals: [
            .init(title: "Write 300 words every day", duration: "Daily habit", level: "Medium"),
            .init(title: "Sketch something every evening", duration: "Daily habit", level: "Easy"),
            .init(title: "Finish one project you've been putting off", duration: "One-time", level: "Medium"),
            .init(title: "Learn one chord or one new note every day", duration: "Daily habit", level: "Easy"),
        ]),
        .init(name: "Finance", icon: "◉", colorToken: "gold", goals: [
            .init(title: "Log every purchase the day it happens", duration: "Daily habit", level: "Easy"),
            .init(title: "No impulse buys — 48-hour wait rule", duration: "Daily habit", level: "Medium"),
            .init(title: "Save $100 per week automatically", duration: "Weekly", level: "Medium"),
            .init(title: "Pack lunch instead of eating out", duration: "Daily habit", level: "Easy"),
        ]),
        .init(name: "Sobriety & Recovery", icon: "◎", colorToken: "sage", goals: [
            .init(title: "30 days alcohol-free", duration: "30 days", level: "Hard"),
            .init(title: "Replace the craving with a walk", duration: "Daily habit", level: "Medium"),
            .init(title: "Call your accountability partner weekly", duration: "Weekly", level: "Easy"),
        ]),
        .init(name: "Productivity", icon: "△", colorToken: "terra", goals: [
            .init(title: "Plan tomorrow's top 3 tasks each evening", duration: "Daily habit", level: "Easy"),
            .init(title: "Single-task — one thing at a time", duration: "Daily habit", level: "Medium"),
            .init(title: "Inbox zero every Friday", duration: "Weekly", level: "Medium"),
        ]),
        .init(name: "Gratitude", icon: "♡", colorToken: "terra", goals: [
            .init(title: "Send one thank-you message per day", duration: "Daily habit", level: "Easy"),
            .init(title: "End each day listing one win", duration: "Daily habit", level: "Easy"),
            .init(title: "Tell someone you appreciate them weekly", duration: "Weekly", level: "Easy"),
        ]),
    ]
}
```

- [ ] **Step 2: Build — confirm zero errors**

⌘B. Expected: Build Succeeded.

- [ ] **Step 3: Commit**

```bash
git add VitaminG/Models/ChallengeLibrary.swift
git commit -m "feat: add ChallengeLibrary static goal catalogue (12 categories)"
```

---

### Task 3: Extract VGCapsule component

**Files:**
- Create: `Views/Components/VGCapsule.swift`
- Modify: `Views/Onboarding/WelcomeScreen.swift` (remove private VitaminTablet, import VGCapsule)

- [ ] **Step 1: Create `Views/Components/VGCapsule.swift`**

```swift
import SwiftUI

// MARK: - VGCapsule
// Vitamin tablet motif — chunky rounded square used on the splash screen and community cards.

struct VGCapsule: View {
    let size: CGFloat
    let color1: Color
    let color2: Color

    private var corner: CGFloat { size * 0.28 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner)
                .fill(color1)
                .overlay(RoundedRectangle(cornerRadius: corner)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
            VStack(spacing: 0) {
                Color.clear
                color2.opacity(0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: corner))
            Rectangle()
                .fill(Color.white.opacity(0.18))
                .frame(height: 1)
            Ellipse()
                .fill(Color.white.opacity(0.22))
                .frame(width: size * 0.27, height: size * 0.22)
                .offset(x: -size * 0.17, y: -size * 0.19)
                .rotationEffect(.degrees(-15))
            Text("g")
                .font(Font.custom("Georgia-Italic", size: size * 0.36))
                .foregroundStyle(Color.white.opacity(0.30))
        }
        .frame(width: size, height: size)
    }
}
```

- [ ] **Step 2: In `Views/Onboarding/WelcomeScreen.swift`, remove the private `VitaminTablet` struct entirely and replace all `VitaminTablet(` calls with `VGCapsule(`**

The parameters are identical — `size:`, `color1:`, `color2:`. The struct was marked `private` so only that file used it.

- [ ] **Step 3: Build — confirm zero errors**

⌘B. Expected: Build Succeeded.

- [ ] **Step 4: Commit**

```bash
git add VitaminG/Views/Components/VGCapsule.swift VitaminG/Views/Onboarding/WelcomeScreen.swift
git commit -m "refactor: extract VGCapsule component from WelcomeScreen"
```

---

### Task 4: ProgressRingView — glow + sublabel

**Files:**
- Modify: `Views/Components/ProgressRingView.swift`

- [ ] **Step 1: Add `glow` and `sublabel` parameters**

Open `Views/Components/ProgressRingView.swift`. Add two parameters to the existing struct's init (or default properties if it uses them):

```swift
struct ProgressRingView: View {
    let progress: Double          // 0.0–1.0
    let tier: GoalTier
    let isCompleted: Bool
    var size: CGFloat = 80
    var strokeWidth: CGFloat = 6
    var glow: Bool = true
    var sublabel: String? = nil

    @Environment(\.colorScheme) private var colorScheme
```

- [ ] **Step 2: Apply glow shadow on the progress arc**

Inside the body, find the stroke circle (the filled arc). Add after existing modifiers:

```swift
.shadow(
    color: glow && colorScheme == .dark
        ? tierColor.opacity(0.6)
        : .clear,
    radius: 6
)
```

Where `tierColor` is whatever color the ring currently uses for the filled arc. If the view derives color from `tier`, keep using that. The `.clear` shadow in light mode adds zero cost.

- [ ] **Step 3: Add sublabel below the percentage in the ring center**

Find where the center label is rendered (the `Text` or `VStack` inside the ring overlay). Add after the existing percentage text:

```swift
if let sublabel {
    Text(sublabel)
        .font(.system(size: size * 0.11))
        .foregroundStyle(VGTheme.textMuted)
        .lineLimit(1)
}
```

- [ ] **Step 4: Build — confirm zero errors**

⌘B.

- [ ] **Step 5: Commit**

```bash
git add VitaminG/Views/Components/ProgressRingView.swift
git commit -m "feat: add glow and sublabel to ProgressRingView"
```

---

### Task 5: Onboarding — WelcomeScreen + MotivationCategoryScreen

**Files:**
- Modify: `Views/Onboarding/WelcomeScreen.swift`
- Modify: `Views/Onboarding/MotivationCategoryScreen.swift`

- [ ] **Step 1: Update WelcomeScreen button labels**

Find the primary `Button` label. Change `"Get Started"` → `"Create account"`.

Find the secondary/ghost button. Change its border to `1.5pt` `Color.white.opacity(0.2)`:

```swift
Button(action: { /* existing action */ }) {
    Text(savedName.trimmingCharacters(in: .whitespaces).isEmpty
         ? "I'll set this up later"
         : "Sign in")
        .font(.system(size: 17, weight: .medium))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .foregroundStyle(VGTheme.sand)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
        )
}
```

- [ ] **Step 2: Rewrite MotivationCategoryScreen body to match the handoff grid**

Replace the existing list/grid with:

```swift
// Inside the view's body, after the step bar and headlines:
let categories: [(label: String, icon: String)] = [
    ("Health & Fitness", "◎"), ("Mindfulness", "◇"),
    ("Career", "△"),           ("Relationships", "◈"),
    ("Learning", "◉"),         ("Nutrition", "◑"),
    ("Creativity", "◐"),       ("Morning Habits", "☀"),
]

LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
    ForEach(Array(categories.enumerated()), id: \.offset) { index, cat in
        let isOn = selectedIndices.contains(index)
        Button {
            if isOn { selectedIndices.remove(index) }
            else { selectedIndices.insert(index) }
        } label: {
            HStack(spacing: 10) {
                Text(cat.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isOn ? VGTheme.terra : VGTheme.muted)
                Text(cat.label)
                    .font(.system(size: 13, weight: isOn ? .semibold : .regular))
                    .foregroundStyle(isOn ? VGTheme.clay : VGTheme.muted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(isOn ? VGTheme.terraLight : VGTheme.warmWhite)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isOn ? VGTheme.terra : VGTheme.sandMid, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
.padding(.horizontal, 28)
.padding(.top, 24)
```

Add `@State private var selectedIndices: Set<Int> = []` to the view.

The existing `StepBarView(current: 1, total: 4)` stays as-is.

- [ ] **Step 3: Build — confirm zero errors**

⌘B.

- [ ] **Step 4: Commit**

```bash
git add VitaminG/Views/Onboarding/WelcomeScreen.swift VitaminG/Views/Onboarding/MotivationCategoryScreen.swift
git commit -m "feat(onboarding): update welcome button labels and motivation category grid"
```

---

### Task 6: Onboarding — NotificationOnboardingScreen dark card

**Files:**
- Modify: `Views/Onboarding/NotificationOnboardingScreen.swift`

- [ ] **Step 1: Replace the existing card with the frosted notification preview card**

Inside the screen's `VStack`, replace the existing mock notification block with:

```swift
// Frosted notification preview card
RoundedRectangle(cornerRadius: 18)
    .fill(.ultraThinMaterial)
    .overlay(Color.white.opacity(0.11))
    .overlay(
        RoundedRectangle(cornerRadius: 18)
            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
    )
    .frame(height: 130)
    .overlay(alignment: .leading) {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(VGTheme.terra)
                    .frame(width: 34, height: 34)
                    .overlay(Text("G").font(Font.custom("Georgia-Italic", size: 18))
                        .foregroundStyle(VGTheme.warmWhite))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vitamin G").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(VGTheme.sand)
                    Text("now").font(.system(size: 11)).foregroundStyle(VGTheme.muted)
                }
            }
            Text("Good morning, \(firstName) ☀️")
                .font(VGTheme.serif(19)).foregroundStyle(VGTheme.sand)
            Text("Day 12 of your Summer Body Challenge. You're 72% there.")
                .font(.system(size: 13)).foregroundStyle(VGTheme.sand.opacity(0.7))
                .lineLimit(2)
        }
        .padding(18)
    }
    .padding(.horizontal, 28)
    .padding(.bottom, 32)
```

- [ ] **Step 2: Replace hero text block**

Below the card, replace the existing text with:

```swift
VStack(alignment: .leading, spacing: 14) {
    Group {
        Text("Stay on track,\n")
            .font(VGTheme.serif(42))
        + Text("every day.")
            .font(VGTheme.serifItalic(42))
            .foregroundStyle(VGTheme.terraSoft)
    }
    .foregroundStyle(VGTheme.sand)
    .lineSpacing(2)

    Text("One daily nudge at the time you choose. No noise, just your reminder to keep going.")
        .font(.system(size: 14, weight: .light))
        .foregroundStyle(VGTheme.muted)
        .lineSpacing(4)
}
.padding(.horizontal, 28)
```

- [ ] **Step 3: Update buttons — light style on dark background**

Primary button: `background(VGTheme.sand)`, `foregroundStyle(VGTheme.clay)`  
Ghost button: `foregroundStyle(VGTheme.sand.opacity(0.6))`, no background

- [ ] **Step 4: Build — confirm zero errors**

⌘B.

- [ ] **Step 5: Commit**

```bash
git add VitaminG/Views/Onboarding/NotificationOnboardingScreen.swift
git commit -m "feat(onboarding): redesign notification screen with frosted preview card"
```

---

### Task 7: Onboarding — CommunityGoalOnboardingScreen challenge card

**Files:**
- Modify: `Views/Onboarding/CommunityGoalOnboardingScreen.swift`

- [ ] **Step 1: Replace headline**

```swift
VStack(alignment: .leading, spacing: 0) {
    Text("Your first").font(VGTheme.serif(42)).foregroundStyle(VGTheme.clay)
    Text("challenge").font(VGTheme.serifItalic(42)).foregroundStyle(VGTheme.terra)
    Text("awaits.").font(VGTheme.serif(42)).foregroundStyle(VGTheme.clay)
}
```

- [ ] **Step 2: Replace challenge card**

```swift
VStack(spacing: 0) {
    // Gradient header
    ZStack(alignment: .topLeading) {
        LinearGradient(
            colors: [VGTheme.terraSoft, VGTheme.terra,
                     Color(red: 0.627, green: 0.322, blue: 0.176)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        Circle().fill(Color.white.opacity(0.08))
            .frame(width: 120, height: 120)
            .offset(x: -20, y: -20)
        VStack(alignment: .leading, spacing: 8) {
            Text("☀️ COMMUNITY CHALLENGE")
                .font(.system(size: 10, weight: .bold))
                .kerning(1.4)
                .foregroundStyle(VGTheme.warmWhite.opacity(0.7))
            Text("90-Day Summer\nBody Challenge")
                .font(VGTheme.serif(22, weight: .medium))
                .foregroundStyle(VGTheme.warmWhite)
                .lineSpacing(2)
            Text("Daily workouts · Nutrition plans · Accountability check-ins")
                .font(.system(size: 12))
                .foregroundStyle(VGTheme.warmWhite.opacity(0.75))
        }
        .padding(20)
    }
    .frame(height: 130)

    // White body
    VStack(alignment: .leading, spacing: 14) {
        HStack {
            ForEach([("4,821", "Joined"), ("Day 1", "Starts"), ("90", "Days")], id: \.0) { val, lbl in
                VStack(spacing: 2) {
                    Text(val).font(VGTheme.serif(22, weight: .medium)).foregroundStyle(VGTheme.clay)
                    Text(lbl).font(.system(size: 11)).kerning(0.6)
                        .textCase(.uppercase).foregroundStyle(VGTheme.muted)
                }
                .frame(maxWidth: .infinity)
            }
        }
        // Progress bar
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 99).fill(VGTheme.sandMid).frame(height: 6)
                RoundedRectangle(cornerRadius: 99).fill(VGTheme.terra)
                    .frame(width: geo.size.width * 0.02, height: 6)
            }
        }
        .frame(height: 6)
        // Avatar stack
        HStack(spacing: 6) {
            HStack(spacing: -8) {
                ForEach([VGTheme.terraSoft, VGTheme.sage, VGTheme.gold, VGTheme.purple], id: \.self) { c in
                    Circle().fill(c).frame(width: 26, height: 26)
                        .overlay(Circle().strokeBorder(VGTheme.warmWhite, lineWidth: 2))
                }
            }
            Text("+4,817 others joined").font(.system(size: 12)).foregroundStyle(VGTheme.muted)
        }
    }
    .padding(16)
    .background(VGTheme.warmWhite)
}
.clipShape(RoundedRectangle(cornerRadius: 20))
.shadow(color: VGTheme.clay.opacity(0.12), radius: 24, y: 4)
.padding(.horizontal, 28)
```

- [ ] **Step 3: Build — confirm zero errors**

⌘B.

- [ ] **Step 4: Commit**

```bash
git add VitaminG/Views/Onboarding/CommunityGoalOnboardingScreen.swift
git commit -m "feat(onboarding): redesign community goal screen with gradient challenge card"
```

---

## Phase 2 — Home, Goals & Goal Creation

---

### Task 8: HomeView redesign

**Files:**
- Modify: `Views/HomeView.swift`

- [ ] **Step 1: Add user name + ◉ streak badge to header**

Replace the existing `headerSection`:

```swift
private var headerSection: some View {
    HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(greeting) ☀️")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(VGTheme.textMuted)
                .kerning(0.5)
            Text(displayName)
                .font(VGTheme.serif(26))
                .foregroundStyle(VGTheme.sand)
        }
        Spacer()
        HStack(spacing: 10) {
            streakBadge
            bellButton
        }
    }
    .padding(.horizontal, 24)
    .padding(.top, 8)
}

@AppStorage("vg_onboardingName") private var storedName: String = ""
private var displayName: String {
    storedName.trimmingCharacters(in: .whitespaces).isEmpty ? "You" : storedName
}
```

- [ ] **Step 2: Replace streakBadge with ◉ icon version**

```swift
@Environment(\.colorScheme) private var colorScheme

private var streakBadge: some View {
    HStack(spacing: 5) {
        Text("◉")
            .font(.system(size: 13))
            .foregroundStyle(VGTheme.accentTerra)
            .shadow(color: colorScheme == .dark ? VGTheme.accentTerra.opacity(0.6) : .clear, radius: 4)
        Text("\(currentStreak)")
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundStyle(VGTheme.accentTerra)
        Text("day streak")
            .font(.system(size: 11))
            .foregroundStyle(VGTheme.textMuted)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(VGTheme.surface)
    .clipShape(Capsule())
    .overlay(Capsule().strokeBorder(VGTheme.separator, lineWidth: 1))
}

private var bellButton: some View {
    ZStack(alignment: .topTrailing) {
        Image(systemName: "bell.fill")
            .font(.system(size: 16))
            .foregroundStyle(VGTheme.textSecondary)
            .frame(width: 36, height: 36)
            .background(VGTheme.surface)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(VGTheme.separator, lineWidth: 1))
        Circle()
            .fill(VGTheme.accentTerra)
            .frame(width: 6, height: 6)
            .offset(x: 1, y: -1)
    }
}
```

- [ ] **Step 3: Update quote section with "TODAY'S DOSE" label**

Replace `quoteSection`:

```swift
private var quoteSection: some View {
    let quotes = [
        "Small steps, taken daily, build the life you've been dreaming of.",
        "Progress, not perfection.",
        "Every day is a chance to be better than yesterday.",
        "You don't have to be great to start, but you have to start to be great.",
    ]
    let quote = quotes[Calendar.current.component(.day, from: Date()) % quotes.count]

    return VStack(alignment: .leading, spacing: 6) {
        Text("TODAY'S DOSE")
            .font(.system(size: 9, weight: .semibold))
            .kerning(1.4)
            .textCase(.uppercase)
            .foregroundStyle(VGTheme.textMuted)
        Text(quote)
            .font(VGTheme.serifItalic(16))
            .foregroundStyle(VGTheme.textSecondary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(VGTheme.surface)
    .overlay(alignment: .leading) {
        Rectangle().frame(width: 2).foregroundStyle(VGTheme.accentTerra)
    }
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .padding(.horizontal, 24)
    .padding(.top, 20)
}
```

- [ ] **Step 4: Update secondary goal rows to use mini ProgressRingView**

Replace `goalRow(_:)`:

```swift
private func goalRow(_ goal: Goal) -> some View {
    HStack(spacing: 14) {
        ProgressRingView(
            progress: goalProgress(goal),
            tier: goal.tier,
            isCompleted: goal.isCompleted,
            size: 46,
            strokeWidth: 4,
            glow: true
        )
        VStack(alignment: .leading, spacing: 3) {
            Text(goal.title ?? "Untitled")
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(VGTheme.textPrimary)
                .lineLimit(2)
            HStack(spacing: 4) {
                Text(goal.tier.displayName)
                    .font(.system(size: 11))
                    .foregroundStyle(VGTheme.textMuted)
                Text("· Today")
                    .font(.system(size: 11))
                    .foregroundStyle(VGTheme.accentTerra)
            }
        }
        Spacer()
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(VGTheme.textMuted)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 14)
    .background(VGTheme.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(VGTheme.separator, lineWidth: 1))
}
```

- [ ] **Step 5: Build — confirm zero errors**

⌘B.

- [ ] **Step 6: Commit**

```bash
git add VitaminG/Views/HomeView.swift
git commit -m "feat: redesign HomeView with user name, streak badge, today's dose quote, mini rings"
```

---

### Task 9: GoalListView redesign + haptics

**Files:**
- Modify: `Views/GoalListView.swift`

- [ ] **Step 1: Fix background to adaptive token**

Find `.background(VGTheme.sandLight)` and replace with `.background(VGTheme.background)`.

- [ ] **Step 2: Replace navigation title with inline serif header**

Add at the top of `goalScrollView` (or whichever named var holds the scroll content):

```swift
// Add inside the ScrollView's top, before tier sections:
HStack {
    Text("My Goals")
        .font(VGTheme.serif(28))
        .foregroundStyle(VGTheme.textPrimary)
    Spacer()
    Button { showingAddGoal = true } label: {
        Text("+ New goal")
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(VGTheme.accentTerra)
            .foregroundStyle(VGTheme.background)
            .clipShape(Capsule())
    }
    .shadow(color: VGTheme.accentTerra.opacity(0.4), radius: 8)
}
.padding(.horizontal, 24).padding(.top, 8)
```

Add to the view: `.toolbar(.hidden, for: .navigationBar)` and `.navigationBarTitleDisplayMode(.inline)`.

- [ ] **Step 3: Replace goal row cards with ProgressRingView + adaptive colors**

Find existing goal row views (wherever they render `Goal` cells). Replace card background with `VGTheme.surface`, border `VGTheme.separator`, corner 14pt. Add `ProgressRingView(progress:, tier:, isCompleted:, size: 48, strokeWidth: 4)` as leading element.

- [ ] **Step 4: Add haptic feedback on check-in / completion**

Find the check-in action (wherever `CompletionEvent` is created or `goal.isCompleted` flips to true). Add before or after the data update:

```swift
// On check-in:
UIImpactFeedbackGenerator(style: .medium).impactOccurred()

// On 100% completion:
UINotificationFeedbackGenerator().notificationOccurred(.success)
```

- [ ] **Step 5: Add spring scale animation to goal row tap**

Create a custom `ButtonStyle`:

```swift
struct GoalRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
```

Apply to each goal row: `.buttonStyle(GoalRowButtonStyle())`.

- [ ] **Step 6: Build — confirm zero errors**

⌘B.

- [ ] **Step 7: Commit**

```bash
git add VitaminG/Views/GoalListView.swift
git commit -m "feat: redesign GoalListView with inline header, adaptive colors, haptics, spring animations"
```

---

### Task 10: Goal creation — curated suggestion pool + "pick for me"

**Files:**
- Modify: `Views/GoalCreation/Step2NameScreen.swift`

- [ ] **Step 1: Replace suggestion data with curated pool**

In `Step2NameScreen`, find the suggestion chips array (likely derived from `GoalCategory`). Replace the suggestions per category with the following — add a computed property or update the `GoalCategory` extension:

```swift
// In Step2NameScreen or GoalCategory extension:
func suggestions(for category: GoalCategory) -> [String] {
    switch category {
    case .body:
        return ["Work out 4 times this week", "Run a 5K without stopping",
                "Do 10 push-ups every morning", "Walk 8,000 steps every day",
                "No junk food for 21 days"]
    case .mind:
        return ["Read 20 pages every night before sleep", "Finish one book this month",
                "Learn one new word daily", "Journal for 5 minutes every morning",
                "No social media before noon"]
    case .wellness:
        return ["Be in bed by 10:30 pm", "Drink 3 litres of water daily",
                "No alcohol this month", "Meditate for 10 minutes daily",
                "Take a 10-minute walk every day"]
    case .money:
        return ["Save $200 this month", "Track every expense for 30 days",
                "No unnecessary purchases for 2 weeks", "Pack lunch 4 days a week",
                "Transfer 10% of every paycheck to savings"]
    case .connection:
        return ["Call a friend or family member once a week",
                "Plan one meaningful outing this month",
                "Put the phone away at dinner every night",
                "Send a genuine compliment once a day"]
    case .creative:
        return ["Write 300 words every day", "Sketch something every evening",
                "Finish one project you've been putting off",
                "Learn one chord or one note every day"]
    case .habit:
        return ["No phone in bed", "Make your bed every single morning",
                "Floss every night", "10-minute tidy before bed",
                "First thing: drink water, not scroll"]
    case .other:
        return []
    }
}
```

- [ ] **Step 2: Add "pick for me" button + cycling state**

```swift
@State private var suggestionIndex: Int = 0

// Button in the suggestion area:
Button {
    let pool = suggestions(for: viewModel.selectedCategory)
    guard !pool.isEmpty else { return }
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        viewModel.draftTitle = pool[suggestionIndex % pool.count]
        suggestionIndex += 1
    }
} label: {
    Text("Pick one for me ✦")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(VGTheme.accentTerra)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(VGTheme.surface)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(VGTheme.separator, lineWidth: 1))
}
```

- [ ] **Step 3: Build — confirm zero errors**

⌘B.

- [ ] **Step 4: Commit**

```bash
git add VitaminG/Views/GoalCreation/Step2NameScreen.swift
git commit -m "feat: update goal suggestion pool and add pick-for-me cycling"
```

---

## Phase 3 — Community, Explore & Profile

---

### Task 11: IdeaBoardViewModel

**Files:**
- Create: `ViewModels/IdeaBoardViewModel.swift`

- [ ] **Step 1: Create `ViewModels/IdeaBoardViewModel.swift`**

```swift
import SwiftUI
import SwiftData

@MainActor
@Observable
final class IdeaBoardViewModel {
    private static let promotionThreshold = 20
    private static let upvotedKey = "vg_upvotedIdeaIDs"

    var showingProposeSheet = false
    var toastMessage: String? = nil

    private var upvotedIDs: Set<String> {
        get {
            let raw = UserDefaults.standard.string(forKey: Self.upvotedKey) ?? ""
            return Set(raw.split(separator: ",").map(String.init))
        }
        set {
            UserDefaults.standard.set(newValue.joined(separator: ","), forKey: Self.upvotedKey)
        }
    }

    func isUpvoted(_ idea: SchemaV7.GoalIdea) -> Bool {
        upvotedIDs.contains(idea.id.uuidString)
    }

    func toggleUpvote(_ idea: SchemaV7.GoalIdea, context: ModelContext) {
        let idStr = idea.id.uuidString
        if upvotedIDs.contains(idStr) {
            var ids = upvotedIDs; ids.remove(idStr); upvotedIDs = ids
            idea.upvoteCount = max(0, idea.upvoteCount - 1)
        } else {
            var ids = upvotedIDs; ids.insert(idStr); upvotedIDs = ids
            idea.upvoteCount += 1
            checkPromotion(idea, context: context)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        try? context.save()
    }

    func addToMyGoals(_ idea: SchemaV7.GoalIdea, goalVM: GoalViewModel, context: ModelContext) {
        // Build a GoalInput from the idea
        let tier = GoalTier.immediate
        let frequency = GoalFrequency.daily
        let category = GoalCategory(rawValue: idea.category) ?? .other
        let input = GoalInput(title: idea.title, tier: tier, category: category,
                              frequency: frequency, reminderTime: nil,
                              isPrivate: false, startDate: nil)
        goalVM.addGoal(input: input, context: context)
        idea.copyCount += 1
        try? context.save()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func submitIdea(title: String, description: String, category: String,
                    authorName: String, context: ModelContext) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let idea = SchemaV7.GoalIdea()
        idea.title = String(title.prefix(80))
        idea.ideaDescription = String(description.prefix(200))
        idea.category = category
        idea.authorName = authorName
        context.insert(idea)
        try? context.save()
        showingProposeSheet = false
    }

    private func checkPromotion(_ idea: SchemaV7.GoalIdea, context: ModelContext) {
        guard idea.upvoteCount >= Self.promotionThreshold, !idea.isPromoted else { return }
        // Create a ChallengeTemplate from the idea
        let template = SchemaV4.ChallengeTemplate()
        template.title = idea.title
        template.challengeDescription = idea.ideaDescription
        template.durationDays = 30
        template.isFeatured = false
        context.insert(template)
        idea.isPromoted = true
        idea.promotedChallengeID = template.id
        try? context.save()
        withAnimation {
            toastMessage = "🎉 This idea just became a challenge!"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.toastMessage = nil
        }
    }
}
```

- [ ] **Step 2: Build — confirm zero errors**

⌘B. If `GoalInput`, `GoalFrequency`, `GoalCategory`, or `GoalViewModel.addGoal(input:context:)` are unavailable, check that Phase B (goal creation wizard) was previously implemented. If `addGoal(input:)` doesn't exist yet, call `goalVM.addGoal(title: idea.title, tier: .immediate, context: context)` as a fallback using whatever signature exists.

- [ ] **Step 3: Commit**

```bash
git add VitaminG/ViewModels/IdeaBoardViewModel.swift
git commit -m "feat: add IdeaBoardViewModel with upvote and promotion pipeline"
```

---

### Task 12: IdeaBoardView + ProposeIdeaSheet

**Files:**
- Create: `Views/Community/IdeaBoardView.swift`
- Create: `Views/Community/ProposeIdeaSheet.swift`

- [ ] **Step 1: Create `Views/Community/IdeaBoardView.swift`**

```swift
import SwiftUI
import SwiftData

struct IdeaBoardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SchemaV7.GoalIdea.upvoteCount, order: .reverse)
    private var ideas: [SchemaV7.GoalIdea]

    @State private var vm = IdeaBoardViewModel()
    @State private var goalVM = GoalViewModel()
    @AppStorage("vg_onboardingName") private var userName: String = ""

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(ideas) { idea in
                        ideaCard(idea)
                    }
                    if ideas.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }

            // FAB
            Button { vm.showingProposeSheet = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 54, height: 54)
                    .background(VGTheme.accentTerra)
                    .foregroundStyle(VGTheme.background)
                    .clipShape(Circle())
                    .shadow(color: VGTheme.accentTerra.opacity(0.4), radius: 10)
            }
            .padding(.trailing, 20).padding(.bottom, 30)

            // Toast
            if let msg = vm.toastMessage {
                Text(msg)
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(VGTheme.accentSage)
                    .clipShape(Capsule())
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $vm.showingProposeSheet) {
            ProposeIdeaSheet(vm: vm, authorName: userName)
        }
        .animation(.easeInOut, value: vm.toastMessage)
    }

    private func ideaCard(_ idea: SchemaV7.GoalIdea) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if !idea.category.isEmpty {
                        Text(idea.category.uppercased())
                            .font(.system(size: 9, weight: .semibold)).kerning(1.2)
                            .foregroundStyle(VGTheme.textMuted)
                    }
                    Text(idea.title)
                        .font(VGTheme.serif(17))
                        .foregroundStyle(VGTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                // Upvote button
                Button { vm.toggleUpvote(idea, context: context) } label: {
                    VStack(spacing: 2) {
                        Text("△")
                            .font(.system(size: 16))
                            .foregroundStyle(vm.isUpvoted(idea) ? VGTheme.accentTerra : VGTheme.textMuted)
                        Text("\(idea.upvoteCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(vm.isUpvoted(idea) ? VGTheme.accentTerra : VGTheme.textMuted)
                    }
                    .frame(width: 40, height: 44)
                    .background(VGTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(vm.isUpvoted(idea) ? VGTheme.accentTerra.opacity(0.4) : VGTheme.separator, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            if !idea.ideaDescription.isEmpty {
                Text(idea.ideaDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(VGTheme.textSecondary)
                    .lineLimit(3)
            }

            // Promotion badge
            if idea.isPromoted {
                Label("Now a Challenge — view in Explore", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(VGTheme.accentSage)
            } else if idea.upvoteCount >= 15 {
                Text("🔥 Almost a challenge — \(idea.upvoteCount) votes")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(VGTheme.accentTerra)
            }

            HStack {
                Text("\(idea.copyCount) added this")
                    .font(.system(size: 11)).foregroundStyle(VGTheme.textMuted)
                Spacer()
                Button("Add to my goals →") {
                    vm.addToMyGoals(idea, goalVM: goalVM, context: context)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(VGTheme.accentTerra)
            }
        }
        .padding(16)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(VGTheme.separator, lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("◈").font(.system(size: 40)).foregroundStyle(VGTheme.textMuted)
            Text("No ideas yet").font(VGTheme.serif(20)).foregroundStyle(VGTheme.textPrimary)
            Text("Be the first to propose a goal the community can work toward together.")
                .font(.system(size: 13)).foregroundStyle(VGTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
```

- [ ] **Step 2: Create `Views/Community/ProposeIdeaSheet.swift`**

```swift
import SwiftUI
import SwiftData

struct ProposeIdeaSheet: View {
    let vm: IdeaBoardViewModel
    let authorName: String

    @Environment(\.modelContext) private var context
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory = ""

    private let categories = ChallengeLibrary.categories.map(\.name)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Propose a challenge")
                        .font(VGTheme.serif(28))
                        .foregroundStyle(VGTheme.textPrimary)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("GOAL IDEA").font(.system(size: 10, weight: .semibold)).kerning(1.2)
                            .foregroundStyle(VGTheme.textMuted)
                        TextField("e.g. Walk 10,000 steps every day", text: $title, axis: .vertical)
                            .font(VGTheme.serif(20))
                            .foregroundStyle(VGTheme.textPrimary)
                            .onChange(of: title) { _, new in
                                if new.count > 80 { title = String(new.prefix(80)) }
                            }
                        Divider().background(VGTheme.accentTerra)
                        Text("\(title.count)/80").font(.system(size: 11))
                            .foregroundStyle(VGTheme.textMuted).frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("DESCRIPTION (OPTIONAL)").font(.system(size: 10, weight: .semibold)).kerning(1.2)
                            .foregroundStyle(VGTheme.textMuted)
                        TextField("Why is this a great goal?", text: $description, axis: .vertical)
                            .font(.system(size: 15))
                            .foregroundStyle(VGTheme.textSecondary)
                            .lineLimit(3...6)
                            .onChange(of: description) { _, new in
                                if new.count > 200 { description = String(new.prefix(200)) }
                            }
                        Divider()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("CATEGORY").font(.system(size: 10, weight: .semibold)).kerning(1.2)
                            .foregroundStyle(VGTheme.textMuted)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                let isOn = selectedCategory == cat
                                Button { selectedCategory = isOn ? "" : cat } label: {
                                    Text(cat).font(.system(size: 12, weight: isOn ? .semibold : .regular))
                                        .foregroundStyle(isOn ? VGTheme.accentTerra : VGTheme.textMuted)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(isOn ? VGTheme.accentTerra.opacity(0.1) : VGTheme.surface)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().strokeBorder(
                                            isOn ? VGTheme.accentTerra : VGTheme.separator, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
            .background(VGTheme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.showingProposeSheet = false }.foregroundStyle(VGTheme.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share idea") {
                        vm.submitIdea(title: title, description: description,
                                      category: selectedCategory, authorName: authorName, context: context)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(title.trimmingCharacters(in: .whitespaces).isEmpty ? VGTheme.textMuted : VGTheme.accentTerra)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
```

- [ ] **Step 3: Build — confirm zero errors**

⌘B.

- [ ] **Step 4: Commit**

```bash
git add VitaminG/Views/Community/IdeaBoardView.swift VitaminG/Views/Community/ProposeIdeaSheet.swift
git commit -m "feat: add IdeaBoardView and ProposeIdeaSheet for community goal proposals"
```

---

### Task 13: CommentSheetView + CommunityFeedView engagement

**Files:**
- Create: `Views/Community/CommentSheetView.swift`
- Modify: `Views/CommunityFeedView.swift`

- [ ] **Step 1: Create `Views/Community/CommentSheetView.swift`**

```swift
import SwiftUI

// Local comment model — not synced, stored per post ID in AppStorage as JSON
struct LocalComment: Codable, Identifiable {
    let id: UUID
    let authorName: String
    let body: String
    let createdAt: Date

    init(authorName: String, body: String) {
        self.id = UUID(); self.authorName = authorName
        self.body = body; self.createdAt = Date()
    }
}

struct CommentSheetView: View {
    let postID: String
    @AppStorage("vg_onboardingName") private var userName: String = ""
    @State private var comments: [LocalComment] = []
    @State private var draftText = ""
    @FocusState private var fieldFocused: Bool

    private var storageKey: String { "vg_comments_\(postID)" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if comments.isEmpty {
                    Spacer()
                    Text("No comments yet. Be first.")
                        .font(.system(size: 14)).foregroundStyle(VGTheme.textMuted)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(comments) { c in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(c.authorName.isEmpty ? "You" : c.authorName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(VGTheme.textPrimary)
                                    Text(c.body).font(.system(size: 14))
                                        .foregroundStyle(VGTheme.textSecondary)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(VGTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 12)
                    }
                }

                Divider()
                HStack(spacing: 10) {
                    TextField("Add a comment…", text: $draftText, axis: .vertical)
                        .font(.system(size: 14))
                        .lineLimit(1...4)
                        .focused($fieldFocused)
                    Button {
                        let body = draftText.trimmingCharacters(in: .whitespaces)
                        guard !body.isEmpty else { return }
                        let c = LocalComment(authorName: userName, body: String(body.prefix(300)))
                        comments.append(c)
                        persist()
                        draftText = ""
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(draftText.isEmpty ? VGTheme.textMuted : VGTheme.accentTerra)
                    }
                    .disabled(draftText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(VGTheme.background)
            }
            .background(VGTheme.background)
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { load(); fieldFocused = true }
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(comments) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([LocalComment].self, from: data)
        else { return }
        comments = saved
    }
}
```

- [ ] **Step 2: Add tappable reactions and comment sheet trigger to CommunityFeedView**

In `CommunityFeedView`, find the reaction row at the bottom of each post card. Replace static display with tappable state:

```swift
// Per post state — stored in a Dict keyed by post ID
@State private var heartedIDs: Set<String> = []   // load from AppStorage key "vg_hearted"
@State private var firedIDs: Set<String> = []     // "vg_fired"
@State private var commentPostID: String? = nil    // triggers sheet

// In each post's reaction row:
HStack(spacing: 16) {
    // Heart
    Button {
        let id = post.id.uuidString
        if heartedIDs.contains(id) { heartedIDs.remove(id) }
        else { heartedIDs.insert(id); UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    } label: {
        HStack(spacing: 5) {
            Text("♡").font(.system(size: 14))
                .foregroundStyle(heartedIDs.contains(post.id.uuidString) ? VGTheme.accentTerra : VGTheme.textMuted)
            Text("\(post.heartCount + (heartedIDs.contains(post.id.uuidString) ? 1 : 0))")
                .font(.system(size: 12.5, weight: .medium)).foregroundStyle(VGTheme.textMuted)
        }
    }.buttonStyle(.plain)

    // Reply
    Button { commentPostID = post.id.uuidString } label: {
        HStack(spacing: 5) {
            Image(systemName: "bubble.left").font(.system(size: 12))
            Text("Reply").font(.system(size: 12))
        }
        .foregroundStyle(VGTheme.textMuted)
    }.buttonStyle(.plain)

    Spacer()
}
```

Add `.sheet(item: $commentPostID) { id in CommentSheetView(postID: id) }` to the parent view.

*(Note: `post.heartCount` should be whatever Int property the existing model uses. If it doesn't exist, use a hardcoded `0` — the real count is local-only until backend sync is added.)*

- [ ] **Step 3: Build — confirm zero errors**

⌘B.

- [ ] **Step 4: Commit**

```bash
git add VitaminG/Views/Community/CommentSheetView.swift VitaminG/Views/CommunityFeedView.swift
git commit -m "feat: add comment sheet and tappable reactions to community feed"
```

---

### Task 14: CommunityTabView — Feed/Ideas segmented picker

**Files:**
- Modify: `Views/CommunityTabView.swift`

- [ ] **Step 1: Add segment state and picker**

```swift
@State private var segment: CommunitySegment = .feed

enum CommunitySegment: String, CaseIterable {
    case feed = "Feed"
    case ideas = "Ideas"
}
```

- [ ] **Step 2: Add picker to the community header**

Below the "Community" serif heading, before the stories row:

```swift
Picker("Section", selection: $segment) {
    ForEach(CommunitySegment.allCases, id: \.self) { s in
        Text(s.rawValue).tag(s)
    }
}
.pickerStyle(.segmented)
.padding(.horizontal, 16)
.padding(.bottom, 8)
```

- [ ] **Step 3: Conditionalize content on segment**

Wrap the existing feed content in `if segment == .feed { ... }` and add `else { IdeaBoardView() }`.

- [ ] **Step 4: Build — confirm zero errors**

⌘B.

- [ ] **Step 5: Commit**

```bash
git add VitaminG/Views/CommunityTabView.swift
git commit -m "feat: add Feed/Ideas segmented picker to CommunityTabView"
```

---

### Task 15: ChallengeDiscoveryView — 12-category catalogue

**Files:**
- Modify: `Views/ChallengeDiscoveryView.swift`

- [ ] **Step 1: Replace hardcoded categories with ChallengeLibrary**

Remove the existing hardcoded category/goal arrays. Add:

```swift
private let catalogue = ChallengeLibrary.categories
@State private var searchText = ""

private var filtered: [GoalCategorySection] {
    guard !searchText.isEmpty else { return catalogue }
    return catalogue.compactMap { section in
        let goals = section.goals.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
        return goals.isEmpty ? nil : GoalCategorySection(
            name: section.name, icon: section.icon,
            colorToken: section.colorToken, goals: goals)
    }
}
```

- [ ] **Step 2: Add search bar at the top of the scroll view**

```swift
HStack(spacing: 8) {
    Image(systemName: "magnifyingglass")
        .font(.system(size: 14)).foregroundStyle(VGTheme.textFaint)
    TextField("Search goals…", text: $searchText)
        .font(.system(size: 13.5))
        .foregroundStyle(VGTheme.textPrimary)
}
.padding(.horizontal, 14).padding(.vertical, 11)
.background(VGTheme.surface)
.clipShape(RoundedRectangle(cornerRadius: 12))
.overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(VGTheme.separator, lineWidth: 1))
.padding(.horizontal, 16).padding(.top, 8)
```

- [ ] **Step 3: Render 12 category sections from `filtered`**

```swift
ForEach(filtered) { section in
    VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 6) {
            Text(section.icon).font(.system(size: 14))
                .foregroundStyle(VGTheme.accentTerra)
            Text(section.name.uppercased())
                .font(.system(size: 10, weight: .semibold)).kerning(1.2)
                .foregroundStyle(VGTheme.textMuted)
        }
        .padding(.horizontal, 16)

        ForEach(section.goals) { goal in
            HStack(spacing: 12) {
                Circle().fill(VGTheme.accentTerra).frame(width: 7, height: 7)
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title).font(.system(size: 14, weight: .medium))
                        .foregroundStyle(VGTheme.textPrimary)
                    HStack(spacing: 8) {
                        Text(goal.duration).font(.system(size: 11)).foregroundStyle(VGTheme.textMuted)
                        Text(goal.level)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(goal.level == "Easy" ? VGTheme.accentSage : VGTheme.accentGold)
                    }
                }
                Spacer()
                Button("+ Add") {
                    // Create goal from template
                    let input = GoalInput(title: goal.title, tier: .immediate,
                                         category: .habit, frequency: .daily,
                                         reminderTime: nil, isPrivate: false, startDate: nil)
                    goalVM.addGoal(input: input, context: modelContext)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(VGTheme.accentTerra)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(VGTheme.accentTerra.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(VGTheme.accentTerra.opacity(0.3), lineWidth: 1))
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(VGTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(VGTheme.separator, lineWidth: 1))
            .padding(.horizontal, 16)
        }
    }
    .padding(.bottom, 14)
}
```

Add `@State private var goalVM = GoalViewModel()` to the view.

- [ ] **Step 4: Build — confirm zero errors**

⌘B.

- [ ] **Step 5: Commit**

```bash
git add VitaminG/Views/ChallengeDiscoveryView.swift
git commit -m "feat: replace challenge view with 12-category ChallengeLibrary catalogue and search"
```

---

### Task 16: ProfileView — mood logging + hero + heatmap

**Files:**
- Modify: `Views/ProfileView.swift`

- [ ] **Step 1: Add MoodEntry query and persist logic**

```swift
@Query(sort: \SchemaV7.MoodEntry.recordedAt, order: .reverse)
private var moodEntries: [SchemaV7.MoodEntry]

private func logMood(_ index: Int) {
    let today = Calendar.current.startOfDay(for: Date())
    if let existing = moodEntries.first(where: {
        Calendar.current.startOfDay(for: $0.recordedAt) == today
    }) {
        existing.mood = index
    } else {
        let entry = SchemaV7.MoodEntry()
        entry.mood = index
        modelContext.insert(entry)
    }
    try? modelContext.save()
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
}

private var todayMood: Int? {
    let today = Calendar.current.startOfDay(for: Date())
    return moodEntries.first(where: {
        Calendar.current.startOfDay(for: $0.recordedAt) == today
    })?.mood
}
```

- [ ] **Step 2: Replace the mood picker to call `logMood`**

Find the existing mood picker. For each option button:

```swift
let moods = [("◎", "Amazing"), ("○", "Good"), ("◐", "Okay"), ("◑", "Low"), ("◉", "Push")]
ForEach(Array(moods.enumerated()), id: \.offset) { index, mood in
    let isActive = todayMood == index
    Button { logMood(index) } label: {
        VStack(spacing: 4) {
            Text(mood.0).font(.system(size: 18))
                .foregroundStyle(isActive ? VGTheme.accentTerra : VGTheme.textSecondary)
                .shadow(color: isActive && colorScheme == .dark ? VGTheme.accentTerra.opacity(0.6) : .clear, radius: 6)
            Text(mood.1).font(.system(size: 9, weight: isActive ? .semibold : .regular))
                .kerning(0.4)
                .foregroundStyle(isActive ? VGTheme.accentTerra : VGTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isActive ? VGTheme.accentTerra.opacity(0.14) : VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .strokeBorder(isActive ? VGTheme.accentTerra.opacity(0.4) : VGTheme.separator, lineWidth: 1))
        .shadow(color: isActive && colorScheme == .dark ? VGTheme.accentTerra.opacity(0.2) : .clear, radius: 8)
    }
    .buttonStyle(.plain)
}
```

- [ ] **Step 3: Fix background to adaptive token**

Replace `.background(VGTheme.sandLight)` → `.background(VGTheme.background)`.

- [ ] **Step 4: Add activity heatmap for the Activity profile tab**

In the existing `tab === 'activity'` section, add:

```swift
// Add ActivityHeatmapView as a subview inside the activity tab content:
private var activityHeatmap: some View {
    let weeks = 10
    let days = 7
    let calendar = Calendar.current
    let eventDates = Set(completionEvents.compactMap { e -> Date? in
        guard let d = e.date else { return nil }
        return calendar.startOfDay(for: d)
    })
    let today = calendar.startOfDay(for: Date())

    return VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 4) {
            ForEach(0..<weeks, id: \.self) { w in
                VStack(spacing: 4) {
                    ForEach(0..<days, id: \.self) { d in
                        let offset = -(weeks - 1 - w) * 7 - (days - 1 - d)
                        let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
                        let hasActivity = eventDates.contains(date)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(hasActivity ? VGTheme.accentTerra : VGTheme.surface)
                            .frame(width: 22, height: 22)
                            .shadow(color: hasActivity && colorScheme == .dark
                                    ? VGTheme.accentTerra.opacity(0.4) : .clear, radius: 3)
                    }
                }
            }
        }
        HStack {
            Text("10 weeks ago").font(.system(size: 11)).foregroundStyle(VGTheme.textMuted)
            Spacer()
            Text("This week").font(.system(size: 11)).foregroundStyle(VGTheme.textMuted)
        }
        .padding(.top, 4)
    }
    .padding(16)
}
```

Add `.activity` to `ProfileViewModel.ProfileTab` enum if not already present. Show `activityHeatmap` when `activeTab == .activity`.

- [ ] **Step 5: Build — confirm zero errors**

⌘B.

- [ ] **Step 6: Commit**

```bash
git add VitaminG/Views/ProfileView.swift
git commit -m "feat: add mood logging with MoodEntry persistence, adaptive colors, activity heatmap"
```

---

## Phase 4 — Custom Tab Bar + Dark Mode Sweep

---

### Task 17: VGTabBar component

**Files:**
- Create: `Views/Components/VGTabBar.swift`

- [ ] **Step 1: Create `Views/Components/VGTabBar.swift`**

```swift
import SwiftUI

struct VGTabBar: View {
    @Binding var selection: Int
    @Environment(\.colorScheme) private var colorScheme

    private let tabs: [(label: String, icon: String)] = [
        ("Home",      "house"),
        ("Goals",     "circle.circle"),
        ("Community", "person.2"),
        ("Explore",   "magnifyingglass"),
        ("Me",        "person"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                tabItem(index: index, label: tab.label, icon: tab.icon)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
        .background(
            colorScheme == .dark
                ? Color(red: 0.086, green: 0.067, blue: 0.047).opacity(0.92)
                : VGTheme.warmWhite
        )
        .overlay(alignment: .top) {
            Rectangle().frame(height: 0.5).foregroundStyle(VGTheme.separator)
        }
        .background(.ultraThinMaterial)
    }

    private func tabItem(index: Int, label: String, icon: String) -> some View {
        let isActive = selection == index
        return Button {
            if selection == index {
                // Already on tab — could scroll to top; leave for future enhancement
            }
            withAnimation(.easeInOut(duration: 0.15)) { selection = index }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 4) {
                // Active-line indicator
                Rectangle()
                    .frame(height: 2)
                    .foregroundStyle(isActive ? VGTheme.accentTerra : .clear)
                    .shadow(color: isActive ? VGTheme.accentTerra : .clear, radius: 5)

                Image(systemName: isActive ? icon + ".fill" : icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isActive ? VGTheme.accentTerra : VGTheme.textMuted)
                    .shadow(color: isActive && colorScheme == .dark
                            ? VGTheme.accentTerra.opacity(0.55) : .clear, radius: 6)

                Text(label)
                    .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                    .kerning(0.4)
                    .foregroundStyle(isActive ? VGTheme.accentTerra : VGTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Build — confirm zero errors**

⌘B.

- [ ] **Step 3: Commit**

```bash
git add VitaminG/Views/Components/VGTabBar.swift
git commit -m "feat: add VGTabBar with active-line indicator and dark mode glow"
```

---

### Task 18: ContentView — wire VGTabBar

**Files:**
- Modify: `Views/ContentView.swift`

- [ ] **Step 1: Suppress the system tab bar and attach VGTabBar**

In `ContentView.body`, on the `TabView`:

```swift
TabView(selection: $selectedTab) {
    // existing tab content unchanged
}
.toolbar(.hidden, for: .tabBar)
.safeAreaInset(edge: .bottom, spacing: 0) {
    VGTabBar(selection: $selectedTab)
}
```

Remove all `.tabItem { Label(...) }` modifiers from each tab. The tab labels in VGTabBar replace them.

- [ ] **Step 2: Verify tab indices match VGTabBar order**

VGTabBar tab 0 = Home, 1 = Goals, 2 = Community, 3 = Explore, 4 = Me.

Ensure `ContentView` `TabView` tags match: `.tag(0)` on HomeView, `.tag(1)` on Goals, `.tag(2)` on Community, `.tag(3)` on ChallengeDiscoveryView (now Explore), `.tag(4)` on Profile.

- [ ] **Step 3: Build and run on simulator**

Run on iPhone 15 Pro simulator in both light and dark mode. Navigate all 5 tabs. Expected: custom tab bar shows, active-line indicator appears, glow shows in dark mode. No system tab bar visible.

- [ ] **Step 4: Commit**

```bash
git add VitaminG/Views/ContentView.swift
git commit -m "feat: replace system tab bar with VGTabBar via safeAreaInset"
```

---

### Task 19: Dark mode color sweep

**Files:**
- Modify: `Views/GoalDetailView.swift`
- Modify: `Views/SettingsView.swift`

- [ ] **Step 1: In GoalDetailView, replace hardcoded light colors**

Find and replace:
- `.background(VGTheme.sandLight)` → `.background(VGTheme.background)`
- `.background(VGTheme.warmWhite)` → `.background(VGTheme.surface)`
- `.foregroundStyle(VGTheme.clay)` where used as primary text → `.foregroundStyle(VGTheme.textPrimary)`
- Any `Color.white.opacity(X)` used as card background → `VGTheme.surface`

Add haptic to check-in button:
```swift
// In the check-in action:
UIImpactFeedbackGenerator(style: .medium).impactOccurred()
```

- [ ] **Step 2: In SettingsView, replace hardcoded light colors**

Same replacements: `sandLight` → `background`, `warmWhite` → `surface`, `sandMid` separators → `VGTheme.separator`.

- [ ] **Step 3: Build and run in dark mode**

Switch simulator to dark mode (Settings → Developer → Dark Appearance). Navigate to Goal Detail and Settings. Expected: dark warm background, no jarring white patches.

- [ ] **Step 4: Commit**

```bash
git add VitaminG/Views/GoalDetailView.swift VitaminG/Views/SettingsView.swift
git commit -m "fix: replace hardcoded light-mode colors with adaptive VGTheme tokens in GoalDetailView and SettingsView"
```

---

## Self-Review

### Spec coverage check

| Spec requirement | Task |
|-----------------|------|
| SchemaV7: GoalIdea + MoodEntry | Task 1 |
| ChallengeLibrary 12 categories | Task 2 |
| VGCapsule extraction | Task 3 |
| ProgressRingView glow + sublabel | Task 4 |
| WelcomeScreen button labels | Task 5 |
| MotivationCategoryScreen grid | Task 5 |
| NotificationOnboardingScreen dark card | Task 6 |
| CommunityGoalOnboardingScreen card | Task 7 |
| HomeView: name, streak badge, today's dose, mini rings | Task 8 |
| GoalListView: inline header, adaptive bg, rings, haptics, spring | Task 9 |
| Goal suggestion pool + pick-for-me | Task 10 |
| IdeaBoardViewModel: upvote + promote | Task 11 |
| IdeaBoardView + ProposeIdeaSheet | Task 12 |
| CommentSheetView + feed reactions | Task 13 |
| CommunityTabView Feed/Ideas segmented picker | Task 14 |
| ChallengeDiscoveryView 12-category + search | Task 15 |
| ProfileView: mood logging, adaptive bg, heatmap | Task 16 |
| VGTabBar custom component | Task 17 |
| ContentView VGTabBar wiring | Task 18 |
| GoalDetailView + SettingsView dark mode | Task 19 |

All spec requirements covered. ✓

### Type consistency check

- `SchemaV7.GoalIdea` and `SchemaV7.MoodEntry` defined in Task 1, used consistently in Tasks 11, 12, 16.
- `IdeaBoardViewModel.toggleUpvote(_:context:)` defined in Task 11, called in Task 12 — signatures match.
- `IdeaBoardViewModel.submitIdea(title:description:category:authorName:context:)` defined in Task 11, called in Task 12 — matches.
- `ChallengeLibrary.categories: [GoalCategorySection]` defined in Task 2, used in Tasks 12 (ProposeIdeaSheet category names) and 15 — matches.
- `VGTabBar(selection: $selectedTab)` in Task 18 matches the `@Binding var selection: Int` in Task 17.
- `GoalRowButtonStyle` defined in Task 9, applied in Task 9 only.
