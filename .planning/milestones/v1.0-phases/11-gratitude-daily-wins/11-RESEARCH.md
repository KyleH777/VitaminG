# Phase 11: Gratitude / Daily Wins Module — Research

**Phase:** 11 — Gratitude / Daily Wins Module
**Requirements:** GRAT-01, GRAT-02, GRAT-03, GRAT-04, GRAT-05, GRAT-06
**Researched:** 2026-05-01

---

## RESEARCH COMPLETE

---

## Executive Summary

Phase 11 adds a DailyWin SwiftData model (SchemaV3 with lightweight V2→V3 migration), a Wins tab in ContentView, a DailyWinsViewModel, and a second push notification identifier. All patterns follow established V2 precedents — this is a medium-complexity phase with no novel technical territory.

**Key risks:**
1. SchemaV3 migration correctness — VitaminGMigrationPlan.schemas and ModelContainerFactory must both reference SchemaV3.
2. ContentView has 4 existing tabs (Goals · Stats · Settings · Profile). D-01 mandates Goals · Stats · Wins · Profile — Settings tab must be relocated.
3. Win notification deep-link (`.wins` AppRoute) requires tab-switching logic not yet in AppRouter.

---

## 1. SchemaV3 Migration

### Pattern established by SchemaV2

SchemaV2 (in `VitaminG/Models/SchemaV2.swift`) follows this structure:
- Enum `SchemaV2: VersionedSchema` with `versionIdentifier = Schema.Version(2, 0, 0)`
- `models: [Goal.self, CompletionEvent.self, UserProfile.self]`
- Full redeclaration of every `@Model` class belonging to V2
- `VitaminGMigrationPlan` with `schemas: [SchemaV1.self, SchemaV2.self]` and a single `migrateV1toV2` lightweight stage
- Typealiases at file bottom to update call-site resolution

SchemaV1 is frozen (comment in SchemaV1.swift confirms). SchemaV2 should be treated as frozen after V3 is introduced.

### SchemaV3 implementation approach

Create `VitaminG/Models/SchemaV3.swift`:

```swift
enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        // Include all V2 models unchanged + new DailyWin
        [SchemaV2.Goal.self, SchemaV2.CompletionEvent.self,
         SchemaV2.UserProfile.self, DailyWin.self]
    }

    @Model
    final class DailyWin {
        var id: UUID = UUID()
        var date: Date?   // optional — CloudKit compatibility (GRAT-02)
        var text: String? // optional — CloudKit compatibility (GRAT-02)

        init(date: Date = Date(), text: String) {
            self.id = UUID()
            self.date = date
            self.text = text
        }
    }
}

typealias DailyWin = SchemaV3.DailyWin
```

**Why only DailyWin is redeclared:** Goal, CompletionEvent, and UserProfile are unchanged in V3 — their V2 types are referenced by type in SchemaV3.models without redeclaration. Only the new model needs its `@Model` class inside SchemaV3.

**CloudKit rule compliance:** `id`, `date`, `text` all optional or defaulted — satisfies "all properties optional or defaulted" constraint from CLAUDE.md. No `@Attribute(.unique)` used.

### VitaminGMigrationPlan changes (in SchemaV2.swift)

Add SchemaV3 to schemas and a new lightweight stage:

```swift
enum VitaminGMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]  // add SchemaV3
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]  // add new stage
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

Adding a new model with no changes to existing models qualifies as lightweight migration — same precedent as UserProfile in V1→V2.

### ModelContainerFactory changes

Both `makeContainer` and `makeWidgetContainer` currently reference `SchemaV2.models` and `SchemaV2.versionIdentifier`:

```swift
let schema = Schema(SchemaV2.models, version: SchemaV2.versionIdentifier)
```

Must be updated to SchemaV3 in both methods:

```swift
let schema = Schema(SchemaV3.models, version: SchemaV3.versionIdentifier)
```

The DEBUG `initializeCloudKitSchema` extension also hard-codes the model list — add `DailyWin.self`:
```swift
if let mom = NSManagedObjectModel.makeManagedObjectModel(
    for: [Goal.self, CompletionEvent.self, UserProfile.self, DailyWin.self]
)
```

---

## 2. DailyWinsViewModel Pattern

### Established ViewModel pattern

All ViewModels in this project follow `@MainActor @Observable final class`. ModelContext is injected at call-site (not stored), following GoalViewModel's `addGoal(context: ModelContext)` pattern.

**StatsViewModel** is a useful analog: it uses a `refresh(events:goals:)` method that receives raw arrays rather than holding a ModelContext or @Query. `DailyWinsViewModel` can follow a hybrid: hold a ModelContext for mutation, use FetchDescriptor for today-check.

### DailyWinsViewModel sketch

```swift
@MainActor
@Observable
final class DailyWinsViewModel {

    static let maxTextLength = 500  // consistent with goalDescription limit (D-04)

    var draftText = ""
    var validationError: DailyWinValidationError?

    // MARK: - One-per-day enforcement (GRAT-04)

    func todayEntry(context: ModelContext) -> DailyWin? {
        let today = Calendar.current.startOfDay(for: Date())
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
            return nil
        }
        let descriptor = FetchDescriptor<DailyWin>(
            predicate: #Predicate { win in
                (win.date ?? Date.distantPast) >= today &&
                (win.date ?? Date.distantPast) < tomorrow
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor))?.first
    }

    // MARK: - CRUD

    func saveEntry(context: ModelContext) throws {
        let clean = InputSanitizer.sanitize(draftText)
        guard !clean.isEmpty else { throw DailyWinValidationError.textEmpty }
        guard clean.count <= Self.maxTextLength else {
            throw DailyWinValidationError.textTooLong(Self.maxTextLength)
        }

        if let existing = todayEntry(context: context) {
            existing.text = clean  // edit existing (GRAT-04)
        } else {
            let win = DailyWin(date: Date(), text: clean)
            context.insert(win)
        }
    }

    func delete(_ win: DailyWin, context: ModelContext) {
        context.delete(win)
    }
}
```

**FetchDescriptor date predicate note:** SwiftData's `#Predicate` macro supports `>=` and `<` comparisons on `Date?` — but the optional must be unwrapped in the closure. The pattern above using `?? Date.distantPast` is safe and idiomatic.

**Why not @Query in ViewModel:** GoalViewModel doesn't use @Query — it receives context at call-site and uses FetchDescriptor. This keeps the ViewModel free of SwiftUI dependency and fully unit-testable. DailyWinsView uses `@Query` directly for the history list; ViewModel uses FetchDescriptor only for today-check (mutation path).

---

## 3. ContentView Tab Restructure

### Current state

`ContentView.swift` has 4 tabs:
1. Goals (`target` icon)
2. Stats (`chart.bar.fill` icon)
3. Settings (`gear` icon)
4. Profile (`person.crop.circle.fill` icon)

### Required state (D-01)

Phase 11 mandates: **Goals · Stats · Wins · Profile** — 4 tabs.

**Settings must be relocated.** Options:
- A: Add a Settings row to ProfileView (cleanest — profile tabs often contain settings)
- B: Add a Settings toolbar icon to GoalListView (already has Add + Sort toolbar items)
- C: Keep Settings tab and add Wins as a 5th tab (violates D-01 tab order)

**Recommendation: Option A** — move Settings to ProfileView as a NavigationLink. ProfileView already has navigation structure and Settings is a natural fit alongside profile data. The `AppRoute.settings` case remains; it just won't be tab-accessible directly.

### Wins tab addition

```swift
// In ContentView.body TabView:
NavigationStack {
    DailyWinsView()
}
.tabItem {
    Label("Wins", systemImage: "book.pages")  // or "leaf" per D-02
}
```

### Deep-link to Wins tab (GRAT-05, Claude's Discretion)

The win notification should navigate to the Wins tab on tap (D-13). Options:
- A: Add `selectedTab: Int` (or enum-based `activeTab`) to AppRouter, switch tab in ContentView
- B: Accept plain foreground open (no tab switch) — D-13 says "tapping opens the app to the Wins tab (standard foreground open is sufficient)"

Per D-13, plain foreground open is acceptable for Phase 11. If tab-switching is added, it requires:
1. `.wins` case in AppRoute
2. AppRouter `pendingWinsNavigation: Bool` flag (similar to `pendingPublicProfileRecordID`)
3. ContentView binding to switch active tab

**Plan recommendation:** Implement plain foreground open first (no AppRoute changes). Note as a follow-up if deep-link to Wins tab is desired.

---

## 4. Win Notification (GRAT-05)

### Adding a second notification identifier

NotificationScheduler uses `static let identifier = "com.kyleharrington.VitaminG.dailyReminder"` with a remove-before-add pattern. The win reminder needs its own identifier so both notifications coexist.

**iOS 64-request cap:** With `repeats: true`, each `UNCalendarNotificationTrigger` uses 1 slot (not 64). Two `repeats: true` notifications = 2 slots total — well within cap.

### NotificationScheduler additions

```swift
static let winIdentifier = "com.kyleharrington.VitaminG.winReminder"

func makeWinContent() -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.title = "Vitamin G"
    content.body = "What's your win today?"
    content.sound = .default
    content.userInfo = ["deepLink": "wins"]  // for future deep-link routing
    return content
}

func scheduleWinReminder(hour: Int, minute: Int) async {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [Self.winIdentifier])
    let validHour = max(0, min(23, hour))
    let validMinute = max(0, min(59, minute))
    var components = DateComponents()
    components.hour = validHour
    components.minute = validMinute
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    let request = UNNotificationRequest(
        identifier: Self.winIdentifier,
        content: makeWinContent(),
        trigger: trigger
    )
    try? await center.add(request)
}

func rescheduleWinReminder() async {
    await scheduleWinReminder(
        hour: NotificationPreferences.winHour,
        minute: NotificationPreferences.winMinute
    )
}
```

### NotificationPreferences additions

```swift
static let winHourKey   = "winNotificationHour"
static let winMinuteKey = "winNotificationMinute"
static let defaultWinHour   = 20  // 8:00 PM default (D-12)
static let defaultWinMinute = 0

static var winHour: Int {
    if UserDefaults.standard.object(forKey: winHourKey) != nil {
        return UserDefaults.standard.integer(forKey: winHourKey)
    }
    return defaultWinHour
}

static var winMinute: Int {
    if UserDefaults.standard.object(forKey: winMinuteKey) != nil {
        return UserDefaults.standard.integer(forKey: winMinuteKey)
    }
    return defaultWinMinute
}

static func saveWinTime(hour: Int, minute: Int) {
    UserDefaults.standard.set(hour, forKey: winHourKey)
    UserDefaults.standard.set(minute, forKey: winMinuteKey)
    // App Group sync for widget access (future-proofing)
    let shared = UserDefaults(suiteName: suiteName)
    shared?.set(hour, forKey: winHourKey)
    shared?.set(minute, forKey: winMinuteKey)
}
```

### VitaminGApp.init scheduling

Win reminder should be scheduled at app launch alongside goal reminder. VitaminGApp.init currently wires NotificationDelegate for goal deep-links. The win notification's `deepLink: "wins"` value needs handling in NotificationDelegate — add a handler or extend the existing closure:

```swift
let delegate = NotificationDelegate { deepLink in
    if deepLink == "goalList" {
        appRouter.popToRoot()
    }
    // "wins" value — plain foreground open, no additional routing needed in Phase 11
}
```

On app launch, schedule the win reminder after container creation:
```swift
Task {
    await NotificationScheduler.shared.rescheduleWinReminder()
}
```

---

## 5. SettingsView Addition (GRAT-05, D-12)

SettingsView gains a second notification section "Win Reminder" below the existing "Daily Reminder" section. Pattern is identical: DatePicker + same authorization row check.

```swift
Section("Win Reminder") {
    DatePicker(
        "Reminder Time",
        selection: $winNotificationTime,
        displayedComponents: .hourAndMinute
    )
    .disabled(!isAuthorized)
    .onChange(of: winNotificationTime) { _, newValue in
        let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
        let hour = comps.hour ?? NotificationPreferences.defaultWinHour
        let minute = comps.minute ?? NotificationPreferences.defaultWinMinute
        NotificationPreferences.saveWinTime(hour: hour, minute: minute)
        Task { await NotificationScheduler.shared.rescheduleWinReminder() }
    }
}
```

SettingsView needs a second `@State private var winNotificationTime: Date` initialized from `NotificationPreferences.winHour/winMinute`.

---

## 6. DailyWinsView Layout

### Component breakdown

```
NavigationStack {
    DailyWinsView {
        // Section 1: Today's editor (D-09)
        Section {
            VStack {
                TextEditor(text: $viewModel.draftText)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                Text("\(viewModel.draftText.count)/500")  // character count (Claude's Discretion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Button("Save") { ... }
            }
        } header: {
            Text(todayDate)  // formatted "Monday, May 1"
        }

        // Section 2: History (D-08, D-10)
        Section("Past Wins") {
            if historyEntries.isEmpty {
                Text("Your wins will appear here.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(historyEntries) { win in
                    WinCardView(win: win)
                }
                .onDelete { ... }  // swipe-to-delete (D-07)
            }
        }
    }
    .navigationTitle("Daily Wins")
}
```

**History query:** `@Query(sort: \DailyWin.date, order: .reverse) private var allWins: [DailyWin]`

To get history entries (all except today's), filter allWins in a computed property using `Calendar.current.isDateInToday`.

### TextEditor pre-fill (GRAT-04)

On `.onAppear`, call `viewModel.todayEntry(context: modelContext)` to check if today's entry exists. If it does, set `viewModel.draftText = existing.text ?? ""`.

---

## 7. Validation Architecture

### Testable behaviors

| Function | Input | Expected output | Test approach |
|----------|-------|-----------------|---------------|
| `todayEntry(context:)` | Empty store | nil | in-memory ModelContainer |
| `todayEntry(context:)` | DailyWin with today's date | returns the win | in-memory ModelContainer |
| `todayEntry(context:)` | DailyWin with yesterday's date | nil | in-memory ModelContainer |
| `saveEntry(context:)` | empty text | throws `.textEmpty` | no container needed |
| `saveEntry(context:)` | 501-char text | throws `.textTooLong(500)` | no container needed |
| `saveEntry(context:)` | valid text, no today entry | inserts DailyWin | in-memory ModelContainer |
| `saveEntry(context:)` | valid text, today entry exists | updates existing | in-memory ModelContainer |
| `makeWinContent()` | n/a | title="Vitamin G", body="What's your win today?" | no container, synchronous |
| Win notification identifier | n/a | != dailyReminder identifier | string comparison |

### Test file: `DailyWinsViewModelTests.swift`

Pattern follows `NotificationSchedulerTests.swift` and `GoalViewModelTests.swift`:

```swift
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
}
```

**Key test: one-per-day enforcement**
```swift
func test_saveEntry_todayEntryExists_updatesNotInserts() throws {
    let context = ModelContext(container)
    // Insert today's entry
    let win = DailyWin(date: Date(), text: "First save")
    context.insert(win)

    // Save again — should update, not insert
    viewModel.draftText = "Updated win"
    try viewModel.saveEntry(context: context)

    let descriptor = FetchDescriptor<DailyWin>()
    let all = try context.fetch(descriptor)
    XCTAssertEqual(all.count, 1, "Should not insert a second entry for today")
    XCTAssertEqual(all.first?.text, "Updated win")
}
```

---

## 8. File Map

| New file | Purpose |
|----------|---------|
| `VitaminG/Models/SchemaV3.swift` | DailyWin @Model, SchemaV3 enum |
| `VitaminG/ViewModels/DailyWinsViewModel.swift` | @Observable ViewModel, CRUD, validation |
| `VitaminG/Views/DailyWinsView.swift` | Tab view, today's editor, history list |
| `VitaminGTests/DailyWinsViewModelTests.swift` | Unit tests for ViewModel |

| Modified file | Change |
|---------------|--------|
| `VitaminG/Models/SchemaV2.swift` | Add migrateV2toV3 stage + SchemaV3 to VitaminGMigrationPlan.schemas |
| `VitaminG/Persistence/ModelContainerFactory.swift` | SchemaV3 models + version; add DailyWin to initializeCloudKitSchema |
| `VitaminG/Services/NotificationScheduler.swift` | Add winIdentifier, makeWinContent, scheduleWinReminder, rescheduleWinReminder |
| `VitaminG/Services/NotificationPreferences.swift` | Add winHourKey, winMinuteKey, winHour, winMinute, saveWinTime |
| `VitaminG/Navigation/AppRoute.swift` | Add `.wins` case (for future deep-link; plain open acceptable in Phase 11) |
| `VitaminG/Views/ContentView.swift` | Replace Settings tab with Wins tab; update tab order |
| `VitaminG/Views/SettingsView.swift` | Add Win Reminder section with DatePicker |
| `VitaminG/VitaminGApp.swift` | Schedule win reminder on launch; extend NotificationDelegate handler |

---

## 9. Open Questions for Planner

1. **Settings tab relocation:** D-01 specifies Goals · Stats · Wins · Profile (4 tabs). Where does Settings go — as a row in ProfileView (recommended) or toolbar icon in GoalListView? The planner should pick one and document it.

2. **Win notification deep-link tab switching:** D-13 says "plain app open is acceptable" for Phase 11. Planner should confirm whether to add AppRoute.wins and AppRouter tab-switching or defer to a future phase.

3. **`@Observable` + `@Query` interaction in DailyWinsView:** Whether to put `@Query` in the View (for the history list) and call ViewModel only for mutations (recommended) or have ViewModel manage everything. Recommendation: @Query in View for history, ViewModel for save/delete/today-check (GoalViewModel analogy).

---

*Research complete. No external dependencies needed — all patterns have established analogs in the codebase.*
