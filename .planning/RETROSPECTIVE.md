# Retrospective: Vitamin G

---

## Milestone: v1.0 — MVP

**Shipped:** 2026-05-15
**Phases:** 15 | **Plans:** 67 | **Timeline:** 42 days

### What Was Built

1. Full 4-tier goal management with CloudKit transparent sync and home/lock screen widgets
2. Configurable Challenge Platform — template engine, 3 featured challenges, custom builder, 5 modules
3. Community feed with CloudKit public DB, reactions, profanity filtering
4. User Profiles with AvatarView, privacy toggle, deep links (vitaming:// scheme)
5. Daily Wins / Gratitude module with dedicated tab and "What's your win today?" notification
6. Goal Progress rings, 30-day chart, momentum scoring, micro-milestone celebrations
7. App Store-quality onboarding, Dark Mode, Dynamic Type, VoiceOver

### What Worked

- **VersionedSchema from day one** — paying the upfront cost of SchemaV1 enabled 8 schema migrations (V1→V8) across the milestone without data loss. Would have been painful to retrofit.
- **Template-driven Challenge Platform** — ChallengeTemplate config driving all challenge behavior (CHAL-07) meant adding all 5 optional modules without core engine changes. Design decision paid off.
- **TDD for engine-layer code** — StreakEngine, ProgressViewModel, ChallengeStreakEngine all developed test-first. Caught DST edge cases and index-out-of-bounds bugs before they reached UI.
- **Verification Sprint (Phase 8)** — Dedicated phase to write missing VERIFICATION.md files for phases 2, 3, 7 was the right call. Audit revealed real gaps; Phase 8 closed them cleanly.
- **Decimal phase numbering** — Phases 8, 9, 10 inserted as integers but treated as ordered insertions. Worked cleanly; ROADMAP stayed legible.
- **CloudKit public DB for community** — No server backend required for community posts, reactions, public profiles. Kept the app dependency-free.

### What Was Inefficient

- **Audit ran before Phase 8–15 existed** — The v1.0 milestone audit (April 16) was run before 9 remediation and feature phases completed. Audit status was `gaps_found` at close but most gaps were already resolved. A re-run audit would have been cleaner.
- **REQUIREMENTS.md checkbox staleness** — Checkboxes for Phase 4/5 requirements went stale for months (marked Pending when phases were complete). Should have updated checkboxes at each phase transition, not just at milestone close.
- **Nyquist compliance at 0/15** — No phases achieved nyquist_compliant: true in VALIDATION.md. Test coverage was adequate for engine-layer code but UI flows lacked automated coverage. Something to address in v2.
- **Phase ordering drift** — ROADMAP listed phases 11, 12 after 13, 14 in the bullet list due to execution order drift. The Progress table was accurate but visual ordering was confusing.

### Patterns Established

- `ModelContainerFactory.makeContainer(inMemory: true)` — standard test harness for SwiftData unit tests. Use this in every phase.
- `@MainActor XCTestCase` class — required pattern for all SwiftData tests.
- `VersionedSchema` migration plan (`VitaminGMigrationPlan`) — stage migrations in `willMigrate`/`didMigrate` closures; test with in-memory containers.
- Pure struct ViewModels (StreakEngine, ProgressViewModel) — engine-layer logic decoupled from SwiftUI/SwiftData for easy unit testing.
- Override injection on Observable ViewModels — pass services in init for testability; production code uses singleton.
- `targetEnvironment(simulator)` guards — skip App Group + CloudKit in simulator to prevent test runner crashes.

### Key Lessons

1. **Verify early** — Running the audit before major feature phases completed created confusion. Run `gsd:audit-milestone` after all planned work is done.
2. **Tick checkboxes at phase transition** — Don't let REQUIREMENTS.md drift; update status when the phase SUMMARY is written.
3. **Physical device testing can't be fully automated** — SYNC-01 (cross-device iCloud) and widget rendering require hardware. Budget time for this in planning.
4. **Template-driven features scale better than type-branched features** — ChallengeTemplate proved this. Apply the same pattern to notification types and widget variants in v2.
5. **Schema version discipline pays dividends** — Every schema change via VersionedSchema, no exceptions. This constraint saved data loss risks multiple times.

### Cost Observations

- Model mix: primarily claude-sonnet-4-6
- Sessions: ~20+ sessions across 42 days
- Notable: Large phases (13, 14) with wave-based parallelization reduced per-task context overhead

---

## Cross-Milestone Trends

| Metric | v1.0 |
|--------|------|
| Phases | 15 |
| Plans | 67 |
| Days | 42 |
| LOC (Swift) | ~16,917 |
| Requirements | 98/98 |
| Nyquist compliant | 0/15 |
| Schema versions | 8 |
