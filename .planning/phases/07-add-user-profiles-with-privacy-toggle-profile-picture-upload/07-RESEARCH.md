# Phase 7: User Profiles with Privacy Toggle — Research

**Researched:** 2026-04-13
**Domain:** SwiftData schema migration (V1→V2), CloudKit public database writes, iOS deep-link URL schemes, SwiftUI profile UI patterns
**Confidence:** HIGH (core migration + CloudKit patterns), MEDIUM (CloudKit public DB details)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Avatar**
- D-01: Avatar is a color placeholder with initials — randomly-assigned background color, user's initials on top. No AI API, no photo upload in Phase 7.
- D-02: Color assignment is random at profile creation and persists. User cannot change the color in Phase 7.
- D-03: Photo upload is explicitly deferred. Model must have an optional `photoData: Data?` slot reserved (not surfaced in UI).

**Privacy — Profile level**
- D-04: Profile has a Public / Private toggle. Default: Private.
- D-05: When Public: profile and public goals are visible to anyone with the share link. Stored in CloudKit's **public database**.
- D-06: When Private: profile is not accessible externally. Share Profile button is disabled.
- D-07: Sharing mechanism is a deep link (`vitaming://profile/<recordID>`). User taps "Share Profile" → system share sheet with link.

**Privacy — Per-goal level**
- D-08: Each goal has `isPublic: Bool` (default: `false`).
- D-09: Public/private toggle surfaced on GoalDetailView and EditGoalView.
- D-10: `isPublic` field requires a SchemaV2 migration.

**Profile tab + entry point**
- D-11: Profile is a 4th tab in the TabView. Tab label: "Profile", SF Symbol: `person.crop.circle`.
- D-12: Profile tab layout: Avatar → Display name + edit button → Privacy toggle → Public goals preview → Share Profile button.

**UserProfile data model**
- D-13: New `UserProfile` SwiftData model in SchemaV2:
  - `id: UUID`
  - `displayName: String?` (max 50 chars)
  - `avatarColorHex: String?` (randomly assigned, persisted)
  - `isPublic: Bool` (default: false)
  - `cloudKitPublicRecordID: String?`
  - `photoData: Data?` (reserved nil field, not surfaced)
- D-14: Exactly one UserProfile per device/iCloud account. Created automatically on first Profile tab visit.

**SchemaV2 migration**
- D-15: SchemaV2 must add:
  1. `UserProfile` model to `SchemaV2.models`
  2. `isPublic: Bool = false` property to `Goal`
  3. `SchemaMigrationPlan` updated with V1→V2 stage
  4. `ModelContainerFactory` updated to use SchemaV2 as current schema

### Claude's Discretion
- Exact SF Symbol for the Profile tab
- Avatar color palette (warm, gratitude-toned)
- Visual treatment of the privacy toggle
- Display name character limit enforcement (recommend 50 chars)
- Deep link URL scheme registration in Info.plist
- Share sheet copy
- Empty state for Profile tab when no public goals
- Error handling for CloudKit public database write failures

### Deferred Ideas (OUT OF SCOPE)
- Photo upload
- Avatar color customization
- Username / search
- Follow / friends system
</user_constraints>

---

## Summary

Phase 7 adds a personal identity layer to VitaminG. The core engineering work is a **SwiftData SchemaV2 migration** that adds a new `UserProfile` model and an `isPublic` property to the existing `Goal` model, plus a **CloudKit public database write** for sharing a profile link, plus **deep-link URL scheme** registration for the `vitaming://` scheme.

The migration is lightweight: adding a new model to `SchemaV2.models` and adding `isPublic: Bool = false` with a default value to `Goal` both qualify for `MigrationStage.lightweight`. The CloudKit public database write is a separate, direct CloudKit API call — it cannot go through SwiftData's `.automatic` private database integration. The profile write to CloudKit public must use `CKContainer.default().publicCloudDatabase.save()` with an async/await call guarded in a `Task`.

Deep linking uses iOS's standard custom URL scheme mechanism: register `vitaming` in Info.plist URL Types, then parse with `.onOpenURL` on the `WindowGroup`. Phase 7 only needs to generate the share link from the stored `cloudKitPublicRecordID` — incoming deep link parsing for public profile viewing is a future feature (deferred in CONTEXT.md).

**Primary recommendation:** Implement SchemaV2 with a lightweight migration plan first; isolate the CloudKit public write in `ProfileViewModel`; register the URL scheme in Info.plist and generate the link in the Share button — no incoming deep link parsing required in Phase 7.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftData | iOS 17+ | Persistence for UserProfile and Goal.isPublic | Already in use (SchemaV1) |
| CloudKit (CKContainer/CKDatabase) | iOS 9+ | Public database write for profile sharing | Only path to CloudKit public DB from SwiftData apps |
| SwiftUI | iOS 17+ | ProfileView, AvatarView, ProfileEditSheet | Already in use throughout |
| UserNotifications | (no change) | Not modified | Unchanged |
| WidgetKit | (no change) | SchemaV2 migration affects makeWidgetContainer — must be updated | Existing dependency |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| XCTest | N/A | Unit tests for ProfileViewModel, SchemaV2, migration | All testable logic |
| Foundation (UUID, URL) | iOS 17+ | UUID for UserProfile.id, URL for deep link construction | Already in use |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Direct CKDatabase.save() for public write | NSPersistentCloudKitContainer `.shared` | SwiftData `.automatic` only writes to private DB — public requires direct CloudKit API |
| Custom URL scheme (`vitaming://`) | Universal Links | Universal Links require an HTTPS-hosted `apple-app-site-association` file and a backend — overkill for Phase 7 share-link only |

**Installation:** No new dependencies. All frameworks are already in the project.

---

## Architecture Patterns

### Recommended Project Structure — New Files

```
VitaminG/VitaminG/VitaminG/
├── Models/
│   ├── SchemaV1.swift           — Unchanged (source of truth for V1)
│   ├── SchemaV2.swift           — NEW: V2 models, typealiases, migration plan
│   └── Goal.swift               — Unchanged (GoalTier enum; Goal class now in SchemaV2)
├── Persistence/
│   └── ModelContainerFactory.swift  — MODIFIED: reference SchemaV2, add migrationPlan
├── ViewModels/
│   └── ProfileViewModel.swift   — NEW: @Observable, profile CRUD + CloudKit write
└── Views/
    ├── ProfileView.swift         — NEW: 4th tab content
    └── ContentView.swift        — MODIFIED: add 4th tab
```

### Pattern 1: SchemaV2 VersionedSchema — Lightweight Migration

**What:** Declare `SchemaV2` as a new `VersionedSchema` enum that mirrors SchemaV1's `Goal` model (with `isPublic` added) plus a new `UserProfile` model. Use `MigrationStage.lightweight` for the V1→V2 stage.

**When to use:** Adding optional properties, properties with default values, or entirely new models — SwiftData handles these automatically.

**Key rule:** Adding `isPublic: Bool = false` to `Goal` qualifies as lightweight because a default value is provided and all existing records receive the default. Adding a brand-new model (`UserProfile`) to `schemas` also qualifies as lightweight.

```swift
// Source: [CITED: donnywals.com/a-deep-dive-into-swiftdata-migrations/]
// Source: [CITED: developer.apple.com/documentation/swiftdata/modelcontainer]

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Goal.self, CompletionEvent.self, UserProfile.self]
    }

    // MARK: - Goal (V2 — adds isPublic)
    @Model
    final class Goal {
        var id: UUID = UUID()
        var title: String?
        var goalDescription: String?
        var tierRawValue: String?
        var isCompleted: Bool = false
        var creationDate: Date?
        var associatedInspiration: String?
        var isPublic: Bool = false          // NEW in V2 — lightweight default

        @Relationship(deleteRule: .cascade, inverse: \CompletionEvent.goal)
        var completionEvents: [CompletionEvent]?

        init(
            title: String,
            goalDescription: String = "",
            tier: GoalTier = .immediate,
            associatedInspiration: String = ""
        ) {
            self.id = UUID()
            self.title = title
            self.goalDescription = goalDescription
            self.tierRawValue = tier.rawValue
            self.isCompleted = false
            self.creationDate = Date()
            self.associatedInspiration = associatedInspiration
            self.completionEvents = []
            self.isPublic = false
        }

        var tier: GoalTier {
            get { GoalTier(rawValue: tierRawValue ?? "") ?? .immediate }
            set { tierRawValue = newValue.rawValue }
        }
        var completed: Bool {
            get { isCompleted }
            set { isCompleted = newValue }
        }
    }

    // MARK: - CompletionEvent (V2 — unchanged, redeclared for schema completeness)
    @Model
    final class CompletionEvent {
        var id: UUID = UUID()
        var completedAt: Date?
        var tierRawValue: String?
        var goal: Goal?

        init(goal: Goal) {
            self.id = UUID()
            self.goal = goal
            self.tierRawValue = goal.tierRawValue
            self.completedAt = Date()
        }
        var tier: GoalTier {
            GoalTier(rawValue: tierRawValue ?? "") ?? .immediate
        }
    }

    // MARK: - UserProfile (NEW in V2)
    @Model
    final class UserProfile {
        var id: UUID = UUID()
        var displayName: String?
        var avatarColorHex: String?
        var isPublic: Bool = false
        var cloudKitPublicRecordID: String?
        var photoData: Data?           // reserved for future photo upload

        init() {
            self.id = UUID()
            self.isPublic = false
        }
    }
}

// MARK: - Typealiases (update to point to V2)
typealias Goal = SchemaV2.Goal
typealias CompletionEvent = SchemaV2.CompletionEvent
typealias UserProfile = SchemaV2.UserProfile
```

**CRITICAL:** Once typealiases are updated to SchemaV2, `SchemaV1.Goal` and `SchemaV1.CompletionEvent` must not be used at call sites. The typealiases handle this transparently.

### Pattern 2: SchemaMigrationPlan

```swift
// Source: [CITED: donnywals.com/a-deep-dive-into-swiftdata-migrations/]
// Source: [CITED: developer.apple.com/documentation/swiftdata/modelcontainer/init(for:migrationplan:configurations:)]

enum VitaminGMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
```

### Pattern 3: ModelContainerFactory Update

```swift
// Source: [CITED: developer.apple.com/documentation/swiftdata/modelcontainer]
// MODIFIED: Use SchemaV2 schema and VitaminGMigrationPlan

enum ModelContainerFactory {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(SchemaV2.models, version: SchemaV2.versionIdentifier)

        #if targetEnvironment(simulator)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        #else
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: inMemory ? .none : .identifier("group.com.kyleharrington.VitaminG"),
            cloudKitDatabase: inMemory ? .none : .automatic
        )
        #endif

        return try ModelContainer(
            for: schema,
            migrationPlan: VitaminGMigrationPlan.self,
            configurations: config
        )
    }
    // makeWidgetContainer() needs same Schema update (SchemaV2.models)
}
```

**Note:** The `migrationPlan:` parameter is passed to `ModelContainer.init(for:migrationPlan:configurations:)`. The `for:` parameter receives the schema, not a single model type — use the form `ModelContainer(for: schema, migrationPlan:..., configurations:...)`. [CITED: developer.apple.com/documentation/swiftdata/modelcontainer]

### Pattern 4: CloudKit Public Database Write

SwiftData's `.automatic` CloudKit integration only writes to the **private** database. Writing to CloudKit public requires direct use of `CKContainer` / `CKDatabase` API. [VERIFIED: Apple Developer Forums thread/731334]

```swift
// Source: [CITED: superwall.com/blog/syncing-data-with-cloudkit...]
// Source: [CITED: developer.apple.com/documentation/cloudkit/ckdatabase]

import CloudKit

// In ProfileViewModel:
func publishProfileToCloudKit(profile: UserProfile) async throws -> String {
    let container = CKContainer(identifier: "iCloud.com.kyleharrington.VitaminG")
    let publicDB = container.publicCloudDatabase

    let record = CKRecord(recordType: "PublicProfile")
    record["displayName"] = profile.displayName as? CKRecordValue
    record["avatarColorHex"] = profile.avatarColorHex as? CKRecordValue
    record["isPublic"] = true as CKRecordValue

    let savedRecord = try await publicDB.save(record)
    return savedRecord.recordID.recordName  // store in profile.cloudKitPublicRecordID
}
```

**Idempotency:** If `cloudKitPublicRecordID` is already set, skip the save and reuse the existing ID. If privacy is toggled back off, do NOT delete the CK record — just stop surfacing the share link (too risky to silently delete user data). [ASSUMED]

### Pattern 5: Deep Link URL Scheme Registration and Generation

**Registration (Info.plist — must be added manually or via Xcode target editor):**

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>vitaming</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.kyleharrington.VitaminG</string>
    </dict>
</array>
```

**Link generation in ProfileViewModel:**

```swift
// Source: [CITED: avanderlee.com/swiftui/deeplink-url-handling/]
var shareURL: URL? {
    guard let recordID = profile?.cloudKitPublicRecordID else { return nil }
    return URL(string: "vitaming://profile/\(recordID)")
}
```

**Receiving deep links (Phase 7 only generates, does not need to receive):**

```swift
// In VitaminGApp.body (future phase — Phase 7 generates links, does not need to parse incoming profile links)
.onOpenURL { url in
    // Existing: notification deep link handling
    // Future: parse vitaming://profile/<id> here
}
```

Phase 7 only needs the generation side. The current `NotificationDelegate` already handles the `goalList` deep link. The URL scheme registration is still required in Info.plist so the share link is a valid tappable link on other devices.

### Pattern 6: ProfileViewModel (@Observable)

Follows the same `@Observable` pattern as `GoalViewModel`. No business logic in views.

```swift
// Source: [ASSUMED - pattern matches existing GoalViewModel]
@Observable
final class ProfileViewModel {
    static let maxDisplayNameLength = 50

    // UI draft state
    var draftDisplayName: String = ""
    var showingEditSheet = false
    var showingCloudKitError = false

    // Loaded from SwiftData
    private(set) var profile: UserProfile?

    var isPublic: Bool { profile?.isPublic ?? false }
    var displayName: String { profile?.displayName ?? "" }
    var avatarColorHex: String? { profile?.avatarColorHex }
    var initials: String { /* split displayName, take first letter of each word, max 2 */ }
    var shareURL: URL? { /* vitaming://profile/<cloudKitPublicRecordID> */ }

    func loadOrCreateProfile(context: ModelContext) { ... }
    func updateDisplayName(_ name: String, context: ModelContext) throws { ... }
    func setPublic(_ isPublic: Bool, context: ModelContext) async { ... }
    func updateGoalPublicStatus(goal: Goal, isPublic: Bool, context: ModelContext) { ... }
}
```

### Pattern 7: initials Computation

```swift
// Source: [CITED: 07-UI-SPEC.md — initials derivation rule]
var initials: String {
    guard let name = profile?.displayName, !name.isEmpty else { return "?" }
    let words = name.split(separator: " ").prefix(2)
    return words.compactMap { $0.first.map { String($0).uppercased() } }.joined()
}
```

### Pattern 8: Avatar Color Assignment

```swift
// Source: [CITED: 07-UI-SPEC.md — Avatar Color Palette]
// 6-color warm palette drawn from GoalTier colors + 2 warm additions
static let avatarPalette: [Color] = [
    Color(red: 0.98, green: 0.55, blue: 0.27),  // Warm orange (Immediate)
    Color(red: 0.36, green: 0.78, blue: 0.64),  // Fresh teal (Short-Term)
    Color(red: 0.40, green: 0.61, blue: 0.95),  // Calm blue (Long-Term)
    Color(red: 0.78, green: 0.48, blue: 0.95),  // Deep violet (Life Goal)
    Color(red: 0.95, green: 0.75, blue: 0.28),  // Sunflower gold
    Color(red: 0.87, green: 0.40, blue: 0.55),  // Rose
]

// Stored as hex string in UserProfile.avatarColorHex
// Assigned once at creation: Int.random(in: 0..<6) → avatarPalette[index] → hex string
```

For converting a `Color` to a hex string, use a simple `UIColor` bridge:

```swift
// Source: [ASSUMED]
extension Color {
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
```

### Anti-Patterns to Avoid

- **Re-declaring SchemaV1 models in SchemaV2 with incompatible changes:** All V2 model classes must be declared inside the `SchemaV2` enum; the V1 versions are not modified. The typealiases are updated to point to V2 types after migration is in place.
- **Using SwiftData `.automatic` for public database:** SwiftData's CloudKit integration is private-database only. Public writes need direct `CKDatabase.save()`.
- **Forgetting to update makeWidgetContainer:** Widget container must also use `SchemaV2.models` and `migrationPlan:` or it will crash when opening the migrated store.
- **Storing CloudKit record writes in modelContext:** The `cloudKitPublicRecordID` is persisted in SwiftData (in `UserProfile`), not in CloudKit's local record. CloudKit write is fire-and-retry; SwiftData holds the canonical ID.
- **Using `@Attribute(.unique)` on UserProfile.id:** CloudKit does not support atomic uniqueness — already established by CLAUDE.md.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema migration | Manual SQLite column ALTER | SwiftData `MigrationStage.lightweight` | SwiftData handles all underlying SQLite and CloudKit schema changes automatically |
| CloudKit async save | Completion-handler chains | `CKDatabase.save()` async/await | Modern CloudKit API is async-native since iOS 15 |
| Share sheet | Custom share UI | `ShareLink(item: url)` or `UIActivityViewController` | System share sheet handles copy link, messages, AirDrop — no custom code needed |
| Deep link URL parsing | Regex / manual string split | `.onOpenURL` + `URLComponents` | SwiftUI native; `URLComponents` handles edge cases |
| Initials truncation | Complex text layout | String prefix logic + `Text` overlay on Circle | No library needed — simple computed property |

**Key insight:** Every "custom" solution in this phase (share sheet, deep link, initials, color conversion) has a first-party iOS equivalent. The only non-trivial engineering is the CloudKit public write and the SchemaV2 migration.

---

## Common Pitfalls

### Pitfall 1: makeWidgetContainer Not Updated to SchemaV2
**What goes wrong:** Widget process opens the store with SchemaV1 schema after main app has migrated to SchemaV2 — store mismatch crash at widget render.
**Why it happens:** `ModelContainerFactory.makeWidgetContainer()` references `SchemaV1.models` directly. Phase 7 forgets to update it.
**How to avoid:** Update `makeWidgetContainer()` to use `SchemaV2.models` and pass `migrationPlan: VitaminGMigrationPlan.self` in the same commit as the main container update.
**Warning signs:** Widget crashes on device after Phase 7 deploy; Xcode shows "The model used to open the store is incompatible with the one used to create the store."

### Pitfall 2: Typealiases Updated Before Migration Plan Is Ready
**What goes wrong:** Updating `typealias Goal = SchemaV2.Goal` before `ModelContainerFactory` includes the migration plan causes existing app installs to fail store open (no migration path declared).
**Why it happens:** Developer updates model file first, then ships without migration plan.
**How to avoid:** In the same SchemaV2.swift commit: declare SchemaV2 enum, declare `VitaminGMigrationPlan`, and update `ModelContainerFactory`. All three in one atomic change.

### Pitfall 3: CloudKit Public Write Blocks Main Thread
**What goes wrong:** Calling `publicDB.save()` synchronously blocks the UI thread — app freezes when toggling profile public.
**Why it happens:** `CKDatabase.save()` is network I/O; must be awaited in a background context.
**How to avoid:** Wrap in `Task { do { try await ... } catch { ... } }` in `ProfileViewModel.setPublic()`. Update SwiftData optimistically first, then attempt CK write.

### Pitfall 4: Single UserProfile Not Enforced
**What goes wrong:** App creates multiple `UserProfile` records on repeated Profile tab visits (e.g., if `loadOrCreateProfile` is called multiple times before the first insert is flushed to the store).
**Why it happens:** SwiftData insert is async; a second call before the first is committed creates a duplicate.
**How to avoid:** In `ProfileViewModel.loadOrCreateProfile`, always fetch with a `FetchDescriptor<UserProfile>` first. Only call `context.insert()` if the fetch returns empty. Store the loaded/created profile in a local property to avoid re-fetching.

### Pitfall 5: `isPublic` Lightweight Migration Fails With Non-Optional Bool Without Default
**What goes wrong:** If `isPublic: Bool` is declared without a default value in the `init` OR in the property declaration, SwiftData may not be able to perform lightweight migration for existing records (existing rows have no value for the column).
**Why it happens:** SwiftData lightweight migration requires a fallback value for non-optional properties.
**How to avoid:** Declare `var isPublic: Bool = false` (property-level default) AND include `self.isPublic = false` in the `init`. Both are needed.
**Warning signs:** App crashes at launch with "Migration failed" in the console.

### Pitfall 6: URL Scheme Not Registered in Info.plist
**What goes wrong:** Tapping a `vitaming://profile/...` link on another device shows "Safari cannot open the page" — link is not recognized as an app link.
**Why it happens:** Info.plist requires explicit `CFBundleURLTypes` registration for custom URL schemes to be recognized by iOS.
**How to avoid:** Add URL Types entry in Xcode project → target → Info tab (or directly in Info.plist). Register scheme `vitaming`.

### Pitfall 7: CloudKit Public RecordType Must Be Declared in CloudKit Dashboard Before Production
**What goes wrong:** CloudKit public writes succeed in Development but fail silently in Production because the `PublicProfile` record type was never promoted.
**Why it happens:** CloudKit Development and Production are separate environments. Record types created in Development are not available in Production until promoted (same issue as the main schema promotion in Phase 6).
**How to avoid:** After Phase 7 development, include "promote PublicProfile record type to Production" in the Phase 6/pre-distribution checklist (or add it to Phase 7 success criteria).

---

## Code Examples

### SchemaV2 + Migration Plan — Minimal Working Example

```swift
// Source: [CITED: donnywals.com/a-deep-dive-into-swiftdata-migrations/]
// Source: [CITED: developer.apple.com/documentation/swiftdata/modelcontainer]

enum VitaminGMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [SchemaV1.self, SchemaV2.self]
    static var stages: [MigrationStage] = [migrateV1toV2]

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
```

### CloudKit Public DB Save (async/await)

```swift
// Source: [CITED: developer.apple.com/documentation/cloudkit/ckdatabase]
// Source: [CITED: superwall.com/blog/syncing-data-with-cloudkit...]

func publishToCloudKitPublic(profile: UserProfile) async throws -> String {
    let ckContainer = CKContainer(identifier: "iCloud.com.kyleharrington.VitaminG")
    let record = CKRecord(recordType: "PublicProfile")
    record["displayName"] = profile.displayName as CKRecordValue?
    record["avatarColorHex"] = profile.avatarColorHex as CKRecordValue?
    let saved = try await ckContainer.publicCloudDatabase.save(record)
    return saved.recordID.recordName
}
```

### ProfileViewModel — setPublic (optimistic update)

```swift
// Source: [ASSUMED - follows GoalViewModel pattern + CloudKit async pattern]
func setPublic(_ newValue: Bool, context: ModelContext) {
    guard let profile else { return }
    profile.isPublic = newValue
    // Optimistic: SwiftData write is immediate
    if newValue && profile.cloudKitPublicRecordID == nil {
        Task {
            do {
                let recordName = try await publishToCloudKitPublic(profile: profile)
                profile.cloudKitPublicRecordID = recordName
            } catch {
                showingCloudKitError = true
                // Do NOT revert toggle — CloudKit auto-retries on connectivity restore
            }
        }
    }
}
```

### ShareLink Integration

```swift
// Source: [CITED: developer.apple.com/documentation/swiftui/sharelink]
// Source: [CITED: 07-UI-SPEC.md ShareProfileButton spec]

if let url = viewModel.shareURL {
    ShareLink(
        item: url,
        message: Text("Check out my goals on Vitamin G!")
    ) {
        Label("Share Profile", systemImage: "square.and.arrow.up")
            .font(.system(.body, design: .rounded).weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
    }
    .buttonStyle(.borderedProminent)
    .tint(Color(red: 0.98, green: 0.55, blue: 0.27))
} else {
    Button("Share Profile") {}
        .buttonStyle(.borderedProminent)
        .disabled(true)
        .accessibilityHint("Set your profile to public to enable sharing.")
}
```

### GoalDetailView — isPublic Toggle Addition

```swift
// Source: [CITED: 07-UI-SPEC.md GoalDetailView modification spec]
// Added between headerSection and quoteCardSection in GoalDetailView.body

private var publicToggleSection: some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack {
            Text("Share this goal")
                .font(.system(size: 16, weight: .regular, design: .rounded))
            Spacer()
            Toggle("", isOn: Binding(
                get: { goal.isPublic },
                set: { newValue in
                    viewModel.updateGoalPublicStatus(goal: goal, isPublic: newValue, context: modelContext)
                }
            ))
            .labelsHidden()
            .accessibilityLabel("Share this goal")
            .accessibilityValue(goal.isPublic ? "On" : "Off")
        }
        Text("Public goals appear on your profile when your profile is set to public.")
            .font(.system(size: 12, weight: .regular, design: .rounded))
            .foregroundStyle(.secondary)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal)
}
```

---

## Existing Code Integration Points

### Files That Must Be Modified

| File | Change |
|------|--------|
| `ModelContainerFactory.swift` | Use `SchemaV2.models`, add `migrationPlan: VitaminGMigrationPlan.self` |
| `ContentView.swift` | Add 4th tab: `ProfileView` with `Label("Profile", systemImage: "person.crop.circle.fill")` |
| `GoalDetailView.swift` | Add `publicToggleSection` between headerSection and quoteCardSection |
| `AppRoute.swift` | Add `.profile` case if needed for future navigation (D-11 note: tab-based, may not need a route in Phase 7) |
| `Info.plist` | Add `CFBundleURLTypes` with scheme `vitaming` |

### Files to Create

| File | Purpose |
|------|---------|
| `Models/SchemaV2.swift` | V2 VersionedSchema + VitaminGMigrationPlan + typealiases |
| `ViewModels/ProfileViewModel.swift` | @Observable ViewModel for all profile state |
| `Views/ProfileView.swift` | ProfileView + AvatarView + ProfileEditSheet + PrivacyToggleRow + PublicGoalsSection + ShareProfileButton |

### Existing Patterns to Reuse

| Pattern | Where | Use In Phase 7 |
|---------|-------|----------------|
| `@Observable` final class | GoalViewModel.swift | ProfileViewModel |
| `sanitize(_ raw: String)` | GoalViewModel.swift | Display name sanitization |
| `CharacterCountView` | AddGoalView.swift | ProfileEditSheet display name field |
| `ModelContainerFactory.makeContainer(inMemory:)` | Tests | ProfileViewModel tests |
| `.sheet(isPresented:)` + `NavigationStack` + `Form` | AddGoalView.swift | ProfileEditSheet |
| `.confirmationDialog` | GoalDetailView.swift | (Not needed in Phase 7 — no destructive profile action) |
| `Color(red:green:blue:)` literal pattern | Goal.swift, UI-SPEC | Avatar color palette |
| `VStack(spacing:)` inside `ScrollView` | StatsView | ProfileView layout |
| `Color(UIColor.systemGroupedBackground)` | StatsView | ProfileView background |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17 (2023) | Already adopted — ProfileViewModel must use `@Observable`, not `ObservableObject` |
| `NavigationView` | `NavigationStack` | iOS 16 (2022) | Already adopted — ProfileEditSheet uses `NavigationStack` |
| `ShareSheet` (UIKit wrapper) | `ShareLink` (SwiftUI native) | iOS 16 (2022) | Use `ShareLink` directly — no UIKit wrapper needed |
| Completion handler CloudKit saves | async/await `CKDatabase.save()` | iOS 15 (2021) | Use async/await throughout |

---

## Runtime State Inventory

This is not a rename/refactor phase. No stored keys, collection names, or OS registrations are being changed. New models (`UserProfile`) and new properties (`Goal.isPublic`) are additive.

**Stored data:** SchemaV1 Goal and CompletionEvent records in the existing SwiftData store — these persist unchanged through the lightweight migration. No data migration needed. [VERIFIED: lightweight migration semantics]

**Live service config:** CloudKit Development schema gains a new `PublicProfile` record type and `isPublic` attribute on `Goal`. This requires `initializeCloudKitSchema` to be run once in DEBUG to push the new attribute to CloudKit. [ASSUMED: same pattern as Phase 1 DEBUG-only schema init]

**OS-registered state:** None.

**Secrets/env vars:** None new. CloudKit container ID `iCloud.com.kyleharrington.VitaminG` is already in use.

**Build artifacts:** None.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode (Swift/SwiftUI/SwiftData) | All code | Yes (in use) | iOS 17+ | — |
| CloudKit container `iCloud.com.kyleharrington.VitaminG` | Public DB write | Yes (existing) | — | Disable Share button if CK fails |
| Info.plist URL Types entry | Deep link generation | Not yet — must add | — | Manual add in Xcode target Info tab |
| CloudKit `PublicProfile` record type in Development schema | CKRecord save | Not yet — created on first DEBUG run | — | initializeCloudKitSchema DEBUG run creates it |

**Missing with no fallback:** None — all missing items are created as part of Phase 7 work.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (existing) |
| Config file | Xcode scheme — VitaminGTests |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests` |
| Full suite command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | File |
|--------|----------|-----------|------|
| PROF-01 | SchemaV2 declares 3 models (Goal, CompletionEvent, UserProfile) | unit | `SchemaV2Tests.swift` (Wave 0 gap) |
| PROF-02 | V1→V2 lightweight migration preserves existing Goal records | unit | `SchemaV2Tests.swift` (Wave 0 gap) |
| PROF-03 | Goal.isPublic defaults to false on existing and new records | unit | `SchemaV2Tests.swift` (Wave 0 gap) |
| PROF-04 | ProfileViewModel creates exactly one UserProfile on first call | unit | `ProfileViewModelTests.swift` (Wave 0 gap) |
| PROF-05 | ProfileViewModel.initials returns correct 1-2 char string | unit | `ProfileViewModelTests.swift` (Wave 0 gap) |
| PROF-06 | ProfileViewModel.displayName validation rejects empty/whitespace | unit | `ProfileViewModelTests.swift` (Wave 0 gap) |
| PROF-07 | ProfileViewModel.displayName validation rejects >50 chars | unit | `ProfileViewModelTests.swift` (Wave 0 gap) |
| PROF-08 | ProfileViewModel.shareURL returns nil when cloudKitPublicRecordID is nil | unit | `ProfileViewModelTests.swift` (Wave 0 gap) |
| PROF-09 | ProfileViewModel.shareURL returns valid vitaming:// URL when recordID is set | unit | `ProfileViewModelTests.swift` (Wave 0 gap) |
| PROF-10 | GoalViewModel.updateGoalPublicStatus persists isPublic change | unit | `GoalViewModelTests.swift` extension (Wave 0 gap) |

### Sampling Rate

- **Per task commit:** `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/SchemaV2Tests` or `ProfileViewModelTests`
- **Per wave merge:** Full VitaminGTests suite
- **Phase gate:** Full suite green before verify

### Wave 0 Gaps

- [ ] `VitaminGTests/SchemaV2Tests.swift` — covers PROF-01, PROF-02, PROF-03
- [ ] `VitaminGTests/ProfileViewModelTests.swift` — covers PROF-04 through PROF-09
- [ ] `GoalViewModelTests.swift` — extend to cover PROF-10 (updateGoalPublicStatus)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A — no auth system |
| V3 Session Management | No | N/A |
| V4 Access Control | Yes (limited) | Privacy toggle: SwiftData private-by-default; public profile only accessible via CloudKit public DB when explicitly set public |
| V5 Input Validation | Yes | displayName: max 50 chars, sanitize() before insert (GoalViewModel.sanitize pattern) |
| V6 Cryptography | No | No encryption of profile data; CloudKit handles transport |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Oversharing (profile public by default) | Info Disclosure | Default `isPublic = false` on both UserProfile and Goal — D-04, D-08 |
| Display name injection (script tags, control chars) | Tampering | sanitize() strips control chars before insert (existing GoalViewModel.sanitize pattern) |
| CloudKit public record enumeration | Info Disclosure | Records are accessed only via direct `recordID` deep link — no query/list endpoint; public records do not expose private goals |
| photoData future field | Info Disclosure | `photoData: Data?` is nil and not rendered in Phase 7 — no privacy surface until photo upload phase |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | CloudKit public record type `PublicProfile` will be created by the existing `initializeCloudKitSchema` DEBUG utility without additional code | Runtime State Inventory | May need separate CK record type creation step; low risk — CloudKit auto-creates record types on first save in Development |
| A2 | When toggling profile from Public back to Private, the CK public record is left in place (not deleted); only `isPublic = false` is set locally | Pattern 4 | If user expectations are that "Private" fully removes the record, the link would still technically work for anyone with it — document as known behavior in UI copy |
| A3 | `MigrationStage.lightweight` handles adding a new `UserProfile` model with no existing records — SwiftData creates the table empty | Architecture Patterns | If adding a new model to schemas is not considered lightweight, a custom migration may be needed; very low risk based on all sources reviewed |
| A4 | `Color.hexString` UIColor bridge works correctly for all 6 avatar colors (no precision loss) | Pattern 8 | Minor rounding differences possible; test with actual palette values |

---

## Open Questions

1. **Does `ModelContainer(for: schema, migrationPlan:..., configurations:...)` accept a `Schema` object as the `for:` parameter, or must it take `[any PersistentModel.Type]`?**
   - What we know: Official docs show both overloads exist. `ModelContainerFactory` already passes a `Schema` object. The `migrationPlan:` overload may have a different signature.
   - What's unclear: The exact overload to use when combining a pre-built `Schema` + migration plan + configurations.
   - Recommendation: Try `ModelContainer(for: Schema(SchemaV2.models, version: SchemaV2.versionIdentifier), migrationPlan: VitaminGMigrationPlan.self, configurations: config)` — if the compiler rejects it, switch to `ModelContainer(for: SchemaV2.models, migrationPlan: VitaminGMigrationPlan.self, configurations: [config])`.

2. **CloudKit public record type promotion for Phase 6/Distribution**
   - What we know: CloudKit Development schema must be promoted to Production before App Store submission (Phase 6 already has this task for Goal/CompletionEvent schema).
   - What's unclear: Whether the `PublicProfile` record type needs to be included in Phase 6's schema promotion checklist, or whether it is automatically included.
   - Recommendation: Add `PublicProfile` record type promotion to Phase 6 success criteria explicitly.

---

## Sources

### Primary (HIGH confidence)
- [CITED: donnywals.com/a-deep-dive-into-swiftdata-migrations/] — Lightweight migration code patterns, MigrationStage.lightweight example
- [CITED: developer.apple.com/documentation/swiftdata/modelcontainer] — ModelContainer init signatures
- [CITED: 07-CONTEXT.md] — All locked decisions (D-01 through D-15)
- [CITED: 07-UI-SPEC.md] — UI components, color palette, copywriting
- [CITED: SchemaV1.swift (codebase)] — Existing model structure to extend
- [CITED: ModelContainerFactory.swift (codebase)] — Existing factory to modify
- [CITED: GoalViewModel.swift (codebase)] — ViewModel pattern to replicate

### Secondary (MEDIUM confidence)
- [CITED: developer.apple.com/documentation/cloudkit/ckdatabase] — CKDatabase API, async save
- [CITED: superwall.com/blog/syncing-data-with-cloudkit-in-your-ios-app-using-cksyncengine-and-swift/] — CloudKit async/await save example
- [VERIFIED: Apple Developer Forums thread/731334] — SwiftData `.automatic` only writes to private DB; public requires direct CKDatabase
- [CITED: avanderlee.com/swiftui/deeplink-url-handling/] — SwiftUI onOpenURL, URL scheme setup

### Tertiary (LOW confidence)
- None — no LOW confidence claims in this research.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all frameworks are already in use or are standard Apple first-party
- SchemaV2 migration: HIGH — lightweight migration for `Bool = false` default and new model is well-documented across multiple sources
- CloudKit public database: MEDIUM — confirmed limitation (private-only via SwiftData), confirmed workaround (direct CKDatabase), but exact error behavior and retry semantics are ASSUMED
- Architecture patterns: HIGH — directly mirrors existing GoalViewModel / SchemaV1 patterns in the codebase
- Deep linking: HIGH — standard iOS capability with official documentation

**Research date:** 2026-04-13
**Valid until:** 2026-05-13 (stable Apple framework; 30 days)
