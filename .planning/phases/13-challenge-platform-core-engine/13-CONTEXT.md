# Phase 13: Challenge Platform — Core Engine — Context

**Status:** Not yet gathered — run `/gsd-discuss-phase 13` to gather context before planning.

**Phase goal:** One configurable challenge engine (SchemaV3 migration) powers Featured and Custom Challenges. Three featured challenges seeded via template system. Discovery screen, check-in flows, streak/milestone system, evening reminder notifications.

**Requirements:** CHAL-01 through CHAL-12

**Depends on:** Phase 3 (notifications), Phase 7 (user profiles)

**Source spec:** Challenge Platform vision doc (provided 2026-05-01) — key architecture: one engine, config-driven, zero per-type logic branching.

**Key open questions before planning:**
- SchemaV3 migration strategy (building on SchemaV2's VitaminGMigrationPlan)
- ChallengeTemplate storage: SwiftData (private CloudKit) vs. bundled JSON seed file for featured templates
- AppRoute additions for challenge navigation (discovery, detail, check-in, celebration)
- 5th tab vs. modal sheet for challenge discovery surface

---
*Added to roadmap 2026-05-01*
