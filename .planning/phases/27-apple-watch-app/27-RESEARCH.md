# Phase 27: Apple Watch App - Research

**Researched:** 2026-06-02
**Domain:** WatchConnectivity (WCSession), WidgetKit on watchOS, App Groups (Watch-scoped), SwiftData/MainActor integration
**Confidence:** HIGH (all critical claims verified via Apple Developer Forums with DTS engineer responses or cross-confirmed with multiple sources)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- WatchConnectivity (not App Groups) for iOS-Watch data bridge
- `WCSession.updateApplicationContext` for iPhone→Watch snapshot delivery (WATCH-02)
- `WCSession.transferUserInfo` for Watch→iPhone check-in relay (WATCH-03)
- New target `VitaminGWatchWidget` (Watch Widget Extension) for the accessoryRectangular complication
- `WatchSessionManager` service on iOS side (dedicated singleton)
- Watch reads from Watch-local UserDefaults (NOT ModelContainer/SwiftData — iOS-only)
- `watchOS 10.0` minimum; `Button(intent:)` interactive complications require `watchOS 11.0` — guard with `@available`
- Physical device testing required before merging any WatchConnectivity code
- Watch app group: `group.com.kyleharrington.VitaminGWatch` or existing iOS group

### Claude's Discretion
- Check-in scope: which goal(s) to check in — single `activeGoal` identified by `goalId` in `transferUserInfo` payload; disable button if activeGoal is nil
- Watch check-in feedback: optimistic (immediate transition to CheckInSuccessView, no WCSession ack wait)
- Complication checked-in state: `hasCheckedInToday: Bool` in Watch snapshot; complication shows "checked in" layout when true
- WatchSessionManager placement: dedicated singleton initialized at `VitaminGApp` startup via `WatchSessionManager.shared.activate()`
- Watch-local UserDefaults key prefix: `"watchSnapshot_"` keys in `UserDefaults(suiteName: "group.com.kyleharrington.VitaminGWatch")`
- Watch Widget Extension target name: `VitaminGWatchWidget`

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WATCH-02 | User sees active goal title and progress ring in accessoryRectangular complication; data stays current via WatchConnectivity snapshot delivery | WCSession.updateApplicationContext + Watch Widget Extension TimelineProvider reading Watch-scoped App Group UserDefaults |
| WATCH-03 | User taps complication → Watch app opens → Check In button → relays check-in to iPhone via transferUserInfo → same effects as iOS check-in (streak update, widget reload, streak-at-risk cancel) | WCSession.transferUserInfo on Watch side + WatchSessionManager.didReceiveUserInfo on iOS side calling GoalViewModel.addCheckIn on MainActor |
</phase_requirements>

---

## Summary

Phase 27 wires the already-scaffolded `VitaminGWatch` target to live data through three new pieces of infrastructure:

1. **iOS WatchSessionManager** — a singleton service (`NSObject` subclass conforming to `WCSessionDelegate`) activated at `VitaminGApp` startup. On iPhone-side it pushes a `WatchSnapshot` payload via `updateApplicationContext` after every goal mutation; on receive, its `didReceiveUserInfo` delegate method calls `GoalViewModel.addCheckIn` on the main actor, reloads widget timelines, and cancels the streak-at-risk notification.

2. **Watch WCSession receiver** — activated in `VGWatchApp.init()`, decodes incoming application context into Watch-local App Group `UserDefaults`, then calls `WidgetCenter.shared.reloadAllTimelines()` so the complication reflects the latest snapshot.

3. **VitaminGWatchWidget target** — a new Widget Extension added to the VitaminGWatch app in Xcode. Its `TimelineProvider` reads exclusively from Watch-scoped `UserDefaults(suiteName: "group.com.kyleharrington.VitaminGWatch")`, which the Watch app populates from WCSession. Both targets must have the Watch App Group entitlement. The iOS App Group (`group.com.kyleharrington.VitaminG`) is a different filesystem container and **cannot be shared with watchOS targets** — this is a confirmed Apple platform limitation.

The most critical landmine for this phase: `transferUserInfo` is a silent no-op on Simulator — all round-trip testing (Watch→iPhone check-in relay, streak update, notification cancel) **must** occur on physical devices. Plan all WCSession integration tasks to include a device-testing checkpoint.

**Primary recommendation:** Build in wave order — (1) iOS WatchSessionManager + WatchSnapshot struct, (2) Wire VGWatchApp to activate WCSession and write to Watch UserDefaults, (3) new VitaminGWatchWidget target reading those UserDefaults, (4) TodayGlanceView Check In button sending `transferUserInfo`, (5) physical device verification.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| iPhone→Watch snapshot push | iOS App (WatchSessionManager) | — | Only iOS side has SwiftData context to build WidgetDisplayData snapshot |
| Watch-local snapshot storage | Watch App (WCSession delegate) | — | Writes Watch-scoped UserDefaults after decoding applicationContext |
| Watch complication rendering | Watch Widget Extension (WidgetKit) | — | TimelineProvider reads Watch UserDefaults; WidgetKit renders accessoryRectangular |
| Watch complication timeline reload | Watch App (WCSession delegate) | — | Calls WidgetCenter.shared.reloadAllTimelines() after writing UserDefaults |
| Watch→iPhone check-in relay send | Watch App (TodayGlanceView) | — | User taps button; WCSession.transferUserInfo sends payload |
| Watch→iPhone check-in relay receive | iOS App (WatchSessionManager) | — | didReceiveUserInfo dispatches to MainActor for GoalViewModel.addCheckIn |
| Post-check-in side effects | iOS App (GoalViewModel + NotificationScheduler) | — | rescheduleNotification, reloadWidgetTimelines, cancelGlobalStreakAtRiskNudge already on iOS main actor |
| Streak-at-risk notification cancel | iOS App (NotificationScheduler.shared) | — | UNUserNotificationCenter runs on iPhone; Watch check-in must relay to iPhone first |

---

## Standard Stack

### Core (No New External Packages)

This phase uses only Apple frameworks — no third-party packages. [VERIFIED: Apple Developer Documentation]

| Framework | Min OS | Purpose | Why Standard |
|-----------|--------|---------|--------------|
| WatchConnectivity | watchOS 2.0 / iOS 9.0 | Bidirectional iOS↔watchOS data relay | Only supported cross-device bridge; App Groups cannot cross the iPhone/Watch device boundary |
| WidgetKit | watchOS 9.0 | Watch Widget Extension complications | Required for accessoryRectangular complication family on watchOS 9+ |
| SwiftUI | watchOS 7.0+ | Watch app UI | Already in use in VitaminGWatch |
| UserNotifications | iOS 10.0+ | cancelGlobalStreakAtRiskNudge path | Already in use; no change needed |

### No Packages to Install

This phase adds zero CocoaPods, SPM, or Carthage dependencies. [VERIFIED: all required frameworks are Apple system frameworks]

---

## Package Legitimacy Audit

> Not applicable — this phase installs no external packages. All frameworks are Apple system frameworks included with the SDK.

---

## Architecture Patterns

### System Architecture Diagram

```
iPhone App                             Apple Watch
──────────────────────────────────     ──────────────────────────────────────
VitaminGApp.init()
  └─ WatchSessionManager.shared.activate()
       └─ WCSession.default.delegate = self
          WCSession.default.activate()
                                         VGWatchApp.init()
                                           └─ WatchReceiver.activate()
                                                └─ WCSession.default.delegate = self
                                                   WCSession.default.activate()

GoalViewModel.addCheckIn() ──────────── updateApplicationContext ──────────▶
  rescheduleNotification()       [snapshot: WatchSnapshot encoded as Data]
  reloadWidgetTimelines()                                                    │
  cancelGlobalStreakAtRiskNudge()                                            ▼
  WatchSessionManager.shared                               WatchReceiver.session(_:didReceiveApplicationContext:)
    .pushSnapshot(goals:events:context:)                     └─ decode WatchSnapshot
                                                             └─ write to UserDefaults(suiteName: "group.com.kyleharrington.VitaminGWatch")
                                                             └─ WidgetCenter.shared.reloadAllTimelines()

                                                           VitaminGWatchWidget (Watch Widget Extension)
                                                             └─ TimelineProvider.getTimeline()
                                                                  └─ reads UserDefaults(suiteName: "group.com.kyleharrington.VitaminGWatch")
                                                                  └─ returns WatchEntry for accessoryRectangular

TodayGlanceView (Check In tap) ◀────── transferUserInfo ──────────────────
  WatchSessionManager.didReceiveUserInfo()      ["action": "checkIn",
    └─ DispatchQueue.main.async {                "goalId": "<uuid-string>"]
         fetch Goal by id from ModelContext              │
         GoalViewModel.addCheckIn(for:context:) ◀───────┘
         reloadWidgetTimelines()
         cancelGlobalStreakAtRiskNudge()
         WatchSessionManager.pushSnapshot()  ──────────▶ updateApplicationContext
       }                                                  [hasCheckedInToday: true]
```

### Recommended Project Structure

```
VitaminG/VitaminG/VitaminG/
├── Services/
│   ├── WatchSessionManager.swift     # NEW — iOS-side WCSession singleton
│   └── (existing services)
├── Models/
│   └── WatchSnapshot.swift           # NEW — Codable struct for WCSession payload

VitaminG/VitaminGWatch/
├── VGWatchApp.swift                  # MODIFIED — activate WatchReceiver at launch
├── Shared/
│   └── WatchReceiver.swift           # NEW — watchOS-side WCSession delegate
├── Screens/
│   └── TodayGlanceView.swift         # MODIFIED — live data, transferUserInfo button

VitaminG/VitaminGWatchWidget/         # NEW TARGET (Widget Extension)
├── VitaminGWatchWidget.swift         # Widget entry point, TimelineProvider, views
└── VitaminGWatchWidget.entitlements  # NEW — App Group: group.com.kyleharrington.VitaminGWatch
```

The Watch target also needs a new `.entitlements` file with the Watch App Group.

---

### Pattern 1: WCSession Singleton — iOS Side (WatchSessionManager)

**What:** NSObject subclass conforming to WCSessionDelegate; `shared` singleton pattern matches existing services (NotificationScheduler.shared). Must inherit from NSObject because WCSessionDelegate extends NSObjectProtocol. [VERIFIED: Apple Developer Documentation]

**When to use:** Activated at VitaminGApp.init(); pushes snapshots after every GoalViewModel mutation.

**Critical invariant:** `session.delegate` must be set before `activate()` is called. Cannot call `activate()` without a delegate. [VERIFIED: Apple Developer Documentation]

```swift
// Source: Apple Developer Documentation — WCSession, WCSessionDelegate
import WatchConnectivity

final class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private override init() { super.init() }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func pushSnapshot(goals: [Goal], events: [CompletionEvent], context: ModelContext) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }
        let snapshot = WatchSnapshot.build(goals: goals, events: events, context: context)
        let data = (try? JSONEncoder().encode(snapshot)) ?? Data()
        try? WCSession.default.updateApplicationContext(["snapshot": data])
    }

    // iOS-only lifecycle methods — guard with #if os(iOS)
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate() // re-activate on watch switch
    }
    #endif

    // MARK: — Receive check-in relay from Watch
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        // WCSession delegate queue is a non-main serial background queue.
        // GoalViewModel is @MainActor — dispatch required. [VERIFIED: Apple Developer Documentation]
        DispatchQueue.main.async { [weak self] in
            self?.handleCheckIn(userInfo: userInfo)
        }
    }

    @MainActor
    private func handleCheckIn(userInfo: [String: Any]) {
        guard let action = userInfo["action"] as? String, action == "checkIn",
              let goalIdString = userInfo["goalId"] as? String,
              let goalId = UUID(uuidString: goalIdString) else { return }
        // Fetch and call GoalViewModel — see Pattern 4 for ModelContext access
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
```

---

### Pattern 2: WatchSnapshot Codable Struct

**What:** A Codable struct mirroring the fields the Watch needs. Transmitted as `Data` in the `[String: Any]` applicationContext dictionary. [ASSUMED — struct design; WCSession dict-of-Data encoding pattern is standard]

```swift
// Source: [ASSUMED] — mirrors WidgetDisplayData pattern; WCSession encoding pattern standard
struct WatchSnapshot: Codable {
    let activeGoalTitle: String?
    let activeGoalProgress: Double        // 0.0–1.0
    let globalStreak: Int
    let hasCheckedInToday: Bool
    let activeGoalId: String?             // UUID.uuidString; nil when no active goal

    static func build(goals: [Goal], events: [CompletionEvent], context: ModelContext) -> WatchSnapshot {
        let displayData = WidgetDataProvider.build(goals: goals, events: events)
        let activeGoal = GoalTier.ordered.compactMap { tier in
            goals.filter { $0.tier == tier && !$0.isCompleted }
                 .sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
                 .first
        }.first
        let hasCheckedIn = activeGoal?.completionEvents?.contains {
            Calendar.current.isDateInToday($0.completedAt ?? .distantPast)
        } ?? false
        return WatchSnapshot(
            activeGoalTitle: displayData.activeGoalTitle,
            activeGoalProgress: displayData.activeGoalProgress ?? 0.0,
            globalStreak: displayData.globalStreak,
            hasCheckedInToday: hasCheckedIn,
            activeGoalId: activeGoal?.id.uuidString
        )
    }
}
```

---

### Pattern 3: Watch-Side WCSession Receiver (WatchReceiver)

**What:** Watch-side session activation and applicationContext decoding into Watch-scoped App Group UserDefaults. [VERIFIED: Apple Developer Forums thread/734955 — DTS engineer confirmed App Group suiteName pattern for Watch app + Watch Widget Extension]

```swift
// Source: Apple Developer Forums thread/734955 + Apple Developer Documentation
import WatchConnectivity
import WidgetKit

final class WatchReceiver: NSObject, WCSessionDelegate {
    static let shared = WatchReceiver()
    private let suiteName = "group.com.kyleharrington.VitaminGWatch"

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["snapshot"] as? Data,
              let snapshot = try? JSONDecoder().decode(WatchSnapshot.self, from: data) else { return }
        writeToUserDefaults(snapshot)
        // Trigger Watch Widget Extension timeline reload — same device, WidgetCenter works here
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func writeToUserDefaults(_ snapshot: WatchSnapshot) {
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.set(snapshot.activeGoalTitle, forKey: "watchSnapshot_activeGoalTitle")
        defaults?.set(snapshot.activeGoalProgress, forKey: "watchSnapshot_activeGoalProgress")
        defaults?.set(snapshot.globalStreak, forKey: "watchSnapshot_globalStreak")
        defaults?.set(snapshot.hasCheckedInToday, forKey: "watchSnapshot_hasCheckedInToday")
        defaults?.set(snapshot.activeGoalId, forKey: "watchSnapshot_activeGoalId")
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    // watchOS does NOT have sessionDidBecomeInactive / sessionDidDeactivate — omit entirely
}
```

---

### Pattern 4: WatchSessionManager + GoalViewModel MainActor Integration

**What:** WatchSessionManager is a non-SwiftUI singleton that needs to call `GoalViewModel.addCheckIn(for:context:)`, which is `@MainActor`. The singleton cannot hold a direct `GoalViewModel` reference (not injectable at init time). The pattern is to inject the `ModelContainer` reference at activation, then create a `ModelContext` on the main actor when needed. [VERIFIED: Apple WWDC23 "Dive deeper into SwiftData" — ModelContext is MainActor-bound, cannot cross actors]

```swift
// Source: [ASSUMED] — standard pattern for cross-singleton ModelContext access
// WatchSessionManager.swift (iOS target)

extension WatchSessionManager {
    // Called from VitaminGApp after container is created
    func configure(container: ModelContainer) {
        self.container = container
    }

    @MainActor
    private func handleCheckIn(userInfo: [String: Any]) {
        guard let goalIdString = userInfo["goalId"] as? String,
              let goalId = UUID(uuidString: goalIdString),
              let container = self.container else { return }
        let context = container.mainContext
        guard let goal = (try? context.fetch(FetchDescriptor<Goal>()))?.first(where: { $0.id == goalId })
        else { return }
        // username/colorHex passed empty — Watch check-in does not write GoalGlimpse
        goalViewModel?.addCheckIn(for: goal, context: context)
        // Independently call post-check-in side effects:
        reloadWidgetTimelines()
        Task { await NotificationScheduler.shared.cancelGlobalStreakAtRiskNudge() }
        // Push updated snapshot (hasCheckedInToday now true) back to Watch
        let goals = (try? context.fetch(FetchDescriptor<Goal>())) ?? []
        let events = (try? context.fetch(FetchDescriptor<CompletionEvent>())) ?? []
        pushSnapshot(goals: goals, events: events, context: context)
    }
}
```

**Alternative approach (simpler):** Inject a closure `onCheckIn: @MainActor (UUID) -> Void` at VitaminGApp startup. This avoids circular dependency between WatchSessionManager and GoalViewModel. The planner should choose whichever fits the existing injection pattern.

---

### Pattern 5: Watch Widget Extension TimelineProvider

**What:** Watch Widget Extension reads exclusively from Watch-scoped App Group UserDefaults. No SwiftData, no ModelContainer. [VERIFIED: Apple Developer Forums thread/711567 and CONTEXT.md canonical refs]

```swift
// Source: [ASSUMED] — mirrors StreakProvider pattern from VitaminGWidget/StreakWidget.swift
import WidgetKit
import SwiftUI

struct WatchEntry: TimelineEntry {
    let date: Date
    let goalTitle: String?
    let progress: Double
    let globalStreak: Int
    let hasCheckedInToday: Bool
}

struct WatchSnapshotProvider: TimelineProvider {
    private let suiteName = "group.com.kyleharrington.VitaminGWatch"

    func placeholder(in context: Context) -> WatchEntry {
        WatchEntry(date: .now, goalTitle: "Morning run", progress: 0.72, globalStreak: 7, hasCheckedInToday: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: suiteName)
        let entry = WatchEntry(
            date: .now,
            goalTitle: defaults?.string(forKey: "watchSnapshot_activeGoalTitle"),
            progress: defaults?.double(forKey: "watchSnapshot_activeGoalProgress") ?? 0.0,
            globalStreak: defaults?.integer(forKey: "watchSnapshot_globalStreak") ?? 0,
            hasCheckedInToday: defaults?.bool(forKey: "watchSnapshot_hasCheckedInToday") ?? false
        )
        // Push-only refresh: WatchReceiver calls reloadAllTimelines() on each WCSession update
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}
```

---

### Pattern 6: accessoryRectangular Complication View

**What:** accessoryRectangular layout is approximately 150×47 pt on 44mm watch faces (varies by watch size). Supports multiple lines of text + SF Symbols or custom views. [CITED: developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications]

```swift
// Source: [ASSUMED] — mirrors StreakWidgetView pattern; accessoryRectangular standard layout
struct WatchComplicationView: View {
    let entry: WatchEntry

    var body: some View {
        if entry.hasCheckedInToday {
            // "Done" state
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(VGWatch.terraGlow)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Checked in")
                        .font(.caption2.bold())
                        .foregroundColor(VGWatch.terraGlow)
                    Text(entry.goalTitle ?? "Vitamin G")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        } else {
            // Active state
            HStack(spacing: 6) {
                VGRingView(progress: entry.progress, size: 32, lineWidth: 3, color: VGWatch.terraSoft, glow: false)
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.goalTitle ?? "No active goal")
                        .font(.caption2.bold())
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    Text("Day \(entry.globalStreak)")
                        .font(.caption2)
                        .foregroundColor(VGWatch.terraSoft)
                }
            }
        }
    }
}
```

---

### Pattern 7: `Button(intent:)` Guard for watchOS 11

**What:** Interactive widget buttons via `Button(intent:)` require watchOS 11.0+. For watchOS 10 (the minimum), the complication is tap-to-open (launches Watch app). [VERIFIED: Apple WWDC24 "What's new in watchOS 11" + Apple Developer Forums thread/732771]

```swift
// Source: Apple WWDC24 — What's new in watchOS 11
struct WatchComplicationView: View {
    let entry: WatchEntry

    var body: some View {
        if #available(watchOS 11.0, *) {
            // Interactive button — check in directly from complication
            WatchComplicationInteractiveView(entry: entry)
        } else {
            // watchOS 10 fallback — tap to open app (Link widget)
            WatchComplicationPassiveView(entry: entry)
        }
    }
}

@available(watchOS 11.0, *)
struct WatchComplicationInteractiveView: View {
    let entry: WatchEntry
    var body: some View {
        Button(intent: CheckInIntent()) {
            // complication body
        }
    }
}
```

**Decision for this phase:** The CONTEXT.md has decided to implement watchOS 10 fallback (tap-to-open app) as the primary path and guard `Button(intent:)` with `@available`. The plan should wire the passive path first and add the interactive path as a conditional upgrade — this reduces the test matrix since watchOS 10 is already in the minimum.

---

### Pattern 8: TodayGlanceView — transferUserInfo on Check In

**What:** Watch→iPhone check-in relay. `transferUserInfo` is queued delivery — survives offline. Works on physical devices only (silent no-op on Simulator). [VERIFIED: Apple Developer Forums thread/43596 + Apple Developer Documentation]

```swift
// Source: [ASSUMED] — WCSession.transferUserInfo standard pattern
Button {
    guard let goalId = snapshot.activeGoalId else { return }
    let payload: [String: Any] = ["action": "checkIn", "goalId": goalId]
    if WCSession.isSupported(), WCSession.default.activationState == .activated {
        WCSession.default.transferUserInfo(payload)
    }
    // Optimistic UI — navigate immediately, don't wait for WCSession ack
    showSuccessView = true
} label: {
    // button label
}
.disabled(snapshot.hasCheckedInToday || snapshot.activeGoalId == nil)
```

---

### Anti-Patterns to Avoid

- **Using `sendMessage(_:replyHandler:)` for check-in relay**: Requires Watch app in foreground AND paired device reachable. Use `transferUserInfo` instead — it's queued and survives offline. [VERIFIED: alexanderweiss.dev cross-referenced with Apple documentation]
- **Calling `updateApplicationContext` without activationState check**: Throws an exception if session not yet activated. Always guard with `WCSession.default.activationState == .activated`. [ASSUMED — standard defensive coding]
- **Accessing UserDefaults.standard in Watch Widget Extension**: Returns nil — must use `UserDefaults(suiteName:)` with the Watch App Group. [VERIFIED: Apple Developer Forums thread/734955]
- **Using ModelContainer in Watch Widget Extension**: iOS-only; Watch Widget Extension cannot access SwiftData. Read from Watch-scoped UserDefaults exclusively. [VERIFIED: CONTEXT.md + REQUIREMENTS.md Out of Scope]
- **Using `transferCurrentComplicationUserInfo()`**: Documented to be incompatible with WidgetKit-based complications. Use `updateApplicationContext` for complication data and call `WidgetCenter.shared.reloadAllTimelines()` on Watch receive. [VERIFIED: Apple Developer Forums thread/759389 — Apple Frameworks Engineer response]
- **Sharing iOS App Group (`group.com.kyleharrington.VitaminG`) with Watch targets**: Platform limitation — iOS and watchOS App Group containers are in different filesystem locations even with the same identifier. Watch app and Watch Widget Extension must use a separate Watch-scoped App Group (`group.com.kyleharrington.VitaminGWatch`). [VERIFIED: Apple Developer Forums thread/739235 — DTS response with filesystem paths showing different container IDs]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| iOS↔Watch data delivery | Custom TCP/CloudKit sync | `WCSession.updateApplicationContext` + `transferUserInfo` | Only reliable cross-device bridge; App Groups cannot cross device boundary |
| Complication rendering | ClockKit custom template | WidgetKit `accessoryRectangular` | ClockKit deprecated since watchOS 9; WidgetKit is the only supported API for watchOS 9+ complications |
| Watch-side persistence | SwiftData / CoreData | Watch-scoped App Group UserDefaults | ModelContainer is iOS-only; SwiftData does not run on watchOS in this project architecture |
| Queued message delivery | Retry loop with timer | `WCSession.transferUserInfo` | Built-in queue survives offline and is delivered in order when connection resumes |
| Thread dispatch for WCSession callbacks | Manual queue management | `DispatchQueue.main.async` wrapper in delegate methods | WCSession calls delegate on a non-main background queue; all SwiftData/MainActor access requires dispatch |

**Key insight:** The watch architecture is deliberately thin — Watch receives WCSession payloads, writes to UserDefaults, reads from UserDefaults. Zero SwiftData, zero network calls from Watch. All business logic lives on iPhone.

---

## Common Pitfalls

### Pitfall 1: Session Not Activated on Watch Cold Launch
**What goes wrong:** Watch app is launched from a complication tap. `VGWatchApp` may not have activated the WCSession yet. If `TodayGlanceView` tries to send `transferUserInfo` before activation completes, it silently fails.
**Why it happens:** `activate()` is asynchronous — `activationDidCompleteWith` fires on a background queue. The app's `@main` body runs before this callback.
**How to avoid:** (1) Activate WCSession in `VGWatchApp.init()` (earliest possible point). (2) Guard `transferUserInfo` calls with `activationState == .activated`. (3) Since `transferUserInfo` is queued delivery, also consider queueing the payload and sending once activated.
**Warning signs:** Check-in button tap produces no WCSession activity; `transferUserInfo` returns without error but iPhone never receives the payload.

### Pitfall 2: `transferUserInfo` is Silent No-Op on Simulator
**What goes wrong:** The check-in relay appears to work in Simulator (no crash, no error), but iPhone never receives `didReceiveUserInfo`. CI tests pass; physical device testing fails silently.
**Why it happens:** Apple documentation explicitly states the Simulator does not support `transferUserInfo`, `transferFile`, or `transferCurrentComplicationUserInfo`. [VERIFIED: Apple Developer Forums thread/127460]
**How to avoid:** All integration tests for the Watch→iPhone relay path require physical devices. Document this in all related plan tasks as a human-verify checkpoint.
**Warning signs:** No `didReceiveUserInfo` callback in iOS logs despite Watch button tap.

### Pitfall 3: `updateApplicationContext` Only Delivers the Latest Value
**What goes wrong:** If the iPhone pushes three context updates in rapid succession (e.g., during a batch goal import), the Watch only receives the third one.
**Why it happens:** This is by design — `updateApplicationContext` is a "last writer wins" snapshot, not a queue. [VERIFIED: alexanderweiss.dev]
**How to avoid:** Acceptable for this use case (snapshot of current state). Do NOT use `updateApplicationContext` for the check-in relay — use `transferUserInfo` there (queued, all delivered in order).
**Warning signs:** Only relevant if intermediate state is needed; not a problem for this phase's snapshot delivery model.

### Pitfall 4: WCSession Delegate Queue vs. MainActor
**What goes wrong:** `didReceiveUserInfo` is called on a non-main serial background queue. Calling `GoalViewModel.addCheckIn()` (which is `@MainActor`) directly from this callback causes a runtime crash or Swift concurrency warning.
**Why it happens:** WCSession documentation states all delegate methods are called on a non-main serial queue; the client is responsible for dispatching to main. [VERIFIED: Apple Developer Documentation — WCSessionDelegate]
**How to avoid:** Wrap all SwiftData/UI work in `DispatchQueue.main.async { }` or `Task { @MainActor in }`. The `WatchSessionManager.handleCheckIn` example in Pattern 4 above demonstrates this.
**Warning signs:** Swift concurrency warning "expression is 'async' but is not marked with 'await'"; EXC_BAD_ACCESS on SwiftData model access from background thread.

### Pitfall 5: Watch-Scoped App Group Not Registered in Apple Developer Portal
**What goes wrong:** `UserDefaults(suiteName: "group.com.kyleharrington.VitaminGWatch")` returns nil at runtime.
**Why it happens:** A new App Group identifier must be registered in the Apple Developer Portal under Identifiers → App Groups before Xcode can use it in entitlements. Adding the entitlement locally is not sufficient.
**How to avoid:** The Wave 0 plan task must include a human checkpoint: "Register `group.com.kyleharrington.VitaminGWatch` in Apple Developer Portal → Identifiers → App Groups, then update entitlements on both VitaminGWatch and VitaminGWatchWidget targets."
**Warning signs:** `UserDefaults(suiteName:)` returns nil; all watchSnapshot_ keys read as default values.

### Pitfall 6: `sessionDidBecomeInactive` / `sessionDidDeactivate` on watchOS
**What goes wrong:** Including `sessionDidBecomeInactive` and `sessionDidDeactivate` in the Watch-side WCSession delegate causes a compilation error — these methods are iOS-only.
**Why it happens:** The WCSessionDelegate protocol has platform-specific requirements. These two methods only exist in the iOS version of the protocol. [VERIFIED: Hacking with Swift WCSession tutorial + multiple cross-sources]
**How to avoid:** Either (1) implement a single cross-platform `WatchSessionManager.swift` with `#if os(iOS)` guards, or (2) use two separate files: `WatchSessionManager.swift` (iOS target) and `WatchReceiver.swift` (watchOS target). The two-file approach is cleaner for this project.
**Warning signs:** Compiler error "type does not conform to protocol 'WCSessionDelegate'" on watchOS target if these methods are included.

### Pitfall 7: Watch Widget Extension VGRingView Access
**What goes wrong:** The `VGRingView` and `VGWatchTheme` Swift files are in the VitaminGWatch target. The new `VitaminGWatchWidget` target cannot use them unless they are explicitly added to both targets in Xcode.
**Why it happens:** Swift source files belong to exactly one target unless manually added to multiple targets.
**How to avoid:** In Xcode, select `VGRingView.swift` and `VGWatchTheme.swift` → Target Membership → enable `VitaminGWatchWidget` checkbox. No file duplication needed.
**Warning signs:** "Use of unresolved identifier 'VGWatch'" or "cannot find type 'VGRingView'" when building the widget extension.

### Pitfall 8: `transferCurrentComplicationUserInfo()` Incompatibility
**What goes wrong:** Developer uses `transferCurrentComplicationUserInfo()` thinking it will trigger instant complication refresh. It does not work with WidgetKit complications.
**Why it happens:** `transferCurrentComplicationUserInfo()` was designed for ClockKit; WidgetKit complications use a different reload mechanism. [VERIFIED: Apple Developer Forums thread/759389 — Apple Frameworks Engineer confirmation]
**How to avoid:** Use the pattern in this research: `updateApplicationContext` for data delivery, then `WidgetCenter.shared.reloadAllTimelines()` called from the Watch app's `didReceiveApplicationContext`. Never call `transferCurrentComplicationUserInfo()`.
**Warning signs:** Complication data never updates despite WCSession activity; no error thrown.

---

## App Group Configuration — Critical Details

### Confirmed Architecture

| Group Identifier | Targets | Purpose |
|-----------------|---------|---------|
| `group.com.kyleharrington.VitaminG` | iOS app + VitaminGWidget | Existing iOS widget data sharing (UserDefaults + SwiftData container) |
| `group.com.kyleharrington.VitaminGWatch` | **VitaminGWatch** + **VitaminGWatchWidget** | NEW — Watch-local snapshot data sharing between Watch app and Watch Widget Extension |

**The iOS group cannot be shared with watchOS targets.** Even if the same identifier appears in both entitlements, the filesystem containers are different physical paths (iOS uses the phone's filesystem, watchOS uses the watch's filesystem). [VERIFIED: Apple Developer Forums thread/739235 — DTS engineer response with actual container UUID evidence]

### Xcode Entitlement Files Required

1. **New file:** `VitaminGWatch/VitaminGWatch.entitlements`
   ```xml
   <key>com.apple.security.application-groups</key>
   <array><string>group.com.kyleharrington.VitaminGWatch</string></array>
   ```

2. **New file:** `VitaminGWatchWidget/VitaminGWatchWidget.entitlements`
   ```xml
   <key>com.apple.security.application-groups</key>
   <array><string>group.com.kyleharrington.VitaminGWatch</string></array>
   ```

3. **No change to** `VitaminG/VitaminG.entitlements` or `VitaminGWidget/VitaminGWidget.entitlements`.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Physical Apple Watch (hardware) | WCSession transferUserInfo E2E test | Unknown — developer's personal device | watchOS 10+ required | None — Simulator cannot test transferUserInfo |
| iPhone paired to Watch | WCSession activation | Unknown | iOS 17+ (project minimum) | None |
| Apple Developer Portal access | New App Group registration | ✓ (assumed — project has existing groups) | N/A | None — blocking |
| Xcode 16+ | watchOS 10+ SDK, WidgetKit for watchOS 9+ | Unknown | N/A | Xcode 15 may work for watchOS 10 target |

**Missing dependencies with no fallback:**
- Physical Apple Watch device — required before any WCSession integration task can be marked complete. STATE.md already documents: "Physical device testing required before merging any WatchConnectivity code (Phase 27)"
- Apple Developer Portal App Group registration — `group.com.kyleharrington.VitaminGWatch` must be registered before Watch entitlements work at runtime

**Missing dependencies with fallback:**
- WCSession data flow can be partially verified via mock/stub approach in unit tests (mock WCSession delegate callbacks)

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (existing VitaminGTests target) |
| Config file | None — uses Xcode test scheme |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Full suite command | Same — all tests in VitaminGTests |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WATCH-02 | WatchSnapshot.build() produces correct fields from goals/events | unit | `xcodebuild test -only-testing:VitaminGTests/WatchSnapshotTests` | ❌ Wave 0 |
| WATCH-02 | WatchReceiver writes correct UserDefaults keys from applicationContext | unit | `xcodebuild test -only-testing:VitaminGTests/WatchReceiverTests` | ❌ Wave 0 |
| WATCH-03 | WatchSessionManager.handleCheckIn calls addCheckIn for correct goal | unit | `xcodebuild test -only-testing:VitaminGTests/WatchSessionManagerTests` | ❌ Wave 0 |
| WATCH-03 | WatchSessionManager.handleCheckIn calls cancelGlobalStreakAtRiskNudge | unit | `xcodebuild test -only-testing:VitaminGTests/WatchSessionManagerTests` | ❌ Wave 0 |
| WATCH-03 | WatchSessionManager.handleCheckIn calls WidgetCenter.reloadAllTimelines | unit (mock) | `xcodebuild test -only-testing:VitaminGTests/WatchSessionManagerTests` | ❌ Wave 0 |
| WATCH-02/03 | Full round-trip: iPhone push → Watch receive → Watch check-in → iPhone update | E2E | manual-only (physical device required) | N/A |

### Sampling Rate
- **Per task commit:** `xcodebuild test -only-testing:VitaminGTests/WatchSessionManagerTests -only-testing:VitaminGTests/WatchSnapshotTests -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green + physical device E2E verification before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `VitaminGTests/WatchSnapshotTests.swift` — covers WATCH-02 snapshot build
- [ ] `VitaminGTests/WatchSessionManagerTests.swift` — covers WATCH-03 receive handler
- [ ] `VitaminGTests/WatchReceiverTests.swift` — covers WATCH-02 UserDefaults write

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ClockKit complications | WidgetKit complications (accessoryRectangular) | watchOS 9 (2022) | Must use WidgetKit; ClockKit deprecated and removed |
| `transferCurrentComplicationUserInfo()` instant push | `updateApplicationContext` + `WidgetCenter.reloadAllTimelines()` | watchOS 9 (WidgetKit migration) | `transferCurrentComplicationUserInfo` does not work with WidgetKit |
| WatchKit extension (separate process) | watchOS app (single process, SwiftUI) | watchOS 7 | VitaminGWatch already uses modern SwiftUI app architecture |
| `InterfaceController` (WKInterfaceController) | SwiftUI `View` + `@main App` | watchOS 7 | VGWatchApp already uses this |

**Deprecated/outdated:**
- ClockKit: removed in watchOS 9; all complications must use WidgetKit
- `WKInterfaceController`: removed; replaced by SwiftUI
- `WKExtensionDelegate`: removed; `@main App` struct replaces it
- `transferCurrentComplicationUserInfo()`: documented incompatible with WidgetKit complications

---

## Watchos Deployment Target: Immediate Action Required

**Current state:** `WATCHOS_DEPLOYMENT_TARGET = 7.0` in both Debug and Release configurations of the VitaminGWatch target (confirmed in project.pbxproj lines 553, 978).

**Required:** Must be raised to `10.0` per STATE.md locked decision ("watchOS 10.0 minimum for Watch target") AND to use WidgetKit complications (requires watchOS 9.0 minimum).

**How:** Xcode project settings → VitaminGWatch target → Deployment Info → Minimum Deployments → watchOS 10.0. This must be a Wave 0 task before any other Watch code changes.

---

## Runtime State Inventory

> This is a code/feature addition phase, not a rename/refactor. However, two pre-existing runtime state items are affected by Phase 27:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | No existing Watch-related stored data | None |
| Live service config | No Watch app group registered yet (`group.com.kyleharrington.VitaminGWatch`) | Register in Apple Developer Portal before runtime testing |
| OS-registered state | No Watch complications registered yet | None — user adds complication manually during testing |
| Secrets/env vars | No WCSession-specific secrets | None |
| Build artifacts | VitaminGWatch.app built with watchOS 7.0 deployment target | Must rebuild after raising to watchOS 10.0 |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `WatchSnapshot` struct design (field names, Codable encoding as Data in dict) | Pattern 2 | Low — struct is internal; can be renamed without user impact |
| A2 | `WatchSessionManager.configure(container:)` injection pattern for ModelContainer | Pattern 4 | Medium — alternate approach is closure injection; both work |
| A3 | WatchComplicationView layout code for accessoryRectangular | Pattern 6 | Low — layout can be adjusted during implementation; constraints confirmed |
| A4 | `@available(watchOS 11.0, *)` guard for `Button(intent:)` pattern | Pattern 7 | Low — `@available` syntax is stable; interactive complications may need CheckInIntent struct |

---

## Open Questions

1. **WatchSessionManager and GoalViewModel injection path**
   - What we know: GoalViewModel is `@MainActor @Observable`; WatchSessionManager.shared is a singleton with no SwiftUI environment access
   - What's unclear: Whether to inject via `configure(container:)` call + direct ModelContext creation, or via closure injection at VitaminGApp startup
   - Recommendation: Use closure injection in VitaminGApp (simpler, avoids storing ModelContainer in WatchSessionManager): `WatchSessionManager.shared.onCheckIn = { [container] goalId in await goalViewModel.handleRemoteCheckIn(goalId: goalId, context: container.mainContext) }`. The planner chooses the specific injection pattern.

2. **CheckInSuccessView dynamic data (streak number, day number)**
   - What we know: `CheckInSuccessView` currently shows hardcoded "Day 65 logged. Streak: 13 🔥" — see line 55-60 of CheckInSuccessView.swift
   - What's unclear: Should Phase 27 also update CheckInSuccessView to show live streak from WatchSnapshot?
   - Recommendation: Yes — pass the WatchSnapshot's `globalStreak + 1` (optimistic) to CheckInSuccessView. Minor change, high polish impact.

3. **Watch App Group Apple Developer Portal registration**
   - What we know: `group.com.kyleharrington.VitaminG` already exists; `group.com.kyleharrington.VitaminGWatch` does not
   - What's unclear: When should this human step happen in the wave ordering?
   - Recommendation: Wave 0 human checkpoint — block all subsequent tasks on confirmation that the new group is registered and both entitlements files are created.

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Forums thread/759389 — Apple Frameworks Engineer confirmed `transferCurrentComplicationUserInfo()` incompatible with WidgetKit
- Apple Developer Forums thread/734955 — WatchOS App Group + Watch Widget Extension correct pattern (suiteName required)
- Apple Developer Forums thread/711567 — App Groups supported between Watch app and Watch Widget Extension
- Apple Developer Forums thread/739235 — DTS engineer confirmed iOS and watchOS App Group containers are different filesystem locations
- Apple Developer Documentation — WCSessionDelegate (delegate called on non-main serial queue)
- Apple Developer Documentation — WCSession (activation lifecycle, isSupported, delegate requirement)
- Apple WWDC24 "What's new in watchOS 11" — Button(intent:) interactive complications require watchOS 11

### Secondary (MEDIUM confidence)
- alexanderweiss.dev — Three Ways to Communicate via WatchConnectivity (updateApplicationContext vs transferUserInfo delivery semantics, cross-verified with Apple docs)
- Apple Developer Forums thread/127460 — transferUserInfo Simulator no-op limitation (multiple confirmations)
- Apple Developer Forums thread/43596 — WCSession simulator limitations cross-confirmed

### Tertiary (LOW confidence)
- N/A — no claims rely solely on tertiary sources

---

## Metadata

**Confidence breakdown:**
- WCSession delivery semantics (updateApplicationContext vs transferUserInfo): HIGH — Apple documentation + cross-referenced forum posts with DTS responses
- App Group architecture (Watch-scoped separate from iOS): HIGH — DTS engineer response with filesystem UUID evidence
- Watch Widget Extension setup: HIGH — confirmed by Apple Frameworks Engineer and multiple forum threads
- `transferCurrentComplicationUserInfo()` incompatibility: HIGH — Apple Frameworks Engineer direct statement
- WatchSnapshot struct design: ASSUMED — internal detail, low risk
- GoalViewModel injection pattern: ASSUMED — planner's discretion

**Research date:** 2026-06-02
**Valid until:** 2026-09-02 (watchOS and WidgetKit APIs stable; WatchConnectivity behavior unchanged since watchOS 9)
