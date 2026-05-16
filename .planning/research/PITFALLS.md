# Pitfalls Research

**Project:** Vitamin G — iOS Goal Tracking / Gratitude App
**Domain:** iOS 17+, SwiftData, CloudKit sync, WidgetKit, UserNotifications, MVVM
**Researched:** 2026-04-03 (v1.0) / 2026-05-15 (v2.0 addendum)
**Overall confidence:** HIGH (sourced from Apple Developer Forums, official docs, verified community articles)

---

## v2.0 Feature Pitfalls

These pitfalls are specific to adding v2.0 social growth features to an **existing** SwiftData/CloudKit app with 8 schema versions and live users on the App Store. Ordered by severity within each feature area.

---

### Feature: StoreKit 2 Tip Jar

#### V2-SK-1 — Tip jar must use Apple IAP; external payment links cause immediate rejection

**Severity:** HIGH
**What goes wrong:** Any UI element that directs users to an external payment mechanism (a "Buy Me a Coffee" link, Stripe checkout, PayPal) instead of StoreKit 2 is a Guideline 3.1.1 rejection. This applies even when tips are voluntary and gated behind no content. One developer lost multiple review rounds over a simple "buy me a coffee" link in a free utility app.
**Warning sign:** Any URL navigation to a third-party payment page, any mention of external tipping services in app text or metadata.
**Prevention:** Use `StoreKit.Product.purchase()` exclusively. All tip amounts must be configured as IAP products in App Store Connect before submission. No workarounds.
**Suggested phase:** Tip Jar phase — configure IAP in App Store Connect before writing any code, then build UI against the StoreKit 2 API only.

#### V2-SK-2 — Consumable vs non-consumable IAP type determines whether a "Restore" button is required

**Severity:** HIGH
**What goes wrong:** If you implement tip tiers as non-consumable IAPs (purchasable once), App Store Review requires a "Restore Purchases" button accessible to the user. Missing it will cause rejection. If you implement them as consumables (can be purchased multiple times), no restore button is needed — but consumables cannot be restored if the user reinstalls.
**Warning sign:** Shipping a non-consumable tip IAP with no restore mechanism. Shipping a consumable tip IAP and confusing users who expect to "get their tip back" after reinstall.
**Prevention:** Choose consumable IAPs for tips (natural fit — a tip is a one-time transaction, not a durable unlock). Document this choice. If using non-consumable, add a Restore button to the tip jar screen.
**Suggested phase:** Tip Jar phase — decision must be made before App Store Connect product setup.

#### V2-SK-3 — Products must be in App Store Connect and in "Ready to Submit" state before sandbox purchases work on device

**Severity:** HIGH
**What goes wrong:** Developers build the StoreKit 2 integration locally using a StoreKit Configuration File (which works fine in Simulator), then test on a real device with a sandbox account and get empty product arrays or purchase errors. The products exist only locally, not in App Store Connect.
**Warning sign:** `Product.products(for:)` returning an empty array on a physical device. Purchase call hanging or returning `.userCancelled` with no UI shown.
**Prevention:** Configure all tip IAP products in App Store Connect with the same product identifiers used in the StoreKit Configuration File. Products must be in at least "Ready to Submit" state. Create sandbox test accounts in App Store Connect > Users and Access > Sandbox Testers. Test on real device with sandbox account logged in under Settings > App Store > Sandbox Account.
**Suggested phase:** Tip Jar phase — App Store Connect setup is a prerequisite, not an afterthought.

#### V2-SK-4 — Transaction listener must be started at app launch, not only on the paywall screen

**Severity:** MEDIUM
**What goes wrong:** If `Transaction.updates` is only observed when the tip jar sheet is open, a purchase that completes in the background (e.g., after a family sharing approval, or after network interruption) is never processed. The user paid but the app never acknowledged the transaction, and it remains pending indefinitely.
**Warning sign:** `Transaction.updates` task started inside a View's `onAppear` instead of at the App struct level.
**Prevention:** Start a long-lived `Task` observing `Transaction.updates` in the `App` struct's `init` or `body`. This task must persist for the app's lifetime. Call `transaction.finish()` on every verified transaction.
**Suggested phase:** Tip Jar phase — architecture decision, not a UI detail.

#### V2-SK-5 — Sandbox receipt validation behaves differently from production; old sandbox accounts accumulate broken state

**Severity:** MEDIUM
**What goes wrong:** Sandbox Apple IDs that have been used for many test purchases can accumulate corrupt state on Apple's servers, causing intermittent receipt errors ("receipt is not valid") that vanish after using a fresh sandbox account. Developers mistake this for a code bug and spend hours debugging.
**Warning sign:** StoreKit 2 purchase flow failing intermittently in sandbox but not locally in Xcode. Error disappears when using a different sandbox account.
**Prevention:** Keep multiple fresh sandbox accounts for testing. When a sandbox account starts behaving oddly, create a new one rather than debugging the account. Do not use a sandbox account's Apple ID for actual App Store purchases — keep them fully separate. The StoreKit Configuration File in Xcode is the cleanest environment for unit testing; sandbox is for integration testing on device.
**Suggested phase:** Tip Jar phase — establish testing accounts early in the phase.

---

### Feature: CloudKit Profile Picture Storage

#### V2-CK-IMG-1 — CKAsset fileURL is a temporary path that the system silently reclaims

**Severity:** HIGH
**What goes wrong:** After fetching a CloudKit record that includes a `CKAsset`, the asset's `fileURL` points to a temporary file in `~/Library/Caches/CloudKit/Assets/`. The system removes this file when storage pressure increases, without notification. Code that stores the `fileURL` URL string and reads it later finds the file gone, resulting in a broken profile picture with no error.
**Warning sign:** Profile picture displays correctly immediately after fetch, then disappears after the user backgrounds and returns to the app.
**Prevention:** Copy the asset's data immediately on record fetch using `Data(contentsOf: asset.fileURL!)` and persist the compressed image data either to the app's `Application Support` directory or as an `@Attribute(.externalStorage)` in SwiftData. Never store the raw `fileURL` URL for later use.
**Suggested phase:** Profile Picture phase — fundamental architecture decision for the image pipeline.

#### V2-CK-IMG-2 — CKAsset size limit is 250 MB per asset; record total is 1 MB — images must be compressed before upload

**Severity:** HIGH
**What goes wrong:** A user selects a 12 MB HEIC photo from PHPhotoPicker. The app uploads it as-is. CloudKit accepts it (under 250 MB), but users on slow connections wait 30+ seconds for profile pictures to load on the community feed. On the public database, this also consumes the app's CloudKit data transfer quota far faster than necessary.
**Warning sign:** Images uploaded without compression. No max-dimension limit applied to profile pictures.
**Prevention:** Before creating the `CKAsset`, compress the image: downsample to a max dimension (e.g., 512 px for profile pictures), then JPEG-compress at 0.75 quality. Use `CGImageSourceCreateThumbnailAtIndex` with `kCGImageSourceThumbnailMaxPixelSize` to avoid loading the full image into memory first. Profile pictures should be 50–100 KB maximum.
**Suggested phase:** Profile Picture phase — applies to both upload from PHPhotoPicker and camera capture.

#### V2-CK-IMG-3 — Public database images require explicit schema deployment before they appear in production

**Severity:** HIGH
**What goes wrong:** Profile picture `CKAsset` fields added to a public database record type work in development (CloudKit automatically creates the schema on-the-fly during debug builds), but after shipping, the field does not exist in the production schema. All saves fail silently or with a schema mismatch error.
**Warning sign:** Image uploads work in TestFlight (development environment) but fail or vanish after App Store release.
**Prevention:** After adding the asset field to your CloudKit record type definition, open the CloudKit Console, navigate to Schema > Deploy Schema Changes, and explicitly deploy to production before releasing the app update. Add this step to the release checklist.
**Suggested phase:** Profile Picture phase — must be done before TestFlight goes live to any external testers on the production environment.

#### V2-CK-IMG-4 — Public database CloudKit storage quota is shared across all users of the app

**Severity:** MEDIUM
**What goes wrong:** If profile pictures are stored in the CloudKit public database, every byte of image data counts against the app's CloudKit storage quota (10 GB baseline, scaling with active users). If profile pictures are stored in the private database, they count against each user's iCloud storage quota instead, which is the user's problem rather than the app's.
**Warning sign:** Planning to store profile pictures in the public database without estimating quota impact.
**Prevention:** Store profile pictures in the user's private database (they own the space). Reference the picture in the public database by storing a `recordName` string (not the asset itself) that the viewing app fetches from the user's public profile record. Alternatively, store images in private DB and share via CloudKit shared zones. Confirm the architecture with the team before implementation.
**Suggested phase:** Profile Picture phase — architecture must be decided before any CloudKit record types are defined.

---

### Feature: Unique Username Enforcement

#### V2-UN-1 — CloudKit cannot enforce uniqueness atomically; two users can claim the same username simultaneously

**Severity:** HIGH
**What goes wrong:** Two users open the app at the same moment, both search for `@goldenuser`, both get "available", and both submit the claim. CloudKit processes both saves and both records exist with username `goldenuser`. The app now has a duplicate username in the public database with no way to undo either record.
**Warning sign:** Username uniqueness enforced only client-side (query then save pattern). No server-side atomic lock.
**Prevention:** Use `recordName` (the `CKRecordID` name) to enforce uniqueness. CloudKit guarantees that two saves to the same `recordName` will conflict, with one winning via last-write-wins. Set the CloudKit record's recordName to the lowercase normalized username string (e.g., `"username:goldenuser"`). Saves with the same recordName will overwrite — which means the last writer wins the name, not ideal but far better than true duplicates. Add a post-save verification query to detect displacement: after the user claims the name, fetch that recordName back and verify the fetched record's `creatorUserRecordID` matches the current user. If not, show a "username was taken while you were submitting — please choose another" message.
**Suggested phase:** Onboarding / Auth phase — username design is a core onboarding step.

#### V2-UN-2 — Username normalization must happen before uniqueness checks

**Severity:** MEDIUM
**What goes wrong:** User A registers as `Golden_User`. User B registers as `golden_user`. The app treats them as different (case-sensitive comparison), but they look identical on screen. The community feed shows what appears to be two users with the same name.
**Warning sign:** Username comparison using `==` without normalizing case and stripping whitespace.
**Prevention:** Normalize usernames to lowercase + strip leading/trailing whitespace + disallow special characters except underscore before performing any uniqueness check or CloudKit save. Store the normalized form as the CloudKit recordName. Display the original casing the user chose, but store and compare the lowercase version. Validate with a regex on entry (`^[a-z0-9_]{3,20}$` on the normalized form).
**Suggested phase:** Onboarding / Auth phase.

---

### Feature: PHPhotoPicker / Camera

#### V2-PP-1 — Missing privacy strings in Info.plist cause immediate App Store rejection

**Severity:** HIGH
**What goes wrong:** The app uses `UIImagePickerController` (camera) or `PHPickerViewController` (photo library) without adding `NSCameraUsageDescription` and/or `NSPhotoLibraryUsageDescription` to Info.plist. The app is rejected at binary validation before review even begins, with error `ITMS-90683`.
**Warning sign:** Camera or photo picker code added without corresponding Info.plist entries.
**Prevention:**
- Camera access: Add `NSCameraUsageDescription` with a clear, user-facing reason (e.g., "Vitamin G uses your camera to set your profile photo.").
- Photo library read: Add `NSPhotoLibraryUsageDescription`.
- Photo library write-only: Add `NSPhotoLibraryAddUsageDescription` (sufficient if you only save, not read).
- `PHPickerViewController` (iOS 14+) does not require `NSPhotoLibraryUsageDescription` for reading — it operates without the full library permission. Do not request more access than needed.
**Suggested phase:** Profile Picture / Onboarding phase.

#### V2-PP-2 — Loading full-resolution PHAsset into UIImage spikes memory to 2+ GB

**Severity:** HIGH
**What goes wrong:** Calling `loadObject(ofClass: UIImage.self)` from a `PHPickerResult` loads the full decoded HEIC image into memory. A 48 MP iPhone 15 Pro Max photo decompressed to raw pixels is ~192 MB. With multiple image operations in flight, memory peaks above 2 GB and the OS terminates the app with a memory warning.
**Warning sign:** Profiling shows memory spike when user selects a photo. Crash reports from OOM termination after photo selection.
**Prevention:** Do not decode to `UIImage` directly from the full-resolution asset. Use `loadFileRepresentation(forTypeIdentifier:completionHandler:)` to get a temporary file URL, then use `CGImageSourceCreateWithURL` and `CGImageSourceCreateThumbnailAtIndex` with `kCGImageSourceThumbnailMaxPixelSize` set to the maximum display dimension (e.g., 512) to downsample without decoding the full image. The memory footprint drops from ~200 MB to ~3 MB.
**Suggested phase:** Profile Picture phase — image pipeline architecture.

#### V2-PP-3 — PHPickerViewController result processing must handle the case where the user selects nothing

**Severity:** LOW
**What goes wrong:** The delegate method `picker(_:didFinishPicking:)` is called with an empty `results` array when the user taps Cancel. Code that force-unwraps `results.first` crashes.
**Warning sign:** `results.first!` or unchecked index access on the results array.
**Prevention:** Always guard `results.isEmpty` and return early (dismiss the picker, take no action) when the array is empty.
**Suggested phase:** Profile Picture phase.

---

### Feature: CoreMotion Shake Detection

#### V2-CM-1 — Continuous CoreMotion updates drain battery; must stop updates when the screen is not visible

**Severity:** HIGH
**What goes wrong:** `CMMotionManager.startAccelerometerUpdates(to:withHandler:)` runs continuously if not explicitly stopped. If the user navigates away from the Explore tab (where shake-for-goal lives), accelerometer updates keep firing at 60 Hz, consuming ~6% CPU continuously. Over an hour this measurably impacts battery life and may draw App Store reviewer attention.
**Warning sign:** `stopAccelerometerUpdates()` not called in `onDisappear` of the Explore tab view. Motion updates started at app launch.
**Prevention:** Start CoreMotion updates only in `onAppear` of the Explore tab. Stop them in `onDisappear`. Use `CMMotionManager` as a singleton (only one instance should exist in the app). Sample rate should be 60 Hz (sufficient for shake detection; do not use 100+ Hz).
**Suggested phase:** Explore Tab phase.

#### V2-CM-2 — UIKit shake via motionEnded is simpler for one-off shake gestures; CoreMotion is overkill

**Severity:** MEDIUM
**What goes wrong:** Developers reach for `CoreMotion` (CMMotionManager, raw accelerometer data, custom threshold detection) when `UIResponder.motionEnded(_:with:)` would handle the use case in 10 lines. CoreMotion requires manual threshold tuning and produces false positives on bumpy surfaces or when the device is set down sharply.
**Warning sign:** Custom shake algorithm with accelerometer thresholds. False positive rate not measured before shipping.
**Prevention:** For the "shake to get a daily goal" feature, use `UIEvent.EventSubtype.motionShake` via `motionEnded` on a `UIViewController` subclass or via SwiftUI's `onShake` custom modifier (which wraps the same UIKit event). The OS applies its own debouncing and false-positive filtering to the built-in shake event. Only reach for CoreMotion if the gesture needs custom thresholds (e.g., detecting a specific motion pattern).
**Suggested phase:** Explore Tab phase.

---

### Feature: In-App Dark Mode Override

#### V2-DM-1 — UIApplication.shared.windows is deprecated in iOS 15; using it in iOS 17 code draws reviewer scrutiny

**Severity:** MEDIUM
**What goes wrong:** Common code samples for in-app dark mode override use `UIApplication.shared.windows.first?.overrideUserInterfaceStyle`. This API was deprecated in iOS 15. While it still compiles and runs in iOS 17, Apple's documentation flags it, and it will eventually stop working. More immediately, App Store review bots flag deprecated API usage and sometimes require justification.
**Warning sign:** `UIApplication.shared.windows` anywhere in the codebase.
**Prevention:** Use `UIApplication.shared.connectedScenes` instead:
```swift
UIApplication.shared.connectedScenes
    .compactMap { $0 as? UIWindowScene }
    .first?.windows
    .first(where: { $0.isKeyWindow })?
    .overrideUserInterfaceStyle = style
```
For a pure SwiftUI approach: store the preference as a `@AppStorage` enum (system/light/dark) and apply `.preferredColorScheme()` on the root `WindowGroup`. The `.preferredColorScheme` approach is cleaner and has no deprecated API surface, but note it does not affect `UIAlertController` and system sheet presentations — those inherit the window's style, not the SwiftUI hierarchy's. Use `overrideUserInterfaceStyle` on the window for complete coverage.
**Suggested phase:** Settings phase.

#### V2-DM-2 — Dark mode preference must be applied on every cold launch, not only when the user toggles it

**Severity:** MEDIUM
**What goes wrong:** The developer applies `overrideUserInterfaceStyle` when the user taps the toggle in Settings. On the next cold launch, the app opens in the system appearance for a brief flash before applying the saved preference. Users who prefer dark mode see a white flash on every launch.
**Warning sign:** `overrideUserInterfaceStyle` set only in the Settings view's toggle handler. No application in the app startup path.
**Prevention:** Store the dark mode preference in `UserDefaults` (or `@AppStorage`). On app launch — before the first view renders — read the preference and apply it to the window. In the SwiftUI `App` struct, read from `@AppStorage` and pass to `.preferredColorScheme()` on `WindowGroup`. The window override approach requires waiting for the window to exist (apply in `SceneDelegate.scene(_:willConnectTo:options:)` or in an `.onAppear` of the root view).
**Suggested phase:** Settings phase.

#### V2-DM-3 — WidgetKit ignores in-app dark mode override — widgets follow system appearance only

**Severity:** LOW
**What goes wrong:** User sets the app to forced light mode. The widget remains dark because widgets inherit the system appearance, not the app's `overrideUserInterfaceStyle`.
**Warning sign:** Designing widgets that are expected to match the in-app appearance override.
**Prevention:** Accept this as a platform constraint. Do not design features that require widgets to match the in-app override. Mention this limitation in internal documentation.
**Suggested phase:** Settings phase — document the limitation; no code fix available.

---

### Feature: SwiftData Schema Migration to SchemaV9

#### V2-SD-1 — Custom MigrationStage crashes with CloudKit enabled in iOS 17.x; lightweight is the only safe path

**Severity:** HIGH
**What goes wrong:** SchemaV8 → SchemaV9 requires adding new model types (e.g., a `UserPresence` model for live presence, a `TipTransaction` model). If any `SchemaMigrationStage` is a `CustomMigrationStage`, the workaround for CloudKit-migration ordering (disable CloudKit, migrate, re-enable on next launch) crashes in iOS 17.4+ instead of falling through gracefully. This leaves users who have the existing app stuck with a corrupted or empty container on update.
**Warning sign:** Any `SchemaMigrationPlan` stage that is a `.custom(...)` stage rather than `.lightweight(...)` when CloudKit is enabled.
**Prevention:** Design SchemaV9 so that all changes are lightweight-migration-compatible: new model types with all-optional properties and default values, new optional properties on existing models, no renames, no deletions, no type changes. If a data transformation is needed (e.g., populating a new field from an existing field), do it lazily at first access in the app layer, not in a migration stage. This avoids the custom migration crash entirely.
**Suggested phase:** Schema Migration phase — must be the first v2.0 phase before any other v2.0 data model work.

#### V2-SD-2 — New @Model types in SchemaV9 must declare ALL properties as optional or with defaults for CloudKit

**Severity:** HIGH
**What goes wrong:** Adding a new `@Model class UserPresence` to SchemaV9 with a non-optional property like `var lastSeenAt: Date` (without a default value) causes the `ModelContainer` to refuse to initialize when CloudKit is enabled, because CloudKit requires all attributes to be optional.
**Warning sign:** Any `@Model` class added in v2.0 with a non-optional stored property and no default value.
**Prevention:** Every new v2.0 model must follow the rule: `var property: Type? = nil` OR `var property: Type = defaultValue`. This applies to every field including identifiers, timestamps, and enum-backed strings. Audit every new `@Model` before merging.
**Suggested phase:** Schema Migration phase.

#### V2-SD-3 — Widget extension's ModelContainer must also be updated to SchemaV9

**Severity:** HIGH
**What goes wrong:** The widget creates its own `ModelContainer` from the shared App Group store. If the widget target's schema list is not updated to include all SchemaV9 model types, the widget's `ModelContainer` may attempt to open the migrated SchemaV9 store with a SchemaV8 model definition. This produces a schema mismatch crash in the widget extension, causing the widget to display an error placeholder.
**Warning sign:** Widget's `ModelContainer` init hardcoded to a previous schema version or model list.
**Prevention:** Use a shared helper (a single Swift file included in both the app target and widget target) that returns the canonical `Schema` and `SchemaMigrationPlan`. Both the app and widget must reference the same shared container definition after migration. Verify in Xcode that the widget target's target membership includes the new model files.
**Suggested phase:** Schema Migration phase — test the widget explicitly after each schema version bump.

#### V2-SD-4 — CloudKit production schema must be deployed before the update ships to users

**Severity:** HIGH
**What goes wrong:** SchemaV9 adds new CloudKit record types (e.g., `UserPresence`, `TipTransaction`). The new record types work automatically in development (CloudKit auto-creates them in the Development environment). But in production, the schema is locked. When users receive the update, CloudKit save operations for the new types fail silently because the schema does not exist in production.
**Warning sign:** New record types visible in CloudKit Console > Development but not deployed to Production.
**Prevention:** Before submitting the v2.0 update for App Store Review, open CloudKit Console > Schema > Deploy Schema Changes to Production. Verify the new record types appear in Production after deployment. Include "Deploy CloudKit schema" in the release checklist. This step requires the developer account holder or an admin.
**Suggested phase:** Schema Migration phase and pre-release checklist.

#### V2-SD-5 — Existing users migrating from SchemaV8 to SchemaV9 will have their first launch fail if ModelContainer init throws before migration runs

**Severity:** HIGH
**What goes wrong:** A known SwiftData + CloudKit bug: when an existing user updates the app, CloudKit tries to initialize against the store before the SwiftData migration runs. Because the store is SchemaV8 and the app expects SchemaV9, CloudKit cannot reconcile the schema and fails, leaving the container in an error state. The workaround (disable CloudKit, migrate, re-enable on next launch) does not work with custom migration stages.
**Warning sign:** Using a custom migration stage in the V8→V9 plan. Not testing the upgrade path from a real SchemaV8 database (only testing fresh installs).
**Prevention:** Keep V8→V9 strictly lightweight (see V2-SD-1). Test the migration explicitly: install the current App Store build, create sample data, then install the v2.0 build over it and verify the container loads. Do not only test fresh installs.
**Suggested phase:** Schema Migration phase — migration testing must include upgrade-from-existing-data scenarios.

---

### Feature: CloudKit Live User Presence

#### V2-LP-1 — SwiftData does not support CloudKit public database; NSPersistentCloudKitContainer polls every 30 minutes

**Severity:** HIGH
**What goes wrong:** The community feed uses the CloudKit public database (already established in v1.0). SwiftData does not support the public or shared CloudKit database directly — only the private database. Public database queries must use `CKDatabase` directly (not via SwiftData). Additionally, `NSPersistentCloudKitContainer` (if used) polls the public database approximately every 30 minutes, making it unsuitable for anything that needs to look "live" to users.
**Warning sign:** Treating the community public database as if it has the same real-time behavior as the private database. Expecting SwiftData `@Query` to return public database records.
**Prevention:** Public database operations must be done via direct `CKDatabase` API. For "live presence" simulation, this means polling manually on a timer when the community screen is visible (e.g., every 60 seconds while the view is active). Stop the timer in `onDisappear`. Accept that the "live users" section is a simulation, not true real-time. Display data as "active recently" rather than "online now" to set accurate user expectations.
**Suggested phase:** Community Phase — architecture decision that affects the entire public data layer.

#### V2-LP-2 — CKQuerySubscription for public database notifications is unreliable; silent pushes require special configuration

**Severity:** MEDIUM
**What goes wrong:** Implementing CKSubscriptions to push-notify the app when another user updates their presence record seems like the right approach. In practice: (1) the public database limits subscription types; (2) if `shouldSendContentAvailable` is set and the app is force-quit, notifications are never delivered; (3) if the user doesn't grant notification permission, content-available pushes still don't wake the app in the background.
**Warning sign:** Designing live presence on the assumption that CloudKit push notifications will reliably deliver within seconds.
**Prevention:** Do not build live presence on CloudKit push as the primary mechanism. Use foreground polling (timer-based `CKQuery` operations) when the community screen is visible. Push notifications can be used as a supplement (to trigger a refresh when the app transitions to foreground) but should not be the primary data delivery path. Design the feature with the mental model "refreshes every 60 seconds when viewed" not "updates instantly."
**Suggested phase:** Community Phase.

#### V2-LP-3 — CloudKit query rate limit (40 queries/second) can be breached at scale if each user polls independently

**Severity:** LOW (for current scale; monitor as user base grows)
**What goes wrong:** If 50 users are simultaneously viewing the community screen and each is polling CloudKit every 30 seconds, that generates ~1.7 queries/second — well under the limit. At 2000 simultaneous users, this reaches ~67 queries/second and begins to throttle. Throttled queries return errors that must be handled gracefully.
**Warning sign:** No error handling for CloudKit `CKError.requestRateLimited`. No exponential backoff on query failure.
**Prevention:** Add error handling for `CKError.requestRateLimited`. Use exponential backoff for retries. At current expected scale this is unlikely to be triggered, but the error path must be handled so it does not crash. Revisit if the app scales significantly.
**Suggested phase:** Community Phase.

---

### Feature: Tab Structure Restructuring

#### V2-TAB-1 — Existing NavigationStack paths that reference removed tab indices will silently route nowhere

**Severity:** HIGH
**What goes wrong:** v1.0 has 5 tabs in this order: Goals, Stats, Wins, Challenges, Profile. v2.0 replaces them with: Home, Goals, Explore, Community, Profile. Any code that selects a tab by index (`selectedTab = 3` for Challenges) now routes to Community instead. Any stored deep link or widget tap action that encodes a tab index as a raw integer is now wrong.
**Warning sign:** Tab selection using raw integer indices. `@AppStorage` or `UserDefaults` storing a tab index integer across app versions. Widget app intent or URL scheme that encodes a tab index.
**Prevention:** Use a `Tab` enum with stable string raw values (not integers) for all tab selection logic. When restructuring tabs, audit every call site that sets `selectedTab` and update to the new enum case. Review widget app intents and deep link handlers — these likely encode tab destinations that must be remapped. If a previously stored `selectedTab` integer is read from `UserDefaults` and no longer maps to a valid tab, default to the Home tab.
**Suggested phase:** Tab Restructuring phase — first v2.0 UI phase, must be done before building any new tab content.

#### V2-TAB-2 — Removing the Stats and Wins tabs drops features that v1.0 users may depend on

**Severity:** MEDIUM
**What goes wrong:** The v2.0 spec replaces the 5-tab v1.0 structure (Goals, Stats, Wins, Challenges, Profile) with a new 5-tab structure (Home, Goals, Explore, Community, Profile). The Stats and Wins tabs are removed. Users who have built habits around those tabs will be disoriented and may leave negative reviews if functionality disappears without explanation.
**Warning sign:** Stats and Wins views deleted without being surfaced elsewhere in the new structure.
**Prevention:** Before removing tabs, confirm that the features are accessible in the new structure: Stats should be accessible from Profile or Home, Wins should be accessible from Home or a settings area. Add a one-time "what's new" screen on first launch after the update to orient existing users to the new structure. Never silently delete a feature a user has used.
**Suggested phase:** Tab Restructuring phase.

---

### Feature: Applause / Floating Animation System

#### V2-ANIM-1 — Uncontrolled particle emitters accumulate and crash on low-memory devices

**Severity:** HIGH
**What goes wrong:** Each applause action triggers a floating emoji animation. If the developer creates a new `CAEmitterLayer` or `SKNode` per tap without removing finished emitters, 50 rapid applause taps create 50 emitters still running in the background. On devices with constrained memory (iPhone SE, older iPads), this causes a memory warning followed by OOM termination.
**Warning sign:** Emitter or animation node created in a tap handler without a reference to track and remove it. No `removeFromParent()` or `removeFromSuperlayer()` after animation completes.
**Prevention:** Keep a maximum of 1–3 concurrent applause emitters. Use a `DispatchWorkItem` or `Task` to remove the emitter after a fixed duration (e.g., 2 seconds). For confetti, use `CAEmitterLayer`'s `birthRate` property: set it to 0 after the burst to stop generating new particles; existing particles continue to animate and then disappear naturally. Profile on an iPhone SE 2nd gen before shipping.
**Suggested phase:** Community / Applause phase.

#### V2-ANIM-2 — Confetti animation on top of community feed must not block touch events

**Severity:** MEDIUM
**What goes wrong:** A `CAEmitterLayer` or overlay view placed at the window level to show confetti intercepts touch events and makes the community feed non-interactive while the animation is running.
**Warning sign:** Confetti layer added with `isUserInteractionEnabled = true` (the default for UIView). Full-screen overlay view not pass-through.
**Prevention:** Set `isUserInteractionEnabled = false` on any confetti overlay layer/view. For SwiftUI, use `.allowsHitTesting(false)` on the confetti view. Ensure the confetti layer is above content visually but does not consume touches.
**Suggested phase:** Community / Applause phase.

---

### Feature: App Store Review — Profile Pictures and User-Generated Content

#### V2-ASR-1 — Apps with user profile pictures must implement content moderation or face rejection under Guideline 1.2

**Severity:** HIGH
**What goes wrong:** When users can upload profile pictures, App Store Review Guideline 1.2 requires: (1) a mechanism to filter objectionable content, (2) a way for users to report offensive content, (3) the ability to block abusive users, and (4) contact information for support. Missing any of these causes rejection. Apple's review team actively tests UGC features and will upload an inappropriate image to verify moderation exists.
**Warning sign:** Profile picture upload with no report/flag mechanism in the UI. No in-app support contact method.
**Prevention:**
- Add a "Report" option to every public profile view (accessible via a long press or context menu).
- Add a "Block" option to prevent seeing a user's content.
- Provide a contact support email or form (required under App Store review).
- Consider server-side image scanning (even basic URL-based hash checking) as a first line. For a zero-backend app using CloudKit, at minimum implement client-side reporting that creates a CloudKit record in a "reports" container that you monitor manually.
- Your Terms and Conditions PDF must explicitly state prohibited content types and your moderation policy.
**Suggested phase:** Profile Picture / Onboarding phase — moderation must ship with profile picture support, not be added later.

#### V2-ASR-2 — Camera access permission slide in onboarding must not gate core app functionality

**Severity:** MEDIUM
**What goes wrong:** If the onboarding flow requires camera permission to proceed (e.g., "You must add a profile picture to continue"), App Store Review will reject under Guideline 2.5.4 (apps may not require permission to a device feature that is not necessary for the app's core functionality in order to proceed).
**Warning sign:** Camera permission request with no "Skip" or "Do this later" option. Profile picture step marked as required in onboarding.
**Prevention:** Make the profile picture step in onboarding skippable. Users should be able to complete onboarding with the default avatar and add a profile picture later from their profile. The camera permission slide should explain the value proposition and offer both "Allow Camera" and "Skip for now" options.
**Suggested phase:** Onboarding phase.

---

## v1.0 Pitfalls (Retained for Reference)

These pitfalls were identified during v1.0 development and remain relevant for ongoing v2.0 work.

### P0-1 — CloudKit Requires All Model Properties and Relationships to Be Optional

**What goes wrong:** SwiftData with CloudKit integration enforces a constraint that every property must be either optional or carry a default value, and every relationship must be optional. If you design the `Goal` model with non-optional fields like `title: String` or `tier: GoalTier` without defaults, CloudKit will emit a compile-time or runtime error and refuse to sync.

**Root cause:** CloudKit's partial-sync architecture means a device may receive a record with only some fields populated. SwiftData cannot satisfy a non-optional property in that state.

**Specific error you will see:**
```
CloudKit integration requires that all attributes be optional, or have a default value set.
The following attributes are marked non-optional but do not have a default value...
```

**Consequences:**
- iCloud sync silently disabled or crashes at `ModelContainer` initialization.
- Relationships (e.g., a future `Inspiration` linked to a `Goal`) fail to resolve unless marked optional.

**Prevention:**
- Design every `@Model` property as `optional` OR provide a default value from day one: `var title: String = ""`.
- For relationships: `var associatedInspiration: Inspiration? = nil`.
- Use a computed non-optional accessor to maintain clean API in the ViewModel layer while the stored property stays optional.

**Warning signs:** Any non-optional `@Model` property without a default value. Compiler warnings about CloudKit schema when `NSPersistentCloudKitContainer` or SwiftData CloudKit config is active.

**Phase:** Data model phase (Phase 1). Must be correct before any data is persisted.

---

### P0-2 — SwiftData Schema Not Versioned from Day One

**What goes wrong:** If you ship without wrapping your models in `VersionedSchema`, your first schema change after release requires a "complex" manual migration with no safety net. SwiftData will delete and recreate the store if it cannot migrate, wiping all user data.

**Root cause:** SwiftData's automatic lightweight migration only works within a versioned schema chain. Without `VersionedSchema` declared from the start, there is no chain to extend.

**Consequences:**
- Any field rename, type change, or added non-optional property post-ship causes data loss for users on update.
- Re-adding `VersionedSchema` retroactively is possible but requires careful `SchemaMigrationPlan` work that is harder when version 1 was never formally declared.

**Prevention:**
- **Always wrap models in `VersionedSchema` from the first commit**, even before the first TestFlight build.
- Start with `SchemaV1`, use `SchemaMigrationPlan` that declares `stages: []` (empty) initially.
- Never rename a stored property — add a new one, migrate values, deprecate the old one.

**Warning signs:** `ModelContainer` init without a `migrationPlan` parameter. Models not nested inside a `VersionedSchema` enum.

**Phase:** Phase 1 (data modeling). Zero-cost to do right; catastrophic to fix after.

---

### P0-3 — CloudKit Schema Is Add-Only After First Production Push

**What goes wrong:** Once your CloudKit schema is pushed to production (via CloudKit Dashboard or first live user sync), you cannot rename, delete, or change the type of any entity or attribute. CloudKit interprets a rename as "delete old + add new," causing data loss.

**Root cause:** CloudKit's schema versioning is permanent and immutable for deployed record types.

**Consequences:**
- A renamed `GoalTier` enum stored as a `String` attribute breaks existing user records.
- A refactored relationship (e.g., changing from a flat list to hierarchical tiers) cannot be expressed in the existing CloudKit schema.

**Prevention:**
- Finalize entity and attribute names before first TestFlight with iCloud enabled.
- Use `initializeCloudKitSchema()` during development to force CloudKit to match your local model — call this explicitly during dev, never in production builds.
- Follow "Add Only, No Delete, No Change" as a rule after the first production release.

**Warning signs:** Any attribute or entity rename after a CloudKit-enabled beta has been distributed.

**Phase:** Phase 1 (data modeling) and Phase 3 (CloudKit integration). Must be stable before CloudKit phase.

---

### P0-4 — Adding Widget Extension to Existing App Silently Breaks the SwiftData Store

**What goes wrong:** When you add a WidgetKit extension with App Group support to an app that already has users, SwiftData's default behavior changes its store lookup path to the App Group container. Existing users' data appears to vanish — the app opens to an empty state.

**Root cause:** When an App Group entitlement is present, SwiftData automatically uses the App Group container as the parent directory for the store file. The store that existed at the app's default container path is no longer found.

**Consequences:**
- All existing user data appears to be deleted on update (it still exists at the old path, but SwiftData cannot find it).
- Must be handled with an explicit migration to copy the existing `.store` file to the App Group path.

**Prevention:**
- Plan for App Groups from Phase 1. Add the App Group entitlement to the main app before any user data exists, even if the widget isn't built yet.
- If adding after users exist: write a one-time migration that checks `UserDefaults` for a "migrated" flag, copies the store file to the App Group container, then sets the flag.
- Configure `ModelConfiguration` with an explicit `url` pointing to the App Group container in both the app target and the widget target.

**Warning signs:** App Group entitlement added to a project that already has a `ModelContainer` configured without an explicit store URL.

**Phase:** Phase 1 (infrastructure setup). Must configure App Groups before storing any user data.

---

### P0-5 — Widget Cannot Use `.modelContainer()` Modifier — Must Create Its Own Container

**What goes wrong:** Developers attempt to attach `.modelContainer(_:)` to a `Widget` struct inside `body`. This modifier is not defined for `WidgetConfiguration` and fails to compile. The widget runs in its own process and has zero access to the main app's in-memory `ModelContext`.

**Root cause:** Widgets are isolated processes. The main app's context is not shared across process boundaries.

**Consequences:**
- Widget shows stale or empty data regardless of main app state.
- Using the wrong store URL in the widget's `ModelContainer` init creates a second, separate SQLite file, splitting data across two stores.

**Prevention:**
- Create a `ModelContainer` inside the widget's `TimelineProvider` (in `getTimeline`), pointed at the shared App Group store URL.
- Use a shared helper (e.g., a Swift Package or shared source file included in both targets) that returns the canonical `ModelConfiguration` with the App Group URL.
- Never pass `ModelContainer` or `ModelContext` across the process boundary — only serialize primitive data if needed.

**Warning signs:** Widget target missing App Group entitlement. Widget's `ModelContainer` using default store URL instead of App Group URL.

**Phase:** Phase 4 (widgets). Blocked on P0-4 (App Groups) being resolved first.

---

### Common Mistakes (v1.0)

#### P1-1 — MVVM + @Query Collision: Putting @Query in a ViewModel Breaks the Pattern

**What goes wrong:** `@Query` is a SwiftUI property wrapper that requires access to the SwiftUI environment's `ModelContext`. When placed inside a `class`-based ViewModel (even an `@Observable` one), `@Query` has no SwiftUI environment to attach to and either fails to compile or returns empty results.

**Prevention:** Accept the hybrid pattern: `@Query` lives in the `View`, but sorting/filtering predicates are owned by the ViewModel. For imperative fetches in a ViewModel, use `ModelContext.fetch(_:)` with a `FetchDescriptor`.

**Phase:** Phase 1 (architecture setup).

---

#### P1-2 — SwiftData Models Are Not Sendable — Passing Across Actors Causes Crashes

**What goes wrong:** SwiftData `@Model` instances are bound to the `ModelContext` they were fetched from. Passing a model object from a background `ModelActor` context to the main actor crashes at runtime.

**Prevention:** Never pass `@Model` instances across actor boundaries. Pass only IDs (`PersistentIdentifier`) or plain value-type structs. Use `@ModelActor` for background contexts.

**Phase:** Phase 2 (streak/statistics features).

---

#### P1-3 — iOS Notification Scheduling Hard Limit of 64 Pending Requests

**What goes wrong:** iOS allows a maximum of 64 pending `UNNotificationRequest` objects. Excess requests are silently dropped.

**Prevention:** Pre-schedule only 60 days of notifications. Reschedule on every app foreground. Use `getPendingNotificationRequests` to audit before adding.

**Phase:** Phase 3 (notifications).

---

#### P1-4 — Notification Permission Requested Too Early (App Launch)

**Prevention:** Show custom pre-permission screen before triggering system dialog. Request only after user sets their first goal. Handle `.denied` gracefully.

**Phase:** Phase 3 (notifications).

---

#### P1-5 — Streak Timezone and DST Edge Cases Break Reset Logic

**Prevention:** Use `Calendar.current.isDateInToday(_:)` and `Calendar.current.isDate(_:inSameDayAs:)`. Never use raw `TimeInterval` arithmetic for day comparisons.

**Phase:** Phase 2 (core data model and statistics).

---

#### P1-6 — SwiftData Unique Constraint Added to Existing Field Blocks App Launch

**Prevention:** Define uniqueness constraints from the first version. Do not use `@Attribute(.unique)` if CloudKit sync is enabled.

**Phase:** Phase 1 (data modeling).

---

## Phase Mapping — v2.0 Pitfalls

| Feature Area | Pitfall ID | Severity | Suggested Phase |
|---|---|---|---|
| StoreKit 2 | V2-SK-1 | HIGH | Tip Jar phase |
| StoreKit 2 | V2-SK-2 | HIGH | Tip Jar phase |
| StoreKit 2 | V2-SK-3 | HIGH | Tip Jar phase |
| StoreKit 2 | V2-SK-4 | MEDIUM | Tip Jar phase |
| StoreKit 2 | V2-SK-5 | MEDIUM | Tip Jar phase |
| CloudKit Images | V2-CK-IMG-1 | HIGH | Profile Picture phase |
| CloudKit Images | V2-CK-IMG-2 | HIGH | Profile Picture phase |
| CloudKit Images | V2-CK-IMG-3 | HIGH | Profile Picture phase |
| CloudKit Images | V2-CK-IMG-4 | MEDIUM | Profile Picture phase (architecture) |
| Unique Username | V2-UN-1 | HIGH | Onboarding / Auth phase |
| Unique Username | V2-UN-2 | MEDIUM | Onboarding / Auth phase |
| PHPhotoPicker / Camera | V2-PP-1 | HIGH | Profile Picture / Onboarding phase |
| PHPhotoPicker / Camera | V2-PP-2 | HIGH | Profile Picture phase |
| PHPhotoPicker / Camera | V2-PP-3 | LOW | Profile Picture phase |
| CoreMotion | V2-CM-1 | HIGH | Explore Tab phase |
| CoreMotion | V2-CM-2 | MEDIUM | Explore Tab phase |
| Dark Mode Override | V2-DM-1 | MEDIUM | Settings phase |
| Dark Mode Override | V2-DM-2 | MEDIUM | Settings phase |
| Dark Mode Override | V2-DM-3 | LOW | Settings phase |
| Schema Migration | V2-SD-1 | HIGH | Schema Migration phase (first v2.0 phase) |
| Schema Migration | V2-SD-2 | HIGH | Schema Migration phase |
| Schema Migration | V2-SD-3 | HIGH | Schema Migration phase |
| Schema Migration | V2-SD-4 | HIGH | Schema Migration phase + release checklist |
| Schema Migration | V2-SD-5 | HIGH | Schema Migration phase |
| Live Presence | V2-LP-1 | HIGH | Community phase |
| Live Presence | V2-LP-2 | MEDIUM | Community phase |
| Live Presence | V2-LP-3 | LOW | Community phase |
| Tab Restructuring | V2-TAB-1 | HIGH | Tab Restructuring phase (first UI phase) |
| Tab Restructuring | V2-TAB-2 | MEDIUM | Tab Restructuring phase |
| Applause / Animation | V2-ANIM-1 | HIGH | Community / Applause phase |
| Applause / Animation | V2-ANIM-2 | MEDIUM | Community / Applause phase |
| App Store Review — UGC | V2-ASR-1 | HIGH | Profile Picture phase |
| App Store Review — UGC | V2-ASR-2 | MEDIUM | Onboarding phase |

---

## Sources

### v2.0 Research Sources

- [App Review Guidelines — Apple Developer](https://developer.apple.com/app-store/review/guidelines/)
- [Implementing a Tip Jar with Swift and SwiftUI — Ben Cardy](https://bencardy.co.uk/2023/02/17/implementing-a-tip-jar-with-swift-and-swiftui/)
- [My Ongoing Battle with Apple Over a "Buy Me a Coffee" Link — Robert Baer, Medium](https://medium.com/@robert-baer/my-ongoing-battle-with-apple-over-a-buy-me-a-coffee-link-is-over-9c158df81c05)
- [Mastering StoreKit 2 in SwiftUI — Dhruvin Bhalodiya, Medium](https://medium.com/@dhruvinbhalodiya752/mastering-storekit-2-in-swiftui-a-complete-guide-to-in-app-purchases-2025-ef9241fced46)
- [Testing In-App Purchases with sandbox — Apple Developer Documentation](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox)
- [Mastering StoreKit 2 — Swift with Majid](https://swiftwithmajid.com/2023/08/01/mastering-storekit2/)
- [Working with in-app purchases in StoreKit 2 — WWDC by Sundell](https://wwdcbysundell.com/2021/working-with-in-app-purchases-in-storekit2/)
- [Restoring purchased products — Apple Developer Documentation](https://developer.apple.com/documentation/storekit/restoring-purchased-products)
- [All you need to know about CloudKit — iteo](https://iteo.medium.com/all-you-need-to-know-about-cloudkit-art-fac434c0e7b0)
- [CloudKit 101 — Rambo Codes](https://www.rambo.codes/posts/2020-02-25-cloudkit-101)
- [Working with Images in CloudKit — Marcus Smith, Medium](https://medium.com/frozen-fire-studios/working-with-images-in-cloudkit-1e3579c67558)
- [CKAsset — Apple Developer Documentation](https://developer.apple.com/documentation/cloudkit/ckasset)
- [CloudKit Web Services Data Size Limits — Apple Documentation](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/PropertyMetrics.html)
- [Using PHPickerViewController Images in a Memory-Efficient Way — Christian Selig](https://christianselig.com/2020/09/phpickerviewcontroller-efficiently/)
- [Optimizing Images — Swiftjective-C](https://www.swiftjectivec.com/optimizing-images/)
- [NSCameraUsageDescription — Apple Developer Documentation](https://developer.apple.com/documentation/BundleResources/Information-Property-List/NSCameraUsageDescription)
- [Best way to handle unique values with SwiftData and CloudKit — Hacking with Swift Forums](https://www.hackingwithswift.com/forums/swiftui/best-way-to-handle-unique-values-with-swiftdata-and-cloudkit/30145)
- [Anyway to specify a unique constraint in CloudKit record — Apple Developer Forums](https://developer.apple.com/forums/thread/126019)
- [Why CloudKit integration does not support unique constraints — Apple Developer Forums](https://developer.apple.com/forums/thread/656380)
- [Energy Efficiency Guide for iOS Apps — Apple Developer](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/MotionBestPractices.html)
- [SwiftData CloudKit migration error — Apple Developer Forums](https://developer.apple.com/forums/thread/775060)
- [SwiftData+CloudKit Migration Fail — Apple Developer Forums](https://developer.apple.com/forums/thread/742899)
- [An Unauthorized Guide to SwiftData Migrations — Atomic Robot](https://atomicrobot.com/blog/an-unauthorized-guide-to-swiftdata-migrations/)
- [SwiftData custom migration crash — Apple Developer Forums](https://developer.apple.com/forums/thread/758874)
- [Deploy your CloudKit-backed SwiftData entities to production — Leo Kwan](https://www.leojkwan.com/swiftdata-cloudkit-deploy-schema-changes/)
- [Fixing CloudKit Sync in Production: Deploying Schema — fatbobman](https://fatbobman.com/en/snippet/why-core-data-or-swiftdata-cloud-sync-stops-working-after-app-store-login/)
- [Core Data with CloudKit — Synchronizing Public Database — fatbobman](https://fatbobman.com/en/posts/coredatawithcloudkit-5/)
- [Sync a Core Data store with the CloudKit public database — WWDC20](https://developer.apple.com/videos/play/wwdc2020/10650/)
- [40 per second rate limit after a CKSubscription — Apple Developer Forums](https://developer.apple.com/forums/thread/114339)
- [Five Reasons CloudKit Notifications Are Not Arriving — Cocoacasts](https://cocoacasts.com/five-reasons-cloudkit-notifications-are-not-arriving)
- [Dark Mode: Adding support to your app in Swift — SwiftLee](https://www.avanderlee.com/swift/dark-mode-support-ios/)
- [Overriding Dark Mode — Use Your Loaf](https://useyourloaf.com/blog/overriding-dark-mode/)
- [Implement In-App Dark Mode Using Swift Observation Protocols — SwiftSenpai](https://swiftsenpai.com/development/implement-in-app-dark-mode-using-swift-observation-protocols/)
- [Using NavigationPath with TabView in SwiftUI — Tanaschita](https://tanaschita.com/swiftui-navigation-path-with-tabview/)
- [Building a High-Performance Confetti Animation in SwiftUI using SpriteKit — Stackademic](https://blog.stackademic.com/building-a-high-performance-confetti-animation-in-swiftui-using-spritekit-03bed17cf277)
- [How to Comply with Apple App Store User-Generated Content Requirements — TermsFeed](https://www.termsfeed.com/videos/apple-app-store-comply-ugc-requirements/)
- [How to avoid App Store rejection for apps with User-Generated Content — Armia](https://www.armia.com/blog/how-to-avoid-app-store-rejection-for-apps-with-user-generated-content/)

### v1.0 Research Sources (Retained)

- [Designing Models for CloudKit Sync: Core Data & SwiftData Rules — fatbobman.com](https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/)
- [Some Quirks of SwiftData with CloudKit — Firewhale.io](https://firewhale.io/posts/swift-data-quirks/)
- [Fixing SwiftData & Core Data Sync: initializeCloudKitSchema — fatbobman.com](https://fatbobman.com/en/snippet/resolving-incomplete-icloud-data-sync-in-ios-development-using-initializecloudkitschema/)
- [SwiftData+CloudKit Migration — Apple Developer Forums](https://developer.apple.com/forums/thread/742899)
- [How to access a SwiftData container from widgets — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-access-a-swiftdata-container-from-widgets)
- [An Unauthorized Guide to SwiftData Migrations — Atomic Robot](https://atomicrobot.com/blog/an-unauthorized-guide-to-swiftdata-migrations/)
- [App Store Review Guidelines — Apple Developer](https://developer.apple.com/app-store/review/guidelines/)
