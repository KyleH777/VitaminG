---
phase: 11-gratitude-daily-wins
fixed_at: 2026-05-01T00:00:00Z
review_path: .planning/phases/11-gratitude-daily-wins/11-REVIEW.md
iteration: 1
findings_in_scope: 10
fixed: 10
skipped: 0
status: all_fixed
---

# Phase 11: Code Review Fix Report

**Fixed at:** 2026-05-01
**Source review:** `.planning/phases/11-gratitude-daily-wins/11-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 10 (1 critical, 6 warning, 3 info)
- Fixed: 10
- Skipped: 0

All 10 findings raised in the Phase 11 code review were addressed. Each fix
was committed atomically with `--no-verify`. No tests were modified (the
existing 10 `DailyWinsViewModelTests` continue to operate against the same
public API: `draftText`, `validationError`, `saveEntry(context:)`,
`todayEntry(context:)`, `delete(_:context:)`). No SwiftData schema changes were
made — `SchemaV3` remains the current version.

## Fixed Issues

### CR-01: Win reminder scheduled on every launch without checking authorization

**Files modified:** `VitaminG/VitaminG/VitaminG/VitaminGApp.swift`
**Commit:** `6af56c9`
**Applied fix:** Wrapped the launch-time `rescheduleWinReminder()` call inside
an `await NotificationScheduler.shared.isAuthorized()` guard, mirroring the
existing pattern that gates `reschedule(activeGoals:)` in `SettingsView`. Added
an inline comment explaining the rationale (avoids wasted remove-before-add
work and asymmetry with the goal reminder flow).

### WR-01: `scheduleWinReminder` and `schedule` silently discard `center.add` errors

**Files modified:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift`
**Commit:** `c2a94af`
**Applied fix:** Replaced both `try? await center.add(request)` call sites
(lines 72 and 150 in pre-fix numbering — daily reminder and win reminder)
with `do { try ... } catch { #if DEBUG print(...) #endif }`. Errors now
surface in DEBUG builds with a tagged log line; release builds remain silent
to preserve the non-fatal API contract.

### WR-02: Stale editor draft after deleting today's win re-inserts it on next save

**Files modified:** `VitaminG/VitaminG/VitaminG/Views/DailyWinsView.swift`
**Commit:** `56dfefa`
**Applied fix:** Inside the confirmationDialog "Delete" button, when
`winToDelete` is today's entry (per `Calendar.current.isDateInToday`), reset
`viewModel.draftText = ""` BEFORE calling `viewModel.delete(...)`. Prevents
the pre-filled editor from silently re-creating the deleted win on the next
Save Win tap.

### WR-03: Character counter uses raw count instead of sanitized count

**Files modified:**
- `VitaminG/VitaminG/VitaminG/ViewModels/DailyWinsViewModel.swift`
- `VitaminG/VitaminG/VitaminG/Views/DailyWinsView.swift`

**Commit:** `99f64ee`
**Applied fix:** Added `var sanitizedCount: Int { InputSanitizer.sanitize(draftText).count }`
to `DailyWinsViewModel`. Updated the `Text("\(...)/500")` and matching
`accessibilityLabel` in `DailyWinsView` to read `viewModel.sanitizedCount`
instead of `viewModel.draftText.count`. The displayed counter now matches
the value `saveEntry` validates against — no more "501/500" surprises from
trailing whitespace.

### WR-04: `historyWins` filter includes wins with `nil` date

**Files modified:** `VitaminG/VitaminG/VitaminG/Views/DailyWinsView.swift`
**Commit:** `746f90a`
**Applied fix:** Changed `guard let d = win.date else { return true }` to
`return false` so corrupt/incomplete records (nil date) are excluded from
the Past Wins list. Such records cannot be edited (`todayEntry` already
skips nil-dated rows) and would render an empty date label — better hidden.

### WR-05: Duplicate `authorizationRow` across two `Section` blocks

**Files modified:** `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift`
**Commit:** `f4dd523`
**Applied fix:** Removed the second `authorizationRow` from the Win Reminder
section. The single instance in the Daily Reminder section now serves both
notifications (UNAuthorizationStatus is per-app, not per-identifier). Added
an inline comment explaining the deliberate single-row design and the race
condition it avoids on `.notDetermined`.

### WR-06: `VitaminGMigrationPlan` lives in `SchemaV2.swift` but references `SchemaV3`

**Files modified:**
- `VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift` (NEW)
- `VitaminG/VitaminG/VitaminG/Models/SchemaV2.swift`

**Commit:** `d9c615b`
**Applied fix:** Created
`VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift` containing the
`VitaminGMigrationPlan` enum (with `migrateV1toV2` and `migrateV2toV3`
constants intact). Removed the duplicate definition from `SchemaV2.swift` and
left a marker comment pointing future schema authors at the new file. The
file lives under `VitaminG/VitaminG/VitaminG/Models/` so the project's
`PBXFileSystemSynchronizedRootGroup` picks it up automatically. No imports
needed updating — `ModelContainerFactory` already references the type via
module-level lookup.

### IN-01: `DailyWin.id = UUID()` redundantly assigned in `init`

**Files modified:** `VitaminG/VitaminG/VitaminG/Models/SchemaV3.swift`
**Commit:** `36b3b43`
**Applied fix:** Removed `self.id = UUID()` from `DailyWin.init` — the
property's default `= UUID()` already runs at instance creation. The
property itself was retained per finding guidance (CloudKit + parity with
`Goal` / `CompletionEvent`). Added an inline comment explaining the
rationale to prevent re-introduction.

### IN-02: Missing `sharedWinHour()` / `sharedWinMinute()` App Group accessors

**Files modified:** `VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift`
**Commit:** `c67e905`
**Applied fix:** Added `static func sharedWinHour() -> Int` and
`static func sharedWinMinute() -> Int` mirroring the existing `sharedHour()` /
`sharedMinute()` pattern. Both read from the App Group suite
(`group.com.kyleharrington.VitaminG`) using `winHourKey` / `winMinuteKey`,
with default-value fallback. No widget consumes these today, but the
symmetric API removes a future copy-paste hazard.

### IN-03: Keyboard dismiss timing on Save Win button

**Files modified:** `VitaminG/VitaminG/VitaminG/Views/DailyWinsView.swift`
**Commit:** `bb817e6`
**Applied fix:** Moved `editorFocused = false` to BEFORE `try viewModel.saveEntry(...)`
inside the Save Win button action. Previously, when `saveEntry` threw
(textEmpty / textTooLong), the dismiss line was skipped because it sat after
`try`. Keyboard now dismisses on every tap regardless of validation outcome.
Added a clarifying multi-line comment documenting the intentional ordering.

---

## Skipped Issues

None — all 10 findings were fixed.

---

## Verification Notes (per finding, requires human confirmation)

The following fixes touch behaviour that is best confirmed by a developer
running the app on-device or in the simulator:

- **CR-01** — confirm that on a fresh install, no "Pending Notifications"
  request appears in the device Settings before the user grants permission.
- **WR-02** — swipe-delete today's entry from Past Wins (after first creating
  one for today), confirm editor field is empty and Save Win produces a
  fresh insert (not an edit of the deleted one).
- **WR-05** — open Settings while `authStatus == .notDetermined` and confirm
  exactly one "Enable Notifications" button is visible.

---

_Fixed: 2026-05-01_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
