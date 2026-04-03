# Pitfalls Research

**Project:** Vitamin G — iOS Goal Tracking / Gratitude App
**Domain:** iOS 17+, SwiftData, CloudKit sync, WidgetKit, UserNotifications, MVVM
**Researched:** 2026-04-03
**Overall confidence:** HIGH (sourced from Apple Developer Forums, official docs, verified community articles)

---

## Critical Pitfalls

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

## Common Mistakes

### P1-1 — MVVM + @Query Collision: Putting @Query in a ViewModel Breaks the Pattern

**What goes wrong:** `@Query` is a SwiftUI property wrapper that requires access to the SwiftUI environment's `ModelContext`. When placed inside a `class`-based ViewModel (even an `@Observable` one), `@Query` has no SwiftUI environment to attach to and either fails to compile or returns empty results.

**Root cause:** `@Query` is designed for `View` bodies. It cannot live in an arbitrary class.

**Consequences:**
- Developers who strictly apply MVVM attempt to move `@Query` into the ViewModel, then hit confusing empty-data bugs.
- Workarounds involve maintaining manual fetch arrays in ViewModels that must be kept in sync by hand.

**Prevention:**
- Accept the hybrid pattern: `@Query` lives in the `View`, but sorting/filtering predicates are owned by the ViewModel.
- For imperative fetches in a ViewModel, use `ModelContext.fetch(_:)` with a `FetchDescriptor`.
- Mark ViewModels with `@Observable` (not `ObservableObject`) for iOS 17+. Use `@State` in the view to instantiate them.
- Do not use `@Published` — `@Observable` makes all stored properties observable automatically.

**Warning signs:** `@Query` inside a `class`. ViewModel inheriting `ObservableObject` with `@Published` properties in an iOS 17+ codebase.

**Phase:** Phase 1 (architecture setup). Establish the correct pattern in the first ViewModel; enforce it via code review from that point.

---

### P1-2 — SwiftData Models Are Not Sendable — Passing Across Actors Causes Crashes

**What goes wrong:** SwiftData `@Model` instances are bound to the `ModelContext` they were fetched from. Passing a model object from a background `ModelActor` context to the main actor (e.g., via a completion closure or `async` return) crashes at runtime with an assertion failure.

**Root cause:** SwiftData models are not `Sendable`. They track their context internally and assert single-actor access.

**Consequences:**
- Background data operations (e.g., computing streak statistics, bulk-inserting goals) that naively return model objects to the UI crash under Swift concurrency.

**Prevention:**
- Never pass `@Model` instances across actor boundaries. Pass only IDs (e.g., `PersistentIdentifier`) or plain value-type structs.
- Use `@ModelActor` for background contexts. Fetch and process data entirely within that actor, then return primitive results to the main actor.
- Reserve `ModelContainer.mainContext` exclusively for main-actor UI work.

**Warning signs:** `async` functions returning `@Model` objects. `Task.detached` blocks that access `ModelContext`. Passing model objects into `DispatchQueue.global()` closures.

**Phase:** Phase 2 (streak/statistics features). Any background computation phase.

---

### P1-3 — iOS Notification Scheduling Hard Limit of 64 Pending Requests

**What goes wrong:** iOS allows a maximum of 64 pending `UNNotificationRequest` objects per app. The system keeps only the soonest-firing 64 and silently drops the rest. A naive implementation that pre-schedules a year of daily morning notifications (365 requests) will have 301 requests silently discarded.

**Root cause:** `UNUserNotificationCenter` enforces a 64-request cap at the OS level. There is no error thrown — excess requests are silently ignored.

**Consequences:**
- Notifications stop being delivered after the 64th scheduled date, with no indication to the developer or user.
- For a daily notification app this means at most 64 days of pre-scheduled notifications.

**Prevention:**
- Pre-schedule only 60 days of notifications (staying safely under the cap).
- Reschedule the next batch when the app is foregrounded: in `applicationDidBecomeActive` / `sceneDidBecomeActive`, check pending count and top up to 60 days if below a threshold.
- Use `UNUserNotificationCenter.current().getPendingNotificationRequests` to audit the queue before adding.
- Do not call `removeAllPendingNotificationRequests()` carelessly — it wipes all scheduled notifications including ones added by other parts of the app.

**Warning signs:** Pre-scheduling notifications in a single batch for more than 60 future dates. No rescheduling logic in the app's foreground re-entry points.

**Phase:** Phase 3 (notifications). Must be the implementation strategy from day one.

---

### P1-4 — Notification Permission Requested Too Early (App Launch)

**What goes wrong:** Requesting notification permission at app launch (before the user understands the app's value) triggers the OS permission dialog immediately. Users who dismiss it deny permission permanently — a significant portion of goal-tracking app users never re-enable notifications after an initial dismissal.

**Root cause:** iOS shows the system permission dialog exactly once. A second request to `requestAuthorization` after denial does nothing; the user must manually go to Settings.

**Consequences:**
- Low notification opt-in rate hurts the core value proposition (morning reminders are the product's main hook).
- App Store reviewers flag apps that require notifications to function (Guideline 4.5.4).

**Prevention:**
- Show a custom pre-permission screen explaining the "daily morning reminder" value before triggering the system dialog.
- Request permission only after the user has set at least one goal (demonstrated intent).
- Handle the `.denied` authorization status gracefully — show an in-app prompt with a "Enable in Settings" deep link using `UIApplication.openSettingsURLString`.
- Never gate core app functionality on notification permission; reviewers will reject the app.

**Warning signs:** `requestAuthorization` called in `AppDelegate.application(_:didFinishLaunchingWithOptions:)` or at first app screen load.

**Phase:** Phase 3 (notifications). Gate the permission request behind the first-goal-creation flow.

---

### P1-5 — Streak Timezone and DST Edge Cases Break Reset Logic

**What goes wrong:** Streak calculations based on UTC dates fail for users in non-UTC timezones. A user who completes a goal at 11:30 PM local time (which is 4:30 AM UTC next day) may have their "today" completion counted on the wrong calendar day, breaking streaks or granting double-credit.

**Root cause:** Streak "days" are local calendar days, not UTC intervals. DST transitions create days that are 23 or 25 hours long, breaking naive "did anything happen in the last 86,400 seconds" logic.

**Consequences:**
- Streaks reset incorrectly for users in non-UTC timezones, especially near DST transitions.
- Users lose streaks they legitimately maintained, generating support complaints and negative reviews.

**Prevention:**
- Store all timestamps as UTC `Date` values in SwiftData.
- Compute streak boundaries using `Calendar.current` (not `Calendar(identifier: .gregorian)` with a hardcoded timezone) so the device's local calendar is always used.
- Use `Calendar.current.isDateInToday(_:)` and `Calendar.current.isDate(_:inSameDayAs:)` for day comparisons, never raw `TimeInterval` arithmetic.
- Test streak logic with a `Calendar` stub that can be injected with different timezones.

**Warning signs:** Streak logic using `Date().timeIntervalSince(lastCompletionDate) < 86400`. Hardcoded `TimeZone(identifier: "UTC")` in date comparisons.

**Phase:** Phase 2 (core data model and statistics). Streak model design must be correct before UI is built on top of it.

---

### P1-6 — SwiftData Unique Constraint Added to Existing Field Blocks App Launch

**What goes wrong:** Adding `@Attribute(.unique)` to a field (e.g., `id: UUID`) that already has duplicate values in existing stores causes SwiftData to abort the migration at launch. The app will not open for affected users.

**Root cause:** SwiftData enforces uniqueness constraints during migration. If duplicates exist, it has no automatic resolution and halts.

**Consequences:**
- App appears to crash on launch after an update, with no user-facing error message.
- Affects any user whose data has duplicates, which may be common if sync introduced them.

**Prevention:**
- Define uniqueness constraints from the very first version of the model — do not add them retroactively.
- For `id: UUID` specifically, it is inherently unique if always generated with `UUID()` — adding `@Attribute(.unique)` is a guardrail, not a functional requirement, and can be deferred.
- If adding a unique constraint to an existing field post-ship, write a `CustomMigrationStage` that de-duplicates records before the constraint is applied.
- Note: `@Attribute(.unique)` is also **incompatible with CloudKit** — CloudKit does not support atomic cross-device uniqueness checks. Do not use it if CloudKit sync is enabled.

**Warning signs:** `@Attribute(.unique)` added in a schema migration without a custom de-duplication stage. `@Attribute(.unique)` on any field in a CloudKit-enabled model.

**Phase:** Phase 1 (data modeling). Must be a deliberate decision, not an afterthought.

---

## Watch Out For

### P2-1 — Input Validation Must Happen at the ViewModel/Model Layer, Not Only the View

**What goes wrong:** SwiftUI `TextField` character limits enforced only via view-layer `.onChange` modifiers can be bypassed by programmatic inserts (e.g., paste, Siri shortcuts, widget interactions, or future API exposure). Overly long strings inserted into SwiftData may cause display issues or, in extreme cases, performance problems.

**Prevention:**
- Validate and truncate/reject invalid input in the ViewModel's `save` method, not only in the View.
- Define constants (e.g., `Goal.maxTitleLength = 100`, `Goal.maxDescriptionLength = 500`) in a single source of truth and reference them from both View and ViewModel.
- Log or silently truncate rather than crash on oversized input.

**Phase:** Phase 1 (data model) for constants; Phase 2 (ViewModel layer) for enforcement.

---

### P2-2 — WidgetKit Timeline Does Not Update Reactively to SwiftData Changes

**What goes wrong:** When the main app modifies a goal (e.g., marks it complete), the widget does not automatically reflect the change. Widgets operate on a scheduled timeline model, not a reactive data stream.

**Root cause:** WidgetKit's `TimelineProvider` is not connected to SwiftData's change notifications. The widget process may be suspended and never re-queried.

**Prevention:**
- After any goal modification, call `WidgetCenter.shared.reloadAllTimelines()` from the main app.
- For critical state changes (goal completion, new goal added), always trigger a timeline reload.
- Keep widget timeline entry generation lightweight — fetch only the minimum necessary data.

**Phase:** Phase 4 (widgets). A one-line fix, but easy to forget.

---

### P2-3 — CloudKit Sync Conflicts Are Silent — No Built-In Conflict Resolution UI

**What goes wrong:** If a user edits a goal on two devices simultaneously while offline, CloudKit will resolve the conflict automatically using "last write wins" semantics. The user may lose an edit with no indication that a conflict occurred.

**Root cause:** SwiftData's CloudKit integration uses `NSPersistentCloudKitContainer` under the hood, which applies last-write-wins with no app-level conflict notification API.

**Prevention:**
- Accept last-write-wins for v1 — it is appropriate for a single-user personal app.
- Store `lastModifiedDate` on every goal so that conflict resolution is at least predictable.
- Document this behavior in the app's privacy/data description so users understand multi-device sync semantics.

**Phase:** Phase 3 (CloudKit integration). Design decision, not an implementation fix.

---

### P2-4 — App Store Guideline 4.5.4 — Notifications Cannot Be Required for Core Functionality

**What goes wrong:** If the app's main value proposition is described in App Store metadata as "daily push notification reminders" and the app gates key features behind notification permission, reviewers may reject under Guideline 4.5.4.

**Prevention:**
- Ensure the app is fully functional without notifications — daily reminders are an enhancement, not the product.
- App Store description should emphasize goal tracking as the core feature; notifications as a supporting feature.
- Provisional authorization (`UNAuthorizationOptionProvisional`) can be used to trial-deliver quiet notifications without requiring a permission dialog — a useful onboarding technique.

**Phase:** Phase 5 (App Store submission). Inform marketing copy and onboarding design decisions.

---

### P2-5 — @Observable ViewModels Must Be Instantiated with @State, Not @StateObject

**What goes wrong:** Developers migrating from `ObservableObject` patterns wrap `@Observable` ViewModels in `@StateObject`. `@StateObject` is for `ObservableObject`-conforming types only. Using it with `@Observable` results in the ViewModel not receiving automatic SwiftUI observation invalidation, causing the view to not update when ViewModel properties change.

**Root cause:** `@Observable` and `@ObservableObject` are separate observation systems. `@StateObject` hooks into `objectWillChange`, which `@Observable` types do not publish.

**Prevention:**
- Use `@State var viewModel = GoalViewModel()` for `@Observable` ViewModels in iOS 17+.
- Remove all `@Published` annotations from `@Observable` classes — they are implicit and `@Published` has no effect.
- Do not mix `@Observable` and `ObservableObject` on the same type.

**Phase:** Phase 1 (architecture). Establish this pattern in the first ViewModel.

---

### P2-6 — initializeCloudKitSchema() Must Never Be Called in Production Builds

**What goes wrong:** Calling `NSPersistentCloudKitContainer.initializeCloudKitSchema()` in a production build can corrupt the production CloudKit schema or create unexpected schema versions.

**Prevention:**
- Gate with `#if DEBUG` preprocessor flag.
- Call once manually during development when the local model changes, not on every app launch.

**Phase:** Phase 3 (CloudKit integration).

---

## Phase Mapping

| Pitfall | ID | Phase | Priority |
|---------|-----|-------|----------|
| All model properties must be optional for CloudKit | P0-1 | Phase 1 — Data Model | Blocking |
| VersionedSchema from day one | P0-2 | Phase 1 — Data Model | Blocking |
| CloudKit schema is add-only after production | P0-3 | Phase 1 + CloudKit Phase | Blocking |
| App Group store path change breaks existing users | P0-4 | Phase 1 — Infrastructure | Blocking |
| Widget must create its own ModelContainer | P0-5 | Phase 4 — Widgets | Blocking |
| @Query cannot live in ViewModel | P1-1 | Phase 1 — Architecture | High |
| Models not Sendable — no cross-actor passing | P1-2 | Phase 2 — Statistics | High |
| 64 notification request limit | P1-3 | Phase 3 — Notifications | High |
| Permission requested too early | P1-4 | Phase 3 — Notifications | High |
| Streak timezone / DST bugs | P1-5 | Phase 2 — Core Logic | High |
| Unique constraint on existing field blocks launch | P1-6 | Phase 1 — Data Model | High |
| Input validation at ViewModel layer | P2-1 | Phase 1 + Phase 2 | Medium |
| Widget timeline not reactive to SwiftData changes | P2-2 | Phase 4 — Widgets | Medium |
| CloudKit silent conflict resolution | P2-3 | Phase 3 — CloudKit | Low (acceptable) |
| App Store Guideline 4.5.4 | P2-4 | Phase 5 — Submission | Medium |
| @Observable must use @State not @StateObject | P2-5 | Phase 1 — Architecture | Medium |
| initializeCloudKitSchema in production | P2-6 | Phase 3 — CloudKit | Medium |

---

## Sources

- [Designing Models for CloudKit Sync: Core Data & SwiftData Rules — fatbobman.com](https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/)
- [Some Quirks of SwiftData with CloudKit — Firewhale.io](https://firewhale.io/posts/swift-data-quirks/)
- [Fixing SwiftData & Core Data Sync: initializeCloudKitSchema — fatbobman.com](https://fatbobman.com/en/snippet/resolving-incomplete-icloud-data-sync-in-ios-development-using-initializecloudkitschema/)
- [Syncing model data across a person's devices — Apple Developer Documentation](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)
- [SwiftData+CloudKit Migration — Apple Developer Forums](https://developer.apple.com/forums/thread/742899)
- [How to access a SwiftData container from widgets — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-access-a-swiftdata-container-from-widgets)
- [Add App Group to Existing SwiftData App — Apple Developer Forums](https://developer.apple.com/forums/thread/789173)
- [Using WidgetKit + SwiftData — Caleb Hearth](https://calebhearth.com/using-widgetkit-with-swiftdata)
- [SwiftData with Widgets in SwiftUI — Rishabh Sharma, Medium](https://medium.com/@rishixcode/swiftdata-with-widgets-in-swiftui-0aab327a35d8)
- [Is SwiftData incompatible with MVVM? — Matteo Manferdini](https://matteomanferdini.com/swiftdata-mvvm/)
- [How to use MVVM to separate SwiftData from your views — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-use-mvvm-to-separate-swiftdata-from-your-views)
- [SwiftData does not work on a background Task — Apple Developer Forums](https://developer.apple.com/forums/thread/736226)
- [Using ModelActor in SwiftData — BrightDigit](https://brightdigit.com/tutorials/swiftdata-modelactor/)
- [Saving SwiftData in Background Does Not Update @Query — Apple Developer Forums](https://developer.apple.com/forums/thread/758882)
- [If You Are Not Versioning Your SwiftData Schema — AzamSharp](https://azamsharp.com/2026/02/14/if-you-are-not-versioning-your-swiftdata-schema.html)
- [An Unauthorized Guide to SwiftData Migrations — Atomic Robot](https://atomicrobot.com/blog/an-unauthorized-guide-to-swiftdata-migrations/)
- [How to create a complex migration using VersionedSchema — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-a-complex-migration-using-versionedschema)
- [iOS pending notification limit — Flutter Local Notifications Issue](https://github.com/MaikuB/flutter_local_notifications/issues/2312)
- [Scheduling a notification locally from your app — Apple Developer Documentation](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)
- [App Store Review Guidelines — Apple Developer](https://developer.apple.com/app-store/review/guidelines/)
- [The ultimate guide to App Store rejections — RevenueCat](https://www.revenuecat.com/blog/growth/the-ultimate-guide-to-app-store-rejections/)
- [Handling Time Zones in Global Gamification Features — Trophy](https://trophy.so/blog/handling-time-zones-gamification)
- [How to Build a Streaks Feature — Trophy](https://trophy.so/blog/how-to-build-a-streaks-feature)
- [Migrating a Core Data store to an App Group shared container — Pol Piella](https://www.polpiella.dev/core-data-migration-app-group)
- [Relationships in SwiftData — fatbobman.com](https://fatbobman.com/en/posts/relationships-in-swiftdata-changes-and-considerations/)
