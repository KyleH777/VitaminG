# Security Standard Operating Procedures — Vitamin G

**Version:** 1.0 (Phase 22 baseline)
**Last updated:** 2026-05-25
**Applies to:** All CloudKit public-DB write paths introduced in Phase 22 (Profiles, Follow, Public Goals, Discover search)

---

## 1. Authentication Boundary

CloudKit public database writes require a signed-in iCloud account. `CKContainer(identifier:).publicCloudDatabase` transparently enforces this — unauthenticated callers receive `CKError.notAuthenticated`. No custom auth code is required; Apple's CloudKit infrastructure handles identity validation.

**Control:** Inherent — CloudKit SDK rejects writes from unauthenticated containers.
**Verify:** Ship a test build; sign out of iCloud; attempt a follow write → `CKError.notAuthenticated` error surfaced to user.

---

## 2. Input Sanitization

All `String` values written to CloudKit records MUST pass through `InputSanitizer.sanitizeForPublic()` before assignment to a `CKRecordValue`. This trims whitespace, strips control characters, and enforces character limits per field.

| Field | Max Length | Enforced By |
|-------|-----------|-------------|
| `username` | 20 chars | InputSanitizer + ProfileSharingService |
| `displayName` | 50 chars | InputSanitizer + ProfileSharingService |
| `motto` | 100 chars | InputSanitizer + ProfileSharingService |
| `followerUsername` / `followeeUsername` | 20 chars | InputSanitizer + ProfileSharingService.writeFollow |
| CKQuery predicate values (search text) | 100 chars (truncated before predicate) | PublicGoalService.searchGoals / searchPeople |

**Control:** Code-level — `InputSanitizer.sanitizeForPublic` called in all service write paths.
**Verify:** `grep -c "InputSanitizer.sanitizeForPublic" VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift` ≥ 3; same check for `PublicGoalService.swift` ≥ 2.

---

## 3. Search Rate Limiting (Discover)

`DiscoverViewModel` enforces a **20 searches per 60 seconds** in-session limit using an in-memory timestamp queue (`recentSearchTimes: [Date]`). Searches exceeding this limit display `"Too many searches. Please slow down."` and return without issuing a CloudKit query.

The 500ms debounce (Task.sleep + cancellation) runs first and handles the common keystroke-spam case. The rate limiter is the second line of defense for sustained high-frequency use.

**Control:** In-memory — `DiscoverViewModel.onSearchTextChanged` filters `recentSearchTimes` to the last 60 seconds and gates on count < 20 before launching any search Task.
**Verify:** `grep -E "recentSearchTimes" VitaminG/VitaminG/VitaminG/ViewModels/DiscoverViewModel.swift` ≥ 2 hits.

---

## 4. Follow Write Rate Limiting

`ProfileSharingService.writeFollow` enforces a **10 follows per 60 minutes** limit using a `UserDefaults` timestamp array (`vg_follow_write_times`). Before issuing a CloudKit save, the method:

1. Reads `vg_follow_write_times` from UserDefaults as `[Double]` (epoch seconds)
2. Filters to the last 3600 seconds
3. If `count >= 10`: throws `NSError(domain: "VGRateLimit", code: 429)` — no CloudKit call is made
4. On successful save: appends `Date().timeIntervalSince1970` and writes back to UserDefaults

This limit survives app restart (UserDefaults is persistent) and prevents bulk-following automation from a single account.

**Control:** UserDefaults-backed — survives app restarts within the TTL window.
**Verify:** `grep -E "vg_follow_write_times" VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift` ≥ 2 hits.

---

## 5. Daily Cheer Gate

`ApplauseGate.canApplaud(for: username)` limits cheers to **once per calendar day** per recipient. `ProfileSharingService.writeFollow` idempotency (deterministic `recordName = "\(follower)_\(followee)"`) prevents duplicate Follow records from multiple taps.

**Control:** `ApplauseGate` (UserDefaults-backed, existing Phase 21 utility).
**Verify:** `Phase21ApplauseDailyGateTests` suite green.

---

## 6. Privacy Guard — Profile Publish

`VitaminGApp` launch hooks and `GoalViewModel.addCheckIn` hooks MUST check `UserProfile.isPublic == true` before calling `ProfileSharingService.publishProfile`. Private-profile users' `streakLength`, `goalCount`, and `motto` must never reach the CloudKit public database.

**Control:** `if userProfile.isPublic` guard in every `publishProfile` call site.
**Verify:** `grep -E "isPublic\s*==\s*true" VitaminG/VitaminG/VitaminG/VitaminGApp.swift` ≥ 1 hit (Plan 04 acceptance criterion T-22-04-05).

---

## 7. CloudKit Server-Side Rate Limiting

CloudKit imposes its own server-side rate limits per container. When the server throttles a request it returns `CKError.requestRateLimited` with a `retryAfterSeconds` value. All service methods that save or query records must catch this error and surface it to the user rather than silently swallowing it or retrying in a tight loop.

**Control:** Catch `CKError.requestRateLimited` in service error handlers; propagate to ViewModel `error` state property with a user-facing message: `"Vitamin G is a bit busy. Try again shortly."`.
**Verify:** Code review — confirm no bare `try? container.save(record)` exists without `requestRateLimited` handling in new Phase 22 service methods.

---

## 8. Threat Model Quick Reference

| Threat | Mitigation | Status |
|--------|-----------|--------|
| Unauthenticated CloudKit writes | CloudKit iCloud auth required | Inherent |
| XSS / injection via user strings | InputSanitizer on all CK writes | In code |
| Follow spam (bulk following) | 10 follows/hour UserDefaults gate | Phase 22 |
| Search hammering (DoS quota) | 500ms debounce + 20/min cap | Phase 22 |
| Profile data leaking (private users) | isPublic guard before publishProfile | Phase 22 |
| Duplicate Follow records | Deterministic recordName (idempotent) | Phase 22 |
| Duplicate Cheer writes | ApplauseGate (once/day per recipient) | Phase 21 |
| CloudKit quota exhaustion | Server-side CKError.requestRateLimited handling | Phase 22 |
| Participant count drift | Accepted risk — cosmetic; requires real Join action | Accepted |

---

## 9. Review Cadence

- **Per-phase:** Verify this document is updated before executing any phase that adds new CloudKit write paths.
- **Pre-release:** Run `grep -rn "InputSanitizer" VitaminG/VitaminG/VitaminG/Services/` and confirm every new String CKRecord write is covered.
- **Post-release:** Monitor CloudKit Console for `requestRateLimited` spikes. If sustained > 1% of requests, tighten client-side limits.

---

*Maintained by the development team. Update when write paths or rate limits change.*
