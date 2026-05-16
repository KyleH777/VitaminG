# Phase 7: Add user profiles with privacy toggle, profile picture upload, and AI-generated character avatar - Context

**Gathered:** 2026-04-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a personal identity layer with optional social sharing. Users get a profile (display name + color/initials avatar), a profile-level privacy toggle (public vs. private), a per-goal public/private toggle, and a share link that lets others view the public profile. No photo upload or AI API in this phase — the avatar is a randomly-assigned color + initials placeholder. This is a post-App Store bolt-on (Phase 7, after Phase 6 distribution).

</domain>

<decisions>
## Implementation Decisions

### Avatar
- **D-01:** The avatar is a **color placeholder with initials** — a randomly-assigned background color and the user's initials displayed on top. No AI API, no photo upload in this phase.
- **D-02:** Color assignment is random at profile creation and persists (not re-randomized on each load). User cannot change the color in Phase 7 (extensible in a future phase).
- **D-03:** Photo upload is explicitly deferred to a future phase. The profile model must be designed to accommodate a photo field later (optional `Data?` slot in the model or a URL field).

### Privacy — Profile level
- **D-04:** Profile has a **Public / Private toggle**. Default: Private.
- **D-05:** When Public: profile and public goals are visible to anyone who has the share link. The profile is stored in CloudKit's **public database** so recipients can read it without authentication.
- **D-06:** When Private: profile is not accessible externally. The Share Profile button is disabled/grayed out.
- **D-07:** Sharing mechanism is a **deep link** (e.g., `vitaming://profile/<recordID>`) generated from the CloudKit public record ID. User taps "Share Profile" → system share sheet with link. No username search, no follow system.

### Privacy — Per-goal level
- **D-08:** Each goal has a `isPublic: Bool` field (default: `false` — all goals are private by default).
- **D-09:** The public/private toggle is surfaced on **GoalDetailView** and in the **EditGoalView** form. When a goal is public, it appears in the public profile preview on the Profile tab.
- **D-10:** The `isPublic` field requires a **SchemaV2 migration** — it must be added to the existing `Goal` model via a new `VersionedSchema` version.

### Profile tab + entry point
- **D-11:** Profile is a **4th tab** in the existing TabView in `ContentView`. Tab label: "Profile" with an appropriate SF Symbol (e.g., `person.crop.circle`).
- **D-12:** Profile tab layout:
  1. Avatar (color + initials, large, centered)
  2. Display name + edit button
  3. Privacy toggle (Public / Private)
  4. "Public goals" preview — list of goals where `isPublic == true`
  5. Share Profile button (disabled when Private)
  - Exact visual design is Claude's discretion via the UI-SPEC.

### UserProfile data model
- **D-13:** New `UserProfile` SwiftData model added in **SchemaV2**:
  - `id: UUID`
  - `displayName: String?` (max 50 chars, same validation pattern as goal titles)
  - `avatarColorHex: String?` (randomly assigned hex color, persisted)
  - `isPublic: Bool` (default: false)
  - `cloudKitPublicRecordID: String?` (populated when profile is first made public, used to generate share link)
  - `photoData: Data?` — reserved nil field for future photo upload; not surfaced in Phase 7 UI
- **D-14:** There is exactly **one UserProfile per device/iCloud account**. The app creates it automatically on first launch (or first visit to the Profile tab) if one does not exist.

### SchemaV2 migration
- **D-15:** SchemaV2 must add:
  1. `UserProfile` model to `SchemaV2.models`
  2. `isPublic: Bool = false` property to `Goal` (lightweight migration — default value provided)
  3. `SchemaMigrationPlan` updated to include the V1 → V2 migration stage
  4. `ModelContainerFactory` updated to use `SchemaV2` as the current schema

### Claude's Discretion
- Exact SF Symbol for the Profile tab
- Avatar color palette (warm, gratitude-toned — should feel personal and positive, not random/cold)
- Visual treatment of the privacy toggle (segmented control vs. iOS toggle vs. custom)
- Display name character limit enforcement (recommend 50 chars, matching existing pattern)
- Deep link URL scheme registration in Info.plist
- Share sheet copy ("Check out my Vitamin G goals!")
- Empty state for Profile tab when no public goals exist
- Error handling for CloudKit public database write failures

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing data layer (SchemaV1 — being extended to V2)
- `VitaminG/VitaminG/VitaminG/Models/SchemaV1.swift` — Current VersionedSchema with Goal and CompletionEvent; V2 must extend this, not replace it
- `VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift` — Container factory; must be updated to reference SchemaV2 and the migration plan
- `VitaminG/VitaminG/VitaminG/Models/Goal.swift` — GoalTier enum and colors; `isPublic` field adds here

### Existing navigation
- `VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift` — Add `.profile` case for profile deep-link navigation if needed
- `VitaminG/VitaminG/VitaminG/Views/ContentView.swift` — Add 4th Profile tab to TabView here
- `VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift` — Add public/private toggle here (D-09)

### Existing views to modify
- `VitaminG/VitaminG/VitaminG/Views/AddGoalView.swift` — Pattern to follow for form field + toggle in EditGoalView

### Requirements
- `.planning/REQUIREMENTS.md` — All active requirements; Phase 7 requirements are TBD (new requirements should follow naming pattern PROF-01, PROF-02, etc.)

### Architecture decisions from prior phases
- `.planning/phases/01-foundation/01-CONTEXT.md` — VersionedSchema pattern, App Group, CloudKit configuration
- `.planning/phases/02-core-goal-ui/02-CONTEXT.md` — Navigation pattern (AppRoute), GoalDetailView pattern, form reuse pattern

### Project constraints
- `.planning/PROJECT.md` — Stack constraints (Swift/SwiftUI/SwiftData, no third-party deps unless necessary), MVVM enforcement, App Store guidelines

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SchemaV1.Goal` — Add `isPublic: Bool = false` in SchemaV2 migration; existing `@Model` pattern is the template
- `AddGoalView / EditGoalView` — Form + validation pattern to follow for ProfileEditView
- `SettingsView` — Streak display pattern (prominent number) can inform profile stat display
- `AppRoute` — Already has `.stats` and `.settings` cases; add `.profile` if needed for navigation

### Established Patterns
- MVVM: all business logic in `@Observable` ViewModel — `ProfileViewModel` required
- VersionedSchema: V2 must follow SchemaV1 pattern exactly — new models declared inside the enum, typealiases exported
- Input validation: max character limits enforced at ViewModel layer before SwiftData insert (pattern from GoalViewModel)
- CloudKit: `ModelContainerFactory` already configures `cloudKitDatabase: .automatic` — public database access requires a separate `CKContainer` / `CKDatabase` reference for the public record writes

### Integration Points
- `ContentView.swift` TabView — 4th tab added here
- `GoalDetailView.swift` — Public/private toggle added to existing detail view
- `ModelContainerFactory.swift` — Schema version bump here
- New file: `VitaminG/VitaminG/VitaminG/Models/SchemaV2.swift` — New VersionedSchema
- New file: `VitaminG/VitaminG/VitaminG/ViewModels/ProfileViewModel.swift`
- New file: `VitaminG/VitaminG/VitaminG/Views/ProfileView.swift`

</code_context>

<specifics>
## Specific Ideas

- The avatar color should feel warm and personal — not random cold tech colors. Consider a palette drawn from the app's tier color system (warm golds, greens, blues) so the avatar feels like it belongs in Vitamin G.
- The streak number in SettingsView is described as a "dopamine hit" (Phase 4 context) — the profile should carry the same warm, celebratory tone. Not a corporate LinkedIn profile; more like a personal gratitude card.
- Goals are private by default — this should be explicit in the onboarding for the Profile tab the first time a user visits it. A brief empty state explaining "Your goals are private. Mark any goal public to share it on your profile."

</specifics>

<deferred>
## Deferred Ideas

- **Photo upload** — User expressed interest but chose to defer for privacy/security reasons. Future phase: ProfileView already has a `photoData: Data?` slot reserved.
- **Avatar color customization** — User cannot change their assigned avatar color in Phase 7. Could be a future "Personalize" feature.
- **Username / search** — No username search in Phase 7. Share link only. Username lookup could be a future social expansion.
- **Follow / friends system** — Not in scope for Phase 7. Share link is the only social mechanic.

</deferred>

---

*Phase: 07-add-user-profiles-with-privacy-toggle-profile-picture-upload*
*Context gathered: 2026-04-13*
