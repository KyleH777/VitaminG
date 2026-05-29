# Phase 25: Smart Notifications Enhancement - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 25-smart-notifications-enhancement
**Areas discussed:** Morning copy shape, Streak-at-risk identity, Check-in hour tracking, Nudge suggestion banner

---

## Morning Copy Shape

### Tone tiers

| Option | Description | Selected |
|--------|-------------|----------|
| Three distinct copy banks | Replace generic messages with 3 separate arrays per tone tier; day-of-year rotation within matching bank | ✓ |
| Tone prefix + shared messages | Keep 7 existing messages, prepend tone-specific opener | |
| Single message with dynamic phrase | One template with swapped streak descriptor | |

**User's choice:** Three distinct copy banks

---

### Goal titles format

| Option | Description | Selected |
|--------|-------------|----------|
| Newline-separated | `body = "{tone}\n{Goal 1}\n{Goal 2}"` | ✓ |
| Comma-joined | `body = "{tone}\n{Goal 1} & {Goal 2}"` | |
| Title only in subtitle | Use `content.subtitle` field | |

**User's choice:** Newline-separated

---

### Streak parameter threading

| Option | Description | Selected |
|--------|-------------|----------|
| New parameter `makeContent(activeGoals:currentStreak:)` | Caller passes streak; pure function maintained | ✓ |
| Inject StreakEngine reference | makeContent calls StreakEngine with [CompletionEvent] | |
| UserDefaults cached streak | Store streak on addCheckIn, read in makeContent | |

**User's choice:** New parameter

---

### Copy bank location

| Option | Description | Selected |
|--------|-------------|----------|
| Inline in NotificationScheduler | Static let arrays alongside existing inspirationalMessages | ✓ |
| Separate NotificationCopy.swift | New file with enum NotificationCopy | |

**User's choice:** Inline in NotificationScheduler

---

## Streak-at-Risk Identity

### Identifier strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Replace Phase 23 nudge (same identifier) | Reuse globalStreakAtRiskIdentifier; remove repeating, schedule daily one-shot | ✓ |
| New identifier, coexist | Keep Phase 23 repeating + add new per-day identifier | |
| New identifier, remove old | Remove Phase 23 entirely, new identifier | |

**User's choice:** Replace it (same identifier, smarter behavior)

---

### When to schedule the one-shot

| Option | Description | Selected |
|--------|-------------|----------|
| Inside `schedule(hour:minute:activeGoals:)` | Schedule both morning + today's 7 PM in one call | ✓ |
| Separately in VitaminGApp.onReceive / scenePhase | At app foreground, check and schedule if missing | |

**User's choice:** Inside `schedule()`

---

### Alert copy

| Option | Description | Selected |
|--------|-------------|----------|
| Goal title + streak count | "Your [Goal Title] streak is at risk — check in to keep your [N]-day run alive." | ✓ |
| Streak count only | "Your [N]-day streak is at risk." | |
| Generic (same as Phase 23) | Keep static Phase 23 copy | |

**User's choice:** Goal title + streak count

---

## Check-In Hour Tracking

### UserDefaults storage format

| Option | Description | Selected |
|--------|-------------|----------|
| [Int] array, last 14 entries, FIFO | Key "checkInHourHistory", App Group suite | ✓ |
| Dict keyed by date string | ["2026-05-29": 8, ...] | |
| Histogram (hour-bucket array) | 12-element [Int] indexed by hour-bucket | |

**User's choice:** [Int] array, last 14 entries, FIFO

---

### Write timing

| Option | Description | Selected |
|--------|-------------|----------|
| In `GoalViewModel.addCheckIn()` | Same call site as cancelGlobalStreakAtRiskNudge | ✓ |
| In `NotificationScheduler.reschedule()` | At schedule time (app launch / settings change) | |

**User's choice:** In GoalViewModel.addCheckIn()

---

### Modal analysis timing

| Option | Description | Selected |
|--------|-------------|----------|
| In `SettingsView.onAppear` | Compute on Settings navigation; show banner if threshold met | ✓ |
| In `VitaminGApp.onReceive` (foreground) | Run every app foreground | |

**User's choice:** SettingsView.onAppear

---

## Nudge Suggestion Banner

### Banner placement

| Option | Description | Selected |
|--------|-------------|----------|
| Above DatePicker, same section | Conditional row in Notifications section | ✓ |
| New Section at top of Settings | Separate Section at top | |
| Alert dialog | .alert() or .confirmationDialog() on appear | |

**User's choice:** Above DatePicker row, same section

---

### Suggested time content

| Option | Description | Selected |
|--------|-------------|----------|
| Specific computed time | "You usually check in around 7:00 AM. Shift your nudge to 7:00 AM?" | ✓ |
| Direction only | "Your check-ins tend to be 2+ hours before your nudge time. Move it earlier?" | |

**User's choice:** Specific computed time

---

### Reappearance behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Never again once acted on | UserDefaults flag `nudgeSuggestionDismissed`; permanent | ✓ |
| Re-evaluate each visit | Banner reappears if check-in time drifts again | |

**User's choice:** Never again once acted on

---

## Claude's Discretion

- Exact copy text for each tone bank (~5 messages per bank)
- Exact fallback copy for streak-at-risk when no active goal title
- Dismiss button style (xmark icon vs. "Dismiss" text)
- Mode tie-breaking logic for check-in hour histogram
- Whether `schedule()` skips one-shot 7 PM scheduling when called after 7 PM that day

## Deferred Ideas

None — discussion stayed within phase scope.
