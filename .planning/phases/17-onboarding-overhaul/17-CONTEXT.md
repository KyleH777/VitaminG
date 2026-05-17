# Phase 17: Onboarding Overhaul — Context

**Gathered:** 2026-05-16 (updated 2026-05-16)
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the multi-option auth welcome screen with Apple Sign-In as the sole, mandatory auth path. Rework the onboarding step sequence to gate legal acknowledgment (T&C PDF) before identity setup, add unique username claim with async CloudKit uniqueness check, add optional profile picture upload, add camera permission priming, and remove MotivationCategoryScreen and the GoalCreationWizard step from the flow. Update LoginScreen (Welcome Back) to route returning users through after Apple re-authentication. Add Report/Block actions to ProfileView (App Store Guideline 1.2, required alongside profile photos). No new schema migration (SchemaV8 already has `username` and `photoData`).

</domain>

<decisions>
## Implementation Decisions

### Auth + Welcome Screen
- **D-01:** Auth is mandatory — no skip option. Sign in with Apple is the only CTA on WelcomeScreen. Remove the Google stub button and "Create account" button entirely.
- **D-02:** Keep raining-tablets animation and clay/sand visual design. Only the button area changes. Move "GOALS. GROWTH. COMMUNITY." tagline from below the app name to **above the app icon**.
- **D-03:** After Apple Sign-In succeeds on WelcomeScreen: if the user has a stored `appleUserID` and `vg_onboardingName`, route to LoginScreen (Welcome Back). If no name is stored, proceed into new onboarding.

### Onboarding Step Sequence
- **D-04:** NameScreen stays; pre-fill the display name field from the Apple Sign-In credential's `fullName` (if provided). User can edit before continuing.
- **D-05:** MotivationCategoryScreen is removed from onboarding. CommunityGoalOnboardingScreen is kept.
- **D-06:** New onboarding flow (in order):
  1. WelcomeScreen (Apple Sign-In — sole entry gate)
  2. T&CScreen (new)
  3. NameScreen (pre-filled from Apple fullName)
  4. UsernameScreen (new)
  5. ProfilePictureScreen (new, skippable)
  6. NotificationOnboardingScreen (existing)
  7. CameraPermissionScreen (new)
  8. CommunityGoalOnboardingScreen (existing)
  9. → App (hasCompletedOnboarding = true)
- **D-07:** Username uniqueness check fires inline debounced (500ms after user stops typing). Shows a spinner while checking, then ✓ (available) or ✗ (taken) inline beneath the field. Continue button is disabled until the username is confirmed available.
- **D-16:** Remove the `.createGoal` `OnboardingStep` enum case entirely (was wired to `GoalCreationWizardView(isOnboarding: true)`). Delete the case and its `navigationDestination` block. Phase 18 redesigns goal creation from scratch — no point maintaining dead code for one phase.

### T&C Acknowledgment
- **D-08:** T&C PDF (`Vitamin_G_Terms_and_Conditions.pdf`) is bundled in the app bundle. The file exists at the project root and must be copied into `VitaminG/VitaminG/VitaminG/Resources/` and added to the app target in Xcode (see D-18). The T&C step shows a brief description and a "Read Terms" button that opens the PDF via QuickLook in a sheet modal. User dismisses the sheet to return to the step.
- **D-09:** Acknowledgment is a single "I Agree — Continue" primary button. No checkbox. Tapping it records acceptance and advances to NameScreen.
- **D-18:** T&C PDF asset — copy `Vitamin_G_Terms_and_Conditions.pdf` from the project root into `VitaminG/VitaminG/VitaminG/Resources/` and add it to the app target's "Copy Bundle Resources" phase in Xcode. The file already exists and is complete.

### Username Uniqueness
- **D-07:** (see above)
- **D-17:** Username race condition UX — If the post-save CloudKit re-check finds the username was claimed between the availability check and the write: delete the conflicting record written by this device, return the user to `UsernameScreen` with the field cleared, and show an inline error message "That username was just taken — try another." No blocking alert. Flow stays within `UsernameScreen`.

### Welcome Back Screen (Returning Users)
- **D-10:** LoginScreen already exists with the correct "Good to see you" copy and profile card. For Phase 17, update it so returning users who are not yet re-authenticated reach it via WelcomeScreen after Sign in with Apple. The "Continue as [name]" card taps through to the app (hasCompletedOnboarding = true path).
- **D-11:** AUTH-07 requires Sign in with Apple button on the Welcome Back screen. Add the Apple Sign-In button as an explicit CTA on LoginScreen for the case where `appleUserID` is set but the credential needs re-validation (e.g., after reinstall). Tapping it triggers `ASAuthorizationController` and on success completes the re-auth.

### PROF-05 — Report/Block
- **D-12:** Report/Block added to ProfileView only (the existing v1.0 profile screen). Phase 22 carries the pattern forward to the full public profile redesign.
- **D-13:** Entry points: (1) long-press `.contextMenu` on the user's avatar and on their display name/handle; (2) an explicit "Report or Block" button on the profile view. Both entry points surface the same two actions.
- **D-14:** Report action: check `MFMailComposeViewController.canSendMail()` first. If true, present the rich compose sheet (pre-populated subject: `[Vitamin G] Report User: @{username}`, body with reporter's Apple user ID, reported username, timestamp, and a prompt for description). If false (no Mail account configured), fall through to a `mailto:` URL with the same subject and body. This is now locked — do not defer to planner.
- **D-15:** Block action: stores the blocked user's Apple User ID in a `Set<String>` persisted to `UserDefaults` (key: `vg_blockedUserIDs`). Community feed filters out blocked users client-side. Confirmation alert shown before blocking. Block is reversible from Settings (future phase).

### Claude's Discretion
- Exact visual layout of the T&C screen (headline, subtitle, PDF preview card) — planner follows Vitamin G brand spec (clay/sand palette, Georgia serif, VGTheme).
- StepBarView `total:` count update to match the new step count (7 steps: T&C, Name, Username, ProfilePicture, Notifications, Camera, CommunityGoal).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Requirements
- `.planning/ROADMAP.md` §Phase 17 — goal, success criteria, requirements list (AUTH-01–AUTH-07, PROF-05)
- `.planning/REQUIREMENTS.md` §AUTH-01–AUTH-07, §PROF-05 — full requirement definitions with acceptance criteria detail

### Files to Modify
- `VitaminG/VitaminG/VitaminG/Views/Onboarding/WelcomeScreen.swift` — remove Google stub + "Create account" button; keep only Sign in with Apple; move tagline above app icon; route returning users to LoginScreen
- `VitaminG/VitaminG/VitaminG/Views/Onboarding/OnboardingView.swift` — add new cases to `OnboardingStep` enum (`.termsAndConditions`, `.username`, `.profilePicture`, `.cameraPermission`); remove `.motivationCategories` case; **remove `.createGoal` case entirely** (D-16); update `navigationDestination` wiring; reorder steps
- `VitaminG/VitaminG/VitaminG/Views/Onboarding/OnboardingViewModel.swift` — extend to manage T&C acknowledgment state, username validation async task, photo data, race condition recovery (D-17)
- `VitaminG/VitaminG/VitaminG/Views/Onboarding/LoginScreen.swift` — add Sign in with Apple button for re-authentication (AUTH-07)
- `VitaminG/VitaminG/VitaminG/Views/Onboarding/NameScreen.swift` — accept pre-filled name from Apple credential; pass credential through
- `VitaminG/VitaminG/VitaminG/Views/Onboarding/MotivationCategoryScreen.swift` — remove from flow (file can stay but is no longer referenced)

### New Files to Create
- `VitaminG/.../Views/Onboarding/TermsAndConditionsScreen.swift` — new T&C step with QuickLook sheet + "I Agree" button
- `VitaminG/.../Views/Onboarding/UsernameScreen.swift` — new username claim step with debounced CKQuery + race condition recovery (D-17)
- `VitaminG/.../Views/Onboarding/ProfilePictureScreen.swift` — new profile picture upload step (skippable, PHPickerViewController + UIImagePickerController)
- `VitaminG/.../Views/Onboarding/CameraPermissionScreen.swift` — new camera permission priming slide (AVCaptureDevice.requestAccess)

### Bundle Asset
- `VitaminG/VitaminG/VitaminG/Resources/Vitamin_G_Terms_and_Conditions.pdf` — T&C PDF must be copied here and added to Xcode target (D-18). Source file is at project root: `Vitamin_G_Terms_and_Conditions.pdf`.

### Profile View (PROF-05)
- `VitaminG/VitaminG/VitaminG/Views/ProfileView.swift` (or equivalent) — add Report/Block `.contextMenu` on avatar and display name; add explicit Report or Block button

### Architecture Reference
- `VitaminG/VitaminG/VitaminG/VitaminGApp.swift` — `@AppStorage("hasCompletedOnboarding")` usage; `@AppStorage("vg_appleUserID")` storage pattern
- `VitaminG/VitaminG/VitaminG/Views/Onboarding/NotificationOnboardingScreen.swift` — existing priming slide pattern to reuse for CameraPermissionScreen

### Prior Phase Context
- `.planning/phases/16-tab-restructuring-approute-updates/16-CONTEXT.md` — Phase 16 deferred the PROF-05 long-press contextMenu UX detail to Phase 17; read before implementing Report/Block

### App Store Compliance
- PROF-05 requirement: App Store Guideline 1.2 requires user-generated-content moderation (Report + Block) whenever profile photos are shown — Phase 17 ships photos, so this is a hard blocker for App Review

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `WelcomeScreen`: `SignInWithAppleButton` already fully wired with `onRequest`/`onCompletion` handlers and `@AppStorage("vg_appleUserID")`. Only remove the other 3 buttons and reposition the tagline.
- `NotificationOnboardingScreen`: Full-screen dark permission priming slide — reuse this exact pattern (dark clay bg, mock preview card, primary CTA + "Maybe later" secondary) for the new `CameraPermissionScreen`.
- `StepBarView`: Reusable step progress indicator — update `total:` to 7 (T&C, Name, Username, ProfilePicture, Notifications, Camera, CommunityGoal).
- `NameScreen`: `@AppStorage("vg_onboardingName")` pattern + `StepBarView` — extend to accept an optional `prefilledName: String?` parameter from Apple credential.
- `LoginScreen`: "Welcome Back" layout already done — just add `SignInWithAppleButton` for AUTH-07.
- `VGTheme`: Clay, sand, terra, muted colors + Georgia serif + `VGCapsule` component — all existing; no new design tokens needed.

### Established Patterns
- `OnboardingStep: Hashable` enum + `NavigationStack(path:)` — the step router; add 4 new cases, remove 2 (`.motivationCategories`, `.createGoal`).
- `@AppStorage` for lightweight onboarding state (`vg_onboardingName`, `vg_appleUserID`, `hasCompletedOnboarding`) — continue this pattern; add `vg_onboardingUsername`, `vg_hasAgreedToTerms`.
- `@Observable` ViewModel + `@MainActor` — `OnboardingViewModel` follows this pattern; extend it.
- `AuthenticationServices.SignInWithAppleButton` — already imported in `WelcomeScreen`; reuse in `LoginScreen`.
- `PHPickerViewController` for photo library access — iOS 17+ compatible; use `PhotosUI` import.
- CloudKit async query pattern for username check: `CKDatabase.records(matching:)` async/await — check → write → re-verify sequence; on conflict: delete and show D-17 inline error.
- `MFMailComposeViewController.canSendMail()` check before presenting; `mailto:` URL fallback if false (D-14).

### Integration Points
- `WelcomeScreen` onCompletion handler routes into `OnboardingView.path` — the returning-user routing (D-03) needs to check `appleUserID` + `savedName` before appending to path.
- `OnboardingView.finish()` sets `hasCompletedOnboarding = true` — all paths (including Welcome Back) must call through this or set the flag directly.
- SchemaV8 already defines `username` and `photoData` on the user's local SwiftData model — `UsernameScreen` and `ProfilePictureScreen` write to these fields during onboarding.
- `UserDefaults(suiteName: appGroupID)` is used for widget sync — `vg_blockedUserIDs` block list can use standard UserDefaults (no widget dependency).

</code_context>

<specifics>
## Specific Ideas

- WelcomeScreen: "GOALS. GROWTH. COMMUNITY." tagline moves to above the app icon (above the `RoundedRectangle` icon block), keeping the Georgia-Italic label style but repositioned in the center VStack.
- CameraPermissionScreen: Mirror the NotificationOnboardingScreen dark-clay aesthetic — headline "Share your journey", body explaining profile picture and goal photos, primary "Allow Camera" CTA, "Skip for now" secondary link.
- UsernameScreen: Inline ✓/✗ feedback beneath the text field (500ms debounce); use a subdued color (VGTheme.sage for available, VGTheme.terra for taken); Continue button uses `.disabled()` binding. Race condition recovery: clear field + inline error "That username was just taken — try another." (D-17).
- Report email subject: `"[Vitamin G] Report User: @{username}"` with body template including reporter context and timestamp.
- Block confirmation: Alert with title "Block [username]?" and message "They won't appear in your community feed." with "Block" (destructive role) and "Cancel" actions.
- Phase 16 deferred (PROF-05 gesture): `.contextMenu` modifier on avatar `Circle` and on the display name `Text` on ProfileView — same menu items as the explicit button.

</specifics>

<deferred>
## Deferred Ideas

- Block list management in Settings (view blocked users, unblock) — Future phase (likely Phase 19 Settings page).
- CloudKit-backed block list sync across devices — v3.0; UserDefaults local list is sufficient for v2.0.
- Report reason picker (Spam / Harassment / Inappropriate / Other) before email — deferred; plain pre-filled email is sufficient for App Store compliance now.

</deferred>

---

*Phase: 17-onboarding-overhaul*
*Context gathered: 2026-05-16*
