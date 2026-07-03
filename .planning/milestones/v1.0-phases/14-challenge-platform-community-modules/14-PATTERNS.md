# Phase 14: Challenge Platform — Community & Modules - Pattern Map

**Mapped:** 2026-05-07
**Files analyzed:** 20 (new/modified)
**Analogs found:** 20 / 20

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Models/SchemaV5.swift` | model | CRUD | `Models/SchemaV4.swift` | exact |
| `Models/VitaminGMigrationPlan.swift` | config | batch | `Models/VitaminGMigrationPlan.swift` | exact |
| `Persistence/ModelContainerFactory.swift` | config | CRUD | `Persistence/ModelContainerFactory.swift` | exact |
| `Services/CommunityService.swift` | service | request-response | `Services/ProfileSharingService.swift` | exact |
| `ViewModels/CommunityFeedViewModel.swift` | viewmodel | request-response | `ViewModels/PublicProfileViewModel.swift` | exact |
| `Services/ProfanityFilter.swift` | utility | transform | `Services/InputSanitizer.swift` | role-match |
| `Services/NotificationScheduler.swift` (extend) | service | event-driven | `Services/NotificationScheduler.swift` | exact |
| `Navigation/AppRoute.swift` (extend) | config | request-response | `Navigation/AppRoute.swift` | exact |
| `Views/CommunityFeedView.swift` | view | request-response | `Views/ChallengeDiscoveryView.swift` | exact |
| `Views/Components/CommunityPostCard.swift` | component | request-response | `Views/ChallengeDiscoveryView.swift` (ChallengeCardView) | exact |
| `Views/Components/ReactionPill.swift` | component | event-driven | `Views/Components/StreakChainView.swift` | role-match |
| `Views/PostComposeSheet.swift` | view | request-response | `Views/ChallengeCheckInView.swift` | exact |
| `Views/CustomChallengeBuilderView.swift` | view | request-response | `Views/ChallengeCheckInView.swift` | role-match |
| `Views/Modules/SpendingFreezeModuleView.swift` | component | CRUD | `Views/ChallengeCheckInView.swift` (booleanCheckInSection) | role-match |
| `Views/Modules/NutritionLogModuleView.swift` | component | CRUD | `Views/DailyWinsView.swift` | exact |
| `Views/Modules/CravingToolsModuleView.swift` | view | event-driven | `Views/MilestoneCelebrationView.swift` | role-match |
| `Views/Modules/TransformationPhotosModuleView.swift` | view | file-I/O | `Views/ChallengeDetailView.swift` | role-match |
| `Views/Modules/BuddyAccountabilityModuleView.swift` | view | event-driven | `Views/ProfileEditSheet.swift` | role-match |
| `Views/Modules/ContactPickerRepresentable.swift` | utility | request-response | (no UIViewControllerRepresentable in codebase) | no-analog |
| `Views/ChallengeDetailView.swift` (extend) | view | CRUD | `Views/ChallengeDetailView.swift` | exact |
| `VitaminGTests/ProfanityFilterTests.swift` | test | transform | `VitaminGTests/GoalViewModelTests.swift` | role-match |
| `VitaminGTests/CommunityFeedViewModelTests.swift` | test | request-response | `VitaminGTests/PublicProfileViewModelTests.swift` | exact |
| `VitaminGTests/SchemaV5Tests.swift` | test | CRUD | `VitaminGTests/GoalViewModelTests.swift` | role-match |
| `VitaminGTests/NotificationSchedulerPhase14Tests.swift` | test | event-driven | `VitaminGTests/GoalViewModelTests.swift` | role-match |

---

## Pattern Assignments

### `Models/SchemaV5.swift` (model, CRUD)

**Analog:** `Models/SchemaV4.swift` (lines 1–103)

**Imports pattern** (lines 1–3):
```swift
import SwiftData
import Foundation
```

**Core schema declaration pattern** (lines 18–29):
```swift
enum SchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        // V3 models unchanged + 3 new V4 types
        [SchemaV2.Goal.self,
         SchemaV2.CompletionEvent.self,
         SchemaV2.UserProfile.self,
         SchemaV3.DailyWin.self,
         SchemaV4.ChallengeTemplate.self,
         SchemaV4.UserChallenge.self,
         SchemaV4.CheckIn.self]
    }
```

**Model declaration pattern** (lines 83–97, CheckIn as the simplest model):
```swift
@Model
final class CheckIn {
    var id: UUID = UUID()
    var date: Date?
    var payloadBool: Bool?
    var payloadNumber: Double?
    var payloadNote: String?
    var timestamp: Date?

    var userChallenge: UserChallenge?

    init() {}
}
```

**Rules enforced by CLAUDE.md that SchemaV5 must follow:**
- All properties must be `?` (optional) or have a default value — no non-optional properties
- No `@Attribute(.unique)` — CloudKit does not support atomic uniqueness
- `@Attribute(.externalStorage)` only for binary blobs (`imageData: Data?` on TransformationPhoto)
- Use denormalized `userChallengeID: UUID?` instead of `@Relationship` for module entries to avoid inverse complexity

**New fields to add to existing SchemaV4.ChallengeTemplate** (before SchemaV5 is locked — pre-production):
```swift
var enabledModulesJSON: String?   // JSON-encoded [String], same pattern as milestonesJSON
var privacy: String?              // "private" | "community"
```

**New fields to add to existing SchemaV4.UserChallenge:**
```swift
var buddyDisplayName: String?     // contact display name from CNContact
var buddyPingLastSent: Date?      // for 24h cooldown enforcement
```

**SchemaV5 models list** (add V4 models + 3 new):
```swift
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
```

**Typealias pattern** (bottom of SchemaV4.swift, lines 101–103):
```swift
typealias ChallengeTemplate = SchemaV4.ChallengeTemplate
typealias UserChallenge = SchemaV4.UserChallenge
typealias CheckIn = SchemaV4.CheckIn
```
SchemaV5 should add:
```swift
typealias TransformationPhoto = SchemaV5.TransformationPhoto
typealias SpendingFreezeEntry = SchemaV5.SpendingFreezeEntry
typealias NutritionEntry = SchemaV5.NutritionEntry
```

---

### `Models/VitaminGMigrationPlan.swift` (config, batch)

**Analog:** `Models/VitaminGMigrationPlan.swift` (lines 1–42) — file is modified in-place

**Exact pattern to extend** (lines 19–41):
```swift
enum VitaminGMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self]  // add SchemaV5.self
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4]  // add migrateV4toV5
    }

    static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self
    )
    // Add below:
    static let migrateV4toV5 = MigrationStage.lightweight(
        fromVersion: SchemaV4.self,
        toVersion: SchemaV5.self
    )
}
```

---

### `Persistence/ModelContainerFactory.swift` (config, CRUD)

**Analog:** `Persistence/ModelContainerFactory.swift` (lines 1–108) — file modified in-place

**Pattern to update** (lines 11–12 and 37–38):
```swift
// BEFORE:
let schema = Schema(SchemaV4.models, version: SchemaV4.versionIdentifier)

// AFTER:
let schema = Schema(SchemaV5.models, version: SchemaV5.versionIdentifier)
```

**initializeCloudKitSchema object list** (lines 84–86 in DEBUG extension) must add new V5 models:
```swift
if let mom = NSManagedObjectModel.makeManagedObjectModel(
    for: [Goal.self, CompletionEvent.self, UserProfile.self, DailyWin.self,
          ChallengeTemplate.self, UserChallenge.self, CheckIn.self,
          TransformationPhoto.self, SpendingFreezeEntry.self, NutritionEntry.self]
)
```

---

### `Services/CommunityService.swift` (service, request-response)

**Analog:** `Services/ProfileSharingService.swift` (lines 1–70)

**Imports pattern** (line 1):
```swift
import CloudKit
```

**Enum + containerID pattern** (lines 6–9):
```swift
enum ProfileSharingService {
    private static let containerID = "iCloud.com.kyleharrington.VitaminG"
    private static let recordType = "PublicProfile"
```

**Async/await save pattern** (lines 38–40):
```swift
let savedRecord = try await publicDB.save(record)
return savedRecord.recordID.recordName
```

**Fetch by recordID pattern** (lines 46–53):
```swift
static func fetchProfile(recordID: String) async throws -> (displayName: String?, avatarColorHex: String?) {
    let container = CKContainer(identifier: containerID)
    let publicDB = container.publicCloudDatabase
    let ckRecordID = CKRecord.ID(recordName: recordID)
    let record = try await publicDB.record(for: ckRecordID)
    let displayName = record["displayName"] as? String
    let avatarColorHex = record["avatarColorHex"] as? String
    return (displayName: displayName, avatarColorHex: avatarColorHex)
}
```

**Delete with silent-success pattern** (lines 59–68):
```swift
do {
    try await publicDB.deleteRecord(withID: ckRecordID)
} catch let error as CKError where error.code == .unknownItem {
    // Record already deleted — not an error
}
```

**CommunityService must also use** `InputSanitizer.sanitizeForPublic()` on all String fields before CKRecord write (see InputSanitizer.swift lines 35–54).

---

### `ViewModels/CommunityFeedViewModel.swift` (viewmodel, request-response)

**Analog:** `ViewModels/PublicProfileViewModel.swift` (lines 1–51)

**Observable declaration pattern** (lines 1–6):
```swift
import Observation
import CloudKit

@MainActor
@Observable
final class PublicProfileViewModel {
```

**State + loading flag pattern** (lines 8–20):
```swift
enum ViewState: Equatable {
    case loading
    case loaded(displayName: String?, avatarColorHex: String?)
    case error(message: String)
}

var state: ViewState = .loading

var isLoading: Bool {
    if case .loading = state { return true }
    return false
}
```

**CKError discrimination pattern** (lines 34–47):
```swift
} catch let error as CKError {
    switch error.code {
    case .unknownItem:
        state = .error(message: "This profile is no longer available.")
    case .networkFailure, .networkUnavailable:
        state = .error(message: "Couldn't load profile. Check your internet connection and try again.")
    default:
        state = .error(message: "Couldn't load profile. Check your internet connection and try again.")
    }
} catch {
    state = .error(message: "Couldn't load profile. Check your internet connection and try again.")
}
```

**Test override injection pattern** (lines 22–24):
```swift
/// Closure override for unit testing. When non-nil, used instead of ProfileSharingService.
/// Follows the fake-injection pattern from NotificationSchedulerTests.
var fetchOverride: ((String) async throws -> (String?, String?))? = nil
```

**CommunityFeedViewModel additions vs analog:**
- `var posts: [CKRecord] = []` (not a ViewState enum — list grows incrementally)
- `var submitError: String? = nil`
- `var isLoading: Bool = false`
- `func loadPosts(category: String) async` wraps `CommunityService.fetchPosts`
- `func submitPost(text:imageData:category:author:) async` calls `ProfanityFilter.containsProfanity` BEFORE any CloudKit write

---

### `Services/ProfanityFilter.swift` (utility, transform)

**Analog:** `Services/InputSanitizer.swift` (lines 1–55)

**Enum + static pure function pattern** (lines 7–11):
```swift
enum InputSanitizer {

    static func sanitize(_ raw: String) -> String {
        // ...
    }
    static func sanitizeForPublic(_ raw: String) -> String {
```

**Pattern to copy for ProfanityFilter:**
```swift
enum ProfanityFilter {
    // Lazy static — loaded once from Bundle; O(1) after warm-up
    static let blockedWords: Set<String> = { /* load profanity_list.txt */ }()

    /// Whole-word match only — split on non-alphanumeric to avoid "classy" → "ass" false positive.
    static func containsProfanity(_ text: String) -> Bool {
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return words.contains { blockedWords.contains($0) }
    }
}
```

**Pre-warm call site:** Call `_ = ProfanityFilter.blockedWords` from `ChallengeDiscoveryView.onAppear` (background Task) to avoid first-tap stall (Pitfall 7 in RESEARCH.md).

---

### `Services/NotificationScheduler.swift` extension (service, event-driven)

**Analog:** `Services/NotificationScheduler.swift` lines 176–236 (Phase 13 challenge reminder extension)

**Per-identifier remove-before-add pattern** (lines 194–196):
```swift
let identifier = Self.challengeReminderIdentifier(for: challengeID)
let center = UNUserNotificationCenter.current()
center.removePendingNotificationRequests(withIdentifiers: [identifier])
```

**UNCalendarNotificationTrigger pattern** (lines 210–214):
```swift
var components = DateComponents()
components.hour   = validHour
components.minute = validMinute
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
```

**UNNotificationRequest with deepLink userInfo** (lines 200–208):
```swift
let content = UNMutableNotificationContent()
content.title = "Check in on your challenge"
content.body = challenge.template?.title ?? "Daily check-in reminder"
content.sound = .default
content.userInfo = [
    "deepLink": "challengeCheckIn",
    "userChallengeID": challengeID.uuidString
]
```

**Error logging pattern** (lines 220–225):
```swift
do {
    try await center.add(request)
} catch {
    #if DEBUG
    print("[NotificationScheduler] Failed to add challenge reminder: \(error)")
    #endif
}
```

**Phase 14 identifier scheme to follow:**
- Streak-at-risk: `"com.kyleharrington.VitaminG.streakAtRisk.\(challengeID.uuidString)"`
- Milestone: `"com.kyleharrington.VitaminG.milestone.\(challengeID.uuidString).\(threshold)"`
- Buddy ping: `"com.kyleharrington.VitaminG.buddyPing.\(challengeID.uuidString)"`

**For immediate one-time notifications** (milestone, buddy ping) use `UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)` instead of `UNCalendarNotificationTrigger`.

---

### `Navigation/AppRoute.swift` extension (config, request-response)

**Analog:** `Navigation/AppRoute.swift` (lines 1–17)

**Exact enum case addition pattern** (lines 8–16):
```swift
enum AppRoute: Hashable {
    case goalDetail(Goal)
    case stats
    case settings
    case profile
    case publicProfile(recordID: String)
    case wins
    case challengeDetail(UserChallenge)
    case challengeCheckIn(UserChallenge)
    // Phase 14 — add:
    case communityFeed(UserChallenge)   // push route carrying the challenge for category scoping
}
```

---

### `Views/CommunityFeedView.swift` (view, request-response)

**Analog:** `Views/ChallengeDiscoveryView.swift` (lines 1–171)

**Imports pattern** (lines 1–2):
```swift
import SwiftUI
import SwiftData
```

**State + ViewModel pattern** (lines 14–19):
```swift
@Environment(\.modelContext) private var modelContext
@State private var viewModel = ChallengeViewModel()
@Query private var templates: [ChallengeTemplate]
@Query private var userChallenges: [UserChallenge]
@State private var showBuildYourOwn = false
```

**CommunityFeedView state uses** `@State private var viewModel = CommunityFeedViewModel()` and `@State private var showCompose = false` — no `@Query` (posts are `[CKRecord]` managed by the ViewModel).

**LazyVStack list pattern** (lines 54–61):
```swift
LazyVStack(spacing: 12) {
    ForEach(templates.filter { $0.isFeatured }, id: \.id) { template in
        ChallengeCardView(
            template: template,
            userChallenge: userChallenges.first { $0.template?.id == template.id },
            onJoin: { joinChallenge(template) }
        )
    }
}
```

**Empty state pattern** (lines 113–131):
```swift
private var emptyFeaturedState: some View {
    VStack(spacing: 16) {
        Image(systemName: "flame.fill")
            .font(.system(size: 48))
            .foregroundStyle(VGTheme.muted)
        Text("No Challenges Yet")
            .font(.title2)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .foregroundStyle(VGTheme.clay)
        Text("Featured challenges are coming soon...")
            .font(.body)
            .fontDesign(.rounded)
            .foregroundStyle(VGTheme.muted)
            .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 32)
}
```

**Copy for CommunityFeedView empty state:** SF Symbol `person.3.fill`, heading "Be the First to Share", body "Be the first to share your progress! Your post can encourage others on the same journey."

**Background + onAppear pattern** (lines 32–38):
```swift
.background(VGTheme.sandLight)
.navigationTitle("Challenges")
.onAppear {
    viewModel.seedFeaturedTemplates(context: modelContext)
}
```

---

### `Views/Components/CommunityPostCard.swift` (component, request-response)

**Analog:** `Views/ChallengeDiscoveryView.swift` — private `ChallengeCardView` struct (lines 178–254)

**Card container pattern** (lines 249–253):
```swift
.padding(.horizontal, 16)
.padding(.vertical, 12)
.background(Color(.secondarySystemGroupedBackground))
.clipShape(RoundedRectangle(cornerRadius: 12))
```

**Accent color resolution pattern** (lines 183–185):
```swift
private var accentColor: Color {
    Color(hex: template.accentColorHex ?? "#C4673A")
}
```

**Report button:** `flag.fill` SF Symbol, `VGTheme.muted` tint, right-aligned in author row. `.confirmationDialog` on tap — copy from `Views/GoalDetailView.swift` delete confirmation pattern (lines 50–63).

**ReactionPill container within card:** `HStack(spacing: 8)` with two `ReactionPill` components + `Spacer()`.

---

### `Views/Components/ReactionPill.swift` (component, event-driven)

**Analog:** `Views/Components/StreakChainView.swift` (lines 1–86) — pure display component, no SwiftData

**Pure display component declaration pattern** (lines 13–19):
```swift
struct StreakChainView: View {
    let checkInDates: [Date]
    let accentColor: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
```

**ReactionPill declaration:**
```swift
struct ReactionPill: View {
    let emoji: String           // "👍" or "❤️"
    let count: Int
    let isActive: Bool          // current user has reacted
    let accentColor: Color
    let action: () -> Void
}
```

**Capsule shape pattern** (from ChallengeDiscoveryView category chips, lines 82–87):
```swift
.padding(.horizontal, 16)
.padding(.vertical, 8)
.background(Color(.secondarySystemGroupedBackground))
.clipShape(Capsule())
.foregroundStyle(VGTheme.clay)
```

**Active state border:** `.overlay(Capsule().strokeBorder(accentColor, lineWidth: 1))` when `isActive == true`.

**Accessibility:** `.accessibilityLabel("Thumbs up, \(count) reactions")` — no raw emoji in accessibility string.

---

### `Views/PostComposeSheet.swift` (view, request-response)

**Analog:** `Views/ChallengeCheckInView.swift` (lines 1–200)

**Sheet NavigationStack pattern** (lines 23–58):
```swift
NavigationStack {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            // ...
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle(modalTitle)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Cancel") { dismiss() }
                .font(.body)
                .fontDesign(.rounded)
        }
    }
}
```

**Note:** UI-SPEC mandates "Discard Post" (not "Cancel") for the leading cancel button.

**Save button helper pattern** (lines 163–173):
```swift
@ViewBuilder
private func saveButton(_ label: String, action: @escaping () -> Void) -> some View {
    Button(label, action: action)
        .font(.body)
        .fontWeight(.semibold)
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(accentColor)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}
```

**Error display pattern** (lines 38–43):
```swift
if let error = saveError {
    Text(error)
        .font(.caption)
        .fontDesign(.rounded)
        .foregroundStyle(.red)
}
```

**TextEditor placeholder pattern** (from DailyWinsView.swift lines 41–54):
```swift
ZStack(alignment: .topLeading) {
    if viewModel.draftText.isEmpty {
        Text("What's your win today?")
            .font(.body).fontDesign(.rounded)
            .foregroundStyle(.tertiary)
            .padding(.top, 8)
            .padding(.leading, 4)
            .allowsHitTesting(false)
    }
    TextEditor(text: $viewModel.draftText)
        .font(.body).fontDesign(.rounded)
        .frame(minHeight: 80)
        .scrollContentBackground(.hidden)
}
```

**Character count badge pattern** (DailyWinsView.swift lines 66–72):
```swift
Text("\(viewModel.sanitizedCount)/500")
    .font(.caption).fontDesign(.rounded)
    .foregroundStyle(.secondary)
    .frame(maxWidth: .infinity, alignment: .trailing)
```

**Profanity rejection state:** TextEditor `.overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.red, lineWidth: 1))` when profanity detected. Inline `.caption` red error below TextEditor. "Post" button disabled.

---

### `Views/Modules/SpendingFreezeModuleView.swift` (component, CRUD)

**Analog:** `Views/ChallengeCheckInView.swift` — booleanCheckInSection (lines 63–76)

**Toggle in card pattern** (lines 65–72):
```swift
Toggle("Did you complete today's goal?", isOn: $boolValue)
    .font(.body)
    .fontDesign(.rounded)
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color(.secondarySystemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
```

**Badge display when toggle ON:**
```swift
if isFreezeActive {
    Label("Freeze Active", systemImage: "snowflake.fill")
        .font(.caption.weight(.semibold))
        .fontDesign(.rounded)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(VGTheme.sage.opacity(0.2))
        .foregroundStyle(VGTheme.sage)
        .clipShape(Capsule())
}
```

**Section header pattern** (from ChallengeDetailView.swift lines 183–189):
```swift
Text("About This Challenge")
    .font(.title2)
    .fontWeight(.semibold)
    .fontDesign(.rounded)
    .foregroundStyle(VGTheme.clay)
```

---

### `Views/Modules/NutritionLogModuleView.swift` (component, CRUD)

**Analog:** `Views/DailyWinsView.swift` (lines 1–80)

**TextEditor with placeholder pattern** (lines 41–62, see PostComposeSheet above) — identical to DailyWinsView's today's editor.

**Save confirmation inline pattern** (DailyWinsView lines 76–79):
```swift
if let error = viewModel.validationError {
    Text(error.errorDescription ?? "")
        .font(.caption).fontDesign(.rounded)
        .foregroundStyle(.red)
}
```

Adapt for "Saved" confirmation: show `.caption` text in `VGTheme.sage` for 2 seconds after save using `.transition(.opacity)` and a `Task { try? await Task.sleep(for: .seconds(2)); showSaved = false }`.

**Save button:** Full-width, 44pt, template `accentColor` fill — copy `saveButton` helper from ChallengeCheckInView (lines 163–173). Only visible when text has changed since last save.

---

### `Views/Modules/CravingToolsModuleView.swift` (view, event-driven)

**Analog:** `Views/MilestoneCelebrationView.swift` (lines 1–60 read) + `Views/ChallengeCheckInView.swift`

**Sheet NavigationStack with "Done" toolbar** (MilestoneCelebrationView pattern + ProfileEditSheet lines 59–63):
```swift
NavigationStack {
    // content
    .navigationTitle("Craving Tools")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
        ToolbarItem(placement: .confirmationAction) {
            Button("Done") { dismiss() }
                .font(.body.weight(.semibold))
        }
    }
}
```

**accessibilityReduceMotion gate** (ChallengeDetailView.swift line 13, StreakChainView.swift line 19):
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

**VGTheme.serifItalic for motivational prompt** (from GoalDetailView pattern — referenced in UI-SPEC):
```swift
Text(currentPrompt)
    .font(VGTheme.serifItalic(17))
    .multilineTextAlignment(.center)
    .foregroundStyle(VGTheme.clay)
    .padding(.horizontal, 24)
```

**VGQuoteBank.randomQuote() pattern** (VGQuoteBank.swift lines 107–109):
```swift
static func randomQuote() -> VGQuote {
    all.randomElement() ?? all[0]
}
```
Craving Tools uses `VGQuoteBank.randomQuote()` for the motivational distraction prompt; "Another One" button calls it again.

**Box breathing animation state:**
```swift
@State private var phase: BreathingPhase = .inhale
@State private var countdown: Int = 4
@State private var fillFraction: Double = 0.0

// TimelineView drives per-frame animation; fillFraction drives scaleEffect
// .animation(.linear(duration: 4), value: fillFraction)
// If reduceMotion: static Circle().strokeBorder(accentColor, lineWidth: 3) only
```

---

### `Views/Modules/TransformationPhotosModuleView.swift` (view, file-I/O)

**Analog:** `Views/ChallengeDetailView.swift` (navigation push target pattern)

**NavigationStack push screen pattern** (ChallengeDetailView.swift lines 9–17):
```swift
struct ChallengeDetailView: View {
    let userChallenge: UserChallenge

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = ChallengeViewModel()
```

**LazyVGrid for photo thumbnails:**
```swift
let columns = Array(repeating: GridItem(.fixed(80), spacing: 8), count: 3)

LazyVGrid(columns: columns, spacing: 8) {
    ForEach(photos) { photo in
        // 80pt × 80pt thumbnail with date caption overlay
    }
}
```

**PhotosPicker import** (native SwiftUI — no UIViewControllerRepresentable):
```swift
import PhotosUI

@State private var selectedItem: PhotosPickerItem?

PhotosPicker(selection: $selectedItem, matching: .images) {
    Label("Add Today's Photo", systemImage: "plus")
}
.onChange(of: selectedItem) { _, newItem in
    Task {
        if let data = try? await newItem?.loadTransferable(type: Data.self) {
            // store in TransformationPhoto.imageData via modelContext.insert
        }
    }
}
```

**Empty state pattern** (ChallengeDiscoveryView lines 113–131 — copy structure):
SF Symbol `photo.stack.fill`, heading "No Photos Yet", body "Add your first transformation photo to track your journey."

---

### `Views/Modules/BuddyAccountabilityModuleView.swift` (view, event-driven)

**Analog:** `Views/ProfileEditSheet.swift` (lines 1–60)

**Sheet NavigationStack pattern** (ProfileEditSheet lines 15–30):
```swift
NavigationStack {
    Form {
        // content
    }
    .navigationTitle("Accountability Buddy")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
        // Discard Builder button
    }
}
```

**Toggle/HStack row from GoalDetailView** (GoalDetailView.swift lines 68–78 — not fully shown but pattern matches):
```swift
HStack {
    Text("Accountability Buddy")
        .font(.body).fontDesign(.rounded)
    Spacer()
    // buddy name or "Choose Contact" button
}
.padding(.horizontal, 16)
.padding(.vertical, 12)
.background(Color(.secondarySystemGroupedBackground))
.clipShape(RoundedRectangle(cornerRadius: 12))
```

**Ping button with 24h cooldown:**
```swift
Button("Ping \(buddyDisplayName)") {
    sendBuddyPing()
}
.disabled(!userChallenge.canSendBuddyPing || pingSentRecently)
.font(.body.weight(.semibold)).fontDesign(.rounded)
.frame(maxWidth: .infinity, minHeight: 44)
.background(accentColor)
.foregroundStyle(.white)
.clipShape(RoundedRectangle(cornerRadius: 12))
```

---

### `Views/Modules/ContactPickerRepresentable.swift` (utility, request-response)

**No codebase analog** — no existing `UIViewControllerRepresentable` in the project.

Use RESEARCH.md Pattern 6 exactly:
```swift
import ContactsUI

struct ContactPickerRepresentable: UIViewControllerRepresentable {
    var onContactSelected: (String) -> Void  // displayName only — no phone number

    func makeUIViewController(context: Context) -> UINavigationController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return UINavigationController(rootViewController: picker)  // REQUIRED — blank sheet without wrapper
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onContactSelected: onContactSelected) }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onContactSelected: (String) -> Void
        init(onContactSelected: @escaping (String) -> Void) { self.onContactSelected = onContactSelected }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = [contact.givenName, contact.familyName].filter { !$0.isEmpty }.joined(separator: " ")
            // Sanitize before storing: InputSanitizer.sanitize(name)
            onContactSelected(name.isEmpty ? "Buddy" : name)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {}
    }
}
```

---

### `Views/CustomChallengeBuilderView.swift` (view, request-response)

**Analog:** `Views/ChallengeCheckInView.swift` (lines 1–200) — two-step modal pattern

**Multi-step state pattern** (ChallengeCheckInView lines 16–21, multiStepCheckInSection lines 112–157):
```swift
@State private var multiStepPage: Int = 0

// Step navigation:
Button("Next Step") { multiStepPage = 1 }
// or in Phase 14:
Button("Next") { currentStep = 2 }
    .disabled(challengeName.trimmingCharacters(in: .whitespaces).isEmpty)
```

**Step indicator UI-SPEC pattern:**
```swift
Text("Step \(currentStep) of 2")
    .font(.caption.weight(.regular))
    .fontDesign(.rounded)
    .foregroundStyle(VGTheme.muted)
    .frame(maxWidth: .infinity, alignment: .center)
```

**Sheet with NavigationStack + toolbar cancel:**
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button("Discard Builder") { dismiss() }  // not "Cancel" — UI-SPEC mandate
            .font(.body).fontDesign(.rounded)
    }
    ToolbarItem(placement: .navigationBarTrailing) {
        Button("Next") { currentStep = 2 }
            .disabled(!isStep1Valid)
    }
}
```

**Validation error pattern** (ChallengeCheckInView lines 38–43):
```swift
if let error = validationError {
    Text(error)
        .font(.caption).fontDesign(.rounded)
        .foregroundStyle(.red)
}
```

**"Create Challenge" primary CTA:** Same as `saveButton` helper (ChallengeCheckInView lines 163–173) with template `accentColor` — disabled until Step 2 validation passes.

**Create action calls:** `ChallengeViewModel.createCustomTemplate(...)` which inserts a `ChallengeTemplate` with `challengeType = "custom"` into `modelContext`.

---

### `Views/ChallengeDetailView.swift` extension (view, CRUD)

**Analog:** `Views/ChallengeDetailView.swift` itself (lines 1–253) — file is modified in-place

**New section addition pattern** (follow existing progressSection/reminderSection structure, lines 130–196):
```swift
// Add "Tools & Modules" section below StreakChainView, before reminderSection:
if hasEnabledModules {
    modulesSection
        .padding(.top, 16)
}
```

**Module row pattern** (copy from ChallengeDiscoveryView category chip HStack — lines 79–87):
```swift
Label("Spending Freeze", systemImage: "snowflake")
    .font(.body).fontDesign(.rounded)
    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    .padding(.horizontal, 16)
    .background(Color(.secondarySystemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
```

**Sheet presentation pattern already in file** (lines 47–48):
```swift
.sheet(isPresented: $showCheckIn) {
    ChallengeCheckInView(userChallenge: userChallenge, viewModel: viewModel)
}
```

Add analogous `.sheet` bindings for `showCravingTools`, `showBuddy`, and NavigationLink for `TransformationPhotosModuleView`.

**Community link:** `NavigationLink(value: AppRoute.communityFeed(userChallenge))` — same pattern as `AppRoute.challengeDetail(challenge)` used in ChallengeDiscoveryView line 218.

---

## Test File Patterns

### `VitaminGTests/ProfanityFilterTests.swift` (test, transform)

**Analog:** `VitaminGTests/GoalViewModelTests.swift` (lines 1–60)

**Test class setup pattern** (lines 1–16):
```swift
import XCTest
@testable import VitaminG

@MainActor
final class GoalViewModelTests: XCTestCase {
    var sut: GoalViewModel!

    override func setUpWithError() throws {
        sut = GoalViewModel()
    }
    override func tearDownWithError() throws {
        sut = nil
    }
```

**Pure function test pattern** (no container needed for ProfanityFilter):
```swift
import XCTest
@testable import VitaminG

final class ProfanityFilterTests: XCTestCase {
    func test_containsProfanity_blockedWord_returnsTrue() {
        XCTAssertTrue(ProfanityFilter.containsProfanity("some blocked word here"))
    }
    func test_containsProfanity_cleanText_returnsFalse() {
        XCTAssertFalse(ProfanityFilter.containsProfanity("This is a great challenge!"))
    }
    func test_containsProfanity_partialWordEmbedded_returnsFalse() {
        // Whole-word match: "classy" must not match "ass"
        XCTAssertFalse(ProfanityFilter.containsProfanity("that was a classy performance"))
    }
}
```

### `VitaminGTests/CommunityFeedViewModelTests.swift` (test, request-response)

**Analog:** `VitaminGTests/PublicProfileViewModelTests.swift` (lines 1–59)

**Override injection pattern** (lines 22–24 and 26–47):
```swift
@MainActor
final class CommunityFeedViewModelTests: XCTestCase {
    var sut: CommunityFeedViewModel!

    override func setUp() async throws { sut = CommunityFeedViewModel() }
    override func tearDown() async throws { sut = nil }

    func test_loadPosts_success_populatesPostsArray() async throws {
        // Use fetchOverride (same fake-injection pattern as PublicProfileViewModelTests)
        sut.fetchOverride = { _ in [/* mock CKRecords */] }
        await sut.loadPosts(category: "fitness")
        XCTAssertFalse(sut.posts.isEmpty)
    }
```

### `VitaminGTests/SchemaV5Tests.swift` (test, CRUD)

**Analog:** `VitaminGTests/GoalViewModelTests.swift` (lines 1–16, container setup)

**In-memory container pattern** (lines 12–16):
```swift
override func setUpWithError() throws {
    container = try ModelContainerFactory.makeContainer(inMemory: true)
    context = container.mainContext
}
```

Tests confirm SwiftData insert + fetch roundtrip for `TransformationPhoto`, `SpendingFreezeEntry`, `NutritionEntry` using the same `inMemory: true` container.

### `VitaminGTests/NotificationSchedulerPhase14Tests.swift` (test, event-driven)

**Analog:** `VitaminGTests/GoalViewModelTests.swift` (setup/teardown pattern)

Tests verify identifier string correctness, `UNCalendarNotificationTrigger` at `hour: 20, minute: 0`, and `UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)` for milestone/buddy ping. Use `UNUserNotificationCenter.current()` in test mode with a mock delegate.

---

## Shared Patterns

### VGTheme Tokens (apply to ALL new views)
**Source:** `VGTheme.swift` (lines 1–46)
```swift
// Background surfaces
.background(VGTheme.sandLight)                          // screen background
.background(Color(.secondarySystemGroupedBackground))   // cards and rows

// Text hierarchy
.foregroundStyle(VGTheme.clay)     // primary text
.foregroundStyle(VGTheme.muted)    // secondary, placeholder, disabled

// Accent — always from template:
private var accentColor: Color {
    Color(hex: userChallenge.template?.accentColorHex ?? "#C4673A")
}
```

### Button Shape Contract (apply to ALL new primary CTAs)
**Source:** `Views/ChallengeCheckInView.swift` lines 163–173, `Views/ChallengeDetailView.swift` lines 117–126
```swift
Button(label, action: action)
    .font(.body)
    .fontWeight(.semibold)
    .fontDesign(.rounded)
    .frame(maxWidth: .infinity, minHeight: 44)
    .background(accentColor)
    .foregroundStyle(.white)
    .clipShape(RoundedRectangle(cornerRadius: 12))
```

### Typography Contract (apply to ALL new views)
**Source:** `Views/ChallengeDetailView.swift`, `Views/ChallengeDiscoveryView.swift`
- Section headers: `.font(.title2).fontWeight(.semibold).fontDesign(.rounded).foregroundStyle(VGTheme.clay)`
- Body text: `.font(.body).fontDesign(.rounded)`
- Captions/counts: `.font(.caption).fontDesign(.rounded).foregroundStyle(VGTheme.muted)`
- No `.fontDesign(.rounded)` omissions — every text element uses it

### Card Container (apply to ALL new card/row components)
**Source:** `Views/ChallengeDiscoveryView.swift` lines 249–253
```swift
.padding(.horizontal, 16)
.padding(.vertical, 12)
.background(Color(.secondarySystemGroupedBackground))
.clipShape(RoundedRectangle(cornerRadius: 12))
```

### InputSanitizer (apply to ALL user text before CloudKit write)
**Source:** `Services/InputSanitizer.swift` lines 35–54
- Post text: `InputSanitizer.sanitizeForPublic(text)` before CKRecord write
- Buddy display name: `InputSanitizer.sanitize(rawName)` before storing to `UserChallenge.buddyDisplayName`
- Nutrition note: `InputSanitizer.sanitize(note)` + enforce ≤ 300 chars

### JSON Encode/Decode (apply to all JSON string fields)
**Source:** `Models/ChallengeTemplate+Featured.swift` lines 119–137
```swift
// Decode (never crash — try? always):
guard let json = milestonesJSON,
      let data = json.data(using: .utf8),
      let decoded = try? JSONDecoder().decode([MilestoneConfig].self, from: data) else {
    return []
}

// Encode:
guard let data = try? JSONEncoder().encode(configs),
      let json = String(data: data, encoding: .utf8) else { return nil }
return json
```

### ConfirmationDialog for Destructive Actions (apply to report post, abandon challenge)
**Source:** `Views/ChallengeDetailView.swift` lines 66–77
```swift
.confirmationDialog(
    "Abandon this challenge?",
    isPresented: $showAbandonDialog,
    titleVisibility: .visible
) {
    Button("Abandon", role: .destructive) { /* action */ }
    Button("Keep Going", role: .cancel) {}
} message: {
    Text("Your progress will not be deleted, but your streak will end.")
}
```

### accessibilityReduceMotion Gate (apply to CravingToolsModuleView box breathing, any animation)
**Source:** `Views/ChallengeDetailView.swift` line 13, `Views/Components/StreakChainView.swift` line 19
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
// Then: if !reduceMotion { /* animated view */ } else { /* static fallback */ }
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `Views/Modules/ContactPickerRepresentable.swift` | utility | request-response | No existing `UIViewControllerRepresentable` bridge in the codebase — use RESEARCH.md Pattern 6 exactly |

---

## Metadata

**Analog search scope:** All Swift files under `VitaminG/VitaminG/VitaminG/` and `VitaminGTests/`
**Files scanned:** 33 source files + 9 test files
**Pattern extraction date:** 2026-05-07

**Key constraint reminders from CLAUDE.md:**
- `@Observable` macro (not `ObservableObject`) for all new ViewModels
- All SwiftData properties: `?` optional or defaulted — never bare non-optional
- No `@Attribute(.unique)` — uniqueness at ViewModel layer only
- No third-party dependencies — all CloudKit is raw CKRecord API
- MVVM strictly enforced — zero CloudKit calls in View layer
- `@Query` has no sort descriptor — ViewModel manages `[CKRecord]` sort
