# Phase 11: Gratitude / Daily Wins Module - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-01
**Phase:** 11-gratitude-daily-wins
**Areas discussed:** Navigation / Entry Point, Win Entry Format, History Layout, Notification Config

---

## Navigation / Entry Point

| Option | Description | Selected |
|--------|-------------|----------|
| 4th tab "Wins" | Dedicated tab in TabView — most prominent, matches Goals/Stats/Profile pattern | ✓ |
| Sheet from existing tab | Floating button or card on Goals tab opening a sheet | |
| Embedded in Stats tab | Daily win entry as a section within the existing Stats surface | |

**User's choice:** Deferred to Claude's recommendation — 4th tab "Wins"
**Notes:** App currently has 3 tabs (Goals, Stats, Profile). Claude recommended 4th tab as most prominent and best aligned with "Vitamin G for Gratitude" brand. GRAT-06 requires "prominent surface."

---

## Win Entry Format

| Option | Description | Selected |
|--------|-------------|----------|
| Single free-text, editable | TextEditor, 500-char limit, one per day, always editable | ✓ |
| Create-once, read-only after save | Entry locked after initial save — diary-style | |
| Structured prompts | Multiple fields (gratitude, win, reflection) | |

**User's choice:** Deferred to Claude's recommendation — single free-text, editable
**Notes:** 500-char limit consistent with `goalDescription` validation pattern. One-per-day via `Calendar.current` day comparison (DST-safe, same as StreakEngine). Editable at any time — not locked to midnight.

---

## History Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Reverse-date card list | Newest first, date + text per card — simple and fast to build | ✓ |
| Calendar grid (HeatmapView pattern) | Visual density map of days with entries — heavier to build | |
| Grouped by month | Sections per month with entries listed within — intermediate complexity | |

**User's choice:** Deferred to Claude's recommendation — reverse-date card list
**Notes:** HeatmapView already exists in StatsView and could be reused in a future phase for wins streaks. Keeping Phase 11 simple lets it ship faster.

---

## Notification Config

| Option | Description | Selected |
|--------|-------------|----------|
| Separate time picker in SettingsView | Second "Win reminder" row, independent time, new identifier | ✓ |
| Share existing goal-reminder time | Single time picker controls both notifications | |
| No separate time — fixed evening | Win reminder always fires at hardcoded time (e.g., 8PM) | |

**User's choice:** Deferred to Claude's recommendation — separate independent time picker
**Notes:** New identifier `com.kyleharrington.VitaminG.winReminder`. Default 8:00 PM (evening reflection vs. 8:00 AM morning goals). Consistent remove-before-add pattern. New `winNotificationHour` / `winNotificationMinute` keys in `NotificationPreferences`.

---

## Claude's Discretion

All four areas were delegated to Claude's judgment by the user ("what do you think should be done here"). Claude selected recommendations based on:
- Codebase patterns from prior phases
- GRAT-01–GRAT-06 requirements
- Brand alignment with "Vitamin G for Gratitude"
- Phase scope (keeping it buildable without feature creep)

## Deferred Ideas

- Gratitude streaks (future phase — possibly Phase 12 momentum integration)
- Structured prompts / rotating prompt copy
- HeatmapView for win history
- Home screen shortcut for quick win entry
