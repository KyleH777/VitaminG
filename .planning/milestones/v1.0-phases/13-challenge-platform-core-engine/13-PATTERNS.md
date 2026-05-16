# Phase 13: Challenge Platform — Core Engine - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 18
**Analogs found:** 18 / 18

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `Models/SchemaV4.swift` | model | CRUD | `Models/SchemaV3.swift` | exact |
| `Models/VitaminGMigrationPlan.swift` | config | CRUD | self (update) | exact |
| `Persistence/ModelContainerFactory.swift` | config | CRUD | self (update) | exact |
| `ViewModels/ChallengeViewModel.swift` | viewmodel | CRUD | `ViewModels/GoalViewModel.swift` + `ViewModels/DailyWinsViewModel.swift` | exact |
| `Services/ChallengeStreakEngine.swift` | service | transform | `Services/StreakEngine.swift` | exact |
| `Services/NotificationScheduler.swift` | service | event-driven | self (extend) | exact |
| `Services/DeepLinkBuilder.swift` | service | request-response | self (extend) | exact |
| `Services/DeepLinkParser.swift` | service | request-response | self (extend) | exact |
| `Navigation/AppRoute.swift` | config | request-response | self (extend) | exact |
| `Navigation/AppRouter.swift` | config | request-response | self (extend) | exact |
| `Views/ContentView.swift` | component | request-response | self (extend) | exact |
| `Views/ChallengeDiscoveryView.swift` | component | CRUD | `Views/DailyWinsView.swift` + `Views/GoalListView.swift` | role-match |
| `Views/ChallengeDetailView.swift` | component | CRUD | `Views/GoalDetailView.swift` | role-match |
| `Views/ChallengeCheckInView.swift` | component | CRUD | `Views/DailyWinsView.swift` | role-match |
| `Views/MilestoneCelebrationView.swift` | component | event-driven | `Views/GoalListView.swift` (GoalRowView milestone badge) | partial-match |
| `Views/Components/StreakChainView.swift` | component | transform | `Views/Components/ProgressRingView.swift` | role-match |
| `VitaminGTests/ChallengeStreakEngineTests.swift` | test | transform | `VitaminGTests/StreakEngineTests.swift` | exact |
| `VitaminGTests/ChallengeViewModelTests.swift` | test | CRUD | `VitaminGTests/DailyWinsViewModelTests.swift` + `VitaminGTests/GoalViewModelTests.swift` | exact |

---

## Pattern Assignments

### `Models/SchemaV4.swift` (model, CRUD)

**Analog:** `Models/SchemaV3.swift`

**Imports pattern** (SchemaV3.swift lines 1-2):
```swift
import SwiftData
import Foundation
```

**Core schema enum pattern** (SchemaV3.swift lines 13-20):
```swift
enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        // V2 models (unchanged) + DailyWin (new in V3)
        [SchemaV2.Goal.self, SchemaV2.CompletionEvent.self,
         SchemaV2.UserProfile.self, SchemaV3.DailyWin.self]
    }
```

**Model declaration pattern** (SchemaV3.swift lines 28-41):
```swift
@Model
final class DailyWin {
    var id: UUID = UUID()
    var date: Date?
    var text: String?

    init(date: Date = Date(), text: String) {
        self.date = date
        self.text = text
    }
}
```

**Typealias pattern** (SchemaV3.swift lines 44-47):
```swift
// MARK: - Typealias (V3)
typealias DailyWin = SchemaV3.DailyWin
```

**Rules for SchemaV4:**
- `static var versionIdentifier = Schema.Version(4, 0, 0)`
- `models` array includes all V3 models unchanged (`SchemaV2.Goal.self`, `SchemaV2.CompletionEvent.self`, `SchemaV2.UserProfile.self`, `SchemaV3.DailyWin.self`) plus the three new V4 types
- All three new `@Model` classes live inside `enum SchemaV4` only — never redeclare prior-version models
- Every property: `var foo: Type?` OR `var foo: Type = default` — no non-optional properties without defaults (CloudKit constraint from CLAUDE.md)
- No `@Attribute(.unique)` on any property
- Every `@Relationship` must declare `inverse:` on both ends
- Three typealiases at the bottom: `ChallengeTemplate`, `UserChallenge`, `CheckIn`

---

### `Models/VitaminGMigrationPlan.swift` (config, CRUD) — UPDATE

**Analog:** Self — `Models/VitaminGMigrationPlan.swift`

**Current state** (lines 19-35):
```swift
enum VitaminGMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self
    )
}
```

**Changes required — add SchemaV4 to both arrays and add migration stage:**
```swift
// schemas array: add SchemaV4.self
[SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self]

// stages array: add migrateV3toV4
[migrateV1toV2, migrateV2toV3, migrateV3toV4]

// New stage (additive-only — lightweight is correct):
static let migrateV3toV4 = MigrationStage.lightweight(
    fromVersion: SchemaV3.self,
    toVersion: SchemaV4.self
)
```

---

### `Persistence/ModelContainerFactory.swift` (config, CRUD) — UPDATE

**Analog:** Self — `Persistence/ModelContainerFactory.swift`

**Current schema references** (lines 12, 38):
```swift
let schema = Schema(SchemaV3.models, version: SchemaV3.versionIdentifier)
```

**Changes required — update both `makeContainer` and `makeWidgetContainer`:**
```swift
// Replace SchemaV3 with SchemaV4 in BOTH functions:
let schema = Schema(SchemaV4.models, version: SchemaV4.versionIdentifier)
```

**CloudKit schema init DEBUG block** (lines 60-107) — update `makeManagedObjectModel` call (line 83-85):
```swift
// Current:
if let mom = NSManagedObjectModel.makeManagedObjectModel(
    for: [Goal.self, CompletionEvent.self, UserProfile.self, DailyWin.self]
)

// Updated — add 3 new model types:
if let mom = NSManagedObjectModel.makeManagedObjectModel(
    for: [Goal.self, CompletionEvent.self, UserProfile.self, DailyWin.self,
          ChallengeTemplate.self, UserChallenge.self, CheckIn.self]
)
```

The `migrationPlan: VitaminGMigrationPlan.self` parameter in both `makeContainer` and `makeWidgetContainer` does NOT need changing — migration plan already references its own enum which will include the new stage.

---

### `ViewModels/ChallengeViewModel.swift` (viewmodel, CRUD) — NEW

**Primary analog:** `ViewModels/GoalViewModel.swift`
**Secondary analog:** `ViewModels/DailyWinsViewModel.swift`

**Imports pattern** (GoalViewModel.swift lines 1-5):
```swift
import SwiftData
import SwiftUI
import Observation
import WidgetKit
```

For ChallengeViewModel — omit `WidgetKit` (challenges don't reload widget timelines in Phase 13):
```swift
import SwiftData
import Foundation
import Observation
```

**Class declaration + Observable pattern** (GoalViewModel.swift lines 30-32):
```swift
@MainActor
@Observable
final class GoalViewModel {
```

**Pending milestone + firedMilestones pattern** (GoalViewModel.swift lines 56-60):
```swift
var pendingMilestone: (goalID: UUID, threshold: Int)? = nil
private var firedMilestones: Set<String> = []
```

For ChallengeViewModel — adapt the tuple fields:
```swift
var pendingMilestone: (challengeID: UUID, threshold: Int)? = nil
private var firedMilestones: Set<String> = []
```

**FetchDescriptor idempotency guard pattern** (DailyWinsViewModel.swift lines 52-65 — `todayEntry` as model):
```swift
func todayEntry(context: ModelContext) -> DailyWin? {
    let today = Calendar.current.startOfDay(for: Date())
    guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
        return nil
    }
    let descriptor = FetchDescriptor<DailyWin>(
        sortBy: [SortDescriptor(\.date, order: .reverse)]
    )
    let all = (try? context.fetch(descriptor)) ?? []
    return all.first { win in
        guard let d = win.date else { return false }
        return d >= today && d < tomorrow
    }
}
```

Apply same pattern for `todayCheckIn(for:context:)` and `seedFeaturedTemplates(context:)` (use `FetchDescriptor<ChallengeTemplate>` with `#Predicate { $0.isFeatured == true }`; guard `existing.isEmpty`).

**Milestone detection delegation pattern** (GoalViewModel.swift lines 122-132):
```swift
let count = goal.completionEvents?.count ?? 0
if let threshold = progressVM.milestoneJustCrossed(
    count: count,
    firedSet: firedMilestones,
    goalID: goal.id
) {
    let key = "\(goal.id.uuidString)-\(threshold)"
    firedMilestones.insert(key)
    pendingMilestone = (goalID: goal.id, threshold: threshold)
}
```

**Notification scheduling from ViewModel** (GoalViewModel.swift lines 177-185):
```swift
func rescheduleNotification(context: ModelContext) {
    let descriptor = FetchDescriptor<Goal>(predicate: #Predicate { !$0.isCompleted })
    let activeGoals = (try? context.fetch(descriptor)) ?? []
    Task {
        await NotificationScheduler.shared.reschedule(activeGoals: activeGoals)
    }
}
```

For ChallengeViewModel — adapt for challenge reminder scheduling using `Task { await NotificationScheduler.shared.scheduleChallengeReminder(for: challenge, hour: h, minute: m) }`.

**No `@Query` inside ViewModel** — this constraint is established by `ProgressViewModel` (pure struct), `StatsViewModel`, and `DailyWinsViewModel`. ChallengeViewModel receives arrays; `@Query` lives in Views.

---

### `Services/ChallengeStreakEngine.swift` (service, transform) — NEW

**Analog:** `Services/StreakEngine.swift` — direct adaptation

**Imports pattern** (StreakEngine.swift line 1):
```swift
import Foundation
```

**Struct declaration pattern** (StreakEngine.swift lines 13-14):
```swift
struct StreakEngine {
```

**DST-safe currentStreak pattern** (StreakEngine.swift lines 27-69):
```swift
static func currentStreak(
    from events: [CompletionEvent],
    tier: GoalTier? = nil,
    calendar: Calendar = .current
) -> Int {
    // Build Set<Date> of startOfDay values — O(1) lookup
    let days: Set<Date> = Set(
        filtered.compactMap { $0.completedAt }.map { calendar.startOfDay(for: $0) }
    )
    guard !days.isEmpty else { return 0 }

    let today = calendar.startOfDay(for: Date())
    var candidate: Date
    if days.contains(today) {
        candidate = today
    } else {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            return 0
        }
        candidate = yesterday
    }

    var streak = 0
    while days.contains(candidate) {
        streak += 1
        guard let previous = calendar.date(byAdding: .day, value: -1, to: candidate) else {
            break
        }
        candidate = previous
    }
    return streak
}
```

For `ChallengeStreakEngine` — input is `[Date]` (check-in dates) not `[CompletionEvent]`. Replace `filtered.compactMap { $0.completedAt }` with `checkInDates.compactMap { calendar.startOfDay(for: $0) }`. Add a `longestStreak(from:calendar:)` static method that sorts and walks forward (see RESEARCH.md Pattern 5).

**Injectable Calendar parameter** (StreakEngine.swift line 30): `calendar: Calendar = .current` — copy exactly for testability.

---

### `Services/NotificationScheduler.swift` (service, event-driven) — EXTEND

**Analog:** Self — existing `NotificationScheduler.swift`

**Identifier scheme pattern** (lines 17, 124):
```swift
static let identifier = "com.kyleharrington.VitaminG.dailyReminder"
static let winIdentifier = "com.kyleharrington.VitaminG.winReminder"
```

Follow same naming for challenge reminder: `"com.kyleharrington.VitaminG.challengeReminder.\(challengeID.uuidString)"`.

**Remove-before-add pattern** (lines 53-56):
```swift
func schedule(hour: Int, minute: Int, activeGoals: [Goal]) async {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
```

**UNCalendarNotificationTrigger + UNNotificationRequest pattern** (lines 59-78):
```swift
let validHour = max(0, min(23, hour))
let validMinute = max(0, min(59, minute))

var components = DateComponents()
components.hour = validHour
components.minute = validMinute

let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
let request = UNNotificationRequest(
    identifier: Self.identifier,
    content: makeContent(activeGoals: activeGoals),
    trigger: trigger
)
do {
    try await center.add(request)
} catch {
    #if DEBUG
    print("[NotificationScheduler] Failed to add daily reminder request: \(error)")
    #endif
}
```

**userInfo deep-link pattern** (lines 42-46):
```swift
content.userInfo = ["deepLink": "goalList"]
```

For challenge reminder: `content.userInfo = ["deepLink": "challengeCheckIn", "userChallengeID": id.uuidString]`.

**Win reminder as model for per-challenge extension** (lines 120-165): The win reminder (added in Phase 11) establishes the per-feature extension pattern. The challenge reminder extension follows the same structure: a static identifier factory method, a `scheduleChallengeReminder(for:hour:minute:) async` method, and a `removeChallengeReminder(for:)` method.

---

### `Services/DeepLinkBuilder.swift` (service, request-response) — EXTEND

**Analog:** Self — existing `DeepLinkBuilder.swift`

**Current file** (lines 1-14):
```swift
import Foundation

enum DeepLinkBuilder {
    static let scheme = "vitaming"

    static func profileURL(recordID: String?) -> URL? {
        guard let recordID, !recordID.isEmpty else { return nil }
        return URL(string: "\(scheme)://profile/\(recordID)")
    }
}
```

**URL construction pattern** — add static func inside the same enum:
```swift
// vitaming://challengeCheckIn/<userChallengeID>
static func challengeCheckInURL(userChallengeID: UUID) -> URL? {
    URL(string: "\(scheme)://challengeCheckIn/\(userChallengeID.uuidString)")
}
```

---

### `Services/DeepLinkParser.swift` (service, request-response) — EXTEND

**Analog:** Self — existing `DeepLinkParser.swift`

**Current parsing pattern** (lines 11-17):
```swift
static func recordID(from url: URL) -> String? {
    guard url.scheme == DeepLinkBuilder.scheme,
          url.host == "profile",
          let recordID = url.pathComponents.dropFirst().first,
          !recordID.isEmpty else { return nil }
    return recordID
}
```

**Add parallel static func inside the same enum:**
```swift
static func challengeCheckInID(from url: URL) -> String? {
    guard url.scheme == DeepLinkBuilder.scheme,
          url.host == "challengeCheckIn",
          let id = url.pathComponents.dropFirst().first,
          !id.isEmpty else { return nil }
    return id
}
```

Security note: same guard chain as existing `recordID(from:)` — scheme + host + non-empty path. `UUID(uuidString:)` called at call-site to validate format before use.

---

### `Navigation/AppRoute.swift` (config, request-response) — EXTEND

**Analog:** Self — existing `AppRoute.swift`

**Current file** (lines 8-15):
```swift
enum AppRoute: Hashable {
    case goalDetail(Goal)
    case stats
    case settings
    case profile
    case publicProfile(recordID: String)
    case wins
}
```

**Add two new cases inside the same enum:**
```swift
case challengeDetail(UserChallenge)   // Phase 13 — CHAL-08, D-05
case challengeCheckIn(UserChallenge)  // Phase 13 — CHAL-09, D-05, D-06
```

`UserChallenge` is a SwiftData `@Model` class. Verify `Hashable` conformance compiles (PersistentModel provides `Identifiable` via `id`). If not, add below SchemaV4 declaration:
```swift
extension SchemaV4.UserChallenge: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
```

---

### `Navigation/AppRouter.swift` (config, request-response) — EXTEND

**Analog:** Self — existing `AppRouter.swift`

**Current pending deep-link state pattern** (lines 12-13):
```swift
var pendingPublicProfileRecordID: String? = nil
```

**Add challenge pending state parallel to the profile pattern:**
```swift
var pendingChallengeCheckInID: String? = nil
```

`ProfileDeepLinkItem` struct (lines 29-32) is the model for a thin `Identifiable` wrapper enabling `.sheet(item:)`. Create parallel `ChallengeCheckInDeepLinkItem: Identifiable` if needed for `.sheet(item:)` on the check-in modal triggered from notification tap.

---

### `Views/ContentView.swift` (component, request-response) — EXTEND

**Analog:** Self — existing `ContentView.swift`

**TabView structure pattern** (lines 11-39):
```swift
TabView {
    goalsTab
        .tabItem { Label("Goals", systemImage: "target") }

    NavigationStack { StatsView() }
        .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

    NavigationStack { DailyWinsView() }
        .tabItem { Label("Wins", systemImage: "book.pages") }

    // Profile tab — Plan 07-02 (D-11)
    NavigationStack { ProfileView() }
        .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
}
```

**Add Challenges tab before Profile (slot index 3, 0-based), matching D-04 order:**
```swift
NavigationStack { ChallengeDiscoveryView() }
    .tabItem { Label("Challenges", systemImage: "flame.fill") }
```

**navigationDestination switch pattern** (lines 52-67):
```swift
.navigationDestination(for: AppRoute.self) { route in
    switch route {
    case .goalDetail(let goal):
        GoalDetailView(goal: goal)
    // ...
    }
}
```

**Add challenge cases to the switch** (inside the goals-tab `goalsTab` — or add to the Challenges tab's own `NavigationStack`):
```swift
case .challengeDetail(let challenge):
    ChallengeDetailView(userChallenge: challenge)
case .challengeCheckIn(let challenge):
    ChallengeCheckInView(userChallenge: challenge)
```

**Notification-triggered check-in sheet pattern** — mirror the `pendingPublicProfileRecordID` sheet (lines 40-45):
```swift
.sheet(item: Binding(
    get: { router.pendingPublicProfileRecordID.map { ProfileDeepLinkItem(id: $0) } },
    set: { _ in router.pendingPublicProfileRecordID = nil }
)) { item in
    PublicProfileView(recordID: item.id)
}
```

Apply same `.sheet(item:)` binding pattern for `pendingChallengeCheckInID`.

---

### `Views/ChallengeDiscoveryView.swift` (component, CRUD) — NEW

**Analog:** `Views/DailyWinsView.swift` + `Views/GoalListView.swift`

**Imports pattern** (DailyWinsView.swift lines 1-2):
```swift
import SwiftUI
import SwiftData
```

**Environment + Query + ViewModel state pattern** (DailyWinsView.swift lines 10-20):
```swift
@Environment(\.modelContext) private var modelContext
@State private var viewModel = DailyWinsViewModel()
@Query(sort: \DailyWin.date, order: .reverse) private var allWins: [DailyWin]
```

For ChallengeDiscoveryView:
```swift
@Environment(\.modelContext) private var modelContext
@State private var viewModel = ChallengeViewModel()
@Query private var templates: [ChallengeTemplate]   // no sort — VM provides sorted computed property (CLAUDE.md constraint)
@Query private var userChallenges: [UserChallenge]
```

**NavigationLink to associated-value route pattern** (GoalListView.swift lines 156-158):
```swift
NavigationLink(value: AppRoute.goalDetail(goal)) {
    GoalRowView(...)
}
```

Apply for challenge cards: `NavigationLink(value: AppRoute.challengeDetail(userChallenge)) { ... }`.

**onAppear seeding pattern** (DailyWinsView.swift lines 151-154):
```swift
.onAppear {
    if let existing = viewModel.todayEntry(context: modelContext) {
        viewModel.draftText = existing.text ?? ""
    }
}
```

For ChallengeDiscoveryView — call seeding on appear:
```swift
.onAppear {
    viewModel.seedFeaturedTemplates(context: modelContext)
}
```

---

### `Views/ChallengeDetailView.swift` (component, CRUD) — NEW

**Analog:** `Views/GoalDetailView.swift` (for detail layout structure) + `Views/GoalListView.swift` (for milestone fullScreenCover)

**Environment + State pattern** (GoalListView.swift lines 6-16):
```swift
@Environment(\.modelContext) private var modelContext
@State private var viewModel = GoalViewModel()
@State private var showingAddGoal = false
```

**fullScreenCover milestone pattern** (GoalListView.swift lines 132-146 — `.onChange(of:)` handler):
```swift
.onChange(of: viewModel.pendingMilestone?.goalID) { _, _ in
    if let milestone = viewModel.pendingMilestone {
        pendingMilestone = milestone
        viewModel.pendingMilestone = nil
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            pendingMilestone = nil
        }
    }
}
```

For ChallengeDetailView — use `.fullScreenCover` (CHAL-10 requires full-screen, not inline badge):
```swift
@State private var showMilestoneCelebration = false
@State private var currentMilestone: (challengeID: UUID, threshold: Int)? = nil

// In body:
.fullScreenCover(isPresented: $showMilestoneCelebration) {
    MilestoneCelebrationView(milestone: currentMilestone, ...) {
        showMilestoneCelebration = false
    }
}
.onChange(of: viewModel.pendingMilestone?.challengeID) { _, _ in
    if let m = viewModel.pendingMilestone {
        currentMilestone = m
        viewModel.pendingMilestone = nil
        showMilestoneCelebration = true
    }
}
```

**Reduce-motion accessibility pattern** (GoalListView.swift / GoalRowView lines 218, 286):
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

---

### `Views/ChallengeCheckInView.swift` (component, CRUD) — NEW

**Analog:** `Views/DailyWinsView.swift`

**Save action pattern with error handling** (DailyWinsView.swift lines 83-94):
```swift
Button {
    editorFocused = false
    do {
        try viewModel.saveEntry(context: modelContext)
    } catch {
        // validationError is set inside saveEntry — UI picks it up
    }
} label: { ... }
```

For ChallengeCheckInView — adapt for `viewModel.recordCheckIn(for:payload:context:)`:
```swift
do {
    try viewModel.recordCheckIn(for: userChallenge, payload: payload, context: modelContext)
    dismiss()
} catch {
    // error handled inline
}
```

**Inline validation error display pattern** (DailyWinsView.swift lines 76-79):
```swift
if let error = viewModel.validationError {
    Text(error.errorDescription ?? "")
        .font(.caption).fontDesign(.rounded)
        .foregroundStyle(.red)
}
```

**Type-specific branching in View layer only** (CHAL-07/CHAL-09): The `switch` on `template.checkInType` is allowed exclusively here, not in the engine. Pattern:
```swift
switch userChallenge.template?.checkInType {
case "boolean":
    BooleanCheckInSection(payload: $payload)
case "numeric":
    NumericCheckInSection(payload: $payload)
case "multiStep":
    MultiStepCheckInSection(payload: $payload)
default:
    EmptyView()
}
```

**InputSanitizer for payloadNote** (InputSanitizer.swift `sanitize(_:)` static method — max 500 chars matching DailyWin pattern):
```swift
let cleanNote = InputSanitizer.sanitize(rawNote)
guard cleanNote.count <= 500 else { /* throw */ }
```

---

### `Views/MilestoneCelebrationView.swift` (component, event-driven) — NEW

**Analog:** `Views/GoalListView.swift` (GoalRowView milestone badge animation — partial match; Phase 13 elevates to full-screen)

**Existing badge SF symbol selection pattern** (GoalListView.swift lines 269-271):
```swift
Image(systemName: threshold == 50 ? "trophy.fill" : "star.fill")
    .font(.system(size: 48))
    .foregroundStyle(goal.tier.color)
```

For MilestoneCelebrationView — use `MilestoneConfig.badgeSymbol` from the challenge template's decoded milestones array (e.g., `"flame.fill"` at 7-day, `"trophy.fill"` at 30-day, `"star.fill"` at 90-day).

**Scale + opacity animation pattern** (GoalListView.swift GoalRowView lines 326-338):
```swift
withAnimation(.easeOut(duration: 0.2)) {
    badgeOpacity = 1.0
    badgeScale = 1.2
}
// ...
withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
    badgeScale = 1.0
}
```

Use `withAnimation(.spring)` for confetti and badge entrance (CONTEXT.md Claude's discretion recommendation). No third-party confetti — implement as SwiftUI `Canvas` or `TimelineView` particle overlay (CLAUDE.md: no third-party deps).

**Reduce-motion pattern** (GoalListView.swift GoalRowView lines 316-322):
```swift
if reduceMotion {
    badgeOpacity = 1.0
    badgeScale = 1.0
    // static display, shorter hold, no spring
}
```

**Accessibility announcement** (GoalListView.swift line 309):
```swift
UIAccessibility.post(notification: .announcement,
                     argument: "Milestone reached: \(threshold) completions!")
```

---

### `Views/Components/StreakChainView.swift` (component, transform) — NEW

**Analog:** `Views/Components/ProgressRingView.swift`

**Imports pattern** (ProgressRingView.swift line 1):
```swift
import SwiftUI
```

**Reduce-motion environment pattern** (ProgressRingView.swift line 17):
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

**Circle stroke pattern** (ProgressRingView.swift lines 29-35):
```swift
Circle()
    .stroke(tier.color.opacity(0.15), lineWidth: 3)

Circle()
    .trim(from: 0, to: progress)
    .stroke(strokeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
    .rotationEffect(.degrees(-90))
```

For StreakChainView — day dots use `Circle().fill(accentColor)` (checked in) vs `Circle().fill(Color.clear).strokeBorder(accentColor.opacity(0.4), lineWidth: 1)` (missed). Today's dot gets 2pt stroke at full accent opacity.

**Accessibility label pattern** (ProgressRingView.swift lines 43-47):
```swift
.accessibilityLabel(
    isCompleted
        ? "Goal complete"
        : "\(Int((progress * 100).rounded()))% momentum this week"
)
.accessibilityAddTraits(.isStaticText)
```

**Frame size from Claude's discretion** (CONTEXT.md): 20pt diameter circles, 4pt spacing in HStack, ScrollView(.horizontal). `.frame(width: 20, height: 20)` per dot.

**`ScrollView(.horizontal)` with `HStack`** — generates 30 days via:
```swift
private var days: [Date] {
    let today = Calendar.current.startOfDay(for: Date())
    return (0..<30).compactMap {
        Calendar.current.date(byAdding: .day, value: -($0), to: today)
    }.reversed()
}
```

---

### `VitaminGTests/ChallengeStreakEngineTests.swift` (test, transform) — NEW

**Analog:** `VitaminGTests/StreakEngineTests.swift` — direct adaptation

**Test class declaration + setUp pattern** (StreakEngineTests.swift lines 6-18):
```swift
import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class StreakEngineTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }
```

**Helper to make test dates** (StreakEngineTests.swift lines 23-33):
```swift
private func makeEvent(dayOffset: Int, tier: GoalTier = .immediate) -> CompletionEvent {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    let date = cal.date(byAdding: .day, value: dayOffset, to: today)!
    // ...
}
```

For ChallengeStreakEngineTests — helper returns `Date` directly:
```swift
private func makeDate(dayOffset: Int, calendar: Calendar = .current) -> Date {
    let today = calendar.startOfDay(for: Date())
    return calendar.date(byAdding: .day, value: dayOffset, to: today)!
}
```

**Test cases to cover** (from RESEARCH.md validation architecture CHAL-05):
- `test_emptyCheckIns_returnsZeroStreak()`
- `test_singleTodayCheckIn_returnsOneStreak()`
- `test_consecutiveDays_returnsCorrectStreak()` — mirror StreakEngineTests line 53
- `test_gapBreaksStreak()` — mirror StreakEngineTests line 63
- `test_multipleSameDayCheckIns_countAsOneDay()` — mirror StreakEngineTests line 104
- `test_dstSafe_usesCalendarStartOfDay()` — injectable calendar, mirror StreakEngineTests line 130
- `test_longestStreak_correctAcrossGap()`
- `test_todayMissed_yesterdayStreakPreserved()` — mirror StreakEngineTests line 183

---

### `VitaminGTests/ChallengeViewModelTests.swift` (test, CRUD) — NEW

**Primary analog:** `VitaminGTests/DailyWinsViewModelTests.swift`
**Secondary analog:** `VitaminGTests/GoalViewModelTests.swift`

**Test class declaration pattern** (DailyWinsViewModelTests.swift lines 6-17):
```swift
import XCTest
import SwiftData
@testable import VitaminG

@MainActor
final class DailyWinsViewModelTests: XCTestCase {
    private var container: ModelContainer!
    private var viewModel: DailyWinsViewModel!

    override func setUp() async throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        viewModel = DailyWinsViewModel()
    }

    override func tearDown() async throws {
        container = nil
        viewModel = nil
    }
```

**XCTAssertThrowsError pattern** (DailyWinsViewModelTests.swift lines 44-48):
```swift
XCTAssertThrowsError(try viewModel.saveEntry(context: context)) { error in
    XCTAssertEqual(error as? DailyWinValidationError, .textEmpty)
}
```

**One-per-day enforcement test pattern** (DailyWinsViewModelTests.swift lines 70-83):
```swift
func test_saveEntry_validText_todayEntryExists_updatesNotInserts() throws {
    let context = ModelContext(container)
    let existing = DailyWin(date: Date(), text: "First save")
    context.insert(existing)

    viewModel.draftText = "Updated win"
    try viewModel.saveEntry(context: context)

    let all = try context.fetch(FetchDescriptor<DailyWin>())
    XCTAssertEqual(all.count, 1, "Should not insert a second entry for today")
}
```

**Test cases to cover** (from RESEARCH.md validation architecture CHAL-03, CHAL-06, CHAL-07, CHAL-10):
- `test_seedFeaturedTemplates_emptyStore_insertsThreeTemplates()` — CHAL-06
- `test_seedFeaturedTemplates_calledTwice_noduplicates()` — idempotency, CHAL-06
- `test_recordCheckIn_secondCallSameDay_throws()` — CHAL-03
- `test_recordCheckIn_booleanPayload_persists()` — CHAL-07
- `test_recordCheckIn_numericPayload_persists()` — CHAL-07
- `test_recordCheckIn_multiStepPayload_persists()` — CHAL-07
- `test_milestoneFiresAtThreshold_notTwice()` — CHAL-10; follow GoalViewModelTests milestone pattern

---

## Shared Patterns

### @Observable ViewModel Declaration
**Source:** `ViewModels/GoalViewModel.swift` lines 30-32, `ViewModels/DailyWinsViewModel.swift` lines 27-29
**Apply to:** `ChallengeViewModel.swift`
```swift
@MainActor
@Observable
final class ChallengeViewModel {
```

### @State ViewModel Instantiation in Views
**Source:** `Views/DailyWinsView.swift` line 13, `Views/GoalListView.swift` line 12
**Apply to:** `ChallengeDiscoveryView`, `ChallengeDetailView`, `ChallengeCheckInView`
```swift
@State private var viewModel = ChallengeViewModel()
```
No `@StateObject`, no `@EnvironmentObject`.

### Calendar.current.startOfDay (DST-safe date arithmetic)
**Source:** `Services/StreakEngine.swift` lines 38-45, `ViewModels/DailyWinsViewModel.swift` lines 53-54
**Apply to:** `ChallengeStreakEngine.swift`, `ChallengeViewModel.todayCheckIn()`
```swift
let today = Calendar.current.startOfDay(for: Date())
guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else { return nil }
```
Never use raw `TimeInterval` for day comparisons. Always `startOfDay`.

### Remove-Before-Add Notification Scheduling
**Source:** `Services/NotificationScheduler.swift` lines 53-56, 141-143
**Apply to:** `NotificationScheduler.scheduleChallengeReminder()` extension
```swift
center.removePendingNotificationRequests(withIdentifiers: [identifier])
// Then add new request
```

### Error Logging Pattern
**Source:** `Services/NotificationScheduler.swift` lines 73-77
**Apply to:** All `try await center.add(request)` calls in the challenge notification extension
```swift
do {
    try await center.add(request)
} catch {
    #if DEBUG
    print("[NotificationScheduler] <context>: \(error)")
    #endif
}
```

### (try? context.fetch(...)) ?? [] FetchDescriptor Pattern
**Source:** `ViewModels/DailyWinsViewModel.swift` line 60, `ViewModels/GoalViewModel.swift` line 181
**Apply to:** `ChallengeViewModel.seedFeaturedTemplates()`, `ChallengeViewModel.todayCheckIn()`
```swift
let all = (try? context.fetch(descriptor)) ?? []
```
Never `try!`. Always fall back to empty array on fetch failure.

### InputSanitizer for User Text
**Source:** `Services/InputSanitizer.swift` `sanitize(_:)` static method
**Apply to:** `ChallengeCheckInView` payloadNote field (multi-step check-in), max 500 chars
```swift
let cleanNote = InputSanitizer.sanitize(rawNote)
guard cleanNote.count <= 500 else { throw CheckInError.noteTooLong }
```

### In-Memory Test Container
**Source:** `VitaminGTests/StreakEngineTests.swift` lines 10-18, `VitaminGTests/DailyWinsViewModelTests.swift` lines 10-16
**Apply to:** All Phase 13 test files
```swift
override func setUp() async throws {
    container = try ModelContainerFactory.makeContainer(inMemory: true)
    context = container.mainContext  // or: context = ModelContext(container)
}
```

### VGTheme and Brand Colors
**Source:** `VGTheme.swift` (shared design tokens), `Views/GoalListView.swift` LinearGradient usage
**Apply to:** `MilestoneCelebrationView`, `StreakChainView` (accentColor from template), `ChallengeDiscoveryView` (featured card gradient)

---

## No Analog Found

All Phase 13 files have usable analogs from the existing codebase. No files require falling back to RESEARCH.md-only patterns. The RESEARCH.md patterns (especially Patterns 1-10) were themselves derived from the existing codebase and align precisely with the analogs identified here.

---

## Metadata

**Analog search scope:** `VitaminG/VitaminG/VitaminG/` (all subdirectories), `VitaminG/VitaminG/VitaminGTests/`
**Files scanned:** 53 Swift source files
**Pattern extraction date:** 2026-05-05
