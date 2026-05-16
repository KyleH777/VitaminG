# Phase 4: iCloud Sync & Widgets - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the discussion.

**Date:** 2026-04-06
**Phase:** 04-icloud-sync-widgets
**Mode:** discuss
**Areas covered:** Home screen widget content, Lock screen widget content, iCloud sync UX, Widget refresh strategy

---

## Gray Areas Presented

| Area | Options Offered |
|------|----------------|
| Home screen widget content | One goal per tier / Top 3–4 by priority / Streak + top goal |
| Lock screen widget content | Top active goal / Global streak / Smart fallback |
| iCloud sync UX | Truly invisible / iCloud row in Settings / Status + last synced |
| Widget refresh strategy | Daily + on app open / Daily only / After every change |

---

## Decisions Made

### Home Screen Widget
- **Selected:** One goal per tier (4 rows, Immediate → Life Goal)
- **Correction:** User added — global streak shown as footer row at the bottom

### Lock Screen Widget
- **Selected:** Smart logic — streak if > 0, else top active goal title

### iCloud Sync UX
- **Initial selection:** Truly invisible
- **Correction:** Truly invisible for sync, BUT Settings shows global streak count as a motivational dopamine hit element (user's framing: "a reason to keep coming back")

### Widget Refresh Strategy
- **Selected:** Daily + on app open (WidgetCenter.reloadAllTimelines() after any goal change)

---

## No Corrections Needed Beyond Discussion

All areas resolved in one or two clarification rounds. No scope creep flagged.
