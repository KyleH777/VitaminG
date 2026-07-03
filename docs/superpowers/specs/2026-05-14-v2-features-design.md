# VitaminG v2 Features Design

**Date:** 2026-05-14  
**Scope:** Two-phase milestone adding dark mode completion, haptic feedback, Consistency Score, Streak Freeze, widget improvements, StandBy support, interactive lock screen widget, Claude Vision photo moderation, and privacy-first community posts.

---

## Phase 15: Quick Wins

### 1. Dark Mode Fix

**Problem:** Six views use hardcoded `Color(red:...)` values that don't adapt to dark mode. `VGTheme` already has the correct adaptive tokens — they just aren't being used.

**Fix:** Mechanical token replacement only. No new colors invented.

| Hardcoded value | Replace with | Affected files |
|----------------|--------------|----------------|
| `Color(red: 0.98, green: 0.55, blue: 0.27)` | `VGTheme.accentTerra` | StatsView, SettingsView, DailyWinsView, NotificationPermissionSheet, TiersScreen, PublicProfileView |
| `Color(red: 0.78, green: 0.48, blue: 0.95)` | `VGTheme.accentPurple` | StatsView, SettingsView, DailyWinsView, NotificationPermissionSheet, TiersScreen |
| `Color(red: 0.98, green: 0.55, blue: 0.27)` (standalone) | `VGTheme.accentTerra` | PublicProfileView (foregroundStyle + tint) |
| `Color.white.opacity(0.1)` on spark bar (GoalListView:229) | `VGTheme.accentSage.opacity(0.1)` | GoalListView |

**Note:** `Color.white.opacity(...)` in HomeView and ProfileView are intentional frosted-glass overlays on always-dark hero backgrounds — do not change these.

---

### 2. Haptic Feedback

**Where:** Two trigger points.

- `GoalRowView` — completion toggle: `.sensoryFeedback(.success, trigger: goal.completed)`
- `ChallengeCheckInView` — confirm button: `.sensoryFeedback(.success, trigger: checkInConfirmed)`

No UIKit. SwiftUI `.sensoryFeedback` only. One line per trigger point.

---

### 3. Consistency Score

**Formula:** Exponential decay over 30 days.

```
weight(daysAgo) = e^(-0.05 * daysAgo)
score = sum(completed(day) * weight(day)) / sum(weight(day)) * 100
```

Days 1–7 carry ~85% of total weight. Day 30 carries ~22%. A single missed day early in the window has minimal impact; recent consistency matters most. This prevents the psychological crash from a single off-day without rewarding streaks that were active months ago.

**New struct: `ConsistencyEngine`**
- Pure struct, zero SwiftUI/SwiftData dependency — same pattern as `StreakEngine`
- `func score(events: [CompletionEvent], asOf: Date = .now) -> Int`
- Injectable `asOf` date for unit testing
- Considers all tiers combined (global consistency, not per-tier)

**`StatsViewModel` addition:**
- `var consistencyScore: Int = 0`
- Computed alongside existing streak fields in `refresh(events:goals:)`

**New view: `ConsistencyScoreCard`**
- Standalone `View` struct, receives `score: Int` and `recentDays: [Bool]` (last 7 days, true = had ≥1 completion)
- Layout A (selected): card below `globalStreakCard` in `StatsView`
- Background: `VGTheme.backgroundSecondary`, border: `VGTheme.separator`
- Score numeral: `VGTheme.accentSage` (neon sage green in dark, sage in light)
- 7-bar mini chart: one bar per day, filled = `VGTheme.accentSage`, empty = `VGTheme.separator`
- Progress fill bar: `VGTheme.accentSage` fill on `VGTheme.separator` track
- Subtitle: "Last 30 days · recent days weighted"

---

### 4. Streak Freeze ("Never Miss Twice")

**Rule:** One freeze per calendar month. Freezing covers the current day as if the user completed a goal, preventing streak loss.

**`StreakFreezeService`**
- Backed by `UserDefaults` (App Group suite — shared with widgets)
- Keys: `vg.streakFreeze.lastFreezeDate` (`Date`), `vg.streakFreeze.usedThisMonth` (`Bool`)
- `var canFreeze: Bool` — true if `usedThisMonth == false` or `lastFreezeDate` is in a prior calendar month
- `func freeze(on date: Date = .now)` — sets `lastFreezeDate`, marks `usedThisMonth = true`, resets if month changed
- `var frozenDates: [Date]` — stored as `[TimeInterval]` in UserDefaults, used by `StreakEngine` to treat frozen days as completed

**`StreakEngine` update:**
- Add `frozenDates: [Date] = []` parameter to `currentStreak(events:asOf:frozenDates:)` — default `[]` keeps all existing callers unaffected
- A frozen date is treated as a completed day only when it has zero `CompletionEvent` records. If the user actually completed a goal on a frozen day, the real completion takes precedence and the freeze token is not consumed.

**UI:**
- `🧊 Freeze Streak` button appears inside `globalStreakCard` only when `StreakFreezeService.canFreeze == true`
- Tapping: confirmation alert ("Use your monthly freeze? You get one per month.") → confirm → calls `StreakFreezeService.freeze()` → refreshes `StatsViewModel`
- After freeze used: button replaced by `"❄️ Streak protected this month"` label (muted, no tap)

---

### 5. Widget Push-to-Refresh

**Problem:** Both widgets use `.after(nextRefresh)` with a 1-hour fallback, allowing iOS to poll hourly. `GoalViewModel` already calls `WidgetCenter.shared.reloadAllTimelines()` on every mutation — polling is redundant and wastes battery.

**Fix:** Change `TimelineReloadPolicy` in both widgets from `.after(...)` to `.never`.

```swift
// GoalSummaryWidget.swift + StreakWidget.swift
let timeline = Timeline(entries: [entry], policy: .never)
```

Widgets now only refresh when `reloadAllTimelines()` is called by the app (goal toggle, create, delete, challenge check-in). Remove the `nextRefresh` date calculation — it's no longer needed.

---

## Phase 16: Platform Features

### 6. StandBy Mode Widget

**How StandBy works:** iOS 17+ automatically uses existing widgets in StandBy's full-screen layout. No dedicated StandBy API is required — iOS picks up any widget that supports `.containerBackground`.

**Required change:** Add `.containerBackground(.fill.tertiary, for: .widget)` to both existing widget views. Without this, iOS 17 renders them incorrectly in StandBy.

**New `systemSmall` widget:** Add a small widget variant showing:
- Consistency Score (large numeral, `VGTheme.accentSage`)
- Global streak (smaller, below)
- Top active goal name (one line, truncated) — same tier-priority ordering as `CompleteTopGoalIntent`

Small widget uses `GoalSummaryProvider` (same data) with a compact layout. This is the widget iOS surfaces in StandBy rotation.

---

### 7. Interactive Lock Screen Widget

**Goal:** One-tap goal completion from the lock screen without unlocking the phone.

**Requires:** `AppIntents` framework (iOS 17+), `WidgetKit` interactive buttons.

**`CompleteTopGoalIntent: AppIntent`**
- `title`: "Complete Today's Goal"
- Fetches top incomplete goal from App Group SwiftData store using `makeWidgetContainer()` — "top" defined as: first goal with no `CompletionEvent` today, sorted by tier priority (Life → Year → Month → Week) then by creation date ascending
- Creates `CompletionEvent` for that goal with `Date.now`
- Calls `WidgetCenter.shared.reloadAllTimelines()`
- Returns `IntentResultValue.finished` with a brief confirmation string ("✓ Goal logged")

**Lock screen widget update (`StreakWidget`):**
- Add `Button(intent: CompleteTopGoalIntent())` showing the top goal's name + a circle checkmark
- Only shown when the top goal has no completion event today
- After tap: button changes to "✓ Done" (widget re-renders via `reloadAllTimelines`)

**Authentication:** AppIntents on lock screen require Face ID/Touch ID to execute by default on iOS 17.4+. No extra code needed — system handles it.

---

### 8. Claude Vision Photo Moderation

**`PhotoModerationService`**
- Single `async func isSafe(imageData: Data) async throws -> Bool`
- Converts `imageData` to base64, sends to Claude API with `claude-haiku-4-5` (fast, cost-effective for moderation)
- System prompt: `"You are a content safety classifier. Respond with only valid JSON: {\"safe\": true/false, \"reason\": \"string\"}. Flag any adult content, nudity, graphic violence, or sexually suggestive imagery as unsafe."`
- Parses JSON response. If API fails or times out (10s timeout), defaults to `true` (fail open — don't block users on network errors)
- API key read from `Info.plist` key `ANTHROPIC_API_KEY` (set via `Secrets.xcconfig`)

**Integration in `PostComposeSheet`:**
- On "Post" tap: show inline spinner, call `PhotoModerationService.isSafe(imageData:)`
- If `false`: show inline error below the photo picker — "This photo can't be posted. Please choose a different image." Post button re-enables for retry with a different photo.
- If `true`: proceed to `CommunityService.submitPost()`

**Also fix CR-01:** Delete the CKAsset temp file after `CKModifyRecordsOperation` completes (success or failure). Add `defer { try? FileManager.default.removeItem(at: tmpURL) }` after the temp file is created.

---

### 9. Privacy-First Community Posts

**Principle:** Posts contain no PII. Users' real identity is never stored in the community post record.

**CKRecord schema for posts (no changes to existing fields, constraints clarified):**
- `postID` — random UUID generated client-side (not linked to CloudKit record ID or Apple ID)
- `displayName` — user's chosen display name from `UserProfile` (user-controlled pseudonym, not real name)
- `text` — post body (profanity filtered before storage)
- `photoAsset` — `CKAsset` (expiring temp URL, not a permanent CDN link — cannot be shared outside the app)
- `category` — challenge category string
- `reactions` — reaction counts only, no reactor identities stored
- `reportedBy` — array of anonymous reporter tokens (not Apple IDs)

**No fields stored:** Apple ID, email, phone, device ID, location, IP address.

**User controls:**
- Users can delete their own posts (`CommunityService.deletePost(postID:)` — match on `postID` field, not CloudKit record owner, to avoid iCloud account exposure)
- Deletion removes the `CKRecord` and the `CKAsset` from CloudKit

**Moderation chain:** Text → `ProfanityFilter` (on-device) → Photo → `PhotoModerationService` (Claude Haiku) → if both pass → post submitted. Users never see content that failed either check.

---

## What's Not Changing

- CloudKit architecture — no S3/R2 backend needed. CloudKit's expiring `CKAsset` URLs provide equivalent privacy to signed URLs for this use case.
- Existing streak display on goal cards and widgets — Consistency Score is Stats screen only.
- Community feed reaction types — 👍 ❤️ stays as designed in Phase 14.

---

## Phase Summary

| Phase | Features | Risk |
|-------|----------|------|
| 15 | Dark mode tokens, haptic feedback, Consistency Score card, Streak Freeze, widget policy fix | Low — all local, no new APIs |
| 16 | StandBy widget, interactive lock screen widget (AppIntents), Claude Vision moderation, privacy post schema | Medium — AppIntents requires entitlement + device testing |
