---
phase: 07
slug: add-user-profiles-with-privacy-toggle-profile-picture-upload
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-14
---

# Phase 07 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| SwiftData store migration | Existing user data must survive V1→V2 migration without loss | Goal + CompletionEvent records (local) |
| User input → displayName | Untrusted string input validated at ViewModel layer | Plain string (display only) |
| App → CloudKit public DB | Profile data crosses from local device to publicly accessible database | displayName, avatarColorHex only |
| CloudKit public DB → Any reader | Anyone with the recordID can read the PublicProfile record | displayName, avatarColorHex |
| Deep link URL → External apps | URL shared via system share sheet to arbitrary apps | vitaming://profile/<recordID> |
| photoData → UIImage | Untrusted binary data decoded for display | Binary image blob |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-07-01 | Tampering | SchemaV2 migration | mitigate | `MigrationStage.lightweight` from SchemaV1→SchemaV2; `isPublic = false` default on Goal and UserProfile | closed |
| T-07-02 | Denial of Service | ModelContainerFactory | mitigate | Both `makeContainer` and `makeWidgetContainer` use `Schema(SchemaV2.models)` + `VitaminGMigrationPlan.self` to prevent store mismatch crash | closed |
| T-07-03 | Information Disclosure | UserProfile.photoData | accept | Reserved nil field — no UI to populate it in Phase 7. No data exposure risk until photo upload is implemented. | closed |
| T-07-04 | Tampering | ProfileViewModel.validateAndSaveDisplayName | mitigate | `sanitize()` strips control + illegal + HTML chars, normalizes whitespace; 50-char cap enforced before SwiftData save | closed |
| T-07-05 | Information Disclosure | PublicGoalsSection | accept | Only goal titles and tier displayed in public goals list — no descriptions, inspiration text, or completion data. User explicitly opted in. | closed |
| T-07-06 | Denial of Service | loadOrCreateProfile | mitigate | `FetchDescriptor.fetchLimit = 1` prevents unbounded query | closed |
| T-07-07 | Spoofing | displayName input | mitigate | `sanitize()` blocks `controlCharacters ∪ illegalCharacters ∪ { <, >, ", ' }` — HTML angle brackets explicitly removed | closed |
| T-07-08 | Information Disclosure | ProfileSharingService.publishProfile | mitigate | Explicit two-field allowlist: only `displayName` and `avatarColorHex` written to CKRecord | closed |
| T-07-09 | Tampering | CKRecord fields | mitigate | `publicCloudDatabase` used; no custom ACL set — CloudKit default grants write only to record creator | closed |
| T-07-10 | Repudiation | unpublishProfile | accept | No audit trail on profile publish/unpublish. Acceptable for a personal gratitude app with no compliance requirements. | closed |
| T-07-11 | Denial of Service | CloudKit write failure | mitigate | Publish failure shows error alert (optimistic UI preserved); `unpublishProfile` silently ignores `.unknownItem` | closed |
| T-07-12 | Information Disclosure | Deep link URL | accept | RecordID is a UUID-like CloudKit identifier — not guessable, not sequential. Acceptable for share-link distribution. | closed |
| T-07-13 | Tampering | AvatarView photoData | mitigate | `UIImage(data:)` safely returns nil for malformed data; `else` branch falls back to initials avatar | closed |
| T-07-14 | Denial of Service | AvatarView initials computation | accept | O(n) on displayName max 50 chars (enforced upstream). Negligible performance impact. | closed |

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-07-01 | T-07-03 | photoData reserved nil — no write path exists in Phase 7 | Kyle | 2026-04-14 |
| AR-07-02 | T-07-05 | Goal title/tier only; user explicitly opted in via isPublic toggle | Kyle | 2026-04-14 |
| AR-07-03 | T-07-10 | No compliance requirements; personal gratitude app | Kyle | 2026-04-14 |
| AR-07-04 | T-07-12 | UUID-like recordID; no guessable sequence; share-link model | Kyle | 2026-04-14 |
| AR-07-05 | T-07-14 | 50-char enforced upstream; O(n) on trivial input | Kyle | 2026-04-14 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-14 | 14 | 14 | 0 | gsd-security-auditor (sonnet) + T-07-07 fix applied |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-14
