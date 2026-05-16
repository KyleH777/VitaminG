# Phase 13: Challenge Platform — Core Engine - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-04
**Phase:** 13-challenge-platform-core-engine
**Areas discussed:** Featured template storage, Tab / entry point, Check-in notification routing, Streak chain view

---

## Featured Template Storage

| Option | Description | Selected |
|--------|-------------|----------|
| Swift constants → seed on launch | Featured templates defined as static Swift constants; inserted into SwiftData once at first launch if absent. Type-safe, no JSON decoding. | ✓ |
| Bundled JSON file → decode on launch | Templates in a .json bundle; decoded and inserted at launch if absent. Flexible but adds JSON decoding layer. | |
| SwiftData only → no seed | Templates created programmatically; no automatic seeding. | |

**User's choice:** Swift constants → seed on launch
**Notes:** User accepted recommended approach. Seeding location confirmed as `ChallengeViewModel.seedFeaturedTemplates()` (not ModelContainerFactory or app entry point) — follows GoalViewModel ownership pattern.

---

## Tab / Entry Point

### Tab structure
| Option | Description | Selected |
|--------|-------------|----------|
| 5th tab — Goals · Stats · Wins · Challenges · Profile | Challenges gets slot 4, before Profile. `flame.fill` icon. | ✓ |
| 5th tab — Goals · Challenges · Stats · Wins · Profile | Challenges at slot 2, next to Goals. | |
| No new tab — accessible from Goals tab | Challenges as modal/sheet from GoalListView. | |

**User's choice:** Goals · Stats · Wins · Challenges · Profile, `flame.fill`

### Tab icon
| Option | Description | Selected |
|--------|-------------|----------|
| flame.fill | Streak/challenge energy, universally understood. | ✓ |
| trophy.fill | Milestone/achievement framing. | |
| bolt.fill | Energy/action framing. | |

### AppRoute additions
| Option | Description | Selected |
|--------|-------------|----------|
| challengeDetail + challengeCheckIn | Two routes: detail view and check-in modal. | ✓ |
| challengeDetail only | Check-in is a sheet from detail, not a separate route. | |
| challengeDiscovery + challengeDetail + challengeCheckIn | Full set including discovery route (unnecessary — discovery is tab root). | |

**Notes:** User interrupted with scope creep suggestion (profile photo frame subscription). Captured as deferred idea. Otherwise accepted all recommended choices.

---

## Check-in Notification Routing

| Option | Description | Selected |
|--------|-------------|----------|
| Direct to check-in modal | Notification payload carries UserChallenge ID; opens check-in sheet immediately. | ✓ |
| Challenge detail view first | Notification opens detail view; user taps Check In from there. | |
| Challenges tab root | Notification opens tab root; user navigates from there. | |

**User's choice:** Direct to check-in modal

### Reminder time configuration
| Option | Description | Selected |
|--------|-------------|----------|
| Per-challenge time picker in challenge detail | Each UserChallenge has its own reminder time. Matches CHAL-12. | ✓ |
| Global default from SettingsView | One time for all challenges. | |
| Set at challenge join time | Picker shown at join; editable in detail later. | |

**User's choice:** Per-challenge time picker in challenge detail
**Notes:** Both choices matched recommendations. User satisfied after 2 questions, moved to next area.

---

## Streak Chain View (CHAL-11)

### Component approach
| Option | Description | Selected |
|--------|-------------|----------|
| New StreakChainView — horizontal day dots | New compact component: horizontal scrollable row of circles (30 days), filled/outlined based on check-in. Accent color from template. | ✓ |
| Reuse HeatmapView | Per-challenge check-in history in existing grid component. | |
| Simple counter only | Large streak number + longest streak text. No visual chain. | |

**User's choice:** New StreakChainView — horizontal day dots

### Placement
| Option | Description | Selected |
|--------|-------------|----------|
| Challenge detail view — below check-in button | Streak chain in detail/progress screen, beneath active check-in CTA. | ✓ |
| Inside the check-in modal | Motivational context before confirming check-in. | |
| Discovery card (collapsed) | Mini streak strip on each active challenge card. | |

**User's choice:** Challenge detail view — below check-in button
**Notes:** User confirmed day-dot visual: `● ○ ● ● ● ● ● ○ ● ● ●` — filled = checked in, outlined = missed.

---

## Claude's Discretion

- Exact day-dot circle size in `StreakChainView` (recommended: 20pt diameter)
- Progress bar position relative to streak chain view in detail layout
- SF Symbol for milestone badges at different thresholds (`flame.fill` at 7-day, `trophy.fill` at 30-day)
- Animation curve for full-screen confetti celebration (CHAL-10)

## Deferred Ideas

- $2 subscription tier with profile photo frames (cosmetic rewards / monetization) — raised during tab discussion; belongs in a future monetization phase post Phase 14
- Community feed, reactions, profanity filter — Phase 14
- Optional modules (Spending Freeze, Craving Tools, etc.) — Phase 14
- Custom challenge builder — Phase 14
