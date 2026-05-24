# Phase 22: Public Profile + Follow + Discover — Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 16 new/modified files
**Analogs found:** 16 / 16

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `Models/SchemaV9.swift` | model | CRUD | `Models/SchemaV8.swift` | exact |
| `Models/VitaminGMigrationPlan.swift` (edit) | config | CRUD | `Models/VitaminGMigrationPlan.swift` itself | self-analog |
| `Models/Schema8pV2.swift` (edit typealias) | config | CRUD | `Models/Schema8pV2.swift` itself | self-analog |
| `Models/CommunityHubModels.swift` (edit) | model | transform | `Models/CommunityHubModels.swift` itself | self-analog |
| `Services/ProfileSharingService.swift` (edit) | service | request-response | `Services/UsernameLookupService.swift` | exact |
| `Services/PublicGoalService.swift` (new) | service | CRUD + request-response | `Services/CommunityService.swift` | exact |
| `Services/CommunityService.swift` (read-only reuse) | service | CRUD | self | self-analog |
| `ViewModels/PublicProfileViewModel.swift` (edit) | view-model | request-response | `ViewModels/CommunityHubViewModel.swift` | exact |
| `ViewModels/DiscoverViewModel.swift` (new) | view-model | request-response | `ViewModels/ExploreViewModel.swift` | role-match |
| `Views/PublicProfileView.swift` (redesign) | view | request-response | `Views/PublicProfileView.swift` itself | self-analog |
| `Views/Explore/ExploreView.swift` (edit) | view | request-response | `Views/Explore/ExploreView.swift` itself | self-analog |
| `Views/Explore/Discover/DiscoverOverlayView.swift` (new) | view | request-response | `Views/CommunityTabView.swift` | role-match |
| `Views/Explore/Discover/GoalSearchResultCard.swift` (new) | view/component | request-response | `Views/Components/CommunityPostCard.swift` | role-match |
| `Views/Explore/Discover/PeopleSearchResultCard.swift` (new) | view/component | request-response | `Views/Community/GlimpsesCarouselSection.swift` | role-match |
| `Views/Components/PublicGoalCard.swift` (new) | view/component | request-response | `Views/Components/ProgressRingView.swift` | role-match |
| `VitaminGApp.swift` (edit — launch hooks) | app entry | event-driven | `VitaminGApp.swift` itself | self-analog |
| `ViewModels/GoalViewModel.swift` (edit — check-in hook) | view-model | CRUD | `ViewModels/GoalViewModel.swift` itself | self-analog |
| `Views/ProfileEditSheet.swift` (edit — motto field) | view | request-response | `Views/ProfileEditSheet.swift` itself | self-analog |
| `VitaminGTests/Phase22PublicProfileViewModelTests.swift` (new) | test | — | `VitaminGTests/PublicProfileViewModelTests.swift` | exact |
| `VitaminGTests/Phase22FollowServiceTests.swift` (new) | test | — | `VitaminGTests/Phase21ApplauseDailyGateTests.swift` | role-match |
| `VitaminGTests/Phase22PublicGoalServiceTests.swift` (new) | test | — | `VitaminGTests/Phase21CommunityHubViewModelTests.swift` | role-match |
| `VitaminGTests/Phase22DiscoverViewModelTests.swift` (new) | test | — | `VitaminGTests/ExploreViewModelTests.swift` | role-match |
| `VitaminGTests/Phase22SchemaV9Tests.swift` (new) | test | — | `VitaminGTests/SchemaV6Tests.swift` | role-match |

---

## Pattern Assignments

### `Models/SchemaV9.swift` (model, CRUD)

**Analog:** `Models/SchemaV8.swift`

**Full file pattern** (lines 1–33 of SchemaV8.swift):
```swift
// SchemaV9: adds UserProfile.motto (String?, nil default) and Goal.cloudKitPublicGoalRecordID (String?, nil default)
// — lightweight migration from V8. Phase 22 D-07, D-10.
import SwiftData
import Foundation

enum SchemaV9: VersionedSchema {
    static var versionIdentifier = Schema.Version(9, 0, 0)
    static var models: [any PersistentModel.Type] = [
        SchemaV9.Goal.self,
        SchemaV2.CompletionEvent.self,
        SchemaV9.UserProfile.self,
        SchemaV3.DailyWin.self,
        SchemaV4.ChallengeTemplate.self,
        SchemaV4.UserChallenge.self,
        SchemaV4.CheckIn.self,
        SchemaV5.TransformationPhoto.self,
        SchemaV5.SpendingFreezeEntry.self,
        SchemaV5.NutritionEntry.self,
        SchemaV7.GoalIdea.self,
        SchemaV7.MoodEntry.self
    ]

    @Model final class UserProfile {
        // ... all SchemaV8.UserProfile fields verbatim ...
        var motto: String? = nil   // NEW in V9 (D-07)
    }

    @Model final class Goal {
        // ... all SchemaV6.Goal fields verbatim ...
        var cloudKitPublicGoalRecordID: String? = nil  // NEW in V9 (D-10)
    }
}
```

**Key rule:** V8 lists `SchemaV6.Goal.self` in its `models` array (Goal definition lives in V6). V9 must declare its own inner `Goal` class that adds the new optional field — same pattern as V8 declaring its own `UserProfile`. Both new fields use `= nil` default so they qualify for lightweight migration.

---

### `Models/VitaminGMigrationPlan.swift` (config, edit)

**Analog:** `Models/VitaminGMigrationPlan.swift` lines 23–68

**Edit pattern** — add to both arrays:
```swift
// In schemas array — append SchemaV9.self:
static var schemas: [any VersionedSchema.Type] {
    [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self,
     SchemaV5.self, SchemaV6.self, SchemaV7.self, SchemaV8.self, SchemaV9.self]
}

// In stages array — append migrateV8toV9:
static var stages: [MigrationStage] {
    [migrateV1toV2, migrateV2toV3, migrateV3toV4,
     migrateV4toV5, migrateV5toV6, migrateV6toV7, migrateV7toV8, migrateV8toV9]
}

// New stage constant — copy migrateV7toV8 pattern exactly:
static let migrateV8toV9 = MigrationStage.lightweight(
    fromVersion: SchemaV8.self,
    toVersion: SchemaV9.self
)
```

---

### `Models/Schema8pV2.swift` (config, edit — typealias update)

**Analog:** `Models/Schema8pV2.swift` lines 144–146

**Edit pattern** — update two typealiases:
```swift
// BEFORE (lines 144–146):
typealias Goal = SchemaV6.Goal
typealias CompletionEvent = SchemaV2.CompletionEvent
typealias UserProfile = SchemaV8.UserProfile

// AFTER:
typealias Goal = SchemaV9.Goal
typealias CompletionEvent = SchemaV2.CompletionEvent
typealias UserProfile = SchemaV9.UserProfile
```

---

### `Models/CommunityHubModels.swift` (model, edit — add Phase 22 structs)

**Analog:** `Models/CommunityHubModels.swift` lines 1–52 (existing struct pattern)

**Pattern to copy** (struct declaration style with Identifiable + Sendable):
```swift
// Each struct: Identifiable (id: String = CKRecord.recordID.recordName), Sendable,
// fields directly mirror CKRecord field names and types.
// Example from lines 8–16:
struct GoalGlimpseItem: Identifiable, Sendable {
    let id: String
    let username: String
    let goalTitle: String
    let progressPercent: Int      // Int64 in CK, Int locally
    let authorColorHex: String
    let photoFileURL: URL?
    let dayKey: String
}
```

**New structs to add** (follow the exact same pattern):
```swift
// PublicProfileData — returned by ProfileSharingService.fetchProfile() in Phase 22
struct PublicProfileData: Equatable, Sendable {
    let displayName: String?
    let avatarColorHex: String?
    let username: String?
    let motto: String?
    let streakLength: Int
    let goalCount: Int
    let cheersGivenCount: Int
}

// PublicGoalItem — CKRecord mirror for PublicGoal type
struct PublicGoalItem: Identifiable, Sendable {
    let id: String               // goal.id.uuidString (record name)
    let title: String
    let category: String
    let creatorUsername: String
    let participantCount: Int    // Int64 in CK
    let progressPercent: Int     // Int64 in CK
    let durationDays: Int        // Int64 in CK
    let creationEpoch: Int       // Int64 in CK
}

// DiscoverGoalResult — search result card data
struct DiscoverGoalResult: Identifiable, Sendable {
    let id: String               // CKRecord.recordID.recordName
    let title: String
    let category: String
    let creatorUsername: String
    let participantCount: Int
    let progressPercent: Int
}

// DiscoverPersonResult — search result card data
struct DiscoverPersonResult: Identifiable, Sendable {
    let id: String               // CKRecord.recordID.recordName (appleUserID)
    let username: String
    let avatarColorHex: String
    let goalCount: Int
    let cheersGivenCount: Int
}
```

---

### `Services/ProfileSharingService.swift` (service, edit)

**Analog:** `Services/UsernameLookupService.swift` (lines 1–92) — exact same CloudKit public DB pattern with `CKContainer(identifier: containerID)`, `CKRecord.ID(recordName:)`, fetch-or-create, `unknownItem` catch.

**Imports pattern** (lines 1–2 of ProfileSharingService.swift):
```swift
import CloudKit
// (no other imports needed — same as existing file)
```

**Container pattern** (lines 8–9 of ProfileSharingService.swift):
```swift
// Always use explicit identifier — not CKContainer.default()
// This is the established pattern in ProfileSharingService and UsernameLookupService.
private static let containerID = "iCloud.com.kyleharrington.VitaminG"
```

**Expanded `publishProfile` signature** — additive parameters, never drop old ones:
```swift
static func publishProfile(
    displayName: String?,
    avatarColorHex: String?,
    username: String? = nil,
    existingRecordID: String?,
    streakLength: Int = 0,   // NEW Phase 22 (D-05)
    goalCount: Int = 0,      // NEW Phase 22 (D-05)
    motto: String? = nil     // NEW Phase 22 (D-07)
) async throws -> String {
    // existing fetch-or-create logic unchanged
    // NEW: write new fields ONLY when non-nil/non-default:
    record["streakLength"] = Int64(streakLength) as CKRecordValue
    record["goalCount"] = Int64(goalCount) as CKRecordValue
    if let motto = motto {
        record["motto"] = InputSanitizer.sanitizeForPublic(motto) as CKRecordValue
    }
    // ... existing save ...
}
```

**Expanded `fetchProfile` return type** — mirrors existing pattern but returns struct:
```swift
// BEFORE (lines 58–66 of ProfileSharingService.swift):
static func fetchProfile(recordID: String) async throws -> (displayName: String?, avatarColorHex: String?)

// AFTER — same call site, returns PublicProfileData struct:
static func fetchProfile(recordID: String) async throws -> PublicProfileData {
    // ... same CKContainer / record fetch ...
    let displayName = record["displayName"] as? String
    let avatarColorHex = record["avatarColorHex"] as? String
    let username = record["username"] as? String
    let motto = record["motto"] as? String
    let streakLength = Int((record["streakLength"] as? Int64) ?? 0)
    let goalCount = Int((record["goalCount"] as? Int64) ?? 0)
    return PublicProfileData(displayName: displayName, avatarColorHex: avatarColorHex,
        username: username, motto: motto, streakLength: streakLength,
        goalCount: goalCount, cheersGivenCount: 0)  // cheersGivenCount fetched separately
}
```

**New `fetchFollowState` method** — copy from `UsernameLookupService.isUsernameTaken` (lines 26–32) but using record ID lookup:
```swift
// Source: UsernameLookupService.swift lines 53–70 (writeUsername fetch-or-create with unknownItem catch)
static func fetchFollowState(followerUsername: String, followeeUsername: String) async throws -> Bool {
    let db = CKContainer(identifier: containerID).publicCloudDatabase
    let recordName = "\(followerUsername)_\(followeeUsername)"
    let recordID = CKRecord.ID(recordName: recordName)
    do {
        _ = try await db.record(for: recordID)
        return true
    } catch let e as CKError where e.code == .unknownItem {
        return false
    }
}
```

**New `writeFollow` method** — copy from `UsernameLookupService.writeUsername` pattern (lines 53–70):
```swift
static func writeFollow(followerUsername: String, followeeUsername: String) async throws {
    let db = CKContainer(identifier: containerID).publicCloudDatabase
    let recordName = "\(followerUsername)_\(followeeUsername)"
    let recordID = CKRecord.ID(recordName: recordName)
    do {
        _ = try await db.record(for: recordID)
        return  // Already following — idempotent
    } catch let e as CKError where e.code == .unknownItem {
        let record = CKRecord(recordType: "Follow", recordID: recordID)
        record["followerUsername"] = InputSanitizer.sanitizeForPublic(followerUsername) as CKRecordValue
        record["followeeUsername"] = InputSanitizer.sanitizeForPublic(followeeUsername) as CKRecordValue
        record["createdAt"] = Int64(Date().timeIntervalSince1970) as CKRecordValue
        _ = try await db.save(record)
    }
}
```

---

### `Services/PublicGoalService.swift` (new service, CRUD)

**Analog:** `Services/CommunityService.swift` (entire file — same structure: `enum` with `private static let containerID`, static async methods, InputSanitizer on all writes, `.serverRecordChanged` one-retry pattern)

**Imports + declaration pattern** (lines 1–27 of CommunityService.swift):
```swift
import CloudKit
import Foundation

enum PublicGoalService {
    private static let containerID = "iCloud.com.kyleharrington.VitaminG"
    // IMPORTANT: Use CKContainer(identifier:), NOT CKContainer.default()
    // This matches ProfileSharingService and UsernameLookupService (established in Phase 17).
}
```

**Write record pattern** — copy `CommunityService.writeApplause` (lines 326–340) structure:
```swift
// Source: CommunityService.swift lines 326–340
static func writePublicGoal(goal: Goal) async throws {
    let db = CKContainer(identifier: containerID).publicCloudDatabase
    let recordName = goal.id.uuidString  // D-09: stable identity
    let recordID = CKRecord.ID(recordName: recordName)
    let record = CKRecord(recordType: "PublicGoal", recordID: recordID)
    record["title"] = InputSanitizer.sanitizeForPublic(goal.title ?? "") as CKRecordValue
    record["category"] = InputSanitizer.sanitizeForPublic(goal.category ?? "") as CKRecordValue
    // ... remaining fields ...
    do {
        _ = try await db.save(record)
    } catch let error as CKError where error.code == .serverRecordChanged {
        // One retry — same pattern as CommunityService.writeApplause
        _ = try await db.save(record)
    }
}
```

**Delete record pattern** — copy `ProfileSharingService.unpublishProfile` (lines 71–81):
```swift
// Source: ProfileSharingService.swift lines 71–81
static func deletePublicGoal(recordName: String) async throws {
    let db = CKContainer(identifier: containerID).publicCloudDatabase
    let recordID = CKRecord.ID(recordName: recordName)
    do {
        try await db.deleteRecord(withID: recordID)
    } catch let error as CKError where error.code == .unknownItem {
        // Already deleted — not an error
    }
}
```

**Fetch with NSPredicate pattern** — copy `CommunityService.fetchPosts` (lines 30–38):
```swift
// Source: CommunityService.swift lines 30–38
static func searchGoals(keyword: String) async throws -> [DiscoverGoalResult] {
    let db = CKContainer(identifier: containerID).publicCloudDatabase
    let predicate = NSPredicate(format: "title CONTAINS[cd] %@", keyword)
    let query = CKQuery(recordType: "PublicGoal", predicate: predicate)
    // No sort descriptor needed for search; resultsLimit: 25
    let (results, _) = try await db.records(matching: query, resultsLimit: 25)
    let records = results.compactMap { try? $0.1.get() }
    return records.map { mapRecordToDiscoverGoalResult($0) }
}

static func searchPeople(usernamePrefix: String) async throws -> [DiscoverPersonResult] {
    let db = CKContainer(identifier: containerID).publicCloudDatabase
    let predicate = NSPredicate(format: "username BEGINSWITH[cd] %@", usernamePrefix)
    let query = CKQuery(recordType: "PublicProfile", predicate: predicate)
    let (results, _) = try await db.records(matching: query, resultsLimit: 25)
    let records = results.compactMap { try? $0.1.get() }
    return records.map { mapRecordToDiscoverPersonResult($0) }
}
```

**Atomic increment pattern** — copy `CommunityService.toggleReaction` (lines 73–96):
```swift
// Source: CommunityService.swift lines 73–96 — fetch + mutate + save + one retry
static func incrementParticipantCount(recordName: String) async {
    let db = CKContainer(identifier: containerID).publicCloudDatabase
    let recordID = CKRecord.ID(recordName: recordName)
    do {
        let record = try await db.record(for: recordID)
        let current = (record["participantCount"] as? Int64) ?? 0
        record["participantCount"] = current + 1 as CKRecordValue
        _ = try await db.save(record)
    } catch let error as CKError where error.code == .serverRecordChanged {
        // One retry on conflict — mirror toggleReaction retry pattern
        do {
            let record = try await db.record(for: recordID)
            let current = (record["participantCount"] as? Int64) ?? 0
            record["participantCount"] = current + 1 as CKRecordValue
            _ = try await db.save(record)
        } catch {
            // Silently discard (D-16: count failure must not roll back local goal)
        }
    } catch {
        // Silently discard — fire-and-forget
    }
}
```

**Upsert (backfill/sync) pattern** — copy `CommunityService.writeGlimpse` upsert section (lines 204–235):
```swift
// Source: CommunityService.swift lines 204–235 — query existing, create or update
static func backfillPublicGoals(goals: [Goal]) async {
    for goal in goals where goal.isPublic && goal.cloudKitPublicGoalRecordID == nil {
        do {
            try await writePublicGoal(goal: goal)
            // After successful save, update SwiftData cloudKitPublicGoalRecordID
            // (caller passes ModelContext; or use actor-based update)
        } catch {
            // Silently discard per-goal failures — continue backfill
        }
    }
}
```

---

### `ViewModels/PublicProfileViewModel.swift` (view-model, edit)

**Analog:** `ViewModels/CommunityHubViewModel.swift` (lines 1–282) — exact same `@MainActor @Observable final class` pattern with test override closures, parallel async fetches, and explicit error constants.

**Class declaration pattern** (lines 70–72 of CommunityHubViewModel.swift):
```swift
@MainActor
@Observable
final class PublicProfileViewModel {
```

**Expanded ViewState enum** — replace current `loaded(displayName:avatarColorHex:)` with:
```swift
// Source: current PublicProfileViewModel.swift lines 8–12
// BEFORE:
enum ViewState: Equatable {
    case loading
    case loaded(displayName: String?, avatarColorHex: String?)
    case error(message: String)
}

// AFTER — Phase 22 expansion:
enum ViewState: Equatable {
    case loading
    case loaded(profile: PublicProfileData)
    case error(message: String)
}
```

**Follow state machine** — new enum alongside ViewState:
```swift
enum FollowState: Equatable {
    case idle
    case loading
    case followed
}
var followState: FollowState = .idle
var followError: String? = nil  // auto-clears after 3s
```

**Test override pattern** (lines 94–98 of CommunityHubViewModel.swift):
```swift
// Keep the fetchOverride closure — update its return type to PublicProfileData:
// BEFORE: var fetchOverride: ((String) async throws -> (String?, String?))? = nil
// AFTER:
var fetchOverride: ((String) async throws -> PublicProfileData)? = nil
```

**Cheer gate pattern** (lines 192–199 of CommunityHubViewModel.swift):
```swift
// Source: CommunityHubViewModel.swift lines 192–199
// Wrap ApplauseGate directly — same pattern as CommunityHubViewModel:
func canCheerToday(recipientUsername: String, defaults: UserDefaults = .standard) -> Bool {
    ApplauseGate.canApplaud(recipientUsername: recipientUsername, defaults: defaults)
}

func onCheer(recipientUsername: String, giverUsername: String) {
    guard canCheerToday(recipientUsername: recipientUsername) else { return }
    ApplauseGate.markApplauseGiven(to: recipientUsername)
    Task {
        try? await CommunityService.writeApplause(
            giverUsername: giverUsername,
            recipientUsername: recipientUsername
        )
    }
}
```

---

### `ViewModels/DiscoverViewModel.swift` (new view-model, request-response)

**Analog:** `ViewModels/ExploreViewModel.swift` (lines 1–121) — `@MainActor @Observable final class`, UserDefaults date gates, private async fetch functions. Also draws from `CommunityHubViewModel.swift` for the override closure test seam pattern.

**Class + imports pattern** (lines 1–7 of ExploreViewModel.swift):
```swift
import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class DiscoverViewModel {
```

**Debounced search pattern** (from CONTEXT.md Claude's Discretion):
```swift
// Task.sleep + cancellation — consistent with codebase async/await style (not Combine)
private var searchTask: Task<Void, Never>?

func onSearchTextChanged(_ newText: String) {
    searchTask?.cancel()
    guard !newText.isEmpty else {
        goalResults = []
        peopleResults = []
        return
    }
    searchTask = Task {
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        await performSearch(newText)
    }
}
```

**State properties** — follow ExploreViewModel computed property pattern (lines 32–40):
```swift
var goalResults: [DiscoverGoalResult] = []
var peopleResults: [DiscoverPersonResult] = []
var isSearching: Bool = false
var searchError: String? = nil
var selectedSegment: SearchSegment = .goals  // enum Goals | People

// Joined goal IDs — prevents duplicate Join on retry (Pitfall 5)
private var joinedGoalIDs: Set<String> = []
func isJoined(goalID: String) -> Bool { joinedGoalIDs.contains(goalID) }
```

**Test override closure pattern** (lines 94–98 of CommunityHubViewModel.swift):
```swift
// Nil in production; set in tests to avoid hitting CloudKit:
var searchGoalsOverride: ((String) async throws -> [DiscoverGoalResult])? = nil
var searchPeopleOverride: ((String) async throws -> [DiscoverPersonResult])? = nil
```

**Join action pattern** — copy GoalViewModel.addGoal(input:context:) pattern (lines 208–229 of GoalViewModel.swift):
```swift
// 1. Create local SwiftData Goal FIRST (D-16: never reverse this order)
// 2. Fire-and-forget participant count increment
func joinGoal(_ result: DiscoverGoalResult, tier: GoalTier, context: ModelContext) {
    guard !isJoined(goalID: result.id) else { return }
    joinedGoalIDs.insert(result.id)
    // Create local goal
    let goal = Goal(title: result.title, tier: tier)
    goal.isPublic = false   // D-15: joined copies are private by default
    goal.category = result.category
    goal.creationDate = Date()
    context.insert(goal)
    // Fire-and-forget participant count — failure must not roll back goal (D-16)
    Task {
        await PublicGoalService.incrementParticipantCount(recordName: result.id)
    }
}
```

---

### `Views/PublicProfileView.swift` (view, full redesign)

**Analog:** `Views/PublicProfileView.swift` (lines 1–233) — keep all existing patterns: `NavigationStack` wrapper, `.navigationTitle("Profile")`, `.navigationBarTitleDisplayMode(.inline)`, "Done" toolbar button with `VGTheme.accentTerra`, `@State private var viewModel`, `.onAppear { viewModel.fetchProfile(...) }`, `switch viewModel.state` rendering, block/report alert + MailComposeView.

**Shell pattern to carry forward** (lines 1–65):
```swift
import SwiftUI
import MessageUI

struct PublicProfileView: View {
    let recordID: String
    @State private var viewModel = PublicProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    // Carry forward: showBlockConfirm, showMailCompose, reportMailSubject, reportMailBody
    // Carry forward: @AppStorage("vg_appleUserID")
    // NEW Phase 22: @AppStorage("vg_username") for CheerButton giverUsername

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(VGTheme.background.ignoresSafeArea())  // changed from systemGroupedBackground
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                            .font(.body.weight(.semibold))
                            .foregroundStyle(VGTheme.accentTerra)
                    }
                }
        }
        .onAppear { viewModel.fetchProfile(recordID: recordID) }
        // ... existing .alert and .sheet modifiers carry forward unchanged
    }
```

**Loading state pattern** (lines 71–79 of current PublicProfileView.swift):
```swift
// Copy exactly — ProgressView + label + tint:
case .loading:
    VStack(spacing: 12) {
        ProgressView()
            .tint(VGTheme.accentTerra)
            .accessibilityLabel("Loading profile")
        Text("Loading profile...")
            .font(.body).fontDesign(.rounded)
            .foregroundStyle(.secondary)
    }
```

**Error state pattern** (lines 143–159):
```swift
case .error(let message):
    VStack(spacing: 16) {
        Spacer()
        Image(systemName: "exclamationmark.icloud.fill")
            .font(.title)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        Text(message)
            .font(.body).fontDesign(.rounded)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        Spacer()
    }
```

**Report/Block pattern** — carry forward unchanged from lines 162–191.

**Section eyebrow label pattern** (from ExploreView.swift lines 77–83):
```swift
// Reuse ExploreView's sectionLabel helper — same uppercase + kerning + textMuted style:
private func sectionLabel(_ text: String) -> some View {
    Text(text.uppercased())
        .font(.system(size: 13, weight: .semibold))
        .kerning(0.4)
        .foregroundStyle(VGTheme.textMuted)
        .padding(.horizontal, 16)
}
```

---

### `Views/Explore/ExploreView.swift` (view, edit — add .searchable overlay)

**Analog:** `Views/Explore/ExploreView.swift` (lines 1–84) — extend, do not replace. All 6 existing sections stay intact.

**Current structure to preserve** (lines 1–84 — keep every section):
```swift
// The existing body wraps everything in ScrollView > VStack.
// Phase 22 wraps the ENTIRE body output in a conditional on isSearching.
// .searchable must be placed on the NavigationStack in ContentView.swift (Pitfall 1):

// In ContentView.swift (lines 27–33):
NavigationStack {
    ExploreView()
        .navigationDestination(for: GoalCategory.self) { category in
            CategoryGoalListView(category: category)
        }
}
// BECOMES:
NavigationStack {
    ExploreView()
        .navigationDestination(for: GoalCategory.self) { category in
            CategoryGoalListView(category: category)
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search goals or people…"
        )
}
```

**isSearching pattern** — add to ExploreView body:
```swift
// New state in ExploreView:
@State private var searchText: String = ""
@Environment(\.isSearching) private var isSearching

// Replace the existing single-return body with conditional:
var body: some View {
    if isSearching && searchText.isEmpty {
        // D-02: show TrendingChallengesSection only
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionLabel("TRENDING CHALLENGES")
                ChallengeDiscoveryView()
            }
            .padding(.top, 8).padding(.bottom, 24)
        }
        .background(VGTheme.background.ignoresSafeArea())
    } else if isSearching {
        // D-03: show Discover overlay with segment control
        DiscoverOverlayView(searchText: searchText)
    } else {
        // D-04: show ExploreView normally — existing 6-section ScrollView unchanged
        existingScrollContent
    }
}

// Extract current body content to private computed var (no logic changes):
private var existingScrollContent: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            // ... all 6 existing sections unchanged ...
        }
    }
    .background(VGTheme.background.ignoresSafeArea())
    .navigationTitle("Explore")
    // ... existing toolbar unchanged ...
}
```

---

### `Views/Explore/Discover/DiscoverOverlayView.swift` (new view, request-response)

**Analog:** `Views/CommunityTabView.swift` — same top-level view structure with section headers and a `@State private var viewModel` pattern.

**Picker segment control pattern** (Apple SwiftUI standard, referenced in RESEARCH.md):
```swift
import SwiftUI
import SwiftData

struct DiscoverOverlayView: View {
    let searchText: String
    @State private var viewModel = DiscoverViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // Segment control — .segmented style (D-03)
            Picker("Search type", selection: $viewModel.selectedSegment) {
                Text("Goals").tag(SearchSegment.goals)
                Text("People").tag(SearchSegment.people)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            ScrollView {
                LazyVStack(spacing: 8) {
                    if viewModel.isSearching {
                        ProgressView().tint(VGTheme.accentTerra)
                    } else if viewModel.selectedSegment == .goals {
                        ForEach(viewModel.goalResults) { result in
                            GoalSearchResultCard(result: result, ...)
                        }
                    } else {
                        ForEach(viewModel.peopleResults) { result in
                            PeopleSearchResultCard(result: result, ...)
                        }
                    }
                }
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2),
                           value: viewModel.selectedSegment)
                .padding(.horizontal, 16).padding(.top, 8)
            }
        }
        .background(VGTheme.background.ignoresSafeArea())
        .onChange(of: searchText) { _, newText in
            viewModel.onSearchTextChanged(newText)
        }
    }
}
```

---

### `Views/Explore/Discover/GoalSearchResultCard.swift` (new component, request-response)

**Analog:** `Views/Components/CommunityPostCard.swift` (lines 1–131) — HStack card layout with background surface, rounded corners, padding, action button on trailing edge.

**Card layout pattern** (lines 33–120 of CommunityPostCard.swift):
```swift
import SwiftUI

struct GoalSearchResultCard: View {
    let result: DiscoverGoalResult
    let isJoined: Bool
    let onJoin: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Progress ring (32pt — UI-SPEC §4)
            ZStack {
                Circle()
                    .stroke(VGTheme.accentTerra.opacity(0.15), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: Double(result.progressPercent) / 100.0)
                    .stroke(VGTheme.accentTerra,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 32, height: 32)

            // Text block
            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.system(size: 16).fontDesign(.rounded))
                    .foregroundStyle(VGTheme.textPrimary)
                    .lineLimit(1)
                Text("@\(result.creatorUsername) · \(result.category) · \(result.participantCount) people")
                    .font(.system(size: 13).fontDesign(.rounded))
                    .foregroundStyle(VGTheme.textMuted)
            }

            Spacer()

            // Join button
            Button(isJoined ? "Joined" : "Join", action: onJoin)
                .disabled(isJoined)
                .font(.system(size: 13, weight: .semibold).fontDesign(.rounded))
                .foregroundStyle(isJoined ? VGTheme.accentSage : VGTheme.accentTerra)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(
                    (isJoined ? VGTheme.accentSage : VGTheme.accentTerra).opacity(0.12)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
}
```

---

### `Views/Explore/Discover/PeopleSearchResultCard.swift` (new component, request-response)

**Analog:** `Views/Components/CommunityPostCard.swift` (lines 33–58 — HStack header row pattern with AvatarView + text + action button).

**Key reuse — AvatarView** (lines 36–37 of CommunityPostCard.swift):
```swift
// Use existing AvatarView at size 40 — same as PostCard's 32pt but scaled up:
AvatarView(
    displayName: result.username,
    avatarColorHex: result.avatarColorHex,
    photoData: nil,   // D-06: no photoData on public profiles
    size: 40
)
```

**Card body pattern:**
```swift
struct PeopleSearchResultCard: View {
    let result: DiscoverPersonResult
    let followState: FollowState  // .idle | .loading | .followed
    let onFollow: () -> Void
    let onTap: () -> Void  // opens PublicProfileView sheet

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(displayName: result.username, avatarColorHex: result.avatarColorHex,
                       photoData: nil, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("@\(result.username)")
                    .font(.system(size: 16, weight: .semibold).fontDesign(.rounded))
                    .foregroundStyle(VGTheme.textPrimary)
                Text("\(result.goalCount) goals · \(result.cheersGivenCount) cheers given")
                    .font(.system(size: 13).fontDesign(.rounded))
                    .foregroundStyle(VGTheme.textMuted)
            }

            Spacer()

            // Inline FollowButton (reuse FollowButton component)
            FollowButton(state: followState, onFollow: onFollow)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .onTapGesture(perform: onTap)  // tap row (not button) to open profile
    }
}
```

---

### `Views/Components/PublicGoalCard.swift` (new component, request-response)

**Analog:** `Views/Components/ProgressRingView.swift` (lines 1–76) — `Circle().trim()` pattern, `StrokeStyle(lineCap: .round)`, `.rotationEffect(.degrees(-90))`, reduced motion handling, percentage label at `size * 0.22`.

**Progress ring adaptation** (lines 34–60 of ProgressRingView.swift):
```swift
import SwiftUI

struct PublicGoalCard: View {
    let goal: PublicGoalItem

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            // 44pt ring — no GoalTier dependency (UI-SPEC §1, CONTEXT.md Claude's Discretion)
            ZStack {
                Circle()
                    .stroke(VGTheme.accentTerra.opacity(0.15), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: Double(goal.progressPercent) / 100.0)
                    .stroke(VGTheme.accentTerra,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    // Source: ProgressRingView.swift lines 43–46
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.4),
                        value: goal.progressPercent
                    )
                // Center label — from ProgressRingView lines 54–60
                Text("\(goal.progressPercent)%")
                    .font(.system(size: 44 * 0.22, weight: .semibold, design: .rounded))
                    .foregroundStyle(VGTheme.accentTerra)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.system(size: 16).fontDesign(.rounded))
                    .foregroundStyle(VGTheme.textPrimary)
                    .lineLimit(2)
                Text("\(goal.category) · \(goal.durationDays) days left")
                    .font(.system(size: 13).fontDesign(.rounded))
                    .foregroundStyle(VGTheme.textMuted)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        // Source: ProgressRingView.swift lines 69–72
        .accessibilityLabel("\(goal.progressPercent)% complete. \(goal.title). \(goal.durationDays) days remaining.")
        .accessibilityAddTraits(.isStaticText)
    }
}
```

---

### `VitaminGApp.swift` (edit — launch hooks)

**Analog:** `VitaminGApp.swift` lines 88–103 (existing `.task` modifier pattern)

**Fire-and-forget Task pattern** (lines 181–188 of GoalViewModel.swift):
```swift
// Source: GoalViewModel.swift lines 181–188 — fire-and-forget Task { await ... }
// Add to the existing .task modifier in VitaminGApp.swift body — DO NOT await these:
.task {
    // Existing notification scheduling (lines 89–103) stays first
    let isGranted = await NotificationScheduler.shared.isAuthorized()
    if isGranted { ... }

    // NEW Phase 22 launch hooks (D-08, D-11, D-12) — fire-and-forget:
    Task { await ProfileSharingService.publishProfile(...) }
    Task { await PublicGoalService.backfillPublicGoals(...) }
    Task { await PublicGoalService.syncOwnedPublicGoals(...) }
}
```

---

### `ViewModels/GoalViewModel.swift` (edit — check-in hook)

**Analog:** `ViewModels/GoalViewModel.swift` lines 172–189 (existing fire-and-forget Task in addCheckIn)

**Hook insertion point** — after line 188 (after writeGlimpse Task):
```swift
// Source: GoalViewModel.swift lines 181–188 — existing fire-and-forget pattern to copy:
Task {
    await CommunityService.writeGlimpse(
        username: username,
        goalTitle: goal.title ?? "",
        progressPercent: progressPercent,
        authorColorHex: colorHex
    )
}
// ADD after this block (D-08, D-12):
Task { await ProfileSharingService.publishProfile(...) }
Task { await PublicGoalService.syncOwnedPublicGoals(...) }
```

---

### `Views/ProfileEditSheet.swift` (edit — motto field)

**Analog:** `Views/ProfileEditSheet.swift` lines 58–84 (existing username TextField section pattern)

**TextField + char count section pattern** (lines 58–84):
```swift
// Add a new Section after the username section, following the exact same pattern:
Section {
    VStack(alignment: .leading, spacing: 4) {
        TextField("Your motto or bio", text: $viewModel.draftMotto)
            .font(.body).fontDesign(.rounded)
            .onChange(of: viewModel.draftMotto) { _, newValue in
                // 100-char max (D-07) — same pattern as displayName 50-char limit (line 36–41)
                if newValue.count > ProfileViewModel.maxMottoLength {
                    viewModel.draftMotto = String(newValue.prefix(ProfileViewModel.maxMottoLength))
                }
            }
        HStack {
            Spacer()
            Text("\(viewModel.draftMotto.count)/\(ProfileViewModel.maxMottoLength)")
                .font(.caption).fontDesign(.rounded)
                .foregroundStyle(.secondary)
        }
    }
} header: {
    Text("Motto")
} footer: {
    Text("A short bio shown on your public profile.")
        .font(.caption).fontDesign(.rounded)
}
```

---

### `VitaminGTests/Phase22PublicProfileViewModelTests.swift` (new test)

**Analog:** `VitaminGTests/PublicProfileViewModelTests.swift` (lines 1–59) — exact same test structure to replace/extend.

**Test shell pattern** (lines 1–14 of PublicProfileViewModelTests.swift):
```swift
import XCTest
import CloudKit
@testable import VitaminG

@MainActor
final class Phase22PublicProfileViewModelTests: XCTestCase {

    var sut: PublicProfileViewModel!

    override func setUp() async throws { sut = PublicProfileViewModel() }
    override func tearDown() async throws { sut = nil }
```

**Override closure test pattern** (lines 27–35):
```swift
// Updated to match new return type PublicProfileData (Pitfall 6):
func test_fetchProfile_success_transitionsToLoaded() async throws {
    let mockProfile = PublicProfileData(displayName: "Alice", avatarColorHex: "#FF8C44",
        username: "alice", motto: "Keep going", streakLength: 7, goalCount: 3, cheersGivenCount: 5)
    sut.fetchOverride = { _ in mockProfile }
    sut.fetchProfile(recordID: "abc123")
    try await Task.sleep(nanoseconds: 50_000_000)
    if case .loaded(let profile) = sut.state {
        XCTAssertEqual(profile.displayName, "Alice")
    } else {
        XCTFail("Expected .loaded, got \(sut.state)")
    }
}
```

---

### `VitaminGTests/Phase22FollowServiceTests.swift` (new test)

**Analog:** `VitaminGTests/Phase21ApplauseDailyGateTests.swift` (lines 1–63) — isolated UserDefaults suite, pure-logic tests with no CloudKit calls.

**Test structure pattern** (lines 9–27):
```swift
// Follow tests use deterministic record name logic — no CloudKit needed:
final class Phase22FollowServiceTests: XCTestCase {

    func test_followRecordName_isDeterministic() {
        let name = "\("alice")_\("bob")"
        XCTAssertEqual(name, "alice_bob")
    }

    func test_followRecordName_isOrderSensitive() {
        let name1 = "\("alice")_\("bob")"
        let name2 = "\("bob")_\("alice")"
        XCTAssertNotEqual(name1, name2)
    }
}
```

---

### `VitaminGTests/Phase22DiscoverViewModelTests.swift` (new test)

**Analog:** `VitaminGTests/ExploreViewModelTests.swift` — ViewModel unit tests with injectable overrides. Also draws from `Phase21CommunityHubViewModelTests.swift` for override closure pattern.

**Override pattern for DiscoverViewModel:**
```swift
@MainActor
final class Phase22DiscoverViewModelTests: XCTestCase {
    var sut: DiscoverViewModel!

    override func setUp() async throws { sut = DiscoverViewModel() }

    func test_onSearchTextChanged_emptyText_clearsResults() {
        sut.goalResults = [/* stub */]
        sut.onSearchTextChanged("")
        // After clearing, results should be empty immediately (no debounce on empty)
        XCTAssertTrue(sut.goalResults.isEmpty)
    }

    func test_joinGoal_setsJoinedState() throws {
        let ctx = try ModelContext(ModelContainer(for: Goal.self))
        let result = DiscoverGoalResult(id: "uuid-1", title: "Run 5K", ...)
        sut.joinGoal(result, tier: .daily, context: ctx)
        XCTAssertTrue(sut.isJoined(goalID: "uuid-1"))
    }
}
```

---

## Shared Patterns

### CloudKit Container Identifier
**Source:** `Services/ProfileSharingService.swift` lines 8–9; `Services/UsernameLookupService.swift` lines 17–18
**Apply to:** `PublicGoalService.swift`, expanded `ProfileSharingService.swift`
```swift
// Always use explicit identifier — never CKContainer.default() for new services:
private static let containerID = "iCloud.com.kyleharrington.VitaminG"
// Access: CKContainer(identifier: containerID).publicCloudDatabase
```

### Input Sanitization Before CloudKit Write
**Source:** `Services/CommunityService.swift` lines 50–53; `Services/CommunityService.swift` lines 329–330
**Apply to:** All CloudKit write methods in `PublicGoalService.swift` and `ProfileSharingService.swift`
```swift
// Every String field written to CloudKit public DB must be sanitized:
record["title"] = InputSanitizer.sanitizeForPublic(rawTitle) as CKRecordValue
record["motto"] = InputSanitizer.sanitizeForPublic(rawMotto) as CKRecordValue
```

### serverRecordChanged One-Retry Pattern
**Source:** `Services/CommunityService.swift` lines 86–95 (`toggleReaction`)
**Apply to:** `PublicGoalService.incrementParticipantCount`, any mutating CK write
```swift
} catch let error as CKError where error.code == .serverRecordChanged {
    // One retry — fetch latest, re-apply mutation, save
}
```

### Fire-and-Forget Task
**Source:** `ViewModels/GoalViewModel.swift` lines 181–188
**Apply to:** `VitaminGApp.swift` launch hooks, `GoalViewModel.addCheckIn` Phase 22 hooks, `PublicProfileViewModel.onCheer`, `PublicProfileViewModel.onFollow`
```swift
// Never await directly in the calling context — wrap in Task:
Task {
    await SomeService.someFireAndForgetOperation(...)
}
```

### ApplauseGate Reuse
**Source:** `ViewModels/CommunityHubViewModel.swift` lines 192–199 (`canApplaud`, `markApplauseGiven`)
**Apply to:** `PublicProfileViewModel` CheerButton gate
```swift
// Delegate to ApplauseGate static methods — do not re-implement:
ApplauseGate.canApplaud(recipientUsername: username, defaults: .standard)
ApplauseGate.markApplauseGiven(to: username, defaults: .standard)
```

### @MainActor @Observable ViewModel
**Source:** `ViewModels/CommunityHubViewModel.swift` lines 70–72; `ViewModels/ExploreViewModel.swift` lines 5–7
**Apply to:** `DiscoverViewModel.swift`, expanded `PublicProfileViewModel.swift`
```swift
@MainActor
@Observable
final class DiscoverViewModel { ... }
```

### Section Eyebrow Label
**Source:** `Views/Explore/ExploreView.swift` lines 77–83
**Apply to:** `PublicProfileView.swift` ("MY PUBLIC GOALS"), `DiscoverOverlayView.swift` ("TRENDING CHALLENGES")
```swift
private func sectionLabel(_ text: String) -> some View {
    Text(text.uppercased())
        .font(.system(size: 13, weight: .semibold))
        .kerning(0.4)
        .foregroundStyle(VGTheme.textMuted)
        .padding(.horizontal, 16)
}
```

### Card Surface + Shadow
**Source:** `Views/Components/CommunityPostCard.swift` lines 117–120
**Apply to:** `GoalSearchResultCard`, `PeopleSearchResultCard`, `PublicGoalCard`
```swift
.background(VGTheme.surface)
.clipShape(RoundedRectangle(cornerRadius: 12))  // 16pt for PublicGoalCard per UI-SPEC
.shadow(color: .black.opacity(0.04), radius: 6, y: 2)
```

### ViewModel Test Seam (fetchOverride closure)
**Source:** `ViewModels/PublicProfileViewModel.swift` lines 22–23; `ViewModels/CommunityHubViewModel.swift` lines 94–98
**Apply to:** `DiscoverViewModel` (searchGoalsOverride, searchPeopleOverride)
```swift
// nil in production — set in tests to avoid CloudKit:
var fetchOverride: ((String) async throws -> ReturnType)? = nil
```

### Isolated UserDefaults in Tests
**Source:** `VitaminGTests/Phase21ApplauseDailyGateTests.swift` lines 13–27
**Apply to:** `Phase22DiscoverViewModelTests`, any test touching UserDefaults
```swift
private var testDefaults: UserDefaults!
private var suiteName: String!

override func setUp() {
    suiteName = "test.\(UUID().uuidString)"
    testDefaults = UserDefaults(suiteName: suiteName)
}
override func tearDown() {
    testDefaults.removePersistentDomain(forName: suiteName)
    testDefaults = nil
}
```

---

## No Analog Found

All files have analogs. No entries in this section.

---

## Critical Implementation Notes for Planner

1. **ContentView.swift line 27–33**: The `NavigationStack` wrapping `ExploreView` already exists. `.searchable` must be added to this `NavigationStack` (not to ExploreView's internal ScrollView). `@State private var searchText` lives in ContentView or in ExploreView — planner must confirm the binding propagation approach.

2. **PublicProfileViewModelTests.swift must be updated**: The existing test file uses `fetchOverride: ((String) async throws -> (String?, String?))`. When `fetchProfile` return type changes to `PublicProfileData`, both `PublicProfileViewModel.fetchOverride` property type AND the test closures must be updated in the same plan step (Pitfall 6).

3. **typealias chain in Schema8pV2.swift**: The `typealias Goal = SchemaV6.Goal` and `typealias UserProfile = SchemaV8.UserProfile` lines (144–146) must both update to `SchemaV9` in the same commit as adding SchemaV9 (Pitfall 2).

4. **CloudKit Console human checkpoint**: `PublicGoal` and `Follow` record types must be deployed to Production before real-device testing. This is a blocking dependency with no code workaround. Include as a human verification step in Wave 1.

---

## Metadata

**Analog search scope:** All directories under `VitaminG/VitaminG/VitaminG/` and `VitaminG/VitaminG/VitaminGTests/`
**Files scanned:** 39 Swift source files + 39 test files
**Key analog files read:**
- `Services/CommunityService.swift` — CloudKit write/read/retry patterns
- `Services/ProfileSharingService.swift` — existing publishProfile/fetchProfile to expand
- `Services/UsernameLookupService.swift` — fetch-or-create with unknownItem catch
- `ViewModels/PublicProfileViewModel.swift` — ViewState enum and fetchOverride seam
- `ViewModels/CommunityHubViewModel.swift` — ApplauseGate, parallel async let, override closures
- `ViewModels/ExploreViewModel.swift` — UserDefaults gate, debounce structure
- `ViewModels/GoalViewModel.swift` — fire-and-forget Task pattern, addGoal(input:)
- `Views/PublicProfileView.swift` — shell to keep (navigation, toolbar, block/report)
- `Views/Explore/ExploreView.swift` — sectionLabel helper, 6-section layout
- `Views/Community/ApplauseButtonView.swift` — float animation, reduced motion, gate
- `Views/Components/ProgressRingView.swift` — Circle().trim() with rotationEffect + animation
- `Views/Components/CommunityPostCard.swift` — card layout with HStack + surface + shadow
- `Views/AvatarView.swift` — photoData: nil usage
- `Models/SchemaV8.swift` + `VitaminGMigrationPlan.swift` — schema version chain
- `Models/CommunityHubModels.swift` — Identifiable+Sendable struct pattern
- `VitaminGTests/PublicProfileViewModelTests.swift` — fetchOverride test seam pattern
- `VitaminGTests/Phase21ApplauseDailyGateTests.swift` — isolated UserDefaults test pattern
- `VitaminGApp.swift` — .task launch hook, fire-and-forget Task storage
- `Views/ProfileEditSheet.swift` — TextField + char count Section pattern
- `Views/ContentView.swift` — ExploreView NavigationStack placement confirmed (lines 27–33)
**Pattern extraction date:** 2026-05-24
