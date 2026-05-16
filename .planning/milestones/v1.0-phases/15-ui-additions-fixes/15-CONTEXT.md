# Phase 15: UI Additions & Fixes — Context

**Gathered:** 2026-05-15
**Status:** Ready for planning
**Source:** PRD Express Path (`VitaminG/docs/superpowers/specs/2026-05-15-ui-additions-design.md`)

<domain>
## Phase Boundary

17+ implementation units across 4 tabs (Home, Explore/Challenges, Community, Profile) plus WelcomeScreen. Combines bug-fix/polish items with new sections from the Claude Design handoff bundle. All existing functional behaviour (SwiftData, CloudKit, navigation, notifications) is preserved — visual layer plus new views only. No schema changes required.

</domain>

<decisions>
## Implementation Decisions

### Architecture

- **No new SwiftData schema migration required** — all changes are UI layer only; no new models or model modifications
- **No new SPM dependencies** — Google Sign-In is stubbed (button shows "coming soon" alert); `AuthenticationServices` and `PhotosUI` are built-in
- **MVVM strictly enforced** — all new logic lives in ViewModels, not Views; no business logic in Views per CLAUDE.md
- **`NSCameraUsageDescription` added to Info.plist** — required for D2 (camera) and C3 (photo sharing)

### Part A — HomeView Additions

- **A1: Check-in CTA** — gradient terra button "Log your workout →" (or primary goal title) placed below `primaryGoalCard`; conditionally shown when `primaryGoal != nil` AND today not already checked in; taps `AppRoute.goalDetail(primaryGoal)` via `NavigationLink`
- **A2: Quick Stats Row** — three-column `HStack` of `statCell` views (already a private func in HomeView — reuse it): active goals count (`goals.filter { !$0.isCompleted }.count`), total check-in events (`completionEvents.count` with new `@Query` for CompletionEvent), badges earned (`userChallenges` with `earnedBadgeSymbolsJSON` count)
- **A3: Stay Close section** — section title "Stay close" + subtitle + horizontal `ScrollView` of 3 cards: About Us (`NavigationLink` to `AboutUsView`), Contact Us (`Button` opening `mailto:hello@vitamingapp.com`), FAQ (`NavigationLink` to `FAQView`); card anatomy: 148pt wide, 16pt padding, 18pt cornerRadius, 44×44 icon chip with `RoundedRectangle(cornerRadius: 14)`, serif 18 title, 12pt subtitle, "Open →" in accent color
- **A4: New files** — `AboutUsView` (terra gradient header + serif title + founder paragraphs) and `FAQView` (DisclosureGroup accordion, 8–10 static Q&As) in `Views/Support/`; added as `navigationDestination` in ContentView tab 0's NavigationStack using direct `NavigationLink(destination:)` — no new AppRoute case

### Part B — ChallengeDiscoveryView Redesign

- **B1: Featured padding fix** — `.padding(.horizontal, 16)` on `LazyVStack` in `featuredSection` — one-line fix
- **B2: Layout restructure** — replace current body with: Dispenser → Mood Scanner → Trending row → Vitamin Shelf grid → Mood-filtered list (when mood != "all"); remove old `catalogueSection` flat list and old `buildYourOwnButton` bottom position
- **B3: VitaminDispenserView** — private struct; state `@State var dispensedGoal: GoalCatalogueItem?` + `@State var isShaking: Bool`; bottle rendered as simple `RoundedRectangle` with label band overlay (no third-party SVG); shake via `DragGesture().onEnded`; `dispense()` picks random `GoalCatalogueItem` filtered by active mood; shows result card with "Shake again" + "Add to my goals" buttons; "Add to my goals" calls `goalVM.addGoal(...)` then navigates to new goal via path append
- **B4: MoodScannerView** — private struct; horizontal `ScrollView` of pill `Button`s; moods: All / Tired / Stuck / Hopeful / Fired up / Soft; active pill uses `VGTheme.accentTerra` fill + white text; inactive uses `VGTheme.surface` fill + `VGTheme.textPrimary`; binding `@Binding var selectedMood: String`
- **B5: TrendingChallengesRow** — private struct; horizontal `ScrollView` of restyled `ChallengeCardView` items from `templates.filter { $0.isFeatured }`; tap → `NavigationLink(value: AppRoute.challengeDetail(userChallenge))` if joined, else calls `joinChallenge` then navigates
- **B6: VitaminShelfGrid** — private struct; 2-column `LazyVGrid` from `ChallengeLibrary.categories`; each cell: category emoji + name + goal count + expandable list of 3 goals with `+ ADD` buttons; expansion state `@State private var expandedCategory: String?`; expanded cell shown full-width inline as conditional `VStack` after grid row
- **B7: Build-Your-Own button moved** — `buildYourOwnButton` inserted directly below `MoodScannerView`, above `VitaminShelfGrid`
- **B8: Navigate after + Add** — `GoalViewModel.addGoal` signature changes to `@discardableResult func addGoal(...) throws -> Goal`; `ChallengeDiscoveryView` receives `@Binding var navigationPath: NavigationPath` from ContentView tab 3's `NavigationStack(path:)`

### Part C — Community Goals Landing Page

- **C1: CommunityChallengeCellView redesign** — in `CommunityTabView.swift`; height increased to ~100pt (`.frame(minHeight: 100)`); left accent bar replaced with 56×56 rounded square SF symbol (size 28, accent color fill); `ProgressRingView` (size 48, stroke 4) right-aligned showing `totalCheckIns / durationDays`; card tap routes to `AppRoute.communityGoals(challenge)` not `.communityFeed`
- **C2: CommunityGoalsLandingView** — new file `Views/CommunityGoalsLandingView.swift`; structure: header ("☀️ [title]" + "We're X% of the way there." + member count), collective progress card (200px `ProgressRingView` + stat strip: Joined · Day · Days Left), photo wall ("Today's check-ins" + featured large photo 4:5 aspect 354pt + thumbnail strip + AddTile), live ticker (static seed data, no CloudKit stream), leaderboard (local top participants), sticky bottom CTA "Share today's check-in" → `PhotosPicker` sheet
- **C3: Photo sharing** — `PhotosUI.PhotosPicker` (iOS 16+); on selection, compress to max 800KB JPEG, post to CloudKit as `CKAsset` on new `CheckInPhoto` record type; `CommunityService` gains `func postCheckInPhoto(_:challengeCategory:)` method; `NSPhotoLibraryUsageDescription` already in place; add `NSCameraUsageDescription`
- **C4: AppRoute update** — add `case communityGoals(UserChallenge)` to `AppRoute.swift`; wire destination in ContentView tab 2 NavigationStack and Goals tab NavigationStack

### Part D — ProfileView Fixes

- **D1: Mood picker hide after log** — in `ProfileView.heroBanner`, wrap mood picker `VStack` in `if todayMood == nil { ... }`; when `todayMood != nil`, show single-line "Feeling: [mood label]" badge + small "change" link that re-shows the picker
- **D2: Camera permission + photo picker** — `ProfileView` gains `@State private var showingPhotoPicker = false` and `@State private var cameraPermissionDenied = false`; camera badge `ZStack` wrapped in a `Button { requestCameraAndShow() }`; `requestCameraAndShow()` checks `AVCaptureDevice.authorizationStatus(for: .video)` → request → show `PhotosPicker` (or show settings alert if denied); on selection, compress to max 200KB JPEG, write `Data` to `profile.photoData`, save context; add `NSCameraUsageDescription` to Info.plist: "Vitamin G uses your camera to update your profile photo."

### Part E — WelcomeScreen Auth Buttons

- **E1: Layout** — current 2-button bottom VStack replaced with: "Create account" (terra fill, unchanged) → `SignInWithAppleButton(.signIn, onRequest:, onCompletion:)` (black fill, rounded rect style) → Google stub button (white pill + inline Google G SVG rendered in SwiftUI, no SPM) → "I'll set this up later" ghost link (moved below auth buttons)
- **E2: Sign in with Apple** — `AuthenticationServices` (built-in); on completion, save `userIdentifier` to `UserDefaults`; if user previously onboarded (name stored), call `onSkip()` to go to main app; otherwise push to `.name` onboarding step
- **E3: Google stub** — no `GoogleSignIn-iOS` package; button is white pill with inline SwiftUI `G` logo; tap shows `Alert`: "Google Sign-In is coming soon."; swap in real SDK post-launch when needed

### Username Field (added 2026-05-15)

- **UIADD-07: Username added to UserProfile** — `UserProfile` gains `var username: String?`; requires SchemaV6 migration (V5 → V6) adding the field with `nil` default on existing records; displayed alongside display name in ProfileView and ProfileEditSheet; editable in ProfileEditSheet; validation: alphanumeric + underscores only, lowercase, max 30 characters; shown as "@username" format where displayed; also surfaced in WelcomeScreen sign-up flow as an optional step after name entry (or added to ProfileEditSheet only — planner's discretion on entry point)
- **Username in community contexts** — where community posts/cards show the author, show `@username` (if set) below the display name; fall back to display name only if `username` is nil
- **No unique constraint** — per CloudKit compatibility rules (`@Attribute(.unique)` is forbidden); application-level duplicate detection is not required for Phase 15 (post-launch concern)

### Claude's Discretion

- Exact confetti/animation details for any new micro-interactions not specified in the design
- VitaminShelfGrid expanded-cell layout implementation details (conditional VStack vs GridItem span) — use whichever renders cleanly
- Static FAQ content (8–10 Q&As can be app-support/gratitude-themed, planner decides)
- Static "About Us" founder note copy (planner writes placeholder, real copy provided post-launch)
- Order of tab navigation path wiring (ContentView) — planner determines cleanest approach given existing NavigationStack setup

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design Source
- `VitaminG/docs/superpowers/specs/2026-05-15-ui-additions-design.md` — full design spec with exact dimensions, file paths, function signatures, and architecture decisions (PRIMARY REFERENCE)

### Existing Views to Modify
- `VitaminG/Views/HomeView.swift` — add A1/A2/A3; understand existing `statCell` private func and `primaryGoalCard` position
- `VitaminG/Views/ChallengeDiscoveryView.swift` — full B1–B8 redesign; understand current body structure before replacing
- `VitaminG/Views/CommunityTabView.swift` — C1 card redesign + route change
- `VitaminG/Views/ProfileView.swift` — D1 mood picker + D2 camera; understand `heroBanner` and camera badge ZStack (line ~106–124)
- `VitaminG/Views/Onboarding/WelcomeScreen.swift` — E1–E3 auth buttons

### New Files to Create
- `VitaminG/Views/Support/AboutUsView.swift` — A4
- `VitaminG/Views/Support/FAQView.swift` — A4
- `VitaminG/Views/CommunityGoalsLandingView.swift` — C2

### Navigation & Routing
- `VitaminG/Navigation/AppRoute.swift` — add `.communityGoals(UserChallenge)` (C4); understand existing cases before adding
- `VitaminG/Views/ContentView.swift` — wire new routes, pass navigationPath binding to ChallengeDiscoveryView; understand tab structure

### ViewModel
- `VitaminG/ViewModels/GoalViewModel.swift` — change `addGoal` return type (B8); read current signature before changing

### Services
- `VitaminG/Services/CommunityService.swift` — add `postCheckInPhoto` (C3); understand existing CloudKit patterns

### Theme System
- `VitaminG/Views/Components/VGTheme.swift` (or wherever VGTheme is defined) — use `VGTheme.accentTerra`, `VGTheme.surface`, `VGTheme.textPrimary` for mood pills; `VGCapsule.swift` for Dispenser reference

### Existing Components to Reuse
- `VitaminG/Views/Components/VGCapsule.swift` — reference for Dispenser bottle visual
- `VitaminG/Views/Components/ProgressRingView.swift` — reuse for community card (48pt) and landing page (200pt)
- `VitaminG/Views/CommunityTabView.swift` — `CommunityChallengeCellView` is here

### Project Constraints (CLAUDE.md)
- `.planning/CLAUDE.md` — tech stack constraints (no third-party dependencies unless necessary, Swift/SwiftUI/SwiftData only, iOS 17+, MVVM strictly enforced)

</canonical_refs>

<specifics>
## Specific Ideas

- **Quick Stats row** — reuse the existing `statCell` private func already in HomeView (do not create a new component)
- **Vitamin Dispenser bottle** — use simple `RoundedRectangle` with label band overlay; `VGCapsule` for reference; no SVG paths needed
- **MoodScannerView pill pills** — moods: All / Tired / Stuck / Hopeful / Fired up / Soft
- **Stay Close cards** — 148pt wide × 16pt padding × 18pt cornerRadius; icon chip is 44×44 `RoundedRectangle(cornerRadius: 14)`
- **Community landing photo wall** — featured photo at 4:5 aspect ratio, 354pt wide, with gradient placeholder; thumbnail strip uses 90pt tiles + AddTile
- **Camera permission denied** → show alert linking to Settings (`UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)`)
- **Photo compression targets** — profile photo: max 200KB JPEG; community check-in photo: max 800KB JPEG
- **Apple Sign In saves** — `userIdentifier` to `UserDefaults`; gates onboarding vs main app entry based on stored name

</specifics>

<deferred>
## Deferred Ideas

- CloudKit aggregate for collective progress ring (use `userChallenge.totalCheckIns / template.durationDays` locally for now)
- Real-time live ticker from CloudKit (use seed data for Phase 15)
- Leaderboard from CloudKit (use local participants for Phase 15)
- Google Sign-In real SDK (stubbed button ships; swap in `GoogleSignIn-iOS` post-launch when needed)

</deferred>

---

*Phase: 15-ui-additions-fixes*
*Context gathered: 2026-05-15 via PRD Express Path*
