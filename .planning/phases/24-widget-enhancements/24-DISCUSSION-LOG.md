# Phase 24: Widget Enhancements - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 24-widget-enhancements
**Areas discussed:** GoalSummaryWidget redesign, Active goal definition, Progress representation, Freeze reload gap (WID-02)

---

## GoalSummaryWidget Redesign

| Option | Description | Selected |
|--------|-------------|----------|
| Full redesign — streak + active goal | Drop 4-tier rows; equal-split layout: top = streak, bottom = active goal + progress bar | ✓ |
| Keep 4-tier rows, add progress | Maintain tier row layout, add compact progress indicator per row | |
| You decide | Claude chooses layout that fits WidgetKit constraints | |

**User's choice:** Full redesign — streak + active goal

---

**Layout emphasis:**

| Option | Description | Selected |
|--------|-------------|----------|
| Streak dominant, goal secondary | Large streak number as hero; goal below | |
| Goal dominant, streak secondary | Goal + progress as primary; streak in corner | |
| Equal split | Top row: streak (flame + count). Bottom row: active goal + progress bar | ✓ |

**User's choice:** Equal split

---

**StreakWidget (accessoryRectangular) changes:**

| Option | Description | Selected |
|--------|-------------|----------|
| Keep as-is — already correct | No redesign needed; streak count + fallback is already v2.0 correct | ✓ |
| Update to show active goal progress | Add compact progress text to lock screen widget | |
| You decide | Claude assesses accessoryRectangular constraints | |

**User's choice:** Keep as-is

---

## Active Goal Definition

**Which goal is "active":**

| Option | Description | Selected |
|--------|-------------|----------|
| Highest-priority active goal | Top non-completed goal, local SwiftData only. No new data model. | ✓ |
| Most recently checked in today | Goal user interacted with today; fall back to highest-priority | |
| User-designated primary goal | New `isPrimary` flag on Goal model (schema change) | |

**User's choice:** Highest-priority active goal

---

**Tier priority:**

| Option | Description | Selected |
|--------|-------------|----------|
| Highest tier first (Life Goal → Immediate) | Biggest aspiration first | |
| Immediate tier first (reversed) | Most actionable today first | |
| You decide | Claude picks best tier priority | ✓ |

**User's choice:** You decide — *Claude chose Immediate first (most actionable for daily widget context)*

---

**Progress calculation:**

| Option | Description | Selected |
|--------|-------------|----------|
| Check-ins vs duration (Recommended) | completionEvents.count / durationDays | ✓ |
| Days elapsed vs duration | daysSinceStart / durationDays | |
| Show 'X/Y days' text | Literal text label instead of ratio | |

**User's choice:** Check-ins vs duration

---

**No-duration fallback:**

| Option | Description | Selected |
|--------|-------------|----------|
| Show title only, no bar (Recommended) | Clean — no fake 0% bar | ✓ |
| Show 0% progress bar | Renders bar but always empty | |
| Skip goals without duration | Pick next goal that has duration | |

**User's choice:** Show title only, no bar

---

## Progress Representation

**Visual format:**

| Option | Description | Selected |
|--------|-------------|----------|
| Thin linear progress bar (Recommended) | Full-width Capsule().trim() | ✓ |
| Progress ring (circle trim) | Circular ring like Goals view | |
| Text percentage only | '72%' text, no visual bar | |

**User's choice:** Thin linear progress bar

---

**Progress bar color:**

| Option | Description | Selected |
|--------|-------------|----------|
| VGTheme.accentTerra (Recommended) | App's primary action color; consistent across CTAs | ✓ |
| Goal tier color | Match active goal's tier color | |
| System accent / adaptive | Follow `.tint` or `.accentColor` | |

**User's choice:** VGTheme.accentTerra

---

## Freeze Reload Gap (WID-02)

**Where to add missing reloadAllTimelines():**

| Option | Description | Selected |
|--------|-------------|----------|
| Add in StatsView after freeze() (Recommended) | Surgical one-line fix; keeps StreakFreezeService pure | ✓ |
| Move freeze into GoalViewModel | Centralizes all widget mutations; more refactor | |
| Add inside StreakFreezeService.freeze() | Automatic but adds WidgetKit dependency to pure service | |

**User's choice:** Add in StatsView after freeze() call

---

**WID-02 audit scope:**

| Option | Description | Selected |
|--------|-------------|----------|
| Just the freeze gap | GoalViewModel covers everything else | |
| Audit all v2.0 mutation sites too | Walk all new v2.0 ViewModels/Views for missing reloads | ✓ |

**User's choice:** Audit all v2.0 mutation sites

---

## Claude's Discretion

- **Tier priority for active goal (D-03):** Chose Immediate-first over Life-Goal-first. Reasoning: the widget is a daily home screen tool — showing the most actionable today-level goal drives daily check-in behavior better than surfacing a long-horizon aspiration.
- **`activeGoalProgress: Double?` uses nil not 0.0 as sentinel:** Prevents rendering an empty bar for goals without a duration, which would look broken.

## Deferred Ideas

- **Interactive widget (tap-to-check-in):** App Intents + `AppIntentConfiguration` to let users check in from the widget. No AppIntent scaffold exists yet — v3.0 candidate.
- **Additional widget families:** systemSmall, systemLarge, accessoryCircular — not in WID-01 scope; defer to future widget phase.
