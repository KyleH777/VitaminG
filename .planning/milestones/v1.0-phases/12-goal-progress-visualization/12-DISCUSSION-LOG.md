# Phase 12: Goal Progress Visualization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-03
**Phase:** 12-goal-progress-visualization
**Areas discussed:** Progress ring placement, Time window, Milestone celebration style, Detail view history format

---

## Progress Ring Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Replace tier pip with circular ring | 28pt diameter, 3pt stroke, tier color, clockwise fill. Zero layout change — same HStack slot as current 4×36pt pip. | ✓ |
| Thin bar below title | Horizontal progress bar spanning the title/desc VStack width. More familiar reading metaphor; slightly taller rows. | |

**User's choice:** Replace the tier pip with a circular progress ring (recommended option accepted).
**Notes:** User selected "Do what you think would be best" across all areas — all recommended options accepted.

---

## "Recent" Time Window

| Option | Description | Selected |
|--------|-------------|----------|
| 7 days, consistent with momentum | Ring fill = completions last 7 days ÷ 7. Same formula as PROG-04 momentum score. Drains quickly when inactive. | ✓ |
| 30 days, more forgiving | Ring fill = completions last 30 days ÷ 30. Slower to fill and drain. Better for long-term goals. | |

**User's choice:** 7-day window (recommended option accepted).
**Notes:** Consistency between ring and momentum score was the deciding factor.

---

## Milestone Celebration Style

| Option | Description | Selected |
|--------|-------------|----------|
| Animated badge overlay, non-blocking | .star.fill SF Symbol, tier color, scale+fade over the card for ~2s. No modal. | ✓ |
| Full-screen confetti overlay | Custom Canvas particle confetti for 1.5s. More dramatic but ~80 lines of particle code. | |

**User's choice:** Animated badge overlay, non-blocking (recommended option accepted).
**Notes:** No third-party deps constraint made confetti less attractive. Non-blocking keeps the flow.

---

## Detail View History Format

| Option | Description | Selected |
|--------|-------------|----------|
| Swift Charts bar chart, per-goal | Bar per day, last 30 days, filtered to this goal's CompletionEvents. Apple framework, no deps. | ✓ |
| Reuse HeatmapView, scoped per-goal | Filter existing [Date: Int] HeatmapView to this goal's events. Fast to build. | |

**User's choice:** Swift Charts bar chart (recommended option accepted).
**Notes:** Per-goal heatmap would be too sparse for most goals; bar chart shows trend direction better.

---

## Claude's Discretion

- Exact SF Symbol for milestone badge (`.star.fill` vs `.trophy.fill` for 50 threshold)
- Progress ring animation on appear
- Chart X-axis label density
- Exact padding in GoalDetailView progress section

## Deferred Ideas

- Cross-goal progress dashboard / leaderboard — future phase
- Persistent milestone history across launches — UserDefaults polish, future phase
- Streak arc layer on progress ring — StatsView already covers streaks
- Widget showing individual goal progress ring — Phase 4 extension
