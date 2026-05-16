# Phase 13: Challenge Platform — Core Engine - Research

**Researched:** 2026-05-04
**Domain:** SwiftData schema migration (SchemaV4), configurable challenge engine, streak computation, notification scheduling, SwiftUI navigation
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Featured ChallengeTemplate instances defined as Swift static constants — no JSON decoding, no file I/O. Type-safe, zero new dependency patterns.
- **D-02:** Seeding lives in `ChallengeViewModel.seedFeaturedTemplates()`, called on ViewModel init. Idempotent (checks SwiftData before inserting). Follows GoalViewModel pattern.
- **D-03:** UserChallenge and CheckIn records sync via CloudKit private DB normally. Template definitions are local constants only — no catalog sync.
- **D-04:** 5th "Challenges" tab added to ContentView TabView. Tab order: Goals · Stats · Wins · Challenges · Profile. Tab icon: `flame.fill`. Discovery is the tab root.
- **D-05:** Two new AppRoute cases: `challengeDetail(UserChallenge)` and `challengeCheckIn(UserChallenge)`. Both pushed from Challenges tab NavigationStack.
- **D-06:** `AppRoute.challengeCheckIn` is the notification deep-link destination — evening reminder carries `UserChallenge.id` in payload, resolved to check-in modal on tap.
- **D-07:** Evening reminder → tap → opens directly to check-in modal (`challengeCheckIn` route). Uses existing DeepLinkParser/Builder infrastructure extended with challenge-specific URL scheme.
- **D-08:** Per-challenge reminder time picker in challenge detail view (not global SettingsView). Each UserChallenge stores `reminderHour: Int?` and `reminderMinute: Int?`. Notification identifier: `com.kyleharrington.VitaminG.challengeReminder.\(userChallengeID)`. Remove-before-add pattern.
- **D-09:** New `StreakChainView` — horizontal scrollable row of day circles (past 30 days). Filled = checked in; outlined = missed; today highlighted. Accent color from template. NOT HeatmapView.
- **D-10:** StreakChainView appears in challenge detail view, below the active check-in CTA.
- **SchemaV4 naming:** Context file calls it SchemaV4 (Phase 11 added SchemaV3 for DailyWin). The roadmap says "SchemaV3" but that's stale — V4 is correct.

### Claude's Discretion

- Exact size of day-dot circles in StreakChainView (recommended: 20pt diameter, 2pt stroke for outlined, solid for filled)
- Whether progress bar toward goal value sits above or below StreakChainView in detail layout
- SF Symbol for milestone celebration badge at different thresholds (e.g., `flame.fill` at 7-day, `trophy.fill` at 30-day)
- Animation curve for confetti full-screen celebration (CHAL-10) — `withAnimation(.spring)` recommended

### Deferred Ideas (OUT OF SCOPE)

- $2 subscription tier with profile photo frames — future phase post Phase 14
- Community feed, reactions, profanity filter — Phase 14
- Optional modules (Spending Freeze, Craving Tools, Transformation Photos, Nutrition Log, Buddy Accountability) — Phase 14
- Custom challenge builder — Phase 14
- Full notification suite (streak-at-risk, milestone reached, reaction received, buddy ping) — Phase 14
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CHAL-01 | ChallengeTemplate SwiftData model (SchemaV4) — id, title, description, category, type (featured/custom), check_in_type (boolean/numeric/photo/multi-step), goal_type (streak/target/date-bound), duration, milestones array, accent color, icon, featured flag + active date range | SchemaV4 pattern from SchemaV3; all properties optional or defaulted for CloudKit |
| CHAL-02 | UserChallenge model — links user to template with start date, target end date, current streak, longest streak, total check-ins, status (active/completed/abandoned), and milestone history | SwiftData @Model pattern from SchemaV2/V3; optional relationship to ChallengeTemplate |
| CHAL-03 | CheckIn model — challenge instance ID, date, type-specific payload (boolean/number/note/photo), timestamp; one per day per challenge enforced | DailyWinsViewModel.todayEntry() pattern for day-boundary enforcement |
| CHAL-04 | SchemaV4 migration adds ChallengeTemplate, UserChallenge, CheckIn without data loss | Lightweight migration — additive-only; update VitaminGMigrationPlan.swift |
| CHAL-05 | Challenge engine computes streak correctly across midnight and DST transitions; missed check-in breaks streak; longest streak tracked | StreakEngine.swift pattern; Calendar.current.startOfDay |
| CHAL-06 | Three featured challenges seeded via template system: 90-Day Summer Body (fitness/multi-step), Save $5,000 (finance/numeric), Dry Summer (sobriety/boolean) | Static constants in ChallengeViewModel; seedFeaturedTemplates() pattern |
| CHAL-07 | Adding a new challenge type requires zero new core engine logic — all behavior driven by template config | Engine reads check_in_type/goal_type at runtime; no switch statements on type in engine layer |
| CHAL-08 | Discovery screen shows Featured Challenges, category browse, "Build Your Own" CTA | SwiftUI LazyVStack + ScrollView; @Query for UserChallenge join |
| CHAL-09 | Daily check-in flow adapts to check_in_type from template (boolean/numeric/multi-step) with no type-specific branching in engine layer | ViewModifier or ViewBuilder switch on check_in_type is allowed in View layer only; engine layer is type-blind |
| CHAL-10 | Milestone array from template triggers full-screen celebration (confetti + personalized message + milestone badge saved to profile) | fullScreenCover modifier; pendingMilestone pattern from GoalViewModel |
| CHAL-11 | Progress tracking: StreakChainView (day dots), progress bar toward goal value, prominent day counter for sobriety-type challenges | New StreakChainView component (D-09); similar to ProgressRingView composition pattern |
| CHAL-12 | Evening check-in reminder notification fires per-challenge at user-set time if no check-in logged that day | NotificationScheduler per-challenge extension; UNCalendarNotificationTrigger |
</phase_requirements>

---

## Summary

Phase 13 introduces a configurable challenge engine on top of SchemaV4 — three new SwiftData models (ChallengeTemplate, UserChallenge, CheckIn), a ChallengeViewModel, a StreakChainView component, and the full Challenges tab (discovery, detail, check-in modal). The phase's defining architectural constraint is that the engine layer must be completely type-blind: `check_in_type` and `goal_type` fields on the template drive all behavior without any `switch` or `if/else` branching in the engine itself. The engine reads template config and applies it; type-specific rendering is allowed only in the View layer.

All patterns needed to build Phase 13 exist in the codebase today. SchemaV4 follows the SchemaV3 pattern exactly: an enum implementing `VersionedSchema`, three new `@Model` classes, a lightweight migration stage added to `VitaminGMigrationPlan`, and updated `ModelContainerFactory`. Streak computation follows `StreakEngine` exactly — `Calendar.current.startOfDay` for DST safety, a `Set<Date>` for O(1) day lookups. Notification scheduling follows the existing `NotificationScheduler` per-identifier pattern extended for per-challenge identifiers. The milestone celebration follows the `pendingMilestone` / `fullScreenCover` pattern already in `GoalViewModel` / `GoalListView`, elevated to a full-screen confetti overlay.

The one architectural novelty is the multi-step check-in type — it requires a lightweight wizard UI (2-3 steps) but no new engine concepts. All steps collect payloads that are serialized into the `CheckIn` model's payload field; the engine never inspects step count.

**Primary recommendation:** Build in this order: (1) SchemaV4 models + migration, (2) ChallengeViewModel with streak engine + seeding, (3) CheckInEngine (one-per-day enforcement, streak update), (4) Challenges tab navigation wiring, (5) Discovery + Detail UI, (6) Check-in modal (all 3 types), (7) StreakChainView, (8) Milestone celebration, (9) Evening reminder notifications.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| ChallengeTemplate / UserChallenge / CheckIn persistence | SwiftData model layer | CloudKit (private DB) | Data models; engine reads arrays, never queries directly |
| Featured challenge seeding | ChallengeViewModel (init) | — | Follows GoalViewModel pattern; idempotent, model-context-aware |
| Streak computation | ChallengeStreakEngine (pure struct) | ChallengeViewModel (coordinator) | Zero SwiftUI/SwiftData dependency; injectable Calendar; unit-testable |
| One-check-in-per-day enforcement | ChallengeViewModel (mutation method) | View layer (disabled CTA) | Business rule belongs in VM, not in View |
| Milestone detection | ChallengeViewModel (after check-in) | — | Follows GoalViewModel.pendingMilestone pattern |
| Check-in type rendering | View layer (ChallengeCheckInView) | — | Type-specific UI is View concern; engine is type-blind |
| Discovery screen data | View layer (@Query on ChallengeTemplate) | ChallengeViewModel (join/filter) | @Query in View; VM provides joinedData, joinedCommunitySize |
| Evening reminder scheduling | NotificationScheduler (extended) | ChallengeViewModel (triggers schedule) | Extends existing scheduler; per-challenge identifier |
| Deep-link routing (notification tap) | DeepLinkParser/Builder (extended) | AppRouter (pendingChallengeCheckInID) | Follows existing profile deep-link pattern |
| Challenges tab navigation | ContentView (TabView) + AppRouter | AppRoute (two new cases) | Same pattern as Wins/Profile tabs |
| StreakChainView rendering | StreakChainView (component) | ChallengeDetailView (host) | Pure display component; takes [Date] of check-ins |
| Milestone celebration overlay | FullScreen overlay in ChallengeDetailView/tab | — | fullScreenCover .sheet; confetti + badge |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftData | iOS 17+ | ChallengeTemplate, UserChallenge, CheckIn models | Project standard since Phase 1 |
| SwiftUI | iOS 17+ | All UI: Discovery, Detail, CheckIn modal, StreakChainView | Project standard; widget-native |
| UserNotifications | iOS 10+ | Per-challenge evening reminder | Used by existing NotificationScheduler |
| Observation (`@Observable`) | iOS 17+ | ChallengeViewModel MVVM pattern | Project standard since Phase 1 |
| Foundation (`Calendar`, `DateComponents`) | iOS 17+ | DST-safe streak arithmetic | StreakEngine pattern |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| XCTest | N/A | Unit tests for ChallengeStreakEngine, ChallengeViewModel | All pure-struct/VM logic needs coverage |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Static Swift constants for templates | JSON file bundled in app | JSON adds decoding complexity, file I/O, no type safety — D-01 locks this to Swift constants |
| Per-challenge UserDefaults for reminder times | reminderHour/reminderMinute on UserChallenge model | Model storage is simpler, syncs via CloudKit naturally, avoids UserDefaults key explosion |

**No third-party dependencies.** PROJECT.md and CLAUDE.md both prohibit external dependencies unless absolutely necessary. Nothing in Phase 13 requires them.

---

## Architecture Patterns

### System Architecture Diagram

```
User Action
     |
     v
ChallengeDiscoveryView  ─── @Query ──> [ChallengeTemplate]
     |                       @Query ──> [UserChallenge]
     | (tap Join / tap card)
     v
ChallengeViewModel.joinChallenge(template:context:)
     |─── inserts UserChallenge ──> SwiftData
     |─── schedules reminder ──> NotificationScheduler.scheduleChallengeReminder()
     v
AppRoute.challengeDetail(userChallenge)
     |
     v
ChallengeDetailView
     |─── StreakChainView(checkIns: [Date], accentColor:)
     |─── ProgressSection (bar toward goal value OR day counter)
     |─── ReminderTimePicker ──> ChallengeViewModel.updateReminder()
     |─── Check-in CTA ──────> AppRoute.challengeCheckIn(userChallenge)
     |
     v
ChallengeCheckInView (modal, .sheet)
     |─── template.checkInType == .boolean ──> BooleanCheckInView
     |─── template.checkInType == .numeric ──> NumericCheckInView
     |─── template.checkInType == .multiStep ──> MultiStepCheckInView
     |
     | (submit)
     v
ChallengeViewModel.recordCheckIn(for:payload:context:)
     |─── enforces one-per-day (todayCheckIn guard)
     |─── inserts CheckIn ──> SwiftData
     |─── ChallengeStreakEngine.updateStreak()
     |─── checks milestone thresholds ──> pendingMilestone?
     |
     v
[if milestone]
MilestoneCelebrationView (.fullScreenCover)
     |─── confetti animation
     |─── badge saved to UserChallenge.milestoneHistory

Notification tap ─> DeepLinkParser.challengeCheckInID(from:)
     |─> AppRouter.pendingChallengeCheckInID = id
     |─> ContentView resolves ──> .sheet(challengeCheckIn(userChallenge))
```

### Recommended Project Structure

```
VitaminG/
├── Models/
│   ├── SchemaV4.swift               # ChallengeTemplate, UserChallenge, CheckIn
│   └── VitaminGMigrationPlan.swift  # Add migrateV3toV4 stage (UPDATED)
├── ViewModels/
│   └── ChallengeViewModel.swift     # @Observable, seeding, CRUD, streak coordinator
├── Services/
│   ├── ChallengeStreakEngine.swift   # Pure struct, DST-safe, injectable Calendar
│   ├── NotificationScheduler.swift  # EXTENDED: scheduleChallengeReminder()
│   ├── DeepLinkBuilder.swift        # EXTENDED: challenge check-in URL
│   └── DeepLinkParser.swift         # EXTENDED: parse challenge check-in URL
├── Navigation/
│   ├── AppRoute.swift               # EXTENDED: challengeDetail, challengeCheckIn
│   └── AppRouter.swift              # EXTENDED: pendingChallengeCheckInID
├── Views/
│   ├── ContentView.swift            # EXTENDED: 5th Challenges tab
│   ├── ChallengeDiscoveryView.swift # Featured cards, category browse, "Build Your Own" CTA
│   ├── ChallengeDetailView.swift    # Detail, StreakChainView, check-in CTA, reminder picker
│   ├── ChallengeCheckInView.swift   # Adaptive check-in modal (boolean/numeric/multi-step)
│   ├── MilestoneCelebrationView.swift  # Full-screen confetti + badge
│   └── Components/
│       └── StreakChainView.swift    # Horizontal day-dot component (30 days)
└── VitaminGTests/
    ├── ChallengeStreakEngineTests.swift
    └── ChallengeViewModelTests.swift
```

### Pattern 1: SchemaV4 VersionedSchema

Add three `@Model` classes inside `enum SchemaV4: VersionedSchema`. All prior-version models are referenced, not redeclared.

```swift
// Source: [VERIFIED: existing SchemaV3.swift pattern]
enum SchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        // V3 models unchanged + 3 new models
        [SchemaV2.Goal.self, SchemaV2.CompletionEvent.self,
         SchemaV2.UserProfile.self, SchemaV3.DailyWin.self,
         SchemaV4.ChallengeTemplate.self,
         SchemaV4.UserChallenge.self,
         SchemaV4.CheckIn.self]
    }

    @Model final class ChallengeTemplate {
        var id: UUID = UUID()
        var title: String?
        var challengeDescription: String?
        var category: String?               // "fitness", "finance", "sobriety"
        var challengeType: String?          // "featured" | "custom"
        var checkInType: String?            // "boolean" | "numeric" | "multiStep"
        var goalType: String?               // "streak" | "target" | "dateBound"
        var durationDays: Int?
        var milestonesJSON: String?         // JSON-encoded [MilestoneConfig] — see Pattern 4
        var accentColorHex: String?
        var iconName: String?
        var isFeatured: Bool = false
        var activeFrom: Date?
        var activeUntil: Date?
        var communitySize: Int = 0          // seeded value, not live count in Phase 13

        @Relationship(deleteRule: .nullify, inverse: \UserChallenge.template)
        var userChallenges: [UserChallenge]?

        init() {}
    }

    @Model final class UserChallenge {
        var id: UUID = UUID()
        var startDate: Date?
        var targetEndDate: Date?
        var currentStreak: Int = 0
        var longestStreak: Int = 0
        var totalCheckIns: Int = 0
        var statusRaw: String?              // "active" | "completed" | "abandoned"
        var milestoneHistoryJSON: String?   // JSON-encoded [Int] — thresholds already awarded
        var reminderHour: Int?
        var reminderMinute: Int?

        var template: ChallengeTemplate?

        @Relationship(deleteRule: .cascade, inverse: \CheckIn.userChallenge)
        var checkIns: [CheckIn]?

        init() {}
    }

    @Model final class CheckIn {
        var id: UUID = UUID()
        var date: Date?
        var payloadBool: Bool?
        var payloadNumber: Double?
        var payloadNote: String?
        var timestamp: Date?

        var userChallenge: UserChallenge?

        init() {}
    }
}

typealias ChallengeTemplate = SchemaV4.ChallengeTemplate
typealias UserChallenge = SchemaV4.UserChallenge
typealias CheckIn = SchemaV4.CheckIn
```

**CloudKit constraint:** All properties must be optional or have default values. No `@Attribute(.unique)`. `@Relationship` inverse must be declared on both ends.

### Pattern 2: Lightweight Migration V3 → V4

```swift
// Source: [VERIFIED: existing VitaminGMigrationPlan.swift pattern]
// In VitaminGMigrationPlan.swift — update schemas array AND stages array:

static var schemas: [any VersionedSchema.Type] {
    [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self]  // ADD SchemaV4
}

static var stages: [MigrationStage] {
    [migrateV1toV2, migrateV2toV3, migrateV3toV4]  // ADD stage
}

static let migrateV3toV4 = MigrationStage.lightweight(
    fromVersion: SchemaV3.self,
    toVersion: SchemaV4.self
)
```

V3 → V4 is purely additive (3 new models, no changes to existing models) — lightweight migration is correct. No custom stage needed.

### Pattern 3: ChallengeViewModel — Seeding + Structure

```swift
// Source: [VERIFIED: existing DailyWinsViewModel.swift + GoalViewModel.swift patterns]
@MainActor
@Observable
final class ChallengeViewModel {

    var pendingMilestone: (challengeID: UUID, threshold: Int)? = nil
    private var firedMilestones: Set<String> = []

    // MARK: - Seeding (D-02, CHAL-06)
    func seedFeaturedTemplates(context: ModelContext) {
        // Fetch existing featured templates to guard idempotency
        let descriptor = FetchDescriptor<ChallengeTemplate>(
            predicate: #Predicate { $0.isFeatured == true }
        )
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for template in ChallengeTemplate.featuredTemplates {
            context.insert(template)
        }
    }

    // MARK: - One-per-day enforcement (CHAL-03)
    func todayCheckIn(for challenge: UserChallenge, context: ModelContext) -> CheckIn? {
        let today = Calendar.current.startOfDay(for: Date())
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
            return nil
        }
        let id = challenge.id
        let descriptor = FetchDescriptor<CheckIn>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.first { ci in
            guard ci.userChallenge?.id == id, let d = ci.date else { return false }
            return d >= today && d < tomorrow
        }
    }

    // MARK: - Record check-in (CHAL-03, CHAL-05, CHAL-10)
    func recordCheckIn(for challenge: UserChallenge,
                       payload: CheckInPayload,
                       context: ModelContext) throws {
        guard todayCheckIn(for: challenge, context: context) == nil else {
            throw CheckInError.alreadyCheckedInToday
        }
        let checkIn = CheckIn()
        checkIn.date = Date()
        checkIn.timestamp = Date()
        payload.apply(to: checkIn)
        checkIn.userChallenge = challenge
        context.insert(checkIn)

        challenge.totalCheckIns += 1
        // Fetch all check-in dates for this challenge for streak computation
        let dates = (challenge.checkIns ?? []).compactMap { $0.date }
        challenge.currentStreak = ChallengeStreakEngine.currentStreak(from: dates)
        challenge.longestStreak = max(challenge.longestStreak, challenge.currentStreak)

        // Milestone detection (CHAL-10)
        if let threshold = milestoneJustCrossed(
            count: challenge.totalCheckIns,
            firedSet: firedMilestones,
            challengeID: challenge.id
        ) {
            pendingMilestone = (challengeID: challenge.id, threshold: threshold)
            firedMilestones.insert("\(challenge.id.uuidString)-\(threshold)")
        }
    }
}
```

### Pattern 4: MilestoneConfig — Stored as JSON String

CloudKit does not support SwiftData array-of-struct properties. Store milestones as a JSON-encoded string on the model; decode at use.

```swift
// Source: [ASSUMED] — no existing milestone array on SwiftData models; need workaround for CloudKit
struct MilestoneConfig: Codable {
    let dayThreshold: Int       // e.g. 7, 30, 60, 90
    let message: String         // "One week strong!"
    let badgeSymbol: String     // SF Symbol name — "flame.fill", "trophy.fill"
}

extension ChallengeTemplate {
    var milestones: [MilestoneConfig] {
        guard let json = milestonesJSON,
              let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([MilestoneConfig].self, from: data)
        else { return [] }
        return decoded
    }
}
```

**Why JSON string:** SwiftData with CloudKit sync does not support non-`@Model` embedded types as stored arrays. A JSON string on a `String?` property satisfies CloudKit's attribute constraints. Decoding is O(n) on a small array (max ~5 milestones per challenge).

### Pattern 5: ChallengeStreakEngine (pure struct)

Identical to `StreakEngine` but operates on `[Date]` (check-in dates) rather than `[CompletionEvent]`.

```swift
// Source: [VERIFIED: existing StreakEngine.swift pattern — direct adaptation]
struct ChallengeStreakEngine {
    static func currentStreak(
        from checkInDates: [Date],
        calendar: Calendar = .current
    ) -> Int {
        let days = Set(checkInDates.compactMap { calendar.startOfDay(for: $0) })
        guard !days.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        var candidate = days.contains(today) ? today
            : calendar.date(byAdding: .day, value: -1, to: today) ?? today

        var streak = 0
        while days.contains(candidate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: candidate) else { break }
            candidate = prev
        }
        return streak
    }

    static func longestStreak(from checkInDates: [Date], calendar: Calendar = .current) -> Int {
        let sorted = checkInDates
            .compactMap { calendar.startOfDay(for: $0) }
            .sorted()
        guard !sorted.isEmpty else { return 0 }

        var best = 1
        var current = 1
        for i in 1..<sorted.count {
            guard let prev = calendar.date(byAdding: .day, value: 1, to: sorted[i-1]) else { continue }
            if sorted[i] == prev {
                current += 1
                best = max(best, current)
            } else if sorted[i] != sorted[i-1] {
                current = 1
            }
        }
        return best
    }
}
```

### Pattern 6: Per-Challenge Notification (CHAL-12)

```swift
// Source: [VERIFIED: existing NotificationScheduler.swift pattern]
// Extension on NotificationScheduler:

extension NotificationScheduler {
    static func challengeReminderIdentifier(for challengeID: UUID) -> String {
        "com.kyleharrington.VitaminG.challengeReminder.\(challengeID.uuidString)"
    }

    func scheduleChallengeReminder(
        for challenge: UserChallenge,
        hour: Int,
        minute: Int
    ) async {
        guard let id = challenge.id as UUID? else { return }
        let identifier = Self.challengeReminderIdentifier(for: id)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let validHour   = max(0, min(23, hour))
        let validMinute = max(0, min(59, minute))

        let content = UNMutableNotificationContent()
        content.title = "Check in on your challenge"
        content.body = challenge.template?.title ?? "Daily check-in reminder"
        content.sound = .default
        content.userInfo = [
            "deepLink": "challengeCheckIn",
            "userChallengeID": id.uuidString
        ]

        var components = DateComponents()
        components.hour   = validHour
        components.minute = validMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        do {
            try await center.add(request)
        } catch {
            #if DEBUG
            print("[NotificationScheduler] Failed to add challenge reminder: \(error)")
            #endif
        }
    }

    func removeChallengeReminder(for challengeID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [Self.challengeReminderIdentifier(for: challengeID)]
            )
    }
}
```

**iOS 64-request cap:** Phase 13 adds up to N per-challenge reminders (where N = number of active challenges) plus 1 goal reminder + 1 win reminder. If a user joins all 3 featured challenges that's 5 total pending notifications — well within the 64 cap. Even with future custom challenges, the cap is not a concern in Phase 13.

### Pattern 7: Deep-Link Extension for Challenge Check-In (D-07, CHAL-12)

```swift
// Source: [VERIFIED: existing DeepLinkBuilder.swift + DeepLinkParser.swift patterns]

// DeepLinkBuilder extension:
extension DeepLinkBuilder {
    // vitaming://challengeCheckIn/<userChallengeID>
    static func challengeCheckInURL(userChallengeID: UUID) -> URL? {
        URL(string: "\(scheme)://challengeCheckIn/\(userChallengeID.uuidString)")
    }
}

// DeepLinkParser extension:
extension DeepLinkParser {
    static func challengeCheckInID(from url: URL) -> String? {
        guard url.scheme == DeepLinkBuilder.scheme,
              url.host == "challengeCheckIn",
              let id = url.pathComponents.dropFirst().first,
              !id.isEmpty else { return nil }
        return id
    }
}
```

### Pattern 8: StreakChainView Component

```swift
// Source: [VERIFIED: existing ProgressRingView.swift composition pattern + D-09]
// Day dot pattern from CONTEXT.md: ● ○ ● ● ● ● ● ○ ● ● ●
struct StreakChainView: View {
    let checkInDates: Set<Date>     // startOfDay values
    let accentColor: Color
    let dayCount: Int = 30

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var days: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        return (0..<dayCount).compactMap {
            Calendar.current.date(byAdding: .day, value: -($0), to: today)
        }.reversed()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(days, id: \.self) { day in
                    let isToday = Calendar.current.isDateInToday(day)
                    let checkedIn = checkInDates.contains(day)
                    Circle()
                        .fill(checkedIn ? accentColor : Color.clear)
                        .stroke(
                            isToday ? accentColor : accentColor.opacity(0.4),
                            lineWidth: isToday ? 2 : 1
                        )
                        .frame(width: 20, height: 20)  // 20pt diameter (Claude's discretion)
                }
            }
            .padding(.horizontal)
        }
        .accessibilityLabel("Streak chain: \(checkInDates.count) check-ins in the last 30 days")
    }
}
```

### Pattern 9: Milestone Celebration — fullScreenCover

The Phase 12 milestone pattern uses an inline overlay on the goal row. Phase 13 requires a full-screen celebration (CHAL-10). Use `.fullScreenCover`:

```swift
// Source: [VERIFIED: GoalViewModel.pendingMilestone pattern + CHAL-10 requirement]
// In ChallengeDetailView or the Challenges tab root:
.fullScreenCover(isPresented: $showMilestoneCelebration) {
    MilestoneCelebrationView(
        milestone: currentMilestone,
        challengeTitle: userChallenge.template?.title ?? "Challenge"
    ) {
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

**MilestoneCelebrationView:** Confetti layer (SwiftUI `TimelineView` or canvas-based particle effect — no third-party library), personalized message from `MilestoneConfig.message`, badge symbol from `MilestoneConfig.badgeSymbol` (SF Symbol rendered large), and dismiss button. Badge is also appended to `UserChallenge.milestoneHistoryJSON`.

### Pattern 10: Featured Template Static Constants (D-01, CHAL-06)

```swift
// Source: [VERIFIED: D-01 in CONTEXT.md — static constants, no JSON]
extension ChallengeTemplate {
    static var featuredTemplates: [ChallengeTemplate] {
        [summerBodyTemplate, save5000Template, drySummerTemplate]
    }

    static var summerBodyTemplate: ChallengeTemplate {
        let t = ChallengeTemplate()
        t.title = "90-Day Summer Body"
        t.challengeDescription = "Transform your fitness over 90 days with daily movement check-ins."
        t.category = "fitness"
        t.challengeType = "featured"
        t.checkInType = "multiStep"
        t.goalType = "streak"
        t.durationDays = 90
        t.accentColorHex = "#FF6B4A"  // warm orange
        t.iconName = "figure.run"
        t.isFeatured = true
        t.communitySize = 1240
        t.milestonesJSON = Self.encodedMilestones([
            MilestoneConfig(dayThreshold: 7, message: "One week strong!", badgeSymbol: "flame.fill"),
            MilestoneConfig(dayThreshold: 30, message: "A whole month! Keep going.", badgeSymbol: "trophy.fill"),
            MilestoneConfig(dayThreshold: 90, message: "You did it! 90 days!", badgeSymbol: "star.fill")
        ])
        return t
    }

    // save5000Template: checkInType = "numeric", goalType = "target" (target: 5000)
    // drySummerTemplate: checkInType = "boolean", goalType = "streak"
}
```

### Anti-Patterns to Avoid

- **Engine-layer type switching:** Never put `switch template.checkInType` in `ChallengeViewModel` or `ChallengeStreakEngine`. Type-specific logic belongs in `ChallengeCheckInView` only. CHAL-07 requires zero new core logic per type.
- **Hardcoded challenge data:** Never create a `SummerBodyCheckIn` subclass or `FitnessChallenge` model. The engine must work identically for all 3 featured types.
- **Raw TimeInterval for day arithmetic:** Never `date.timeIntervalSince` for streak computation. Always `Calendar.current.startOfDay`. CHAL-05 requires DST safety.
- **Duplicate schema model declarations:** New models go inside `SchemaV4` enum only. Prior models (Goal, CompletionEvent, UserProfile, DailyWin) are referenced from their original schemas in `SchemaV4.models`, not redeclared.
- **`@Attribute(.unique)` on any new model property:** CloudKit does not support this. Uniqueness enforced at ViewModel layer (idempotent seeding guard).
- **Non-optional properties without defaults on SwiftData models:** Every new model property must be `var foo: Type?` or `var foo: Type = default`. CloudKit requires this.
- **Notification scheduling in View layer:** All `NotificationScheduler` calls belong in `ChallengeViewModel`, not in `ChallengeDetailView`.
- **@Query inside ViewModels:** Never put `@Query` inside ChallengeViewModel. VM receives arrays, @Query lives in Views. This matches the GoalViewModel / StatsViewModel pattern and is required for testability.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DST-safe date arithmetic | Raw `timeIntervalSince` for streak | `Calendar.current.startOfDay` | DST boundary causes raw interval to be wrong |
| Per-challenge notification identifier | Custom string scheme | `"com.kyleharrington.VitaminG.challengeReminder.\(id)"` | Existing identifier scheme in NotificationScheduler |
| Confetti particle system | Custom SpriteKit scene | SwiftUI canvas + TimelineView particles | No third-party deps; simple confetti is achievable without SpriteKit |
| Milestone array persistence | Core Data transformable | JSON-encoded String on SwiftData model | CloudKit only supports primitive + Date + UUID + String + Data attributes |
| Day-dot calendar grid | HeatmapView (existing) | StreakChainView (new horizontal component) | Heatmap is semantically different (density grid vs. chain); D-09 requires the new component |
| Template catalog sync | CloudKit public DB | Swift static constants + no sync | D-03 locks this; catalog sync is Phase 14+ community concern |

**Key insight:** The configurable engine is itself the "don't hand-roll" insight — the template config system means no hand-rolling per-type logic for future challenge types.

---

## Common Pitfalls

### Pitfall 1: SchemaV4 ModelContainerFactory Update Forgotten

**What goes wrong:** App launches, SwiftData sees schema with 3 new model types not in the configured schema — crash or silent data loss.
**Why it happens:** `ModelContainerFactory.makeContainer()` still references `SchemaV3.models`. The migration plan is updated but the container factory is not.
**How to avoid:** Update `ModelContainerFactory` to use `Schema(SchemaV4.models, version: SchemaV4.versionIdentifier)` and pass `VitaminGMigrationPlan.self` (which now includes the V3→V4 stage). Also update `makeWidgetContainer()` to include the new schema, even though widget doesn't write challenge data.
**Warning signs:** `ModelContainer` init crash at launch with "migration required" or "unrecognized store" error.

### Pitfall 2: Widget Container Schema Mismatch

**What goes wrong:** Widget crashes silently or returns stale data after SchemaV4 migration.
**Why it happens:** `makeWidgetContainer()` still uses SchemaV3 schema — mismatch with the migrated store on disk.
**How to avoid:** Both `makeContainer()` and `makeWidgetContainer()` must use the same `SchemaV4.models` and `VitaminGMigrationPlan`. The widget does not need to query ChallengeTemplate/UserChallenge in Phase 13, but it must open the store with the correct schema.
**Warning signs:** Widget shows blank data after first app launch post-migration.

### Pitfall 3: CloudKit Schema Initialized Before New Models Are Registered

**What goes wrong:** CloudKit does not sync `UserChallenge` or `CheckIn` records — properties appear to write locally but never upload.
**Why it happens:** `initializeCloudKitSchema()` in `ModelContainerFactory` (DEBUG only) references the old model list. New models must be added to the `NSManagedObjectModel.makeManagedObjectModel(for:)` call.
**How to avoid:** Add `ChallengeTemplate.self`, `UserChallenge.self`, `CheckIn.self` to the `makeManagedObjectModel` call in the debug extension.
**Warning signs:** CloudKit console does not show new record types after first run in DEBUG.

### Pitfall 4: Seeding Runs on Every ChallengeViewModel Init

**What goes wrong:** Duplicate featured templates appear in the database — user sees 6 or 9 featured challenges.
**Why it happens:** `seedFeaturedTemplates()` is called on every ViewModel init without checking for existing records.
**How to avoid:** `seedFeaturedTemplates()` MUST begin with a SwiftData fetch for `isFeatured == true` templates. If any exist, return immediately without inserting. This is the idempotency guard specified in D-02.
**Warning signs:** Discovery screen shows duplicate featured challenge cards.

### Pitfall 5: One-Per-Day Check-In Using `Date()` Equality

**What goes wrong:** A check-in at 11:55 PM and one at 12:05 AM (next day) are compared with raw `Date` equality — the 12:05 AM check-in is not recognized as a new day.
**Why it happens:** Using `Date()` or `timeIntervalSince` instead of `Calendar.current.startOfDay`.
**How to avoid:** `todayCheckIn(for:context:)` must use `Calendar.current.startOfDay(for: Date())` as lower bound and compute the next day as upper bound — identical to `DailyWinsViewModel.todayEntry(context:)`.
**Warning signs:** Users can't check in after midnight even though it's a new calendar day.

### Pitfall 6: iOS 64 Notification Request Cap Overflow (Future-Proofing)

**What goes wrong:** If a user joins many challenges in Phase 14+ with custom reminders, the cap is hit — new notifications silently fail to schedule.
**Why it happens:** Each active `UserChallenge` with a reminder adds 1 request. The existing 2 requests (goal + win reminder) reduce the available slots.
**How to avoid:** In Phase 13, the 3 featured challenges = 3 challenge reminders + 1 goal + 1 win = 5 total. Well within cap. Document the running tally so Phase 14 planners are aware. The remove-before-add pattern (D-08) ensures no leakage from abandoned challenges.
**Warning signs:** `UNUserNotificationCenter.getPendingNotificationRequests` returns exactly 64 items — all new adds silently fail.

### Pitfall 7: SwiftData Relationship Without Inverse Declaration

**What goes wrong:** SwiftData crash or data corruption — the relationship between `ChallengeTemplate` and `UserChallenge`, or between `UserChallenge` and `CheckIn`, silently breaks.
**Why it happens:** `@Relationship` on one side without declaring the inverse on the other side.
**How to avoid:** `ChallengeTemplate.userChallenges` must declare `inverse: \UserChallenge.template`; `UserChallenge.checkIns` must declare `inverse: \CheckIn.userChallenge`. Both sides of every relationship must be declared.
**Warning signs:** SwiftData relationship returns nil even after insert.

### Pitfall 8: Type-Specific Branching in Engine Layer (CHAL-07 Violation)

**What goes wrong:** `ChallengeViewModel.recordCheckIn` contains `if checkInType == "multiStep" { ... }` — adding a 4th check-in type requires modifying the engine.
**Why it happens:** Convenience — it's tempting to special-case multi-step in the VM because it has more payload fields.
**How to avoid:** The VM accepts a `CheckInPayload` value type that encapsulates all possible payload fields. The VM calls `payload.apply(to: checkIn)` without knowing the type. Type-specific UI lives entirely in `ChallengeCheckInView`.
**Warning signs:** Any `switch checkInType` or `if checkInType ==` in ChallengeViewModel or ChallengeStreakEngine.

---

## Code Examples

### In-Memory Test Container for Phase 13 Tests

```swift
// Source: [VERIFIED: existing StreakEngineTests.swift + DailyWinsViewModelTests.swift patterns]
// Use ModelContainerFactory.makeContainer(inMemory: true) — same as all prior tests
// After SchemaV4 is added, no change needed — factory auto-includes new models

@MainActor
final class ChallengeStreakEngineTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try ModelContainerFactory.makeContainer(inMemory: true)
        context = container.mainContext
    }

    func test_emptyCheckIns_returnsZeroStreak() {
        XCTAssertEqual(ChallengeStreakEngine.currentStreak(from: []), 0)
    }

    func test_consecutiveDays_returnsCorrectStreak() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let dayBefore = cal.date(byAdding: .day, value: -2, to: today)!
        XCTAssertEqual(
            ChallengeStreakEngine.currentStreak(from: [today, yesterday, dayBefore]), 3
        )
    }
}
```

### AppRoute Extension for Phase 13

```swift
// Source: [VERIFIED: existing AppRoute.swift pattern]
enum AppRoute: Hashable {
    // ... existing cases ...
    case challengeDetail(UserChallenge)   // Phase 13 — CHAL-08, D-05
    case challengeCheckIn(UserChallenge)  // Phase 13 — CHAL-09, D-05, D-06
}
```

`UserChallenge` must conform to `Hashable`. Since it is a SwiftData `@Model` class, it already conforms via `PersistentModel` (which provides `Identifiable` via `id`). Verify `Hashable` conformance compiles — if not, extend with `func hash(into:)` using `id`.

### CheckInPayload Value Type

```swift
// Source: [VERIFIED: pattern ensures engine-layer type-blindness per CHAL-07]
enum CheckInPayload {
    case boolean(Bool)
    case numeric(Double)
    case multiStep(note: String, numericValue: Double?)

    func apply(to checkIn: CheckIn) {
        switch self {
        case .boolean(let v):
            checkIn.payloadBool = v
        case .numeric(let v):
            checkIn.payloadNumber = v
        case .multiStep(let note, let num):
            checkIn.payloadNote = note
            checkIn.payloadNumber = num
        }
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` / `@Published` | `@Observable` macro | iOS 17 / Phase 1 | Property-level invalidation; no `@StateObject` |
| `NavigationView` | `NavigationStack` | iOS 16 / Phase 1 | Programmatic navigation via `path` array |
| `IntentConfiguration` widget | `AppIntentConfiguration` | iOS 17 / Phase 4 | N/A for Phase 13 |
| V3 schema (DailyWin) | V4 schema (+ 3 challenge models) | Phase 13 | Lightweight additive migration |

**Not deprecated in Phase 13:**
- `UNCalendarNotificationTrigger` — still the correct local notification trigger (no backend push)
- `@Query` in Views — still correct; VM receives arrays, not queries

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `PersistentModel` (SwiftData @Model class) conforms to `Hashable` automatically, enabling use as AppRoute associated value | Code Examples — AppRoute Extension | If not, must add explicit `Hashable` conformance via `func hash(into:)` using `id.hashValue` — minor fix |
| A2 | SwiftUI `fullScreenCover` can be triggered from a sibling view (ChallengeDetailView) observing ChallengeViewModel state | Pattern 9 — Milestone Celebration | If sheet/fullScreenCover nesting causes SwiftUI issues, use `@Environment(\.dismiss)` + a separate coordinator; low likelihood |
| A3 | `MilestonesJSON` (JSON-encoded string) is the correct CloudKit-compatible storage for an array of structs | Pattern 4 — MilestoneConfig | If SwiftData adds native Codable array support in iOS 18+, could switch to native; JSON workaround is safe for iOS 17 |
| A4 | communitySize on ChallengeTemplate can be a seeded static Int (not live count) in Phase 13 | Pattern 10 — Featured Template Constants | Phase 14 community features will require real counts; Phase 13 seeded value is a placeholder — confirmed by CONTEXT.md deferred list |

**If A1 is wrong:** Add `extension SchemaV4.UserChallenge: Hashable { func hash(into hasher: inout Hasher) { hasher.combine(id) } }` below the model declaration — 2 lines, zero risk.

---

## Open Questions (RESOLVED)

1. **Multi-step check-in: what are the steps for "90-Day Summer Body"?**
   - What we know: `checkInType = "multiStep"` is defined; the engine is type-blind
   - What's unclear: Are the steps fixed (e.g., "Did you work out?" + "How many minutes?") or configurable per template?
   - Recommendation: For Phase 13, hardcode 2-step for Summer Body (workout boolean + duration numeric) in the CheckInPayload construction inside `ChallengeCheckInView`. The engine accepts the `multiStep` payload regardless. Phase 14 can make steps configurable via a `stepsJSON` field on the template.

2. **"Build Your Own" CTA in Discovery: does it navigate anywhere in Phase 13?**
   - What we know: CHAL-08 requires the CTA to exist; custom challenge builder is deferred to Phase 14 (D in CONTEXT.md)
   - What's unclear: Does tapping it do nothing, show a "Coming Soon" sheet, or navigate to a locked builder?
   - Recommendation: Show a `.sheet` with a "Custom challenges coming soon" placeholder message. One `@State var showingComingSoon` bool in `ChallengeDiscoveryView`.

3. **Milestone badge saved to profile: which model stores it?**
   - What we know: CHAL-10 says "milestone badge saved to profile"; `UserChallenge.milestoneHistoryJSON` stores thresholds already awarded
   - What's unclear: Is there a `UserProfile.badges` field, or does "saved to profile" mean `UserChallenge.milestoneHistoryJSON` is the profile-level artifact?
   - Recommendation: Store milestone thresholds awarded in `UserChallenge.milestoneHistoryJSON` (the challenge-level record). "Saved to profile" means these are persisted permanently (not in-memory). No new `UserProfile` fields needed in Phase 13. The profile view can surface badges in Phase 14.

---

## Environment Availability

Step 2.6: SKIPPED (no external tools, services, or CLIs beyond the project's own Swift/Xcode toolchain — all dependencies are Apple platform frameworks already in use).

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (built into Xcode) |
| Config file | VitaminG.xcodeproj (scheme: VitaminGTests) |
| Quick run command | `xcodebuild test -project VitaminG/VitaminG/VitaminG.xcodeproj -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -project VitaminG/VitaminG/VitaminG.xcodeproj -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -30` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CHAL-01 | ChallengeTemplate model persists and fetches | unit | XCTest in-memory container | ❌ Wave 0 |
| CHAL-02 | UserChallenge links to template; streak/longestStreak initialized to 0 | unit | XCTest in-memory | ❌ Wave 0 |
| CHAL-03 | One check-in per day enforced; second call on same day throws | unit | ChallengeViewModelTests | ❌ Wave 0 |
| CHAL-04 | SchemaV4 migration: existing DailyWin + Goal records survive V3→V4 | unit | Migration test with pre-seeded V3 store | ❌ Wave 0 |
| CHAL-05 | ChallengeStreakEngine: gap breaks streak; DST-safe via injectable calendar | unit | ChallengeStreakEngineTests | ❌ Wave 0 |
| CHAL-06 | seedFeaturedTemplates() inserts exactly 3 templates on empty store; idempotent on second call | unit | ChallengeViewModelTests | ❌ Wave 0 |
| CHAL-07 | recordCheckIn accepts boolean/numeric/multiStep payloads without engine branching | unit | ChallengeViewModelTests | ❌ Wave 0 |
| CHAL-08 | Discovery screen UI (human verify) | visual/manual | Human check | N/A |
| CHAL-09 | Check-in modal renders correct UI per checkInType (human verify) | visual/manual | Human check | N/A |
| CHAL-10 | pendingMilestone fires after crossing threshold; does not fire twice for same threshold | unit | ChallengeViewModelTests | ❌ Wave 0 |
| CHAL-11 | StreakChainView renders correct filled/outlined dots (human verify) | visual/manual | Human check | N/A |
| CHAL-12 | Notification scheduled with correct identifier; reminder removed on challenge abandon | unit | NotificationSchedulerTests extension | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Run existing `VitaminGTests` suite (all tests pass before any commit)
- **Per wave merge:** Full suite — new ChallengeStreakEngineTests + ChallengeViewModelTests must be green
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `VitaminGTests/ChallengeStreakEngineTests.swift` — covers CHAL-05
- [ ] `VitaminGTests/ChallengeViewModelTests.swift` — covers CHAL-03, CHAL-06, CHAL-07, CHAL-10
- [ ] `VitaminGTests/NotificationSchedulerChallengeTests.swift` — covers CHAL-12

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — (local app, no auth layer) |
| V3 Session Management | no | — (no server session) |
| V4 Access Control | no | — (single-user app; UserChallenge private CloudKit) |
| V5 Input Validation | yes | InputSanitizer.sanitize() on all user-entered text (payloadNote in multi-step check-in, challenge custom title in Phase 14) |
| V6 Cryptography | no | — (no custom crypto; CloudKit handles transport security) |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed JSON in milestonesJSON / milestoneHistoryJSON | Tampering | Decode with `try?` and fall back to empty array; never crash on decode failure |
| Notification userInfo injection (deep-link `userChallengeID`) | Tampering | DeepLinkParser validates scheme + host + UUID format before use; UUID(uuidString:) returns nil for malformed input |
| Over-long payloadNote in multi-step check-in | Tampering | InputSanitizer.sanitize() + max 500-char limit (matching DailyWin pattern) enforced before CheckIn insert |
| Duplicate featured templates from concurrent ViewModel inits | Tampering | Idempotent seed guard — fetch before insert; SwiftData's main context is `@MainActor`-serialized |

---

## Project Constraints (from CLAUDE.md)

All directives from `VitaminG/CLAUDE.md` that apply to Phase 13:

| Directive | Impact on Phase 13 |
|-----------|-------------------|
| No third-party dependencies unless necessary | No external confetti library; implement with SwiftUI canvas or simple particle overlay |
| All SwiftData model properties must be optional or have defaults | All SchemaV4 model properties: `var foo: Type?` or `var foo: Type = default` |
| No `@Attribute(.unique)` on any property | Uniqueness enforced at ViewModel layer (idempotent seed guard, one-per-day check) |
| `UNCalendarNotificationTrigger` for local notifications | Per-challenge evening reminders use this trigger — no background fetch |
| `@Observable` ViewModel | ChallengeViewModel uses `@Observable` macro, not `ObservableObject` |
| iOS 17+ minimum | All SwiftUI APIs, SwiftData, `@Observable` — all iOS 17+, no back-compat needed |
| MVVM strictly enforced — no business logic in Views | ChallengeCheckInView renders UI only; all check-in logic in ChallengeViewModel |
| All @Relationship inverses declared | Both sides of ChallengeTemplate↔UserChallenge and UserChallenge↔CheckIn must declare inverse |
| `@Query` has no sort descriptor — dynamic sort via computed property | ChallengeDiscoveryView @Query for ChallengeTemplate with no sort; VM provides sorted computed property |
| `NavigationStack` (not `NavigationView`) | Challenges tab uses `NavigationStack` with `navigationDestination` |

---

## Sources

### Primary (HIGH confidence)

- [VERIFIED: existing SchemaV3.swift] — VersionedSchema pattern; enum structure; model property conventions
- [VERIFIED: existing VitaminGMigrationPlan.swift] — lightweight migration pattern; schemas + stages arrays
- [VERIFIED: existing ModelContainerFactory.swift] — container configuration; widget container pattern
- [VERIFIED: existing StreakEngine.swift] — Calendar.current.startOfDay arithmetic; Set<Date> lookup; DST safety
- [VERIFIED: existing NotificationScheduler.swift] — per-identifier remove-before-add; UNCalendarNotificationTrigger; win identifier pattern
- [VERIFIED: existing DeepLinkBuilder.swift + DeepLinkParser.swift] — URL scheme; scheme/host/path validation
- [VERIFIED: existing AppRoute.swift + AppRouter.swift] — Hashable route enum; pendingPublicProfileRecordID pattern
- [VERIFIED: existing ContentView.swift] — TabView structure; navigationDestination switch pattern
- [VERIFIED: existing DailyWinsViewModel.swift] — todayEntry calendar arithmetic; one-per-day enforcement pattern
- [VERIFIED: existing GoalViewModel.swift] — pendingMilestone pattern; firedMilestones Set; @Observable structure
- [VERIFIED: existing ProgressViewModel.swift] — pure struct with no SwiftData dependency; arrays-in pattern
- [VERIFIED: existing VGTheme.swift] — brand color system; accentColor conventions
- [VERIFIED: existing NotificationPreferences.swift] — per-key UserDefaults pattern for notification times
- [VERIFIED: VitaminG/CLAUDE.md] — all model/architecture constraints
- [VERIFIED: 13-CONTEXT.md] — all locked decisions D-01 through D-10

### Secondary (MEDIUM confidence)

- [CITED: developer.apple.com SwiftData VersionedSchema] — lightweight migration for additive changes is valid for new model additions
- [CITED: developer.apple.com UserNotifications] — UNCalendarNotificationTrigger; 64-request cap

### Tertiary (LOW confidence)

- None — all critical claims verified against existing codebase or official documentation pattern

---

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — verified from existing codebase; same Apple frameworks in use since Phase 1
- Architecture: HIGH — all patterns directly derived from verified existing code (StreakEngine, GoalViewModel, DailyWinsViewModel, NotificationScheduler)
- Pitfalls: HIGH — most identified from existing CLAUDE.md constraints + direct pattern inspection of the codebase
- MilestoneConfig JSON storage: MEDIUM — CloudKit limitation on non-primitive arrays is well-known; JSON workaround is standard iOS pattern

**Research date:** 2026-05-04
**Valid until:** 2026-06-04 (stable Apple platform; no version changes expected in 30-day window)
