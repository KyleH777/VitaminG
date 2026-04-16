# Phase 5: Onboarding & Polish — Context

**Gathered:** 2026-04-15
**Status:** Ready for planning
**Source:** UI/UX Pro Max skill (SwiftUI stack) + Phase 7 UI-SPEC established design system

<domain>
## Phase Boundary

This phase delivers two interrelated outcomes:

1. **Onboarding flow** — a first-launch multi-screen sequence that explains the four tiers, guides the user to create their first goal, and requests notification permission with a value-framing screen. Returning users skip it automatically.

2. **Polish pass** — Light/Dark Mode correctness across all existing views, Dynamic Type support replacing every fixed font size, VoiceOver labels on all interactive elements, empty states for every tier, and elimination of any remaining placeholder UI.

Phase 5 does NOT add new features. It makes what exists feel like a shipped App Store app.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Onboarding: Skip always available
Provide a visible "Skip" button from the first onboarding screen. UX rule (UI Pro Max): users must never be locked into a forced linear tour. Users who re-open the app after an interrupted onboarding land on the main GoalListView, not the onboarding flow.

### D-02 — Onboarding: Back navigation
Each onboarding screen (except the first) has a Back button or swipe-back gesture. Use `NavigationStack` with `navigationDestination(for:)` pattern already established in the app. Do NOT use modal `.fullScreenCover` for onboarding — it breaks back navigation.

### D-03 — Onboarding: 3-screen sequence
**Screen 1 — Welcome**: App name "Vitamin G", tagline copy, animated accent gradient circle/logo. Skip button top-right.
**Screen 2 — The Four Tiers**: Explain Immediate / Short-Term / Long-Term / Life Goal with tier colors, icons, and one-line warm descriptions. Back + Next/Continue.
**Screen 3 — Create First Goal**: Embed a minimal version of AddGoalView or navigate to it. User must create at least one goal to advance. "Maybe later" link skips to main view.

### D-04 — Onboarding: Notification permission screen
After first goal is created (or after the onboarding flow if skipped via "maybe later"), present a half-sheet (`.sheet` medium detent) explaining: "Wake up to your goals every morning." Shows a mock notification preview. Two buttons: "Allow Notifications" (calls `NotificationScheduler.requestAuthorization()`) and "Not now". This satisfies NOTIF-01 and ONBOARD-03 — permission is never requested on cold launch without context.

### D-05 — Onboarding: Persistence via AppStorage
Track onboarding completion with `@AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false`. Set to `true` after user reaches GoalListView. VitaminGApp checks this on launch and gates the onboarding `NavigationStack` vs the main `ContentView`.

### D-06 — Empty states: One per tier, not one global
Each tier section in GoalListView shows its own empty state when it has no active goals. UI Pro Max rule: "Show helpful message and action — not blank white space." Each empty state shows:
- Tier icon (SF Symbol) + tier color
- 1-line warm description of that tier's purpose
- "Add your first [tier] goal" button that opens AddGoalView pre-set to that tier

### D-07 — Empty states: Warm, gratitude-framing copy (ONBOARD-01 tone)
Copy must not feel productivity-aggressive. Examples:
- Immediate: "What's one small win you can chase today?"
- Short-Term: "What are you working toward this week or month?"
- Long-Term: "What would make this year meaningful?"
- Life Goal: "What do you want your life to stand for?"

### D-08 — Light/Dark Mode: Use semantic system colors, not hardcoded
All existing views that use hardcoded `Color(red:green:blue:)` for text or backgrounds must audit against Dark Mode. Rules from UI Pro Max:
- Body text: `Color.primary` (system) — not hardcoded dark values
- Secondary text: `Color.secondary` — not hardcoded gray
- App background: `Color(.systemGroupedBackground)` in Dark Mode renders correctly; the existing `Color(red:0.949,green:0.949,blue:0.969)` is light-only and must be conditionalized
- Card surfaces: `Color(.secondarySystemGroupedBackground)` adapts automatically
- Accent gradient: unchanged — gradient on colored surfaces (buttons, avatar) is fine in both modes
- Contrast check: minimum 4.5:1 for all text on their backgrounds (UI Pro Max WCAG rule)

### D-09 — Dynamic Type: Replace all fixed font sizes
UI Pro Max SwiftUI rule (High severity): do NOT use `.system(size: N)` for semantic content. Every view that currently uses fixed sizes must be migrated:
- Body content → `.font(.body)` with `.fontDesign(.rounded)`
- Title content → `.font(.title2)` or `.font(.headline)` with `.fontDesign(.rounded)`
- Caption/metadata → `.font(.caption)` or `.font(.footnote)` with `.fontDesign(.rounded)`
- Exception: AvatarView initials remain at proportional `size * 0.386` (non-semantic, visual-only component)
- Exception: Tier icon sizes that are layout-fixed (not text) remain as `Image` resizable frames

### D-10 — Reduced motion: Gate all slide/scale animations
UI Pro Max SwiftUI rule (High severity): check `@Environment(\.accessibilityReduceMotion)`. When true:
- Onboarding screen transitions: no slide animation (instant transition)
- Tier empty state icons: no bounce/scale-in animation
- Completion celebration animation: fade only (no scale pop)
- Notification permission sheet: no spring animation on appear
Implementation: create a single helper `func animation<V: Equatable>(_ value: V, reducedMotion: Bool) -> Animation?` or use `withAnimation(reducedMotion ? nil : .spring())`.

### D-11 — VoiceOver: All interactive elements need labels
UI Pro Max a11y rule: icon-only buttons need `.accessibilityLabel()`. Audit checklist:
- GoalListView sort toolbar button: `.accessibilityLabel("Sort goals")`
- AddGoalView tier picker cells: `.accessibilityLabel("\(tier.name) tier — \(tier.description)")`
- GoalRowView completion toggle: `.accessibilityLabel(goal.isCompleted ? "Mark \(goal.title) incomplete" : "Complete \(goal.title)")`
- AvatarView: already has `.accessibilityLabel("Profile avatar for \(displayName ?? "you")")`
- Any button showing only an SF Symbol: add `.accessibilityLabel()`

### D-12 — Touch targets: 44pt minimum everywhere
UI Pro Max touch rule: minimum 44×44pt for all tappable elements. Use `.frame(minWidth: 44, minHeight: 44)` or `.contentShape(Rectangle())` with `.frame(height: 44)` on rows. Audit: GoalRowView completion toggle, tier picker cells, settings time picker controls.

### D-13 — Onboarding animations: Spring with reduced-motion guard
Onboarding screen transitions use `.easeInOut(duration: 0.25)` (150–300ms range per UI Pro Max). Reduced motion guard from D-10 applies. The accent gradient on the welcome screen may pulse with `.animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true))` — guarded.

### D-14 — No placeholder UI in shipping build
UI-04 requirement. Audit: any `Text("TODO")`, `Text("Coming soon")`, `Color.gray` placeholder rectangles, `EmptyView()` sections in the stats tab that were stubs, any `#if DEBUG` content that bleeds into release builds.

### D-15 — App icon and launch screen
Phase 5 is responsible for the final app icon (all required sizes) and a clean launch screen (no spinner, instant — SwiftUI `Color(.systemBackground)` or app accent color fill). Assets must be in Assets.xcassets at build time. Required icon sizes: 1024×1024 App Store + all device icon sizes generated by Xcode.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing UI foundation
- `.planning/phases/07-add-user-profiles-with-privacy-toggle-profile-picture-upload/07-UI-SPEC.md` — Full design system: spacing scale, typography, color palette, accent gradient, avatar colors. Phase 5 MUST NOT deviate from this.

### Requirements
- `.planning/REQUIREMENTS.md` — ONBOARD-01/02/03/04, NOTIF-01, UI-04, UI-05, UI-06

### Existing views to audit (read before modifying)
- `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift` — primary list view, empty states live here
- `VitaminG/VitaminG/VitaminG/Views/AddGoalView.swift` — must embed/reuse in onboarding
- `VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift` — fixed font sizes to migrate
- `VitaminG/VitaminG/VitaminG/Views/StatsView.swift` — fixed font sizes, Dark Mode audit
- `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift` — fixed font sizes
- `VitaminG/VitaminG/VitaminG/Views/ProfileView.swift` — fixed font sizes
- `VitaminG/VitaminG/VitaminG/VitaminGApp.swift` — launch gate for onboarding check
- `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` — `requestAuthorization()` already exists

### Architecture references
- `.planning/STATE.md` — key decisions, MVVM enforcement, no business logic in Views
- `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` — `@MainActor @Observable` pattern to replicate in OnboardingViewModel

</canonical_refs>

<specifics>
## Specific Ideas & Requirements from UI/UX Pro Max

### SwiftUI Stack Rules (applied to this phase)
- **Dynamic Type (High severity):** `.font(.body)`, `.font(.title2)`, `.font(.caption)` with `.fontDesign(.rounded)` — never `.system(size: N)` for semantic text
- **Reduced motion (High severity):** `@Environment(\.accessibilityReduceMotion)` guards all entry animations, bounce effects, and repeating pulsing animations
- **NavigationStack:** Already established. Onboarding uses `NavigationStack` with `navigationDestination(for: OnboardingStep.self)` — type-safe step routing
- **Dismiss:** `@Environment(\.dismiss)` — not `presentationMode`
- **Animation:** `.animation(.easeInOut(duration: 0.25), value:)` for UI transitions; `.spring(response: 0.4, dampingFraction: 0.7)` for interactive spring moments

### UX Rules (applied to this phase)
- **Empty states:** Helpful message + action CTA button. Never blank white space.
- **Onboarding skip:** Skip button visible from screen 1. No locked linear tour.
- **Touch targets:** 44×44pt minimum. Use `.contentShape(Rectangle())` on rows.

### Color (Phase 5 additions)
- All new views adapt `Color(.systemGroupedBackground)` as screen background (adapts Light/Dark automatically)
- `Color(.secondarySystemGroupedBackground)` for card/list row surfaces
- Accent gradient retained for onboarding welcome hero element
- Tier colors in empty state icons: existing `GoalTier.color` values

### Accessibility Checklist (per UI Pro Max pre-delivery requirements)
- [ ] All icon-only buttons have `.accessibilityLabel()`
- [ ] Completion toggle label describes goal title + action
- [ ] Tier picker cells announce tier name and description
- [ ] Onboarding screens have `.accessibilityElement(children: .combine)` where appropriate
- [ ] All transitions respect `accessibilityReduceMotion`
- [ ] No color as the only differentiator (tier icons + text labels alongside tier colors)

</specifics>

<deferred>
## Deferred / Out of Scope for Phase 5

- App icon design content (art direction) — Xcode placeholder icon is acceptable; final icon art is a content/design task, not engineering
- Haptic feedback patterns — enhancement, not Polish requirement
- Localization — English only per PROJECT.md constraints
- iPad layout — iPhone only per constraints
- Interactive widget buttons — v2 requirement per REQUIREMENTS.md
- Onboarding re-entry (re-run tutorial from Settings) — v2 nice-to-have

</deferred>

---

*Phase: 05-onboarding-polish*
*Context gathered: 2026-04-15 via UI/UX Pro Max skill (SwiftUI stack) + Phase 7 UI-SPEC*
