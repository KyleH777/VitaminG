# Phase 11: Gratitude / Daily Wins Module - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 11 adds a dedicated gratitude / daily wins logging capability to Vitamin G. Users get a new **4th tab ("Wins")** where they can write a free-text entry for today, edit it any time before midnight, and scroll through a reverse-chronological history of past entries. A second daily push notification — "What's your win today?" — fires at a separately configurable time, distinct from the existing goal-reminder notification. A new `DailyWin` SwiftData model (SchemaV3) persists entries date-keyed with UUID + date + text.

Phase 11 does NOT add: entry reactions, streaks on gratitude, social sharing of wins, or structured prompt templates — those are future capabilities.

</domain>

<decisions>
## Implementation Decisions

### Navigation / Entry Point (GRAT-06)
- **D-01:** Add a 4th tab "Wins" to `ContentView`'s `TabView`. Tab order: Goals · Stats · Wins · Profile.
- **D-02:** Use a journal or leaf SF Symbol for the Wins tab icon (e.g., `book.pages` or `leaf`).
- **D-03:** The Wins tab is the primary — and only — entry point in Phase 11. No home screen shortcut in this phase.

### Win Entry Format (GRAT-01, GRAT-04)
- **D-04:** Single free-text `TextEditor` field, max 500 characters (consistent with `goalDescription` 500-char limit pattern). Validated at ViewModel layer before SwiftData insert.
- **D-05:** One entry per calendar day (`Calendar.current` day comparison — DST-safe, same pattern as StreakEngine). GRAT-04: if today's entry already exists, the editor pre-fills with the existing text.
- **D-06:** Entries are **editable** at any time (not just until midnight). The "one per day" rule means no second entry can be created for the same day, but the existing entry can always be edited or deleted. This matches user expectation for a journal.
- **D-07:** Entries can be deleted individually from the history view (swipe-to-delete pattern, consistent with GoalListView's delete flow).

### History Layout (GRAT-03)
- **D-08:** Reverse-chronological card list (newest first). Each card shows the calendar date (formatted as "Monday, May 1") and the entry text. No calendar grid in Phase 11 — the simpler list is faster to build and cleaner to read.
- **D-09:** Today's entry editor appears at the top of the Wins tab — above the history list. If no entry exists today, the editor shows a warm placeholder ("What's your win today?"). If an entry exists, it pre-fills.
- **D-10:** History section is titled "Past Wins" and appears below today's editor, separated by a section header. Empty state: "Your wins will appear here." (warm, non-intrusive).

### Notification Configuration (GRAT-05)
- **D-11:** The "What's your win today?" notification uses a **separate identifier** — `com.kyleharrington.VitaminG.winReminder` — distinct from the existing `com.kyleharrington.VitaminG.dailyReminder`. NotificationScheduler gets a second static method / second identifier for win reminders. Both stay within the iOS 64-request cap via the same remove-before-add pattern.
- **D-12:** `SettingsView` gains a second notification time row: "Win reminder" below the existing "Goal reminder". Same UX pattern: time picker, same `UNCalendarNotificationTrigger` approach. Stored in `NotificationPreferences` using new keys (e.g., `winNotificationHour` / `winNotificationMinute`), defaulting to 8:00 PM.
- **D-13:** Win notification content: title = "Vitamin G" (or "Daily Win"), body = "What's your win today?" — static body (no goal titles). No deep-link routing needed in Phase 11; tapping opens the app to the Wins tab (standard foreground open is sufficient).

### Schema Migration (GRAT-02)
- **D-14:** Add `DailyWin` model inside a new `SchemaV3` enum following the existing pattern in `SchemaV2.swift`. Fields: `id` (UUID, default `UUID()`), `date` (Date?), `text` (String?) — all optional for CloudKit compatibility. No relationships needed in Phase 11.
- **D-15:** Extend `VitaminGMigrationPlan` with a `migrateV2toV3` lightweight stage. Adding a new model qualifies as lightweight migration (same precedent as UserProfile in V2).
- **D-16:** Update `ModelContainerFactory` to include `DailyWin.self` in the models array.

### Claude's Discretion
- Exact color/icon for the Wins tab (warm tone — consistent with existing tier palette)
- Whether the today-section uses a `TextEditor` inline or opens a sheet on tap (either is fine)
- Exact typography and card padding in the history list (follow existing card patterns from GoalListView)
- Whether to show entry character count in the editor (recommended: yes, subtle)
- Win notification deep-link behavior: tapping can navigate to Wins tab via AppRoute (add `.wins` case if AppRouter has one; otherwise plain app open is acceptable)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Data model and schema migration
- `VitaminG/VitaminG/VitaminG/Models/SchemaV2.swift` — Pattern for VersionedSchema enum, model declarations, migration plan, typealiases. SchemaV3 must follow this exactly.
- `VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift` — Add `DailyWin.self` to models array here.

### Notification infrastructure
- `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` — Existing scheduler with single-identifier remove-before-add pattern. Add second method for win reminder using new identifier.
- `VitaminG/VitaminG/VitaminG/Services/NotificationPreferences.swift` — Existing UserDefaults keys for hour/minute. Add `winNotificationHour` / `winNotificationMinute` here.
- `VitaminG/VitaminG/VitaminG/Services/NotificationDelegate.swift` — Deep-link routing on notification tap; extend if Wins tab navigation is needed.

### Navigation infrastructure
- `VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift` — Add `.wins` case if deep-link navigation to Wins tab is wired.
- `VitaminG/VitaminG/VitaminG/Navigation/AppRouter.swift` — `@Observable` router injected at WindowGroup level; consistent injection pattern for new ViewModel.
- `VitaminG/VitaminG/VitaminG/Views/ContentView.swift` — Add 4th tab (Wins) to `TabView` here.

### UI patterns to match
- `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift` — Swipe-to-delete pattern, section headers, empty state structure.
- `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift` — Time picker row pattern for the second notification row.
- `VitaminG/VitaminG/VitaminG/Services/StreakEngine.swift` — `Calendar.current` day-comparison pattern for one-entry-per-day enforcement.

### Architecture and constraints
- `.planning/PROJECT.md` — Stack constraints (no third-party deps), MVVM enforcement, iOS 17+ minimum, input validation rules.
- `.planning/REQUIREMENTS.md` — GRAT-01 through GRAT-06 are the requirements being closed by this phase.
- `VitaminG/CLAUDE.md` — SwiftData model rules (all optional for CloudKit), `@Observable` ViewModel pattern, Dynamic Type + reduced motion requirements.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `NotificationScheduler` — Already handles one notification with remove-before-add pattern and `UNCalendarNotificationTrigger`. Add a parallel `scheduleWinReminder(hour:minute:)` method using a new identifier constant.
- `NotificationPreferences` — Already stores hour/minute in UserDefaults. Extend with two new keys for win reminder time.
- `StreakEngine` — Contains the `Calendar.current` day-comparison logic. The "one entry per day" check in `DailyWinsViewModel` should replicate this pattern.
- `InputSanitizer` — Existing input validation service. Use for the 500-char limit on win entry text.
- `GoalListView` — Provides the swipe-to-delete, section header, and empty state patterns the Wins history list should mirror.

### Established Patterns
- `@Observable` ViewModel with `@Query` or manual fetch — all ViewModels in this project follow this pattern (see `GoalViewModel`, `StatsViewModel`).
- VersionedSchema enum — every model addition lives inside a new `SchemaVN` enum with a `VitaminGMigrationPlan` lightweight stage.
- `ModelContainerFactory` — single source of truth for the models array; must be updated when new models are added.
- Dynamic Type: use semantic font modifiers (`.font(.body)`, `.font(.headline)`) — no fixed sizes.
- Reduced motion: gate animations on `@Environment(\.accessibilityReduceMotion)`.

### Integration Points
- `ContentView.swift` — new Wins tab added to existing `TabView`
- `SettingsView.swift` — second notification time row wired to `NotificationScheduler`
- `VitaminGMigrationPlan` in `SchemaV2.swift` → extended in `SchemaV3.swift` with `migrateV2toV3` stage
- `ModelContainerFactory` — `DailyWin.self` added to models array

</code_context>

<specifics>
## Specific Ideas

- Tab icon: `book.pages` or `leaf` SF Symbol (warm, reflective — matches app tone)
- Today's editor placeholder text: "What's your win today?" (mirrors notification prompt)
- Win notification default time: 8:00 PM (evening reflection vs. 8:00 AM morning goals reminder)
- Past wins date format: "Monday, May 1" — friendly, not ISO
- No structured prompts in Phase 11 — simplicity is the point

</specifics>

<deferred>
## Deferred Ideas

- **Gratitude streaks** — Tracking consecutive days of win entries (like goal streaks). Could integrate with Phase 12's momentum score concept. Defer to Phase 12 or a future phase.
- **Structured prompts / prompt rotation** — Rotating "What are you grateful for?" style prompts. Would require a prompt model or hardcoded list. Defer to a future polish phase.
- **Heatmap for wins** — Calendar grid view of days with entries (like StatsView's HeatmapView). Could be added alongside or replacing the list in a future phase.
- **Home screen shortcut** — Quick-add win from home screen. Defer to widget work (Phase 4 patterns).

</deferred>

---

*Phase: 11-gratitude-daily-wins*
*Context gathered: 2026-05-01*
