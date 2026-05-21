# Phase 19: Tip Jar + About Page + Settings - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Add three new screens to the app: (1) an AboutView accessible via "About Vitamin G" row in SettingsView, showing the founder bio with a floating sticky tip button; (2) a TipJarView (NavigationLink push from AboutView) showing 3 StoreKit 2 consumable IAP tiers with a full-screen celebration on purchase; (3) expand the existing SettingsView Form with new sections for Appearance (dark mode), Privacy (profile toggle), and Support (contact + About row). Also add a conditional NOTIF-01 nudge-time picker screen to onboarding (shown after permission is granted), and update daily notification copy to rotate inspirational messages + top goal title.

Phase 16 tab restructuring (5-tab v2.0 layout) is a prerequisite — Settings is accessed from the Profile tab via the existing NavigationLink in ProfileView.shareAndSettings.

</domain>

<decisions>
## Implementation Decisions

### About Page
- **D-01:** About page is accessed via an "About Vitamin G" row at the bottom of the expanded SettingsView. This is a standard iOS pattern (Settings → About). No second NavigationLink in ProfileView.
- **D-02:** The tip button on About is a floating sticky footer — it appears after a short scroll down (not blocking the top header, not buried at bottom). The founder bio content scrolls beneath the fixed footer. The floating button reads something like "Buy me a coffee ☕" or "Tip the Developer".
- **D-03:** About page content: app name, current app version (from Bundle.main.infoDictionary), and the founder's bio (cancer recovery and goal-setting story — exact text must be preserved verbatim as provided in the codebase or a resource file).

### Tip Jar
- **D-04:** Tapping the floating tip button on About navigates (NavigationLink push) to a dedicated `TipJarView` — not a sheet, not inline on About. Full navigation push gives more space to present the 3 tiers.
- **D-05:** TipJarView shows 3 consumable IAP tiers: Small Coffee (~$0.99), Large Coffee (~$2.99), Supporter (~$4.99). Prices rendered via StoreKit 2 `product.displayPrice`. Each tier has an emoji, name, and price.
- **D-06:** Post-purchase: a full-screen cover appears (same `.fullScreenCover` pattern as GoalListView milestone celebrations) showing "Thank you! You're the best." with a confetti or heart animation. Dismisses via a "Done" button (no auto-dismiss required for purchase confirmation).
- **D-07:** Consumable IAPs are always shown as purchasable regardless of prior transaction history. No "you've already tipped" state to track — consumables can be bought multiple times by design.
- **D-08:** StoreKit 2 `Transaction.updates` listener is wired at `VitaminGApp` init (locked decision from STATE.md). TipJarView uses `StoreKit.Product.products(for:)` to fetch live prices at view appear.
- **D-09:** No external payment links anywhere in the app — App Store Guideline 3.1.1 compliance (locked as MON-03). No "watch an ad" mechanism (requires third-party SDK dependency and violates Vitamin G no-third-party policy).

### Settings Page Expansion
- **D-10:** Extend the existing SettingsView Form with new sections — do not redesign the visual style. New sections to add:
  - **"Appearance"** section: A `Picker` (segmented or menu) for System / Light / Dark with label "Appearance". Stored as `@AppStorage("vg_colorScheme")` string enum.
  - **"Privacy"** section: A `Toggle` for "Public Profile" wired to the existing profile's `isPublic` SwiftData field.
  - **"Support"** section: A "Contact Support" row (mailto: `VitaminG.info@gmail.com` with pre-filled subject "Vitamin G Support") and an "About Vitamin G" NavigationLink row that pushes to `AboutView`.
- **D-11:** Dark mode stored as `@AppStorage("vg_colorScheme")` on a `ColorSchemePreference` enum (cases: `.system`, `.light`, `.dark`) read from `VitaminGApp.swift`. Applied via `.preferredColorScheme()` on the `WindowGroup`. Change takes effect immediately without a restart.
- **D-12:** Contact Support email is `VitaminG.info@gmail.com`. Implementation: a `Link` or `Button` that opens `mailto:VitaminG.info@gmail.com?subject=Vitamin%20G%20Support` via `openURL`. Simple, no MFMailComposeViewController dependency needed.

### NOTIF-01 Onboarding Nudge-Time Picker
- **D-13:** The nudge-time picker (NOTIF-01) is a **conditional onboarding step** — it only appears if the user granted notification permission on Step 6 (NotificationOnboardingScreen). If denied or skipped, the flow jumps directly to CameraPermissionScreen (Step 7). Dynamic step count: either 8 or 9 steps depending on permission grant.
- **D-14:** The nudge-time picker screen shows 5 quick-select time chips: 6 AM, 7 AM, 8 AM, 9 AM, 10 AM. Plus a "Custom time" DatePicker for other times. A "Skip for now" secondary link advances without saving (keeps the existing default). StepBarView total updates dynamically based on whether this step is shown.
- **D-15:** Default chip selection and pre-selection behavior: Claude's discretion — pick whatever feels most natural and reduces friction (8 AM chip pre-selected is a reasonable starting point given `NotificationPreferences.defaultHour = 8`).

### Notification Copy Update
- **D-16:** The daily morning notification body text changes from "up to 3 goal titles" to: a rotating inspirational message (hardcoded Swift array, seeded by day-of-year so it's consistent for the day) on line 1, followed by the user's top active goal title on line 2. Example phrases: "You got this! 💪", "Take your daily Vitamin G 💊", "Your goals are waiting ☀️", "One step closer today 🌱", "Make it happen 🔥". The notification title remains the app name or "Good morning".
- **D-17:** The inspirational message array lives in `NotificationScheduler.swift` (or a new `NotificationCopy.swift` helper). Selection rotates by day — `Calendar.current.ordinality(of: .day, in: .year, for: Date()) % messages.count` — so the same message plays all day but changes daily.

### Claude's Discretion
- Exact NOTIF-01 chip pre-selection (D-15): use 8 AM as default, matches `NotificationPreferences.defaultHour`.
- Visual layout of AboutView (header photo, bio text styling — follow VGTheme clay/sand palette and Cormorant Garamond for headings).
- TipJarView tier card layout (emoji size, card border/shadow treatment — follow VGTheme surface/card patterns from prior phases).
- Exact inspirational message copy in the rotating array (D-16) — keep it short, warm, and on-brand.
- StepBarView `total:` count when NOTIF-01 step is conditionally shown (can use 9 when shown, 8 when not, or show a constant 9 and hide the dot for skipped steps).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Requirements
- `.planning/ROADMAP.md` §Phase 19 — goal, success criteria, requirements list (MON-01–MON-04, SET-01–SET-05, NOTIF-01–NOTIF-02)
- `.planning/REQUIREMENTS.md` §MON-01–MON-04, §SET-01–SET-05, §NOTIF-01–NOTIF-02 — full requirement definitions

### Existing Views to Modify
- `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift` — extend Form with Appearance, Privacy, Support sections; add "About Vitamin G" NavigationLink row (SET-02–SET-05)
- `VitaminG/VitaminG/VitaminG/Views/ProfileView.swift` — no structural changes needed; existing NavigationLink to SettingsView already wired
- `VitaminG/VitaminG/VitaminG/VitaminGApp.swift` — add `@AppStorage("vg_colorScheme")` and `.preferredColorScheme()` modifier on WindowGroup (SET-04); confirm `Transaction.updates` listener already present (MON-03)
- `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` — update notification body to use rotating inspirational message + top goal title (D-16, D-17)

### Onboarding Flow (Phase 17 established — must read before modifying)
- `.planning/phases/17-onboarding-overhaul/17-CONTEXT.md` — D-06 establishes the 8-step onboarding sequence; NOTIF-01 inserts conditionally after Step 6
- `VitaminG/VitaminG/VitaminG/Views/Onboarding/` — onboarding step views; find NotificationOnboardingScreen to wire the conditional nudge-time step after it

### Services and Utilities to Reuse
- `VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift` — `defaultHour`, `defaultMinute`, `save(hour:minute:)` — use in NOTIF-01 screen to persist selected time
- `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` — `reschedule(activeGoals:)` — call after user picks nudge time in NOTIF-01 and after user changes time in Settings
- `VitaminG/VitaminG/VitaminG/VGTheme.swift` — color system, typography (Cormorant Garamond headings, system font body), clay/sand palette — use for AboutView and TipJarView

### StoreKit 2
- No third-party StoreKit wrapper — use `import StoreKit` directly. Products fetched via `Product.products(for: productIDs)`. Purchases via `product.purchase()`. `Transaction.updates` at app init for delivery.
- App Store Connect: 3 consumable IAP product IDs must be configured before real-device testing (noted in STATE.md pending todos: Small Coffee ~$0.99, Large Coffee ~$2.99, Supporter ~$4.99)

### Brand + Design
- `VitaminG/VitaminG/VitaminG/VGTheme.swift` — clay/sand palette, VGTheme.surface for cards, VGTheme.terra accent, VGTheme.sandLight backgrounds

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SettingsView.swift` — already a functional Form with notification time DatePicker and win reminder time DatePicker. Extend with new sections rather than rewriting. The Form's `.navigationTitle("Settings")` and `@Query`-based streak display can remain.
- `NotificationPreferences.swift` — `save(hour:minute:)` persists to both standard and App Group UserDefaults (widget-aware). Use directly from NOTIF-01 screen's time chip selection.
- `NotificationScheduler.shared.reschedule(activeGoals:)` — existing reschedule entry point; call after nudge-time selection in onboarding and after Settings change.
- `.fullScreenCover` pattern — existing in `GoalListView.swift` for `pendingMilestone` celebration. Replicate for TipJarView post-purchase thank-you.
- `ProfileView.shareAndSettings` — already has a `NavigationLink(destination: SettingsView())` at line 471. No changes needed here — SettingsView gains the About row as a new section row.

### Established Patterns
- Clay/sand background on scroll views: `VGTheme.sandLight.ignoresSafeArea()`
- Cormorant Garamond for page headings: `.font(.custom("CormorantGaramond-Regular", size: 34))`
- VGTheme.surface for card backgrounds with `RoundedRectangle(cornerRadius: 12)`
- `@AppStorage` keys use `vg_` prefix (e.g., `vg_blockedUserIDs` from Phase 17 D-15)
- Streak display in SettingsView already uses `LinearGradient(colors: [VGTheme.accentTerra, VGTheme.accentPurple])` — follow this pattern for other gradient accents

### Integration Points
- `VitaminGApp.swift` → WindowGroup → needs `@AppStorage("vg_colorScheme")` + `.preferredColorScheme()` for SET-04
- `SettingsView` → `AboutView` → `TipJarView` (navigation chain: Profile → Settings → About → Tip Jar)
- Onboarding flow: `NotificationOnboardingScreen` (Step 6) → [if permission granted] `NudgeTimePickerScreen` → `CameraPermissionScreen` → `CommunityGoalOnboardingScreen`
- `NotificationScheduler` body text update affects all users who already have notifications scheduled — reschedule should fire on next app launch or via `reschedule()` call in `onAppear` of SettingsView (already done in existing code for time sync)

</code_context>

<specifics>
## Specific Ideas

- Contact Support email: `VitaminG.info@gmail.com` (confirmed by user). Subject line: "Vitamin G Support".
- Notification copy rotating array must include: "You got this! 💪", "Take your daily Vitamin G 💊", "Your goals are waiting ☀️". User wants an inspirational/motivational tone — "Vitamin G for Gratitude" brand voice.
- About page founder bio: cancer recovery and goal-setting story — exact text must be used verbatim (check if it exists in a resource file or hardcoded string constant in the codebase; do not paraphrase).
- App version display on About: use `Bundle.main.infoDictionary?["CFBundleShortVersionString"]` + `CFBundleVersion` for build number.

</specifics>

<deferred>
## Deferred Ideas

- **"Watch an ad to support creator"**: Out of scope for Phase 19 and all future phases while the no-third-party-dependency policy holds. Requires ad SDK (e.g., AdMob), ATT prompt, Privacy Manifest update, and creates App Store review risk under Guideline 3.2.1(vii). User asked about this — noted and declined.
- **Block reversal from Settings**: Phase 17 D-15 blocks users via UserDefaults `vg_blockedUserIDs`. Unblocking from Settings is a future phase feature.
- **Supporter tier perks / feature gates behind tips**: MON-04 explicitly prohibits feature gates behind tips. Any future "supporter benefits" belong in a new milestone.

</deferred>

---

*Phase: 19-tip-jar-about-page-settings*
*Context gathered: 2026-05-20*
