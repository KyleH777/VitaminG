---
phase: 05-onboarding-polish
verified: 2026-04-15T20:00:00Z
status: gaps_found
score: 10/12
overrides_applied: 0
gaps:
  - truth: "All semantic text uses Dynamic Type fonts — no .system(size: N) except documented exceptions"
    status: failed
    reason: "TierPickerView.swift (TierCardView) contains 3 unfixed .system(size:) text calls at sizes 28, 14, and 12. These are used for tier displayName and description text — semantic content that must scale with Dynamic Type. Only StatsView's streak numerals (sizes 48 and 28) were documented as D-09 exceptions. TierPickerView was not listed in Plan 03 files_modified and was not migrated."
    artifacts:
      - path: "VitaminG/VitaminG/VitaminG/Views/TierPickerView.swift"
        issue: "TierCardView line 36: .font(.system(size: 28)) — tier icon (Image, arguable exception); line 41: .font(.system(size: 14, weight: .semibold, design: .rounded)) — displayName text (must scale); line 45: .font(.system(size: 12, weight: .regular, design: .rounded)) — description text (must scale)"
    missing:
      - "Migrate TierCardView displayName font from .system(size: 14, weight: .semibold, design: .rounded) to .font(.subheadline.weight(.semibold)).fontDesign(.rounded)"
      - "Migrate TierCardView description font from .system(size: 12, weight: .regular, design: .rounded) to .font(.caption).fontDesign(.rounded)"
      - "Optionally migrate icon from .system(size: 28) to .font(.title2) or keep as documented exception"

  - truth: "App renders correctly in both Light and Dark Mode with no hardcoded light-only backgrounds"
    status: failed
    reason: "TierPickerView.swift (TierCardView) uses Color.white as the background fill for unselected tier cards. Color.white does not adapt in Dark Mode — it renders as a harsh white rectangle against the dark system background, breaking the Dark Mode appearance. This also was not in Plan 03 scope."
    artifacts:
      - path: "VitaminG/VitaminG/VitaminG/Views/TierPickerView.swift"
        issue: "TierCardView line 55: .fill(isSelected ? tier.color.opacity(0.12) : Color.white) — Color.white is a hardcoded light-only background"
    missing:
      - "Replace Color.white with Color(.secondarySystemGroupedBackground) in TierCardView unselected fill to match the semantic color system already used throughout the app"

human_verification:
  - test: "Run app on simulator or device, switch to Dark Mode in Settings. Open AddGoalView (tap + button). Observe TierPickerView tier cards."
    expected: "Tier cards adapt to dark appearance — no white cards visible. Unselected cards should match the dark secondary grouped background."
    why_human: "Dark Mode rendering cannot be verified programmatically without running the app."
  - test: "Run app on simulator, set Text Size to 'Accessibility Extra Extra Extra Large' in Settings > Accessibility > Display & Text Size. Open AddGoalView and observe tier picker."
    expected: "Tier card labels (displayName, description) scale with the user's preferred text size."
    why_human: "Dynamic Type scaling requires visual runtime verification across accessibility text sizes."
  - test: "On physical device or simulator with VoiceOver enabled, navigate through the full onboarding flow: Welcome screen -> Tiers screen -> Create First Goal screen."
    expected: "VoiceOver announces each screen's content meaningfully. The Skip button announces 'Skip'. The Get Started button announces correctly. All tier cards in TierPickerView announce displayName and description. The Save button announces its disabled state when title is empty."
    why_human: "VoiceOver navigation behavior requires on-device testing with VoiceOver active."
  - test: "Delete app from simulator, reinstall, and launch fresh. Complete the onboarding flow (create a goal), then check that the notification permission half-sheet appears."
    expected: "Onboarding shows Welcome -> Tiers -> Create Goal. After saving a goal, a half-sheet appears with 'Wake up to your goals every morning.' and 'Allow Notifications' / 'Not now'. Subsequent launches go directly to the goal list."
    why_human: "First-launch behavioral flow requires end-to-end testing of @AppStorage persistence and notification sheet timing."
---

# Phase 5: Onboarding & Polish — Verification Report

**Phase Goal:** First-time users are guided into the app with tier explanation and first-goal creation; returning users experience App Store-quality UI with full accessibility and Light/Dark Mode support
**Verified:** 2026-04-15T20:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|---------|
| 1 | First-launch user sees a 3-screen onboarding flow before reaching GoalListView | VERIFIED | OnboardingView.swift: NavigationStack(path: $path) with WelcomeScreen root, .tiers and .createGoal destinations wired. VitaminGApp.swift: Group { if hasCompletedOnboarding { ContentView() } else { OnboardingView() } }. |
| 2 | Onboarding explains all four tiers with warm, gratitude-framing copy | VERIFIED | TiersScreen.swift contains all 4 D-07 strings: "Quick wins you can chase today", "Goals for the coming weeks and months", "What would make this year meaningful", "What you want your life to stand for". |
| 3 | User can create their first goal from within onboarding screen 3 | VERIFIED | CreateFirstGoalScreen.swift: viewModel.addGoal(context: modelContext) in saveAndComplete(). Reuses GoalViewModel + TierPickerView. "Maybe later" skip path present. |
| 4 | Notification permission is requested via half-sheet after first goal creation or skip — never on cold launch | VERIFIED | OnboardingViewModel.completeOnboarding() checks authorizationStatus() and only sets showNotificationSheet = true if .notDetermined. requestAuthorization() not present in VitaminGApp.swift init. OnboardingView wires .sheet with .presentationDetents([.medium]). |
| 5 | Skip button is visible from the first onboarding screen | VERIFIED | WelcomeScreen.swift: ToolbarItem(placement: .topBarTrailing) { Button("Skip") { onSkip() } }. TiersScreen also has Skip toolbar button. |
| 6 | Returning users who have completed onboarding go directly to ContentView | VERIFIED | VitaminGApp.swift @AppStorage("hasCompletedOnboarding") stored property gates Group between ContentView() and OnboardingView(). |
| 7 | Back navigation works on every onboarding screen via NavigationStack | VERIFIED | OnboardingView uses NavigationStack(path: $path) with navigationDestination(for: OnboardingStep.self). WelcomeScreen has .navigationBarBackButtonHidden(true). TiersScreen and CreateFirstGoalScreen inherit default back button. |
| 8 | Each of the four tier sections shows a warm, actionable empty state when it has no active goals | VERIFIED | GoalListView.swift: TierSectionView always rendered for all tiers; EmptyTierView(tier: tier) shown when tieredGoals.isEmpty with onAdd closure setting viewModel.draftTier = tier and showingAddGoal = true. EmptyTierView contains all 4 D-07 copy strings. |
| 9 | App renders correctly in both Light and Dark Mode with no hardcoded light-only backgrounds | FAILED | No Color(red: 0.949...) remains in any view file (PASS). However, TierPickerView.swift TierCardView uses Color.white as the unselected card background fill — a hardcoded light-only color that renders as a harsh white rectangle in Dark Mode. |
| 10 | All semantic text uses Dynamic Type fonts with .fontDesign(.rounded) — no .system(size: N) except documented exceptions | FAILED | GoalDetailView, GoalListView, ProfileView, ProfileEditSheet: zero .system(size:) remaining (PASS). StatsView: exactly 2 with D-09 exception comments (PASS). TierPickerView.swift (TierCardView): 3 unfixed .system(size:) calls — displayName (.system(size: 14)) and description (.system(size: 12)) are semantic text that must scale with Dynamic Type. |
| 11 | All icon-only buttons have VoiceOver accessibility labels | VERIFIED | GoalListView sort Menu: .accessibilityLabel("Sort goals") at line 64. GoalRowView completion toggle: .accessibilityLabel(goal.completed ? "Mark \(goal.title ?? "goal") as active" : "Mark \(goal.title ?? "goal") as complete"). TierPickerView tier cards: .accessibilityLabel("\(tier.displayName), \(tier.description)"). |
| 12 | AppIcon.appiconset references AppIcon.png and test suite compiles with new stubs | VERIFIED | Contents.json universal iOS entry has "filename" : "AppIcon.png". AppIcon.png exists. VitaminGTests.swift contains struct OnboardingViewModelTests and struct EmptyTierViewTests. |

**Score:** 10/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|---------|--------|---------|
| `VitaminG/VitaminG/VitaminG/ViewModels/OnboardingViewModel.swift` | Onboarding state management with @MainActor | VERIFIED | Contains @MainActor, @Observable, class OnboardingViewModel, hasCreatedFirstGoal, showNotificationSheet, completeOnboarding() async |
| `VitaminG/VitaminG/VitaminG/Views/Onboarding/OnboardingView.swift` | NavigationStack shell with step routing | VERIFIED | Contains NavigationStack(path:), enum OnboardingStep, @AppStorage("hasCompletedOnboarding"), .sheet for notification permission |
| `VitaminG/VitaminG/VitaminG/Views/Onboarding/WelcomeScreen.swift` | Screen 1 with Skip, pulse animation | VERIFIED | Button("Skip"), pulseScale, accessibilityReduceMotion, .navigationBarBackButtonHidden(true) |
| `VitaminG/VitaminG/VitaminG/Views/Onboarding/TiersScreen.swift` | Screen 2 with all 4 tier cards and warm copy | VERIFIED | GoalTier.ordered ForEach, all 4 D-07 descriptions present |
| `VitaminG/VitaminG/VitaminG/Views/Onboarding/CreateFirstGoalScreen.swift` | Screen 3 with goal creation | VERIFIED | viewModel.addGoal(context: modelContext), "Maybe later", TierPickerView, no nested NavigationStack |
| `VitaminG/VitaminG/VitaminG/Views/Sheets/NotificationPermissionSheet.swift` | Notification permission half-sheet | VERIFIED | "Wake up to your goals every morning.", "Allow Notifications", "Not now", .accessibilityElement(children: .combine) on mock card |
| `VitaminG/VitaminG/VitaminG/VitaminGApp.swift` | @AppStorage gate in app body | VERIFIED | @AppStorage("hasCompletedOnboarding") as struct property, Group with both branches, .modelContainer(container) on Group |
| `VitaminG/VitaminG/VitaminG/Views/Components/EmptyTierView.swift` | Per-tier empty state component | VERIFIED | struct EmptyTierView: View, all 4 D-07 prompt copy strings, tier.icon, tier.color, onAdd closure |
| `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift` | Wired per-tier empty states + accessibility + semantic colors | VERIFIED | EmptyTierView(tier: tier) in tier ForEach, viewModel.draftTier = tier, .accessibilityLabel("Sort goals"), Color(.systemGroupedBackground) in EmptyStateView |
| `VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift` | Dynamic Type fonts + semantic background | VERIFIED | Color(.systemGroupedBackground), all 10 font replacements present (.font(.title2.weight(.semibold)).fontDesign(.rounded) etc.), zero .system(size:) |
| `VitaminG/VitaminG/VitaminG/Views/ProfileView.swift` | Dynamic Type fonts | VERIFIED | Zero .system(size:) occurrences, .font(.title2.weight(.semibold)).fontDesign(.rounded) for display name |
| `VitaminG/VitaminG/VitaminG/Views/ProfileEditSheet.swift` | Dynamic Type fonts | VERIFIED | Zero .system(size:) occurrences |
| `VitaminG/VitaminG/VitaminG/Views/StatsView.swift` | D-09 exceptions documented | VERIFIED | Exactly 2 .system(size:) occurrences (48 and 28) with D-09 exception comments |
| `VitaminG/VitaminG/VitaminG/Views/TierPickerView.swift` | Dynamic Type fonts + semantic colors | FAILED | Contains 3 unfixed .system(size:) text calls and Color.white hardcoded background |
| `VitaminG/VitaminG/VitaminG/Assets.xcassets/AppIcon.appiconset/Contents.json` | App icon filename reference | VERIFIED | "filename" : "AppIcon.png" in universal iOS entry; dark/tinted entries have no filename |
| `VitaminG/VitaminG/VitaminGTests/VitaminGTests.swift` | Expanded test coverage | VERIFIED | struct OnboardingViewModelTests, struct EmptyTierViewTests, OnboardingViewModel() initialization tested |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| VitaminGApp.swift | OnboardingView | @AppStorage gate in body | WIRED | Group { if hasCompletedOnboarding { ContentView() } else { OnboardingView() } } with @AppStorage("hasCompletedOnboarding") as struct property |
| CreateFirstGoalScreen | GoalViewModel.addGoal | modelContext from environment | WIRED | viewModel.addGoal(context: modelContext) in saveAndComplete(); @Environment(\.modelContext) private var modelContext |
| NotificationPermissionSheet | NotificationScheduler.requestAuthorization | onAllow closure | WIRED | Task { await NotificationScheduler.shared.requestAuthorization() } in OnboardingView onAllow handler |
| GoalListView (tier ForEach) | EmptyTierView | Conditional rendering in tier ForEach loop | WIRED | EmptyTierView(tier: tier) { viewModel.draftTier = tier; showingAddGoal = true } inside TierSectionView when tieredGoals.isEmpty |
| EmptyTierView onAdd | GoalListView showingAddGoal | onAdd closure sets viewModel.draftTier and showingAddGoal | WIRED | viewModel.draftTier = tier set before showingAddGoal = true |
| OnboardingView finish() | hasCompletedOnboarding | @AppStorage synchronous set | WIRED | hasCompletedOnboarding = true set synchronously before Task { await onboardingVM.completeOnboarding() } |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|-------------------|--------|
| EmptyTierView | tier.icon, tier.color, promptCopy | GoalTier enum (compile-time) | Yes — enum values, no network/DB needed | FLOWING |
| TiersScreen | GoalTier.ordered | GoalTier enum (compile-time) | Yes | FLOWING |
| CreateFirstGoalScreen | viewModel.draftTitle, draftTier | GoalViewModel @State | Yes — writes via addGoal(context:) to SwiftData | FLOWING |
| GoalListView tier sections | tieredGoals | goals(for: tier) via @Query | Yes — live SwiftData query | FLOWING |

### Behavioral Spot-Checks

Step 7b: SKIPPED — behavioral spot-checks require running the iOS Simulator. The app cannot be launched headlessly from the terminal in this environment without a full xcodebuild test run.

Commit verification:

| Commit | Description | Status |
|--------|-------------|--------|
| d157f09 | feat(05-01): add OnboardingViewModel and 3-screen onboarding flow | VERIFIED in git log |
| f000c0c | feat(05-01): add NotificationPermissionSheet and wire @AppStorage gate in VitaminGApp | VERIFIED in git log |
| 210e231 | feat(05-02): add EmptyTierView component with per-tier warm copy | VERIFIED in git log |
| c969831 | feat(05-02): wire EmptyTierView into GoalListView tier sections | VERIFIED in git log |
| 969f3d0 | feat(05-03): migrate GoalDetailView and GoalListView to semantic colors and Dynamic Type | VERIFIED in git log |
| 4a63cb9 | feat(05-03): migrate ProfileView and ProfileEditSheet to Dynamic Type; document StatsView exceptions | VERIFIED in git log |
| aa60d21 | feat(05-04): add VoiceOver label to sort Menu in GoalListView | VERIFIED in git log |
| bee90fd | feat(05-04): wire app icon, add OnboardingViewModel and EmptyTierView test stubs | VERIFIED in git log |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| ONBOARD-01 | 05-01-PLAN | First-launch onboarding explains the 4 tiers with warm, gratitude-framing copy | SATISFIED | TiersScreen.swift has all 4 warm D-07 copy strings. WelcomeScreen explains the app. |
| ONBOARD-02 | 05-01-PLAN | Onboarding guides user to create their first goal before reaching the main view | SATISFIED | CreateFirstGoalScreen uses GoalViewModel.addGoal(). onComplete() calls finish() which sets hasCompletedOnboarding = true. |
| ONBOARD-03 | 05-01-PLAN | Notification permission request occurs during onboarding with clear value framing | SATISFIED | NotificationPermissionSheet presented via OnboardingView sheet. "Wake up to your goals every morning." value framing. Never called on cold launch. |
| ONBOARD-04 | 05-01-PLAN, 05-02-PLAN | Empty states for each tier include actionable prompts to add a first goal | SATISFIED | EmptyTierView wired in GoalListView for all 4 tiers. All 4 D-07 copy strings present. onAdd sets correct tier and opens AddGoalView. |
| NOTIF-01 | 05-01-PLAN | App requests notification permission during onboarding (not on cold launch without context) | SATISFIED | requestAuthorization() only called from notification sheet onAllow handler. VitaminGApp.init() has no notification permission call. OnboardingViewModel checks authorizationStatus() and only shows sheet if .notDetermined. |
| UI-04 | 05-02-PLAN, 05-03-PLAN, 05-04-PLAN | App Store-quality polish: no placeholder UI, no debug elements, smooth transitions | SATISFIED (partial) | No Text("TODO") or Text("Coming soon") found. Sort button VoiceOver label added. AppIcon wired. Test stubs added. TierPickerView fixed-font issue is a quality gap. |
| UI-05 | 05-03-PLAN | Supports both Light and Dark Mode | FAILED | Color(red: 0.949...) removed from all 5 migrated views. However TierPickerView.swift TierCardView still uses Color.white as unselected card background — will render incorrectly in Dark Mode. |
| UI-06 | 05-03-PLAN, 05-04-PLAN | Accessibility: Dynamic Type support, VoiceOver labels on all interactive elements | PARTIAL | VoiceOver labels: verified on sort button, tier picker, GoalRowView completion toggle, NotificationPermissionSheet CTA. Dynamic Type: FAILED for TierPickerView TierCardView text (sizes 14 and 12 are hardcoded, not semantic). All other audited views pass. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| TierPickerView.swift | 41 | `.font(.system(size: 14, weight: .semibold, design: .rounded))` — displayName text | Blocker | Text does not scale with user's Dynamic Type preference — violates UI-06 and SC4 |
| TierPickerView.swift | 45 | `.font(.system(size: 12, weight: .regular, design: .rounded))` — description text | Blocker | Text does not scale with user's Dynamic Type preference — violates UI-06 and SC4 |
| TierPickerView.swift | 55 | `.fill(isSelected ? tier.color.opacity(0.12) : Color.white)` — hardcoded light-only background | Blocker | Renders as white card in Dark Mode — violates UI-05 and SC4 |
| TierPickerView.swift | 36 | `.font(.system(size: 28))` — tier icon Image | Warning | SF Symbol Image at fixed size — analogous to AvatarView initials, but undocumented. Arguable exception; icon is decorative and layout-fixed within the 2x2 grid. |
| WelcomeScreen.swift | 52 | `.font(.system(size: 72))` — star.circle.fill SF Symbol in 160pt hero circle | Info | Decorative display element at fixed size — consistent with D-09 exception rule for layout-fixed visual elements. Analogous to AvatarView initials. Acceptable. |

### Human Verification Required

#### 1. Dark Mode — TierPickerView Card Rendering

**Test:** Open the app in iOS Simulator. In Settings > Developer > Appearance, switch to Dark Mode. Navigate to + (Add Goal) from the main goal list. Observe the tier picker cards.
**Expected:** Cards should have a dark-adapted background for unselected state (matching the dark secondary grouped background — not white). Currently `Color.white` is used and will fail this check until fixed.
**Why human:** Color adaptation in Dark Mode requires visual runtime inspection.

#### 2. Dynamic Type Scaling — Tier Picker

**Test:** In Settings > Accessibility > Display & Text Size, set Text Size to "Accessibility Extra Extra Extra Large". Navigate to Add Goal. Observe tier card labels.
**Expected:** Tier displayName and description text should scale up. Currently fixed at 14pt and 12pt respectively.
**Why human:** Dynamic Type rendering requires visual runtime verification.

#### 3. VoiceOver Navigation — Full Onboarding Flow

**Test:** On device or simulator with VoiceOver (or Accessibility Inspector), delete the app (or reset @AppStorage), reinstall, and launch. Navigate through: Welcome screen -> Tiers screen -> Create Goal screen.
**Expected:** VoiceOver announces each tier card with its displayName and description. Skip button announces "Skip". All interactive elements are reachable and announced meaningfully.
**Why human:** VoiceOver navigation order and announcement quality require accessibility testing tooling or on-device VoiceOver.

#### 4. First-Launch Behavioral Flow

**Test:** Delete the app from simulator. Install fresh build. Launch. Complete the onboarding: tap "Get Started", tap "Continue", enter a goal title, tap "Save". Observe what happens next. Force-quit and relaunch.
**Expected:** After saving a goal, the notification permission half-sheet appears (if permission is .notDetermined). After dismissing it, the main GoalListView is visible. On relaunch, onboarding is skipped.
**Why human:** @AppStorage persistence behavior and notification permission sheet timing require end-to-end behavioral testing.

---

## Gaps Summary

Two blocking gaps were found in `TierPickerView.swift` (`TierCardView` private struct), a view that was not included in the files_modified scope of Plan 03 (which listed GoalDetailView, GoalListView, ProfileView, ProfileEditSheet, StatsView) or Plan 04. The gaps were introduced during Phase 2 (Core Goal UI) when TierPickerView was first built, and were never remediated in Phase 5.

**Gap 1 — Dynamic Type:** `TierCardView` uses `.font(.system(size: 14))` and `.font(.system(size: 12))` for displayName and description text labels. These are semantic text content (user reads them to understand tier categories) and must scale with Dynamic Type per SC4 and UI-06.

**Gap 2 — Dark Mode:** `TierCardView` uses `Color.white` as the background fill for unselected tier cards. `Color.white` is a hardcoded light-mode-only value. In Dark Mode, it renders as a bright white rectangle against the dark system background, breaking the visual experience. It should be replaced with `Color(.secondarySystemGroupedBackground)` which adapts automatically.

Both gaps are in the same file and the same private struct (`TierCardView`). They share a root cause: TierPickerView was excluded from Plan 03's migration scope. A single targeted fix to `TierPickerView.swift` would close both gaps.

---

_Verified: 2026-04-15T20:00:00Z_
_Verifier: Claude (gsd-verifier)_
