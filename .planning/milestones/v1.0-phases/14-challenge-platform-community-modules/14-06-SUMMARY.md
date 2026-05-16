---
plan: 14-06
phase: 14
status: complete
completed: 2026-05-13
---

## Summary

Created `CravingToolsModuleView` — a SwiftUI sheet modal with three sequential tools for managing cravings during a challenge (CHAL-19).

## What Was Built

**`VitaminG/VitaminG/VitaminG/Views/Modules/CravingToolsModuleView.swift`**

- `BreathingPhase` enum with 4 cases (inhale, holdFull, exhale, holdEmpty), each carrying a label, fill target, and next-phase pointer
- 4-4-4-4 box breathing animation: `Circle().fill(accentColor).scaleEffect(fillFraction)` with `.animation(.linear(duration: 4))` per phase; countdown digit 48pt semibold (no fontDesign per UI-SPEC)
- `@Environment(\.accessibilityReduceMotion)` gate: when true, fill animation is suppressed; only a static 3pt accent strokeBorder circle remains; countdown still ticks
- Motivational prompt section with `VGTheme.serifItalic(17)` typography from `VGQuoteBank.randomQuote()`; "Another One" button cycles quotes
- Buddy ping section rendered only when `userChallenge.buddyDisplayName != nil`; gated on 24h cooldown via local `canPing` computed property (matches Plan 14-08's future `canSendBuddyPing` extension math)
- Sends local notification via `NotificationScheduler.shared.scheduleBuddyPing(challengeID:buddyDisplayName:challengeTitle:)` from Plan 14-03
- NavigationStack with "Craving Tools" inline title and "Done" confirmation toolbar button

## Key Design Decisions

- Local `canPing` fallback: Plan 14-08 will add `UserChallenge.canSendBuddyPing` extension; Plan 14-06 uses identical inline math to remain self-contained and compilable before Plan 14-08 ships
- Sheet architecture: CravingToolsModuleView owns its own NavigationStack (presented as .sheet from ChallengeDetailView via Plan 14-10)
- Breathing loop: `isActive` bool breaks the `while` loop on `.onDisappear` to prevent retain-cycle / orphaned Tasks

## Acceptance Criteria Met

- [x] BreathingPhase enum with all 4 cases
- [x] 4-second linear animation per phase
- [x] Reduce Motion: static strokeBorder, countdown ticks
- [x] VGTheme.serifItalic(17) for quote
- [x] VGQuoteBank.randomQuote() with "Another One" cycling
- [x] "Stay Grounded" heading, "Done" toolbar button
- [x] Buddy ping conditional on buddyDisplayName + 24h cooldown
- [x] scheduleBuddyPing wired from Plan 14-03

## Self-Check: PASSED
