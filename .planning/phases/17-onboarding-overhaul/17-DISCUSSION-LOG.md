# Phase 17: Onboarding Overhaul — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-16 (updated 2026-05-16)
**Phase:** 17-onboarding-overhaul
**Areas discussed:** Auth + Welcome screen, Onboarding step sequence, T&C acknowledgment design, PROF-05 report/block scope, GoalCreationWizardView in flow, Username race condition UX, T&C PDF asset, Report mechanism (session 2)

---

## Auth + Welcome screen

### Q1: CTA structure after removing Google and "Create account"

| Option | Description | Selected |
|--------|-------------|----------|
| Sign in with Apple only (Recommended) | One primary CTA: black Apple button. No separate "Create account" path. Small "Skip for now" text link remains below. | |
| Sign in with Apple + Skip | Two CTAs: Apple Sign-In (primary) + "I'll set this up later" (ghost). Same as current minus Google and Create Account. | |
| Remove skip entirely — auth is mandatory | Only Sign in with Apple. No skip option. | ✓ |

**User's choice:** Remove skip entirely — auth is mandatory
**Notes:** Auth is a hard requirement going forward.

---

### Q2: Visual design / animation

| Option | Description | Selected |
|--------|-------------|----------|
| Keep animation — it's on-brand (Recommended) | Raining tablet animation stays. Only button area changes. | |
| Refresh layout but keep animation | Same tablet rain, reposition headline and button area. | |
| Mix of 1 and 2 (free text) | Keep animation + clay design; remove all non-Apple-Sign-In buttons; move tagline. | ✓ |

**User's choice:** Keep animation + clay design; remove all options that aren't Apple Sign-In; move the tagline.
**Notes:** Tagline "GOALS. GROWTH. COMMUNITY." moves to above the app icon.

---

### Q3: Tagline placement

| Option | Description | Selected |
|--------|-------------|----------|
| Above the app icon (Recommended) | Tagline sits at top of center content block, above the app icon. | ✓ |
| Below the Apple Sign-In button | Tagline moves to footer area beneath the CTA. | |
| You decide placement | Planner picks best visual position given single-button layout. | |

**User's choice:** Above the app icon

---

### Q4: Returning user routing after Apple Sign-In

| Option | Description | Selected |
|--------|-------------|----------|
| Route to the Welcome Back screen (Recommended) | LoginScreen shows "Good to see you" + name. Confirm identity, jump into app. | ✓ |
| Route directly into the app (skip Welcome Back) | Apple Sign-In credential alone is sufficient. | |
| Always run full onboarding for returning users | All new onboarding steps again. | |

**User's choice:** Route to the Welcome Back screen

---

## Onboarding step sequence

### Q1: Fate of NameScreen

| Option | Description | Selected |
|--------|-------------|----------|
| Pre-fill NameScreen from Apple credential (Recommended) | Show NameScreen with name pre-filled from Apple fullName; user can edit. | ✓ |
| Skip NameScreen — use Apple name directly | Save Apple name automatically; skip the screen. | |
| Keep NameScreen as-is, ignore Apple name | Always show empty NameScreen; user types manually. | |

**User's choice:** Pre-fill NameScreen from Apple credential

---

### Q2: Fate of MotivationCategoryScreen and CommunityGoalOnboardingScreen

| Option | Description | Selected |
|--------|-------------|----------|
| Remove both from onboarding (Recommended) | Leaner onboarding; features live elsewhere. | |
| Keep both as-is | Preserve existing flow; insert new steps around them. | |
| Keep CommunityGoal, remove MotivationCategory | CommunityGoal surfaces the primary community goal shown on new Home tab. | ✓ |

**User's choice:** Keep CommunityGoal, remove MotivationCategory

---

### Q3: New step sequence

| Option | Description | Selected |
|--------|-------------|----------|
| T&C → Name → Username → Profile Picture → Notification → Camera → CommunityGoal → App (Recommended) | Legal first, then identity, then permissions, then community hook. | ✓ |
| Name → Username → T&C → Profile Picture → Notification → Camera → CommunityGoal → App | Personal identity before legal. | |
| T&C → Name → Username → Notification → Camera → Profile Picture → CommunityGoal → App | Permissions before photo. | |

**User's choice:** T&C → Name → Username → Profile Picture → Notification → Camera → CommunityGoal → App

---

### Q4: Username uniqueness check timing

| Option | Description | Selected |
|--------|-------------|----------|
| Inline debounced check while typing (Recommended) | Spinner + ✓/✗ feedback 500ms after user stops typing. Continue disabled until confirmed. | ✓ |
| Check on 'Continue' tap only | Blocking spinner fires on submit. One network call per attempt. | |
| You decide | Planner picks implementation approach. | |

**User's choice:** Inline debounced check while typing

---

## T&C acknowledgment design

### Q1: PDF presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Sheet modal with PDF via QuickLook (Recommended) | T&C step shows doc + "Read Terms" button. QuickLook sheet. Dismiss to return. | ✓ |
| Inline scrollable text | T&C text rendered in ScrollView on the step itself. | |
| External link only | Tappable link opens PDF in Safari. | |

**User's choice:** Sheet modal with PDF via QuickLook

---

### Q2: Acknowledgment mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| 'I Agree' button only (Recommended) | Primary CTA is "I Agree — Continue". No checkbox. | ✓ |
| Checkbox + 'Continue' button | User must check box before Continue enables. | |
| Must open PDF first, then 'I Agree' unlocks | Continue disabled until PDF opened. | |

**User's choice:** 'I Agree' button only

---

### Q3: PDF storage location

| Option | Description | Selected |
|--------|-------------|----------|
| Bundled in the app bundle (Recommended) | Vitamin_G_Terms_and_Conditions.pdf included in Xcode project. QuickLook renders it. | ✓ |
| Hosted at a URL (not bundled) | PDF at a web URL. SFSafariViewController. Allows T&C updates without app update. | |

**User's choice:** Bundled in the app bundle

---

## PROF-05 report/block scope

### Q1: Which profile surfaces

| Option | Description | Selected |
|--------|-------------|----------|
| ProfileView only (Recommended) | Existing v1.0 profile screen. Phase 22 carries forward to full redesign. | ✓ |
| ProfileView + community post/card author taps | Broader coverage. More work. | |
| Wait for Phase 22 | No public-profile UGC surfaces currently. Defer PROF-05 entirely. | |

**User's choice:** ProfileView only

---

### Q2: Report action

| Option | Description | Selected |
|--------|-------------|----------|
| Pre-filled email to support (Recommended) | MFMailComposeViewController with pre-filled subject/body. No new CloudKit record type. | ✓ |
| CloudKit flag record | Report record in CloudKit public DB. Requires new record type. | |
| In-app reason picker + email | ActionSheet with reason options, then pre-filled email. | |

**User's choice:** Pre-filled email to support

---

### Q3: Block behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Local block list in UserDefaults (Recommended) | Set<String> of blocked Apple User IDs in UserDefaults. Feed filters client-side. | ✓ |
| CloudKit private DB block record | Syncs across devices. More complex. | |
| Session-only hide (no persistence) | Not persistent. | |

**User's choice:** Local block list in UserDefaults

---

## Claude's Discretion

- Exact visual layout of the T&C screen (headline, subtitle, PDF preview card) — planner follows Vitamin G brand spec (clay/sand palette, Georgia serif, VGTheme).
- StepBarView `total:` count — confirmed as 7 (T&C, Name, Username, ProfilePicture, Notifications, Camera, CommunityGoal).

## Session 2 — Decisions Locked (2026-05-16)

### GoalCreationWizardView in flow (D-16)

| Option | Description | Selected |
|--------|-------------|----------|
| Remove the enum case entirely | Delete `.createGoal` case and its `navigationDestination` block. Phase 18 redesigns — no dead code. | ✓ |
| Keep the case, just don't route to it | Leave in enum but remove from sequence. Lower-risk but leaves dead code. | |
| Keep it as-is, adjust in Phase 18 | Don't touch in Phase 17. Phase 18 decides. | |

**User's choice:** Remove the enum case entirely
**Notes:** `.createGoal` case removed along with `.motivationCategories`. `GoalCreationWizardView(isOnboarding: true)` call removed.

---

### Username race condition UX (D-17)

| Option | Description | Selected |
|--------|-------------|----------|
| Inline error on UsernameScreen | Delete conflicting record, clear field, show "That username was just taken — try another." No alert. | ✓ |
| Alert, then return to UsernameScreen | System alert, user dismisses, field cleared. | |
| Silent retry on a derived username | Auto-append random suffix, only prompt if retry fails. | |

**User's choice:** Inline error on UsernameScreen
**Notes:** Consistent with the debounce inline feedback UX. No blocking modal.

---

### T&C PDF asset (D-18)

| Option | Description | Selected |
|--------|-------------|----------|
| Add existing PDF to Xcode target | Copy to Resources/, add to app target. File already exists at project root. | ✓ |
| Embed a placeholder, update later | Placeholder PDF for testing; real PDF before submission. | |
| Link to hosted URL instead | SFSafariViewController + live URL. No bundle change. | |

**User's choice:** Add existing PDF to Xcode target
**Notes:** `Vitamin_G_Terms_and_Conditions.pdf` confirmed at `~/Desktop/AI/Vitamin G/`. Target destination: `VitaminG/VitaminG/VitaminG/Resources/`.

---

### Report mechanism confirmation (D-14 locked)

| Option | Description | Selected |
|--------|-------------|----------|
| MFMailCompose with mailto: fallback | `canSendMail()` check; rich sheet if true; mailto: URL if false. | ✓ |
| mailto: URL only | Always open via URL. Simpler but body params unreliable on some mail apps. | |

**User's choice:** MFMailComposeViewController with mailto: fallback
**Notes:** D-14 was already the stated approach; now explicitly locked out of "Claude's Discretion."

---

## Deferred Ideas

- Block list management in Settings (view blocked users, unblock) — Phase 19 Settings page.
- CloudKit-backed block list sync across devices — v3.0.
- Report reason picker before email — deferred; plain pre-filled email sufficient for App Store compliance.
