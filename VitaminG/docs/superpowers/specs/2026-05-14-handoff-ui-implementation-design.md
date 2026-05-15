# Handoff UI Implementation — Vitamin G

**Date:** 2026-05-14  
**Approach:** Screen-by-screen (Approach B) — replace each screen to match the design handoffs exactly  
**Sources:**
- Light mode: `Desktop/AI/Vitamin G/VitaminG_redux/vitaming-redux/project/uploads/App onboarding/Vitamin G Signup.html`
- Dark mode: `Desktop/AI/Vitamin G/VitaminG_redux/vitaming-redux/project/VitaminG Dark.html` + `vg-dark-base.jsx` + `vg-dark-screens.jsx`
**Supersedes:** `2026-05-13-visual-redesign-design.md` (same intent, handoffs are the authoritative source)

---

## Overview

The user provided two Claude Design handoff bundles. This spec captures every visual change needed to make the Swift app match them pixel-faithfully, across four implementation phases. The handoffs use Cormorant Garamond (serif) + DM Sans, the existing `VGTheme` color tokens, and a warm light palette in light mode and a deep-ink palette with luminous accents in dark mode.

All functional behavior (SwiftData, CloudKit, notifications, navigation routes) is preserved unchanged unless explicitly noted. Visual layer only, except for the custom tab bar which requires replacing the system `TabView` host.

---

## Design tokens (reference)

All tokens already exist in `VGTheme.swift`. This spec references them by name throughout.

**Light mode palette:** `sand` (#F2E8D9), `sandLight` (#FAF5EE), `sandMid` (#E8D9C4), `sandDeep` (#D4C4A8), `clay` (#3D2F1E), `clayMid` (#5A4232), `terra` (#C4673A), `terraSoft` (#E8956D), `terraLight` (#F5DDD0), `sage` (#7A9E7E), `sageMid` (#5C8A61), `gold` (#C4A459), `muted` (#9A8A78), `warmWhite` (#FDFAF6)

**Dark mode palette:** `inkDeep` (#16110C), `inkMid` (#1F1812), `terraGlow` (#FF8A5C), `sageGlow` (#95D69C), `goldGlow` (#E8D070), `irisGlow` (#C2A4DD), sand variants with opacity

**Adaptive tokens (use these in all views):** `VGTheme.background`, `VGTheme.backgroundSecondary`, `VGTheme.surface`, `VGTheme.surface2`, `VGTheme.separator`, `VGTheme.textPrimary`, `VGTheme.textSecondary`, `VGTheme.textMuted`, `VGTheme.accentTerra`, `VGTheme.accentSage`, `VGTheme.accentGold`, `VGTheme.accentPurple`

**Fonts:** `VGTheme.serif(_:weight:)`, `VGTheme.serifItalic(_:)` for serif; `.system(size:weight:)` for DM Sans (system sans maps well enough)

---

## Shared Components

### `ProgressRingView` — add glow support

Current `ProgressRingView` already exists in `Views/Components/`. Add:
- `glow: Bool = true` parameter — when true and dark mode active, apply `shadow(color: color.opacity(0.6), radius: 6)` on the stroke circle
- `sublabel: String? = nil` — second line below the percentage label in the ring center, 55% of label font size, `VGTheme.textMuted`
- In dark mode the inner label badge background changes to `rgba(34,26,20,0.78)` (use `VGTheme.inkMid.opacity(0.78)`)

### `VGCapsule` (vitamin tablet)

Already implemented in `WelcomeScreen.swift` as `VitaminTablet`. Extract to `Views/Components/VGCapsule.swift` for reuse in onboarding screens.

---

## Phase 1 — Onboarding

### WelcomeScreen.swift

**Changes only:**
- Primary button label: `"Get Started"` → `"Create account"`
- Secondary button: add explicit `1.5pt` border in `Color.white.opacity(0.2)`, label stays as-is (already adaptive)
- No structural change — animation, pile, radial glow all stay

### LoginScreen.swift

This screen currently shows a returning-user greeting (per Phase A spec). The handoff `SignupMethodScreen` is a phone/email entry screen. Since VitaminG has no backend auth, `LoginScreen` remains the returning-user screen (per the approved Phase A decision). **No change needed here** — do not add phone input.

### NameScreen.swift

**Minor changes:**
- Headline: `"What should we call you?"` → `"What should\nwe call you?"` (line break preserved)
- Step bar: confirm `StepBarView(current: 0, total: 4)` shows step 1 of 4

### MotivationCategoryScreen.swift

**Structural rework to match handoff `MotivationScreen`:**
- Headline: `"What do you\nwant to grow?"` (serif 42pt, clay, weight 400)
- Subtext: `"Pick what matters most to you right now."` (14pt, muted)
- Grid: `LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10)`
- Each cell: `padding("16px 14px")`, 14pt corner radius, terra background/border when selected (`terraLight` bg, `terra` 2pt border), white otherwise (`warmWhite` bg, `sandMid` 2pt border)
- Cell content: icon (18pt, terra when selected / muted unselected) + label (13pt, 600 when selected / 400 unselected, clay/muted)
- Category list + icons:

  | Label | Icon |
  |-------|------|
  | Health & Fitness | `◎` |
  | Mindfulness | `◇` |
  | Career | `△` |
  | Relationships | `◈` |
  | Learning | `◉` |
  | Nutrition | `◑` |
  | Creativity | `◐` |
  | Morning Habits | `☀` |

- Step bar: `StepBarView(current: 1, total: 4)`
- CTA button: disabled when nothing selected, enabled otherwise

### NotificationOnboardingScreen.swift

**Major rework to match handoff `NotifScreen`:**

Background: `VGTheme.clay` fullscreen with `RadialGradient(colors: [VGTheme.clayMid, VGTheme.clay], center: UnitPoint(x: 0.5, y: 0.3))` — already done.

**Add frosted notification preview card** (above the hero text):
```
RoundedRectangle(18pt)
  .fill(.ultraThinMaterial) + Color.white.opacity(0.11)
  .overlay(stroke: Color.white.opacity(0.14), 1pt)
```
Card content:
- Row: app icon thumbnail (34×34, 9pt corner, terra fill with "G") + name "Vitamin G" 13pt 600 sand + time "now" 11pt muted
- Serif title 19pt sand: "Good morning, [firstName] ☀️"
- Body 13pt rgba(242,232,217,0.7): "Day 12 of your Summer Body Challenge…"
- Progress row: small `ProgressRingView(pct: 0.72, size: 34, stroke: 4)` + inline bar + "72%" label

**Hero text block** (below card):
- Serif 42pt sand: `"Stay on track,\n"` + italic terraSoft: `"every day."`
- Body 14pt 300 muted: "One daily nudge at the time you choose…"

**Buttons:**
- Primary: `"Allow notifications"` — sand fill, clay text (light button on dark bg)
- Ghost: `"Maybe later"` — rgba(242,232,217,0.6) text, no border

### CommunityGoalOnboardingScreen.swift

**Rework to match handoff `CommunityGoalScreen`:**

Headline: serif 42pt clay with italic terra emphasis: `"Your first"` / `"challenge"` (italic terra) / `"awaits."`  
Subtext: "Join thousands already working toward it. You're never doing this alone."

**Challenge card** (full-width, 20pt corner, soft shadow):
- Header section: `LinearGradient(colors: [terraSoft, terra, Color(red:0.627,green:0.322,blue:0.176)])`, 22×20pt padding
  - Label: 10pt uppercase warmWhite.opacity(0.7) "☀️ Community Challenge"
  - Title: serif 22pt 500 warmWhite "90-Day Summer\nBody Challenge"
  - Subtitle: 12pt warmWhite.opacity(0.75) "Daily workouts · Nutrition plans · Accountability check-ins"
- Body section: warmWhite background, 16×20pt padding
  - Stat row: "4,821 Joined" | "Day 1 Starts" | "90 Days" — serif 22pt clay + 11pt uppercase muted labels
  - Progress bar: 6pt height, sandMid track, terra fill at 2%
  - Avatar stack: 4 circles (26pt, colored, overlapping -8pt) + "+4,817 others joined" 12pt muted

Buttons: `"Join the challenge"` primary + `"Set my own goal first"` ghost

---

## Phase 2 — Home & Goals

### HomeView.swift

**Header section:**
- Greeting: `"\(greeting) ☀️"` 13pt muted, letterSpacing 0.04em
- User name below greeting: serif 26pt sand (currently shows "Vitamin G" — use `@AppStorage("vg_onboardingName")` or from profile)
- Streak badge: replace `Image(systemName: "flame.fill")` with `Text("◉")` (13pt, terraGlow in dark / terraSoft in light, with glow shadow in dark mode), `"\(streak)"` count, `"day streak"` label
- Notification bell: `Image(systemName: "bell.fill")` button, 36×36pt circle, `VGTheme.surface` bg, `VGTheme.separator` border, 1pt unread dot (`VGTheme.accentTerra`, 6pt, top-right)

**Quote section ("Today's dose"):**
- Add label above quote: `"TODAY'S DOSE"` 9pt 600 muted, letter-spacing 0.14em, uppercase, marginBottom 6pt
- Quote: serif italic 16pt `VGTheme.textSecondary`, line-height 1.55
- Left border: 2pt `VGTheme.accentTerra`
- Background: `VGTheme.surface`

**Primary goal card:**
- Corner glow: `RadialGradient` in top-right corner, `accentTerra.opacity(0.18)`, 180pt circle
- `ProgressRingView(pct:, size: 104, stroke: 8, color: VGTheme.accentTerra, label: "\(pct)%", sublabel: "Day \(day)")` with glow in dark
- Goal title: serif 21pt medium `VGTheme.textPrimary`
- Status row: "25 days remaining · On track" 12pt muted

**Secondary goal rows:**
- Each row: `ProgressRingView(pct:, size: 46, stroke: 4, color: tierColor, label: "\(pct)%")` — replace the old non-ring view
- Tier color mapping: `.lifeGoal` → `accentTerra`, `.longTerm` → `accentGold`, `.shortTerm` → `accentSage`, `.immediate` → `accentPurple`
- Tag text: frequency + "· Today" or "· N days left" using `VGTheme.accentXxx` for the deadline part

### GoalListView.swift

**Background:** `VGTheme.background` (adaptive, replaces hardcoded `VGTheme.sandLight`)

**Inline header** (inside scroll view, not navigation bar):
```swift
HStack {
    Text("My Goals")
        .font(VGTheme.serif(28))
        .foregroundStyle(VGTheme.textPrimary)
    Spacer()
    Button("+ New goal") { showingAddGoal = true }
        .font(.system(size: 12, weight: .semibold))
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(VGTheme.accentTerra)
        .foregroundStyle(VGTheme.background)
        .clipShape(Capsule())
        .shadow(color: VGTheme.accentTerra.opacity(0.45), radius: 8)  // glow in dark
}
.padding(.horizontal, 24).padding(.top, 8)  // extra top padding handled by NavigationStack safe area
```
Hide system navigation title: `.navigationBarTitleDisplayMode(.inline)` + `.toolbar(.hidden, for: .navigationBar)`

**Primary challenge hero card:** matches the handoff `GoalTrackerScreen` primary section — background `VGTheme.surface`, 18pt corner radius, 20pt padding, `ProgressRingView` + 7-day bar chart. Taps to `AppRoute.challengeDetail(userChallenge)`. (Keeps existing `primaryChallenge` data binding.)

**Goal rows:** use `ProgressRingView` with tier colors as defined above. Card background: `VGTheme.surface`. Border: `VGTheme.separator`. Corner radius: 14pt. Remove List chrome — use `LazyVStack` inside `ScrollView`.

---

## Phase 3 — Community, Explore, Profile

### CommunityTabView + CommunityFeedView

**"Community" header:** serif 28pt `VGTheme.textPrimary` + 12pt muted subtext "See what others are working on"

**Stories row** (horizontal scroll, `ScrollView(.horizontal, showsIndicators: false)`):
- "Your story" cell: 54pt circle, dashed `accentTerra` 2pt border, `+` in terra
- User cells: 54pt circle, `VGTheme.surface` fill, 2pt solid border in user accent color, initial letter (serif 20pt), 13×13pt sageGlow online dot (bottom-right, inkDeep border)

**Post cards** (`VGTheme.surface` bg, `VGTheme.separator` border, 18pt corner):
- Header: 38pt avatar circle (colored, glow shadow) + name 13.5pt 600 + handle 11pt muted + time ago + `ProgressRingView(size: 36, stroke: 3, glow: false)`
- Post text: 13.5pt `VGTheme.textSecondary`, lineSpacing 1.6, `Text(...).fixedSize(horizontal: false, vertical: true)`
- Reaction bar: `♡` terra + `◉` gold + `△` sage (each with count) + "Reply" trailing

### ChallengeDiscoveryView (rename conceptually to "Explore")

Tab label: `"Explore"` (rename from "Challenges"), icon: `magnifyingglass` SF Symbol

**Layout:**
- Header: serif 28pt "Explore" + 12pt muted "Need a nudge?"
- Subtext: 13pt muted "Tap any goal to add it — no planning needed."
- Search bar: `VGTheme.surface` bg, `VGTheme.separator` border, 12pt corner, magnifyingglass icon, placeholder 13.5pt `VGTheme.textFaint` "Search goals…"
- Featured challenge banner: `LinearGradient(accentTerra.opacity(0.18), accentTerra.opacity(0.05))`, corner 18pt, 1pt `accentTerra.opacity(0.35)` border, `boxShadow: accentTerra.opacity(0.15)` — title, "4,821 people" subtext, "Join challenge" button
- Category sections: `SectionLabel` (10pt 600 uppercase muted) with icon glyph + goal list rows

**Goal rows in explore:** `VGTheme.surface` bg, dot accent, title + duration/level row, `"+ Add"` pill button (`accentTerra.opacity(0.14)` bg, `accentTerra.opacity(0.3)` border, terra label)

### ProfileView.swift

**Background:** `VGTheme.background` (replace hardcoded `sandLight`)

**Hero section** (matches `ProfileScreen` / `ProfileDark`):
- bg: adaptive gradient from `VGTheme.backgroundSecondary`
- Corner glow: radial terra.opacity(0.20), 240pt, top-right
- "Today's dose" mini quote card: `VGTheme.surface`, left 2pt `accentTerra` border
- Avatar: 76pt circle, terra gradient fill, 3pt inkDeep/sandLight border, glow shadow in dark
- Name: serif 22pt `VGTheme.textPrimary`
- Handle + location: 12pt `VGTheme.textMuted`
- Joined date: 11.5pt `VGTheme.textFaint`
- Edit button: `VGTheme.surface` bg, `VGTheme.separator2` border, 12pt 500
- Bio: 12.5pt `VGTheme.textSecondary`
- Stat row: 4 cells (Streak / Goals / Check-ins / Reactions), dividers `VGTheme.separator`

**Mood picker** (new section):
```swift
// 5 options: Amazing ◎ / Good ○ / Okay ◐ / Low ◑ / Push ◉
// Active option: accentTerra.opacity(0.16) bg, accentTerra.opacity(0.4) border, glow shadow in dark
// Stored in @AppStorage("vg_todayMood") as Int (0–4)
```

**Tabs:** Goals / Badges / Activity (already exist — visual update only)

**Activity heatmap tab** (new `ProfileTab.activity` case):
- 10-week grid (10 columns × 7 rows), 22×22pt cells, 5pt corner radius
- 3 fill levels: empty `VGTheme.surface`, partial `accentTerra.opacity(0.30)`, full `VGTheme.accentTerra`
- In dark mode: full cells get `shadow(color: accentTerra.opacity(0.45), radius: 3)`
- Legend: "Less / More" with 3 sample cells
- Data: count `CompletionEvent`s per calendar day

---

## Phase 4 — Custom Tab Bar + Dark Mode Polish

### Custom Tab Bar

**Why custom:** System `TabView.tabItem` cannot render an active-line indicator above the icon or a glow drop-shadow on the active icon. The design requires both.

**Implementation:**

1. In `ContentView`, remove `.tabItem {}` modifiers. Replace `TabView` host with a `ZStack(alignment: .bottom)` containing the page content plus `VGTabBar`.

2. `VGTabBar` — new file `Views/Components/VGTabBar.swift`:

```swift
struct VGTabBar: View {
    @Binding var selection: Int
    // tabs: [(label: String, icon: String, activeIcon: String)]
    // using SF Symbol names for icons
}
```

Tab definitions matching handoff (5 tabs):

| # | Label | SF Symbol |
|---|-------|-----------|
| 0 | Home | `house` |
| 1 | Goals | `circle.circle` |
| 2 | Community | `person.2` |
| 3 | Explore | `magnifyingglass` |
| 4 | Me | `person` |

Visual spec per tab item:
- Container: `flex: 1`, vertical stack, icon + label, no default tint
- Active state: `accentTerra` color, `drop-shadow(accentTerra.opacity(0.6))` filter on icon, active-line `Rectangle().frame(height: 2)` at top of tab bar with `accentTerra` fill + `shadow(color: accentTerra, radius: 5)`
- Inactive state: `VGTheme.textMuted` color, no glow
- Label: 10pt, 600 when active / 400 when inactive, letter-spacing 0.4pt
- Tab bar background: `VGTheme.inkDeep.opacity(0.85)` in dark / `warmWhite` in light, `ultraThinMaterial` blur, top border `VGTheme.separator`
- Bottom padding: safe area bottom inset (use `safeAreaInsets.bottom` via `GeometryReader` or environment)

3. Pages are managed by keeping `TabView(selection: $selectedTab)` as the content host with `.toolbar(.hidden, for: .tabBar)` to suppress the system tab bar. `VGTabBar` is attached as `.safeAreaInset(edge: .bottom) { VGTabBar(selection: $selectedTab) }` on the `TabView` — this correctly pushes scroll content above the custom bar without `ZStack` z-fighting.

4. Remove all `.tabItem` labels and system chrome.

### Dark mode polish (apply throughout all phases)

**Views that hardcode light-mode colors — replace with adaptive tokens:**

| File | Find | Replace |
|------|------|---------|
| `GoalListView.swift` | `.background(VGTheme.sandLight)` | `.background(VGTheme.background)` |
| `ProfileView.swift` | `.background(VGTheme.sandLight)` | `.background(VGTheme.background)` |
| `GoalDetailView.swift` | Any `sandLight` / `warmWhite` direct refs | `VGTheme.background` / `VGTheme.surface` |
| `SettingsView.swift` | `sandLight` refs | `VGTheme.background` |
| Goal rows in `GoalListView` | `warmWhite` card bg | `VGTheme.surface` |

**Glow shadows in dark mode only:**
```swift
// Pattern — apply to accent-colored elements
.shadow(color: isDark ? VGTheme.accentTerra.opacity(0.45) : .clear, radius: 8)
```
Use `@Environment(\.colorScheme) var colorScheme` in views that need it.

---

## Navigation / Functionality Constraints

- All `AppRoute` navigation destinations remain unchanged.
- `TabView` page management preserves existing navigation stacks per tab.
- `VGTabBar` selection binding replaces `TabView`'s internal selection; deep-link sheet triggers from `AppRouter` still work.
- No SwiftData model changes in this spec.
- No new `AppStorage` keys except `vg_todayMood: Int` for the mood picker.
- Onboarding flow routing (`OnboardingView`) unchanged — only visual layout of screens updates.

---

## Testing

- Visual regression: build and run in light and dark mode on iPhone 15 Pro simulator for each phase before committing.
- Functional regression: navigate all tabs, create a goal, complete a check-in, view profile — ensure no crashes or data loss.
- Onboarding: run through the full flow (new user path and returning user path) after Phase 1 changes.

---

## File Change Map

### Phase 1
| File | Action |
|------|--------|
| `Views/Onboarding/WelcomeScreen.swift` | Modify — button labels |
| `Views/Onboarding/MotivationCategoryScreen.swift` | Modify — grid layout + icon set |
| `Views/Onboarding/NotificationOnboardingScreen.swift` | Modify — frosted card + hero text |
| `Views/Onboarding/CommunityGoalOnboardingScreen.swift` | Modify — challenge card layout |
| `Views/Components/VGCapsule.swift` | Create — extract VitaminTablet from WelcomeScreen |

### Phase 2
| File | Action |
|------|--------|
| `Views/HomeView.swift` | Modify — header, quote, goal rows |
| `Views/GoalListView.swift` | Modify — background, header, hero card, goal rows |
| `Views/Components/ProgressRingView.swift` | Modify — glow + sublabel params |

### Phase 3
| File | Action |
|------|--------|
| `Views/CommunityTabView.swift` | Modify — header + stories row |
| `Views/CommunityFeedView.swift` | Modify — post cards |
| `Views/ChallengeDiscoveryView.swift` | Modify — search, featured banner, goal rows |
| `Views/ProfileView.swift` | Modify — hero, mood picker, activity tab |

### Phase 4
| File | Action |
|------|--------|
| `Views/Components/VGTabBar.swift` | Create — custom tab bar |
| `Views/ContentView.swift` | Modify — replace tabItem with VGTabBar |
| `Views/GoalDetailView.swift` | Modify — dark mode adaptive colors |
| `Views/SettingsView.swift` | Modify — dark mode adaptive colors |

All paths relative to `Desktop/AI/Vitamin G/VitaminG/VitaminG/`.
