# Phase 27: Apple Watch App - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire the already-scaffolded `VitaminGWatch` target to live data via WatchConnectivity, add a real `accessoryRectangular` WidgetKit complication in a new Watch Widget Extension target, and implement the bidirectional WCSession relay:

1. **iPhone → Watch snapshot** (WATCH-02) — iPhone pushes `activeGoalTitle`, `activeGoalProgress`, `globalStreak`, and `hasCheckedInToday` via `WCSession.updateApplicationContext` whenever goal/check-in state changes; Watch complication and `TodayGlanceView` read from Watch-local UserDefaults populated by the WCSession delegate
2. **Watch → iPhone check-in relay** (WATCH-03) — User taps Check In on `TodayGlanceView`; Watch sends a `WCSession.transferUserInfo` payload to iPhone; iPhone receives it in a `WCSessionManager` service, calls `GoalViewModel.addCheckIn()` for the relevant goal, reloads widgets, and cancels the streak-at-risk notification via the same `cancelGlobalStreakAtRiskNudge()` path used by iOS and widget check-in surfaces

</domain>

<decisions>
## Implementation Decisions

### TodayGlanceView Data (D-01, D-02)

- **D-01:** The progress ring in `TodayGlanceView` is driven by **`activeGoalProgress`** (0.0–1.0) from the WCSession snapshot. Ring center text shows the percentage (e.g., "72%") or fraction. Consistent with the complication, which also shows the active goal + ring. (`WidgetDisplayData.activeGoalProgress` already computed by `WidgetDataProvider.build()` — mirror this field in the Watch snapshot struct.)
- **D-02:** `TodayGlanceView` header: **"Day [globalStreak]"** (actual streak from WCSession snapshot, replacing hardcoded "Day 65"). Below the ring: **active goal title** in small text (replacing no goal title in the current hardcoded view). Layout matches the existing serif "Day X" + italic streak number pattern already in the view.

### Claude's Discretion

- **Check-in scope**: Which goal(s) get checked in when user taps Check In on Watch. Recommended: check in the single `activeGoal` (the one shown in the complication) by including its `goalId` in the `transferUserInfo` payload. Consistent with the iOS per-goal `addCheckIn(for:)` model and the complication's single-goal framing. If `activeGoal` is nil (all goals completed), disable the Check In button.
- **Watch check-in feedback**: Whether the transition to `CheckInSuccessView` is immediate (optimistic) or waits for WCSession queuing acknowledgment. Recommended: optimistic — transition immediately on button tap; `transferUserInfo` delivery to iPhone happens in background. `CheckInSuccessView` is already built with the glow bloom animation.
- **Complication checked-in state**: Whether the `accessoryRectangular` complication changes appearance (e.g., checkmark, "Done") after today's check-in. Recommended: yes — include `hasCheckedInToday: Bool` in the Watch snapshot; complication swaps to a "checked in" layout when true. Requires iPhone to push an updated `applicationContext` after processing the check-in relay.
- **WatchSessionManager placement on iOS**: Recommended: a dedicated `WatchSessionManager` service (mirrors existing service pattern — `NotificationScheduler`, `StreakEngine`, etc.) initialized at `VitaminGApp` startup via `WatchSessionManager.shared.activate()`.
- **Watch-local UserDefaults key prefix**: Recommend `"watchSnapshot_"` keys in standard `UserDefaults` on the Watch side (Watch app and Watch Widget Extension share the same container via an App Group named `group.com.kyleharrington.VitaminGWatch` or reusing the existing `group.com.kyleharrington.VitaminG` if the Watch target is added to the same group).
- **Watch Widget Extension target name**: Recommend `VitaminGWatchWidget` — a new Widget Extension added to the `VitaminGWatch` app in Xcode.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Requirements
- `.planning/ROADMAP.md` §Phase 27 — goal, success criteria, requirements (WATCH-02, WATCH-03)
- `.planning/REQUIREMENTS.md` §WATCH-02, WATCH-03 — full requirement definitions including WCSession delivery mechanism and check-in relay behavior

### Existing Watch Target (read before touching)
- `VitaminG/VitaminGWatch/VGWatchApp.swift` — Watch app entry point; WatchSessionManager must be activated here
- `VitaminG/VitaminGWatch/VGWatchContentView.swift` — TabView with TodayGlanceView at tag 0; this is the complication tap target
- `VitaminG/VitaminGWatch/Screens/TodayGlanceView.swift` — hardcoded check-in screen; Phase 27 replaces hardcoded values with live WCSession snapshot data; Check In button must call WCSession.transferUserInfo
- `VitaminG/VitaminGWatch/Screens/CheckInSuccessView.swift` — already-built success animation screen; transition here after check-in tap
- `VitaminG/VitaminGWatch/Shared/VGRingView.swift` — reusable ring component; use for complication progress ring
- `VitaminG/VitaminGWatch/Shared/VGWatchTheme.swift` — `VGWatch` color tokens; use for all Watch UI colors

### Existing iOS Services (read before extending)
- `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` — `addCheckIn(for:context:)` at line ~169; `cancelGlobalStreakAtRiskNudge()` Task already present; WatchSessionManager must call this path
- `VitaminG/VitaminG/VitaminG/Services/WidgetDataProvider.swift` — `WidgetDisplayData` struct with `activeGoalTitle`, `activeGoalProgress`, `globalStreak`; `WidgetDataProvider.build(goals:events:)` computes these fields; mirror this struct or a subset as the Watch snapshot payload
- `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` — `cancelGlobalStreakAtRiskNudge()` — this method must be called by the WatchSessionManager's receive handler after a successful Watch check-in

### Existing Widget Target (reference for complication pattern)
- `VitaminG/VitaminG/VitaminGWidget/StreakWidget.swift` — `StreakProvider: TimelineProvider`, `.supportedFamilies([.accessoryRectangular])` — copy the TimelineProvider pattern for the new Watch Widget Extension; the Watch extension uses the same WidgetKit APIs but must read from Watch-local UserDefaults (not ModelContainer, which is iOS-only)
- `VitaminG/VitaminG/VitaminGWidget/GoalSummaryWidget.swift` — `WidgetContainerCache` singleton, `GoalSummaryProvider` — do NOT copy the ModelContainer approach for Watch; Watch widget reads from UserDefaults only

### Prior Phase Context
- `.planning/STATE.md` — key decisions: "WatchConnectivity (not App Groups) for iOS-Watch data bridge", "Watch check-in must cancel streak-at-risk notification via same path as iOS/widget", "watchOS 10.0 minimum for Watch target", "Button(intent:) interactive complications require watchOS 11.0, guard with @available", "Physical device testing required before merging any WatchConnectivity code"
- `.planning/REQUIREMENTS.md` §Out of Scope — "Watch-native SwiftData store" is out of scope; Watch widget reads from UserDefaults only

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `VGRingView(progress:size:lineWidth:color:)` — already in Watch target (`VitaminGWatch/Shared/VGRingView.swift`); use directly in the complication view and TodayGlanceView; supports `animated: Bool` parameter
- `WidgetDisplayData` fields `activeGoalTitle`, `activeGoalProgress`, `globalStreak` — already computed by `WidgetDataProvider.build()`; define a mirroring `WatchSnapshot` struct (or reuse `WidgetDisplayData`) as the WCSession payload; include `hasCheckedInToday: Bool` and `activeGoalId: String?` as additional fields
- `WidgetDataProvider.build(goals:events:)` — pure static function; call this on the iOS side inside `WatchSessionManager` to build the snapshot before pushing via `updateApplicationContext`
- `CheckInSuccessView` — fully built success animation; `appeared` `@State` var drives the glow bloom; just navigate to it after check-in tap
- `VGWatch` color tokens — complete set including `terra`, `terraSoft`, `terraGlow`, `sageBright`, `gold`, `plum`; use for complication and updated TodayGlanceView

### Established Patterns
- **`updateApplicationContext` for state sync** — `WCSession.updateApplicationContext([String: Any])` for push-on-mutation delivery (replaces stale complication data); call after every `addCheckIn`, `GoalViewModel` save, and app foreground
- **`transferUserInfo` for check-in relay** — queued delivery; survives Watch going out of range; Watch calls this; iPhone receives in `WCSession(_ session:didReceiveUserInfo:)` delegate method
- **Service singleton pattern** — all services (`NotificationScheduler.shared`, `WidgetDataProvider` static) use `shared` singleton or static methods; `WatchSessionManager.shared` follows this pattern
- **Widget push-only refresh** — `WidgetCenter.shared.reloadAllTimelines()` is already called in `GoalViewModel.addCheckIn()`; WatchSessionManager's receive handler calls this after processing the Watch check-in, so the home screen widget also updates
- **App Group UserDefaults** — `UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")` used for widget-visible keys; a parallel App Group for Watch (`group.com.kyleharrington.VitaminGWatch`) may be needed if the Watch Widget Extension cannot share the iOS App Group; planner to verify Xcode entitlements

### Integration Points
- **iOS side**: `VitaminGApp` → activate `WatchSessionManager.shared` at startup; `GoalViewModel.addCheckIn()` → after saving, call `WatchSessionManager.shared.pushSnapshot(goals:events:context:)` to update Watch complication
- **Watch side**: `VGWatchApp` → activate `WCSession`; receive delegate callbacks; store snapshot in UserDefaults; `TodayGlanceView` → read from UserDefaults via `@AppStorage` or a Watch-side ViewModel; `Check In` button → call `WCSession.transferUserInfo(["action": "checkIn", "goalId": activeGoalId])`
- **Watch Widget Extension**: new target `VitaminGWatchWidget`; `TimelineProvider` reads Watch-local UserDefaults; `WidgetKit.WidgetCenter` reload triggered from Watch app's WCSession delegate after receiving updated snapshot

</code_context>

<specifics>
## Specific Ideas

- `TodayGlanceView` header replaces hardcoded `"Day 65"` with `"Day \(snapshot.globalStreak)"` using the existing serif `VGWatch.serif(22)` font; the italic streak number style (e.g., `Text("65").font(VGWatch.serif(22, italic: true)).foregroundColor(VGWatch.terraSoft)`) carries over
- The `WatchSnapshot` struct (or `WidgetDisplayData` extension) should be `Codable` so it can be encoded/decoded for WCSession `applicationContext` dictionary (`try? JSONEncoder().encode(snapshot)` → `Data` → stored as `[String: Any]`)
- `WatchFaceView.swift` already has a comment "To activate as a real complication, add a WidgetKit target (File > New > Target > Widget Extension) and reference VGWatch colors + VGRingView from this source set" — follow exactly
- Physical device testing is required for all WCSession behavior (Simulator cannot test `transferUserInfo` end-to-end); STATE.md pending todo: "Physical device testing required before merging any WatchConnectivity code (Phase 27)"

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 27-apple-watch-app*
*Context gathered: 2026-06-02*
