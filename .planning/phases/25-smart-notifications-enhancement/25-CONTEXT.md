# Phase 25: Smart Notifications Enhancement - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend `NotificationScheduler` with three behavioral upgrades:

1. **Tone-adaptive morning copy** (NOTIF-01) — three distinct copy banks selected by streak level; inline in `NotificationScheduler`
2. **Goal-title personalization** (NOTIF-02) — up to 2 active goal titles in the morning notification body
3. **Streak-at-risk per-day scheduling** (NOTIF-04) — replace the Phase 23 repeating 7 PM nudge with a daily schedule-and-cancel pattern; cancel fires on any check-in surface (iOS, widget, Watch)
4. **Nudge-time suggestion banner** (NOTIF-03) — 14-day check-in hour history in UserDefaults; a non-intrusive banner in SettingsView suggests a specific shift when the modal check-in hour differs from the current nudge by ≥ 2 hours

No schema migration. No new network calls. No new widget families. All v3.0 state lives in UserDefaults.

</domain>

<decisions>
## Implementation Decisions

### Morning Notification Copy (NOTIF-01, NOTIF-02)

- **D-01:** Replace the 7 generic `inspirationalMessages` with **three distinct static arrays** inside `NotificationScheduler`: `celebratoryCopy` (streak ≥ 7 days), `neutralBuildingCopy` (streak 1–6 days), `encouragingCopy` (streak 0 or broken). Each array holds ~4–7 messages. Day-of-year rotation selects within the matching bank.
- **D-02:** `makeContent()` gains a `currentStreak: Int` parameter. Tone tier is determined by this parameter. Signature: `makeContent(activeGoals: [Goal], currentStreak: Int) -> UNMutableNotificationContent`. Remains a pure function — no hidden state reads.
- **D-03:** Callers (`schedule(hour:minute:activeGoals:)`, `reschedule(activeGoals:)`) call `StreakEngine.currentStreak(from:)` using the CompletionEvent array and pass the result to `makeContent`. The scheduler receives `[CompletionEvent]` as a new parameter alongside `[Goal]`.
- **D-04:** Up to 2 active goal titles in the notification body, **newline-separated**: `body = "{tone message}\n{Goal 1 title}\n{Goal 2 title}"`. Second title only included when ≥ 2 non-completed goals with non-empty titles exist. Single-title body (`body = "{tone message}\n{Goal 1 title}"`) when only one active goal exists; tone message alone when none.

### Streak-at-Risk Per-Day Alert (NOTIF-04)

- **D-05:** NOTIF-04 **replaces** the Phase 23 repeating `globalStreakAtRiskNudge`. The identifier `globalStreakAtRiskIdentifier` is reused but the notification is no longer repeating. Each call to `schedule(hour:minute:activeGoals:completionEvents:)` removes the old nudge and schedules a one-time `UNCalendarNotificationTrigger(dateMatching: {hour:19, minute:0}, repeats: false)`. `cancelGlobalStreakAtRiskNudge()` (already called in `GoalViewModel.addCheckIn`) handles cancellation — no new cancellation sites needed.
- **D-06:** Streak-at-risk alert copy (personalized): `body = "Your \(topGoalTitle) streak is at risk — check in to keep your \(streak)-day run alive."` Falls back to a generic message (e.g., "You haven't checked in today — keep your streak alive.") when no active goal title is available.
- **D-07:** `schedule(hour:minute:activeGoals:completionEvents:)` schedules **both** the morning notification (repeating, existing pattern) and today's 7 PM one-shot alert. The one-shot fires at the next occurrence of 19:00 — naturally correct when called before 7 PM; if called after 7 PM, it fires the following day at 7 PM (acceptable behavior).

### Check-In Hour Tracking (NOTIF-03)

- **D-08:** UserDefaults key `"checkInHourHistory"` stores `[Int]` (hours 0–23), last 14 entries, FIFO. Written to the **App Group suite** (`group.com.kyleharrington.VitaminG`) so future widget/Watch targets can read it. Key added to `NotificationPreferences`.
- **D-09:** `GoalViewModel.addCheckIn()` appends `Calendar.current.component(.hour, from: Date())` to the array immediately before `cancelGlobalStreakAtRiskNudge()`. Drops the oldest entry when count exceeds 14.
- **D-10:** Modal analysis runs in **`SettingsView.onAppear`** (not on every app foreground). Condition to show banner: `history.count >= 14` AND `|modalHour - NotificationPreferences.hour| >= 2`. Modal hour = the most frequently occurring hour in the array (mode; ties broken by earliest occurrence).

### Nudge-Time Suggestion Banner (NOTIF-03 UI)

- **D-11:** Banner is a **conditional row inserted above the DatePicker** in the Notifications section of SettingsView. Shown when `@State var showNudgeSuggestion: Bool` is true (computed in `.onAppear`).
- **D-12:** Banner displays the specific computed time: `"You usually check in around [modal time]. Shift your nudge to [modal time]?"` with an **Apply** button and an **X dismiss** button. Tapping Apply calls `NotificationPreferences.save(hour:minute:)` and `NotificationScheduler.shared.reschedule(activeGoals:)` — applies immediately, no DatePicker interaction required.
- **D-13:** Once acted on (Apply or X), set `UserDefaults` key `"nudgeSuggestionDismissed"` to `true`. `SettingsView.onAppear` checks this flag before setting `showNudgeSuggestion = true`. Banner **never reappears** after being acted on (dismissed state is permanent unless manually cleared — not exposed to the user). Key added to `NotificationPreferences`.

### Claude's Discretion

- Exact copy text for each of the three tone banks (celebratory, neutral-building, encouraging) — ~5 messages per bank
- Exact copy for the streak-at-risk fallback (no active goal)
- Dismiss button style (SF Symbol `xmark` icon button vs. "Dismiss" text)
- Mode tie-breaking logic for check-in hour histogram
- Whether `schedule()` skips the one-shot 7 PM scheduling when the current time is already past 7 PM that day (vs. letting it naturally fire the following day)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Requirements
- `.planning/ROADMAP.md` §Phase 25 — goal, success criteria, requirements (NOTIF-01 through NOTIF-04)
- `.planning/REQUIREMENTS.md` §NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04 — full requirement definitions

### Existing Notification Code (read before touching)
- `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` — `makeContent()`, `schedule()`, `reschedule()`, `scheduleGlobalStreakAtRiskNudge()`, `cancelGlobalStreakAtRiskNudge()` (all methods to be extended/replaced)
- `VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift` — UserDefaults keys, App Group suite name, `save()` — extend with `checkInHourHistory` and `nudgeSuggestionDismissed` keys
- `VitaminG/VitaminG/VitaminG/Services/NotificationDelegate.swift` — existing notification tap routing (no changes expected)

### Check-In and Streak
- `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` — `addCheckIn()` at line ~169 — add check-in hour write + array maintenance here; `cancelGlobalStreakAtRiskNudge()` call already present
- `VitaminG/VitaminG/VitaminG/Services/StreakEngine.swift` — `StreakEngine.currentStreak(from:frozenDates:tier:)` static method — used by `schedule()` to compute streak for tone selection

### Settings UI
- `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift` — existing Notifications section with DatePicker — insert suggestion banner above DatePicker

### Prior Phase Context
- `.planning/STATE.md` — key decisions: "Streak-at-risk evening alert uses schedule-and-cancel (not BGAppRefreshTask)", "No SchemaV11 required — check-in hour history in UserDefaults", "Watch check-in must cancel streak-at-risk notification via same path as iOS/widget"
- `.planning/phases/24-widget-enhancements/24-CONTEXT.md` — App Group UserDefaults patterns (`group.com.kyleharrington.VitaminG` suite) established in widget phase

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `NotificationScheduler.schedule(hour:minute:activeGoals:)` — existing scheduling skeleton; extend signature to accept `completionEvents: [CompletionEvent]` and call `StreakEngine.currentStreak()` internally before calling `makeContent(activeGoals:currentStreak:)`
- `NotificationScheduler.cancelGlobalStreakAtRiskNudge()` — existing cancellation method; already called in `GoalViewModel.addCheckIn()` and handles all cancellation paths
- `NotificationPreferences.save(hour:minute:)` — existing App Group write pattern; mirror for new `checkInHourHistory` and `nudgeSuggestionDismissed` keys
- `StreakEngine.currentStreak(from:frozenDates:tier:)` — already used by `WidgetDataProvider`; pass `nil` for tier to compute global streak
- `UNCalendarNotificationTrigger` with `repeats: false` — one-shot pattern already used by `scheduleMilestoneNotification()`

### Established Patterns
- **Remove-before-add** for all notification scheduling — maintain this to stay within iOS 64-request cap
- **64-cap guard** (`pending.count < 60`) before scheduling non-critical notifications — apply to the one-shot 7 PM alert
- **App Group UserDefaults** (`UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")`) for anything widgets or Watch may need to read
- **Pure function `makeContent()`** — no side effects, easy to unit test; maintain purity with the new `currentStreak:` parameter
- **`Task { await ... }` wrapping** for async notification calls in synchronous `addCheckIn()` — follow existing pattern

### Integration Points
- `schedule()` → also schedules one-shot 7 PM alert (D-07): add after the existing `center.add(request)` call
- `GoalViewModel.addCheckIn()` → append to `checkInHourHistory` array before the `cancelGlobalStreakAtRiskNudge()` Task
- `SettingsView` Notifications section → insert conditional suggestion row above the nudge time DatePicker
- `NotificationPreferences` → add `checkInHourHistoryKey`, `nudgeSuggestionDismissedKey`, and associated `appendCheckInHour(_:)` / `modalCheckInHour()` helpers

</code_context>

<specifics>
## Specific Ideas

- The suggestion banner copy uses the modal hour formatted as a time string, e.g., "You usually check in around 7:00 AM. Shift your nudge to 7:00 AM?" — concrete and immediately actionable.
- The one-shot 7 PM alert notification identifier is `globalStreakAtRiskIdentifier` (D-05 — same as Phase 23). Reusing it means there is always at most one 7 PM nudge pending, regardless of how many times `schedule()` is called that day.
- `NotificationSchedulerTests` and `NotificationSchedulerPhase14Tests` exist — new tests for tone selection, goal-title formatting, and the one-shot scheduling should follow the existing test patterns in those files.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 25-smart-notifications-enhancement*
*Context gathered: 2026-05-29*
