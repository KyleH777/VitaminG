# Phase 26: Analytics Dashboard - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 26-analytics-dashboard
**Areas discussed:** Entry point & navigation, Chart style (ANLT-02), Per-goal heatmap placement (ANLT-03), CSV format & export scope (ANLT-04)

---

## Entry Point & Navigation

### How should users reach the Analytics Dashboard?

| Option | Description | Selected |
|--------|-------------|----------|
| Button/link inside StatsView | StatsView already lives off the Home tab; zero new wiring | ✓ |
| New button on HomeView directly | Two separate nav destinations from Home | |
| Replace StatsView entirely | Phase 26 absorbs StatsView; higher refactor risk | |

**User's choice:** Button/link inside StatsView

---

### Where in StatsView should the Analytics entry point live?

| Option | Description | Selected |
|--------|-------------|----------|
| Nav row/button at the bottom of StatsView | "View Analytics" row at end of scroll view | ✓ |
| Toolbar button (top-right) | Small nav bar button; always visible | |
| Section header with "See More" link | Contextually placed next to the heatmap section | |

**User's choice:** Navigation row/button at the bottom of StatsView

---

### Nav title

| Option | Description | Selected |
|--------|-------------|----------|
| "Analytics" | Clear, matches phase name and requirement language | ✓ |
| "Goal History" | More descriptive of contents | |
| "Insights" | Apple-idiomatic, aligns with Health app | |

**User's choice:** "Analytics"

---

## Chart Style (ANLT-02)

### Bar chart or line chart?

| Option | Description | Selected |
|--------|-------------|----------|
| Bar chart | Discrete weekly/monthly buckets via BarMark; same pattern as GoalDetailView | ✓ |
| Line chart | LineMark trend line; needs PointMark for sparse data | |
| Toggle (bar + line) | Segmented control switching between both; doubles implementation surface | |

**User's choice:** Bar chart (BarMark)

---

### Weekly AND monthly or toggle?

| Option | Description | Selected |
|--------|-------------|----------|
| Segmented control toggle (Weekly / Monthly) | Standard iOS pattern; mirrors Health app D/W/M/Y | ✓ |
| Two separate charts stacked | No interaction needed; more vertical space | |
| Monthly only | Simplest implementation | |

**User's choice:** Segmented control toggle

---

### Y-axis definition

| Option | Description | Selected |
|--------|-------------|----------|
| % of days with at least one check-in | (days with any check-in) / (total days) × 100; consistent with ConsistencyEngine | ✓ |
| % of active goals completed each day, averaged | More granular; harder to explain to the user | |

**User's choice:** % of days with at least one check-in

---

## Per-Goal Heatmap Placement (ANLT-03)

### Where does the heatmap appear when user "taps a goal"?

| Option | Description | Selected |
|--------|-------------|----------|
| Goal list inside AnalyticsView → tap → heatmap | Self-contained in Analytics flow; no changes to GoalDetailView | ✓ |
| GoalDetailView (existing goal tap destination) | Simpler; reuses existing navigation; makes GoalDetailView heavier | |
| Both — GoalDetailView AND AnalyticsView | Most surface area to implement | |

**User's choice:** Goal list inside AnalyticsView → tap goal → expanded heatmap section

---

### How should the heatmap scroll for 1000+ days?

| Option | Description | Selected |
|--------|-------------|----------|
| Horizontal scroll (LazyHStack rows) | Mandated by REQUIREMENTS.md ANLT-03; virtualizes rows for performance | ✓ |
| Vertical scroll (more weeks stacked) | Simpler but contradicts REQUIREMENTS.md spec | |

**User's choice:** Horizontal scroll (LazyHStack) — required by ANLT-03

---

### Which goals appear in the AnalyticsView list?

| Option | Description | Selected |
|--------|-------------|----------|
| All goals (active + completed) | Analytics covers history; completed goals have valuable heatmap data | ✓ |
| Active goals only | Simpler list; completed goals have frozen heatmaps | |
| Active first, Past Goals section below | Best of both; adds section divider | |

**User's choice:** All goals (active + completed)

---

## CSV Format & Export Scope (ANLT-04)

### What should the export cover?

| Option | Description | Selected |
|--------|-------------|----------|
| All CompletionEvents across all goals (global) | Global export from AnalyticsView | |
| Per-goal export only | Export button on each goal's heatmap view | |
| Both — global AND per-goal | Most flexible; two export surfaces | ✓ |

**User's choice:** Both — global export on AnalyticsView + per-goal export on each goal's heatmap view

---

### Columns

| Option | Description | Selected |
|--------|-------------|----------|
| goal_name, date, tier | Minimal — exactly ANLT-04 spec | |
| goal_name, date, tier, goal_id | Adds stable identifier for renamed goals | |
| goal_name, date, tier, is_frozen | Distinguishes real check-ins from streak-freeze days | ✓ |

**User's choice:** goal_name, date, tier, is_frozen

---

### Date format

| Option | Description | Selected |
|--------|-------------|----------|
| ISO 8601 (YYYY-MM-DD) | Standard, unambiguous, lexicographically sortable | ✓ |
| Locale-formatted | Familiar but ambiguous across locales | |

**User's choice:** ISO 8601 (YYYY-MM-DD)

---

## Claude's Discretion

- Tier display names in CSV (raw `tierRawValue` strings vs. human-readable labels)
- Export filename convention
- Sort order of CompletionEvents in CSV (date ascending implied)
- Color palette for bar chart (existing `VGTheme` colors)
- X-axis label format for weekly/monthly buckets
- Inline-expand vs. push-navigation for goal → heatmap in AnalyticsView
- Whether to show a horizontal scroll-to-end snap on initial heatmap render

## Deferred Ideas

None — discussion stayed within phase scope.
