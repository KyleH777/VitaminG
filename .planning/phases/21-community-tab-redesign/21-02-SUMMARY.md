---
phase: 21-community-tab-redesign
plan: "02"
subsystem: community-service
tags: [cloudkit, community, social, goal-glimpse, reactions]
dependency_graph:
  requires: [21-01]
  provides: [writeGlimpse, fetchGlimpses, writeUserPresence, fetchActiveUsers, writeApplause, fetchReceivedApplause, fetchGlowingUser, fetchGlobalPosts, writeReply, fetchReplies, addCheckIn-glimpse-injection]
  affects: [21-03, GoalViewModel, GoalDetailView]
tech_stack:
  added: []
  patterns: [cloudkit-upsert-fetch-or-create, ck-asset-application-support-copy, fire-and-forget-task, profanity-gate, conflict-retry-serverRecordChanged]
key_files:
  created: []
  modified:
    - VitaminG/VitaminG/VitaminG/Services/CommunityService.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift
    - VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift
decisions:
  - "GoalGlimpse upsert keyed on sanitized username + todayKey (ISO8601 YYYY-MM-DD); fetch-or-create pattern reuses existing CKRecord to avoid duplicates"
  - "writeGlimpse is fully fire-and-forget (async, no throws) — all errors silently discarded to avoid blocking UI check-in flow"
  - "writeReply returns Bool (false on profanity or final CloudKit failure) and is @discardableResult for flexible caller usage"
  - "Progress percent in GoalGlimpse = min(100, completionCount / durationDays * 100); defaults to 0 when durationDays nil or zero"
  - "addCheckIn guards writeGlimpse call with !username.isEmpty to avoid writing empty-username glimpse records for legacy call sites"
  - "CheckInCelebrationView has no addCheckIn call site; only GoalDetailView updated (second call site mentioned in plan does not exist in current codebase)"
metrics:
  duration: "5 minutes"
  completed: "2026-05-23"
  tasks_completed: 2
  files_modified: 3
---

# Phase 21 Plan 02: CommunityService Extension + GoalGlimpse Injection Summary

Extended CommunityService with 9 new CloudKit methods for the Phase 21 community hub (GoalGlimpse, UserPresence, Applause, CommunityReply, global feed) and injected a fire-and-forget GoalGlimpse upsert into GoalViewModel.addCheckIn.

## Tasks Completed

| # | Task | Commit | Key Changes |
|---|------|--------|-------------|
| 1 | Add ReactionType.fire + 9 new CommunityService methods | 91773b5 | CommunityService.swift +307 lines: case fire, 4 record type constants, 9 new static methods, private mapRecordToGlimpseItem helper |
| 2 | Inject GoalGlimpse write into GoalViewModel.addCheckIn | 32e2f3e | GoalViewModel.swift: addCheckIn extended signature with username/colorHex defaults; GoalDetailView.swift: @Query profiles added, call site updated |

## What Was Built

### Task 1: CommunityService Extensions

**ReactionType.fire** — Added `case fire` to existing enum with `fieldKey == "fireCount"`.

**Record type constants** — `glimpseRecordType`, `presenceRecordType`, `applauseRecordType`, `replyRecordType`.

**9 new static async methods:**
- `writeGlimpse` — upserts GoalGlimpse keyed on username + todayKey (fetch-or-create pattern), handles optional photoData via compressToJPEG + CKAsset, conflict retry, fire-and-forget (no throws)
- `fetchGlimpses` — dayKey predicate, sort descending, CKAsset copied to Application Support via UUID-named destination
- `writeUserPresence` — upserts by username, sets lastActiveDate = Date(), fire-and-forget
- `fetchActiveUsers` — lastActiveDate > now-7200, sort descending, resultsLimit:20
- `writeApplause` — creates new Applause CKRecord, conflict retry once
- `fetchReceivedApplause` — recipientUsername predicate, sort descending, resultsLimit:20
- `fetchGlowingUser` — dayKey >= sevenDaysAgoKey predicate, sort descending, resultsLimit:50
- `fetchGlobalPosts` — reportCount < 3, sort descending, configurable limit defaulting to 50
- `writeReply` — ProfanityFilter gate (returns false if profane), InputSanitizer on all fields, conflict retry, returns Bool
- `fetchReplies` — parentPostID predicate, sort ascending, resultsLimit:50
- `mapRecordToGlimpseItem` (private) — shared CKAsset-copy helper for fetchGlimpses and fetchGlowingUser

All user string fields pass through `InputSanitizer.sanitizeForPublic()` before CKRecord assignment (21 occurrences total).

### Task 2: GoalViewModel.addCheckIn Injection

- Extended signature: `func addCheckIn(for goal: Goal, context: ModelContext, username: String = "", colorHex: String = "")` — default empty strings keep all existing call sites backward-compatible without modification
- Fire-and-forget `Task { await CommunityService.writeGlimpse(...) }` runs at end of addCheckIn when username is non-empty
- Progress percent: `min(100, (completionCount * 100) / durationDays)` where completionCount = events count + 1 (includes the just-inserted event); defaults to 0 when durationDays is nil or zero
- GoalDetailView.swift: added `@Query private var profiles: [UserProfile]`; updated check-in button to pass `profiles.first?.displayName ?? ""` and `profiles.first?.avatarColorHex ?? ""`

## Deviations from Plan

### Adjustments

**1. [Rule 2 - Missing functionality] CheckInCelebrationView had no addCheckIn call site**
- **Found during:** Task 2
- **Issue:** Plan specified updating both GoalDetailView and CheckInCelebrationView, but CheckInCelebrationView is a pure presentation view (receives `streakCount: Int` and `onDismiss: () -> Void`). It has no GoalViewModel injection and does not call addCheckIn.
- **Fix:** Updated only GoalDetailView (the sole actual call site). CheckInCelebrationView left unchanged — no update needed.
- **Files modified:** None (no CheckInCelebrationView change required)

## Known Stubs

None — all methods are fully implemented with real CloudKit calls.

## Threat Surface Scan

No new network endpoints or auth paths introduced beyond what is described in the plan's threat model. The 9 new CloudKit public DB writes are all accounted for in T-21-02-01 through T-21-02-05.

## Self-Check: PASSED

- CommunityService.swift: modified and committed at 91773b5
- GoalViewModel.swift: modified and committed at 32e2f3e
- GoalDetailView.swift: modified and committed at 32e2f3e
- grep "case fire": confirmed
- grep -c method names: 10 confirmed
- grep "CommunityService.writeGlimpse": confirmed
- grep "applicationSupportDirectory": confirmed
- grep -c "sanitizeForPublic": 21 (>= 9 required)
- Build: SUCCEEDED (zero new errors)
