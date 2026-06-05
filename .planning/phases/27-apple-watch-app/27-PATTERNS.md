# Phase 27: Apple Watch App - Pattern Map

**Mapped:** 2026-06-02
**Files analyzed:** 9 (5 new, 4 modified)
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `VitaminG/VitaminG/VitaminG/Services/WatchSessionManager.swift` | service | event-driven | `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` | role-match |
| `VitaminG/VitaminG/VitaminG/Models/WatchSnapshot.swift` | model | transform | `VitaminG/VitaminG/VitaminG/Services/WidgetDataProvider.swift` | data-flow-match |
| `VitaminG/VitaminGWatch/Shared/WatchReceiver.swift` | service | event-driven | `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` | role-match |
| `VitaminG/VitaminGWatchWidget/VitaminGWatchWidget.swift` | provider + view + config | request-response | `VitaminG/VitaminG/VitaminGWidget/StreakWidget.swift` | exact |
| `VitaminG/VitaminGWatch/VitaminGWatch.entitlements` (new file) | config | — | `VitaminG/VitaminG/VitaminGWidget/VitaminGWidget.entitlements` | exact |
| `VitaminG/VitaminGWatchWidget/VitaminGWatchWidget.entitlements` (new file) | config | — | `VitaminG/VitaminG/VitaminGWidget/VitaminGWidget.entitlements` | exact |
| `VitaminG/VitaminGWatch/VGWatchApp.swift` *(modify)* | app entry point | event-driven | `VitaminG/VitaminG/VitaminG/VitaminGApp.swift` | role-match |
| `VitaminG/VitaminGWatch/Screens/TodayGlanceView.swift` *(modify)* | view | event-driven | self (existing hardcoded shell) | self-reference |
| `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` *(modify)* | view-model | CRUD | self | self-reference |

---

## Pattern Assignments

### `VitaminG/VitaminG/VitaminG/Services/WatchSessionManager.swift` (service, event-driven)

**Analog:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift`

**Imports pattern** (NotificationScheduler.swift lines 1-2):
```swift
import UserNotifications
import Foundation
```
Apply the same minimal-import convention — for WatchSessionManager:
```swift
import WatchConnectivity
import SwiftData
import WidgetKit
```

**Singleton pattern** (NotificationScheduler.swift lines 15-19):
```swift
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    static let identifier = "com.kyleharrington.VitaminG.dailyReminder"

    private init() {}
```
Copy exactly for WatchSessionManager — `final class`, `static let shared`, `private init()`. WatchSessionManager must also inherit from `NSObject` because `WCSessionDelegate` extends `NSObjectProtocol`:
```swift
final class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private override init() { super.init() }
```

**Service activation pattern** — called at app startup, analogous to how `NotificationScheduler.shared.rescheduleWinReminder()` is called in `VitaminGApp.body.task` (VitaminGApp.swift lines 107-108):
```swift
// VitaminGApp.swift — .task { } block pattern for service activation at launch
let isGranted = await NotificationScheduler.shared.isAuthorized()
if isGranted {
    await NotificationScheduler.shared.rescheduleWinReminder()
}
```
Adapt for WatchSessionManager — activation is not async, call in `VitaminGApp.init()` before the container is created (or in `.task` body on `container.mainContext`):
```swift
// In VitaminGApp.init(), after self.container is set:
WatchSessionManager.shared.configure(container: container)
WatchSessionManager.shared.activate()
```

**iOS-only lifecycle guard** — use `#if os(iOS)` to wrap `sessionDidBecomeInactive` / `sessionDidDeactivate` (RESEARCH.md Pattern 1, lines 200-205):
```swift
#if os(iOS)
func sessionDidBecomeInactive(_ session: WCSession) {}
func sessionDidDeactivate(_ session: WCSession) {
    session.activate() // re-activate on Watch switch
}
#endif
```

**MainActor dispatch for delegate callbacks** — WCSession delegate fires on a non-main background queue; all SwiftData access requires dispatch. Pattern from GoalViewModel.swift line 222:
```swift
// GoalViewModel.swift line 222 — Task dispatch for cross-actor side effects
Task { await NotificationScheduler.shared.cancelGlobalStreakAtRiskNudge() }
```
For the WatchSessionManager receive path, the equivalent is:
```swift
func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
        self?.handleCheckIn(userInfo: userInfo)
    }
}
```

**Post-check-in side effects pattern** (GoalViewModel.swift lines 213-222 — the exact path WatchSessionManager must replicate):
```swift
// Keep notifications and widgets fresh after the check-in
rescheduleNotification(context: context)
reloadWidgetTimelines()

NotificationPreferences.appendCheckInHour(Calendar.current.component(.hour, from: Date()))

// MILE-02: Cancel the global 7 PM streak-at-risk nudge after a successful check-in.
Task { await NotificationScheduler.shared.cancelGlobalStreakAtRiskNudge() }
```

**`cancelGlobalStreakAtRiskNudge()` implementation** (NotificationScheduler.swift lines 585-588):
```swift
func cancelGlobalStreakAtRiskNudge() {
    UNUserNotificationCenter.current()
        .removePendingNotificationRequests(withIdentifiers: [Self.globalStreakAtRiskIdentifier])
}
```

**`#if DEBUG` error logging pattern** (NotificationScheduler.swift lines 131-134):
```swift
} catch {
    #if DEBUG
    print("[NotificationScheduler] Failed to add daily reminder request: \(error)")
    #endif
}
```
Use the same `#if DEBUG` / `print("[WatchSessionManager] ...")` pattern for all guard/error paths.

---

### `VitaminG/VitaminG/VitaminG/Models/WatchSnapshot.swift` (model, transform)

**Analog:** `VitaminG/VitaminG/VitaminG/Services/WidgetDataProvider.swift`

**Struct declaration pattern** (WidgetDataProvider.swift lines 8-43):
```swift
struct WidgetDisplayData {
    struct TierRow {
        let tier: GoalTier
        let topGoalTitle: String?  // nil = show empty state prompt
    }

    let tierRows: [TierRow]
    let globalStreak: Int
    let activeGoalTitle: String?
    let activeGoalProgress: Double?

    static let placeholder = WidgetDisplayData(...)
    static let empty = WidgetDisplayData(...)
}
```
`WatchSnapshot` mirrors this struct pattern but is `Codable` (for WCSession JSON encoding) and adds `hasCheckedInToday` and `activeGoalId`:
```swift
struct WatchSnapshot: Codable {
    let activeGoalTitle: String?
    let activeGoalProgress: Double      // 0.0–1.0
    let globalStreak: Int
    let hasCheckedInToday: Bool
    let activeGoalId: String?           // UUID.uuidString; nil when no active goal

    static let placeholder = WatchSnapshot(
        activeGoalTitle: "Morning run",
        activeGoalProgress: 0.72,
        globalStreak: 7,
        hasCheckedInToday: false,
        activeGoalId: nil
    )
}
```

**`build()` pure static function pattern** (WidgetDataProvider.swift lines 58-103):
```swift
static func build(
    goals: [Goal],
    events: [CompletionEvent],
    calendar: Calendar = .current
) -> WidgetDisplayData {
    let globalStreak = StreakEngine.currentStreak(from: events, calendar: calendar)

    // D-03: Active goal = highest-priority non-completed goal
    let activeGoal = GoalTier.ordered.compactMap { tier in
        goals
            .filter { $0.tier == tier && !$0.isCompleted }
            .sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
            .first
    }.first

    let activeGoalTitle = activeGoal?.title

    let activeGoalProgress: Double? = {
        guard let goal = activeGoal,
              let duration = goal.durationDays,
              duration > 0 else { return nil }
        let count = Double(goal.completionEvents?.count ?? 0)
        return min(1.0, count / Double(duration))
    }()
    // ...
}
```
`WatchSnapshot.build()` calls `WidgetDataProvider.build()` to reuse the same active goal computation, then augments with `hasCheckedInToday` and `activeGoalId`.

---

### `VitaminG/VitaminGWatch/Shared/WatchReceiver.swift` (service, event-driven)

**Analog:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift`

**Singleton pattern** (NotificationScheduler.swift lines 15-19) — same pattern as WatchSessionManager:
```swift
final class WatchReceiver: NSObject, WCSessionDelegate {
    static let shared = WatchReceiver()
    private let suiteName = "group.com.kyleharrington.VitaminGWatch"
    private override init() { super.init() }
```

**Imports** — watchOS-side; omit UIKit-dependent frameworks:
```swift
import WatchConnectivity
import WidgetKit
```

**UserDefaults(suiteName:) pattern** — analogous to the iOS widget's App Group UserDefaults usage in the project. Key prefix `"watchSnapshot_"` matches CONTEXT.md decision D (Claude's Discretion):
```swift
private func writeToUserDefaults(_ snapshot: WatchSnapshot) {
    let defaults = UserDefaults(suiteName: suiteName)
    defaults?.set(snapshot.activeGoalTitle, forKey: "watchSnapshot_activeGoalTitle")
    defaults?.set(snapshot.activeGoalProgress, forKey: "watchSnapshot_activeGoalProgress")
    defaults?.set(snapshot.globalStreak, forKey: "watchSnapshot_globalStreak")
    defaults?.set(snapshot.hasCheckedInToday, forKey: "watchSnapshot_hasCheckedInToday")
    defaults?.set(snapshot.activeGoalId, forKey: "watchSnapshot_activeGoalId")
}
```

**WidgetCenter reload pattern** — after writing UserDefaults, trigger complication refresh. Analogous to `WidgetCenter.shared.reloadAllTimelines()` in GoalViewModel.swift lines 357, 365:
```swift
WidgetCenter.shared.reloadAllTimelines()
```

**CRITICAL: watchOS does NOT have `sessionDidBecomeInactive` or `sessionDidDeactivate`** — omit both methods entirely in `WatchReceiver`. Only implement `activationDidCompleteWith`.

---

### `VitaminG/VitaminGWatchWidget/VitaminGWatchWidget.swift` (provider + view + config, request-response)

**Analog:** `VitaminG/VitaminG/VitaminGWidget/StreakWidget.swift`

**Imports pattern** (StreakWidget.swift lines 1-3):
```swift
import WidgetKit
import SwiftUI
import SwiftData   // NOT included for Watch widget — Watch widget has no SwiftData access
```
Watch widget omits `SwiftData`:
```swift
import WidgetKit
import SwiftUI
```

**TimelineEntry pattern** (VitaminGWidget/WidgetTimelineEntry.swift lines 5-8):
```swift
struct GoalEntry: TimelineEntry {
    let date: Date
    let displayData: WidgetDisplayData
}
```
Watch widget defines its own entry (cannot share the iOS entry type):
```swift
struct WatchEntry: TimelineEntry {
    let date: Date
    let goalTitle: String?
    let progress: Double
    let globalStreak: Int
    let hasCheckedInToday: Bool
}
```

**TimelineProvider structure** (StreakWidget.swift lines 7-38 — exact pattern to copy):
```swift
struct StreakProvider: TimelineProvider {

    func placeholder(in context: Context) -> GoalEntry {
        GoalEntry(date: .now, displayData: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (GoalEntry) -> Void) {
        completion(GoalEntry(date: .now, displayData: .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalEntry>) -> Void) {
        do {
            let container = try WidgetContainerCache.shared   // iOS only — DO NOT copy this
            // ...
        }
        // Push-only refresh: app explicitly calls reloadAllTimelines() on mutations (WIDGET-05)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}
```
Watch variant reads from `UserDefaults(suiteName:)` instead of ModelContainer (RESEARCH.md Anti-Pattern warning):
```swift
struct WatchSnapshotProvider: TimelineProvider {
    private let suiteName = "group.com.kyleharrington.VitaminGWatch"

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: suiteName)
        let entry = WatchEntry(
            date: .now,
            goalTitle: defaults?.string(forKey: "watchSnapshot_activeGoalTitle"),
            progress: defaults?.double(forKey: "watchSnapshot_activeGoalProgress") ?? 0.0,
            globalStreak: defaults?.integer(forKey: "watchSnapshot_globalStreak") ?? 0,
            hasCheckedInToday: defaults?.bool(forKey: "watchSnapshot_hasCheckedInToday") ?? false
        )
        // Push-only refresh — WatchReceiver calls reloadAllTimelines() on each WCSession update
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}
```

**Widget configuration pattern** (StreakWidget.swift lines 91-102):
```swift
struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Your current streak, or your top immediate goal.")
        .supportedFamilies([.accessoryRectangular])
    }
}
```
Copy exactly, substituting `WatchSnapshotProvider` and `WatchComplicationView`, and use `"VitaminGWatchWidget"` as `kind`.

**Complication view `containerBackground` pattern** (StreakWidget.swift line 85):
```swift
.containerBackground(.fill.tertiary, for: .widget)
```
Apply to the outermost view of `WatchComplicationView` — required for all WidgetKit views on watchOS 10+.

**VGRingView usage in complication** — `VGRingView` and `VGWatchTheme` Swift files must have `VitaminGWatchWidget` added to their Target Membership in Xcode (Pitfall 7 from RESEARCH.md). Reference:
```swift
// VGRingView.swift — already in Watch target; reuse in complication
VGRingView(progress: entry.progress, size: 32, lineWidth: 3, color: VGWatch.terraSoft, glow: false)
```

**`@available(watchOS 11.0, *)` guard for interactive complications** (RESEARCH.md Pattern 7):
```swift
var body: some View {
    if #available(watchOS 11.0, *) {
        WatchComplicationInteractiveView(entry: entry)
    } else {
        WatchComplicationPassiveView(entry: entry)
    }
}
```
Implement passive (tap-to-open) path first; interactive is a conditional upgrade.

---

### `VitaminG/VitaminGWatch/VitaminGWatch.entitlements` (new config file)

**Analog:** `VitaminG/VitaminG/VitaminGWidget/VitaminGWidget.entitlements`

**Entitlements file structure** (VitaminGWidget.entitlements lines 1-10):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.kyleharrington.VitaminG</string>
    </array>
</dict>
</plist>
```
Watch variant uses the Watch-scoped group (NOT the iOS group — platform limitation confirmed in RESEARCH.md):
```xml
<string>group.com.kyleharrington.VitaminGWatch</string>
```

---

### `VitaminG/VitaminGWatchWidget/VitaminGWatchWidget.entitlements` (new config file)

**Analog:** `VitaminG/VitaminG/VitaminGWidget/VitaminGWidget.entitlements`

Identical structure to VitaminGWatch.entitlements above — same Watch App Group identifier `group.com.kyleharrington.VitaminGWatch`. Both Watch app and Watch Widget Extension must share this group for `UserDefaults(suiteName:)` to work across process boundaries.

---

### `VitaminG/VitaminGWatch/VGWatchApp.swift` (modify — app entry point, event-driven)

**Analog:** `VitaminG/VitaminG/VitaminG/VitaminGApp.swift`

**Current file** (VGWatchApp.swift lines 1-10 — entire file):
```swift
import SwiftUI

@main
struct VGWatchApp: App {
    var body: some Scene {
        WindowGroup {
            VGWatchContentView()
        }
    }
}
```

**Service activation at init pattern** (VitaminGApp.swift lines 19-78 — init() block). On Watch there is no container, so activation happens directly in `init()`:
```swift
import SwiftUI
import WatchConnectivity

@main
struct VGWatchApp: App {
    init() {
        WatchReceiver.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            VGWatchContentView()
        }
    }
}
```
This mirrors how `VitaminGApp.init()` wires `NotificationDelegate` and stores service references before the body is evaluated.

---

### `VitaminG/VitaminGWatch/Screens/TodayGlanceView.swift` (modify — view, event-driven)

**Analog:** self (existing hardcoded shell at lines 1-83)

**Current hardcoded values to replace:**

Header (TodayGlanceView.swift lines 18-25):
```swift
HStack(spacing: 0) {
    Text("Day ")
        .font(VGWatch.serif(22))
        .foregroundColor(.white)
    Text("65")                                          // <-- replace with snapshot.globalStreak
        .font(VGWatch.serif(22, italic: true))
        .foregroundColor(VGWatch.terraSoft)
}
```
Replace `"65"` with `"\(snapshot.globalStreak)"` per CONTEXT.md decision D-02.

Ring (TodayGlanceView.swift lines 33-48):
```swift
ZStack {
    VGRingView(progress: 0.72, size: 100, lineWidth: 9, color: VGWatch.terraSoft)  // <-- replace 0.72 with snapshot.activeGoalProgress
    VStack(spacing: 1) {
        HStack(alignment: .lastTextBaseline, spacing: 1) {
            Text("72")                                  // <-- replace with Int(snapshot.activeGoalProgress * 100)
                .font(.system(size: 28, weight: .thin))
                .foregroundColor(.white)
```

Check In button (TodayGlanceView.swift lines 52-73) — replace `checkedIn = true` with `transferUserInfo` + navigation:
```swift
Button {
    guard let goalId = snapshot.activeGoalId else { return }
    let payload: [String: Any] = ["action": "checkIn", "goalId": goalId]
    if WCSession.isSupported(), WCSession.default.activationState == .activated {
        WCSession.default.transferUserInfo(payload)
    }
    // Optimistic UI — navigate immediately per CONTEXT.md Claude's Discretion
    showSuccessView = true
} label: {
    // Preserve existing label layout (lines 55-70)
}
.disabled(snapshot.hasCheckedInToday || snapshot.activeGoalId == nil)
```

**Goal title display below ring** — new element per CONTEXT.md D-02. Use existing small-text style from the view:
```swift
Text(snapshot.activeGoalTitle ?? "")
    .font(.system(size: 10, weight: .semibold))
    .foregroundColor(.white.opacity(0.65))
    .lineLimit(1)
    .padding(.top, 4)
```

**Navigation to CheckInSuccessView** — use `NavigationStack` + `navigationDestination` or a `.fullScreenCover` triggered by `showSuccessView`. `CheckInSuccessView` already built (CheckInSuccessView.swift).

**Snapshot state** — read from Watch-scoped UserDefaults via `@AppStorage` or a lightweight ObservableObject ViewModel:
```swift
// Option A: @AppStorage per key (simplest for watchOS)
@AppStorage("watchSnapshot_globalStreak", store: UserDefaults(suiteName: "group.com.kyleharrington.VitaminGWatch"))
private var globalStreak: Int = 0
```
Or use a dedicated `WatchSnapshotViewModel` that reads from `UserDefaults(suiteName:)` in `onAppear`/`.task`.

---

### `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` (modify — view-model, CRUD)

**Analog:** self

**`addCheckIn` method location** (GoalViewModel.swift line 169):
```swift
func addCheckIn(for goal: Goal, context: ModelContext, username: String = "", colorHex: String = "") {
```

**Where to add `pushSnapshot` call** — immediately after `reloadWidgetTimelines()` at line 215:
```swift
rescheduleNotification(context: context)
reloadWidgetTimelines()
// NEW: Push updated snapshot to Watch after every check-in
WatchSessionManager.shared.pushSnapshot(goals: ..., events: ..., context: context)
```
The `goals` and `events` arrays must be fetched from `context` — same pattern used at VitaminGApp.swift lines 146-148:
```swift
let allGoals = (try? launchContext.fetch(FetchDescriptor<Goal>())) ?? []
let allEvents = allGoals.compactMap { $0.completionEvents }.flatMap { $0 }
```

---

## Shared Patterns

### Singleton Service Pattern
**Source:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` lines 15-19
**Apply to:** `WatchSessionManager.swift`, `WatchReceiver.swift`
```swift
final class ServiceName {
    static let shared = ServiceName()
    private init() {}
    // NSObject subclass variant: private override init() { super.init() }
```

### `#if DEBUG` Error Logging
**Source:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` lines 131-134
**Apply to:** `WatchSessionManager.swift`, `WatchReceiver.swift`
```swift
} catch {
    #if DEBUG
    print("[WatchSessionManager] Failed to ...: \(error)")
    #endif
}
```

### Push-Only Widget Refresh
**Source:** `VitaminG/VitaminG/VitaminGWidget/StreakWidget.swift` lines 28-30
**Apply to:** `WatchReceiver.swift`, `VitaminGWatchWidget/VitaminGWatchWidget.swift`
```swift
// Push-only refresh: app explicitly calls reloadAllTimelines() on mutations (WIDGET-05)
let timeline = Timeline(entries: [entry], policy: .never)
completion(timeline)
```

### `cancelGlobalStreakAtRiskNudge` Call After Check-in
**Source:** `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` line 222
**Apply to:** `WatchSessionManager.swift` (in `handleCheckIn`)
```swift
Task { await NotificationScheduler.shared.cancelGlobalStreakAtRiskNudge() }
```

### VGWatch Color Tokens
**Source:** `VitaminG/VitaminGWatch/Shared/VGWatchTheme.swift` lines 6-24
**Apply to:** `VitaminGWatchWidget/VitaminGWatchWidget.swift`, `TodayGlanceView.swift`
```swift
VGWatch.terra      // #C4673A
VGWatch.terraSoft  // #E8956D
VGWatch.terraGlow  // #FFB07A
VGWatch.sageBright // #A4C9AE
VGWatch.gold       // #C4A459
VGWatch.plum       // #9B7DB6
```

### VGRingView Usage
**Source:** `VitaminG/VitaminGWatch/Shared/VGRingView.swift` lines 3-25
**Apply to:** `VitaminGWatchWidget/VitaminGWatchWidget.swift`
- Signature: `VGRingView(progress:size:lineWidth:color:trackColor:glow:animated:)`
- For complication: `glow: false` (complication rendering context)
- Target membership: add `VGRingView.swift` and `VGWatchTheme.swift` to `VitaminGWatchWidget` target in Xcode

### VGWatch Serif Font
**Source:** `VitaminG/VitaminGWatch/Shared/VGWatchTheme.swift` lines 20-23
**Apply to:** `TodayGlanceView.swift` modifications, `CheckInSuccessView.swift` (if updated)
```swift
static func serif(_ size: CGFloat, italic: Bool = false) -> Font {
    let name = italic ? "CormorantGaramond-Italic" : "CormorantGaramond-Regular"
    return .custom(name, size: size)
}
```

### App Entitlements File Structure
**Source:** `VitaminG/VitaminG/VitaminGWidget/VitaminGWidget.entitlements` lines 1-10
**Apply to:** `VitaminGWatch/VitaminGWatch.entitlements`, `VitaminGWatchWidget/VitaminGWatchWidget.entitlements`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.kyleharrington.VitaminGWatch</string>
    </array>
</dict>
</plist>
```

---

## No Analog Found

All files have analogs. No new patterns are required from RESEARCH.md alone — all patterns have direct codebase matches.

---

## Critical Implementation Notes (extracted from RESEARCH.md)

These are not pattern choices but hard constraints the planner must embed as task checklist items:

1. **Wave 0 human checkpoint**: Register `group.com.kyleharrington.VitaminGWatch` in Apple Developer Portal → Identifiers → App Groups before any runtime testing. `UserDefaults(suiteName:)` returns nil without this.

2. **Deployment target**: Raise `VitaminGWatch` target from `watchOS 7.0` (project.pbxproj lines 553, 978) to `watchOS 10.0` before any other Watch code changes.

3. **Target membership for shared files**: Add `VGRingView.swift` and `VGWatchTheme.swift` to `VitaminGWatchWidget` target membership in Xcode to avoid "Use of unresolved identifier 'VGWatch'" build error.

4. **Simulator limitation**: `WCSession.transferUserInfo` is a silent no-op on Simulator. All WATCH-03 integration tasks require physical device verification checkpoint.

5. **Do NOT use `transferCurrentComplicationUserInfo()`**: Incompatible with WidgetKit complications. Use `updateApplicationContext` + `WidgetCenter.shared.reloadAllTimelines()` pattern only.

6. **iOS App Group isolation**: The iOS group `group.com.kyleharrington.VitaminG` cannot be shared with watchOS targets — different filesystem containers even with the same identifier.

---

## Metadata

**Analog search scope:** `VitaminG/VitaminG/VitaminG/Services/`, `VitaminG/VitaminG/VitaminGWidget/`, `VitaminG/VitaminGWatch/`
**Files scanned:** 12
**Pattern extraction date:** 2026-06-02
