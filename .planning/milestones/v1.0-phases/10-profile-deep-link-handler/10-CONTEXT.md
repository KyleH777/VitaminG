# Phase 10: Profile Deep Link Handler - Context

**Gathered:** 2026-04-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement the incoming `vitaming://profile/<recordID>` receive path. When someone taps a shared profile link, the app opens and presents a lightweight `PublicProfileView` showing the linked user's avatar and display name (fetched from CloudKit public database). The link-send path (Phase 7) and URL scheme registration (Info.plist) are already complete — this phase wires the receive side only.

</domain>

<decisions>
## Implementation Decisions

### Destination View
- **D-01:** Build a new `PublicProfileView` — a lightweight sheet that shows the linked user's color avatar (initials + hex color) and display name, fetched from CloudKit public database using the `recordID`.
- **D-02:** Content is **avatar + display name only**. Public goal titles are NOT stored in the CloudKit public record (only `displayName` and `avatarColorHex` are there per Phase 7's `ProfileSharingService`). Showing goals would require a data model redesign that is out of scope for Phase 10.
- **D-03:** A new `ProfileSharingService.fetchProfile(recordID:)` function must be added to read a `PublicProfile` CKRecord from CloudKit public database.

### AppRoute Change
- **D-04:** Add a new `AppRoute.publicProfile(recordID: String)` case. Do **not** modify the existing `.profile` case — it is used for own-profile navigation and NOTIF-07 compatibility.
- **D-05:** `AppRoute.publicProfile` is the route that the `.onOpenURL` handler resolves to. `AppRoute.profile` remains the route for navigating to the current user's own Profile tab.

### Tab Switch / Presentation
- **D-06:** `PublicProfileView` is presented as a **sheet** over whatever tab is active. No tab switching. No push onto NavigationStack. This works from any tab and handles cold launch without timing issues.
- **D-07:** `AppRouter` owns the sheet trigger: add `pendingPublicProfileRecordID: String?` property to `AppRouter`. Setting it to a non-nil value causes `ContentView` to present the `PublicProfileView` sheet. Clearing it (nil) dismisses.
- **D-08:** `VitaminGApp.body` gets `.onOpenURL { url in ... }` on the `WindowGroup`. The handler parses the URL, extracts the recordID, and sets `router.pendingPublicProfileRecordID = recordID`.

### URL Parsing
- **D-09:** URL format is `vitaming://profile/<recordID>` (matches `DeepLinkBuilder.profileURL()`). Parser checks: scheme == "vitaming", host == "profile", first path component == recordID. Unknown URLs are silently ignored.

### Error / Loading States
- **D-10:** Claude's discretion. Recommended: `PublicProfileView` shows a loading state while fetching, then transitions to content or an inline error message ("This profile is no longer available.") with a Dismiss button. No separate alert — inline state keeps the sheet self-contained and avoids alert-on-alert UX.

### Claude's Discretion
- Exact visual design of `PublicProfileView` (layout, typography, padding) — match the warm tone established in `ProfileView`
- Loading skeleton vs. spinner during CloudKit fetch
- Whether to use `@Observable` ViewModel pattern (consistent with all other views in this project) or inline `@State` for the simple fetch (recommend ViewModel for MVVM consistency)
- Specific error messages for different CKError codes (network vs. record-not-found)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing navigation infrastructure
- `VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift` — Add `.publicProfile(recordID: String)` case here; do not modify `.profile`
- `VitaminG/VitaminG/VitaminG/Navigation/AppRouter.swift` — Add `pendingPublicProfileRecordID: String?` property here
- `VitaminG/VitaminG/VitaminG/VitaminGApp.swift` — Add `.onOpenURL` to `WindowGroup` body; wire to `router.pendingPublicProfileRecordID`
- `VitaminG/VitaminG/VitaminG/Views/ContentView.swift` — Add `.sheet(item:)` or `.sheet(isPresented:)` bound to `router.pendingPublicProfileRecordID`

### Deep link infrastructure (Phase 7)
- `VitaminG/VitaminG/VitaminG/Services/DeepLinkBuilder.swift` — URL format definition (`vitaming://profile/<recordID>`); parser must match this exactly
- `VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift` — Add `fetchProfile(recordID:)` here alongside existing `publishProfile` / `unpublishProfile`

### Data model
- `VitaminG/VitaminG/VitaminG/Models/SchemaV2.swift` — `UserProfile` model for reference; `PublicProfile` CloudKit record fields are `displayName` and `avatarColorHex` only
- `VitaminG/VitaminG/VitaminG/Views/ProfileView.swift` — Visual reference for avatar + name patterns; `AvatarView` component already handles color + initials rendering

### Architecture decisions from prior phases
- `.planning/phases/07-add-user-profiles-with-privacy-toggle-profile-picture-upload/07-CONTEXT.md` — D-07 (deep link format), D-13 (UserProfile fields), CloudKit public database decisions
- `.planning/phases/01-foundation/01-CONTEXT.md` — MVVM enforcement, AppRouter injection pattern, CloudKit container ID

### Project constraints
- `.planning/PROJECT.md` — Stack constraints (no third-party deps), MVVM enforcement, iOS 17+ minimum
- `.planning/REQUIREMENTS.md` — PROF-06 and PROF-07 are the requirements being closed

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppRouter` — Already `@Observable`, already injected at `WindowGroup` level. Add one property for sheet trigger.
- `AvatarView` — Already renders color + initials avatar. Reuse directly in `PublicProfileView`.
- `ProfileSharingService` — Already imports CloudKit, already has the container ID and `recordType = "PublicProfile"`. Extend with a `fetchProfile` function.
- `DeepLinkBuilder` — Already has `scheme = "vitaming"` constant. Parser can import this to avoid string duplication.
- `NotificationDelegate` deep link pattern — `VitaminGApp` already handles one deep link (goalList) via a closure passed to `NotificationDelegate`. The `.onOpenURL` pattern is analogous and fits in the same App struct.

### Established Patterns
- MVVM: All ViewModels use `@Observable` macro (no `ObservableObject`). New `PublicProfileViewModel` should follow this pattern.
- CloudKit async: `ProfileSharingService` uses `async throws` with `await publicDB.record(for:)`. `fetchProfile` should follow the same pattern.
- Error handling: `ProfileViewModel` uses `@Published`-style state via `@Observable`; error states drive `showingCloudKitError` alert. `PublicProfileViewModel` can follow a similar `.loaded` / `.loading` / `.error` state enum.
- Sheet presentation: `ProfileView` uses `viewModel.showingEditSheet` → `.sheet(isPresented:)`. Same pattern for the public profile sheet in `ContentView`.

### Integration Points
- `VitaminGApp.body` → add `.onOpenURL` modifier to `WindowGroup` → sets `router.pendingPublicProfileRecordID`
- `ContentView` → observe `router.pendingPublicProfileRecordID` → present `PublicProfileView` sheet
- `AppRoute.swift` → add `.publicProfile(recordID: String)` case (new — does not break existing cases)
- `AppRouter.swift` → add `var pendingPublicProfileRecordID: String?` (new property, no breakage)
- `ProfileSharingService.swift` → add `fetchProfile(recordID:) async throws -> (displayName: String?, avatarColorHex: String?)` (new method, no breakage)

</code_context>

<specifics>
## Specific Ideas

- The `.onOpenURL` handler in `VitaminGApp` should be symmetric with the existing `NotificationDelegate` closure — both set router state, nothing else
- `PublicProfileView` should feel like a read-only card, not a navigation destination — a sheet with a title bar and a Done/Dismiss button is the right treatment
- CloudKit container ID is already defined in `ProfileSharingService` as `"iCloud.com.kyleharrington.VitaminG"` — reuse this constant, do not hardcode again

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 10-profile-deep-link-handler*
*Context gathered: 2026-04-18*
