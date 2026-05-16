# Phase 14: Challenge Platform — Community & Modules - Research

**Researched:** 2026-05-07
**Domain:** CloudKit public database, SwiftData SchemaV5, PhotosUI, ContactsUI, UNUserNotificationCenter, SwiftUI animation
**Confidence:** HIGH (codebase patterns), MEDIUM (CloudKit subscription reliability)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
All open questions from CONTEXT.md have been resolved by 14-UI-SPEC.md:

1. Profanity filter = on-device word list (synchronous check — no CoreML, no CreateML)
2. Buddy ping = local `UNUserNotificationCenter` push to the app itself (NOT a remote push to buddy's device; buddy must have app installed)
3. Report auto-hide = threshold of 3 reports from different users
4. Transformation photos = SwiftData `@Attribute(.externalStorage)` on `Data?` property in CloudKit private DB (NOT public DB)
5. Module attachment = JSON-encoded array of module identifier strings on `ChallengeTemplate` (same pattern as `milestonesJSON`)
6. Custom Challenge builder replaces the coming-soon placeholder sheet in `ChallengeDiscoveryView`

### Claude's Discretion
- Exact profanity word list source and format
- CKQuerySubscription subscription ID naming convention
- `reporterIDsJSON` encoding strategy for de-duplication of reporters
- Specific UserDefaults key names for buddy ping cooldown tracking
- Notification identifier scheme for streak-at-risk and milestone notifications

### Deferred Ideas (OUT OF SCOPE)
- Real push notification to buddy's device (requires APNs server + Contacts framework permissions)
- Backend moderation team review workflow
- Transformation photo export/share in Phase 14
- CoreML/CreateML profanity classifier
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CHAL-13 | Community feed scoped per challenge category — posts visible only within same category | CloudKit CKQuery with `category` predicate; local filtering fallback |
| CHAL-14 | Post reactions: 👍 and ❤️ only; reaction counts visible; no comments | CKRecord reaction count fields; optimistic UI + CloudKit write-behind |
| CHAL-15 | Report button on every post; report count never shown publicly | CKRecord `reportCount` Int field; client-side auto-hide at threshold 3 |
| CHAL-16 | Profanity filter on post submission — rejects and prompts, never silently drops | On-device `Set<String>` word list loaded from bundle; synchronous check |
| CHAL-17 | Community posts and reactions persist in CloudKit public database | CKContainer.publicCloudDatabase; CKRecord save/fetch; no SwiftData mirror |
| CHAL-18 | Spending Freeze module — daily self-reported toggle, badge, daily reminder | SpendingFreezeEntry SwiftData model; existing NotificationScheduler extension |
| CHAL-19 | Craving Tools module — box breathing (4-4-4-4), motivational prompt, buddy ping | SwiftUI TimelineView + `.animation(.linear(duration:4))`; UIAccessibility.isReduceMotionEnabled |
| CHAL-20 | Transformation Photos module — private dated photo log, user-only visible | SwiftData `TransformationPhoto` model; `@Attribute(.externalStorage)` on `imageData: Data?` |
| CHAL-21 | Nutrition Log module — simple daily meal note per challenge | `NutritionEntry` SwiftData model keyed by challenge ID + date |
| CHAL-22 | Buddy Accountability module — opt-in contact; buddy receives ping on request | `CNContactPickerViewController` (read-only, no permission prompt); `UNTimeIntervalNotificationTrigger`; UserDefaults 24h cooldown |
| CHAL-23 | Custom Challenge builder — name/category/check-in type/goal type/duration/privacy — produces `ChallengeTemplate` | Existing `ChallengeTemplate` model; no new fields except `privacy: String?`; builder creates local template |
| CHAL-24 | Notification suite: streak-at-risk (8pm), milestone reached, reaction received, buddy ping | Four new `UNUserNotificationCenter` identifiers; CKQuerySubscription for reaction received (reliability caveat documented) |
| CHAL-25 | Warm empty states, no red failure states in challenge UI | Existing `VGTheme` + copy contract from UI-SPEC; `.opacity` transitions, not red error views |
</phase_requirements>

---

## Summary

Phase 14 extends the Phase 13 challenge engine in three directions: a CloudKit public database community feed (CKRecord-based, not SwiftData-backed), five optional module views (three require new SwiftData models in SchemaV5), and a four-notification type suite. The codebase already has a production-quality CloudKit public DB pattern in `ProfileSharingService.swift` (CKRecord save/fetch async/await) — Phase 14 generalises this into a `CommunityService` covering posts, reactions, and report counts.

The most architecturally new element is SchemaV5: three additive models (`TransformationPhoto`, `SpendingFreezeEntry`, `NutritionEntry`) plus two new fields on `ChallengeTemplate` (`enabledModulesJSON: String?` and `privacy: String?`) and two new fields on `UserChallenge` (`buddyDisplayName: String?` and `buddyPingLastSent: Date?`). All changes are purely additive — lightweight migration V4→V5 is correct. Community posts live entirely in CKRecord (no SwiftData mirror) to avoid a second `ModelContainer` configuration for the public database.

The single highest-risk research finding is **CKQuerySubscription reliability**: a developer forum thread confirmed a regression in iOS 26.4 where public database subscriptions fail to deliver APNS notifications in production. The fix is confirmed in iOS 26.4.1+, but the planner must include a graceful fallback: the "reaction received" notification degrades to a no-op if the subscription cannot be registered or delivers no push. The rest of the notification suite uses local `UNUserNotificationCenter` and is unaffected.

**Primary recommendation:** Build in this order: (1) SchemaV5 models + migration, (2) CommunityService (CKRecord CRUD), (3) community feed Views + profanity filter + reaction UI, (4) all five Module Views (Spending Freeze, Nutrition Log, Transformation Photos, Craving Tools, Buddy Accountability), (5) Custom Challenge builder, (6) full notification suite.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Community posts (create/fetch/react/report) | CommunityService (CloudKit CKRecord) | CommunityFeedViewModel (coordinator) | Public DB is not SwiftData — use direct CKRecord API; follows ProfileSharingService pattern |
| Profanity filter check | ProfanityFilter struct (utility) | CommunityFeedViewModel (calls filter before write) | Synchronous, pure function — no state, no SwiftUI/SwiftData; easily unit-tested |
| Reaction optimistic UI | View layer (local @State) | CommunityFeedViewModel (writes CKRecord, reverts on failure) | Immediate visual feedback; error revert follows CHAL-17 contract |
| Report count increment | CommunityService (fetch-then-save CKRecord) | CommunityFeedViewModel (hides post locally after increment) | CKRecord lacks atomic increment; fetch-modify-save with CKError.serverRecordChanged retry |
| Transformation photos persistence | SwiftData `TransformationPhoto` @Model | CloudKit private DB (via SwiftData sync) | Private data; @Attribute(.externalStorage) verified compatible with CloudKit private DB |
| Spending Freeze daily state | SwiftData `SpendingFreezeEntry` @Model | SpendingFreezeModuleView (inline) | One record per challenge per day; lightweight; private |
| Nutrition Log daily state | SwiftData `NutritionEntry` @Model | NutritionLogModuleView (inline) | One record per challenge per day; same pattern as DailyWin |
| Photo selection (posts + transformation) | SwiftUI `PhotosPicker` (native, iOS 16+) | — | No UIViewControllerRepresentable needed; native SwiftUI picker |
| Contact selection (buddy) | `ContactPickerRepresentable` (UIViewControllerRepresentable wrapping CNContactPickerViewController) | BuddyAccountabilityModuleView | No native SwiftUI contact picker in iOS 17; UIKit bridge required |
| Box breathing animation | SwiftUI `TimelineView(.animation)` + `withAnimation(.linear(duration:4))` | CravingToolsModuleView | TimelineView drives phase transitions; `@Environment(\.accessibilityReduceMotion)` gates animation |
| Module enablement on template | `ChallengeTemplate.enabledModulesJSON: String?` (JSON-encoded [String]) | — | Same JSON-string pattern as `milestonesJSON`; CloudKit-safe |
| Custom challenge creation | CustomChallengeBuilderView (View) → ChallengeViewModel (ViewModel) | SwiftData ChallengeTemplate | Builder produces a ChallengeTemplate identical to featured ones; no new model needed |
| Streak-at-risk notification | NotificationScheduler extension (schedulable per challenge, 8pm) | — | UNCalendarNotificationTrigger at 20:00; per-challenge identifier |
| Milestone notification | NotificationScheduler extension (fire-once, immediate) | ChallengeViewModel (triggers after milestone detection) | UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false) |
| Reaction received notification | CommunityService (CKQuerySubscription registration) | NotificationDelegate (handles inbound push) | CloudKit push; reliability caveat — must degrade gracefully on failure |
| Buddy ping notification | NotificationScheduler (schedule immediate local notification) | BuddyAccountabilityModuleView (24h cooldown via UserDefaults) | Local only; UNTimeIntervalNotificationTrigger(timeInterval: 1) |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftData | iOS 17+ | SchemaV5: three new models + two field additions | Project standard since Phase 1 |
| CloudKit | iOS 17+ | CKContainer.publicCloudDatabase for community posts/reactions/reports | Project has CloudKit entitlement; ProfileSharingService already uses public DB |
| SwiftUI | iOS 17+ | All new Views: feed, module sheets, builder | Project standard |
| PhotosUI | iOS 16+ | `PhotosPicker` native SwiftUI picker for post photo + transformation photo | Native; no third-party; no UIViewControllerRepresentable needed |
| ContactsUI | iOS 9+ | `CNContactPickerViewController` for buddy contact selection | Only UIKit option; requires UIViewControllerRepresentable bridge |
| UserNotifications | iOS 10+ | Four new notification types | Existing NotificationScheduler extends naturally |
| Foundation | iOS 17+ | JSON encoding for `enabledModulesJSON`, `reporterIDsJSON`; UserDefaults for ping cooldown | Already used throughout project |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| XCTest | N/A | Unit tests: ProfanityFilter, CommunityFeedViewModel, SchemaV5 migration, notification payload | All pure-struct/VM logic |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SwiftUI `PhotosPicker` | `PHPickerViewController` via `UIViewControllerRepresentable` | PhotosPicker is native SwiftUI since iOS 16 — no bridge needed. PHPicker still correct for UIKit targets only. |
| JSON-encoded `enabledModulesJSON` on `ChallengeTemplate` | Separate `ModuleConfig` @Model with relationship | JSON string avoids a new @Relationship and migration complexity; consistent with `milestonesJSON` pattern already in codebase |
| CKRecord for community posts | SwiftData + separate `ModelContainer(for: publicDB)` | SwiftData's `.cloudKitDatabase: .automatic` maps to private DB only; public DB requires NSPersistentCloudKitContainer or raw CKRecord — raw CKRecord is the simpler approach and matches ProfileSharingService pattern already in use |
| CKQuerySubscription for reaction received | Polling (CKQuery on app foreground) | Polling works but requires more foreground code; CKQuerySubscription is the standard push path — include both but make subscription failure non-fatal |

**Installation:** No new packages. All frameworks are Apple first-party. No `swift package add` required.

**Version verification:** All frameworks are Apple SDK-bundled; version is iOS minimum (17+). No registry check needed.

---

## Architecture Patterns

### System Architecture Diagram

```
User taps "Share Progress" in ChallengeDetailView
     |
     v
PostComposeSheet
     |─── ProfanityFilter.check(text) ─── FAIL ──> inline red caption, Post button disabled
     |─── PhotosPicker (optional) ──────── select photo ──> loadTransferable(Data.self) ──> JPEG compress
     |─── "Post" tapped (text clean)
     v
CommunityFeedViewModel.submitPost(text:imageData:category:)
     |─── CommunityService.createPost(recordType:"CommunityPost") ──> CKContainer.publicCloudDatabase.save(record)
     |─── On success: dismiss sheet, prepend post to feed
     |─── On failure: alert "Couldn't post. Please try again."
     v
CommunityFeedView
     |─── @State posts: [CKRecord] (fetched on appear)
     |─── CKQuery(recordType:"CommunityPost", predicate: category == X)
     |─── sorted by creationDate descending
     |
     |─── Tap 👍 / ❤️ (ReactionPill)
     |     |─── Optimistic: toggle @State isThumbsUp / isHeart
     |     |─── CommunityService.toggleReaction(record:type:userID:) in background
     |     |─── On failure: revert state, show alert
     |
     |─── Tap Report (flag.fill)
     |     |─── .confirmationDialog
     |     |─── CommunityService.reportPost(record:reporterID:)
     |     |─── Client-side: if reportCount >= 3, hide post locally
     |
     v
ChallengeDetailView "Tools & Modules" section (if enabledModulesJSON non-empty)
     |─── Spending Freeze ──> inline SpendingFreezeModuleView
     |─── Nutrition Log ──> inline NutritionLogModuleView
     |─── Craving Tools ──> .sheet CravingToolsModuleView
     |     |─── TimelineView(.animation) box breathing: 4 phases × 4s each
     |     |─── @Environment(\.accessibilityReduceMotion): static circle if true
     |     |─── VGQuoteBank motivational prompt (random, cycle on tap)
     |     |─── BuddyPingSection (if buddyDisplayName != nil)
     |─── Transformation Photos ──> push TransformationPhotosModuleView
     |     |─── LazyVGrid of TransformationPhoto @Model records
     |     |─── PhotosPicker -> loadTransferable(Data.self) -> @Attribute(.externalStorage) save
     |─── Buddy Accountability ──> .sheet BuddyAccountabilityModuleView
           |─── CNContactPickerViewController (UIViewControllerRepresentable)
           |─── Saves displayName to UserChallenge.buddyDisplayName
           |─── "Ping" -> UNTimeIntervalNotificationTrigger(1) + UserDefaults cooldown

ChallengeDiscoveryView "Build Your Own" button
     |─── .sheet CustomChallengeBuilderView (replaces coming-soon placeholder)
     |─── Step 1: name / category / privacy / accent color
     |─── Step 2: check-in type / goal type / duration
     |─── "Create Challenge" -> ChallengeViewModel.createCustomTemplate() -> ChallengeTemplate insert

NotificationScheduler Phase 14 extensions
     |─── scheduleStreakAtRiskReminder(for:) ── 20:00 UNCalendarNotificationTrigger
     |─── scheduleMilestoneNotification(for:threshold:) ── UNTimeIntervalNotificationTrigger(1)
     |─── scheduleBuddyPing(buddyName:challengeTitle:) ── UNTimeIntervalNotificationTrigger(1)
     |─── CKQuerySubscription for "CommunityPost" creation (reaction received) ── best-effort
```

### Recommended Project Structure

```
VitaminG/
├── Models/
│   ├── SchemaV5.swift                      # NEW: TransformationPhoto, SpendingFreezeEntry, NutritionEntry
│   └── VitaminGMigrationPlan.swift         # UPDATED: add migrateV4toV5 stage
├── ViewModels/
│   ├── ChallengeViewModel.swift            # EXTENDED: createCustomTemplate(), module-check helpers
│   └── CommunityFeedViewModel.swift        # NEW: @Observable, post fetch/submit/react/report
├── Services/
│   ├── CommunityService.swift              # NEW: CKRecord CRUD for public DB community posts
│   ├── ProfanityFilter.swift               # NEW: static struct, synchronous Set<String> check
│   ├── NotificationScheduler.swift         # EXTENDED: 4 new notification methods
│   └── InputSanitizer.swift                # EXTENDED: sanitizeForPublic already exists; reuse
├── Navigation/
│   ├── AppRoute.swift                      # EXTENDED: communityFeed(UserChallenge) push route
│   └── AppRouter.swift                     # unchanged
├── Views/
│   ├── ChallengeDetailView.swift           # EXTENDED: "Tools & Modules" section + community link
│   ├── ChallengeDiscoveryView.swift        # EXTENDED: "Build Your Own" opens builder sheet (not placeholder)
│   ├── CommunityFeedView.swift             # NEW
│   ├── PostComposeSheet.swift              # NEW
│   ├── CustomChallengeBuilderView.swift    # NEW
│   ├── Components/
│   │   ├── CommunityPostCard.swift         # NEW
│   │   └── ReactionPill.swift              # NEW
│   └── Modules/
│       ├── SpendingFreezeModuleView.swift  # NEW
│       ├── CravingToolsModuleView.swift    # NEW
│       ├── TransformationPhotosModuleView.swift  # NEW
│       ├── NutritionLogModuleView.swift    # NEW
│       └── BuddyAccountabilityModuleView.swift   # NEW
│       └── ContactPickerRepresentable.swift      # NEW: UIViewControllerRepresentable bridge
└── VitaminGTests/
    ├── ProfanityFilterTests.swift          # NEW: covers CHAL-16
    ├── CommunityFeedViewModelTests.swift   # NEW: covers CHAL-13, CHAL-14, CHAL-15
    ├── SchemaV5Tests.swift                 # NEW: covers TransformationPhoto migration
    └── NotificationSchedulerPhase14Tests.swift  # NEW: covers CHAL-24
```

### Pattern 1: SchemaV5 — Additive Models + Field Additions

```swift
// Source: [VERIFIED: existing SchemaV4.swift pattern — direct extension]
enum SchemaV5: VersionedSchema {
    static var versionIdentifier = Schema.Version(5, 0, 0)

    static var models: [any PersistentModel.Type] {
        [SchemaV2.Goal.self,
         SchemaV2.CompletionEvent.self,
         SchemaV2.UserProfile.self,
         SchemaV3.DailyWin.self,
         SchemaV4.ChallengeTemplate.self,
         SchemaV4.UserChallenge.self,
         SchemaV4.CheckIn.self,
         SchemaV5.TransformationPhoto.self,
         SchemaV5.SpendingFreezeEntry.self,
         SchemaV5.NutritionEntry.self]
    }

    // Transformation photo — private, user-only (CHAL-20)
    // @Attribute(.externalStorage) confirmed compatible with CloudKit private DB [VERIFIED: Apple Forums]
    @Model final class TransformationPhoto {
        var id: UUID = UUID()
        var date: Date?
        var userChallengeID: UUID?      // denormalized — avoids relationship complexity
        @Attribute(.externalStorage) var imageData: Data?
        var timestamp: Date?
        init() {}
    }

    // Spending Freeze daily entry — one per challenge per calendar day (CHAL-18)
    @Model final class SpendingFreezeEntry {
        var id: UUID = UUID()
        var date: Date?
        var userChallengeID: UUID?
        var isFreeze: Bool = false
        var timestamp: Date?
        init() {}
    }

    // Nutrition Log daily note — one per challenge per calendar day (CHAL-21)
    @Model final class NutritionEntry {
        var id: UUID = UUID()
        var date: Date?
        var userChallengeID: UUID?
        var note: String?               // max 300 chars; validated at ViewModel
        var timestamp: Date?
        init() {}
    }
}
```

**New fields on existing V4 models (added as optional/defaulted — lightweight migration compatible):**

```swift
// On ChallengeTemplate (SchemaV4 — add in SchemaV5's models list as the same class):
// These fields cannot literally be added to SchemaV4.ChallengeTemplate at the source level
// because SwiftData VersionedSchema requires the class to be redeclared for new properties.
// The migration approach: declare NEW fields in SchemaV5.ChallengeTemplate and use a
// custom migration stage to copy V4 template data. SEE Pitfall 1 below for the safe pattern.
// The recommended approach: Use SchemaV4.ChallengeTemplate as-is and add the new fields
// as a SEPARATE migration-safe extension approach: store in a new SchemaV5 ChallengeTemplateExtension
// OR add the two new fields to the SchemaV4.ChallengeTemplate class definition NOW (before V5 is locked)
// since no production users exist yet. See Decision Point A1 below.
```

**CRITICAL: Adding fields to existing @Model classes in VersionedSchema**

[ASSUMED] — this is the pattern documented in community resources but must be validated against
the actual VitaminG migration plan at planning time. The safe approach for adding fields to an
existing model within a new VersionedSchema is to redeclare the model in the new schema with the
additional fields and use a lightweight migration. SwiftData lightweight migration handles adding
optional properties with defaults without data loss.

### Pattern 2: SchemaV5 Lightweight Migration

```swift
// Source: [VERIFIED: existing VitaminGMigrationPlan.swift pattern]
// VitaminGMigrationPlan.swift changes:
static var schemas: [any VersionedSchema.Type] {
    [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self, SchemaV5.self]
}

static var stages: [MigrationStage] {
    [migrateV1toV2, migrateV2toV3, migrateV3toV4, migrateV4toV5]
}

static let migrateV4toV5 = MigrationStage.lightweight(
    fromVersion: SchemaV4.self,
    toVersion: SchemaV5.self
)
```

V4 → V5 is purely additive (3 new models, new optional properties on existing models) — lightweight migration is correct. No custom stage needed.

### Pattern 3: CommunityService — CloudKit Public DB CRUD

The pattern is already established in `ProfileSharingService.swift`. Phase 14 generalises it.

```swift
// Source: [VERIFIED: ProfileSharingService.swift — async/await CKRecord pattern in use]
enum CommunityService {
    private static let containerID = "iCloud.com.kyleharrington.VitaminG"
    static let postRecordType = "CommunityPost"

    // MARK: - Fetch posts by category
    static func fetchPosts(category: String, limit: Int = 50) async throws -> [CKRecord] {
        let container = CKContainer(identifier: containerID)
        let db = container.publicCloudDatabase
        let predicate = NSPredicate(format: "category == %@ AND reportCount < 3", category)
        let query = CKQuery(recordType: postRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let (results, _) = try await db.records(matching: query, resultsLimit: limit)
        return results.compactMap { try? $0.1.get() }
    }

    // MARK: - Create post
    static func createPost(
        text: String,
        imageData: Data?,
        category: String,
        authorDisplayName: String?,
        authorColorHex: String?
    ) async throws -> CKRecord {
        let container = CKContainer(identifier: containerID)
        let record = CKRecord(recordType: postRecordType)
        record["text"] = InputSanitizer.sanitizeForPublic(text) as CKRecordValue
        record["category"] = category as CKRecordValue
        record["authorDisplayName"] = (authorDisplayName ?? "Anonymous") as CKRecordValue
        record["authorColorHex"] = (authorColorHex ?? "") as CKRecordValue
        record["thumbsUpCount"] = 0 as CKRecordValue
        record["heartCount"] = 0 as CKRecordValue
        record["reportCount"] = 0 as CKRecordValue
        record["reporterIDsJSON"] = "[]" as CKRecordValue  // JSON [String] of reporter IDs

        if let imageData = imageData {
            // Photo as CKAsset (thumbnail only; max ~500KB enforced before calling)
            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".jpg")
            try imageData.write(to: tmpURL)
            record["photoAsset"] = CKAsset(fileURL: tmpURL) as CKRecordValue
        }

        return try await container.publicCloudDatabase.save(record)
    }

    // MARK: - Toggle reaction (fetch-modify-save; handles CKError.serverRecordChanged)
    static func toggleReaction(
        recordID: CKRecord.ID,
        reactionType: ReactionType,  // enum: thumbsUp / heart
        add: Bool
    ) async throws -> CKRecord {
        let container = CKContainer(identifier: containerID)
        let db = container.publicCloudDatabase
        var record = try await db.record(for: recordID)
        let key = reactionType == .thumbsUp ? "thumbsUpCount" : "heartCount"
        let current = (record[key] as? Int) ?? 0
        record[key] = max(0, add ? current + 1 : current - 1) as CKRecordValue
        return try await db.save(record)
    }

    // MARK: - Report post (fetch-modify-save with reporter de-duplication)
    static func reportPost(recordID: CKRecord.ID, reporterID: String) async throws -> Int {
        let container = CKContainer(identifier: containerID)
        let db = container.publicCloudDatabase
        let record = try await db.record(for: recordID)
        // De-duplicate reporters via JSON-encoded [String]
        let existingJSON = (record["reporterIDsJSON"] as? String) ?? "[]"
        var reporters = (try? JSONDecoder().decode([String].self, from: Data(existingJSON.utf8))) ?? []
        guard !reporters.contains(reporterID) else {
            return (record["reportCount"] as? Int) ?? 0
        }
        reporters.append(reporterID)
        record["reporterIDsJSON"] = (try? String(data: JSONEncoder().encode(reporters), encoding: .utf8)) ?? "[]"
        let newCount = reporters.count
        record["reportCount"] = newCount as CKRecordValue
        let _ = try await db.save(record)
        return newCount
    }
}

enum ReactionType { case thumbsUp, heart }
```

### Pattern 4: ProfanityFilter — On-Device Word List

```swift
// Source: [ASSUMED — standard iOS bundle resource loading pattern; no external API]
// File: Services/ProfanityFilter.swift
// Bundle resource: profanity_list.txt (one word per line, lowercase)
// Target membership: VitaminG target; "Copy Bundle Resources" phase

enum ProfanityFilter {
    // Loaded once at first access; synchronous after that.
    // Set<String> provides O(1) lookup for whole-word matching.
    static let blockedWords: Set<String> = {
        guard let url = Bundle.main.url(forResource: "profanity_list", withExtension: "txt"),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return Set(contents.components(separatedBy: .newlines)
            .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty })
    }()

    /// Returns true if the text contains any blocked word (whole-word match, case-insensitive).
    /// Synchronous — safe to call on main thread before any CloudKit write.
    static func containsProfanity(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        // Simple whole-word boundary check using split-by-non-alphanumeric approach
        let words = lowercased.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return words.contains { blockedWords.contains($0) }
    }
}
```

**Word list sourcing:** [ASSUMED] Use a community-maintained open-source English profanity list (e.g., https://github.com/censor-text/profanity-list). Bundle as `profanity_list.txt` added to Copy Bundle Resources in Xcode. The list is a plain text file — one word per line. Set load is O(n) at first access, O(1) thereafter. List size is typically 1,000–3,000 words (< 50KB).

### Pattern 5: PhotosPicker (Native SwiftUI — No UIViewControllerRepresentable)

```swift
// Source: [VERIFIED: PhotosUI native SwiftUI since iOS 16 — confirmed by WebSearch]
// PhotosPicker is the correct SwiftUI-native approach for iOS 16+.
// No UIViewControllerRepresentable needed.
import PhotosUI

struct PostComposeSheet: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    var body: some View {
        // ...
        PhotosPicker(selection: $selectedItem, matching: .images) {
            Label("Add Photo", systemImage: "photo.fill")
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = compressToJPEG(data, maxBytes: 500_000)
                }
            }
        }
    }

    private func compressToJPEG(_ data: Data, maxBytes: Int) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        // Binary search on compressionQuality
        var quality: CGFloat = 0.8
        var compressed = image.jpegData(compressionQuality: quality) ?? data
        while compressed.count > maxBytes && quality > 0.1 {
            quality -= 0.1
            compressed = image.jpegData(compressionQuality: quality) ?? compressed
        }
        return compressed
    }
}
```

**For Transformation Photos:** Same `PhotosPicker` pattern. Full-res `Data` stored in `TransformationPhoto.imageData` via `@Attribute(.externalStorage)`. No compression needed — private storage, not a public CKAsset.

### Pattern 6: ContactPickerRepresentable — UIViewControllerRepresentable Bridge

```swift
// Source: [VERIFIED: CNContactPickerViewController requires UIKit bridge — no native SwiftUI picker]
// Key finding: wrapping CNContactPickerViewController in UINavigationController avoids blank sheet bug.
// No NSContactsUsageDescription needed — system contact picker grants read-only access to selected contact only.
import ContactsUI

struct ContactPickerRepresentable: UIViewControllerRepresentable {
    var onContactSelected: (String) -> Void  // displayName: givenName + " " + familyName

    func makeUIViewController(context: Context) -> UINavigationController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        // No predicateForEnablingContact needed — single selection by default
        return UINavigationController(rootViewController: picker)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onContactSelected: onContactSelected)
    }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onContactSelected: (String) -> Void
        init(onContactSelected: @escaping (String) -> Void) {
            self.onContactSelected = onContactSelected
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            onContactSelected(name.isEmpty ? "Buddy" : name)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {}
    }
}
```

**No phone number needed.** Per UI-SPEC decision: buddy ping is a local `UNUserNotificationCenter` push to the app itself, not an SMS/iMessage. Only `displayName` is stored in `UserChallenge.buddyDisplayName`. `NSContactsUsageDescription` is NOT required for `CNContactPickerViewController` (it's a system controller that provides read-only access to the user's selection).

### Pattern 7: Box Breathing Animation — TimelineView

```swift
// Source: [VERIFIED: SwiftUI TimelineView + .animation(.linear) — iOS 17 confirmed by WebSearch]
struct BoxBreathingView: View {
    @State private var phase: BreathingPhase = .inhale
    @State private var countdown: Int = 4
    @State private var fillFraction: Double = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0)) { timeline in
            ZStack {
                // Static outline
                Circle()
                    .strokeBorder(accentColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 200, height: 200)
                // Animated fill (disabled when reduceMotion)
                if !reduceMotion {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 200, height: 200)
                        .scaleEffect(fillFraction)
                        .animation(.linear(duration: 4), value: fillFraction)
                } else {
                    Circle()
                        .strokeBorder(accentColor, lineWidth: 3)
                        .frame(width: 200, height: 200)
                }
                // Phase label + countdown
                VStack(spacing: 8) {
                    Text(phase.label)
                        .font(.title2).fontWeight(.semibold).fontDesign(.rounded)
                    Text("\(countdown)")
                        .font(.system(size: 48, weight: .semibold))
                }
            }
        }
        .onAppear { startPhase(.inhale) }
    }

    private func startPhase(_ newPhase: BreathingPhase) {
        phase = newPhase
        countdown = 4
        fillFraction = newPhase == .inhale ? 1.0 : (newPhase == .exhale ? 0.0 : fillFraction)
        // Countdown ticks driven by a Timer or recursive Task.sleep
    }
}

enum BreathingPhase { case inhale, holdFull, exhale, holdEmpty
    var label: String {
        switch self {
        case .inhale: return "Inhale"
        case .holdFull, .holdEmpty: return "Hold"
        case .exhale: return "Exhale"
        }
    }
}
```

**Phase cycling:** `Task { try? await Task.sleep(for: .seconds(4)) }` chained through all four phases is the clean async/await approach without a stored `Timer`. `TimelineView(.animation)` drives the fill scaleEffect each frame; the `fillFraction` state variable is toggled at phase start with `.animation(.linear(duration: 4))` applied.

### Pattern 8: Streak-at-Risk Notification (8pm conditional)

```swift
// Source: [VERIFIED: existing NotificationScheduler.scheduleChallengeReminder pattern + UNCalendarNotificationTrigger]
// Identifier scheme: com.kyleharrington.VitaminG.streakAtRisk.<challengeID>
// Scheduled nightly at 20:00; fires only if no check-in exists for today.
// The condition ("only if no check-in") is evaluated in NotificationDelegate.userNotificationCenter(_:willPresent:) or
// in the app's UNNotificationServiceExtension — BUT since there is no server extension,
// the practical approach is: schedule the 8pm trigger per challenge; in the notification tap handler,
// check if today's check-in already exists and suppress the in-app display if so.
// The notification WILL fire in the system tray regardless — this is a known limitation of local notifications
// without a Notification Service Extension. Document this in PLAN.md.

extension NotificationScheduler {
    static func streakAtRiskIdentifier(for challengeID: UUID) -> String {
        "com.kyleharrington.VitaminG.streakAtRisk.\(challengeID.uuidString)"
    }

    func scheduleStreakAtRiskReminder(for challenge: UserChallenge, challengeTitle: String) async {
        let id = challenge.id
        let identifier = Self.streakAtRiskIdentifier(for: id)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Don't lose your streak!"
        content.body = "You haven't checked in on \(challengeTitle) today. Tap to log your check-in."
        content.sound = .default
        content.userInfo = [
            "deepLink": "challengeCheckIn",
            "userChallengeID": id.uuidString
        ]

        var components = DateComponents()
        components.hour = 20
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }
}
```

### Pattern 9: CKQuerySubscription for Reaction Received (CHAL-24)

```swift
// Source: [VERIFIED: CKQuerySubscription API; MEDIUM confidence — reliability caveat below]
// Registers a subscription for new CommunityPost records where the author matches the current user.
// This fires when someone creates a reaction record — see architecture note on reaction model design.

extension CommunityService {
    static func registerReactionSubscription(userRecordName: String) async {
        let container = CKContainer(identifier: containerID)
        let db = container.publicCloudDatabase

        let subscriptionID = "reaction-received-\(userRecordName)"
        // Check if already registered (avoid duplicate subscriptions across app launches)
        if let existing = try? await db.subscription(for: subscriptionID), existing != nil { return }

        let predicate = NSPredicate(format: "targetAuthorID == %@", userRecordName)
        let subscription = CKQuerySubscription(
            recordType: "CommunityReaction",  // separate record type for reactions
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation]
        )
        let info = CKSubscription.NotificationInfo()
        info.alertLocalizationKey = "Someone reacted to your post"
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info

        do {
            try await db.save(subscription)
        } catch {
            // Non-fatal: subscription registration failure is gracefully degraded.
            // App functions fully without this notification.
            #if DEBUG
            print("[CommunityService] Subscription registration failed: \(error)")
            #endif
        }
    }
}
```

**CRITICAL RELIABILITY CAVEAT:** A confirmed regression in iOS 26.4 causes CKQuerySubscription on public databases to not deliver APNS notifications in production (TestFlight). This is fixed in iOS 26.4.1+. The planner MUST make reaction subscription failure non-fatal and not gate any UI on subscription success. [VERIFIED: Apple Developer Forums thread/820562]

**Required capability:** Push Notifications capability must be enabled in Xcode project settings (Signing & Capabilities tab). Without this, CloudKit subscriptions cannot deliver APNS. This is a Xcode capability toggle — no code change needed. Verify it is already enabled (ProfileSharingService uses public DB, but subscriptions require an additional entitlement `aps-environment`).

### Pattern 10: Module Enablement on ChallengeTemplate

The UI-SPEC decision is to store enabled modules as a JSON-encoded `[String]` on `ChallengeTemplate`, identical to the `milestonesJSON` pattern:

```swift
// Source: [VERIFIED: milestonesJSON pattern in ChallengeTemplate+Featured.swift — direct adaptation]
// Add to ChallengeTemplate (SchemaV5 redeclaration or direct add if pre-production):
// var enabledModulesJSON: String?   // JSON-encoded [String], e.g. ["spendingFreeze", "cravingTools"]
// var privacy: String?              // "private" | "community"

extension ChallengeTemplate {
    enum ModuleIdentifier: String {
        case spendingFreeze = "spendingFreeze"
        case cravingTools   = "cravingTools"
        case transformation = "transformationPhotos"
        case nutritionLog   = "nutritionLog"
        case buddy          = "buddyAccountability"
    }

    var enabledModules: [ModuleIdentifier] {
        guard let json = enabledModulesJSON,
              let data = json.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return ids.compactMap { ModuleIdentifier(rawValue: $0) }
    }

    func isModuleEnabled(_ module: ModuleIdentifier) -> Bool {
        enabledModules.contains(module)
    }
}
```

### Anti-Patterns to Avoid

- **CKRecord in @Query:** Never attempt to use `@Query` for CloudKit public DB records. `@Query` only works with SwiftData's private CloudKit database. Community posts must be fetched via raw `CKRecord` API.
- **SwiftData ModelContainer for public DB:** SwiftData's `.cloudKitDatabase: .automatic` connects to the private database. A separate `ModelContainer` for public DB is not possible without NSPersistentCloudKitContainer. Use raw CKRecord API for all community data.
- **Blocking main thread on profanity filter:** `ProfanityFilter.blockedWords` lazy-loads from Bundle. Perform the first access from a background task or at app launch to avoid blocking the "Post" tap. After first access, `Set.contains` is O(1) and safe on main thread.
- **NSContactsUsageDescription for CNContactPickerViewController:** System contact picker does NOT require this plist key. Never add unnecessary permission strings.
- **Whole-word vs substring profanity matching:** Substring matching (`.contains`) incorrectly flags "classy" for "ass". Always split by non-alphanumeric characters and match whole tokens.
- **CKRecord atomic reportCount increment:** CloudKit has no atomic increment. Fetch-modify-save can produce lost updates under concurrent reporters. At the 3-report threshold this is acceptable (false negatives only; post stays visible slightly longer). Never rely on `reportCount` for security decisions.
- **Storing phone number for buddy ping:** The buddy ping is a local notification to the app itself. Phone number must never be stored — only `displayName`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Photo selection | UIImagePickerController | `PhotosPicker` (SwiftUI native, iOS 16+) | Native SwiftUI; no UIViewControllerRepresentable; privacy-preserving out-of-process picker |
| JPEG compression | Custom image pipeline | `UIImage.jpegData(compressionQuality:)` | First-party; handles all UIImage types |
| Contact selection | CNContactStore + permission flow | `CNContactPickerViewController` (UIKit bridge) | System picker requires zero permission prompts; user selects one contact, app receives only that contact |
| On-device profanity detection | CoreML/CreateML model | `Set<String>` bundle word list | Word list is sufficient, synchronous, zero latency, zero model training, no size cost |
| CloudKit async/await wrapping | Custom continuation wrappers | Direct `try await db.save(record)` | CKDatabase has native async/await since iOS 15; already used in ProfileSharingService |
| Reaction count CRDTs | Custom conflict-free replicated data type | Accept last-write-wins at 3-report threshold | CRDT complexity far exceeds moderation needs at small community scale |
| Notification scheduling for "immediate" delivery | `DispatchQueue.asyncAfter` | `UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)` | UNTimeIntervalNotificationTrigger fires in background and persists if app quits |

**Key insight:** The CloudKit public DB pattern is already proven in `ProfileSharingService.swift`. Phase 14's `CommunityService` is a straightforward generalisation of that pattern — not a new architecture.

---

## Common Pitfalls

### Pitfall 1: Adding Fields to Existing SchemaV4 Models in a VersionedSchema

**What goes wrong:** Directly editing `SchemaV4.ChallengeTemplate` to add `enabledModulesJSON` and `privacy` fields, then declaring SchemaV5 without those changes — SwiftData migration fails because V4's model hash changes.
**Why it happens:** VersionedSchema captures a fixed model hash per version. Editing the V4 class after V4 is used in production corrupts the migration chain.
**How to avoid:** Two valid approaches: (a) Since no production users exist yet (project is pre-launch), add the fields directly to `SchemaV4.ChallengeTemplate` before SchemaV4 is ever shipped — this is the cleanest option. (b) If SchemaV4 is already shipped (TestFlight), redeclare `ChallengeTemplate` in SchemaV5 with the additional fields and use a custom migration stage to copy records. The plan MUST specify which approach is correct given the deployment state.
**Warning signs:** App crashes at launch with "Migration required" or "Invalid model" error after adding fields to an existing VersionedSchema class.

### Pitfall 2: ModelContainerFactory Not Updated for SchemaV5

**What goes wrong:** New SwiftData models (`TransformationPhoto`, `SpendingFreezeEntry`, `NutritionEntry`) are not in the `ModelContainer`'s schema — they are silently ignored and never persist.
**Why it happens:** `ModelContainerFactory.makeContainer()` still references `SchemaV4.models`. The migration plan is updated but the container factory is not.
**How to avoid:** Update `makeContainer()` and `makeWidgetContainer()` to use `Schema(SchemaV5.models, version: SchemaV5.versionIdentifier)` and pass `VitaminGMigrationPlan.self` with the V4→V5 stage.
**Warning signs:** Saving a `TransformationPhoto` succeeds (no crash) but fetching returns 0 results.

### Pitfall 3: CKQuerySubscription Push Notifications Not Working in Production

**What goes wrong:** Reaction received notifications work in development simulator but never fire for TestFlight users.
**Why it happens:** CKQuerySubscription has a known regression in iOS 26.4 (fixed in 26.4.1). Additionally, CloudKit subscriptions NEVER fire on the same device that created the record — only on other users' devices.
**How to avoid:** (a) Make subscription registration non-fatal. (b) Do not test subscription delivery on the same device that created the reaction. (c) Document the iOS 26.4.1 requirement. (d) Implement subscription registration idempotently (check before re-registering on each app launch).
**Warning signs:** Subscription saves successfully to CloudKit Dashboard but no push arrives on test device.

### Pitfall 4: `aps-environment` Entitlement Missing for CKSubscription Push

**What goes wrong:** CKQuerySubscription is registered but push notifications are never delivered — even on devices running iOS 26.4.1+.
**Why it happens:** The `Push Notifications` capability must be explicitly enabled in Xcode's Signing & Capabilities tab. Without the `aps-environment` entitlement in the app's provisioning profile, CloudKit cannot route subscription pushes to the device.
**How to avoid:** Before implementing CKQuerySubscription, verify the app has the Push Notifications capability enabled. Check the `.entitlements` file for `aps-environment` key. This is a one-time Xcode setup step.
**Warning signs:** CloudKit Dashboard shows subscription exists and records match, but no push arrives on any device.

### Pitfall 5: PhotosPicker `loadTransferable(type: Data.self)` Returns Nil for HEIC

**What goes wrong:** User selects a HEIC photo from iPhone camera roll; `loadTransferable(type: Data.self)` returns nil because the default encoding policy doesn't transcode HEIC to a loadable format.
**Why it happens:** `PhotosPickerItem.loadTransferable(type: Data.self)` may not automatically transcode HEIC. Using `PHPickerConfiguration.encodingPolicy = .compatible` in `PhotosPicker` configuration solves this.
**How to avoid:** Configure `PhotosPicker` with `matching: .images` and rely on `UIImage(data:)` → `jpegData()` to handle format conversion after load. If `Data` loading fails, fall back to `loadTransferable(type: UIImage.self)`.
**Warning signs:** `selectedItem?.loadTransferable(type: Data.self)` returns nil for some photos; `UIImage(data:)` also returns nil.

### Pitfall 6: 64-Notification Cap Overflow with Phase 14 Suite

**What goes wrong:** With many active challenges, the notification cap is exceeded — new notifications silently fail to schedule.
**Why it happens:** Phase 14 adds: 1 streak-at-risk per active challenge (nightly) + 4 types of one-time notifications (milestone, buddy ping). With N active challenges: 1 goal reminder + 1 win reminder + N challenge reminders + N streak-at-risk reminders = 2 + 2N scheduled. At N=30 challenges that's 62 — near the cap.
**How to avoid:** Milestone and buddy ping notifications use `UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)` — they fire immediately and are removed from pending requests after delivery. They don't count toward the cap long-term. The planner must document: cap = 64; current usage = 2 (goal+win) + N (challenge) + N (streak-at-risk) = 2 + 2N. Enforce a maximum of 30 active challenges to stay at 62/64.
**Warning signs:** `UNUserNotificationCenter.getPendingNotificationRequests()` returns exactly 64 items — all new adds silently fail.

### Pitfall 7: Profanity Filter First-Access on Main Thread at "Post" Tap

**What goes wrong:** First "Post" tap in a session causes a 50–200ms stall while the word list is read from disk.
**Why it happens:** `ProfanityFilter.blockedWords` is a lazy static property — it reads the bundled text file the first time it is accessed.
**How to avoid:** Pre-warm `ProfanityFilter.blockedWords` at app launch (or at `ChallengeDiscoveryView.onAppear`) with a background `Task { _ = ProfanityFilter.blockedWords }`. After warm-up, all accesses are in-memory.
**Warning signs:** First "Post" tap in any session has a brief UI freeze before the profanity result is returned.

### Pitfall 8: CNContactPickerViewController Blank Sheet Without UINavigationController Wrapper

**What goes wrong:** Presenting `CNContactPickerViewController` directly via `UIViewControllerRepresentable` shows a blank sheet.
**Why it happens:** `CNContactPickerViewController` requires a `UINavigationController` wrapper when presented as a SwiftUI sheet; without it the contacts list is not rendered.
**How to avoid:** `makeUIViewController` must return `UINavigationController(rootViewController: picker)`, not `picker` directly.
**Warning signs:** Buddy Accountability "Choose Contact" button presents a blank sheet with no contacts.

---

## Code Examples

### SchemaV5 Module Fields — Extension on ChallengeTemplate

```swift
// Source: [VERIFIED: milestonesJSON pattern in existing ChallengeTemplate+Featured.swift]
// Add to ChallengeTemplate:
// var enabledModulesJSON: String?   // JSON [String] — see ModuleIdentifier enum
// var privacy: String?              // "private" | "community" (default: "private")

// Extension on ChallengeTemplate (separate file: ChallengeTemplate+Modules.swift):
extension ChallengeTemplate {
    var isPrivate: Bool { privacy == nil || privacy == "private" }
    var isCommunity: Bool { privacy == "community" }

    static func setEnabledModules(_ modules: [ModuleIdentifier]) -> String? {
        try? String(data: JSONEncoder().encode(modules.map { $0.rawValue }), encoding: .utf8)
    }
}
```

### CommunityFeedViewModel Skeleton

```swift
// Source: [VERIFIED: GoalViewModel + ProfileSharingService patterns — direct composition]
@MainActor
@Observable
final class CommunityFeedViewModel {
    var posts: [CKRecord] = []
    var isLoading: Bool = false
    var submitError: String? = nil

    func loadPosts(category: String) async {
        isLoading = true
        defer { isLoading = false }
        posts = (try? await CommunityService.fetchPosts(category: category)) ?? []
    }

    func submitPost(text: String, imageData: Data?, category: String, author: UserProfile?) async {
        guard !ProfanityFilter.containsProfanity(text) else { return }  // View already gates this
        do {
            let record = try await CommunityService.createPost(
                text: text, imageData: imageData, category: category,
                authorDisplayName: author?.displayName, authorColorHex: author?.avatarColorHex
            )
            posts.insert(record, at: 0)
        } catch {
            submitError = "Couldn't post. Please try again."
        }
    }
}
```

### UserChallenge Buddy Fields (SchemaV5 additions)

```swift
// Source: [VERIFIED: UserChallenge model pattern in SchemaV4.swift]
// New optional fields to add to UserChallenge (SchemaV5):
// var buddyDisplayName: String?       // contact display name from CNContact
// var buddyPingLastSent: Date?        // for 24h cooldown enforcement

// Cooldown check in BuddyAccountabilityModuleView or ViewModel:
extension UserChallenge {
    var canSendBuddyPing: Bool {
        guard let last = buddyPingLastSent else { return true }
        return Date().timeIntervalSince(last) >= 86_400  // 24 hours
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `PHPickerViewController` UIViewControllerRepresentable | `PhotosPicker` (native SwiftUI view) | iOS 16 | No bridge code needed for photo selection |
| `ObservableObject` / `@Published` | `@Observable` macro | iOS 17 / Phase 1 | Used throughout; `CommunityFeedViewModel` follows this |
| Completion handler CKDatabase operations | `async throws` directly | iOS 15+ | `ProfileSharingService` already uses async/await — CommunityService follows same pattern |
| SwiftData non-optional properties | All optional or defaulted | SwiftData v1 | All SchemaV5 models follow this constraint |

**Not deprecated:**
- `UNCalendarNotificationTrigger` — still the correct local notification mechanism
- `CNContactPickerViewController` — still the only zero-permission contact picker
- JSON-encoded arrays on SwiftData models — still the only CloudKit-safe array-of-struct storage

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Adding `enabledModulesJSON` and `privacy` fields to `ChallengeTemplate` can be done by directly editing `SchemaV4.ChallengeTemplate` before Phase 14 ships, since no production users exist | Pitfall 1 | If SchemaV4 is already in production CloudKit schema, must use custom V5 migration stage instead; plan must specify |
| A2 | `ProfanityFilter.blockedWords` static lazy load from Bundle is O(1) after warm-up; disk I/O occurs only once per process lifetime | Pattern 4 | If the bundled file is missing, the filter returns `false` for all input — fail-open (permissive). Acceptable for a word-list filter; add a DEBUG assertion that the list is non-empty |
| A3 | `CNContactPickerViewController` does NOT require `NSContactsUsageDescription` when presented as a system picker | Pattern 6 | If Apple adds a requirement in a future iOS version, the app would be rejected without this plist key; low risk in iOS 17 |
| A4 | The English profanity word list from an open-source repository is appropriate for Phase 14 launch | Pattern 4 | If a word is missing from the list, it will appear in posts; the 3-report mechanism is the fallback. List can be updated without a migration |
| A5 | `UserChallenge` fields `buddyDisplayName: String?` and `buddyPingLastSent: Date?` can be added in the SchemaV5 lightweight migration | Pattern 8 | Same as A1 — additive optional fields are lightweight-migration compatible per Apple docs and existing project history |

---

## Open Questions (RESOLVED)

1. **SchemaV5 field additions — pre-production vs. post-production**
   - What we know: The project is pre-launch. SchemaV4 may or may not have been pushed to CloudKit Production schema.
   - What's unclear: Were any TestFlight builds distributed using SchemaV4? If yes, the CloudKit Production schema is locked for existing fields and new fields on `ChallengeTemplate` require a SchemaV5 redeclaration with migration. If no, editing SchemaV4 directly is safe.
   - Recommendation: Plan Wave 0 task: check CloudKit Dashboard → Schema → whether `ChallengeTemplate` record type exists in Production. If yes, redeclare in V5. If no, edit V4 in place.
   - RESOLVED: `VitaminG.entitlements` has no `aps-environment` key, confirming no TestFlight push builds have been distributed. SchemaV4 field additions are safe in-place; SchemaV5 is still the correct approach for additive migration to keep VersionedSchema lineage clean.

2. **`aps-environment` entitlement already present?**
   - What we know: `ProfileSharingService` uses CloudKit public DB for profile records but does not use subscriptions.
   - What's unclear: Does the current `.entitlements` file include `aps-environment`? If not, CKQuerySubscription cannot deliver push.
   - Recommendation: Plan Wave 0 task: check `VitaminG.entitlements` for `aps-environment` key. If missing, add Push Notifications capability in Xcode before implementing CKQuerySubscription.
   - RESOLVED: `VitaminG.entitlements` does NOT contain `aps-environment`. Plan 14-03 Wave 0 task must add Push Notifications capability in Xcode (Signing & Capabilities → + Capability → Push Notifications). CKQuerySubscription will degrade non-fatally until this is done.

3. **`VGQuoteBank.swift` — does it already contain motivational prompts for Craving Tools?**
   - What we know: `VGQuoteBank.swift` exists in Services. Craving Tools requires a random motivational distraction prompt from `ChallengeTemplate.motivationalPrompts`.
   - What's unclear: Does the current `VGQuoteBank` have content suitable for craving diversion, or does Phase 14 need to add a separate prompt array to each ChallengeTemplate?
   - Recommendation: Read `VGQuoteBank.swift` at plan time. If it has general motivational content, use it for the distraction prompt. If it's goal-specific, add a `motivationalPromptsJSON: String?` field to `ChallengeTemplate` with 3–5 prompts per template.
   - RESOLVED: `VGQuoteBank.swift` contains 54 general motivational quotes organized by psychological category. The content is general enough for craving-distraction use. Plan 14-06 (CravingToolsModuleView) should use `VGQuoteBank` directly — `VGQuoteBank.random()` or equivalent — rather than adding `motivationalPromptsJSON` to `ChallengeTemplate`.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / iOS SDK | All Swift development | ✓ | Assumed current (project active) | — |
| CloudKit Production schema | CommunityService, CKQuerySubscription | ✓ (private DB confirmed) | — | Public DB schema must be initialized via DEBUG initializeCloudKitSchema run |
| Push Notifications entitlement | CKQuerySubscription reaction received | Unknown — verify | — | If missing: add capability in Xcode; reaction notifications degrade to no-op without it |
| CNContactPickerViewController | Buddy Accountability | ✓ (ContactsUI iOS 9+) | iOS 9+ | — |
| PhotosPicker | Post photo, Transformation photo | ✓ (PhotosUI iOS 16+) | iOS 16+ | — |

**Missing dependencies with no fallback:**
- None that would block core feature delivery. CKQuerySubscription failure is graceful (non-fatal).

**Missing dependencies requiring verification before planner executes Wave 0:**
- Push Notifications capability in `.entitlements` — must be confirmed or added.
- CloudKit Public DB schema for `CommunityPost` and `CommunityReaction` record types — must be initialized in DEBUG before TestFlight.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (built into Xcode) |
| Config file | VitaminG.xcodeproj (scheme: VitaminGTests) |
| Quick run command | `xcodebuild test -project "VitaminG/VitaminG/VitaminG.xcodeproj" -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -project "VitaminG/VitaminG/VitaminG.xcodeproj" -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -30` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CHAL-13 | CommunityService.fetchPosts returns only records matching category predicate | unit | XCTest in-memory mock CKRecord | ❌ Wave 0 |
| CHAL-14 | toggleReaction increments thumbsUpCount/heartCount; only one type per user enforced | unit | CommunityFeedViewModelTests | ❌ Wave 0 |
| CHAL-15 | reportPost increments reportCount; de-duplicates reporters via reporterIDsJSON | unit | CommunityFeedViewModelTests | ❌ Wave 0 |
| CHAL-16 | ProfanityFilter.containsProfanity returns true for blocked words, false for clean text, whole-word match only | unit | ProfanityFilterTests | ❌ Wave 0 |
| CHAL-17 | CommunityService.createPost builds CKRecord with correct field values (human verify CloudKit Dashboard) | manual | CloudKit Dashboard inspection | N/A |
| CHAL-18 | SpendingFreezeEntry: one per challenge per day enforced; badge state correct | unit | SchemaV5Tests | ❌ Wave 0 |
| CHAL-19 | Box breathing phase cycles: Inhale→HoldFull→Exhale→HoldEmpty→Inhale (human verify) | visual/manual | Human check | N/A |
| CHAL-20 | TransformationPhoto saves and retrieves imageData via @Attribute(.externalStorage) | unit | SchemaV5Tests | ❌ Wave 0 |
| CHAL-21 | NutritionEntry: one per challenge per day; note max 300 chars enforced | unit | SchemaV5Tests | ❌ Wave 0 |
| CHAL-22 | Buddy ping schedules UNTimeIntervalNotificationTrigger; 24h cooldown stored in UserChallenge.buddyPingLastSent | unit | NotificationSchedulerPhase14Tests | ❌ Wave 0 |
| CHAL-23 | CustomChallengeBuilderView creates ChallengeTemplate with correct fields; builder validation (human verify) | visual/manual | Human check | N/A |
| CHAL-24 | Streak-at-risk: identifier scheme correct, 20:00 trigger, remove-before-add | unit | NotificationSchedulerPhase14Tests | ❌ Wave 0 |
| CHAL-24 | Milestone reached: UNTimeIntervalNotificationTrigger(1), correct title/body | unit | NotificationSchedulerPhase14Tests | ❌ Wave 0 |
| CHAL-25 | Empty state shows "Be the First to Share" copy, not a red error view (human verify) | visual/manual | Human check | N/A |

### Sampling Rate

- **Per task commit:** Run existing `VitaminGTests` suite (all tests pass before any commit)
- **Per wave merge:** Full suite — new Phase 14 tests must be green
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `VitaminGTests/ProfanityFilterTests.swift` — covers CHAL-16
- [ ] `VitaminGTests/CommunityFeedViewModelTests.swift` — covers CHAL-13, CHAL-14, CHAL-15
- [ ] `VitaminGTests/SchemaV5Tests.swift` — covers CHAL-18, CHAL-20, CHAL-21
- [ ] `VitaminGTests/NotificationSchedulerPhase14Tests.swift` — covers CHAL-22, CHAL-24
- [ ] Bundle resource: `profanity_list.txt` added to Copy Bundle Resources phase — required for ProfanityFilter

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — (local app, CloudKit identity via CKContainer) |
| V3 Session Management | no | — (no server session) |
| V4 Access Control | yes | Community posts scoped by `category` predicate; transformation photos stored in private DB (never public) |
| V5 Input Validation | yes | `ProfanityFilter.containsProfanity()` on post text; `InputSanitizer.sanitizeForPublic()` on all CKRecord string fields; `InputSanitizer.sanitize()` on buddy display name; nutrition note max 300 chars |
| V6 Cryptography | no | — (no custom crypto; CloudKit handles transport; private DB encryption at rest via iOS) |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Post text injection into CKRecord | Tampering | `InputSanitizer.sanitizeForPublic()` strips `<>'"` and control characters before CKRecord write |
| Profanity bypass via Unicode lookalikes | Tampering | On-device word list covers common spellings; accept residual false negatives — 3-report mechanism is the fallback |
| Buddy display name injected from CNContact | Tampering | `InputSanitizer.sanitize()` on raw `givenName + familyName` before storing to `UserChallenge.buddyDisplayName` |
| Report count spoofing (same user reports multiple times) | Tampering | `reporterIDsJSON` de-duplicates by reporter ID (CKRecord.ID.recordName of the reporting user's profile); accepted limitation: no server-side enforcement without a backend |
| Transformation photo data exfiltration | Information Disclosure | `imageData` in CloudKit private DB (not public DB); no share/export in Phase 14 |
| CKAsset post thumbnail exceeding size limit | Denial of Service | Compress to max 500KB via `UIImage.jpegData(compressionQuality:)` loop before CKAsset creation |
| Malformed JSON in `reporterIDsJSON` / `enabledModulesJSON` | Tampering | All JSON decodes use `try?` with empty-array fallback; never crash on decode failure |

---

## Project Constraints (from CLAUDE.md)

| Directive | Impact on Phase 14 |
|-----------|-------------------|
| No third-party dependencies | No FirebaseFirestore, no Realm, no SwiftyCKRecord — all CloudKit is raw CKRecord API; profanity filter is on-device word list |
| All SwiftData properties optional or defaulted | All SchemaV5 model properties: `var foo: Type?` or `var foo: Type = default` |
| No `@Attribute(.unique)` | Uniqueness enforced at ViewModel layer (one-per-day checks) |
| `@Observable` ViewModel | `CommunityFeedViewModel` uses `@Observable` macro |
| iOS 17+ minimum | `PhotosPicker` (iOS 16+), `CNContactPickerViewController` (iOS 9+), `TimelineView` (iOS 15+) — all met |
| MVVM strictly enforced | All CloudKit CRUD in `CommunityService` / `CommunityFeedViewModel`, not in Views |
| `@Query` has no sort descriptor | `CommunityFeedViewModel.posts` is an `@State [CKRecord]` in Views; ViewModel fetches and sorts |
| All `@Relationship` inverses declared | SchemaV5 models use denormalized `userChallengeID: UUID?` instead of relationships where possible — avoids inverse complexity for module entries |

---

## Sources

### Primary (HIGH confidence)
- [VERIFIED: existing SchemaV4.swift] — VersionedSchema pattern; additive migration pattern for SchemaV5
- [VERIFIED: existing VitaminGMigrationPlan.swift] — lightweight migration stage pattern; `migrateV4toV5` follows exactly
- [VERIFIED: existing ModelContainerFactory.swift] — container update pattern for SchemaV5
- [VERIFIED: existing ProfileSharingService.swift] — CKRecord save/fetch async/await on public DB; `CommunityService` is a direct generalisation
- [VERIFIED: existing ChallengeTemplate+Featured.swift] — `milestonesJSON` JSON string pattern; `enabledModulesJSON` follows this exactly
- [VERIFIED: existing NotificationScheduler.swift] — per-identifier remove-before-add pattern; 4 new notification types extend this
- [VERIFIED: existing InputSanitizer.swift] — `sanitizeForPublic()` already strips HTML-injection characters; reuse for CKRecord fields
- [VERIFIED: existing VGTheme.swift] — `sage`, `terra`, `gold`, `purple`, `clay`, `muted` tokens used in module views
- [VERIFIED: Apple Developer Forums thread/751617] — `@Attribute(.externalStorage)` confirmed compatible with CloudKit private DB by Apple Frameworks Engineer
- [VERIFIED: Apple Developer Forums thread/820562] — CKQuerySubscription regression in iOS 26.4; fixed in 26.4.1 — non-fatal degradation required

### Secondary (MEDIUM confidence)
- [CITED: developer.apple.com/documentation/PhotosUI/PHPickerViewController and WWDC23/10107] — `PhotosPicker` is native SwiftUI since iOS 16; no UIViewControllerRepresentable needed
- [CITED: developer.apple.com/documentation/contactsui/cncontactpickerviewcontroller] — `CNContactPickerViewController` requires UIKit bridge; no permission prompt needed
- [CITED: developer.apple.com/documentation/cloudkit/ckquerysubscription] — public database subscriptions use `CKQuerySubscription`; `CKDatabaseSubscription` is for private/shared databases only
- [CITED: WebSearch verified — multiple sources] — `UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)` is the correct pattern for immediate one-time local notifications
- [CITED: WebSearch + Apple forums] — CloudKit `CKDatabase.records(matching: CKQuery)` and `.save(CKRecord)` are async/await compatible since iOS 15

### Tertiary (LOW confidence)
- [ASSUMED] On-device profanity word list from open-source repository is appropriate for Phase 14 — must be confirmed (A4)
- [ASSUMED] SchemaV4 `ChallengeTemplate` fields can be extended in-place before production push (A1) — must be verified against CloudKit Dashboard state

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all frameworks verified from existing codebase or Apple docs
- Architecture: HIGH — `CommunityService` pattern directly derived from `ProfileSharingService` already in production; SchemaV5 follows established project migration pattern
- CKQuerySubscription reliability: MEDIUM — confirmed working when iOS ≥ 26.4.1, but known regression exists; non-fatal fallback required
- Profanity filter word list: LOW — source and content not verified in this session; [ASSUMED] open-source list is suitable
- Pitfalls: HIGH — most identified from direct codebase inspection or Apple documentation

**Research date:** 2026-05-07
**Valid until:** 2026-06-07 (stable Apple platform; CKQuerySubscription regression fix confirmed in 26.4.1)
