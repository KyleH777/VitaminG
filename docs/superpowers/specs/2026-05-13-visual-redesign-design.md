# Visual Redesign — Vitamin G
**Date:** 2026-05-13  
**Mode:** Light mode only  
**Scope:** Tab structure, GoalListView, ProfileView, ChallengeDiscoveryView, CommunityTabView (new), widget redesigns

---

## 1. Tab Structure

### New tab bar (5 tabs)

| Position | Label | Icon | View |
|----------|-------|------|------|
| 1 | Home | `house.fill` | `HomeView` (unchanged) |
| 2 | Goals | `target` | `GoalListView` (redesigned) |
| 3 | Community | `person.2.fill` | `CommunityTabView` (new) |
| 4 | Challenges | `flame.fill` | `ChallengeDiscoveryView` (redesigned) |
| 5 | Profile | `person.crop.circle.fill` | `ProfileView` (redesigned) |

### Changes to ContentView
- Remove the Wins (`DailyWinsView`) tab item.
- Add `CommunityTabView` in slot 3, wrapped in a `NavigationStack`.
- The `.wins` case in `AppRoute` is preserved — it remains a valid navigation destination from within the app (e.g. deep links), just no longer a top-level tab.
- All existing deep-link sheets (public profile, challenge check-in) are unchanged.

---

## 2. GoalListView Redesign

### Structure
Replace `List` with `ScrollView` + `LazyVStack(spacing: 12)`. Background: `VGTheme.sandLight`.

### Header
```
HStack {
    Text("My Goals")  // VGTheme.serif(28), VGTheme.clay
    Spacer()
    Button("+ New Goal")  // VGTheme.terra fill, white label, 10pt radius, 8×14pt padding
}
.padding(.horizontal, 24)
.padding(.top, safeAreaTop)
```

### Primary challenge card (clay hero)
Shown when the user has at least one active `UserChallenge`. Full-width card inside the scroll view.

- Background: linear gradient `VGTheme.clay → VGTheme.clayMid`, 18pt corner radius, soft shadow
- Category label: 10pt uppercase, `VGTheme.muted`, letter-spacing 0.12em
- Challenge name: `VGTheme.serif(18)`, `VGTheme.sand`, line-height 1.3
- `ProgressRing`: 80pt, `VGTheme.terraSoft` stroke, white-opacity track, `label: "XX%"`, `sublabel: "Day N"`
- Days remaining: 12pt `VGTheme.muted`
- Status indicator: 8pt sage dot + "On track" / terra dot + "Behind" in 12pt
- 7-day bar chart: M–S bars, `VGTheme.terraSoft` fill for completed days, white-opacity 10% for incomplete
- Taps to `AppRoute.challengeDetail(userChallenge)`
- Padding: 20pt internal, 16pt horizontal margin

### Goal rows
White `VGTheme.warmWhite` cards, 14pt corner radius, `shadow(color: VGTheme.clay.opacity(0.07), radius: 8, y: 1)`.

```
HStack(spacing: 14) {
    ProgressRing(pct, size: 48, stroke: 4, color: tier.color, trackColor: VGTheme.sandMid,
                 label: completed ? "✓" : "\(pct)%")
    VStack(alignment: .leading, spacing: 3) {
        Text(goal.title)   // 14pt medium, VGTheme.clay; muted + strikethrough when completed
        Text(tagLine)      // 12pt, VGTheme.muted  e.g. "Daily · Streak: 12"
    }
    Spacer()
    chevron  // VGTheme.muted, 16pt
}
.padding(.horizontal, 16).padding(.vertical, 14)
```

`NavigationLink(value: AppRoute.goalDetail(goal))` wrapping each card.

### Sections
- Default sort (`.byTier`): Section headers above each tier group — 10pt uppercase `VGTheme.muted`, 0.1em letter-spacing, no tier color in header.
- Completion-status sort: "Active" / "Completed" plain section headers.
- No `List` section chrome — headers rendered as plain `Text` inside the `LazyVStack`.

### Preserved behaviours
- Sort picker in toolbar `.secondaryAction` menu (unchanged).
- Swipe-to-delete: `.swipeActions` on each card row.
- Milestone badge overlay on `GoalRowView` (unchanged logic, updated container).
- Empty state: existing `EmptyStateView` (already warm-aesthetic, no changes needed).
- `pendingMilestone` routing via `GoalViewModel` (unchanged).

---

## 3. ProfileView Redesign

### Overall layout
`ScrollView` on `VGTheme.sandLight`. Hero banner at top, tab bar pinned below hero, tab content scrolls.

### Hero banner
Background: `LinearGradient(colors: [VGTheme.clay, Color(hex: "#5A3A22")], startPoint: .topLeading, endPoint: .bottomTrailing)`. Padding top: safe area inset.

**Quote strip**
- Container: `VGTheme.warmWhite` 7% opacity background, 3pt left border in `VGTheme.terra`, 12pt corner radius
- Label: "Today's dose" — 10pt uppercase, `VGTheme.muted`, 0.1em letter-spacing
- Quote: `VGTheme.serifItalic(14)`, `VGTheme.sand` at 85% opacity, line-height 1.5
- Quote array in `ProfileViewModel`; index = `Calendar.current.component(.day, from: Date()) % quotes.count`

**Avatar row**
- Avatar: 72pt circle, terra gradient fill (or photo if `photoData` set), 3pt clay border, shadow
- Camera badge: 22pt terra circle bottom-right, white camera SF symbol 11pt
- Display name: `VGTheme.serif(22)`, `VGTheme.sand`
- Handle + location: 12pt `VGTheme.muted` (sourced from `UserProfile.displayName` formatted as `@first_last`)
- Edit button: ghost style, `VGTheme.sand` label, rounded 10pt

**Bio**: 13pt `VGTheme.sand` at 70% opacity. Sourced from a new optional `bio: String?` field on `UserProfile` (nullable, max 160 chars, validated in `ProfileViewModel`). If nil, show nothing.

**Stats row** (4 equal columns, dividers between)
| Column | Value source |
|--------|-------------|
| Streak | `StreakEngine.currentStreak(events: completionEvents, tier: nil)` |
| Goals | `goals.count` |
| Check-ins | `completionEvents.count` |
| Reactions | `ProfileViewModel.reactionCount` (CloudKit fetch, default 0) |

Each column: serif 20pt value in `VGTheme.sand`, 10pt uppercase `VGTheme.muted` label.

**Mood check-in strip**
- 5 options: `[("🌟","Amazing"), ("😊","Good"), ("😐","Okay"), ("😔","Low"), ("💪","Push")]`
- Selected state: terra tint background + terra border; unselected: white-opacity 5%
- `@State var selectedMood: Int?` in `ProfileView` — ephemeral, not persisted
- Label: 11pt, muted unselected / `VGTheme.terraSoft` selected

**Curved bottom edge**: `sandLight`-filled `RoundedRectangle` with only top corners radiused (50% radius) — creates scallop transition into tab content.

### Tab bar (Goals / Badges / Activity)
- `sandLight` background, 1pt `VGTheme.sandMid` bottom border
- Active: 13pt 600-weight `VGTheme.terra`, 2pt terra underline
- Inactive: 13pt 400-weight `VGTheme.muted`
- `@State var activeProfileTab: ProfileTab` in `ProfileView`, enum `ProfileTab { case goals, badges, activity }`

### Goals tab
`LazyVStack(spacing: 10)` of goal cards (same card style as GoalListView rows). All goals, sorted by tier. No section headers. `NavigationLink` to `AppRoute.goalDetail`.

### Badges tab
Data source: for each `UserChallenge`, decode `earnedBadgeSymbolsJSON` → array of SF symbol strings → map to badge definitions:

```swift
struct BadgeDefinition {
    let sfSymbol: String
    let emoji: String
    let label: String
    let color: Color
}
// Known mappings:
// "flame.fill"  → 🔥 "7-Day Streak"   VGTheme.terraSoft
// "trophy.fill" → 🏆 "30-Day Champ"   VGTheme.gold
// "medal.fill"  → 🥇 "60-Day Grind"   VGTheme.sage
// "star.fill"   → ⭐ "90-Day Legend"  VGTheme.purple
```

- 3-column grid of badge cards: white `VGTheme.warmWhite`, 16pt radius. Emoji 28pt, label 11pt bold `VGTheme.clay`. Earned: full opacity + 6pt sage dot top-right. Unearned: 50% opacity.
- "Next badge" progress card below grid: shows the next unearned badge with a terra progress bar (days completed / milestone threshold).
- If no challenges joined: empty state — "Complete challenges to earn badges."

### Activity tab
**Check-in heatmap**: 10 weeks × 7 days grid. Each cell: 32×32pt, 6pt corner radius.
- 0 check-ins: `VGTheme.sandMid`
- 1 check-in: `VGTheme.terra` at 35% opacity
- 2+ check-ins: `VGTheme.terra` full

Source: `@Query var completionEvents: [CompletionEvent]` filtered to last 70 days.  
Day labels (M T W T F S S) above grid in 9pt `VGTheme.muted`.

**Mood history row**: Last 7 days. `@State var moodHistory: [String: String]` persisted via `UserDefaults` (keyed by ISO-8601 date string `"yyyy-MM-dd"` → emoji string e.g. `"😊"`). Each day: emoji 18pt + day letter 10pt muted below.

**Summary card**: white `VGTheme.warmWhite` card, 3 columns:
- Completion rate: `completedToday / totalGoals` as `%` — serif 22pt `VGTheme.terra`
- Current streak: from `StreakEngine`
- Best streak: `StreakEngine.bestStreak(events:)` (add this method if not present)

### Share button + Settings link
Placed at bottom of scroll content (below tab content), same as current implementation.

### Removed from current ProfileView
- Privacy toggle section (public/private profile) — moved to Settings
- `publicGoalsSection` — replaced by Goals tab

---

## 4. ChallengeDiscoveryView Redesign

Visual polish only — structure and data flow unchanged.

### Changes
- Navigation title: replace `.navigationTitle("Challenges")` with inline header `Text("Challenges")` using `VGTheme.serif(28)` + `VGTheme.clay` (consistent with GoalListView header style)
- Background: already `VGTheme.sandLight` ✓
- Featured section label: 10pt uppercase `VGTheme.muted`, 0.12em letter-spacing
- Challenge cards (`ChallengeCardView`): update background from system grouped to `VGTheme.warmWhite`, 18pt corner radius, `shadow(color: VGTheme.clay.opacity(0.07), radius: 8, y: 1)`
- Active/joined challenge banner: clay gradient card (matching GoalListView's primary challenge card) shown at the top of the list when user has an active challenge
- Category pill buttons: `VGTheme.sandMid` background, `VGTheme.clay` text, terra fill on selected state
- "Build Your Own" CTA: `VGTheme.terra`-filled button, full width, 14pt corner radius, white bold label

---

## 5. CommunityTabView (New File)

**File**: `Views/CommunityTabView.swift`

### Layout
`NavigationStack` wrapping a `ScrollView` on `VGTheme.sandLight`.

### Header
`Text("Community")` — `VGTheme.serif(28)`, `VGTheme.clay`, 24pt horizontal padding, safe area top padding.

### Joined challenges list
`@Query var userChallenges: [UserChallenge]` filtered to `!isCompleted`.

Each card (`VGTheme.warmWhite`, 14pt radius, soft shadow):
```
HStack(spacing: 12) {
    RoundedRectangle(cornerRadius: 2)
        .fill(accentColor)
        .frame(width: 4, height: 44)  // accent bar
    VStack(alignment: .leading, spacing: 3) {
        Text(challengeName)   // 14pt medium, VGTheme.clay
        Text(categoryLabel)   // 12pt, VGTheme.muted
    }
    Spacer()
    if hasNewActivity { Circle().fill(VGTheme.terra).frame(width: 8) }
    chevron
}
.padding(.horizontal, 16).padding(.vertical, 14)
```

`NavigationLink(value: AppRoute.communityFeed(userChallenge))` — uses existing route.

### New activity detection
`UserDefaults` key `"community_last_visit_\(challenge.id.uuidString)"` — set to `Date()` `onAppear` of `CommunityFeedView`. A challenge has new activity if its CloudKit posts contain any records newer than this timestamp. Computed in `CommunityFeedViewModel` and exposed as `hasNewPosts: Bool`.

### Empty state
Centered `VStack`:
- `VGTheme.serif(20)`, `VGTheme.clay`: "No challenges yet"
- 14pt `VGTheme.muted`: "Join a challenge to connect with others."
- Terra-filled "Explore Challenges" button — switches active tab to Challenges via `@Binding var selectedTab: Int` (add `@State private var selectedTab = 0` to `ContentView`; pass `$selectedTab` to `TabView(selection:)` and down to `CommunityTabView`; Challenges tab = index 3)

---

## 6. Widget Redesigns

### GoalSummaryWidget (updated, `.systemMedium`)

**Visual changes only — provider and data unchanged.**

View layout:
```
VStack(alignment: .leading, spacing: 0) {
    // Header row
    HStack {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 5).fill(VGTheme.terra)
                .frame(22, 22)  // app icon placeholder
            Text("Today · Vitamin G")  // 11pt uppercase, VGTheme.muted
        }
        Spacer()
        Text("\(done) of \(total)")
            .font(.caption.bold())
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(VGTheme.terraLight)
            .foregroundStyle(VGTheme.terra)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .padding(.bottom, 12)

    // Body
    HStack(alignment: .center, spacing: 14) {
        ProgressRing(pct, size: 64, stroke: 6, color: VGTheme.terra,
                     trackColor: VGTheme.sandMid, label: "\(pct)%")
        VStack(alignment: .leading, spacing: 4) {
            ForEach(topGoals) { goal in
                // GoalCheckRow: private struct in GoalSummaryWidget.swift
                // HStack: 14pt sage-filled circle (checkmark when done) + Text(goal.title)
                // strikethrough + muted when done, clay + medium weight when pending
                GoalCheckRow(goal)
            }
        }
    }
}
.padding(16)
.containerBackground(VGTheme.warmWhite, for: .widget)
```

### StreakHomeWidget (new, `.systemSmall`)

**New `Widget` struct** added to `GoalSummaryWidget.swift` (or its own file). Reuses `StreakProvider` and `GoalEntry`.

```
ZStack(alignment: .topTrailing) {
    // Decorative capsule
    RoundedRectangle(cornerRadius: 10)
        .fill(.white.opacity(0.18))
        .frame(50, 50)
        .rotationEffect(.degrees(20))
        .offset(x: 8, y: -8)

    VStack(alignment: .leading, spacing: 0) {
        Text("STREAK")  // 10pt uppercase, warmWhite at 70%
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text("\(streak)")
                .font(VGTheme.serif(38))
                .foregroundStyle(.white)
            Text("days").font(.system(size: 13)).foregroundStyle(.white.opacity(0.75))
        }
        .padding(.top, 10)
        Text(tagline)  // 11pt, warmWhite at 70%, line-height 1.4
            .padding(.top, 6)
    }
    .padding(14)
}
.containerBackground(
    LinearGradient(colors: [VGTheme.terra, Color(hex: "#A0522D")],
                   startPoint: .topLeading, endPoint: .bottomTrailing),
    for: .widget
)
```

Tagline logic:
- Within 3 days of best streak: "🔥 Personal best in sight"
- Otherwise: "Keep it going"

Registered as `StreakHomeWidget` with `.supportedFamilies([.systemSmall])`.

### QuoteWidget (new, `.systemSmall`)

**New file**: `VitaminGWidget/QuoteWidget.swift`

Provider: `QuoteProvider: TimelineProvider` — no SwiftData access. Quotes array of 30 strings. Entry index = `Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0 % quotes.count`. Timeline refreshes at midnight.

View:
```
VStack(alignment: .leading, spacing: 0) {
    Text("DAILY DOSE")  // 10pt uppercase, VGTheme.muted
    Spacer()
    Text(""\(quote)"")
        .font(VGTheme.serifItalic(13))
        .foregroundStyle(VGTheme.clay)
        .lineSpacing(1.4 * 13 - 13)
        .lineLimit(5)
    Spacer()
    HStack {
        RoundedRectangle(cornerRadius: 3)
            .fill(LinearGradient(colors: [VGTheme.terraSoft, VGTheme.terra],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 14, height: 14)
        Spacer()
        Text("TAP TO REFLECT")  // 9pt, VGTheme.muted, 0.05em letter-spacing
    }
}
.padding(14)
.containerBackground(VGTheme.warmWhite, for: .widget)
.widgetURL(URL(string: "vitaming://wins"))  // deep link to DailyWinsView
```

### VitaminGWidgetBundle update
Add `StreakHomeWidget()` and `QuoteWidget()` to the bundle body alongside existing widgets.

---

## Data Model Notes

- `UserProfile.bio: String?` — new optional field, max 160 chars. SwiftData migration: additive nullable field, no migration script needed.
- `StreakEngine.bestStreak(events:)` — new static method needed if not present. Same logic as `currentStreak` but returns the max consecutive run rather than the current one.
- Mood history — stored in `UserDefaults` only (ephemeral per device, not synced). No SwiftData changes.
- `ProfileViewModel.reactionCount` — CloudKit fetch of public reaction records for the user's profile. Returns `Int`, default 0 on error.

---

## Architecture Constraints

- MVVM strictly enforced: all business logic (badge computation, streak calculation, quote indexing) lives in ViewModels or services, not in Views.
- No third-party dependencies.
- iOS 17+ minimum — use `@Observable`, `@Query`, `.containerBackground(for: .widget)`.
- `ProgressRing` — widget-compatible reimplementation needed (cannot import app target types into widget extension). Define a local `ProgressRingView` in the widget target or move to a shared framework/file included in both targets.
- All new string inputs (bio field) validated in ViewModel with character limit enforcement before SwiftData write.

---

## Files Touched

| File | Change |
|------|--------|
| `ContentView.swift` | Remove Wins tab, add Community tab |
| `GoalListView.swift` | Full redesign |
| `ProfileView.swift` | Full redesign |
| `ProfileViewModel.swift` | Add bio, mood, reactionCount, quote array, bestStreak wiring |
| `ChallengeDiscoveryView.swift` | Visual polish |
| `CommunityTabView.swift` | New file |
| `GoalSummaryWidget.swift` | Visual update + add StreakHomeWidget |
| `QuoteWidget.swift` | New file |
| `VitaminGWidgetBundle.swift` | Register new widgets |
| `StreakEngine.swift` | Add `bestStreak(events:)` if missing |
| `UserProfile` model | Add `bio: String?` field |
