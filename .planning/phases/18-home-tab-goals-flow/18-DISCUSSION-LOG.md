# Phase 18: Home Tab + Goals Flow Enhancements - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-17
**Phase:** 18-home-tab-goals-flow
**Areas discussed:** Home dashboard layout, Goal creation entry flow, Goal detail day grid, Check-in celebration screen

---

## Home Dashboard Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Community goal replaces personal goal card | Takes the hero position; personal goals in My Goals below | |
| Community goal gets its own section above My Goals | Two sections: community goal card, then My Goals | ✓ |
| Community goal as compact banner | Slim progress bar banner between quote and My Goals | |

**User's choice:** Community goal gets its own section above My Goals

---

| Option | Description | Selected |
|--------|-------------|----------|
| Tappable row cards on Home scroll | Existing quickStatsRow/dailyWinsEntry promoted to nav entries | ✓ |
| Compact icon buttons in 2-up grid | Sheet-opening grid below community goal | |
| Tap streak/wins count in header | Header elements are tappable entry points | |

**User's choice:** Tappable row cards (NavigationStack push)
**Notes:** User also explicitly removed HOME-06 (Daily Wins / Gratitude) from scope, stating "I can't seem to find a reason for it when there are goals to do." dailyWinsEntry section removed from HomeView.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Streak in header alongside greeting | "Good morning, Kyle ☀️  🔥 14" on same line | ✓ |
| Streak badge beneath greeting | Name line + flame + number on separate line | |
| You decide | Claude picks exact placement | |

**User's choice:** In the header alongside the greeting

---

## Goal Creation Entry Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Choice screen with 3 paths | Sheet with "Need ideas" / "Already have a goal" / wizard | ✓ |
| Jump straight into wizard | "Need ideas" and "Already have a goal" as secondary CTAs inside wizard | |
| Always show "Need ideas" first | Pre-made goals list is the default; "Write my own" to skip | |

**User's choice:** Choice screen with 3 paths (sheet)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Hardcoded list in the app | Static Swift array, works offline | ✓ |
| Pulled from CloudKit public DB | Dynamic but adds network dependency | |
| Reuse existing GoalCategory suggestions | Zero new data but limited set | |

**User's choice:** Hardcoded list

---

| Option | Description | Selected |
|--------|-------------|----------|
| Keep tier in Step 3 | Alongside duration, start date, reminder, privacy | ✓ |
| Move tier to Step 1 | Category + tier together | |
| Drop tier from creation flow | Default to short-term, editable later | |

**User's choice:** Keep tier in Step 3

---

## Goal Detail Day Grid

| Option | Description | Selected |
|--------|-------------|----------|
| Calendar-month rows | Mon–Sun week rows, filled/empty circles | ✓ |
| Compact linear strip | Horizontal scrollable row of day dots | |
| Heat map grid | GitHub-style contribution graph | |

**User's choice:** Calendar-month rows

---

| Option | Description | Selected |
|--------|-------------|----------|
| Current month only | Simple, fast to render | ✓ |
| Full goal duration (all months) | Scrolls through entire goal lifespan | |
| Last 30 days rolling | Fixed 30-day window | |

**User's choice:** Current month only

---

## Check-in Celebration Screen

| Option | Description | Selected |
|--------|-------------|----------|
| Overall app streak | Total VitaminG streak across all goals | ✓ |
| Per-goal streak | Consecutive days for this specific goal | |
| Both | Per-goal prominent, overall as secondary | |

**User's choice:** Overall app streak

---

| Option | Description | Selected |
|--------|-------------|----------|
| Full-screen cover, auto-dismiss after 2s | Confetti + streak, auto-advances, manual "Back to Goals" available | ✓ |
| Full-screen cover, manual dismiss only | User must tap button | |
| Modal sheet with confetti | Sheet slides up from bottom | |

**User's choice:** Full-screen cover, auto-dismiss after ~2 seconds

---

## Claude's Discretion

- Exact confetti animation style on celebration screen
- Community goal card: whether to show community-wide % or user's contribution
- Layout and icon treatment of the 3-path goal entry choice screen
- Swipe navigation between months in the day grid (chevron buttons sufficient)
- Whether "Already have a goal" path shows all 3 steps or skips Step 1

## Deferred Ideas

- **Daily Wins / Gratitude (HOME-06):** Explicitly removed by user — "I can't seem to find a reason for it when there are goals to do."
- **Per-goal streak on celebration screen:** User chose overall app streak; per-goal display not pursued.
- **Full goal duration in day grid:** Current month only chosen; full lifespan browsing deferred.
