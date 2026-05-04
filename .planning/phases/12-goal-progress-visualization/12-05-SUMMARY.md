---
phase: 12
plan: "05"
status: complete
wave: 1
completed: 2026-05-03
key-files:
  modified:
    - VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift
---

## Summary

GoalDetailView gains a "Progress History" card between the quote card and notes sections. The card shows total completions, last completed date, a 30-day Swift Charts bar chart, and a momentum score color-coded dot. Build verified green.

## What Was Built

- `import Charts` added at top of file (Apple first-party; no third-party deps)
- `private var goalEvents: [CompletionEvent]` — reads `goal.completionEvents ?? []` per body refresh
- `private var totalCompletions: Int` — `goalEvents.count`
- `private var lastCompletedDate: Date?` — max of `completedAt` values, nil if never completed
- `private var progressVM: ProgressViewModel` — pure struct delegate, re-instantiated per render
- `progressSection` (@ViewBuilder) — card containing:
  - "Progress History" header (footnote semibold rounded, secondary color)
  - "Total completions" row with count (body semibold)
  - "Last completed" row with abbreviated date or "Never" (body semibold)
  - 30-day `Chart(chartItems)` with `BarMark(x: unit .day, y: count)`, tier color fill, Y-axis hidden, last-7-day X-axis weekday labels, 80pt height
  - Accessibility: `.accessibilityLabel` + `.accessibilityValue` on chart
  - Momentum HStack: 10pt color circle dot, "Momentum" label, "completions in the last 7 days" caption, trailing score `"%.2f"`
  - Momentum row accessibility: `.accessibilityElement(children: .combine)` with combined label
  - Card styled: `.padding(16).background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal)`
- `progressSection` inserted between `quoteCardSection` and `notesSection` in body VStack

## Momentum Color Thresholds

| Score | Color |
|-------|-------|
| >= 0.5 | `.green` |
| >= 0.1 | `.orange` |
| < 0.1 | `.secondary` |

## Deviations from Plan

None — plan executed exactly as written. The `progressSection` implementation follows the plan's `<action>` block and `<behavior>` spec precisely, including accessibility labels and the chart X-axis last-7-dates approach.

## Self-Check: PASSED

- Build green: `** BUILD SUCCEEDED **` with `-sdk iphonesimulator -destination "platform=iOS Simulator,name=iPhone 17 Pro"`
- `import Charts` count: 1
- `progressSection` count: 2 (insertion in VStack + property declaration)
- `BarMark(` count: 1
- `Chart(chartItems)` count: 1
- `.chartYAxis(.hidden)` count: 1
- `Total completions` count: 1
- `Last completed` count: 1
- `Momentum` count: 3 (label, description, accessibility)
- `.frame(height: 80)` count: 1
- `completions in the last 7 days` count: 2 (caption + accessibility label)
- `AxisValueLabel` count: 1
- `Progress History` count: 1
- progressSection positioned between quoteCardSection and notesSection: confirmed
