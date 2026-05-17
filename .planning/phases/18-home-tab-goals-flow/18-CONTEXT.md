# Phase 18: Home Tab + Goals Flow Enhancements - Context

**Gathered:** 2026-05-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Rebuild the Home tab into a complete dashboard showing the user's display name + streak count, quote of the day, community goal with progress bar, and a "My Goals" section with inline "+add". Add Stats view access from Home (NavigationStack push). Remove Daily Wins / Gratitude from the Home tab entirely. Redesign goal creation with a 3-path entry choice screen ("Need ideas" / "Already have a goal" / wizard), a hardcoded pre-made goals list, and a 3-step wizard retaining tier in Step 3. Add a full-screen check-in celebration screen (auto-dismiss after 2s, overall app streak). Upgrade GoalDetailView with a calendar-month day grid (current month only, week rows).

HOME-06 (Daily Wins / Gratitude view) is explicitly dropped from Phase 18 scope — not deferred to a later phase, removed.

</domain>

<decisions>
## Implementation Decisions

### Home Dashboard Layout
- **D-01:** Community goal (HOME-03) gets its own card section between the quote section and "My Goals" — distinct from the user's personal top goal. Two clear sections: community goal card (with title + progress bar showing community completion %), then "My Goals" below.
- **D-02:** Stats view (HOME-05) surfaces as a tappable row card in the Home scroll that pushes to the full StatsView via NavigationStack. The existing `quickStatsRow` section is promoted to a proper navigation entry point. No separate tab needed.
- **D-03:** Streak count lives in the header alongside the greeting: `"Good morning, Kyle ☀️  🔥 14"` — streak count + flame emoji on the same line as the greeting. Prominent and glanceable.
- **D-04:** HOME-06 (Daily Wins / Gratitude) is dropped. Remove the existing `dailyWinsEntry` section from HomeView. No gratitude log in Phase 18.

### Goal Creation Entry Flow
- **D-05:** When the user taps "+add" on the Home screen, a choice screen appears (sheet) with 3 paths: "Need ideas" (pre-made goals list), "Already have a goal" (blank goal form — GOAL2-03), and the 3-step wizard ("Build my own goal"). User picks their path.
- **D-06:** "Need ideas" pre-made goals list (GOAL2-02) is a hardcoded Swift array — no network call, works offline. Goals are organized by GoalCategory. Tapping a pre-made goal pre-fills Step 2 (name) and Step 1 (category) of the wizard, then lands on Step 3 for final details.
- **D-07:** Tier (life goal / long-term / short-term / challenge) stays in Step 3 alongside duration, start date, reminder time, and public/private toggle. The redesigned Step 3 replaces the existing Step3DetailsScreen content but retains tier as a required field.
- **D-08:** "Already have a goal" path (GOAL2-03) opens a blank goal landing page — effectively drops the user into Step 2 (goal name text field) with Step 1 category defaulted or choosable inline.

### Goal Detail Day Grid
- **D-09:** Day grid (GOAL2-05) uses calendar-month rows — days arranged Mon–Sun in week rows. Filled circles for completed days, empty circles for future/missed days. Current month shown by default.
- **D-10:** Only the current calendar month is shown at a time. No scrolling through full goal duration — keeps the view fast and focused. (Swipe navigation to adjacent months is Claude's discretion.)
- **D-11:** Flame icon on goals with 3+ consecutive days (GOAL2-05) appears on the goal row/card in the My Goals section (not just in the detail grid). Sourced from per-goal streak calculated against CompletionEvent records.

### Check-in Celebration Screen
- **D-12:** The celebration screen (GOAL2-04) shows the user's **overall app streak** (same number displayed in the Home header), not a per-goal streak.
- **D-13:** Celebration appears as a full-screen cover. It auto-dismisses after ~2 seconds, after which the user sees "Back to Goals". A manual "Back to Goals" button is also present for users who don't want to wait. Matches the existing milestone achievement pattern (pendingMilestone) in GoalListView.

### Claude's Discretion
- Exact confetti animation style on the check-in celebration screen.
- Whether the community goal card shows the community-wide completion percentage or the user's personal contribution — use whatever data is available from CloudKit or the local model.
- Layout of the goal creation choice screen (sheet title, icon treatment for the 3 paths).
- Swipe navigation between months in the day grid (if adding, keep it simple — chevron buttons are sufficient).
- Whether "Already have a goal" shows all 3 steps or skips Step 1 if category is not critical.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Requirements
- `.planning/ROADMAP.md` §Phase 18 — goal, success criteria, requirements list (HOME-01–HOME-06, GOAL2-01–GOAL2-05)
- `.planning/REQUIREMENTS.md` §HOME-01–HOME-06, §GOAL2-01–GOAL2-05 — full requirement definitions
- Note: HOME-06 is explicitly dropped from this phase per D-04 above

### Existing Views to Modify
- `VitaminG/VitaminG/VitaminG/Views/HomeView.swift` — primary Home tab; add streak to header, add community goal section, promote Stats row to navigation, remove dailyWinsEntry
- `VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift` — add calendar-month day grid, "Check in for today" CTA with streak count, flame icon for 3+ consecutive days
- `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift` — update "+add" trigger to show choice screen instead of directly launching wizard
- `VitaminG/VitaminG/VitaminG/Views/GoalCreation/GoalCreationWizardView.swift` — redesign step routing; Step 1 (category), Step 2 (name/say it out loud), Step 3 (tier, duration, start date, reminder, privacy)
- `VitaminG/VitaminG/VitaminG/Views/GoalCreation/Step3DetailsScreen.swift` — update to include duration and start date fields alongside existing tier, reminder, privacy

### New Files to Create
- `VitaminG/.../Views/GoalCreation/GoalEntryChoiceView.swift` — 3-path entry sheet ("Need ideas" / "Already have a goal" / wizard)
- `VitaminG/.../Views/GoalCreation/PremadeGoalsListView.swift` — hardcoded pre-made goals list organized by category (GOAL2-02)
- `VitaminG/.../Views/CheckInCelebrationView.swift` — full-screen cover celebration with confetti, overall streak count, auto-dismiss + "Back to Goals" (GOAL2-04)
- `VitaminG/.../Views/Components/GoalDayGridView.swift` — calendar-month grid component; week rows, filled/empty day circles, reusable (GOAL2-05)

### Existing Components to Reuse
- `VitaminG/VitaminG/VitaminG/Views/Components/ProgressRingView.swift` — use in My Goals section for progress rings per goal (size: 28pt default); scalable for larger goal cards
- `VitaminG/VitaminG/VitaminG/Services/StreakEngine.swift` — use for overall app streak (Home header + celebration screen) and per-goal consecutive day calculation (flame icon threshold: 3 days)
- `VitaminG/VitaminG/VitaminG/ViewModels/GoalCreationWizardViewModel.swift` — extend to support pre-made goal pre-fill and "Already have a goal" blank path

### Brand + Design
- `VitaminG/VitaminG/VitaminG/VGTheme.swift` — color system, typography (Cormorant Garamond serif headings, system font body), clay/sand palette

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ProgressRingView` — 28pt circular progress ring, configurable size/stroke/tier color. Can scale to larger sizes for community goal card or goal detail. Supports completion state and sublabel.
- `GoalCreationWizardView` — existing 3-step wizard with `isOnboarding`, `editingGoal`, `onComplete` init params. Phase 18 redesigns the step content but keeps the wrapper/NavigationStack pattern.
- `GoalViewModel` — handles goal CRUD, deletion, completion; used by HomeView, GoalListView, GoalDetailView.
- `GoalCreationWizardViewModel` — manages wizard draft state (`draftTier`, `selectedFrequency`, etc.); has `configure(from:)` for pre-fill. Extend for pre-made goal pre-fill.
- `StreakEngine` — existing service for streak calculations. Already used in GoalListView for milestone detection.
- Capsule step-dots pattern — existing in Step1/Step3 screens (`ForEach(0..<3)` capsule pills). Reuse for any new step indicator.

### Established Patterns
- Clay/sand background: `VGTheme.sandLight.ignoresSafeArea()` on scroll views
- Cormorant Garamond for step headers: `.font(.custom("CormorantGaramond-Regular", size: 34))`
- `@Query` for SwiftData live queries (Goals, CompletionEvent)
- Safe area inset for sticky bottom buttons: `.safeAreaInset(edge: .bottom)`
- Full-screen milestone celebration: existing `pendingMilestone` + `.fullScreenCover` pattern in GoalListView — replicate for check-in celebration

### Integration Points
- `HomeView` connects to `GoalListView` (Goals tab) via tab structure; "+add" on Home and Goals tab should both trigger the new choice screen
- `GoalDetailView(goal: Goal)` — navigation destination from GoalListView rows and Home "My Goals" section
- `CompletionEvent` model — source of truth for day grid filled/empty state and per-goal consecutive streak
- `VitaminGApp.swift` — tab bar structure; confirm Home tab is already the first tab in v2.0 structure

</code_context>

<specifics>
## Specific Ideas

- Streak count display in header: `"Good morning, Kyle ☀️  🔥 14"` — exact format with flame emoji inline
- Community goal card: prominent section between quote and My Goals, shows community-wide progress bar
- Check-in celebration: auto-dismiss after ~2 seconds — same behavior as Duolingo streak screen; feel rewarding without blocking rapid multi-goal check-ins
- Day grid: calendar-month week rows — Mon–Sun, filled circles for completed, empty for missed/future. Current month default.

</specifics>

<deferred>
## Deferred Ideas

- **Daily Wins / Gratitude (HOME-06):** Explicitly removed from Phase 18. User does not see value in a gratitude log alongside goal tracking. May be reconsidered in a future milestone if there's a use case.
- **Per-goal streak on celebration screen:** User chose overall app streak; per-goal streak display deferred if ever needed.
- **Full goal duration in day grid:** Showing all months of a goal's lifespan deferred — current month view is sufficient for Phase 18.
- **Month navigation in day grid:** Swipe/chevron to adjacent months is Claude's discretion; full month-browsing UI deferred.

</deferred>

---

*Phase: 18-home-tab-goals-flow*
*Context gathered: 2026-05-17*
