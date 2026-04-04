# Vitamin G

## What This Is

Vitamin G is an iOS app for daily gratitude and tiered goal tracking. Users set goals across four tiers — from immediate wins to life goals — and receive a daily morning push notification reminding them of what they're working toward. It's "Vitamin G for Gratitude": a daily dose of intentionality.

## Core Value

Every morning, the user is reminded of their goals — making progress feel inevitable, not accidental.

## Requirements

### Validated

- [x] Four-tier goal system: Immediate, Short-Term, Long-Term, Life Goal — *Validated in Phase 1: Foundation*
- [x] Goal model: id, title, goalDescription, tier, isCompleted, creationDate, associatedInspiration — *Validated in Phase 1: Foundation*
- [x] Secure input validation on all String fields (100/500/300 char limits, sanitization) — *Validated in Phase 1: Foundation*
- [x] MVVM architecture with SwiftData persistence (SchemaV1 VersionedSchema, ModelContainerFactory) — *Validated in Phase 1: Foundation*
- [x] App Group + CloudKit-ready ModelContainer shared between app and widget targets — *Validated in Phase 1: Foundation*

### Active

- [ ] Four-tier goal system: Immediate, Short-Term, Long-Term, Life Goal
- [ ] Goal model: id, title, description, tier, isCompleted, creationDate, associatedInspiration
- [ ] Secure input validation on all String fields (character limits, injection prevention)
- [ ] MVVM architecture with SwiftData persistence
- [ ] Daily morning push notifications summarizing active goals
- [ ] Streak tracking and completion statistics per tier
- [ ] iCloud sync via CloudKit / SwiftData sync
- [ ] Home screen and lock screen widgets showing daily goal summary
- [ ] Polished, App Store-quality UI (ui-ux-pro-max design quality)

### Out of Scope

- Social / sharing features — keeping it personal and private for v1
- Goal collaboration / team goals — single-user app for now
- Android / cross-platform — iOS-first, always
- Web dashboard — native iOS is the experience

## Context

- Target platform: iOS 17+ (SwiftData requires iOS 17)
- Architecture: MVVM with SwiftData as the persistence layer
- Distribution: App Store launch + portfolio showcase
- User mentioned 6 phases in mind for the roadmap
- Developer has a specific vision for the 4-tier goal hierarchy; relationship between tiers is flexible for now (left to v2+)
- UI quality is a priority — ui-ux-pro-max skill to be applied during frontend phases

## Constraints

- **Tech Stack**: Swift, SwiftUI, SwiftData — no third-party dependencies unless necessary
- **Security**: All String inputs must have strict character limits and validation; local SwiftData storage must be treated as untrusted input boundary
- **Platform**: iOS 17+ minimum for SwiftData and modern SwiftUI APIs
- **Distribution**: Must meet App Store Review Guidelines — proper notification permissions, no background abuse
- **Architecture**: MVVM strictly enforced — no business logic in Views

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| SwiftData over CoreData | Modern Swift-native API, SwiftUI integration, CloudKit sync built-in | — Pending |
| MVVM architecture | Clean separation of concerns, testable ViewModels, industry standard for iOS | — Pending |
| SwiftUI-first UI | Matches SwiftData, enables widgets via WidgetKit naturally | — Pending |
| 4-tier goal hierarchy | Immediate → Short-Term → Long-Term → Life Goal maps to realistic planning horizons | — Pending |
| Input validation at model layer | Prevent injection/overflow even in local storage; defense in depth | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-04 after Phase 1: Foundation complete*
