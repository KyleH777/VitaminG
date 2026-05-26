# Phase 23: Milestone Features + Streak Freeze - Research

**Researched:** 2026-05-25
**Domain:** SwiftUI / SwiftData / UserNotifications / CloudKit — streak mechanics, celebration screens, community sharing
**Confidence:** HIGH (all findings verified from codebase reads; no external package installs required)

---

## Summary

Phase 23 adds six related features that together form a "streak protection and celebration" layer on top of the existing goal-tracking core. The codebase is already further along than the phase description implies: `StreakFreezeService` exists but uses a monthly reset, not the weekly ISO8601 reset required by MILE-01; `MilestoneCelebrationView` exists but is wired to `UserChallenge` milestones (thresholds 7/30/60/90), not goal-streak milestones; and `CheckInCelebrationView` exists and provides the confetti + Canvas pattern that MILE-06's goal-completion page should clone. The notification infrastructure (`NotificationScheduler`, `NotificationPreferences`) is mature and follows a strict remove-before-add pattern against the iOS 64-notification cap, which must be respected when adding the MILE-02 streak-at-risk nudge.

The biggest schema work is in `SchemaV10`: adding `Goal.streakFreezeUsedWeekISO` (ISO8601 week key to track "freeze used this week"), `Goal.streakMilestonesShownJSON` (persisted set of shown milestone thresholds), and optionally `Goal.completionCelebrationShown` (Bool). A `StreakAchievement` CloudKit record type (a new `recordType` string constant in `CommunityService`) handles MILE-05 community sharing of achievements — reusing the existing public CloudKit database write pattern, not a new SwiftData model.

The `HeatmapView` requires a targeted extension: it currently displays completion-count cells using `[Date: Int]`; frozen days need a sentinel value (e.g., `-1`) so the view can render ❄️ instead of the green-intensity color. `StatsViewModel.buildHeatmapData` must merge frozen dates from `StreakFreezeService` before passing the dictionary to `HeatmapView`.

**Primary recommendation:** Implement in four waves — (1) schema + service layer corrections, (2) UI views (heatmap extension, goal-streak milestone screen, goal-completion screen), (3) notification nudge, (4) community achievement sharing. No third-party packages are needed.

---

## Project Constraints (from CLAUDE.md)

- **No third-party dependencies** unless necessary — use SwiftUI Canvas confetti (already established), SwiftData, CloudKit, UserNotifications only.
- **iOS 17+ minimum** — all APIs must be iOS 17 compatible.
- **MVVM strictly enforced** — no business logic in Views.
- **All String inputs** must have character limits and sanitization (`InputSanitizer.sanitizeForPublic`).
- **CloudKit model rules** — all new SwiftData `@Model` properties must be optional or have defaults; no `@Attribute(.unique)`.
- **UserDefaults key pattern** — `vg_` prefix for App Group / standard keys; `vg.streakFreeze.*` for `StreakFreezeService` internal keys.
- **`@Observable` macro** — not `ObservableObject`.
- **Character limits** — existing goals use max 100 title, 500 description; share text must apply `InputSanitizer.sanitizeForPublic`.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MILE-01 | "Life happened." streak freeze — once per week (ISO8601 Monday reset), preserves streak count, frozen day shows ❄️ in heatmap | `StreakFreezeService` exists; `canFreeze` must change from monthly to ISO8601 weekly check; `StreakEngine.currentStreak(frozenDates:)` already accepts frozen dates |
| MILE-02 | "Streak at risk" notification/in-app nudge at 7 PM if not checked in and freeze available | `NotificationScheduler.scheduleStreakAtRiskReminder` pattern exists (fires at 20:00 per challenge); must add goal-level variant at 19:00; cap guard required |
| MILE-03 | Frozen days display as ❄️ in streak calendar/heatmap | `HeatmapView` takes `[Date: Int]`; sentinel value `-1` for frozen days; `cellColor(for:)` needs a frozen branch; `StatsViewModel.buildHeatmapData` must merge frozen dates |
| MILE-04 | Achievement unlocked full-screen at streak milestones 7/14/30/60/90/365 — confetti, milestone label, "Share to Community" CTA, each shown only once (persisted) | `MilestoneCelebrationView` exists but is challenge-scoped; need `GoalStreakMilestoneView` with UserDefaults persistence keyed `vg_milestone_shown_{goalID}_{threshold}`; `CheckInCelebrationView` confetti pattern is the template |
| MILE-05 | Shared achievements scroll in Community feed alongside regular posts | New `StreakAchievement` CloudKit record type in public DB; `CommunityHubViewModel.feedPosts` already a `[CKRecord]` array; feed card needs type discriminator |
| MILE-06 | "You did it" goal completed page — animated checkmark, goal title, goal-specific streak count, confetti, ShareLink + "Back to Goals" | No existing goal-completion celebration; `CheckInCelebrationView` is the template; `goal.isCompleted = true` is the trigger in `GoalViewModel.toggleCompletion` |

</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Streak freeze availability check | Service (`StreakFreezeService`) | View (reads `canFreeze`) | Business rule belongs in service, not view |
| Weekly ISO8601 reset logic | Service (`StreakFreezeService`) | — | Purely computed from stored date vs current ISO week |
| Frozen day heatmap display | View (`HeatmapView`) | ViewModel (`StatsViewModel`) | View renders sentinel; ViewModel injects merged data |
| Streak milestone detection | ViewModel (`GoalViewModel` / `StreakEngine`) | — | Computed at check-in time; existing `milestoneJustCrossed` pattern |
| Milestone shown-once persistence | Service (UserDefaults helper) | ViewModel | Must survive app restarts; different from in-session `firedMilestones` |
| Goal-streak milestone celebration UI | View (`GoalStreakMilestoneView`) | — | Full-screen cover; no business logic |
| Goal completion celebration UI | View (`GoalCompletionCelebrationView`) | — | Full-screen cover; clone of `CheckInCelebrationView` |
| Streak-at-risk notification scheduling | Service (`NotificationScheduler` extension) | ViewModel | Scheduling side-effect after check-in |
| Community achievement sharing | Service (`CommunityService` extension) | ViewModel | CloudKit write to public DB |
| Achievement feed display | View (`GlobalFeedSection` / new card) | ViewModel (`CommunityHubViewModel`) | CKRecord type discriminator in existing feed |

---

## Codebase Findings

### Q1: How does the current streak calculation work?

[VERIFIED: codebase] `StreakEngine.currentStreak(from:tier:frozenDates:calendar:)` in `StreakEngine.swift` is the sole source of truth. It builds a `Set<Date>` of calendar start-of-day values from `CompletionEvent.completedAt`, unions in `frozenDates`, then walks backward from today (or yesterday if today has no event) counting consecutive days. It is a pure static method — no SwiftData context required. `StatsViewModel.refresh(events:goals:frozenDates:)` calls it on every `events.count` / `goals.count` change.

### Q2: Does a "missed day" concept exist in the data model?

[VERIFIED: codebase] No. A "missed day" is purely derived — any calendar day without a `CompletionEvent` AND not in `frozenDates` is a miss. There is no stored "missedDate" field. This means the at-risk nudge (MILE-02) must compute at notification-fire time whether today has a check-in, not rely on stored state.

### Q3: What is the existing heatmap view implementation?

[VERIFIED: codebase] `HeatmapView` (`Views/HeatmapView.swift`) accepts `data: [Date: Int]` pre-built by `StatsViewModel.buildHeatmapData`. It renders a `LazyVGrid` with 7-column cells. `cellColor(for:)` maps count to green intensity: 0 = systemFill, 1 = .green.opacity(0.3), 2 = .green.opacity(0.6), 3+ = .green. There is no branch for frozen days. The view has a `windowDays: Int = 90` parameter.

**Required change for MILE-03:** Add a `frozenDates: Set<Date>` parameter (or encode frozen as sentinel `-1` in the data dict). The sentinel approach (`-1`) requires no new parameter and matches the existing data-shape contract — `StatsViewModel.buildHeatmapData` merges them before passing the dict.

### Q4: How does the community feed consume posts?

[VERIFIED: codebase] `GlobalFeedSection` takes `feedPosts: [CKRecord]` from `CommunityHubViewModel`. Records are rendered via `CommunityPostCard(post: CKRecord, ...)`. Record type is `CommunityService.postRecordType = "CommunityPost"`. The ViewModel's `feedPosts` is a `[CKRecord]` array populated by `CommunityService.fetchGlobalPosts`. No model-object wrapper — raw `CKRecord` throughout the feed path.

**Required change for MILE-05:** A `StreakAchievement` record type needs a discriminator field (e.g., `recordKind: "achievement"`) so `CommunityPostCard` (or a new `StreakAchievementCard`) can branch on record type. Alternatively, fetch achievements separately and interleave in `CommunityHubViewModel.loadAll`.

### Q5: UserDefaults key pattern for one-time achievement persistence

[VERIFIED: codebase] The `ApplauseGate` uses key `"vg_community_applauseGiven"` storing a JSON-encoded `[String: Date]` dict. The `MilestoneCelebrationView` uses `UserChallenge.earnedBadgeSymbolsJSON` (a SwiftData stored JSON string) for idempotent persistence. For MILE-04 (goal streak milestones), the correct pattern is UserDefaults JSON — because these milestones are per-goal and per-threshold, not tied to a SwiftData relationship. Pattern to follow:

```
Key: "vg_milestone_shown"
Value: JSON-encoded [String: Bool] where key is "\(goalID.uuidString)-\(threshold)"
```

This mirrors how `firedMilestones: Set<String>` works in-memory in `GoalViewModel`, but persisted to UserDefaults so "shown only once" survives app restarts.

### Q6: Is there a confetti library or custom SwiftUI animation?

[VERIFIED: codebase] No third-party library. The confetti implementation is a `TimelineView(.animation)` + `Canvas` pattern used in both `MilestoneCelebrationView` and `CheckInCelebrationView`. It renders 60 particles using golden-angle scatter, hue-varied colors, and downward y-drift wrapping at screen height. Both files contain identical implementations with a comment noting it is "copied verbatim." MILE-04 and MILE-06 should use this same implementation (copy the inner `confettiView` computed property).

### Q7: How is goal completion currently detected?

[VERIFIED: codebase] `GoalViewModel.toggleCompletion(goal:context:)` sets `goal.completed = true` (via the `completed` computed property that wraps `isCompleted`). There is no `completionDate` field. The `isCompleted: Bool = false` stored property in `SchemaV9.Goal` is the flag. MILE-06's "You did it" page should be triggered by `toggleCompletion` setting `isCompleted = true` — a `@State var showingCompletionCelebration = false` in the caller view (e.g., `GoalDetailView`) toggled after the call.

There is no automatic detection of "all durationDays checked in." The `isCompleted` flag is set only by explicit user action via `toggleCompletion`. If MILE-06 should fire automatically when `completionEvents.count >= durationDays`, that is a behavior change that needs user confirmation (see Open Questions).

### Q8: Weekly ISO8601 Monday reset for freeze availability

[VERIFIED: codebase] The existing `StreakFreezeService.canFreeze` uses `Calendar.current.isDate(_:equalTo:_:toGranularity:.month)` — monthly, not weekly. The requirement is weekly with ISO8601 Monday boundary.

The correct replacement uses `Calendar(identifier: .iso8601)` (already used in `CommunityHubViewModel` for `GlowingSelector`):

```swift
// Inside StreakFreezeService
var canFreeze: Bool {
    guard let lastDate = lastFreezeDate else { return true }
    let iso = Calendar(identifier: .iso8601)
    let lastWeek = iso.component(.weekOfYear, from: lastDate)
    let currentWeek = iso.component(.weekOfYear, from: Date())
    let lastYear = iso.component(.year, from: lastDate)
    let currentYear = iso.component(.year, from: Date())
    return lastWeek != currentWeek || lastYear != currentYear
}
```

The `freeze(on:)` method and `frozenDates` array storage require no change — only `canFreeze` and the UX copy ("once per week" not "once per month") change.

### Q9: Notification scheduling approach for 7 PM at-risk nudge

[VERIFIED: codebase] `NotificationScheduler` has `scheduleStreakAtRiskReminder(challengeID:challengeTitle:)` at 20:00 repeating. The MILE-02 nudge fires at 19:00 and is per-app (not per-challenge). The cleanest approach is a new static identifier `"com.kyleharrington.VitaminG.streakAtRisk.global"` with a repeating `UNCalendarNotificationTrigger` at 19:00. The notification should be cancelled same-day when `addCheckIn` is called (like challenge streak-at-risk reminders are cancelled on check-in). The iOS 64-cap guard from `scheduleStreakAtRiskReminder` (check `pending.count < 60` before adding) must be replicated.

**Critical difference from challenge variant:** The global nudge condition ("not checked in today AND freeze available") cannot be evaluated at scheduling time — it fires unconditionally at 19:00 and the app must suppress presentation in `UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:)` if the condition is not met. However, since iOS does not allow conditional presentation suppression for pending requests, the standard approach is to reschedule/cancel the notification at check-in time via `cancelStreakAtRiskGlobal()` called from `addCheckIn`.

### Q10: CloudKit record type for shared achievements

[VERIFIED: codebase] The community feed uses raw `CKRecord` objects fetched from the public CloudKit database. `CommunityService` defines record type strings as `static let` constants. The pattern is to add a new constant:

```swift
static let streakAchievementRecordType = "StreakAchievement"
```

Fields to write: `username`, `authorColorHex`, `goalTitle`, `streakLength`, `milestoneThreshold`, `authorID` (for de-duplication). This mirrors `GoalGlimpse` field structure. The achievement record is written once per milestone-threshold per user and should be de-duplicated by fetching before writing (same upsert pattern as `writeGlimpse`).

For MILE-05 display, `CommunityHubViewModel.loadAll` can fetch `StreakAchievement` records separately and interleave with `feedPosts`, or `fetchGlobalPosts` can be extended to include both record types. Separate fetch + interleave by date is cleaner and avoids a compound query.

---

## Standard Stack

No new packages. All implementation uses the established in-project stack.

| Library/Framework | Version | Purpose | Why Standard |
|---|---|---|---|
| SwiftData | iOS 17+ | Schema migration for new Goal fields | Project standard |
| SwiftUI (Canvas + TimelineView) | iOS 17+ | Confetti animation for MILE-04, MILE-06 | Already implemented; no SpriteKit |
| UserNotifications | iOS 10+ | 7 PM streak-at-risk nudge (MILE-02) | Project standard |
| CloudKit (public DB) | iOS 17+ | StreakAchievement record write/read (MILE-05) | Project standard |
| ShareLink | iOS 16+ | "Share to Community" and "Share" on completion page | Native SwiftUI; already used in ProfileView |

## Package Legitimacy Audit

> No external packages are being installed in this phase. All implementation is first-party Apple frameworks and in-project code.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
User action (check-in / toggleCompletion)
         │
         ▼
GoalViewModel.addCheckIn / toggleCompletion
         │
         ├─► StreakEngine.currentStreak(frozenDates:)
         │         └─► streak value
         │
         ├─► StreakMilestoneGate.justCrossed(streak, goalID)
         │         └─► threshold? → @State pendingGoalMilestone
         │
         ├─► NotificationScheduler.cancelStreakAtRiskGlobal()  [MILE-02]
         │
         └─► [if toggleCompletion && isCompleted]
                   └─► @State showingCompletionCelebration = true  [MILE-06]

pendingGoalMilestone set
         │
         ▼
GoalListView / GoalDetailView .onChange
         │
         ├─► .fullScreenCover → GoalStreakMilestoneView  [MILE-04]
         │         └─► "Share to Community" → CommunityService.writeStreakAchievement
         │
         └─► StreakMilestoneGate.markShown(goalID, threshold)  [UserDefaults persist]

StatsView.onAppear / onChange
         │
         ▼
StatsViewModel.refresh(events, goals, frozenDates: StreakFreezeService.frozenDates)
         │
         ├─► StreakEngine.currentStreak(frozenDates:)
         └─► buildHeatmapData(events, frozenDates)  [sentinel -1 for frozen days]
                   └─► HeatmapView(data:)  [❄️ cell for value == -1]  [MILE-03]

UNCalendarNotificationTrigger at 19:00 daily  [MILE-02]
         │
         └─► "Streak at risk" — cancelled by addCheckIn same-day

CommunityHubViewModel.loadAll
         │
         ├─► CommunityService.fetchGlobalPosts → [CKRecord]
         └─► CommunityService.fetchStreakAchievements → [CKRecord]
                   └─► interleaved by creationDate → feedPosts  [MILE-05]
```

### Recommended Project Structure Changes

```
Services/
├── StreakFreezeService.swift          # MODIFY: canFreeze → ISO8601 weekly
├── StreakMilestoneGate.swift          # NEW: UserDefaults persistence for shown milestones
├── NotificationScheduler.swift       # MODIFY: add global streakAtRisk extension
└── CommunityService.swift            # MODIFY: add writeStreakAchievement, fetchStreakAchievements

ViewModels/
├── GoalViewModel.swift               # MODIFY: add goal-streak milestone detection, cancel nudge
├── StatsViewModel.swift              # MODIFY: buildHeatmapData merges frozenDates as sentinel -1
└── CommunityHubViewModel.swift       # MODIFY: loadAll fetches + interleaves StreakAchievement

Views/
├── HeatmapView.swift                 # MODIFY: cellColor handles sentinel -1 → ❄️ text/icon
├── GoalStreakMilestoneView.swift      # NEW: MILE-04 full-screen celebration
├── GoalCompletionCelebrationView.swift # NEW: MILE-06 "You did it" full-screen
└── Community/
    └── StreakAchievementCard.swift   # NEW: MILE-05 feed card for achievement records

Models/
└── SchemaV10.swift                   # NEW: adds Goal.streakMilestonesShownJSON (optional),
                                      #      Goal.completionCelebrationShown (Bool? = nil)
                                      #      StreakFreezeService key change is UserDefaults only — no schema
```

### Pattern 1: ISO8601 Weekly Freeze Gate

**What:** Replace monthly boundary check with ISO8601 week-of-year comparison.
**When to use:** `StreakFreezeService.canFreeze`

```swift
// [VERIFIED: codebase pattern from CommunityHubViewModel.GlowingSelector]
var canFreeze: Bool {
    guard let lastDate = lastFreezeDate else { return true }
    let iso = Calendar(identifier: .iso8601)
    let lastWeek = iso.component(.weekOfYear, from: lastDate)
    let thisWeek = iso.component(.weekOfYear, from: .now)
    let lastYear = iso.component(.year, from: lastDate)
    let thisYear = iso.component(.year, from: .now)
    return lastWeek != thisWeek || lastYear != thisYear
}
```

Year comparison is required to handle week 52 → week 1 year boundary.

### Pattern 2: Heatmap Frozen-Day Sentinel

**What:** Encode frozen dates as value `-1` in the `[Date: Int]` dictionary; `HeatmapView.cellColor` branches on `-1`.
**When to use:** `StatsViewModel.buildHeatmapData` + `HeatmapView.cellColor`

```swift
// StatsViewModel — [VERIFIED: codebase, extension of existing buildHeatmapData]
private func buildHeatmapData(from events: [CompletionEvent], frozenDates: [Date]) -> [Date: Int] {
    var dict: [Date: Int] = [:]
    for event in events {
        guard let date = event.completedAt else { continue }
        let day = Calendar.current.startOfDay(for: date)
        dict[day, default: 0] += 1
    }
    for frozen in frozenDates {
        let day = Calendar.current.startOfDay(for: frozen)
        if dict[day] == nil { dict[day] = -1 }  // only if no real check-in that day
    }
    return dict
}

// HeatmapView — [VERIFIED: codebase, extension of existing cellColor]
private func cellColor(for count: Int) -> Color {
    switch count {
    case -1:  return .blue.opacity(0.4)   // frozen sentinel — render ❄️ text overlay instead
    case 0:   return Color(.systemFill)
    case 1:   return .green.opacity(0.3)
    case 2:   return .green.opacity(0.6)
    default:  return .green
    }
}
```

The ❄️ character is rendered as a `Text("❄️")` overlay on the cell, not as a color. The cell background can be `.blue.opacity(0.2)` with the emoji positioned centered in the 12pt cell. Given the cell is only 12x12pt, an SF Symbol `snowflake` at font size 8 is cleaner than the emoji.

### Pattern 3: Streak Milestone Persistence (UserDefaults JSON)

**What:** `StreakMilestoneGate` — a static enum following the `ApplauseGate` pattern.

```swift
// [VERIFIED: codebase, mirrors ApplauseGate in CommunityHubViewModel.swift]
enum StreakMilestoneGate {
    private static let key = "vg_streakMilestonesShown"
    // key format: "\(goalID.uuidString)-\(threshold)"

    static func hasShown(goalID: UUID, threshold: Int,
                         defaults: UserDefaults = .standard) -> Bool {
        let compositeKey = "\(goalID.uuidString)-\(threshold)"
        guard let data = defaults.data(forKey: key),
              let set = try? JSONDecoder().decode(Set<String>.self, from: data)
        else { return false }
        return set.contains(compositeKey)
    }

    static func markShown(goalID: UUID, threshold: Int,
                          defaults: UserDefaults = .standard) {
        var set: Set<String> = []
        if let data = defaults.data(forKey: key),
           let existing = try? JSONDecoder().decode(Set<String>.self, from: data) {
            set = existing
        }
        set.insert("\(goalID.uuidString)-\(threshold)")
        if let encoded = try? JSONEncoder().encode(set) {
            defaults.set(encoded, forKey: key)
        }
    }
}
```

### Pattern 4: GoalStreakMilestoneView Confetti

**What:** Clone the `confettiView` from `CheckInCelebrationView` verbatim. No changes needed.

```swift
// [VERIFIED: codebase — CheckInCelebrationView.swift lines 107-125]
// Same TimelineView(.animation) + Canvas pattern. 60 particles, golden-angle scatter.
// Suppress under .accessibilityReduceMotion.
```

### Pattern 5: CloudKit StreakAchievement Write

**What:** New `CommunityService` static method following `writeGlimpse` upsert pattern.

```swift
// [VERIFIED: codebase, mirrors CommunityService.writeGlimpse]
static func writeStreakAchievement(
    username: String,
    authorColorHex: String,
    goalTitle: String,
    goalID: String,          // for de-dup predicate
    threshold: Int,
    streakLength: Int
) async { /* upsert by username+goalID+threshold, one retry on .serverRecordChanged */ }
```

Fields on the `StreakAchievement` CKRecord: `username`, `authorColorHex`, `goalTitle`, `goalID`, `threshold`, `streakLength`, `creationDate` (set by CloudKit automatically).

### Anti-Patterns to Avoid

- **Storing frozenDates in SwiftData** — `StreakFreezeService` correctly uses `UserDefaults` with the App Group suite. Do not move frozen dates to a new SwiftData model; the App Group shared suite is required for widget access.
- **Scheduling the 7 PM nudge without a same-day cancel** — the repeating `UNCalendarNotificationTrigger` fires every day at 19:00. If `addCheckIn` does not cancel it for today, the notification fires even after the user checks in. Cancel on `addCheckIn`, re-schedule on the next calendar day's midnight (or simply leave the repeating trigger and rely on same-day cancellation).
- **Using `goal.isCompleted` as a heatmap cell** — completion events (via `addCheckIn`) drive the heatmap, not `isCompleted`. The heatmap must remain event-driven.
- **Milestone detection inside the View** — `GoalViewModel` must detect the milestone and set `pendingGoalMilestone`; the View only consumes it via `.onChange`.
- **Posting achievements without InputSanitizer** — all CloudKit writes must run goal title and username through `InputSanitizer.sanitizeForPublic` before writing.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Confetti particle system | Custom SpriteKit scene | `TimelineView(.animation)` + `Canvas` | Already implemented; consistent with existing views |
| Sharing to iOS share sheet | UIActivityViewController | `ShareLink` (SwiftUI native, iOS 16+) | Already used in `ProfileView.swift`; cleaner API |
| ISO8601 week arithmetic | Manual date subtraction | `Calendar(identifier: .iso8601).component(.weekOfYear, from:)` | Already used in `GlowingSelector`; handles locale edge cases |
| Milestone idempotency | Custom DB table | `StreakMilestoneGate` UserDefaults JSON (mirrors `ApplauseGate`) | Established pattern; no SwiftData migration needed |
| Persistent frozen dates | New SwiftData model | `StreakFreezeService` UserDefaults with App Group suite | Already implemented; App Group access from widgets required |

---

## Data Model Changes Needed

### SchemaV10

SchemaV10 must be created as a new `VersionedSchema` following the established pattern. Only the fields that must survive across app launches and are goal-associated belong in SwiftData. UserDefaults handles the rest.

**New `Goal` fields in SchemaV10:**

| Field | Type | Default | Purpose | CloudKit safe? |
|-------|------|---------|---------|----------------|
| `streakMilestonesShownJSON` | `String?` | `nil` | JSON-encoded `[Int]` of shown thresholds for this goal — backup persistence if UserDefaults is cleared | Yes — optional |
| `completionCelebrationShown` | `Bool?` | `nil` (treated as false) | Whether the MILE-06 "You did it" screen has been shown | Yes — optional |

Note: `streakMilestonesShownJSON` on the model is belt-and-suspenders alongside `StreakMilestoneGate` in UserDefaults. Using both means if UserDefaults is cleared (sandbox restore, OS eviction), the SwiftData field prevents re-showing the milestone screen.

**No new SwiftData models required.** `StreakAchievement` lives only in CloudKit (public DB), consistent with `GoalGlimpse`, `UserPresence`, and `Applause`.

**`StreakFreezeService` key change:** The `keyLastFreezeDate` computation changes from month-granularity to ISO8601-week-granularity entirely in the service's `canFreeze` method. The underlying UserDefaults keys (`vg.streakFreeze.lastFreezeDate`, `vg.streakFreeze.frozenDates`) remain unchanged.

**Migration:** SchemaV10 is a lightweight migration — only optional fields with nil defaults are added. No `MigrationPlan` custom stage needed if all new fields are optional with nil defaults.

---

## Common Pitfalls

### Pitfall 1: Year boundary breaks ISO8601 weekly freeze check
**What goes wrong:** `weekOfYear == 1` in late December for some locales, matching week 1 of the new year — making `canFreeze` return `true` incorrectly.
**Why it happens:** ISO8601 week 1 of the new year can begin in late December; comparing only `weekOfYear` without `year` produces a false match.
**How to avoid:** Always compare both `weekOfYear` AND `year` components, both from `Calendar(identifier: .iso8601)`.
**Warning signs:** Tests that freeze in last week of December and check `canFreeze` in first week of January.

### Pitfall 2: Notification 64-cap exceeded by global streak-at-risk
**What goes wrong:** Adding a repeating global streak-at-risk notification without checking the pending count can push over the iOS 64-notification cap, silently dropping the oldest scheduled notification (often the morning goal reminder).
**Why it happens:** The app already schedules: 1 daily reminder + 1 win reminder + N per-goal reminders + M challenge reminders. The existing `scheduleStreakAtRiskReminder` checks `pending.count < 60` before adding.
**How to avoid:** Mirror the `pending.count < 60` guard from `NotificationScheduler.scheduleStreakAtRiskReminder` in the new global nudge method.
**Warning signs:** Morning goal reminders stop firing after adding the nudge.

### Pitfall 3: Milestone fires again after app reinstall
**What goes wrong:** `StreakMilestoneGate` stores shown milestones in `UserDefaults.standard`. A reinstall or backup restore clears UserDefaults, so the milestone screen shows again on the next check-in that crosses the threshold.
**Why it happens:** UserDefaults does not survive reinstall by default (unless backed up via iCloud).
**How to avoid:** Belt-and-suspenders: also store the shown-threshold set in `Goal.streakMilestonesShownJSON` in SwiftData (which does survive reinstall via CloudKit sync). Check both stores in `StreakMilestoneGate.hasShown`.
**Warning signs:** Testers who reinstall the app report seeing milestones again.

### Pitfall 4: HeatmapView frozen cell collides with same-day check-in
**What goes wrong:** If a user freezes and also checks in on the same day, storing `-1` overwrites the real check-in count.
**Why it happens:** `buildHeatmapData` writes the sentinel unconditionally.
**How to avoid:** Only write `-1` if `dict[day] == nil` — i.e., only for days with no real check-in. A frozen day with a check-in shows as a normal green cell (the streak was already protected; the freeze was redundant but valid).
**Warning signs:** Days with both a check-in and a freeze show ❄️ instead of green.

### Pitfall 5: Goal-streak milestone thresholds differ from challenge milestones
**What goes wrong:** `MilestoneCelebrationView` (challenge path) uses thresholds 7/30/60/90. MILE-04 specifies 7/14/30/60/90/365 for goal streaks. Using the wrong threshold list misses 14 and 365.
**Why it happens:** Copy-paste from challenge milestone code.
**How to avoid:** Define goal-streak thresholds as a separate constant in `GoalStreakMilestoneView` or `StreakMilestoneGate`:
  ```swift
  static let goalStreakThresholds: [Int] = [7, 14, 30, 60, 90, 365]
  ```
**Warning signs:** 14-day and 365-day milestones never fire.

### Pitfall 6: `toggleCompletion` vs `addCheckIn` — goal completion vs daily check-in
**What goes wrong:** MILE-06's "You did it" page triggers on `goal.isCompleted = true`, which is set only by `toggleCompletion`, not `addCheckIn`. If the product intention is "auto-complete when durationDays check-ins are reached," that's an addCheckIn-path change — currently not implemented.
**Why it happens:** The two paths are intentionally separate in the codebase.
**How to avoid:** Confirm with user whether MILE-06 fires only on manual toggle, or also auto-fires when `completionEvents.count >= durationDays`. (See Open Questions.)
**Warning signs:** No "You did it" screen ever appears during normal daily check-in flow.

### Pitfall 7: CloudKit StreakAchievement upsert without de-duplication
**What goes wrong:** Each time the user shares an achievement, a new `StreakAchievement` record is created, producing duplicate entries in the community feed.
**Why it happens:** CloudKit has no server-side uniqueness; `writeGlimpse` avoids this with a query-before-write upsert on `username + dayKey`.
**How to avoid:** De-duplicate on `username + goalID + threshold`. Query first, create if not found, update if found.
**Warning signs:** Community feed shows the same user's achievement multiple times.

---

## Code Examples

### Correct: ISO8601 weekly freeze check
```swift
// [VERIFIED: codebase — mirrors CommunityHubViewModel.GlowingSelector]
let iso = Calendar(identifier: .iso8601)
let lastWeek = iso.component(.weekOfYear, from: lastDate)
let thisWeek = iso.component(.weekOfYear, from: .now)
let lastYear = iso.component(.year, from: lastDate)
let thisYear = iso.component(.year, from: .now)
return lastWeek != thisWeek || lastYear != thisYear
```

### Correct: Goal-streak milestone detection in addCheckIn
```swift
// [VERIFIED: codebase — mirrors GoalViewModel.toggleCompletion milestone block]
let goalEvents = goal.completionEvents?.filter {
    // count events matching today through streak window
} ?? []
let streakLen = StreakEngine.currentStreak(from: allEvents, frozenDates: freezeService.frozenDates)
for threshold in StreakMilestoneGate.goalStreakThresholds {
    if streakLen >= threshold
       && streakLen - 1 < threshold  // just crossed
       && !StreakMilestoneGate.hasShown(goalID: goal.id, threshold: threshold) {
        pendingGoalMilestone = (goalID: goal.id, threshold: threshold)
        break
    }
}
```

Note: The milestone is on the **global app streak**, not per-goal streak, per the requirement "streak milestones 7/14/30/60/90/365." If it is per-goal streak, the events filter must be scoped to a single goal's events. This ambiguity should be resolved (see Open Questions).

### Correct: Global streak-at-risk notification (MILE-02)
```swift
// [VERIFIED: codebase — extension of NotificationScheduler.scheduleStreakAtRiskReminder]
static let globalStreakAtRiskIdentifier = "com.kyleharrington.VitaminG.streakAtRisk.global"

func scheduleGlobalStreakAtRiskNudge() async {
    let center = UNUserNotificationCenter.current()
    let pending = await center.pendingNotificationRequests()
    guard pending.count < 60 else { return }   // cap guard
    center.removePendingNotificationRequests(withIdentifiers: [Self.globalStreakAtRiskIdentifier])
    let content = UNMutableNotificationContent()
    content.title = "Life happened?"
    content.body = "You haven't checked in today. Use your streak freeze to protect your streak."
    content.sound = .default
    content.userInfo = ["deepLink": "goalList", "source": "streakAtRisk"]
    var components = DateComponents()
    components.hour = 19; components.minute = 0
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    let request = UNNotificationRequest(identifier: Self.globalStreakAtRiskIdentifier, content: content, trigger: trigger)
    try? await center.add(request)
}

func cancelGlobalStreakAtRiskNudge() {
    UNUserNotificationCenter.current()
        .removePendingNotificationRequests(withIdentifiers: [Self.globalStreakAtRiskIdentifier])
}
```

### Correct: ShareLink for achievement sharing (MILE-04, MILE-06)
```swift
// [VERIFIED: codebase — mirrors ProfileView.swift ShareLink usage]
ShareLink(
    item: "I just hit a \(threshold)-day streak on Vitamin G! 🔥",
    subject: Text("My Vitamin G Streak"),
    message: Text("Download Vitamin G to track your goals.")
)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Monthly streak freeze (`canFreeze` checks `.month` granularity) | Weekly ISO8601 freeze (MILE-01) | Phase 23 | `StreakFreezeService.canFreeze` rewrite; UX copy update ("per week" not "per month") |
| In-session only milestone dedup (`firedMilestones: Set<String>`) | Persistent milestone dedup (`StreakMilestoneGate` + SwiftData field) | Phase 23 | Survives app restart; prevents re-showing on reinstall |
| No goal-completion celebration | `GoalCompletionCelebrationView` (MILE-06) | Phase 23 | New full-screen cover triggered by `toggleCompletion` |

**Deprecated/outdated:**
- `StreakFreezeService.canFreeze` monthly-granularity check — replaced by ISO8601 weekly check in Phase 23.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | MILE-04 streak milestones (7/14/30/60/90/365) are on the **global app streak** (all goals combined), not per-goal streak | Code Examples, Pitfall 5 | If per-goal: milestone detection logic changes significantly; must filter events to a single goal |
| A2 | MILE-06 "You did it" page fires only on **manual** `toggleCompletion` (user marks goal done), not auto-triggered when `completionEvents.count >= durationDays` | Q7, Pitfall 6 | If auto-trigger: `addCheckIn` needs a completion-detection branch and schema may need `completionDate` |
| A3 | MILE-02 nudge fires unconditionally at 7 PM and is cancelled by `addCheckIn` (not conditionally scheduled per-day) | Q9 | If conditional-schedule approach is preferred: need a mechanism to schedule tomorrow's notification from `addCheckIn` callback |
| A4 | MILE-05 shared achievements appear in the **global community feed** (`CommunityTabView → GlobalFeedSection`), not in a challenge-specific feed | Q10 | If challenge-specific: routing is different; needs challenge ID on the achievement record |

---

## Open Questions

1. **Are MILE-04 milestones on the global app streak or per-goal streak?**
   - What we know: The requirement says "streak milestones" without specifying scope; the global streak is the prominently displayed number in `StatsView`.
   - What's unclear: Per-goal streaks are also computed (by filtering events to a single goal's events); "streak at risk" (MILE-02) implies per-goal context.
   - Recommendation: Clarify before implementing — global streak is simpler and aligns with the StatsView design; per-goal streak requires milestone detection inside the goal card.

2. **Does MILE-06 fire automatically when `completionEvents.count >= durationDays` OR only on manual `toggleCompletion`?**
   - What we know: `toggleCompletion` sets `isCompleted = true` manually; `addCheckIn` never sets it.
   - What's unclear: A 30-day goal with 30 check-ins does not auto-complete today.
   - Recommendation: If auto-complete is desired, add a branch in `addCheckIn` that calls `toggleCompletion` when count equals durationDays, then fires the celebration. This is a behavior addition that needs explicit sign-off.

3. **Does MILE-05 community sharing require a new "Achievements" section in CommunityTabView, or does it interleave with the global feed?**
   - What we know: The requirement says "scroll in Community feed alongside regular posts" — suggests interleaving.
   - What's unclear: Interleaving mixed `CKRecord` types in `GlobalFeedSection` requires type-discriminating the `ForEach`.
   - Recommendation: Interleave by `creationDate` in `CommunityHubViewModel`; add a `recordKind` field (`"achievement"` vs `"post"`) for cell type routing.

4. **Should the MILE-02 in-app nudge be a banner/alert rather than (or in addition to) the push notification?**
   - What we know: The requirement says "notification/in-app nudge" — both are mentioned.
   - What's unclear: In-app would require `GoalListView` to check "not checked in today + freeze available" at view appearance time and show a banner.
   - Recommendation: Implement push notification first (simpler, consistent with existing patterns); in-app banner can be a secondary enhancement.

---

## Environment Availability

> This phase is purely code/config changes and CloudKit schema additions. No new CLI tools, databases, or external services are required. CloudKit development environment is assumed operational from Phase 22.

Step 2.6: SKIPPED (no new external dependencies identified — same stack as Phase 22)

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest |
| Config file | None — integrated in Xcode scheme |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/<TestClass>` |
| Full suite command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MILE-01 | `canFreeze` resets on ISO8601 Monday | unit | `-only-testing:VitaminGTests/StreakFreezeTests` | Existing — extend |
| MILE-01 | Year-boundary (week 52 → week 1) does not reset freeze | unit | `-only-testing:VitaminGTests/StreakFreezeTests` | Existing — extend |
| MILE-01 | `StreakEngine.currentStreak` counts frozen day as active | unit | `-only-testing:VitaminGTests/StreakEngineTests` | Existing — already covered |
| MILE-03 | `buildHeatmapData` writes `-1` sentinel for frozen days with no check-in | unit | `-only-testing:VitaminGTests/Phase23StatsViewModelTests` | Wave 0 gap |
| MILE-03 | `buildHeatmapData` does NOT write `-1` if check-in exists on frozen day | unit | `-only-testing:VitaminGTests/Phase23StatsViewModelTests` | Wave 0 gap |
| MILE-04 | `StreakMilestoneGate.hasShown` returns false on fresh install | unit | `-only-testing:VitaminGTests/Phase23MilestoneGateTests` | Wave 0 gap |
| MILE-04 | `StreakMilestoneGate.markShown` + `hasShown` returns true | unit | `-only-testing:VitaminGTests/Phase23MilestoneGateTests` | Wave 0 gap |
| MILE-04 | Milestones `[7, 14, 30, 60, 90, 365]` all trigger independently | unit | `-only-testing:VitaminGTests/Phase23MilestoneGateTests` | Wave 0 gap |
| MILE-02 | `scheduleGlobalStreakAtRiskNudge` respects 64-cap guard | unit | `-only-testing:VitaminGTests/Phase23NotificationTests` | Wave 0 gap |
| MILE-05 | `writeStreakAchievement` de-duplicates by username+goalID+threshold | unit (mock CloudKit) | manual / integration | N/A |

### Sampling Rate

- **Per task commit:** `xcodebuild test -only-testing:VitaminGTests/<relevant test class>`
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green before verification

### Wave 0 Gaps

- [ ] `Phase23StatsViewModelTests.swift` — covers MILE-03 heatmap sentinel logic
- [ ] `Phase23MilestoneGateTests.swift` — covers MILE-04 `StreakMilestoneGate` persistence
- [ ] `Phase23NotificationTests.swift` — covers MILE-02 cap guard and identifier pattern
- [ ] Extend `StreakFreezeTests.swift` — ISO8601 weekly reset, year-boundary case

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes | `isPublic` gate before writing StreakAchievement; only public users share achievements |
| V5 Input Validation | yes | `InputSanitizer.sanitizeForPublic` on all CloudKit writes (goalTitle, username) |
| V6 Cryptography | no | — |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Achievement flooding (user shares achievement many times) | Spoofing / Tampering | Upsert de-dup by username+goalID+threshold in `writeStreakAchievement` |
| Profanity in shared achievement text | Information disclosure | `ProfanityFilter.containsProfanity` check before CloudKit write |
| UserDefaults milestone key tampering | Tampering | `StreakMilestoneGate` is a soft gate — clearing defaults re-shows celebrations; acceptable per `ApplauseGate` security note pattern |
| Notification content injection via goal title | Tampering | `InputSanitizer.sanitize` already applied at goal-write time; goal title is safe at notification-read time |

---

## Recommended Plan Structure

Four plans, two waves:

**Wave 1 (service + schema layer):**
- Plan 01: SchemaV10 migration + `StreakFreezeService` weekly reset fix + `StreakMilestoneGate` new service
- Plan 02: `StatsViewModel.buildHeatmapData` frozen sentinel + `HeatmapView` ❄️ cell + `GoalViewModel` goal-streak milestone detection

**Wave 2 (UI + notifications + community):**
- Plan 03: `GoalStreakMilestoneView` (MILE-04) + `GoalCompletionCelebrationView` (MILE-06) + wiring in `GoalDetailView`/`GoalListView`
- Plan 04: MILE-02 global streak-at-risk notification + MILE-05 `CommunityService.writeStreakAchievement` + `CommunityHubViewModel` feed integration + `StreakAchievementCard`

---

## Sources

### Primary (HIGH confidence)
- `StreakFreezeService.swift` — current implementation, freeze gate logic, UserDefaults keys
- `StreakEngine.swift` — streak algorithm, `frozenDates` parameter signature
- `HeatmapView.swift` — data shape `[Date: Int]`, `cellColor` method
- `StatsViewModel.swift` — `buildHeatmapData` implementation, `refresh` signature
- `MilestoneCelebrationView.swift` — confetti pattern, `TimelineView` + `Canvas` implementation
- `CheckInCelebrationView.swift` — confetti pattern (verbatim copy), `reduceMotion` handling
- `NotificationScheduler.swift` — 64-cap guard pattern, `scheduleStreakAtRiskReminder` at 20:00
- `CommunityService.swift` — `writeGlimpse` upsert pattern, `fetchGlobalPosts`, record type constants
- `GoalViewModel.swift` — `addCheckIn`, `toggleCompletion`, milestone detection wiring
- `CommunityHubViewModel.swift` — `ApplauseGate` pattern, `loadAll` structure
- `VGTheme.swift` — design tokens; `accentTerra`, `accentSage`, `accentGold` for milestone colors
- `SchemaV9.swift` — current `Goal` and `UserProfile` model; CloudKit-safe field rules

### Secondary (MEDIUM confidence)
- `StatsView.swift` — `StreakFreezeService` instantiation, freeze button wiring (establishes UI integration point for MILE-01 UI changes)
- `GoalDetailView.swift` — `CheckInCelebrationView` trigger pattern (`.fullScreenCover`); MILE-06 trigger should follow the same pattern
- `CommunityTabView.swift` — `GlobalFeedSection` integration point for MILE-05

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all confirmed from codebase
- Architecture: HIGH — direct codebase verification of all integration points
- Pitfalls: HIGH — derived from explicit code patterns and existing pit-avoidance comments in codebase
- Open questions: the 4 open questions above are genuine ambiguities in requirements, not research gaps

**Research date:** 2026-05-25
**Valid until:** 2026-07-25 (stable Swift/SwiftData; CloudKit API is stable)
