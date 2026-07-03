---
status: partial
phase: 28-ai-claude-integration
source: [28-01-SUMMARY.md, 28-02-SUMMARY.md, 28-03-SUMMARY.md, 28-04-SUMMARY.md]
started: 2026-06-08T00:00:00Z
updated: 2026-06-08T00:00:00Z
---

## Current Test

[testing paused — 4 items outstanding, blocked by onboarding Sign in with Apple on entry screen]

## Tests

### 1. Worker Health Check
expected: POST to the deployed Cloudflare Worker with a valid token returns HTTP 200 with {"text":"..."} for type=motivation and {"suggestions":[...]} (3 items) for type=suggestions. POST with a wrong token returns HTTP 401.
result: pass

### 2. Home Tab - AI Motivation Card Visible
expected: Open the app and tap the Home tab. The motivation card is present and displays content (not blank, not a crash). The old static quote section is gone and replaced by the AI card.
result: pass

### 3. Home Tab - YOUR DOSE Label (Claude Path)
expected: When Claude successfully returns a motivation message (network available, cache hit or fresh fetch), the card label reads "YOUR DOSE" and shows Claude-generated copy. The label is NOT "TODAY'S DOSE".
result: pass

### 4. Home Tab - TODAY'S DOSE Label (Fallback Path)
expected: When Claude is unavailable (e.g. airplane mode or network blocked), the card shows "TODAY'S DOSE" and displays a VGQuoteBank fallback quote. The card is never blank or showing an error.
result: pass

### 5. Home Tab - Loading Skeleton
expected: On the first load (cold launch, no cache), the motivation card briefly shows a redacted/skeleton loading state while the fetch is in flight, then transitions to the actual content. No spinner, no empty white card.
result: skipped
reason: hard to reproduce once cache is warm for the day

### 6. Explore Tab - GOALS FOR YOU Section Position
expected: Open the Explore tab. A section labelled "GOALS FOR YOU" is visible between "Today's Gift" (GoalGifterCard) and "Daily Mood" (MoodPromptCard). It is NOT at the top or bottom of the list.
result: pass

### 7. Explore Tab - 3 Suggestions Display
expected: The GOALS FOR YOU card shows exactly 3 goal suggestion rows. Each row has suggestion text and an "Add Goal" capsule button. A sparkles icon and title "Goals suggested for you" appear in the card header.
result: blocked
blocked_by: prior-phase
reason: "Sign in with Apple button appears on entry/splash screen — cannot get past it in simulator"

### 8. Explore Tab - Add Goal Interaction
expected: Tapping "Add Goal" on a suggestion row transitions that row's button to a green checkmark (checkmark.circle.fill) and the Add Goal button disappears. Navigating to the Goals tab shows the newly added goal under QuickWin. A haptic tap fires on add.
result: blocked
blocked_by: prior-phase
reason: "Sign in with Apple button appears on entry/splash screen — cannot get past it in simulator"

### 9. Explore Tab - Cache Hit on Re-entry
expected: Leave the Explore tab and return to it (same app session, same day). The same 3 suggestions are shown without a loading skeleton — the UserDefaults daily cache is served without a new network call.
result: blocked
blocked_by: prior-phase
reason: "Sign in with Apple button appears on entry/splash screen — cannot get past it in simulator"

### 10. Explore Tab - Search Branch Gating
expected: Tap the search bar in the Explore tab and type a query. The GOALS FOR YOU card is hidden/not shown while search is active. Clearing the search restores the card to its normal position.
result: blocked
blocked_by: prior-phase
reason: "Sign in with Apple button appears on entry/splash screen — cannot get past it in simulator"

## Summary

total: 10
passed: 5
issues: 0
pending: 0
skipped: 1
blocked: 4

## Gaps

- truth: "Onboarding entry/splash screen shows falling vitamin confetti with a Get Started CTA; Sign in with Apple appears on screen 2 or 3 of the onboarding flow — not on the entry screen"
  status: failed
  reason: "User reported: Sign in with Apple button is on the entry screen with the falling vitamin confetti, blocking access to the app in the simulator"
  severity: blocker
  test: 7
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
