# Phase 6: Distribution - Context

**Gathered:** 2026-04-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the app to the App Store. This phase covers: creating `PrivacyInfo.xcprivacy`, preparing App Store metadata and screenshots, promoting the CloudKit schema from Development to Production, validating through TestFlight on a physical device, and submitting for App Store Review.

No new features are added in this phase. The code is complete — this phase is purely delivery infrastructure and store listing assets.

</domain>

<decisions>
## Implementation Decisions

### PrivacyInfo.xcprivacy
- **D-01:** Create `PrivacyInfo.xcprivacy` in the main app target (`VitaminG/`). Required-reason API entry: `NSPrivacyAccessedAPICategoryUserDefaults` with reasons `CA92.1` (app functionality — notification time preference) and `1C8F.1` (app-extension sharing — widget App Group UserDefaults suite `group.com.kyleharrington.VitaminG`).
- **D-02:** No other required-reason APIs needed. The app does not use file timestamp APIs, system boot time APIs, disk space APIs, or active keyboard APIs.
- **D-03:** Photos data type is **not declared** in the privacy manifest or App Store label. The `photoData` field exists in `UserProfile` (SchemaV2) but no photo upload/picker UI was ever implemented — no photo data is collected.

### App Store Privacy Label (App Store Connect)
- **D-04:** Goal titles and descriptions → **Data Linked to You** (User Content category) — synced via CloudKit under the user's Apple ID.
- **D-05:** Display name → **Data Linked to You** (Contact Info / Name category) — stored in iCloud via CloudKit `PublicProfile` record.
- **D-06:** Notification time preference → **not declared** — stored in `UserDefaults` locally, never transmitted off-device.
- **D-07:** No "Data Used to Track You" declarations — the app has no advertising, no analytics SDK, and no cross-app tracking.

### App Store Positioning
- **D-08:** **Category:** Productivity (primary). Goal tracking + daily reminders is productivity-first; Health & Fitness is better suited for workout/diet apps. No secondary category needed.
- **D-09:** **Pricing:** Free, no in-app purchases. This is a portfolio showcase — maximize downloads and exposure over revenue.
- **D-10:** **Age Rating:** 4+ — no objectionable content. Profiles default to private; no user-generated content is publicly visible without explicit opt-in.
- **D-11:** **Description tone:** Warm, personal, intentional. Tagline: "Your daily dose of goals." Lead with the morning reminder value proposition, then list the four-tier goal system as the structural differentiator.
- **D-12:** **Keywords (use all 100 chars):** goal tracker, daily goals, gratitude, habit tracker, productivity, reminders, streaks, life goals, motivation

### Screenshot Strategy
- **D-13:** Submit as **iPhone-only** in App Store Connect. The app has no iPad-optimized layouts; declare iPhone only (the app remains accessible on iPad as a scaled iPhone app).
- **D-14:** **Required screenshot size:** iPhone 6.7" (1290×2796 px) — use Xcode Simulator with iPhone 15 Pro Max target. Apple requires at least one screenshot at this size since 2024.
- **D-15:** **Optional second size:** iPhone 6.5" (1284×2778 px, e.g., iPhone 14 Plus simulator) — covers older max-size iPhones; include if time permits.
- **D-16:** **5 key screens to capture:**
  1. Goal list — all four tiers visible, ideally with sample goals populated
  2. Add/Edit goal sheet — shows the form with tier picker and inspiration field
  3. Stats view — heatmap + streak counts, demonstrating the tracking value
  4. Profile view — avatar, display name, privacy toggle, and share button
  5. Onboarding / welcome screen — first impression for App Store browsers
- **D-17:** **Screenshot approach:** Xcode Simulator screenshots + warm gradient background overlay + one short caption per screenshot. Match the app's warm color palette (amber/yellow tones established in Phase 7's `AvatarView`). No separate design tool required — use Preview or simple image editing.
- **D-18:** Dark mode screenshots optional. Include 1–2 if time allows for polish; not required for initial submission.

### CloudKit Production Sequence
- **D-19:** **CloudKit container ID:** `iCloud.com.kyleharrington.VitaminG` — confirmed in `VitaminG/VitaminG/VitaminG/VitaminG.entitlements`.
- **D-20:** **Required promotion sequence (must follow this exact order):**
  1. Open CloudKit Console (cloudkit.developer.apple.com) → select container `iCloud.com.kyleharrington.VitaminG`
  2. Verify Development schema contains all models from SchemaV1 (`Goal`, `CompletionEvent`) and SchemaV2 (`UserProfile`) — confirm `Goal.isPublic` field is present
  3. Click **Deploy Schema Changes to Production**
  4. Archive app in Xcode: Product → Archive with Release scheme + App Store Connect distribution profile
  5. Upload to TestFlight via Xcode Organizer
  6. Install from TestFlight on a **physical iPhone** signed into iCloud
  7. Run validation: create a goal → complete it → view stats → open profile → toggle public → verify `PublicProfile` record appears in CloudKit Dashboard (Production environment)
  8. If sync verified: submit build for App Store Review in App Store Connect
- **D-21:** **Schema promotion is irreversible for existing fields.** Once Production schema is deployed, fields can only be added — never renamed or removed. Do not promote until all fields from SchemaV1 and SchemaV2 are finalized. (They are — no further schema changes are planned.)
- **D-22:** **TestFlight scope:** Internal testing only (no external beta group needed). Core flows to validate: create goal, complete goal, view stats, receive scheduled notification, view profile, share profile link (generates `vitaming://profile/<recordID>`), tap shared link on another device.

### Claude's Discretion
- Exact App Store description body copy — stay within the warm/personal tone and lead with the morning reminder value proposition
- Screenshot caption text and exact overlay layout — match the app's amber/warm palette
- Whether to include App Preview video — recommended to skip for initial submission; revisit post-launch
- Specific error message copy in the App Store listing subtitle and promotional text

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Privacy manifest
- `VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift` — Defines the two `UserDefaults` keys (`notificationHour`, `notificationMinute`) and App Group suite name (`group.com.kyleharrington.VitaminG`) that require PrivacyInfo declaration
- `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift` — Second call site for `UserDefaults.standard` writes (notification time persistence)
- `VitaminG/VitaminG/VitaminG/Models/SchemaV2.swift` — Confirms `photoData: Data?` is a stub field with no upload UI; no Photos API usage

### CloudKit infrastructure
- `VitaminG/VitaminG/VitaminG/VitaminG.entitlements` — Contains `iCloud.com.kyleharrington.VitaminG` container ID and App Group entitlement
- `VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift` — `cloudKitDatabase: .automatic` setup and simulator guard; confirms CloudKit is wired for production builds
- `VitaminG/VitaminG/VitaminG/Models/SchemaV2.swift` — SchemaV2 model definitions that must be verified in Development CloudKit schema before Production promotion
- `VitaminG/VitaminG/VitaminG/Models/SchemaV1.swift` — SchemaV1 model definitions

### Deep link / URL scheme
- `VitaminG/VitaminG/VitaminG/Info.plist` — `CFBundleURLSchemes: [vitaming]` already registered; no changes needed for Phase 6

### App Store assets reference
- `VitaminG/VitaminG/VitaminG/Assets.xcassets/AppIcon.appiconset/AppIcon.png` — App icon exists; verify all required sizes are present in the asset catalog before archiving
- `VitaminG/VitaminG/VitaminG/Views/ContentView.swift` — Root view, reference for screenshot composition (tab structure: Goals, Stats, Settings, Profile)

### Requirements
- `.planning/REQUIREMENTS.md` — SYNC-03: "CloudKit schema promoted to Production before App Store submission" — this is the sole requirement for Phase 6
- `.planning/ROADMAP.md` — Phase 6 success criteria (three items: Production CloudKit sync verified, TestFlight passes, App Store listing complete)

### Prior phase context
- `.planning/phases/07-add-user-profiles-with-privacy-toggle-profile-picture-upload/07-CONTEXT.md` — CloudKit public database decisions, UserProfile model fields, `ProfileSharingService` (needed to understand what's in the CloudKit schema that must be promoted)
- `.planning/phases/01-foundation/01-CONTEXT.md` — App Group ID, CloudKit container decisions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `NotificationPreferences.swift` — Single source of truth for UserDefaults keys; reference this when listing the required-reason API justification in PrivacyInfo.xcprivacy
- `AvatarView.swift` — Warm color avatar with initials; reuse as screenshot composition element
- `Assets.xcassets/AppIcon.appiconset` — App icon already exists; verify all Xcode-required sizes are generated before archiving

### Established Patterns
- **No third-party dependencies** — All distribution tooling must use native Apple tools: Xcode Organizer for upload, Simulator for screenshots, Apple's CloudKit Console for schema promotion
- **Simulator guard pattern** — `ModelContainerFactory` skips App Group + CloudKit on Simulator; physical device is required for TestFlight validation (D-22)
- **Warm visual tone** — Phase 7 established amber/yellow avatar colors and warm profile UI; screenshot overlays should match this palette

### Integration Points
- Phase 6 adds no new code files. The only code artifact is `PrivacyInfo.xcprivacy` (new file, main app target only)
- All existing tabs (Goals, Stats, Settings, Profile) are screenshot candidates — `ContentView.swift` shows the tab structure
- Widget target (`VitaminGWidget`) may also need a `PrivacyInfo.xcprivacy` — check Apple's requirement for extension targets

</code_context>

<specifics>
## Specific Ideas

- "Vitamin G: your daily dose of goals" — the tagline is built into the app name; use it in the App Store subtitle
- The four-tier hierarchy (Immediate → Short-Term → Long-Term → Life Goal) is a differentiator worth calling out in the App Store description as it maps to realistic planning horizons
- Portfolio showcase use case: prioritize clean, readable screenshots over heavy marketing overlays

</specifics>

<deferred>
## Deferred Ideas

- App Preview (video) — defer to post-launch; not required for initial submission
- iPad-optimized layout — would require NavigationSplitView and multi-column design; separate phase if ever pursued
- Localization / App Store listing in multiple languages — single English listing is sufficient for portfolio launch
- In-app purchases or subscription model — out of scope; Free tier is the decision

</deferred>

---

*Phase: 6-distribution*
*Context gathered: 2026-04-27*
