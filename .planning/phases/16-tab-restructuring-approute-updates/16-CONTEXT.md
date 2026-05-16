# Phase 16: Tab Restructuring + AppRoute Updates — Context

**Gathered:** 2026-05-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Restructure the 5-tab navigation from `Home · Goals · Community · Explore · Me` to `Home · Goals · Explore · Community · Profile`, swap Community and Explore indices, demote Stats and Wins from Goals tab navigation destinations to Home tab, and replace raw integer tab selection with a typed `Tab` enum (string raw values) throughout ContentView, VGTabBar, and CommunityTabView. No new views, no schema changes, no new SPM dependencies.

</domain>

<decisions>
## Implementation Decisions

### Stats Entry Point
- **D-01:** Quick Stats row in HomeView (the 3-column active goals · check-ins · badges row added in Phase 15) is made tappable as a `NavigationLink` destination to `StatsView`. No new UI elements required.
- **D-02:** `.stats` AppRoute case wired exclusively in the Home tab `NavigationStack`'s `navigationDestination`. Remove `.stats` from `goalsTab`'s `navigationDestination` in ContentView.

### Daily Wins Entry Point
- **D-03:** A "Daily Wins →" link or button is added near the Check-in CTA area in HomeView (grouped with the daily check-in habit zone, below or adjacent to the "Log your workout →" CTA). Exact label and visual treatment at planner's discretion — must be clearly tappable and labelled.
- **D-04:** `.wins` AppRoute case wired exclusively in the Home tab `NavigationStack`'s `navigationDestination`. Remove `.wins` from `goalsTab`'s `navigationDestination` in ContentView.

### Tab Enum
- **D-05:** Full migration — `Tab` enum replaces `Int` everywhere in tab selection: `ContentView.selectedTab: Tab`, `VGTabBar.selection: Binding<Tab>`, `CommunityTabView.selectedTab: Binding<Tab>`.
- **D-06:** `Tab` enum uses `String` raw values, all lowercase: `"home"`, `"goals"`, `"explore"`, `"community"`, `"profile"`.
- **D-07:** New tab order (index mapping): `.home` (0) · `.goals` (1) · `.explore` (2) · `.community` (3) · `.profile` (4). Community and Explore swap from their current positions (Community was 2, Explore was 3).
- **D-08:** `CommunityTabView`'s hard-coded `selectedTab = 3` (integer, navigates to old Explore index) → `selectedTab = .explore` using the Tab enum.
- **D-09:** `VGTabBar` "Me" label → "Profile". `VGTabBar.tabs` array reordered to match new tab order.

### Claude's Discretion
- Exact label text and visual treatment for the Daily Wins entry in HomeView (button vs text link vs inline row) — must be visible and tappable near the Check-in CTA
- Whether to define a `var index: Int` computed property on `Tab` or use enum order directly for `TabView(selection:)` — either approach is fine
- Whether `Tab` is defined in its own file (`Tab.swift` in Navigation/) or inline in ContentView

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Requirements
- `.planning/ROADMAP.md` §Phase 16 — goal, success criteria, requirements list (TAB-01–TAB-04)
- `.planning/REQUIREMENTS.md` §TAB-01–TAB-04 — full requirement definitions

### Files to Modify
- `VitaminG/VitaminG/VitaminG/Views/ContentView.swift` — current tab wiring; tags 0–4 with raw Int; `goalsTab` has `.stats` and `.wins` destinations to remove; tab type changes to `Tab`
- `VitaminG/VitaminG/VitaminG/Views/Components/VGTabBar.swift` — Int-typed selection binding; `tabs` array has current order (Home, Goals, Community, Explore, Me) and "Me" label; must reorder and relabel
- `VitaminG/VitaminG/VitaminG/Views/CommunityTabView.swift` — `selectedTab = 3` hard-coded integer at line 73 ("Explore Challenges" button); binding type changes to `Tab`
- `VitaminG/VitaminG/VitaminG/Views/HomeView.swift` — add tappable Quick Stats row (NavigationLink to StatsView) + Daily Wins entry point near Check-in CTA; add `.stats` and `.wins` to this tab's NavigationStack navigationDestination

### Navigation Layer
- `VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift` — existing `.stats` and `.wins` cases (no changes to the enum itself; just rewire where they're handled)
- `VitaminG/VitaminG/VitaminG/Navigation/AppRouter.swift` — centralized navigation state; understand before touching ContentView
- `VitaminG/VitaminG/VitaminG/VitaminGApp.swift` — deep link handler (no changes expected; Tab enum is for tab selection only, not deep link routing)

### Prior Phase Context
- `.planning/milestones/v1.0-phases/15-ui-additions-fixes/15-CONTEXT.md` — Phase 15 added Quick Stats row (statCell private func), Check-in CTA, and Stay Close section to HomeView; read to understand HomeView's current layout before adding entry points

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `statCell` private func in HomeView — the Quick Stats row already renders 3 stat chips; wrap in a `NavigationLink(destination: StatsView())` to make it tappable (D-01)
- `ProgressRingView`, `VGTheme` — unchanged; no new visual components needed for this phase

### Established Patterns
- `NavigationStack` + `navigationDestination(for: AppRoute.self)` — used in all 4 tabs; Home tab currently has no destinations wired; add `.stats` and `.wins` here
- `AppRoute` enum — extend only if new routes are needed (none expected for this phase); `.stats` and `.wins` already exist
- `@Binding var selectedTab: Int` in `CommunityTabView` — established cross-view state sharing pattern; becomes `@Binding var selectedTab: Tab`

### Integration Points
- ContentView passes `selectedTab` binding to `VGTabBar` and `CommunityTabView` — all three must agree on type (`Tab` after migration)
- `TabView(selection: $selectedTab)` + `.tag(N)` — tags must match Tab enum values or their underlying Int indices; verify `.tag()` works with `Tab` (it requires `Tab: Hashable`, which `String`-rawValue enums satisfy automatically)
- Deep links in `VitaminGApp.swift` set `router.pendingPublicProfileRecordID` / `pendingChallengeCheckInID` — these are unaffected by the Tab enum; no changes needed there

</code_context>

<specifics>
## Specific Ideas

- Quick Stats row tap → StatsView (no intermediate screen; direct NavigationLink)
- Daily Wins link near the Check-in CTA ("Log your workout →" button area) — planner decides exact label
- `Tab` enum raw values: `"home"`, `"goals"`, `"explore"`, `"community"`, `"profile"` — these double as future widget intent / URL scheme tab parameters

</specifics>

<deferred>
## Deferred Ideas

### Phase 17 — PROF-05 UX Detail (Guideline 1.2)
- **Block/Report gesture entry point:** Report and Block actions should be accessible via a **long-press (press-and-hold) context menu** on a user's profile picture/avatar and on their @handle/display name — in addition to any explicit button on the public profile view. This satisfies App Store Guideline 1.2's moderation requirement with a familiar iOS gesture pattern. Capture this in Phase 17's discuss/plan so the planner wires `contextMenu` modifiers on the relevant views.

</deferred>

---

*Phase: 16-tab-restructuring-approute-updates*
*Context gathered: 2026-05-16*
