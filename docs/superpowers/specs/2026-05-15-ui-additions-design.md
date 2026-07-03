# Vitamin G — UI Additions & Fixes Design

**Date:** 2026-05-15
**Branch:** main (new branch: feat/ui-additions)
**Source designs:** `App additions.zip` — Vitamin G Home.html, Explore.html, Community Goals.html, Signup.html
**Approved by user:** 2026-05-15

---

## Overview

17 implementation units across 4 tabs. Combines 8 bug-fix/polish items with new sections from the Claude Design handoff bundle. All existing functional behaviour (SwiftData, CloudKit, navigation, notifications) is preserved. Visual layer plus new views.

---

## Architecture decisions

1. **HomeView** — already exists at `Views/HomeView.swift`. Add Quick Stats row + Stay Close section + Today's check-in CTA at the bottom. No structural change to existing sections.
2. **ChallengeDiscoveryView** — full redesign. Replace the flat category list + featured section with the Dispenser / Mood Scanner / Trending / Vitamin Shelf layout from Explore.html. Preserve `CustomChallengeBuilderView` sheet and `ChallengeCardView` as Trending row items.
3. **CommunityGoalsLandingView** — new file. Accessed via new `AppRoute.communityGoals(UserChallenge)` case. CommunityTabView card tap routes there. Existing `CommunityFeedView` (text posts) remains but is accessed from inside the landing page.
4. **Google Sign-In** — GoogleSignIn-iOS SPM required. Add package. Custom-styled button (white pill, Google `G` logo). If auth fails or package unavailable, button shows toast "Google Sign-In coming soon."
5. **Photo wall** — uses `PhotosUI.PhotosPicker` (zero dependencies, iOS 16+). Camera source uses `PHPickerFilter`. For camera specifically, add `NSCameraUsageDescription` to Info.plist and request `AVCaptureDevice` permission before presenting.
6. **Community progress ring** — collective check-in count is a CloudKit aggregate. For now use local `userChallenge.totalCheckIns` as numerator and `template.durationDays` as denominator. Full CloudKit aggregate is post-MVP.

---

## Part A — HomeView additions

**File:** `Views/HomeView.swift`

### A1. Today's check-in CTA
Below `primaryGoalCard`, add a gradient terra button "Log your workout →" (or primary goal's title if set). Taps `AppRoute.goalDetail(primaryGoal)` via `NavigationLink`. Only shown when `primaryGoal != nil` and today not already checked in.

### A2. Quick stats row
Three-column grid below CTA:
- Active goals count (`goals.filter { !$0.isCompleted }.count`)
- Total check-in events (`completionEvents.count` — add `@Query` for CompletionEvent)
- Badges earned (`userChallenges` with `earnedBadgeSymbolsJSON` count)

Layout: `HStack` of three `statCell` views (already implemented as a private func in HomeView — reuse it).

### A3. Stay Close section
Below stats row. Section title "Stay close" + subtitle "We're a small team and we'd love to hear from you."

Three cards in a horizontal `ScrollView`:
- **About Us** → `NavigationLink` to new `AboutUsView`
- **Contact Us** → `Button` that calls `UIApplication.shared.open(URL(string: "mailto:hello@vitamingapp.com")!)`
- **FAQ** → `NavigationLink` to new `FAQView`

Card anatomy: tinted disc background, icon chip (44×44, `RoundedRectangle(cornerRadius: 14)`), title (serif 18), subtitle (12), "Open →" label in accent color. Width 148, padding 16, cornerRadius 18.

Navigation: add `AboutUsView` and `FAQView` as `navigationDestination` in `ContentView` tab 0's `NavigationStack`. No new `AppRoute` case needed — use direct `NavigationLink(destination:)`.

### A4. New files: AboutUsView, FAQView
- **AboutUsView** — static scroll: terra gradient header, serif title "About Vitamin G", founder note paragraphs. Close/back via navigation bar.
- **FAQView** — `List` of accordion rows. Each row: question (bold) + answer (expandable with `DisclosureGroup`). 8–10 static Q&As. Both files in `Views/Support/`.

---

## Part B — ChallengeDiscoveryView redesign (Explore tab)

**File:** `Views/ChallengeDiscoveryView.swift`

### B1. Featured padding fix
`LazyVStack` in `featuredSection` gets `.padding(.horizontal, 16)`. One-line fix.

### B2. Layout restructure
Replace the current `VStack(alignment: .leading, spacing: 24)` body with:
1. Dispenser section
2. Mood Scanner
3. Trending row (if `templates.filter { $0.isFeatured }` non-empty)
4. Vitamin Shelf grid
5. Mood-filtered list (when mood != "all")

Remove: old `catalogueSection` flat list layout, old `buildYourOwnButton` bottom position.

### B3. Vitamin Dispenser
New private `struct VitaminDispenserView: View`. State: `@State var dispensedGoal: GoalCatalogueItem?`, `@State var isShaking: Bool`.

Bottle: `VGCapsule` already exists in `Views/Components/VGCapsule.swift`. Use a ZStack with a rounded-rect body SVG to simulate the bottle shape, or replicate the SVG as a SwiftUI `Path`. Keep it simple — `RoundedRectangle` body with a label band overlay is sufficient.

Shake gesture: `.gesture(DragGesture(...).onEnded { _ in dispense() })`. Also a tap button "Give it a shake."

`dispense()` picks random `GoalCatalogueItem` from `ChallengeLibrary.categories` filtered by active mood. Shows the goal card with "Shake again" and "Add to my goals" buttons.

"Add to my goals" → calls `goalVM.addGoal(...)` → on success, navigate to new goal via `path.append(AppRoute.goalDetail(newGoal))`. Requires `@Binding var path: [AppRoute]` passed in from `ContentView`'s NavigationStack, or use a `@State private var navigationPath` local to the tab.

### B4. Mood Scanner
New private `struct MoodScannerView: View`. Horizontal `ScrollView` of pill `Button`s. Moods: All, Tired, Stuck, Hopeful, Fired up, Soft. Active pill: `VGTheme.accentTerra` fill, white text. Inactive: `VGTheme.surface` fill, `VGTheme.textPrimary`.

Binding: `@Binding var selectedMood: String`. Passed from `ChallengeDiscoveryView`.

### B5. Trending challenges row
New private `struct TrendingChallengesRow: View`. Horizontal `ScrollView` of `TrendingChallengeCard` items. Data: `templates.filter { $0.isFeatured }` — uses existing `ChallengeCardView` data, restyled as gradient cards (accent color background, white text, `ProgressRing` overlay, participant count).

Tap → `NavigationLink(value: AppRoute.challengeDetail(userChallenge))` if joined, or calls `joinChallenge` then navigates.

### B6. Vitamin Shelf grid
New private `struct VitaminShelfGrid: View`. 2-column `LazyVGrid`. Items from `ChallengeLibrary.categories`. Each cell: category emoji, name, goal count, expandable inline list of 3 goals with `+ ADD` buttons.

Expansion: `@State private var expandedCategory: String?`. Expanded cell spans both columns via `GridItem(.flexible())` swap — or simpler: show expanded cell inline as a `VStack` within the `ForEach` by using a conditional full-width card after the grid row.

`+ ADD` in shelf → same navigate-after-add behaviour as B3.

### B7. Move Build a goal button
Insert `buildYourOwnButton` directly below `MoodScannerView`, above the `VitaminShelfGrid`. Remove from bottom of scroll.

### B8. Navigate after + Add
`GoalViewModel.addGoal` currently returns `Void`. Change to `@discardableResult func addGoal(...) throws -> Goal`. After add, `path.append(AppRoute.goalDetail(newGoal))`.

**Navigation path wiring:** `ChallengeDiscoveryView` receives `@Binding var navigationPath: NavigationPath` (or uses environment). `ContentView` tab 3 wraps it in a `NavigationStack(path:)` and passes the binding down. Add `AppRoute` destinations to that stack.

---

## Part C — Community Goals Landing Page

**File:** `Views/CommunityGoalsLandingView.swift` (new)
**Route:** New `AppRoute.communityGoals(UserChallenge)` case added to `AppRoute.swift`

### C1. Community tab cards redesign
`CommunityChallengeCellView` in `CommunityTabView.swift`:
- Height: increase to ~100pt (add `.frame(minHeight: 100)`)
- Left accent bar → replace with a 56×56 rounded square showing `template.iconName` SF symbol (size 28, accent color fill)
- Add `ProgressRingView` (size 48, stroke 4) right-aligned showing `totalCheckIns / durationDays` progress
- Card tap → `AppRoute.communityGoals(challenge)` not `.communityFeed`

### C2. Landing page structure
```
NavigationStack presented from CommunityTabView

VStack:
  Header: "☀️ 90-Day Summer Body" label + serif "We're X% of the way there." + member count line
  Collective progress card:
    ProgressRingView (200px, terra) — pct = totalCheckIns / durationDays
    Stat strip: Joined (communitySize) · Day (currentDayNumber) · Days Left
  Photo wall section:
    "Today's check-ins" heading + dot indicators
    Featured large photo (auto-cycles, aspect ratio 4:5, 354pt wide, gradient placeholder)
    Thumbnail strip (90pt tiles + AddTile)
  Live ticker (static seed data — no CloudKit stream yet)
  Leaderboard section ("Leading the pack") — local top participants from check-in data
  Sticky bottom: "Share today's check-in" CTA → PhotosPicker sheet → on confirm, posts photo via CommunityService
```

### C3. Photo sharing (check-in photo)
Uses `PhotosUI.PhotosPicker` (iOS 16+). On selection, compress to max 800KB JPEG, post to CloudKit as `CKAsset` on a new `CheckInPhoto` record type. `CommunityService` gains `func postCheckInPhoto(_:challengeCategory:)` method. `NSPhotoLibraryUsageDescription` already needed; add `NSCameraUsageDescription`.

### C4. AppRoute update
Add `case communityGoals(UserChallenge)` to `AppRoute.swift`. Wire destination in both `ContentView` tab 2 NavigationStack and the Goals tab NavigationStack.

---

## Part D — ProfileView: mood picker hide + camera fix

### D1. Mood picker hide after log (Feature 5)
In `ProfileView.heroBanner`, wrap the mood picker `VStack` in `if todayMood == nil { ... }`. When `todayMood != nil`, replace with a single-line "Feeling: [mood label]" badge showing the logged mood and a small "change" link that un-hides the picker.

### D2. Camera permission + photo picker (Feature 7)
The camera badge `ZStack` (line 106–124 `ProfileView.swift`) is currently non-interactive.

Add to `ProfileView`:
```swift
@State private var showingPhotoPicker = false
@State private var cameraPermissionDenied = false
```

Wrap the `ZStack` in a `Button { requestCameraAndShow() }`.

`requestCameraAndShow()`:
1. Check `AVCaptureDevice.authorizationStatus(for: .video)`
2. If `.notDetermined` → `requestAccess` → on granted show `PhotosPicker`
3. If `.authorized` → show `PhotosPicker` with `photoLibrary` source (or camera via `UIImagePickerController`)
4. If `.denied` → set `cameraPermissionDenied = true` → show alert linking to Settings

On photo selection: compress to max 200KB JPEG, write `Data` to `profile.photoData`, save context.

Add `NSCameraUsageDescription` to `Info.plist`: "Vitamin G uses your camera to update your profile photo."

---

## Part E — WelcomeScreen: Sign in with Apple + Google

**File:** `Views/Onboarding/WelcomeScreen.swift`

### E1. Layout change
Current bottom VStack has 2 buttons. Replace with:
1. "Create account" (terra fill) — unchanged
2. Sign in with Apple — `SignInWithAppleButton(.signIn, onRequest:, onCompletion:)` from `AuthenticationServices`. Black fill, white text, rounded rect to match app style.
3. Sign in with Google — custom `GoogleSignInButton` styled as white pill with inline Google `G` SVG. Requires `GoogleSignIn` SPM package.
4. "I'll set this up later" ghost link — unchanged, moved below the auth buttons

### E2. Sign in with Apple
`AuthenticationServices` (built-in). On completion, save `userIdentifier` to `UserDefaults`. If user previously onboarded (name stored), skip to main app via `onSkip()`. Otherwise push to `.name` step.

### E3. Sign in with Google — stubbed (no SDK)
**Decision:** No GoogleSignIn-iOS package. The button is rendered as a white pill with inline Google `G` SVG but tapping it shows an alert: "Google Sign-In is coming soon." Zero new dependencies. Swap in the real SDK post-launch when needed.

---

## Files to create

| File | Purpose |
|------|---------|
| `Views/Support/AboutUsView.swift` | About Us landing page |
| `Views/Support/FAQView.swift` | FAQ accordion |
| `Views/CommunityGoalsLandingView.swift` | Community challenge landing |

## Files to modify

| File | Changes |
|------|---------|
| `Views/HomeView.swift` | Add check-in CTA, quick stats, Stay Close section |
| `Views/ChallengeDiscoveryView.swift` | Full redesign per Part B |
| `Views/CommunityTabView.swift` | Larger cards + new route |
| `Views/ProfileView.swift` | Mood picker hide, camera button wired |
| `Views/Onboarding/WelcomeScreen.swift` | Apple + Google auth buttons |
| `Navigation/AppRoute.swift` | Add `.communityGoals` case |
| `Views/ContentView.swift` | Wire new routes, nav path for Explore tab |
| `ViewModels/GoalViewModel.swift` | `addGoal` returns `Goal` |
| `Services/CommunityService.swift` | `postCheckInPhoto` method |
| `WaterRingToss/Info.plist` | Camera + photo usage strings (VitaminG target) |

---

## Out of scope (post-MVP)

- CloudKit aggregate for collective progress ring (use local data for now)
- Real-time live ticker from CloudKit (use seed data)
- Leaderboard from CloudKit (use local participants)
- Google Sign-In real SDK (stubbed button ships now; swap in GoogleSignIn-iOS post-launch)
