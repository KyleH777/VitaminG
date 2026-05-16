---
phase: 12
status: findings
reviewed: 2026-05-03
depth: standard
files_reviewed: 6
files_reviewed_list:
  - VitaminG/VitaminG/VitaminG/Services/ProgressViewModel.swift
  - VitaminG/VitaminG/VitaminG/Views/Components/ProgressRingView.swift
  - VitaminG/VitaminG/VitaminG/Views/GoalListView.swift
  - VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
  - VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift
  - VitaminG/VitaminG/VitaminGTests/ProgressViewModelTests.swift
findings:
  critical: 2
  warning: 5
  info: 3
  total: 10
---

# Phase 12 Code Review

## Summary

The core progress math (7-day window, clamp, completed-goal override) is correct and well-tested. However, two critical issues exist: a property-name mismatch in a SwiftData predicate that compiles but produces wrong results at runtime, and a missing `@Query` for `CompletionEvent` in `GoalDetailView` that silently falls back to an in-memory relationship that can miss events added after the view is loaded. Five warnings cover unstored `Task` handles (can produce race conditions), a duplicate `ProgressViewModel()` allocation on every row render, magic color literals duplicated across files, an accessibility label that surfaces a raw decimal instead of a rounded integer, and a missing reduced-motion gate on the `EmptyStateView` pulse animation.

---

## Critical Issues

### CR-01: SwiftData predicate references non-existent property `isCompleted` — wrong results at runtime

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift:179`

**Issue:** `rescheduleNotification` builds a `FetchDescriptor<Goal>` with the predicate `#Predicate { !$0.isCompleted }`. The stored SwiftData property on `Goal` is `isCompleted` (line 29 of SchemaV1.swift), so the predicate key path compiles because `isCompleted` does exist. **However**, across the rest of the codebase (GoalListView, GoalRowView, GoalDetailView, ProgressViewModel) the code uniformly accesses `goal.completed`, which is the computed wrapper. The predicate macro expands at compile time using the stored-property key path, so `#Predicate { !$0.isCompleted }` is actually correct — but this means the two usages are mismatched in naming convention and one is fragile.

The real bug is the inverse: every other site that writes `goal.completed.toggle()` (e.g. `toggleCompletion`, line 115) mutates the computed wrapper `completed`, which in turn sets `isCompleted`. But `goal.completed` is **not** a stored property, so a `#Predicate` using `$0.completed` would crash at runtime with "Key path cannot be used in a predicate". If any future developer copies the pattern from `toggleCompletion` into a predicate, it will silently compile and crash at runtime. More critically, `GoalDetailView.progressSection` (line 205–211) builds `goalEvents` from `goal.completionEvents ?? []`, which is the in-memory relationship snapshot, not a live `@Query`. This is covered in CR-02.

For this finding the direct correctness issue is: **`rescheduleNotification` uses `isCompleted` in the predicate but `toggleCompletion` sets `completed` (the wrapper).** Because `completed` and `isCompleted` both resolve to the same stored column this works today, but the asymmetry is a maintainability trap. Mark the predicate with a comment or unify usage to one accessor so the intent is unambiguous.

**Fix:**
```swift
// GoalViewModel.swift line 179 — use the stored property name explicitly and document it
let descriptor = FetchDescriptor<Goal>(
    // NOTE: Use isCompleted (stored property), NOT completed (computed wrapper).
    // #Predicate macros require stored-property key paths.
    predicate: #Predicate { !$0.isCompleted }
)
```

---

### CR-02: `GoalDetailView.progressSection` uses an in-memory relationship snapshot — completions added during the session are invisible until navigation pop/push

**File:** `VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift:190–211`

**Issue:** `goalEvents` is a plain computed property that reads `goal.completionEvents ?? []`. This is the relationship array cached on the in-memory `Goal` object when the view was pushed. When the user taps "Mark as Complete" in `GoalDetailView.actionsSection` (line 306), `toggleCompletion` inserts a new `CompletionEvent` via `context.insert(event)` in `GoalViewModel`. SwiftData will add the new event to the model graph, but SwiftUI body re-evaluation reads `goal.completionEvents` from the same live `@Model` object, which **should** update via `@Observable` — however the chart, total-completions count, and momentum score all re-derive from `goalEvents` which re-reads the relationship. If SwiftData defers faulting the relationship (which it does in some configurations), the count and chart will not reflect the just-added event until the view is re-presented.

The safe pattern mandated by the project's CLAUDE.md is to use `@Query` for all list reads. `GoalDetailView` has no `@Query` for `CompletionEvent`. Adding one scoped to the goal's `id` guarantees live update.

**Fix:**
```swift
// Add a scoped @Query at the top of GoalDetailView:
@Query private var allEvents: [CompletionEvent]

// Then scope in computed property:
private var goalEvents: [CompletionEvent] {
    allEvents.filter { $0.goal?.id == goal.id }
}
```
Or use a dynamic query predicate initialised from `goal.id` in an `init` that takes the goal.

---

## Warnings

### WR-01: Unstored `Task` handles in `fireMilestoneBadge` and `onChange(of: goal.completed)` — cannot be cancelled on view disappear

**File:** `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift:285–290, 308–332`

**Issue:** Both animation `Task { @MainActor in ... }` blocks in `GoalRowView` are fire-and-forget. `GoalRowView` is a private struct inside a `List`, so rows are destroyed and recreated as the user scrolls. If a row disappears while a `Task.sleep` is in-flight, the task continues running, calls `withAnimation(...)` on `@State` variables that belong to a deallocated view, and writes back `showMilestoneBadge = false` or `bounceScale = 1.0` into a stale state store. In practice SwiftUI does not crash on this, but the animation may fire on the wrong row after list reuse, and the badge state can get stuck. The same pattern applies to the `Task` in `GoalListView.onChange(of: viewModel.pendingMilestone?.goalID)` (line 141–145).

**Fix:**
```swift
// In GoalRowView, store tasks:
@State private var bounceTask: Task<Void, Never>?
@State private var badgeTask: Task<Void, Never>?

// On .onChange(of: goal.completed):
bounceTask?.cancel()
bounceTask = Task { @MainActor in
    try? await Task.sleep(for: .milliseconds(150))
    guard !Task.isCancelled else { return }
    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { bounceScale = 1.0 }
}

// Cancel in .onDisappear:
.onDisappear {
    bounceTask?.cancel()
    badgeTask?.cancel()
}
```

---

### WR-02: `ProgressViewModel()` allocated on every `body` evaluation of `GoalRowView`

**File:** `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift:258`

**Issue:** `GoalRowView.body` calls `ProgressViewModel().ringProgress(for: goal, events: events)` (line 258). `GoalRowView` is a `struct` View, so `body` is called by SwiftUI whenever any observed state changes — including unrelated parent-state changes. `ProgressViewModel` is a plain `struct` (no stored state), so allocation is cheap, but the pattern defeats the intent of the `progressVM` singleton on `GoalViewModel` (line 63 of GoalViewModel.swift) and creates an inconsistency: the list computes progress with ephemeral instances while the detail view and GoalViewModel share a reused instance. Move the `ProgressViewModel` to a `@State` or `let` constant so it is consistent.

**Fix:**
```swift
// In GoalRowView, add:
private let progressVM = ProgressViewModel()

// In body:
ProgressRingView(
    progress: progressVM.ringProgress(for: goal, events: events),
    tier: goal.tier,
    isCompleted: goal.completed
)
```

---

### WR-03: Magic color literal `Color(red: 0.063, green: 0.725, blue: 0.506)` duplicated in four places with no shared constant

**File:** `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift:167, 220` | `VitaminG/VitaminG/VitaminG/Views/Components/ProgressRingView.swift:21` | `VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift:123, 317`

**Issue:** The `completionGreen` color is defined as a private `let` in `GoalRowView` (line 220) and again in `ProgressRingView` (line 21), and used inline in `GoalDetailView` (lines 123, 317) and `GoalListView` (line 167). The comment in `ProgressRingView` explicitly says "keep in sync", which is a code smell acknowledging the duplication. If the brand color changes, four sites must be updated in sync; missing any one produces visual inconsistency.

**Fix:** Add a single extension on `Color` in a shared file (e.g., `VitaminGColors.swift`):
```swift
extension Color {
    static let completionGreen = Color(red: 0.063, green: 0.725, blue: 0.506)
}
```
Remove the four private `let` declarations and inline literals.

---

### WR-04: Accessibility label on `ProgressRingView` surfaces a raw integer percentage that rounds incorrectly for progress values below 1%

**File:** `VitaminG/VitaminG/VitaminG/Views/Components/ProgressRingView.swift:47`

**Issue:** The label is `"\(Int(progress * 100))% momentum this week"`. `Int(...)` truncates (not rounds) toward zero: a `progress` of 0.999 (6 completions) produces "99% momentum" rather than "100%", and any value below 0.01 (< 1 completion in 7 days but > 0) produces "0%" even though the ring is visually non-empty. For VoiceOver users the label is misleading. The completed-goal branch ("Goal complete") is fine.

**Fix:**
```swift
.accessibilityLabel(
    isCompleted
        ? "Goal complete"
        : "\(Int((progress * 100).rounded()))% momentum this week"
)
```

---

### WR-05: `EmptyStateView` `.symbolEffect(.pulse)` is not gated on `accessibilityReduceMotion`

**File:** `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift:374`

**Issue:** The star icon in `EmptyStateView` applies `.symbolEffect(.pulse)` unconditionally. Every other animation in this phase (ProgressRingView, GoalRowView bounce, milestone badge) respects `@Environment(\.accessibilityReduceMotion)`. The omission is inconsistent with the project's stated commitment to reduce-motion support (D-15 in design constraints) and will trigger continuous motion for users who have requested reduced motion.

**Fix:**
```swift
struct EmptyStateView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // In body:
    Image(systemName: "star.circle.fill")
        // ...
        .symbolEffect(.pulse, isActive: !reduceMotion)
}
```

---

## Info

### IN-01: `chartData` comment says "oldest-first" but the implementation reverses a **descending** range — correct but confusing

**File:** `VitaminG/VitaminG/VitaminG/Services/ProgressViewModel.swift:74–81`

**Issue:** The range `(0..<30)` iterates offsets 0 (today) through 29 (29 days ago), producing a descending date sequence, which is then `.reversed()` to yield oldest-first. The comment says "offset 29 (29 days ago) … offset 0 (today)" but the code iterates 0…29 and reverses — the comment describes the **post-reversal** order, not the loop order. This is correct but easily misread by someone tracing the loop.

**Fix:** Reverse the range instead of calling `.reversed()` on the result, or rewrite the comment to describe the loop iteration order, then note the reversal.

```swift
// Iterate descending (today first) then reverse to produce oldest-first output
return (0..<30).map { offset -> DayCount in
    let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
    return DayCount(date: day, count: dict[day] ?? 0)
}.reversed()
```

---

### IN-02: Test helper `makeEvent(daysAgo:tier:)` force-unwraps `calendar.date(byAdding:)` — acceptable in tests but worth noting

**File:** `VitaminG/VitaminG/VitaminGTests/ProgressViewModelTests.swift:36`

**Issue:** `cal.date(byAdding: .day, value: -daysAgo, to: today)!` will crash the test suite if `Calendar.current` returns `nil` (extremely unlikely but not impossible under a custom test locale). This is test code so not a production risk, but XCTest's `setUp` already throws, making it easy to use `try XCTUnwrap(...)` instead.

**Fix:**
```swift
let date = try XCTUnwrap(cal.date(byAdding: .day, value: -daysAgo, to: today))
```

---

### IN-03: `milestoneJustCrossed` uses exact-equality check (`count == threshold`) — missed if toggleCompletion is called twice before the event count updates

**File:** `VitaminG/VitaminG/VitaminG/Services/ProgressViewModel.swift:95`

**Issue:** The milestone fires only when `count == threshold` exactly. If `goal.completionEvents?.count` jumps from 4 to 6 in a single transaction (e.g., batch import or test seeding), the threshold of 5 is skipped silently. This is low-risk in normal single-tap usage but could be encountered in testing or future bulk-import features. The `firedSet` dedup means a missed threshold is never recoverable.

**Fix:** Change the condition to `count >= threshold && count - 1 < threshold` (i.e., threshold was just crossed from below) or use `count >= threshold`:
```swift
// Fires on the first event that meets or exceeds the threshold, not just the exact count
if count >= threshold && !firedSet.contains(key) {
    return threshold
}
```
Then mark the threshold fired immediately so future counts > threshold don't re-fire.

---

## Verdict

**needs-fixes** — Two critical issues (SwiftData predicate naming ambiguity / CR-01, and stale in-memory relationship in detail view / CR-02) must be resolved before shipping. The five warnings are important quality issues, particularly the unstored Task handles (WR-01) and missing reduce-motion gate (WR-05).

---

_Reviewed: 2026-05-03_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
