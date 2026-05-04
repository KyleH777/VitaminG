---
status: partial
phase: 04-icloud-sync-widgets
source: [04-VERIFICATION.md]
started: 2026-05-04
updated: 2026-05-04
---

## Current Test

Awaiting physical device testing.

## Tests

### 1. Cross-Device iCloud Sync
expected: Sign two physical iOS devices into the same iCloud account. Create a goal on Device A. Within ~60 seconds, it appears on Device B with no manual refresh.
result: [pending]

### 2. Home Screen Widget Rendering
expected: Long-press home screen → + → search "Vitamin G" → add GoalSummaryWidget (medium). Widget shows 4 tier rows with top goal titles and a streak footer.
result: [pending]

### 3. Lock Screen Widget Rendering
expected: Lock screen customization → add Vitamin G accessoryRectangular widget. Shows streak count or top Immediate goal title; falls back to "Set a goal" when empty.
result: [pending]

### 4. Widget Refresh After Goal Mutation
expected: With widgets installed, create or complete a goal in the app. Both widgets update within the WidgetKit refresh window (~30s).
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
